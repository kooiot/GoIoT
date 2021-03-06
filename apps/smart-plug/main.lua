
local ioapp = require 'shared.io'
local log = require 'shared.log'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local hex = require 'shared.util.hex'
local devctrl = require 'devctrl'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local DEVS = {
	sp2 = { ip = "192.168.10.100", ver = 2, state= { relay="ON", light="OFF"}},
	sp1 = { ip = "192.168.10.105", ver = 1, state= { relay="ON"}}
}

local function save_conf(app)
	local config = require 'shared.api.config'
	config.set(ioname..'.devs', cjson.encode({DEVS=DEVS}))
end

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



local add_device = function (app, name, dev)
	if not name or not dev.ip then
		return nil, "Incorrect device properties"
	end
	if DEVS[name] then
		return nil, "The device name has been used"
	end
	dev.ver = tonumber(dev.ver) or 1
	dev.state = dev.state or {}
	DEVS[name] = dev

	save_conf(app)

	add_device_cmd(app, name, 'relay_on', 'Turn on the switch')
	add_device_cmd(app, name, 'relay_off', 'Turn off the switch')
	if dev.ver > 1 then 
		add_device_cmd(app, name, 'light_on', 'Turn on the switch')
		add_device_cmd(app, name, 'light_off', 'Turn off the switch')
	end

	return true
end

local function del_device(app, name)
	DEVS[name] = nil
	return true
end

local function create_vdevs(app)
	for name, dev in pairs(DEVS) do
		add_device_cmd(app, name, 'relay_on', 'Turn on the switch')
		add_device_cmd(app, name, 'relay_off', 'Turn off the switch')
		if dev.ver > 1 then 
			add_device_cmd(app, name, 'light_on', 'Turn on the switch')
			add_device_cmd(app, name, 'light_off', 'Turn off the switch')
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
			r, err = create_vdevs(app)
		end
	end
	return r, err
end

local handlers = {}
handlers.start = function(app)
	devctrl.set_timeout(1) -- timeout 1 second
	return load_conf(app)
end

handlers.reload = function(app)
	-- TODO:
end

handlers.run = function(app)
	local abort = false
	while not abort do
		for name, dev in pairs(DEVS) do
			local r, state = devctrl.relay(dev.ip)
			if r then
			--	print(name..'.RELAY: '..state)
				dev.state['relay'] = state
			end
			abort = coroutine.yield(false, 50)
			if abort then
				break
			end

			if dev.ver == 2 then
				local r, state = devctrl.light(dev.ip)
				if r then
			--		print(name..'.LIGHT: '..state)
					dev.state['light'] = state
				end
				abort = coroutine.yield(false, 50)
				if abort then
					break
				end
			end
		end

		abort = coroutine.yield(false, 3000)
	end
	--
	return coroutine.yield(false, 1000)
end

handlers.write = function(app, path, value, from)
	return nil, 'FIXME'
end

handlers.command = function(app, path, value, from)
	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	local devname, cmd = path:match(match)
	local dev = DEVS[devname]
	if not dev then
		return nil, "No such device "..devname
	end
	local func = devctrl[cmd]
	if not func then
		return nil, "No such command "..cmd
	end

	local c, s = cmd:match('^(.+)_(.-)$')
	print(c, s)
	DEVS[devname].state[c] = s:upper()

	return func(dev.ip)
end

handlers.import = function(app, filename)
	local f, err = io.open(filename)
	if not f then
		return nil, err
	end
	local c = f:read('*a')
	local cmds, err = cjson.decode(c)
	if not cmds then
		return nil, err
	end

	for dev, v in pairs(cmds) do
		print(v)	
		for k, v in pairs(v) do
			add_device_cmd(app, dev, k, v)
		end
	end
	save_conf(app)

	return true
end

local gapp = ioapp.init(ioname, handlers)
assert(gapp)

gapp:reg_request_handler('list', function(app, vars)
	print('LIST')
	local reply = {'list', DEVS}
	app.server:send(cjson.encode(reply))
end)

gapp:reg_request_handler('add', function(app, vars)
	print('ADD', vars.name, vars.dev.ip, vars.dev.ver)
	local r, err = add_device(app, vars.name, vars.dev)
	local reply = {'add', {result=r, err = err}}
	app.server:send(cjson.encode(reply))
end)

gapp:reg_request_handler('del', function(app, vars)
	local r, err = del_device(app, vars.name)
	local reply = {'del', {result=r, err = err}}
	app.server:send(cjson.encode(reply))
end)

ioapp.run()

