--- plugin example

local class = {}

function class:open()
end

function class:close()
end

function class:data(tag)
	tag:getAttr('n0')

	local port = app:getPort()
	port:send(string.byte(123))

	local msg, err = port:recv(32, 3000)
	if not msg then
		-- log the err
		print(err)
		return
	end

	-- process message
	local api = app:getDataApi()
	api:set('tag1', 10)
end

function class:command(cmd)
	if cmd.name == 'setdouble' then
	end
end

local function new(app)
	return setmetatable({app=app}, {__index=class})
end

