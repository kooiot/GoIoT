local cjson = require 'cjson.safe'
local api = require 'shared.api.configs'

local name = cgilua.POST.name
if name then
	if cgilua.POST.key == 'ports' then
		local ports = cjson.decode(cgilua.POST.data)
		if ports and #ports ~= 0 then
			cgilua.print(api.set(name..'.ports', ports))
		else
			cgilua.print('Incorrect port data') 
		end
	end
	cgilua.print('done')
else
	cgilua.print('ERROR')
end
