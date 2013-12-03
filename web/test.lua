--[[
cgilua.htmlheader()  

if cgilua.QUERY.language == 'english' then
	greeting = 'Hello World!'
elseif cgilua.QUERY.language == 'portuguese' then
	greeting = 'Olá Mundo!'
else
	greeting = '[unknown language]'
end

cgilua.put('<html>')  
cgilua.put('<head>')
cgilua.put('  <title>'..greeting..'</title>')
cgilua.put('</head>')
cgilua.put('<body>')
cgilua.put('  <strong>'..greeting..'</strong>')
]]--

local api = require 'api'

local function get_tag(name)
	local tag = api.get(name)
	for k,v in pairs(tag) do
		cgilua.put(k, '=', v)
		cgilua.put('<p>')
	end
end

get_tag('test.tag1')
get_tag('test.tag2')
get_tag('test.tag9')

