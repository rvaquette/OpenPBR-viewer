#!/usr/bin/env node
// T005 (specs/006-webgpu-mtlx-render-pathtracer): capture WebGL baselines for the
// `Pathtracer MTLX` and `Rasterizer MTLX` routes across the synthetic MaterialX
// fixtures and the named open_pbr_surface materials, under
// artifacts/webgpu-render-pathtracer/baselines/. Assumes a Vite dev server is
// already running on --port (default 5173); pass --start-server=true to let each
// launch_render.mjs invocation start/stop its own server instead.
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = process.cwd();
const outDir = resolve(root, 'artifacts/webgpu-render-pathtracer/baselines');
mkdirSync(outDir, { recursive: true });

const args = Object.fromEntries(process.argv.slice(2).map(a => {
    const m = a.match(/^--([^=]+)=(.*)$/);
    return m ? [m[1], m[2]] : [a.replace(/^--/, ''), 'true'];
}));
const port = args.port ?? '5173';
const startServer = args['start-server'] === 'true';

// Fixture matrix: synthetic MVP models (spec 005 T052.1) plus the named
// open_pbr_surface materials used as the plan's visual comparison set. Each
// fixture is rendered through both MTLX routes with the same scene/camera/seed.
const fixtures = [
    { id: 'open_pbr_surface',   scene: 'standard-shader-ball', material: 'public/mtlx-library/open_pbr_default.mtlx' },
    { id: 'standard_surface',   scene: 'standard-shader-ball', material: 'public/mtlx-input/standard_surface_default/standard_surface_default.mtlx' },
    { id: 'disney_principled',  scene: 'standard-shader-ball', material: 'public/mtlx-input/plastic/plastic.mtlx' },
    { id: 'gltf_pbr',           scene: 'standard-shader-ball', material: 'public/mtlx-input/metal_brushed/metal_brushed.mtlx' },
    { id: 'usd_preview_surface', scene: 'standard-shader-ball', material: 'public/mtlx-input/_chrome_test/_chrome_test.mtlx' },
    { id: 'metal',              scene: 'glavenus',              material: 'public/mtlx-library/open_pbr_aluminum_brushed.mtlx' },
    { id: 'carpaint',           scene: 'standard-shader-ball',  material: 'public/mtlx-library/open_pbr_carpaint.mtlx' },
    { id: 'glass',              scene: 'bearded-man',           material: 'public/mtlx-library/open_pbr_glass.mtlx' },
    { id: 'pearl',              scene: 'standard-shader-ball',  material: 'public/mtlx-library/open_pbr_pearl.mtlx' },
    { id: 'soapbubble',         scene: 'terrain',                material: 'public/mtlx-library/open_pbr_soapbubble.mtlx' },
];
const routes = [
    { key: 'pathtracer', mode: 'Pathtracer MTLX' },
    { key: 'rasterizer', mode: 'Rasterizer MTLX' },
];

const manifestPath = resolve(outDir, 'manifest.json');
const manifest = { version: 1, port, cases: [] };

for (const fixture of fixtures) {
    for (const route of routes) {
        const output = resolve(outDir, `${route.key}-${fixture.id}.png`);
        console.log(`Rendering ${route.mode} / ${fixture.id} -> ${output}`);
        const cliArgs = [
            'launch_render.mjs',
            '--headless',
            `--start-server=${startServer}`,
            `--port=${port}`,
            `--mode=${route.mode}`,
            `--scene=${fixture.scene}`,
            `--mtlx=${resolve(root, fixture.material)}`,
            `--output=${output}`,
            '--size=256x256',
            '--spp=16',
            '--bounces=6',
            '--gpu=false',
            '--denoise=false',
            '--browser=auto',
        ];
        execFileSync(process.execPath, cliArgs, { cwd: root, stdio: 'inherit' });
        if (!existsSync(output)) throw new Error(`Missing baseline output: ${output}`);
        const sha256 = createHash('sha256').update(readFileSync(output)).digest('hex');
        manifest.cases.push({
            id: fixture.id,
            route: route.mode,
            scene: fixture.scene,
            material: fixture.material,
            output: `artifacts/webgpu-render-pathtracer/baselines/${route.key}-${fixture.id}.png`,
            sha256,
            resolution: { width: 256, height: 256 },
            samples: 16,
            bounces: 6,
        });
        mkdirSync(dirname(manifestPath), { recursive: true });
        writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    }
}

console.log(`Wrote ${manifest.cases.length} baseline captures to ${manifestPath}`);
