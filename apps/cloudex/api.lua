local rest = require 'rest'
local cjson = require 'cjson.safe'
local fifo = require 'shared.util.fifo'
local log = require 'shared.log'

local ioname = arg[1]

local _M = {}

local PUSH = {}
local ACTIONS = {}
local pcache = fifo()
local cache = fifo()
local MAX_CACHE_SIZE = 512

local function save_conf()
	local config = require 'shared.api.config'
	config.set(ioname..'.api.conf', cjson.encode({PUSH=PUSH}))
end

local function load_conf()
	local config = require 'shared.api.config'
	local r, err = config.get(ioname..'.api.conf')
	if r then
		local t, err = cjson.decode(r)
		if t then
			PUSH = t.PUSH
		end
	end
end

--- Initialize the api, and set the write/command callback function
_M.init = function(cfg, write, command)
	load_conf()
	rest.init(cfg.key, cfg.url, cfg.timeout, cfg.gzip)
	_M.on_write = write
	_M.on_command = command
end

_M.call = rest.call

_M.pull_command = function()
	local r, re = rest.call('GET', nil, 'actions/command')
	if not r then
		return nil, re
	end
	if string.len(re) == 0 then
		return true
	end

	local list, err = cjson.decode(re)
	if not list then
		return nil, err
	end
	for _, action in ipairs(list) do
		if action.path then
			log:warn(ioname, 'Received COMMAND, path: '..action.path)
			local r, err = _M.on_command(action.path, action.args)
			rest.call('POST', {name=name, id=action.id, result=r, err=err}, 'actions/command')
		else
			rest.call('POST', {name=name, id=action.id, result=false, err='No path in action'}, 'actions/command')
		end
	end
	return true
end

_M.pull_write = function()
	local r, re = rest.call('GET', nil, 'actions/output')
	if not r then
		return nil, re
	end
	if string.len(re) == 0 then
		return true
	end

	local list, err = cjson.decode(re)
	if not list then
		return nil, err
	end
	for _, action in ipairs(list) do
		if action.path then
			log:warn(ioname, 'Received WRITE, path: '..action.path)
			local r, err = _M.on_write(action.path, action.value)
			rest.call('POST', {name=name, id=action.id, result=r, err=err}, 'actions/output')
		else
			rest.call('POST', {name=name, id=action.id, result=false, err='No path in action'}, 'actions/command')
		end
	end
	return true
end

