#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'

local running = {
	test = {run = true, last = os.time()}
}

local ctx = zmq.context()
local poller = zpoller.new(1)

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5511"}
zassert(server, err)

local mpft = {} -- message process function table

function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	print(rep_json)
	server:send(rep_json)
end

mpft['notice'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) == 'table' then
		if vars.name then
			running[vars.name] = running[vars.name] or {} 
			running[vars.name].last = os.time()
			local rep = {'notice', {result=true}}
			server:send(cjson.encode(rep))
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
	for k, v in pairs(running) do
		if not vars or vars[k] then
			st[k] = v
		end
	end
	local rep = {'query', {result=true, status = st}}
	server:send(cjson.encode(rep))
end

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
		--print('checking '..k..' run:'..tostring(v.run)..' last:'..tostring(v.last))
		if v.run == true and (now - v.last)  > 10 then
			print('application does not send the notice')
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
