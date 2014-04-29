return {
	get = function(req, res)
		res.headers['Content-Type'] = 'application/json; charset=utf8'
		local shared = app.model:get('shared')

		--[[
		local api = shared.require('api.iobus')
		]]

		local tags ={
			{
				name = "dddd",
				desc = "ddd desc",
				value = "10", 
				timestamp = os.date('%c', 12312322)
			},
			{
				name = "dddd2",
				desc = "ddd2 desc",
				value = "12", 
				timestamp = os.date('%c', 12312398)
			}
		}

		local j = {tags=tags}
		local cjson = require 'cjson.safe'
		res:write(cjson.encode(j))
	end
}
