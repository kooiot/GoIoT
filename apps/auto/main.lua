#!/usr/bin/env lua

require 'shared.zhelpers'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local log = require 'shared.log'
local config = require 'shared.api.config'
local api = require 'shared.api.iobus'
local cjson = require 'cjson.safe'

platform = require "shared.platform"
path_plat = platform.path.apps

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')


local info = {}
info.port = 5631
info.ctx = zmq.context()
info.poller = zpoller.new()
info.name = ioname
local function sleep(n)
	os.execute('sleep '.. n/1000)
end

local function load_conf()

	local path_plat = path_plat .. "/" .. ioname .. "/config/" .. ioname .. "/"
	local filename = path_plat .. ioname .. "_config.json"
	local file, err = io.open(filename, "a+")

	if file then
		local config = file:read("*a")
		if config == "" then
			devices = {}
			t = {}
			table.insert(devices,t)
			config = cjson.encode(devices)
			file:write(config)
		end
		file:close()
		print(config)
		config = cjson.decode(config)
		return config
	end

end

local conf = load_conf()
local rules = {}
--local client = api.new(arg[1], info.ctx, info.poller)


local function on_start()
	print ("---on start---",conf)
	log:info(ioname, 'Starting application[SmartHome]')
	--[[
	for k, v in pairs (conf) do
		if type(v)=="table" then
			conf = v
		end
	end
	--]]
end

local api = require "shared.api.iobus.client"
local client = api.new("config")
local function create_funcs(parentID)
	return {
		get_val = function(name)
--			local api = require "shared.api.iobus.client"
--			local client = api.new("config")
			for k, v in pairs(conf) do
				if v.tree.name == name and v.tree.pId == parentID then
					name = v.config.input
					local r, err = client:read(name)
					if not r then
						return nil, err
					end
					return r.value
				end
			end
		end
	}
end

local function action_ctrl(vars,path)
	local Unit = 0
	local Name = ""
--	local api = require 'shared.api.iobus.client'
--	local client = api.new("auto")
	local commands = {}
	local nss, err = client:enum('.+')
	for k, v in pairs(conf) do
		if tonumber(v.tree.level) == 1 then
			local str = v.config.str
			--print(str)
			local func = require("shared.compat.env").load(str, nil, nil, create_funcs(v.tree.id))
			if func == nil then
			else
			local val = func()
			print(v.config.unit, v.tree.name)
			print(val)
			if val then
				local unit = v.config.unit
				local name = v.tree.name
				if nss then
					for ns, devs in pairs(nss) do

						local tree, err = client:tree(ns)

						if tree then
							for k, dev in pairs(tree.devices) do
								for k, v in pairs(dev.commands) do
									commands[#commands + 1] = {name=v.name, desc=v.desc, path=v.path}

									local r, err = client:command(v.path, {unit=unit,name=name})
								end
							end
						end
					end	
				else
					log:error("what the info is error",err)
				end
			end  end
		end
	end
end



local app = nil
local aborting = false
local function on_close()
	app:close()
	aborting = true
end

app = require('shared.app').new(info, {on_start = on_start, on_close = on_close})
app:init()
--[[
app:reg_request_handler('set_rule', function(app, vars)
	print("----------------",cjson.encode(vars))
	conf.rules = vars
	local r, err = config.set(ioname..'.conf', conf)

	local reply = {'set_rule',  {result=true}}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('get_rule', function(app, vars)
	local reply = {'get_rule',  {result=true, rules=conf}}
	app.server:send(cjson.encode(reply))
end)
--]]
-- The mail loop
local ms = 1000
while not aborting do
	local timer = ztimer.monotonic(ms)
	timer:start()
	while timer:rest() > 0 do
		action_ctrl()
		app:run(timer:rest())
	end
end

