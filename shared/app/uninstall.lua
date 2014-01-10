
local list = require 'shared.app.list'

local function on_remove()
	local dest_folder = apps_folder..'/'..dest_name
	assert(os.execute('rm -rf '..dest_folder))
end

return function(apps_folder, name, insname)
	local lock = lfs.lock_dir(apps_folder)
	list.del(name, insname, on_remove)
	lock:free()
	return true
end
