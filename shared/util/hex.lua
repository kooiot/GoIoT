
local function dump(raw)
	if not raw then
		return ""
	end
	if (string.len(raw) > 1) then
		return string.format("%02X ", string.byte(raw:sub(1, 1)))..dump(raw:sub(2))
	else
		return string.format("%02X ", string.byte(raw:sub(1, 1)))
	end
end


return {
	dump = dump,
}
