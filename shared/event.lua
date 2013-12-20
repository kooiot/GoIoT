
require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'

local CONN_METHOD = "tcp://"
local PUB_SERVER_PORT = ":5519"
local REP_SERVER_PORT = ":5418"
local SERVER_ENDPOINT = "localhost"

local _CLIENT = {}

function _CLIENT:open(ip)

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
		--print('EVENT FIRE RESULT: '..msg)
	end)
end

function _CLIENT:close()
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

function _CLIENT:send(event)
	assert(event.src)
	assert(event.name)
	event.dest = event.dest or "ALL"
	-- We will not wait for event done
	return self.client:send(cjson.encode(event))
end

function _CLIENT.new(ctx, poller, cb)
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
	}, {__index = _CLIENT})
end

local _SERVER = {}

function _SERVER:open(ip)
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

function _SERVER.new(ctx)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable(
	{
		ctx = ctx,
		server = nil,
		publisher = nil,
		option = nil,
	}, {__index = _SERVER})
end

function _SERVER:close()
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

return  {
	C = _CLIENT,
	S = _SERVER
}
