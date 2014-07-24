return {
	post = function(req, res)
		req:read_body()
		if not lwf.ctx.user then
			lwf.exit(401)
			return
		end
		local appname = req:get_arg('app')
		if not appname then
			lwf.exit(400)
			return
		end
		local store = require 'shared.store'
		local r, err = store.remove(appname)
		if r then
			res:write('DONE')
		else
			res:write(err)
		end
	end,
}
