#!/usr/bin/env lua
--- IO Application base helper
--

local configs = require 'shared.api.config'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
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
			log:warn(app.name, "Received on_close event")
			app:close()
			return true
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
				log:error(name, 'Command operation failed', err)
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
		log:warn(app.name, 'import message received')
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
		local reply = {'devs', {devices=app.devices.devices, verinfo=verinfo}}
		app.server:send(cjson.encode(reply))
	end)

	-- Import the configuration
	import_default_conf()
	--TODO: export
	
	return app
end

--- The IO Application running loop
-- Blocks until abort been called
function _M.run()
	if _M.handlers.on_run then
		app:add_thread(function()
			app:sleep(0)
			_M.handlers.on_run(app)
		end)
	end
	app:run()
end

return _M

