local serial = require 'serial'

local ioapp = require 'shared.io'
local log = require 'shared.log'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local hex = require 'shared.util.hex'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local app = nil
local commands = {}

local function load_from_file()
	local file, err = io.open('conf.json')
	if not file then
		return nil, err
	end

	local c = file:read('*a')
	file:close()
	return c
end

local function save_to_file(str)
	local f, err = io.open('conf.json', 'w+')
	if not f then
		return nil, err
	end
	local r, err = f:write(str)
	f:close()
	return r, err
end

local function add_device_cmd(device, name, cmd)
	if not device or not name or not cmd then
		return nil, 'How dare U!!'
	end

	local dev = app.devices:get(device)
	if not dev then
		dev = app.devices:add(device, 'IR Devices ['..device..']')
	end
	if not dev then
		return nil, 'Cannot create devices for '..device
	end

	print('Added command '..device..':'..name)
	local obj = dev.commands:get(name)
	if not obj then
		dev.commands:add(name, 'Control command', {})
	end

	commands[device] = commands[device] or {}
	commands[device][name] = cmd
end

local function save_conf()
	local r, err = cjson.encode(commands)
	if r then
		--[[
		print(save_to_file(r))
		local config = require 'shared.api.config'
		local cmds = r 
		r, err = config.set(ioname..'.commands', cmds)
		]]--
		r, err = save_to_file(r)
	end
	return r, err
end

local function load_conf(app, reload)
	--local config = require 'shared.api.config'
	--local cmds, err = config.get(ioname..'.commands') or load_from_file()
	local cmds, err = load_from_file()
	if not cmds then
		log:error(ioname, err or 'Failed to get command configuration')
		return
	end
	commands = cjson.decode(cmds) or {}
	if commands then
		for devname, cmds in pairs(commands) do
			if type(cmds) ~= 'table' then
				break
			end

			local dev = app.devices:add(devname, 'IR Devices ['..devname..']')
			for name, cmd in pairs(cmds) do
				print('Added command '..devname..':'..name)
				dev.commands:add(name, 'Control command', {})
			end
		end
	end
end

local port = serial.new()
local learn_table = {}

local handlers = {}
handlers.on_start = function(app)
	log:info(ioname, 'Starting application[IR]')
	if port:is_open() then
		return true
	end

	local config = require 'shared.api.config'
	local port_name = config.get(ioname..'.port_name') or '/dev/ttyUSB0'
	local r, err = port:open(port_name)
	if not r then
		log:error(ioname, err)
		return nil
	end
	return load_conf(app)
end

handlers.on_reload = function(app)
	-- TODO:
end

local function reading(app)
	local abort = false
	local timer = ztimer.monotonic(1000)
	local len = string.byte(learn_table.result)
	timer:start()
	while not abort  and timer:rest() > 0 and learn_table.learning do
		local r, data, size = port:read(1)
		if r then
			print('2', hex.dump(data))
			learn_table.result = learn_table.result..data
			if len and string.len(learn_table.result) == len then
				print('finished reading', len)
				break
			end
		else
			abort = coroutine.yield(false, 50)
		end
	end
	if port:read(1) then
		print('SSSSSSSSSSSSSS')
	end

	local f = io.open('/tmp/ir_learn_result', 'w+')
	f:write(learn_table.result)
	f:close()

	learn_table.learning = false
end

handlers.on_run = function(app)
	local abort = false
	while not abort and learn_table.learning do
		local r, data, size = port:read(1)
		if r then
			print('1', hex.dump(data))
			if not learn_table.result and  data ~= string.char(0xFF) then
				print('Start receving learn result')
				learn_table.result = data
				reading(app)
				break
			end
		else
			print('warting...')
			abort = coroutine.yield(false, 50)
		end
	end
	--
	return coroutine.yield(false, 1000)
end

handlers.on_write = function(app, path, value, from)
	return nil, 'FIXME'
end


local function _send_cmd(cmd)
	print(hex.dump(cmd))
	port:write(string.char(0xe3))
	for i = 1, string.len(cmd) do
		port:write(cmd:sub(i, i))
		os.execute('sleep 0')
	end
	local r, data, size = port:read(1, 500)
	if r and data then
		print(hex.dump(data))
	end
	return r, err
end

local function send_cmd(device, name)
	local dev = app.devices:get(device)
	if not dev or not commands[device] then
		return nil, 'No such devices '..device
	end

	local cmdobj = dev.commands:get(name)
	if not cmdobj then
		for k, v in pairs(dev.commands) do
			print(k, string.len(k), v)
		end
		return nil, "No such command "..name
	end		

	local cmd = commands[device][cmdobj.name]
	if cmd then
		log:info(ioname, string.format('Writing commmand[%s] to devices', name))
		local r, err = _send_cmd(cmd)
		if not r then
			return r, err
		end
	else
		return nil, "No command name"
	end
	return true
end

handlers.on_command = function(app, path, value, from)
	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	local devname, cmd = path:match(match)
	if devname == 'ir' and cmd == 'send' then
		local cjson = require 'cjson.safe'

		if type(value) ~= 'table' then
			value = {value}
		end
		local pp = require 'shared.PrettyPrint'
		print(pp(value))

		for _, cmd in pairs(value) do
			cmd = tostring(cmd)
			local device, name = cmd:match('^([^/]+)/(.+)$')
			send_cmd(device, name)
		end
		return true
	else
		return send_cmd(devname, cmd)
	end
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
			add_device_cmd(dev, k, v)
		end
	end
	save_conf()

	return true
end

app = ioapp.init(ioname, handlers)
assert(app)
app:reg_request_handler('list_commands', function(app, vars)
	local list = {}
	for k, v in pairs(commands) do
		for name, _ in pairs(v) do
			list[#list + 1] = k..'/'..name
		end
	end
	local reply = {'list_commands', list}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('list_devs', function(app, vars)
	local list = {}
	for k, v in pairs(commands) do
		list[#list + 1] = k
	end
	local reply = {'list_devs', list}
	app.server:send(cjson.encode(reply))
end)

local function learn()
	port:write(string.char(0xe2))
	port:read(1, 500)
	local r, err = port:write(string.char(0xe0))
	if not r then
		return nil, err
	end
	local r, data, size = port:read(1, 500)
	if not r then
		return nil, "Start learn failure, err: "..( data or 'timeout')
	end
	if data ~= string.char(0xE0) then
		return nil, "Start learn failure, returns "..hex.dump(data)
	end
	return true
end

app:reg_request_handler('learn', function(app, vars)
	local r, err = learn()
	local reply = {'learn', {result=r, err = err}}
	if r then
		learn_table.learning = true
		learn_table.result = nil
	end
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('learn_result', function(app, vars)
	local learn_result = nil
	if not learn_table.learning and learn_table.result then
		learn_result = hex.dump(learn_table.result)
	end
	local reply = {'learn_result', {result = learn_result and true or false, learn = learn_result}}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('learn_save', function(app, vars)
	local result = false
	local err = nil
	if vars.name and vars.device then
		if not learn_table.learning and learn_table.result then
			add_device_cmd(vars.device, vars.name, learn_table.result)
			save_conf()
		else
			err = 'no learn result'
		end
	else
		err = 'no learn result name or device provided'
	end

	local reply = {'learn_result', {result = result, err=err}}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('learn_stop', function(app, vars)
	log:info(ioname, 'Stop learning')
	if port:is_open() then
	end
	port:write(string.char(0xe2))
	port:read(1, 200)

	local reply = {'learn_stop', {result = true}}
	app.server:send(cjson.encode(reply))
end)

ioapp.run()

