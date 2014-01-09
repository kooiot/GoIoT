local cjson = require 'cjson.safe'

local _M = {}

local list = {}

local function load()
	local file, err = io.open('/tmp/apps/_list', "r")
	if file then
		for line in file:lines() do
			local name, project, json = line:match("NAME='(.+)' PROJECT='(.+)' JSON='(.+)'")
			list[name] = {name=name, project=project, app=cjson.decode(json)}
		end
		file:close()
	end
end

local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, node in pairs(list) do
			local json = app and cjson.encode(app) or ''
			assert(file:write("NAME='"..node.name.."' PROJECT='"..node.project.."' JSON='"..json.."'\n"))
		end
		file:close()
		return true
	else
		return nil, err
	end
end

_M.add = function(name, project, app)
	list[name] = {name=name, project=project, app=app}
	save()
end

_M.del = function(name)
	if list[name] then
		list[name] = nil
		for k, v in pairs(list) do
			if v.project == name then
				list[k] = nil
			end
		end
		save()
	end
end

_M.list = function()
	return list
end

load()

return _M
