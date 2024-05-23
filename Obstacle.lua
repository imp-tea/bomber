local class = require 'middleclass'
Obstacle = class('Obstacle')

Obstacles = {}

function Obstacle:initialize(world, x, y, properties)
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
	self.spin = properties.spin or 0
	self.points = properties.points or nil


    self.body = love.physics.newBody(world, x, y, "kinematic")
    if self.type == "rectangle" then
    	self.shape = love.physics.newRectangleShape(0,0, self.width, self.height, self.rotation)
    end
	if self.type == "circle" then
		self.shape = love.physics.newCircleShape(self.size)
	end
	if self.type == 'polygon' then
		self.shape = love.physics.newPolygonShape(self.points)
	end
	self.body:setUserData(self.userData)
    self.fixture = love.physics.newFixture (self.body, self.shape, self.density)
    self.fixture:setFilterData(self.category, self.mask, self.group)
    self.fixture:setFriction(self.friction)
    self.fixture:setUserData(self.userData)
	self.fixture:setRestitution(self.restitution)
	if self.spin ~= nil then self.body:setAngularVelocity(self.spin) end

	self.path = properties.path or nil
	if self.path ~= nil then
		self.timeZero = love.timer.getTime()
		self.steps = #self.path
		self.currentStep = 1
		self.startValues = {self.body:getX(),self.body:getY(),self.body:getAngle()}
	end

	self.id = id or "Obstacle"..tostring(x)..tostring(y)..tostring(self.type)..tostring(math.random(1,1000))
    Obstacles[self.id] = self
end

function Obstacle:draw()
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

function Obstacle:update()
	if self.path ~= nil then self:tween() end
end


function Obstacle:tween()
	local clock = love.timer.getTime() - self.timeZero

	if clock >= self.path[self.currentStep][1] then
		self.body:setX(self.startValues[1]+self.path[self.currentStep][2])
		self.body:setY(self.startValues[2]+self.path[self.currentStep][3])
		self.body:setAngle(self.startValues[3]+self.path[self.currentStep][4])
		self.startValues = {self.body:getX(),self.body:getY(),self.body:getAngle()}
		self.currentStep = self.currentStep + 1
		clock = 0
		self.timeZero = love.timer.getTime()
		if self.currentStep > self.steps then
			self.currentStep = 1
		end
	end
	--{"startTime","endTime","deltaX","deltaY","deltaAngle"}
	local path = self.path[self.currentStep]
	local period = path[1]
	local mode = path[5] or 'linear'
	local vx,vy,va = 0,0,0
	if mode == 'linear' then
		vx = path[2] / period
		vy = path[3] / period
		va = path[4] / period
	elseif mode == 'eased' then
		local easeScale = (2-math.abs(-4*clock/period+2))
		vx = (path[2] / period) * easeScale
		vy = (path[3] / period) * easeScale
		va = (path[4] / period) * easeScale
	end
	self.body:setLinearVelocity(vx,vy)
	self.body:setAngularVelocity(va)

end
