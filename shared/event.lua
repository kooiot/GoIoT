
require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'

local CONN_METHOD = "tcp://"
local PUB_SERVER_PORT = ":5519"
local REP_SERVER_PORT = ":5418"
local SERVER_ENDPOINT = "localhost"

local _CLIENT = {}

function _CLIENT:open(poller, ip)
	self.poller = poller

	local SOCKET_OPTION = {
		zmq.SUB,
		linger   = 0,
		connect  = CONN_METHOD..(endpoint or SERVER_ENDPOINT)..PUB_SERVER_PORT,
	}

	local subscriber, err = self.ctx:socket(SOCKET_OPTION)
	zassert(subscriber, err)
	self.subscriber = subscriber
	
	self.poller:add(self.subscriber, zmq.POLLIN, function()
		print('EVENT SUB RECV')
		if self.callback then
			local msg, err = self.subscriber:recv()
			if msg then
				local event, err = cjson.decode(msg)
				if event and type(event) == 'table' then
					if event[1] == 'EVENT' then
						self.callback(event[2])
					end
				end
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

function _CLIENT:close()
	if self.poller then
		self.poller:remove(self.client)
		self.poller = nil
	end
	self.client:close()
	self.client = nil
end

function _CLIENT:send(event)
	assert(event.src)
	assert(event.name)
	event.dest = event.dest or "ALL"
	local msg = {
		"EVENT",
		event,
	}
	-- We will not wait for event done
	return self.client:send(cjson.encode(msg))
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
		bind  = CONN_METHOD..ip..PUB_SERVER_PORT,
	}

	local publisher, err = self.ctx:socket(SOCKET_OPTION)
	zassert(publisher, err)

	self.publisher = publisher

	local REP_SOCKET_OPT = {
		zmq.REP,
		bind = CONN_METHOD..ip..REP_SERVER_PORT,
	}
	local server, err = self.ctx:socket(REP_SOCKET_OPT)
	zassert(server, err)
	self.server = server

	self.poller = poller
	poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		print('EVENT RECV', msg)
		if msg then
			self.publisher:send(msg)
		else
			print('ERR', err)
		end
		print('EVENT PUB DONE')
		-- tell the client
		self.server:send('DONE')
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
	}, {__index = _SERVER})
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
