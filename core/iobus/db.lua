
local sql = require 'luasql.sqlite3'
local log = require 'shared.log'

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
		log:info('IOBUS', 'tags table not exist, create new')
		create(path)
	end
end

function class:set(name, value, timestamp, quality)
	local obj = self.fake[name]
	if not obj then
		obj = {value=value, timestamp=timestamp, quality=quality}
		self.fake[name]  = obj
	else
		self.fake[name].value = value
		self.fake[name].timestamp = timestamp
	end
	return true
end

function class:get(name)
	local obj = self.fake[name]
	if obj then
		return true, obj.value, obj.timestamp, obj.quality
	else
		return false, 'Tag '..name..' not exist'
	end
end

function class:enum(pattern)
	if pattern == "*" then
		return self.fake
	end
	local matches = {}
	for k, v in pairs(self.fake) do
		if k:match(pattern) then
			matches[k] = v
		end
	end
	return matches
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
