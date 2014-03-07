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

-- hanlde login
mpft['login'] = function(vars)
	local namespace = vars.from
	local user = vars.user
	local pass = vars.pass
	local port = vars.port
	clients[namespace] = { user=user, pass=pass, port=port }
	local rep = {"login", { ver="1" }}
	server:send(cjson.encode(rep))
end

mpft['publish'] = function(vars)
	log:debug('IOBUS', 'PUBLISH', vars.path)
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
				r, err = db:set(v.path, v.value, v.timestamp)
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
		local r, err = pub.write(vars.path, vars.value, vars.from)
		local reply = {'write', {result=r, err=err}}
		server:send(cjson.encode(reply))
	end
	send_err(err)
end

mpft['command'] = function(vars)
	local err = 'Invalid/Unsupported command request'
	if vars and type(vars) == 'table' and vars.path then
		-- command operation to application
		local r, err = pub.command(vars.path, vars.args, vars.from)
		local reply = {'command', {result=r, err=err}}
		server:send(cjson.encode(reply))
	end
	send_err(err)
end

mpft['enum'] = function (vars)
	local tags = db:enum(vars.pattern or "*")
	local rep = {'enum', tags}
	server:send(cjson.encode(rep))
end

local function get_devices_tree(path)
	local ns, dev = path:match('([^/]-)/(.-)$')
	if not ns then
		ns = path
	end
	if ns and clients[ns] and clients[ns].port then
		-- Query devvices tree
		if not clients[ns].tree then
			local api = require('shared.api.app').new(clients[ns].port)
			local err = nil
			local tree, err = api.request('devs')
			if not tree then
				return nil, err
			end

			clients[ns].tree = tree
			return tree[dev]
		else
			return clients[ns].tree[dev]
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
			server:send(cjson.encode(rep))
		else
			send_err(err)
		end
	else
		local err = 'Invalid/Unsupported get request'
		send_err(err)
	end
end

mpft['subscribe'] = function(vars)
	local result, err = pub.sub(vars.devpath, vars.from)
	local rep = {'subscribe', {result=result, err=err}}
	server:send(cjson.encode(rep))
end

mpft['unsubscribe'] = function(vars)
	local result, err = pub.unsub(vars.devpath, vars.from)
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

