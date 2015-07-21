
local ioapp = require 'shared.io'
local log = require 'shared.log'
local cjson = require 'cjson.safe'
local hex = require 'shared.util.hex'
local udp = require 'shared.io.udp'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')
local server = nil

--- The table saving devices
local DEVS = {
	["172.16.0.185"] = { ip = "172.16.0.185", name="test", online=os.time(), used=true},
}

--- The table saving all device inputs props
local INPUTS = {}

--- Global application handle
local gapp = nil

--- Save application configuration
local function save_conf(app)
	local config = require 'shared.api.config'
	config.set(ioname..'.devs', cjson.encode({DEVS=DEVS}))
end

--- Add device command to device
local function add_device_cmd(app, device, name, desc)
	if not device or not name then
		return nil, 'How dare U!!'
	end

	local dev = app.devices:get(device)
	if not dev then
		dev = app.devices:add(device, 'Smart-Plug devices ['..device..']')
	end
	if not dev then
		return nil, 'Cannot create devices for '..device
	end

	print('Added command '..device..':'..name)
	local obj = dev.commands:get(name)
	if not obj then
		local r, err = dev.commands:add(name, desc or 'Control command', {})
		if not r then 
			return nil, err
		end
	end

	return true
end

local function add_device_input(app, device, name, desc, typ)
	assert(app)
	assert(device, name)
	local dev = app.devices:get(device) or app.devices:add(device, 'NodeMCU devices')
	if not dev then
		return nil, 'Cannot create device for '..device
	end
	print('Add input '..device..':'..name)
	local obj = dev.inputs:get(name)
	if not obj then
		obj, err = dev.inputs:add(name, desc or 'Input')
		if obj then
			obj:value_type('number/integer')
		end
	end
	return obj
end

local function create_vdevs(app)
	for ip, dev in pairs(DEVS) do
		if dev.used then
			local t = INPUTS[dev.name] or {}

			t['ADC'] = add_device_input(app, dev.name, 'ADC', 'ADC input')
			for i = 1, 12 do 
				add_device_cmd(app, dev.name, 'GPIO'..i, 'Change GPIO'..i..' state')
				t['GPIO'..i] = add_device_input(app, dev.name, 'GPIO'..i, 'GPIO '..i..' input')
			end

			INPUTS[dev.name] = t
		end
	end
	return true
end

local function load_conf(app)
	local config = require 'shared.api.config'
	local r, err = config.get(ioname..'.devs')
	if r then
		local t, err = cjson.decode(r)
		if t then
			DEVS = t.DEVS
		end
	end
	
	r, err = create_vdevs(app)
	return r, err
end

local function send(data, ip)
	if server then
		return server:send(data, ip or '255.255.255.255', 6000)
	else
		return nil, 'No UDP socket'
	end
end

local function scan_device(app)
	log:debug(ioname, 'Sending request of version')
	return send('SDP:')
end

local function read_gpio(app)
	return send('GPIO:a')
end

local function read_adc(app)
	return send('ADC:0')
end


local function on_recv(data, ip, port)
	print(data, ip, port)
	if data:sub(1, 4) == 'ADC:' then
		local dev = DEVS[ip]
		if dev then
			local ts = gapp:time()
			local tags = INPUTS[dev.name]
			if tags then
				local v = tonumber(data:sub(5))
				local tag = tags['ADC']
				if v and tag then
					tag:set(v, ts, 1)	
				end
			end
		end
	end
	if data:sub(1, 5) == 'GPIO:' then
		local dev = DEVS[ip]
		if dev then
			local ts = gapp:time()
			local tags = INPUTS[dev.name]
			if tags and data:sub(6, 7) == 'a:' then
				local s = data:sub(8)
				local t = {}
				for v in s:gmatch('([^:]+)') do
					t[#t + 1] = v
				end
				for k, v in pairs(t) do
					local tag = tags['GPIO'..k]
					if tag and tonumber(v) then
						tag:set(tonumber(v), ts, 1)
					else
						print('GPIO'..k..' is not exits')
					end
				end
			end
		end
	end
	if data:sub(1, 4) == 'SDP:' then
		local sdp = cjson.decode(data:sub(5))
		assert(sdp.name and sdp.ver and sdp.mac)
		if not DEVS[ip] or DEVS[ip].name ~= sdp.name or DEVS[ip].mac ~= sdp.mac then
			print('New device found', ip, data:sub(5))

			sdp.ip = ip
			sdp.port = port
			sdp.online = os.time()
			sdp.used = true

			DEVS[ip] = sdp
			create_vdevs(gapp)
		end
	end
end

local handlers = {}
handlers.start = function(app)
	print('Start')
	server = udp.new(app, "*", 6006)
	assert(server:open(on_recv))
	return load_conf(app)
end

handlers.reload = function(app)
	-- TODO:
end

handlers.run = function(app)
	local abort = false
	local count = 0
	while not abort do
		abort = app:sleep(1)
		for ip, dev in pairs(DEVS) do
			abort = app:sleep(0)
			if abort then
				break
			end
			if dev.used then
				read_gpio(app)
				read_adc(app)
			end
		end
		if count == 0 then
			scan_device(app)
		end
		count = (count + 1) % 60
	end
end

handlers.write = function(app, path, value, from)
	return nil, 'FIXME'
end

handlers.command = function(app, path, value, from)
	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	local key, cmd = path:match(match)

	for ip, dev in pairs(DEVS) do
		if dev.ip == key or dev.name == key then
			local r, err = send(cmd, dev.ip)
			if not r then
				log:error(ioname, "Failed to send out command", err)
			end
		end
	end
	log:error(ioname, 'Cannot find device', key)
end

gapp = ioapp.init(ioname, handlers)
assert(gapp)

gapp:reg_request_handler('list', function(app, vars)
	print('LIST')
	local reply = {'list', DEVS}
	app.server:send(cjson.encode(reply))
end)

gapp:reg_request_handler('scan', function(app, vars)
	print('SCAN')
	local r, err = scan_device(app)
	local reply = {'scan', {result=r, err = err}}
	app.server:send(cjson.encode(reply))
end)

ioapp.run()

