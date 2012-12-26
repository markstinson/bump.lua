local bump = {}

local path = (...):gsub("%.init$","")

local nodes  = require(path .. '.nodes')
local cells  = require(path .. '.cells')
local aabb    = require(path .. '.aabb')
local grid   = require(path .. '.grid')
local util   = require(path .. '.util')

bump.nodes, bump.cells, bump.aabb, bump.grid, bump.util = nodes, cells, aabb, grid, util

--------------------------------------
-- Locals for faster acdess


local nodes_get, nodes_add, nodes_remove, nodes_update, nodes_each =
      nodes.get, nodes.add, nodes.remove, nodes.update, nodes.each

local cells_eachItemInBox, cells_add, cells_remove, cells_get =
      cells.eachItemInBox, cells.add, cells.remove, cells.get

local aabb_getDisplacement, aabb_isIntersecting, aabb_getSegmentIntersection, aabb_getCenter =
      aabb.getDisplacement, aabb.isIntersecting, aabb.getSegmentIntersection, aabb.getCenter

local grid_getBox, grid_getBox2, grid_traverse = grid.getBox, grid.getBox2, grid.traverse

local abs, newWeakTable, min = util.abs, util.newWeakTable, util.min

--------------------------------------
-- Private stuff

local defaultCellSize = 64
local cellSize, collisions, collisionsHappened, prevCollisions

local function collisionHasHappened(item1, item2)
  return (collisionsHappened[item1] and collisionsHappened[item1][item2]) or
         (collisionsHappened[item2] and collisionsHappened[item2][item1])
end

local function markCollisionAsHappened(item1,item2)
  collisionsHappened[item1]        = collisionsHappened[item1] or {}
  collisionsHappened[item1][item2] = true
end

