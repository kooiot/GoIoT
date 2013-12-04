#!/usr/bin/env lua

local sql = require 'luasql.sqlite3'

for k, v in pairs(sql) do print(k,v) end

print(sql.sqlite3)
local sqlite3 = sql.sqlite3()

local con = sqlite3:connect('config-db.sqlite3')

con:execute([[ CREATE TABLE test (id, content) ]])

local r, err = con:execute(con:escape([[INSERT INTO test VALUES (1, "hello world")]]))
if not r then
	print (err)
end

r, err = con:execute(con:escape([[INSERT INTO test VALUES (2, "hello lua")]]))
if not r then
	print (err)
end

con:commit()


local cur = con:execute([[SELECT * FROM test]])

if cur then
	local row = cur:fetch({})
	while row do
		for k,v in pairs(row) do
			print(k,v)
		end
		row = cur:fetch(row)
	end
end

