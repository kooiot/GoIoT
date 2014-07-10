---
-- Base interface for application

local zmq = require 'lzmq'
local event = require 'shared.event'
local zpoller = require 'lzmq.poller'
local cjson = require 'cjson.safe'

local mpft = require 'shared.app.mpft'
local empft = require 'shared.app.empft'

local _ver = require '_ver'

--- Application class
-- @type class
local class = {}

--- Fire event to target
-- @tparam string dest the event target application
-- @tparam string name the event name
-- @tparam table vars the varaiables used by this event
-- @return ok
-- @treturn string error
function class:firevent(dest, name, vars)
	local event = {src=self.name, dest=dest, name=name, vars=vars}
	--print('fire EVENT('..name..') to '..dest )
	return self.event:send(event)
end

--- Send error reply
-- @tparam Server server the server object
-- @tparam string err the error message
-- @return ok
-- @treturn string error
local function send_err(server, err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	return server:send(rep_json)
end

--- Register request handler
-- @tparam stirng name the request method name
-- @tparam function handler the request handler function
-- @return ok
-- @treturn string error
function class:reg_request_handler(name, handler)
	if not self.mpft[name] then
		self.mpft[name] = handler
		return true
	end
	return false, 'MSG '..name..' already registered!!'
end

--- Request Handler Internal helper
-- @local
-- @tparam string msg string in json
-- @treturn nil
function class:on_request(msg)
	local json, err = cjson.decode(msg)
	if not json then
		print('JSON DECODE ERR', err)
		send_err(self.server, 'Unsupported message format')
		return
	end

	local msgtype = json[1]
	if self.mpft[msgtype] then
		self.mpft[msgtype](self, json[2])
	else
		send_err(self.server, self.name..' has no handler for message '..msgtype)
	end
end

--- Register event handler
-- @tparam stirng name the event name
-- @tparam function handler the event handler function
-- @return ok
-- @treturn string error
function class:reg_event_handler(name, handler)
	if not self.empft[name] then
		self.empft[name] = handler
		return true
	end
	return false, 'Event '..name..' already registered!!'
end

--- Event Handler Internal helper
-- @local
-- @tparam string event message string in json
-- @treturn nil
function class:on_event(event)
	print('on_event', event.name, event.dest)
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

--- Initialize the application object
-- @raise asserts on binding failure
function class:init()
	if self.port then
		local server, err = self.ctx:socket({
			zmq.REP,
		})
		zassert(server, err)
		if self.port_retry ~= 0 and server.bind_to_random_port then
			self.port, err = server:bind_to_random_port('tcp://*', self.port, 128)
			zassert(self.port, err)
		else
			zassert(server:bind('tcp://*:'..self.port))
		end
		self.server = server

		self.poller:add(server, zmq.POLLIN, function()
			local msg, err = self.server:recv()
			if msg then
				print(os.date(), 'Received request message')
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

	-- Send the notice once before calling on_start, because it may take a few seconds for application initialization
	self:send_notice()

	if self.handlers.on_start then
		self.handlers.on_start(self)
	end
end

--- Send notice to monitor services tells it we are aliving
-- @tparam string typ the notice type, current only support to be nil or 'exit'
function class:send_notice(typ)
	if not self.closed then
		--print(os.date(), 'send notice')
		local req = {'notice', {name=self.name, desc=self.desc, port=self.port, typ=typ}}
		self.monclient:send(cjson.encode(req))
	end
end

--- Application run loop
-- @tparam number ms the maxmium time running inside this loop
-- @treturn nil
function class:run(ms)
	if self.closed then
		return
	end

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

--- Get application meta table
-- @treturn table the meta table
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
		app = self.handlers.app_meta(self)
	}
end

--- Application exit/close/destroy
--  Call this when application is closing
function class:close()
	self:send_notice('exit')
	self.closed = true
end

--- Module functions
-- @section

--- Application infomation table
-- @table Info
-- @field version Version number 
-- @field build Version build number
-- @field name Appliation name
-- @field desc Application description
-- @field web (deleted)
-- @field manufactor Application manufactor
-- @field port Application management service port
-- @field port_retry Whether retry with port inscrease to solve the bind failures
-- @field handlers The request handlers table
-- @field ctx lzmq.context
-- @field poller lzmq.poller

--- Create new applicatoin instance
-- @tparam Info info the application information table
-- @tparam table handlers the list of handler functions
-- @treturn class the application instance
-- @raise asserts failures for binding port
local function new(info, handlers)
	assert(info.name, 'App port must be specified')

	local obj = {}
	obj.version = _ver.version or '0.1'
	obj.build = _ver.build or '000001'
	obj.name = info.name or _ver.name 
	obj.desc = _ver.desc or 'unknown application'
	obj.web = _ver.web or false -- the application pack has its own web pages
	obj.manufactor = _ver.manufactor or 'OpenGate'
	obj.port = info.port or 5515
	obj.port_retry = info.no_port_retry and 0 or 128
	obj.server = nil

	-- handler functions
	obj.handlers = handlers or {}

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

	-- Closed flag
	obj.closed = false

	return setmetatable(obj, {__index = class})
end

---
-- @export
return {
	new = new
}

