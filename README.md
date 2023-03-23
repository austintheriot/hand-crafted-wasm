## 2D Parametric Equations: 587 bytes

An amazing (and often beautiful) variety of unique 2-dimensional patterns can be discovered by graphing the following parametric equation: 
```
x = cos(At) + sin(Bt)
y = cos(Ct) + sin(Dt)
```
where `A`, `B`, `C`, and `D` are arbitrary constants, and `t` increments upward towards infinity on every frame. 

It's amazing how minute adjustments to `A`, `B`, `C`, and `D` (sometimes differing by only by 0.01) can produce wildly different results. It's important to note that although many examples in the gallery below give the illusion of 3D, they are entirely 2-dimensional.

Below you can find a live, editable demo as well as a gallery of interesting combinations I've found. If you come up with your own interesting pattern, I'd love to see it!

[See live demo](/parametric_equations/)

[See full gallery](/parametric_equations/gallery.html)

![Parametric Equations](/images/parametric_equations.png)

## 2D Perlin Noise Field: 1083 bytes

A rasterized perlin noise field rendered in WebAssembly. Uses a custom all-WebAssembly port of processing/p5.js' perlin noise implementation.

[See live demo](/noise_field/)

![Perlin Noise](/images/perlin_noise.png)

## 3D Particle Simulation - Lorenz System: 1200 bytes

3D particle simulation of the Lorenz strange attractor using 30,000 particles. Use arrow keys or drag/touch the window to change the camera position. All physics/3d projection code was written from scratch in WebAssembly and was inspired by ssloy's tinyrenderer: https://github.com/ssloy/tinyrenderer

[See live demo](/lorenz_system/)

![Lorenz System](/images/lorenz_system.png)

## 2D Conway's Game Of Life: 1240 bytes

An implementation of the classic Conway's Game Of Life, hand written in WebAssembly.

[See live demo](/life/)

![Conway's Game of Life](/images/conways_game_of_life.png)

## 2D Chaos Circle: 1898 bytes

An ever-contracting and expanding flower shape. Uses a custom all-WebAssembly port of processing/p5.js' perlin noise implementation.

[See live demo](/chaos_circle/)

![Chaos Circle](/images/chaos_circle.png)

## 3D Noise Cloud: 1988 bytes

3D particle waves. Use arrow keys or drag/touch the window to change the camera position. 

[See live demo](/noise_cloud)

![Noise Cloud](/images/noise_cloud.png)

## 3D Terrain/Water Generator: 2241-2775 bytes

3D Terrain Generator and 3D Water Emulator are two projects that draw heavily from one another. They both use Perlin noise for generating shapes and movement but in two different ways. 3D Terrain keeps each vertex "static" once it has been generated, whereas 3D Water generates a new random offset based on it's current location at every frame, creating a more dynamic randomized effect. For either project, use mouse or drag/touch the window to change camera position.

**Terrain: 2241 bytes**

[See live demo](/terrain)

![Terrain](/images/terrain.png)

**Water: 2288 bytes**

[See live demo](/water)

![Water](/images/water.png)

**Water (Low-fi/ASCII version): 2775 bytes**

[See live demo](/water_ascii)

![Water ASCII](/images/water_ascii.png)

## More

More demos coming soon!