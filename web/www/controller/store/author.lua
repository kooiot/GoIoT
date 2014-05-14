return {
	get = function(req, res, username)
		local store = require 'shared.store'
		local srvurl = store.get_srv()
		res:redirect('http://'..(srvurl or 'store.symid.com')..'/users/'..username)
	end
}
