local rs232 = require("luars232")

local class = {}

--- Open serial port
-- Linux
-- port_name = "/dev/ttyS0"
-- (Open)BSD
-- port_name = "/dev/cua00"
-- Windows
--port_name = "COM1"
-- @tparam string port_name the searial port name 
-- @tparam table option table
-- @tparam function callback function(data)
function class:open(port_name, opt, callback)
	-- open port
	local e, p = rs232.open(port_name)
	if e ~= rs232.RS232_ERR_NOERROR then
		-- handle error
		return nil, string.format("can't open serial port '%s', error: '%s'", port_name, rs232.error_tostring(e))
	end

	local opt = opt or {}
	opt.baudrate = tostring(opt.baudrate or 9600)
	opt.databits = tostring(opt.databits or 8)
	opt.parity = tostring(opt.parity or 'NONE')
	opt.stopbits = tostring(opt.stopbits or '1')
	opt.flowcontrol = tostring(opt.flowcontrol or 'OFF')

	-- set port settings
	assert(p:set_baud_rate(rs232['RS232_BAUD_'..opt.baudrate]) == rs232.RS232_ERR_NOERROR)
	assert(p:set_data_bits(rs232['RS232_DATA_'..opt.databits]) == rs232.RS232_ERR_NOERROR)
	assert(p:set_parity(rs232['RS232_PARITY_'..opt.parity]) == rs232.RS232_ERR_NOERROR)
	assert(p:set_stop_bits(rs232['RS232_STOP_'..opt.stopbits]) == rs232.RS232_ERR_NOERROR)
	assert(p:set_flow_control(rs232['RS232_FLOW_'..opt.flowcontrol]) == rs232.RS232_ERR_NOERROR)

	print(string.format("OK, port open with values '%s'", tostring(p)))
	self.port = p
	self.callback = callback

	self.app:add_thread(function()
		while not self._close do
			if self.app:sleep(0) then
				break
			end
			local r, data, size = self:read(64, 10)
			if r then
				self.callback(data, size)
			end
		end
	end)

	return true
end

--- Read data from serial port
-- @tparam number len the length you want to read from searial
-- @tparam number timeout the timeout in ms for reading
-- @treturn boolean whether reading is success or not
-- @treturn string the data read from serial
-- @treturn number the size of data
function class:_read(len, timeout)
	if not self.port then 
		return false, '', 0
	end

	assert(len)
	-- read with timeout
	local timeout = timeout or self.read_timeout -- in miliseconds
	local e, data_read, size = self.port:read(len, timeout)
	return e == rs232.RS232_ERR_NOERROR, data_read, size
end

--- Write data to serial port
-- @tparam string data
-- @tparam number timeout timeout in ms for writing operation
function class:write(data, timeout)
	if not self.port then
		return false, 0
	end

	-- write with timeout 1000 msec
	local e, len_written = self.port:write(data, timeout or self.write_timeout)
	return e == rs232.RS232_ERR_NOERROR, len_written
end

function class:close()
	if not self.port then
		return
	end
	self._close = true
	self.app:sleep(10)

	-- close
	assert(self.port:close() == rs232.RS232_ERR_NOERROR)
	self.port = nil
end

function class:set_timeout(write, read)
	self.write_timeout = write or 100
	self.read_timeout = read or 1000
end

function class:is_open()
	return self.port
end

return {
	---- Create new serial port interface
	-- @tparam object app application object
	new = function(app)
		local obj = {
			app = app,
			write_timeout = 100,
			read_timeout = 1000,
		}
		return setmetatable(obj, {__index=class})
	end
}
