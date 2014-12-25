return {
	post = function(req, res)
		local input = req:get_arg('input')
		if not input then
			res:write('incorrect post')
		else
			local api = require 'shared.api.iobus.client'
			local client = api.new('web')
			local r, err = client:read("sys/dev/inputs/time")
			local r, err = client:read(input)
			local config = require 'shared.api.config'
			config.set(app.appname..'.read', r)
			if r then
				local cjson = require 'cjson.safe'
				res:write(cjson.encode(r))
			else
				res:write(err)
			end
		end
	end
}
