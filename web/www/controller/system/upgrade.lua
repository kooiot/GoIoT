
return {
	get = function(req, res)
		if lwf.ctx.user then
			res:ltp('system/upgrade.html')
		else
			res:redirect('/user/login')
		end
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:write("You are not logined")
			lwf.set_status(403)
			return
		end

		req:read_body()

		local file = req.post_args['file']

		if not file or type(file) ~= 'table' or not next(file) then
			res:write('Incorrect post found')
			return lwf.set_status(403)
		end

		res:write("<br> Uploaded ("..string.len(file.contents).." bytes)")

		local system = require 'shared.system'
		local r, info = system.upgrade(file)
		res:write(info)
		if not r then
			lwf.set_status(403)
		end
	end
}
