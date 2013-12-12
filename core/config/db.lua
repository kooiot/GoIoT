#!/usr/bin/env lua

local sql = require 'luasql.sqlite3'
local sqlite3 = sql.sqlite3()
local con = sqlite3:connect('config-db.sqlite3')

local _M = {}
local _buf = {}
local _del = {}

local _create_table = [[CREATE TABLE IF NOT EXISTS configs
						(key, value);]]
						--(id INTEGER PRIMARY KEY UNIQUE NOT NULL, key TEXT, value TEXT);]]

con:execute(_create_table)
con:setautocommit(false)

local function save_(key, value)
	--local s = string.format('REPLACE INTO configs VALUES (%d,"%s", "%s")', id, key, value)
	--local s = 'REPLACE INTO configs VALUES ('..id..',"'..key..'","'..value..'")'
	local s = string.format('REPLACE INTO configs VALUES ("%s", "%s")', key, value)
	return con:execute(con:escape(s))
end

local function delete_(key)
	local s = 'DELETE from configs WHERE key=="'..key..'";'

	return con:execute(con:escape(s))
end

local function load()
	local cur = con:execute('SELECT * FROM configs')

	if cur then
		local row = cur:fetch({})
		while row do
			for k,v in pairs(row) do
				_buf[k] = v
			end
			row = cur:fetch(row)
		end
	end

end

local function save()
	for k, v in pairs(_buf) do
		local r, err = save_(k, v)
		if not r then
			print('ERR', err)
		end
	end
	con:commit()
end

function _M.set(key, value)
	_buf[key] = value
end

function _M.get(key)
	return _buf[key]
end

function _M.add(key, value)
	_buf[key] = value
end

function _M.del(key)
	_buf[key] = nil
	_del[key] = true
end

_M.load = load
_M.timer = function()
	save()
	for k, v in pairs(_del) do
		if not _buf[key] then
			delete_(key)
		end
	end
	con:commit()
	_del = {}
end

_M.reload = function()
	_buf = {}
	_del = {}
	load()
end
