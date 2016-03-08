-- modbus decode functions
--
local bit32 = require 'shared.compat.bit'

local _M = {}

_M.int8 = function (data)
	local val = string.byte(data)
	return ((val + 128) % 256) - 128
end

_M.uint8 = function (data)
	return string.byte(data)
end

_M.int16 = function (data)
	local hv = string.byte(data)
	local lv = string.byte(data, 2)
	val = hv * 256 + lv
	return ((val + 32768) % 65536) - 32768
end

_M.uint16 = function (data)
	local hv = string.byte(data)
	local lv = string.byte(data, 2)
	return hv * 256 + lv
end

_M.int32 = function (data)
	local val = _M.uint32(data)
	return ((val + 1073741824) % 2147483648) - 1073741824
end

_M.uint32 = function (data)
	local hv = _M.uint16(data)
	local lv = _M.uint16(string.sub(data, 2, 2))
	return hv * 65536 + lv
end

_M.string = function (data, len)
	return string.sub(data, 1, len)
end

_M.bit = function (data, len, offset)
	local raw = string.sub(data, offset / 8)
	if bit32.band(_M.uint8(raw), bit32.lshift(1, offset % 8)) == 0 then
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
