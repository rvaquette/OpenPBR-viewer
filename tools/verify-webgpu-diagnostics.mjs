#!/usr/bin/env node
// T025: WebGPU diagnostics validation on standard-shader-ball — hit, normal, UV,
// ground diagnostics, resize, reset and accumulation resume, without any
// MaterialX dependency (the WGSL integrator only uses simple reference BRDFs).
import { chromium } from 'playwright-core';
import { spawn } from 'child_process';
import { existsSync } from 'node:fs';
import { setTimeout as sleep } from 'timers/promises';
import sharp from 'sharp';

const port = process.env.SMOKE_PORT || '5175';
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;
const url = `${BASE_URL}?renderer_backend=webgpu&renderer_mode=Pathtracer%20MTLX&gpu=true&paused=false&scene_name=standard-shader-ball`;

const BROWSER_CANDIDATES = [
    { kind: 'chrome', path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'chrome', path: 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'edge', path: 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe' },
    { kind: 'edge', path: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' },
];
const candidate = BROWSER_CANDIDATES.find(c => existsSync(c.path));
if (!candidate) {
    console.error('Chrome or Edge not found for the WebGPU diagnostics test.');
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

async function captureLuminanceVariance(page) {
    const canvas = page.locator('#openpbr-webgpu-canvas');
    const buffer = await canvas.screenshot();
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
    return { mean, variance };
}

let browser = null;
let exitCode = 0;
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

    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 120000 });
    await page.waitForFunction(() => {
        const state = window.__openpbrRendererBackend;
        return state?.active === 'webgpu' || state?.webgpuStatus === 'error';
    }, null, { timeout: 60000 });

    const initialState = await page.evaluate(() => window.__openpbrRendererBackend ?? null);
    if (initialState?.active !== 'webgpu') throw new Error(`WebGPU activation failed: ${JSON.stringify(initialState)}`);
    console.log('Activation: OK', JSON.stringify(initialState));

    const modes = ['hit', 'distance', 'normal', 'uv', 'material', 'ground', 'pdf', 'bounces'];
    for (const mode of modes) {
        await page.evaluate(debugMode => window.__openpbrSetDebugMode(debugMode), mode);
        await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 2, null, { timeout: 20000 });
        const stats = await captureLuminanceVariance(page);
        if (!Number.isFinite(stats.variance) || stats.variance < 4) {
            throw new Error(`Diagnostic mode '${mode}' produced a near-uniform image (variance=${stats.variance}); geometry/UV/hit data may not reach the shader.`);
        }
        console.log(`Diagnostic '${mode}': OK (mean=${stats.mean.toFixed(1)}, variance=${stats.variance.toFixed(1)})`);
    }

    // Resize check.
    await page.setViewportSize({ width: 96, height: 160 });
    await page.evaluate(() => window.dispatchEvent(new Event('resize')));
    await sleep(300);
    const canvasSize = await page.evaluate(() => {
        const canvas = document.getElementById('openpbr-webgpu-canvas');
        return canvas ? { width: canvas.width, height: canvas.height } : null;
    });
    if (!canvasSize || canvasSize.width < 1 || canvasSize.height < 1) throw new Error(`Resize check failed: ${JSON.stringify(canvasSize)}`);
    console.log('Resize check: OK', JSON.stringify(canvasSize));

    // Reset + resume accumulation check.
    await page.evaluate(debugMode => window.__openpbrSetDebugMode(debugMode), 'hit');
    await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 3, null, { timeout: 20000 });
    const beforeReset = await page.evaluate(() => window.__openpbrSamples ?? 0);
    await page.evaluate(() => window.__openpbrResetSamples());
    const rightAfterReset = await page.evaluate(() => window.__openpbrSamples ?? 0);
    await page.waitForFunction(() => (window.__openpbrSamples ?? 0) >= 2, null, { timeout: 20000 });
    const afterResume = await page.evaluate(() => window.__openpbrSamples ?? 0);
    if (!(rightAfterReset <= beforeReset && afterResume >= 2)) {
        throw new Error(`Reset/resume check failed: before=${beforeReset}, afterReset=${rightAfterReset}, afterResume=${afterResume}`);
    }
    console.log(`Reset/resume check: OK (before=${beforeReset}, afterReset=${rightAfterReset}, afterResume=${afterResume})`);

    console.log('\nWebGPU diagnostics validation PASSED.');
} catch (error) {
    console.error('\nWebGPU diagnostics validation FAILED:', error?.message || error);
    exitCode = 1;
} finally {
    await browser?.close();
    vite.kill();
}
process.exit(exitCode);
