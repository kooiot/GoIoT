--- Event classes
-- @author Dirk Chang
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'

local cfg = require 'shared.event.cfg'

--- Event Object Type
-- @table event
-- @field src the event source
-- @field name the event's name
-- @field dest the target event receiver name, nil will send to ALL

--- Callback function
-- @function callback
-- @tparam event event

--- Event client class
--	a type class
local class = {}

--- Create a new client object
-- @tparam lzmq.context ctx 
-- @tparam lzmq.poller poller 
-- @tparam callback cb callback function
-- @treturn class a new server object
function class.new(ctx, poller, cb)
	local poller = poller or zpoller.new()
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx = ctx,
		poller = poller,
		client = nil,
		subscriber = nil,
		option = nil,
		callback = cb,
	}, {__index = class})
end

--- Open connection 
-- @tparam string ip remote ip
-- @treturn nil
-- @raise assert on binding failure
function class:open(ip)

	local SOCKET_OPTION = {
		zmq.SUB,
		subscribe = 'EVENT ',
		connect  = cfg.CONN_METHOD..(ip or cfg.SERVER_ENDPOINT)..cfg.PUB_SERVER_PORT,
	}

	local subscriber, err = self.ctx:socket(SOCKET_OPTION)
	zassert(subscriber, err)
	self.subscriber = subscriber
	
	self.poller:add(self.subscriber, zmq.POLLIN, function()
		local msg, err = self.subscriber:recv()
		if msg ~= 'EVENT ' then
			print('Received in correct message')
			return
		end

		local msg, err = self.subscriber:recv()
		--print('EVENT SUB RECV:', msg)

		if msg and self.callback then
			local event, err = cjson.decode(msg)
			if event and type(event) == 'table' then
				self.callback(event)
			end
		end
	end)


	local REQ_SOCKET_OPTION = {
		zmq.REQ,
		linger   = 0,
		connect  = cfg.CONN_METHOD..(ip or cfg.SERVER_ENDPOINT)..cfg.REP_SERVER_PORT,
	}

	local client, err = self.ctx:socket(REQ_SOCKET_OPTION)
	zassert(client, err)
	self.client = client
	
	self.poller:add(self.client, zmq.POLLIN, function()
		local msg, err = self.client:recv()
		print('EVENT FIRE RESULT: '..msg)
	end)
end

--- Close connection 
--@treturn bool result
--@treturn string error
function class:close()
	if not self.client then
		return nil, "not connected"
	end

	if self.poller then
		self.poller:remove(self.client)
		self.poller:remove(self.subscriber)
	end
	self.client:close()
	self.client = nil
	self.subscriber:close()
	self.subscriber = nil
	return true
end

--- Send event to server
-- @tparam event event object
-- @treturn boolean ok
-- @treturn string error
function class:send(event)
	assert(event.src)
	assert(event.name)
	event.dest = event.dest or "ALL"
	-- We will not wait for event done
	return self.client:send(cjson.encode(event))
end

---@export
return {
	new = class.new
}
