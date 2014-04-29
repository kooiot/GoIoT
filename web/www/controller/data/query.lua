return {
	get = function(req, res)
		res.headers['Content-Type'] = 'application/json; charset=utf8'
		local shared = app.model:get('shared')

		--[[
		local api = shared.require('api.iobus')
		]]

		local j = {tags=tags}
		local cjson = require 'cjson.safe'
		res:write(cjson.encode(j))
	end
}
