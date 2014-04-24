--- Event classes
-- includes C(client) and S(server)
-- @author Dirk Chang
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'

local CONN_METHOD = "tcp://"
local PUB_SERVER_PORT = ":5519"
local REP_SERVER_PORT = ":5518"
local SERVER_ENDPOINT = "localhost"


--- Event Object Type
-- @table event
-- @field src the event source
-- @field name the event's name
-- @field dest the target event receiver name, nil will send to ALL

--- Callback function
-- @function callback
-- @tparam event event

--- A client class
-- @type C
local C = {}

--- Create a new client object
-- @tparam lzmq.context ctx 
-- @tparam lzmq.poller poller 
-- @tparam callback cb callback function
-- @treturn C a new server object
function C.new(ctx, poller, cb)
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
	}, {__index = C})
end

--- Open connection 
-- @tparam string ip remote ip
-- @treturn nil
-- @raise assert on binding failure
function C:open(ip)

	local SOCKET_OPTION = {
		zmq.SUB,
		subscribe = 'EVENT ',
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..PUB_SERVER_PORT,
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
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..REP_SERVER_PORT,
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
function C:close()
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
function C:send(event)
	assert(event.src)
	assert(event.name)
	event.dest = event.dest or "ALL"
	-- We will not wait for event done
	return self.client:send(cjson.encode(event))
end

--- A server class
-- @type S
local S = {}

--- Create a new server object
-- @tparam lzmq.context ctx
-- @tparam lzmq.poller poller
-- @treturn S a new server object
function S.new(ctx, poller)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable(
	{
		ctx = ctx,
		poller = poller,
		server = nil,
		publisher = nil,
		option = nil,
	}, {__index = S})
end


--- Open the service
-- @tparam string ip local ip address, nil or '*' for any ethernet address
-- @treturn nil
-- @raise assert on binding failure
function S:open(ip)
	local ip = ip or "*"
	local SOCKET_OPTION = {
		zmq.PUB,
		bind  = CONN_METHOD..ip..PUB_SERVER_PORT,
	}

	local publisher, err = self.ctx:socket(SOCKET_OPTION)
	zassert(publisher, err)

	self.publisher = publisher

	--[[
	self.poller:add(self.publisher, zmq.POLLIN, function()
	end)
	]]--

	local REP_SOCKET_OPT = {
		zmq.REP,
		bind = CONN_METHOD..ip..REP_SERVER_PORT,
	}
	local server, err = self.ctx:socket(REP_SOCKET_OPT)
	zassert(server, err)
	self.server = server

	self.poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		if msg then
			--print('EVENT RECV', msg)
			self.publisher:send('EVENT ', zmq.SNDMORE)
			self.publisher:send(msg)
			--print('EVENT PUB DONE')
		else
			print('ERR', err)
		end
		-- tell the client
		self.server:send('DONE')
	end)
end

--- Close the server
-- @return ok result
-- @treturn string error error message
function S:close()
	if not server then
		return nil, "not initialized"
	end
	if self.poller then
		self.poller:remove(self.server)
		self.poller:remove(self.publisher)
	end
	
	self.server:close()
	self.server = nil
	self.publisher:close()
	self.publisher = nil
	return true
end

---@export
return  {
	C = C,
	S = S,
}
