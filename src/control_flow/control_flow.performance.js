const { setupWasmInstance } = require('../../utils/wasmUtils.js');
const MODULE_NAME = 'control_flow';

// identical implementation to WebAssembly
function fibonacciJs(n) {
  if (n === 0) return 0;
  let a = 0;
  let b = 1;

  for (let i = 2; i < n; i++) {
    const c = a + b;
    a = b;
    b = c;
  }

  return a + b;
}

const testPerformance = async () => {
  try {
    const wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}.wasm`, {
      js: { fn: () => { } }
    });

    const iterations = 100;

    // performed 1 time: average ~10ms
    // performed 10_00_000+ times: average ~130ns
    let total = BigInt(0);
    for (let i = 0; i < iterations; i++) {
      const start = process.hrtime.bigint();
      wasm.exports.fibonacci(30)
      total = total + (process.hrtime.bigint() - start);
    }
    console.log(total / BigInt(iterations));


    // performed 1 time: average ~20-400ms
    // performed 10_00_000+ times: average ~105ns
    total = BigInt(0);
    for (let i = 0; i < iterations; i++) {
      const start = process.hrtime.bigint();
      fibonacciJs(30);
      total = total + (process.hrtime.bigint() - start);
    }
    console.log(total / BigInt(iterations));

  } catch (e) {
    console.error(e);
  }
}

testPerformance();