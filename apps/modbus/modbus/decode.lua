-- modbus decode functions
--

local _M = {}

_M.int8 = function (data)
	val = string.byte(data)
	val = ((val + 128) % 256) - 128
	return val
end

_M.uint8 = function (data)
	return string.byte(data)
end

_M.int16 = function (data, option)
	hv = string.byte(data)
	hl = string.byte(data, 2)
	if option == 3 then
		val = hv * 256 + hl
	else
		val = hl * 256 + hl
	end
	val = ((val + 32768) % 65536) - 32768
	return val
end

_M.uint16 = function (data, option)
	hv = string.byte(data)
	hl = string.byte(data, 2)
	if option == 3 then
		val = hv * 256 + hl
	else
		val = hl * 256 + hv
	end
	return val
end

_M.int32 = function (data)
	val = _M.uint32(data)
	val = ((val + 1073741824) % 2147483648) - 1073741824
	return val
end

_M.uint32 = function (data)
	hv = _M.uint16(data)
	hl = _M.uint16(string.sub(data, 2, 2))
	return hv * 65536 + hl
end

_M.string = function (data, len)
	return string.sub(data, 1, len)
end

_M.bit = function (data, len, offset)
	if bit32.band(_M.uint8(data), bit32.lshift(1, offset)) == 0 then
		return 0
	else
		return 1
	end
end

_M.get_len = function (name, len)
	if name == 'string' then
		return len
	end
	if name == 'bit' then
		return 1
	end
	return len or math.floor(name:sub(5) / 8)
end

return _M
