local aabb = {}

local path = (...):gsub("%.aabb$","")
local util       = require(path .. '.util')

local abs, nearest = util.abs, util.nearest

local function liangBarsky(l,t,w,h, x1,y1,x2,y2, t0,t1)
  local dx, dy  = x2-x1, y2-y1
  local p, q, r

  for side = 1,4 do
    if     side == 1 then p,q = -dx, x1 - l
    elseif side == 2 then p,q =  dx, l + w - x1
    elseif side == 3 then p,q = -dy, y1 - t
    else                  p,q =  dy, t + h - y1
    end

    if p == 0 then
      if q < 0 then return nil end
    else
      r = q / p
      if p < 0 then
        if     r > t1 then return nil
        elseif r > t0 then t0 = r
        end
      else -- p > 0
        if     r < t0 then return nil
        elseif r < t1 then t1 = r
        end
      end
    end
  end

  return t0,t1, dx,dy
end

function liangBarskyIntersections(l,t,w,h, x1,y1,x2,y1, minT, maxT)
  local t0,t1,dx,dy = liangBarsky(l,t,w,h, x1,y1,x2,y1, minT, maxT)
  if t0 then return x1 + dx*t0, y1 + dy*t0, x1 + dx*t1, y1 + dy*t1 end
end

function aabb.isIntersecting(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

function aabb.containsPoint(l,t,w,h, x,y)
  return not(x < l or y < t or x > l + w or y > t + h)
end
local containsPoint = aabb.containsPoint

function aabb.getNearestPointInPerimeter(l,t,w,h, x,y)
  return nearest(x, l, l+w), nearest(y, t, t+h)
end
local getNearestPointInPerimeter = aabb.getNearestPointInPerimeter

function aabb.getMinkowskyDiff(l1,t1,w1,h1, l2,t2,w2,h2)
  return l2 - l1 - w1,
         t2 - t1 - h1,
         w1 + w2,
         h1 + h2
end
local getMinkowskyDiff = aabb.getMinkowskyDiff

function aabb.getDisplacement(l1,t1,w1,h1, l2,t2,w2,h2)
  local l,t,w,h = getMinkowskyDiff(l1,t1,w1,h1, l2,t2,w2,h2)
  if not containsPoint(l,t,w,h, 0,0) then return nil end

  local dx, dy  = getNearestPointInPerimeter(l,t,w,h, 0,0)
  if abs(dx) < abs(dy) then return dx,0,dx,dy end

  return 0,dy,dx,dy
end

function aabb.getSegmentIntersection(l,t,w,h, x1,y1,x2,y2)
  return liangBarskyIntersections(l,t,w,h, x1,y1,x2,y1, 0,1)
end

function aabb.getRayIntersection(l,t,w,h, x1,y1,x2,y2)
  return liangBarskyIntersections(l,t,w,h, x1,y1,x2,y1, 0,math.huge)
end

return aabb
