require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'

local class = {}


function hex_raw(raw)
	if not raw then
		return ""
	end
	if (string.len(raw) > 1) then
		return string.format("%02X", string.byte(raw:sub(1, 1)))..hex_raw(raw:sub(2))
	else
		return string.format("%02X", string.byte(raw:sub(1, 1)))
	end
end

function class:on_rev(msg)
	assert(self)
	print('on_rev', hex_raw(msg))
	self.buf = self.buf..msg
end

function class:open(cb)
	if self.client then
		return nil, "already connected"
	end

	self.cb = cb or self.on_rev

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

function class:read(check, timeout)

	local ztimer = require 'lzmq.timer'
	local timer = ztimer.monotonic(timeout)
	timer:start()

	local abort = false
	while not abort and timer:rest() > 0 do
		if string.len(self.buf) > 0 then
			local r, len = check(self.buf)
			if r then
				local msg = string.sub(self.buf, 1, len + 1)
				self.buf = string.sub(self.buf, len + 1)
				return msg
			end
		end
		abort = coroutine.yield(false, 100)
	end
	return nil, timeout
end

local _M = {}
_M.new = function(ctx, poller, sip, sport)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable({
		ctx = ctx,
		poller = poller,
		buf = '',
		client=nil,
		client_id = nil,
		sip = sip or "127.0.0.1",
		sport = sport or 4000,
		cb=nil},
		{__index=class})
end

return _M
