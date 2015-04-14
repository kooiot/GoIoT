--- Hex utitlity helpers
-- @author Dirk Chang
--

local dump = require 'shared.util.hex.dump'
local tohex = require 'shared.util.hex.tohex'

--- A dump function
-- Dump string to readable hex formated content
-- @type dump

--- A tohex function
-- Convert string to readable hex formated string
-- @type tohex


---@export
return {
	dump = dump,
	tohex = tohex,
}
