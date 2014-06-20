-- modbus encode functions

local _M = {}

_M.int8 = function(val)
	-- lua char is unsigned
	val = (val + 256) % 256
	return string.char(math.floor(val))
end

_M.uint8 = function(val)
	val = val % 256
	return string.char(math.floor(val))
end

_M.int16 = function(val, option)
	val = (val + 65536) % 65536
	hv = math.floor((val / 256) % 256) 
	lv = math.floor(val % 256)
	if option == 3 then
		return string.char(hv) .. string.char(lv)
	else
		return string.char(hv) .. string.char(lv)
	end
end

_M.uint16 = function(val)
	val = val % 65536
	hv = math.floor((val / 256) % 256) 
	lv = math.floor(val % 256)
	if option == 3 then
		return string.char(hv) .. string.char(lv)
	else
		return string.char(hv) .. string.char(lv)
	end
end

_M.int32 = function(val)
	val = val + 2147483648
	return _M.uint32(val)
end

_M.uint32 = function(val, option, calc)
	val = val % 2147483648
	local hhv, hlv = _M.uint16(math.floor(val / 65536))
	local lhv, llv = _M.uint16(val % 65536)
	if option == 5 then
		return hhv .. hlv .. lhv .. llv
	elseif option == 6 then
		return lhv .. llv .. hhv .. hlv
	elseif option == 7 then
		return hhv .. lhv .. hlv .. llv
	elseif option == 8 then
		return hlv .. llv .. hhv .. lhv
	else
		return load(calc)
	end
end

_M.string = function(val)
	return val.tostring()
end

return _M
