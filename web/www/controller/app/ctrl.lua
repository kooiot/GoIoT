
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
		local list = require 'shared.app.list'
		local log = require 'shared.log'

		local app = list.find(key)
		if not app then
			res:write('The application['..key..'] is not installed')
		else
			local caddir = os.getenv('CAD_DIR') or '/tmp/cad2'
			local cmd = caddir..'/scripts/run_app.sh start '..app.name..' '..key

			if debug then
				if debug.addr then
					local file, err = io.open('/tmp/apps/_debug', "w")
					if file then
						local pp = require 'shared.PrettyPrint'
						local cfg = {}
						cfg.addr = debug.addr
						cfg.port = debug.port or 8172
						file:write('return '..pp(cfg)..'\n')
						file:close()
						cmd = cmd..' -debug'
					else
						log:error('WEB', err)
					end
				else
					log:error('WEB', "Incorrect debug post")
				end
			end

			log:debug('WEB', "Running application", cmd)
			os.execute(cmd)
			res:write('Starting application....')
		end
	end

	actions.enable = function(key)
	end

	actions.disable = function(key)
	end

	if actions[action] then
		actions[action](appname)
	else
		local event = require('shared.event').C.new()
		event:open()
		event:send({src='web', name=action, dest=appname})
		res:write('DONE')
	end

end

return {
	get = doi,
	post = doi,
}
