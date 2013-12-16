#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local app = nil

local info = {
	version = "1.0",
	build = 'build01',
	name = 'io', -- TODO:
	web = true,
	manufactor = 'OpenGate',
	port = 5515,
	onStart = function ()
		print('onStart')
		return true
	end,
	onStop = function ()
		print('onStop')
		return true
	end,
	onReload = function ()
		print('onReload')
		return true
	end,
	onStatus = function ()
		print('onStatus')
		return true
	end,
}

app = require('shared.app').new(info)

assert(app)

app:init()

local ztimer = require 'lzmq.timer'
local timer = ztimer.monotonic(3000)

while true do
	timer:start()
	while timer:rest() > 0 do
		app:run(timer:rest())
	end
	print('fire event')
	app:firevent('ALL', 'ping', {ping = 'test'})
end

