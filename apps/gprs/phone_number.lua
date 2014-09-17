cjson = require 'cjson.safe'

local tab = {{name="jack.dai",number="13001143649"}}

local _M={}
--------------------------------------
function table(t)
	for i, v in pairs(t) do
--		print ("...",v)
	if type(v) == "table" then
		print ("name",v.name)
		print ("number",v.number)
		t = v
		table (t)
		end
	end

end

function _M.insert(name, number)	
	local file = io.open("test.json","w+")
	tab[#tab+1] = {name=name, number=number}
	local t =cjson.encode(tab)
	file:write(t)
	file:close()
end


function _M.read()
	local file = io.open("test.json","r")
	t = file:read("*all")
	print ("-----------before_decode--------------",t)
	t = cjson.decode(t)
	table (t)
	file:close()
end

--[[
while true do 
	local case =io.read("*line")
	if case == "insert" then
		insert("jack","130014143649")
	end
	if case == "read" then
		read()
	end
end
--]]
return _M

