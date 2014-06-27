return {
	get = function(req, res)
		local templ = require 'shared.store.template'
		local cjson = require 'cjson.safe'

		local list, err = templ.list('admin/ir')
		if list then
			res.headers['Content-Type'] = 'application/json; charset=utf-8'
			res:write(cjson.encode(list))
		else
			res:write(err)
		end
	end
}
