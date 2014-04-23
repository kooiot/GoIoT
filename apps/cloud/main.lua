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

local buf = require 'dbuf'

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
buf.set_api(cloudapi)

local client = api.new(arg[1], info.ctx, info.poller)

local function query_tree(ns)
	assert(ns, 'Namespace cannot be nil')
	local trees, err = client:tree(ns)

	local pp = require 'shared.PrettyPrint'
	if trees then
		local verinfo = trees.verinfo
		print(pp(verinfo))
		for k, v in pairs(trees.devices) do
			buf.add_dev(v)
		end
	else
		assert(false, err)
	end
end

client:onupdate(function(namespace) 
	query_tree(namespace)
end)

local function cov(path, value)
	--print('data changed on ', path)
	buf.add_cov(path, value)
end

local function on_start()
	client:subscribe('^.+', cov)
	local devs, err = client:enum('.+')
	if not devs then
		assert(false, err)
	else
		for ns, dlist in pairs(devs) do
			query_tree(ns)
		end
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
	buf.on_send(cb)
end

local ms = 1000 * 60 * 2
while not aborting do
	while not aborting do
		save_all(function() app:run(50) end)
		local timer = ztimer.monotonic(ms)
		timer:start()
		while timer:rest() > 0 do
			app:run(timer:rest())
		end
		-- For testing
		-- aborting = true
	end
end

