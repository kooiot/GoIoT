
local cjson = require 'cjson.safe'

return function(con)
	assert(con)
	local con = con

	local result_f = function(msg, result, err)
		local reply = {msg, result, err}
		local rep_json, json_err = cjson.encode(reply)
		if not rep_json then
			rep_json, err = cjson.encode({msg, nil, json_err})
			assert(rep_json, err)
		end
		con:send(rep_json)
	end
	local err_f = function(msg, err)
		assert(msg)
		assert(err)
		return result_f(msg, nil, err)
	end

	return {
		result = result_f,
		err = err_f,
	}
end

