const { readFileSync } = require("fs");
const { clean, buildDebug, buildNoDebug, optimize } = require("./scriptUtils");
const path = require('path');

const DEFAULT_ROOT_DIR = 'src';

const setupWasmInstance = async (pathToWasm, importObject) => {
  // only clean and build the files in the directory that this function is being called
  let thisDir = pathToWasm.split('/');
  // default back to /src (or whatever the default root directory is) if no nested directories specified
  thisDir = thisDir.length > 1 ? thisDir.slice(0, -1).join('/') : DEFAULT_ROOT_DIR;

  // convert all wat to wasm files
  await clean(thisDir);
  await buildDebug(thisDir);
  await buildNoDebug(thisDir);
  await optimize(thisDir);

  // instantiate wasm modules
  const buffer = readFileSync(pathToWasm);
  const module = await WebAssembly.compile(buffer);
  const instance = await WebAssembly.instantiate(module, importObject);
  return instance;
}

module.exports = {
  setupWasmInstance,
  DEFAULT_ROOT_DIR
};