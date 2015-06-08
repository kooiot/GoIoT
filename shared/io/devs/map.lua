--- Map object container
--

--- Create an new map module which contains an new function
-- @function module
-- @tparam function factory  Factory function
-- @treturn class Map container
return function (factory) 
	local factory = factory

	--- Map Class
	-- @type class
	local class = {}

	--- Add new item
	-- @tparam string name Item name
	-- @tparam string desc Item description
	-- @param ... Optional args
	function class:add(name, desc, ...)
		assert(not self[name], 'The sub node exists for '..name)
		self[name] = factory(name, desc, ...)

		return self[name]
	end

	--- Remove an item by name
	-- @tparam string name Item name
	function class:erase(name)
		self[name] = nil
		self(name)
	end

	--- Get an item by name
	-- @tparam string name Item name
	-- @treturn object item
	function class:get(name)
		return self[name]
	end

	return {
		--- Create an new map instance
		-- @tparam table newindex __newindex metatable
		-- @treturn class Map object
		new = function(newindex, deleted)
			local cb = deleted or function() end
			local map = {}
			return setmetatable(map, {__index=class, __newindex=newindex, __call=cb})
		end
	}
end
