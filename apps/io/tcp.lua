
local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'

local ctx = zmq.context()

local client, err = ctx:socket({zmq.STREAM, linger=0, identity='abcde', connect="tcp://localhost:8000"})

zassert(client, err)

local id, err = client:getopt_str(zmq.IDENTITY)
zassert(id, err)
print(id, err)

while(true) do
	client:send(id, zmq.SNDMORE)
	client:send("hello world")

	local msg, err = client:recv()
	if msg then
		print(msg)
	else
		print(err)
	end
end
