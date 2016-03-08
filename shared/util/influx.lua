
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local cjson = require 'cjson'
local url = require 'socket.url'
local zlib_loaded, zlib = pcall(require, 'zlib')
local class = require 'middleclass'

local API = class('InfuxDBLuaApi')

function API:initialize(host, opts, timeout, gzip)
	self._HOST = host
	self._OPTS = opts
	self._TIMEOUT = timeout or 5
	self._GZIP = gzip
end

function API:URL(path)
	if not self._OPTS then
		return self._HOST..path
	else
		return self._HOST..path..'?'..self._OPTS
	end
end

function API:post(content)
	local u = url.parse(self:URL('/write'), {path='', scheme='http'})

	if type(content) == 'table' then
		content = table.concat(content, '\n')
	end

	if self._GZIP and zlib_loaded then
		content = zlib.compress(content, 9, nil, 15 + 16)
	end

	local re = {}

	u.source = ltn12.source.string(content)
	u.sink, re = ltn12.sink.table(re)
	u.method = 'POST'
	u.headers = {}
	u.headers["content-length"] = string.len(content)
	u.headers["content-type"] = "application/x-www-form-urlencoded;charset=utf-8"

	if self._GZIP and zlib_loaded then
		u.headers["content-encoding"] = "gzip"
	end

	http.TIMEOUT = self._TIMEOUT
	local r, code, headers, status = http.request(u)
	--print(r, code)--, pp(headers), status)

	if r and code >= 200 and code <=300  then
		return true, table.concat(re)
	else
		local err = 'Error: code['..(code or 'Unknown')..'] status ['..(status or '')..']'
		print(err)
		print(table.concat(re))
		return nil, err
	end
end

function API:get(query)
	local query = url.escape(query)
	local u = url.parse(self:URL('/query'), {path='', scheme='http'})

	u.query = u.query and u.query..'&epoch=ms&q='..query or 'epoch=ms&q='..query

	local re = {}

	u.sink, re = ltn12.sink.table(re)
	u.method = 'GET'
	u.headers = {}
	u.headers["content-length"] = 0
	u.headers["content-type"] = "application/json;charset=utf-8"

	http.TIMEOUT = self._TIMEOUT
	local r, code, headers, status = http.request(u)
	--print(r, code)--, pp(headers), status)

	if r and code >= 200 and code <=300  then
		return true, table.concat(re)
	else
		local err = 'Error: code['..(code or 'Unknown')..'] status ['..(status or '')..']'
		print(err)
		print(table.concat(re))
		return nil, err
	end
end


local INF = class('INFLUX_API')
function INF:initialize(m)
	self._lwf = m.lwf
	self._app = m.app
end

function INF:init()
	self._api = API:new("http://localhost:8086", "db=test&u=test&p=test", 2, false)
	--api:init("http://kooiot.com:8086/query?db=rtdb&u=test&p=test", 2, false)
end

function INF:close()
end

function INF:list(key, path, len)
	local len = len or 10240
	local query = {
		'select * from ',
		key,
		' where path=',
		"'"..path.."'",
		' limit ',
		len
	}
	local r, data = self._api:get(table.concat(query))
	if r then
		local r, jdata = pcall(cjson.decode, data)
		if not r then
			return nil, data
		end

		local results = jdata.results
		if not results or #results == 0 then
			return nil, 'No results in database'
		end
		assert(#results == 1)

		local series = results[1].series
		if not series or #series == 0 then
			return nil, 'No series in database'
		end

		print(series[1].name, key)
		assert(series[1].name == key)
		local its = 1
		local ival = 4
		local iqual = 3
		local columns = series[1].columns
		for i, v in ipairs(columns) do
			if v == 'time' then
				its = i
			end
			if v == 'value' then
				ival = i
			end
			if v == 'quality' then
				iqual = i
			end
		end

		local values = series[1].values
		local rdata = {}
		for _, v in ipairs(values) do
			rdata[#rdata + 1] = {timestamp=v[its], value=v[ival], quality=v[iqual]}
		end
		return rdata
	else
		return nil, data
	end

end

function INF:get(key, path)
	local r, err = self:list(key, path, 1)
	if r then
		return r[1]
	end
	return nil, err
end

function INF:add(key, path, list)
	local data = {}
	for _, v in ipairs(list) do
		data[#data + 1] = table.concat({
			key..',path=',
			path,
			' value=',
			v.value,
			',quality=',
			v.quality or 0,
			' ',
			tostring(v.timestamp) or '',
			"000000",
		})
	end
	local r, err = self._api:post(data)
	if not r then 
		print(err)
		return nil, err
	end
	return true
end

return INF
