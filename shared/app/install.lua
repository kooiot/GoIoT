--[[
application install lua script
]]--

local lfs = require 'lfs'
local unzip = require 'shared.unzip'
local list = require 'shared.app.list'

return function(zip_file, apps_folder, dest_name)
	assert(zip_file, 'No application packe file specified')
	assert(apps_folder, 'No installation folder specified')
	assert(dest_name, 'No installation name specified')

	local lock = lfs.lock_dir(apps_folder)

	local dest_folder = apps_folder..'/'..dest_name

	assert(os.execute('rm -rf '..dest_folder))
	assert(os.execute('mkdir '..dest_folder))

	assert( unzip(zip_file, dest_folder) )

	--TODO:
	-- installation

	-- Add to auto start script
	-- 
	list.add(dest_name, dest_name)

	lock:free()
end
