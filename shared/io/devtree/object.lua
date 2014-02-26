
local map = require 'shared.io.devtree.map'
local prop = require 'shared.io.devtree.prop'
local pub = require 'shared.io.devtree.pub'
local props = map(prop)

local class = {}

function class:set(value, timestamp, quality)
	if self then
		self.value = value
		self.timestamp = timestamp
		self.quality = quality or self.quality
		pub.cov(self.path, self)
		return true
	end
end

function class:get()
	return self.value, self.timestamp, self.quality
end

-- set the proper path for prop
local function newprop(obj)
	return function(props, key, prop)
		prop.path = obj.path..'/props/'..key
		rawset(props, key, prop)
	end
end

return function(name, desc)
	local obj = {
		name = name, 
		desc = desc,
	}
	obj.props = props.new(newprop(obj))
	return setmetatable(obj, {__index=class})
end

