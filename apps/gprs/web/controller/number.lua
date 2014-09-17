return {
	post = function(req, res)
			
	local api = require 'shared.api.iobus.client'
	local client = api.new('web')
	local cjson = require 'cjson.safe'

	local commands = {}
	local inputs = {}

	local nss, err = client:enum('.+')

	if nss then
		for ns, devs in pairs(nss) do
			local tree, err = client:tree(ns)

			if tree then
				for k, dev in pairs(tree.devices) do
					for k, v in pairs(dev.commands) do
						commands[#commands + 1] = {name=v.name, desc=v.desc, path=v.path}
						local r, err = client:command(v.path, {number="13001143649",name="jack"})
					end
					for k, v in pairs(dev.inputs) do
						inputs[#inputs + 1] = {name = v.name, desc = v.desc, path=v.path}
					end
				end
			end
		end	
	else
		info = err
	end
--	res:ltp('index.html', {lwf=lwf, app=app, rules=rules, commands=commands, inputs=inputs, info=info})
end
}
