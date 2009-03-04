Menu = {}
Menu.filesystem = {}
Menu.graphics = {}
Menu.audio = {}
Menu.newfilesystem = {}
Menu.newgraphics = {}
Menu.newaudio = {}
Menu.selected = 1
Menu.entries = 0

function Menu.newfilesystem.newFile(filename, mode)
	return Menu.filesystem.newFile(Menu.name .. filename, mode)
end

function Menu.newfilesystem.isDirectory(dirname)
	return Menu.filesystem.isDirectory(Menu.name .. dirname)
end

function Menu.newfilesystem.isFile(filename)
	return Menu.filesystem.isFile(Menu.name .. filename)
end

function Menu.newfilesystem.mkdir(dirname)
	return Menu.filesystem.mkdir(Menu.name .. dirname)
end

function Menu.newfilesystem.remove(filename)
	return Menu.filesystem.remove(Menu.name .. filename)
end

function Menu.newfilesystem.exists(filename)
	return Menu.filesystem.exists(Menu.name .. filename)
end

function Menu.newfilesystem.read(file, bytes)
	if type(file) == "string" then
		return Menu.filesystem.read(Menu.name .. file, bytes)
	else
		return Menu.filesystem.read(file, bytes)
	end
end

function Menu.newfilesystem.write(file, data)
	if type(file) == "string" then
		return Menu.filesystem.read(Menu.name .. file, data)
	else
		return Menu.filesystem.read(file, data)
	end
end

function Menu.newfilesystem.lines(file)
	if type(file) == "string" then
		return Menu.filesystem.lines(Menu.name .. file)
	else
		return Menu.filesystem.lines(file)
	end
end

function Menu.newfilesystem.enumerate(dirname)
	return Menu.filesystem.enumerate(Menu.name .. dirname)
end

function Menu.newfilesystem.include(filename)
	return Menu.filesystem.include(Menu.name .. filename)
end

function Menu.newfilesystem.load(filename)
	return Menu.filesystem.load(Menu.name .. filename)
end

function Menu.newfilesystem.load(filename)
	return Menu.filesystem.load(Menu.name .. filename)
end

function Menu.newgraphics.newImage(filename, mode)
	if filename == love.default_logo_256 then
		return Menu.graphics.newImage(love.default_logo_256)
	end
	if mode ~= nil then
		return Menu.graphics.newImage(Menu.name .. filename, mode)
	end
	return Menu.graphics.newImage(Menu.name .. filename)
end

function Menu.newgraphics.newFont(filename, size)
	size = size or 12
	if filename == love.default_font then
		return Menu.graphics.newFont(love.default_font, size)
	end
	return Menu.graphics.newFont(Menu.name .. filename, size)
end

function Menu.newgraphics.newImageFont(filename, glyphs, spacing)
	return Menu.graphics.newImageFont(Menu.name .. filename, glyphs, spacing)
end

function Menu.newaudio.newSound(filename)
	return Menu.audio.newSound(Menu.name .. filename)
end

function Menu.newaudio.newMusic(filename)
	return Menu.audio.newMusic(Menu.name .. filename)
end

for i, v in pairs(Menu.newfilesystem) do
	Menu.filesystem[i] = love.filesystem[i]
	love.filesystem[i] = v
end
for i, v in pairs(Menu.newgraphics) do
	Menu.graphics[i] = love.graphics[i]
	love.graphics[i] = v
end
for i, v in pairs(Menu.newaudio) do
	Menu.audio[i] = love.audio[i]
	love.audio[i] = v
end

function Menu.emptycallbacks()
	local callbacks = { "load", "update", "draw", "mousepressed", "mousereleased", "keypressed", "keyreleased", "joystickpressed", "joystickreleased" }
	for i, v in ipairs(callbacks) do
		_G[v] = function() end
	end
end

function Menu.run(selected)
	local ir = 1
	local index = 0
	for i, v in pairs(Menu.list) do
		if ir == selected then index = i end
		ir = ir + 1
	end
	Menu.name = Menu.list[index] .. "/"
	Menu.emptycallbacks()
	local conf = love.filesystem.load("game.conf")
	Menu.conf = {}
	setfenv(conf, Menu.conf)
	conf()
	love.graphics.setCaption(Menu.conf.title)
	love.graphics.setMode(Menu.conf.width or 800, Menu.conf.height or 600, Menu.conf.fullscreen or false, Menu.conf.vsync or true, Menu.conf.fsaa or 0)
	love.filesystem.require("main.lua")
	load()
end

Menu.emptycallbacks()

function load()
	love.graphics.setFont(love.default_font)
	Menu.list = Menu.filesystem.enumerate("/")
	for i, v in pairs(Menu.list) do
		if not Menu.filesystem.isDirectory(v) then
			Menu.list[i] = nil
		else
			Menu.entries = Menu.entries + 1
		end
	end
end

function draw()
	love.graphics.rectangle(love.draw_line, 30, 30, 740, 400)
	local ir = 1
	for i, v in pairs(Menu.list) do
		if ir == Menu.selected then
			love.graphics.rectangle(love.draw_fill, 30, 30+20*(ir-1), 740, 20)
			love.graphics.setColor(0, 0, 0)
		end
		love.graphics.draw(v, 50, 42+20*(ir-1))
		if ir == Menu.selected then
			love.graphics.setColor(255, 255, 255)
		end
		ir = ir + 1
	end
end

function keypressed(key)
	if key == love.key_down then
		Menu.selected = Menu.selected + 1
		if Menu.selected > Menu.entries then
			Menu.selected = Menu.entries
		end
	elseif key == love.key_up then
		Menu.selected = Menu.selected - 1
		if Menu.selected < 1 then
			Menu.selected = 1
		end
	elseif key == love.key_return then
		Menu.run(Menu.selected)
	end
end

