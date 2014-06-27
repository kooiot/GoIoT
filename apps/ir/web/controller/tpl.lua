local function get_list(appname)
	local templ = require 'shared.store.template'
	local cjson = require 'cjson.safe'

	local list = require 'shared.app.list'
	local app = list.find(appname)
	local app_path = app and app.path or 'admin/ir'

	local list, err = templ.list(app_path)
	return list, err
end

return {
	get = function(req, res)
		local devs = {}
		local info = nil

		local mon = require 'shared.api.mon'
		local status, err = mon.query({app.appname})
		if status and status[app.appname] then
			local api = require 'shared.api.app'
			local client = api.new(status[app.appname].port)
			local r, err = client:request('list_devs', {})
			for k, v in pairs(r) do print(k, v) end
			print(r, err)
			if r then
				devs = r
			else
				info = err
			end
		else
			info = err or 'Cannot find status'
		end

		local tlist = get_list(app.appname)
		res:ltp('tpl.html', {lwf=lwf, app=app, devs=devs, tlist=tlist, info=info})
	end,
}
