import { MainToWorkerMessageTypes } from "./messages";
import { PromisifyWorker } from "./promisifyWorker";
import { WorkerToMainGlobals } from "./worker";

const canvas = document.querySelector("canvas") as HTMLCanvasElement;
const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
const leftStickButton = document.querySelector(
  ".left-stick"
) as HTMLButtonElement;
const leftThumbLocationIndicatorButton = document.querySelector(
  ".left-thumb-location-indicator"
) as HTMLDivElement;
const rightStickButton = document.querySelector(
  ".right-stick"
) as HTMLButtonElement;
const rightThumbLocationIndicatorButton = document.querySelector(
  ".right-thumb-location-indicator"
) as HTMLDivElement;

main();

async function main() {
  (window as any).coi = {
    // // A function that is run to decide whether to register the SW or not.
    // You could for instance make this return a value based on whether you actually need to be cross origin isolated or not.
    shouldRegister: () => true,
    // If this function returns true, any existing service worker will be deregistered (and nothing else will happen).
    shouldDeregister: () => false,
    // A function that is run to decide whether to use "Cross-Origin-Embedder-Policy: credentialless" or not.
    // See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy#browser_compatibility
    coepCredentialless: () =>
      !(navigator.userAgent.indexOf("CriOS") > -1 || !(window as any).chrome),
    // Override this if you want to prompt the user and do reload at your own leisure. Maybe show the user a message saying:
    // "Click OK to refresh the page to enable <...>"
    doReload: () => window.location.reload(),
    // Set to true if you don't want coi to log anything to the console.
    quiet: false,
  };

  const NUM_WORKERS = 16;
  const workers = new Array(NUM_WORKERS)
    .fill(null)
    .map(() => new PromisifyWorker("worker.ts"));

  const sharedMemory = new WebAssembly.Memory({
    shared: true,
    initial: 2000,
    maximum: 2000,
  });

  const render = async ({
    canvasDataPtr,
    canvasDataLen,
    canvasWidth,
    canvasHeight,
  }) => {
    // sync viewport with webassembly canvas
    if (canvas.width != canvasWidth) {
      canvas.width = canvasWidth;
    }
    if (canvas.height != canvasHeight) {
      canvas.height = canvasHeight;
    }

    // get reference to canvas image data in wasm's linear memory
    const canvasData = new Uint8Array(
      sharedMemory.buffer,
      canvasDataPtr,
      canvasDataLen
    );

    // transform wasm linear memory to image data
    const imageData = ctx.createImageData(canvasWidth, canvasHeight);
    imageData.data.set(canvasData);

    // load image data onto canvas
    ctx.putImageData(imageData, 0, 0);
  };

  let [globals] = (await Promise.all(
    workers.map((worker) =>
      worker.postMessage({
        type: MainToWorkerMessageTypes.INIT,
        windowInnerWidth: window.innerWidth,
        windowInnerHeight: window.innerHeight,
        sharedMemory,
      })
    )
  )) as WorkerToMainGlobals[];

  workers.forEach(addListeners);
  
  /**
   * Creates list of windows into wasm linear memory to give each worker:
   * @example
   * ```
   * [[0, 719], [720, 1439], [1440, 2159]] // etc.
   * ```
   */
  type Accumulator = [number, [number, number][]];
  const windowSize = Math.floor(globals.canvasMaxDataLen / workers.length);
  const [_, canvasPtrWindows]: Accumulator = workers.reduce(
    ([sum, ptrs]: Accumulator, _, i) => {
      if (i === workers.length - 1) {
        return [sum + windowSize, [...ptrs, [sum, globals.canvasMaxDataLen]]];
      } else {
        return [sum + windowSize, [...ptrs, [sum, sum + windowSize - 1]]];
      }
    },
    [0, []] as Accumulator
  );

  const animate = async () => {
    const [updatedGlobals] = await Promise.all(canvasPtrWindows.map(([start, end], i) =>
    workers[i].postMessage({
        type: MainToWorkerMessageTypes.TICK,
        memIndexStart: start,
        memIndexEnd: end,
      })
    ));
    render(updatedGlobals as any);
    requestAnimationFrame(animate);
  };

  animate();
}

