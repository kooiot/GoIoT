--- UDP wrapper module
-- Wrap the luasocket udp with copas for multiple-threading
--
local socket = require 'socket'
local copas = require 'copas'

--- metatable class
-- @type class
local class = {}

--- Open connection
-- @tparam string host local binded ip (nil for "*")
-- @tparam number port local binded port (nil for 4000)
-- @tparam function callback callback function when receiving data
-- @tparam number port the local binding port for receiving message (as a server)
-- @treturn boolean result
-- @treturn string error
function class:open(host, port, callback)
	self._host = host or self._host
	self._port = port or self._port
	self._callback = callabck
	assert(self._host and self._port and callback)

	local server = socket.udp()
	server:setsockname(self._host, self._port)

	server:setoption('broadcast', true)

	function handler(skt)
		skt = copas.wrap(skt)
		print("UDP connection handler")

		while not self._app:closed() do
			--print("receiving...")
			local s, ip, port  = skt:receivefrom(2048)
			if not s then
				print("Receive error: ", ip)
				return
			end

			--print("Received data, bytes:" , #s)
			if callback then
				callback(s, ip, port)
			end
		end
	end
	self._server = server
	return self.app:add_server(server, handler, 1)
end

function class:send(s, ip, port)
	local server = self._server
	if not server then
		return nil, "not opened"
	end
	local port = port or self.port
	return server:sendto(s, ip, port)
end

--- Module
local _M = {}

--- Module functions
-- @section

--- Create new udp server object
-- @tparam shared.app app application object from io.init()
_M.new = function(app)
	return setmetatable({
		_app = app,
		_host = "*",
		_port = 4000,
		_server = nil,
		_callback = nil},
		{__index = class})
end

return _M
