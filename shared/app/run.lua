#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local pwd = os.getenv('PWD')
local log = require('shared.log')
local ztimer = require('lzmq.timer')

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

ztimer.sleep(1000)
