local serial = require 'serial'

local ioapp = require 'shared.io'
local cjson = require 'cjson.safe'
local ztimer = require 'lzmq.timer'

local ioname = arg[1]
local command = {}
local port = serial.new()
local learn_table = {}

local handlers = {}

local function load_from_file()
	local file, err = io.open('conf.json')
	if not file then
		return nil, err
	end

	local c=file:read('*a')
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

local function save_conf()
	local r, err = cjson.encode(commands)
	if r then
		r, err = save_to_file(r)
	end
	return r, err
end

local function add_device_cmd(app, device, name, cmd, desc)
	if not device or not name then
		return nil
	end

	local dev = app.devices:get(device)
	if not dev then
		return nil, 'cannot creat devices for '..device 
	end
	print ('Added connand '..device..':'..name)
	local obj = dev.commands:get(name)
	if not obj then
		local r, err = dev.commands:add(name, desc or 'control command', {})
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

local function load_conf(app, reload)
	local cmds, err = load_from_file()
	if not cmds then
		log:error(ioname, err or 'Faild to get command configuration')
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
		end
	end
		assert(add_device_cmd(app, 'gprs', 'send', 'The sender which used to send multiple commands(in json string arry) out'))
end



handlers.on_start = function(app)
	log:info(ioname, 'Starting application[GPRS]')
	if port:is_open() then 
		return true
	end

	local config = require 'shared.api.config'
	local port_name = config.get(ioname .. '.port') or '/dev/ttyUSB0'
	local r, err = port:open(port_name)
	if not r then 
		log:error(ioname, err)
		return nil
	end
	return load_conf(app)
end

local function reading(app)
	local abort = false
	local timer = ztimer.monotonic(1000)
	local len = string.byte(learn_table.result)
	timer:start()
	while not abort and timer:rest() > 0 do
		local r, data, size = port:read(8)
		if r then
			print('2: ',data)
			learn_table.result = learn_table.result..data
			if len and string.len(learn_table.result) == len then
				print ('finished reading', len)
				break
			end
		else
			abort = coroutine.yield(false, 50)
		end
	end
	if port:read(1) then
		print('*************')
	end

	local f = io.open('/tmp/gprs_learn_result', 'w+')
	f:write(learn_table.reault)
	f:close()
	
	learn_table.learning = false
end


handlers.on_write = function (app, path, value, from)
	return nil, 'FIXME'
end

handlers.on_run = function(app)
	local abort = false
	while not abort do
		local r, data, size = port:read(8)
		print ('1: ', data)
		if r then
			if not data ~= "OK" then
				print ('recving ...')
				reading(app)
				break
			end
		else
			print('waiting...')
			abort = coroutine.yield(false, 50)
		end
	end
	return coroutine.yield(false, 1000)
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
	save_conf()
	return true
end

local gapp = ioapp.init(ioname, handlers)
assert(gapp)
gapp:reg_request_handler('list_commands', function(app, vars)
				local list = {}
				for k, v, in pairs(commands) do
					for name, _in pairs(v) do
						list[#list+1] = k ..'/' .. name
					end
				end
				local reply = {'list_commands', list}
				app.server:send(cjson.encode(reply))
end)
gapp:reg_request_handler('list_devs', function (app, vars)
	local list = {}
	for k, v in pairs(commands) do
		list[#list + 1] = k
	end
	local reply = {'list_devs', list}
	app.server:send(cjson.encode(reply))
end)






