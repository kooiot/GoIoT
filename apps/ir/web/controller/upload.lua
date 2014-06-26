return {
	get = function(req, res)
		local cjson = require 'cjson.safe'
		local tpl = require 'shared.store.template'
		local r, err = tpl.upload('admin/ir', 'GREE', 'GREE Air Condition', [[{'adafa'='dafdafda','dafeeee'='wwwwwww'}]])
		if r then
			res.headers['Content-Type'] = 'application/json; charset=utf-8'
			res:write(cjson.encode(r))
		else
			res:write(err)
		end
	end
}
