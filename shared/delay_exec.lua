local temp_folder = '/tmp'

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
