#!/usr/bin/env lua

local api = require 'shared.api.data'
local sub = require 'shared.api.data_sub'
local cjson = require 'cjson.safe'
local zpoller =  require 'lzmq.poller'
local zmq = require 'lzmq'
local yapi = require 'yapi'
local log = require 'shared.log'

require 'shared.zhelpers'

local ctx = zmq.context()
local poller = zpoller.new()

local ioname = arg[1]
assert(ioname, 'Applicaiton needs to have a name')

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
		dev.tags[tagname] = dev.tags[tagname] or {info = v, id=nil, sub=false, vals = {}, last=os.time() - 11}
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
			log:info('YEELINK', 'Subscribe data changes', name, #stags)
			local r, err = api.subscribe(ioname, stags)
			if r then
				for k, v in pairs(stags) do
					stags_t[k].sub = true
				end
			else
				log:error('YEELINK', 'Subscribe to db', err)
			end
		end
	end
end

local function yxx_map_tags(dev)
	log:debug('YEELINK', 'Mapping device', dev.name, 'id', dev.id)
	for name, tag in pairs(dev.tags) do
		if tag.id then
			local r, err = yapi.sensors.get(dev.id, tag.id)
			if not r then
				tag.id = nil 
			end
		end
		if not tag.id  then
			local ids, err = yapi.sensors.find(dev.id, tag.info.name)
			if ids then
				tag.id = ids[1]
			end
		end
		if not tag.id  then
			local r, err = yapi.sensors.create(dev.id, 'value', tag.info.name, tag.info.desc, {}, {name="Unknown", symbol='N/A'})
			if not r then
				log:error('YEELINK', err)
			else
				tag.id = r
				log:info('YEELINK', 'Create sensor', tag.info.name, 'successfully')
			end
		end
	end
end

local function yxx_map()
	for name, dev in pairs(dtree) do
		if dev.id then
			local dev, err = yapi.devices.get(dev.id)
			if not dev then
				dev.id = nil
			else
				log:debug('YEELINK', 'Device exist id is', dev.id)
			end
		end
		if not dev.id then
			local ids = yapi.devices.find(dev.name)
			if ids then
				dev.id = ids[1]
			end
		end
		if not dev.id then
			local devid, err = yapi.devices.create(dev.name)
			if devid then
				log:info('YEELINK', 'Create device', dev.name, 'Sucessfully')
				dev.id = devid
			else
				log:error('YEELINK', err)
			end
		end
	end
	for name, dev in pairs(dtree) do
		if dev.id then
			yxx_map_tags(dev)
		end
	end
end

build_dtree()
yxx_map()

local function send_tag_data(devid, tag, val)
	if not tag.id then
		log:debug('YEELINK', 'Tag not created')
		return
	end
	val.timestamp = val.timestamp / 1000
	table.insert(tag.vals, val)

	local now = os.time()
	if now - tag.last > 10 then
		yapi.dp.adds(devid, tag.id, tag.vals)
		tag.last = now
	end
end
sub.open(ioname, ctx, poller, function(filter, data)
	if data then
		local vals = cjson.decode(data)
		--[[
		for k,v in pairs(tag) do
			print('PUB', k,v)
		end
		]]--

		local devname, tagname = vals.name:match('([^%.]+)%.(.+)$')
		if devname and tagname then
			if dtree[devname] and dtree[devname].id then
				local tags = dtree[devname].tags

				if tags and tags[tagname] then
					send_tag_data(dtree[devname].id, tags[tagname], vals)
				else
					log:debug('YEELINK', 'No such tag')
				end
			else
				log:debug("YEELINK", "Device not created")
			end
		else
			log:error("YEELINK", "Tag not formated correctly", tag.name)
		end
	end
end)

sub_dtree()

poller:start()

sub.close()

