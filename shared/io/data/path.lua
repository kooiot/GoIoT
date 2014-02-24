local sub = '/'

local gen = function(device, obj_type, obj_name, attr)
	local path = sub..device
	if obj_type and obj_name then
		path = path..sub..obj_type
	end
	if obj_name then
		path = path..sub..obj_name
	end
	if attr then
		path = path..sub..attr
	end
	return path
end

return function (devs)
	local devices = devs
	return {
		gen = gen,
		parser = function(path)
			local obj = devices
			for k in path:gmatch('/([^/]+)') do
				obj = devices[k]
				if not obj then
					break
				end
			end
			return obj
		end
	}
end

