
local _M = {}

local buf = {}

function _M.add_dev(device)
	local ns = device.path:match('^[^/]+')
	print('create device under ns ', ns)
	buf[ns] = buf[ns] or {}
	local t = buf[ns]

	for k,v in pairs(device.inputs) do
		local vt = { {value = v.value, timestamp = v.timestamp, quality=v.quality} }
		t[v.path] = {path = v.path, values=vt}
	end

	print('Input counts', #t)

end

function _M.add_cov(path, value)
	assert(path)
	assert(value)
	local ns = path:match('^[^/]+')
	if ns and buf[ns] then
		local vt = buf[ns][path]
		vt.values[#vt.values + 1] = value
		print('value size '..#vt.values)
	else
		print('error on ', ns)
	end
end

function _M.send_all(api)
	for ns, t in pairs(buf) do
		local all = {}
		for path, vt in pairs(t) do
			if #vt.values ~= 0 then
				all[#all + 1] = {path = vt.path, values = vt.values}
				vt.values = nil
				vt.values = {}
			end
		end
		--[[
		local pp = require 'shared.PrettyPrint'
		print(pp(all))
		]]--
		api.call('POST', all, 'Data')
	end
end

return _M

