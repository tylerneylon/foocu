--[[ draw.lua

     This holds foocu's main drawing function.
     Use it like this:

       local draw = require('draw')

       -- Later, when we want to draw to the screen:
       draw()

       -- To update drawing data based on map/hero data:
       draw.compute()

       -- This holds 'normal' or 'debug':
       draw.mode

  ]]


--[[ TODO
      * Make sure function descriptions are clear.
      * Learn the standard best practice for exporting functions in a table,
        and do that.
  ]]

local M = {}


-------------------------------------------------------------------------------
-- Public interface. Definitions are below.
-------------------------------------------------------------------------------

-- Draw the current map and hero data to the screen.
M.draw = function() end

-- Update the internal draw buffer. Call this after movement but before draw is
-- called again.
M.compute = function() end

-- The drawing mode. The alternative is 'debug'.
M.mode = 'normal'


-------------------------------------------------------------------------------
-- Singleton wrapper.
-------------------------------------------------------------------------------

local selfname = debug.getinfo(1).source
if not global_singleton then global_singleton = {} end
if global_singleton[selfname] then return global_singleton[selfname] end
global_singleton[selfname] = M


-------------------------------------------------------------------------------
-- Private parts.
-------------------------------------------------------------------------------

local shadow_debug_mode = false

-- For this function, the input sprite is an image.
-- This takes care of map_offset_{x,y} for sprites.
local function draw_sprite(sprite, x, y)
  love.graphics.draw(sprite, x * tile_w + map_offset_x, y * tile_h + map_offset_y)
end

-- The input x, y are in screen sprite coordinates.
local function draw_shadow(shadow, x, y)
  local x_size = 0.2  -- As a fraction of a (map) sprite.
  local x_start = 1.0 - x_size
  local y_size = 0.45
  local y_start = 1.0 - y_size

  love.graphics.setColor(0, 0, 0, 100)
  if shadow_debug_mode then love.graphics.setColor(0, 0, 255) end
  for i, s in ipairs(shadow) do
    local vertices = {}
    
    -- Accepts x, y in the range [0, 1] for the local sprite.
    function add_relative_pt(pt_x, pt_y)
      table.insert(vertices, (x + pt_x) * tile_w + map_offset_x)
      table.insert(vertices, (y + 3 * pt_y) * tile_h + map_offset_y)
    end
    function add_relative_pts(pts)
      for i = 1, #pts, 2 do add_relative_pt(pts[i], pts[i + 1]) end
    end

    if s == 0 then
      add_relative_pts({x_start, 0, 1, 0, 1, y_start, x_start, y_start})
    elseif s == 1 then
      add_relative_pts({x_start, 0, 1, 0, 1, 1, x_start, y_start})
    elseif s == 2 then
      add_relative_pts({0, y_start, x_start, y_start, x_start, 1, 0, 1})
    elseif s == 3 then
      add_relative_pts({0, y_start, x_start, y_start, 1, 1, 0, 1})
    elseif s == 4 then
      add_relative_pts({x_start, y_start, 1, y_start, 1, 1, x_start, 1})
    end

    if #vertices > 0 then
      love.graphics.polygon('fill', vertices)
    end
  end
  love.graphics.setColor(255, 255, 255)
end

-- The input x, y are in screen sprite coordinates.
local function draw_bordered_tile(tile_index, shadow, border, x, y)
  if tile_index == -1 then return end

  if not shadow_debug_mode then
    draw_sprite(tile[tile_index], x, y)
  end

  draw_shadow(shadow, x, y)

  -- Draw the border.
  love.graphics.setColor(0, 255, 0)

  -- I'll set things up so we draw in a clockwise fashion.
  local w, h = tile_w - 1, tile_h * 3 - 1
  local pts = {[0] = {0, h}, [1] = {0, 0}, [2] = {w, 0}, [3] = {w, h}}
  for i, border_code in ipairs(border) do
    local tx, ty = x * tile_w + map_offset_x, y * tile_h + map_offset_y
    local start, stop = border_code, (border_code + 1) % 4
    love.graphics.line(tx + pts[start][1], ty + pts[start][2],
                       tx + pts[stop][1], ty + pts[stop][2])
  end

  love.graphics.setColor(255, 255, 255)
