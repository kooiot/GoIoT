#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local app = nil

local ioname = arg[1]
local port = arg[2]
local folder = arg[3]

if not ioname then
	print('Applicaiton needs to have a name')
	os.exit(-1)
end

if not folder then
	folder = ioname
end

local info = {
	version = "1.0",
	build = 'build01',
	name = ioname,
	web = true,
	manufactor = 'OpenGate',
	port = port,
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
	app:firevent('ALL', 'ping', {ping = 'test'})
end

