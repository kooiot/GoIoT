#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
local log = require 'shared.log'

local db = require('db').new()
db:open('db.sqlite3')

local ctx = zmq.context()

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5555"}
zassert(server, err)

local pub = require 'pub'
local publisher = pub.init(ctx)

function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	server:send(rep_json)
end

local clients = {} -- contains clients information
local mpft = {} -- message process function table

-- hanlde login from data generator, TODO: handler the login from data subscribers
mpft['login'] = function(vars)
	local namespace = vars.from
	local user = vars.user
	local pass = vars.pass
	local port = vars.port
	clients[namespace] = { user=user, pass=pass, port=port }
	local rep = {"login", { result = true, ver="1" }}
	server:send(cjson.encode(rep))

	if port and port ~= 0 then
		-- Tell all client there possiably an updated application back online
		pub.update(ns)
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
				local rep = {'publish', {result=true, path=vars.path}}
				server:send(cjson.encode(rep))
				pub.cov(vars.path, vars)
				return
			end
		end
	end
	send_err(err)
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
		local rep = {'batch_publish', {result=result, paths=paths}}
		server:send(cjson.encode(rep))
		return
	end
	send_err(err)
end

mpft['read'] = function(vars)
	local err = 'Invalid/Unsupported get request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.path then
			local r, value, timestamp = db:get(vars.path)
			if r then
				local rep = {'read', {path=vars.path, value=value, timestamp=timestamp}}
				server:send(cjson.encode(rep))
				return
			else
				err = value
			end
		end
	end
	send_err(err)
end

mpft['write'] = function(vars)
	local err = 'Invalid/Unsupported write request'
	if vars and type(vars) == 'table' and vars.path then
		-- write operation to application
		local ns, dev = vars.path:match('^([^/]+)/([^/]+)/.+')
		if clients[ns] then
			local r, err = pub.write(vars.path, vars.value, vars.from)
			local reply = {'write', {result=r, err=err}}
			server:send(cjson.encode(reply))
		else
			err = 'Device path incorrect, no such namespace'
		end
	end
	log:error('IOBUS', 'Error on write', err)
	send_err(err)
end

mpft['command'] = function(vars)
	local err = 'Invalid/Unsupported command request'
	if vars and type(vars) == 'table' and vars.path then
		-- command operation to application
		local ns, dev = vars.path:match('^([^/]+)/([^/]+)/.+')
		if clients[ns] then
			local r, err = pub.command(vars.path, vars.args, vars.from)
			local reply = {'command', {result=r, err=err}}
			server:send(cjson.encode(reply))
		else
			err = 'Device path incorrect, no such namespace'
		end
	end
	log:error('IOBUS', 'Error on command', err)
	send_err(err)
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

	local rep = {'enum', {result=ture, devices=devs}}
	server:send(cjson.encode(rep))
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
			local err = nil
			local r, tree = api:request('devs')
			if not r then
				return nil, tree
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
			server:send(cjson.encode({'tree', {result=true, tree=obj}}))
		else
			send_err(err)
		end
	else
		local err = 'Invalid/Unsupported get request'
		send_err(err)
	end
end

mpft['subscribe'] = function(vars)
	local result, err = pub.sub(vars.pattern, vars.from)
	local rep = {'subscribe', {result=result, err=err}}
	server:send(cjson.encode(rep))
end

mpft['unsubscribe'] = function(vars)
	local result, err = pub.unsub(vars.pattern, vars.from)
	local rep = {'unsubscribe', {result=result, err=err}}
	server:send(cjson.encode(rep))
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
				send_err('Unsupported message operation: '..req[1])
			end
		end
	end
end)

poller:add(publisher, zmq.POLLIN, function()
	--- NONE
end)

poller:start()

