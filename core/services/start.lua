#!/usr/bin/env lua

--- A services server which accept an lua string task, and will report the running status
-- Which could abort the task

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
local log = require 'shared.log'
local runner = require 'runner'

local NAME = 'SERVICES'

local running = {
--	test = {desc = 'xxfadfa', status = RUNNING, last = os.time(), result=nil, percent=50, pid=xxxx}
}
local logs = {
	-- test = {'start on .dafa', 'dafdafd'}
}

local ctx = zmq.context()
local poller = zpoller.new(2)

local server, err = ctx:socket{zmq.REP, bind = "tcp://127.0.0.1:5115"}
zassert(server, err)

local send = require('shared.msg.send')(server)
local send_result, send_err = send.result, send.err

local mpft = {} -- message process function table

local function save_file(str)
	local file = os.tmpname()
	local f, err = io.open(file, 'w+')
	if not f then
		os.remove(file)
		return nil, err
	end
	f:write(str)
	f:close()
	return file
end

local function run_file(name, desc, file)
	if running[name] and running[name].status == 'RUNNING' then
		return nil, 'Same name service is running'
	end

	local pid, err = runner.run(name, file)
	if pid then
		running[name] = {
			status = 'RUNNING',
			file = file,
			last = os.time(),
			pid = pid,
			desc = desc,
		}
		log:info(NAME, 'One new service added ['..name..']')
		return pid
	else
		running[name] = {
			status = 'ERROR',
			file = file,
			desc = desc,
			last = os.time(),
			output = err,
			pid = nil,
		}
	end
	assert(err)
	log:error(NAME, err)
	return nil, err
end

mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) == 'table' then
		local name = vars.name
		local dostr = vars.dostr
		local desc = vars.desc or ''
		if name and dostr then
			local result = false
			local file, pid = nil, nil
			file, err = save_file(dostr)
			--- Get a tmp file name 
			if file then
				pid, err = run_file(name, desc, file)
				if pid then
					log:info(NAME, 'Services '..name..' has been started! pid='..pid)
				else
					--os.remove(file)
					log:error(NAME, 'Services '..name..' failed to started '..err)
				end
			else
				err = 'Cannot save the dostr to tempfile'
				log:error(NAME, err)
			end

			if pid then
				result = true
			end
			return send_result('add', result, err)
		end
	end
	send_err('add', err)
end

mpft['result'] = function(vars)
	local err = 'Invalid/Unsupported result request'
	if vars and type(vars) == 'table' then
		local name = vars.name
		local result = vars.result
		local output = vars.output
		log:info(NAME, 'Result from service ['..name..']', output)
		if running[name] then
			running[name].result = result
			running[name].output = output
			return send_result('result', true)
		else
			err = "The services not exists "..name
			log:error(NAME, err)
		end
	end
	send_err('result', err)
end

mpft['progress'] = function(vars)
	local err = 'Invalid/Unsupported progress request'
	if vars and type(vars) == 'table' then
		local name = vars.name
		local desc = vars.desc
		local perc = vars.perc
		log:info(NAME, 'Progress from service ['..name..'] - '..desc..' - ', perc)
		if running[name] and desc and name then
			running[name].percent = perc
			logs[name] = logs[name] or {}
			logs[name][#logs[name]] = desc
			return send_result('progress', true)
		else
			err = "The services not exists "..name
			log:error(NAME, err)
		end
	end
	send_err('progress', err)
end

mpft['abort'] = function(vars)
	if vars and type(vars) ~= 'table' then
		local err = 'Invalid/Unsupported abort request'
		return send_err('abort', err)
	end

	local name = vars.name
	local result = false
	local err = ''

	if name and running[name] then
		if running[name].status == 'RUNNING' then
			runner.abort(name)
			running[name].status = 'ABORTED'
			running[name].result = false
			running[name].output = 'Services aborted!!!'
			result = true
		else
			err =  'Service already aborted'
		end
	else
		err = "No such services "..name
	end

	return send_result('abort', result, err)
end


mpft['query'] = function(vars)
	local err = 'Invalid/Unsupported query request'
	if vars and type(vars) ~= 'table' then
		send_err('query', err)
		return
	end

	local name = vars.name
	local status = 'NONE'
	local percent = nil
	local lgs = nil

	if name and running[name] then
		status = running[name].status
		percent = running[name].percent
		lgs = logs[name]
	end

	return send_result('query', {status = status, percent = percent, logs=lgs})
end

mpft['list'] = function(vars)
	local err = 'Invalid/Unsupported query request'

	local st = {}
	--[[
	local st = { {
		name = 'store.install.dummy',
		desc = '/admin/modbus',
		pid = 0,
		status = 'RUNNING',
		result = true,
		output = 'Done',
	}}
	]]--
	for n, v in pairs(running) do
		st[#st + 1] = {
			name = n,
			desc = v.desc,
			status = v.status,
			pid = v.pid,
			result = v.result,
			output = v.output,
			percent = v.percent,
		}
	end
	return send_result('list', st)
end

mpft['version'] = function()
	local reply = {
		'version',
		{
			version = '0.1',
			build = '01',
		}
	}
	server:send(cjson.encode(reply))
end


poller:add(server, zmq.POLLIN, function()
	local req_json = server:recv()
	--print("REQ:\t"..req_json)

	local req, err = cjson.decode(req_json)
	if not req then
		log:error(NAME, err)
		send_err('error', err)
	else
		if type(req) ~= 'table' then
			send_err('error', 'unsupport message type')
		else
			--print('Received Request -'..req[1])
			-- handle request
			--server:send(cjson.encode(req))
			local fun = mpft[req[1]]
			if fun then
				fun(req[2])
			else
				send_err('error', 'Unsupported message operation'..req[1])
			end
		end
	end
	
end)

local ztimer   = require "lzmq.timer"
local timer = ztimer.monotonic(3000)
local stop = false

local function check_timeout()
	local now = os.time()
	for k,v in pairs(running) do
		if v.status == 'RUNNING' and (now - v.last)  > 1 then
			v.last = now
			local result, output = runner.check(k)
			if not result then
				v.status = 'DONE'
				v.result = v.result or true
			end
			if v.file and v.status ~= 'RUNNING' then
				os.remove(v.file)
				v.file = nil
			end
		end
	end
end

while not stop do
	timer:start()
	while timer:rest() > 0 do
		poller:poll(timer:rest())
	end
	check_timeout()
end

