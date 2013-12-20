--
-- Base interface for application
--    based on event system?
--

local zmq = require 'lzmq'
local event = require 'shared.event'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'

local mpft = require 'shared.app.mpft'
local empft = require 'shared.app.empft'

local class = {}

function class:log(level, cate, msg)
	-- TODO:
	print(level, cate, self.name, msg)
end

function class:firevent(dest, name, vars)
	local event = {src=self.name, dest=dest, name=name, vars=vars}
	--print('fire EVENT('..name..') to '..dest )
	return self.event:send(event)
end

local function send_err(server, err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	return server:send(rep_json)
end

function class:reg_request_handler(name, handler)
	if not self.mpft[name] then
		self.mpft[name] = handler
		return true
	end
	return false, 'MSG '..name..' already registered!!'
end

function class:on_request(msg)
	local json, err = cjson.decode(msg)
	if not json then
		print('JSON DECODE ERR', err)
		send_err(self.server, 'Unsupported message format')
		return
	end

	local msgtype = json[1]
	if self.mpft[msgtype] then
		self.mpft[msgtype](self, msg)
	else
		send_err(self.server, 'No handler for message '..msgtype)
	end
end

function class:reg_event_handler(name, handler)
	if not self.empft[name] then
		self.empft[name] = handler
		return true
	end
	return false, 'Event '..name..' already registered!!'
end

function class:on_event(event)
	--print('on_event', event.name, event.dest)
	if event.dest ~= self.name and event.dest ~= 'ALL' then
		print('Event is not for me')
		return
	end

	if self.empft[event.name] then
		self.empft[event.name](self, event)
	else
		print('No handler for event', event.name)
	end
end

function class:init()
	if self.port then
		local server, err = self.ctx:socket({
			zmq.REP,
			bind = "tcp://*:"..self.port
		})
		zassert(server, err)
		self.server = server

		self.poller:add(server, zmq.POLLIN, function()
			local msg, err = self.server:recv()
			if msg then
				self:on_request(msg)
			else
				print('ERR', err)
			end
		end)
	end

	self.event = event.C.new(self.ctx, self.poller, function (event) 
		self:on_event(event)
	end)
	self.event:open()

	local client, err = self.ctx:socket({
		zmq.REQ,
		connect = "tcp://localhost:5511"
	})
	zassert(client, err)
	self.monclient = client

	self.poller:add(client, zmq.POLLIN, function()
		local msg, err = self.monclient:recv()
		-- DO NOTHING on return
	end)

	self.on_start()
end

function class:send_notice()
	--print(os.date(), 'send notice')
	local req = {'notice', {name=self.name, port=self.port}}
	self.monclient:send(cjson.encode(req))
end

function class:run(ms)
	-- make sure there will no longger than 3 second blocked in poller
	if ms > 3000 then
		ms = 3000
	end
	if ms then
		self.poller:poll(ms)
	end

	local now = os.time()
	if now - self.monlast >= 2 then
		self.monlast = now + 1
		self:send_notice()
	end
end

function class:meta()
	return {
		name = self.name,
		port = self.port,
		version = {
			version = self.version,
			build = self.build,
			manufactor = self.manufactor,
		},
		web = self.web,
		app = self:app_meta()
	}
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

	-- handler functions
	obj.on_start = info.on_start or function() return true end
	obj.on_stop = info.on_stop or function() return true end
	obj.on_reload = info.on_reload or function() return true end
	obj.on_status = info.on_status or function() return false end

	-- app meta data enum interface
	obj.app_meta = info.app_meta or function() return {} end

	obj.ctx = info.ctx or zmq.context()
	obj.poller = info.poller or zpoller.new(3)
	obj.event = nil

	-- Message Process Function table for REQ/REP
	obj.mpft = {}
	for k,v in pairs(mpft) do
		obj.mpft[k] = v
	end

	-- Event Message Process Function table
	obj.empft = {}
	for k,v in pairs(empft) do
		obj.empft[k] = v
	end

	-- Monitor application interfaces, which will be updated automatically
	obj.monlast = 0
	obj.monclient = nil

	return setmetatable(obj, {__index = class})
end

return _M
