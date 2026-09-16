#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(fileURLToPath(new URL('..', import.meta.url)));
const CONFIG_PATH = resolve(ROOT, 'tools/glslang-config.json');
const CONFIG = JSON.parse(readFileSync(CONFIG_PATH, 'utf8'));
const EXIT_CODES = {
  usage: 2,
  toolMissing: 20,
  compileFailed: 21,
};

function fail(code, message) {
  console.error(`${message} [MTLX_WGSL_GLSLANG_${code === EXIT_CODES.toolMissing ? 'MISSING' : code === EXIT_CODES.compileFailed ? 'COMPILE' : 'USAGE'}]`);
  process.exit(code);
}

function parseArgs(argv) {
  const options = { stage: CONFIG.defaultStage };
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    if (arg === '--input' || arg === '--output' || arg === '--stage' || arg === '--entry-point') {
      const value = argv[++index];
      if (!value) fail(EXIT_CODES.usage, `Missing value for ${arg}.`);
      options[arg.slice(2)] = value;
    } else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node tools/compile-glsl-to-spirv.mjs --input shader.comp.glsl --output shader.comp.spv [--stage comp|frag|vert] [--entry-point NAME]');
      process.exit(0);
    } else {
      fail(EXIT_CODES.usage, `Unknown argument '${arg}'.`);
    }
  }
  if (!options.input || !options.output) fail(EXIT_CODES.usage, '--input and --output are required.');
  if (!['comp', 'frag', 'vert'].includes(options.stage)) fail(EXIT_CODES.usage, `Unsupported stage '${options.stage}'.`);
  return options;
}

function findValidator() {
  const candidates = [];
  if (process.env.GLSLANG_VALIDATOR) candidates.push(process.env.GLSLANG_VALIDATOR);
  candidates.push(resolve(ROOT, 'tools/bin/glslangValidator.exe'));
  candidates.push(resolve(ROOT, 'tools/bin/glslangValidator'));
  return candidates.find(candidate => existsSync(candidate)) || (process.platform === 'win32' ? 'glslangValidator.exe' : 'glslangValidator');
}

const options = parseArgs(process.argv.slice(2));
const input = resolve(process.cwd(), options.input);
const output = resolve(process.cwd(), options.output);
if (!existsSync(input)) fail(EXIT_CODES.usage, `Input GLSL file does not exist: ${input}`);

const validator = findValidator();
const args = [
  '-V',
  '--target-env', CONFIG.targetEnv,
  '-S', options.stage,
  ...(options['entry-point'] ? ['--source-entrypoint', 'main', '--entry-point', options['entry-point']] : []),
  '-o', output,
  input,
];
const result = spawnSync(validator, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
if (result.error?.code === 'ENOENT') {
  fail(EXIT_CODES.toolMissing, `glslangValidator ${CONFIG.version} was not found. Set GLSLANG_VALIDATOR or install it at tools/bin/.`);
}
if (result.error) fail(EXIT_CODES.toolMissing, `Unable to launch glslangValidator: ${result.error.message}`);
if (result.stdout) process.stdout.write(result.stdout);
if (result.stderr) process.stderr.write(result.stderr);
if (result.status !== 0) fail(EXIT_CODES.compileFailed, `glslangValidator failed with exit code ${result.status}.`);
console.log(`Compiled ${input} -> ${output} with glslangValidator ${CONFIG.version} (${CONFIG.targetEnv}).`);
