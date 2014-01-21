-- Weather update client
-- Connects SUB socket to tcp://localhost:5556
-- Collects weather updates and finds avg temp in zipcode

require "shared.zhelpers"
local zmq = require "lzmq"

local _M = {}

function _M.open(filter, ctx, poller, cb)
	assert(ctx)
	assert(poller)
	assert(cb)
	-- Subscribe to filter 
	_M.filter = filter or ""
	_M.filter = _M.filter..' '
	_M.poller = poller
	_M.callback = cb

	printf("Collecting updates from publish server ...\n")

	_M.context = ctx
	_M.option = {
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

	poller:add(subscriber, zmq.POLLIN, function()
		local filter, data = _M.recv()
		if filter and data then
			cb(filter, data)
		end
	end)
end

function _M.recv()
	if not _M.subscriber then
		return nil, nil
	end
	-- receive the filter
	local filter = _M.subscriber:recv()
	if filter then
		print('FILTER', filter, _M.filter)
	else
		return nil, nil
	end

	-- receive content
	local data, err = _M.subscriber:recv()
	return filter, data, err
end

function _M.close()
	_M.poller:remove(_M.subscriber)
	_M.subscriber:close()
	_M.subscriber = nil
end

return _M
