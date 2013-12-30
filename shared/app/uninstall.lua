

return function(apps_folder, name)
	local lock = lfs.lock_dir(apps_folder)
	local dest_folder = apps_folder..'/'..dest_name
	assert(os.execute('rm -rf '..dest_folder))
	lock:free()
end
