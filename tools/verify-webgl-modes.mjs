#!/usr/bin/env node
// T015: non-regression check — ?renderer_backend=webgl (implicit default) must still
// serve all four existing renderer modes without behavioral divergence.
import { execFileSync } from 'node:child_process';

const MODES = ['Rasterizer legacy', 'Rasterizer MTLX', 'Pathtracer MTLX', 'Pathtracer legacy'];
const results = [];

for (const mode of MODES) {
    const args = [
        'launch_render.mjs',
        `--mode=${mode}`,
        '--renderer_backend=webgl',
        '--gpu=false',
        '--spp=2',
        '--denoise=false',
        `--output=artifacts/webgpu-migration/t015-${mode.replace(/\s+/g, '_').toLowerCase()}.png`,
    ];
    try {
        execFileSync(process.execPath, args, { cwd: process.cwd(), stdio: 'pipe', encoding: 'utf8' });
        results.push({ mode, status: 'pass' });
    } catch (error) {
        results.push({ mode, status: 'fail', error: error?.stdout || error?.stderr || error?.message || String(error) });
    }
}

console.log(JSON.stringify(results, null, 2));
const failed = results.filter(result => result.status !== 'pass');
if (failed.length) {
    console.error(`\n${failed.length}/${results.length} renderer modes regressed under renderer_backend=webgl.`);
    process.exit(1);
}
console.log(`\nAll ${results.length} renderer modes pass under renderer_backend=webgl.`);
