local class = require 'middleclass'
require 'Entity'

Player = class('Player', Entity)

function Player:initialize(world, x, y, properties)
    if properties == nil then properties = {} end
    Entity.initialize(self, world, x, y, properties, false)

    self.jumpSpeed = properties.jumpSpeed or math.sqrt(3*self.height*self.gy)
    self.ungroundedMultiplier = properties.ungroundedMultiplier or 1
    self.canJump = false
    self.maxSpeed = properties.maxSpeed or 750
    self.grounded = false
    self.body:setUserData(self)
    self.moveForce = properties.moveForce or self.body:getMass()*2500

    self.minimumCharge = 3
    self.maximumCharge = 15
    self.charging = false
    self.charge = self.minimumCharge

    self.facing = 1
    self.animTimer = 0
    self.anim = properties.anim or {
        idle = {0.3, love.graphics.newImage('anim/idle1.png'),love.graphics.newImage('anim/idle2.png'), love.graphics.newImage('anim/idle1.png'),love.graphics.newImage('anim/idle2.png')},
        run = {0.1, love.graphics.newImage('anim/run1.png'),love.graphics.newImage('anim/run2.png'),love.graphics.newImage('anim/run3.png'),love.graphics.newImage('anim/run4.png')},
        jump = {1, love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png'), love.graphics.newImage('anim/jump1.png')}
    }
    self.anim.loop = self.anim.idle  --idle, run, or jump
	self.anim.frame = 2

    self.id = id or "Player"..tostring(x)..tostring(y)..tostring(self.shape)..tostring(math.random(1,1000))
    Updateables[self.id] = self
    Drawables[self.id] = self
end

function Player:jump(override)
    if override == true or self.grounded then
        self.body:setLinearVelocity(self.vx, self.jumpSpeed*-1)
    end
end

function Player:update(dt)
    self.grounded = self:isGrounded()
    self.vx, self.vy = self.body:getLinearVelocity()
    if love.keyboard.isDown("d") and self.vx < self.maxSpeed then
        self:move('R')
        self.facing = 1
    elseif love.keyboard.isDown("a") and self.vx > self.maxSpeed*-1 then
        self:move('L')
        self.facing = -1
    elseif self.grounded then
        self.body:setLinearVelocity(self.vx*0.975, self.vy)
    end
    if love.keyboard.isDown("w") then self:jump() end

    if self.charging  and self.charge <= self.maximumCharge then
        self.charge = self.charge + dt*5
        if self.charge > self.maximumCharge then self.charge = self.maximumCharge end
    end
    self.x,self.y = self.body:getPosition()
    if self.grounded then
        if math.abs(self.vx) < 100 then
            self.anim.loop = self.anim.idle
        else
            self.anim.loop = self.anim.run
        end
    else
        self.anim.loop = self.anim.jump
    end
    self:updateAnimation(dt)
end

function Player:move(direction)
    local fx = 0
    local fy = 0
    local cmx,cmy = self.body:getWorldCenter()
    local directionTable = {
        ["U"] = {0,-1},
        ["D"] = {0,1},
        ["L"]= {-1,0},
        ["R"] = {1,0},
        ["UL"] = {-0.7071,-0.7071},
        ["UR"] = {0.7071,-0.7071},
        ["DL"] = {-0.7071,0.7071},
        ["DR"] = {0.7071,0.7071}
    }
    --
    if type(direction) == "string" then
        fx = self.moveForce*directionTable[direction][1]
        fy = self.moveForce*directionTable[direction][2]
    else
        fx = self.moveForce*direction[1]
        fy = self.moveForce*direction[2]
    end
    if not self.grounded then
        fx = fx*self.ungroundedMultiplier
        fy = fy*self.ungroundedMultiplier
        self.body:applyForce(fx,fy,cmx,cmy)
    else
        self.body:applyForce(fx,fy,cmx,cmy)
    end
end

function Player:shoot()
    local offsetX = (self.width + self.charge)*self.facing
    local offsetY = -10
    local velocityX = self.facing * 1500 + self.body:getLinearVelocity()
    local bomb = Bomb:new(self.world, self.x + offsetX, self.y + offsetY, {radius = self.charge, vx = velocityX})
end

function Player:updateAnimation(dt)
    self.animTimer = self.animTimer + dt
    local n = table.getn(self.anim.loop) - 1
    if self.animTimer > self.anim.loop[1] then
        self.animTimer = 0
        if self.anim.frame < n then
            self.anim.frame = self.anim.frame + 1
        else
            self.anim.frame = 2
        end
    end
end

function Player:draw()
    love.graphics.setColor(1,1,1)
	love.graphics.draw(self.anim.loop[self.anim.frame], self.body:getX(), self.body:getY(), 0, self.facing*2, 2, 16, 16, 0, 0)
end