local function upload_tpl(name, alias)
	local cjson = require 'cjson.safe'
	local tpl = require 'shared.store.template'
	local platform = require 'shared.platform'

	local path = platform.path.apps..'/'..app.appname..'/conf.json'
	local f, err = io.open(path)
	if not f then
		return nil, err
	end

	local c = f:read('*a')
	f:close()
	local cmds = cjson.decode(c)

	if not cmds[name] then
		return nil, 'No such template'
	end

	local content = cjson.encode(cmds[name])

	-- TODO: For description
	return tpl.upload('admin/ir', alias or name, 'IR template', content)
end

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
	end,
	post = function(req, res)
		local name = req:get_arg('name')
		local alias = req:get_arg('alias')
		if not alias or string.len(alias) == 0 then
			alias = name
		end

		local r, err = upload_tpl(name, alias)
		if r then
			res:write('DONE')
		else
			res:write(err)
		end
	end
}
