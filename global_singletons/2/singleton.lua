local M = {}

print('singleton is running')

M.x = 3

local function say_hi()
  print('hi! x=' .. M.x)
end

M.f = function()
  say_hi()
end

return M
