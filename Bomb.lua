local class = require 'middleclass'
Bomb = class('Bomb')
Bombs = {}

require 'Explosion'

function Bomb:initialize(world, x, y, properties)
    self.world = world
    self.gx,self.gy = self.world:getGravity()
    if properties == nil then properties = {} end
    self.x,self.y = x,y
    self.friction = properties.friction or 0.5
    self.radius = properties.radius or 3
    self.maxLife = properties.maxLife or self.radius * 0.6
    self.life = properties.life or self.maxLife
    self.density = properties.density or 1
    self.color = properties.color or {0.25,0.25,0.25}
    self.restitution = properties.restitution or 0.5
    self.category = properties.category or 1
    self.mask = properties.mask or 1
    self.group = properties.group or 0
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.stickTo = properties.stickTo or {}
    self.isStuck = false
    self.stuckTo = {self}
    self.explodeOn = properties.explodeOn or {}
    self.body:setFixedRotation(properties.fixedRotation or false)
    self.body:setLinearDamping(properties.linearDamping or 0)
    self.body:setAngularDamping(properties.angularDamping or 1.5)
    self:attachShape()
    self.body:setLinearVelocity((properties.vx or 0),(properties.vy or 0))
    self.body:setAngularVelocity(properties.angularVelocity or math.random(1,15))
    self.body:setUserData(self)
    self.mass = self.body:getMass()
    self.isBomb = true
    self.id = id or "Bomb"..tostring(x)..tostring(y)..tostring(math.random(1,100000))
    Bombs[self.id] = self
    Updateables[self.id] = self
    Drawables[self.id] = self
end

function Bomb:attachShape()
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

function Bomb:draw()
    love.graphics.setColor(self.color)
    love.graphics.setLineWidth(1)
    local length = self.life/self.maxLife
    local tmp = ((math.cos(length*10*math.pi)+1)/2)^2
    if self.life>self.maxLife*5/6 then tmp = 0 end
    if tmp > 0.75 then tmp = 1 else tmp = 0 end
    if self.life < 0.25 then tmp = 1 end
    local size = self.radius+tmp*(self.radius/3)
    love.graphics.setColor(tmp,tmp*(1-length)*0.5,0)
    love.graphics.circle("fill",self.body:getX(),self.body:getY(),size)
    if self.life < 0.25 then 
        love.graphics.setColor(1,0.8,0)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), (size)*(1-self.life*4)) 
    end
    love.graphics.setColor(1,1,1, 0.5)
    love.graphics.circle("fill", self.body:getX() - size/2, self.body:getY() - size/2, size/4)
    love.graphics.setColor(1,1,1)
    love.graphics.circle("line",self.body:getX(),self.body:getY(),size)
    local angle = self.body:getAngle()
    local cross = angle - math.pi/2
    local legs = {x=math.cos(angle), y=math.sin(angle)}
    local startPoint = {x=self.body:getX()+legs.x*size, y=self.body:getY()+legs.y*size}
    local endPoint = {x=self.body:getX()+legs.x*(size + length*5), y=self.body:getY()+legs.y*(size + length*5)}
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(size/2)
    love.graphics.line(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
end

function Bomb:update(dt)
    self.x,self.y = self.body:getPosition()
    self.life = self.life - dt
    if #self.stickTo > 0 or #self.explodeOn > 0 then
        local contacts = self.body:getContacts()
        for i,contact in pairs(contacts) do
            if contact:isTouching() then
                local fixtureA, fixtureB = contact:getFixtures()
                local other = fixtureA
                if fixtureA:getUserData() == self then other = fixtureB end
                local otherObject = other:getUserData()

                if #self.stickTo > 0 and not self.isStuck then
                    for j,object in pairs(self.stickTo) do
                        if object=="All" or string.find(otherObject.id, object) then
                            local otherBody = other:getBody()
                            local cx1, cy1, cx2, cy2 = contact:getPositions()
                            local joint = love.physics.newWeldJoint(self.body, otherBody, cx1, cy1, false)
                            if otherObject.isBomb then
                                table.insert(self.stuckTo, otherObject)
                                table.insert(otherObject.stuckTo, self)
                                if #otherObject.stuckTo > #self.stuckTo then
                                    self.stuckTo = otherObject.stuckTo
                                elseif #otherObject.stuckTo < #self.stuckTo then
                                    otherObject.stuckTo = self.stuckTo
                                end
                                local life = 0
                                for k,bomb in pairs(self.stuckTo) do
                                    life = life + bomb.life
                                end
                                life = life / #self.stuckTo
                                for k,bomb in pairs(self.stuckTo) do
                                    bomb.life = life
                                end
                                otherObject.isStuck = true
                            end
                            self.isStuck = true
                            break
                        end
                    end
                end
                if #self.explodeOn > 0 then

                end
            end
        end
    end
    if self.life <= 0 then
        local explosion = Explosion(self.world, self.x, self.y, {radius = self.radius*self.radius*2+25})
        self:kill()
    end
end

function Bomb:kill()
    self.body:destroy()
    Bombs[self.id] = nil
    Updateables[self.id] = nil
    Drawables[self.id] = nil
    self = nil
end