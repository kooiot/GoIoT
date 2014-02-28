#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local api = require 'shared.api.iobus'
local sub = require 'shared.api.iobus_sub'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
require 'shared.zhelpers'

local ctx = zmq.context()
local poller = zpoller.new()

sub.open("999", ctx, poller, function(filter, data)
	if data then
		print(data)
		local tag = cjson.decode(data)
		for k,v in pairs(tag) do
			print(k,v)
		end
	end
end)

api.subscribe(999, {"modbus.tag1", "modbus.tag2"})

poller:start()

sub.close()
