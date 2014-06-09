return function(cmd)
	if _VERSION == 'Lua 5.1' then
		local code = os.execute(cmd)
		return 0 == code, code 
	else
		local r, way, code = os.execute(cmd)
		return (r and (way == 'exit')), code
	end
end
