
local sql = require 'luasql.sqlite3'

local sqlite3 = sql.sqlite3()

local class = {}

local function create(path)
	local con = sqlite3:connect(path)

	assert(con:setautocommit(false))
	assert(con:execute(con:escape([[CREATE TABLE IF NOT EXISTS tags
									(id INTEGER PRIMARY KEY UNIQUE NOT NULL,
										name TEXT,
										desc TEXT,
										value TEXT,
										timestamp TEXT) ]])))
	assert(con:commit())
	assert(con:close())
end

function class:open(path)
	self.path = path
	self.conn = assert(sqlite3:connect(path))
	local check_sql = [[SELECT name FROM sqlite_master WHERE type = "table" AND name = "tags"]]
	check_sql = assert(self.conn:escape(check_sql))
	local cur = assert(self.conn:execute(check_sql))
	if not cur:fetch() then
		print('tags table not exist, create new')
		create(path)
	end
end

function class:add(name, desc, value)
	self.fake[name] = {name=name, desc=desc, value=value, timestamp = 0}
	return true
end

function class:erase(name)
	self.fake[name] = nil
	return true
end

function class:set(name, value, timestamp)
	if self.fake[name] then
		self.fake[name].value = value
		self.fake[name].timestamp = timestamp
		return true
	else
		return false, 'Tag '..name..' not exist'
	end
end

function class:get(name)
	if self.fake[name] then
		return true, self.fake[name].value, self.fake[name].timestamp
	else
		return false, 'Tag '..name..' not exist'
	end
end

function class:close()
	assert(self._conn:close())
end

local _M = {}

function _M.new()
	return setmetatable(
	{
		path = "db.sqlite3",
		conn = true,
		fake = {},
	}, {__index = class})
end

return _M
