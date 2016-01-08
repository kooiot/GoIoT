#!/usr/bin/env lua

require 'shared.zhelpers'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local log = require 'shared.log'
local config = require 'shared.api.config'
local api = require 'shared.api.iobus'
local cjson = require 'cjson.safe'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local info = {}
info.port = 5631
info.ctx = zmq.context()
info.poller = zpoller.new()
info.name = ioname

local function load_conf()
	local conf, err = config.get(ioname..'.conf')
	return conf or {
		--rules = { ['^.+'] = {' return function(path, value, client) print(path, value, client) end '}}
		--rules = { ['eeee/unit.1/inputs/data2'] = {[[ return function(path, value, client) SEND_CMD('gree/ir/commands/send', {'GREE/开机'}) end ]]}}
		--rules = { ['eeee/unit.1/inputs/data2'] = {[[ return function(path, value, client) SEND_CMD('gree/GREE/commands/开机', {'GREE/开机'}) end ]]}}
	}
end

local conf = load_conf()
local rules = {}
local client = api.new(arg[1], info.ctx, info.poller)

function SEND_CMD(path, vars, desc)
	log:warn(ioname, desc or 'Action triggered for path: '..path)
	return client:command(path, vars)
end

local last_values = {}
function GET_LAST_VALUE(path, new_value)
	local value = last_values[path]
	last_values[path] = new_value
	return value
end

client:onupdate(function(namespace) 
	--print('New namesapce online ', namespace)
end)

local function cov(path, value)
	--print('data changed on ', path)
	for k, v in pairs(rules) do
		if path:match(k) then
			--print('Matched rule', k)
			for _, f in pairs(v) do
				f(path, value, client)
			end
		end
	end
end

local function on_start()
	local CE = require 'shared.compat.env'
	local load = CE.load
	if conf.rules then
		for k, v in pairs(conf.rules) do
			log:debug(ioname, 'Subscribe path '..k)
			client:subscribe(k, cov)
			rules[k] = {}
			local t = rules[k]
			for _, dostr in pairs(v) do
				local f = load(dostr)
				if f then
					t[#t + 1] = f()
				end
			end
		end
	else
		log:debug(ioname, 'No auto-control rules found in configuration')
	end
end

local app = nil
local aborting = false
local function on_close()
	app:close()
	aborting = true
end

app = require('shared.app').new(info, {start = on_start, close = on_close})
app:init()
app:reg_request_handler('set_rule', function(app, vars)
	--print(cjson.encode(vars))
	conf.rules = vars
	local r, err = config.set(ioname..'.conf', conf)

	local reply = {'set_rule',  {result=true}}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('get_rule', function(app, vars)
	local reply = {'get_rule',  {result=true, rules=conf.rules}}
	app.server:send(cjson.encode(reply))
end)


-- The mail loop
local ms = 1000
while not aborting do
	local timer = ztimer.monotonic(ms)
	timer:start()
	while timer:rest() > 0 do
		app:run(timer:rest())
	end
end

