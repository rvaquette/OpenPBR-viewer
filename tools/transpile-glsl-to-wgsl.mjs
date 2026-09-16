#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(fileURLToPath(new URL('..', import.meta.url)));
const GLSLANG_WRAPPER = resolve(ROOT, 'tools/compile-glsl-to-spirv.mjs');
const NAGA_CONFIG_PATH = resolve(ROOT, 'tools/naga-config.json');
const NAGA_CONFIG = JSON.parse(readFileSync(resolve(ROOT, 'tools/naga-config.json'), 'utf8'));
const EXIT_CODES = {
  usage: 2,
  glslang: 30,
  naga: 31,
};

function fail(code, message, details = '') {
  const suffix = details ? `\n${details}` : '';
  console.error(`${message}${suffix} [MTLX_WGSL_${code === EXIT_CODES.glslang ? 'GLSLANG' : code === EXIT_CODES.naga ? 'NAGA' : 'USAGE'}]`);
  process.exit(code);
}

function parseArgs(argv) {
  const options = { stage: 'comp', keep: true };
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    if (arg === '--input' || arg === '--output' || arg === '--stage' || arg === '--artifacts-dir' || arg === '--entry-point') {
      const value = argv[++index];
      if (!value) fail(EXIT_CODES.usage, `Missing value for ${arg}.`);
      options[arg.slice(2)] = value;
    } else if (arg === '--keep-intermediates') {
      options.keep = true;
    } else if (arg === '--no-keep-intermediates') {
      options.keep = false;
    } else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node tools/transpile-glsl-to-wgsl.mjs --input shader.comp.glsl --output shader.comp.wgsl [--stage comp|frag|vert] [--entry-point NAME] [--artifacts-dir DIR] [--no-keep-intermediates]');
      process.exit(0);
    } else {
      fail(EXIT_CODES.usage, `Unknown argument '${arg}'.`);
    }
  }
  if (!options.input || !options.output) fail(EXIT_CODES.usage, '--input and --output are required.');
  if (!['comp', 'frag', 'vert'].includes(options.stage)) fail(EXIT_CODES.usage, `Unsupported stage '${options.stage}'.`);
  return options;
}

function run(command, args) {
  return spawnSync(command, args, { cwd: ROOT, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function writeLog(path, result) {
  writeFileSync(path, [result.stdout || '', result.stderr || ''].filter(Boolean).join('\n'), 'utf8');
}

const options = parseArgs(process.argv.slice(2));
const input = resolve(process.cwd(), options.input);
const output = resolve(process.cwd(), options.output);
const artifactsDir = resolve(process.cwd(), options['artifacts-dir'] || `${dirname(output)}/.transpile-artifacts`);
const spv = resolve(artifactsDir, `${output.split(/[\\/]/).pop().replace(/\.[^.]+$/, '')}.${options.stage}.spv`);
const glslangLog = resolve(artifactsDir, 'glslang.log');
const nagaLog = resolve(artifactsDir, 'naga.log');
if (!existsSync(input)) fail(EXIT_CODES.usage, `Input GLSL file does not exist: ${input}`);
mkdirSync(artifactsDir, { recursive: true });
try { unlinkSync(output); } catch {}

const glslangArgs = [GLSLANG_WRAPPER, '--input', input, '--output', spv, '--stage', options.stage];
if (options['entry-point']) glslangArgs.push('--entry-point', options['entry-point']);
const glslang = run(process.execPath, glslangArgs);
writeLog(glslangLog, glslang);
if (glslang.status !== 0) {
  fail(EXIT_CODES.glslang, `GLSL to SPIR-V compilation failed. Artifacts preserved in ${artifactsDir}.`, `glslang exit=${glslang.status}`);
}

const nagaCandidates = [
  process.env.NAGA,
  resolve(ROOT, NAGA_CONFIG.binary),
  resolve(ROOT, 'tools/bin/naga.exe'),
  resolve(ROOT, 'tools/bin/naga'),
].filter(Boolean);
const naga = nagaCandidates.find(candidate => existsSync(candidate));
if (!naga) {
  fail(EXIT_CODES.naga, `Naga ${NAGA_CONFIG.version} was not found. Artifacts preserved in ${artifactsDir}.`, `Set NAGA or install ${NAGA_CONFIG.binary}`);
}
mkdirSync(dirname(output), { recursive: true });
const nagaArgs = ['--input-kind', 'spv', spv, output];
const nagaStage = { comp: 'compute', frag: 'fragment', vert: 'vertex' }[options.stage];
if (nagaStage) nagaArgs.splice(2, 0, '--shader-stage', nagaStage);
const nagaResult = run(naga, nagaArgs);
writeLog(nagaLog, nagaResult);
if (nagaResult.status !== 0) {
  fail(EXIT_CODES.naga, `SPIR-V to WGSL conversion failed. Artifacts preserved in ${artifactsDir}.`, `naga exit=${nagaResult.status}`);
}
if (!existsSync(output)) fail(EXIT_CODES.naga, `Naga completed without producing ${output}. Artifacts preserved in ${artifactsDir}.`);
if (!options.keep) {
  // Keep logs for diagnosis; only remove the successful intermediate SPIR-V.
  try { unlinkSync(spv); } catch {}
}
console.log(`Transpiled ${input} -> ${output} via glslangValidator and naga ${NAGA_CONFIG.version}.`);
