#!/usr/bin/env node
import { chromium } from 'playwright-core';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import sharp from 'sharp';

const root = process.cwd();
const port = process.env.SMOKE_PORT || '5186';
const base = `http://localhost:${port}/OpenPBR-viewer/`;
const output = resolve(root, process.env.T052_REPORT_PATH || 'artifacts/webgpu-migration/webgpu-materialx-fixtures-report.json');
const matrix = JSON.parse(readFileSync(resolve(root, 'artifacts/webgpu-migration/t052-fixture-matrix.json'), 'utf8'));
const requestedFixtures = new Set(String(process.env.T052_FIXTURE_ID || '').split(',').map(value => value.trim()).filter(Boolean));
const setupOnly = process.env.T052_SETUP_ONLY === '1';
const closeGate = process.env.T052_CLOSE_GATE === '1';
const fixtures = matrix.fixtures
  .filter(fixture => requestedFixtures.size === 0 || requestedFixtures.has(fixture.fixtureId))
  .map(fixture => [fixture.fixtureId, fixture.materialPath, fixture.kind]);
if (fixtures.length !== (requestedFixtures.size || fixtures.length)) throw new Error(`Unknown T052 fixture selection: ${[...requestedFixtures].join(',')}`);
if (matrix.rendererBackend !== 'webgpu' || matrix.rendererMode !== 'Pathtracer MTLX') throw new Error('T052 matrix must target the WebGPU Pathtracer MTLX route.');
for (const [, material] of fixtures) {
  if (!existsSync(resolve(root, 'public', material))) throw new Error(`T052 fixture is missing: ${material}`);
}
const browserPath = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].find(existsSync);
if (!browserPath) throw new Error('Chrome or Edge is required for T052.');

