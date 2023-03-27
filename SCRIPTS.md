# Scripts

## Overview

A typical workflow looks like this:\

- Create a .html and .wat file
- Build the compiled/optimized .wasm filed as you work on the .wat file
- When ready, copy the contents of /src into a /dist folder and compile the Readme into an index.html file
- Open up a live server locally to see results

## Examples

Optimizing a compiled binary file:

```sh
wasm-opt src/ray_tracing/ray_tracing.wasm -all -O2 -o src/ray_tracing/ray_tracing_optimized.wasm
```

Build all wasm binaries and then optimize specific binary:

```sh
# debugging is easier when optimizing from the debug version of the binary
npm run build-wasm:debug && wasm-opt src/ray_tracing/ray_tracing_debug.wasm -all -O2 -o src/ray_tracing/ray_tracing_optimized.wasm
```

Build all wasm binaries, optimize specific binary, and copy into dist for viewing:

```sh
# debugging is easier when optimizing from the debug version of the binary
npm run build-wasm:debug && wasm-opt src/ray_tracing/ray_tracing_debug.wasm -all -O2 -o src/ray_tracing/ray_tracing_optimized.wasm && npm run build
```

Assembling .wat to debug .wasm via binaryen:

```sh
wasm-as src/ray_tracing/ray_tracing.wat -o src/ray_tracing/ray_tracing.wasm --debuginfo -all --debug
```

Assemblin .wat to debug .wasm via wabt (this is useful for debugging files):

```sh
wat2wasm src/ray_tracing/ray_tracing.wat -o src/ray_tracing/ray_tracing.wasm --debug-parser --enable-all --debug-names
```
