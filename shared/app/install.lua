--[[
application install lua script
]]--

local cjson = require 'cjson.safe'
local lfs = require 'lfs'
local unzip = require 'shared.unzip'
local list = require 'shared.app.list'
local newinst = require 'shared.app.newinst'
local pp = require 'shared.PrettyPring'

local function update_ver(apps_folder, dest_name)
	local _ver = nil
	local file, err = io.open(apps_folder..'/'..dest_name..'/_ver.lua', 'r')
	if file then
		local data = file:read('*a')
		local chunk, err = load(data)

		_ver = chunk and chunk() or {}
		file:close()
	end

	_ver.name=dest_name
	_ver.localapp = true
	local file, err = io.open(apps_folder..'/'..dest_name..'/_ver.lua', 'r')
	if file then
		file:write('return '..pp(_ver))
		file:close()
	end
end

--TODO: Windows is not supported!!
--
return function(zip_file, apps_folder, dest_name, app)
	assert(zip_file, 'No application packe file specified')
	assert(apps_folder, 'No installation folder specified')
	assert(dest_name, 'No installation name specified')

	local lock = lfs.lock_dir(apps_folder)

	local dest_folder = apps_folder..'/'..dest_name
	if app then
		dest_folder = apps_folder..'/'..app.name
	end

	assert(os.execute('rm -rf '..dest_folder))
	assert(os.execute('mkdir '..dest_folder))

	assert( unzip(zip_file, dest_folder) )

	if not app then
		app = update_ver(apps_folder, dest_name)

		-- Add to auto start script
		-- 
		list.add(dest_name, dest_name, app)
	else
		newinst(apps_folder, app, dest_name)
	end
	lock:free()
end
