/** @jest-environment node */
const { setupWasmInstance } = require('../../utils/wasmUtils.js');

const MODULE_NAME = 'memory';

describe(`Test ${MODULE_NAME}`, () => {
  let wasm;
  beforeAll(async () => {
    wasm = await setupWasmInstance(`src/${MODULE_NAME}/${MODULE_NAME}_debug.wasm`);
  })

  test("Hello, world - as string", () => {
    const bytes = new Uint8Array(wasm.exports.memory.buffer, 0, 13);
    const string = new TextDecoder('utf8').decode(bytes);
    expect(string).toBe('Hello, world!');
  });

  test("Hello, world - as hex values", () => {
    const bytes = new Uint8Array(wasm.exports.memory.buffer, 13, 13);
    const string = new TextDecoder('utf8').decode(bytes);
    expect(string).toBe('Hello, world!');
  });

  test("Hello, world - as hex values", () => {
    const bytes = new Uint8Array(wasm.exports.memory.buffer, 26, 1);
    const string = new TextDecoder('utf8').decode(bytes);
    expect(string).toBe('?');
  });
})
