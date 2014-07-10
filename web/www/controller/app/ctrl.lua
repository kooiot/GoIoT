
local function doi(req, res)
	local action = req:get_arg('action')
	if not action then
		res:write('Action not specified!')
		return
	end
	local appname = req:get_arg('app')
	if not appname then
		res:write('Application name not specified')
		return
	end

	local actions = {}

	actions.start = function(key, debug)
		local log = require 'shared.log'
		log:warn('WEB', 'Start application '..key)

		local app = require 'shared.api.app'
		local r, err = app.start(key, debug)

		if not r then
			log:error('WEB', err)
			res:write(err)
		else
			res:write('DONE')
		end
	end

	actions.enable = function(key)
	end

	actions.disable = function(key)
	end

	if actions[action] then
		actions[action](appname)
	else
		local log = require 'shared.log'
		log:warn('WEB', 'Process application action '..action)
		local event = require('shared.event').C.new()
		event:open()
		local r, err = event:send({src='web', name=action, dest=appname})
		if not r then
			res:write(err)
		else
			res:write('DONE')
		end
	end

end

return {
	get = doi,
	post = doi,
}
