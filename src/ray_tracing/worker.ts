const init = ({ windowInnerWidth, windowInnerHeight, sharedMemory, uid }) => {
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
      } = await WebAssembly.instantiate(bytes1, { console: console as any, Math: Math as any });

      // ray_tracing
      return WebAssembly.instantiate(bytes2, {
        noise: { perlin_noise },
        Math: Math as any,
        console: console as any,
        error: { throw: throwError },
        Date: Date as any,
        memory: { sharedMemory },
      });
    })
    .then(({ instance: { exports: wasm } }) => {
      wasm.init(windowInnerWidth, windowInnerHeight);
      wasm.tick();

      const res = {
        type: "renderComplete",
        canvasWidth: wasm.canvas_width.value,
        canvasHeight: wasm.canvas_height.value,
        canvasDataPtr: wasm.canvas_data_ptr.value,
        canvasDataLen: wasm.canvas_data_len.value,
        uid: uid,
      };
      console.log({ res })
      postMessage(res);
    })
    .catch((e) => console.error(e));
};

onmessage = (e) => {
  console.log("message received in worker: ", { e });
  const { type } = e.data;

  switch (type) {
    case "start":
      {
        const { sharedMemory } = e.data;
        const array = new Uint8Array(sharedMemory.buffer);
        let value = Atomics.load(array, 0);
        console.log("First value from worker before render: ", {
          sharedMemory,
          array,
          value,
        });
        init(e.data);
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
