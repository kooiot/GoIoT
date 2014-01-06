local _M = {}

local list = {}

local function load()
	local file, err = io.open('/tmp/apps/_list', "r")
	if file then
		for line in file:lines() do
			local name, project = line:match('NAME=(.+) PROJECT=(.+)')
			list[name] = {name=name, project=project}
		end
		file:close()
	end
end

local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, node in pairs(list) do
			assert(file:write('NAME='..node.name..' PROJECT='..node.project..'\n'))
		end
		file:close()
		return true
	else
		return nil, err
	end
end

_M.add = function(name, project)
	list[name] = {name=name, project=project}
	save()
end

_M.del = function(name)
	if list[name] then
		list[name] = nil
		save()
	end
end

load()

return _M
