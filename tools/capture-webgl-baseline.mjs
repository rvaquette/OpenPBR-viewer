#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = process.cwd();
const manifestPath = resolve(root, 'artifacts/webgpu-migration/baseline-manifest.json');
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));

for (const baseline of manifest.cases) {
    const output = resolve(root, baseline.output);
    if (baseline.sha256 && existsSync(output)) continue;
    mkdirSync(dirname(output), { recursive: true });
    execFileSync(process.execPath, [
        'launch_render.mjs',
        '--mode=Pathtracer MTLX',
        `--scene=${baseline.scene}`,
        `--mtlx=${resolve(root, baseline.material)}`,
        `--output=${output}`,
        '--size=256x256',
        '--spp=16',
        '--bounces=6',
        '--gpu=false',
        '--denoise=false'
    ], { cwd: root, stdio: 'inherit' });

    if (!existsSync(output)) throw new Error(`Missing baseline output: ${output}`);
    baseline.sha256 = createHash('sha256').update(readFileSync(output)).digest('hex');
    writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
}

writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');