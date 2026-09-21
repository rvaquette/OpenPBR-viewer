#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';

const root = process.cwd();
const inputReportPath = resolve(process.argv[2] || 'artifacts/webgpu-render-pathtracer/glsl-vulkan/report.json');
const outputReportPath = resolve(process.argv[3] || 'artifacts/webgpu-render-pathtracer/transpilation-report.json');
if (!existsSync(inputReportPath)) throw new Error(`Missing GLSL report: ${inputReportPath}`);
const inputReport = JSON.parse(readFileSync(inputReportPath, 'utf8'));
const results = [];

for (const item of inputReport.fixtures || []) {
    const result = { id: item.id, route: item.route, material: item.material, status: 'failed', glsl: item.glsl };
    const output = resolve(dirname(item.glsl), `${item.route}.fragment-render.wgsl`);
    const manifest = `${output}.manifest.json`;
    const artifactsDir = resolve(dirname(output), `${item.route}.transpile-artifacts`);
    try {
        if (!existsSync(item.glsl)) throw new Error(`missing GLSL source: ${item.glsl}`);
        execFileSync(process.execPath, [
            'tools/transpile-glsl-to-wgsl.mjs',
            '--mode', 'fragment-render',
            '--input', item.glsl,
            '--output', output,
            '--manifest', manifest,
            '--artifacts-dir', artifactsDir,
        ], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
        if (!existsSync(output) || readFileSync(output).length === 0) throw new Error(`missing WGSL output: ${output}`);
            if (item.route === 'rasterizer' || item.route === 'pathtracer') {
                const rasterWgsl = readFileSync(output, 'utf8')
                    .replace(/textureSample\(([^\n()]*)\)/g, 'textureSampleLevel($1, 0.0)');
                writeFileSync(output, `diagnostic(off, derivative_uniformity);\n${rasterWgsl}`, 'utf8');
            }
        result.status = 'transpiled';
        result.wgsl = output;
        result.manifest = manifest;
        result.diagnostics = {
            glslang: resolve(artifactsDir, 'glslang.log'),
            naga: resolve(artifactsDir, 'naga.log'),
        };
        const manifestData = JSON.parse(readFileSync(manifest, 'utf8'));
        result.hashes = {
            glslSha256: manifestData.inputSha256,
            spirvSha256: manifestData.spvSha256,
            wgslSha256: manifestData.wgslSha256,
        };
    } catch (error) {
        result.error = [error.stdout, error.stderr, error.message].filter(Boolean).join('\n');
    }
    results.push(result);
    console.log(`${item.route}/${item.id}: ${result.status}`);
}

mkdirSync(dirname(outputReportPath), { recursive: true });
writeFileSync(outputReportPath, `${JSON.stringify({
    version: 1,
    sourceReport: inputReportPath,
    stages: ['fragment'],
    status: results.every(result => result.status === 'transpiled') ? 'pass' : 'blocked',
    fixtures: results,
}, null, 2)}\n`, 'utf8');
process.exitCode = results.some(result => result.status !== 'transpiled') ? 1 : 0;
