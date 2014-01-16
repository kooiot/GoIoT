
local uninstall = require 'shared.app.uninstall'

return function(cfg, app, lname)
	return uninstall(cfg.appsfolder, app.name, lname)
end
