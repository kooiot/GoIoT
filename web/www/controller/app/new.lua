local function get_full_path(path)
	local path = app.config.static..'releases/'..path
	os.execute('mkdir -p '..path)
	return path
end

local function save_app(path, file, version)
	local path = get_full_path(path)
	filename = path..'/latest.lpk'
	vfilename = path..'/'..version..'.lpk'
	print(filename, vfilename)
	local f, err = io.open(filename, 'w+')
	if f then
		f:write(file.contents)
		f:close()
		os.execute('cp '..filename..' '..vfilename)
		return true
	end
	return nil, err
end

local TYPES = {'IO', 'APP'}
local CATES = {'Industrial', 'Home Automation'}

return {
	get = function(req, res)
		if lwf.ctx.user then
			res:ltp('app/new.html')
		else
			res:redirect('/user/login')
		end
	end,
	post = function(req, res)
		req:read_body()
		if lwf.ctx.user then
			local file = req.post_args['file']
			local appname = req.post_args['appname']
			local apptype = req.post_args['apptype']
			local version = req.post_args['version']
			local category = req.post_args['category']
			local desc = req.post_args['desc']
			version = version:match('(%d+%.%d+%.%d+)')
			local info = 'Error:'
			if file and appname and version then 
				local version = version or '1.0.0'
				print(appname..'-'..apptype..'-'..category)
				local apptype = TYPES[tonumber(apptype) or 1]
				local category = CATES[tonumber(category) or 1]
				print(appname..'-'..apptype..'-'..category)
				local username = lwf.ctx.user.username
				local db = app.model:get('db')
				db:init()
				local info = db:get_app(username, appname)
				local path = username..'/'..appname
				local r, err = save_app(path, file, version)
				if r then
					if not info then
						db:create_app(username, appname, {path=path, name=appname, version=version, category=category, desc=desc})
					else
						db:update_app(username, appname, {path=path, name=appname, version=version, category=category, desc=desc})
					end
				end
				res:redirect('/app/detail/'..path)
			else
				if not appname then
					info = info..'\n Application name not specified'
				end
				if not version then
					info = info..'\n Application version not specified or incorrect'
				end
			end
			res:ltp('app/new.html', {app=app, lwf=lwf, info=info})
			--
		else
			res:redirect('/user/login')
		end
	end
}
