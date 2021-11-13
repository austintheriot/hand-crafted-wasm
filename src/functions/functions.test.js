/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'functions';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`);
  })

  test("It returns two added numbers", () => {
    expect(wasm.exports.add(1, 1)).toBe(2);
    expect(wasm.exports.add(1.1, -9.7)).toBe(-8.6);
    expect(wasm.exports.add(1000, 999)).toBe(1999);
  });

  test("It returns two added numbers, with alternate syntax", () => {
    expect(wasm.exports.add2(1, 1)).toBe(2);
    expect(wasm.exports.add2(1.1, -9.7)).toBe(-8.6);
    expect(wasm.exports.add2(1000, 999)).toBe(1999);
  });

  test("It returns two added numbers, with inline export", () => {
    expect(wasm.exports.add3(1, 1)).toBe(2);
    expect(wasm.exports.add3(1.1, -9.7)).toBe(-8.6);
    expect(wasm.exports.add3(1000, 999)).toBe(1999);
  });

  test("It returns two added numbers, when calling other function inside .wat", () => {
    expect(wasm.exports.add4(1, 1)).toBe(2);
    expect(wasm.exports.add4(1.1, -9.7)).toBe(-8.6);
    expect(wasm.exports.add4(1000, 999)).toBe(1999);
  });
})
