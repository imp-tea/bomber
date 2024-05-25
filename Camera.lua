local class = require 'middleclass'
Camera = class('Camera')

function Camera:initialize(target, scale, rotation, targetType)
    self.target = target or {x=love.graphics.getWidth()/2, y=love.graphics.getHeight()/2}
    self.scale = scale or 1
    self.targetScale = self.scale
    self.rotation = rotation or 0
    self.targetType = targetType or "coordinates"
    self.x = self.target.x - ((love.graphics.getWidth()/2)*self.scale)
    self.y = self.target.y - ((love.graphics.getHeight()/2)*self.scale)
end

function Camera:update()
    self.scale = self.scale + (self.targetScale-self.scale)/20
    local tarx = self.target.x - ((love.graphics.getWidth()/2)*self.targetScale)
    local tary = self.target.y - ((love.graphics.getHeight()/2)*self.targetScale)
    self:move((tarx-self.x)/20, (tary-self.y)/20)
end

function Camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scale, 1 / self.scale)
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

function Camera:zoom(z)
  local zoomFactor = 1.1
  if z < 0 then zoomFactor = 0.9 end
  self.targetScale = self.targetScale * zoomFactor
end