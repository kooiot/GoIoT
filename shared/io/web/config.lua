local cjson = require 'cjson.safe'
local api = require 'shared.api.config'

local name = cgilua.POST.name
if name then
	if cgilua.POST.key == 'ports' then
		local ports = cjson.decode(cgilua.POST.data)
		if ports and #ports ~= 0 then
			local reply, err = api.set(name..'.ports', ports)
			if reply then
				cgilua.print('done')
			else
				cgilua.print(err)
			end
		else
			cgilua.print('Incorrect port data') 
		end
	else
		cgilua.print('Incorrect port data') 
	end
else
	cgilua.print('ERROR')
end
