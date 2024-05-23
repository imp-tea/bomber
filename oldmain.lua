
function love.load() -- Bombin Beverly
	width = 600
	height = 800
	window = love.window.setMode(width,height)
	love.graphics.setBackgroundColor(0.8,0.8,1)

	math.randomseed(os.time())

	world = love.physics.newWorld(0,1000,true)
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)

	player = {}
	terrain = {}
	bullets = {}

	player.width = 20
	player.height = 32
	player.acceleration = 1000
	player.airAcceleration = 500
	player.maxSpeed = 300
	player.jumpSpeed = -400
	player.canJump = false
	player.charging = false
	player.charge = 0
	player.baseSize = 4
	player.maxCharge = 15

	player.body = love.physics.newBody(world, width/2, height-300, "dynamic")
	player.body:setFixedRotation(true)
	player.body:setLinearDamping(0.05)
	player.body:setMass(2)
	attachPillbox(player.body,player.width,player.height,1,1,-1,"player",1,0)--(body,w,h,category,mask,group,userData,friction,restitution)
	player.fixtures = player.body:getFixtures()
	player.anim = {}
	player.anim.idle = {0.3, love.graphics.newImage('anim/idle1.png'),love.graphics.newImage('anim/idle2.png'), love.graphics.newImage('anim/idle1.png'),love.graphics.newImage('anim/idle2.png')}
	player.anim.run = {0.1, love.graphics.newImage('anim/run1.png'),love.graphics.newImage('anim/run2.png'),love.graphics.newImage('anim/run3.png'),love.graphics.newImage('anim/run4.png')}
	player.anim.jump = {1, love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png')}
	player.anim.facing = 1 --One is right, Negative one is left.
	player.anim.loop = player.anim.idle  --idle, run, or jump
	player.anim.frame = 2 --current frame in animation loop (+1 because of the first number in the animation sequence)
	animTimer = 0

	--Containers for the physics of the terrain objects: bodies, shapes, fixtures, and joints.
	terrain.b = {}
	terrain.s = {}
	terrain.f = {}
	terrain.j = {}

	--Custom methods for adding terrain pieces
	addRectangle(width/2, height-20, width, 40, true)
	addRectangle(40, height-40, 80, 80, true)
	addRectangle(width-40, height-40, 80, 80, true)
	addTriangle(80, height-80, 80, height-40, 160, height-40, true)
	addTriangle(width-160, height-40,width-80, height-40, width-80,height-80,true)
	addRectangle(-20, height/2, 40, height, false)
	addRectangle(width+20, height/2, 40, height, false)
	addRectangle(width/2, height-120, width-320, 20, true)

	explosions = {}
end

function love.update(dt)
	local vx, vy = player.body:getLinearVelocity()
	local grounded = checkGrounded(player.body)

	if grounded then
		if math.abs(vy) < 1 then
			player.canJump = true
			if math.abs(vx) < 100 then
				player.anim.loop = player.anim.idle
			end
		end
	end

	if grounded==false then
		player.canJump = false
		player.anim.loop = player.anim.jump
	end

	if math.abs(vx) < player.maxSpeed then
		if grounded then
			if love.keyboard.isDown('d') then
				player.body:applyForce(player.acceleration,0)
				if player.canJump then
					player.anim.loop = player.anim.run
				end
			elseif love.keyboard.isDown('a') then
				player.body:applyForce(player.acceleration*-1,0)
				if player.canJump then
					player.anim.loop = player.anim.run
				end
			end
		else
			if love.keyboard.isDown('d') then
				player.body:applyForce(player.airAcceleration, 0)
			elseif love.keyboard.isDown('a') then
				player.body:applyForce(player.airAcceleration*-1, 0) -- get rekted
			end
		end
	end

	if player.charging then 
		player.charge = player.charge + dt*5 
		if player.charge > player.maxCharge then player.charge = player.maxCharge end
	end
	updatePlayerAnimation(dt)
	updateBullets(dt)
	world:update(dt)
end
 
function love.draw()
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1,1,1)
	love.graphics.draw(player.anim.loop[player.anim.frame], player.body:getX(), player.body:getY(), 0, player.anim.facing, 1, 16, 16, 0, 0)
	if player.charging then
		love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
		love.graphics.circle("fill", player.body:getX()+(player.width/2 + player.charge)*player.anim.facing, player.body:getY(), player.charge)
	end
	
	for i,b in ipairs(bullets) do
		love.graphics.setLineWidth(1)
		local length = b.life/b.maxLife
		local tmp = ((math.cos(length*10*math.pi)+1)/2)^2
		tmp = tmp*tmp
		if b.life>b.maxLife*5/6 then tmp = 0 end
		if tmp > 0.75 then tmp = 1 else tmp = 0 end
		if b.life < 0.25 then tmp = 1 end
		local size = b.r+tmp
		love.graphics.setColor(tmp,tmp*(1-length)*0.5,0)
		love.graphics.circle("fill",b.body:getX(),b.body:getY(),size)
		if b.life < 0.25 then 
			love.graphics.setColor(1,0.8,0)
			love.graphics.circle("fill", b.body:getX(), b.body:getY(), (size)*(1-b.life*4)) 
		end
		love.graphics.setColor(1,1,1, 0.5)
		love.graphics.circle("fill", b.body:getX() - size/2, b.body:getY() - size/2, size/4)
		love.graphics.setColor(0,0,0)
		love.graphics.circle("line",b.body:getX(),b.body:getY(),size)
		local angle = b.body:getAngle()
		local cross = angle - math.pi/2
		local legs = {x=math.cos(angle), y=math.sin(angle)}
		local startPoint = {x=b.body:getX()+legs.x*size, y=b.body:getY()+legs.y*size}
		local endPoint = {x=b.body:getX()+legs.x*(size + length*5), y=b.body:getY()+legs.y*(size + length*5)}
		love.graphics.setColor(0,0,0)
		love.graphics.setLineWidth(size/2)
		love.graphics.line(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
	end

	love.graphics.setColor(0.5,0.5,0.2)
	for i = 1,table.getn(terrain.s),1 do
		if terrain.s[i]:getType() == 'polygon' then
			love.graphics.polygon("fill", terrain.b[i]:getWorldPoints(terrain.s[i]:getPoints()))
		elseif terrain.s[i]:getType() == 'circle' then
			love.graphics.circle("fill",terrain.b[i]:getX(),terrain.b[i]:getY(),terrain.s[i]:getRadius())
		end
	end
	for i = #explosions, 1, -1 do
		love.graphics.setColor(1, 1, 1, 0.5)
		local explosion = explosions[i]
		local size = explosion[3]*20
		love.graphics.circle("fill", explosion[1], explosion[2], size)
		explosion[3] = explosion[3]-1
		if explosion[3] == 0 then
			table.remove(explosions, i)
		end
	end
end

function love.keypressed(key)
	if key == "w" or key == "space" then
		local vx, vy = player.body:getLinearVelocity()
		if checkGrounded(player.body) and player.canJump then
			player.anim.loop = player.anim.jump
			player.body:setLinearVelocity(vx, player.jumpSpeed)
			player.canJump = false
		end
	end
	if key == "d" then
		player.anim.facing = 1
	end
	if key == "a" then
		player.anim.facing = -1
	end
end

function love.mousepressed(x,y,button)
	if button == 1 or button == 2 then
		player.charge = player.baseSize --butts
		player.charging = true
	end
end

function love.mousereleased(x, y, button)
	if player.charging then
		spawnBullet(player.body:getX()+(player.width/2 + player.charge)*player.anim.facing, player.body:getY(), 1000, player.anim.facing, player.charge, player.charge*0.6, button==2)
		player.charging = false
		player.charge = player.baseSize
	end
end

function updatePlayerAnimation(t)
	animTimer = animTimer + t
	local n = table.getn(player.anim.loop) - 1
	if animTimer > player.anim.loop[1] then
		animTimer = 0
		if player.anim.frame < n then
			player.anim.frame = player.anim.frame + 1
		else
			player.anim.frame = 2
		end
	end
end

function checkGrounded(b)
	local contacts = b:getContacts()
	for key,value in pairs(contacts) do
		local fixA, fixB = value:getFixtures()
		if fixA:getUserData() == "jumpable" or fixB:getUserData() == "jumpable" then
			return true
		end
	end
end

function spawnBullet(startx,starty,speed,direction,size,lifetime,sticky)
	local bd = love.physics.newBody(world,startx,starty,"dynamic")
	local s = love.physics.newCircleShape(size)
	table.insert(bullets,
	{  
		r = size,
		life=lifetime,
		maxLife = lifetime,
		body=bd,
		shape=s,
		fixture=love.physics.newFixture(bd, s, 0.35),
		stick = sticky or false,
		stuck = false
	})
	local b = bullets[table.getn(bullets)]
	b.fixture:setFriction(1)
	b.fixture:setRestitution(0.5)
	b.body:setLinearDamping(0)
	b.fixture:setUserData("bullet")
	b.fixture:setFilterData(1,1,0)
	b.body:setLinearVelocity(speed*direction,0)
	b.body:setAngularVelocity((math.random()-math.random())*20)

end

function updateBullets(dt) -- yeeter
	for i,b in ipairs(bullets) do
		b.life = b.life - dt
		if b.stick and not b.stuck then
			local contacts = b.body:getContacts();
			local touching = false
			for i,contact in ipairs(contacts) do
				if contact:isTouching() then
					local fixA, fixB = contact:getFixtures()
					if (fixA:getUserData() ~= "player" and fixB:getUserData() ~= "player") or b.life < (b.maxLife-0.05) then
						touching = true -- gay
						break
					end
				end
			end
			if touching then b.stuck = true end
		end
		if b.stuck then
			b.body:setType("static")
			b.fixture:setUserData("jumpable")
		end
		if b.life <= 0 then
			explode(b.body:getX(), b.body:getY(), 1500 * b.maxLife)
			table.insert(explosions, {b.body:getX(), b.body:getY(), 3})
			b.fixture:destroy()
			b.body:destroy()
			table.remove(bullets,i)
		end
	end
end

function addRectangle(x,y,w,h,jumpable)
	local n = table.getn(terrain.b) + 1
	terrain.b[n] = love.physics.newBody(world,x,y,"static") -- your mom
	terrain.s[n] = love.physics.newRectangleShape(w,h)
	terrain.f[n] = love.physics.newFixture(terrain.b[n],terrain.s[n],1)
	terrain.f[n]:setFilterData(1, 1, 0)
	if jumpable then
		terrain.f[n]:setUserData("jumpable")
	end
end

function addTriangle (x1,y1,x2,y2,x3,y3,jumpable)
	local n = table.getn(terrain.b) + 1
	terrain.b[n] = love.physics.newBody(world,x,y,"static")
	local npoints = {x1,y1,x2,y2,x3,y3}
	terrain.s[n] = love.physics.newPolygonShape(npoints)
	terrain.f[n] = love.physics.newFixture(terrain.b[n],terrain.s[n],1)
	terrain.f[n]:setFilterData(1, 1, 0)
	if jumpable then
		terrain.f[n]:setUserData("jumpable")
	end
end

function attachPillbox (body,w,h,category,mask,group,userData,friction,restitution)
	local top = love.physics.newCircleShape(0, (h-w)/-2.1, w/2)
	local mid = love.physics.newRectangleShape(w,h-w)
	local bottom = love.physics.newCircleShape(0, (h-w)/2.1, w/2)
	--
	local topFixture = love.physics.newFixture (body, top, 0.3)
	topFixture:setFilterData(category, mask, group)
	topFixture:setFriction(0)
	topFixture:setRestitution(restitution)
	topFixture:setUserData(userData)
	--
	local midFixture = love.physics.newFixture (body, mid, 0.3)
	midFixture:setFilterData(category, mask, group)
	midFixture:setFriction(0)
	midFixture:setRestitution(restitution)
	midFixture:setUserData(userData)
	--
	local bottomFixture = love.physics.newFixture (body, bottom, 0.3) --butts
	bottomFixture:setFilterData(category, mask, group)
	bottomFixture:setFriction(friction)
	bottomFixture:setRestitution(restitution)
	bottomFixture:setUserData(userData)
end

function explode(x, y, impulse)
	for i,b in ipairs(world:getBodies()) do
		if b:getType() == "dynamic" then
			local dx = (x - b:getX())
			local dy = (y - b:getY())
			if (math.abs(dx) + math.abs(dy)) < impulse/20 then
				local userData = b:getFixtures()[1]:getUserData()
				local dSq = math.sqrt(dx*dx+dy*dy)
				if userData=="bullet" then dSq = dSq * 15 end
				local angle = math.atan2(dy*-1, dx*-1)
				local fx = math.cos(angle)*impulse/dSq
				local fy = math.sin(angle)*impulse/dSq
				b:applyLinearImpulse(fx, fy)
			end
		end
	end
end