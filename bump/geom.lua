-- bump.geom
-- This bump module contains functions related with spacial queries, like
-- 'do these to boxes collide?'

local geom = {}

local path = (...):gsub("%.geom$","")
local util       = require(path .. '.util')

-- private stuff

local abs         = util.abs
local floor, ceil = math.floor, math.ceil

local function gridTraverseInit(cellSize, t, t1, t2)
  local v = t2 - t1
  if     v > 0 then
    return  1,  cellSize / v, ((t + v) * cellSize - t1) / v
  elseif v < 0 then
    return -1, -cellSize / v, ((t + v - 1) * cellSize - t1) / v
  else
    return 0, math.huge, math.huge
  end
end

-- public stuff

function geom.boxesIntersect(l1,t1,w1,h1, l2,t2,w2,h2)
  return l1 < l2+w2 and l1+w1 > l2 and t1 < t2+h2 and t1+h1 > t2
end

function geom.boxesDisplacement(l1,t1,w1,h1, l2,t2,w2,h2)
  local c1x, c2x = (l1+w1) * .5, (l2+w2) * .5
  local c1y, c2y = (t1+h1) * .5, (t2+h2) * .5
  local dx = l2 - l1 + (c1x < c2x and -w1 or w2)
  local dy = t2 - t1 + (c1y < c2y and -h1 or h2)
  if abs(dx) < abs(dy) then return dx,0,dx,dy end
  return 0,dy,dx,dy
end

function geom.boxSegmentIntersection(l,t,w,h, x1,y1,x2,y2)
  local dx, dy  = x2-x1, y2-y1

  local t0, t1  = 0, 1
  local p, q, r

  for side = 1,4 do
    if     side == 1 then p,q = -dx, x1 - l
    elseif side == 2 then p,q =  dx, l + w - x1
    elseif side == 3 then p,q = -dy, y1 - t
    else                  p,q =  dy, t + h - y1
    end

    if p == 0 then
      if q < 0 then return nil end  -- Segment is parallel and outside the bbox
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

  local ix1, iy1, ix2, iy2 = x1 + t0 * dx, y1 + t0 * dy,
                             x1 + t1 * dx, y1 + t1 * dy

  if ix1 == ix2 and iy1 == iy2 then return ix1, iy1 end
  return ix1, iy1, ix2, iy2
end

function geom.gridCoords(cellSize, x,y)
  return floor(x / cellSize) + 1, floor(y / cellSize) + 1
end
local geom_gridCoords = geom.gridCoords

function geom.gridBox(cellSize, l,t,w,h)
  if not l then return nil end
  local gl,gt = geom_gridCoords(cellSize, l,t)
  local gr,gb = ceil((l+w) / cellSize), ceil((t+h) / cellSize)
  return gl, gt, gr-gl, gb-gt
end

-- based on http://www.cse.yorku.ca/~amana/research/grid.pdf
function geom.gridTraverse(cellSize, x1,y1, x2,y2, callback)
  local x, y           = geom_gridCoords(cellSize, x1,y1)
  local ox, oy         = geom_gridCoords(cellSize, x2,y2)

  local maxLen         = abs(ox-x) + abs(oy-y)
  local len            = 1

  local stepX, dx, tx  = gridTraverseInit(cellSize, x, x1, x2)
  local stepY, dy, ty  = gridTraverseInit(cellSize, y, y1, y2)

  if callback(x,y) == false then return len end

  while len <= maxLen and (x~=ox or y~=oy) do
    if tx < ty then
      tx = tx + dx
      x = x + stepX
    else
      ty = ty + dy
      y = y + stepY
    end
    len = len + 1
    if callback(x,y) == false then return len end
  end
  return len
end

return geom
