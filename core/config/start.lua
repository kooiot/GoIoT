#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
local log = require 'shared.log'
local db = require 'db'
db.load()


local ctx = zmq.context()
local poller = zpoller.new(1)

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5522"}
zassert(server, err)

local mpft = {} -- message process function table

function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	print(rep_json)
	server:send(rep_json)
end

mpft['get'] = function(vars)
	local err = 'Invalid/Unsupported request message format'
	if vars and type(vars) == 'table' then
		if vars.key then
			local val_json = db.get(vars.key)
			log:debug('CONFIGS', 'get '..vars.key..(val_json or 'nil'))
			local vals = cjson.decode(val_json)
			local rep = {'get', {result=true, key=vars.key, vals=vals}}
			server:send(cjson.encode(rep))
			return
		end
	end
	send_err(err)
end

mpft['set'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key and vars.vals then
			db.set(vars.key, cjson.encode(vars.vals))
			local rep = {'set', {result=true}}
			server:send(cjson.encode(rep))
			return
		end
	end
	send_err(err)
end

mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key and vars.vals then
			local r, err = db.add(vars.key, vars.vals)
			local rep = {'add', {result=r, err=err}}
			server:send(cjson.encode(rep))
			return
		end
	end
	send_err(err)
end

mpft['erase'] = function(vars)
	local err = 'Invalid/Unsupported request message format'

	if vars and type(vars) == 'table' then
		if vars.key then
			local r, err = db.del(vars.key)
			local rep = {'erase', {result=r, err=err}}
			server:send(cjson.encode(rep))
			return
		end
	end
	send_err(err)

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
