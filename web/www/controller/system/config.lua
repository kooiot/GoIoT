local doi = function(req, res)
	local config = require 'shared.api.config'
	local lwfutil = require 'lwf.util'

	local list, err = config.list()
	for k, v in pairs(list) do
		--- Escape the string for avoid html tags
		list[k] = lwfutil.escape(v)
	end
	if not list then
		res:write(err)
	else
		res:ltp('system/config.html', {lwf=lwf, app=app, list=list})
	end
end

return {
	get = doi,
	post = function(req, res)
		local config = require 'shared.api.config'

		local action = req:get_arg('action')
		if action == 'delete' then
			local key = req:get_arg('key')
			if key then
				config.erase(key)
			end
		end
		if action == 'clear_all' then
			local r, err = config.clear()
		end

		return doi(req, res)
	end,
}
