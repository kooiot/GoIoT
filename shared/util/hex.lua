--- Hex helper utility functions

local _M = {}

--- Dump raw string as hex printed string
-- @tparam string raw the raw string
-- @treturn string the well printed string e.g. B0 EF 0A D6
function _M.dump(raw)
	if not raw then
		return ""
	end
	if (string.len(raw) > 1) then
		return string.format("%02X ", string.byte(raw:sub(1, 1)))..dump(raw:sub(2))
	else
		return string.format("%02X ", string.byte(raw:sub(1, 1)))
	end
end


return _M
