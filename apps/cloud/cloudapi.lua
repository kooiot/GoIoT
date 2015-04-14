
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local url = require 'socket.url'
local pp = require 'shared.util.PrettyPrint'
local cjson = require 'cjson.safe'

local KEY = nil
local URL = nil

local function api(method, obj, path)
	assert(path)
	print(URL..'/'..path)
	local u = url.parse(URL..'/'..path, {path=path, scheme='http'})

	local rstring = cjson.encode(obj)
	--print('JSON', rstring)

	local re = {}

	u.source = ltn12.source.string(rstring)
	u.sink, re = ltn12.sink.table(re)
	u.method = method
	u.headers = {}
	u.headers['U-ApiKey'] = KEY
	u.headers["content-length"] = string.len(rstring)
	--print(string.len(rstring))
	u.headers["content-type"] = "application/json;charset=utf-8"

	local r, code, headers, status = http.request(u)
	print(r, code)--, pp(headers), status)

	if r and code == 200 then
		return true
	else
		return nil, 'Error: code['..(code or 'Unknown')..'] status ['..(status or '')..']'
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
	init = function (key, url, timeout)
		KEY = key
		URL = url
		http.TIMEOUT = timeout or 5
	end,
	call = api,
}
