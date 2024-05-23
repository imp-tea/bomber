local class = require 'middleclass'
Camera = class('Camera')

function Camera:initialize(target, scale, rotation, targetType)
    self.target = target or {x=love.graphics.getWidth()/2, y=love.graphics.getHeight()/2}
    self.scaleX = scale or 1
    self.scaleY = self.scaleX
    self.rotation = rotation or 0
    self.targetType = targetType or "coordinates"
    self.x = self.target.x - ((love.graphics.getWidth()/2)*self.scaleX)
    self.y = self.target.y - ((love.graphics.getHeight()/2)*self.scaleY)
end

function Camera:update()
    local tarx = self.target.x - ((love.graphics.getWidth()/2)*self.scaleX)
    local tary = self.target.y - ((love.graphics.getHeight()/2)*self.scaleY)
    self:move((tarx-self.x)/10, (tary-self.y)/10)
end

function Camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
  love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
  love.graphics.pop()
end

function Camera:move(dx, dy)
  self.x = self.x + (dx or 0)
  self.y = self.y + (dy or 0)
end

function Camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end
