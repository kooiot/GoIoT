cgilua.contentheader('application', 'text; charset=utf8')

if cgilua.POST.key then
	local api = require 'shared.api.configs'
	local r, err = api.set(cgilua.POST.key, cgilua.POST.value)
	if not r then
		cgilua.put(err)
	else
		cgilua.put('DONE')
	end
elseif cgilua.QUERY.key then
	local api = require 'shared.api.configs'
	local value, err = api.get(cgilua.QUERY.key)
	if not value then
	--	cgilua.put(err)
	else
		cgilua.put(value)
	end
end

