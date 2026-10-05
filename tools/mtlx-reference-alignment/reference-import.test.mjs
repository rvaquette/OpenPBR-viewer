import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';

const root = fileURLToPath(new URL('../../', import.meta.url));
const directory = join(root, 'src/bvh/reference');
const manifest = JSON.parse(readFileSync(join(directory, 'SOURCES.json'), 'utf8'));
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');

test('six pinned TS sources preserve upstream algorithms and only adapt the mesh import', () => {
    assert.equal(manifest.files.length, 6);
    assert.equal(manifest.algorithmChanges, false);
    assert.equal(manifest.backendActivated, false);
    for (const entry of manifest.files) {
        const original = readFileSync(join(manifest.referenceRoot, entry.source));
        const local = readFileSync(join(directory, entry.target));
        assert.equal(hash(original), entry.sourceSha256, entry.source);
        assert.equal(hash(local), entry.localSha256, entry.target);
        const expected = entry.adaptation === 'mesh-import-type-only'
            ? Buffer.from(original.toString('utf8').replace('import { Mesh, MeshInstance } from "../core/mesh.js";', 'import type { Mesh, MeshInstance } from "../core/mesh.js";'))
            : original;
        assert.ok(local.equals(expected), `Unexpected source edit: ${entry.target}`);
    }
});

test('AMD and host MIT notices are retained with the derived sources', () => {
    const bytes = readFileSync(join(directory, manifest.notices.file));
    assert.equal(hash(bytes), manifest.notices.sha256);
    const notice = bytes.toString('utf8');
    assert.match(notice, /2016 Advanced Micro Devices/);
    assert.match(notice, /2019 Asif Ali/);
    assert.match(notice, /The above copyright notice and this permission notice shall be included/);
});

test('Vite compiler bundles isolated TS and preserves executable constructors', async () => {
    const result = await build({
        stdin: { resolveDir: root, loader: 'ts', contents: [
            'export { BBox } from "./src/bvh/reference/bvh/bbox.ts";',
            'export { Bvh } from "./src/bvh/reference/bvh/bvh.ts";',
            'export { SplitBvh } from "./src/bvh/reference/bvh/splitBvh.ts";',
            'export { BvhTranslator } from "./src/bvh/reference/bvh/bvhTranslator.ts";',
            'export { Vec3 } from "./src/bvh/reference/math/vec3.ts";',
            'export { Vec4 } from "./src/bvh/reference/math/vec4.ts";',
        ].join('\n') },
        absWorkingDir: root, bundle: true, platform: 'browser', format: 'esm', write: false, metafile: true,
    });
    const modules = Object.keys(result.metafile.inputs).filter((file) => file !== '<stdin>');
    assert.equal(modules.length, 6);
    for (const file of modules) {
        assert.ok(file.startsWith('src/bvh/reference/'), file);
        assert.ok(!/core\/mesh|renderer|material|loaders|external/.test(file), file);
    }
    const api = await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].contents).toString('base64')}`);
    for (const name of ['BBox', 'Bvh', 'SplitBvh', 'BvhTranslator', 'Vec3', 'Vec4']) assert.equal(typeof api[name], 'function', name);
    const bounds = [new api.BBox(new api.Vec3(0, 0, 0), new api.Vec3(1, 1, 1)),
        new api.BBox(new api.Vec3(2, 2, 2), new api.Vec3(3, 3, 3))];
    const bvh = new api.Bvh(10, 64, false);
    bvh.build(bounds);
    assert.equal(bvh.getNumIndices(), 2);
    assert.deepEqual(bvh.bounds().pmin.toArray(), [0, 0, 0]);
    assert.deepEqual(bvh.bounds().pmax.toArray(), [3, 3, 3]);
    const split = new api.SplitBvh(2, 64, 0, 0.001, 0);
    split.build(bounds);
    assert.equal(split.getNumIndices(), 2);
    const tlas = new api.Bvh(10, 64, false);
    tlas.build([new api.BBox(new api.Vec3(0, 0, 0), new api.Vec3(3, 3, 3))]);
    const translator = new api.BvhTranslator();
    translator.process(tlas, [{ bvh: split }], [{ meshID: 0, materialID: 7 }]);
    assert.equal(translator.nodes[translator.topLevelIndex].LRLeaf.z, -1);
    assert.equal(translator.nodes[translator.topLevelIndex].LRLeaf.y, 7);
});

test('production viewer retains its Three.js backend and has no reference import', () => {
    const main = readFileSync(join(root, 'main.js'), 'utf8');
    assert.match(main, /new MeshBVH\(/);
    assert.ok(!main.includes('src/bvh/reference/'));
    assert.ok(!readFileSync(join(root, 'glsl-sources.js'), 'utf8').includes('bvh/reference/'));
});