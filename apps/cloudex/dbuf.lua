
local log = require 'shared.log'

local _M = {}

local buf = {}
local devlist = {}
local api = nil

local ioname = arg[1] or 'APP.CLOUD'

function _M.set_api(capi)
	api = capi
end

function _M.add_dev(device)
	local ns = device.path:match('^[^/]+')
	buf[ns] = buf[ns] or {}
	local t = buf[ns]

	for k,v in pairs(device.inputs) do
		local vt = { {value = v.value, timestamp = v.timestamp or (os.time() * 1000), quality=v.quality or 1} }
		t[v.path] = {path = v.path, devpath=device.path, values=vt}
	end
	devlist[device.path] = {sync=nil, device=device}
end

function _M.add_cov(path, value)
	assert(path)
	assert(value)
	print('on add_cov', path)
	local ns = path:match('^[^/]+')
	if ns and buf[ns] then
		local vt = buf[ns][path]
		vt.values[#vt.values + 1] = value
		--print('value size '..#vt.values)
	else
		local err = 'Error on '..ns
		log:error(ioname, err)
		return nil, err
	end
	return true
end

function _M.on_create(cb)
	for k, v in pairs(devlist) do
		if not v.sync then
			assert(v.device.version)
			log:debug(ioname, 'Create device:'..v.device.path..' in cloud')
			if v.device.path == 'sys/dev' then
				local cjson = require 'cjson.safe'
				print(cjson.encode(v.device))
			end
			local r, err = api.call('POST', v.device, 'device')
			if r then
				v.sync = true
			else
				log:error(ioname, 'failed to create device in cloud, error:'..err)
			end
			cb()
		end
	end
end

function _M.on_send(cb)
	--log:debug(ioname, 'On_send')
	for ns, t in pairs(buf) do
		local all = {}
		for path, vt in pairs(t) do

			if #vt.values ~= 0 then
				-- If not created then data will be droped for memory 
				if devlist[vt.devpath].sync then
					all[#all + 1] = {path = vt.path, values = vt.values}
				end

				vt.values = nil
				vt.values = {}
			end
		end
		--[[
		local pp = require 'shared.PrettyPrint'
		print(pp(all))
		]]--
		if #all ~= 0 then
			--log:debug(ioname, 'POST Data.............')
			local r, err = api.call('POST', all, 'data')
			if not r then
				log:error(ioname, err)
			end
		else
			--log:debug(ioname, ns..' has no updated data')
		end
		cb()
	end
end

return _M

