--- Uninstall helper function
-- the wrapper of app.uninstall
-- @local

local uninstall = require 'shared.app.uninstall'

return function(cfg, name, lname)
	return uninstall(cfg.appsfolder,name, lname)
end
