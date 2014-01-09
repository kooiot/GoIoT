local cjson = require 'cjson.safe'

local _M = {}

local list = {}

local function load()
	local file, err = io.open('/tmp/apps/_list', "r")
	if file then
		for line in file:lines() do
			local name, insname, json = line:match("NAME='(.+)' INSNAME='(.+)' APPJSON='(.+)'")
			if not list[name] then
				list[name] = {name=name, insts={insname}, app=cjson.decode(json)}
			else
				table.insert(list[name].insts, name)
			end
		end
		file:close()
	end
end

local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, node in pairs(list) do
			local json = app and cjson.encode(app) or ''
			for k, v in pairs(node.insts) do
				assert(file:write("NAME='"..node.name.."' INSNAME='"..v.."' APPJSON='"..json.."'\n"))
			end
		end
		file:close()
		return true
	else
		return nil, err
	end
end

_M.add = function(insname, name, app)
	table.insert(list[name].insts, insname)
	save()
end

_M.del = function(name, on_remove)
	if list[name] then
		for k, v in pairs(list[name].insts) do
			if v == name then
				list[name].insts = nil
			end
		end
		if #list[name].insts == 0 then
			on_remove()
			list[name] = nil
		end
		save()
	end
end

_M.list = function()
	return list
end

load()

return _M
