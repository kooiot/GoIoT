return {
	get = function(req, res)
		res:write('V3')
		local arg = req:get_arg('name')
		if not arg then
			res:write('hello')
		end
		if arg then
			res:write(arg)
		end
		res:write('\n')
	end,
}
