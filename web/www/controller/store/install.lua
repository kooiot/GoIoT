return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end
		if not appname then
			res:redirect('/store')
		else
			local store = require 'shared.store'
			res:ltp('store/detail.html', {app=app, lwf=lwf, appname=appname, srvurl=store.get_srv()})
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
		local desc = req:get_arg('desc') or 'You are too lazy, my body!'
		local lname = req:get_arg('lname')
		local typ = req:get_arg('type')
		local version = req:get_arg('version') or 'latest'
		local depends = req:get_arg('depends')
		if depends then
			local cjson = require 'cjson.safe'
			depends = cjson.decode(depends)
		end
		depends = depends or {}

		if name and path and lname then
			local depstr = ""
			if #depends then
				depstr = ", {"
			end
			for k, v in pairs(depends) do
				depstr = depstr..'"'..v..'",'
			end
			if #depends then
				depstr = depstr.."}"
			end

			local dostr = [[
				local store = require 'shared.store'
				assert(store.install("]]..name..'","'..path..'","'..typ..'","'..lname..'",[['..desc..']],"'..version..'"'..depstr..'))'
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
