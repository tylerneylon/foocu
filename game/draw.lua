--[[ TODO
      * Make sure function descriptions are clear.
      * Learn the standard best practice for exporting functions in a table,
        and do that.
  ]]

-- For this function, the input sprite is an image.
-- This takes care of map_offset_{x,y} for sprites.
function draw_sprite(sprite, x, y)
  love.graphics.draw(sprite, x * tile_w + map_offset_x, y * tile_h + map_offset_y)
end

-- The input x, y are in screen sprite coordinates.
function draw_bordered_tile(tile_index, border, x, y)
  if tile_index == -1 then return end

  draw_sprite(tile[tile_index], x, y)
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
function draw_rect_at_map_point(x, y)
  print_if_moved('draw_rect_at_map_point(' .. x .. ', ' .. y .. ')')
  local hx, hy = math.floor(hero_map_x + 0.5), math.floor(hero_map_y + 0.8)
  local hero_height = map_height(hx, hy)
  local hdiff = map_height(x, y) - hero_height

  local ex, ey = x, y - hdiff / 3  -- e is for effective, meaning adjusted for height.
  print_if_moved('(ex, ey) = (' .. ex .. ', ' .. ey .. ')')

  love.graphics.rectangle(
      'line',
      (ex - ul_corner_x) * tile_w + map_offset_x,
      (ey - ul_corner_y) * 3 * tile_h + map_offset_y,
      tile_w,
      tile_h * 3)
end

-- Accepts either 'background' or 'foreground' for the layer_name.
function draw_map_layer(layer_name)
  local is_top_layer = (layer_name == 'foreground')

  for y = 0, map_display_h do
    for x = 0, map_display_w do
      local layers = tile_cols[x][y]
      if layers == nil then
        print('nil layers at x=' .. x .. ', y=' .. y)
      end
      local border_layers = borders[x][y]
      if border_layers == nil then border_layers = {nil, nil} end
      local tile_index = layers[1]
      local border = border_layers[1]
      if tile_index == nil then
        tile_index = layers[2]
        border = border_layers[2]
      end
      if tile_index == nil then
        print('Error: both layers are nil at x=' .. x .. ' y=' .. y)
      end

      -- Convert the offset from map to screen coordinates.
      local offset_x = math.floor(ul_corner_x) - ul_corner_x
      local offset_y = (math.floor(ul_corner_y) - ul_corner_y) * 3

      if not is_top_layer then
        draw_bordered_tile(tile_index, border, x + offset_x, y + offset_y)
      else
        if layers[1] and layers[2] then
          -- This is a transparent overlay.
          love.graphics.setColor(255, 255, 255, 100)
          draw_bordered_tile(layers[2], border_layers[2], x + offset_x, y + offset_y)
          love.graphics.setColor(255, 255, 255, 255)
        end
      end
    end
  end
end

function draw_map()
  draw_map_layer('background')

  -- Draw the hero and debug outlines.
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
  -- The - 1 is to account for the double-height of the hero sprite. We want to draw
  -- his feet on the square were we count him as.
  draw_sprite(hero[hero_sprite], hero_map_x - ul_corner_x, (hero_map_y - ul_corner_y) * 3 - 1 - hero_anim_offset())

  draw_map_layer('foreground')

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

