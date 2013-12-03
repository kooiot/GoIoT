#!/usr/bin/env lua

require 'zhelpers'
local zmq = require 'lzmq'
local cjson = require 'cjson.safe'
local db = require('db').new()
db:open('db.sqlite3')

local ctx = zmq.context()

local server, err = ctx:socket{zmq.REP, bind = "tcp://*:5555"}
zassert(server, err)

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
				local rep = {'add', {result='ok', name=vars.name}}
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
				local rep = {'erase', {result='ok', name=vars.name}}
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
				local rep = {'set', {result='ok', name=vars.name}}
				server:send(cjson.encode(rep))
				return
			end
		end
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

function run()
	while true do
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
	end
end

run()
