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

server = {}
server.__index = server
server.version = "0.03"

if LUBE_VERSION then
	if LUBE_VERSION ~= server.version then
		error("LUBE VERSIONS DO NOT MATCH")
		return nil
	end
else LUBE_VERSION = server.version
end

server.udp = {}
server.udp.protocol = "udp"
server.tcp = {}
server.tcp.protocol = "tcp"
server.ping = {}
server.ping.enabled = false
server.ping.time = 0
server.ping.msg = "ping"
server.ping.queue = {}
server.ping.dt = 0
local server_mt = {}
function server_mt:__call(...)
	local t = {}
	local mt = { __index = self }
	setmetatable(t, mt)
	t:Init(...)
	return t
end

setmetatable(server, server_mt)

function server:Init(port, socktype)	Clients = {}

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
	self.handshake = ""
	self.recvcallback = function(data, ip, port) end
	self.connectcallback = function(ip, port) end
	self.disconnectcallback = function(ip, port) end
	self:startserver(port)
end

function server:setPing(enabled, time, msg)
	self.ping.enabled = enabled
	if enabled then self.ping.time = time; self.ping.msg = msg end
end

function server.udp:receive()
	return self.socket:receivefrom()
end

function server.udp:send(data, rcpt)
	if rcpt then
		return self.socket:sendto(data, rcpt, Clients[rcpt])
	else
		local errors = 0
		for ip, port in pairs(Clients) do
			if not pcall(self.socket.sendto, self.socket, data, ip, port) then errors = errors + 1 end
		end
		return errors
	end
end

function server.udp:startserver(port)
	self.socket:setsockname("*", port)
end

function server.tcp:receive()
	for i, v in pairs(ClientSocks) do
		local data = v:receive()
		if data then return data, v:getpeername() end
	end
end

function server.tcp:send(data, rcpt)
	if data:sub(-1) ~= "\n" then data = data .. "\n" end
	if rcpt then
		return ClientSocks[rcpt]:send(data)
	else
		local errors = 0
		for i, v in pairs(ClientSocks) do
			if not pcall(v.send, v, data) then errors = errors + 1 end
		end
		return errors
	end
end

function server.tcp:startserver(port)
	ClientSocks = {}
	self.socket:bind("*", port)
	self.socket:listen(5)
end

function server.tcp:acceptAll()
	local client = self.socket:accept()
	if client then
		local ip, port = client:getpeername()
		ClientSocks[ip] = client
	end
end

function server:setHandshake(hshake)
	self.handshake = hshake
end

function server:setCallback(recv, connect, disconnect)
	if recv then
		self.recvcallback = recv
	else
		self.recvcallback = function(data, ip, port) end
	end
	if connect then
		self.connectcallback = connect
	else
		self.connectcallback = function(ip, port) end
	end
	if disconnect then
		self.disconnectcallback = disconnect
	else
		self.disconnectcallback = function(ip, port) end
	end
	return (recv ~= nil), (connect ~= nil), (disconnect ~= nil)
end

function server:checkPing(dt)
	if not self.ping.enabled then return end
	self.ping.dt = self.ping.dt + dt
	if self.ping.dt >= self.ping.time then
		for ip, port in pairs(self.ping.queue) do
			self.disconnectcallback(ip, port)
			Clients[ip] = nil
		end
		self.ping.dt = 0
		self.ping.queue = {}
		for ip, port in pairs(Clients) do
			self.ping.queue[ip] = port
		end
	end
end

function server:update()
	local data, ip, port = self:receive()
	if data then
		if data == self.handshake then
			if Clients[ip] then
				Clients[ip] = nil
				return self.disconnectcallback(ip, port)
			else
				Clients[ip] = port
				return self.connectcallback(ip, port)
			end
		elseif data == self.ping.msg then
			self.ping.queue[ip] = nil
			return
		end
		return self.recvcallback(data, ip, port)
	end
end
