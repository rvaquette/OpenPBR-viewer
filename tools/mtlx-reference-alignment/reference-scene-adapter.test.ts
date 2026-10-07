import test from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { BufferGeometry, Float32BufferAttribute, BufferAttribute, Group, InterleavedBuffer, InterleavedBufferAttribute, Mesh, MeshBasicMaterial, Texture } from 'three';
import { adaptReferenceGeometry } from '../../src/bvh/referenceSceneAdapter.js';
import { disposeReferenceSceneResources } from '../../src/scene/referenceSceneAdapter.js';

function makeGeometry(indexed = true) {
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(indexed
        ? [0,0,0, 1,0,0, 0,1,0, 1,1,0]
        : [0,0,0, 1,0,0, 0,1,0, 1,0,0, 1,1,0, 0,1,0], 3));
    if (indexed) geometry.setIndex([0, 1, 2, 1, 3, 2]);
    return geometry;
}

test('indexed and non-indexed triangles produce the same reference positions and bounds', () => {
    const indexed = makeGeometry();
    const original = [...indexed.getAttribute('position').array];
    const first = adaptReferenceGeometry(indexed).primitives[0];
    const second = adaptReferenceGeometry(makeGeometry(false)).primitives[0];
    assert.deepEqual(first.verticesUVX, second.verticesUVX);
    assert.deepEqual(first.triangleBounds.map((bounds) => [bounds.pmin.toArray(), bounds.pmax.toArray()]),
        [[[0,0,0],[1,1,0]], [[0,0,0],[1,1,0]]]);
    assert.deepEqual(first.sourceVertexIndices, [0,1,2,1,3,2]);
    assert.deepEqual([...indexed.getAttribute('position').array], original);
    assert.equal(first.triangleCount, 2);
    assert.equal(first.materialID, null);
});

test('material groups are separate primitives and respect drawRange without applying transforms', () => {
    const geometry = makeGeometry();
    geometry.addGroup(0, 3, 0);
    geometry.addGroup(3, 3, 1);
    const adapted = adaptReferenceGeometry(geometry, { materialIDs: [7, 11], name: 'quad' });
    assert.deepEqual(adapted.primitives.map((primitive) => primitive.materialID), [7,11]);
    assert.deepEqual(adapted.primitives.map((primitive) => primitive.sourceTriangleIDs), [[0],[1]]);
    assert.equal(adapted.transformsApplied, false);
    geometry.setDrawRange(3, 3);
    assert.deepEqual(adaptReferenceGeometry(geometry).primitives[0].sourceTriangleIDs, [1]);
    assert.throws(() => adaptReferenceGeometry(geometry, { materialIDs: [7] }), /MATERIAL_ID_INVALID/);
});

test('interleaved and normalized attributes preserve UVs, normals, tangents and neutral flags', () => {
    const geometry = makeGeometry();
    const interleaved = new InterleavedBuffer(new Float32Array([0.1,0.2,9, 0.3,0.4,9, 0.5,0.6,9, 0.7,0.8,9]), 3);
    geometry.setAttribute('uv', new InterleavedBufferAttribute(interleaved, 2, 0));
    geometry.setAttribute('normal', new BufferAttribute(new Int8Array([0,0,127, 0,0,127, 0,0,127, 0,0,127]), 3, true));
    geometry.setAttribute('tangent', new Float32BufferAttribute([1,0,0,-1, 1,0,0,-1, 1,0,0,-1, 1,0,0,-1], 4));
    geometry.setAttribute('neutralFlag', new Float32BufferAttribute([1,1,1,1], 1));
    const primitive = adaptReferenceGeometry(geometry).primitives[0];
    assert.equal(primitive.verticesUVX[0].w, geometry.getAttribute('uv').getX(0));
    assert.equal(primitive.normalsUVY[0].w, geometry.getAttribute('uv').getY(0));
    assert.equal(primitive.normalsUVY[0].z, 1);
    assert.equal(primitive.tangents[0].w, -1);
    assert.deepEqual(primitive.extraAttributes.neutralFlag.values, [1,1,1,1,1,1]);
    assert.deepEqual(primitive.flags, { hasNormals: true, hasUvs: true, hasTangents: true });
});

