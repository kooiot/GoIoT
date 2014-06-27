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

local post = function(src, authkey, body)
	local u = url.parse(src, {path='/', scheme='http'})

	--local rstring = cjson.encode(obj)

	local re = {}

	u.source = ltn12.source.string(body)
	u.sink, re = ltn12.sink.table(re)
	u.method = 'POST' 
	u.headers = {}
	u.headers["authkey"] = authkey
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
-- @tparam string app_path the path of application which templates belongs to
-- @tparam string name the name of this template
-- @tparam string desc the description of this template
-- @tparam string content the content of this template in json format
-- @treturn boolean result
-- @treturn string error message
function _M.upload(app_path, name, desc, content)
	assert(app_path and name and desc and content)

	local store = require 'shared.store'
	local log = require 'shared.log'

	local key = store.get_authkey()
	if not key or string.len(key) == 0 then
		return nil, 'You have to set your authkey first'
	end

	local url = 'http://'..store.get_srv()..'/tpl/upload'
	log:info('store.template', 'post to '..url)

	local cjson = require 'cjson.safe'
	local t = {
		app_path = app_path,
		name = name,
		desc = desc,
		content = content
	}

	local r, err = post(url, key, cjson.encode(t))
	if not r then
		return nil, err
	end
	return cjson.decode(r)
end

--- Get the list of template names of application
-- @tparam string app_path the path of application which templates belongs to
-- @treturn table an array of name/description pair
-- @treturn string error message
function _M.list(app_path)
	local log = require 'shared.log'
	local store = require 'shared.store'

	local url = 'http://'..store.get_srv()..'/tpl/list?path='..app_path
	log:info('store.template', 'list from '..url)

	local str, err = get(url)
	if not str then
		return nil, err
	end
	return cjson.decode(str)
end

--- Get the template content of template
-- @tparam string app_path the path of application which templates belongs to
-- @tparam string path the path of this template
-- @treturn string the content of this template in json format
-- @treturn string error message
function _M.download(app_path, path)
	local log = require 'shared.log'
	local store = require 'shared.store'

	local url = 'http://'..store.get_srv()..'/tpl/download?app_path='..app_path..'&path='..path
	log:info('store.template', 'download from '..url)

	local str, err = get(url)
	return str, err
end

--- Fetch information from server
-- @tparam string app_path the path of application
function _M.fetch(app_path)
end

return _M
