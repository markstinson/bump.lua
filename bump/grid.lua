local grid = {}

local path = (...):gsub("%.grid$","")

-- private stuff

local abs, min, max, floor, ceil = math.abs, math.min, math.max, math.floor, math.ceil

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

function grid.getCoords(cellSize, x,y)
  return floor(x / cellSize) + 1, floor(y / cellSize) + 1
end
local grid_getCoords = grid.getCoords

function grid.getBox(cellSize, l,t,w,h)
  if not l then return nil end
  local gl,gt = grid_getCoords(cellSize, l,t)
  local gr,gb = ceil((l+w) / cellSize), ceil((t+h) / cellSize)
  return gl, gt, gr-gl, gb-gt
end

-- returns the box that bounds two given boxes
function grid.getBox2(l1,t1,w1,h1, l2,t2,w2,h2)
  local l,t         = min(l1,l2), min(t1,t2)
  local r1,b1,r2,b2 = l1+w1,t1+h1, l2+w2,t2+h2
  local r,b         = max(r1,r2), max(b1,b2)
  return l,t, r-l, b-t
end

-- based on http://www.cse.yorku.ca/~amana/research/grid.pdf
function grid.traverse(cellSize, x1,y1, x2,y2, callback)
  local x, y           = grid_getCoords(cellSize, x1,y1)
  local ox, oy         = grid_getCoords(cellSize, x2,y2)

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

return grid
