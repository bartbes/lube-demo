love.filesystem.require("Client.lua")
love.filesystem.require("Binary.lua")

ball = { img, x, y , dir = { x, y } }
player = {}
player[1] = { img, x, y }
player[2] = { img, x, y }
text = ""
dbg = ""
score = { 0, 0 }

function load()
	player[1].img = love.graphics.newImage("player.png")
	player[2].img = player[1].img
	ball.img = love.graphics.newImage("ball.png")
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(love.graphics.newFont(love.default_font, 20))
	love.graphics.setLineWidth(5)
	love.mouse.setVisible(false)
	
	startdir = 1
	ball.x = 400
	ball.y = 300
	ball.dir.x = startdir
	ball.dir.y = 0
	player[1].x = 20
	player[1].y = 300
	player[2].x = 780
	player[2].y = 300
	pspeed = 150
	bspeed = 250
	totaltimer = 60
	finished = false
	pausetimer = 1
	paused = false
	menu = true
	gspeed = 2
	suspended = false
	color = false
	
	if love.joystick.getNumJoysticks() > 0 then
		joystick = true
		dialog("Who uses the joystick " .. love.joystick.getName(0) .. "?", "Player 1", "Player 2", function (n) joystickd.user = n end)
		joystickd = {}
		joystickd.user = 1
		joystickd.used = false
		joystickd.handle = love.joystick.open(0)
	end
	client:Init()
	client:setPing(true, 2, "PING!")
	client:setHandshake("Hi! I want to play pong!")
	client:setCallback(updatedata)
	updatetimer = 0
end

function update(dt)
	updatetimer = updatetimer + dt
	if updatetimer < 0.02 then return end
	if joystick and not joystickd.used and joystickd.user ~= 3 then joystickd.used = true end
	if not menu then
		if suspended then
			return
		end
		if not finished then
			totaltimer = totaltimer - dt
			if totaltimer <= 0 then
				if score[1] == score[2] then
					text = "Winner: None"
				elseif score[1] > score[2] then
					text = "Winner: Player 1"
				else
					text = "Winner: Player 2"
				end
				finished = true
				totaltimer = 10
			end
		else
			totaltimer = totaltimer - dt
			if totaltimer <= 0 then
				client:disconnect()
				love.system.restart()
			end
			return
		end
		if paused then
			pausetimer = pausetimer - dt
			if pausetimer <= 0 then
				paused = false
				pausetimer = 1
				text = ""
				ball.x = 400
				ball.y = 300
				ball.dir.x = startdir
				ball.dir.y = 0
				bspeed = 250
			else
				return
			end
		end
		if love.keyboard.isDown(love.key_w) then
			player[1].y = player[1].y - (pspeed * dt * gspeed);
		end
		if love.keyboard.isDown(love.key_s) then
			player[1].y = player[1].y + (pspeed * dt * gspeed);
		end
		if love.keyboard.isDown(love.key_up) then
			player[2].y = player[2].y - (pspeed * dt * gspeed);
		end
		if love.keyboard.isDown(love.key_down) then
			player[2].y = player[2].y + (pspeed * dt * gspeed);
		end
		if player[2].targety then
			local ydiff = player[2].targety - player[2].y
			local maxmove = pspeed * dt * gspeed
			if math.abs(ydiff) <= maxmove then
				player[2].y = player[2].targety
			else
				player[2].y = player[2].y + maxmove * ydiff / math.abs(ydiff)
			end
		end
		if joystick and joystickd.used then
			local axis = love.joystick.getAxis(0, 1)
			if axis > 0 then
				player[joystickd.user].y = player[joystickd.user].y + (pspeed * dt * gspeed * axis)
			elseif axis < 0 then
				player[joystickd.user].y = player[joystickd.user].y + (pspeed * dt * gspeed * axis)
			end
		end
		if player[1].y < 0 then
			player[1].y = 0
		elseif player[1].y > 600 then
			player[1].y = 600
		end
		if player[2].y < 0 then
			player[2].y = 0
		elseif player[2].y > 600 then
			player[2].y = 600
		end
		ball.x = ball.x + (ball.dir.x * bspeed * dt * gspeed)
		ball.y = ball.y + (ball.dir.y * bspeed * dt * gspeed)
		if ball.x <= -15 then
			bspeed = 0
			text = "Player 2 scored!"
			paused = true
			score[2] = score[2] + 1
			startdir = -1
		elseif ball.x >= 815 then
			bspeed = 0
			text = "Player 1 scored!"
			paused = true
			score[1] = score[1] + 1
			startdir = 1
		elseif ball.y <= 15 then
			ball.dir.y = -ball.dir.y
		elseif ball.y >= 585 then
			ball.dir.y = -ball.dir.y
		end
		if ball.x <= player[1].x + 25 and ball.x >= player[1].x and ball.y <= player[1].y + 60 and ball.y >= player[1].y - 60 then
			ball.dir.x = -ball.dir.x
			ball.dir.y = ball.dir.y + (ball.y - player[1].y) / 60
		elseif ball.x >= player[2].x - 25 and ball.x <= player[2].x and ball.y >= player[2].y - 60 and ball.y <= player[2].y + 60 then
			ball.dir.x = -ball.dir.x
			ball.dir.y = ball.dir.y + (ball.y - player[2].y) / 60
		end
		senddata()
		client:doPing(dt)
		client:update()
		love.timer.sleep(10)
	end
	updatetimer = updatetimer - 0.02
