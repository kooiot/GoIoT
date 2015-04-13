--- Hex utitlity helpers
-- @author Dirk Chang
--

local dump = require 'shared.hex.dump'
local tohex = require 'shared.hex.tohex'

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
