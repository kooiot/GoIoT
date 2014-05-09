return {
	get = function(req, res)
		local api = require 'shared.api.services'
		local cjson = require 'cjson.safe'
		local name = req:get_arg('name')
		local r, err
		if name then
			r, err = api.query(name)
			if r then
				r = {r}
			end
		else
			r, err = api.list()
		end
		res:ltp('system/services.html', {lwf=lwf, app=app, status = r, err = err})
	end,
	post = function(req, res)
		local api = require 'shared.api.services'
		local name = req:get_arg('name')
		local dostr = req:get_arg('dostr')
		local r, err = api.add(name, dostr)
		if r then
			res:write('done')
		else
			res:write(err)
		end
	end,
}
