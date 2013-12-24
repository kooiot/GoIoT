#!/usr/bin/env lua

local configs = require 'shared.api.configs'
local info = require '_ver'
local setting = require 'apps.io.setting'

local app = nil

local function load_config()
	local debug = true
	if debug then
		return {
			port = 5515,
		}
	end
	local config, err = configs.get(ioname..'.configs')
	assert(config, err)

	config, err = cjson.decode(settings)
	assert(config, err)

	return config 
end

local config = nil

local _M = {}
_M.ports = {}
_M.settings = {}
_M.commands = {}

local function  app_meta()
	return {
		type = "IO",
		config = config,
		ports = _M.ports,
		settings = _M.settings,
		commands = _M.commands
	}
end

function _M.add_setting(item)
	_M.settings[item.name] = item:meta()
end

function _M.get_setting(name)
	if config.settings and config.settings[name] then
		return setting.from(config.settings[name])
	end

	if _M.settings[name] then
		return setting.from(_M.settings[name])
	end
	return nil, 'no such setting'
end

function _M.add_command(cmd)
	_M.commands[cmd.name] = cmd:meta()
end

function _M.add_port(name, types, default)
	local port = require 'apps.io.port'
	_M.ports[#_M.ports + 1] = {name=name, types = types, default = port[default..'_conf']()}
end

local function get_port_conf(name)
	if config.ports and config.ports[name] then
		return config.ports[name]
	end

	for k,v in pairs(_M.ports) do
		if v.name == name then
			return v.default
		end
	end

	return nil, 'no such port'
end

function _M.get_port(name)
	local conf, err = get_port_conf(name)
	if not conf then
		return nil, err
	end

	local port = require 'apps.io.port'

	return port.create(app, conf)
end

function _M.init(name, handlers)
	config = load_config()
	_M.handlers = handlers
	info.name = name 
	info.port = config.port
	info.on_start = function()
		handlers.on_start(app)
	end
	info.on_stop = function()
		handlers.on_stop(app)
	end
	info.on_reload = function()
		handlers.on_reload(app)
	end
	info.on_status = function()
		handlers.on_status(app)
	end

	info.app_meta = app_meta

	app = require('shared.app').new(info)

	assert(app)

	app:init()
	
	return app
end

function _M.run(ms)
	local ms = ms or 1000
	local ztimer = require 'lzmq.timer'
	local timer = ztimer.monotonic(ms)

	while true do
		timer:start()
		while timer:rest() > 0 do
			app:run(timer:rest())
		end
		_M.handlers.on_timer(app)
	end
end

return _M
