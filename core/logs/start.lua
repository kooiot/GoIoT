#!/usr/bin/env lua
--[[
-- Save a cached log for web, and publish the log to any one who wants.
]]--

-- TODO: not use the appbase for this core log

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local config_api = require 'shared.api.config'
local fifo = require 'shared.fifo'

local App = {}

local cache = fifo({timestamp = ztimer.absolute_time(), src="CORE", level="info", content="Log Start"})
local pcache = fifo()

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

local function  app_meta()
	return {
		type = "App",
		config = config,
	}
end

-- The handler table
App.mpft = {}

App.mpft['logs'] = function(app, vars)
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
end

App.mpft['packets'] = function(app, vars)
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
end

local function send_err(server, err)
	local reply = {'error', {err=err}}
	local rep_json = cjson.encode(reply)
	return server:send(rep_json)
end


local function on_request(msg)
	print('on_request')
	local json, err = cjson.decode(msg)
	if not json then
		print('JSON DECODE ERR', err)
		send_err(App.server, 'Unsupported message format')
		return
	end

	local msgtype = json[1]
	if App.mpft[msgtype] then
		App.mpft[msgtype](App, json[2])
	else
		send_err(App.server, 'No handler for message '..msgtype)
	end
end

local function init()
	-- Loading the configuration from db
	App.config = load_config()
	-- Initialize zmq
	App.ctx = zmq.context()
	App.poller = zpoller.new(2)
	-- Create the handler
	local server, err = App.ctx:socket({zmq.REP, bind="tcp://127.0.0.1:"..App.config.port or 5500})
	zassert(server, err)
	App.server = server
	App.poller:add(server, zmq.POLLIN, function()
		local msg, err = App.server:recv()
		if msg then
			on_request(msg)
		end
	end)

	local pub = require 'shared.pub'
	pub.create(App.ctx, {
		zmq.PUB, 
		bind = "tcp://*:5577"
	})

	local logsrv = require('shared.log.server')(App.ctx, App.poller, function(log)
		--local pp = require 'shared.PrettyPrint'
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
	logsrv:open()

	App.pub = pub
	App.logsrv = logsrv
end

init()
while true do
	App.poller:poll(1000)
end
