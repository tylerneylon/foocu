--[[ control.lua

     Functions for working with user input, for foocu.
  ]]

function update(dt)
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

  -- print_if_moved('dt=' .. dt)
  -- print_if_moved('ul_corner = (' .. ul_corner_x .. ', ' .. ul_corner_y .. ')')
  -- print_if_moved('hero_map = (' .. hero_map_x .. ', ' .. hero_map_y .. ')')
end


