--- execute function wrapper which take cares the difference between lua5.2 and lua5.1

--- Execute function
-- @function return
-- @tparam string cmd the command string
-- @treturn boolean execute result
-- @treturn number the process exit code
return function(cmd)
	if _VERSION == 'Lua 5.1' then
		local code = os.execute(cmd)
		return 0 == code, code 
	else
		local r, way, code = os.execute(cmd)
		return (r and (way == 'exit')), code
	end
end
