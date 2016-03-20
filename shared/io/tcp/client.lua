--- TCP wrapper module
-- Wrap the zmq raw socket
--

--- metatable class 
-- @type class
local class = {}

--- Open connection
-- @tparam function callback Callback function when receiving data
-- @treturn boolean result
-- @treturn string error
function class:open(callback)
	if self._client then
		return nil, "already connected"
	end

	if not callback then
		return nil, "no callback function"
	end
	self._callback = callback

	--print(require('shared.util.PrettyPrint')({zmq.STREAM, linger=0, identity='abcde', connect="tcp://"..self._sip..":"..self._sport}))

	local client, err = self._ctx:socket({
		zmq.STREAM,
		linger=0,
		identity='abcde',
		connect="tcp://"..self._sip..":"..self._sport
	})
	zassert(client, err)

	local id, err = client:getopt_str(zmq.IDENTITY)
	zassert(id, err)
	self._client_id = id

	self._client = client 

	self._poller:add(client, zmq.POLLIN, function()
		local id, err = client:recv_len(256)
		if not id then
			print(err)
		end

		local msg, err = client:recv()
		if msg then
			if self._callback then
				self._callback(self, msg)
			end
		else
			print(err)
		end
	end)
	return true
end

--- Close the tcp connection
-- @treturn boolean result
-- @treturn string error 
function class:close()
	if not self._client then
		return nil, "not connected"
	end
	self._poller:remove(self._client)
	self._client:close()
	self._client = nil
	return true
end

--- Send message to peer
-- @tparam string msg the message which will sent to peer
-- @treturn boolean
-- @treturn error
function class:send(msg)
	local r, err = self._client:send(self._client_id, zmq.SNDMORE)
	assert(r, err)
	return self._client:send(msg)
end

--- Module
local _M = {}

--- Module functions
-- @section

--- Create new tcp client object
-- @tparam shared.app app application object (returns from io.init())
-- @tparam string sip server ip
-- @tparam number sport server listen port
-- @treturn class
_M.new = function(app, sip, sport)
	local ctx = app.ctx
	local poller = app.poller
	assert(ctx and poller)
	return setmetatable({
		_ctx = ctx,
		_poller = poller,
		_client=nil,
		_client_id = nil,
		_sip = sip or "127.0.0.1",
		_sport = sport or 4000,
		_callback=nil},
		{__index=class})
end

return _M
