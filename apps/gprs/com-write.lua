
local serial = require 'serial'
local port = serial.new()
local port_name = '/dev/ttyUSB0'	
local r, err = port:open(port_name)
--延时
local function sleep(n)
	os.execute('sleep ' .. n/1000)
end

function gprs_init()
	port:write('+++\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("+++", e,data, size)
	port:write('+++')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("+++", e,data, size)
	port:write('                                        ')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("space",e,data, size)
	port:write('AT+LOGIN=admin\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("login", e,data, size)
	port:write('AT+GETPARAM=SPPN\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("param1",e,data, size)
	port:write('AT+GETPARAM=SPSV\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("param2", e,data, size)
	port:write('AT+GETPARAM=SPLAN\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("param3", e,data, size)
	port:write('AT+GETPARAM?')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("the data:", e,data, size)
	port:write('AT+CNUM?')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("the number:", e,data, size)

	local _,_,a,b = string.find(data, "CHPSN=(%d+)")

	print ("**************************", a,b)
	
	port:write('AT+CSCA?\r\n')
	sleep(100)
	local e, data, size = port:read(128, 1000)
	print ("the CSCA:", e,data, size)
end

gprs_init()
	
