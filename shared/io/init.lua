#!/usr/bin/env lua

local configs = require 'shared.api.config'
local info = require '_ver'
local setting = require 'shared.io.setting'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'

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

	local port = require 'shared.io.port'

	return port.create(app, conf), conf
end

function _M.set_tags(tags)
	_M.tags = tags
end

function _M.init(name, handlers)
	config = load_config()
	_M.handlers = handlers
	info.name = name 
	info.port = config.port
	info.on_start = function()
		if handlers.on_start then
			return handlers.on_start(app)
		else
			return nil, 'Not implemented'
		end
	end
	info.on_stop = function()
		if handlers.on_stop then
			return handlers.on_stop(app)
		else
			return nil, 'Not implemented'
		end
	end
	info.on_reload = function()
		if handlers.on_reload then
			return handlers.on_reload(app)
		else
			return nil, 'Not implemented'
		end
	end
	info.on_status = function()
		if handlers.on_status then
			return handlers.on_status(app)
		else
			return nil, 'Not implemented'
		end
	end

	info.app_meta = app_meta

	app = require('shared.app').new(info)

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

