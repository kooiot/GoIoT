-- construct a setting item object

local class = {}

function class:add_prop(name, desc, type, value, vals)
	self.props[name] = {name = name, desc = desc, type = type, value=value, vals = vals}
end

function class:get_prop(name, default)
	local arg = self.props[name]
	if not arg or not arg.value then
		return default
	end
	return arg.value
end

function class:meta()
	return {
		name = self.name,
		props = self.props
	}
end

local _M = {}

function _M.new(name)
	assert(name)
	return setmetatable({name=name, props={}}, {__index=class})
end

function _M.from(tbl)
	assert(tbl)
	return setmetatable(tbl, {__index=class})
end

return _M
