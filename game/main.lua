--[[ main.lua

     The main module for the 2d action/rpg game foocu.
  ]]

require('control')
require('draw')
require('map')
require('setup')
require('util')

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

function love.load()
  init()  -- Defined in setup.lua.
end

function love.draw()
  draw_map()  -- Defined in draw.lua.
end

function love.update(dt)
  update(dt)  -- Defined in control.lua.
end

function love.keypressed(key)
  keypressed(key)
end
