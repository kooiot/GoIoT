#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'

local CONF_FILE = 'conf.json'

local conf = nil
local running = {}

function load_conf()
	local file, err = io.open(CONF_FILE, "r")
	if file then
		local conf, err = cjson.decode(file:read("*a"))
		file:close()
		if not conf then
			print(err)
		end
		return conf, err
	end
	print('no configuration file found')
	return nil, err
end

function save_conf()
	local file, err = io.open(CONF_FILE, "w+")
	if file then
		file:write(cjson.encode(conf))
		file:close()
		return true
	end
	return nil, err
end

conf = load_conf()  or {}

local function start_app(app)
	running[app.name] = running[app.name] or {}
	if running[app.name].run then
		return
	end
	if not app.program then
		print('Quit as there is no program for '..app.name)
		return
	end
	if not app.restart and running[app.name].run == false then
		print('Application quit, no restart setting '..app.name)
		return
	end

	if type(app.restart) == 'function' then
		-- let the restart function handle every thing, normally it will call restart all
		app.restart()
		return
	end

	if app.startup and type(app.startup) == 'function' then
		app.startup()
	end
	print('Now start app '..app.name)
--	os.execute('cd '..app.path..';'..app.program..' '..(app.args  or '').. " > /dev/null &")
	running[app.name].run = true
	running[app.name].last = os.time()
end

local function start(app) 
	for k, v in pairs(conf) do
		if not app or app == v.name then
			start_app(v)
		end
	end
end

local mpft = {} -- message process function table

function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	print(rep_json)
	server:send(rep_json)
end

mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.name and vars.desc and vars.value then
			local r = true
			r, err = db:add(vars.name, vars.desc, vars.value)
			if r then
				local rep = {'add', {result='ok', name=vars.name}}
				server:send(cjson.encode(rep))
				return
			end
		end
	end
	send_err(err)
end

mpft['notice'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) == 'table' then
		if vars.name and running[vars.name] then
			running[vars.name].last = os.time()
			local rep = {'notice', {result='ok'}}
			server:send(cjson.encode(rep))
		else
			print('balbabalbaba')
		end
	end
	send_err(err)
end

mpft['query'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) ~= 'table' then
		send_err(err)
		return
	end

	local st = {}
	for k, v in pairs(conf) do
		if not vars or vars[v.name] then
			st[v.name] = running[v.name]
		end
	end
	local rep = {'query', {result='ok', status = st}}
	server:send(cjson.encode(rep))
end

local ctx = zmq.context()
local poller = zpoller.new(1)

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5511"}
zassert(server, err)

poller:add(server, zmq.POLLIN, function()
	local req_json = server:recv()
	print("REQ:\t"..req_json)

	local req, err = cjson.decode(req_json)
	if not req then
		send_err(err)
	else
		if type(req) ~= 'table' then
			send_err('unsupport message type')
		else
			-- handle request
			--server:send(cjson.encode(req))
			local fun = mpft[req[1]]
			if fun then
				fun(req[2])
			else
				send_err('Unsupported message operation'..req[1])
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
		print('checking '..k..' run:'..tostring(v.run)..' last:'..tostring(v.last))
		if v.run == true and (now - v.last)  > 10 then
			print('application does not send the notice')
			v.run = false
		end
	end
end

while not stop do
	start() -- start all application first
	timer:start()
	while timer:rest() > 0 do
		poller:poll(timer:rest())
	end
--	check_timeout()
end

save_conf()
