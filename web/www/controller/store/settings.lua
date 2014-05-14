return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local store = require 'shared.store'
			res:ltp('store/settings.html', {lwf=lwf, app=app, srvurl = store.get_srv()})
		end
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local srvurl = req:get_arg('srvurl')
			local userkey = req:get_arg('userkey')
			if srvurl and userkey then
				local store = require 'shared.store'
				local r, err = store.config('http://'..srvurl..'/static/releases')
				if not r then
					res:write(err)
					lwf.exit(500)
				else
					res:ltp('store/settings.html', {lwf=lwf, app=app, srvurl = store.get_srv()})
				end
			else
				res:write('Incorrect post')
				lwf.exit(403)
			end
		end
	end
}
