#!/usr/bin/env lua

local io = require('shared.io')
local pp = require('shared.PrettyPrint')
local modbus = require('modbus.init')
local port = require('shared.io.port')
local log = require('shared.log')
local ztimer = require 'lzmq.timer'
local decode = require "modbus.decode"
local encode = require "modbus.encode"
local serial = require "serial"

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

-- application object
local app = nil
local mclient = nil
local io_ports = {}
local err_count = 1

-- the stream object used by modbus lib
-- TODO: use the ltn12 utility from luasocket ??????
local stream = {}
stream.buf = ''


-- Load tags from file
local packets = {}
local modbus_mode = {}
local tags = {}

local function remove_tags()
	for k, v in pairs(packets) do
		for k,v in pairs(v.vals) do
			if v.name ~= '' then
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

	packets, modbus_mode = require("tags").load_tags(ioname)

	for k, v in pairs(packets) do
		port_config = v.port_config
		local unit = v.port_config.unit -- one unit is one device
		local dev = app.devices:get('unit.'..unit) 
		dev = dev or app.devices:add('unit.'..unit, 'Modbus device (unit:'..unit..')')

		log:debug(ioname, 'Create inputs for device "unit.'..unit..'"')
		for k, v in pairs(v.tags) do
			if v.vals then
				for k,v in pairs(v.vals) do
					for k, v in pairs(v) do
						if k == "Name" then
							name = v
						end
						if k == "Description" then
							desc = v
						end
					end
					local input = dev.inputs:get(name)
					if not input then
						input = dev.inputs:add(name, desc)
						assert(input)
						local prop = input.props:add('high', 'alarm high condition', 100)
						prop = input.props:add('low', 'alarm low condition', 20)
						name = ioname .. "/unit." .. port_config.unit .. "/inputs/" .. name
						tags[name] = input
					end
				end
			end
		end
	end

	return true
end

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
--	log:packet(ioname, 'MODBUS.RECV', hex_raw(msg))
	stream.buf = stream.buf..msg
	print("RECV", hex_raw(stream.buf))
end

stream.read = function (t, check, timeout)
	local ztimer = require 'lzmq.timer'
	local timer = ztimer.monotonic(timeout)
	timer:start()

	local abort = false
	while not abort and timer:rest() > 0 do
		if modbus_mode.mode == "0" or modbus_mode.mode == "2" then
			local r, data, size = io_ports.port:read(1024, 1000)
			if r and data then
				on_rev(nil, data)
			end

			if string.len(stream.buf) > 0 then
				--print(os.date(), 'DATA CHECK', hex_raw(stream.buf))
				local r, b, e = check(stream.buf, t, port_config, ecm)
				if r then
					return r
				end
			end
			abort = coroutine.yield(false, 50)
		else
			if string.len(stream.buf) > 0 then
				--print(os.date(), 'DATA CHECK', hex_raw(stream.buf))
				local r, b, e = check(stream.buf, t, port_config)
				if r then
					return r
				end
			end
			abort = coroutine.yield(false, 50)
		end
	end
	stream.buf = ''
	return nil, 'timeout'
end

stream.send = function(msg)
	--log:packet(ioname, "MODBUS.SEND", hex_raw(msg))
	if modbus_mode.mode == "0" or modbus_mode.mode == "2" then
		io_ports.port:write(msg, 500)
	else
		io_ports.main:send(msg)
	end
	print("SEND", hex_raw(msg))
end

