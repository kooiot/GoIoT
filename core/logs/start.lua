#!/usr/bin/env lua
--[[
-- Save a cached log for web, and publish the log to any one who wants.
]]--

-- TODO: not use the appbase for this core log

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local config_api = require 'shared.api.config'
local fifo = require 'shared.fifo'
local pub = require 'shared.pub'

local info = require '_ver'
local cache = fifo({timestamp = ztimer.absolute_time(), src="CORE", level="info", content="Log Start"})
local pcache = fifo()

local app = nil

local function load_config()
	local debug = true
	if debug then
		return {
			port = 5500,
		}
	end
	local config, err = config_api.get(ioname..'.configs')
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

local function init()
	config = load_config()
	info.port = config.port
	info.app_meta = app_meta
	info.no_port_retry = true

	app = require('shared.app').new(info)
	assert(app)
	app:init()

	return app
end

local function run(app)
	while true do
		app:run(1000)
	end
end

app = init()

pub.create(app.ctx, {
	zmq.PUB, 
	bind = "tcp://*:5577"
})

local srv = require('shared.log.server')(app.ctx, app.poller, function(log)
	local pp = require 'shared.PrettyPrint'
	--print(pp(log))

	pub.pub(log.level, cjson.encode(log))

	-- Do not save the packet to cache
	if log.level == 'packet' then
		pcache:push(log)
		if pcache:length() > 512 then
			pcache:pop()
		end
	else
		cache:push(log)
		if cache:length() > 512 then
			cache:pop()
		end
	end
end)
srv:open()

app:reg_request_handler('logs', function(app, vars)
	print('logs request received')
	--assert(false)
	local caches = {}

	if cache:length() > 0 then
		cache:foreach(function(k,v)
			table.insert(caches, cjson.encode(v))
		end)
		if vars.clean == true then
			print('clean logs...')
			cache:clean()
		end
	end
	local reply = {'logs', {result=true, logs=caches}}	
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('packets', function(app, vars)
	print('logs request received')
	--assert(false)
	local caches = {}
	if pcache:length() > 0 then
		pcache:foreach(function(k,v)
			table.insert(caches, cjson.encode(v))
		end)

		if vars.clean == true then
			print('clean packets...')
			pcache:clean()
		end
	end

	local reply = {'packets', {result=true, logs=caches}}	
	app.server:send(cjson.encode(reply))
end)

run(app)
