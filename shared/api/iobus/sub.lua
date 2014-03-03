-- iobus client
-- Connects SUB socket to tcp://localhost:5556
-- Collects data updates 

require "shared.zhelpers"
local zmq = require "lzmq"

local class = {}

function class:bind(path, cb)
	assert(not self.callbacks[path])
	self.callbacks[path] = cb
end

function class:unbind(path)
	self.callbacks[path] = nil
end

function class:open()
	printf("Collecting updates from publish server ...\n")
	-- Socket to talk to server
	local subscriber, err = self.context:socket(self.option)
	zassert(subscriber, err)
	self.subscriber = subscriber

	poller:add(subscriber, zmq.POLLIN, function()
		local filter, data = self.recv()
		if filter and data then
			if data.path and self.callbacks[data.path] then
				-- Call backs
				self.callbacks[data.path](filter, data)
			end
		end
	end)
end

function class:recv()
	if not self.subscriber then
		return nil, nil
	end
	-- receive the filter
	local filter = self.subscriber:recv()
	if filter then
		assert(filter==self.filter)
	else
		return nil, nil
	end

	-- receive content
	local data, err = self.subscriber:recv()
	return filter, data, err
end

function class:close()
	self.poller:remove(self.subscriber)
	self.subscriber:close()
	self.subscriber = nil
end

return function(filter, ctx, poller)
	local obj = {}
	assert(ctx)
	assert(poller)
	-- Subscribe to filter 
	local filter = filter or ""
	obj.filter = filter..' '
	obj.poller = poller
	obj.callbacks = {}


	obj.context = ctx
	obj.option = {
		zmq.SUB,
		subscribe = obj.filter,
		connect   = "tcp://localhost:5566",
		rcvtimeo = 1000;
	}
	assert(obj.option[1] == zmq.SUB)
	
	local c = setmetatable(obj, {__index=class})
	c:open()
	return c
end
