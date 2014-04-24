--- Install helpers
-- @local
--
local app_install = require 'shared.app.install'
local io_install = require 'shared.io.install'
local download = require 'shared.cloud.download'
local log = require 'shared.log'

--- Create callback function for intalling an application
-- @tparam table cfg configureation table
-- @return function callback function
local function create_cb(cfg)
	--- The callback function
	return function (app)
		-- Download the applcation from server
		local src = cfg.srvurl..'/'..app.path..'/latest.zip'
		local dest = cfg.cachefolder..'/'..app.name..'.zip'
		log:info('CLOUD', "Download", app.name, "from", src, "to", dest)
		local r, err = download(src, dest)
		if not r then
			log:warn('CLOUD', "Download fails", err)
			return nil, err
		end
		return dest
	end
end

--- Install helper function
-- @function module
-- @tparam table cfg Configuration
-- @tparam Application app Application object
-- @tparam string lname Local install name
return function(cfg, app, lname)
	local downcb = create_cb(cfg)
	-- INstall the application
	log:info('CLOUD', "Install", lname, "to", cfg.appsfolder)
	if not app.type or app.type == 'app' then
		local dest, err = downcb(app)
		if dest then
			return app_install(dest, cfg.appsfolder, lname, app)
		else
			return nil, err
		end
	end

	if app.type:match('^app%.io') then
		return io_install(app, cfg.appsfolder, lname, downcb)
	end
	return nil, "Incorrect application type found "..app.type
end
