local Entity = require 'entities.Entity'
local bump   = require 'lib.bump'

local Laser = class('Laser', Entity)

function Laser:initialize(l,t,target)
  Entity.initialize(self)
  self.l = l
  self.t = t
  self.target = target
  self.w = 30
  self.h = self.w
  self.ray = {}
  self.rayFunction = function(item, x, y)
    if item == self then return end
    self.ray.x = x
    self.ray.y = y
    self.hitting = item == target
    return false
  end
  bump.add(self)
end

function Laser:update(dt)
  local tx, ty = self.target:getCenter()
  local x,y = self:getCenter()
  bump.eachInSegment(x, y, tx, ty, self.rayFunction)
end

function Laser:shouldCollide()
  return false
end

function Laser:draw()
  local x,y = self:getCenter()
  love.graphics.setColor(255,0,0,70)
  love.graphics.circle('fill', x, y, 20)
  love.graphics.setColor(255,0,0)
  love.graphics.circle('line', x, y, 20)

  love.graphics.setColor(255, 255, 255, 70)
  love.graphics.line(x, y, self.target:getCenter())

  if self.hitting then
    love.graphics.setColor(255, 0, 0)
  else
    love.graphics.setColor(255, 255, 0)
  end
  love.graphics.line(x, y, self.ray.x, self.ray.y)
end



return Laser
