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
		config = cjson.decode(config)
		return config
	end

end

local conf = load_conf()
local rules = {}
local client = api.new(arg[1], info.ctx, info.poller)


local function on_start()
	print ("---on start---",conf)
	for k, v in pairs (conf) do
		if type(v)=="table" then
			conf = v
			print (conf)
		end
	end
end

local function action_ctrl(vars,path)
	local Unit = 0
	local Name = ""
	local api = require 'shared.api.iobus.client'
	local client = api.new("auto")
	local commands = {}
	local nss, err = client:enum('.+')

		if conf.config.ratio then
			for k,v in pairs(conf.config.ratio) do
				sleep (10)
		--		local r, err = client:read("sys/dev/inputs/time")
				local r, err = client:read(v.Command)
					if r == nil then
						print ("nill")
					end
				if r then
					print ("------command and value ------",v.Command,r.value,v.Compare)
					if type(tonumber(v.Value))=="number" then
						v.Value=tonumber(v.Value)
						r.value=tonumber(r.value)
						if v.Compare == "&gt;" then
							if r.value > v.Value then   --r is true data v is config data
						--		print (">>>>>>")
						--		print ("v.Value",v.Value)	
						--		print ("v.Command",v.Command)	
								Unit =v.Unit
								Name = v.Name
							end
						end
						if v.Compare == "&lt;" then
							if r.value < v.Value then
						--		print ("<<<<<<<<<")
						--		print ("v.Value",v.Value)	
						--		print ("v.Command",v.Command)
								Unit =v.Unit
								Name = v.Name
							end
						end
						if v.Compare == "=" then
						--	print ("=======")
						--	print ("v.Value",v.Value)	
						--	print ("v.Command",v.Command)	
							Unit =v.Unit
							Name = v.Name
						end
					
					else  -----------此处的数据不是单独的数字，而是字符串
						if v.Compare == "[x,y]" then
							local x,_, y = string.match(v.Value,"(%d+)(%W)(%d+)")
							print (v.Value,x,y)
							if x == nil or y == nil then
								log:error("Please input the format like this [x,y] or x-y x,y x~y")
								print ("--------------please input the format like this----[x,y] or x-y x,y x~y")
							else
								x = tonumber(x)
								y = tonumber(y)
								if r.value > x and r.value < y then
								--	print ("[][][][][][][][][][]")
								--	print ("x and y are ",x,y)	
								--	print ("v.Command",v.Command)	
									print ("*******************OKOKOKOKOKOKOK******************")
									Unit =v.Unit
									Name = v.Name
								end
							end
						end
					end
							if nss then
						--		print ("---------------------2-------------------")	
								for ns, devs in pairs(nss) do

									local tree, err = client:tree(ns)

									if tree then
										for k, dev in pairs(tree.devices) do
											for k, v in pairs(dev.commands) do
												commands[#commands + 1] = {name=v.name, desc=v.desc, path=v.path}
												
												local r, err = client:command(v.path, {unit=Unit,name=Name})
											--	print ("the commands is ..", v.path,v.name, v.devname,v.value)
											end
										end
									end
								end	
							else
								log:error("what the info is error",err)
							end
				else
					log:error("nil",err)
				end
			end
		end
	
end


function ctrl_data(state)
	local appapi = require 'shared.api.app'
	local port, err = appapi.find_app_port(ioname)
	local client = appapi.new(port)
	local r, err = client:request('get_rule', {result = state})
	client:close()
end
function func()
--	sleep (3000)
--	ctrl_data()
	action_ctrl()
end		


local app = nil
local aborting = false
local function on_close()
	app:close()
	aborting = true
end

app = require('shared.app').new(info, {on_start = on_start, on_close = on_close})
app:init()
app:reg_request_handler('set_rule', function(app, vars)
	print("----------------",cjson.encode(vars))
	conf.rules = vars
	local r, err = config.set(ioname..'.conf', conf)

	local reply = {'set_rule',  {result=true}}
	app.server:send(cjson.encode(reply))
end)

app:reg_request_handler('get_rule', function(app, vars)
	--local config = require 'shared.api.config'
--	local conf = config.get(ioname ..'.read')
--	action_ctrl(conf.value, conf.path)
	local reply = {'get_rule',  {result=true, rules=conf}}
	app.server:send(cjson.encode(reply))
end)

-- The mail loop
local ms = 1000
while not aborting do
	local timer = ztimer.monotonic(ms)
	timer:start()
	while timer:rest() > 0 do
		func()
		app:run(timer:rest())
	end
end

