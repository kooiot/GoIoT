local serial = require 'serial'

local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ioapp = require 'shared.io'
local cjson = require 'cjson.safe'
local log = require 'shared.log'
local object_ = require 'shared.io.devs'
local config = require 'shared.api.config'
local ztimer = require 'lzmq.timer'

local ioname = arg[1]
local port = serial.new()

local handlers = {}
local commands = {}

--延时
local function sleep(n)
	os.execute('sleep ' .. n/1000)
end

local function load_from_file()
	local file, err = io.open('conf.json')
	if not file then
		return nil, err
	end

	local cmd = file:read('*a')
	file:close()
	return cmd
end

local function add_the_number(app, device, name, cmd, desc)
	if not device or not name then
		return nil, 'no device no name'
	end

	local dev = app.devices:get(device)
		if not dev then
		dev = app.devices:add(device, 'GPRS Devices ['..device..']')
	end

	--local input = dev.inputs:get(name)

	if not dev then
		return nil, 'Cannot create devices for ' .. device
	end

	print('Added command '..device..':'..name..":"..cmd)
	local obj = dev.commands:get(name)
	if not obj then
		local r, err = dev.commands:add(name, desc or 'Control command',{})
		if not r then
			return nil, err
		end
	end

	if cmd then
		commands[device] = commands[device] or {}
		commands[device][name] = cmd
	end
	return true
end

local function load_conf(app, reload)
	local cmds, err = load_from_file()
	if not cmds then
		log:error(ioname, err or 'Failde to get command configuration')
		return
	end
	cmds = cjson.decode(cmds) or {}
	if cmds then
		for devname, cmds in pairs(cmds) do
			if type(cmds) ~= 'table' then
				break
			end

			for name, cmd in pairs(cmds) do
				assert(add_the_number(app, devname, name, cmd))
			end
		end
	end
end

--初始化并且加载配置文件
handlers.on_start = function(app)
	log:info(ioname, 'Starting application[GPRS]')
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
	return load_conf(app)
end

local function reading(app)
	local abort = false
	local timer = ztimer.monotonic(1000)
	local len = string.byte(learn_table.result)
	timer:start()
	while not abort and timer:rest() > 0 do
		local r, data, size = port:read(8)
		if r then
			print('2: ',data)
			learn_table.result = learn_table.result..data
			if len and string.len(learn_table.result) == len then
				print ('finished reading', len)
				break
			end
		else
			abort = coroutine.yield(false, 50)
		end
	end
	if port:read(1) then
		print('*************')
	end

	local f = io.open('/tmp/gprs_learn_result', 'w+')
	f:write(learn_table.reault)
	f:close()
	
	learn_table.learning = false
end


handlers.on_write = function (app, path, value, from)
	return nil, 'FIXME'
end

--发信息--
local send_message = function (center_number, phone_number, message)
	port:write('AT+CMGF=1\r\n')
	c_n = string.format('%s%s%s','AT+CSCA=\'+86','13800100500','\'\r\n')
	port:write(c_n, 1000)
		sleep(500)
	p_n = string.format('%s%s%s','AT+CMGS=\'+86',phone_number,'\'\r\n')
		sleep(500)
	port:write(p_n,1000)
		sleep(500)
	port:write(message, 1000)
		sleep(500)
	port:write('\x1a\r\n', 1000)
		sleep(500)
	local e,data,size =port:read(128,1000)
	print ('the data & size is ', e, data, size, '\r\n')
	port:close()
end

local data_read = function(app)
	return nil
end

local message_state = function(app)

	local data = data_read(app)
	if data == 'VOL' then
		send_message (center_number, phone_number, message)
	elseif data == 'TEM' then
		send_message (center_number, phone_number, message)
	else
		print ('There has no group number')
	end
end

--gprs have SIM?---
local gprs_SIM = function()
	port:write('AT+CPIN?\r\n')
	sleep (500)
	local e, data, size = port:read(128, 1000)
	if data ~= nil then
		local i, j = string.find(data, 'READY')
		if i and j then
			data = string.sub(data, i, j)
		else 
		--	log:error(data, "the gprs data is wrong perhaps Line empty")
		return
		end
		if data == 'READY' then
			print ("The SIM is", data)
			return data
		else
		--	log:error(data, "The GPRS has no response")
		return
		end
	end
	print ('Init the SIM ...')
	local file, err = io.open('conf.json')
	local text = file:read('*a')
	text = cjson.decode(text)
	text.SIGNAL="hello my name is SIGNAL"
	print(text.SIGNAL)
	file:close()
	
end

--gprs 激活--
local gprs_active = function(app)
	while true do
		gprs_SIM()
		port:write('+++')
		sleep (500)
		local e, data, _ = port:read(128, 1000)	
		if data ~= nil then
		local i, j = string.find(data, 'OK')
			if i and j then
				data = string.sub(data, i, j)
			end
			if data == 'OK' then
				print ("The GPRS is active")
				break
			end	
		end
			print ("Waiting for activity")
	end	
end

local ms = 1000
local info = {}
info.port = 5631
info.ctx = zmq.context()
info.poller = zpoller.new()
info.name = ioname

local function on_start()
	return
end

local ggapp = nil
local aborting = false
local function on_close()
	ggapp:close()
	aborting = true
end
--local rules = {}
local signal_data=0
local conf, err = config.get(ioname..'.conf')
ggapp = require('shared.app').new(info, {on_start = on_start, on_close = on_close})
ggapp:init()
ggapp:reg_request_handler('gprs_data', function(ggapp, vars)
				while true do
				message_state(app)
				local reply = {'gprs_data', {result=true, rules=signal_data}}

				print ("in gprs_data ***********************")
				ggapp.server:send(cjson.encode(reply))
				end
				end)


local ts = ztimer.absolute_time()

local function gprs_data()
	local timer = ztimer.monotonic(ms)
	timer:start()
		while timer:rest() > 0 do
		ggapp:run(timer:rest())
		end
end

handlers.on_run = function(app)
	local abort = false
	gprs_active(app)
	
	while not abort do
		gprs_SIM()
		port:write('AT+CSQ?\r\n')
		sleep(500)
		local r, data, size = port:read(128, 1000)	
	--	print ('signal data is: ', data)
		local s
		if r then
			local i, j = string.find(data, 'OK')
			sleep (500)
			if i and j then
				s = string.sub(data, string.find(data, '%d%d'))
				s = tonumber(s)
				data = string.sub(data, i, j)	
			end
			
			if data == 'OK' then 
				if s< 20 then
					--warnning--
					print ('the signal is weak < 20.. ', s)
				--	log:info('The signal is weak now is ', s)
				end
				message_state(app)
				print ('the signale is: ', s) --signale state
				signal_data = s
				gprs_data()
				--dev.inputs:set(s, ts, 1)--------------
				--sleep(500)
			--	port:write('AT+CPBS="ON"\r\n')
			--	sleep(500)
			--	port:write('AT+CPBW=1,\'15622871913\'\r\n')
			--	sleep(500)
			--	port:write('AT+CNUM\r\n')
			--	sleep(500)
			--	local r, data, size = port:read(128, 1000)
			--	print("the number is : ", data)
				print ("ioname = : ", ioname)
			else
				--warnning--
				print ('if waitting 2 min you have to restart the gprs')
			end
		else
			log:error(data, 'The data is wrong of the GPRS')
			abort = coroutine.yield(false, 50)
			break
		end
	end
	return coroutine.yield(false, 1000)
end

print ("before request****************************")
local gapp = ioapp.init(ioname, handlers)
assert(gapp)


ioapp.run()


