

g_console = {}

love.filesystem.require("IRC.lua")

g_printText = "Press Tab to enjoy the wonders of IRC\n\nTo change nick: /nick <nickname>\nTo quit: /quit\nPrivate message: @<user> <message>"

-- console keys:
-- Page up/down: scroll the output a bit
-- Up/Down arrows: input history (pressing down on the first item will clear the input)

function load()
	-- New console, please
	g_console = IRC:new()
	
	love.graphics.setCaption("LUBE-IRC")
	curFont = love.graphics.newFont(love.default_font, 12)
	love.graphics.setFont(curFont)
	
	-- Console:init() sets the console width (to the screen width) and 
	--  stores the font height, so be sure to call this after you've set up
	--  your window and font
	g_console:init()
	
	-- Print some text
end

function keypressed(key)
	
	-- If you don't want the keys to get processed by your game when the console's down
	--  (at least in keypressed(), not so much love.keyboard.isDown()..) then you can 
	--  check if Console:keypressed() returns true (it returns false when the console
	--  is hidden)
	if g_console:keypressed(key) then
		return
	end
	
	-- Using key #96 (the tilde (~) key) as an example
	-- If you use something else, best to set Console.toggleKey to the new key code so
	--  that Console:keypressed() won't process it
	if key == g_console.toggleKey then
		g_console:toggle() -- Or if you'd like, g_console:display(true/false)
	end
	
	
end

function update(dt)

	-- Make sure you update the console
	g_console:update(dt)
	love.timer.sleep(10)
end

function draw()

	love.graphics.draw(g_printText, 300, 300)
	
	-- You'll probably want to draw the console after everything else
	g_console:draw()
	
end

