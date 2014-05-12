return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end
		if not appname then
			res:redirect('/store')
		else
			res:ltp('store/detail.html', {app=app, lwf=lwf, appname=appname})
		end
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		--- TODO: Using a standlone program to do the instllation, as this will block web server
		local name = req:get_arg('name')
		local path = req:get_arg('path')
		local lname = req:get_arg('lname')
		local typ = req:get_arg('type')

		if name and path and lname then
			local dostr = [[
				local store = require 'shared.store'
				store.install("]]..name..'","'..path..'","'..typ..'","'..lname..'")'
			local api = require 'shared.api.services'
			local r, err = api.add('store.install.'..lname, dostr, 'Install '..lname..' ('..path..')')
			if r then
				res:write('View backend for installation status')
			else
				res:write('ERROR: ', err)
			end
		else
			res:write('Error parameter')
		end
	end
}
