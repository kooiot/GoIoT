return {
	get = function(req, res)
		--res:write(app.appname..'From app')
		--res:write(req:get_arg('insname', 'nil')..'From arg')
		res:ltp('index.html')
	end
}
