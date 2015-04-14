--- HexDump helper function
--

--[[
http://lua-users.org/wiki/HexDump
]]--

--- Dump binrary string to readable hex content
-- @tparam string buf
-- @tparam number first start of the hex string position
-- @tparam number last end of hex string position
-- @treturn string
function hex_dump(buf,first,last)
	local function align(n) return math.ceil(n/16) * 16 end
	local re = {}
	for i=(align((first or 1)-16)+1),align(math.min(last or #buf,#buf)) do
		if (i-1) % 16 == 0 then
			re[#re + 1] = string.format('%08X  ', i-1)
		end
		re[#re + 1] = i > #buf and '   ' or string.format('%02X ', buf:byte(i))
		if i %  8 == 0 then
			re[#re + 1] = ' '
		end
		if i % 16 == 0 then
			re[#re + 1] = buf:sub(i-16+1, i):gsub('%c','.')
			re[#re + 1] = '\t\n'
		end
	end
	return table.concat(re)
end

--[[
function hex_dump(buf)
	local re = {}
	for byte=1, #buf, 16 do
		local chunk = buf:sub(byte, byte+15)
		re[#re + 1] = string.format('%08X  ',byte-1)
		chunk:gsub('.', function (c) re[#re + 1] = string.format('%02X ',string.byte(c)) end)
		re[#re + 1] = string.rep(' ',3*(16-#chunk))
		re[#re + 1] = ' '
		re[#re + 1] = chunk:gsub('%c','.')
		re[#re + 1] = '\r\n'
	end
	return table.concat(re)
end
]]--

--[[
s = "hello world, hadaf!#@^@!#49**($..342)"
print(hex_dump(s))
]]--

return hex_dump
