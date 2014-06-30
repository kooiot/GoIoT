return {
	get = function(req, res, insname, action)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		local action = action or ''
		local list = require 'shared.app.list'
		list:reload()
		if list.find(insname) then
			local platform = require 'shared.platform'
			local path = platform.path.apps..'/'..insname..'/web'
			local app = lwf.folk_app(insname, path)
			local urlpath = req.path:match('/apps/'..insname..'(.+)') or '/'

			--- get the insname by req:get_arg('insname') or app.appname or app.app_name
			req.uri_args['insname'] = req.uri_args['insname'] or insname
			app.appname = insname
			--- Get the static file real path
			app.static = function(self, path)
				assert(self)
				assert(path)
				return '/static/apps/'..(self.appname)..'/web/static/'..path
			end
			return app:dispatch(req, res, urlpath)
		else
			res:redirect('/#apps')
		end
	end
}
