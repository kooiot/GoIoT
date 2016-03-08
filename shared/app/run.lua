#!/usr/bin/env lua

--- Applicaiton runner which could catch the errors and logging erros
-- @local
-- @usage
-- link or copy this file to your application folder
-- create your own main.lua

local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

--local pwd = os.getenv('PWD')
local log = require('shared.log')
local compat = require('shared.compat.env')
local appenv = require 'shared.app.env'

if #arg < 1 then
	log:error('RUNNER', 'Application should start with its instance name')
	os.exit()
end

if arg[#arg] == '-debug' then
	local path = require('shared.platform').path
	local info = dofile(path.apps..'/_debug') or {}
	info.addr = info.addr or 'localhost'
	info.port = info.port or 8172
	require("mobdebug").start(info.addr, info.port)

	log:info('RUNNER', 'Start application in DEBUG mode, addr:', info.addr, 'port:', info.port)
end

local f, err =  compat.loadfile('main.lua', nil, appenv)
if not f then
	log:error('RUNNER', 'Failed to compile application[', arg[1], ']:', err)
else
	local r, err = pcall(f)

	if not r then
		log:error('RUNNER', 'Application exit with err[', arg[1], ']:', err)
	else
		log:info('RUNNER', 'Application exited normally[', arg[1], ']')
	end
end
----
local ztimer = require('lzmq.timer')
ztimer.sleep(1000)
os.exit()
