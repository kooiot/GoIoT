local unzip = require 'shared.unzip'
local download = require 'shared.cloud.download'
local install = require 'shared.app.install'
local uninstall = require 'shared.app.uninstall'
local list = require 'shared.app.list'

local _M = {}
_M.apps = {}
_M.inst_apps = {}
_M.srvurl = 'cloud.opengate.com'
_M.cachefolder = '/tmp'
_M.appsfolder = '/tmp/apps'

local function load_cache()
	local cache = _M.cachefolder..'/release'

	-- load the lua file
	local chunk, err = loadfile(cache..'/apps.lua')
	if not chunk then
		return nil, err
	end

	_M.apps, err = chunk()
	return _M.apps, err
end

local function load_installed()
	_M.inst_apps = {}
	local apps = list.list()
	for k, v in pairs(apps) do
		table.insert(_M.inst_apps, v.app)
	end
end

--
-- Initialize the server url and cache folder
_M.init = function (srvurl, cachefolder, appfolder)
	_M.srvurl = srvurl or _M.srvurl
	_M.cachefolder = cachefolder or _M.cachefolder
	_M.appsfolder = appsfolder or _M.appsfolder

	load_cache()
	load_installed()
end

--
-- Fetch the release.gz from server
_M.update = function()
	local src = _M.srvurl..'/release.zip'
	local dest = _M.cachefolder..'/release.zip'
	local cache = _M.cachefolder..'/release'

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

--
-- Search one application
_M.search = function(key)
	local matches = {}
	local pattern = '.-'..key..'.-'
	for k,v in pairs(_M.apps) do
		if v.name:match(pattern) then
			table.insert(matches, v)
		end
		if v.desc:match(pattern) then
			table.insert(matches, v)
		end
	end
	return matches
end

--
-- Install one application
_M.install = function(name, lname)
	local app = _M.apps[name]
	if not app then
		return nil, "no such app "..name
	end

	local src = _M.srvurl..app.path..'/latest.zip'
	local dest = _M.cachefolder..'/'..name..'.zip'
	local r, err = download(src, dest)
	if not r then
		return nil, err
	end
		
	install(dest, _M.appsfolder, lname, app)
end

--
-- Remove one application
-- Mode: 'a' -- purge all stuff includes configuration
--       'n' -- only remove application, keep the configuration
_M.remove = function(lname, mode)
	local mode = mode or 'n'
	-- TODO: for clean the configuration
	return uninstall(_M.appsfolder, lname)
end

--
-- List all avaiable/installed application
-- mode:
--	'a' - all avaiable applications
--	'i' - all installed applications
_M.list = function(mode)
	local mode = mode or 'a'
	if mode == 'a' then
		return _M.apps
	end
	if mode == 'i' then
		return _M.inst_apps
	end
	return nil, 'incorrect mode'
end

return _M
