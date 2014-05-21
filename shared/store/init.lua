--- Store module
-- The store helper functions

local unzip = require 'shared.unzip'
local download = require 'shared.store.download'
local list = require 'shared.app.list'
local log = require 'shared.log'
local pp = require 'shared.PrettyPrint'
local cjson = require 'cjson.safe'

--- Module 
local _M = {}

--- The default store configuration
local cfg = {
	--srvurl = 'ftp://store.opengate.com',
	srvurl = 'http://172.30.11.169:8081/static/releases',
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

-- TODO: for checking server
_M.check_server = function()
	return true
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
		return save_after_success(_M.check_server())
	end
	if type(c) == 'string' then
		cfg.srvurl = c
		return save_after_success(_M.check_server())
	end
	log:error('STORE', 'Incorrect config parameter')
	return nil, 'Incorrect config parameter'
end

--- Get the current store srv
-- @treturn string the server domain:port only
_M.get_srv = function()
	return cfg.srvurl:match('://([^/]+)/')
end

--- Search one application from cache
-- @tparam string key the search key string, nil will match all
-- @treturn table matched applications
_M.search = function(key)
	local platform = require 'shared.platform'
	local path = platform.path.temp..'/_store_cache'
	local file, err = io.open(path)
	if not file then
		return nil, err
	end
	local str = file:read('*a')
	file:close()
	str = str or ""
	local apps, err =  cjson.decode(str)
	if not apps then
		return nil, err
	end

	if key then
		key = key:lower()
		local t = {}
		for author, list in pairs(apps) do
			for _, v in pairs(list) do
				if v.name:lower():match(key) or (v.info.desc and v.info.desc:lower():match(key)) then
					t[author] = t[author] or {}
					table.insert(t[author], v)
				end
			end
		end
		apps = t
	end
	return apps
end

--- Update the store cache file
-- @return boolean result
-- @return string error
_M.update = function()
	local http = require 'socket.http'
	http.TIMEOUT = 10
	local url = 'http://'.._M.get_srv()..'/app/repo'
	local json, code, headers, status = http.request(url)
	if code ~= 200 then
		return nil, status
	end
	local r, err = cjson.decode(json)
	if not r then
		return nil, err
	end

	local platform = require 'shared.platform'
	local path = platform.path.temp..'/_store_cache'
	local file, err = io.open(path, 'w+')
	if not file then
		return nil, err
	end
	file:write(json)
	file:close()
	return true
end

local function get_app_info(path, version)
	local http = require 'socket.http'
	http.TIMEOUT = 10
	local url = 'http://'.._M.get_srv()..'/app/queryinfo?path='..path..'&version='..version
	local json, code = http.request(url)
	if code == 200 then
		return cjson.decode(json)
	end
	return nil, 'Failed to download, return code: '..code..' url: '..url
end

---
-- Install one application
-- @tparam string lname Application local install name
-- @tparam string path Application path in store server
-- @tparam string version Application version
-- @treturn boolean ok
-- @treturn string error message
_M.install = function(lname, path, version)
	local app, err = get_app_info(path, version)
	if not app then
		return nil, err
	end
	app.path = app.path or path
	assert(app.name)
	assert(app.path)
	assert(app['type'])
	assert(app.desc)
	assert(app.version)
	assert(app.depends)
	log:info('STORE', "Installing "..path.." as "..lname)
	-- Check for unique local name
	for k, v in pairs(load_installed()) do
		if v.lname == lname then
			return nil, "The application instance name has been used"
		end
	end

	local install = require 'shared.store.install'
	return install(cfg, app, lname)
end

---
-- Remove one application
-- @tparam string lname Application local install name
-- @tparam string mode Mode (not implemented):
--		'a' -- purge all stuff includes configuration
--      'n' -- only remove application, keep the configuration
-- @return  ok
-- @treturn string error message
_M.remove = function(lname, mode)
	local mode = mode or 'n'
	log:info("STORE", "Uninstalling application", lname)
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
