return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end
		if not appname then
			res:redirect('/store')
		else
			res:ltp('/store/install.html')
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

		if name and path and lname then
			local r, err = cloud.install(path, lname)
			if r then
				res:write('DONE')
			else
				res:write('ERROR: ', err)
			end
		else
			res:write('Error parameter')
		end
	end
}
