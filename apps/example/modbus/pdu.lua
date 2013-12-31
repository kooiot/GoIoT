
local encode = require('modbus.encode')
local decode = require('modbus.decode')
local code = require('modbus.code')

local _M = {}

function _M.max_size()
	return 253
end

local function create_pdu(fc)
	local obj = {
		fc = fc,
		max_size = _M.max_size,
		data = {},
		raw_data = {},
	}
	return {
		append = function(self, name, val) 
			obj.data[#obj.data + 1] = { name = name, val = val }
			obj.raw_data[#obj.raw_data + 1] = encode[name](val)
		end,
		reset = function(self)
			obj.data = {}
			obj.raw_data = {}
		end,
		raw = function(self)
			return encode.uint8(fc)..table.concat(obj.raw_data)
		end
	} 
end

function _M.parser_pdu(raw)
	local fc = decode.uint8(raw.sub(1,1))
	local raw_len = decode.uint8(raw:sub(2,2))
	if raw_len + 2 > string.len(raw) then
		return nil, 'data not enough raw_len:'..raw_len..' len(raw):'..string.len(raw)
	end

	local obj = {
		fc = fc,
		data = {},
		raw_data = raw:sub(3),
		raw_len = raw_len,
		curpos = 1,
	}
	return {
		data = function(self)
			return obj.data
		end,
		get = function(self, index)
			return obj.data[index]
		end,
		raw = function(self)
			return obj.raw_data
		end,
		parser = function(self, index, decode_func, start, len, offset)
			start = start or obj.curpos
			len = decode.get_len(decode_func, len)
			local raw_data = obj.raw_data:sub(start, start + len - 1)
			if not raw_data or string.len(raw_data) < len then
				return nil, 'not enough data'
			end
			--print(string.len(raw_data))
			local val = decode[decode_func](raw_data, len, offset)
			if val then
				obj.data[index] = val
				if start == obj.curpos then
					obj.curpos = obj.curpos + len
				end
				return val
			end
			return nil
		end
	}
end

function _M.create_exception(fc, ec)
	local pdu = create_pdu(fc + 0x80)
	pdu:append("int8", ec)
	return pdu
end

function _M.create_read_pdu(fc, addr, len)
	local pdu = create_pdu(fc)
	if addr then
		pdu:append("uint16", addr)
		pdu:append("uint16", len)
	end
	return pdu
end

function _M.create_write_pdu(fc, addr, val)
	local pdu = create_pdu(fc)
	pdu:append("uint16", addr)
	pdu:append("uint16", val)
	return pdu
end

_M.ReadCoils = function (addr, len)
	return _M.create_read_pdu(code.ReadCoils, addr, len), function(pdu)
		if not pdu then
			return nil, 'error case'
		end
		for i = 1, len do
			local start = math.floor((i + 7) / 8)
			if not pdu:parser(i, 'bit', start, 1, (i - 1) % 8) then
				return nil, 'not enough data'
			end
		end
		return pdu
	end
end
_M.ReadDisreteInputs = function (addr, len) 
	return _M.create_read_pdu(code.ReadDisreteInputs, addr, len), function(pdu)
		len = math.floor(len + 7)
		for i = 1, len do
			if not pdu:parser(i, 'uint8') then
				return nil, 'not enough data'
			end
		end
		return pdu
	end
end
_M.ReadHoldingRegisters = function (addr, len) 
	return _M.create_read_pdu(code.ReadHoldingRegisters, addr, len), function(pdu)
		if not pdu then
			return nil, 'falure cause'
		end
		for i = 1, len do
			if not pdu:parser(i, 'uint16') then
				return nil, 'not enough data'
			end
		end
		return pdu
	end
end
_M.ReadInputRegisters = function (addr, len)
	return _M.create_read_pdu(code.ReadInputRegisters, addr, len), function(pdu)
		for i = 1, len do
			if not pdu:parser(i, 'uint16') then
				return nil, 'not enough data'
			end
		end
		return pdu
	end
end
_M.WriteSingleCoil = function(addr, val) 
	return _M.create_write_pdu(code.WriteSingleCoil, addr, val), function(pdu)
		return pdu
	end
end
_M.WriteSingleRegister = function(addr, val)
	return _M.create_write_pdu(code.WriteSingleRegister, addr, val), function(pdu)
		return pdu
	end
end
_M.ReadExceptionStatus = function() 
	local pdu = create_pdu(code.ReadExceptionStatus) 
	return pdu, function(pdu)
		return pdu
	end
end

_M.WriteMultipleRegisters = function(addr, len, ...) 
	local args = {...}
	local pdu = create_write_pdu(add, len)
	pdu:append("uint8", len * 2)
	for i, v in ipairs(args) do
		pdu:append("uint16", v)
	end
	return pdu
end

return _M
