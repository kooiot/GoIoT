#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
local log = require 'shared.log'

local running = {
--	test = {run = true, last = os.time()}
}

local ctx = zmq.context()
local poller = zpoller.new(2)

local event = require('shared.event').S.new(ctx, poller)
event:open()

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5511"}
zassert(server, err)

local send = require('shared.msg.send')(server)
local send_result, send_err = send.result, send.err

local mpft = {} -- message process function table

mpft['notice'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) == 'table' then
		if vars.name then
			if vars.typ and vars.typ == 'exit' then
				log:warn('MONITOR', 'Application ['..vars.name..'] exited normally!!!')
				vars.run = false
			else
				vars.run = true
			end
			running[vars.name] = vars 
			running[vars.name].last = os.time()
			return send_result('notice', true)
		end
	end
	return send_err('notice', err)
end

mpft['query'] = function(vars)
	local err = 'Invalid/Unsupported query request'
	if vars and type(vars) ~= 'table' then
		return send_err('query', err)
	end

	local names = {}
	if vars then
		for _, name in pairs(vars) do
			names[name] = true
		end
	end

	local st = {}
	for k, v in pairs(running) do
		if not vars or names[k] then
			st[k] = v
		end
	end
	return send_result('query', st)
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
		send_err('error', err)
	else
		if type(req) ~= 'table' then
			send_err('error', 'unsupport message type')
		else
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
		--print('checking '..k..' run:'..tostring(v.run)..' last:'..tostring(v.last))
		if v.run == true and (now - v.last)  > 10 then
			print('application does not send the notice')
			log:warn('MONITOR', 'Application ['..k..'] does not send the notice message within 10 seconds')
			v.run = false
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
