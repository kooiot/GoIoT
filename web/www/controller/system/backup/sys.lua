return {
	get = function(req, res)
		res:redirect('/static/backups/cad2.sfs')
	end,
	post = function(req, res)
		local socket = require 'socket'
		-- TODO:
		os.execute('mkdir /tmp/backups/')
		os.execute('ln -s /home/user/cad2.sfs /tmp/backups/')
		socket.sleep(1)
		res:write('/static/backups/cad2.sfs')
	end,
}
