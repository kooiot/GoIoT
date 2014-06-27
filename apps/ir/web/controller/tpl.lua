local function get_list(app_path)
	local templ = require 'shared.store.template'
	local cjson = require 'cjson.safe'

	local list, err = templ.list(app_path or 'admin/ir')
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

		local tlist = get_list()
		res:ltp('tpl.html', {lwf=lwf, app=app, devs=devs, tlist=tlist, info=info})
	end,
}
