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
		local status, err = api.query(vars)

		--[[
		if status then
			for k, v in pairs(status) do
				print(k)
				for k, v in pairs(v) do
					print(k, v)
				end
			end
		else
			print(status, err)
		end
		]]--

		if status then
			res.headers['Content-Type'] = 'application/json'
			res:write(cjson.encode(status))
		else
			res:write(err)
		end
	end
}
