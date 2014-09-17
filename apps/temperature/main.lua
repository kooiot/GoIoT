local serial = require 'serial'

local ioapp = require 'shared.io'
local log = require 'shared.log'

local ioname = arg[1]
local port = serial.new()

local handlers = {}

--延时
local function sleep(n)
	os.execute('sleep ' .. n/1000)
end

handlers.on_start = function(app)
	log:info(ioname, 'Starting application[TEMPERATURE]')
	if port:is_open() then 
		return true
	end
	
	local config = require 'shared.api.config'
	local port_name = config.get(ioname .. '.port') or '/dev/ttyUSB0'
	local r, err = port:open(port_name)
	if not r then 
		log:error(ioname, err)
		return nil
	end
end

handlers.on_write = function (app, path, value, from)
	return nil, 'FIXME'
end

--Split the string 
function Split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	local i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i=i+1
	end
	return t
end

local message_state = function(app)

	local config=require 'shared.api.config'
	local mod = config.get(ioname.. '.mod')
	if mod ~= nil then
		local i, j = string.find(mod, 'send')
		local contant = nil
		contant = Split(mod, "*#!")
		print ("****************", contant[1],contant[2], contant[3])
	end
end

local function message_contral()
	local api = require 'shared.api.iobus.client'
	local client = api.new("client")
	local commands = {}

	print ("---------------------1-------------------")	
	local nss, err = client:enum('.+')

	if nss then
	print ("---------------------2-------------------")	
		for ns, devs in pairs(nss) do

			local tree, err = client:tree(ns)

			if tree then
				for k, dev in pairs(tree.devices) do
					for k, v in pairs(dev.commands) do
						commands[#commands + 1] = {name=v.name, desc=v.desc, path=v.path}

						
						local config=require 'shared.api.config'
						local mod = config.get(ioname.. '.mod')
						local contant = nil
						if mod ~= nil then
							local i, j = string.find(mod, 'send')
							contant = Split(mod, "*#!")
							print ("*******2*********", contant[1],contant[2], contant[3])
						end
			
	print ("---------------------3-------------------")	
						local r, err = client:command(v.path, {tel=contant[2],mes=contant[3],group="TEMPERATURE",grade ="1"})
						print ("the commands is ..", v.path,v.name, v.devname)
					end
				end
			end
		end	
	else
		log:error("what the info is error",err)
	end

end


handlers.on_run = function(app)
	local abort = false
	while not abort do
		sleep (8000)
		print ("*")
		message_contral()
	--	message_state(app)
		abort = coroutine.yield(false, 50)
	end
	return coroutine.yield(false, 1000)
end

local gapp = ioapp.init(ioname, handlers)
assert(gapp)


ioapp.run()


