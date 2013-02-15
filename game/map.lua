-- map.lua
-- Functions to generate a nice random map.


-- Globals.

seed = 47
rand_max = 65535
max_scale = 6


-- Public functions.

-- This table memoizes output from map_height.
-- In the future, we could save memory by making it an LRU cache.
mem_height = {}
function map_height(x, y)
  if mem_height[x] == nil then mem_height[x] = {} end
  local val = mem_height[x][y]
  if val ~= nil then return val end
  val = math.floor(perlin_noise(x / 4, y / 4))
  mem_height[x][y] = val
  return val
end


-- Private functions.

-- Returns a value in the range [0, 255].
-- This value is pseudorandom and based on the seed.
function perlin_noise(x, y)
  local result = 0
  for i = 0, max_scale do
    result = result + base_fancy_tri_perlin_value(x, y, i)
  end
  -- result is now in the range [-127, 127].
  result = result + 127
  if result < 0 or result > 255 then
    print('ERROR: In set_plain_perlin_color, ended up with result=' .. result)
  end
  return result
end

-- Returns corners, weights such that (x, y) = sum of w * c for c, w in corners,
-- weights; and the corners form a square of side length 2^i containing (x, y).
function find_tri_corners(x, y, i)
  local p = 2 ^ i
  x = x / p
  y = y / p

  x, y = jiggle_point(x, y, i)

  -- Apply T^{-1} to (x, y). This is from my LSH paper.
  local mu = (1 - 1 / math.sqrt(3)) / 2
  local s = x + y
  x = x / math.sqrt(3) + mu * s
  y = y / math.sqrt(3) + mu * s

  local cx, cy = math.floor(x) * p, math.floor(y) * p
  local dir_by_order = {[false] = {1, 0}, [true] = {0, 1}}
  local fx, fy = x - math.floor(x), y - math.floor(y)
  local min_xy, max_xy = math.min(fx, fy), math.max(fx, fy)

  local corners = {}
  local weights = {}

  table.insert(corners, {cx, cy})
  table.insert(weights, 1.0 - max_xy)

  local dir = dir_by_order[fx < fy]
  if show_debug_out then print('dir=' .. stringify(dir)) end
  table.insert(corners, {cx + dir[1] * p, cy + dir[2] * p})
  table.insert(weights, max_xy - min_xy)

  table.insert(corners, {cx + p, cy + p})
  table.insert(weights, min_xy)

  return corners, weights
end

function base_fancy_tri_perlin_value(x, y, i)
  local corners, weights = find_tri_corners(x, y, i)
  local result = 0
  for j = 1, 3 do
    local x = rand_from_3d_pt(corners[j][1], corners[j][2], i)
    x = x / rand_max * 2 - 1  -- x is now in the range [-1, 1].
    x = x * (2^i)
    result = result + x * weights[j]
  end
  return result
end

-- Applies a random transformation to (x, y) based on i and the seed.
function jiggle_point(x, y, i)
  local r = rand_next(i)  -- r is always an int that we can call rand_iter on.
  local dx = r / rand_max
  r = rand_next(r)
  local dy = r / rand_max
  r = rand_next(r)
  local angle = r / rand_max * math.pi * 2
  local c, s = math.cos(angle), math.sin(angle)

  x = x + dx
  y = y + dy
  return c * x - s * y, c * y + s * x
end

-- This is a bijection from Z (all integers) to integers >= 0.
function int_to_nonneg_int(i)
  if i >= 0 then
    return i * 2
  else
    return i * -2 - 1
  end
end

-- This is a bijection from (N >= 0)^2 to (N > 0).
-- Input is expected to be two nonnegative integers.
function pair_to_pos_int(x, y)
  diag = x + y
  max = (diag + 1) * (diag + 2) / 2
  return max - x
end

-- Given one pseudo-random integer, return another.
function rand_next(i)
  -- I just made this up. I have no idea if it's any good.
  return ((i + seed) * 523947 + 28348) % rand_max
end

-- Use the seed to deterministically turn (x, y, z) into
-- a pseudorandom integer.
function rand_from_3d_pt(x, y, z)
  local w = pair_to_pos_int(x, y)
  local n = pair_to_pos_int(w, z)
  local result = rand_next(rand_next(n))
  return result
end

