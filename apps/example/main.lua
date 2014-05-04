#!/usr/bin/env lua

local io = require('shared.io')
local pp = require('shared.PrettyPrint')
local modbus = require('modbus.init')
local port = require('shared.io.port')
local log = require('shared.log')
local ztimer = require 'lzmq.timer'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

-- application object
local app = nil
local io_ports = {}
local err_count = 1

-- the stream object used by modbus lib
-- TODO: use the ltn12 utility from luasocket ??????
local stream = {}
stream.buf = ''


-- Load tags from file
local packets = {}
local tags = {}

local function remove_tags()
	for k, v in pairs(packets) do
		for k,v in pairs(v.names) do
			if v ~= '' then
				-- TODO:
				--api.erase(ioname..'.'..v, 'Modebus Tag '..v, 0)
			end
		end
	end
end

local function load_tags_conf(app, reload)
	if reload then
		-- Remove previous tags first when doing import
		remove_tags()
	end

	if not reload then
		local vdev = app.devices:add('ts', 'Time station device (virtual) used to sending the time sync commands', true)
		if not vdev then
			log:error(ioname, 'Failed to create virtual device for time station')
		else
			-- create timesync command
			vdev.commands:add('timesync', 'Time sync command', {time = { name='time', desc='time in ms', optional=true}})
		end
	end

	packets = require('tags').load_tags()

	for k, v in pairs(packets) do
		local unit = v.unit -- one unit is one device
		local dev = app.devices:get('unit.'..unit) 
		dev = dev or app.devices:add('unit.'..unit, 'Modbus device (unit:'..unit..')')

		log:debug(ioname, 'Create inputs for device "unit.'..unit..'"')
		for k,v in pairs(v.names) do
			if v ~= '' then
				local input = dev.inputs:add(v, 'Input tag '..v)
				local prop = input.props:add('high', 'alarm high condition', 100)
				prop = input.props:add('low', 'alarm low condition', 20)
				tags[v] = input
			end
		end
	end

	return true
end

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
	log:packet(ioname, 'MODBUS.RECV', hex_raw(msg))
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
	log:info(ioname, 'Received event [START]')
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

		load_tags_conf(app)

		return true
	end
	return false
end

handlers.on_pause = function(app)
	--print(os.date(), 'Received pause Event')
	log:info(ioname, 'Received event [PAUSE]')
	pause = true
end

handlers.on_reload = function(app)
	--print(os.date(), "On Reload")
	log:info(ioname, 'Received event [RELOAD]')

	return load_tags_conf(app, true)
end

handlers.on_run = function(app)
	--log:info(ioname, 'RUN TIME')
	--print(os.date(), 'RUN TIME')
	
	if err_count > 5 then
		err_count = 1
		log:warn(ioname, 'Error reach the max count, wait for 30 seconds for retry')
		return coroutine.yield(false,  30000)
	end

	if not pause then
		for k, v in pairs(packets) do
			local pa, err = mclient:request(v.unit, v.code, v.start, v.count)
			if pa then
				local ts = ztimer.absolute_time()
				local vals = {}
				for i, val in pairs(pa:data()) do
					if v.names[i] and v.names[i] ~= '' then
						tags[v.names[i]]:set(val, ts, 1)
						vals[#vals+1] = {name = ioname..'.'..v.names[i], value = val, timestamp=ts}
					end
				end
				-- TODO:
				--api.sets(vals)
				err_count = 0
			else
				err_count = err_count + 1
				print(os.date(), 'pa is nil', err)
			end
		end
	end

	return coroutine.yield(false, 1000)
end

-- Onwrite
handlers.on_write = function(app, path, value, from)
	log:debug(ioname, 'on_write called')
	return nil, 'FIXME'
end

handlers.on_command = function(app, path, value, from)
	log:debug(ioname, 'on_command called')
	return nil, 'FIXME'
end

handlers.on_import = require('import').import

io.add_port('main', {port.tcp_client, port.serial}, port.tcp_client) 
io.add_port('backup', {port.tcp_client, port.serial}, port.tcp_client) 

local setting = require('shared.io.setting')

local t1 = setting.new('t1')
t1:add_prop('prop1', 'test prop 1', 'number', 11, {min=1, max=99})
io.add_setting(t1)

app = io.init(ioname, handlers)
assert(app)

io.run()

