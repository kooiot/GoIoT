local r = require 'runner'
local name = 'aaaa'
print('start service')
local pid, err = r.run(name, 'sleep 0')
print(pid, err)
print('check service')
assert(r.check(name))
print('abort service')
assert(r.abort(name))
