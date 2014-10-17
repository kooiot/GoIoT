
local function doi(req, res)
		local climate = {temp="error"}
	assert (app.appname)
		local cjson = require 'cjson.safe'
	--	local climate = {city="city",temp1="temp1",temp2="temp2", temp="temp",weather="weather",WD="WD",WS="WS",SD="SD",WES="WES",time="time"}
		local appapi = require 'shared.api.app'
		local port, err = appapi.find_app_port(app.appname)
		if not port then
			res:write(err or 'Error when trying to find application mgr port')
		else
			local client = appapi.new(port)
			local r, err = client:request('climate_data', {})
				client:close()
			if r then
				climate = r.rules
			end
		end

		local conf={}
		local list_onlight = {"NULL"}
			for i=0, 45 do
				list_onlight[#list_onlight+1] = i
			end
		local config = require 'shared.api.config'
		local conf, err = config.get(app.appname..'.temp') or
		[[	conf.onlight_less =  "NULL"
			conf.onlight_l_on =  "NULL"
			conf.onlight_l_num =  "NULL"
			conf.onlight_l_on_off =  "NULL"
			conf.onlight_l_on_off_num =  "NULL"
			
			conf.onlight_more =  "NULL"
			conf.onlight_m_on =  "NULL"
			conf.onlight_m_num =  "NULL"
			conf.onlight_m_on_off =  "NULL"
			conf.onlight_m_on_off_num =  "NULL"
		]]

		

		res:ltp('temp.html', {lwf=lwf, app=app, list_onlight=list_onlight,conf=conf})

end


return {
	get = 	doi,
	post = function(req, res)

		local conf = {}
	---------------小于光照动作-------------------
		local onlight_less = req:get_arg('onlight_less')
		local onlight_l_on = req:get_arg('onlight_l_on')
		local onlight_l_num = req:get_arg('onlight_l_num')
		local onlight_l_on_off = req:get_arg('onlight_l_on_off')
		local onlight_l_on_off_num = req:get_arg('onlight_l_on_off_num')
		
	--------------大于光照动作--------------------
		local onlight_more = req:get_arg('onlight_more')
		local onlight_m_on = req:get_arg('onlight_m_on')
		local onlight_m_num = req:get_arg('onlight_m_num')
		local onlight_m_on_off = req:get_arg('onlight_m_on_off')
		local onlight_m_on_off_num = req:get_arg('onlight_m_on_off_num')
		if (not onlight_less)then
			conf.onlight_less =  onlight_less or "NULL"
			conf.onlight_l_on =  onlight_l_on or "NULL"
			conf.onlight_l_num =  onlight_l_num or "NULL"
			conf.onlight_l_on_off =  onlight_l_on_off or "NULL"
			conf.onlight_l_on_off_num =  onlight_l_on_off_num or "NULL"
			
			conf.onlight_more =  onlight_more or "NULL"
			conf.onlight_m_on =  onlight_m_on or "NULL"
			conf.onlight_m_num =  onlight_m_num or "NULL"
			conf.onlight_m_on_off =  onlight_m_on_off or "NULL"
			conf.onlight_m_on_off_num =  onlight_m_on_off_num or "NULL"
			res:write('Incorrect post')
			
		else
			conf.onlight_more =  onlight_more or "NULL"
			conf.onlight_m_on =  onlight_m_on or "NULL"
			conf.onlight_m_num =  onlight_m_num or "NULL"
			conf.onlight_m_on_off =  onlight_m_on_off or "NULL"
			conf.onlight_m_on_off_num =  onlight_m_on_off_num or "NULL"
			
			conf.onlight_less =  onlight_less or "NULL"
			conf.onlight_l_on =  onlight_l_on or "NULL"
			conf.onlight_l_num =  onlight_l_num or "NULL"
			conf.onlight_l_on_off =  onlight_l_on_off or "NULL"
			conf.onlight_l_on_off_num =  onlight_l_on_off_num or "NULL"
			local config = require 'shared.api.config'
			config.set(app.appname..'.temp', conf)
			res:write('DONE')
		end


		local climate = {temp="error"}
		local cjson = require 'cjson.safe'

		local action = req:get_arg('action')
		if action == 'result' then

			local appapi = require 'shared.api.app'
			local port, err = appapi.find_app_port(app.appname)
			if not port then
				res:write(err or 'Error when trying to find application mgr port')
			else
				local client = appapi.new(port)
				local r, err = client:request('climate_data', {})
				client:close()
				if r then
					--res:write('Done, you need restart the application mannually')
					climate = r.rules
				else
					res:write(err..' '.. app.appname)
				end
			end
			res:write(climate)
		end 
		
	end
}

