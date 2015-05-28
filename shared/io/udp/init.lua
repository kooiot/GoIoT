--- UDP wrapper module
-- Wrap the luasocket udp with copas for multiple-threading
--
local socket = require 'socket'
local copas = require 'copas'

--- metatable class
-- @type class
local class = {}

--- Open connection
-- @tparam function cb callback function when receiving data
-- @tparam number port the local binding port for receiving message (as a server)
-- @treturn boolean result
-- @treturn string error
function class:open(cb)
	self.cb = cb
	local server = socket.udp()
	if self.port then
		server:setsockname(self.ip or "*", self.port)
	end
	server:setoption('broadcast', true)

	function handler(skt)
		skt = copas.wrap(skt)
		print("UDP connection handler")

		while not self.app.closed() do
			--print("receiving...")
			local s, ip, port  = skt:receivefrom(2048)
			if not s then
				print("Receive error: ", ip)
				return
			end

			--print("Received data, bytes:" , #s)
			if self.cb then
				self.cb(s, ip, port)
			end
		end
	end
	self.skt = server
	return self.app:add_server(server, handler, 1)
end

function class:send(s, ip, port)
	if not self.skt then
		return nil, "not opened"
	end
	local port = port or self.port
	return self.skt:sendto(s, ip, port)
end

--- Module
local _M = {}

--- Module functions
-- @section

--- Create new udp server object
-- @tparam shared.app app application object from io.init()
-- @tparam string ip local binded ip (nil for "*")
-- @tparam number port local binded port
_M.new = function(app, ip, port)
	return setmetatable({
		app = app,
		ip = ip,
		port = port,
		skt = nil,
		cb = nil},
		{__index = class})
end

return _M
