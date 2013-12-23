require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'

local class = {}

function class:open(cb)
	if self.server then
		return nil, "already binded"
	end

	if not cb then
		return nil, "No callback"
	end
	self.cb = cb

	local server, err = ctx:socket({zmq.STREAM, linger=0, bind="tcp://"..self.sip..":"..self.sport})
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
	return true
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
_M.new = function(ctx, poller, ip, port)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable({
		ctx = ctx,
		poller = poller,
		server=nil,
		client_cbs = {},
		sip = ip or "*",
		sport = port or 4000,
		cb=nil},
		{__index=class})
end

return _M
