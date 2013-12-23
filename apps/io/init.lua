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

function _M.add_port(name, port)
	_M.ports[name] = port
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
