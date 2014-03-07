
local class = {}

function class:action()
end

return function(name, desc, args)
	local cmd = { name = name, desc = desc, args = args}

	return setmetatable(cmd, {__index=class})
end
