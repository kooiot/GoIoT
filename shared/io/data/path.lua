local sub = '/'

local gen = function(device, obj_type, obj_name, attr)
	local path = sub..device
	if obj_type and obj_name then
		path = path..sub..obj_type..sub..obj_name
	end
	if attr then
		path = path..sub..attr
	end
	return path
end

local parser = function(path)
	local obj = devices
	for k in path:gmatch('/([^/]+)') do
		obj = devices[k]
		if not obj then
			break
		end
	end
	return obj
end


return {
	gen = gen,
	parser = parser,
}

