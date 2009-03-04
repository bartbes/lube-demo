love.filesystem.require("Client.lua")

function rcvCallback(data)
	text = "Received: " .. data
end

client:Init()
client:setPing(true, 3, "ping")
client:setHandshake("Hi") --useless in with this beta LUBE binary (copy-protection)
if client:connect("localhost", 9090, true) == nil then text = "Ready"
else error("Couldn't connect") end
client:setCallback(rcvCallback)
time = 0

function keypressed(key)
	if key == love.key_q or key == love.key_escape then
		love.system.exit()
	end
end

function update(dt)
	client:doPing(dt)
	client:update()
	time = time + dt
	if time > 5 then
		client:send("LUBE: A smooth experience across the world")
		time = 0
	end
end

function draw()
	love.graphics.draw(text, center.x - fontd.width*#text/2, center.y - fontd.height/2)
end

