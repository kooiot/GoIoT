
return function (factory) 
	local factory = factory

	local class = {}

	function class:add(name, desc, ...)
		assert(not self[name], 'The sub node exists for '..name)
		self[name] = factory(name, desc, ...)

		return self[name]
	end

	function class:erase(name)
		self[name] = nil
	end

	function class:get(name)
		return self[name]
	end

	return {
		new = function(newindex)
			local map = {}
			return setmetatable(map, {__index=class, __newindex=newindex})
		end
	}
end
