-- publisher

local _M = {}
local ptable = {}

function _M.cov(path, value)
	for k, v in pairs(ptable) do
		v(path, value)
	end
end

function _M.bind(func)
	assert(func)
	assert(type(func) == 'function')
	table.insert(ptable, func)
end

return _M

