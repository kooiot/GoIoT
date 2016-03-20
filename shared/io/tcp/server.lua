--- TCP server wrapper
-- 

--- metatable class 
-- @type class
local class = {}

--- Open listen port
-- @tparam string host local binded ip (default is "*")
-- @tparam number port local binded port (default is 4000)
-- @tparam function callback Callback when new connection is in
-- @treturn boolean result
-- @treturn string error
function class:open(host, port, callback)
	if self._server then
		return nil, "already binded"
	end

	if not callback then
		return nil, "No callback"
	end
	self._sip = host or self._sip 
	self._port = port or self._port
	self._callbak = callback

	local server, err = ctx:socket({zmq.STREAM, linger=0, bind="tcp://"..self._sip..":"..self._sport})
	zassert(server, err)

	self._server = server

	self._poller:add(server, zmq.POLLIN, function()
		local id, err = server:recv_len(256)
		if not id then
			print(err)
		end
		if not self._client_cbs[id] then
			self._callback(self, id)
		end

		local msg, err = self.client:recv()
		if msg then
			local handler = self._client_cbs[id]
			if handler then
				handler(self, msg, id)
			end
		else
			print(err)
		end
	end)
	return true
end

--- Register message handler function
-- @tparam string id the tcp client id
-- @tparam function func the callback function handles the message from specified client (by id)
-- @treturn boolean result
-- @treturn string error
function class:reg_msg_handler(id, func)
	if type(func) == 'function' then
		self._client_cbs[id] = func
		return true
	else
		return nil, "callback must be a function"
	end
end

--- Close client connection specified by client id
-- @tparam string id client id
function class:close_client(id)
	local server = self._server
	server:send(id, zmq.SNDMORE)
	server:send('')
end

--- Close tcp server 
-- @tparam boolean result
-- @tparam string error
function class:close()
	local server = self._server
	if not server then
		return nil, "not connected"
	end
	self._poller:remove(server)
	server:close()
	self._server = nil
end

--- Send message to specified client
-- @tparam string id client id
-- @tparam string msg message data
function class:send(id, msg)
	local server = self._server
	local r, err = server:send(id, zmq.SNDMORE)
	assert(r, err)
	return server:send(msg)
end

--- Module
local _M = {}

--- Module functions
-- @section

--- Create new server object
-- @tparam shared.app app application object from io.init()
_M.new = function(app)
	local ctx = app.ctx
	local poller = app.poller
	assert(ctx and poller)
	return setmetatable({
		_ctx = ctx,
		_poller = poller,
		_server=nil,
		_client_cbs = {},
		_sip = "*",
		_sport = 4000,
		_callback=nil},
		{__index=class})
end

return _M
