-- Three-space indents?!? wut. this is from a tutorial.

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
  --print('from '..x..','..y..' got v='..v)
  return rand_next(rand_next(v)) % 2
end

function love.load()

  -- our tiles
  tile = {}
  for i = 0, 1 do
     tile[i] = love.graphics.newImage( "img/tile"..i..".png" )
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
  clock = 0

  print("hi command line")
  for key, value in pairs(_G) do
    print(key, value)
  end
end

function love.draw()
  draw_map()
  -- love.graphics.print('Hello World!', 400, 300)
end

function love.keypressed(key, unicode)
   if key == 'up' then
      map_y = map_y-1
      --if map_y < 0 then map_y = 0; end
   end
   if key == 'down' then
      map_y = map_y+1
      --if map_y > map_h-map_display_h then map_y = map_h-map_display_h; end
   end
   
   if key == 'left' then
      map_x = map_x - 1
      --map_x = math.max(map_x-1, 0)
   end
   if key == 'right' then
      map_x = map_x + 1
      --map_x = math.min(map_x+1, map_w-map_display_w)
   end

   clock = clock + 1
end

function draw_map()
   for y=1, map_display_h do
      for x=1, map_display_w do
         love.graphics.draw( 
            tile[map(x + map_x, y + map_y)], 
            (x*tile_w)+map_offset_x, 
            (y*tile_h)+map_offset_y )
      end
   end

   mid_x, mid_y = map_display_w / 2, map_display_h / 2
   love.graphics.draw(
       hero[clock % 2],
       mid_x * tile_w + map_offset_x,
       mid_y * tile_h + map_offset_y)

end
