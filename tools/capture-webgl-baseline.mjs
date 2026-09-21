#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = process.cwd();
const manifestPath = resolve(root, 'artifacts/webgpu-migration/baseline-manifest.json');
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));

const defaultCaptureMetadata = {
    rendererMode: 'Pathtracer MTLX',
    backend: 'webgl',
    environment: {
        envMap: 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\san_giuseppe_bridge.hdr',
        envIrradiance: 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\irradiance\\san_giuseppe_bridge.hdr',
        skyPower: null,
        sunPower: null,
        sunDir: null
    },
    camera: {
        position: [0, 0.9, 5.5],
        target: [0, 0.9, 0],
        fov: 45,
        near: 0.1,
        far: 1000
    },
    seed: 1,
    bounces: 6,
    samples: 16,
    resolution: { width: 256, height: 256 },
    tonemapping: 'viewer default',
    dispatchHash: null,
    route: 'Pathtracer MTLX'
};

for (const baseline of manifest.cases) {
    const output = resolve(root, baseline.output);
    const metadata = {
        ...defaultCaptureMetadata,
        scene: baseline.scene,
        material: baseline.material,
        class: baseline.class,
        route: 'Pathtracer MTLX',
        output,
        rendererMode: 'Pathtracer MTLX',
        bounces: manifest.captureDefaults?.bounces ?? 6,
        samples: manifest.captureDefaults?.spp ?? 16,
        resolution: {
            width: 256,
            height: 256
        },
        environment: {
            ...defaultCaptureMetadata.environment,
            materialUrl: baseline.material
        }
    };

    if (baseline.sha256 && existsSync(output)) {
        baseline.captureMetadata = metadata;
        continue;
    }
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
    baseline.captureMetadata = metadata;
    baseline.captureMetadata.dispatchHash = `sha256:${baseline.sha256}`;
    baseline.captureMetadata.tonemapping = 'viewer default';
    writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
}

writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');