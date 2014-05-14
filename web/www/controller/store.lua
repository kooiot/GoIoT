
return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local store = require 'shared.store'
			res:ltp('store/index.html', {lwf=lwf, app=app, srvurl=store.get_srv()})
		end
	end
}
