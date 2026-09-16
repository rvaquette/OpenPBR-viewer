#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const root = process.cwd();
const thresholds = JSON.parse(readFileSync(resolve(root, 'artifacts/webgpu-migration/comparison-thresholds.json'), 'utf8'));
const cases = [
  { id: 'standard-opaque', baseline: 'artifacts/webgpu-migration/baselines/standard-opaque.png', candidate: 'artifacts/webgpu-migration/webgpu-materialx/standard-opaque.png', acceptedDifference: 'WebGPU MaterialX runtime, transpiler and sampling precision may differ from WebGL.' },
  { id: 'standard-emissive', baseline: 'artifacts/webgpu-migration/baselines/standard-emissive.png', candidate: 'artifacts/webgpu-migration/webgpu-materialx/standard-emissive.png', acceptedDifference: 'WebGPU MaterialX runtime, transpiler and sampling precision may differ from WebGL.' },
  { id: 'glavenus-metal', baseline: 'artifacts/webgpu-migration/baselines/glavenus-metal.png', candidate: 'artifacts/webgpu-migration/webgpu-materialx/glavenus-metal.png', acceptedDifference: 'MaterialX closure and stochastic sampling precision may differ from WebGL.' },
  { id: 'bearded-glass', baseline: 'artifacts/webgpu-migration/baselines/bearded-glass.png', candidate: 'artifacts/webgpu-migration/webgpu-materialx/bearded-glass.png', acceptedDifference: 'MaterialX transmission and stochastic sampling precision may differ from WebGL.' },
  { id: 'terrain-procedural', baseline: 'artifacts/webgpu-migration/baselines/terrain-procedural.png', candidate: 'artifacts/webgpu-migration/webgpu-materialx/terrain-procedural.png', acceptedDifference: 'MaterialX texture sampling precision may differ from WebGL.' },
];

const results = cases.map(testCase => {
  const baseline = resolve(root, testCase.baseline);
  const candidate = resolve(root, testCase.candidate);
  if (!existsSync(baseline)) return { ...testCase, status: 'blocked', reason: 'baseline missing' };
  if (!existsSync(candidate)) return { ...testCase, status: 'blocked', reason: 'WebGPU MaterialX capture missing' };
  try {
    const output = execFileSync(process.execPath, [
      'tools/compare-render-images.mjs',
      `--reference=${baseline}`,
      `--candidate=${candidate}`,
      `--mean-threshold=${thresholds.metrics.meanAbsoluteRgbError}`,
      `--outlier-threshold=${thresholds.metrics.maximumOutlierPixelRatio}`,
      `--pixel-threshold=${thresholds.metrics.outlierPixelAbsoluteRgbError}`,
    ], { cwd: root, encoding: 'utf8' });
    return { ...testCase, status: 'pass', comparison: JSON.parse(output) };
  } catch (error) {
    let comparison = null;
    try { comparison = JSON.parse(error.stdout || '{}'); } catch {}
    return { ...testCase, status: 'fail', comparison, reason: 'comparison thresholds exceeded' };
  }
});

const report = {
  version: 1,
  status: results.some(result => result.status === 'blocked') ? 'blocked' : results.some(result => result.status === 'fail') ? 'fail' : 'pass',
  thresholds,
  forbiddenDifferences: thresholds.forbiddenDifferences,
  cases: results,
};
const output = resolve(root, 'artifacts/webgpu-migration/webgpu-materialx-baseline-comparison.json');
writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: report.status, total: cases.length, pass: results.filter(result => result.status === 'pass').length, blocked: results.filter(result => result.status === 'blocked').length, fail: results.filter(result => result.status === 'fail').length, output }, null, 2));
process.exit(report.status === 'pass' ? 0 : 1);
