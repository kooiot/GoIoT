---
-- Base interface for application

local zmq = require 'lzmq'
local event_client = require 'shared.event.client'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local copas = require 'copas'

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
	return self._event:send({
		src=self._name,
		dest=dest,
		name=name,
		vars=vars
	})
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
	local mpft = self._mpft or {}
	if not _mpft[name] then
		mpft[name] = handler
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
		send_err(self._server, 'Unsupported message format')
		return
	end

	local msgtype = json[1]
	local mpft = self._mpft or {}
	if mpft[msgtype] then
		mpft[msgtype](self, json[2])
	else
		send_err(self._server, self._name..' has no handler for message '..msgtype)
	end
end

--- Register event handler
-- @tparam stirng name the event name
-- @tparam function handler the event handler function
-- @return ok
-- @treturn string error
function class:reg_event_handler(name, handler)
	local empft = self._empft or {}
	if not empft[name] then
		empft[name] = handler
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
	if event.dest ~= self._name and event.dest ~= 'ALL' then
		print('Event is not for me')
		return
	end

	local empft = self._empft or {}
	if empft[event.name] then
		empft[event.name](self, event)
	else
		print('No handler for event', event.name)
	end
end

--- Initialize the application object
-- @raise asserts on binding failure
function class:init()
	if self._port then
		local server, err = self._ctx:socket({
			zmq.REP,
		})
		zassert(server, err)
		if self._port_retry ~= 0 and server.bind_to_random_port then
			self._port, err = server:bind_to_random_port('tcp://127.0.0.1', self._port, 128)
			zassert(self._port, err)
		else
			zassert(server:bind('tcp://127.0.0.1:'..self._port))
		end
		self._server = server

		self._poller:add(server, zmq.POLLIN, function()
			local msg, err = server:recv()
			if msg then
				print(os.date(), 'Received request message')
				self:on_request(msg)
			else
				print('ERR', err)
			end
		end)
	end

	self._event = event_client.new(self._ctx, self._poller, function (event) 
		self:on_event(event)
	end)
	self._event:open()

	local client, err = self._ctx:socket({
		zmq.REQ,
		connect = "tcp://localhost:5511"
	})
	zassert(client, err)
	self._monclient = client

	self._poller:add(client, zmq.POLLIN, function()
		local msg, err = self._monclient:recv()
		-- DO NOTHING on return
	end)

	-- Send the notice once before calling handler.start, because it may take a few seconds for application initialization
	self:send_notice()

	-- Added default tasks
	self:add_thread(function()
		local monlast = 0
		while not self._closed do
			self:sleep(0)
			-- Sent out notice
			local now = os.time()
			if now - monlast >= 2 then
				monlast = now + 1
				self:send_notice()
			end
			-- Let the zmq run
			self._poller:poll(50)
		end

	end)

	if self._handlers.start then
		self._handlers.start(self)
	end
end

--- Send notice to monitor services tells it we are aliving
-- @tparam string typ the notice type, current only support to be nil or 'exit'
function class:send_notice(typ)
	if not self._closed then
		--print(os.date(), 'send notice')
		local req = {'notice', {name=self._name, desc=self._desc, port=self._port, typ=typ}}
		self._monclient:send(cjson.encode(req))
	end
end

--- Application run loop
-- This function will block until app:close() been called
-- @treturn nil
function class:run()
	while not self._closed do
		local r, err = copas.step(1)
		if r == nil then
			return nil, err
		end
	end
end

--- Get application meta table
-- @treturn table the meta table
function class:meta()
	return {
		name = self._name,
		desc = self._desc,
		port = self._port,
		version = self._ver,
		app = self.handlers.app_meta(self)
	}
end

--- Application exit/close/destroy
--  Call this when application is closing
function class:close()
	self:send_notice('exit')
	self._closed = true
end

--- Add thread
-- Call this adding your own thread
-- @tparam function task task main function
function class:add_thread(task)
	return copas.addthread(task)
end

--- Add server
-- call this adding your own server
-- @tparam socket server LuaSocket server socket created using socket.bind()
-- @tparam function handler function that receives a LuaSocket client socket and handles the communication with that client
-- @tparam number timeout (optional) the timeout for blocking I/O in seconds. The handler will be executed in parallel with other threads and the registered handlers as long as it uses the Copas socket functions.
function class:add_server(server, handler, timeout)
	copas.addserver(server, handler, timeout)
	return true
end

--- Sleep function which will pause current thread
-- @tprarm number sec seconds to pause, if sec is less than 1, we will using timer for ms sleep
-- @treturn boolean whether the application closed
function class:sleep(sec)
	local sec = sec or 0
	if sec == 0 then
		copas.sleep(0)
		return self._closed
	end

	if sec < 1 and sec >= 0.001 then
		local timer = ztimer.monotonic(sec * 1000)
		timer:start()
		while timer:rest() > 0 do
			copas.sleep(0)
		end
	else
		copas.sleep(sec)
	end

	return self._closed
end

-- Get system time in ms
-- @return number ms
function class:time()
	return ztimer.absolute_time()
end

--- Check whether application is closing
-- @treturn boolean whether the application closed
function class:closed()
	return self._closed
end

--- Module functions
-- @section

--- Application infomation table
-- @table Info
-- @field version Version number 
-- @field build Version build number
-- @field name Appliation name
-- @filed desc Application description
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

	local mpft = require 'shared.app.mpft'
	local empft = require 'shared.app.empft'
	local _ver = require '_ver' or {}

	local obj = {
		zmq = zmq,
		zpoller = zpoller,
		cjson = cjson,
		event = event,
	}
	obj._ver = {
		version = _ver.version or '0.1',
		build = _ver.build or '000001',
		manufactor = _ver.manufactor or 'KooIoT'
	}
	obj._name = info.name or _ver.name 
	obj._desc = info.desc or _ver.desc or 'unknown application'
	obj._port = info.port or 5515
	obj._port_retry = info.no_port_retry and 0 or 128
	obj._server = nil

	-- handler functions
	obj._handlers = handlers or {}

	obj._ctx = info.ctx or zmq.context()
	obj._poller = info.poller or zpoller.new(3)
	obj._event = nil

	-- Message Process Function table for REQ/REP
	obj._mpft = {}
	for k,v in pairs(mpft) do
		obj._mpft[k] = v
	end

	-- Event Message Process Function table
	obj._empft = {}
	for k,v in pairs(empft) do
		obj._empft[k] = v
	end

	-- Monitor application interfaces, which will be updated automatically
	obj._monclient = nil

	-- Closed flag
	obj._closed = false

	return setmetatable(obj, {__index = class})
end

---
-- @export
return {
	new = new
}

