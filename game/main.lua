require('draw')
require('map')

--[[ TODO

     Soon:
     * Change hero movement so he is considered to take up space instead of
       being a single point in space. Use multiple sprites to determine where
       he can walk or if he will fall; disallow walking partially into walls.
     * Check that multi-height slopes are not getting extra green borders.
     * Move all map functions from here into map.lua.
     * Separate groups of similar functions into files.
     * Make 1-height changes 1/3rd of a cube in size, semi-Lego-ish.
     * Make a single map sprite (an xy-square) have 1:1 pixel ratio (square).

     Soonish (which occurs after soon unless I feel otherwise):
     * Add biomes.
     * Modify height calculation based on biomes.
     * Add shacks, villages, towns, and cities.
     * Add roads of appropriate sizes between dwellings.
     * Line lengths limited by 80 chars.
     * Remove 3 as a magin number in 3rd-height slopes.
     * Factor out the hero_map_xy-to-map_squares_occupied code.

     Later:
     * Improve map sections transparency.
     * Make independent files also independent code-wise (for now I'm afraid
       they may rely on globals).

     (Other todo items are in my notebook.)
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
    tile[i] = love.graphics.newImage("img/tile" .. i .. ".png")
  end

  hero = {}
  for i = 0, 1 do
    hero[i] = love.graphics.newImage("img/hero" .. i .. ".png")
  end
  
  love.graphics.setNewFont(12)
  
  -- map variables
  map_offset_x, map_offset_y = 30, 30  -- In pixels.
  map_display_w = 14  -- In sprites.
  map_display_h = 30
  tile_w = 48  -- In pixels.
  tile_h = 16
  -- These are all in sprite coordinates.
  ul_corner_x = 0
  ul_corner_y = 0
  scroll_frame = 3  -- In sprites. We scroll if the hero tries to move into this frame.

  -- These are in sprites, and are allowed to be non-integers.
  hero_map_x = map_display_w / 2
  hero_map_y = map_display_h / 6

  -- moving variables
  hero_speed = 2.5  -- In sprites per second.
  hero_sprite = 0
  move_clock = 0  -- A float that counts up in seconds as the hero moves.
  move_tick = 0.07  -- In seconds, how often a moving hero sprite changes.

  for key, value in pairs(_G) do
    print(key, value)
  end

end

function love.draw()
  draw_map()
end

-- Variables used for climb/fall animations.
pending_xy_delta = nil  -- This will have the form {dx, dy}, pre-multiplied by dt and speed.
pending_anim_time_left = 0
pending_hdiff = 0
anim_duration = 0.08

function love.update(dt)
  --print('ul_corner_y=' .. ul_corner_y)
  -- clock = math.floor((love.timer.getMicroTime() - clock_start) / 0.2)

  -- Only do the standard movement if we're not mid-climb/fall.
  did_move = false
  -- local did_move = false  -- When not debugging, maybe this should be local.
  if pending_hdiff == 0 then

    dir_by_key = {up = {0, -1},
                  down = {0, 1},
                  left = {-1, 0},
                  right = {1, 0}}
    local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
    local old_height = map_height(hx, hy)
    local hero_save_x, hero_save_y = hero_map_x, hero_map_y

    local total_dir = {0, 0}
    for key, dir in pairs(dir_by_key) do
      if love.keyboard.isDown(key) then
        for i = 1, 2 do total_dir[i] = total_dir[i] + dir[i] end
        did_move = true
      end
    end
    hero_map_x = hero_map_x + total_dir[1] * dt * hero_speed
    hero_map_y = hero_map_y + total_dir[2] * dt * hero_speed

    hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
    local new_height = map_height(hx, hy)
    local hdiff = new_height - old_height

    if hdiff < 0 then  -- It's a fall.
      pending_xy_delta = {0, 0}
      pending_anim_time_left = anim_duration
      pending_hdiff = hdiff
      ul_corner_y = ul_corner_y + pending_hdiff / 3
    elseif hdiff > 0 then  -- It's a climb.
      pending_xy_delta = {total_dir[1] * dt * hero_speed, total_dir[2] * dt * hero_speed}
      hero_map_x, hero_map_y = hero_save_x, hero_save_y
      pending_anim_time_left = anim_duration
      pending_hdiff = hdiff
    end
  end

  if pending_hdiff ~= 0 then
    local effective_dt = pending_anim_time_left
    pending_anim_time_left = pending_anim_time_left - dt
    if pending_anim_time_left <= 0 then
      hero_map_x = hero_map_x + pending_xy_delta[1]
      hero_map_y = hero_map_y + pending_xy_delta[2]
      if pending_hdiff > 0 then ul_corner_y = ul_corner_y + pending_hdiff / 3 end
      pending_anim_time_left = 0
    else
      effective_dt = dt
    end
    -- ul_corner_y = ul_corner_y + pending_hdiff * (effective_dt / anim_duration)
    -- TODO Clean up all this animation code. It is sloppy as I'm figuring it out.
    if pending_anim_time_left <= 0 then pending_hdiff = 0 end
  end

  scroll_if_needed()

  if did_move then
    move_clock = move_clock + dt
    hero_sprite = math.floor(move_clock / move_tick) % 2
  end

  -- TODO Maybe this should only be done if did_move is true.
  recalc_zbuffer()

  print_if_moved('dt=' .. dt)
  print_if_moved('ul_corner = (' .. ul_corner_x .. ', ' .. ul_corner_y .. ')')
  print_if_moved('hero_map = (' .. hero_map_x .. ', ' ..
                 hero_map_y .. ')')
end

-- For a fall, this will go from N down to 0. (Always non-negative.)
-- For a climb, this will go from 0 up to N.  (Always non-negative.)
-- I expect it to be used to draw the hero as something like:
--   drawn_y = standing_still_y - hero_anim_offset()
function hero_anim_offset()
  local perc_left = pending_anim_time_left / anim_duration
  if pending_hdiff < 0 then
    return pending_hdiff * -1 * perc_left
  elseif pending_hdiff > 0 then
    return pending_hdiff * (1 - perc_left)
  else
    return 0
  end
end

--[[ Returns a list of elements from (0, 1, 2, 3) indicating which borders
     should be drawn for the given tile. The border numbers are set up like so:
          ---1---
         |       |
         0       2
         |       |
          ---3---
     This way, we can look at b%2 and b//2 to concisely know what to draw.
  ]]
function get_border(map_x, map_y)
  local h = map_height(map_x, map_y)
  local border = {}
  local dirs = {{-1, 0}, {0, -1}, {1, 0}, {0, 1}}
  for i, dir in ipairs(dirs) do
    local other_h = map_height(map_x + dir[1], map_y + dir[2])
    if other_h ~= h then table.insert(border, i - 1) end
  end
  return border
end

function recalc_zbuffer()

  -- Reset the zbuffer, which we call tile_cols. I could rename either
  -- this function or the variable so it's more obvious they refer to the same thing.
  -- tile_cols[col#][row#] = {bkg_tile, fg_tile} or just {bkg_tile}.
  tile_cols = {}
  borders = {}

  -- Variables to be used in the functions below.
  local last_hdiff = nil
  local bkg_fg_index = 1
  local this_border = nil

  -- base_{x,y} are the screen coordinates before accounting for h_diff. They should be
  -- integers, and y may be off the visible screen, including negative.
  function add_point_to_zbuffer(base_x, base_y, tile_index, hdiff, top_layer)
    --[[ print('add_point_to_zbuffer(' .. base_x .. ', ' .. base_y .. ', ' ..
          tile_index .. ', ' .. hdiff .. ', ..)') ]]
    top_layer = top_layer or false  -- Now top_layer should always be a bool.
    add_tile_to_zbuffer(base_x, 3 * base_y - hdiff, tile_index, top_layer)
    if last_hdiff ~= nil and hdiff < last_hdiff then
      -- print('in the slope block')
      -- We may need to put some slopes in here.
      for hd = hdiff + 1, last_hdiff do  -- Not (last_hdiff - 1) because last time base_y was 1 lower.
        add_tile_to_zbuffer(base_x, 3 * base_y - hd, 2, top_layer)
      end
    end
    last_hdiff = hdiff
  end

  function add_tile_to_zbuffer(x, y, tile_index, top_layer)
    -- print('add_tile_to_zbuffer(' .. x .. ', ' .. y .. ', ..)')
    if y < -2 or y > map_display_h then return end
    if tile_cols[x][y] == nil then tile_cols[x][y] = {} end
    if borders[x][y] == nil then borders[x][y] = {} end
    if tile_cols[x][y][1] and top_layer then bkg_fg_index = 2 end
    tile_cols[x][y][bkg_fg_index] = tile_index
    if tile_index < 2 then for dy = 1, 2 do
      if tile_cols[x][y + dy] == nil then tile_cols[x][y + dy] = {} end
      tile_cols[x][y + dy][bkg_fg_index] = -1  -- Indicate do-not-draw here.
    end end
    -- print('borders=' .. stringify(borders))
    -- print('borders[x]=' .. stringify(borders[x]))
    -- print('borders[x][y]=' .. stringify(borders[x][y]))
    borders[x][y][bkg_fg_index] = this_border
  end

  local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
  local hero_height = map_height(hx, hy)
  -- print('hero_height=' .. hero_height)
  for x = 0, map_display_w do
    -- print('x=' .. x)
    tile_cols[x] = {}
    borders[x] = {}
    bkg_fg_index = 1
    local y = 0
    local map_sprites_h = math.floor(map_display_h  / 3) + 1
    while y <= map_sprites_h or tile_cols[x][map_display_h] == nil do
      -- print('y=' .. y)
      -- print('tile_cols[' .. x .. '][' .. map_display_h .. ']=' .. type(tile_cols[x][map_display_h]))
      local map_x, map_y = math.floor(x + ul_corner_x), math.floor(y + ul_corner_y)
      local tile_index = map(map_x, map_y)
      local height = map_height(map_x, map_y)
      -- print('height=' .. height)
      local hdiff = height - hero_height
      this_border = get_border(map_x, map_y)
      -- print('hdiff=' .. hdiff)
      local screen_y = 3 * y - hdiff
      if y == 0 then
        -- tile_cols[x][y + hdiff] = tile_index
        local dy = 0
        while screen_y > 0 do
          dy = dy - 1
          hdiff = map_height(map_x, map_y + dy) - hero_height
          screen_y = 3 * y - hdiff
        end
        while dy <= 0 do
          -- print('dy=' .. dy)
          tile_index = map(map_x, map_y + dy)
          hdiff = map_height(map_x, map_y + dy) - hero_height
          this_border = get_border(map_x, map_y + dy)
          add_point_to_zbuffer(x, y + dy, tile_index, hdiff)
          dy = dy + 1
        end
      else
        local top_layer = (map_y > hy)
        add_point_to_zbuffer(x, y, tile_index, hdiff, top_layer)
      end
      y = y + 1
    end
  end
end

function love.keypressed(key, unicode)
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
      hero_map_x, hero_map_y - hero_anim_offset(),
      ul_corner_x + scroll_frame, ul_corner_y + scroll_frame,
      map_display_w - 2 * scroll_frame - 1, map_display_h / 3 - 2 * scroll_frame - 1)
  
  ul_corner_x = ul_corner_x + dx
  ul_corner_y = ul_corner_y + dy
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
