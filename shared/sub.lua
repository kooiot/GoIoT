-- Weather update client
-- Connects SUB socket to tcp://localhost:5556
-- Collects weather updates and finds avg temp in zipcode

require "shared.zhelpers"
local zmq = require "lzmq"

local _M = {}

function _M.open(filter, ctx, option)
	-- Subscribe to filter 
	_M.filter = filter or "*"
	_M.filter = _M.filter..' '

	printf("Collecting updates from publish server ...\n")

	_M.context = ctx or zmq.context()
	_M.option = option or {
		zmq.SUB,
		subscribe = _M.filter,
		connect   = "tcp://localhost:5566",
		rcvtimeo = 1000;
	}
	assert(_M.option[1] == zmq.SUB)

	-- Socket to talk to server
	local subscriber, err = _M.context:socket(_M.option)
	zassert(subscriber, err)
	_M.subscriber = subscriber

end

function _M.recv()
	-- receive the filter
	local filter = _M.subscriber:recv()
	if filter then
		print(filter, _M.filter)
		assert(_M.filter == filter)
	else
		return nil, 'timeout'
	end

	-- receive content
	local data, err = _M.subscriber:recv()
	return data, err
end

function _M.close()
	_M.subscriber:close()
end

return _M
