--- Execute commands with delayed method
-- delay three seconds then execute the commands, function returned before commands been executed
-- 

--- The default temperate file saving path
local temp_folder = '/tmp'

--- Execute function 
-- @function return
-- @tparam string filename the filename saved the temperatly shell file
-- @tparam table cmds the commands table
-- @return nil
return function (filename, cmds)
	if type(cmds) == 'string' then
		cmds = {cmds}
	end

	local temp_file = temp_folder..'/'..filename
	os.execute('echo "sleep 3;" >> '..temp_file)
	for i, cmd in pairs(cmds) do
		os.execute('echo "'..cmd..';" >> '..temp_file)
	end
	os.execute('sh '..temp_file..' > /tmp/log.log &')
end
