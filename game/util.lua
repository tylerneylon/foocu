--[[ util.lua

     Utility functions for foocu.
  ]]

-- Versatile indexing functions.

function int_to_nonneg_int(i)
  if i >= 0 then
    return i * 2
  else
    return i * -2 - 1
  end
end

-- Input is expected to be two nonnegative integers.
function pair_to_pos_int(x, y)
  diag = x + y
  max = (diag + 1) * (diag + 2) / 2
  return max - x
end

-- Pseudorandom functions.

function rand_next(i)
  -- I just made this up. I have no idea if it's any good.
  return (i * 23947 + 28348) % 65535
end

-- Printing and string functions.

-- This doesn't handle strings yet (ironically).
function stringify(t)
  if type(t) == 'table' then
    local s = '{'
    for i, v in ipairs(t) do
      if #s > 1 then s = s .. ', ' end
      s = s .. stringify(v)
    end
    s = s .. '}'
    return s
  elseif type(t) == 'number' then
    return tostring(t)
  elseif type(t) == 'boolean' then
    return tostring(t)
  end
  return 'unknown type'
end

-- This version also prints out table keys.
function full_stringify(t)
  if type(t) == 'table' then
    local s = '{'
    for k, v in pairs(t) do
      if #s > 1 then s = s .. ', ' end
      s = s .. ('[' .. stringify(k) .. ']=')
      s = s .. stringify(v)
    end
    s = s .. '}'
    return s
  elseif type(t) == 'number' then
    return tostring(t)
  end
  return 'unknown type'
end


-- This always returns a short string representation of t.
-- I'm originally writing it to be able to concatenate possibly-nil values
-- via the .. operator.
function s(t)
  if type(t) == 'string' then return "'" .. t .. "'" end
  return '<' .. type(t) .. '>'
end

did_move = false
function print_if_moved(s)
  if did_move then print(s) end
end
