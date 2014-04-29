
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local url = require 'socket.url'
local pp = require 'shared.PrettyPrint'
local cjson = require 'cjson.safe'

http.TIMEOUT = 2

local KEY = 'bablbababab'
local base_url = 'http://172.30.0.115:8000/RestService/'

local function api(method, obj, path)
	assert(path)
	local u = url.parse(base_url..path, {path=path, scheme='http'})

	local rstring = cjson.encode(obj)
	--print('JSON', rstring)

	u.source = ltn12.source.string(rstring)
	local re = {}
	u.sink, re = ltn12.sink.table(re)
	u.method = method
	u.headers = {}
	u.headers['U-ApiKey'] = KEY
	u.headers["content-length"] = string.len(rstring)

	local r, code, headers, status = http.request(u, dest)
	print(r, code)--, pp(headers), status)

	if r and code == 200 then
		return true
	else
		return nil, 'Error'
	end
	--[[
	if r and code == 200 then
		if #re == 0 then
			return r, code, headers, status
		end

		local j, err = cjson.decode(table.concat(re))
		if j then
			print(pp(j))
			return j
		else
			return nil, code, headers, status, err
		end
	end
	return nil, code, headers, status
	]]--
end

return {
	init = function (key)
		KEY = key
	end,
	call = api,
}
