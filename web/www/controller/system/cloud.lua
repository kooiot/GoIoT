return {
	post = function(req, res)
		local enable = req:get_arg('enable')
		local ns = req:get_arg('namespace')
		local authkey = req:get_arg('authkey')
		if authkey and ns then
			local config = require 'shared.api.config'
			local cjson = require 'cjson.safe'
			local s, err = cjson.encode({namespace = ns, authkey = authkey, enable = enable and true or false})
			if s then
				local r, err = config.set('settings.cloud', s)
				if not r then
					res:write(err)
				else
					res:write('Cloud settings saved '..s)
				end
			else
				res:write(err)
			end
		else
			res:write('Incorrect post request')
		end
	end
}
