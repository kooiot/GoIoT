
local list = require 'shared.app.list'
local log = require 'shared.log'

local function on_remove(apps_folder) 
	return function(name, insname, keep)
		log:warn("APP", "Removing installed application", insname)
		if name ~= insname then
			local dest_folder = apps_folder..'/'..insname
			assert(os.execute('rm -rf '..dest_folder))
		end
		if not keep then
			log:info("APP", "No instance left, remove whole application")
			local dest_folder = apps_folder..'/'..name
			assert(os.execute('rm -rf '..dest_folder))
		end
	end
end

return function(apps_folder, name, insname)
	local lock = lfs.lock_dir(apps_folder)
	list.del(name, insname, on_remove(apps_folder))
	lock:free()
	return true
end
