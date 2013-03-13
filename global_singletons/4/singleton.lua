local selfname = debug.getinfo(1).source
if not global_singleton then global_singleton = {} end
if global_singleton[selfname] then return global_singleton[selfname] end

local M = {}
global_singleton[selfname] = M

--[[ Begin module definition ]]

print('singleton is running')

local function say_hi()
  print('hi! x=' .. M.x)
end

M.x = 3

M.f = function()
  say_hi()
end

--[[ End module definition ]]

return M