end

-- As the name implies, the inputs are in map sprite coordinates.
local function draw_rect_at_map_point(x, y)
  -- print_if_moved('draw_rect_at_map_point(' .. x .. ', ' .. y .. ')')
  local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
  local hero_height = map_height(hx, hy)
  local hdiff = map_height(x, y) - hero_height

  local ex, ey = x, y - hdiff / 3  -- e is for effective, meaning adjusted for height.
  -- print_if_moved('(ex, ey) = (' .. ex .. ', ' .. ey .. ')')

  love.graphics.rectangle(
      'line',
      (ex - ul_corner_x) * tile_w + map_offset_x,
      (ey - ul_corner_y) * 3 * tile_h + map_offset_y,
      tile_w,
      tile_h * 3)
end

-- Accepts either 'background' or 'foreground' for the layer_name.
local function draw_map_layer(layer_name)
  local is_top_layer = (layer_name == 'foreground')

  for y = -2, map_display_h + 2 do
    for x = 0, map_display_w do
      local layers = tile_cols[x][y]
      if layers ~= nil then
        local border_layers = borders[x][y]
        local shadow_layers = shadows[x][y]
        if border_layers == nil then border_layers = {nil, nil} end
        if shadow_layers == nil then shadow_layers = {nil, nil} end
        local tile_index = layers[1]
        local border = border_layers[1]
        local shadow = shadow_layers[1]
        if tile_index == nil then
          tile_index = layers[2]
          border = border_layers[2]
          shadow = shadow_layers[2]
        end
        if tile_index == nil then
          print('Error: both layers are nil at x=' .. x .. ' y=' .. y)
        end

        -- Convert the offset from map to screen coordinates.
        local offset_x = math.floor(ul_corner_x) - ul_corner_x
        local offset_y = (math.floor(ul_corner_y) - ul_corner_y) * 3

        if not is_top_layer then
          draw_bordered_tile(tile_index, shadow, border, x + offset_x, y + offset_y)
        else
          if layers[1] and layers[2] then
            --[[ The original system was designed to make this a transparent
                 overlay. However, the original system looked bad. I need to
                 redesign the transparency system, and for now I'll just draw
                 everything opaque. ]]
            -- love.graphics.setColor(255, 255, 255, 100)
            draw_bordered_tile(layers[2], shadow_layers[2], border_layers[2],
                               x + offset_x, y + offset_y)
            -- love.graphics.setColor(255, 255, 255, 255)
          end
        end
      end
    end
  end
end

-- TODO Make these all local, and declare them at the start of the file?
-- Variables used for climb/fall animations.
pending_xy_delta = nil  -- This will have the form {dx, dy}, pre-multiplied by dt and speed.
pending_anim_time_left = 0
pending_hdiff = 0
anim_duration = 0.08

-- For a fall, this will go from N down to 0. (Always non-negative.)
-- For a climb, this will go from 0 up to N.  (Always non-negative.)
-- I expect it to be used to draw the hero as something like:
--   drawn_y = standing_still_y - hero_anim_offset()
local function hero_anim_offset()
  local perc_left = pending_anim_time_left / anim_duration
  if pending_hdiff < 0 then
    return pending_hdiff * -1 * perc_left
  elseif pending_hdiff > 0 then
    return pending_hdiff * (1 - perc_left)
  else
    return 0
  end
end

