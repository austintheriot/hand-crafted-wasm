/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'ops';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`, {
      console: { log: (n) => console.log(n) }
    });
  })

  test("shift_left", () => {
    expect(wasm.exports.shift_left(1, 1)).toBe(2);
  });


  test("get_bit", () => {
    // 1
    expect(wasm.exports.get_bit(0b1, 0)).toBe(1);
    expect(wasm.exports.get_bit(0b1, 1)).toBe(0);
    expect(wasm.exports.get_bit(0b1, -1)).toBe(0);

    // 2
    expect(wasm.exports.get_bit(0b10, 0)).toBe(0);
    expect(wasm.exports.get_bit(0b10, 1)).toBe(1);
    expect(wasm.exports.get_bit(0b10, 2)).toBe(0);

    // 3
    expect(wasm.exports.get_bit(0b101, 0)).toBe(1);
    expect(wasm.exports.get_bit(0b101, 1)).toBe(0);
    expect(wasm.exports.get_bit(0b101, 2)).toBe(1);
    expect(wasm.exports.get_bit(0b101, 3)).toBe(0);

    // -1 (all ones)
    expect(wasm.exports.get_bit(-1, 0)).toBe(1);
    expect(wasm.exports.get_bit(-1, 1)).toBe(1);
    expect(wasm.exports.get_bit(-1, 2)).toBe(1);
    expect(wasm.exports.get_bit(-1, 3)).toBe(1);
    expect(wasm.exports.get_bit(-1, 16)).toBe(1);
    expect(wasm.exports.get_bit(-1, 32)).toBe(1);
  });

  test("set_bit", () => {
    // 1
    expect(wasm.exports.set_bit(0b1, 0, 0)).toBe(0);
    expect(wasm.exports.set_bit(0b1, 0, 1)).toBe(1);
    expect(wasm.exports.set_bit(0b1, 1, 1)).toBe(3);
    expect(wasm.exports.set_bit(0b1, 2, 1)).toBe(5);

    // 5
    expect(wasm.exports.set_bit(0b101, 0, 0)).toBe(4);
    expect(wasm.exports.set_bit(0b101, 0, 1)).toBe(5);
    expect(wasm.exports.set_bit(0b101, 1, 1)).toBe(7);
    expect(wasm.exports.set_bit(0b101, 2, 1)).toBe(5);

    // edge cases (takes only final bit of input bit)
    expect(wasm.exports.set_bit(0b1, 0, 2)).toBe(0);
    expect(wasm.exports.set_bit(0b1, 0, 3)).toBe(1);
    expect(wasm.exports.set_bit(0b1, 1, 7)).toBe(3);
    expect(wasm.exports.set_bit(0b1, 2, 211)).toBe(5);
  });
})
