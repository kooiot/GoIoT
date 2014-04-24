--- Object class
--

local map = require 'shared.io.devs.map'
local prop = require 'shared.io.devs.prop'
local pub = require 'shared.io.devs.pub'
local props = map(prop)

--- Metatable 
-- @type class
local class = {}

--- Set the value of this object
-- @param value New value
-- @tparam number timestamp Timestamp
-- @tparam number quality  Quality
function class:set(value, timestamp, quality)
	if self then
		self.value = value
		self.timestamp = timestamp
		self.quality = quality or self.quality
		pub.cov(self.path, self)
		return true
	end
end

--- Get the value of this object
-- @return value Value
-- @treturn number timestamp Timestamp
-- @treturn number quality Quality
function class:get()
	return self.value, self.timestamp, self.quality
end

--- Create new property helper function
-- set the proper path for prop
-- @tparam class obj Object
-- @treturn function a property creating function
local function newprop(obj)
	return function(props, key, prop)
		prop.path = obj.path..'/props/'..key
		rawset(props, key, prop)
	end
end

--- Module functions
-- @section 

--- Create new object function
-- @function module
-- @tparam string name Object name
-- @tparam string desc Object description
-- @treturn class Object
return function(name, desc)

	--- Object Fields
	--@section
	local obj = {
		name = name, 
		desc = desc,
	}
	
	--- Map of properties
	-- @table props
	-- @see io.devs.prop
	-- @see io.devs.map
	obj.props = props.new(newprop(obj))

	return setmetatable(obj, {__index=class})
end

