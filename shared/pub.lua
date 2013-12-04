require "shared.zhelpers"
local zmq =require"lzmq"
local cjson = require 'cjson.safe'

local _M = {}

function _M.create(ctx, option)
	_M.context = ctx or zmq.context()
	if option then
		option[1] = zmq.PUB
		_M.option = option
	else
		_M.option = {
			zmq.PUB, 
			bind = "tcp://*:5566"
		}
	end

	local err = nil
	_M.publisher, err = _M.context:socket(_M.option)
	zassert(_M.publisher, err)
	return true
end

_M.close = function ()
	_M.publisher:close()
end

_M.pub = function (key, data)
	-- Write two messages, each with an envelope and content
	_M.publisher:send(key..' ', zmq.SNDMORE)
	_M.publisher:send(data)
end

return _M