end

function keypressed(key)
	if key == love.key_return and (love.keyboard.isDown(love.key_lalt) or love.keyboard.isDown(love.key_ralt)) then
		love.graphics.toggleFullscreen()
		suspended = true
		text = "PAUSED"
	end
	if key == love.key_p then
		suspended = not suspended
		if suspended then
			text = "PAUSED"
		else
			text = ""
		end
	end
	if key == love.key_r and love.keyboard.isDown(love.key_rshift) then
		client:disconnect()
		love.system.restart()
	end
	if key == love.key_p and love.keyboard.isDown(love.key_lalt) then
		color = not color
		if color then
			love.graphics.setColorMode(love.color_modulate)
			love.graphics.setBackgroundColor(0, 100, 0)
		else
			love.graphics.setColorMode(love.color_normal)
			love.graphics.setBackgroundColor(0, 0, 0)
		end
	end
	if menu then
		if key == love.key_left then
			gspeed = gspeed - 1
		elseif key == love.key_right then
			gspeed = gspeed + 1
		end

		if gspeed < 1 then
			gspeed = 1
		elseif gspeed > 3 then
			gspeed = 3
		end
	end
end

function keyreleased(key)
	if key == love.key_return and not (love.keyboard.isDown(love.key_lalt) or love.keyboard.isDown(love.key_ralt)) then
		menu = not menu
		if not menu then
			client:connect("83.226.210.4", 8118)
		end
	end
	if key == love.key_q or key == love.key_escape then
		if joystick and love.joystick.isOpen(0) then
			love.joystick.close(0)
		end
		client:disconnect()
		love.system.exit()
	end
end

function dialogkeypressed(key)
	if key == love.key_1 then
		dialogd.resf(1)
	elseif key == love.key_2 then
		dialogd.resf(2)
	elseif key == love.key_3 then
		dialogd.resf(3)
	else
		return
	end
	dbg = "dialog closed"
	dialogd.d = false
	love.mouse.setVisible(dialogd.mvis)
	mousepressed = dialogd.oldmpressed
	mousereleased = dialogd.oldmreleased
	keypressed = dialogd.oldkpressed
	keyreleased = dialogd.oldkreleased
	draw = dialogd.olddraw
end

