#!/usr/bin/env lua

local api = require 'api'

local tags = {}


function create_tags(num)
	for v = 1, num do
		local tag = { name = 'test.tag'..v, desc= 'test.desc'..v, value=0}
		tags[#tags + 1] = tag
		api.add(tag.name, tag.desc, tag.value)
	end
end

function remove_tags()
	for k, v in pairs(tags) do
		api.erase(v.name)
	end
end

create_tags(10)

local loop = true
local var = 1
while loop do
	for k,v in pairs(tags) do
		api.set(v.name, v.value, os.date())
		v.value = v.value + 1
	end
	--[[
	local tag = api.get('tag1')
	print(tag)
	for k,v in pairs(tag) do
		print(k,v)
	end
	]]--
	sleep(1)
	var = var + 1
end

remove_tags()
