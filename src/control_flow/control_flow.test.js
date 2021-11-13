/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'control_flow';

const fn = jest.fn();

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`, {
      js: { fn }
    });
  })

  afterEach(() => {
    jest.clearAllMocks();
  })

  test("call_if_less_than", () => {
    expect(fn).toHaveBeenCalledTimes(0);

    // increments count
    wasm.exports.call_if_less_than(0, 10);
    expect(fn).toHaveBeenCalledTimes(1);

    // ignores
    wasm.exports.call_if_less_than(20, 10);
    expect(fn).toHaveBeenCalledTimes(1);

    // increments count
    wasm.exports.call_if_less_than(-100, 10);
    expect(fn).toHaveBeenCalledTimes(2);
  });

  test("call_if_greater_than", () => {
    expect(fn).toHaveBeenCalledTimes(0);

    // increments count
    wasm.exports.call_if_greater_than(2, 1);
    expect(fn).toHaveBeenCalledTimes(1);

    // ignores
    wasm.exports.call_if_greater_than(0, 1);
    expect(fn).toHaveBeenCalledTimes(1);

    // increments count
    wasm.exports.call_if_greater_than(100, 2);
    expect(fn).toHaveBeenCalledTimes(2);
  });

  test("fibonacci", () => {
    expect(wasm.exports.fibonacci(0)).toBe(0);
    expect(wasm.exports.fibonacci(1)).toBe(1);
    expect(wasm.exports.fibonacci(2)).toBe(1);
    expect(wasm.exports.fibonacci(3)).toBe(2);
    expect(wasm.exports.fibonacci(4)).toBe(3);
    expect(wasm.exports.fibonacci(5)).toBe(5);
    expect(wasm.exports.fibonacci(6)).toBe(8);
    expect(wasm.exports.fibonacci(7)).toBe(13);
    expect(wasm.exports.fibonacci(25)).toBe(75025);
    expect(wasm.exports.fibonacci(30)).toBe(832040);
  });
})
