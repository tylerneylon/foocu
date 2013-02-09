require('map')

--[[ TODO
     * Move all map functions from here into map.lua.
  ]]

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
  return (i * 23947 + 28348) % 65535
end

function map(x, y)
  v = pair_to_pos_int(x, y)
  return rand_next(rand_next(v)) % 2
end

function love.load()

  -- our tiles
  tile = {}
  for i = 0, 2 do
    tile[i] = love.graphics.newImage("img/flat_tile" .. i .. ".png")
  end

  hero = {}
  for i = 0, 1 do
    hero[i] = love.graphics.newImage("img/hero" .. i .. ".png")
  end
  
  love.graphics.setNewFont(12)
  
  -- map variables
  map_offset_x, map_offset_y = 30, 30  -- In pixels.
  map_display_w = 14  -- In sprites.
  map_display_h = 20
  tile_w = 48  -- In pixels.
  tile_h = 24
  -- These are all in sprite coordinates.
  ul_corner_x = 0
  ul_corner_y = 0
  scroll_frame = 2  -- In sprites. We scroll if the hero tries to move into this frame.

  -- These are in sprites, and are allowed to be non-integers.
  hero_map_x = map_display_w / 2
  hero_map_y = map_display_h / 2

  -- love.graphics.setScissor(map_offset_x, map_offset_y, map_display_w * tile_size, map_display_h * tile_size)

  -- moving variables
  hero_speed = 2.5  -- In sprites per second.
  hero_sprite = 0
  move_clock = 0  -- A float that counts up in seconds as the hero moves.
  move_tick = 0.07  -- In seconds, how often a moving hero sprite changes.

  print("hi command line")
  for key, value in pairs(_G) do
    print(key, value)
  end

end

function love.draw()
  draw_map()
end

function love.update(dt)
  -- clock = math.floor((love.timer.getMicroTime() - clock_start) / 0.2)

  local did_move = false
  dir_by_key = {up = {0, -1},
                down = {0, 1},
                left = {-1, 0},
                right = {1, 0}}
  for key, dir in pairs(dir_by_key) do
    if love.keyboard.isDown(key) then
      hero_map_x = hero_map_x + dir[1] * dt * hero_speed
      hero_map_y = hero_map_y + dir[2] * dt * hero_speed
      scroll_if_needed()
      did_move = true
    end
  end

  if did_move then
    move_clock = move_clock + dt
    hero_sprite = math.floor(move_clock / move_tick) % 2
  end
end

function love.keypressed(key, unicode)
end

-- For this function, the input sprite is an image.
-- This takes care of map_offset_{x,y} for sprites.
function draw_sprite(sprite, x, y)
  love.graphics.draw(sprite, x * tile_w + map_offset_x, y * tile_h + map_offset_y)
end

function draw_map()
  for y = 0, map_display_h do
    for x = 0, map_display_w do
      local map_x, map_y = math.floor(x + ul_corner_x), math.floor(y + ul_corner_y)
      local tile_index = map(map_x, map_y)
      local offset_x = math.floor(ul_corner_x) - ul_corner_x
      local offset_y = math.floor(ul_corner_y) - ul_corner_y
      local height = perlin_noise(map_x * 4, map_y * 4)  -- The * 4 is temporary to get steeper slopes so I can see this is working.
      love.graphics.setColor(height, height, height)
      draw_sprite(tile[tile_index], x + offset_x, y + offset_y)
      love.graphics.setColor(255, 255, 255)
    end
  end

  -- Draw the hero.
  local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
  local bx, by = math.floor(hero_map_x), math.floor(hero_map_y + 0.3)
  love.graphics.setColor(0, 0, 255)
  love.graphics.rectangle(
      'line',
      (bx - ul_corner_x) * tile_w + map_offset_x,
      (by - ul_corner_y) * tile_h + map_offset_y,
      tile_w * 2,
      tile_h * 2)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle(
      'line',
      (hx - ul_corner_x) * tile_w + map_offset_x,
      (hy - ul_corner_y) * tile_h + map_offset_y,
      tile_w,
      tile_h)
  -- The - 1 is to account for the double-height of the hero sprite. We want to draw
  -- his feet on the square were we count him as.
  draw_sprite(hero[hero_sprite], hero_map_x - ul_corner_x, hero_map_y - ul_corner_y - 1)


  -- Draw the border. Eventually I plan for this to have status info.
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local lr_x, lr_y = map_offset_x + map_display_w * tile_w, map_offset_y + map_display_h * tile_h
  local r, g, b = love.graphics.getColor()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('fill', 0, 0, map_offset_x, h)
  love.graphics.rectangle('fill', 0, 0, w, map_offset_y)
  love.graphics.rectangle('fill', lr_x, 0, w - lr_x, h)
  love.graphics.rectangle('fill', 0, lr_y, w, h - lr_y)
  love.graphics.setColor(r, g, b)
end

-- Returns the smallest dx, dy so that (px - dx, py - dy) is inside the rect.
function delta_from_rect(px, py, rect_x, rect_y, rect_w, rect_h)
  local dx, dy = 0, 0
  local end_x, end_y = rect_x + rect_w, rect_y + rect_h

  if px < rect_x then dx = px - rect_x end
  if px > end_x then dx = px - end_x end
  if py < rect_y then dy = py - rect_y end
  if py > end_y then dy = py - end_y end

  return dx, dy
end

function scroll_if_needed()
  -- The - 1 in the width and height are to account for the sprite used
  -- up by the hero sprite itself.  We wouldn't need that - 1 if the
  -- hero were just a single point.
  local dx, dy = delta_from_rect(
      hero_map_x, hero_map_y,
      ul_corner_x + scroll_frame, ul_corner_y + scroll_frame,
      map_display_w - 2 * scroll_frame - 1, map_display_h - 2 * scroll_frame - 1)
  
  ul_corner_x = ul_corner_x + dx
  ul_corner_y = ul_corner_y + dy
end
