--- The utility for download/upload templates to store
--

local _M = {}

--- Upload template to store 
-- @tparam string appname the name of application which templates belongs to
-- @tparam string name the name of this template
-- @tparam string desc the description of this template
-- @tparam string content the content of this template in json format
-- @treturn boolean result
-- @treturn string error message
function _M.upload(appname, name, desc, content)
end

--- Get the list of template names of application name
-- @tparam string appname the name of application which templates belongs to
-- @treturn table an array of name/description pair
-- @treturn string error message
function _M.list(appname)
end

--- Get the template content of template
-- @tparam string appname the name of application which templates belongs to
-- @tparam string name the name of this template
-- @treturn string the content of this template in json format
-- @treturn string error message
function _M.download(appname, name)
end

--- Fetch information from server
function _M.fetch(appname)
end
