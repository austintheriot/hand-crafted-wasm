const path = require('path');
const _wabt = require('wabt');
const { promises: asyncFs, ...fs } = require('fs');
const { DEFAULT_ROOT_DIR } = require('./wasmUtils');
const binaryen = require('binaryen');

const isWasm = (pathString) => path.extname(pathString) === '.wasm';

const isWat = (pathString) => path.extname(pathString) === '.wat';

const isFolder = async (pathString) => (await asyncFs.lstat(pathString)).isDirectory();

/** Converts .wat text files to .wasm binary files */
const convertToWasm = async (inputWat, outputWasm, debug = false) => {
  const wabt = await _wabt();
  const wasmModule = wabt.parseWat(inputWat, fs.readFileSync(inputWat, "utf8"),
    // post-MVP wasm features to legalize:
    // enabling those supported in all major browsers
    {
      multi_value: true,
      sign_extension: true,
      sat_float_to_int: true,
    });
  const { buffer } = wasmModule.toBinary({
    // helpful for debugging but can double .wasm binary output sizes
    ...(debug && { write_debug_names: true }),
  });

  if (debug) {
    // convert to _debug.wasm file extension
    const array = outputWasm.split('.wasm')
    array.push('_debug')
    array.push('.wasm');
    outputWasm = array.join('')
  }

  fs.writeFileSync(outputWasm, new Uint8Array(buffer));
};

/** Driving function to recursively traverse directory */
const traverse = async (directoryPath, cb, options) => {
  try {
    if (!(await isFolder(directoryPath))) return;
    const files = await asyncFs.readdir(directoryPath);

    const promises = files.map(async (fileName) => {
      await cb(directoryPath, fileName, traverse, options);
    });

    await Promise.all(promises);
  } catch (e) {
    console.log(`Error retrieving contents of "${directoryPath}":`);
    console.trace(e);
  }
};

const buildCb = async (directoryPath, fileName, fn, options = { debug: false }) => {
  const fullFilePath = `${directoryPath}/${fileName}`;
  if (isWat(fullFilePath)) {
    // copy wasm output into typescript build file
    await convertToWasm(
      fullFilePath,
      `${directoryPath}/${path.basename(fileName).split('.')[0]}.wasm`,
      options.debug,
    )
  } else if (await isFolder(fullFilePath)) {
    await fn(fullFilePath, buildCb, options);
  }
}

const cleanCb = async (directoryPath, fileName, fn, options = {}) => {
  const fullFilePath = `${directoryPath}/${fileName}`;
  if (isWasm(fullFilePath)) {
    await asyncFs.unlink(fullFilePath);
  } else if (await isFolder(fullFilePath)) {
    await fn(fullFilePath, cleanCb, options);
  }
}

const optimizeCb = async (directoryPath, fileName, fn, options = {}) => {
  const fullFilePath = `${directoryPath}/${fileName}`;

  // convert ordinary .wasm to .wasm file
  if (isWasm(fullFilePath) && !fullFilePath.includes('debug') && !fullFilePath.includes('optimized')) {
    // create new file name for the optimize wasm file
    const array = fullFilePath.split('.wasm');
    array.push('_optimized')
    array.push('.wasm');
    const newPath = array.join('');

    const buffer = await asyncFs.readFile(fullFilePath);
    const module = binaryen.readBinary(buffer);
    module.optimize();
    await asyncFs.writeFile(newPath, module.emitBinary());
  } else if (await isFolder(fullFilePath)) {
    await fn(fullFilePath, optimizeCb, options);
  }
}

module.exports = {
  clean: async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, cleanCb),
  buildDebug: async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, buildCb, { debug: true }),
  buildNoDebug: async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, buildCb, { debug: false }),
  optimize: async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, optimizeCb),
};