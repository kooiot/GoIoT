return {
	get = function(req, res)
		local cjson = require 'cjson.safe'
		local typ = req:get_arg('type', 'logs')
		local logs = app.model:get('logs')
		if not logs then
			res:write('')
		else
			res.headers['Content-Type'] = 'application/json'
			res:write(logs:query(typ))
		end
	end
}
