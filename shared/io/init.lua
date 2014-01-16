#!/usr/bin/env lua

local configs = require 'shared.api.config'
local setting = require 'shared.io.setting'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local pp = require 'shared.PrettyPrint'
local platform = require 'shared.platform'
local log = require 'shared.log'

local app = nil

local function load_config(name)
	local config = {
		port = 5515,
	}

	local ports, err = configs.get(name..'.ports')
	if ports then
		config.ports = ports
	end

	return config 
end

local config = nil

local _M = {}
_M.ports = {}
_M.settings = {}
_M.tags = {}
_M.commands = {}

local function  app_meta()
	return {
		type = "IO",
		config = config,
		ports = _M.ports,
		settings = _M.settings,
		tags = _M.tags,
		commands = _M.commands,
	}
end

function _M.add_setting(item)
	table.insert(_M.settings, item:meta())
end

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

function _M.add_command(cmd)
	table.insert(_M.commands, cmd:meta())
end

function _M.add_port(name, types, default)
	local port = require 'shared.io.port'
	_M.ports[#_M.ports + 1] = {name=name, types = types, default = port[default..'_conf']()}
end

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

function _M.get_port(name)
	local conf, err = get_port_conf(name)
	if not conf then
		return nil, err
	end

	local port = require 'shared.io.port'

	return port.create(app, conf), conf
end

function _M.set_tags(tags)
	_M.tags = tags
end

local function import_default_conf()
	if _M.handlers.on_import then
		local path = platform.path.appdefconf..'/'..app.name..'.csv'
		local file, err = io.open(path, 'r')
		if file then
			file:close()
			local r, err = handlers.on_import(app, vars.filename)
			if not r then
				log:error(app.name, 'Load default configuration failure:', err)
			end
			assert(os.execute('mv '..path..' '..path..'.bak'))
		end
	end
end

function _M.init(name, handlers)
	config = load_config(name)
	_M.handlers = handlers
	handlers.app_meta = app_meta

	if not handlers.on_close then
		handlers.on_close = function(app)
			_M.abort()
		end
	end

	local info = {}
	info.name = name
	info.port = config.port
	app = require('shared.app').new(info, handlers)

	assert(app)

	app:init()

	app:reg_request_handler('import', function(app, vars)
		print('import message received')
		local re = false
		local err = 'Incorrect request found for msg:import'
		if vars.filename  then
			if handlers.on_import then
				re, err = handlers.on_import(app, vars.filename)
			else
				err = 'Import not implemented'
			end
		end
		local reply = {'import', {result=re, err=err}}
		app.server:send(cjson.encode(reply))
	end)

	-- Import the configuration
	import_default_conf()
	--TODO: export
	
	return app
end

local aborting = false
function _M.abort()
	aborting = true
end

local MIN_MS = 50

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

