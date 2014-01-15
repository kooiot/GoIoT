local redirecthandler = require "xavante.redirecthandler"
local filehandler = require "xavante.filehandler"

local function addrule(rule)
  rules[#rules+1] = rule
end

--[[
addrule{ -- URI remapping example
  match = "^/images/(.+)",
  with = filehandler,
  params = {baseDir = docroot}
}

addrule{ -- URI remapping example
  match = "^/js/(.+)",
  with = filehandler,
  params = {baseDir = docroot}
}

addrule{ -- URI remapping example
  match = "^/css/(.+)",
  with = filehandler,
  params = {baseDir = docroot}
}
]]--

addrule{ -- URI remapping example
  match = "^/core/(.-)$",
  with = redirecthandler,
  params = {"/index.lua?_path=%1"}
}

