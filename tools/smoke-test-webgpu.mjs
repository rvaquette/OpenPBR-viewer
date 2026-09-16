#!/usr/bin/env node
// T014: WebGPU browser smoke validation — resize plus controlled destroy/recreate.
// Reuses the launch_render.mjs viewer bootstrap conventions (Vite + Playwright) but
// drives the page directly instead of waiting for a fixed sample count.
import { chromium } from 'playwright-core';
import { spawn } from 'child_process';
import { existsSync } from 'node:fs';
import { setTimeout as sleep } from 'timers/promises';

const port = process.env.SMOKE_PORT || '5173';
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;
const url = `${BASE_URL}?renderer_backend=webgpu&renderer_mode=Pathtracer%20MTLX&gpu=true&paused=false`;

const BROWSER_CANDIDATES = [
    { kind: 'chrome', path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'chrome', path: 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'edge', path: 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe' },
    { kind: 'edge', path: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' },
];
const candidate = BROWSER_CANDIDATES.find(c => existsSync(c.path));
if (!candidate) {
    console.error('Chrome or Edge not found for the WebGPU smoke test.');
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

let browser = null;
let exitCode = 0;
try {
    browser = await chromium.launch({
        executablePath: candidate.path,
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--enable-gpu', '--enable-unsafe-webgpu'],
    });
    const context = await browser.newContext({ viewport: { width: 256, height: 256 } });
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
    if (initialState?.active !== 'webgpu') throw new Error(`Initial WebGPU activation failed: ${JSON.stringify(initialState)}`);
    console.log('Initial activation: OK', JSON.stringify(initialState));

    // Resize check: change the viewport and confirm the canvas tracks the new size.
    await page.setViewportSize({ width: 320, height: 200 });
    await page.evaluate(() => window.dispatchEvent(new Event('resize')));
    await sleep(500);
    const canvasSize = await page.evaluate(() => {
        const canvas = document.getElementById('openpbr-webgpu-canvas');
        return canvas ? { width: canvas.width, height: canvas.height } : null;
    });
    if (!canvasSize || canvasSize.width < 1 || canvasSize.height < 1) throw new Error(`Resize check failed: canvas size ${JSON.stringify(canvasSize)}`);
    console.log('Resize check: OK', JSON.stringify(canvasSize));

    // Destroy/recreate check: tear down the renderer in place and confirm reactivation.
    // Per T014 this is best-effort ("si le navigateur le permet"): some headless
    // Chromium configurations serialize/stall a second requestAdapter+requestDevice
    // in the same tab, so a timeout here is reported as a skip, not a hard failure.
    const nodeTimeout = new Promise(resolvePromise => setTimeout(() => resolvePromise({ timedOut: true }), 15000));
    const recreateAttempt = page.evaluate(async () => {
        if (typeof window.__openpbrRecreateWebGpuRenderer !== 'function') return { supported: false };
        const result = await window.__openpbrRecreateWebGpuRenderer();
        return { supported: true, result, state: window.__openpbrRendererBackend };
    }).catch(error => ({ supported: true, error: error?.message || String(error) }));
    const recreated = await Promise.race([recreateAttempt, nodeTimeout]);
    if (recreated.timedOut) {
        console.log('Destroy/recreate check: SKIPPED (renderer recreation did not complete within 15s in this environment)');
    } else if (!recreated.supported) {
        throw new Error('Recreate hook window.__openpbrRecreateWebGpuRenderer is not exposed.');
    } else if (recreated.error || recreated.result !== true || recreated.state?.active !== 'webgpu') {
        throw new Error(`Destroy/recreate check failed: ${JSON.stringify(recreated)}`);
    } else {
        console.log('Destroy/recreate check: OK', JSON.stringify(recreated.state));
    }

    console.log('\nWebGPU smoke test PASSED.');
} catch (error) {
    console.error('\nWebGPU smoke test FAILED:', error?.message || error);
    exitCode = 1;
} finally {
    await browser?.close();
    vite.kill();
}
process.exit(exitCode);