local function install_app(path, lname, version)
	assert(path, lname)
	local version = version or 'latest'

	local dostr = [[
	local store = require 'shared.store'
	assert(store.install("]]..lname..'","'..path..'","'..version..'"))'
	local api = require 'shared.api.services'
	local r, err = api.add('store.install.'..lname, dostr, 'Install '..lname..' ('..path..')')
	return r, err
end

local function uninstall_app(lname)
	local store = require 'shared.store'
	local r, err = store.remove(lname)
	return r, err
end

local function upgrade_app(lname, version)
	local list = require 'shared.app.list'
	list.reload()
	local info = list.find(lname) 
	if not info then
		return nil, 'ERROR: The application is not installed!!'
	end
	if info.version == version then
		return nil, 'ERROR: Application is latest version'
	end

	local path = info.path
	local dostr = [[
	local store = require 'shared.store'
	assert(store.upgrade("]]..path..'","'..version..'"))'
	local api = require 'shared.api.services'
	local r, err = api.add('store.install.'..lname..'.upgrade', dostr, 'Upgrade '..lname..' ('..path..')')
	return r, err
end

local function list_apps()
	local api = require 'shared.api.mon'

	local list = require 'shared.app.list'
	list.reload()
	local l = list.list() or {}

	local rlist = {}
	for k, v in pairs(l) do
		for _, info in ipairs(v.insts) do
			local run = false
			if info.insname then
				local vars = {info.insname}
				local status, err = api.query(vars)
				if status and status[info.insname] then
					run = status[info.insname].run
				else
					run = 'UNKNOWN'
				end
			end
			rlist[#rlist + 1] = {
				name = k,
				insname = info.insname,
				run = run,
				app = {
					name = info.app.name,
					path = info.app.path,
					author = info.app.author,
					desc = info.app.desc,
					version = info.app.version
				},
			}
		end
	end
	return rlist
end

local function list_services()
	local api = require 'shared.api.services'
	local list = api.list()
	return list
end

local function abort_service(name)
	local api = require 'shared.api.services'
	local r, err = api.abort(name)
	return r, err
end

local ACT_MAP = {}

_M.pull_extra = function()
	local r, re = rest.call('GET', nil, 'actions/system')
	if not r then
		return nil, re
	end
	if string.len(re) == 0 then
		return true
	end

	local list, err = cjson.decode(re)
	if not list then
		return nil, err
	end
	for _, action in ipairs(list) do
		local name = action.name
		local id = action.id
		assert(id and name)
		log:warn(ioname, 'Received action '..name)
		ACTIONS[id] = action
		if name == 'logs' then
			if action.enable then
				PUSH.log = true
			else
				PUSH.log = nil
			end
			save_conf()
			rest.call('POST', {name=name, id=id, result=true}, 'actions/system')
		elseif name == 'packets' then
			if action.enable then
				PUSH.packets = true
			else
				PUSH.packets = nil
			end
			save_conf()
			rest.call('POST', {name=name, id=id, result=true}, 'actions/system')
		elseif name == 'install' then
			local app_path = action.app_path
			local insname = action.insname
			--- Install application
			local r, err = install_app(app_path, insname)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'uninstall' then
			--- Uninstall application
			local insname = action.insname
			local r, err = uninstall_app(insname)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'upgrade' then
			local insname = action.insname
			local version = action.version
			local r, err = upgrade_app(insname, version)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'app_start' then
			local insname = action.insname
			local debug = action.debug
			local api = require 'shared.api.app'
			log:debug(ioname, 'Application start ', insname)
			local r, err = api.start(insname, debug)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'app_stop' then
			local insname = action.insname
			log:debug(ioname, 'Application stop ', insname)
			local api = require 'shared.api.app'
			local r, err = api.stop(insname)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'list' then
			--- List applications
			local list = list_apps()
			rest.call('POST', {name=name, id=id, result=true, list=list}, 'actions/system')
		elseif name == 'list_services' then
			--- List the backgroud services status
			local list = list_services()
			rest.call('POST', {name=name, id=id, result=true, list=list}, 'actions/system')
		elseif name == 'abort_service' then
			--- List the backgroud services status
			local name = action.name
			local r, err = abort_service(name)
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		elseif name == 'stript' then
			local script = actions.script
			local f = load(script)
			local r, err = f()
			rest.call('POST', {name=name, id=id, result=r, err=err}, 'actions/system')
		else
			rest.call('POST', {name=name, id=id, result=false, err='Action is recorgnized'}, '/actions/system')
		end
	end
	return true
end

_M.pull = function(cb)
	_M.pull_command()
	cb()
	_M.pull_write()
	cb()
	_M.pull_extra()
end

local function push_action_result()
	for k, v in pairs(ACTIONS) do
	end
end

_M.push = function(cb)
	--- PUSH action result
	if PUSH.log then
		local list = {}
		if cache:length() > 0 then
			cache:foreach(function(k,v)
				table.insert(list, v)
			end)
		end

		if #list ~= 0 then
			local r, err = rest.call('POST', list, '/logs')
			if r then
				cache:clean()
			end
		end
	end
	cb()
	if PUSH.packets then
		local list = {}
		if pcache:length() > 0 then
			pcache:foreach(function(k,v)
				table.insert(list, v)
			end)
		end

		if #list ~= 0 then
			local r, err = rest.call('POST', list, '/packets')
			if r then
				pcache:clean()
			end
		end
	end
end

_M.on_log = function(filter, log)
	-- Seperate the packat and log
	if log.level == 'packet' then
		pcache:push(log)
		if pcache:length() > MAX_CACHE_SIZE then
			pcache:pop()
		end
	else
		cache:push(log)
		if cache:length() > MAX_CACHE_SIZE then
			cache:pop()
		end
	end
end

--- Keep the device online?
_M.ping = function()
	local r, re = rest.call('POST', nil, '/ping')
	if not r then
		return nil, re
	end
	return true
end

return _M
