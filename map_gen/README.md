# Map generation.

This directory contains experimental code to help me
find good ways to randomly generate an infinite world.

I am inspired by the work of Amit Patel here:

http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/

but my goal is a bit different. Amit is basically doing a one-time
render of data that can be saved so that at runtime it's easy to access
quickly. My goal is an infinite world, so that pre-rendering is not
an option. Instead, I'd like an algorithm that can basically take an
(x, y) coordinate and a random seed, and quickly deterministically return
the information about that coordinate, such as elevation, biome, and
block type (grass, sand, bushes, trail, etc).

The tricky part to that is making the elevation mostly smooth, and having
biome areas that make sense. Overall, the land needs to feel natural and
continuous in its properties, although it is never computed as a whole.

## Elevation

### Idea 1 - Perlin noise

I think I can use a Perlin noise algorithm to generate random elevations
infinitely and efficiently.

There are two perspectives:

1. For a diminishing amplitude and block size, randomly create a series of smooth
   elevation functions. Add those together, and the result is the continuous
   and natural-seeming Perlin noise.
2. For any given point, to compute the elevation quickly, we just need to know
   which blocks it is in for each of the component elevation functions, and
   add those up. For example, if our amplitudes are chosen as powers of 2,
   64 down to 1, then we have 7 elevation functions to add up, so we need to
   compute that many values to add up.

I am leaving out a lot of details here, but default 2d Perlin noise is based
on overlapping square grids, and that leads me to idea 2.

### Idea 2 - Improve the edges

One weakness I see in the first idea is that it may have some vaguely
boxy artifacts since the blocks are all squares. In particular,
the largest elevation function is a series of flat squares when seen from
above, and I suspect the result will look slightly less natural because
all the elevation fuctions have fold lines parallel to the axes.

An idea to improve this is to use permutahedron simplices. Intuitively,
each random point is at the center of a regular hexagon, so that the planes become
equilateral triangles. Just for kicks, we could also randomly translate
and rotate the different component elevation functions. This would avoid
alignment or overlap of the fold lines.

### Procedure

My current plan is to implement ideas 1 and 2, both with a
sum-first and sum-lazily algorithm. Unless there is a bug, the sum-first
and sum-lazily results should be identical. I expect the typical output
of idea 1 to be different from that of idea 2, with idea 2 output
appearing slightly more natural. I'll code these up and examine
the results.

I could also implement idea 2 with and without the random translations
and rotations to see how those affect the final output.

#### Code design

I changed my mind about generating each image twice. I'll generate all
of them once using per-point calculations.

I'll make three images:

* Idea 1 = basic Perlin.
* Idea 2 less fancy = Perlin on triangles
* Idea 3 more fancy = Perlin on triangles with trans and rotation