local handlers = {}
handlers.on_start = function(app)
	log:info(ioname, 'Starting application[MODBUS]')
	load_tags_conf(app)
	if modbus_mode.mode == "0"  or modbus_mode.mode == "3" then
		mclient = modbus.client(stream, modbus.apdu_rtu)
	elseif modbus_mode.mode == "1" then
		mclient = modbus.client(stream, modbus.apdu_tcp)
	else
		mclient = modbus.client(stream, modbus.apdu_ascii)
	end

	if modbus_mode.mode == "0" or modbus_mode.mode == "2" then
		io_ports.port = serial.new()
		if io_ports.port:is_open() then
			return true
		end

		local port_name = modbus_mode.sPort
		local opt = {}
		opt.baudrate = tostring(modbus_mode.baud)
		opt.databits = tostring(modbus_mode.dbs)
		if modbus_mode.parity == "0" then
			opt.parity = "NONE"
		elseif modbus_mode.parity == "1" then
			opt.parity = "ODD"
		else
			opt.parity = "EVEN"
		end
		opt.stopbits = tostring(modbus_mode.sbs)
		opt.flowcontrol = modbus_mode.flowcontrol

		local r, err = io_ports.port:open(port_name, opt)
		if not r then
			log:error(ioname, err)
			return nil
		end
	else
		local remote_addr = modbus_mode.sIp
		local port = modbus_mode.port
		local tcpc = require 'shared.io.tcp.client'
		log:info(app.name, 'Creating tcp client to', remote_addr, 'port', port)
		io_ports.main = tcpc.new(app.ctx, app.poller, remote_addr, port)
		io_ports.main:open(on_rev)
	end
end

handlers.on_pause = function(app)
	--print(os.date(), 'Received Stop Event')
	log:info(ioname, 'Received event [PAUSE]')
	pause = true
	return true
end

handlers.on_reload = function(app)
	--print(os.date(), "On Reload")
	log:info(ioname, 'Received event [RELOAD]')

	return load_tags_conf(app, true)
end

local create_funcs = function(raw, addr)
	return {
		byte = function(index)
			return decode.byte(raw, addr, index)
		end,
		bit = function(index)
			return decode.bit(raw, addr, index)
		end
	}
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
			port_config = v.port_config
			for k, v in pairs(v.tags) do
				if v.request.cycle ~= "" then
					if v.request.cycle and v.request.timer:rest() == 0 then
						local pdu, err = mclient:request(v, port_config, modbus_mode.ecm)
						if pdu then
							local ts = ztimer.absolute_time()
							local vals = {}
							fc = tonumber(v.request.func)
							if fc == 1 or fc == 2 or fc == 3 or fc == 4 then
								len = decode.uint8(pdu:sub(2, 2))
								raw = pdu:sub(3)
								for k, v in pairs(v.vals) do
									local name = v.Name
									local multiple = tonumber(v.Multiple)
									local addr = tonumber(v.Address)
									local ctpt = v.CTPT
									local calc = v.Calc

									local func = require('shared.compat.env').load(calc, nil,nil, create_funcs(raw, addr))
									val = func()
									val = val * multiple

									if ctpt == "2" then
										val = val * modbus_mode.ct
									elseif ctpt == "3" then
										val = val * modbus_mode.pt
									elseif ctpt == "4" then
										val = val * modbus_mode.ct * modbus_mode.pt
									else
										val = val
									end


									for k, v in pairs (v) do
										if k == "Data" then
											v = val
										end
									end
									name = ioname .. "/unit." .. port_config.unit .. "/inputs/" .. name
									tags[name]:set(val, ts, 1)
									vals[#vals+1] = {name = ioname..'.'.. name, value = val, timestamp=ts}
									--print("addr = ",  addr, "name = ", name, "val = ", val)
								end
							else
								for k, v in pairs(v.vals) do
									local name = v.Nmae
									local addr = v.Address
									local data = v.Data
									name = ioname .. "/unit." .. port_config.unit .. "/inputs/" .. name
									tags[name]:set(data, ts, 1)
									--vals[#vals+1] = {name = ioname..'.'..name, value = data, timestamp = ts}
									vals[#vals+1] = {name, value = data, timestamp = ts}
								end
							end

							stream.buf = ""
						else
							err_count = err_count + 1
							print(os.date(), 'pa is nil', err)
						end
					end
				end
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

--io.add_port('main', {port.tcp_client, port.serial}, port.tcp_client) 
--io.add_port('backup', {port.tcp_client, port.serial}, port.tcp_client) 

app = io.init(ioname, handlers)
assert(app)

io.run()

