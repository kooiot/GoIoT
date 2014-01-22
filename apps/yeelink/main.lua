#!/usr/bin/env lua

local api = require 'shared.api.data'
local sub = require 'shared.api.data_sub'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local ztimer = require 'lzmq.timer'
local yapi = require 'yapi'
local log = require 'shared.log'

require 'shared.zhelpers'

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

local info = {}
info.port = 5611
info.ctx = zmq.context()
info.poller = zpoller.new()
info.name = ioname

local function load_key()
	local KEY = "6015c744795762df41e9ebfa25fd625c"
	return KEY
end
local KEY = load_key()
assert(KEY, "No Yeelink key")
yapi.init(KEY)

local dtree = {}

local function build_dtree()
	local tags = api.enum('*')
	for k, v in pairs(tags) do
		local devname, tagname = v.name:match('([^%.]+)%.(.+)$')
		print(v.name, 'Device', devname, 'Tag', tagname)
		dtree[devname] = dtree[devname] or {id=nil, name=devname}

		local dev = dtree[devname]
		dev.tags = dev.tags or {}
		dev.tags[tagname] = dev.tags[tagname] or {info = v, id=nil, sub=false, vals = {}, last=os.time() - 1}
	end

	return dtree
end

local function sub_dtree()
	local stags = {}
	local stags_t = {}
	for name, dev in pairs(dtree) do
		for name, v in pairs(dev.tags) do
			if not v.sub then
				table.insert(stags, v.info.name)
				table.insert(stags_t, v)
			end
		end

		if #stags ~= 0 then
			log:info(ioname, 'Subscribe data changes', name, #stags)
			local r, err = api.subscribe(ioname, stags)
			if r then
				for k, v in pairs(stags) do
					stags_t[k].sub = true
				end
			else
				log:error(ioname, 'Subscribe to db', err)
			end
		end
	end
end

local function yxx_map_tags(dev)
	log:debug(ioname, 'Mapping device', dev.name, 'id', dev.id)
	local sensors = yapi.sensors.enum(dev.id)
	local ids = {}

	for k, v in pairs(sensors) do
		ids[v.title] = v.id
	end

	for name, tag in pairs(dev.tags) do
		if tag.id then
			local r, err = yapi.sensors.get(dev.id, tag.id)
			if not r then
				tag.id = nil 
			end
		end
		if not tag.id  then
			tag.id = ids[name]
		end
		if not tag.id  then
			local r, err = yapi.sensors.create(dev.id, 'value', name, tag.info.desc, {}, {name="Unknown", symbol='N/A'})
			if not r then
				log:error(ioname, err)
			else
				tag.id = r
				log:info(ioname, 'Create sensor', tag.info.name, 'successfully')
			end
		end
	end
end

local function yxx_map()
	local devices = yapi.devices.enum()
	local ids = {}
	for k, v in pairs(devices) do
		ids[v.title] = v.id
	end

	for name, dev in pairs(dtree) do
		if dev.id then
			local dev, err = yapi.devices.get(dev.id)
			if not dev then
				dev.id = nil
			else
				log:debug(ioname, 'Device exist id is', dev.id)
			end
		end
		if not dev.id then
			dev.id = ids[name]
		end
		if not dev.id then
			local devid, err = yapi.devices.create(dev.name)
			if devid then
				log:info(ioname, 'Create device', dev.name, 'Sucessfully')
				dev.id = devid
			else
				log:error(ioname, err)
			end
		end
	end
	for name, dev in pairs(dtree) do
		if dev.id then
			yxx_map_tags(dev)
		end
	end
end

local function send_tag_data(devid, tag)
	if not tag.id then
		log:debug(ioname, 'Tag not created')
		return
	end

	local now = os.time()
	if now - tag.last > 11 then
		log:debug(ioname, 'SAVING', tag.info.name, tag.vals[1].value, 'COUNT', #tag.vals)
		local r, err = yapi.dp.adds(devid, tag.id, tag.vals)
		if r then
			tag.last = now
			tag.vals = {}
		else
			print(os.date('%c', now), os.date('%c', tag.last))
			log:error(ioname, err)
		end
	end
end

local function save_all(callback)
	for name, dev in pairs(dtree) do
		local devid = dev.id
		for name, tag in pairs(dev.tags) do
			send_tag_data(devid, tag)
			callback()
		end
	end
end

local function init_sub()
	sub.open(ioname, info.ctx, info.poller, function(filter, data)
		if data then
			local val = cjson.decode(data)
			--[[
			for k,v in pairs(tag) do
			print('PUB', k,v)
			end
			]]--

			local devname, tagname = val.name:match('([^%.]+)%.(.+)$')
			if devname and tagname then
				if dtree[devname] and dtree[devname].id then
					local tags = dtree[devname].tags

					if tags and tags[tagname] then
						local tag = tags[tagname]
						val.timestamp = val.timestamp / 1000
						table.insert(tag.vals, val)
					else
						log:debug(ioname, 'No such tag')
					end
				else
					log:debug("YEELINK", "Device not created")
				end
			else
				log:error("YEELINK", "Tag not formated correctly", tag.name)
			end
		end
	end)
end

local function on_start()
	build_dtree()
	yxx_map()

	init_sub()
	sub_dtree()
end
app = require('shared.app').new(info, {on_start = on_start})
app:init()

local ms = 3000
while not aborting do
	while not aborting do
		local timer = ztimer.monotonic(ms)
		timer:start()
		while timer:rest() > 0 do
			app:run(timer:rest())
		end
		save_all(function() app:run(50) end)
	end
end

sub.close()