function dialog(q, a1, a2, resf)
	if type(dialogd) ~= "table" then
		dialogd = {}
	end
	dialogd.q = q
	dialogd.a1 = "1 " .. a1
	dialogd.a2 = "2 " .. a2
	dialogd.a3 = "3 Cancel"
	dialogd.resf = resf
	dialogd.mvis = love.mouse.isVisible()
	dialogd.oldmpressed = mousepressed
	dialogd.oldmreleased = mousereleased
	dialogd.oldkpressed = keypressed
	dialogd.oldkreleased = keyreleased
	dialogd.olddraw = draw
	mousepressed = function(x,y,but) end
	mousereleased = function(x,y,but) end
	keypressed = dialogkeypressed
	keyreleased = function(key) end
	draw = drawdialog
	love.mouse.setVisible(true)
	dialogd.d = true
	dbg = "dialog opened"
end

function drawdialog()
	local f = love.graphics.getFont()
	local w = f:getWidth(dialogd.q)
	local h = f:getHeight()
	love.graphics.draw(dialogd.q, love.graphics.getWidth()/2-w/2, love.graphics.getHeight()/2-h/2-h)
	w = f:getWidth(dialogd.a1)
	love.graphics.draw(dialogd.a1, love.graphics.getWidth()/2-w/2, love.graphics.getHeight()/2-h/2)
	w = f:getWidth(dialogd.a2)
	love.graphics.draw(dialogd.a2, love.graphics.getWidth()/2-w/2, love.graphics.getHeight()/2-h/2+h)
	w = f:getWidth(dialogd.a3)
	love.graphics.draw(dialogd.a3, love.graphics.getWidth()/2-w/2, love.graphics.getHeight()/2-h/2+2*h)
	if dbgon then love.graphics.drawf(dbg, 500, 500, 100, love.align_center) end
end

function draw()
	if not menu and not holding then
		love.graphics.setColor(255, 255, 255, 100)
		love.graphics.line(400, 0, 400, 600)
		love.graphics.setColor(255, 255, 0)
		love.graphics.draw(ball.img, ball.x, ball.y, 0, 0.25)
		love.graphics.setColor(255, 0, 0)
		love.graphics.draw(player[1].img, player[1].x, player[1].y, 90)
		love.graphics.setColor(0, 0, 255)
		love.graphics.draw(player[2].img, player[2].x, player[2].y, 90)
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(math.abs(math.ceil(totaltimer)), 300, 30)
		love.graphics.draw(score[1] .. " - " .. score[2], 500, 30)
		love.graphics.drawf(text, 350, 300, 100, love.align_center)
	elseif holding then
		love.graphics.draw("Waiting for opponent...", 20, 20)
	else
		love.graphics.draw("Speed: " .. gspeed, 350, 300)
		love.graphics.draw("Press Enter to start/continue.", 250, 320)
		love.graphics.draw("Press Q/Escape to quit", 290, 340)
	end
	if dbgon then love.graphics.drawf(dbg, 500, 500, 100, love.align_center) end
end

function draw_connectionrejected()
	love.graphics.draw("Connection rejected by server, server might be full", 20, 20)
end

function senddata()
	if not playing then return end
	local t = {}
	t.bx = ball.x
	t.by = ball.y
	t.bdx = ball.dir.x
	t.bdy = ball.dir.y
	t.px = player[netplayer].x
	t.py = player[netplayer].y
	t.opx = player[localplayer].x
	t.opy = player[localplayer].y
	t.bspeed = bspeed --???
	t.gspeed = gspeed --???
	t.pspeed = pspeed
	t.miny = 0
	t.maxy = 600
	t.padh = 100
	t.padw = 25
	client:send(bin:pack(t))
end

function updatedata(data)
	local clientstatus = data:gfind("Client=(.*)")()
	if clientstatus then
		if clientstatus == "Rejected" then
			draw = draw_connectionrejected
		elseif clientstatus == "InHold" then
			holding = true
		else
			localplayer = tonumber(clientstatus)
			if not localplayer then return end
			playing = true
			holding = false
			if localplayer == 1 then netplayer = 2
			else netplayer = 1
			end
			print("Localplayer = " .. localplayer)
		end
	else
		local env = bin:unpack(data)
		--player[netplayer].x = tonumber(env.px)
		player[netplayer].y = tonumber(env.opy)
		ball.x = env.bx
		ball.y = env.by
		ball.dir.x = env.bdx
		ball.dir.y = env.bdy
	end
end

