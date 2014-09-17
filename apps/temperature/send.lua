return {
	post = function(req, res)
		local command = req:get_arg('command')
		if not command then
			res:write('incorrect post')
		else
			local api = require 'shared.api.iobus.client'
			local client = api.new('web')
			local r, err = client:command(command, {})
			if r then
				res:write('done')
			else
				res:write(err)
			end
		end
	end
}
