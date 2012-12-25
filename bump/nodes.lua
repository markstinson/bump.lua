-- bump.nodes
-- A node in lua is 'the information bump has about that node'
-- Typically, its boundingbox & gridbox. This module deals with managing and storing
-- bump's nodes.

local nodes = {} -- (public/exported) holds the public methods of this module

local path = (...):gsub("%.nodes$","")
local util       = require(path .. '.util')

local store      -- (private) holds the list of created nodes

function nodes.add(item, l,t,w,h, al,at,aw,ah)
  store[item] = {l=l,t=t,w=w,h=h,
                 pl=l,pt=t,pw=w,ph=h,
                 al=al,at=at,aw=aw,ah=ah,
                 dx=0,dy=0}
end

function nodes.get(item)
  return store[item]
end

function nodes.reset()
  store = util.newWeakTable()
end

function nodes.count()
  local count = 0
  for _,_ in pairs(store) do count = count + 1 end
  return count
end

function nodes.remove(item)
  store[item] = nil
end

function nodes.each(callback)
  for item,node in pairs(store) do
    if callback(item, node) == false then return false end
  end
end

nodes.reset()

return nodes
