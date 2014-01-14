
local log = require 'shared.log'

cgilua.contentheader('application', 'text; charset=utf8')

local key = cgilua.POST.key
local action = cgilua.POST.action

local actions = {}

actions.start = function(key)
	local list = require 'shared.app.list'

	local app = list.find(key)
	if not app then
		put('Can not find application information')
	else
		local caddir = os.getenv('CAD_DIR') or '/tmp/cad2'
		local cmd = caddir..'/scripts/run_app.sh start '..app.name..' '..key

		if cgilua.POST.debug == '1' then
			if cgilua.POST.addr then
				local file, err = io.open('/tmp/apps/_debug', "w")
				if file then
					local pp = require 'shared.PrettyPrint'
					local cfg = {}
					cfg.addr = cgilua.POST.addr
					cfg.port = cgilua.POST.port
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
		put('Starting application....')
	end
end

actions.enable = function(key)
end

actions.disable = function(key)
end

if key and action then
	if actions[action] then
		actions[action](key)
	else
		local event = require('shared.event').C.new()
		event:open()
		event:send({src='web', name=cgilua.POST.action, dest=cgilua.POST.key})
		put('DONE')
	end
else
	put('Incorrect POST params')
end
