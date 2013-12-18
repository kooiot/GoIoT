
local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local zmq = require 'lzmq'

local ctx = zmq.context()

local server, err = ctx:socket({zmq.STREAM, linger=0, bind="tcp://*:8000"})

zassert(server, err)

while(true) do
	local id, err = server:recv_len(256)
	if not id then
		print(err)
	else
		print(id)
	end

	local msg, err = server:recv()
	if msg then
		print(msg)
	else
		print(err)
	end
end
