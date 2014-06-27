return {
	get = function(req, res)
		local templ = require 'shared.store.template'
		local cjson = require 'cjson.safe'

		local applist = require 'shared.app.list'
		local app = applist.find(appname)
		local app_path = app and app.path or 'admin/ir'

		local list, err = templ.list(app_path)
		if list then
			res.headers['Content-Type'] = 'application/json; charset=utf-8'
			res:write(cjson.encode(list))
		else
			res:write(err)
		end
	end
}
