return {
	get = function(req, res)
		local api = require 'shared.api.app'
		local port = api.find_app_port(app.appname)
		if port then
			local client = api.new(port)
			local r, err = client:request('learn_stop', {})
			if not r then
				res:write(err)
				return
			end
		end
		res:redirect('/apps/'..app.appname)
	end
}
