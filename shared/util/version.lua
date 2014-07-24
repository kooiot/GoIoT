--- Version string compare utility module

local _M = {}

--- Break the version string an table
local function ver_to_table(ver)
	local t = {}
	for v in ver:gmatch('[^%.]+') do
		t[#t + 1] = tonumber(v)
	end
	return t
end

--- Compare the version string
-- @tparam string v1 first version string 
-- @tparam string v2 second version string 
-- @treturn boolean true if v1 < v2
function _M.lt(v1, v2)
	local t1 = ver_to_table(v1)
	local t2 = ver_to_table(v2)

	for i = 1, 4 do
		t1[i] = t1[i] or 0
		t2[i] = t2[i] or 0
		if t1[i] < t2[i] then
			return true
		end
	end
	return false
end

--- Compare the version string
-- @tparam string v1 first version string 
-- @tparam string v2 second version string 
-- @treturn boolean true if v1 <= v2 
function _M.le(v1, v2)
	if _M.lt(v1, v2) then
		return true
	end
	return _M.eq(v1, v2)
end

--- Compare the version string
-- @tparam string v1 first version string 
-- @tparam string v2 second version string 
-- @treturn boolean true if v1 == v2
function _M.eq(v1, v2)
	return tostring(ver1) == tostring(ver2)
end

return _M
