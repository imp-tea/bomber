local class = require 'middleclass'
Entity = class('Entity')
require 'util'

Entities = {}

function Entity:initialize(world, x, y, properties)
    self.world = world
    self.gx,self.gy = self.world:getGravity()
    if properties == nil then properties = {} end
    self.x,self.y = x,y
    self.hasGravity = properties.hasGravity or true
    self.friction = properties.friction or 0.2
    self.shape = properties.shape or "circle"
    self.radius = properties.radius or 5
    self.height = properties.height or 40
    self.width = properties.width or 20
    self.density = properties.density or 1
    self.headSize = properties.headSize or 1
    self.color = properties.color or {1,1,1,1}
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
    self.body:setUserData(self)
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
        self.fixtures[k]:setUserData(self)
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
    self.x,self.y = self.body:getPosition()
end
