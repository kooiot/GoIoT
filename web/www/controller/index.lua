
local SYS_SRC = {
	['IOBUS'] = 1,
	['CORE'] = 1,
	['APP'] = 1,
	['MONITOR'] = 1,
	['STORE'] = 1,
	['INSTALL.io'] = 1,
	['INSTALL.io.conf'] = 1,
	['WEB'] = 1,
	['RUNNER'] = 1,
	['SRV_RUNNER'] = 1,
	['SERVICES'] = 1,
}
local function log_to_event(logs)
	
	local events = {}
	local sys_events = {}
	for _, v in ipairs(logs) do
			local ev = {}
			if v.level == 'warn' then
				ev.label = {icon='green warning'}
			elseif v.level == 'error' then
				ev.label = {icon='red attention'}
			else
				ev.label = {icon='teal info'}
			end
			ev.date = os.date('%c', v.timestamp / 1000)
		if not SYS_SRC[v.src] then
			ev.extra = {
				text = v.content
			}
			ev.summary = '<a href="/apps/'..v.src..'">'..v.src..'</a>'
			table.insert(events, ev)
		else
			ev.summary = '<a>'..v.src..'</a> <p>'..v.content
			table.insert(sys_events, ev)
		end
	end
	return events, sys_events
end

local function query_log(limit)
	local api = app.model:get('logs')
	assert(api)
	
	local logs, err = api:query('logs')
	api:close()
	if logs then
		local cjson = require 'cjson.safe'
		local flogs = {}
		for k, v in pairs(logs) do
			local v = cjson.decode(v)
			if v and (v.level == 'warn' or v.level == 'error' or v.level == 'info') then
				flogs[#flogs + 1] = v
			end
			if limit and #flogs > limit then
				table.remove(flogs, 1)
			end
		end
		logs = flogs
	end
	return logs, err
end

local function get_system_settings()
	local settings = {}
	local config = require 'shared.api.config'
	local cloud, err = config.get('settings.cloud')
	settings.cloud = cloud
	return settings, err
end

return {
	get = function(req, res)
		local applist = {}
		local apps = {}
		local user = lwf.ctx.user
		local list = require 'shared.app.list'
		local api = require 'shared.api.mon'
		local store = require 'shared.store'
		list.reload()
		local l = list.list()
		for name, v in pairs(l) do
			for _, info in pairs(v.insts) do
				local run = 'UNKNOWN'
				if info.insname then
					local vars = {info.insname}
					local status, err = api.query(vars)
					if status and status[info.insname] then
						run = status[info.insname].run
					end
				end
				local app, err = store.find(info.app.path)
				local new_version = nil
				if app and app.info and app.info.version ~= info.app.version then
					new_version = app.info.version
				end


				apps[info.app.type] = apps[info.app.type]  or {}
				apps[info.app.type][#apps[info.app.type]+1] = {
					lname = info.insname,
					version = info.app.version,
					desc = info.app.desc,
					name = info.app.name,
					author = info.app.author or info.app.path:match('([^/]+)/.+'),
					path = info.app.path,
					run = run,
					new_version = new_version,
				}
			end
		end
		local logs, err = query_log(30)
		local events = {}
		local sys_events = {}
		if logs then 
			events, sys_events = log_to_event(logs)
		else
			events = {
				{
					label = {
						icon = 'green ok sign',
					},
					date = "Just moments ago",
					summary = "System running well without any event fired",
				}
			}
		end
		local settings, err = get_system_settings()
		res:ltp('index.html', {app=app, lwf=lwf, apps=apps, events=events, sevents=sys_events, settings=settings, err=err})
	end
}
