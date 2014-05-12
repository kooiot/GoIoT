local r = require 'runner'
local name = 'aaaa'
print('start service')
local pid, err = r.run(name, 'sleep.lua')
print(pid, err)
os.execute('sleep 20')
print('check service')
assert(r.check(name))
print('abort service')
assert(r.abort(name))
