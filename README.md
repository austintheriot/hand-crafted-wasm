# Raw WebAssembly

## Plotting 2D Curves: 530 bytes

An amazing variety of unique 2-dimensional shapes can be plotted by minute adjustments to the constants A, B, C, D when plotting the following: 
```
x = cos(At) + sin(Bt)
y = cos(Ct) + sin(Dt)
```
where t increments toward infinity on every frame.

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/plotting_curves/)

[See full gallery](https://austintheriot.github.io/hand-crafted-wasm/src/plotting_curves/gallery.html)

![Plotting curves](/images/plotting_curves.png)

## 2D Perlin Noise Field: 1083 bytes

A rasterized perlin noise field rendered in WebAssembly. Uses a custom all-WebAssembly port of processing/p5.js' perlin noise implementation.

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/noise_field/)

![Perlin Noise](/images/perlin_noise.png)

## 3D Particle Simulation - Lorenz System: 1200 bytes

3D particle simulation of the Lorenz strange attractor using 30,000 particles. Use arrow keys or drag/touch the window to change the camera position. All physics/3d projection code was written from scratch in WebAssembly and was inspired by ssloy's tinyrenderer: https://github.com/ssloy/tinyrenderer

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/lorenz_system/)

![Lorenz System](/images/lorenz_system.png)

## 2D Conway's Game Of Life: 1240 bytes

An implementation of the classic Conway's Game Of Life, hand written in WebAssembly.

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/life/)

![Conway's Game of Life](/images/conways_game_of_life.png)

## 3D Noise Waves: 1755 bytes

3D particle waves. Use arrow keys or drag/touch the window to change the camera position. 

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/noise_waves)

![Noise Waves](/images/noise_waves.png)

## 2D Chaos Circle: 1898 bytes

An ever-contracting and expanding flower shape. Uses a custom all-WebAssembly port of processing/p5.js' perlin noise implementation.

[See live demo](https://austintheriot.github.io/hand-crafted-wasm/src/chaos_circle/)

![Chaos Circle](/images/chaos_circle.png)

## More

More demos coming soon!