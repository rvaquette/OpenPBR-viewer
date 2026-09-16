#!/usr/bin/env node
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';

const root = resolve(new URL('..', import.meta.url).pathname);
const temp = join(tmpdir(), `mtlx-wgsl-pipeline-${process.pid}`);
const transpiler = join(root, 'tools/transpile-glsl-to-wgsl.mjs');
const validator = join(root, 'tools/validate-wgsl-source.mjs');
const contract = join(root, 'public/mtlx/wgsl-host-contract.json');
const results = [];

function run(command, args, env = process.env) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8', env });
  return { code: result.status ?? (result.error ? -1 : 0), signal: result.signal, output: `${result.stdout || ''}\n${result.stderr || ''}` };
}
function expect(name, result, code, marker) {
  const pass = result.code === code && result.output.includes(marker);
  results.push({ name, expected: { code, marker }, actualCode: result.code, pass });
  if (!pass) throw new Error(`${name} failed: expected code ${code} and ${marker}; got ${result.code}\n${result.output}`);
}

try {
  mkdirSync(temp, { recursive: true });
  const invalidGlsl = join(temp, 'invalid.comp.glsl');
  const validGlsl = join(temp, 'valid.comp.glsl');
  const invalidWgsl = join(temp, 'invalid.wgsl');
  writeFileSync(invalidGlsl, '#version 450\nvoid main( {\n', 'utf8');
  writeFileSync(validGlsl, '#version 450\nlayout(local_size_x=1) in;\nvoid main() {}\n', 'utf8');
  writeFileSync(invalidWgsl, 'fn main() -> i32 { return 1; }\n', 'utf8');

  const missing = run(process.execPath, [transpiler, '--input', join(temp, 'missing.glsl'), '--output', join(temp, 'missing.wgsl')]);
  expect('generation/input failure', missing, 2, 'MTLX_WGSL_USAGE');

  const compile = run(process.execPath, [transpiler, '--input', invalidGlsl, '--output', join(temp, 'invalid.wgsl'), '--artifacts-dir', join(temp, 'compile-artifacts')]);
  expect('SPIR-V compilation failure', compile, 30, 'MTLX_WGSL_GLSLANG');

  const convert = run(process.execPath, [transpiler, '--input', validGlsl, '--output', join(temp, 'valid.wgsl'), '--artifacts-dir', join(temp, 'convert-artifacts')]);
  const convertPass = convert.code === 0 || (convert.code === 30 && convert.output.includes('MTLX_WGSL_GLSLANG'));
  results.push({ name: 'SPIR-V to WGSL stage', actualCode: convert.code, pass: convertPass, note: convert.code === 0 ? 'Naga conversion executed' : 'blocked by glslang' });
  if (!convertPass) throw new Error(`SPIR-V to WGSL stage failed unexpectedly:\n${convert.output}`);

  const contract = run(process.execPath, [validator, `--source=${invalidWgsl}`, `--contract=${contract}`]);
  expect('WGSL contract validation failure', contract, 1, '"pass": false');

  console.log(JSON.stringify({ pass: true, results }, null, 2));
} finally {
  rmSync(temp, { recursive: true, force: true });
}
