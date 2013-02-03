
--[[ Better code would take the seed as a function parameter. But I am a crazy-ass
     mofo so I will just use a global. ]]
seed = 37
rand_max = 65535

show_debug_out = false

function love.load()
  print('Rendering images...')
  w, h = love.graphics.getWidth(), love.graphics.getHeight()
  image_w = w / 5
  image_h = image_w
  local image_types = {'plain', 'triangles', 'triangles fancy'}
  base_images = {}  -- These are the high-amplitude functions included in each final image.
  images = {}
  for j = 0, 1 do
    local image_list = nil
    if j == 0 then image_list = images else image_list = base_images end
    local base_only = (j == 1)
    for i, image_type in ipairs(image_types) do
      local canvas = love.graphics.newCanvas(image_w, image_h)
      -- local canvas = love.graphics.newCanvas(256, 256)
      love.graphics.setCanvas(canvas)
      draw_image_type(image_type, image_w, image_h, base_only)
      love.graphics.setCanvas()
      table.insert(image_list, canvas)
    end
  end
  love.graphics.setColor(255, 255, 255)
  print('Done.')

  -- love.graphics.setColor(255, 0, 0)
  -- love.graphics.point(10, 10)
end

function love.draw()
  -- dx, dy are the margins around each image
  dx = (w - 3 * image_w) / 6
  dy = (h - 2 * image_h) / 4
  local x = dx
  local y = dy
  for i, image in ipairs(base_images) do
    love.graphics.draw(image, x, y)
    x = x + image_w + 2 * dx
  end
  x = dx
  y = 3 * dy + image_h
  for i, image in ipairs(images) do
    love.graphics.draw(image, x, y)
    x = x + image_w + 2 * dx
  end
end

function love.mousepressed(x, y, button)
  x = x - dx
  y = y - dy
  print('Mouse pressed at coords (' .. x .. ', ' .. y .. ') in image 1.')
  show_debug_out = true
  print('Base Perlin value here is ' .. base_plain_perlin_value(x, y, 6) .. '.')
  show_debug_out = false
end

-- Temporary function while testing stuff.
function set_random_color()
  love.graphics.setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
end

function draw_image_type(image_type, w, h, base_only)
  for x = 0, w - 1 do
    for y = 0, h - 1 do
      set_perlin_color(image_type, x, y, base_only)
      love.graphics.point(x + 0.5, y + 0.5)
    end
  end
end

function set_perlin_color(image_type, x, y, base_only)
  if image_type == 'plain' then
    set_plain_perlin_color(x, y, base_only)
  elseif image_type == 'triangles' then
    set_tri_perlin_color(x, y, base_only)
  elseif image_type == 'triangles fancy' then
    set_fancy_tri_perlin_color(x, y, base_only)
  end
end

-- Plain Perlin functions.

function set_plain_perlin_color(x, y, base_only)
  local result = 0
  local min_i = 0
  if base_only then min_i = 6 end
  for i = min_i, 6 do
    result = result + base_plain_perlin_value(x, y, i)
  end
  -- result is now in the range [-127, 127].
  result = result + 127
  if result < 0 or result > 255 then
    print('ERROR: In set_plain_perlin_color, ended up with result=' .. result)
  end
  love.graphics.setColor(result, result, result)
end

function base_plain_perlin_value(x, y, i)
  local corners, weights = find_square_corners(x, y, i)
  local result = 0
  for j = 1, 4 do
    local x = rand_from_3d_pt(corners[j][1], corners[j][2], i)
    x = x / rand_max * 2 - 1  -- x is now in the range [-1, 1].
    x = x * (2^i)
    if show_debug_out then print('for corner ' .. stringify(corners[j]) .. ', x=' .. x) end
    result = result + x * weights[j]
  end
  return result
end

t = 5
function debug_out(s)
  if t <= 0 then return end
  print(s)
  t = t - 1
end

-- Returns corners, weights such that (x, y) = sum of w * c for c, w in corners, weights;
-- and the corners form a square of side length 2^i containing (x, y).
function find_square_corners(x, y, i)
  -- debug_out('find_square_corners(' .. x .. ', ' .. y .. ', ' .. i .. ')')
  if show_debug_out then print('find_square_corners(' .. x .. ', ' .. y .. ', ' .. i .. ')') end
  local p = 2 ^ i
  x = x / p
  y = y / p
  local cx, cy = math.floor(x) * p, math.floor(y) * p
  local corners = {}
  local weights = {}
  for dx = 0, 1 do
    for dy = 0, 1 do
      table.insert(corners, {cx + dx * p, cy + dy * p})
      local wx = 1.0 - math.abs(math.floor(x) + dx - x)
      local wy = 1.0 - math.abs(math.floor(y) + dy - y)
      table.insert(weights, wx * wy)
    end
  end
  -- debug_out('corners=' .. stringify(corners))
  -- debug_out('weights=' .. stringify(weights))
  if show_debug_out then print('corners=' .. stringify(corners)) end
  if show_debug_out then print('weights=' .. stringify(weights)) end
  return corners, weights
end

-- Triangle Perlin functions.

function set_tri_perlin_color(x, y, base_only)
  -- Not yet done.
  set_random_color()
end

function set_fancy_tri_perlin_color(x, y, base_only)
  -- Not yet done.
  set_random_color()
end

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

function rand_next(i)
  -- I just made this up. I have no idea if it's any good.
  return ((i + seed) * 523947 + 28348) % rand_max
end

function rand_from_3d_pt(x, y, z)
  if show_debug_out then print('rand_from_3d_pt(' .. x .. ', ' .. y .. ', ' .. z .. ')') end
  local w = pair_to_pos_int(x, y)
  local n = pair_to_pos_int(w, z)
  local result = rand_next(rand_next(n))
  if show_debug_out then print('result=' .. result) end
  return result
end

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
  end
  return 'unknown type'
end
