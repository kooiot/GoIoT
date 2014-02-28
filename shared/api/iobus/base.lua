-- Data api access the datacache

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'

local req = require "shared.req"
local client = req.new()

client:open()

local _M = {}

local function reply(json, err)
	local reply = nil
	if json then
		reply, err = cjson.decode(json)
		if reply then
			if #reply == 2 then
				err = reply[2].err
				reply = reply[2].result
			else
				err = "incorrect reply json"
			end
		end
	end
	return reply, err
end

_M.add = function(name, desc, value)
	local req = {"add", {name=name, desc=desc, value=value}}
	return reply(client:request(cjson.encode(req), true))
end

_M.erase = function(name)
	local req = {"erase", {name=name}}
	return reply(client:request(cjson.encode(req), true))
end

_M.set = function(name, val, timestamp)
	local timestamp = timestamp or ztimer.absolute_time()
	local req = {'set', {name=name, value=val, timestamp=timestamp}}
	return reply(client:request(cjson.encode(req), true))
end

_M.sets = function(vals)
	local req = {'sets', vals}
	return reply(client:request(cjson.encode(req), true))
end

_M.get = function(name)
	local req = {'get', {name=name}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.enum = function(pattern)
	local req = {'enum', {pattern=pattern}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.subscribe = function(self_id, tags)
	local req = {'subscribe', {id = self_id, tags=tags}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.unsubscribe = function(self_id)
	local req = {'unsubscribe', {id = self_id}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.version = function()
	local req = {'version'}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

return _M
