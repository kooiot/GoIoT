#!/usr/local/bin/lua

--local rs232 = require("luars232")
local cjson = require "cjson"
local serial = require "serial"
local port_name = "/dev/ttyUSB0"
local port = serial.new()
local _M = {}
--打开GPRS设备--
local open = port:open(port_name, nil)	
--延时--
function delay()	
	os.execute("sleep " .. 1)
end	

--发AT测试命令--
_M.at_test = function()
	local write = port:write("AT\r\n",1000)
	print("write = ", write)
	delay()
	local e,data,size =port:read(128,1000)
	print ("the data & size is ", e, data, size, "\r\n")
end

--thread 信号检测
signal_test = function()
	return coroutine.create(function()
	while true do
		port:write("AT+CSQ?\r\n")
		delay()
		local e,data,size = port:read(128, 1000)
		coroutine.yield(data)
		print ("hello i`m in yield thread the signale is ", string.sub(data, string.find(data, "%d%d")))
		end
	end)
end


--gprs 激活--
local gprs_active = function()
	while true do
		port:write('+++')
		delay (500)
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


--thread 发信息
local i = 2
test_message = function(co)
	gprs_active()
	while true do
		coroutine.resume(co)
		delay()
		print("hello i`m in resume thread if the temperature is higher than 40 I will send message")
		if i>1 then
			i = i-1
			port:write("AT+CMGF=1\r\n")
			c_n = string.format("%s%s%s","AT+CSCA=\"+86","13010888500","\"\r\n")
			delay()
			port:write(c_n, 1000)
			p_n = string.format("%s%s%s","AT+CMGS=\"+86","13001143649","\"\r\n")
			delay()
			port:write(p_n,1000)
			delay()
			port:write("hello my name is jack", 1000)
			delay()
			port:write("\x1a\r\n", 1000)
			delay()
			local e,data,size =port:read(128,1000)
			print ("the data & size is ", e, data, size, "\r\n")
		end
	end
	port:close()
end

test_message(signal_test())
	
	

--发信息--
_M.send_message = function (center_number, phone_number, message)
	port:write("AT+CMGF=1\r\n")
	c_n = string.format("%s%s%s","AT+CSCA=\"+86","13800100500","\"\r\n")
	delay()
	port:write(c_n, 1000)
	p_n = string.format("%s%s%s","AT+CMGS=\"+86",phone_number,"\"\r\n")
	delay()
	port:write(p_n,1000)
	delay()
	port:write(message, 1000)
	delay()
	port:write("\x1a\r\n", 1000)
	delay()
	local e,data,size =port:read(128,1000)
	print ("the data & size is ", e, data, size, "\r\n")
	port:close()
end

return _M
