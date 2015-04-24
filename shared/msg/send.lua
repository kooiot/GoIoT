--- The utility helper function for sending result in json format

local cjson = require 'cjson.safe'

--- Create an new send helper object contains: result, err
-- @function Module
-- @tparam the connection object which has send function
-- @treturn table
return function(con)
	assert(con)
	local con = con

	--- Send result to peer
	-- @function result
	-- @tparam string msg the message id
	-- @tparam object result object
	-- @tparam strint err error information
	local result_f = function(msg, result, err)
		local reply = {msg, result, err}
		local rep_json, json_err = cjson.encode(reply)
		if not rep_json then
			rep_json, err = cjson.encode({msg, nil, json_err})
			assert(rep_json, err)
		end
		return con:send(rep_json)
	end
	--- Send error information to peer
	-- @function err
	-- @tparam string msg message id
	-- @tparam string err error information
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

