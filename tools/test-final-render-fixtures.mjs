#!/usr/bin/env node
import { chromium } from 'playwright-core';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { resolve } from 'node:path';
import { tmpdir } from 'node:os';

const root = process.cwd();
const port = process.env.T0312_PORT || '5173';
const requestedFixture = process.env.T0312_FIXTURE_ID || '';
const offlineTranspilation = process.env.T0312_OFFLINE === '1';
const browserHeadless = process.env.T0312_HEADED !== '1';
const timeout = Number(process.env.T0312_TIMEOUT || 60000);
const transpilePort = Number(process.env.T0312_TRANSPILER_PORT || 5197);
const reportPath = resolve(root, process.env.T0312_REPORT || 'artifacts/webgpu-render-pathtracer/transpilation-report.json');
const outputPath = resolve(root, process.env.T0312_OUTPUT || 'artifacts/webgpu-render-pathtracer/final-render-fixture-report.json');
const trace = (...values) => console.log('[T031.2.8.6]', ...values);
const browserPath = ['C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'].find(existsSync);
if (!browserPath) throw new Error('Chrome or Edge is required for T031.2.8.');
const report = JSON.parse(readFileSync(reportPath, 'utf8'));
const materialById = new Map([
    ['open_pbr_surface', 'mtlx-library/open_pbr_default.mtlx'],
    /*['standard_surface', 'mtlx-input/standard_surface_default/standard_surface_default.mtlx'],
    ['disney_principled', 'mtlx-input/plastic/plastic.mtlx'],
    ['gltf_pbr', 'mtlx-input/metal_brushed/metal_brushed.mtlx'],
    ['usd_preview_surface', 'mtlx-input/_chrome_test/_chrome_test.mtlx'],
    ['carpaint', 'mtlx-input/carpaint/carpaint.mtlx'],
    ['glass', 'mtlx-input/glass/glass.mtlx'],
    ['pearl', 'mtlx-input/pearl/pearl.mtlx'],
    ['soapbubble', 'mtlx-input/soapbubble/soapbubble.mtlx'],*/
]);
const results = [];
const transpileRoot = resolve(tmpdir(), `openpbr-t0312-transpile-${process.pid}`);
mkdirSync(transpileRoot, { recursive: true });
const transpileServer = offlineTranspilation ? null : createServer(async (request, response) => {
    response.setHeader('access-control-allow-origin', '*');
    response.setHeader('access-control-allow-methods', 'POST, OPTIONS');
    response.setHeader('access-control-allow-headers', 'content-type');
    if (request.method === 'OPTIONS') { response.writeHead(204); response.end(); return; }
    if (request.method !== 'POST' || request.url !== '/transpile') { response.writeHead(404); response.end(); return; }
    try {
        const chunks = [];
        for await (const chunk of request) chunks.push(chunk);
        const payload = JSON.parse(Buffer.concat(chunks).toString('utf8'));
        trace('transpile request', `glslBytes=${Buffer.byteLength(payload.glsl || '', 'utf8')}`);
        if (typeof payload.glsl !== 'string' || !payload.glsl.trim()) throw new Error('GLSL source is empty');
        const id = `fixture-${Date.now()}-${Math.random().toString(16).slice(2)}`;
        const input = resolve(transpileRoot, `${id}.frag.glsl`);
        const output = resolve(transpileRoot, `${id}.wgsl`);
        writeFileSync(input, payload.glsl, 'utf8');
        const transpile = spawnSync(process.execPath, [
            resolve(root, 'tools/transpile-glsl-to-wgsl.mjs'),
            '--input', input, '--output', output, '--stage', 'frag', '--entry-point', 'mtlxMaterialLibrary',
            '--artifacts-dir', resolve(transpileRoot, `${id}-artifacts`),
        ], { cwd: root, encoding: 'utf8' });
        if (transpile.status !== 0 || !existsSync(output)) throw new Error(`${transpile.stdout || ''}\n${transpile.stderr || ''}`.trim());
        trace('transpile success', `wgslBytes=${readFileSync(output).byteLength}`);
        response.writeHead(200, { 'content-type': 'application/json' });
        response.end(JSON.stringify({ wgsl: readFileSync(output, 'utf8'), stage: 'fragment' }));
    } catch (error) {
        response.writeHead(500, { 'content-type': 'application/json' });
        response.end(JSON.stringify({ error: error.message || String(error) }));
    }
});
if (transpileServer) {
    await new Promise((resolvePromise, reject) => { transpileServer.once('error', reject); transpileServer.listen(transpilePort, '127.0.0.1', resolvePromise); });
    trace('transpile server listening', `127.0.0.1:${transpilePort}`);
} else {
    trace('offline WGSL mode enabled');
}
const browser = await chromium.launch({ executablePath: browserPath, headless: browserHeadless, args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--use-angle=d3d11', '--enable-gpu', '--enable-unsafe-webgpu', `--unsafely-treat-insecure-origin-as-secure=http://localhost:${port}`] });
const context = await browser.newContext({ viewport: { width: 256, height: 256 } });
context.on('close', () => trace('browser context closed'));
browser.on('disconnected', () => trace('browser disconnected'));
if (!offlineTranspilation) {
    await context.addInitScript(({ port: hookPort }) => {
        window.__openpbrTranspileGlslToWgsl = async payload => {
            const response = await fetch(`http://127.0.0.1:${hookPort}/transpile`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(payload) });
            const result = await response.json();
            if (!response.ok) throw new Error(result.error || `Transpiler HTTP ${response.status}`);
            return result;
        };
    }, { port: transpilePort });
}
try {
    for (const fixture of (report.fixtures || []).filter(item => !requestedFixture || item.id === requestedFixture)) {
        const material = materialById.get(fixture.id);
        const result = { id: fixture.id, route: fixture.route, status: 'failed', errors: [] };
        if (!material) { result.errors.push('material mapping missing'); results.push(result); continue; }
        const mode = fixture.route === 'rasterizer' ? 'Rasterizer MTLX' : 'Pathtracer MTLX';
        const offlineParam = offlineTranspilation ? '&mtlx_transpilation=offline' : '';
        const url = `http://127.0.0.1:${port}/OpenPBR-viewer/?renderer_backend=webgpu&webgpu_pipeline=render&renderer_mode=${encodeURIComponent(mode)}&mtlx_url=${encodeURIComponent(material)}&gpu=true&paused=true${offlineParam}`;
        trace('fixture start', `${fixture.id}/${fixture.route}`, url);
        let page;
        try {
            page = await context.newPage();
        } catch (error) {
            trace('page creation failure', `${fixture.id}/${fixture.route}`, error.message);
            result.errors.push(error.message);
            results.push(result);
            continue;
        }
        const diagnostics = [];
        page.on('crash', () => { trace('page crashed', `${fixture.id}/${fixture.route}`); diagnostics.push('page crashed'); });
        page.on('close', () => trace('page closed', `${fixture.id}/${fixture.route}`));
        page.on('pageerror', error => diagnostics.push(error.message));
        page.on('console', message => {
            trace(`browser ${fixture.id}/${fixture.route}`, `${message.type()}: ${message.text()}`);
            if (message.type() === 'error' || message.type() === 'warning') diagnostics.push(`${message.type()}: ${message.text()}`);
        });
        try {
            await page.goto(url, { waitUntil: 'domcontentloaded' });
            trace('domcontentloaded', `${fixture.id}/${fixture.route}`);
            await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout });
            trace('application ready', `${fixture.id}/${fixture.route}`);
            await page.waitForFunction(() => {
                const state = window.__openpbrGetWebGpuRenderState?.();
                return state?.renderPipelineActive === true && state.renderPipelineMaterialXFinal === true;
            }, null, { timeout });
            trace('final pipeline ready', `${fixture.id}/${fixture.route}`);
            const frame = await page.evaluate(async () => {
                const rendered = window.__openpbrRenderPipelineFrame?.() === true;
                await window.__openpbrWaitForWebGpuWork?.();
                return { rendered, state: window.__openpbrGetWebGpuRenderState?.() || null };
            });
            trace('frame result', `${fixture.id}/${fixture.route}`, JSON.stringify({ rendered: frame.rendered, frameCount: frame.state?.renderPipelineFrameCount, bindGroup: frame.state?.renderBindGroup, gpuError: frame.state?.gpuError || null }));
            result.state = frame.state;
            result.rendered = frame.rendered;
            result.diagnostics = diagnostics;
            if (!frame.rendered) result.errors.push(`renderPipelineFrame returned false: ${frame.state?.renderFallbackReason || 'unknown'}`);
            if (frame.state?.renderPipelineFrameCount !== 1) result.errors.push(`expected exactly one final render frame, got ${frame.state?.renderPipelineFrameCount ?? 0}`);
            if (frame.state?.renderPipelineMaterialXFinal !== true) result.errors.push('final MaterialX render fragment was not proven active');
            if (frame.state?.renderBindGroup !== true) result.errors.push('final render bind group inactive');
            if (frame.state?.renderMissingBindings?.length) result.errors.push(`missing render bindings: ${frame.state.renderMissingBindings.join(', ')}`);
            if (frame.state?.gpuError) result.errors.push(`gpuError: ${frame.state.gpuError.message || frame.state.gpuError}`);
            if (!diagnostics.length && !result.errors.length) result.status = 'passed';
        } catch (error) {
            trace('fixture failure', `${fixture.id}/${fixture.route}`, error.message);
            result.errors.push(error.message);
            result.diagnostics = diagnostics;
            result.domError = await page.evaluate(() => ({ title: document.title, shaderError: document.getElementById('shader-error-content')?.textContent || '', ready: window.__openpbrReady === true })).catch(() => null);
        } finally { if (!page.isClosed()) await page.close().catch(error => trace('page close failure', error.message)); }
        trace('fixture end', `${fixture.id}/${fixture.route}`, result.status);
        results.push(result);
    }
} catch (error) {
    trace('matrix failure', error.message);
    results.push({ id: requestedFixture || 'matrix', route: 'unknown', status: 'failed', errors: [error.message] });
} finally {
    await context.close().catch(error => trace('context close failure', error.message));
    await browser.close().catch(error => trace('browser close failure', error.message));
    if (transpileServer) await new Promise(resolvePromise => transpileServer.close(resolvePromise));
}
const output = { version: 1, task: 'T031.2.8', status: results.every(result => result.status === 'passed') ? 'pass' : 'blocked', fixtures: results };
writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: output.status, fixtures: results.length, passed: results.filter(result => result.status === 'passed').length, failed: results.filter(result => result.status !== 'passed').length, output: outputPath }, null, 2));
process.exitCode = output.status === 'pass' ? 0 : 1;