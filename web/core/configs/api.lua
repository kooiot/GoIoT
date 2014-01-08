local cjson = require 'cjson.safe'

cgilua.contentheader('application', 'text; charset=utf8')

if cgilua.POST.key then
	local api = require 'shared.api.configs'
	local vals, err = cjson.decode(cgilua.POST.value)
	if vals then
		local r, err = api.set(cgilua.POST.key, vals)
	end
	if err then
		put('<br> '..err)
	else
		put('<br> DONE')
	end
elseif cgilua.QUERY.key then
	local api = require 'shared.api.configs'
	local value, err = api.get(cgilua.QUERY.key)
	if not value then
	--	put(err)
	else
		put(cjson.encode(value))
	end
end