local function calculateItemCollisions(item1)
  local n1 = nodes_get(item1)
  if not n1 then return end
  cells_eachItemInBox(n1.al, n1.at, n1.aw, n1.ah, function(item2)
    if item2 == item1 then return end

    local n2 = nodes_get(item2)
    if not n2
    or collisionHasHappened(item1, item2)
    or not bump.shouldCollide(item1, item2)
    then
      return
    end

    local dx1,dy1,dx2,dy2,t = aabb_getDisplacement(n1.l, n1.t, n1.w, n1.h, n1.dx, n1.dy,
                                                   n2.l, n2.t, n2.w, n2.h, n2.dx, n2.dy)
    if t then
      local col = { item1=item1, item2=item2,
                    dx1=dx1, dy1=dy1, dx2=dx2, dy2=dy2,
                    t=t
      }
      collisions[#collisions + 1] = col
    end
  end)
end

local function cancelItemCollisions(item)
  local col = nil
  for i = #collisions, 1, -1 do
    col = collisions[i]
    if col.item1 == item or col.item2 == item then
      table.remove(collisions, i)
    end
  end
end

local function recalculateItemCollisions(item)
  cancelItemCollisions(item)
  calculateItemCollisions(item)
end

local function moveItem(item, hasMoved)
  local n = nodes_get(item)
  if not n then return end

  local l,t,w,h = bump.getBBox(item)
  if hasMoved or n.l ~= l or n.t ~= t or n.w ~= w or n.h ~= h then
    hasMoved = true
    local gl,gt,gw,gh     = grid_getBox(cellSize, l,t,w,h)
    local pgl,pgt,pgw,pgh = grid_getBox(cellSize, n.pl,n.pt,n.pw,n.ph)
    local al,at,aw,ah     = grid_getBox2(gl,gt,gw,gh, pgl,pgt,pgw,pgh)
    if n.al ~= al or n.at ~= at or n.aw ~= aw or n.ah ~= ah then
      cells_remove(item, n.al, n.at, n.aw, n.ah)
      cells_add(item, al, at, aw, ah)
      n.al, n.at, n.aw, n.ah = al,at,aw,ah
    end
  end

  local cx, cy   = aabb_getCenter(l, t, w, h)
  local pcx, pcy = aabb_getCenter(n.pl, n.pt, n.pw, n.ph)
  n.l,n.t,n.w,n.h, n.dx,n.dy = l,t,w,h, pcx-cx, pcy-cy

  return hasMoved
end

local function popCollision()
  local len = #collisions
  local col = collisions[len]
  collisions[len] = nil
  return col
end

local function collisionSorter(a,b)
  if a.t == b.t then
    a.l = a.l or abs(a.dx1) + abs(a.dy1) + abs(a.dx2) + abs(a.dy2)
    b.l = b.l or abs(b.dx1) + abs(b.dy1) + abs(b.dx2) + abs(b.dy2)
    return a.l > b.l
  end
  return a.t > b.t
end

local function processCollisions()
  table.sort(collisions, collisionSorter)

  local item1,item2,item1Moved,item2Moved
  local col = popCollision()
  while col do
    item1,item2 = col.item1, col.item2

    bump.collision(item1, item2, col.dx1, col.dy1, col.dx2,col.dy2, col.t)
    markCollisionAsHappened(item1, item2)

    item1Moved = moveItem(item1)
    item2Moved = moveItem(item2)
    if item1Moved then recalculateItemCollisions(item1) end
    if item2Moved then recalculateItemCollisions(item2) end
    if item1Moved or item2Moved then table.sort(collisions, collisionSorter) end

    col = popCollision()
  end
end

local function processCollisionEnds()
  for item,neighbors in pairs(prevCollisions) do
    for neighbor,_ in pairs(neighbors) do
      bump.endCollision(item, neighbor)
    end
  end
end

function _getCellSegmentIntersections(cell, x1,y1,x2,y2)
  local intersections, len = {}, 0
  local n, ix1,iy1,ix2,iy2, dx,dy

  for item,_ in pairs(cell.items) do
    n = nodes_get(item)
    ix1, iy1, ix2, iy2 =
      aabb_getSegmentIntersection(n.l, n.t, n.w, n.h, x1, y1, x2, y2)
    if ix1 then
      len, dx, dy = len + 1, x1 - ix1, y1 - iy1
      intersections[len] = { item=item, x=ix1, y=iy1, d=dx*dx + dy*dy }
      if ix2 ~= ix1 or iy2 ~= iy1 then
        len, dx, dy = len + 1, x1-ix2, y1-iy2
        intersections[len] = { item=item, x=ix2, y=iy2, d=dx*dx + dy*dy }
      end
    end
  end

  return intersections, len
end


local function _sortByD(a,b) return a.d < b.d end

--------------------------------------
-- Public stuff

function bump.getCellSize()
  return cellSize
end

-- adds one or more items into bump
function bump.add(item1, ...)
  assert(item1, "at least one item expected, got nil")
  local items = {item1, ...}
  for i=1, #items do
    local item = items[i]
    local l,t,w,h = bump.getBBox(item)
    local gl,gt,gw,gh = grid_getBox(cellSize, l,t,w,h)

    nodes_add(item, l,t,w,h, gl,gt,gw,gh)
    cells_add(item, gl,gt,gw,gh)
  end
end

-- removes an item from bump
function bump.remove(item)
  assert(item, "item expected, got nil")
  local node = nodes_get(item)
  if node then
    cells_remove(item, node.al, node.at, node.aw, node.ah)
    nodes_remove(item)
  end
end

-- Updates the cached information that bump has about an item (bounding boxes, etc)
function bump.update(item)
  local n = nodes_get(item)
  if n then
    local hasMoved = n.pl ~= n.l or n.pt ~= n.t or n.pw ~= n.w or n.ph ~= n.h
    n.pl, n.pt, n.pw, n.ph = n.l, n.t, n.w, n.h
    moveItem(item, hasMoved)
  end
end

-- Execute callback in all the existing items
-- on the region (if no region specified, do it
-- in all items)
function bump.each(callback)
  return nodes_each(function(item,_)
    if callback(item) == false then return false end
  end)
end
local bump_each = bump.each

-- Execute callback in all items touching the specified region (box)
function bump.eachInRegion(l,t,w,h, callback)
  local gl,gt,gw,gh = grid_getBox(cellSize, l,t,w,h)
  cells_eachItemInBox( gl,gt,gw,gh, function(item)
    local node = nodes_get(item)
    if aabb_isIntersecting(l,t,w,h, node.l, node.t, node.w, node.h) then
      if callback(item) == false then return false end
    end
  end)
end
local bump_eachInRegion = bump.eachInRegion

-- Gradually visits all the items in a region defined by a segment. It invokes callback
-- on all items hit by the segment. It will stop if callback returns false
function bump.eachInSegment(x1,y1,x2,y2, callback)

  grid_traverse(cellSize, x1,y1,x2,y2, function(gx,gy)
    local cell = cells_get(gx,gy)
    if not cell then return end

    local intersections, len = _getCellSegmentIntersections(cell, x1,y1,x2,y2)

    table.sort(intersections, _sortByD)

    local inter
    for i=1, len do
      inter = intersections[i]
      if callback(inter.item, inter.x, inter.y) == false then return false end
    end
  end)

end

-- Invoke this function inside your 'update' loop. It will invoke bump.collision and
-- bump.endCollision for all the pairs of items that should collide
-- By default it updates the information of all items before performing the checks.
-- You may choose to update the information manually by passing false in the param
-- and using bump.update() on each item that moves manually.
function bump.collide(updateBefore)
  if updateBefore ~= false then bump_each(bump.update) end

  collisions, collisionsHappened = {}, {}
  bump_each(calculateItemCollisions)
  processCollisions()
  processCollisionEnds()

  prevCollisions = collisions
end

-- This resets the library. You can use it to change the cell size, if you want
function bump.initialize(newCellSize)
  cellSize = newCellSize or defaultCellSize
  nodes.reset()
  cells.reset()
  prevCollisions = newWeakTable()
  collisions     = nil
end

--------------------------------------
-- Stuff that the user will probably want to override

-- called when two items collide. dx, dy is how much must item1 be moved to stop
-- intersecting with item2. Override this function to get a collision callback
function bump.collision(item1, item2, dx, dy)
end

-- called at the end of the bump.collide() function, if two items where collidng
-- before but not any more. Override this function to get a callback when a pair
-- of items stop colliding
function bump.endCollision(item1, item2)
end

-- This function must return true if item1 'interacts' with item2. If it returns
-- false, then they will not collide. Override this function if you want to make
-- 'groups of boxes that don't collide with each other', and that kind of thing.
-- By default, all items collide with all items
function bump.shouldCollide(item1, item2)
  return true
end

-- This is how the bounding box of an object is calculated. You might want to
-- override it if your items have a different way to calculate it. Must return
-- left, top, width and height, in that order.
function bump.getBBox(item)
  return item.l, item.t, item.w, item.h
end

bump.initialize()

return bump
