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

cgilua.contentheader('text', 'plain')

local api = require 'shared.api.data'

local function get_tag(name)
	local tag = api.get(name)
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
