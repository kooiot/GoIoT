
require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'

local IPC = "ipc:///tmp/og.log.ipc"
--local IPC = "tcp://localhost:5593"

local obj = {}

local function open(ctx)
	assert(not obj.cleint)
	obj.ctx = ctx or zmq.context()
	local SOCKET_OPTION = {
		zmq.PUSH,
		connect  = IPC,
	}

	local client, err = obj.ctx:socket(SOCKET_OPTION)
	zassert(client, err)
	obj.client = client
end

function obj:close()
	if not self.client then
		return nil, "not connected"
	end

	self.client:close()
	self.client = nil
	return true
end

function obj:send(log)
	assert(log.src)
	assert(log.level)
	log.timestamp = log.timestamp or ztimer.absolute_time()
	print(os.date('%c', log.timestamp / 1000), log.level, log.content)
	-- We will not wait for event done
	return self.client:send(cjson.encode(log))
end

function obj:error(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'error',
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

function obj:warn(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'warn', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

function obj:info(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'info', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

function obj:debug(src, ...)
	local info = {...}
	local log = {
		src = src or 'UNKOWN',
		level = 'debug', 
		content = table.concat(info, ' '),
	}
	return self:send(log)
end

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

return obj