const transpilePort = Number(process.env.T052_TRANSPILER_PORT || 5187);
const readyTimeout = Number(process.env.T052_READY_TIMEOUT || 120000);
const backendTimeout = Number(process.env.T052_BACKEND_TIMEOUT || 60000);
const samplesTimeout = Number(process.env.T052_SAMPLES_TIMEOUT || 60000);
const transpileRoot = resolve(tmpdir(), `openpbr-t052-transpile-${process.pid}`);
mkdirSync(transpileRoot, { recursive: true });
const glslang = process.env.GLSLANG_VALIDATOR || 'C:\\VulkanSDK\\1.3.296.0\\Bin\\glslangValidator.exe';
const transpileServer = createServer(async (request, response) => {
  response.setHeader('access-control-allow-origin', '*');
  response.setHeader('access-control-allow-methods', 'POST, OPTIONS');
  response.setHeader('access-control-allow-headers', 'content-type');
  if (request.method === 'OPTIONS') { response.writeHead(204); response.end(); return; }
  if (request.method !== 'POST' || request.url !== '/transpile') {
    response.writeHead(404); response.end(); return;
  }
  try {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    const payload = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (typeof payload.glsl !== 'string' || payload.glsl.length === 0) throw new Error('GLSL source is empty');
    const id = `material-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const input = resolve(transpileRoot, `${id}.frag.glsl`);
    const output = resolve(transpileRoot, `${id}.wgsl`);
    writeFileSync(input, payload.glsl, 'utf8');
    const result = spawnSync(process.execPath, [
      resolve(root, 'tools/transpile-glsl-to-wgsl.mjs'),
      '--input', input, '--output', output, '--stage', 'frag',
      '--entry-point', 'mtlxMaterialLibrary',
      '--artifacts-dir', resolve(transpileRoot, `${id}-artifacts`),
    ], { cwd: root, env: { ...process.env, GLSLANG_VALIDATOR: glslang }, encoding: 'utf8' });
    if (result.status !== 0 || !existsSync(output)) {
      const error = new Error(`${result.stdout || ''}\n${result.stderr || ''}`.trim());
      error.code = result.stderr?.includes('MTLX_WGSL_GLSLANG') ? 'MTLX_WGSL_GLSLANG_COMPILE' : 'MTLX_WGSL_NAGA_TRANSPILE';
      throw error;
    }
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ wgsl: readFileSync(output, 'utf8'), stage: 'fragment' }));
  } catch (error) {
    response.writeHead(500, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ error: String(error?.message || error) }));
  }
});
await new Promise((resolvePromise, reject) => { transpileServer.once('error', reject); transpileServer.listen(transpilePort, '127.0.0.1', resolvePromise); });

const vite = spawn(`npx vite --port ${port}`, [], { shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
await new Promise((resolvePromise, reject) => {
  const timeout = setTimeout(() => reject(new Error('Vite timeout')), 60000);
  const ready = data => { if (/Local:|localhost:/i.test(data.toString())) { clearTimeout(timeout); resolvePromise(); } };
  vite.stdout.on('data', ready); vite.stderr.on('data', ready); vite.on('error', reject);
});

const browser = await chromium.launch({ executablePath: browserPath, headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--enable-gpu', '--enable-unsafe-webgpu'] });
const context = await browser.newContext({ viewport: { width: 256, height: 256 } });
const browserDiagnostics = [];
context.on('page', page => {
  page.on('console', message => browserDiagnostics.push(`[console:${message.type()}] ${message.text()}`));
  page.on('pageerror', error => browserDiagnostics.push(`[pageerror] ${error.message}`));
  page.on('requestfailed', request => browserDiagnostics.push(`[requestfailed] ${request.url()} ${request.failure()?.errorText || ''}`));
});
await context.addInitScript(({ port }) => {
  window.__openpbrTranspileGlslToWgsl = async payload => {
    const response = await fetch(`http://127.0.0.1:${port}/transpile`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload) });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || `Transpiler HTTP ${response.status}`);
    return result;
  };
}, { port: transpilePort });
const page = await context.newPage();
const reports = [];
try {
  for (const [id, material, kind] of fixtures) {
    console.log(`[T052] starting ${id}`);
      const fixtureStart = performance.now();
      const params = new URLSearchParams({
        renderer_backend: matrix.rendererBackend,
        renderer_mode: matrix.rendererMode,
        gpu: 'true',
        paused: 'false',
        scene_name: matrix.scene,
        max_samples: String(matrix.samples),
        bounces: String(matrix.bounces),
        env_map_path: matrix.environment.map,
        env_irradiance_path: matrix.environment.irradiance,
        env_map_provided: String(matrix.environment.provided),
        webgpu_debug_mode: process.env.T052_DEBUG_MODE || 'hit',
        mtlx_url: `/${material}`,
      });
      const url = `${base}?${params.toString()}`;
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded' });
      await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: readyTimeout });
      await page.waitForFunction(() => window.__openpbrRendererBackend?.active === 'webgpu' || window.__openpbrRendererBackend?.webgpuStatus === 'error', null, { timeout: backendTimeout });
      if (setupOnly) {
        await page.waitForFunction(() => {
          const state = window.__openpbrGetWebGpuRenderState?.();
          return state?.ready === true && state.nodeCount > 0 && state.triangleCount > 0 && state.hasBindGroups === true;
        }, null, { timeout: samplesTimeout });
      }
      const setupState = await page.evaluate(() => ({
        ready: window.__openpbrReady ?? false,
        backend: window.__openpbrRendererBackend ?? null,
        shaderError: window.__openpbrShaderError ?? null,
        samples: window.__openpbrSamples ?? 0,
        renderState: window.__openpbrGetWebGpuRenderState?.() ?? null,
      }));
      if (setupOnly) {
        const renderState = setupState.renderState;
        const resourceChecks = {
          backendReady: setupState.backend?.requested === 'webgpu' && setupState.backend?.active === 'webgpu' && setupState.backend?.webgpuStatus === 'ready',
          sceneReady: renderState?.ready === true && renderState.nodeCount > 0 && renderState.triangleCount > 0,
          dimensionsMatch: renderState?.width === matrix.resolution.width && renderState?.height === matrix.resolution.height,
          bindGroupsReady: renderState?.hasBindGroups === true,
          groundTextureReady: (renderState?.groundTexture?.width || 0) > 0 && (renderState?.groundTexture?.height || 0) > 0,
          gpuErrorFree: !renderState?.gpuError,
          shaderErrorFree: !setupState.shaderError,
        };
        const setupPass = Object.values(resourceChecks).every(Boolean);
        reports.push({ id, kind, material, status: setupPass ? 'pass' : 'fail', setupOnly: true, setup: { matrix: { scene: matrix.scene, resolution: matrix.resolution, samples: matrix.samples, bounces: matrix.bounces, environment: matrix.environment }, checks: resourceChecks, state: setupState } });
        console.log(`[T052] ${id}: setup ${setupPass ? 'pass' : 'fail'}`);
        continue;
      }
      await page.waitForFunction(() => (window.__openpbrWebGpuMaterialPipeline === true && window.__openpbrWebGpuMaterialBindGroup === true) || Boolean(window.__openpbrShaderError), null, { timeout: backendTimeout });
      await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 2, null, { timeout: samplesTimeout });
      const state = await page.evaluate(() => window.__openpbrRendererBackend || null);
      const error = await page.evaluate(() => window.__openpbrShaderError || null);
      const samples = await page.evaluate(() => window.__openpbrSamples ?? 0);
      const fallback = await page.evaluate(() => window.__openpbrWebGpuMaterialPipeline !== true || window.__openpbrWebGpuMaterialBindGroup !== true);
      const materialDispatch = await page.evaluate(async () => {
        const sha256 = async value => {
          const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value || ''));
          return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
        };
        const glsl = window.__openpbrMtlxRouteDispatchGlsl || '';
        const wgsl = window.__openpbrMtlxGeneratedWgsl || window.__openpbrTranspiledMtlxWgsl || '';
        return {
          generatedWgsl: Boolean(wgsl),
          hostDispatch: Boolean(glsl),
          webgpuMaterialPipeline: Boolean(window.__openpbrWebGpuMaterialPipeline),
          materialBindGroup: Boolean(window.__openpbrWebGpuMaterialBindGroup),
          hostGlslLength: glsl.length,
          wgslLength: wgsl.length,
          hostGlslSha256: await sha256(glsl),
          wgslSha256: await sha256(wgsl),
          bindingNumbers: [...wgsl.matchAll(/@group\(0\)\s*@binding\((\d+)\)/g)].map(match => Number(match[1])),
        };
      });
      materialDispatch.materialBindingsReserved = materialDispatch.bindingNumbers.length > 0 && Math.min(...materialDispatch.bindingNumbers) >= 15;
      await page.evaluate(() => window.__openpbrWaitForWebGpuWork?.());
      const gpuWorkCompleted = true;
      await page.waitForTimeout(100);
      const accumulationPixel = await page.evaluate(() => window.__openpbrReadAccumulationPixel?.(128, 128));
      const bvhDebug = await page.evaluate(() => window.__openpbrReadBvhDebug?.());
      const bvhStackOverflow = await page.evaluate(() => window.__openpbrReadBvhStackOverflow?.());
      const renderState = await page.evaluate(() => window.__openpbrGetWebGpuRenderState?.());
      const generationTimings = await page.evaluate(() => window.__openpbrMtlxTimings || null);
      const hiddenUi = await page.evaluate(() => {
        document.querySelector('.lil-gui')?.remove();
        for (const id of ['progress_overlay', 'samples', 'info', 'shader-error']) {
          const element = document.getElementById(id);
          if (element) element.style.display = 'none';
        }
        const selectors = ['.lil-gui', '#progress_overlay', '#samples', '#info', '#shader-error'];
        const state = Object.fromEntries(selectors.map(selector => {
          const element = document.querySelector(selector);
          if (!element) return [selector, { present: false, hidden: true }];
          const style = getComputedStyle(element);
          const hidden = style.display === 'none' || style.visibility === 'hidden' || Number(style.opacity) === 0;
          return [selector, { present: true, hidden, display: style.display, visibility: style.visibility, opacity: style.opacity }];
        }));
        return { state, pass: Object.values(state).every(value => value.hidden) };
      });
      await page.evaluate(() => new Promise(resolvePromise => requestAnimationFrame(() => requestAnimationFrame(resolvePromise))));
      const capturePath = resolve(root, 'artifacts/webgpu-migration', `${id}-webgpu.png`);
      const viewportCapturePath = resolve(root, 'artifacts/webgpu-migration', `${id}-webgpu-viewport.png`);
      await page.locator('#openpbr-webgpu-canvas').screenshot({ path: capturePath });
      await page.screenshot({ path: viewportCapturePath });
      const { data, info } = await sharp(capturePath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
      const viewportMetadata = await sharp(viewportCapturePath).metadata();
      const captureSha256 = createHash('sha256').update(readFileSync(capturePath)).digest('hex');
      const viewportSha256 = createHash('sha256').update(readFileSync(viewportCapturePath)).digest('hex');
      let sum = 0, sumSquares = 0, pixelCount = 0, objectHitPixels = 0;
      for (let index = 0; index < data.length; index += info.channels) {
        const luminance = (data[index] + data[index + 1] + data[index + 2]) / 3;
        sum += luminance;
        sumSquares += luminance * luminance;
        pixelCount++;
        if (data[index] > data[index + 2] * 1.5 && data[index] > data[index + 1] * 1.5) objectHitPixels++;
      }
      const mean = sum / Math.max(1, pixelCount);
      const variance = sumSquares / Math.max(1, pixelCount) - mean * mean;
      const borderSize = Math.max(1, Math.floor(Math.min(info.width, info.height) * 0.09375));
      const centralMinX = Math.floor(info.width * 0.125);
      const centralMaxX = Math.ceil(info.width * 0.875);
      const centralMinY = Math.floor(info.height * 0.078125);
      const centralMaxY = Math.ceil(info.height * 0.86328125);
      let borderSum = 0, borderPixels = 0, centralSum = 0, centralPixels = 0;
      const luminances = new Float32Array(info.width * info.height);
      for (let y = 0; y < info.height; y++) {
        for (let x = 0; x < info.width; x++) {
          const pixel = y * info.width + x;
          const offset = pixel * info.channels;
          const luminance = (data[offset] + data[offset + 1] + data[offset + 2]) / 3;
          luminances[pixel] = luminance;
          if (x < borderSize || x >= info.width - borderSize || y < borderSize || y >= info.height - borderSize) {
            borderSum += luminance;
            borderPixels++;
          }
          if (x >= centralMinX && x < centralMaxX && y >= centralMinY && y < centralMaxY) {
            centralSum += luminance;
            centralPixels++;
          }
        }
      }
      const borderMean = borderSum / Math.max(1, borderPixels);
      const centralMean = centralSum / Math.max(1, centralPixels);
      let darkCentralPixels = 0;
      for (let y = centralMinY; y < centralMaxY; y++) {
        for (let x = centralMinX; x < centralMaxX; x++) {
          if (luminances[y * info.width + x] <= borderMean - 12) darkCentralPixels++;
        }
      }
      const darkCentralFraction = darkCentralPixels / Math.max(1, centralPixels);
      const objectVisible = borderMean - centralMean > 5 && darkCentralFraction > 0.1;
      const capturesValid = info.width === matrix.resolution.width && info.height === matrix.resolution.height &&
        viewportMetadata.width === matrix.resolution.width && viewportMetadata.height === matrix.resolution.height &&
        capturePath !== viewportCapturePath && existsSync(capturePath) && existsSync(viewportCapturePath);
      const hitcheckPass = process.env.T052_DEBUG_MODE === 'hitcheck' && objectHitPixels > 0;
      const accumulationFinite = Array.isArray(accumulationPixel) && accumulationPixel.length === 4 && accumulationPixel.every(Number.isFinite);
      const accumulationNonZero = accumulationFinite && accumulationPixel.slice(0, 3).some(value => Math.abs(value) > 1.0e-6);
      const materialActive = renderState?.materialPipelineActive === true && renderState?.materialBindGroup === true;
      const presentationPass = gpuWorkCompleted && hiddenUi.pass && capturesValid && objectVisible;
      let hitcheck = null;
      if (closeGate) {
        await page.evaluate(() => {
          window.__openpbrSetDebugMode?.('hitcheck');
          window.__openpbrSamples = 0;
        });
        await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 2, null, { timeout: samplesTimeout });
        await page.evaluate(() => window.__openpbrWaitForWebGpuWork?.());
        const hitcheckPath = resolve(root, 'artifacts/webgpu-migration', `${id}-webgpu-hitcheck.png`);
        await page.locator('#openpbr-webgpu-canvas').screenshot({ path: hitcheckPath });
        const hitcheckImage = await sharp(hitcheckPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
        let hitPixels = 0;
        for (let index = 0; index < hitcheckImage.data.length; index += hitcheckImage.info.channels) {
          if (hitcheckImage.data[index] > hitcheckImage.data[index + 1] * 1.5 && hitcheckImage.data[index] > hitcheckImage.data[index + 2] * 1.5) hitPixels++;
        }
        const hitPixelCount = hitcheckImage.info.width * hitcheckImage.info.height;
        hitcheck = {
          path: hitcheckPath,
          width: hitcheckImage.info.width,
          height: hitcheckImage.info.height,
          samples: await page.evaluate(() => window.__openpbrSamples ?? 0),
          objectHitPixels: hitPixels,
          objectHitFraction: hitPixels / Math.max(1, hitPixelCount),
          sha256: createHash('sha256').update(readFileSync(hitcheckPath)).digest('hex'),
          pass: hitPixels > 0,
        };
      }
      const closeGatePass = !closeGate || hitcheck?.pass === true;
      const pass = state?.active === 'webgpu' && !error && samples >= 2 && !fallback && materialActive && accumulationFinite && accumulationNonZero && presentationPass && closeGatePass && (variance > 1 || hitcheckPass);
      reports.push({ id, kind, material, status: pass ? 'pass' : 'fail', backend: state, samples, error, fallback, timings: { ...generationTimings, pipelineMs: renderState?.materialPipelineDurationMs ?? null, fixtureTotalMs: performance.now() - fixtureStart }, materialDispatch, diagnostics: browserDiagnostics.slice(-40), uiHidden: hiddenUi.pass, hiddenUi, gpuWorkCompleted, presentationPass, closeGatePass, hitcheck, renderState, accumulationPixel, accumulationFinite, accumulationNonZero, bvhDebug, bvhStackOverflow, capture: capturePath, viewportCapture: viewportCapturePath, captures: { canvas: { path: capturePath, width: info.width, height: info.height, sha256: captureSha256 }, viewport: { path: viewportCapturePath, width: viewportMetadata.width, height: viewportMetadata.height, sha256: viewportSha256 }, identicalPixels: captureSha256 === viewportSha256, valid: capturesValid }, objectVisibility: { borderMean, centralMean, contrast: borderMean - centralMean, darkCentralPixels, centralPixels, darkCentralFraction, visible: objectVisible }, image: { width: info.width, height: info.height, mean, variance, nonUniform: variance > 1, objectHitPixels, objectHitFraction: objectHitPixels / Math.max(1, pixelCount) } });
      console.log(`[T052] ${id}: ${pass ? 'pass' : 'fail'} samples=${samples} error=${error || 'none'}`);
    } catch (error) {
      const state = await page.evaluate(() => ({
        ready: window.__openpbrReady ?? false,
        backend: window.__openpbrRendererBackend ?? null,
        shaderError: window.__openpbrShaderError ?? null,
        samples: window.__openpbrSamples ?? 0,
        dispatch: {
          length: window.__openpbrMtlxDispatch?.length ?? 0,
          hasEvaluate: /\bmtlxGenEvaluateBsdf\b/.test(window.__openpbrMtlxDispatch || ''),
          hasSample: /\bmtlxGenSampleBsdf\b/.test(window.__openpbrMtlxDispatch || ''),
        },
      })).catch(() => null);
      reports.push({ id, kind, material, status: 'blocked', error: String(error?.message || error), state, diagnostics: browserDiagnostics.slice(-40) });
      console.log(`[T052] ${id}: blocked ${String(error?.message || error)}`);
    }
  }
} finally {
  await browser.close();
  vite.kill();
  transpileServer.close();
  rmSync(transpileRoot, { recursive: true, force: true });
}
let materialComparison = null;
if (reports.length === 2 && reports.every(item => item.capture && existsSync(item.capture))) {
  const [reference, candidate] = reports;
  const referenceImage = await sharp(reference.capture).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const candidateImage = await sharp(candidate.capture).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  if (referenceImage.info.width !== candidateImage.info.width || referenceImage.info.height !== candidateImage.info.height) {
    throw new Error('T052 material comparison requires captures with matching dimensions.');
  }
  let absoluteDifference = 0;
  let changedPixels = 0;
  const pixelCount = referenceImage.info.width * referenceImage.info.height;
  for (let offset = 0; offset < referenceImage.data.length; offset += 3) {
    const difference = (Math.abs(referenceImage.data[offset] - candidateImage.data[offset]) +
      Math.abs(referenceImage.data[offset + 1] - candidateImage.data[offset + 1]) +
      Math.abs(referenceImage.data[offset + 2] - candidateImage.data[offset + 2])) / 3;
    absoluteDifference += difference;
    if (difference > 1) changedPixels++;
  }
  const dispatchesDiffer = reference.materialDispatch?.wgslSha256 !== candidate.materialDispatch?.wgslSha256 &&
    reference.materialDispatch?.hostGlslSha256 !== candidate.materialDispatch?.hostGlslSha256;
  const meanAbsoluteRgbDifference = absoluteDifference / Math.max(1, pixelCount);
  const changedPixelFraction = changedPixels / Math.max(1, pixelCount);
  const pass = dispatchesDiffer && meanAbsoluteRgbDifference > 0.05 && changedPixelFraction > 0.001;
  materialComparison = {
    reference: reference.id,
    candidate: candidate.id,
    dispatchesDiffer,
    meanAbsoluteRgbDifference,
    changedPixelFraction,
    changedPixels,
    pixelCount,
    pass,
  };
}
const fixturesPass = reports.every(item => item.status === 'pass');
const comparisonPass = reports.length < 2 || materialComparison?.pass === true;
const report = { version: 1, matrix, status: fixturesPass && comparisonPass ? 'pass' : 'blocked', fixtures: reports, materialComparison };
writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: report.status, total: reports.length, pass: reports.filter(item => item.status === 'pass').length, failed: reports.filter(item => item.status !== 'pass').length, output }, null, 2));
process.exit(report.status === 'pass' ? 0 : 1);
