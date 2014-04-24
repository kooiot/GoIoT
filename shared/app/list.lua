--- Installed applicatons list
-- @local

local cjson = require 'cjson.safe'
local log = require 'shared.log'

--- The module table
local _M = {}

--- The application information list (table)
local list = {}

--- Loading the application list
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

--- Save the application list
local function save()
	local file, err = io.open('/tmp/apps/_list', "w")
	if file then
		for name, node in pairs(list) do
			for k, v in pairs(node.insts) do
				local json = v.app and cjson.encode(v.app) or ''
				assert(file:write("NAME='"..node.name.."' INSNAME='"..v.insname.."' APPJSON='"..json.."'\n"))
			end
		end
		file:close()
		return true
	else
		return nil, err
	end
end

--- Add one new application to list
-- @tparam table app Application information object
-- @tparam string name Application name
-- @tparam string insname Application local installed name
-- @treturn nil
_M.add = function(app, name, insname)
	_M.del(name, insname, function() end)
	list[name] = list[name] or {name=name, insts={}}
	table.insert(list[name].insts, {insname=insname, app=app})
	save()
end

--- Delete one application from list
-- @tparam string name The removed application name
-- @tparam string insname The removed application local name
-- @tparam function on_remove Callback functions when application has no reference counter, it is time to delete all files
-- @treturn nil
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

--- Get the application lists
-- @treturn table the list 
_M.list = function()
	return list
end

--- Find the application information
-- @tparam string insname Application local install name
-- @treturn table Applciation infomation table or nil
_M.find = function(insname)
	for name, v in pairs(list) do
		for k, node in pairs(v.insts) do
			if node.insname == insname then
				return node.app
			end
		end
	end
end

--- Loading the application when module required
load()

return _M
