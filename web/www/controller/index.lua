local function log_to_event(logs)
	
	local events = {}
	for k, v in pairs(logs) do
		local ev = {}
		if v.level == 'warn' then
			ev.label = {icon='green warning'}
		elseif v.level == 'error' then
			ev.label = {icon='red attention'}
		else
			ev.label = {icon='teal info'}
		end
		ev.date = os.date('%c', v.timestamp / 1000)
		ev.summary = '<a href="/apps/'..v.src..'">'..v.src..'</a> log ['..v.level..']:'
		ev.extra = {
			text = v.content
		}
		table.insert(events, 1, ev)
	end
	return events
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
			if v and (v.level == 'warn' or v.level == 'error') then
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

return {
	get = function(req, res)
		local applist = {}
		local apps = {}
		local user = lwf.ctx.user
		local list = require 'shared.app.list'
		local l = list.list()
		for name, v in pairs(l) do
			for _, info in pairs(v.insts) do
				apps[info.app.type] = apps[info.app.type]  or {}
				apps[info.app.type][#apps[info.app.type]+1] = {
					lname = info.insname,
					version = info.app.version,
					desc = info.app.desc,
					name = info.app.name,
					author = info.app.author,
				}
			end
		end
		local logs, err = query_log(10)
		local events = {}
		if logs then 
			events = log_to_event(logs)
		else
			events = {
				{
					label = {
						icon = 'green ok sign',
					},
					date = "Just moments ago",
					summary = "<a>Symlink V3 </a> running well without any event fired",
				}
			}
		end
		res:ltp('index.html', {app=app, lwf=lwf, apps=apps, events=events, err=err})
	end
}
