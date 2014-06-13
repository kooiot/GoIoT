#!/usr/bin/env lua
--[[
-- Save a cached log for web, and publish the log to any one who wants.
]]--

-- TODO: not use the appbase for this core log

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local ztimer = require 'lzmq.timer'
local cjson = require 'cjson.safe'
local fifo = require 'shared.util.fifo'

local cache = fifo({timestamp = ztimer.absolute_time(), src="CORE", level="info", content="Log Start"})
local pcache = fifo()

local function  app_meta()
	return {
		type = "app",
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
			--print('clean logs...')
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
			--print('clean packets...')
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
	--print('on_request')
	local json, err = cjson.decode(msg)
	if not json then
		send_err(server, 'Unsupported message format, json decode error - '..err)
		return
	end
	if not json[1] or not json[2] then
		send_err(server, 'Unsupported message format - JSON FORMAT ERROR')
		return
	end

	local msgtype = json[1]
	if mpft[msgtype] then
		mpft[msgtype](json[2])
	else
		if type(msgtype) ~= 'string' then
			msgtype = 'NOT STRING:'..tostring(msgtype)
		end
		send_err(server, 'No handler for message '..(msgtype or 'nil'))
	end
end

local function init()
	-- Create the handler
	local srv, err = ctx:socket({zmq.REP, bind="tcp://127.0.0.1:5500"})
	zassert(srv, err)
	server = srv
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
		if not log.level then
			return nil, 'Incorrect log object'
		end

		local logstr, err = cjson.encode(log)
		if not logstr then
			return nil, err
		end

		pub.pub(log.level, logstr)

		-- Seperate the packat and log
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
