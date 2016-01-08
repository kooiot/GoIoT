local serial = require 'serial'

local ioapp = require 'shared.io'
local log = require 'shared.log'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local hex = require 'shared.util.hex'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

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

local function add_device_cmd(app, device, name, cmd, desc)
	if not device or not name then
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
		local r, err = dev.commands:add(name, desc or 'Control command', {})
		if not r then 
			return nil, err
		end
	end

	if cmd then
		commands[device] = commands[device] or {}
		commands[device][name] = cmd
	end
	return true
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
	cmds = cjson.decode(cmds) or {}
	if cmds then
		for devname, cmds in pairs(cmds) do
			if type(cmds) ~= 'table' then
				break
			end

			for name, cmd in pairs(cmds) do
				assert(add_device_cmd(app, devname, name, cmd))
			end
			--[[
			local dev = app.devices:add(devname, 'IR Devices ['..devname..']')
			for name, cmd in pairs(cmds) do
				print('Added command '..devname..':'..name)
				dev.commands:add(name, 'Control command', {})
			end
			]]
		end
	end
	assert(add_device_cmd(app, 'ir', 'send', nil, 'The sender which used to send multiple commands(in json string array) out'))
end

local port = serial.new()
local learn_table = {}

local handlers = {}
handlers.start = function(app)
end

handlers.reload = function(app)
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

handlers.run = function(app)
	local abort = false
	while not abort and learn_table.learning do
		local r, data, size = port:read(1)
		if r then
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

handlers.write = function(app, path, value, from)
	return nil, 'FIXME'
end


local function _send_cmd(cmd)
	--print(hex.dump(cmd))
	port:write(string.char(0xe3))
	for i = 1, string.len(cmd) do
		port:write(cmd:sub(i, i))
		os.execute('sleep 0')
	end
	local r, data, size = port:read(1, 500)
	if r and data then
		--print(hex.dump(data))
	end
	return r, err
end

local function send_cmd(app, device, name)
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
			return nil, err
		end
	else
		return nil, "No command name"
	end
	return true
end

handlers.command = function(app, path, value, from)
	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	local devname, cmd = path:match(match)
	if devname == 'ir' and cmd == 'send' then
		local cjson = require 'cjson.safe'

		if type(value) ~= 'table' then
			value = {value}
		end
		local pp = require 'shared.util.PrettyPrint'
		print(pp(value))

		local errs = {}
		for _, cmd in pairs(value) do
			cmd = tostring(cmd)
			local device, name = cmd:match('^([^/]+)/(.+)$')
			local r, err = send_cmd(app, device, name)
			if not r then
				errs[#errs + 1] = cmd
				errs[#errs + 1] = '['
				errs[#errs + 1] = err
				errs[#errs + 1] = ']'
			end
		end
		if #errs == 0 then
			return true
		else
			return nil, table.concat(errs)
		end
	else
		return send_cmd(app, devname, cmd)
	end
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
	save_conf()

	return true
end

local gapp = ioapp.init(ioname, handlers)
assert(gapp)

ioapp.run()

