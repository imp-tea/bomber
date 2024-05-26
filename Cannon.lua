local class = require 'middleclass'
Cannon = class('Cannon')
Cannons = {}

require 'Bomb'

function Cannon:initialize(world, x, y, properties)
    self.world = world
    self.gx,self.gy = self.world:getGravity()
    if properties == nil then properties = {} end
    self.x,self.y = x,y
    self.color = properties.color or {1,1,1}
    
    self.radius = properties.radius or 50
    self.barrelLength = properties.barrelLength or 100
    self.barrelWidth = properties.barrelWidth or self.barrelLength/4
    self.angle = properties.angle or 0
    self.target = properties.target or nil
    self.rotationSpeed = properties.rotationSpeed or math.pi/4
    self.bombPeriod = properties.bombPeriod or 1
    self.bombTimer = properties.bombTimer or 0
    self.bombSize = properties.bombSize or 15
    self.bombSpeed = properties.bombSpeed or 1000
    self.category = properties.category or 1
    self.mask = properties.mask or 1
    self.group = properties.group or 0
    self.restitution = properties.restitution or 0
    self.friction = properties.friction or 0.2
    self.body = love.physics.newBody(world, x, y, "kinematic")
    self:attachShape()
    self.body:setAngle(self.angle)
    self.body:setUserData(self)
    self.isCannon = true
    self.id = id or "Cannon"..tostring(x)..tostring(y)..tostring(math.random(1,100000))
    Cannons[self.id] = self
    Updateables[self.id] = self
    Drawables[self.id] = self
end

function Cannon:attachShape()
    self.fixtures = {}
    local shapes = {}
    shapes = {
        love.physics.newCircleShape(self.radius),
        love.physics.newRectangleShape(self.barrelLength/2, 0, self.barrelLength, self.barrelWidth, 0),
    }
    for k,shape in pairs(shapes) do
        self.fixtures[k] = love.physics.newFixture (self.body, shape, self.density)
        self.fixtures[k]:setFilterData(self.category, self.mask, self.group)
        self.fixtures[k]:setFriction(self.friction)
        self.fixtures[k]:setRestitution(self.restitution)
        self.fixtures[k]:setUserData(self)
    end
end

function Cannon:draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
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
end

function Cannon:update(dt)
    self.bombTimer = self.bombTimer + dt
    self.angle = self.body:getAngle()
    self.x = self.body:getX()
    self.y = self.body:getY()
    local dx = math.cos(self.angle)
    local dy = math.sin(self.angle)
    local sx = self.x+dx*self.barrelLength
    local sy = self.y+dy*self.barrelLength
    local vx = self.bombSpeed*dx
    local vy = self.bombSpeed*dy
    local t = 0
    if math.abs(vx) > 0 then t = (self.target.x - sx)/vx end
    local correction = 0.5*self.gy*t*t
    if t < 0 or math.abs(correction)>1000 then correction = 0 end
    dy = (self.target.y-correction)-sy
    dx = self.target.x - sx
    local targetAngle = math.atan2(dy, dx)
    self.body:setAngularVelocity(self.rotationSpeed * getDirection(targetAngle, self.angle))
        
    if self.bombTimer >= self.bombPeriod then
        self.bombTimer = 0
        self:shoot()
    end
end

function Cannon:shoot()
    local dx = math.cos(self.angle)
    local dy = math.sin(self.angle)
    local offsetX = (self.barrelLength+self.bombSize) * dx
    local offsetY = (self.barrelLength+self.bombSize) * dy
    local velocityX = self.bombSpeed * dx
    local velocityY = self.bombSpeed * dy
    local bomb = Bomb:new(self.world, self.x + offsetX, self.y + offsetY, {radius = self.bombSize, vx = velocityX, vy = velocityY, stickTo = {"Bomb"}, gy=750})
end

function Cannon:kill()
    self.body:destroy()
    Cannons[self.id] = nil
    Updateables[self.id] = nil
    Drawables[self.id] = nil
    self = nil
end

-- Function to normalize an angle to the range [0, 2*pi)
function normalize_angle(angle)
    return angle - (2 * math.pi) * math.floor(angle / (2 * math.pi))
end

-- Function to determine if a2 is clockwise or counterclockwise from a1
function getDirection(a1, a2)
    -- Normalize the angles
    a1 = normalize_angle(a1)
    a2 = normalize_angle(a2)
    
    -- Calculate the difference
    local diff = a2 - a1
    
    -- Normalize the difference to the range [-pi, pi)
    if diff < -math.pi then
        diff = diff + 2 * math.pi
    elseif diff >= math.pi then
        diff = diff - 2 * math.pi
    end

    -- Determine the direction
    if diff > 0.01 then
        return -1
    elseif diff < -0.01 then
        return 1
    else
        return 0
    end
end