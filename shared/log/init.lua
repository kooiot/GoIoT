--- Logger client class
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'

---Log object
-- @local
-- @table log
-- @field src log rouce
-- @field desc log description
-- @field level log level
-- @field content log content
-- @field timestamp log timestamp in ms

--- The ipc channel
local IPC = "ipc:///tmp/og.log.ipc"
--local IPC = "tcp://localhost:5593"

--- Logger clent object
local obj = {}

--- Open logger client
-- @tparam lzmq.context ctx
-- @treturn nil
local function open(ctx)
	if obj.client then
		return
	end

	obj.ctx = ctx or zmq.context()
	local SOCKET_OPTION = {
		zmq.PUSH,
		connect  = IPC,
	}

	local client, err = obj.ctx:socket(SOCKET_OPTION)
	zassert(client, err)
	obj.client = client
end

--- Close the logger
-- @treturn boolean ok
-- @treturn[opt] string error message
function obj:close()
	if not self.client then
		return nil, "not connected"
	end

	self.client:close()
	self.client = nil
	return true
end

--- Send log object
-- @local
-- @tparam log log object
-- @return ok
-- @treturn[opt] string error message
function obj:send(log)
	assert(log.src)
	assert(log.level)
	log.timestamp = log.timestamp or ztimer.absolute_time()
	print(os.date('%c', log.timestamp / 1000), log.level, log.content)
	-- We will not wait for event done
	return self.client:send(cjson.encode(log))
end

--- Fire an error log
-- @tparam string src log source
-- @param ... log content refer to print
function obj:error(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'error',
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

--- Fire an warn log
-- @see obj:error
function obj:warn(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'warn', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

--- Fire an info log
-- @see obj:error
function obj:info(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'info', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

--- Fire an debug log
-- @see obj:error
function obj:debug(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'debug', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

--- Fire an protocol packet
-- @tparam string src packet source
-- @tparam string desc packet description
-- @param ... the packet content
function obj:packet(src, desc, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		desc = desc  or '',
		level = 'packet', 
		content = table.concat(info),
	}
	return self:send(log)
end

open()

---
-- export
return obj
