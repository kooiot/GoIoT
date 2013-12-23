-- contrstruct a commond object

local class = {}

function class:add_arg(name, desc, type, value, vals)
	self.args[name] = {name = name, desc = desc, type = type, value=value, vals = vals}
end

function class:get_arg(name, default)
	local arg = self.args[name]
	if not arg or not arg.value then
		return default
	end
	return arg.value
end

function class:meta()
	return {
		name = self.name,
		args = self.args
	}
end

local _M = {}

function _M.new(name)
	assert(name)
	return setmetatable({name=name, args={}}, {__index=class})
end

function _M.from(tbl)
	assert(tbl)
	return setmetatable(tbl, {__index=class})
end

return _M

