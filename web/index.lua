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
local app = cgilua.QUERY._app or 'core'

local lp = require 'cgilua.lp'

local env = _ENV
env.path = path
env.app = app
env.user = user
env.put = cgilua.put
env.print = cgilua.put
env.redirect = cgilua.redirect
env.include = function(path, app)
	local app = app or 'core'
	lp.include(app..'/'..path, env)
end
env.script = function(path, app)
	local app = app or 'core'
	cgilua.doscript(app..'/'..path, env)
end
env.debug = function(...)
	io.write(...)
	io.write('\n')
end

env.url = function(url, app)
	local app = app or 'core'
	if app == 'core' then
		return '"/?_path='..url..'"'
	else
		return '"/?_app='..app..'&_path='..url..'"'
	end
end

local loader = require 'core.model'
env = loader.load(app, env)

cgilua.doscript("core/main.lua", env)
