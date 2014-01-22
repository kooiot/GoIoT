local cjson = require 'cjson.safe'
local log = require 'shared.log'

local _M = {}

local list = {}

local function load()
	local file, err = io.open('/tmp/apps/_list', "r")
	if file then
		for line in file:lines() do
			local name, insname, json = line:match("NAME='(.+)' INSNAME='(.+)' APPJSON='(.-)'")
			if name and insname then
				log:info('WEB', "Loading", name, insname, json)
				local app = json and cjson.decode(json) or {}
				list[name] = list[name] or {name=name, insts={}}
				table.insert(list[name].insts, {insname=insname, app=app})
			end
		end
		file:close()
	end
end

local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, node in pairs(list) do
			for k, v in pairs(node.insts) do
				local json = v.app and cjson.encode(v.app) or ''
				assert(file:write("NAME='"..node.name.."' INSNAME='"..v.."' APPJSON='"..json.."'\n"))
			end
		end
		file:close()
		return true
	else
		return nil, err
	end
end

_M.add = function(app, name, insname)
	_M.del(name, insname, function() end)
	list[name] = list[name] or {name=name, insts={}}
	table.insert(list[name].insts, {insname=insname, app=app})
	save()
end

_M.del = function(name, insname, on_remove)
	if list[name] then
		for k, v in pairs(list[name].insts) do
			if v.insname == insname then
				list[name].insts[k] = nil
			end
		end
		if #list[name].insts == 0 then
			list[name] = nil
		end
		-- name insname keep_app
		on_remove(name, insname, list[name])
		save()
	end
end

_M.list = function()
	return list
end

_M.find = function(insname)
	for name, v in pairs(list) do
		for k, node in pairs(v.insts) do
			if node.insname == insname then
				return node.app
			end
		end
	end
end

load()

return _M
