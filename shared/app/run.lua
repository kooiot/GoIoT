#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

if arg[#arg] == '-debug' then
	local info = dofile('/tmp/apps/_debug') or {}
	info.addr = info.addr or 'localhost'
	info.port = info.port or 8172
	require("mobdebug").start(info.addr, info.port)

	local log = require('shared.log')
	log:info('RUNNER', 'Start application in DEBUG mode, addr:', info.addr, 'port:', info.port)
end

local pwd = os.getenv('PWD')
local log = require('shared.log')

local f, err =  loadfile('main.lua')
if not f then
	log:error('RUNNER', 'Failed to compile application[', pwd, ']:', err)
else
	local r, err = pcall(f)

	if not r then
		log:error('RUNNER', 'Application exit with err[', pwd, ']:', err)
	else
		log:info('RUNNER', 'Application exited normally[', pwd, ']')
	end
end

local ztimer = require('lzmq.timer')
ztimer.sleep(1000)
