local lfs = require 'lfs'

return function()
	local _packages = {}

	local function _enum_dir (path, cb)
		for file in lfs.dir(path) do
			if file ~= "." and file ~= ".." then
				local f = path..'/'..file
				local attr = lfs.attributes (f)
				assert (type(attr) == "table")
				if attr.mode == "directory" then
					--[[
					_enum_dir (f, function(sub)
						cb(file..'/'..sub)
					end)
					]]--
				else
					cb(file)
				end
			end
		end
	end

	local _loaded = {}
	local function _add_package(name, pkname)
		assert(not name:match('%.'))
		assert(type(pkname) == 'string')
		_packages[name] = function() return require(pkname) end
	end

	_loaded.load = function(base_folder, base_pk)
		assert(base_folder and base_pk)
		_enum_dir(base_folder, function(file)
			local p = file:match('(.+)%.lua$') or file:match('(.+)%.luac$')
			if p then
				local pk = p:gsub('/', '.')
				_add_package(pk, base_pk..'.'..pk)
			end
		end)
	end
	_loaded.package = function(name, package)
		if package and type(package) == 'table' then
			_loaded[name] = package
		else
			_add_package(name, package or name)
		end
	end

	local _load = function(name)
		_loaded[name] = _packages[name]()
		return _loaded[name]
	end

	local _loader = function(self, pkname)
		print(self, pkname)
		return _loaded[pkname] or _load(pkname)
	end

	return setmetatable({}, {__index=_loader})
end
