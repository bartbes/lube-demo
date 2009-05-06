require "Server"
require "Binary"
require "ai"

love = {}
love.timer = {}
function love.timer.getDelta()
	return 0.02
end

server:Init(8118)
server:setPing(true, 2, "PING!")
server:setHandshake("Hi! I want to play pong!")
server:setCallback(updatedata)
ai:init()
while true do
	server:update()
end
