
return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local store = require 'shared.store'

			local applist, err = store.search()
			res:ltp('store/index.html', {lwf=lwf, app=app, srvurl=store.get_srv(), applist=applist, err=err})
		end
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:write('You should login first!')
			lwf.exit(403)
		end
		local action = req:get_arg('action')
		if action == 'update' then
			-- TODO: fetch the update in services mode
			local dostr = [[ local store = require 'shared.store'
			assert(store.update())]]

			local api = require 'shared.api.services'
			local r, err = api.add('store.cache.update', dostr, 'update the store cache from server')
			if r then
				res:write('View backend for cache update running status')
			else
				res:write('ERROR: ', err)
				lwf.exit(403)
			end
		else
			local key = req:get_arg('key')
			if key and key == '' then
				key = nil
			end
			local store = require 'shared.store'
			local applist, err = store.search(key)

			if applist then
				res.headers['Content-Type'] = 'application/json'
				local cjson = require 'cjson'
				res:write(cjson.encode(applist))
			else
				res:write(err)
				lwf.exit(403)
			end
		end
	end,
}
