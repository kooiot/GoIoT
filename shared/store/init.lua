--- Store module
-- The store helper functions

local unzip = require 'shared.unzip'
local download = require 'shared.store.download'
local list = require 'shared.app.list'
local log = require 'shared.log'
local pp = require 'shared.PrettyPrint'
local cjson = require 'shared.cjson'

--- Module 
local _M = {}

--- The default store configuration
local cfg = {
	--srvurl = 'ftp://store.opengate.com',
	srvurl = 'http://localhost/',
	cachefolder = '/tmp',
	appsfolder = '/tmp/apps',
}

--- Load the configuration from disk
local function load_config()
	local config = require 'shared.api.config'
	local c, err = config.get('store.config')
	if c then
		local c, err = cjson.decode(c)
		if c then
			cfg = c
		else
			return nil, err
		end
	else
		return nil, err
	end
end

--- Save configuration to disk
local function save_config()
	local c, err = cjson.encode(cfg)
	if c then
		local config = require 'shared.api.config'
		return config.set('store.config', c)
	end
	return nil, err
end

--- Load the installed application list
local function load_installed()
	local inst_apps = {}
	local apps = list.list()
	for name, v in pairs(apps) do
		for i, node in pairs(v.insts) do
			local app = {}
			for k,v in pairs(node.app) do
				app[k] = v
			end
			app.lname = node.insname
			app.name = name
			table.insert(inst_apps, app)
		end
	end
	return inst_apps
end

--
-- Initialize the server url and cache folder
local function init ()
	load_config()
end

--- Save configuration when success
local function save_after_success(r, err)
	if r then
		save_config()
	end
	return r, err
end

--- Change the configuration
-- @tparam string c Store server url or an table(advanced) { srvurl=xxx, cachefolder=xxx, appsfolder=xxx }
-- @treturn boolean ok
-- @treturn[opt] string error message
_M.config = function(c)
	if type(c) == 'table' then
		cfg.srvurl = c.srvurl or cfg.srvurl
		cfg.cachefolder = c.cachefolder or cfg.cachefolder
		cfg.appsfolder = c.appsfolder or cfg.appsfolder
		return save_after_success(_M.update())
	end
	if type(c) == 'string' then
		cfg.srvurl = c
		return save_after_success(_M.update())
	end
	log:error('CLOUD', 'Incorrect config parameter')
	return nil, 'Incorrect config parameter'
end

--- Search one application
-- @tparam string key the search key
-- @treturn table matched names
_M.search = function(key)
	-- TODO: Implement it with socket's http
end

---
-- Install one application
-- @tparam string name Application name
-- @tparam string path Application path in store server
-- @tparam string typ Application type
-- @tparam string lname Application local install name
-- @treturn boolean ok
-- @treturn string error message
_M.install = function(name, path, typ, lname)
	log:info('CLOUD', "Installing "..name.." as "..lname)
	-- Check for unique local name
	for k, v in pairs(load_installed()) do
		if v.lname == lname then
			return nil, "The application instance name has been used"
		end
	end

	local app = {
		name = name, 
		path = path, 
		['type'] = typ,
	}
	if not app then
		return nil, "no such app "..name
	end

	local install = require 'shared.store.install'
	return install(cfg, app, lname)
end

---
-- Remove one application
-- @tparam string lname Application local install name
-- @tparam string mode Mode:
--		'a' -- purge all stuff includes configuration
--      'n' -- only remove application, keep the configuration
-- @return  ok
-- @treturn string error message
_M.remove = function(lname, mode)
	local mode = mode or 'n'
	log:info("CLOUD", "Uninstalling application", lname)
	for k,v in pairs(load_installed()) do
		if v.lname == lname then
			-- TODO: for clean the configuration
			local uninstall = require 'shared.store.uninstall'
			return uninstall(cfg, v.name, lname)
		end
	end
	return nil, "No such application instance"
end

---
-- List all installed application
_M.list = function(mode)
	return load_installed()
end

init()

return _M
