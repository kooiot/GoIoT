
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local url = require 'socket.url'
local pp = require 'shared.PrettyPrint'
local cjson = require 'cjson.safe'
local zlib_loaded, zlib = pcall(require, 'zlib')

local KEY = nil
local URL = nil

local function api(method, obj, path)
	assert(path)
	local fpath = URL..'/'..path
	--print(fpath)
	local u = url.parse(fpath, {path=path, scheme='http'})

	local rstring = cjson.encode(obj)
	--print('JSON', rstring)
	if GZIP and zlib_loaded then
		rstring = zlib.compress(rstring, 9, nil, 15 + 16)
	end

	local re = {}

	u.source = ltn12.source.string(rstring)
	u.sink, re = ltn12.sink.table(re)
	u.method = method
	u.headers = {}
	u.headers['user-auth-key'] = KEY
	u.headers["content-length"] = string.len(rstring)
	--print(string.len(rstring))
	u.headers["content-type"] = "application/json;charset=utf-8"

	local r, code, headers, status = http.request(u)
	--print(r, code)--, pp(headers), status)

	if r and code == 200 then
		return true, table.concat(re)
	else
		local err = 'Error: code['..(code or 'Unknown')..'] status ['..(status or '')..']'
		print(err)
		return nil, err
	end
end

return {
	init = function (key, url, timeout)
		KEY = key
		URL = url
		http.TIMEOUT = timeout or 5
	end,
	call = api,
}
