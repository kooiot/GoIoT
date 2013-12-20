require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'

local ctx = zmq.context()

local server, err = ctx:socket({zmq.STREAM, linger=0, bind="tcp://*:8000"})

zassert(server, err)

while(true) do
	local id, err = server:recv_len(256)
	if not id then
		print(err)
	else
		print(id)
	end

	local msg, err = server:recv()
	if msg then
		print(msg)
	else
		print(err)
	end

	--server:send(id, zmq.SNDMORE)
	server:send('back')
end

local class = {}

function class:open(ip, port)
	if self.server then
		return nil, "already binded"
	end
	if not ip or not port then
		return nil, "Incorrect parameters"
	end

	self.sip = ip
	self.sport = port

	local server, err = ctx:socket({zmq.STREAM, linger=0, bind="tcp://"..ip..":"..port})
	zassert(server, err)

	self.server = server

	self.poller:add(server, zmq.POLLIN, function()
		local id, err = self.server:recv_len(256)
		if not id then
			print(err)
		end
		if not self.client_cbs[id] then
			self.cb(self, id)
		end

		local msg, err = self.client:recv()
		if msg then
			local handler = self.client_cbs[id]
			if handler then
				handler(self, msg, id)
			end
		else
			print(err)
		end
	end)
end

function class:reg_msg_handler(id, func)
	if type(func) == 'function' then
		self.client_cbs[id] = func
		return true
	else
		return nil, "callback must be a function"
	end
end

function class:close_client(id)
	self.server:send(id, zmq.SNDMORE)
	self.server:send('')
end

function class:close()
	if not self.server then
		return nil, "not connected"
	end
	self.poller:remove(self.server)
	self.server:close()
	self.server = nil
end

function class:send(id, msg)
	local r, err = self.server:send(id, zmq.SNDMORE)
	assert(r, err)
	return self.server:send(msg)
end


local _M = {}
_M.new = function(ctx, poller, cb)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable({
		ctx = ctx,
		poller = poller,
		server=nil,
		client_cbs = {},
		sip = "*",
		sport = 4000,
		cb=cb},
		{__index=class})
end

