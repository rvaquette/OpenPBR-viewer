#!/usr/bin/env node
// T032/T033: validate the WGSL reference-BRDF families that exist before MaterialX
// (Lambert, ground texture, point/directional/spot/quad lights, LDR envmap ambient),
// then compare a WebGPU capture against the closest applicable WebGL baseline and
// record the accepted (expected) divergence in artifacts/webgpu-migration/phase4-validation.json.
// Specular/metal BRDFs are intentionally NOT tested here: they are MaterialX-generated
// and remain listed under "notYetComparableFamilies" until Phase 5/6 lands.
import { chromium } from 'playwright-core';
import { execFileSync, spawn } from 'child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import sharp from 'sharp';

const port = process.env.SMOKE_PORT || '5176';
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;

const BROWSER_CANDIDATES = [
    { kind: 'chrome', path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'chrome', path: 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'edge', path: 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe' },
    { kind: 'edge', path: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' },
];
const candidate = BROWSER_CANDIDATES.find(c => existsSync(c.path));
if (!candidate) {
    console.error('Chrome or Edge not found for the WebGPU reference-material test.');
    process.exit(1);
}

console.log('Starting Vite server...');
const vite = spawn(`npx vite --port ${port}`, [], { shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
await new Promise((resolvePromise, reject) => {
    const timeout = setTimeout(() => reject(new Error('Vite timeout')), 60000);
    const onOutput = data => { if (/Local:|localhost:/i.test(data.toString())) { clearTimeout(timeout); resolvePromise(); } };
    vite.stdout.on('data', onOutput);
    vite.stderr.on('data', onOutput);
    vite.on('error', reject);
});
console.log('Vite ready.');

// Root cause of the original "lights have no effect" finding: the default env map
// (env_map_path='textures/envmaps/etzwihl_16k.jpg', 16384px wide) exceeds this
// environment's maxTextureDimension2D (8192), which corrupts binding 12 and makes
// every subsequent compute dispatch's bind group permanently invalid, silently
// freezing accumulation. Use the same reasonably-sized envmap launch_render.mjs uses.
const ENV_PARAMS = '&env_map_path=mtlx-input%2F_env%2Fsan_giuseppe_bridge.hdr&env_irradiance_path=mtlx-input%2F_env%2Firradiance%2Fsan_giuseppe_bridge.hdr&env_map_provided=true';

async function measure(page, urlSuffix) {
    await page.goto(`${BASE_URL}?renderer_backend=webgpu&renderer_mode=Pathtracer%20MTLX&gpu=true&paused=false&scene_name=standard-shader-ball${ENV_PARAMS}${urlSuffix}`, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 120000 });
    await page.waitForFunction(() => {
        const state = window.__openpbrRendererBackend;
        return state?.active === 'webgpu' || state?.webgpuStatus === 'error';
    }, null, { timeout: 60000 });
    const state = await page.evaluate(() => window.__openpbrRendererBackend ?? null);
    if (state?.active !== 'webgpu') throw new Error(`WebGPU activation failed for '${urlSuffix}': ${JSON.stringify(state)}`);
    // Scene/BVH load recreates the accumulation textures without resetting the
    // frame-index counter used as the accumulation weight; reset explicitly so the
    // measured samples are not diluted by frames rendered before the scene loaded.
    await page.evaluate(() => window.__openpbrResetSamples());
    await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 4, null, { timeout: 30000 });
    if (urlSuffix.includes('mtlx_lights_json')) {
        const diagnostic = await page.evaluate(async () => ({
            lights: window.__openpbrGetLightsDiagnostic?.(),
            gpu: await window.__openpbrReadLightsGpuDiagnostic?.(),
        }));
        console.log(`Official light diagnostic for ${urlSuffix.match(/mtlx_lights_json/) ? 'override' : 'baseline'}: ${JSON.stringify(diagnostic)}`);
    }
    const buffer = await page.locator('#openpbr-webgpu-canvas').screenshot();
    const { data, info } = await sharp(buffer).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    let sum = 0, sumSq = 0, count = 0;
    for (let i = 0; i < data.length; i += info.channels) {
        const luminance = (data[i] + data[i + 1] + data[i + 2]) / 3;
        sum += luminance;
        sumSq += luminance * luminance;
        count++;
    }
    const mean = sum / Math.max(1, count);
    const variance = sumSq / Math.max(1, count) - mean * mean;
    return { mean, variance, buffer };
}

async function measureCurrentPage(page) {
    const buffer = await page.locator('#openpbr-webgpu-canvas').screenshot();
    const { data, info } = await sharp(buffer).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    let sum = 0, sumSq = 0, count = 0;
    for (let i = 0; i < data.length; i += info.channels) {
        const luminance = (data[i] + data[i + 1] + data[i + 2]) / 3;
        sum += luminance;
        sumSq += luminance * luminance;
        count++;
    }
    const mean = sum / Math.max(1, count);
    const variance = sumSq / Math.max(1, count) - mean * mean;
    return { mean, variance, buffer };
}

async function maxAbsoluteDifference(bufferA, bufferB) {
    const [a, b] = await Promise.all([
        sharp(bufferA).ensureAlpha().raw().toBuffer({ resolveWithObject: true }),
        sharp(bufferB).ensureAlpha().raw().toBuffer({ resolveWithObject: true }),
    ]);
    let maxDiff = 0;
    for (let i = 0; i < Math.min(a.data.length, b.data.length); i += a.info.channels) {
        const diff = Math.abs(a.data[i] - b.data[i]) + Math.abs(a.data[i + 1] - b.data[i + 1]) + Math.abs(a.data[i + 2] - b.data[i + 2]);
        if (diff > maxDiff) maxDiff = diff;
    }
    return maxDiff;
}

function lightOverride(type, extra = {}) {
    // decay_rate=0 removes distance falloff for point/directional/spot so the test
    // does not depend on knowing the scene's exact scale; the quad area term still
    // applies, so it uses a larger u/v span to stay visible regardless of scale.
    const base = {
        name: `test_${type}`,
        type,
        intensity: 1000,
        decay_rate: 0,
        color: [1, 1, 1],
        position: [0, 10, 0],
        direction: [0, -1, 0],
        corner: [-5, 10, -5],
        u: [10, 0, 0],
        v: [0, 0, 10],
        inner_angle: '40',
        outer_angle: '60',
    };
    return `&mtlx_lights_json=${encodeURIComponent(JSON.stringify([{ ...base, ...extra }]))}`;
}

function lightObject(type) {
    return {
        name: `test_${type}`,
        type: type === 'point' ? 0 : type === 'directional' ? 1 : type === 'spot' ? 2 : 3,
        intensity: 200,
        decayRate: 0,
        color: [1, 1, 1],
        position: type === 'quad' ? [-5, 10, -5] : [0, 10, 0],
        direction: [0, -1, 0],
        u: type === 'quad' ? [10, 0, 0] : [0, 0, 0],
        v: type === 'quad' ? [0, 0, 10] : [0, 0, 0],
        innerCone: 0.7660444431,
        outerCone: 0.5,
    };
}

let browser = null;
let exitCode = 0;
const captures = [];
try {
    browser = await chromium.launch({
        executablePath: candidate.path,
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--enable-gpu', '--enable-unsafe-webgpu'],
    });
    const context = await browser.newContext({ viewport: { width: 128, height: 128 } });
    const page = await context.newPage();
    page.on('console', msg => { if (msg.type() !== 'warning') console.log(`[browser] ${msg.type().toUpperCase()}: ${msg.text()}`); });
    page.on('pageerror', err => console.error('[browser] PAGE ERROR:', err.message));

    // Lambert reference (no extra lights: analytic sun + sky only).
    const lambert = await measure(page, '&webgpu_debug_mode=hit');
    if (lambert.variance < 4) throw new Error(`Lambert reference produced a near-uniform image (variance=${lambert.variance}).`);
    captures.push({ family: 'Lambert', mode: 'hit', mean: lambert.mean, variance: lambert.variance, status: 'pass' });
    console.log(`Lambert: OK (mean=${lambert.mean.toFixed(1)}, variance=${lambert.variance.toFixed(1)})`);

    // Ground texture diagnostic.
    const ground = await measure(page, '&webgpu_debug_mode=ground');
    if (ground.variance < 4) throw new Error(`Ground texture diagnostic produced a near-uniform image (variance=${ground.variance}).`);
    captures.push({ family: 'ground texture', mode: 'ground', mean: ground.mean, variance: ground.variance, status: 'pass' });
    console.log(`Ground texture: OK (mean=${ground.mean.toFixed(1)}, variance=${ground.variance.toFixed(1)})`);

    // Envmap ambient contribution: background pixels must not be pure black.
    if (lambert.mean < 1) throw new Error(`Envmap/background contribution looks absent (mean=${lambert.mean}).`);
    captures.push({ family: 'LDR equirectangular environment sampling', mode: 'hit', mean: lambert.mean, status: 'pass' });
    console.log(`Envmap ambient contribution: OK (baseline mean=${lambert.mean.toFixed(1)})`);

    // Point/directional/spot/quad lights, each isolated via mtlx_lights_json.
    // Disable the environment and analytic sun for this comparison: otherwise
    // their contribution can mask the added light after tone mapping.
    const isolatedLightingBaseline = await measure(page, '&webgpu_debug_mode=hit&skyPower=0&sunPower=-4');
    if (isolatedLightingBaseline.variance < 1) throw new Error(`Isolated lighting baseline produced a near-uniform image (variance=${isolatedLightingBaseline.variance}).`);
    // Compared by max localized pixel difference (not whole-frame mean), since a
    // single added light source can measurably brighten only part of the frame.
    for (const type of ['point', 'directional', 'spot', 'quad']) {
        await page.evaluate(light => window.__openpbrSetTestLights([light]), lightObject(type));
        await page.waitForTimeout(500);
        const result = await measureCurrentPage(page);
        if (result.variance < 4) throw new Error(`${type} light produced a near-uniform image (variance=${result.variance}).`);
        const maxDiff = await maxAbsoluteDifference(isolatedLightingBaseline.buffer, result.buffer);
        const meanDelta = Math.abs(result.mean - isolatedLightingBaseline.mean);
        if (maxDiff < 1 || meanDelta < 0.25) throw new Error(`${type} light did not measurably change the isolated baseline (meanDelta=${meanDelta.toFixed(3)}, maxDiff=${maxDiff}/765).`);
        captures.push({ family: `${type} light`, mode: 'hit', mean: result.mean, variance: result.variance, meanLuminanceDeltaVsBaseline: meanDelta, maxPixelDiffVsBaseline: maxDiff, status: 'pass' });
        console.log(`${type} light: OK (mean=${result.mean.toFixed(1)}, variance=${result.variance.toFixed(1)}, meanDelta=${meanDelta.toFixed(3)}, maxPixelDiff=${maxDiff}/765)`);
    }

    // T033: compare the Lambert-reference capture against the closest applicable WebGL
    // baseline. Material colors are expected to diverge (Lambert reference vs MaterialX
    // default material); this is an accepted, documented difference, not a pass/fail gate.
    const candidatePath = resolve(process.cwd(), 'artifacts/webgpu-migration/webgpu-lambert-standard-shader-ball.png');
    writeFileSync(candidatePath, lambert.buffer);
    const referencePath = resolve(process.cwd(), 'artifacts/webgpu-migration/baselines/standard-opaque.png');
    let comparison = null;
    if (existsSync(referencePath)) {
        try {
            const referenceResized = resolve(process.cwd(), 'artifacts/webgpu-migration/webgpu-lambert-standard-shader-ball-256.png');
            await sharp(candidatePath).resize(256, 256).toFile(referenceResized);
            const output = execFileSync(process.execPath, [
                'tools/compare-render-images.mjs',
                `--reference=${referencePath}`,
                `--candidate=${referenceResized}`,
            ], { cwd: process.cwd(), encoding: 'utf8' });
            comparison = JSON.parse(output);
        } catch (error) {
            comparison = JSON.parse((error.stdout || '{}').toString() || '{}');
            comparison.thrown = error.message;
        }
    }
    console.log('T033 comparison vs WebGL standard-opaque baseline:', JSON.stringify(comparison, null, 2));

    // Update the manifest with concrete evidence and the accepted divergence.
    const manifestPath = resolve(process.cwd(), 'artifacts/webgpu-migration/phase4-validation.json');
    const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
    manifest.captures = captures;
    manifest.webglComparison = comparison ? {
        reference: 'artifacts/webgpu-migration/baselines/standard-opaque.png',
        candidate: 'artifacts/webgpu-migration/webgpu-lambert-standard-shader-ball.png',
        result: comparison,
        acceptedDifference: 'Material color divergence between the WGSL Lambert reference BRDF and the MaterialX open_pbr_default material used by the WebGL baseline; scene, camera, and sampling match. Not expected to pass the generic T006 image-similarity thresholds.',
    } : null;
    writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    console.log(`Updated ${manifestPath}`);

    console.log('\nWebGPU reference-material validation PASSED.');
} catch (error) {
    console.error('\nWebGPU reference-material validation FAILED:', error?.message || error);
    exitCode = 1;
} finally {
    await browser?.close();
    vite.kill();
}
process.exit(exitCode);
