-- bump.util: Some utility functions for bump.lua
local util = {}

local modes = {
  k  = {__mode = 'k'},
  v  = {__mode = 'v'},
  kv = {__mode = 'kv'}
}

local abs = math.abs

function util.newWeakTable(mode)
  return setmetatable({}, modes[mode or 'k'])
end

function util.copy(t)
  local c = {}
  for k,v in pairs(t) do c[k] = v end
  return c
end

function util.nearest(x, a, b)
  if abs(a - x) < abs(b - x) then return a else return b end
end

return util
