--- Event server classes
-- @author Dirk Chang
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'

local cfg = require 'shared.event.cfg'

--- A server class
-- @type class
local class = {}

--- Create a new server object
-- @tparam lzmq.context ctx
-- @tparam lzmq.poller poller
-- @treturn class a new server object
function class.new(ctx, poller)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable(
	{
		ctx = ctx,
		poller = poller,
		server = nil,
		publisher = nil,
		option = nil,
	}, {__index = class})
end


--- Open the service
-- @tparam string ip local ip address, nil or '*' for any ethernet address
-- @treturn nil
-- @raise assert on binding failure
function class:open(ip)
	local ip = ip or "*"
	local SOCKET_OPTION = {
		zmq.PUB,
		bind  = cfg.CONN_METHOD..ip..cfg.PUB_SERVER_PORT,
	}

	local publisher, err = self.ctx:socket(SOCKET_OPTION)
	zassert(publisher, err)

	self.publisher = publisher

	--[[
	self.poller:add(self.publisher, zmq.POLLIN, function()
	end)
	]]--

	local REP_SOCKET_OPT = {
		zmq.REP,
		bind = cfg.CONN_METHOD..ip..cfg.REP_SERVER_PORT,
	}
	local server, err = self.ctx:socket(REP_SOCKET_OPT)
	zassert(server, err)
	self.server = server

	self.poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		if msg then
			--print('EVENT RECV', msg)
			self.publisher:send('EVENT ', zmq.SNDMORE)
			self.publisher:send(msg)
			--print('EVENT PUB DONE')
		else
			print('ERR', err)
		end
		-- tell the client
		self.server:send('DONE')
	end)
end

--- Close the server
-- @return ok result
-- @treturn string error error message
function class:close()
	if not server then
		return nil, "not initialized"
	end
	if self.poller then
		self.poller:remove(self.server)
		self.poller:remove(self.publisher)
	end
	
	self.server:close()
	self.server = nil
	self.publisher:close()
	self.publisher = nil
	return true
end

---@export
return  {
	new = class.new,
}
