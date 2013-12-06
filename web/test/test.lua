--[[
cgilua.htmlheader()  

if cgilua.QUERY.language == 'english' then
	greeting = 'Hello World!'
elseif cgilua.QUERY.language == 'portuguese' then
	greeting = 'Olá Mundo!'
else
	greeting = '[unknown language]'
end

local title = 'Test getting tags'
cgilua.put('<html>')  
cgilua.put('<head>')
cgilua.put('  <title>'..title..'</title>')
cgilua.put('</head>')
cgilua.put('<body>')
cgilua.put('  <strong>'..title..'</strong>')

cgilua.put('</body>')
cgilua.put('</html>')  
]]--

--cgilua.contentheader('application/json', 'charset=utf-8')
cgilua.contentheader('application', 'json; charset=utf8')
--cgilua.header("Content-Type", "application/json; charset=utf-8")

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

local tags = {}
tags[#tags + 1] = get_tag('test.tag1')
tags[#tags + 1] = get_tag('test.tag1')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag2')
tags[#tags + 1] = get_tag('test.tag9')

local cjson = require 'cjson.safe'

local j = {tags=tags}
cgilua.put(cjson.encode(j))
