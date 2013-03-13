local singleton = dofile('singleton.lua')

singleton.x = 5
singleton.f()

local secondary = dofile('secondary.lua')

--[[
for key, value in pairs(_G) do
  print(key, value)
end
]]
