local copas = require 'copas'

local app = {}

function app:add_server(server, handler, timeout)
	return copas.addserver(server, handler, timeout)
end

local m = require 'init'

local udp = m.new(app, '*', 4000)

print(udp:open(function(data, ip, port) 
	print(data, ip, port)
	--  skip data sent by ourself
	if ip == '192.168.56.2' and port == 4000 then
		return
	end
	-- Send something here
	--udp:send('+', '192.168.56.255', 4001)
end))

copas.addthread(function()
	print("This will print immediately, upon adding the thread. So before the loop starts")
	while true do
		copas.sleep(5) -- 1 second interval
		print(os.date())
		udp:send('Hello', '192.168.56.255', 4000)
	end
end)

copas.loop()
