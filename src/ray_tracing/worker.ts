export interface RayTracingExports {
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
  right_stick_x_position: {
    value: number;
  };
  right_stick_y_position: {
    value: number;
  };
  left_stick_x_position: {
    value: number;
  };
  left_stick_y_position: {
    value: number;
  };
  left_stick_z_position: {
    value: number;
  };
  canvas_max_data_len: {
    value: number;
  };
  init(windowInnerWidth: number, windowInnerHeight: number): void;
  sync_viewport(windowInnerWidth: number, windowInnerHeight: number): void;
  tick(memIndexStart: number, memIndexEnd: number ): void;
}

export interface WorkerToMainGlobals {
  canvasWidth: number;
  canvasHeight: number;
  canvasDataPtr: number;
  canvasDataLen: number;
  rightStickXPosition: number;
  rightStickYPosition: number;
  leftStickyXPosition: number;
  leftStickYPosition: number;
  leftStickZPosition: number;
  canvasMaxDataLen: number;
  init(windowInnerWidth: number, windowInnerHeight: number): void;
  sync_viewport(windowInnerWidth: number, windowInnerHeight: number): void;
  tick(): void;
}

let wasm: RayTracingExports;

const getWasmGlobals = () => ({
  canvasWidth: wasm.canvas_width.value,
  canvasHeight: wasm.canvas_height.value,
  canvasDataPtr: wasm.canvas_data_ptr.value,
  canvasDataLen: wasm.canvas_data_len.value,
  canvasMaxDataLen: wasm.canvas_max_data_len.value,
  rightStickXPosition: wasm.right_stick_x_position.value,
  rightStickYPosition: wasm.right_stick_y_position.value,
  leftStickyXPosition: wasm.left_stick_x_position.value,
  leftStickYPosition: wasm.left_stick_y_position.value,
  leftStickZPosition: wasm.left_stick_z_position.value,
});

const init = async ({
  windowInnerWidth,
  windowInnerHeight,
  sharedMemory,
  uid,
  WorkerToMainMessageTypes,
}: {
  WorkerToMainMessageTypes: any;
  uid: BigInt;
  windowInnerWidth: number;
  windowInnerHeight: number;
  sharedMemory: any;
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
    type: WorkerToMainMessageTypes.INIT_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const tick = ({ uid, WorkerToMainMessageTypes, memIndexStart, memIndexEnd }) => {
  wasm.tick(memIndexStart, memIndexEnd);

  postMessage({
    type: WorkerToMainMessageTypes.TICK_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const syncViewport = ({
  uid,
  windowInnerWidth,
  windowInnerHeight,
  WorkerToMainMessageTypes,
}) => {
  wasm.sync_viewport(windowInnerWidth, windowInnerHeight);

  postMessage({
    type: WorkerToMainMessageTypes.SYNC_VIEWPORT_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleTouchMove = ({
  uid,
  WorkerToMainMessageTypes,
  px,
  py,
  side,
}: {
  uid: BigInt;
  px: number;
  py: number;
  side: "left" | "right";
  WorkerToMainMessageTypes: any;
}) => {
  wasm[`${side}_stick_y_position`].value = -py;
  wasm[`${side}_stick_x_position`].value = px;

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_TOUCH_MOVE_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleMouseMove = ({
  uid,
  WorkerToMainMessageTypes,
  x,
  y,
}: {
  uid: BigInt;
  x: number;
  y: number;
  WorkerToMainMessageTypes: any;
}) => {
  wasm.right_stick_x_position.value = x;
  wasm.right_stick_y_position.value = -y;

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_MOUSE_MOVE_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleKey = ({
  uid,
  direction,
  amount,
  WorkerToMainMessageTypes,
}: {
  uid: BigInt;
  direction: "x" | "y" | "z";
  amount: number;
  WorkerToMainMessageTypes: any;
}) => {
  switch (direction) {
    case "x":
      wasm.left_stick_x_position.value += amount;
      break;
    case "y":
      wasm.left_stick_y_position.value += amount;
      break;
    case "z":
      wasm.left_stick_z_position.value += amount;
      break;
  }

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_KEY_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleBlur = ({
  uid,
  WorkerToMainMessageTypes,
}: {
  uid: BigInt;
  WorkerToMainMessageTypes: any;
}) => {
  wasm.left_stick_x_position.value = 0;
  wasm.left_stick_y_position.value = 0;
  wasm.left_stick_z_position.value = 0;

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_BLUR_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleMouseUp = ({
  uid,
  WorkerToMainMessageTypes,
}: {
  uid: BigInt;
  WorkerToMainMessageTypes: any;
}) => {
  wasm.right_stick_x_position.value = 0;
  wasm.right_stick_y_position.value = 0;

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_MOUSE_UP_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

const handleTouchEnd = ({
  uid,
  side,
  WorkerToMainMessageTypes,
}: {
  uid: BigInt;
  side: "left" | "right";
  WorkerToMainMessageTypes: any;
}) => {
  wasm[`${side}_stick_y_position`].value = 0;
  wasm[`${side}_stick_x_position`].value = 0;

  postMessage({
    type: WorkerToMainMessageTypes.HANDLE_TOUCH_END_DONE,
    ...getWasmGlobals(),
    uid: uid,
  });
};

onmessage = async (e) => {
  const { type } = e.data;
  const { MainToWorkerMessageTypes, WorkerToMainMessageTypes } = await import(
    "./messages"
  );

  switch (type) {
    case MainToWorkerMessageTypes.INIT:
      init({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.TICK:
      tick({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.SYNC_VIEWPORT:
      syncViewport({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_TOUCH_MOVE:
      handleTouchMove({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_KEY:
      handleKey({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_BLUR:
      handleBlur({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_MOUSE_UP:
      handleMouseUp({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_TOUCH_END:
      handleTouchEnd({ ...e.data, WorkerToMainMessageTypes });
      break;
    case MainToWorkerMessageTypes.HANDLE_MOUSE_MOVE:
      handleMouseMove({ ...e.data, WorkerToMainMessageTypes });
      break;
  }
};
