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


local function add_device_cmd(app, device, name, cmd, desc)
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


--------------------------------------
local tab = {{name="jack.dai",number="13001143649"}}
--[[
local function table_t(app, t)
	for i, v in pairs(t) do
--		print ("...",v)
	if type(v) == "table" then
		assert(add_device_cmd(app, v.name, "name", v.number))
		print ("name",v.name)
		print ("number",v.number)
		t = v
		table_t (t)
		end
	end

end
--]]
local function phone_insert(name, number)	
	local file = io.open("test.json","w+")
	tab[#tab+1] = {name=name, number=number}
	local t =cjson.encode(tab)
	file:write(t)
	file:close()
end


local function phone_read()
	local file = io.open("test.json","r")
	t = file:read("*all")
	print ("-----------before_decode--------------",t)
	t = cjson.decode(t)
	table_t (t)
	file:close()
end

local function load_from_file()
	local file, err = io.open('test.json',"r")
	if not file then
		return nil, err
	end

	local c = file:read('*all')
	print ("-----------before_decode--------------",c)
	file:close()
	return c
end

local function load_conf(app, reload)
	local cmds, err = load_from_file()
	if not cmds then
		log:error(ioname, err or 'Failed to get command configuration')
		return
	end
	cmds = cjson.decode(cmds) or {}
	
	for i, v in pairs(cmds) do
--		print ("...",v)
		if type(v) == "table" then
			assert(add_device_cmd(app, "NUMBER", v.name, v.number))
			print ("name",v.name)
			print ("number",v.number)
			cmds = v
		end
	end
end
----------------------------------------------

--初始化一些东西
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
	--return load_conf(app)
	return add_device_cmd(app, "GPRS", "SEND_MESSAGE", "send_message")
end

handlers.on_write = function (app, path, value, from)
	return nil, 'FIXME'
end


--发信息--
local center_number = 0
--[[
local send_message = function (phone_number, message)
	port:write("                                        ")
		sleep(100)
	port:write("AT+CMGF=1\r\n")
		sleep(300)
	c_n = string.format("%s%s%s","AT+CSCA=\"+",center_number,"\"\r\n")
		sleep(300)
	port:write(c_n, 1000)
		sleep(300)
	p_n = string.format("%s%s%s","AT+CMGS=\"+86",phone_number,"\"\r\n")
		sleep(300)
	port:write(p_n,1000)
		sleep(300)
	port:write(message, 1000)
		sleep(300)
	port:write("\x1a\r\n", 1000)
		sleep(300)
	local e,data,size =port:read(128,1000)
	print ('CTRL+Z====the data & size is ', e, data, size, '\r\n')
	return e
--	port:close()
end
--]]

----------> dec to hex change <-------------
local str = ""
local function void (n) 
	local n1
	local num,b = math.modf(n/16)
	if num > 0 then
		void(num)
	end
	n1 = n%16
	if n1>=0 and n1<=9 then
		str = str .. n1
	else
 		if 10 == n1 then 	
			str = str .. "A"
		end
		if 11 == n1 then
			str = str .. "B"
		end
		if 12 == n1 then
			str = str .. "C"
		end
		if 13 == n1 then
			str = str .. "D"
		end
		if 14 == n1 then
			str = str .. "E"
		end
		if 15 == n1 then
			str = str .. "F"
		end
	end
	return str
end 

----->  utf8 to 32 code <-----------
function Utf8to32(utf8str)
    assert(type(utf8str) == "string")
    local res, seq, val = {}, 0, nil
    for i = 1, #utf8str do
        local c = string.byte(utf8str, i)
        if seq == 0 then
            table.insert(res, val)
            seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
                  c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
                  error("invalid UTF-8 character sequence")
            val = bit32.band(c, 2^(8-seq) - 1)
        else
            val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
			val = tonumber(val)
        end
        seq = seq - 1
    end
    table.insert(res, val)
--    table.insert(res, 0)
    return res
end

-----> return hex length <--------
function length(i)
	if i=="A" or i=="B" or i=="C" or i=="D" or i=="E" then 
		i='0' .. i
		return i
	else
		return i
	end
end
-------> odd and even num change <------	
function sort_number(num)
	local n=""
	local t={}
	local s = string.len(num)
	for k=1, s do
		table.insert(t, string.sub(num,k,k))
	end
	
	for k=1, s do
		if k%2 == 0 then
		n = n .. t[k] .. t[k-1]
		end
	end
		print ("sort_num is", n)
		return n
end

local send_message = function (phone_number, message)
	----------------> deal eglish or chinese string <-------------
	local res={}
	local stri = ""
	res = Utf8to32(message)
	for k, v in pairs (res) do
		local word_1 = ""
		local word_2 = ""
--		word_1 = void(res[k])
		word_1 = res[k]
		str = ""
		word = tonumber(word_1)
		if word ~= nil then
			if word < 256 then
				word_1 = void(res[k])
				word_2 = "00" .. word_1
			else
				word_1 = void(res[k])
				word_2 = word_1
			end
			print ("***************world_2",  word_2)
		
		else
			log:error("what you input is nil", word)
		end
		stri = stri .. word_2

	end
	--------------> deal string length <------------------
	local str_len=nil
	local mes_len =nil
	local sex_len =nil
	local string = nil
	string = stri
	str_len = string.len(stri)
	mes_len = str_len/2
	sex_len = void(mes_len)
	sex_len = length(sex_len)
	print("string &&&&&&&&&&&&& len" , string, mes_len, sex_len)
	------------> deal phone number <------------
	local phone = 0
	local return_phone = 0
	phone = string.format("%s%s%s","86",phone_number,"F")
	return_phone = sort_number(phone)	
--	print ("&&&&&&&&&&&&&&&&&&&phone", return_phone)
	--------> deal message send <--------------
	port:write("                                        ")
		sleep(300)
	port:write("AT+CSCS=\"GSM\"\r\n")
		sleep(300)
	port:write("AT+CMGF=0\r\n")
		sleep(300)
	cmgs = string.format("%s%s%s","AT+CMGS=",mes_len+15,"\r\n")
	port:write(cmgs)
--	port:write("AT+CMGS=25\r\n")
	p_n = string.format("%s%s%s%s%s","0011000D91",return_phone,"0008A7",sex_len,string)
	print ("the send string is ", p_n)
		sleep(300)
	port:write(p_n,4000)
		sleep(300)
--	port:write("\x1a\r\n", 1000)
		sleep(300)
	local e,data,size =port:read(128,1000)
	print ('CTRL+Z====the data & size is ', e, data, size, '\r\n')
	print ("string is *** " ,string)
	return e
--	port:close()
end

local data_read = function(app)
	return nil
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

--	local data = data_read(app)
--	if data == 'VOL' then
--		send_message (center_number, phone_number, message)
--	elseif data == 'TEM' then
--		send_message (center_number, phone_number, message)
--	else
--		print ('There has no group number')
--	end

	local config=require 'shared.api.config'
	local mod = config.get(ioname.. '.mod')
	if mod ~= nil then
		local i, j = string.find(mod, 'send')
	--	local a,b,c,number,message = string.find(mod, "(%a+):(%d+):(%a+)")
		local contant = nil
		contant = Split(mod, "*#!")
	--	print ("****************", contant[1],contant[2], contant[3])
		if (contant[2] and contant[3]) then
			if i and j then
				mod = string.sub(mod, i, j)
				if mod == 'send' then
					print("&^&^&******: ", mod)
					if 11==string.len(contant[2]) then
						local e =send_message(contant[2], contant[3])
						if false==e then
				--		send_message(number,message)
						end
					else
						config.set(ioname.. '.mod', "The phone number is wrong")
					end
					config.set(ioname.. '.mod', "Already send out thank you !!")
				end
			else
			end
		else
			config.set(ioname.. '.mod', "The format of the input is wrong")
		end
	end
end
--gprs have SIM?---
local gprsdata={} --储存了有关gprs信息在网页中显示
gprsdata.timeout=0
local gprs_SIM = function()
	port:write('AT+CPIN?\r\n')
	sleep (100)
	local e, data, size = port:read(128, 1000)
	if data ~= nil then
		local i, j = string.find(data, 'READY')
		if i and j then
			data = string.sub(data, i, j)
		else 
			log:error(data, "the gprs data is wrong perhaps Line empty")
			gprsdata.timeout = gprsdata.timeout +1
			if gprsdata.timeout == 10 then
				gprsdata.state = "the gprs data is wrong perhaps Line empty" --将sim卡状态数据写入table
				exit()
			end
			return
		end
		if data == 'READY' then
			print ("The SIM is", data)
			gprsdata.state = "The SIM is " ..data --将sim卡状态数据写入table
			return data
		else
			log:error(data, "The GPRS has no response")
		return
		end
	end
	print ('Init the SIM ...')
	gprsdata.state = "Init the SIM ..."
	
end

local Center_Number = function()
	print ("Finding the center number !!")
	while true do
		port:write("AT+CSCA?\r\n")
		sleep (500)
		local e, data, size = port:read(128, 1000)
	
		if data ~= nil then
		local i, j = string.find(data, 'OK')
			if i and j then
				local _,_,number = string.find(data,"+(%d+)")
--				print ("***********",data)
				print ("the CSCA:", number)
				data = string.sub(data, i, j)
				center_number = number
			end
			if data == 'OK' then
				print ("Center_Number is OK")
				gprsdata.state="Center_Number is OK"
				break
			end	
		end
	--		print ("Waiting for finding Center_Number")
	end	
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
				print ("Finding the Center_Number...")
				gprsdata.state="Finding the Center_Number ..."
				Center_Number()
				break
			end	
		end
			print ("Waiting for activity")
	end	
end

local info = {}
info.port = 5632
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
---------------------> init the GPRS <-----------------
function gprs_init()
--[[	port:write('+++\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("+++", e,data, size)
	port:write('+++')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("+++", e,data, size)
	port:write('                                        ')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("space",e,data, size)
--]]	
	port:write('AT+LOGIN=admin\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("login", e,data, size)
	port:write('AT+GETPARAM=SPPN\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("param1",e,data, size)
	port:write('AT+GETPARAM=SPSV\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("param2", e,data, size)
	port:write('AT+GETPARAM=SPLAN\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("param3", e,data, size)
	port:write('AT+GETPARAM?')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("the data:", e,data, size)
	port:write('AT+CNUM?')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("the number:", e,data, size)
	port:write('AT+CREG=1\r\n')
	sleep(10)
	local e, data, size = port:read(128, 1000)
	print ("login", e,data, size)

end



local conf, err = config.get(ioname..'.conf')
ggapp = require('shared.app').new(info, {on_start = on_start, on_close = on_close})
--ggapp = require('shared.app').new(info, {})
ggapp:init()
local gprs_signal=function()
	port:write('          ')
	sleep(10)
	port:write('AT+CSQ?\r\n')
	sleep(10)
	local r, data, size = port:read(128, 1000)
	sleep(10)
--	print ('signal data is: ', data)
	local s=0
	if r then
		local i, j = string.find(data, 'OK')
	--	sleep (100)
		if i and j then
			local a, b = string.find(data, '(%d+)')
			print ('a, b', a, b)
			if a and b then
				s = string.sub(data, string.find(data, '(%d+)'))
				--s = tonumber(s)
				data = string.sub(data, i, j)
			end
			else
		end	
		if data == 'OK' then 
	--		print ('the signale is: ', s) --signale state
			gprsdata.signal=s ------gprs.signal
		else
--			print ('if waitting 2 min you have to restart the gprs')
		end
--			print ("in gprs_data ***********************")
	else
		return nil
	end
	print ("*********************************************", s)
	return s
end

ggapp:reg_request_handler('gprs_data', function(ggapp, vars)
	
		local s = gprs_signal()
	--	local s = 20
		local reply = {'gprs_data', {result=true, rules=gprsdata}}
		ggapp.server:send(cjson.encode(reply))
end)

local ts = ztimer.absolute_time()
local ms = 1
local function gprs_data()
	local timer = ztimer.monotonic(ms)
		timer:start()
		while timer:rest() > 0 do
		ggapp:run(timer:rest())
		end
end

handlers.on_command = function(app, path, value, from)
	local match = '^'..ioname..'/([^/]+)/commands/(.+)'
	local devname, cmd = path:match(match)

	print ("***************************")

	if devname == "GPRS" and cmd == "SEND_MESSAGE" then
		print ("----------read---SEND--------",app,path,devname,cmd,value.tel,value.mes,from)
	send_message(value.tel, value.mes)
	end

end

handlers.on_run = function(app)
	local abort = false
	gprs_active(app)
	gprs_init()
	
	while not abort do
		gprs_data()
		gprsdata.state="The GSM is READY"
		message_state(app)--检测是否发测试信息
		
		abort = coroutine.yield(false, 50)
	end
	gprsdata.state="Please restart the GSM"
	return coroutine.yield(false, 1000)
end

local gapp = ioapp.init(ioname, handlers)
assert(gapp)

ioapp.run()


