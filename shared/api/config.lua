-- Lazy Pirate client
-- Use ZMQ_RCVTIMEO to do a safe request-reply
-- To run, start lpserver and then randomly kill/restart it

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.req"
local client = req.new()

client:open({zmq.REQ, linger = 0, connect="tcp://localhost:5522", rcvtimeo = 300}, 3)

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

_M.add = function(key, vals)
	local req = {"add", {key=key, vals=vals}}
	return reply(client:request(cjson.encode(req), true))
end

_M.erase = function(key)
	local req = {"erase", {key=key}}
	return reply(client:request(cjson.encode(req), true))
end

_M.set = function(key, vals)
	local req = {'set', {key=key, vals=vals}}
	return reply(client:request(cjson.encode(req), true))
end

_M.get = function(key)
	local req = {'get', {key=key}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply, err = cjson.decode(reply)
		if reply then
			if reply[2].result then
				err = reply[2].err
				reply = reply[2].vals
			else
				err = reply.err
			end
		end
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
