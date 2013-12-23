cgilua.contentheader('application', 'text; charset=utf8')

if cgilua.POST.key then
	local api = require 'shared.api.configs'
	local r, err = api.set(cgilua.POST.key, cgilua.POST.value)
	if not r then
		put(err)
	else
		put('DONE')
	end
elseif cgilua.QUERY.key then
	local api = require 'shared.api.configs'
	local value, err = api.get(cgilua.QUERY.key)
	if not value then
	--	put(err)
	else
		put(value)
	end
end

