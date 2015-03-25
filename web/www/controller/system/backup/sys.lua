return {
	get = function(req, res)
		res:redirect('/static/backups/kooiot.sfs')
	end,
	post = function(req, res)
		local socket = require 'socket'
		-- TODO:
		os.execute('mkdir /tmp/backups/')
		os.execute('ln -s /home/user/kooiot.sfs /tmp/backups/')
		socket.sleep(1)
		res:write('/static/backups/kooiot.sfs')
	end,
}
