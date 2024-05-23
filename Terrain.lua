local class = require 'middleclass'
Terrain = class('Terrain')

Terrains = {}

function Terrain:initialize(world, x, y, properties)
	self.world = world
	self.x = x
	self.y = y
    if properties == nil then properties = {} end
    self.friction = properties.friction or 0.2
    self.type = properties.type or "rectangle"
    self.size = properties.size or 5
    self.height = properties.height or 10
    self.width = properties.width or 10
    self.color = properties.color or {1,1,1,1}
    self.category = properties.category or 1
    self.mask = properties.mask or 1
    self.group = properties.group or 0
	self.restitution = properties.restitution or 0
	self.rotation = properties.rotation or 0
    self.userData = properties.userData or {jumpable = true}
	self.points = properties.points or nil

    self.body = love.physics.newBody(world, x, y, "static")
	self.body:setUserData(self.userData)
    if self.type == "rectangle" then
    	self.shape = love.physics.newRectangleShape(0,0, self.width, self.height, self.rotation)
    end
	if self.type == 'polygon' then
		self.shape = love.physics.newPolygonShape(self.points)
	end
	if self.type == "circle" then
		self.shape = love.physics.newCircleShape(self.size)
	end
    self.fixture = love.physics.newFixture (self.body, self.shape, self.density)
    self.fixture:setFilterData(self.category, self.mask, self.group)
    self.fixture:setFriction(self.friction)
    self.fixture:setUserData(self.userData)
	self.fixture:setRestitution(self.restitution)

	self.id = id or "Terrain"..tostring(x)..tostring(y)..tostring(self.type)..tostring(math.random(1,1000))
    Terrains[self.id] = self
end

function Terrain:draw()
	love.graphics.setColor(self.color)
	if self.shape:getType() == "circle" then
        local x,y = self.body:getWorldPoints(self.shape:getPoint())
		love.graphics.setColor(1,1,1,1)
		love.graphics.circle("line",x,y,self.shape:getRadius())
		love.graphics.setColor(self.color)
        love.graphics.circle("fill",x,y,self.shape:getRadius())
    elseif self.shape:getType() == "polygon" then
		love.graphics.setColor(1,1,1,1)
        love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
		love.graphics.setColor(self.color)
        love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
    end
end
