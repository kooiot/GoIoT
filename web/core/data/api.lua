cgilua.contentheader('application', 'json; charset=utf8')

local api = require 'shared.api.data'

local api_fail = false
local function get_tag(name)

	if api_fail then
		return nil
	end

	local tag = api.get(name)
	if not tag then
		api_fail = true
	end
	return tag
	--return {tag.name, tag.value, tag.timestamp}
end

local pattern = cgilua.QUERY.filter or "*"

local match_tags = api.enum(pattern)

local tags = {}
for k, v in pairs(match_tags) do
	table.insert(tags, v)
end

local cjson = require 'cjson.safe'

local j = {tags=tags}
cgilua.put(cjson.encode(j))

