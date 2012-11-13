-- bump.geometry
-- This bump module contains functions related with spacial queries, like
-- 'do these to boxes collide?'

local geometry = {}

local path = (...):gsub("%.geometry$","")
local util       = require(path .. '.util')

local util_abs = util.abs

function geometry.boxesIntersect(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

function geometry.boxesDisplacement(l1,t1,w1,h1, l2,t2,w2,h2)
  local c1x, c2x = (l1+w1) * .5, (l2+w2) * .5
  local c1y, c2y = (t1+h1) * .5, (t2+h2) * .5
  local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
  local dy = t2 - t1 + (c1y < c2y and -h1 or h2)
  if util_abs(dx) < util_abs(dy) then return dx,0,dx,dy end
  return 0,dy,dx,dy
end

return geometry
