
local config = require 'shared.api.config'
local key = cgilua.POST.key
local app = cgilua.POST.app


if not app or not key then
	put('ERROR', 'Incorrect Post!!')
else
	local r, err = config.set(app..'.key', key)
	if r then
		put('DONE')
	else
		put(err)
	end
end
