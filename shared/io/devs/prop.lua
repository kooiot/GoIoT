--- Properties class 
--

local pub = require 'shared.io.devs.pub'

--- Properties Class
-- @type class
local class = {}

--- Set the property value
-- @param value Property value
-- @tparam number timestamp Timestamp in ms
-- @tparam number quality Quality of this value
function class:set(value, timestamp, quality)
	if self then
		self.value = value
		self.timestamp = timestamp
		self.quality = quality or self.quality
		pub.cov(self.path, self)
		return  true
	end
end

--- Get the property value
-- @tparam string name Property name
-- @return value
-- @treturn number timestamp
-- @treturn number quality
function class:get(name)
	return self.value, self.timestamp, self.quality
end

---
--@section

--- Create new property
-- @function new
-- @tparam string name Property name
-- @tparam string desc Property description
-- @param value Initial property value
-- @treturn class Property object
return function(name, desc, value)
	local prop = { name = name, desc = desc, value = value, timestamp = 0, quality = 0 }
	return setmetatable(prop, {__index=class})
end
