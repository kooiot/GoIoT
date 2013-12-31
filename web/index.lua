
local function auth_user()
	local username = cgilua.authentication.username()
	if not username then
		cgilua.redirect(cgilua.authentication.checkURL())
		return false
	end
	return true, username
end

local r, user = auth_user()
if not r then
	return
end

local logoutURL = cgilua.authentication.logoutURL()

local path = cgilua.QUERY._path or '/'

local lp = require 'cgilua.lp'
local urlcode = require 'cgilua.urlcode'

local env = _ENV
env.path = path
env.user = user
env.put = cgilua.put
env.print = cgilua.put
env.redirect = cgilua.redirect
env.rinclude = function(rpath, new_env)
	local folder = path
	if path:match('%.lp$') then
		folder = path:match('(.+)/(.-)%.lp$')
		if not folder then
			folder = '/'
		end
	end
	if path:match('%.lua$') then
		folder = path:match('(.+)/(.-)%.lua$')
		if not folder then
			folder = '/'
		end
	end
	lp.include('core/'..folder..'/'..rpath, new_env or env)
end
env.include = function(path)
	lp.include('core/'..path, env)
end
env.script = function(path)
	cgilua.doscript('core/'..path, env)
end
env.debug = function(...)
	io.write(...)
	io.write('\n')
end

env.url = function(url, args)
	local args = args or {}
	args['_path']=url
	--return '"/?'..urlcode.encodetable(args)..'"'
	local url = {}
	for k,v in pairs(args) do
		url[#url+1] = k..'='..v
	end
	return '/?'..table.concat(url, '&')
end

env.rurl = function(url, args)
	local folder = path
	if path:match('%.lp$') then
		folder = path:match('(.+)/(.-)%.lp$')
		if not folder then
			folder = '/'
		end
	end
	if path:match('%.lua$') then
		folder = path:match('(.+)/(.-)%.lua$')
		if not folder then
			folder = '/'
		end
	end
	local url = folder..'/'..url
	return env.url(url, args)
end

local loader = require 'core.model'
env = loader.load(app, env)

cgilua.doscript("core/main.lua", env)
