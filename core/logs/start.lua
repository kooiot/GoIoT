#!/usr/bin/env lua
--[[
-- Save a cached log for web, and publish the log to any one who wants.
]]--

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local zmq = require 'lzmq'
local cjson = require 'cjson.safe'
local configs = require 'shared.api.configs'
local fifo = require 'shared.fifo'
local pub = require 'shared.pub'

local info = require '_ver'
local cache = fifo('Log Start...')
local pcache = filo()

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

local function init()
	config = load_config()
	info.port = config.port
	info.app_meta = app_meta

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

app:reg_request_handler('logs', function(app, msg)
	print('logs request received')
	--assert(false)
	local caches = {}
	cache:foreach(function(k,v)
		table.insert(caches, cjson.encode(v))
	end)
	local reply = {'logs', {result=true, logs=caches}}	
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('packets', function(app, msg)
	print('logs request received')
	--assert(false)
	local caches = {}
	pcache:foreach(function(k,v)
		table.insert(caches, cjson.encode(v))
	end)
	local reply = {'packets', {result=true, logs=caches}}	
	app.server:send(cjson.encode(reply))
end)

run(app)
