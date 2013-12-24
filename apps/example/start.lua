#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local configs = require 'shared.api.configs'
local info = require '_ver'
local io = require('apps.io')
local pp = require('shared.PrettyPrint')

local app = nil
local io_ports = {}

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local function on_data(port, msg)
	print(msg)
end

local handlers = {}
handlers.on_start = function(app)
	io_ports.main = assert(io.get_port('main'))

	local r, err = io_ports.main:open(on_data)
	if not r then
		print(err)
	end
	return true
end

handlers.on_timer = function(app)
	--print('timer')
end
--[[
handlers.on_run = function(app)
	print('on_run', os.date())
	print(coroutine.yield(false, 1000))
end
]]--

local port = require('apps.io.port')
io.add_port('main', {port.tcp_client, port.tcp_server, port.serial}, port.tcp_client) 
io.add_port('backup', {port.tcp_client, port.tcp_server, port.serial}, port.tcp_client) 

local setting = require('apps.io.setting')
local command = require('apps.io.command')

local t1 = setting.new('t1')
t1:add_prop('prop1', 'test prop 1', 'number', 11, {min=1, max=99})
io.add_setting(t1)

local c1 = command.new('c1')
c1:add_arg('arg1', 'test arg 1', 'number', 10, {min=1, max=99})
io.add_command(c1)

app = io.init(ioname, handlers)
assert(app)

io.run(3000)

