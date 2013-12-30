--[[
application install lua script
]]--

local lfs = require 'lfs'
local unzip = require 'shared.unzip'

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

	lock:free()
end
