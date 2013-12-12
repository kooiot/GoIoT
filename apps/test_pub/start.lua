#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local api = require 'shared.api.data'
local sub = require 'shared.api.data.sub'
local cjson = require 'cjson.safe'
local poller =  require 'lzmq.poller'
require 'shared.zhelpers'

local ctx = zmq.context()

sub.open("999", ctx, poller, function(filter, data)
	if data then
		print(data)
		local tag = cjson.decode(data)
		for k,v in pairs(tag) do
			print(k,v)
		end
	end
end)

api.subscribe(999, {"test.tag1", "test.tag9"})

poller:start()

sub.close()
