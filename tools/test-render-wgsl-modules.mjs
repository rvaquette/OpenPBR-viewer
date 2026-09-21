#!/usr/bin/env node
import { chromium } from 'playwright-core';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = process.cwd();
const port = process.env.T023_PORT || '5173';
const browserHeadless = process.env.T023_HEADLESS !== 'false';
const pageUrl = process.env.T023_URL || `http://localhost:${port}/OpenPBR-viewer/`;
const angleBackend = process.env.T023_ANGLE || 'd3d11';
const reportPath = resolve(root, process.argv[2] || 'artifacts/webgpu-render-pathtracer/transpilation-report.json');
const outputPath = resolve(root, process.argv[3] || 'artifacts/webgpu-render-pathtracer/render-wgsl-module-report.json');
const vertexModulePath = resolve(root, 'src/webgpu/fullscreenTriangle.wgsl.js');
const browserCandidates = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
];
const browserPath = browserCandidates.find(existsSync);
if (!browserPath) throw new Error('Chrome or Edge is required for T023.');
if (!existsSync(reportPath)) throw new Error(`Missing transpilation report: ${reportPath}`);
const report = JSON.parse(readFileSync(reportPath, 'utf8'));
const vertexSource = readFileSync(vertexModulePath, 'utf8').match(/`([\s\S]*)`/)?.[1] || '';
const browser = await chromium.launch({
    executablePath: browserPath,
    headless: browserHeadless,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', `--use-angle=${angleBackend}`, '--enable-gpu', '--enable-unsafe-webgpu', `--unsafely-treat-insecure-origin-as-secure=http://localhost:${port}`],
});
const page = await browser.newPage();
const results = [];
try {
    await page.goto(pageUrl, { waitUntil: 'domcontentloaded' });
    const deviceState = await page.evaluate(async () => {
        if (!window.isSecureContext) return { supported: false, error: 'insecure context', secureContext: false, webgpu: typeof navigator.gpu };
        if (!navigator.gpu) return { supported: false, error: 'navigator.gpu unavailable', secureContext: true };
        const adapter = await navigator.gpu.requestAdapter();
        if (!adapter) return { supported: false, error: 'GPUAdapter unavailable', secureContext: true, webgpu: 'available' };
        const device = await adapter.requestDevice();
        return { supported: true, secureContext: true, limits: { maxBindingsPerBindGroup: device.limits.maxBindingsPerBindGroup } };
    });
    if (!deviceState.supported) {
        const output = { version: 1, browser: browserPath, device: deviceState, status: 'blocked', fixtures: [] };
        writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
        console.error(`T023 blocked: ${deviceState.error}`);
        throw new Error(deviceState.error);
    }
    const vertexResult = await page.evaluate(async source => {
        const adapter = await navigator.gpu.requestAdapter();
        const device = await adapter.requestDevice();
        const module = device.createShaderModule({ code: source });
        const info = await module.getCompilationInfo();
        return { errors: info.messages.filter(message => message.type === 'error').map(message => message.message) };
    }, vertexSource);
    for (const fixture of report.fixtures || []) {
        const result = { id: fixture.id, route: fixture.route, status: 'failed', errors: [] };
        try {
            if (fixture.status !== 'transpiled' || !fixture.wgsl || !existsSync(fixture.wgsl)) throw new Error('WGSL fixture output unavailable');
            const fragmentSource = readFileSync(fixture.wgsl, 'utf8');
            const fragmentResult = await page.evaluate(async source => {
                const adapter = await navigator.gpu.requestAdapter();
                const device = await adapter.requestDevice();
                const module = device.createShaderModule({ code: source });
                const info = await module.getCompilationInfo();
                return { errors: info.messages.filter(message => message.type === 'error').map(message => message.message) };
            }, fragmentSource);
            result.errors = [...vertexResult.errors, ...fragmentResult.errors];
            result.status = result.errors.length === 0 ? 'pass' : 'blocked';
        } catch (error) {
            result.errors = [error?.message || String(error)];
        }
        results.push(result);
        console.log(`${result.route}/${result.id}: ${result.status}`);
    }
    const output = { version: 1, browser: browserPath, device: deviceState, vertex: vertexResult, status: results.every(result => result.status === 'pass') ? 'pass' : 'blocked', fixtures: results };
    writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
    process.exitCode = output.status === 'pass' ? 0 : 1;
} finally {
    await browser.close();
}
