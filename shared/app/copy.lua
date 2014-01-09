
return function(apps_folder, app, dest)
	local org_folder = apps_folder..'/'..app.name
	local new_folder = apps_folder..'/'..dest
	assert(os.execute('ln -s '..org_folder..' '..new_folder))
	
	list.add(dest, app.name, app)
end
