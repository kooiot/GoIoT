local mon = require 'shared.api.mon'
local app_status = mon.query()

local app = cgilua.QUERY.app

if not app_status or not app_status.result then
	cgilua.print('API failure!!!')
else
	for k,v in pairs(app_status.status) do
		if k ~= 'logs' then
			local link = url('apps/'..v.product..'/web', {name=k, port=v.port})
			put('<a href="'..link..'"> '..k..' </a>')
		end
	end
end
