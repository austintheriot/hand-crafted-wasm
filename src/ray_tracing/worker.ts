interface RayTracingExports {
  canvas_width: {
    value: number;
  };
  canvas_height: {
    value: number;
  };
  canvas_data_ptr: {
    value: number;
  };
  canvas_data_len: {
    value: number;
  };
  init(windowInnerWidth: number, windowInnerHeight: number): void;
  tick(): void;
}

let wasm: RayTracingExports;

const getWasmGlobals = () => ({
  canvasWidth: wasm.canvas_width.value,
  canvasHeight: wasm.canvas_height.value,
  canvasDataPtr: wasm.canvas_data_ptr.value,
  canvasDataLen: wasm.canvas_data_len.value,
});

const init = async ({
  windowInnerWidth,
  windowInnerHeight,
  sharedMemory,
  uid,
}) => {
  const throwError = (errorCode) => {
    console.error("Error occurred during execution:", { errorCode });
  };

  const wasmRes = await fetch("./ray_tracing_optimized.wasm");

  // ray_tracing
  const {
    instance: { exports: wasmExports },
  } = await WebAssembly.instantiateStreaming(wasmRes, {
    Math: Math as any,
    console: console as any,
    error: { throw: throwError },
    Date: Date as any,
    memory: { sharedMemory },
  });

  // make available globally
  wasm = wasmExports as any;

  wasm.init(windowInnerWidth, windowInnerHeight);

  postMessage({
    type: "tickComplete",
    ...getWasmGlobals(),
    uid: uid,
  });
};

const tick = ({ uid }) => {
  wasm.tick();

  postMessage({
    type: "tickComplete",
    ...getWasmGlobals(),
    uid: uid,
  });
};

onmessage = (e) => {
  const { type } = e.data;

  switch (type) {
    case "init":
      init(e.data);
      break;
    case "tick":
      tick(e.data);
      break;
  }
};
