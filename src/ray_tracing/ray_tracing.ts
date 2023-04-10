import { PromisifyWorker } from "./promisifyWorker";

const main = async () => {
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

  const canvas = document.querySelector("canvas") as HTMLCanvasElement;
  const ctx = canvas.getContext("2d") as CanvasRenderingContext2D;
  const leftStickButton = document.querySelector(".left-stick");
  const leftThumbLocationIndicatorButton = document.querySelector(
    ".left-thumb-location-indicator"
  );
  const rightStickButton = document.querySelector(".right-stick");
  const rightThumbLocationIndicatorButton = document.querySelector(
    ".right-thumb-location-indicator"
  );

  const worker = new PromisifyWorker("worker.ts");

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

  await worker.postMessage({
    type: "init",
    windowInnerWidth: window.innerWidth,
    windowInnerHeight: window.innerHeight,
    sharedMemory,
  });
  
  const animate = async () => {
    const wasmGlobals = await worker.postMessage({ type: "tick" });
    render(wasmGlobals as any);
    requestAnimationFrame(animate);
  }

  animate();
};

main();
