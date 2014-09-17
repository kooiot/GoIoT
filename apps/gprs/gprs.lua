#!/usr/local/bin/lua

--local rs232 = require("luars232")
local cjson = require "cjson.safe"
local serial = require "serial"
local port_name = "/dev/ttyUSB1"
local port = serial.new()

--打开GPRS设备--
local open = port:open(port_name, nil)	

--延时
local function sleep(n)
	os.execute('sleep ' .. n/1000)
end
--发信息--
local send_message = function (center_number, phone_number, message)
	port:write("AT+CMGF=1\r\n")
	c_n = string.format("%s%s%s","AT+CSCA=\"+86","13800100500","\"\r\n")
	port:write(c_n, 1000)
		sleep(500)
	p_n = string.format("%s%s%s","AT+CMGS=\"+86",phone_number,"\"\r\n")
		sleep(500)
	port:write(p_n,1000)
		sleep(500)
	port:write(message, 1000)
		sleep(500)
	port:write("\x1a\r\n", 1000)
		sleep(500)
	local e,data,size =port:read(128,1000)
	print ("the data & size is ", e, data, size, "\r\n")
	port:close()
end


--发AT测试命令--
local at_test = function()
	local write = port:write("AT\r\n",1000)
	print("write = ", write)
	os.execute('sleep ' .. 1)
	local e,data,size =port:read(128,1000)
	print ("the data & size is ", e, data, size, "\r\n")
end

--thread 信号检测
local flag = 1
local signal_test = function()
	return coroutine.create(function()
		if temperature<10  then
			while true do
			port:write("AT+CSQ?\r\n")
			sleep(500)
			local e,data,size = port:read(128, 1000)
			local i, j = string.find(data, "OK")
			s = string.sub(data, i, j)
			coroutine.yield(data)
				if s ~= "OK" then
				-- warring--
				else
					flag = 1
					print ("hello i`m in yield thread the signale is ", string.sub(data, string.find(data, "%d%d")))
				end
			end
		end
	end)
end
--thread 发信息
local temperature = 1
local test_message = function(co)
	while true do
		coroutine.resume(co)
		sleep(500)
		if flag == 1 and temperature <40 then
		print("hello i`m in resume thread if the temperature is higher than 40 I will send message")
			temperature = temperature+1
			local file = io.open("test.json")
			local c = file:read("*a")
			local t = cjson.decode(c)
			--	send_message(t.center,t.phone, t.message)
			--	send_message(nil,'13001143649', "hello jack i love you")
				print (" hello message have be send")
		end
	end
	port:close()
end

test_message(signal_test())
	
	
