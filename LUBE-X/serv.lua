love.filesystem.require("Server.lua")

lastevnt = ""
time = 0

function connCallback(ip, port)
	lastevnt = "Client " .. ip .. " connected."
end

function rcvCallback(data, ip, port)
	lastevnt = "Client " .. ip .. " sent: " .. data
end

function disconnCallback(ip, port)
	lastevnt = "Client " .. ip .. " disconnected."
end

server:Init(9090)
server:setPing(true, 3, "ping")
server:setHandshake("Hi") --useless in with this beta LUBE binary (copy-protection)
server:setCallback(rcvCallback, connCallback, disconnCallback)

function keypressed(key)
	if key == love.key_q or key == love.key_escape then
		love.system.exit()
	end
end

function update(dt)
	server:update()
	server:checkPing(dt)
	time = time + dt
	if time > 15 then
		server:send("LUBE: A smooth experience across the world")
		time = 0
	end
end

function draw()
	text = "Last event:"
	love.graphics.draw(text, center.x - fontd.width*#text/2, center.y - fontd.height/2)
	love.graphics.draw(lastevnt, center.x - fontd.width*#lastevnt/2, center.y + fontd.height/2)
end
