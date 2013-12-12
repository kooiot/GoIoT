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

local path = cgilua.QUERY._path
if not path then
	path = '/'
end

local lp = require 'cgilua.lp'

local env = _ENV
env.path = path
env.user = user
env.put = cgilua.put
env.print = cgilua.put
env.redirect = cgilua.redirect
env.include = function(path)
	lp.include(path, env)
end
env.script = function(path)
	cgilua.doscript(path, env)
end
env.debug = function(...)
	io.write(...)
	io.write('\n')
end

env.url = function(url)
	return '"/?_path='..url..'"'
end

local loader = require 'core.model'
env = loader.load(app, env)

cgilua.doscript("core/main.lua", env)
