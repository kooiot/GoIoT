local doi = function(req, res)
	local config = require 'shared.api.config'
	local list, err = config.list()
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
