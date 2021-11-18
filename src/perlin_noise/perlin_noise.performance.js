const { setupWasmInstance } = require('../../utils/wasmUtils.js');
const { perlin_noise_js } = require('./perlin_noise');

const MODULE_NAME = 'perlin_noise';

const yellow = '\x1b[33m%s\x1b[0m';
const magenta = '\x1b[35m"%s\x1b[0m';
const bigIntToString = (bigInt) => (bigInt).toString().replace('n', '');

const testPerformance = async () => {
  try {
    const wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}.wasm`, {
      console, Math
    });

    [1, 100, 10_000, 10_000_000].forEach((iterations) => {
      // performed 1 time: average ~80ms
      // performed 100 times: average ~13ms
      // performed 10_00_000+ times: average ~280ns
      let total = BigInt(0);
      for (let i = 0; i < iterations; i++) {
        const start = process.hrtime.bigint();
        wasm.exports.perlin_noise(-1987.1789, 11, 99.1)
        total = total + (process.hrtime.bigint() - start);
      }
      let totalMs = total / BigInt(1000);
      let totalS = totalMs / BigInt(1000);
      console.log(magenta, `Wasm: ${iterations} iterations:`);
      console.log(`Total: ${bigIntToString(totalMs)}ms (${bigIntToString(totalS)})s`)
      console.log(`Avg: ${bigIntToString(total / BigInt(iterations))}ns/call\n`)


      // performed 1 time: average ~20-400ms
      // performed 100 times: average ~6ms
      // performed 10_00_000+ times: average ~235ns
      total = BigInt(0);
      for (let i = 0; i < iterations; i++) {
        const start = process.hrtime.bigint();
        perlin_noise_js(-1987.1789, 11, 99.1);
        total = total + (process.hrtime.bigint() - start);
      }
      totalMs = total / BigInt(1000);
      totalS = totalMs / BigInt(1000);
      console.log(yellow, `JS: ${iterations} iterations:`);
      console.log(`Total: ${bigIntToString(totalMs)}ms (${bigIntToString(totalS)})s`)
      console.log(`Avg: ${bigIntToString(total / BigInt(iterations))}ns/call\n\n`)
    })

  } catch (e) {
    console.error(e);
  }
}

testPerformance();