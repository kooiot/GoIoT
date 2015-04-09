
local function str2hex(buf, sep)
	local re = {}
	for byte=1, #buf, 16 do
		local chunk = buf:sub(byte, byte+15)
		chunk:gsub('.', function (c) re[#re + 1] = string.format('%02X'..(sep or ' '),string.byte(c)) end)
		--re[#re + 1] = string.rep(' ',3*(16-#chunk))
	end
	return table.concat(re)
end

--[[
s = "hello world, hadaf!#@^@!#49**($..342)"
print(str2hex(s))
]]--

return str2hex

