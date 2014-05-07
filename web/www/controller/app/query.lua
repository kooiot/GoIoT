return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		local api = require 'shared.api.mon'
		local cjson = require 'cjson.safe'

		local appname = req:get_arg('app')

		local vars = appname and {appname} or nil
		local reply, err = api.query(vars)
		if reply then
			res.headers['Content-Type'] = 'application/json'
		end
		res:write(cjson.encode(reply and reply.status or err))
	end
}
