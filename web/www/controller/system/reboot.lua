return {
	get = function(req, res)
		res:write('<br> rebooting...')
	end,
	post = function(req, res)
		res:write('<br> rebooting...')
		local delay_exec = app.model:get('shared').require('util.delay_exec')
		delay_exec('reboot.sh', 'reboot')
	end
}
