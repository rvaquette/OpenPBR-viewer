#!/usr/bin/env node
import { existsSync, readFileSync, statSync } from 'node:fs';

const reportPath = process.argv[2] || 'artifacts/webgpu-render-pathtracer/glsl-vulkan/report.json';
const report = JSON.parse(readFileSync(reportPath, 'utf8'));
const expectedFixtures = new Set([
    'open_pbr_surface',
    'standard_surface',
    'disney_principled',
    'gltf_pbr',
    'usd_preview_surface',
    'carpaint',
    'glass',
    'pearl',
    'soapbubble',
]);
const expectedRoutes = new Set(['pathtracer', 'rasterizer']);
const errors = [];

for (const item of report.fixtures || []) {
    const label = `${item.route}/${item.id}`;
    if (item.status !== 'compiled') errors.push(`${label}: status=${item.status}`);
    if (!expectedFixtures.has(item.id)) errors.push(`${label}: unexpected fixture`);
    if (!expectedRoutes.has(item.route)) errors.push(`${label}: unexpected route`);
    if (!item.glsl || !existsSync(item.glsl) || statSync(item.glsl).size === 0) errors.push(`${label}: missing GLSL source`);
    if (!item.spv || !existsSync(item.spv) || statSync(item.spv).size === 0) errors.push(`${label}: missing SPIR-V`);
}

if ((report.fixtures || []).length !== expectedFixtures.size * expectedRoutes.size) {
    errors.push(`expected ${expectedFixtures.size * expectedRoutes.size} cases, got ${(report.fixtures || []).length}`);
}

if (errors.length > 0) {
    console.error(JSON.stringify({ pass: false, errors }, null, 2));
    process.exitCode = 1;
} else {
    console.log(JSON.stringify({
        pass: true,
        fixtures: report.fixtures.length,
        compiled: report.fixtures.length,
        nonEmptyGlsl: report.fixtures.length,
        nonEmptySpv: report.fixtures.length,
    }, null, 2));
}
