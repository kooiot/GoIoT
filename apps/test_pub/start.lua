#!/usr/bin/env lua

local m_path = '/home/cch/cad2/app/shared/'
local m_package_path = package.path  
package.path = string.format("%s;%s?.lua;%s?/init.lua", m_package_path, m_path, m_path)  

local api = require 'api'
local sub = require 'sub'
local cjson = require 'cjson.safe'
require 'zhelpers'

sub.open("999")
api.subscribe(999, {"test.tag1", "test.tag9"})

local loop = true
while loop do
	local msg = sub.recv()
	if msg then
		print(msg)
		tag = cjson.decode(msg)
		for k,v in pairs(tag) do
			print(k,v)
		end
	else
		print('did not got data')
	end
	--sleep(1)
end

sub.close()
