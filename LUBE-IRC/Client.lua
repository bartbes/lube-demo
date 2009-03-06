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

socket = require "socket"

client = {}
client.__index = client
client.version = "0.03"

if LUBE_VERSION then
	if LUBE_VERSION ~= client.version then
		error("LUBE VERSIONS DO NOT MATCH")
		return nil
	end
else LUBE_VERSION = client.version
end
	
client.udp = {}
client.udp.protocol = "udp"
client.tcp = {}
client.tcp.protocol = "tcp"
client.ping = {}
client.ping.enabled = false
client.ping.time = 0
client.ping.msg = "ping"
client.ping.queue = {}
client.ping.dt = 0
local client_mt = {}
function client_mt:__call(...)
	local t = {}
	local mt = { __index = self }
	setmetatable(t, mt)
	t:Init(...)
	return t
end

setmetatable(client, client_mt)

function client:Init(socktype)
	self.host = ""
	self.port = 0
	self.connected = false
	if socktype then
		if self[socktype] then
			self.socktype = socktype
		elseif love.filesystem.exists(socktype .. ".sock") then
			love.filesystem.require(socktype .. ".sock")
			self[socktype] = _G[socktype]
			self.socktype = socktype
		else
			self.socktype = "udp"
		end
	else
		self.socktype = "udp"
	end
	for i, v in pairs(self[self.socktype]) do
		self[i] = v
	end
	self.socket = socket[self.protocol]()
	self.socket:settimeout(0)
	self.callback = function(data) end
	self.handshake = ""
end

function client:setPing(enabled, time, msg)
	self.ping.enabled = enabled
	if enabled then self.ping.time = time; self.ping.msg = msg; self.ping.dt = time end
end

function client:setCallback(cb)
	if cb then
		self.callback = cb
		return true
	else
		self.callback = function(data) end
		return false
	end
end

function client:setHandshake(hshake)
	self.handshake = hshake
end

function client.udp:connect(host, port, dns)
	if dns then
		host = socket.dns.toip(host)
		if not host then
			return false, "Failed to do DNS lookup"
		end
	end
	self.host = host
	self.port = port
	self.connected = true
	if self.handshake ~= "" then self:send(self.handshake) end
end

function client.udp:disconnect()
	if self.handshake ~= "" then self:send(self.handshake) end
	self.host = ""
	self.port = 0
	self.connected = false
end

function client.udp:send(data)
	if not self.connected then return end
	return self.socket:sendto(data, self.host, self.port)
end

function client.udp:receive()
	if not self.connected then return false, "Not connected" end
	local data, err = self.socket:receive()
	if err then
		return false, err
	end
	return true, data
end

function client.tcp:connect(host, port, dns)
	if dns then
		host = socket.dns.toip(host)
		if not host then
			return false, "Failed to do DNS lookup"
		end
	end
	self.host = host
	self.port = port
	self.socket:connect(self.host, self.port)
	self.connected = true
	if self.handshake ~= "" then self:send(self.handshake) end
end

function client.tcp:disconnect()
	if self.handshake ~= "" then self:send(self.handshake) end
	self.host = ""
	self.port = 0
	self.socket:shutdown()
	self.connected = false
end

function client.tcp:send(data)
	if not self.connected then return end
	if data:sub(-1) ~= "\n" then data = data .. "\n" end
	return self.socket:send(data)
end

function client.tcp:receive()
	if not self.connected then return false, "Not connected" end
	local data, err = self.socket:receive()
	if err then
		return false, err
	end
	return true, data
end

function client:doPing(dt)
	if not self.ping.enabled then return end
	self.ping.dt = self.ping.dt + dt
	if self.ping.dt >= self.ping.time then
		self:send(self.ping.msg)
		self.ping.dt = 0
	end
end

function client:update()
	if not self.connected then return end
	local success, data = self:receive()
	if success then
		self.callback(data)
	end
end
