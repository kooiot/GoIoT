#!/usr/bin/env lua

local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
--local log = require 'shared.log'
local db = require 'db'
db.load()


local ctx = zmq.context()
local poller = zpoller.new(1)

local server, err = ctx:socket{zmq.REP, bind = "tcp://127.0.0.1:5522"}
zassert(server, err)

local mpft = {} -- message process function table

local send = require('shared.msg.send')(server)
local send_result, send_err = send.result, send.err

--[[
local function send_result(msg, result, err)
	local reply = {msg, result, err}
	local rep_json, json_err = cjson.encode(reply)
	if not rep_json then
		rep_json = cjson.encode({msg, nil, json_err})
	end
	server:send(rep_json)
end

local function send_err(msg, err)
	return send_result(msg, nil, err)
end
]]--
mpft['list'] = function(vars)
	local list = db.list()
	return send_result('list', list)
end

mpft['get'] = function(vars)
	local err = 'Invalid/Unsupported request message format'
	if vars and type(vars) == 'table' then
		if vars.key then
			local val_json = db.get(vars.key)
			--log:debug('CONFIGS', 'get '..vars.key..(val_json or 'nil'))
			if val_json then
				local value, err = cjson.decode(val_json)
				return send_result('get', value, err)
			else
				err = 'Config not exists'
			end
		end
	end
	return send_err('get', err)
end

mpft['set'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key and vars.value then
			db.set(vars.key, cjson.encode(vars.value))
			return send_result('set', true)
		end
	end
	return send_err('set', err)
end

mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key and vars.value then
			local r, err = db.add(vars.key, vars.value)
			return send_result('add', r, err)
		end
	end
	return send_err('add', err)
end

mpft['erase'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key then
			local r, err = db.del(vars.key)
			return send_result('erase', r, err)
		end
	end
	return send_err('erase', err)
end

mpft['clear'] = function(vars)
	local r, err = db.clear()
	return send_result('list', r, err)
end

mpft['version'] = function()
	return send_result('version', {
		version = '0.1',
		build = '01',
	})
end

poller:add(server, zmq.POLLIN, function()
	local req_json = server:recv()
	print("REQ:\t"..req_json)

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
				send_err(req[1], 'Unsupported message operation'..req[1])
			end
		end
	end
	
end)
local ztimer   = require "lzmq.timer"
local timer = ztimer.monotonic(3000)
local stop = false

local function timer_loop()
	-- trigger saving to disk
	db.timer()
end

while not stop do
	timer:start()
	while timer:rest() > 0 do
		poller:poll(timer:rest())
	end
	timer_loop()
end
