return {
	get = function(req, res)
		local applist = {}
		local apps = {}
		local user = lwf.ctx.user
		--[[
		local db = app.model:get('db')
		if db:init() then
			if user then
				applist = db:list_apps(user.username)
			end
			apps = db:list_all()
		end
		]]--
		res:ltp('index.html', {app=app, lwf=lwf, applist=applist, apps=apps})
	end
}
