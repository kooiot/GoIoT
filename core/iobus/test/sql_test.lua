
local sql = require 'luasql.sqlite3'

local sqlite3 = sql.sqlite3()

local con = sqlite3:connect('config-db.sqlite3')

assert(con:setautocommit(false))
assert(con:execute([[ CREATE TABLE test (id, content) ]]))
--assert(con:execute(con:escape([[INSERT INTO test VALUES (1, "hello world")]])))
--assert(con:execute(con:escape([[INSERT INTO test VALUES (2, "hello lua")]])))
assert(con:commit())

local cur = assert(con:execute([[SELECT * FROM test]]))

print(cur)
if cur then
	print(cur:fetch())
	local row = cur:fetch({})
	while row do
		for k,v in pairs(row) do
			print(k,v)
		end
		row = cur:fetch(row)
	end
end

