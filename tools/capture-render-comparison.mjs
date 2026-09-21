#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const root = process.cwd();
const outputRoot = resolve(root, 'artifacts/webgpu-render-pathtracer/comparisons');
mkdirSync(outputRoot, { recursive: true });
const cases = [
    { id: 'open_pbr_surface', scene: 'standard-shader-ball', material: 'public/mtlx-library/open_pbr_default.mtlx' },
    { id: 'standard_surface', scene: 'standard-shader-ball', material: 'public/mtlx-input/standard_surface_default/standard_surface_default.mtlx' },
    { id: 'disney_principled', scene: 'standard-shader-ball', material: 'public/mtlx-input/plastic/plastic.mtlx' },
    { id: 'gltf_pbr', scene: 'standard-shader-ball', material: 'public/mtlx-input/metal_brushed/metal_brushed.mtlx' },
    { id: 'usd_preview_surface', scene: 'standard-shader-ball', material: 'public/mtlx-input/_chrome_test/_chrome_test.mtlx' },
    { id: 'metal', scene: 'glavenus', material: 'public/mtlx-library/open_pbr_aluminum_brushed.mtlx' },
    { id: 'carpaint', scene: 'standard-shader-ball', material: 'public/mtlx-library/open_pbr_carpaint.mtlx' },
    { id: 'glass', scene: 'bearded-man', material: 'public/mtlx-library/open_pbr_glass.mtlx' },
    { id: 'pearl', scene: 'standard-shader-ball', material: 'public/mtlx-library/open_pbr_pearl.mtlx' },
    { id: 'soapbubble', scene: 'terrain', material: 'public/mtlx-library/open_pbr_soapbubble.mtlx' },
];
const locked = { resolution: '256x256', samples: 16, bounces: 6, seed: 1, tonemapping: 'viewer default', backend: 'webgl' };
const results = [];
for (const fixture of cases) {
    const webglOutput = resolve(outputRoot, `webgl-pathtracer-${fixture.id}.png`);
    const result = { ...fixture, locked, webgl: { output: webglOutput }, webgpuRender: { status: 'blocked', reason: 'render pipeline capture requires the final MaterialX render fragment and browser GPU capture' } };
    try {
        execFileSync(process.execPath, ['launch_render.mjs', '--headless', '--start-server=true', '--mode=Pathtracer MTLX', `--scene=${fixture.scene}`, `--mtlx=${resolve(root, fixture.material)}`, `--output=${webglOutput}`, '--size=256x256', '--spp=16', '--bounces=6', '--gpu=false', '--denoise=false'], { cwd: root, stdio: 'inherit' });
        if (!existsSync(webglOutput)) throw new Error('WebGL capture missing');
        result.webgl.sha256 = createHash('sha256').update(readFileSync(webglOutput)).digest('hex');
        result.webgl.status = 'captured';
    } catch (error) {
        result.webgl.status = 'failed';
        result.webgl.error = error?.message || String(error);
    }
    results.push(result);
}
const report = { version: 1, task: 'T031', status: results.every(item => item.webgl.status === 'captured') && results.every(item => item.webgpuRender.status === 'captured') ? 'pass' : 'blocked', locked, cases: results };
writeFileSync(resolve(outputRoot, 'render-comparison-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: report.status, cases: results.length, webglCaptured: results.filter(item => item.webgl.status === 'captured').length, webgpuCaptured: results.filter(item => item.webgpuRender.status === 'captured').length }, null, 2));
process.exitCode = report.status === 'pass' ? 0 : 1;
