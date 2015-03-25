return {
	get = function(req, res)
		res:redirect('/static/backups/core.sfs')
	end,
	post = function(req, res)
		local socket = require 'socket'
		local platform = require 'shared.platform'
		-- TODO:
		os.execute('mkdir /tmp/backups/')
		os.execute('ln -s '..platform.path.core..'core.sfs /tmp/backups/')
		socket.sleep(1)
		res:write('/static/backups/core.sfs')
	end,
}
