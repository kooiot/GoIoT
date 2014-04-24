--- Fifo module 
-- provides an class fifo
-- @module shared.fifo
--

local select , setmetatable = select , setmetatable
local print = print

--- The fifo class
-- @type fifo
local fifo = {}

--- The fifo metatable table
--
local fifo_mt = {
	__index = fifo ;
	__newindex = function ( f , k , v )
		if type (k) ~= "number" then
			error ( "Tried to set value in fifo" )
		else
			return rawset ( f , k , v )
		end
	end ;
}

local empty_default = function ( self ) error ( "Fifo empty" ) end

--- Create a fifo class object
-- @param ... objects initial pushed to fifo
-- @treturn fifo
function fifo.new ( ... )
	return setmetatable ( { empty = empty_default , head = 1 , tail = select("#",...) , ... } , fifo_mt )
end

--- Get the fifo length
-- @treturn number the fifo length as number
function fifo:length ( )
	return self.tail - self.head + 1
end

--- Peek one from fifo's head
-- the element not removed
function fifo:peek ( )
	return self [ self.head ]
end

--- Push on to fifo's tail
function fifo:push ( v )
	self.tail = self.tail + 1
	self [ self.tail ] = v
end

--- Pop the fifo's head
-- element removed from head
-- @return element
function fifo:pop ( )
	local head , tail = self.head , self.tail
	if head > tail then return self:empty() end

	local v = self [ head ]
	self [ head ] = nil
	self.head = head + 1
	return v
end

--- insert one element at specified position
-- @tparam number n the specified position
-- @param v new element
function fifo:insert ( n , v )
	local head , tail = self.head , self.tail

	local p = head + n - 1
	if p <= (head + tail)/2 then
		for i = head , p do
			self [ i - 1 ] = self [ i ]
		end
		self [ p - 1 ] = v
		self.head = head - 1
	else
		for i = tail , p , -1 do
			self [ i + 1 ] = self [ i ]
		end
		self [ p ] = v
		self.tail = tail + 1
	end
end

--- remove element at specified postion
-- @tparam number n the specified position
-- @return the removed element
function fifo:remove ( n )
	local head , tail = self.head , self.tail

	if head + n > tail then return self:empty() end

	local p = head + n - 1
	local v = self [ p ]

	if p <= (head + tail)/2 then
		for i = p , head , -1 do
			self [ i ] = self [ i - 1 ]
		end
		self.head = head + 1
	else
		for i = p , tail do
			self [ i ] = self [ i + 1 ]
		end
		self.tail = tail - 1
	end

	return v
end

--- Clean the fifo
-- remove all element from fifo
function fifo:clean( )
	local head , tail = self.head , self.tail
	for i = head, tail do
		self[i] = nil
	end
	self.head = 1
	self.tail = 0
end

--- Specify the empty element constructor function
-- @tparam function func
function fifo:setempty ( func )
	self.empty = func
end

local iter_helper = function ( f , last )
	local nexti = f.head+last
	if nexti > f.tail then return nil end
	return last+1 , f[nexti]
end

--- Get the iterator of fifo
-- @return interator
function fifo:iter ( )
	return iter_helper , self , 0
end

--- Process the element with func for each elements
-- @tparam function func
function fifo:foreach ( func )
	for k,v in self:iter() do
		func(k,v)
	end
end

fifo_mt.__len = fifo.length

--- Return fifo.new function as the module
return fifo.new
