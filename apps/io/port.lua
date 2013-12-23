
local class={}

local function serial_conf()
	return {type='serial', props = {
		index={type='number', value=''},
		baudrate={type='number', value=9600, vals={4800, 9600, 38400, 115200}},
		stop={type='number', value=1, vals={0, 1, 1.5, 2}},
		-- TODO:
	}}
end

local function tcp_server_conf()
	return {type='tcp_server', props = {
		port={type='number', value='6000'},
		local_addr={type='string', value='*'},
	}}
end

local function tcp_client_conf()
	return {type='tcp_client', props = {
		port={type='number', value='8000'},
		local_addr={type='string', value='*'},
		remote_addr={type='string', value='172.30.11.28'},
	}}
end

local function create_tcp_server(app, props)
end

local function create_tcp_client(app, props)
	local remote_addr = props.remote_addr.value
	local port = props.port.value 
	local tcpc = require 'apps.io.tcp.client'
	return tcpc.new(app.ctx, app.poller, remote_addr, port)
end

local function create(app, conf)
	if conf.type == 'tcp_client' then
		return create_tcp_client(app, conf.props)
	end
	if conf.type == 'tcp_server' then
		return create_tcp_server(app, conf.props)
	end
	return nil, "not support port"
end

return {
	create = create,
	serial = 'serial',
	serial_conf = serial_conf,
	tcp_server = 'tcp_server',
	tcp_server_conf = tcp_server_conf,
	tcp_client = 'tcp_client',
	tcp_client_conf = tcp_client_conf,
}

