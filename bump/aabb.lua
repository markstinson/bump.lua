local aabb = {}

local path = (...):gsub("%.aabb$","")
local util       = require(path .. '.util')

local abs, nearest  = math.abs, util.nearest
local inf           = math.huge

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

-- returns true if an aabb contains a point (returns false if the box "touches" the point but does not contain
-- it, i.e. the point is right in the aabb frontier)
function aabb.containsPoint(l,t,w,h, x,y)
  return x > l and y > t and x < l + w and y < t + h
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

function aabb.getPointDisplacement(l,t,w,h, x,y)
  local px, py = getNearestPointInPerimeter(l,t,w,h, x,y)
  local dx, dy = x-px, y-py
  if abs(dx) < abs(dy) then return dx,0 end
  return 0,dy
end
local getPointDisplacement = aabb.getPointDisplacement

function aabb.getDisplacement(l1,t1,w1,h1,dx1,dy1, l2,t2,w2,h2,dx2,dy2)
  local ti = 0
  local dx, dy  = dx1 - dx2, dy1 - dy2
  local l,t,w,h = getMinkowskyDiff(l1,t1,w1,h1, l2,t2,w2,h2)

  if containsPoint(l,t,w,h, 0,0) then
    if dx ~= 0 or dy ~= 0 then
      local t0, t1 = liangBarsky(l,t,w,h, 0,0,dx,dy, -inf, inf)
      ti = abs(t0) < abs(t1) and t0 or t1
    end
    dx, dy = getNearestPointInPerimeter(l,t,w,h, 0,0)
    if abs(dx) < abs(dy) then return dx,0,0,0,ti end
    return 0,dy,0,0,ti
  else
    ti = liangBarsky(l,t,w,h, 0,0,dx,dy, 0,1)
    if ti and ti ~= 0 and ti ~= 1 then
      return dx1*ti, dy1*ti, dx2*ti, dy2*ti, ti
    end
  end
end

function aabb.getSegmentIntersection(l,t,w,h, x1,y1,x2,y2)
  return liangBarskyIntersections(l,t,w,h, x1,y1,x2,y1, 0,1)
end

function aabb.getRayIntersection(l,t,w,h, x1,y1,x2,y2)
  return liangBarskyIntersections(l,t,w,h, x1,y1,x2,y1, 0,math.huge)
end

function aabb.getCenter(l,t,w,h)
  return l+w*0.5, t+h*0.5
end

return aabb
