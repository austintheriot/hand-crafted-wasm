const init = (windowInnerWidth, windowInnerHeight, sharedMemory) => {
  const throwError = (errorCode) => {
    console.error("Error occurred during execution:", { errorCode });
  };

  Promise.all([
    fetch("../perlin_noise/perlin_noise_optimized.wasm"),
    fetch("./ray_tracing_optimized.wasm"),
  ])
    .then(([res1, res2]) =>
      Promise.all([res1.arrayBuffer(), res2.arrayBuffer()])
    )
    .then(async ([bytes1, bytes2]) => {
      // perlin noise
      const {
        instance: {
          exports: { perlin_noise },
        },
      } = await WebAssembly.instantiate(bytes1, { console, Math });

      // ray_tracing
      return WebAssembly.instantiate(bytes2, {
        noise: { perlin_noise },
        Math,
        console,
        error: { throw: throwError },
        Date,
        memory: { sharedMemory },
      });
    })
    .then(({ instance: { exports: wasm } }) => {
      wasm.init(windowInnerWidth, windowInnerHeight);
      wasm.tick();
      postMessage({
        type: "renderComplete",
        canvasWidth: wasm.canvas_width.value,
        canvasHeight: wasm.canvas_height.value,
        canvasDataPtr: wasm.canvas_data_ptr.value,
        canvasDataLen: wasm.canvas_data_len.value,
      });
    })
    .catch((e) => console.error(e));
};

onmessage = (e) => {
  console.log("message received in worker: ", { e });
  const { type } = e.data;

  switch (type) {
    case "start":
      {
        const { windowInnerWidth, windowInnerHeight, sharedMemory } = e.data;
        const array = new Uint8Array(sharedMemory.buffer);
        let value = Atomics.load(array, 0);
        console.log("First value from worker before render: ", {
          sharedMemory,
          array,
          value,
        });
        init(windowInnerWidth, windowInnerHeight, sharedMemory);
        value = Atomics.load(array, 0);
        console.log("First value from worker after render: ", {
          sharedMemory,
          array,
          value,
        });
      }
      break;
  }
};
