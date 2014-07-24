return {
	get = function(req, res)
		local api = require 'shared.api.services'
		local cjson = require 'cjson.safe'
		local name = req:get_arg('name')
		local r, err
		if name then
			res.headers['Content-Type'] = 'application/json; charset=utf8'
			r, err = api.query(name)
			if r then
				res:write(cjson.encode(r))
				--r = {r}
			else
				lwf.set_status(403)
			end
		else
			r, err = api.list()
			res:ltp('system/services.html', {lwf=lwf, app=app, status = r, err = err})
		end
	end,
	post = function(req, res)
		local api = require 'shared.api.services'
		local action = req:get_arg('action')
		if action == 'add' then
			local name = req:get_arg('name')
			local dostr = req:get_arg('dostr')
			if name and dostr then
				local r, err = api.add(name, dostr)
				if r then
					res:write('done')
				else
					err = err or 'No err reports'
					res:write(err)
				end
			else
				res:write('Incorrect post parameters')
			end
		elseif action == 'abort' then
			local name = req:get_arg('name')
			if name then
				local r, err, status = api.abort(name)
				if r then
					res:write('DONE')
				else
					err = err or 'No err reports'
					res:write(err)
				end
			else
				res:write('Incorrect post parameters')
			end
		else
			res:write('No action handler '..action)
		end
	end,
}
