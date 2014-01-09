
local list = require 'shared.app.list'

return function(apps_folder, name)
	local lock = lfs.lock_dir(apps_folder)
	list.del(name)
	local dest_folder = apps_folder..'/'..dest_name
	assert(os.execute('rm -rf '..dest_folder))
	lock:free()
	return true
end
