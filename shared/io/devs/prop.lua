local pub = require 'shared.io.devs.pub'
local class = {}

function class:set(value, timestamp, quality)
	if self then
		self.value = value
		self.timestamp = timestamp
		self.quality = quality or self.quality
		pub.cov(self.path, self)
		return  true
	end
end

function class:get(name)
	return self.value, self.timestamp, self.quality
end

return function(name, desc, value)
	local prop = { name = name, desc = desc, value = value, timestamp = 0, quality = 0 }
	return setmetatable(prop, {__index=class})
end
