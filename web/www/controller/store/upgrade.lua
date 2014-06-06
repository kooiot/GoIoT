
return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		local inslist = {}
		local err = nil
		local lname = appname or req:get_arg('lname')
		if lname then
			local list = require 'shared.app.list'
			list.reload()
			local info = list.find(lname)
			inslist = list.enum_by_path(info.path)
		else
			err = 'Application instance name not specified'
		end

		res:ltp('store/upgrade.html', {lwf=lwf, app=app, inslist=inslist, lname=lname, err = err})
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		local lname = req:get_arg('lname')
		if not lname then
			res:write('ERROR', 'The application name is not specified!!')
			return
		end

		local list = require 'shared.app.list'
		list.reload()
		local info = list.find(lname) 
		if not info then
			res:write('ERROR: The application is not installed!!')
			return
		end
		local store = require 'shared.store'
		local app, err = store.find(info.path)
		if not app then
			res:write('ERROR: Applicaiton not found from store cache')
			return
		end
		if info.version == app.info.version then
			res:write('ERROR: Application is latest version')
			return
		end

		local version = app.info.version
		local path = info.path
		local dostr = [[
		local store = require 'shared.store'
		assert(store.upgrade("]]..path..'","'..version..'"))'
		local api = require 'shared.api.services'
		local r, err = api.add('store.install.'..lname..'.upgrade', dostr, 'Upgrade '..lname..' ('..path..')')
		assert(r, err)
		if r then
			res:write([[View the progress <a href="/store/backend">here</a>]])
		else
			res:write('ERROR:'..err)
		end
	end
}
