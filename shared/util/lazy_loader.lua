local lfs = require 'lfs'

local function _enum_dir (path, cb)
	for file in lfs.dir(path) do
		if file ~= "." and file ~= ".." then
			local f = path..'/'..file
			local attr = lfs.attributes (f)
			assert (type(attr) == "table")
			if attr.mode == "directory" then
				_enum_dir (f, function(sub)
					cb(file..'/'..sub)
				end)
			else
				cb(file)
			end
		end
	end
end

local class = {}
local function _add_package(self, name, pkname)
	assert(name)
	assert(type(pkname) == 'string')
	self._packages[name] = function() return require(pkname) end
end

function class:load(base_folder, base_pk)
	assert(base_folder and base_pk)
	_enum_dir(base_folder, function(file, ...)
		local p = file:match('(.+)%.lua$') or file:match('(.+)%.luac$')
		if p then
			local pk = p:gsub('/', '.')
			_add_package(self, pk, base_pk..'.'..pk)
		end
	end)
end
function class:package(name, package)
	_add_package(self, name, package or name)
end

local _load = function(self, name)
	if not self._packages[name] then
		return assert(nil, 'package '..name..' does not exits this loader')
	end
	self._loaded[name] = self._packages[name]()
	return self._loaded[name]
end

local _loader_call = function(self, pkname)
	return self._loaded[pkname] or _load(self, pkname)
end

return function()
	return setmetatable({_loaded = {}, _packages={}}, {__index=class, __call=_loader_call})
end
