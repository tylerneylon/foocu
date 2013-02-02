
--[[ TODO NEXT
     I see some discontinuities in the plain Perlin implementation.
     First I'd like to draw the images to a buffer in order to keep the app responsive.
     Next, I'd like to accept mouse clicks that can print out the (x, y) coordinates
     that is being clicked. This way I can isolate a particular discontinuity and
     investigate how that is happening.

     Or I could make some educated guesses.
  ]]

-- TODO Draw the images once so we don't have to recompute so much every frame.

--[[ Better code would take the seed as a function parameter. But I am a crazy-ass
     mofo so I will just use a global. ]]
seed = 37
rand_max = 65535

function love.load()
  print('2^5=' .. 2^5)
end

function love.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local image_w = w / 4
  local image_h = image_w
  print('image_w=' .. image_w)
  local dx = image_w / 6
  local dy = (h - image_h) / 2
  local image_types = {'plain', 'triangles', 'triangles fancy'}
  local x = dx
  for i, image_type in ipairs(image_types) do
    draw_image_type(image_type, x, dy, image_w, image_h)
    x = x + image_w + 2 * dx
  end

  -- love.graphics.setColor(255, 0, 0)
  -- love.graphics.point(10, 10)
end

-- Temporary function while testing stuff.
function set_random_color()
  love.graphics.setColor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
end

function draw_image_type(image_type, origin_x, origin_y, w, h)
  for x = 0, w - 1 do
    for y = 0, h - 1 do
      set_perlin_color(image_type, x, y)
      love.graphics.point(origin_x + x, origin_y + y)
    end
  end
end

function set_perlin_color(image_type, x, y)
  if image_type == 'plain' then
    set_plain_perlin_color(x, y)
  elseif image_type == 'triangles' then
    set_tri_perlin_color(x, y)
  elseif image_type == 'triangles fancy' then
    set_fancy_tri_perlin_color(x, y)
  end
end

-- Plain Perlin functions.

function set_plain_perlin_color(x, y)
  local result = 0
  -- TODO This should be 0, 6, but I see clear discontinuities with just i = 6, 6. Need to debug that first.
  -- for i = 0, 6 do
  for i = 6, 6 do
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
  for i = 1, 4 do
    local x = rand_from_3d_pt(corners[i][1], corners[i][2], i)
    x = x / rand_max * 2 - 1  -- x is now in the range [-1, 1].
    x = x * (2^i)
    result = result + x * weights[i]
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
  local p = 2 ^ i
  x = x / p
  y = y / p
  local cx, cy = math.floor(x) * p, math.floor(y) * p
  local corners = {}
  local weights = {}
  for dx = 0, 1 do
    for dy = 0, 1 do
      table.insert(corners, {cx + dx * p, cy + dy * p})
      local wx = 1.0 - math.abs(x + dx - math.floor(x))
      local wy = 1.0 - math.abs(y + dy - math.floor(y))
      table.insert(weights, wx * wy)
    end
  end
  -- debug_out('corners=' .. stringify(corners))
  -- debug_out('weights=' .. stringify(weights))
  return corners, weights
end

-- Triangle Perlin functions.

function set_tri_perlin_color(x, y)
  -- Not yet done.
  set_random_color()
end

function set_fancy_tri_perlin_color(x, y)
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
  return ((i + seed) * 23947 + 28348) % rand_max
end

function rand_from_3d_pt(x, y, z)
  w = pair_to_pos_int(x, y)
  n = pair_to_pos_int(w, z)
  return rand_next(rand_next(n))
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
