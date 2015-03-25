#!/usr/bin/env lua

local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local api = require 'shared.api.iobus'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
require 'shared.zhelpers'

local ctx = zmq.context()
local poller = zpoller.new()
local client = api.new(arg[1], ctx, poller)

-- Change of Values callback
local cov = function(path, value)
	print(path, value.value, value.timestamp, value.quality)
end

local tags = client:enum('eeee/unit.1')
for path, v in pairs(tags) do
	for k, v in pairs(v) do
		print(path, k, v)
	end
end

-- Subscribe the device in eeee namespace, named as unit1
client:subscribe('eeee/unit.1', cov)

for v = 1, 1000000000 do
	poller:poll(1000)
	--[[
	print('write inputs data1')
	print(client:write('eeee/unit1/inputs/data1', {value=1}))
	print('write outputs tag1')
	print(client:write('eeee/unit1/outputs/tag1', {value=1}))

	print('command timesync')
	print(client:command('eeee/ts/commands/timesync', {time=os.time()}))
	]]--
end

