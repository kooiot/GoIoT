-- 
-- list all avaiable install applications
local cloud = require 'shared.cloud'
local cjson = require 'cjson.safe'

if cgilua.POST.action == 'config' then
	if cgilua.POST.url then
		local r, err = cloud.config(cgilua.POST.url)
		if r then
			put('DONE')
		else
			put('ERROR: ', err)
		end
	else
		put('Incorrect post parameter')
	end
end

if cgilua.POST.action == 'update' then
	local r, err = cloud.update()
	if r then
		put('DONE')
	else
		put('Failed update', err)
	end		
end

if cgilua.POST.action == 'search' then
	local key = cgilua.POST.key
	if key then
		local app, err = cloud.search(key)
		put(cjson.encode(app))
	else
		put('No search key specified')
	end
end

if cgilua.POST.action == 'list' then
	local mode = cgilua.POST.mode or 'a'
	local list = cloud.list(mode)
	put(cjson.encode(list))
end

if cgilua.POST.action == 'install' then
	local name = cgilua.POST.name
	local lname = cgilua.POST.lname
	if name and lname then
		local r, err = cloud.install(name, lname)
		if r then
			put('DONE')
		else
			put('ERROR: ', err)
		end
	else
		put('Error parameter')
	end
end

if cgilua.POST.action == 'remove' then
	local lname = cgilua.POST.lname
	local mode = cgilua.POST.mode
	if lname then
		local r, err = cloud.remove(lname, mode)
		if r then
			put('DONE')
		else
			put('ERROR', err)
		end
	else
		put('Error parameter')
	end
end

