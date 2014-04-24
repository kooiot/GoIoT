---- IO application install module
-- @local
--
local log  = require 'shared.log'
local install = require 'shared.app.install'
local unzip = require 'shared.unzip'
local platform = require 'shared.platform'


----
local function install_app(app, apps_folder, dest_name, downcb, config_app)
	local path, err = downcb(app)
	if path then
		return install(path, apps_folder, dest_name, app, config_app)
	else
		log:error('INSTALL.io', 'Failed install io application', err)
		return nil, err
	end
	return true
end

return function(app, apps_folder, dest_name, downcb)
	if app.type == 'app.io' then
		return install_app(app, apps_folder, dest_name, downcb)
	elseif app.type == 'app.io.config' then
		assert(#app.depends == 1)

		-- Find the application from cloud
		local cloud = require 'shared.cloud'
		local dapp = cloud.find(app.depends[1])
		if not dapp then
			local err = 'Failed to find the application '..app.depends[1]
			log:error('INSTALL.io', err)
			return nil, err
		end

		-- Download configuation file
		local zip_file, err = downcb(app)
		if not zip_file then
			log:error('INSTALL.io.conf', 'Failed to download io conf', err)
			return nil, err
		end

		-- Unzip file
		local dest_folder = platform.path.appdefconf..'/'..dest_name
		assert( os.execute('rm -rf '..dest_folder))
		assert( unzip(zip_file, dest_folder) )

		-- install application
		return install_app(dapp, apps_folder, dest_name, downcb, app)
	else
		return nil, "Not supported application type"
	end
end
