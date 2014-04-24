--- Logger server module
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'

local IPC = "ipc:///tmp/og.log.ipc"
--local IPC = "tcp://*:5593"

--- Server metatable
-- @type class
local class = {}

--- Create the server object
-- @tparam lzmq.context ctx
-- @tparam lzmq.poller poller
-- @tparam function cb callback function
-- @treturn class object
function class.new(ctx, poller, cb)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new()
	return setmetatable(
	{
		ctx = ctx,
		poller = poller,
		server = nil,
		callback = cb,
	}, {__index = class})
end

--- Open logger server
-- @raise asserts when zeromq bind failure
function class:open()
	local SOCKET_OPT = {
		zmq.PULL,
		bind = IPC,
	}
	local server, err = self.ctx:socket(SOCKET_OPT)
	zassert(server, err)
	self.server = server

	self.poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		if msg then
			local log, err = cjson.decode(msg)
			if log and self.callback then
				self.callback(log)
			end
			if not log then
				print('ERR', err)
			end
		end
	end)
end

--- Close the server
--
function class:close()
	if not server then
		return nil, "not initialized"
	end
	if self.poller then
		self.poller:remove(self.server)
	end
	
	self.server:close()
	self.server = nil
	return true
end

--- Module function
-- @section

--- Create new server object
-- @function module
-- @see class.new
return function(ctx, poller, cb)
	if not cb then
		return nil, "need have callback as the par"
	end
	return class.new(ctx, poller, cb)
end

