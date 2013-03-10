--[[ setup.lua

     Initialization for foocu.
  ]]

function init()
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

  --[[ Use this to check startup globals.
  for key, value in pairs(_G) do
    print(key, value)
  end
  ]]
end
