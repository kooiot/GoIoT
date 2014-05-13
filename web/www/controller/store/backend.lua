return {
	get = function(req, res)
		local api = require 'shared.api.services'
		local cjson = require 'cjson.safe'
		local r, err = api.list()
		local status = {}
		r = r or {}
		for k, v in pairs(r) do
			if v.name:match('^store%.install%.') then
				status[#status + 1] = {
					name = v.name:match('^store%.install%.(.+)$'),
					desc = v.desc,
					status = v.status,
					result = v.result,
					output = v.output,
					pid = v.pid,
				}
			end
		end
		res:ltp('store/backend.html', {lwf=lwf, app=app, status = status, err = err})
	end,
	post = function(req, res)
		local api = require 'shared.api.services'
		local action = req:get_arg('action')
		if action == 'abort' then
			local name = req:get_arg('name')
			if name then
				name = 'store.install.'..name
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
