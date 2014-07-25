return {
	post = function(req, res)
		if not lwf.ctx.user then
			return lwf.set_status(404)
		end

		local version = req:get_arg('version')
		if not version then
			res:write('Incorrect POST')
			return lwf.set_status(403)
		end

		local dostr = [[
			local system = require 'shared.system'
			assert(system.store_upgrade(]]..version..'))'

		local api = require 'shared.api.services'
		local r, err = api.add('system.upgrade', dostr, 'Upgrade system to('..version..')')
		if r then
			res:write('/waitor?name=system.upgrade&link=/system/services')
		else
			res:write('ERROR: ', err)
			lwf.set_status(403)
		end
	end
}
