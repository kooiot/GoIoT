#!/usr/bin/env lua
--- IO Application base helper
--

local configs = require 'shared.api.config'
local setting = require 'shared.io.setting'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local pp = require 'shared.PrettyPrint'
local platform = require 'shared.platform'
local log = require 'shared.log'
local iobus = require 'shared.api.iobus'

local app = nil

local function load_config(name)
	local config = {
		port = 5515,
		revision = 1,
	}

	local ports, err = configs.get(name..'.ports')
	if ports then
		config.ports = ports
	end

	return config 
end

local config = nil

--- Module 
local _M = {}
--- port list
_M.ports = {}
--- setting list
_M.settings = {}

--- Get the applicaiton meta information
local function  app_meta()
	return {
		type = "IO",
		config = config,
		ports = _M.ports,
		settings = _M.settings,
	}
end

--- Add settings item
-- @tparam table item Setting item
-- @treturn nil
function _M.add_setting(item)
	table.insert(_M.settings, item:meta())
end

--- Get settings item according to name
-- @tparam string name The setting name
-- @treturn table item or nil
-- @treturn string error message
function _M.get_setting(name)
	if config.settings then
		for k, v in config.settings do 
			if v.name == name then
				return setting.from(config.settings[name])
			end
		end
	end

	if _M.settings[name] then
		return setting.from(_M.settings[name])
	end
	return nil, 'no such setting'
end

--- Add ports item
-- @tparam string name Port item
-- @tparam table types Port Types in string table
-- @tparam table default Default port object table
-- @treturn nil
function _M.add_port(name, types, default)
	local port = require 'shared.io.port'
	_M.ports[#_M.ports + 1] = {name=name, types = types, default = port[default..'_conf']()}
end

--- Get port settings
-- @tparam string name Port name
-- @treturn table Port configuration
-- @treturn string error message
local function get_port_conf(name)
	local conf = nil
	for k,v in pairs(_M.ports) do
		if v.name == name then
			conf = v.default
		end
	end

	if conf and config.ports and config.ports[name] then
		local ports = config.ports[name]
		for k, v in pairs(ports.props) do
			if conf.props[k] then
				conf.props[k].value = v
			end
		end
	end

	return conf, 'no such port'
end

--- Get port object
-- @tparam string name Port name
-- @treturn table Port object 
-- @treturn string error message
function _M.get_port(name)
	local conf, err = get_port_conf(name)
	if not conf then
		return nil, err
	end

	local port = require 'shared.io.port'

	return port.create(app, conf), conf
end

--- Import the default configration
local function import_default_conf()
	if _M.handlers.on_import then
		local path = platform.path.appdefconf..'/'..app.name..'/config.csv'
		local file, err = io.open(path, 'r')
		if file then
			file:close()
			log:info(app.name, 'Import the defconf install with application')
			local r, err = _M.handlers.on_import(app, path)
			if not r then
				log:error(app.name, 'Load default configuration failure:', err)
			end
			assert(os.execute('mv '..path..' '..path..'.bak'))
		end
	end
end

--- Initialize the IO application
-- @tparam string name IO application name
-- @tparam table handlers IO handler function table
-- @treturn app IO Application object
-- @see app
function _M.init(name, handlers)
	config = load_config(name)
	_M.handlers = handlers
	_M.handlers.app_meta = app_meta

	if not _M.handlers.on_close then
		_M.handlers.on_close = function(app)
			_M.abort()
		end
	end

	local info = {}
	info.name = name
	info.port = config.port
	app = require('shared.app').new(info, _M.handlers)

	--- devcies Interface
	-- @see io.devs
	app.devices = require('shared.io.devs').new(name)
	app.devices:bindcov(function(path, value)
		--log:debug(name, 'Publish data changes at '..path)
		local r, err = app.iobus:publish(path, value.value, value.timestamp, value.quality)
		if not r then
			log:error(name, err)
		end
	end)

	assert(app)

	app:init()
	--- IOBus interface
	-- @local
	-- @see api.iobus
	app.iobus = iobus.new(name, app.ctx, app.poller)
	-- register the command and write handlers
	app.iobus:oncommand(function(path, args, from)
		log:info(name, 'Command operation received')
		if not path:match('.+/commands/[^/]+$') then
			log:error(name, 'Command operation could only perform on commands object')
			return nil, 'Invalid path'
		end
		if _M.handlers.on_command then
			local r, err = _M.handlers.on_command(app, path, args, from)
			if not r then
				log:error(name, 'Write operation failed', err)
			end
			return r, err
		else
			log:error(name, 'on_command not implemented')
			return nil, 'Not implemented'
		end
	end)
	app.iobus:onwrite(function(path, value, from)
		log:info(name, 'Write operation received')
		-- Disable writing on inputs and commands path
		if path:match('.+/inputs/[^/]+$') or path:match('.+/commands/[^/]+$') then
			log:error(name, 'Write only could perform on output/value objects', path)
			return nil, 'Invalid path'
		else
			if _M.handlers.on_write then
				local r, err = _M.handlers.on_write(app, path, value, from)
				if not r then 
					log:error(name, 'Write operation failed', err)
				end
			else
				log:error(name, 'on_write not implemented')
				return nil, 'Not implemented'
			end
		end
	end)

	local r, err = app.iobus:login('user', 'pass', app.port)
	if not r then
		log:error(name, err)
	end

	-- Register the import function handler
	app:reg_request_handler('import', function(app, vars)
		log:warn('import message received')
		local re = false
		local err = 'Incorrect request found for msg:import'
		if vars.filename  then
			if _M.handlers.on_import then
				re, err = _M.handlers.on_import(app, vars.filename)
			else
				err = 'Import not implemented'
			end
		end
		local reply = {'import', {result=re, err=err}}
		app.server:send(cjson.encode(reply))
	end)

	-- Register the data function handler
	app:reg_request_handler('devs', function(app, vars)
		local name = app.name
		local version = app.version
		local verinfo = {
			app = {
				name = name,
				verion = version
			},
			revision = config.revision,
		}
		local reply = {'devs', {result=true, devices=app.devices.devices, verinfo=verinfo}}
		app.server:send(cjson.encode(reply))
	end)

	-- Import the configuration
	import_default_conf()
	--TODO: export
	
	return app
end

--- Aborting flag
local aborting = false
--- Abort the application running
function _M.abort()
	log:warn(app.name, 'Aborting application')
	aborting = true
end

--- The minimum running time for application run loop
local MIN_MS = 50

--- The IO Application running loop
function _M.run()
	aborting = false

	local co = coroutine.create(function (abort)
		local abort = abort or false
		while not abort do
			if _M.handlers.on_run then
				abort = _M.handlers.on_run(app)
			else
				abort = coroutine.yield(false, 1000)
			end
		end
	end)

	local r = true
	local ms = MIN_MS
	while not aborting do
		while not aborting do
			r, aborting, ms = assert(coroutine.resume(co, aborting))
			ms = ms or MIN_MS

			local timer = ztimer.monotonic(ms)
			timer:start()
			while timer:rest() > 0 do
				app:run(timer:rest())
			end
		end
	end
end

return _M

