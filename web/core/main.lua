debug("_path=", path)

local lp_file = true
if path:sub(-1) == '/' then
	path = path..'index.lp'
else
	if not path:match("%.lp$") then
		if path:match("%.lua$") then
			lp_file = false
		else
			path = path..'/index.lp'
		end
	end
end


local real_path= "core/"..path

-- Do not try to access the core/main.lua
if real_path == "core/main.lua" then
	real_path = "core/index.lp"
end

debug("file=", real_path)
local file = io.open(real_path)
if file then
	file:close()
	if lp_file then
		--cgilua.htmlheader()
		-- load the pages now
		include("core/header.lp", env)
		include(real_path)
		include("core/footer.lp", env)
	else
		script(real_path)
	end
else
	include('core/404.lp')	
end

