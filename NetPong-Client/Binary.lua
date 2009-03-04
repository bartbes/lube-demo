--[[
	Copyright © 2008 BartBes <bart.bes+nospam@gmail.com>

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.



	The above license is the MIT/X11 license, check the license for
	information about distribution.

	Also used:
		-LuaSocket (MIT license) Copyright © 2004-2007 Diego Nehab. All rights reserved. 
		-Lua (MIT license) Copyright © 1994-2008 Lua.org, PUC-Rio. 
]]--

bin = {}
bin.__index = bin

bin.null = string.char(30)
bin.one = string.char(31)
bin.defnull = bin.null
bin.defone = bin.one

function bin:setseperators(null, one)
	null = null or self.defnull
	one = one or self.defone
	self.null = null
	self.one = one
end

function bin:pack(t)
	local result = ""
	for i, v in pairs(t) do
		result = result .. self:packvalue(i, v)
	end
	return result
end

function bin:packvalue(i, v)
	local id = ""
	local typev = type(v)
	if typev == "string" then id = "S"
	elseif typev == "number" then id = "N"
	elseif typev == "boolean" then id = "B"
	elseif typev == "userdata"  then id = "U"
	elseif typev == "nil" then id = "0"
	else error("Type " .. typev .. " is not supported by Binary.lua") return
	end
	return tostring(id .. bin.one .. i .. bin.one .. tostring(v) .. bin.null)
end

function bin:unpack(s)
	local t = {}
	local i, v
	for s2 in string.gmatch(s, "[^" .. bin.null .. "]+") do
		i, v = self:unpackvalue(s2)
		t[i] = v
	end
	return t
end

function bin:unpackvalue(s)
	local id = s:sub(1, 1)
	s = s:sub(3)
	local len = s:find(bin.one)
	local i = s:sub(1, len-1)
	local v = s:sub(len+1)
	if id == "N" then v = tonumber(v)
	elseif id == "B" then v = (v == "true")
	elseif id == "0" then v = nil
	end
	return i, v
end
