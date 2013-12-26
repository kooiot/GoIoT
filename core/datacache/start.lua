#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'

local db = require('db').new()
db:open('db.sqlite3')

local ctx = zmq.context()

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5555"}
zassert(server, err)

local ptable = {}
local publisher, err = ctx:socket{zmq.PUB, bind = "tcp://*:5566"}
zassert(publisher, err)

function send_err(err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	print(rep_json)
	server:send(rep_json)
end

local mpft = {} -- message process function table

-- hanlde login
mpft['login'] = function(vars)
	local rep = {"login", { ver="1" }}
	server:send(cjson.encode(rep))
end

mpft['add'] = function(vars)
	local err = 'Invalid/Unsupported add request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.name and vars.desc and vars.value then
			local r = true
			r, err = db:add(vars.name, vars.desc, vars.value)
			if r then
				local rep = {'add', {result=true, name=vars.name}}
				server:send(cjson.encode(rep))
				return
			end
		end
	end
	send_err(err)
end

mpft['erase'] = function(vars)
	local err = 'Invalid/Unsupported erase request, standard one is ["erase", {"name":"tag1"}]'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.name then
			local r = true
			r, err = db:erase(vars.name)
			if r then
				local rep = {'erase', {result=true, name=vars.name}}
				server:send(cjson.encode(rep))
				return
			end
		end
	end
	send_err(err)
end

mpft['set'] = function(vars)
	local err = 'Invalid/Unsupported set request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.name and vars.value and vars.timestamp then
			local r = true
			r, err = db:set(vars.name, vars.value, vars.timestamp)
			if r then
				local rep = {'set', {result=true, name=vars.name}}
				server:send(cjson.encode(rep))

				-- publish changes
				if ptable[vars.name] then
					for k, v in pairs(ptable[vars.name]) do
						publisher:send(k..' ', zmq.SNDMORE)
						publisher:send(cjson.encode(vars))
					end
				end
				return
			end
		end
	end
	send_err(err)
end

mpft['sets'] = function(vars)
	local err = 'Invalid/Unsupported sets request'
	--- valid the request
	if vars and type(vars) == 'table' then
		local result = false
		local names = {}
		for k,v in pairs(vars) do
			if v.name and v.value and v.timestamp then
				local r = true
				r, err = db:set(v.name, v.value, v.timestamp)
				if not r then
					print('ERR', err)
					result = false
				else
					table.insert(names, v.name)
					-- publish changes
					if ptable[v.name] then
						for client_id, sub in pairs(ptable[v.name]) do
							publisher:send(k..' ', zmq.SNDMORE)
							publisher:send(cjson.encode(v))
						end
					end
				end
			else
				result = false
			end
		end
		local rep = {'sets', {result=result, names=names}}
		server:send(cjson.encode(rep))
		return
	end
	send_err(err)
end

mpft['get'] = function(vars)
	local err = 'Invalid/Unsupported get request'
	--- valid the request
	if vars and type(vars) == 'table' then
		if vars.name then
			local r, value, timestamp = db:get(vars.name)
			if r then
				local rep = {'get', {name=vars.name, value=value, timestamp=timestamp}}
				server:send(cjson.encode(rep))
				return
			else
				err = value
			end
		end
	end
	send_err(err)
end

mpft['enum'] = function (vars)
	local tags = db:enum(vars.pattern or "*")
	local rep = {'enum', tags}
	server:send(cjson.encode(rep))
end

mpft['subscribe'] = function(vars)
	local err =  'Invalid/Unsupported subscribe request'
	local id = vars.id
	local tags = vars.tags
	for k,v in pairs(tags) do
		print('subscribe '..v..' for '..id)
		ptable[v] = ptable[v] or {}
		ptable[v][id] = true
	end
	local rep = {'subscribe', {result=true, id=id}}
	server:send(cjson.encode(rep))
end

mpft['unsubscribe'] = function(vars)
	local err =  'Invalid/Unsupported unsubscribe request'
	local id = vars.id
	for k,v in pairs(ptable) do
		if ptable[v] and ptable[v][id] then
			print('unsubscribe '..v..' for '..id)
			ptable[v][id] = nil
		end
	end
	local rep = {'unsubscribe', {result=true, id=id}}
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
				send_err('Unsupported message operation'..req[1])
			end
		end
	end
end)

poller:add(publisher, zmq.POLLIN, function()
	--- NONE
end)

poller:start()

