cgilua.contentheader('application', 'text; charset=utf8')

if cgilua.POST.key then
	local event = require('shared.event').C.new()
	event:open()
	event:send({src='web', name=cgilua.POST.action, dest=cgilua.POST.key})
	put('DONE')
end
