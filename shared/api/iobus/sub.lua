--- IOBUS subscribe client (internal using only)
-- Connects SUB socket to tcp://localhost:5556
-- Collects data updates 

require "shared.zhelpers"
local zmq = require "lzmq"
local log = require 'shared.log'
local cjson = require 'cjson.safe'

--- Subscribe class
-- @type class
local class = {}

--- Bind the path with callback
function class:bind(path, cb)
	assert(not self.callbacks[path])
	self.callbacks[path] = cb
end

--- Unbind the path
function class:unbind(path)
	self.callbacks[path] = nil
end

--- Open the connection
function class:open()
	--log:debug("IOBUS_API", "Collecting updates from publish server ...")
	-- Socket to talk to server
	local subscriber, err = self.context:socket(self.option)
	zassert(subscriber, err)
	self.subscriber = subscriber

	self.poller:add(subscriber, zmq.POLLIN, function()
		local filter, data, err = self:recv()
		if filter and data then
			if data[1] == 'cov' then
				local cb = self.callbacks[data[2].pattern]
				if cb then
					-- Call backs
					cb(data[2].path, data[2].value)
				else
					log:error('IOBUS_API', 'No callback specified for device:', data[2].pattern)
				end
			elseif data[1] == 'write' then
				if self.onwrite then
					self.onwrite(data[2].path, data[2].value, data[2].from)
				else
					log:error('IOBUS_API', 'No onwrite implemented')
				end
			elseif data[1] == 'command' then
				if self.oncommand then
					self.oncommand(data[2].path, data[2].args, data[2].from)
				else
					log:error('IOBUS_API', 'No oncommand implemented')
				end
			elseif data[1] == 'update' then
				if self.onupdate then
					self.onupdate(data[2].namespace)
				else
					log:error('IOBUS_API', 'No onupdate implemented')
				end
			else
				-- No support one?
			end
			if data.namespace == filter then
				-- a write request, or a comommand request
			else
				-- Nothing to do
			end
		end
	end)
end

--- Calling the recv function to get message
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
	if data then
		data, err = cjson.decode(data)
		if not data then
			log:debug('IOBUS_API', 'Cannot decode the data', err)
		end
	end
	return filter, data, err
end

--- Close connection
function class:close()
	self.poller:remove(self.subscriber)
	self.subscriber:close()
	self.subscriber = nil
end

--- Module functions
-- @section

--- Create subscribe api
-- @function module
-- @tparam string filter Your application namespace
-- @tparam lzmq.context ctx
-- @tparam lzmq.poller poller
-- @treturn class object
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