-- Draw the hero and debug outlines.
local function draw_hero()
  if mode == 'debug' then
    local debug_alpha = 90
    local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
    local bx, by = math.floor(hero_map_x), math.floor(hero_map_y + 0.3)
    love.graphics.setColor(0, 0, 255, debug_alpha)  -- Blue.
    for dx = 0, 1 do for dy = 0, 1 do  -- This syntax is not an accident. I like it, ok?
      draw_rect_at_map_point(bx + dx, by + dy)
    end end
    love.graphics.setColor(255, 255, 255, debug_alpha)
    draw_rect_at_map_point(hx, hy)
    love.graphics.setColor(255, 255, 255)
  end
  -- The - 1 is to account for the double-height of the hero sprite. We want to draw
  -- his feet on the square were we count him as.
  draw_sprite(hero[hero_sprite], hero_map_x - ul_corner_x, (hero_map_y - ul_corner_y) * 3 - 1 - hero_anim_offset())
end

-- Draw the border. Eventually I plan for this to have status info.
local function draw_border()
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

--[[ Returns a list of elements from (0, 1, 2, 3) indicating which borders
     should be drawn for the given tile. The border numbers are set up like so:
          ---1---
         |       |
         0       2
         |       |
          ---3---
     This way, we can look at b%2 and b//2 to concisely know what to draw.
  ]]
local function get_border(map_x, map_y)
  local h = map_height(map_x, map_y)
  local border = {}
  local dirs = {{-1, 0}, {0, -1}, {1, 0}, {0, 1}}
  for i, dir in ipairs(dirs) do
    local other_h = map_height(map_x + dir[1], map_y + dir[2])
    if other_h ~= h then table.insert(border, i - 1) end
  end
  return border
end

