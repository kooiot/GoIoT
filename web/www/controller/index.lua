return {
	get = function(req, res)
		local applist = {}
		local apps = {}
		local user = lwf.ctx.user
		local list = require 'shared.app.list'
		local l = list.list()
		for name, v in pairs(l) do
			for _, info in pairs(v.insts) do
				apps[info.app.type] = apps[info.app.type]  or {}
				apps[info.app.type][#apps[info.app.type]+1] = {
					lname = info.insname,
					version = info.app.version,
					desc = info.app.desc,
					name = info.app.name,
					author = info.app.author,
				}
			end
		end
		res:ltp('index.html', {app=app, lwf=lwf, apps=apps})
	end
}
