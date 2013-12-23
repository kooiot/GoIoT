#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local configs = require 'shared.api.configs'
local info = require '_ver'

local app = nil

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local handlers = {}
handlers.on_start = function(app)
	return true
end

handlers.on_timer = function(app)
	print('timer')
end

local io = require('apps.io')

local port = require('apps.io.port')
io.add_port('port', port.tcp_client())

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

