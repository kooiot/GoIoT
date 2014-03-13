#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
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

local cov = function(path, value)
	if data then
		print(data)
		local tag = cjson.decode(data)
		for k,v in pairs(tag) do
			print(k,v)
		end
	end
end

client:subscribe('eeee/unit1', cov)

for v = 1, 100 do
	poller:poll(1000)
	print('write inputs data1')
	print(client:write('eeee/unit1/inputs/data1', {value=1}))
	print('write outputs tag1')
	print(client:write('eeee/unit1/outputs/tag1', {value=1}))

	print('command timesync')
	print(client:command('eeee/ts/commands/timesync', {time=os.time()}))
end

sub.close()
