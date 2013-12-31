#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local configs = require 'shared.api.configs'
local info = require '_ver'
local io = require('shared.io')
local pp = require('shared.PrettyPrint')
local modbus = require('modbus.init')
local port = require('shared.io.port')
local api = require('shared.api.data')
local log = require('shared.log.client')
local ztimer = require 'lzmq.timer'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

-- application object
local app = nil
local io_ports = {}

-- the stream object used by modbus lib
-- TODO: use the ltn12 utility from luasocket ??????
local stream = {}
stream.buf = ''

local mclient = modbus.client(stream, modbus.apdu_tcp)

-- When user click stop, we only pause the data 
local pause = false

local function hex_raw(raw)
	if not raw then
		return ""
	end
	if (string.len(raw) > 1) then
		return string.format("%02X ", string.byte(raw:sub(1, 1)))..hex_raw(raw:sub(2))
	else
		return string.format("%02X ", string.byte(raw:sub(1, 1)))
	end
end

local function on_rev(port, msg)
--	print(os.date(), 'DATA RECV', hex_raw(msg))
	log:packet('MODBUS', ioname..'.RECV', hex_raw(msg))
	stream.buf = stream.buf..msg
end

stream.read = function (check, timeout)
	local ztimer = require 'lzmq.timer'
	local timer = ztimer.monotonic(timeout)
	timer:start()

	local abort = false
	while not abort and timer:rest() > 0 do
		if string.len(stream.buf) > 0 then
			--print(os.date(), 'DATA CHECK', hex_raw(stream.buf))
			local r, len = check(stream.buf)
			if r then
				local msg = string.sub(stream.buf, 1, len + 1)
				stream.buf = string.sub(stream.buf, len + 1)
				return msg
			end
		end
		abort = coroutine.yield(false, 50)
	end
	stream.buf = ''
	return nil, 'timeout'
end

stream.send = function(msg)
	io_ports.main:send(msg)
end

local handlers = {}
handlers.on_start = function(app)
	pause = false
	if io_ports.main then
		return
	end

	io_ports.main, io_ports.main_type = assert(io.get_port('main'))

	if io_ports.main_type ~= port.tcp_client then
		local r, err = io_ports.main:open(on_rev)
		if not r then
			print(err)
		end

		for v = 1, 16 do
			api.add(ioname..'.data'..v, 'Modbus Tag '..v, 0)
		end

		return true
	end
	return false
end

handlers.on_stop = function(app)
	print(os.date(), 'Received Stop Event')
	pause = true
end

handlers.on_run = function(app)
	log:info('example', os.date(), 'RUN TIME')
	--print(os.date(), 'RUN TIME')

	if not pause then
		local pa, err = mclient:request(1, 'ReadHoldingRegisters', 3, 16)
		if pa then
			local ts = ztimer.absolute_time()
			local vals = {}
			for k, v in pairs(pa:data()) do
				vals[#vals+1] = {name = ioname..'.data'..k, value = v, timestamp=ts}
			end
			api.sets(vals)
		else
			print(os.date(), 'pa is nil', err)
		end
	end

	return coroutine.yield(false, 1000)
end

io.add_port('main', {port.tcp_client, port.serial}, port.tcp_client) 
io.add_port('backup', {port.tcp_client, port.serial}, port.tcp_client) 

local setting = require('shared.io.setting')
local command = require('shared.io.command')

local t1 = setting.new('t1')
t1:add_prop('prop1', 'test prop 1', 'number', 11, {min=1, max=99})
io.add_setting(t1)

local c1 = command.new('c1')
c1:add_arg('arg1', 'test arg 1', 'number', 10, {min=1, max=99})
io.add_command(c1)

app = io.init(ioname, handlers)
assert(app)

io.run(5000)

