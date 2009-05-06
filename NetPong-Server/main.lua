love.filesystem.require("Server.lua")
love.filesystem.require("Binary.lua")

function load()
	server:Init(8118)
	server:setPing(true, 2, "PING!")
	server:setHandshake("Hi! I want to play pong!")
	server:setCallback(updatedata, connect, disconnect)
	gamestarted = false
	Players = {}
	numclients = 0
end

function update(dt)
	--server:checkPing(dt)
	server:update()
	love.timer.sleep(10)
end

function draw()
end

function connect(ip, port)
	numclients = numclients + 1
	if numclients > 2 then
		server:send("Client=Rejected", ip)
	elseif numclients == 2 and not gamestarted then
		local i = 0
		for ip, port in pairs(Clients) do
			i = i + 1
			server:send("Client=" .. i, ip)
			table.insert(Players, { ip = ip, port = port })
		end
		gamestarted = true
	else
		server:send("Client=InHold", ip)
	end
end

function disconnect(ip, port)
	numclients = numclients - 1
	if Players[1] and Players[1].ip == ip and Players[1].port == port then
		table.remove(Players, 1)
		gamestarted = false
		server:send("Game=Stopped")
	elseif Players[2] and Players[2].ip == ip and Players[2].port == port then
		table.remove(Players, 2)
		gamestarted = false
		server:send("Game=Stopped")
	end
end

function updatedata(data, ip, port)
	if Players[1] and Players[1].ip == ip and Players[2] then
		server:send(data, Players[2].ip)
	elseif Players[2] and Players[2].ip == ip and Players[1] then
		server:send(data, Players[1].ip)
	end	
end

