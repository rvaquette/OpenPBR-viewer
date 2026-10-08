import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createServer } from 'vite';
import { DEFAULT_BVH_BACKEND, AVAILABLE_BVH_BACKENDS, resolveBvhBackend } from '../../src/bvh/backend.mjs';

test('Vite resolves reference BVH adapters and the browser denoiser without node-fetch', async () => {
    const server = await createServer({configFile:false,optimizeDeps:{noDiscovery:true,include:[]},
        server:{middlewareMode:true,watch:null}});
    try {
        for (const module of ['referenceScene','referenceSceneAdapter','referenceBlas']) {
            const transformed = await server.transformRequest(`/src/bvh/${module}.js`);
            assert.ok(transformed?.code);
            assert.match(transformed.code,/\/src\/bvh\/reference\/.*\.ts/);
        }
        const denoiser = await server.transformRequest('/src/denoiser/reference/denoiser.mjs');
        assert.ok(denoiser?.code);
        const denoiserSource = readFileSync(new URL('../../src/denoiser/reference/denoiser.mjs',import.meta.url),'utf8');
        assert.doesNotMatch(denoiserSource,/sourceMappingURL=index\.mjs\.map/);
        assert.doesNotMatch(denoiser.code,/require\(['"]node-fetch['"]\)/);
        assert.match(denoiser.code,/globalThis\.fetch\.bind\(globalThis\)/);
    } finally { await server.close(); }
});

test('Three.js remains the default and reference is available explicitly', () => {
    assert.equal(DEFAULT_BVH_BACKEND, 'threejs');
    assert.deepEqual(AVAILABLE_BVH_BACKENDS, ['threejs','reference']);
    assert.equal(resolveBvhBackend(), 'threejs');
    for (const mode of ['Pathtracer MTLX', 'Rasterizer MTLX', 'Pathtracing', 'Rasterizing']) {
        assert.equal(resolveBvhBackend('threejs', mode), 'threejs');
    }
});

test('reference requests select the integrated pathtracer backend without raster fallback', () => {
    assert.equal(resolveBvhBackend('reference', 'Pathtracer MTLX'),'reference');
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
    assert.match(source,/materialDefines\.REFERENCE_BVH_ENABLED = true/);
    assert.match(source,/uploadReferenceSceneTextures\(renderer,referenceScene/);
    assert.match(source,/registerReferenceMaterialRegistry\(referenceScene,records\)/);
});