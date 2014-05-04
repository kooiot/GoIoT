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
		type = "app",
		config = config,
	}
end

-- Initialize zmq
local ctx = zmq.context()
local poller = zpoller.new(2)
-- The REQ server
local server = nil

-- The handler table
local mpft = {}

mpft['logs'] = function(vars)
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
	server:send(cjson.encode(reply))
end

mpft['packets'] = function(vars)
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
	server:send(cjson.encode(reply))
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
		send_err(server, 'Unsupported message format')
		return
	end

	local msgtype = json[1]
	if mpft[msgtype] then
		mpft[msgtype](json[2])
	else
		send_err(server, 'No handler for message '..msgtype)
	end
end

local function init()
	-- Loading the configuration from db
	local config = load_config()
	-- Create the handler
	local server, err = ctx:socket({zmq.REP, bind="tcp://127.0.0.1:"..config.port or 5500})
	zassert(server, err)
	server = server
	poller:add(server, zmq.POLLIN, function()
		local msg, err = server:recv()
		if msg then
			on_request(msg)
		end
	end)

	local pub = require 'shared.pub'
	pub.create(ctx, {
		zmq.PUB, 
		bind = "tcp://*:5577"
	})

	local logsrv = require('shared.log.server')(ctx, poller, function(log)
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
end

init()
while true do
	poller:poll(1000)
end
