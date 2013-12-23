require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'

local class = {}

function class:open(cb)
	if self.client then
		return nil, "already connected"
	end

	if not cb then
		return nil, "No callback"
	end
	self.cb = cb

	--print(require('shared.PrettyPrint')({zmq.STREAM, linger=0, identity='abcde', connect="tcp://"..self.sip..":"..self.sport}))

	local client, err = self.ctx:socket({zmq.STREAM, linger=0, identity='abcde', connect="tcp://"..self.sip..":"..self.sport})
	zassert(client, err)

	local id, err = client:getopt_str(zmq.IDENTITY)
	zassert(id, err)
	self.client_id = id

	self.client = client 

	self.poller:add(client, zmq.POLLIN, function()
		local id, err = self.client:recv_len(256)
		if not id then
			print(err)
		end

		local msg, err = self.client:recv()
		if msg then
			if self.cb then
				self.cb(self, msg)
			end
		else
			print(err)
		end
	end)
	return true
end

function class:close()
	if not self.client then
		return nil, "not connected"
	end
	self.poller:remove(self.client)
	self.client:close()
	self.client = nil
end

function class:send(msg)
	local r, err = self.client:send(self.client_id, zmq.SNDMORE)
	assert(r, err)
	return self.client:send(msg)
end

local _M = {}
_M.new = function(ctx, poller, sip, sport)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable({
		ctx = ctx,
		poller = poller,
		client=nil,
		client_id = nil,
		sip = sip or "127.0.0.1",
		sport = sport or 4000,
		cb=nil},
		{__index=class})
end

return _M
