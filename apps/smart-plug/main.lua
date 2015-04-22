
local ioapp = require 'shared.io'
local log = require 'shared.log'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local hex = require 'shared.util.hex'
local devctrl = require 'devctrl'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local DEVS = {
	--[ 'dev1' = { ip = "xxx.xx.xx.xx", ver = 1}
}

local function save_conf(app)
	local config = require 'shared.api.config'
	config.set(ioname..'.devs', cjson.encode({DEVS=DEVS}))
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
	dev.ver = dev.ver or 1
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

local handlers = {}
handlers.on_start = function(app)
	return load_conf(app)
end

handlers.on_reload = function(app)
	-- TODO:
end

local function reading(app)
	local abort = false
	local timer = ztimer.monotonic(1000)
	timer:start()
		--[[
	while not abort  and timer:rest() > 0 do
		local r, data, size = port:read(1)
		if r then
			--print('2', hex.tohex(data))
			learn_table.result = learn_table.result..data
			if len and string.len(learn_table.result) == len then
				print('finished reading', len)
				break
			end
		else
			abort = coroutine.yield(false, 50)
		end
	end
		]]--
end

handlers.on_run = function(app)
	local abort = false
	while not abort do
		--reading(app)
		abort = coroutine.yield(false, 1000)
	end
	--
	return coroutine.yield(false, 1000)
end

handlers.on_write = function(app, path, value, from)
	return nil, 'FIXME'
end

handlers.on_command = function(app, path, value, from)
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
	return func(dev.ip)
end

handlers.on_import = function(app, filename)
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

