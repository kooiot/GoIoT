-- Lazy Pirate client
-- Use ZMQ_RCVTIMEO to do a safe request-reply
-- To run, start lpserver and then randomly kill/restart it

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local client = require "shared.req"

client.open(nil, {zmq.REQ, linger = 0, connect="tcp://localhost:5522", rcvtimeo = 300}, 3)

local _M = {}

_M.add = function(key, vals)
	local req = {"add", {key=key, vals=vals}}
	return client.request(cjson.encode(req), true)
end

_M.erase = function(key)
	local req = {"erase", {key=key}}
	return client.request(cjson.encode(req), true)
end

_M.set = function(key, vals)
	local req = {'set', {key=key, vals=vals}}
	return client.request(cjson.encode(req), true)
end

_M.get = function(key)
	local req = {'get', {key=key}}
	local reply, err = client.request(cjson.encode(req), true)
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
