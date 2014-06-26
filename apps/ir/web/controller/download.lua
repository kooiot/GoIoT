return {
	get = function(req, res)
		local templ = require 'shared.store.template'
		local cjson = require 'cjson.safe'

		local content, err = templ.download('admin/ir', 'GREE')
		print(content, err)
		if content then
			res.headers['Content-Type'] = 'application/json; charset=utf-8'
			res:write(content)
		else
			res:write(err)
		end
	end
}
