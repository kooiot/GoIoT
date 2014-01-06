local _M = {}

local list = {}

local function load()
	local file, err = io.open('/tmp/apps/_list', "r")
	if file then
		for line in file:lines() do
			local name, project = line:match('NAME=(.+) PROJECT=(.+)')
			table.insert(list, {name=name, project=project})
		end
		file:close()
	end
end

local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, project in pairs(list) do
			assert(file:write('NAME='..name..' PROJECT='..project))
		end
		file:close()
		return true
	else
		return nil, err
	end
end

_M.add = function(name, project)
	table.insert(list, {name=name, project=project})
	save()
end

_M.del = function(name)
	for k, v in pairs(list) do
		if v.name == name then
			list[k] = nil
		end
	end
	save()
end

return _M
