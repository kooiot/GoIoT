--
-- Base interface for application
--    based on event system?
--

local zmq = require 'lzmq'
local event = require 'shared.event'
local zpoller = require 'lzmq.poller'
local class = {}

function class:log(level, cate, msg)
	-- TODO:
	print(level, cate, self.name, msg)
end

function class:firevent(name, vals)
	vals.src = self.name
	print('EVENT', name, table.concat(vals))
end

function class:onRequest(msg)
	--TODO: handles the request
end

function class:onEvent(msg)
end

function class:init()
	if self.port then
		local server, err = self.ctx:socket({
			zmq.REP,
			connect = "tcp://*:"..self.port
		})
		zassert(server, err)
		self.server = server
	end
	self.poller:add(server, zmq.POLLIN, function()
		local msg, err = self.server:recv()
		if msg then
			self:onRequest(msg)
		else
			print('ERR', err)
		end
	end)

	self.event = event.C.new(self.ctx, function (event) 
		self:onEvent(event)
	end)
	self.event:open(obj.poller)
end

local _M = {}

function _M.new(info)
	local info = info or {}
	local obj = {}
	obj.version = info.version or '0.1'
	obj.build = info.build or '000001'
	obj.name = info.name or ('name'..os.time()..math.random(os.time()))
	obj.web = info.web or false -- the application pack has its own web pages
	obj.manufactor = info.manufactor or 'OpenGate'
	obj.port = info.port
	obj.server = nil

	obj.onStart = info.onStart or function() return true end
	obj.onStop = info.onStop or function() return true end
	obj.onReload = info.onReload or function() return true end
	obj.onStatus = info.onStatus() or function() return false end

	obj.ctx = info.ctx or zmq.context()
	obj.poller = info.poller or zpoller:new()
	obj.event = nil
	return setmetatable(obj, {__index = class})
end

