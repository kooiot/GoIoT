--- TCP server wrapper
-- 

--- metatable class 
-- @type class
local class = {}

--- Open listen port
-- @tparam function cb callback when new connection is in
-- @treturn boolean result
-- @treturn string error
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

--- Register message handler function
-- @tparam string id the tcp client id
-- @tparam function func the callback function handles the message from specified client (by id)
-- @treturn boolean result
-- @treturn string error
function class:reg_msg_handler(id, func)
	if type(func) == 'function' then
		self.client_cbs[id] = func
		return true
	else
		return nil, "callback must be a function"
	end
end

--- Close client connection specified by client id
-- @tparam string id client id
function class:close_client(id)
	self.server:send(id, zmq.SNDMORE)
	self.server:send('')
end

--- Close tcp server 
-- @tparam boolean result
-- @tparam string error
function class:close()
	if not self.server then
		return nil, "not connected"
	end
	self.poller:remove(self.server)
	self.server:close()
	self.server = nil
end

--- Send message to specified client
-- @tparam string id client id
-- @tparam string msg message data
function class:send(id, msg)
	local r, err = self.server:send(id, zmq.SNDMORE)
	assert(r, err)
	return self.server:send(msg)
end

--- Module
local _M = {}

--- Module functions
-- @section

--- Create new server object
-- @tparam shared.app app application object from io.init()
-- @tparam string ip local binded ip
-- @tparam number port local binded port
_M.new = function(app, ip, port)
	local ctx = app.ctx
	local poller = app.poller
	assert(ctx and poller)
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
