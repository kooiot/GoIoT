
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

return {
	get = function(req, res)
		local applist = {}
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
					summary = "<a>Symlink V3 </a> running well without any event fired",
				}
			}
		end
		res:ltp('index.html', {app=app, lwf=lwf, events=events, sevents=sys_events, err=err})
	end,
}
