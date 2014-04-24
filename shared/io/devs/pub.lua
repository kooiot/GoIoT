--- publisher
-- @local

local _M = {}
local ptable = {}

--- Fire COV event
-- @tparam string path The source object path
-- @tparam table value The value object {value=xxx, timestamp=xxxx, quality=xxx}
-- @treturn nil
function _M.cov(path, value)
	for k, v in pairs(ptable) do
		v(path, value)
	end
end

--- Bind COV callback functions
-- @tparam function func Callback function
-- @treturn nil
function _M.bind(func)
	assert(func)
	assert(type(func) == 'function')
	table.insert(ptable, func)
end

return _M

