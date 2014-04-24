--- Zeromq publish helper module


require "shared.zhelpers"
local zmq =require"lzmq"
local cjson = require 'cjson.safe'

local _M = {}

--- The option table
-- @table option
-- @field 1 it has to be lzmq.PUB
-- @field bind the bind string, e.g. "tcp://*:5566"

--- initial/create the publish service
-- @tparam lzmq.context ctx
-- @tparam[opt] option option default is = { lzmq.PUB, bind="tcp://*:5566" }
-- @treturn boolean ok
-- @raise assert when failed to create the publish services
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

--- Close the publish service
_M.close = function ()
	_M.publisher:close()
end

--- Publish data to client(key)
-- @tparam string key the client key
-- @tparam string data the data you want to publish to client
_M.pub = function (key, data)
	-- Write two messages, each with an envelope and content
	_M.publisher:send(key..' ', zmq.SNDMORE)
	_M.publisher:send(data)
end

return _M
