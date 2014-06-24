return {
	post = function(req, res)
		local enable = req:get_arg('enable')
		local ns = req:get_arg('namespace')
		local authkey = req:get_arg('authkey')
		if authkey and ns then
			local config = require 'shared.api.config'
			local s = {namespace = ns, authkey = authkey, enable = enable and true or false}
			local r, err = config.set('settings.cloud', s)
			if not r then
				res:write(err)
			else
				res:write('Cloud settings saved!')
			end
		else
			res:write('Incorrect post request')
		end
	end
}
