#!/usr/bin/env lua

--- Applicaiton runner which could catch the errors and logging erros
-- @local
-- @usage
-- link or copy this file to your application folder
-- create your own main.lua

local m_path = os.getenv('CAD_DIR') or "../../"
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local pwd = os.getenv('PWD')
local log = require('shared.log')

local luafile = arg[1] or 'main.lua'
local srv_name = arg[2] or 'unknown'
log:info('SRV_RUNNER', 'Start service process from file: '..luafile)

local f, err =  loadfile(luafile)
if not f then
	log:error('SRV_RUNNER', 'Failed to compile service[', pwd, ']:', err)
else
	local r, err = pcall(f)

	if not r then
		log:error('SRV_RUNNER', 'Services exit with err[', pwd, ']:', err)
		local api = require 'shared.api.services'
		api.result(srv_name, false, err)
	else
		log:info('SRV_RUNNER', 'Services exited normally[', pwd, ']')
		local api = require 'shared.api.services'
		api.result(srv_name, ture, 'DONE without error')
	end
end
