cgilua.contentheader('application', 'text; charset=utf8')

local key = cgilua.POST.key
local action = cgilua.POST.action

local actions = {}

actions.start = function(key)
	local list = require 'shared.app.list'

	local app = list.find(key)
	if not app then
		put('Can not find application information')
	end

	local caddir = os.getenv('CAD_DIR') or '/tmp/cad2'
	local cmd = caddir..'/scripts/run_app.sh '..app.name..' '..key..' start'
	os.execute(cmd)
	put('Starting application....')
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
