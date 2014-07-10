#!/usr/bin/env lua

local api = require 'shared.api.iobus'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local cloudapi = require 'api'
local logsub = require 'logsub'
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

local client = api.new(arg[1], info.ctx, info.poller)
logsub.open(info.ctx, info.poller)

local function load_conf()
	local config, err = config.get(ioname..'.conf')
	if config and type(config) == 'string' then
		config, err = cjson.decode(config)
	end
	config = config or {}
	config.key = config.key or "6015c744795762df41e9ebfa25fd625c"
	config.url = config.url or 'http://172.30.1.121:8080/api/'
	config.timeout = config.timeout or 5
	return config
end

local function on_write(path, value)
	log:warn(ioname, 'Write on path ', path)
	return client:write(path, value)
end

local function on_command(path, args)
	log:warn(ioname, 'Command on path ', path)
	return client:command(path, args)
end

local conf = load_conf()

log:debug(ioname, 'SERVER ', conf.url)

cloudapi.init(conf, on_write, on_command)

buf.set_api(cloudapi)
logsub.set_api(cloudapi)

local function query_tree(ns)
	assert(ns, 'Namespace cannot be nil')
	local trees, err = client:tree(ns)

	if trees then
		local verinfo = trees.verinfo
		--[[
		local pp = require 'shared.PrettyPrint'
		print(pp(trees))
		print(pp(verinfo))
		]]--
		for k, v in pairs(trees.devices) do
			v.version = verinfo
			buf.add_dev(v)
		end
	else
		log:error(ioname, err)
	end
end

client:onupdate(function(namespace) 
	query_tree(namespace)
end)

local function cov(path, value)
	return buf.add_cov(path, value)
end

local function on_start()
	client:subscribe('^.+', cov)
	local devs, err = client:enum('.+')
	if not devs then
		log:error(ioname, err)
		return nil, err
	else
		for ns, dlist in pairs(devs) do
			query_tree(ns)
		end
	end
	return true
end

local app = nil
local aborting = false
local function on_close()
	app:close()
	aborting = true
	return true
end

app = require('shared.app').new(info, {on_start = on_start, on_close = on_close})
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

local function task_run(cb)
	--log:debug(ioname, 'One run')
	cloudapi.ping()
	cloudapi.pull(cb)
	buf.on_create(cb)
	buf.on_send(cb)
	cloudapi.push(cb)
end

-- The mail loop
local ms = 1000 * 3
while not aborting do
	task_run(function() app:run(50) end)
	local timer = ztimer.monotonic(ms)
	timer:start()
	while timer:rest() > 0 do
		app:run(timer:rest())
	end
end

