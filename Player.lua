local class = require 'middleclass'
require 'Entity'

Player = class('Player', Entity)

function Player:initialize(world, x, y, properties)
    if properties == nil then properties = {} end
    Entity.initialize(self, world, x, y, properties)
    self.jumpSpeed = properties.jumpSpeed or math.sqrt(3*self.height*self.gy)
    self.ungroundedMultiplier = properties.ungroundedMultiplier or 1
    self.canJump = false
    self.maxSpeed = properties.maxSpeed or 750
    self.grounded = false
    self.body:setUserData(self)
    self.moveForce = properties.moveForce or self.body:getMass()*2500
    self.minimumCharge = 3
    self.maximumCharge = 15
    self.facing = 1
    self.charging = false
    self.charge = self.minimumCharge
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
    local bomb = Bomb(self.world, self.x + offsetX, self.y + offsetY, {radius = self.charge, vx = velocityX})
end