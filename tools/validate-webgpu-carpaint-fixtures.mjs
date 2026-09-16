#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = process.cwd();
const fixtures = ['carpaint', 'glass', 'pearl', 'soapbubble', 'synthetic_default'];
const artifactRoot = resolve(root, 'artifacts/webgpu-migration');
const validator = resolve(root, 'tools/validate-webgpu-materialx-fixtures.mjs');
const glslang = process.env.GLSLANG_VALIDATOR || 'C:\\VulkanSDK\\1.3.296.0\\Bin\\glslangValidator.exe';
const reports = [];

for (let index = 0; index < fixtures.length; index++) {
  const fixtureId = fixtures[index];
  const reportPath = resolve(artifactRoot, `t052.7-${fixtureId}.json`);
  const result = spawnSync(process.execPath, [validator], {
    cwd: root,
    env: {
      ...process.env,
      T052_FIXTURE_ID: fixtureId,
      T052_REPORT_PATH: reportPath,
      SMOKE_PORT: String(5251 + index * 2),
      T052_TRANSPILER_PORT: String(5250 + index * 2),
      T052_READY_TIMEOUT: process.env.T052_READY_TIMEOUT || '300000',
      T052_BACKEND_TIMEOUT: process.env.T052_BACKEND_TIMEOUT || '300000',
      T052_SAMPLES_TIMEOUT: process.env.T052_SAMPLES_TIMEOUT || '120000',
      GLSLANG_VALIDATOR: glslang,
    },
    encoding: 'utf8',
    timeout: 600000,
  });
  let report = null;
  if (existsSync(reportPath)) {
    try { report = JSON.parse(readFileSync(reportPath, 'utf8')); } catch {}
  }
  const fixture = report?.fixtures?.[0] || null;
  const errorText = [fixture?.error, fixture?.state?.shaderError, result.error?.message, result.stderr]
    .filter(Boolean).join('\n');
  const errorCode = errorText.match(/\bMTLX_WGSL_[A-Z_]+\b/)?.[0] || null;
  reports.push({
    fixtureId,
    runnerExitCode: result.status,
    runnerSignal: result.signal,
    runnerError: result.error?.message || null,
    reportPath,
    status: fixture?.status || 'blocked',
    error: fixture?.error || fixture?.state?.shaderError || null,
    errorCode,
    samples: fixture?.samples ?? fixture?.state?.samples ?? null,
    timings: fixture?.timings || null,
    image: fixture?.image ? { width: fixture.image.width, height: fixture.image.height, variance: fixture.image.variance, nonUniform: fixture.image.nonUniform } : null,
    objectVisibility: fixture?.objectVisibility || null,
    pipeline: {
      generatedWgsl: fixture?.materialDispatch?.generatedWgsl === true,
      hostDispatch: fixture?.materialDispatch?.hostDispatch === true,
      webgpuMaterialPipeline: fixture?.materialDispatch?.webgpuMaterialPipeline === true,
      materialBindGroup: fixture?.materialDispatch?.materialBindGroup === true,
    },
    backend: fixture?.backend?.active || fixture?.state?.backend?.active || null,
    gpuError: fixture?.renderState?.gpuError ?? null,
    fallback: fixture?.fallback ?? null,
    capture: fixture?.capture || null,
    stdoutTail: String(result.stdout || '').trim().split(/\r?\n/).slice(-12),
    stderrTail: String(result.stderr || '').trim().split(/\r?\n/).slice(-12),
  });
  console.log(`[T052.7] ${fixtureId}: ${reports.at(-1).status} exit=${result.status} code=${errorCode || 'none'}`);
}

const transmissionFixturesVisible = reports
  .filter(result => result.fixtureId === 'glass' || result.fixtureId === 'soapbubble')
  .every(result => Number.isFinite(result.objectVisibility?.centralMean) && result.objectVisibility.centralMean > 2);
const pass = reports.every(result => result.runnerExitCode === 0 && result.status === 'pass' &&
  result.samples >= 2 && result.image?.width === 256 && result.image?.height === 256 && result.image?.nonUniform === true &&
  result.pipeline.generatedWgsl && result.pipeline.hostDispatch && result.pipeline.webgpuMaterialPipeline && result.pipeline.materialBindGroup &&
  result.backend === 'webgpu' && result.gpuError === null && result.fallback === false &&
  Number.isFinite(result.timings?.generationMs) && Number.isFinite(result.timings?.transpileMs) &&
  Number.isFinite(result.timings?.pipelineMs) && Number.isFinite(result.timings?.fixtureTotalMs) &&
  Boolean(result.capture && existsSync(result.capture))) && transmissionFixturesVisible;
const output = resolve(artifactRoot, 't052.7-carpaint-fixtures-report.json');
writeFileSync(output, `${JSON.stringify({ version: 1, task: 'T052.7', status: pass ? 'pass' : 'blocked', fixtures: reports }, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: pass ? 'pass' : 'blocked', total: reports.length, passed: reports.filter(result => result.status === 'pass').length, failed: reports.filter(result => result.status !== 'pass').length, output }, null, 2));
process.exit(pass ? 0 : 1);
