--- Command class
--

local class = {}

--- trigger action
function class:action()
end

--- create a new command
-- @function module
-- @tparam string name Command name
-- @tparam string desc Command description
-- @tparam table args Command arguments
return function(name, desc, args)
	local cmd = { name = name, desc = desc, args = args}

	return setmetatable(cmd, {__index=class})
end
