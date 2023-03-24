import path from 'path';
import _wabt from 'wabt';
import { promises as asyncFs} from 'fs';
import * as fs from 'fs';

const DEFAULT_ROOT_DIR = 'src';

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
      simd: true,
      bulk_memory: true,
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
  // do not delete optimized files, since these are optimized 
  // and a case-by-case basis through the binaryen CLI
  if (isWasm(fullFilePath) && !fullFilePath.includes('optimize')) {
    await asyncFs.unlink(fullFilePath);
  } else if (await isFolder(fullFilePath)) {
    await fn(fullFilePath, cleanCb, options);
  }
}

// auto update bytes tally in markdown file
const updateBytes = async () => {
  try {
    const readMePath = './README.md';
    const { size: parametricEquations } = await asyncFs.stat('src/parametric_equations/parametric_equations_optimized.wasm');
    const { size: lifeSize } = await asyncFs.stat('src/life/life_optimized.wasm');
    const { size: chaosCircleSize } = await asyncFs.stat('src/life/life_optimized.wasm');
    const { size: perlinNoiseSize } = await asyncFs.stat('src/perlin_noise/perlin_noise_optimized.wasm');
    const { size: noiseFieldSize } = await asyncFs.stat('src/noise_field/noise_field_optimized.wasm');
    const { size: noiseCloudSize } = await asyncFs.stat('src/noise_cloud/noise_cloud_optimized.wasm');
    const { size: lorenzSystemSize } = await asyncFs.stat('src/lorenz_system/lorenz_system_optimized.wasm');
    const { size: terrainSize } = await asyncFs.stat('src/terrain/terrain_optimized.wasm');
    const { size: waterSize } = await asyncFs.stat('src/water/water_optimized.wasm');
    const { size: waterAsciiSize } = await asyncFs.stat('src/water_ascii/water_ascii_optimized.wasm');
    const readMeBytes = await asyncFs.readFile(readMePath);
    const readMe = readMeBytes.toString();
    const terrainGeneratorSizeMin = perlinNoiseSize + Math.min(terrainSize, waterSize, waterAsciiSize);
    const terrainGeneratorSizeMax = perlinNoiseSize + Math.max(terrainSize, waterSize, waterAsciiSize);
    const updatedReadme = readMe
      .replace(/(?<=Parametric Equations:)(.*)(?=bytes)/, ` ${parametricEquations} `)
      .replace(/(?<=Noise Field:)(.*)(?=bytes)/, ` ${perlinNoiseSize + noiseFieldSize} `)
      .replace(/(?<=Life:)(.*)(?=bytes)/, ` ${lifeSize} `)
      .replace(/(?<=Lorenz System:)(.*)(?=bytes)/, ` ${lorenzSystemSize} `)
      .replace(/(?<=Noise Cloud:)(.*)(?=bytes)/, ` ${perlinNoiseSize + noiseCloudSize} `)
      .replace(/(?<=Water Emulator:)(.*)(?=bytes)/, ` ${perlinNoiseSize + waterSize} `)
      .replace(/(?<=Chaos Circle:)(.*)(?=bytes)/, ` ${perlinNoiseSize + chaosCircleSize} `)
      .replace(/(?<=Terrain\/Water Generator:)(.*)(?=bytes)/, ` ${terrainGeneratorSizeMin}-${terrainGeneratorSizeMax} `)
      .replace(/(?<=Terrain:)(.*)(?=bytes)/, ` ${perlinNoiseSize + terrainSize} `)
      .replace(/(?<=Water:)(.*)(?=bytes)/, ` ${perlinNoiseSize + waterSize} `)
      .replace(/(?<=Water \(Low-fi\/ASCII version\):)(.*)(?=bytes)/, ` ${perlinNoiseSize + waterAsciiSize} `);
    await asyncFs.writeFile(readMePath, updatedReadme);
  } catch (e) {
    console.error(e);
  }
}

const clean = async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, cleanCb);
const buildDebug = async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, buildCb, { debug: true })
const buildNoDebug = async (dir = DEFAULT_ROOT_DIR) => await traverse(dir, buildCb, { debug: false });

export {
  clean,
  buildDebug,
  buildNoDebug,
  updateBytes,
  DEFAULT_ROOT_DIR,
}