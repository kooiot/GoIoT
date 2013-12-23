
local class={}

local function serial()
	return {type='serial', props = {
		index={type='number', value=''},
		baudrate={type='number', value=9600, vals={4800, 9600, 38400, 115200}},
		stop={type='number', value=1, vals={0, 1, 1.5, 2}},
		-- TODO:
	}}
end

local function tcp_server()
	return {type='tcp_server', props = {
		port={type='number', value='6000'},
		local_addr={type='string', value='localhost'},
	}}
end

local function tcp_client()
	return {type='tcp_server', props = {
		port={type='number', value='6000'},
		local_addr={type='string', value='localhost'},
	}}
end

return {
	serial = serial,
	tcp_server = tcp_server,
	tcp_client = tcp_client,
}

