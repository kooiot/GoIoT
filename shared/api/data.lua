-- Lazy Pirate client
-- Use ZMQ_RCVTIMEO to do a safe request-reply
-- To run, start lpserver and then randomly kill/restart it

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local client = require "shared.req"

client.open()

local _M = {}

_M.add = function(name, desc, value)
	local req = {"add", {name=name, desc=desc, value=value}}
	return client.request(cjson.encode(req), true)
end

_M.erase = function(name)
	local req = {"erase", {name=name}}
	return client.request(cjson.encode(req), true)
end

_M.set = function(name, val, timestamp)
	local req = {'set', {name=name, value=val, timestamp=timestamp}}
	return client.request(cjson.encode(req), true)
end

_M.get = function(name)
	local req = {'get', {name=name}}
	reply, err = client.request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.subscribe = function(self_id, tags)
	local req = {'subscribe', {id = self_id, tags=tags}}
	reply, err = client.request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.unsubscribe = function(self_id)
	local req = {'unsubscribe', {id = self_id}}
	reply, err = client.request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.version = function()
	local req = {'version'}
	local reply, err = client.request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

return _M
