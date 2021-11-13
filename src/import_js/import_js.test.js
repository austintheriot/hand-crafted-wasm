/** @jest-environment node */
const { expect } = require("@jest/globals");
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'import_js';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`, {
      console: {
        log: (...args) => console.log(...args),
      },
      math: {
        add: (n1, n2) => n1 + n2,
      }
    });
  })

  test("Importing console.log from JS", () => {
    expect(() => wasm.exports.log(1, 2, 3, 4)).not.toThrow();
  });

  test("Importing other function from JS", () => {
    expect(() => wasm.exports.add_and_log(1, 2)).not.toThrow();
  });

  test("Stack order with parameters/arguments", () => {
    expect(() => wasm.exports.log(1, 2, 3, 4)).not.toThrow();
  });
})