--[[ Returns a list of shadows to draw, with values indicating these shapes:
     --   --
     ||   ||
     __   \-  |---_   |---\   r (small square in LR corner)
     0    1   2       3       4

     (0 and 2 don't include 4, so those can be drawn independently)

     In the future, I envision possibly having zbuffers simply point back to
     map_xy locations, which would simplify the zbuffer-and-friends data
     structure. If this and get_border calls are taking up time, I could also
     cache results with the map.

     Also this is built for max-1-height changes which is NOT at all what I
     want in the long run. TODO Handle shadows more generally, but still not
     in true 3d.
  ]]
local function get_shadow(map_x, map_y)
  local h = map_height(map_x, map_y)
  local right_is_higher = map_height(map_x + 1, map_y) > h
  local down_is_higher = map_height(map_x, map_y + 1) > h
  local dr_is_higher = map_height(map_x + 1, map_y + 1) > h
  local shadow = {}
  if right_is_higher then
    if dr_is_higher then
      table.insert(shadow, 0)
    else
      table.insert(shadow, 1)
    end
  end
  if down_is_higher then
    if dr_is_higher then
      table.insert(shadow, 2)
    else
      table.insert(shadow, 3)
    end
  end
  if dr_is_higher then
    table.insert(shadow, 4)
  end
  if right_is_higher and down_is_higher then
    -- This is a special case where dr_is_higher doesn't matter.
    shadow = {0, 2, 4}
  end
  return shadow
end

local function recalc_zbuffer()
  -- Reset the zbuffer, which we call tile_cols. I could rename either
  -- this function or the variable so it's more obvious they refer to the same thing.
  -- tile_cols[col#][row#] = {bkg_tile, fg_tile} or just {bkg_tile}.
  tile_cols = {}
  borders = {}
  shadows = {}

  -- Variables to be used in the functions below.
  local last_hdiff = nil
  local bkg_fg_index = 1
  local this_border = nil
  local this_shadow = nil

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
      -- This loop is not (last_hdiff - 1) because last time base_y was 1 lower.
      for hd = hdiff + 1, last_hdiff do
        add_tile_to_zbuffer(base_x, 3 * base_y - hd, 2, top_layer)
      end
    end
    last_hdiff = hdiff
  end

  function add_tile_to_zbuffer(x, y, tile_index, top_layer)
    -- print('add_tile_to_zbuffer(' .. x .. ', ' .. y .. ', ..)')
    if y < -2 or y > map_display_h + 2 then return end
    if tile_cols[x][y] == nil then tile_cols[x][y] = {} end
    if borders[x][y] == nil then borders[x][y] = {} end
    if shadows[x][y] == nil then shadows[x][y] = {} end
    if tile_cols[x][y][1] and top_layer then bkg_fg_index = 2 end
    tile_cols[x][y][bkg_fg_index] = tile_index
    if tile_index < 2 then for dy = 1, 2 do
      if tile_cols[x][y + dy] == nil then tile_cols[x][y + dy] = {} end
      tile_cols[x][y + dy][bkg_fg_index] = -1  -- Indicate do-not-draw here.
    end end
    -- print('borders=' .. stringify(borders))
    -- print('borders[x]=' .. stringify(borders[x]))
    -- print('borders[x][y]=' .. stringify(borders[x][y]))
    local b, s = this_border, this_shadow
    if tile_index == 2 then b, s = {}, {} end
    borders[x][y][bkg_fg_index] = b
    shadows[x][y][bkg_fg_index] = s
  end

  local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
  local hero_height = map_height(hx, hy)
  -- print('hero_height=' .. hero_height)
  for x = 0, map_display_w do
    -- print('x=' .. x)
    tile_cols[x] = {}
    borders[x] = {}
    shadows[x] = {}
    bkg_fg_index = 1
    local y = 0
    local map_sprites_h = math.floor(map_display_h  / 3) + 1
    while y <= map_sprites_h or tile_cols[x][map_display_h + 2] == nil do
      -- print('y=' .. y)
      -- print('tile_cols[' .. x .. '][' .. map_display_h .. ']=' .. type(tile_cols[x][map_display_h]))
      local map_x, map_y = math.floor(x + ul_corner_x), math.floor(y + ul_corner_y)
      local tile_index = map(map_x, map_y)
      local height = map_height(map_x, map_y)
      -- print('height=' .. height)
      local hdiff = height - hero_height
      this_border = get_border(map_x, map_y)
      this_shadow = get_shadow(map_x, map_y)
      -- print('(' .. x .. ', ' .. y .. '): (shadow) ' .. stringify(this_shadow))
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

-- Returns the smallest dx, dy so that (px - dx, py - dy) is inside the rect.
local function delta_from_rect(px, py, rect_x, rect_y, rect_w, rect_h)
  local dx, dy = 0, 0
  local end_x, end_y = rect_x + rect_w, rect_y + rect_h

  if px < rect_x then dx = px - rect_x end
  if px > end_x then dx = px - end_x end
  if py < rect_y then dy = py - rect_y end
  if py > end_y then dy = py - end_y end

  return dx, dy
end

local function scroll_if_needed()
  -- The - 1 in the width and height are to account for the sprite used
  -- up by the hero sprite itself.  We wouldn't need that - 1 if the
  -- hero were just a single point.
  local dx, dy = delta_from_rect(
      hero_map_x, hero_map_y - hero_anim_offset() / 3,
      ul_corner_x + scroll_frame, ul_corner_y + scroll_frame,
      map_display_w - 2 * scroll_frame - 1, map_display_h / 3 - 2 * scroll_frame - 1)
  
  ul_corner_x = ul_corner_x + dx
  ul_corner_y = ul_corner_y + dy
end

local function draw_debug_text_if_in_debug_mode()
  local y = 5
  love.graphics.print(M.mode .. ' mode', 10, y)
  if M.mode == 'debug' then
    local location_str = string.format('(%.2f, %.2f)', hero_map_x, hero_map_y)
    love.graphics.print(location_str, 100, y)
  end
end

-------------------------------------------------------------------------------
-- Public function definitions.
-------------------------------------------------------------------------------

M.draw = function()
  draw_map_layer('background')
  draw_hero()
  draw_map_layer('foreground')
  draw_border()
  draw_debug_text_if_in_debug_mode()
end

M.compute = function()
  scroll_if_needed()
  recalc_zbuffer()
end


return M
