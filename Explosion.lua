local class = require 'middleclass'
Explosion = class('Explosion')

Explosions = {}

function Explosion:initialize(world, x, y, properties)
    self.world = world
    self.gx,self.gy = self.world:getGravity()
    if properties == nil then properties = {} end
    self.x,self.y = x,y
    self.friction = properties.friction or 0.5
    self.radius = properties.radius or 50
    self.impulse = properties.impulse or self.radius*750
    self.maxLife = properties.maxLife or self.radius/1000
    self.life = properties.life or self.maxLife
    self.color = properties.color or {0.25,0.25,0.25}
    self.id = id or "Explosion"..tostring(x)..tostring(y)..tostring(math.random(1,100000))
    self:explode()
    Explosions[self.id] = self
    Updateables[self.id] = self
    Drawables[self.id] = self
end

function Explosion:attachShape()
    self.fixtures = {}
    local shapes = {}
    shapes = {
        love.physics.newCircleShape(self.radius)
    }
    for k,shape in pairs(shapes) do
        self.fixtures[k] = love.physics.newFixture (self.body, shape, self.density)
        self.fixtures[k]:setFilterData(self.category, self.mask, self.group)
        self.fixtures[k]:setFriction(self.friction)
        self.fixtures[k]:setRestitution(self.restitution)
        self.fixtures[k]:setUserData(self)
    end
end

function Explosion:explode() 
    for i,b in ipairs(self.world:getBodies()) do
		if b:getType() == "dynamic" then
			local dx = (self.x - b:getX())
			local dy = (self.y - b:getY())
            local dxSq = dx*dx
            local dySq = dy*dy
			if (dxSq+dySq) <= self.radius^2+self.radius then
				local userData = b:getFixtures()[1]:getUserData()
				local d = math.sqrt(dxSq+dySq)
				if userData.isBomb then 
                    d = d * 10
                    userData.life = userData.life / 5
                end
				local angle = math.atan2(dy*-1, dx*-1)
				local fx = math.cos(angle)*self.impulse/d
				local fy = math.sin(angle)*self.impulse/d
				b:applyLinearImpulse(fx, fy)
			end
		end
	end
end

function Explosion:draw()
    love.graphics.setColor(1, 1, 1, self.life / self.maxLife)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

function Explosion:update(dt)
    self.life = self.life - dt
    if self.life <= 0 then
        self:kill()
    end
end

function Explosion:kill()
    Explosions[self.id] = nil
    Updateables[self.id] = nil
    Drawables[self.id] = nil
    self = nil
end