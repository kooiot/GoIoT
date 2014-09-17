cjson = require "cjson"

local t={["TEM"]={["jack"]="13001143649",
				["andy"]="13001143649",
				["sara"]="13001143649"},
		 ["VOL"]={["derk"]="13810955224",
		   		["jack"]="13001143649"},
		["SIGNAL"]=nil
			}
	
text = cjson.encode(t)
local file = io.open("test.json", "w+")
file:write(text)
