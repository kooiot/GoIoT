--[[
application install lua script
]]--

--- Application install helper
--

local cjson = require 'cjson.safe'
local lfs = require 'lfs'
local unzip = require 'shared.util.unzip'
local list = require 'shared.app.list'
local newinst = require 'shared.app.newinst'
local pp = require 'shared.PrettyPrint'
local log  = require 'shared.log'

--- Update the version lua file
-- @tparam string apps_folder the folder path for installed applications
-- @tparam string dest_name the destination application name
-- @treturn table the version table
local function update_ver(apps_folder, dest_name)
	local _ver = nil
	local file, err = io.open(apps_folder..'/'..dest_name..'/_ver.lua', 'r')
	if file then
		local data = file:read('*a')
		local chunk, err = load(data)

		_ver = chunk and chunk() or {}
		file:close()
	else
		log:warn('WEB', "Failed to open _ver.lua", err)
	end

	_ver.name=dest_name
	_ver.localapp = true
	local file, err = io.open(apps_folder..'/'..dest_name..'/_ver.lua', 'w')
	if file then
		file:write('return '..pp(_ver)..'\n')
		file:close()
	else
		log:error('WEB', "Failed to save _ver.lua", err)
	end
	return _ver
end

--- install function 
-- @function return 
-- @tparam string zip_file the zipped application file path
-- @tparam string apps_folder the folder path for installed applications
-- @tparam string dest_name the destination application name
-- @tparam table app the application information table
-- @tparam table local_app the local application information table
-- @return ok
-- @treturn string error
-- @todo TODO: Windows is not supported!!
--
return function(zip_file, apps_folder, dest_name, app, local_app)
	assert(zip_file, 'No application packe file specified')
	assert(apps_folder, 'No installation folder specified')
	assert(dest_name, 'No installation name specified')
	log:debug('APP', "install app", zip_file, apps_folder, dest_name)

	local lock = lfs.lock_dir(apps_folder)
	if not lock then
		log:error("APP", "Failed to lock app folder")
		return nil, "already locked"
	end

	local dest_folder = apps_folder..'/'..dest_name
	if app then
		dest_folder = apps_folder..'/'..app.path:gsub('/', '.')
	end
	-- TODO: Do not replace the original code. and need to consider about application version append to folder name?
	log:debug('APP', "Unzip to "..dest_folder)

	assert(os.execute('rm -rf '..dest_folder))
	assert(os.execute('mkdir '..dest_folder))

	assert( unzip(zip_file, dest_folder) )

	if not app then
		app = update_ver(apps_folder, dest_name)

		log:debug('APP', "Installing local application", pp(app))
		-- Add to auto start script
		-- 
		list.add(app, dest_name, dest_name)
	else
		newinst(apps_folder, app, dest_name)
		list.add(local_app or app, app.name, dest_name)
	end
	lock:free()
	log:info("APP", "Install application "..dest_name.." done!!!")
	return true
end
