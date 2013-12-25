#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local configs = require 'shared.api.configs'
local info = require '_ver'

local app = nil

local function load_config()
	local debug = true
	if debug then
		return {
			port = 5500,
		}
	end
	local config, err = configs.get(ioname..'.configs')
	assert(config, err)

	config, err = cjson.decode(settings)
	assert(config, err)

	return config 
end

local config = nil

local function  app_meta()
	return {
		type = "APP",
		config = config,
	}
end

local function init(name)
	config = load_config()
	info.name = name 
	info.port = config.port
	info.on_start = function()
		-- TODO:
		return true
	end
	info.on_stop = function()
		-- TODO:
		return true
	end
	info.on_reload = function()
		return true
	end
	info.on_status = function()
		return 'running'
	end

	info.app_meta = app_meta

	app = require('shared.app').new(info)

	assert(app)

	app:init()
	
	return app
end

local function save_to_file()
	print('TODO: save to file')
end

local function run(app)
	local ztimer = require 'lzmq.timer'
	local timer = ztimer.monotonic(5000)

	local aborting = false
	while not aborting do
		timer:start()
		while not aborting and timer:rest() > 0 do
			app:run(timer:rest())
		end
		save_to_file()
	end
end

app = init()

local srv = require('shared.log.server')(app.ctx, app.poller, function(log)
	local pp = require 'shared.PrettyPrint'
	print(pp(log))
end)
srv:open()

run(app)
