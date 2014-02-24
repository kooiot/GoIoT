#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'
local log = require 'shared.log'
local config = require 'shared.api.config'

local ctx = zmq.context()

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5555"}
zassert(server, err)

local ptable = {}
local publisher, err = ctx:socket{zmq.PUB, bind = "tcp://*:5566"}
zassert(publisher, err)

local function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	server:send(rep_json)
end

local trees = {}
local data = require 'shared.io.data' 
local mpft = {} --- message process functions table

local function cov(client, path, value)
end

local function load_trees()
	local json, err = config.get('devices.list')
	local list, err = cjson.decode(json)
	if list then
		for i, ns in pairs(list) do
			local json, err = config.get('devices.'..ns)
			if not json then
				log:error('DATACACHE', 'Failed to get devices for', ns)
			else
				local tree = data.new(ns, json)
				if not tree then
					log:error('DATACACHE', "Failed to create devices from", json)
				else
					trees[ns] = tree
				end
			end
		end
	end
	log:info('DATACACHE', 'Loading devices tree finished')
end

local function init()
	load_trees()
end

-- hanlde login
mpft['login'] = function(vars)
	local rep = {"login", { ver="1" }}
	server:send(cjson.encode(rep))
end

-- add one device tree
mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.namespace and vars.json then
			local json = vars.json
			local tree = data.new(vars.namespace, json)
			if tree then
				trees[vars.namespace] = tree
				local rep = {'add', {result=true, namespace=vars.namespace}}
				server:send(cjson.encode(rep))
				return
			end
		end
	end
	send_err(err)
end

-- Update device tree
mpft['update'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	if vars and type(vars) == 'table' then
		if vars.namespace and vars.json then
			local json = vars.json
			local tree = trees[vars.namespace]
			if tree then
				tree:update(json)
				-- TODO: Update notice?
				local rep = {'add', {result=true, namespace=vars.namespace}}
				server:send(cjson.encode(rep))
				return
			else
				err = 'Tree is not existing'
			end
		end
	end
	send_err(err)
end

-- Update erase device tree
mpft['erase'] = function(vars)
	local err = 'Invalid/Unsupported erase request, standard one is ["erase", {"name":"tag1"}]'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.namespace then
			trees[vars.namespace] = nil
			local rep = {'erase', {result=true, namespace=vars.namespace}}
			server:send(cjson.encode(rep))
		end
	end
	send_err(err)
end

-- Set object's attribute and value
mpft['set'] = function(vars)
	local err = 'Invalid/Unsupported set request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.namespace then
			local tree = trees[vars.namespace]
			if tree then
				local r = tree.set(vars.path, vars.value)
				if r then
					local rep = {'set', {result=true, namespace=vars.namespace}}
					server:send(cjson.encode(rep))
					return
				end
			end
		end
	end
	send_err(err)
end

mpft['sets'] = function(vars)
	local err = 'Invalid/Unsupported sets request'
	--- valid the request
	if vars and type(vars) == 'table' then
		local paths = {}
		if vars.namespace then
			local tree = trees[vars.namespace]
			if tree then
				for path, val in pairs(vars.pvs) do
					local r = tree.set(path, val)
					if r then
						table.insert(paths, path)
					end
				end
			end
		end

		local result = false
		if #paths == #vars.pvs then
			result = true
		end
		local rep = {'sets', {result=result, paths=paths}}
		server:send(cjson.encode(rep))
		return
	end
	send_err(err)
end

mpft['get'] = function(vars)
	local err = 'Invalid/Unsupported get request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.namespace then
			local tree = trees[vars.namespace]
			local value = nil
			value, err = tree.get(vars.path)
			if value then
				local rep = {'get', {result=true, namespace=vars.namespace, path=vars.path, value=value}}
				server:send(cjson.encode(rep))
				return
			end
		end
	end
	send_err(err)
end

mpft['enum'] = function (vars)
	local t = nil
	if vars.namespace then
		local tree = trees[vars.namespace]
		t = tree.enum(vars.path)
	else
		for namespace, tree in pairs(trees) do
			table.insert(t, namespace)
		end
	end
	local rep = {'enum', {result=true, list=t}}
	server:send(cjson.encode(rep))
end

mpft['subscribe'] = function(vars)
	local err =  'Invalid/Unsupported subscribe request'
	if vars.namespace and vars.from then
		log:info('DATACACHE', 'subscribe '..vars.namespace..' for '..vars.from)
		local tree = trees[vars.namespace]
		if tree then
			tree:subscribe(vars.paths, vars.from)
			local rep = {'subscribe', {result=true}}
			server:send(cjson.encode(rep))
		else
			err = "Namesapce incorrect"
		end
	end
	send_err(err)
end

mpft['unsubscribe'] = function(vars)
	local err =  'Invalid/Unsupported unsubscribe request'
	if vars.namespace and vars.from then
		log:info('DATACACHE', 'unsubscribe '..vars.namespace..' for '..vars.from)
		local tree = trees[vars.namespace]
		if tree then
			tree:unsubscribe(vars.paths, vars.from)
			local rep = {'unsubscribe', {result=true}}
			server:send(cjson.encode(rep))
		else
			err = "Namesapce incorrect"
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
				send_err('Unsupported message operation'..req[1])
			end
		end
	end
end)

poller:add(publisher, zmq.POLLIN, function()
	--- NONE
end)

poller:start()

