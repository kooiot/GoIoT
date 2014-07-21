return {
	get = function(req, res)
		res.headers['Content-Type'] = 'application/json; charset=utf8'
		local shared = app.model:get('shared')

		local tags = {}

		local api = require('shared.api.iobus.client')
		local client = api.new('web')
		local nss, err = client:enum('.+')
		if nss then
			for ns, list in pairs(nss) do
				local tree, err = client:tree(ns)
				if tree and tree.devices then
					for _, dev in pairs(tree.devices) do
						for _, input in pairs(dev.inputs) do
							local vars, err = client:read(input.path)
							--[[
							if vars then
								for k, v in pairs(vars) do print(k, v) end
							else
								print(vars, err)
							end
							]]--
							vars = vars or {timestamp=0}
							local timestamp = vars.timestamp and  (vars.timestamp / 1000) or nil
							tags[#tags+1] = {name=input.path, desc=input.desc, value=vars.value or '', timestamp=os.date('%c', timestamp)}
						end
					end
				end
			end
		end

		local j = {tags=tags}
		local cjson = require 'cjson.safe'
		res:write(cjson.encode(j))
	end
}
