
require "shared.zhelpers"
local zmq = require "lzmq"

local CONN_METHOD = "tcp://"
local PUB_SERVER_PORT = ":5519"
local REP_SERVER_PORT = ":5418"
local SERVER_ENDPOINT = "localhost"

local _CLIENT = {}

function _CLIENT:open(poller, ip)
	local SOCKET_OPTION = {
		zmq.SUB,
		linger   = 0,
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..PUB_SERVER_PORT,
	}

	local subscriber, err = self.ctx:socket(SOCKET_OPTION)
	zassert(subscriber, err)
	self.subscriber = subscriber

	local REQ_SOCKET_OPTION = {
		zmq.REQ,
		linger   = 0,
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..REP_SERVER_PORT,
	}

	local client, err = self.ctx:socket(REQ_SOCKET_OPTION)
	zassert(client, err)
	self.client = client

	self.poller = poller
	
	poller:add(self.subscriber, zmq_POLLIN, function()
		if self.callback then
			local r, err = self.subscriber:recv()
			if r then
				self.callback(r)
			end
		end
	end)
end

function _CLIENT:close()
	if self.poller then
		self.poller:remove(self.client)
		self.poller = nil
	end
	self.client:close()
	self.client = nil
end

function _CLIENT:send(msg, option)
	self.client:send(msg, option)
end

function _CLIENT.new(ctx, cb)
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx = ctx,
		client = nil,
		subscriber = nil,
		option = nil,
		callback = cb,
	}, {__index = _CLIENT})
end

local _SERVER = {}

function _SERVER:open(poller, ip)
	assert(poller)
	local ip = ip or "*"
	local SOCKET_OPTION = {
		zmq.PUB,
		linger   = 0,
		connect  = CONN_METHOD..ip..PUB_SERVER_PORT,
	}

	local publisher, err = self.ctx:socket(SOCKET_OPTION)
	zassert(publisher, err)

	self.publisher = publisher

	local REP_SOCKET_OPT = {
		zmq.REP,
		linger = 0,
		connect = CONN_METHOD..ip..REP_SERVER_PORT,
	}
	local server, err = self.ctx:socket(REP_SOCKET_OPT)
	zassert(server, err)
	self.server = server

	self.poller = poller
	poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		if msg then
			self.publisher:send(msg)
		else
			print('ERR', err)
		end
	end)
end

function _SERVER.new(ctx)
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx = ctx,
		server = nil,
		publisher = nil,
		option = nil,
	}, {__index = _CLIENT})
end

function _SERVER:close()
	self.server:close()
	self.server = nil
	self.publisher:close()
	self.publisher = nil
end

return  {
	C = _CLIENT,
	S = _SERVER
}
