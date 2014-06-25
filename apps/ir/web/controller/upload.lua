return {
	get = function(req, res)
		local tpl = require 'shared.store.template'
		tpl.upload()
	end
}
