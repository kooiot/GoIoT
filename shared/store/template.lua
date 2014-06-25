--- The utility for download/upload templates to store
--

local ftp = require("socket.ftp")
local http = require("socket.http")
local url = require("socket.url")
local cjson = require 'cjson.safe'

local _M = {}

--- Get content
local get = function(src)
	local u = url.parse(src, {path='/', scheme='http'})
	if not u.host then
		return nil, "Missing host : "..src
	end

	if u.scheme == 'http' then
		local r, code, headers, status = http.request(src)
		if not r or code ~= 200 then
			return nil, status
		end
		return r
	elseif u.scheme == 'ftp' then
		u.type = u.type or 'i'
		return ftp.get(src)
	else
		return nil, "Not support url type :"..u.scheme
	end
end

local post = function(src, body)
	local u = url.parse(src, {path='/', scheme='http'})

	--local rstring = cjson.encode(obj)

	local re = {}

	u.source = ltn12.source.string(body)
	u.sink, re = ltn12.sink.table(re)
	u.method = 'POST' 
	u.headers = {}
	u.headers["content-length"] = string.len(body)
	u.headers["content-type"] = "application/json;charset=utf-8"

	local r, code, headers, status = http.request(u)
	print(r, code)--, pp(headers), status)

	if not r or code ~= 200 then
		return nil, status
	end
	return table.concat(re)
end

--- Upload template to store 
-- @tparam string appname the name of application which templates belongs to
-- @tparam string name the name of this template
-- @tparam string desc the description of this template
-- @tparam string content the content of this template in json format
-- @treturn boolean result
-- @treturn string error message
function _M.upload(appname, name, desc, content)
	local log = require 'shared.log'
	local store = require 'shared.store'

	local url = 'http://'..store.get_srv()..'/tpl/upload'
	log:info('store.template', 'post to '..url)

	local cjson = require 'cjson.safe'
	local str, err = post(url, cjson.encode({aaa=10}))
	print(str, err)
end

--- Get the list of template names of application name
-- @tparam string appname the name of application which templates belongs to
-- @treturn table an array of name/description pair
-- @treturn string error message
function _M.list(appname)
	local log = require 'shared.log'
	local store = require 'shared.store'

	local url = 'http://'..store.get_srv()..'/tpl/list'
	log:info('store.template', 'list from '..url)

	local str, err = get(url)
	if not str then
		return nil, err
	end
	return cjson.decode(str)
end

--- Get the template content of template
-- @tparam string appname the name of application which templates belongs to
-- @tparam string name the name of this template
-- @treturn string the content of this template in json format
-- @treturn string error message
function _M.download(appname, name)
end

--- Fetch information from server
-- @tparam string appname the name of application
function _M.fetch(appname)
end

return _M
