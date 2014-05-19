return {
	get = function(req, res)
		--res:write(app.appname..'From app')
		--res:write(req:get_arg('insname', 'nil')..'From arg')
		local sysinfo = require 'shared.util.sysinfo'
		local info = sysinfo.network()
		local file, err = io.open('/etc/network/interfaces')
		local content = ""
		if file then
			content = (file:read('*a'))
			file:close()
		end
		res:ltp('index.html', {lwf=lwf, app=app, info =info, filecontent=content})
	end,
	post = function(req, res)
		local cfg = req:get_arg('cfg')
		os.execute('mv /etc/network/interfaces /etc/network/interfaces.bak')
		local file, err = io.open('/etc/network/interfaces', 'w+')
		--local file, err = io.open('/tmp/interfaces', 'w+')
		if file then
			file:write(cfg)
			file:close()
		end
		local delay_exec = require 'shared.util.delay_exec'
		res:write('system will be reboot to take your configuration file')
		delay_exec('reboot.sh', 'reboot')
	end
}
