local function get_tpl(name, app_path)
	local templ = require 'shared.store.template'
	local cjson = require 'cjson.safe'

	local content, err = templ.download(app_path or 'admin/ir', name)
	return content, err
end

local function save_file(lname, content)
	assert(lname)

	local path = os.tmpname()
	local f, err = io.open(path, 'w+')
	if not f then
		return nil, err
	end

	local cjson = require 'cjson.safe'
	local cmd, err = cjson.decode(content)
	if not cmd then
		return nil, err
	end

	f:write(cjson.encode({[lname]=cmd}))
	f:close()

	return path
end

local function import_tpl(appname, path)
	local api = require 'shared.api.app'

	local port, err = api.find_app_port(appname)
	if not port then
		os.remove(path)
		return nil, err
	end
	local client = api.new(port)
	local r, err = client:import(path)
	os.remove(path)
	return r, err
end

return {
	get = function(req, res)
		local content, err = get_tpl('admin/GREE')
		print(content, err)
		if content then
			res.headers['Content-Type'] = 'application/json; charset=utf-8'
			res:write(content)
		else
			res:write(err)
		end
	end,
	post = function(req, res)
		local name = req:get_arg('name')
		if not name then
			return lwf.exit(403)
		end

		local lname = req:get_arg('lname')
		if not lname or string.len(lname) then
			lname = name:match('/([^/]+)$')
		end

		local content, err = get_tpl(name)
		if not content then
			res:write(err)
		else
			-- TODO: Apply the template
			local path, err = save_file(lname, content) 
			if path then
				local r, err = import_tpl(app.appname, path)
				if r then 
					res:write('DONE')
				else
					res:write(err)
				end
			else
				res:write(err)
			end
		end
	end
}
