return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			res:redirect('/store#/settings')
		end
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:write('You should login first!!')
			lwf.exit(403)
		else
			local srvurl = req:get_arg('srvurl')
			local userkey = req:get_arg('userkey')
			if srvurl and userkey then
				local store = require 'shared.store'
				local r, err = store.config({srvurl='http://'..srvurl..'/static/releases', authkey=userkey})
				if not r then
					res:write(err)
					lwf.exit(500)
				else
					res:write('Store settings has been applied successfully!!!')
				end
			else
				res:write('Incorrect post')
				lwf.exit(403)
			end
		end
	end
}
