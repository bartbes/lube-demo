ai = {}

function ai:init()
	self.roaming = false
	self.trgx = 0
	self.trgy = 0
end

function ai:observe(data)
	self.data = data
	return self:act()
end

function ai:act()
	local	bx = self.data.bx
	local	by = self.data.by
	local	bdx = self.data.bdx
	local	bdy = self.data.bdy
	local	px = self.data.px
	local	py = self.data.py
	local	opx = self.data.opx
	local	opy = self.data.opy
	local	miny = self.data.miny
	local	maxy = self.data.maxy
	-- Pad size
	local	padh = self.data.padh
	local	padw = self.data.padw
	
	if (px - opx) * bdx < 0 then
		-- Ball not heading towards me so let's just go to
		-- some random location for fun.
		if not self.roaming then
			self.trgx = pox
			self.trgy = math.random(miny, maxy)
			self.roaming = true
			senddata(self.data, self.trgx, self.trgy)
		end
	else
		self.roaming = false
		-- Compute where the ball will go.
		local	height = maxy - miny
		local	hitTime = math.abs((px - bx) / bdx)
		local	hity = by + hitTime * bdy
		hity = (hity - miny) % (height + height)
		if hity >= height then
			hity = height  + height - hity
		end
		hity = hity + miny
		--print("BB ", hity)
		-- Move so that the ball hits the side or less
		-- precisely. This might be undesireable. In that
		-- case, change 0.5 to something smaller.
		self.trgx = pox
		if hity < self.trgy then
			self.trgy = hity + padh * 0.4
		else
			self.trgy = hity - padh * 0.4
		end
		senddata(self.data, self.trgx, self.trgy)
	end
end

function ai:smooth(target)
	local dt = love.timer.getDelta()
	local t = {}
	t.targetx = target.targetx
	local ydiff = target.targety - env.py
	local dir = ydiff / math.abs(ydiff)
	local maxmove = env.pspeed * env.gspeed * dt * 2
	if math.abs(ydiff) <= maxmove then
		t.targety = target.targety
	else
		t.targety = env.py + maxmove * dir
	end
	return t
end

function updatedata(data)
	env = bin:unpack(data)
	if not env then print("false") return end
	
	-- Why do we need to update these?
	-- Hey, I'm in first person
 	--player[1].x = t.px
 	--player[1].y = t.py
 	--player[2].x = t.opx
 	--player[2].y = t.opy
	--...

	-- Or should the AI use the above variables?
	move = ai:observe(env)
end

function senddata(data, targetx, targety)
	if targetx then data.px = targetx end
	data.py = targety
	server:send(bin:pack(data))
end

