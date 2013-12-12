
require "shared.zhelpers"
local zmq = require "lzmq"

local CONN_METHOD = "tcp://"
local SERVER_PORT = ":5454"
local SERVER_ENDPOINT = "localhost"

local _CLIENT = {}

function _CLIENT:open(poller, ip)
	local SOCKET_OPTION = {
		zmq.SUB,
		linger   = 0,
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..SERVER_PORT,
	}

	local client, err = self.ctx:socket(SOCKET_OPTION)
	zassert(client, err)

	self.client = client
	self.option = SOCKET_OPTION
	self.poller = poller
	
	poller:add(self.client, zmq_POLLIN, function()
		if self.callback then
			local r, err = self.client:recv()
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

function _CLIENT.new(ctx, cb)
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx = ctx,
		client = nil,
		option = nil,
		callback = cb,
	}, {__index = _CLIENT})
end

local _SERVER = {}

function _SERVER:open(ip)
	local ip = ip or "*"
	local SOCKET_OPTION = {
		zmq.PUB,
		linger   = 0,
		connect  = CONN_METHOD..ip..SERVER_PORT,
	}

	local server, err = self.ctx:socket(SOCKET_OPTION)
	zassert(server, err)

	self.server = server
	self.option = SOCKET_OPTION
end

function _SERVER.new(ctx)
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx = ctx,
		server = nil,
		option = nil,
	}, {__index = _CLIENT})
end

function _SERVER:send(msg, option)
	self.server:send(msg, option)
end

function _SERVER:close()
	self.server:close()
	self.server = nil
end

return  {
	C = _CLIENT,
	S = _SERVER
}