function addListeners(worker: PromisifyWorker) {
  window.addEventListener("resize", (e) => {
    worker.postMessage({
      type: MainToWorkerMessageTypes.SYNC_VIEWPORT,
      windowInnerWidth: window.innerWidth,
      windowInnerHeight: window.innerHeight,
    });
  });

  const makeHandleTouchMove = (side) => (e) => {
    const stickButton = side === "left" ? leftStickButton : rightStickButton;
    const thumbIndicator =
      side === "left"
        ? leftThumbLocationIndicatorButton
        : rightThumbLocationIndicatorButton;
    const {
      width,
      height,
      x: elementX,
      y: elementY,
    } = stickButton.getBoundingClientRect();
    const [{ pageX, pageY }] = e.targetTouches;
    const elementCenterX = elementX + width / 2;
    const elementCenterY = elementY + height / 2;
    const distFromCenterX = pageX - elementCenterX;
    const distFromCenterY = pageY - elementCenterY;

    const STICK_SENSITIVITY = 2;

    // vector from the center of the button to the current element,
    // as a percentage of the element's width / height--
    // if you want non-limited values (i.e. dragging your finger outside
    // of the element itself is considered a stronger vector), then you
    // should use this value
    const px = (distFromCenterX / width) * STICK_SENSITIVITY;
    const py = (distFromCenterY / height) * STICK_SENSITIVITY;

    // get both numbers in range -1->1 going from left-to-right and bottom-to-top
    const BORDER_OFFSET = 0.1;
    const vectorLength = Math.sqrt(px ** 2 + py ** 2) + BORDER_OFFSET;

    // convert [px, py] into a unit vector to keep it in it's containing circle
    // (to make it act similarly to a joystick)
    const unitX = px / vectorLength;
    const unitY = py / vectorLength;

    /** Take whichever is smaller: the unit vector one or the original */
    const smallestX = vectorLength < 1 ? px : unitX;
    const smallestY = vectorLength < 1 ? py : unitY;

    // map from -1->1 to -1->0 -> -100 -> 5
    const cssX = (smallestX * 0.5 - 0.5) * 100;
    const cssY = (smallestY * 0.5 - 0.5) * 100;

    thumbIndicator.style.setProperty(
      "transform",
      `translate(${cssX}%, ${cssY}%)`
    );

    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_TOUCH_MOVE,
      px,
      py,
      side,
    });
  };

  let mouseDown = false;
  const mouseMoveData = {
    x: 0,
    y: 0,
    dx: 0,
    dy: 0,
    px: 0,
    py: 0,
  };

  window.addEventListener("mousedown", (e) => {
    mouseDown = true;
    mouseMoveData.x = e.screenX;
    mouseMoveData.y = e.screenY;
  });

  const MOVEMENT_CONSTANT = 150;
  window.addEventListener("mousemove", (e) => {
    if (!mouseDown) return;
    mouseMoveData.dx = e.screenX - mouseMoveData.x;
    mouseMoveData.dy = e.screenY - mouseMoveData.y;
    mouseMoveData.px = mouseMoveData.dx / MOVEMENT_CONSTANT;
    mouseMoveData.py = mouseMoveData.dy / MOVEMENT_CONSTANT;
    const x = mouseMoveData.px ** 3 / 50;
    const y = -(mouseMoveData.py ** 3) / 50;

    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_MOUSE_MOVE,
      x,
      y,
    });

    // easier to reason when the y value is "flipped" to be bottom-to-top
    const yValue = -mouseMoveData.py;
    if (mouseMoveData.px < 0 && yValue < 0) {
      canvas.style.setProperty("cursor", "sw-resize");
    } else if (mouseMoveData.px < 0 && yValue === 0) {
      canvas.style.setProperty("cursor", "w-resize");
    } else if (mouseMoveData.px < 0 && yValue > 0) {
      canvas.style.setProperty("cursor", "nw-resize");
    } else if (mouseMoveData.px === 0 && yValue < 0) {
      canvas.style.setProperty("cursor", "s-resize");
    } else if (mouseMoveData.px === 0 && yValue === 0) {
      canvas.style.setProperty("cursor", "move");
    } else if (mouseMoveData.px === 0 && yValue > 0) {
      canvas.style.setProperty("cursor", "n-resize");
    } else if (mouseMoveData.px > 0 && yValue < 0) {
      canvas.style.setProperty("cursor", "se-resize");
    } else if (mouseMoveData.px > 0 && yValue === 0) {
      canvas.style.setProperty("cursor", "e-resize");
    } else if (mouseMoveData.px > 0 && yValue > 0) {
      canvas.style.setProperty("cursor", "ne-resize");
    }
  });

  window.addEventListener("mouseup", (e) => {
    mouseDown = false;
    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_MOUSE_UP,
    });
  });

  const makeHandleTouchEnd = (side) => () => {
    const thumbIndicator =
      side === "left"
        ? leftThumbLocationIndicatorButton
        : rightThumbLocationIndicatorButton;

    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_TOUCH_END,
      side,
    });

    thumbIndicator.style.setProperty("transform", `translate(-50%, -50%)`);
  };

  const leftHandleTouchMove = makeHandleTouchMove("left");
  leftStickButton.addEventListener("touchstart", leftHandleTouchMove);
  leftStickButton.addEventListener("touchmove", leftHandleTouchMove);
  leftStickButton.addEventListener("touchend", makeHandleTouchEnd("left"));
  leftStickButton.addEventListener("click", (e) => e.preventDefault());

  const rightHandleTouchMove = makeHandleTouchMove("right");
  rightStickButton.addEventListener("touchstart", rightHandleTouchMove);
  rightStickButton.addEventListener("touchmove", rightHandleTouchMove);
  rightStickButton.addEventListener("touchend", makeHandleTouchEnd("right"));
  rightStickButton.addEventListener("click", (e) => e.preventDefault());

  const keyDownState = {};
  const makeKeyHandler = (handlerType) => (e) => {
    const booleanValue = handlerType === "down";
    if (keyDownState[e.key] === booleanValue) return;

    const constant = handlerType === "down" ? 1 : -1;
    let amount = 0;
    let direction: "x" | "y" | "z" = "x";
    switch (e.key) {
      case "w":
        direction = "y";
        amount = constant;
        break;
      case "s":
        direction = "y";
        amount = -constant;
        break;
      case "d":
        direction = "x";
        amount = constant;
        break;
      case "a":
        direction = "x";
        amount = -constant;
        break;
      case " ":
        direction = "z";
        amount = constant;
        break;
      case "Shift":
        direction = "z";
        amount = -constant;
        break;
    }

    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_KEY,
      amount,
      direction,
    });

    keyDownState[e.key] = booleanValue;
  };
  window.addEventListener("keydown", makeKeyHandler("down"));
  window.addEventListener("keyup", makeKeyHandler("up"));

  // undo all key listeners when focus is taken away from main screen
  const handleBlur = () => {
    Object.keys(keyDownState).forEach((key) => {
      keyDownState[key] = false;
    });

    mouseDown = false;

    worker.postMessage({
      type: MainToWorkerMessageTypes.HANDLE_BLUR,
    });
  };
  window.addEventListener("blur", handleBlur);
  window.addEventListener("contextmenu", handleBlur);
}
