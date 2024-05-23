local class = require 'middleclass'
Entity = class('Entity')
require 'util'

Entities = {}

function Entity:initialize(world, x, y, properties)
    self.world = world
    local gx,gy = self.world:getGravity()
    if properties == nil then properties = {} end
    self.x,self.y = x,y
    self.hasGravity = properties.hasGravity or true
    self.friction = properties.friction or 0.2
    self.shape = properties.shape or "pill"
    self.headSize = properties.headSize or 1
    self.radius = properties.radius or 5
    self.height = properties.height or 40
    self.width = properties.width or 20
    self.density = properties.density or 1
    self.color = properties.color or {1,1,1,1}
    self.jumpSpeed = properties.jumpSpeed or math.sqrt(2.5*self.height*gy)
    self.bobble = properties.bobble or false
    self.ungroundedMultiplier = properties.ungroundedMultiplier or 1
    self.restitution = properties.restitution or 0
    self.category = properties.category or 1
    self.mask = properties.mask or 1
    self.group = properties.group or 0
    self.points = properties.points or nil
    self.body = love.physics.newBody(world, x, y, "dynamic")
    self.body:setFixedRotation(properties.fixedRotation or false)
    self.body:setLinearDamping(properties.linearDamping or 0)
    self.body:setAngularDamping(properties.angularDamping or 0)
    self:attachShape()
    self.body:setLinearVelocity((properties.vx or 0),(properties.vy or 0))
    self.body:setUserData(properties.userData or {jumpable=true, carryable = true})
    self.canJump = false
    self.moveForce = properties.moveForce or self.body:getMass()*1000
    self.mass = self.body:getMass()

    self.id = id or "Entity"..tostring(x)..tostring(y)..tostring(self.shape)..tostring(math.random(1,1000))
    Entities[self.id] = self

end

function Entity:attachShape()
    self.fixtures = {}
    local shapes = {}
    if self.shape == "pill" then
        if self.height > self.width then
            shapes["head"] = love.physics.newCircleShape(0, (self.height-self.width)/-2, self.width*self.headSize/2)
            shapes["foot"] = love.physics.newCircleShape(0, (self.height-self.width)/2, self.width/2)
            if self.headSize == 1 then
                shapes["body"] = love.physics.newRectangleShape(self.width,self.height-self.width)
            else
                local headX,headY = shapes["head"]:getPoint()
                local headRadius = shapes["head"]:getRadius()
                local footX,footY = shapes["foot"]:getPoint()
                local footRadius = shapes["foot"]:getRadius()
                local bodyPoints = {
                    headX - headRadius, headY,
                    headX + headRadius, headY,
                    footX - footRadius, footY,
                    footX + footRadius, footY
                }
                shapes["body"] = love.physics.newPolygonShape(bodyPoints)
            end

        else
            self.radius = self.width/2
            self.shape = "circle"
            goto not_a_pill
        end
    end
    ::not_a_pill::
    if self.shape == "circle" then
        shapes = {
            love.physics.newCircleShape(self.radius)
        }
    end
    if self.shape == "rectangle" then
        shapes = {
            love.physics.newRectangleShape(self.width, self.height)
        }
    end
    if self.shape == 'polygon' then
		shapes = {
            love.physics.newPolygonShape(self.points)
        }
	end
    for k,shape in pairs(shapes) do
        self.fixtures[k] = love.physics.newFixture (self.body, shape, self.density)
        self.fixtures[k]:setFilterData(self.category, self.mask, self.group)
        self.fixtures[k]:setFriction(self.friction)
        self.fixtures[k]:setRestitution(self.restitution)
        self.fixtures[k]:setUserData(self.userData)
    end
end

function Entity:draw()
    love.graphics.setColor(self.color)
    love.graphics.setColor(1,1,1,1)
    for k,fixture in pairs(self.fixtures) do
        local shape = fixture:getShape()
        if shape:getType() == "circle" then
            local x,y = self.body:getWorldPoints(shape:getPoint())
            love.graphics.circle("line",x,y,shape:getRadius())
        elseif shape:getType() == "polygon" then
            love.graphics.polygon("line", self.body:getWorldPoints(shape:getPoints()))

        end
    end
    love.graphics.setColor(self.color)
    for k,fixture in pairs(self.fixtures) do
        local shape = fixture:getShape()
        if shape:getType() == "circle" then
            local x,y = self.body:getWorldPoints(shape:getPoint())
            love.graphics.circle("fill",x,y,shape:getRadius())
        elseif shape:getType() == "polygon" then
            love.graphics.polygon("fill", self.body:getWorldPoints(shape:getPoints()))
        end
    end
    if self.shape == 'pill' then
        local head = self.fixtures["head"]:getShape()
        local hx,hy = self.body:getWorldPoint(head:getPoint())
        love.graphics.setColor(0, 0, 0, 1)
        util.drawFace(hx,hy,self.width*self.headSize/2)
    end
    local cmx,cmy = self.body:getWorldCenter()
    love.graphics.setColor(1,1,1,1)
    love.graphics.circle("fill",cmx,cmy,3)
end

function Entity:jump(override)
    if override == true or self:isGrounded() then
        local vx,vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, self.jumpSpeed*-1)
    end
end

function Entity:isGrounded()
    local contacts = self.body:getContacts()
    for key,contact in pairs(contacts) do
        local fixA, fixB = contact:getFixtures()
        local bodyA, bodyB = fixA:getBody(),fixB:getBody()
        local otherBody = bodyA
        local nx, ny = contact:getNormal()

        if bodyA == self.body then
            otherBody = bodyB
            ny = ny * -1
        end

        if contact:isTouching() and ny<-0.1 then
            local userData = otherBody:getUserData()
            if (userData.jumpable) then
                return true
            end
        end
    end
    return false
end

function Entity:update()
    local vx, vy = self.body:getLinearVelocity()
    self.x,self.y = self.body:getPosition()
    --self.body:setAngularVelocity(self.body:getAngularVelocity() * self.angularDamping)

    if self.bobble then
        local bob = false
        local contacts = self.body:getContacts()
        for key,contact in pairs(contacts) do
            if contact:isTouching() then
                bob = true
                break
            end
        end
        if bob then
            local head = self.fixtures["head"]:getShape()
            local hx,hy = self.body:getWorldPoint(head:getPoint())
            local tail = self.fixtures["foot"]:getShape()
            local tx,ty = self.body:getWorldPoint(tail:getPoint())
            self.body:applyForce(0,self.mass*-1000,hx,hy)
            self.body:applyForce(0,self.mass*1000,tx,ty)
        end
    end
    --self.grounded = self:isGrounded()
end

function Entity:move(direction)
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
        self.body:applyTorque(fx*10)
    else
        self.body:applyForce(fx,fy,cmx,cmy+3)
    end
end
