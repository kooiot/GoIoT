local unzip = require 'shared.unzip'
local download = require 'shared.cloud.download'
local install = require 'shared.app.install'
local uninstall = require 'shared.app.uninstall'
local list = require 'shared.app.list'
local log = require 'shared.log'
local pp = require 'shared.PrettyPrint'

local _M = {}
_M.apps = {}
_M.inst_apps = {}

local cfg = {
	--srvurl = 'ftp://cloud.opengate.com',
	srvurl = 'http://localhost/',
	cachefolder = '/tmp',
	appsfolder = '/tmp/apps',
}

local cfg_file = '/tmp/apps/_store.cfg'

local function load_config()
	local chunk, err = loadfile(cfg_file)

	if chunk then
		local c = chunk()
		if c then
			cfg = c
		end
	end
end

local function save_config()
	local file, err = io.open(cfg_file, 'w')
	if not file then
		log:error('CLOUD', 'Failed to open the configuration file', err)
		return nil, err
	end
	file:write('return '..pp(cfg)..'\n')
	file:close()
end

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

local function load_installed()
	_M.inst_apps = {}
	local apps = list.list()
	for k, v in pairs(apps) do
		table.insert(_M.inst_apps, v.app)
	end
end

--
-- Initialize the server url and cache folder
local function init ()
	load_cache()
	load_installed()
end

local function save_after_success(r, err)
	if r then
		save_config()
	end
	return r, err
end

_M.config = function(c)
	if type(c) == 'table' then
		cfg.srvurl = cfg.srvurl or cfg.srvurl
		cfg.cachefolder = cfg.cachefolder or cfg.cachefolder
		cfg.appsfolder = cfg.appsfolder or cfg.appsfolder
		return save_after_success(_M.update())
	end
	if type(c) == 'string' then
		cfg.srvurl = c
		return save_after_success(_M.update())
	end
	log:error('CLOUD', 'Incorrect config parameter')
	return nil, 'Incorrect config parameter'
end

--
-- Fetch the release.gz from server
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

--
-- Search one application
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

--
-- Install one application
_M.install = function(name, lname)
	log:info('CLOUD', "Installing "..name.." as "..lname)
	local app = nil
	for k, v in pairs(_M.apps) do
		if v.name == name then
			app = v
			break
		end
	end
	if not app then
		return nil, "no such app "..name
	end

	local src = cfg.srvurl..app.path..'/latest.zip'
	local dest = cfg.cachefolder..'/'..name..'.zip'
	log:info('CLOUD', "Download "..name.." from "..src.." to "..dest)
	local r, err = download(src, dest)
	if not r then
		log:warn('CLOUD', "Download fails", err)
		return nil, err
	end
		
	log:info('CLOUD', "Install "..lname.." to "..cfg.appsfolder)
	return install(dest, cfg.appsfolder, lname, app)
end

--
-- Remove one application
-- Mode: 'a' -- purge all stuff includes configuration
--       'n' -- only remove application, keep the configuration
_M.remove = function(lname, mode)
	local mode = mode or 'n'
	-- TODO: for clean the configuration
	return uninstall(cfg.appsfolder, lname)
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

init()

return _M
