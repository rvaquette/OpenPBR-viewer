#!/usr/bin/env node
import { chromium } from 'playwright-core';
import { existsSync, writeFileSync } from 'node:fs';

const port = process.env.T030_PORT || '5173';
const url = process.env.T030_URL || `http://localhost:${port}/OpenPBR-viewer/?renderer_backend=webgpu&webgpu_pipeline=render&renderer_mode=Pathtracer%20MTLX&gpu=true&paused=false&max_samples=4`;
const browserPath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const reportPath = process.env.T030_REPORT || 'artifacts/webgpu-render-pathtracer/render-pipeline-browser-report.json';
if (!existsSync(browserPath)) throw new Error('Chrome executable not found.');

const browser = await chromium.launch({
    executablePath: browserPath,
    headless: false,
    args: [
        '--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--use-angle=d3d11',
        '--enable-gpu', '--enable-unsafe-webgpu',
        `--unsafely-treat-insecure-origin-as-secure=http://localhost:${port}`,
    ],
});
const page = await browser.newPage({ viewport: { width: 256, height: 256 } });
const diagnostics = [];
page.on('pageerror', error => diagnostics.push(`pageerror: ${error.message}`));
try {
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 180000 });
    await page.waitForTimeout(3000);
    const state = await page.evaluate(() => ({
        backend: window.__openpbrRendererBackend || null,
        render: window.__openpbrGetWebGpuRenderState?.() || null,
        samples: window.__openpbrSamples || 0,
    }));
    const pixels = await page.evaluate(() => {
        const canvas = document.getElementById('openpbr-webgpu-canvas');
        if (!canvas) return null;
        const gl = canvas.getContext('webgl2', { preserveDrawingBuffer: true });
        if (!gl) return { canvas: { width: canvas.width, height: canvas.height }, readable: false };
        const data = new Uint8Array(4);
        gl.readPixels(128, 128, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, data);
        return { canvas: { width: canvas.width, height: canvas.height }, readable: true, pixel: Array.from(data) };
    });
    const errors = [];
    if (state.backend?.active !== 'webgpu') errors.push('WebGPU backend is not active');
    if (state.render?.renderPipelineActive !== true) errors.push(`GPURenderPipeline inactive: ${state.render?.renderFallbackReason || 'unknown'}`);
    if (state.render?.renderIncludeHostBindings !== false && state.render?.renderBindGroup !== true) errors.push('render bind group inactive');
    if ((state.render?.gpuError || null) !== null) errors.push('gpuError is not null');
    if (state.samples < 2) errors.push(`insufficient samples: ${state.samples}`);
    if (!pixels?.canvas?.width || !pixels?.canvas?.height) errors.push('canvas is empty');
    const report = { version: 1, url, state, pixels, diagnostics, status: errors.length ? 'blocked' : 'pass', errors };
    writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
    process.exitCode = errors.length ? 1 : 0;
} finally {
    await browser.close();
}
