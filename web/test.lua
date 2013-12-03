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
local tag = api.get('tag1')
for k,v in pairs(tag) do
	cgilua.put(k, '=', v)
	cgilua.put('<p>')
end

