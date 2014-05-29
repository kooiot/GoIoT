local serial = require 'serial'

local ioapp = require 'shared.io'
local log = require 'shared.log'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local app = nil
local commands = nil

local function load_from_file()
	local file, err = io.open('conf.json')
	if not file then
		return nil, err
	end

	local c = file:read('*a')
	file:close()
	return c
end

local function load_conf(app, reload)
	if commands then
		return nil
	end

	local config = require 'shared.api.config'
	local cmds, err = config.get(ioname..'.commands') or load_from_file()
	if not cmds then
		log:error(ioname, err or 'Failed to get command configuration')
		return
	end
	commands = cjson.decode(cmds)
	if commands then
		local dev = app.devices:add('ir', 'IR Controller')
		for k, v in pairs(commands) do
			if v.cmd then
				print('Added command '..k)
				dev.commands:add(k, 'Controll command', {})
			else
				log:warn(ioname, "Incorrect command entry found!")
			end
		end
	end
end

local port = serial.new()

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

handlers.on_run = function(app)
	--
	return coroutine.yield(false, 1000)
end

handlers.on_write = function(app, path, value, from)
	return nil, 'FIXME'
end

handlers.on_command = function(app, path, value, from)

	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	print(path, match)
	local devname, cmd = path:match(match)
	print(devname, cmd, string.len(cmd))
	local dev = app.devices:get('ir')
	if dev then
		local cmdobj = dev.commands:get(cmd)
		if not cmdobj then
			for k, v in pairs(dev.commands) do
				print(k, string.len(k), v)
			end
			return nil, "No such commands"
		end		

		local c = commands[cmdobj.name]
		if c then
			port:write(c.cmd)
			return true
		else
			return nil, "No command name"
		end
	else
		return nil, 'No such devices'
	end
end

handlers.on_import = require('import').import

app = ioapp.init(ioname, handlers)
assert(app)
app:reg_request_handler('list_commands', function(app, vars)
	local list = {}
	for k, v in pairs(commands) do
		list[#list + 1] = k
	end
	local reply = {'list_commands', {result=true, commands=list}}
	app.server:send(cjson.encode(reply))
end)

ioapp.run()

