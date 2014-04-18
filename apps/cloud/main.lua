#!/usr/bin/env lua

local api = require 'shared.api.iobus'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local cloudapi = require 'cloudapi'
local log = require 'shared.log'
local config = require 'shared.api.config'

require 'shared.zhelpers'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local info = {}
info.port = 5611
info.ctx = zmq.context()
info.poller = zpoller.new()
info.name = ioname

local function load_key()
	local config_key = config.get(ioname..'.key')
	return config_key or "6015c744795762df41e9ebfa25fd625c"
end
local KEY = load_key()
assert(KEY, "No Cloud Auth key")
cloudapi.init(KEY)

local client = api.new(arg[1], info.ctx, info.poller)
local function on_start()
	local pp = require 'shared.PrettyPrint'
	local trees, err = client:tree('eeee')
	if trees then
		local verinfo = trees.verinfo
		print(pp(verinfo))
		for k, v in pairs(trees.devices) do
			-- Create devices in cloud
			--print(pp(v))
		end
	else
		assert(false, 'failureeeeeeeeee')
	end
end

app = require('shared.app').new(info, {on_start = on_start})
app:init()
app:reg_request_handler('list_devices', function(app, vars)
	local devs = {}
	--[[
	for name, dev in pairs(dtree) do
		table.insert(devs, {name=name, id=dev.id})
	end
	]]
	local reply = {'list_devices',  {result=true, devs=devs}}
	app.server:send(cjson.encode(reply))
end)

local function save_all(cb)
	cb()
end

local ms = 3000
while not aborting do
	while not aborting do
		local timer = ztimer.monotonic(ms)
		timer:start()
		while timer:rest() > 0 do
			app:run(timer:rest())
		end
		save_all(function() app:run(50) end)
	end
end

