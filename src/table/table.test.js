/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'table';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`);
  })

  test("call_with_one_arg", () => {
    // number to add to, function reference index in the table
    expect(wasm.exports.call_with_one_arg(1, 0)).toBe(1);
    expect(wasm.exports.call_with_one_arg(1, 1)).toBe(2);
    expect(wasm.exports.call_with_one_arg(1, 2)).toBe(3);

    expect(wasm.exports.call_with_one_arg(2, 0)).toBe(2);
    expect(wasm.exports.call_with_one_arg(37, 1)).toBe(38);
    expect(wasm.exports.call_with_one_arg(1001, 2)).toBe(1003);
  });

  test("call_with_two_args", () => {
    // number to add to, number to add to, function reference index in the table
    expect(wasm.exports.call_with_two_args(1, 1, 3)).toBe(2);
    expect(wasm.exports.call_with_two_args(1, 5, 4)).toBe(7);
    expect(wasm.exports.call_with_two_args(1, 11, 5)).toBe(14);
  });

  test("linear memory when there is a table", () => {
    // write to linear memory
    const array = new Uint8Array(wasm.exports.memory.buffer);
    expect(array[3]).toBe(0);
    wasm.exports.write_to_memory_index(3, 57);
    expect(array[3]).toBe(57);

    // function calls should be unaffected by writing to linear memory
    expect(wasm.exports.call_with_one_arg(1, 0)).toBe(1);
    expect(wasm.exports.call_with_one_arg(1, 1)).toBe(2);
    expect(wasm.exports.call_with_one_arg(1, 2)).toBe(3);

    expect(wasm.exports.call_with_two_args(1, 1, 3)).toBe(2);
    expect(wasm.exports.call_with_two_args(1, 5, 4)).toBe(7);
    expect(wasm.exports.call_with_two_args(1, 11, 5)).toBe(14);
  });
})