test('empty and degenerate inputs remain explicit without invoking upstream BVH build', () => {
    const empty = new BufferGeometry();
    empty.setAttribute('position', new Float32BufferAttribute([], 3));
    assert.equal(adaptReferenceGeometry(empty).empty, true);
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute([0,0,0, 0,0,0, 0,0,0], 3));
    const primitive = adaptReferenceGeometry(geometry).primitives[0];
    assert.deepEqual(primitive.degenerateTriangleIDs, [0]);
    assert.ok(primitive.normalsUVY.every((normal) => Number.isFinite(normal.z)));
    assert.equal(primitive.triangleCount, 1);
});

test('malformed topology, groups and attributes fail instead of silently dropping triangles', () => {
    const geometry = makeGeometry();
    geometry.setIndex([0,1,99]);
    assert.throws(() => adaptReferenceGeometry(geometry), /INDEX_OUT_OF_BOUNDS/);
    geometry.setIndex([0,1]);
    assert.throws(() => adaptReferenceGeometry(geometry), /TRIANGLE_COUNT_INVALID/);
    const grouped = makeGeometry();
    grouped.addGroup(0, 3, 0);
    assert.throws(() => adaptReferenceGeometry(grouped), /GROUP_PARTITION_INVALID/);
    grouped.addGroup(0, 3, 1);
    assert.throws(() => adaptReferenceGeometry(grouped), /GROUP_PARTITION_INVALID/);
    const invalid = makeGeometry();
    invalid.getAttribute('position').setX(0, NaN);
    assert.throws(() => adaptReferenceGeometry(invalid), /ATTRIBUTE_VALUE_INVALID/);
    const short = makeGeometry();
    short.setAttribute('normal', new Float32BufferAttribute([0,0,1], 3));
    assert.throws(() => adaptReferenceGeometry(short), /ATTRIBUTE_COUNT_INVALID/);
});

test('three-component tangents use the existing local positive handedness fallback', () => {
    const geometry = makeGeometry();
    geometry.setAttribute('tangent', new Float32BufferAttribute([1,0,0, 1,0,0, 1,0,0, 1,0,0], 3));
    assert.ok(adaptReferenceGeometry(geometry).primitives[0].tangents.every((tangent) => tangent.w === 1));
});

test('adapter is a browser-compatible bundle without distant loaders or engine', async () => {
    const root = fileURLToPath(new URL('../../', import.meta.url));
    const output = await build({ absWorkingDir: root, entryPoints: ['src/bvh/referenceSceneAdapter.js'],
        bundle: true, format: 'esm', platform: 'browser', write: false, metafile: true });
    for (const input of Object.keys(output.metafile.inputs)) {
        assert.ok(input.startsWith('src/bvh/'));
        assert.ok(!/renderer|loaders|materialx|external/.test(input));
    }
    const api = await import(`data:text/javascript;base64,${Buffer.from(output.outputFiles[0].contents).toString('base64')}`);
    assert.equal(api.adaptReferenceGeometry(makeGeometry()).triangleCount, 2);
});

test('scene disposal releases source glTF materials/textures after viewer material replacement', () => {
    const texture = new Texture();
    let textureDisposed = false;
    texture.addEventListener('dispose',() => { textureDisposed = true; });
    const sourceMaterial = new MeshBasicMaterial({ map:texture });
    const viewerMaterial = new MeshBasicMaterial();
    const objectScene = new Group();
    const object = new Mesh(makeGeometry(),sourceMaterial);
    objectScene.add(object);
    object.material = viewerMaterial;

    disposeReferenceSceneResources({ objectScene,sourceMaterials:new Set([sourceMaterial]) });

    assert.equal(textureDisposed,true);
});