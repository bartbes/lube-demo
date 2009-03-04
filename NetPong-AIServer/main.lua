love.filesystem.require("Server.lua")
love.filesystem.require("Binary.lua")
love.filesystem.require("ai.lua")

function load()
	server:Init(8118)
	server:setPing(true, 2, "PING!")
	server:setHandshake("Hi! I want to play pong!")
	server:setCallback(updatedata, connect, disconnect)
	ai:init()
end

function update(dt)
	--server:checkPing(dt)
	server:update()
	love.timer.sleep(10)
end

function draw()
end

function connect(ip, port)
	server:send("Client=1", ip)
end

