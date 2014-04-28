local _M = {}
local require = require

local class = {}

_M.new = function(m)
	local obj = {
		lwf = m.lwf,
		app = m.app,
	}
	obj.require = function(name)
		return require('shared.'..name)
	end
	obj.import = obj.require
	return obj
end

return _M
