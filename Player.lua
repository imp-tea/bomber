local class = require 'middleclass'
require 'Entity'

Player = class('Player', Entity)

function Player:initialize(world, x, y, properties)
    if properties == nil then properties = {} end
    Entity.initialize(self, world, x, y, properties)
    self.jumpSpeed = properties.jumpSpeed or math.sqrt(2.5*self.height*self.gy)
    self.ungroundedMultiplier = properties.ungroundedMultiplier or 1
    self.canJump = false
    self.body:setUserData(self)
    self.moveForce = properties.moveForce or self.body:getMass()*1000
end

function Player:jump(override)
    if override == true or self:isGrounded() then
        local vx,vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, self.jumpSpeed*-1)
    end
end

function Player:update(dt)
    if love.keyboard.isDown("d") then
        self:move('R')
    elseif love.keyboard.isDown("a") then
        self:move('L')
    end
    if love.keyboard.isDown("w") then self:jump() end
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
    if self:isGrounded() == false then
        fx = fx*self.ungroundedMultiplier
        fy = fy*self.ungroundedMultiplier
        self.body:applyForce(fx,fy,cmx,cmy)
    else
        self.body:applyForce(fx,fy,cmx,cmy)
    end
end