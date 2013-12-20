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
app = io.init(ioname, handlers)

assert(app)

io.run(3000)

