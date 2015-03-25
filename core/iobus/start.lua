#!/usr/bin/env lua

local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local log = require 'shared.log'
local vardef = require 'vardef'

local db = require('db').new()
db:open('db.sqlite3')

local ctx = zmq.context()

local server, err = ctx:socket{zmq.REP, bind = "tcp://127.0.0.1:5555"}
zassert(server, err)

local pub = require 'pub'
local publisher = pub.init(ctx)

local send = require('shared.msg.send')(server)
local send_result, send_err = send.result, send.err

local clients = {} -- contains clients information
local mpft = {} -- message process function table

-- hanlde login from data generator, TODO: handler the login from data subscribers
mpft['login'] = function(vars)
	local namespace = vars.from
	local user = vars.user
	local pass = vars.pass
	local port = vars.port
	clients[namespace] = { user=user, pass=pass, port=port }

	send_result('login', {ver="1"})

	if port and port ~= 0 then
		-- Tell all client there possiably an updated application back online
		pub.update(namespace)
	end
end

mpft['publish'] = function(vars)
	--log:debug('IOBUS', 'PUBLISH', vars.path)
	local err = 'Invalid/Unsupported publish request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.path and vars.value and vars.timestamp then
			local r = true
			r, err = db:set(vars.path, vars.value, vars.timestamp, vars.quality)
			if r then
				send_result('publish', true)
				pub.cov(vars.path, vars)
				return
			end
		end
	end
	send_err('publish', err)
end

mpft['batch_publish'] = function(vars)
	local err = 'Invalid/Unsupported batch_publish request'
	--- valid the request
	if vars and type(vars) == 'table' then
		local result = false
		local paths = {}
		for k,v in pairs(vars.pvs) do
			if v.path and v.value and v.timestamp then
				local r = true
				r, err = db:set(v.path, v.value, v.timestamp, v.quality)
				if not r then
					log:error('IOBUS', 'SETS ERR', err)
					result = false
				else
					table.insert(paths, v.path)
					pub.cov(v.path, v)
				end
			else
				result = false
			end
		end
		return send_result('batch_publish', {result=result, paths=paths})
	end
	send_err('batch_publish', err)
end

mpft['read'] = function(vars)
	local err = 'Invalid/Unsupported get request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.path then
			local r, value, timestamp = db:get(vars.path)
			if r then
				return send_result('read', {path=vars.path, value=value, timestamp=timestamp})
			else
				err = value
			end
		end
	end
	send_err('read', err)
end

mpft['write'] = function(vars)
	local err = 'Invalid/Unsupported write request'
	if vars and type(vars) == 'table' and vars.path then
		-- write operation to application
		local ns, dev = vars.path:match('^([^/]+)/([^/]+)/.+')
		if clients[ns] then
			local r, err = pub.write(vars.path, vars.value, vars.from)
			return send_result('write', r, err)
		else
			err = 'Device path incorrect, no such namespace '..vars.path
		end
	end
	log:error('IOBUS', 'Error on write', err)
	send_err('write', err)
end

mpft['command'] = function(vars)
	local err = 'Invalid/Unsupported command request'
	if vars and type(vars) == 'table' and vars.path then
		-- command operation to application
		local ns, dev = vars.path:match('^([^/]+)/([^/]+)/.+')
		if clients[ns] then
			local r, err = pub.command(vars.path, vars.args, vars.from)
			return send_result('command', r, err)
		else
			err = 'Device path incorrect, no such namespace '..vars.path
		end
	end
	log:error('IOBUS', 'Error on command:', err)
	send_err('command', err)
end

local get_devices_tree

-- Enumrate all avaiable namespaces
mpft['enum'] = function (vars)
	local devs = {}
	local pattern = vars.pattern or ".+"
	for ns, c in pairs(clients) do
		if c.port and c.port ~= 0 then
			-- query tree is not queried
			if not c.tree then
				get_devices_tree(ns)
			end

			-- Get the tree
			local devices = c.tree and c.tree.devices or {}
			for name, device in pairs(devices) do
				if device.path:match(vars.pattern) then
					devs[ns] = devs[ns] or {}
					table.insert(devs[ns], name)
				end
			end
		end
	end

	return send_result('enum', devs)
end

get_devices_tree = function(path)
	local ns, dev = path:match('([^/]-)/(.-)$')
	if not ns then
		ns = path
	end
	if ns and clients[ns] and clients[ns].port then
		-- Query devvices tree
		if not clients[ns].tree then
			local api = require('shared.api.app').new(clients[ns].port)
			local tree, err = api:request('devs')
			if not tree then
				return nil, err
			end

			clients[ns].tree = tree
			if dev then
				return {verinfo = tree.verinfo, device = tree.devices[dev]}
			else
				return tree
			end
		else
			local tree = clients[ns].tree
			if dev then
				return {verinfo = tree.verinfo, device = tree.devices[dev]}
			else
				return tree
			end
		end
	end
	return nil, 'Incorrect namespace specified'
end

mpft['tree'] = function(vars)
	-- TODO: Ask application for its io tree
	local path = vars.path
	if path then
		local obj, err = get_devices_tree(path)	
		if obj then
			return send_result('tree', obj)
		else
			return send_err('tree', err)
		end
	else
		local err = 'Invalid/Unsupported get request'
		return send_err('tree', err)
	end
end

mpft['subscribe'] = function(vars)
	local result, err = pub.sub(vars.pattern, vars.from)
	return send_result('subscribe', result, err)
end

mpft['unsubscribe'] = function(vars)
	local result, err = pub.unsub(vars.pattern, vars.from)
	return send_result('subscribe', result, err)
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


local poller = zpoller.new(2)
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
				send_err('error', 'Unsupported message operation: '..req[1])
			end
		end
	end
end)

poller:add(publisher, zmq.POLLIN, function()
	--- NONE
end)

vardef.load()
local ns = vardef.populate(db)
ns.port = -1
clients[ns.name] = ns

--poller:start()
local timer = ztimer.monotonic(1000)
while true do

	timer:start()
	while timer:rest() > 0 do
		poller:poll(timer:rest())
	end

	print('ping....')
	vardef.run(function(path, value, timestamp, quality)
		assert(path and value)
		local timestamp= timestamp or ztimer.absolute_time()
		local quality = quality or 1
		local r, err = db:set(path, value, timestamp, quality)
		if r then
			pub.cov(path, {path=path, value=value, timestamp=timestamp, quality=quality})
		end
	end)
	
end

