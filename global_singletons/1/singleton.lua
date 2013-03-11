local M = {}

M.f = function()
  say_hi()
end

local function say_hi()
  print('hi!')
end

return M
