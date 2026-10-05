import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { DEFAULT_BVH_BACKEND, AVAILABLE_BVH_BACKENDS, resolveBvhBackend } from '../../src/bvh/backend.mjs';

test('Three.js remains the default and only ready backend', () => {
    assert.equal(DEFAULT_BVH_BACKEND, 'threejs');
    assert.deepEqual(AVAILABLE_BVH_BACKENDS, ['threejs']);
    assert.equal(resolveBvhBackend(), 'threejs');
    for (const mode of ['Pathtracer MTLX', 'Rasterizer MTLX', 'Pathtracing', 'Rasterizing']) {
        assert.equal(resolveBvhBackend('threejs', mode), 'threejs');
    }
});

test('reference requests fail without silently falling back', () => {
    assert.throws(() => resolveBvhBackend('reference', 'Pathtracer MTLX'), /BVH_BACKEND_NOT_READY/);
    assert.throws(() => resolveBvhBackend('reference', 'Rasterizer MTLX'), /BVH_BACKEND_ROUTE_UNSUPPORTED/);
});

test('unknown and obsolete backend names are rejected', () => {
    for (const name of ['native', 'auto', '', 'THREEJS']) {
        assert.throws(() => resolveBvhBackend(name), /BVH_BACKEND_UNKNOWN/);
    }
});

test('viewer validates backend requests before generated dispatch and guards BVH construction', () => {
    const source = readFileSync(new URL('../../main.js', import.meta.url), 'utf8');
    const guard = 'window.__openpbrBvhBackend.active = resolveBvhBackend(params.bvh_backend, params.renderer_mode)';
    assert.ok(source.includes(guard));
    assert.ok(source.indexOf(guard) < source.indexOf('// Generate GLSL from .mtlx before building the first shader.'));
    assert.match(source, /function buildBvh\(geometry\)\s*\{\s*resolveBvhBackend\(params.bvh_backend, params.renderer_mode\)/);
});