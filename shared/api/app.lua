
local zmq = require 'lzmq'
local cjson = require "cjson.safe"

local req = require 'shared.req'

local class = {}

function class:version()
	local req = {'version', {from='web'}}
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
	end
	-- reply = { version=xxx, build=xxxx }
	return reply, err
end

function class:status(request)
	local request = request or 'status'
	local req = {request, {from='web'}}
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
		-- reply = { result=xx, status=xxxx }
		if reply.result then
			reply = reply.status
		else
			reply = nil
			err = 'result is not true'
		end
	end
	return reply, err
end

function class:start()
	return self:status('start')
end

function class:stop()
	return self:status('stop')
end

function class:reload()
	return self:status('reload')
end

function class:meta()
	local req = {'meta', {from='web'}}
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
		-- reply = { result=xx, meta={blabla} }
		if reply.result then
			reply = reply.meta
		else
			reply = nil
			err = 'result is not true'
		end
	end
	return reply, err
end

function class:import(filename)
	local req = {'import', {filename=filename}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
		if reply.result then
			reply = true
		else
			err = reply.err
			reply = reply.result
		end
	end
	return reply, err
end

local _M = {}

function _M.new(port)
	local client = req.new()
	client:open({zmq.REQ, linger = 0, connect = "tcp://localhost:"..port, rcvtimeo = 300}, 3)
	return setmetatable({client=client}, {__index=class})
end

return _M
