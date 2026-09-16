#!/usr/bin/env node
// Minimal reproduction for T032.2: the lights[] loop should affect the rendered image
// in the same page/session. This test intentionally fails while the bug is present,
// and will pass once the lights contribution reaches the shader output.
import { chromium } from 'playwright-core';
import { spawn } from 'child_process';
import { existsSync } from 'node:fs';
import sharp from 'sharp';

const port = process.env.SMOKE_PORT || '5185';
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;
const TEST_LIGHT = {
  name: 'test_light',
  type: 'point',
  intensity: 1000,
  decay_rate: 0,
  color: [1, 1, 1],
  position: [0, 10, 0],
  direction: [0, -1, 0],
  u: [0, 0, 0],
  v: [0, 0, 0],
  inner_angle: '40',
  outer_angle: '60',
};
const LIGHT_QUERY = `&mtlx_lights_json=${encodeURIComponent(JSON.stringify([TEST_LIGHT]))}`;
const url = `${BASE_URL}?renderer_backend=webgpu&renderer_mode=Pathtracer%20MTLX&gpu=true&paused=false&scene_name=standard-shader-ball&skyPower=0&sunPower=-4&webgpu_debug_mode=hit${LIGHT_QUERY}`;

const CANDIDATES = [
  { path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' },
  { path: 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe' },
  { path: 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe' },
  { path: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' },
];
const browserPath = CANDIDATES.find(candidate => existsSync(candidate.path))?.path;
if (!browserPath) {
  console.error('Chrome or Edge not found for the lights[] minimal test.');
  process.exit(1);
}

console.log('Starting Vite server...');
const vite = spawn(`npx vite --port ${port}`, [], { shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
await new Promise((resolvePromise, reject) => {
  const timeout = setTimeout(() => reject(new Error('Vite timeout')), 60000);
  const onOutput = data => {
    if (/Local:|localhost:/i.test(data.toString())) {
      clearTimeout(timeout);
      resolvePromise();
    }
  };
  vite.stdout.on('data', onOutput);
  vite.stderr.on('data', onOutput);
  vite.on('error', reject);
});
console.log('Vite ready.');

let browser = null;
let exitCode = 0;
try {
  browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--enable-gpu', '--enable-unsafe-webgpu'],
  });
  const context = await browser.newContext({ viewport: { width: 128, height: 128 } });
  const page = await context.newPage();

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 120000 });
  await page.waitForFunction(() => window.__openpbrRendererBackend?.active === 'webgpu', null, { timeout: 60000 });
  await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 4, null, { timeout: 30000 });

  const urlDiagnostic = await page.evaluate(() => window.__openpbrGetLightsDiagnostic());
  const urlPackedLight = urlDiagnostic.renderer?.lights?.[0];
  if (urlDiagnostic.routeLights?.length !== 1 || urlDiagnostic.renderer?.lightCount !== 1 || urlDiagnostic.renderer?.strideBytes !== 96 || urlPackedLight?.position?.[1] !== 10 || urlPackedLight?.intensity !== 1000) {
    throw new Error(`mtlx_lights_json contract diagnostic mismatch: ${JSON.stringify(urlDiagnostic)}`);
  }
  console.log(`mtlx_lights_json contract: count=${urlDiagnostic.renderer.lightCount}, stride=${urlDiagnostic.renderer.strideBytes} bytes, buffer=${urlDiagnostic.renderer.bufferSizeBytes} bytes`);

  await page.evaluate(() => window.__openpbrSetTestLights([]));
  await page.waitForTimeout(500);
  const baseRgb = await readAverageRgb();
  const base = baseRgb.reduce((sum, value) => sum + value, 0) / 3;

  console.log(`baseline luminance=${base.toFixed(3)}`);

  await page.evaluate(() => {
    window.__openpbrSetTestLights([{
      name: 'test_light',
      type: 0,
      intensity: 1000,
      decayRate: 0,
      color: [1, 1, 1],
      position: [0, 10, 0],
      direction: [0, -1, 0],
      u: [0, 0, 0],
      v: [0, 0, 0],
      innerCone: 0.7660444431,
      outerCone: 0.5,
    }]);
  });
  const lightDiagnostic = await page.evaluate(() => window.__openpbrGetLightsDiagnostic());
  const packedLight = lightDiagnostic.renderer?.lights?.[0];
  if (lightDiagnostic.renderer?.lightCount !== 1 || lightDiagnostic.renderer?.strideBytes !== 96 || packedLight?.type !== 0 || packedLight?.position?.[1] !== 10 || packedLight?.intensity !== 1000) {
    throw new Error(`lights[] contract diagnostic mismatch: ${JSON.stringify(lightDiagnostic)}`);
  }
  const comparableFields = light => ({
    type: light?.type,
    position: light?.position,
    direction: light?.direction,
    intensity: light?.intensity,
    decayRate: light?.decayRate,
    innerCone: light?.innerCone,
    outerCone: light?.outerCone,
    u: light?.u,
    v: light?.v,
  });
  if (JSON.stringify(comparableFields(urlPackedLight)) !== JSON.stringify(comparableFields(packedLight))) {
    throw new Error(`mtlx_lights_json/setLights packing mismatch: ${JSON.stringify({ url: urlPackedLight, manual: packedLight })}`);
  }
  console.log(`lights[] contract: count=${lightDiagnostic.renderer.lightCount}, stride=${lightDiagnostic.renderer.strideBytes} bytes, buffer=${lightDiagnostic.renderer.bufferSizeBytes} bytes`);
  const gpuDiagnostic = await page.evaluate(async () => window.__openpbrReadLightsGpuDiagnostic());
  if (gpuDiagnostic?.lightCount !== 1 || gpuDiagnostic.position?.[1] !== 10 || gpuDiagnostic.direction?.[1] !== -1 || gpuDiagnostic.colorIntensity?.[3] !== 1000) {
    throw new Error(`lights[] GPU readback mismatch: ${JSON.stringify(gpuDiagnostic)}`);
  }
  console.log(`lights[] GPU readback: position=${JSON.stringify(gpuDiagnostic.position)}, intensity=${gpuDiagnostic.colorIntensity[3]}`);

  async function readAverageRgb() {
    const buffer = await page.locator('#openpbr-webgpu-canvas').screenshot();
    const { data, info } = await sharp(buffer).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const average = [0, 0, 0];
    for (let i = 0; i < data.length; i += info.channels) {
      average[0] += data[i];
      average[1] += data[i + 1];
      average[2] += data[i + 2];
    }
    const count = Math.max(1, data.length / info.channels);
    return average.map(value => value / count);
  }

  await page.evaluate(() => window.__openpbrSetDebugMode('lightLoop'));
  await page.waitForTimeout(500);
  const oneLightLoop = await readAverageRgb();
  await page.evaluate(() => window.__openpbrSetTestLights([]));
  await page.waitForTimeout(500);
  const noLightLoop = await readAverageRgb();
  const loopDelta = oneLightLoop.map((value, index) => value - noLightLoop[index]);
  if (Math.max(...loopDelta.map(Math.abs)) < 0.1 || loopDelta[1] <= 0.1) {
    throw new Error(`lights[] loop diagnostic mismatch: ${JSON.stringify({ noLightLoop, oneLightLoop })}`);
  }
  console.log(`lights[] loop diagnostic: noLight=${JSON.stringify(noLightLoop)}, oneLight=${JSON.stringify(oneLightLoop)}, delta=${JSON.stringify(loopDelta)}`);
  await page.evaluate(() => {
    window.__openpbrSetTestLights([{ type: 0, intensity: 1000, decayRate: 0, color: [1, 1, 1], position: [0, 10, 0], direction: [0, -1, 0], u: [0, 0, 0], v: [0, 0, 0], innerCone: 0.7660444431, outerCone: 0.5 }]);
    window.__openpbrSetDebugMode('hit');
  });
  await page.waitForTimeout(250);

  await page.waitForTimeout(500);
  const litRgb = await readAverageRgb();
  const lit = litRgb.reduce((sum, value) => sum + value, 0) / 3;

  console.log(`with light luminance=${lit.toFixed(3)}`);
  const delta = Math.abs(lit - base);
  console.log(`delta=${delta.toFixed(3)}`);

  if (delta < 0.25) {
    console.error('lights[] reproduction: no measurable contribution from the light loop.');
    exitCode = 1;
  } else {
    console.log('lights[] reproduction: light contributes to the image.');
  }

  await page.evaluate(() => {
    window.__openpbrSetTestLights([{ type: 1, intensity: 1000, decayRate: 0, color: [1, 1, 1], position: [0, 10, 0], direction: [0, -1, 0], u: [0, 0, 0], v: [0, 0, 0], innerCone: 1, outerCone: 1 }]);
    window.__openpbrResetSamples();
  });
  await page.waitForTimeout(500);
  const directionalRgb = await readAverageRgb();
  const directionalDelta = directionalRgb.map((value, index) => value - baseRgb[index]);
  if (Math.max(...directionalDelta.map(Math.abs)) < 0.25) {
    console.error(`directional light: no measurable contribution (delta=${JSON.stringify(directionalDelta)})`);
    exitCode = 1;
  } else {
    console.log(`directional light: baseline=${JSON.stringify(baseRgb)}, lit=${JSON.stringify(directionalRgb)}, delta=${JSON.stringify(directionalDelta)}`);
  }

  async function validateLightFamily(label, light, expected) {
    await page.evaluate(nextLight => {
      window.__openpbrSetTestLights([nextLight]);
      window.__openpbrSetDebugMode('hit');
    }, light);
    const diagnostic = await page.evaluate(() => window.__openpbrGetLightsDiagnostic());
    const packed = diagnostic.renderer?.lights?.[0];
    if (diagnostic.renderer?.lightCount !== 1 || diagnostic.renderer?.strideBytes !== 96 || packed?.type !== expected.type || packed?.position?.[1] !== expected.positionY || packed?.intensity !== expected.intensity) {
      throw new Error(`${label} JS packing mismatch: ${JSON.stringify(diagnostic)}`);
    }
    const gpu = await page.evaluate(async () => window.__openpbrReadLightsGpuDiagnostic());
    if (gpu?.lightCount !== 1 || gpu.position?.[1] !== expected.positionY || gpu.colorIntensity?.[3] !== expected.intensity) {
      throw new Error(`${label} GPU packing mismatch: ${JSON.stringify(gpu)}`);
    }
    if (expected.u && JSON.stringify(gpu.edgeU.slice(0, 3)) !== JSON.stringify(expected.u)) {
      throw new Error(`${label} edgeU mismatch: ${JSON.stringify(gpu)}`);
    }
    if (expected.v && JSON.stringify(gpu.edgeV.slice(0, 3)) !== JSON.stringify(expected.v)) {
      throw new Error(`${label} edgeV mismatch: ${JSON.stringify(gpu)}`);
    }
    await page.waitForTimeout(500);
    const rgb = await readAverageRgb();
    const delta = rgb.map((value, index) => value - baseRgb[index]);
    if (Math.max(...delta.map(Math.abs)) < 0.25) {
      throw new Error(`${label} produced no measurable contribution: ${JSON.stringify({ baseRgb, rgb, delta })}`);
    }
    console.log(`${label}: delta=${JSON.stringify(delta)}, gpu=${JSON.stringify(gpu)}`);
  }

  await validateLightFamily('spot light', {
    type: 2, intensity: 1000, decayRate: 0, color: [1, 1, 1], position: [0, 10, 0], direction: [0, -1, 0], u: [0, 0, 0], v: [0, 0, 0], innerCone: 0.7660444431, outerCone: 0.5,
  }, { type: 2, positionY: 10, intensity: 1000 });
  await validateLightFamily('quad light', {
    type: 3, intensity: 1000, decayRate: 0, color: [1, 1, 1], position: [-5, 10, -5], direction: [0, -1, 0], u: [10, 0, 0], v: [0, 0, 10], innerCone: 1, outerCone: 1,
  }, { type: 3, positionY: 10, intensity: 1000, u: [10, 0, 0], v: [0, 0, 10] });
} catch (error) {
  console.error('lights[] minimal test failed:', error?.message || error);
  exitCode = 1;
} finally {
  await browser?.close();
  vite.kill();
}
process.exit(exitCode);
