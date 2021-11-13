/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'globals';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`, {
      js: {
        const_js_global: new WebAssembly.Global({ value: 'i32', mutable: false }, 2),
        mut_js_global: new WebAssembly.Global({ value: 'i32', mutable: true }, -10),
      }
    });
  })

  test("It should return globals instantiated in WebAssembly?", () => {
    expect(wasm.exports.get_const_wasm_global()).toBe(1);
  });

  test("It should return globals imported from JS", () => {
    expect(wasm.exports.get_const_js_global()).toBe(2);
  });

  test("It should modify globals supplied from JS", () => {
    // initial value
    expect(wasm.exports.get_mut_js_global()).toBe(-10);
    wasm.exports.inc_mut_js_global();
    expect(wasm.exports.get_mut_js_global()).toBe(-9);
  });

  test("It should modify globals supplied from wasm", () => {
    expect(wasm.exports.get_mut_wasm_global()).toBe(-100);
    wasm.exports.inc_mut_wasm_global();
    expect(wasm.exports.get_mut_wasm_global()).toBe(-99);
  });
})
