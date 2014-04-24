--- Cloud module
-- The cloud helper functions

local unzip = require 'shared.unzip'
local download = require 'shared.cloud.download'
local list = require 'shared.app.list'
local log = require 'shared.log'
local pp = require 'shared.PrettyPrint'

--- Module 
local _M = {}

--- Application list (cached)
-- @local
_M.apps = {}

--- The default cloud configuration
local cfg = {
	--srvurl = 'ftp://cloud.opengate.com',
	srvurl = 'http://localhost/',
	cachefolder = '/tmp',
	appsfolder = '/tmp/apps',
}

--- The configuration file path
local cfg_file = '/tmp/apps/_store.cfg'

--- Load the configuration from disk
local function load_config()
	local chunk, err = loadfile(cfg_file)

	if chunk then
		local c = chunk()
		if c then
			cfg = c
		end
	end
end

--- Save configuration to disk
local function save_config()
	local file, err = io.open(cfg_file, 'w')
	if not file then
		log:error('CLOUD', 'Failed to open the configuration file', err)
		return nil, err
	end
	file:write('return '..pp(cfg)..'\n')
	file:close()
end

--- Load cached application lists
local function load_cache()
	local cache = cfg.cachefolder..'/release'

	-- load the lua file
	local chunk, err = loadfile(cache..'/apps.lua')
	if not chunk then
		return nil, err
	end

	_M.apps, err = chunk()
	return _M.apps, err
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
	load_cache()
	load_installed()
end

--- Save configuration when success
local function save_after_success(r, err)
	if r then
		save_config()
	end
	return r, err
end

--- Change the configuration
-- @tparam table c Cloud configuration { srvurl=xxx, cachefolder=xxx, appsfolder=xxx }
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

--- Update the local cache
-- Fetch the release.gz from server
-- @return ok
-- @treturn string error message
_M.update = function()
	local src = cfg.srvurl..'/release.zip'
	local dest = cfg.cachefolder..'/release.zip'
	local cache = cfg.cachefolder..'/release'

	-- Remove the previous cache
	os.remove(dest)

	-- Downoad the release.zip
	local r, err = download(src, dest)
	if not r then
		return nil, err
	end

	-- unzip the file
	r, err = unzip(dest, cache, true)
	if not r then
		return nil, err
	end

	return load_cache()
end

--- Search one application
-- @tparam string key the search key
-- @treturn table matched names
_M.search = function(key)
	local matches = {}
	local pattern = '.-'..key..'.-'
	for k,v in pairs(_M.apps) do
		if v.name:match(pattern) then
			table.insert(matches, v)
		else
			if v.desc:match(pattern) then
				table.insert(matches, v)
			end
		end
	end
	return matches
end

---
-- Find application by its name
-- @tparam string name Application name
-- @treturn table application information table, nil when name cannot found in cache
_M.find = function (name)
	for k,v in pairs(_M.apps) do
		if v.name == name then
			return v
		end
	end
	return nil
end

---
-- Install one application
-- @tparam string name Application name
-- @tparam string lname Application local install name
-- @treturn boolean ok
-- @treturn string error message
_M.install = function(name, lname)
	log:info('CLOUD', "Installing "..name.." as "..lname)
	-- Check for unique local name
	for k, v in pairs(load_installed()) do
		if v.lname == lname then
			return nil, "The application instance name has been used"
		end
	end

	-- Find the cloud app information
	local app = _M.find(name)
	if not app then
		return nil, "no such app "..name
	end

	local install = require 'shared.cloud.install'
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
			local uninstall = require 'shared.cloud.uninstall'
			return uninstall(cfg, v.name, lname)
		end
	end
	return nil, "No such application instance"
end

---
-- List all avaiable/installed application
-- @tparam string mode
--	'a' - all avaiable applications
--	'i' - all installed applications
_M.list = function(mode)
	local mode = mode or 'a'
	if mode == 'a' then
		return _M.apps
	end
	if mode == 'i' then
		return load_installed()
	end
	return nil, 'incorrect mode'
end

init()

return _M
