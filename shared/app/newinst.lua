--- New install an application 
-- @local
--
local list = require 'shared.app.list'

----
return function(apps_folder, app, dest)
	local lpath = app.path:gsub('/', '.')
	if lpath ~= dest then
		local org_folder = apps_folder..'/'..lpath
		local new_folder = apps_folder..'/'..dest
		assert(os.execute('ln -s '..org_folder..' '..new_folder))
	end
end
