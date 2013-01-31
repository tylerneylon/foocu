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
  for i = 0, 1 do
    tile[i] = love.graphics.newImage("img/tile" .. i .. ".png")
  end

  hero = {}
  for i = 0, 1 do
    hero[i] = love.graphics.newImage("img/hero" .. i .. ".png")
  end
  
  love.graphics.setNewFont(12)
  
  -- map variables
  map_w = 20
  map_h = 20
  map_x = 0
  map_y = 0
  map_offset_x = 30
  map_offset_y = 30
  map_display_w = 14
  map_display_h = 10
  tile_w = 48
  tile_h = 48

  -- new map variables
  map_offset_x = 30
  map_offset_y = 30
  map_display_w = 14
  map_display_h = 10
  tile_size = 48
  hero_screen_x = map_display_w / 2
  hero_screen_y = map_display_h / 2
  hero_offset_x = 0
  hero_offset_y = 0
  ul_corner_x = 0
  ul_corner_y = 0

  -- moving variables
  hero_speed = 2.5  -- In sprites per second.
  hero_sprite = 0
  move_clock = 0
  move_tick = 0.1  -- In seconds, how often a moving hero sprite changes.

  print("hi command line")
  for key, value in pairs(_G) do
    print(key, value)
  end
end

function love.draw()
  draw_map()
  -- love.graphics.print('Hello World!', 400, 300)
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
      hero_screen_x = hero_screen_x + dir[1] * dt * hero_speed
      hero_screen_y = hero_screen_y + dir[2] * dt * hero_speed
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

function draw_map()
  for y = 1, map_display_h do
    for x = 1, map_display_w do
      love.graphics.draw( 
          tile[map(x + map_x, y + map_y)], 
          (x * tile_w) + map_offset_x, 
          (y * tile_h) + map_offset_y)
    end
  end

  love.graphics.draw(
      hero[hero_sprite],
      math.floor((hero_screen_x + hero_offset_x) * tile_w) + map_offset_x,
      math.floor((hero_screen_y + hero_offset_y) * tile_w) + map_offset_y)
end

