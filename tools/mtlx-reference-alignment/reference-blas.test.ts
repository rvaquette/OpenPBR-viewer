import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { build } from 'esbuild';
import { BufferGeometry, Float32BufferAttribute, BoxGeometry } from 'three';
import { adaptReferenceGeometry } from '../../src/bvh/referenceSceneAdapter.js';
import { REFERENCE_BVH_PROFILES, createReferenceBvh, buildReferenceBlas, inspectReferenceBvh } from '../../src/bvh/referenceBlas.js';

function primitiveFromPositions(positions: number[]) {
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    const adapted = adaptReferenceGeometry(geometry);
    return adapted.primitives[0] || { verticesUVX: [], triangleCount: 0 };
}

function snapshot(bvh) {
    const nodes = bvh.m_nodes.slice(0, bvh.m_nodecnt);
    return { indices: Array.from(bvh.getIndices()), height: bvh.m_height,
        nodes: nodes.map((node) => ({ type: node.type, min: node.bounds.pmin.toArray(), max: node.bounds.pmax.toArray(),
            start: node.startidx, count: node.numprims, left: nodes.indexOf(node.lc), right: nodes.indexOf(node.rc) })) };
}

test('constructor profiles match reference BLAS and TLAS parameters exactly', () => {
    const blas = createReferenceBvh();
    assert.equal(REFERENCE_BVH_PROFILES.blas.algorithm, 'SplitBvh');
    assert.deepEqual([blas.m_traversal_cost, blas.m_num_bins, blas.m_max_split_depth, blas.m_min_overlap, blas.m_extra_refs_budget], [2,64,0,0.001,0]);
    const tlas = createReferenceBvh('tlas');
    assert.deepEqual([tlas.m_traversal_cost, tlas.m_num_bins, tlas.m_usesah], [10,64,false]);
    assert.throws(() => createReferenceBvh('auto'), /PROFILE_UNKNOWN/);
});

test('triangle and multi-triangle leaves retain every packed primitive', () => {
    const triangle = primitiveFromPositions([0,0,0, 1,0,0, 0,1,0]);
    const single = buildReferenceBlas(triangle);
    assert.equal(single.blasStats.maxLeafPrimitives, 1);
    const multi = buildReferenceBlas(primitiveFromPositions(Array.from({ length: 3 }, () => [0,0,0, 1,0,0, 0,1,0]).flat()));
    assert.equal(multi.blasStats.nodeCount, 1);
    assert.equal(multi.blasStats.maxLeafPrimitives, 3);
    assert.deepEqual(Array.from(multi.bvh.getIndices()), [0,1,2]);
});

test('cube and coplanar grids preserve coverage and conservative bounds', () => {
    const cube = new BoxGeometry(2, 2, 2);
    cube.clearGroups();
    const result = buildReferenceBlas(adaptReferenceGeometry(cube).primitives[0]);
    assert.equal(result.blasStats.packedPrimitiveCount, 12);
    assert.deepEqual(result.bvh.bounds().pmin.toArray(), [-1,-1,-1]);
    assert.deepEqual(result.bvh.bounds().pmax.toArray(), [1,1,1]);
    const grid = [];
    for (let index = 0; index < 64; index++) grid.push(index,0,0, index+1,0,0, index,1,0);
    const coplanar = buildReferenceBlas(primitiveFromPositions(grid));
    assert.equal(coplanar.blasStats.packedPrimitiveCount, 64);
    assert.equal(coplanar.blasStats.duplicateReferences, 0);
});

test('identical centroids, degenerate triangles and empty input have explicit outcomes', () => {
    const identical = buildReferenceBlas(primitiveFromPositions(Array.from({ length: 127 }, () => [-1,-1,0, 1,-1,0, 0,2,0]).flat()));
    assert.equal(identical.blasStats.packedPrimitiveCount, 127);
    const degenerate = buildReferenceBlas(primitiveFromPositions(Array.from({ length: 17 }, () => [0,0,0, 0,0,0, 0,0,0]).flat()));
    assert.equal(degenerate.blasStats.packedPrimitiveCount, 17);
    const empty = buildReferenceBlas({ verticesUVX: [], triangleCount: 0 });
    assert.equal(empty.blasStatus, 'empty');
    assert.equal(empty.bvh, null);
    assert.equal(empty.blasStats, null);
});

test('fresh builds do not reuse upstream mutable state or reorder mesh attributes', () => {
    const primitive = primitiveFromPositions([5,0,0, 6,0,0, 5,1,0, 0,0,0, 1,0,0, 0,1,0]);
    const before = JSON.stringify(primitive);
    const first = buildReferenceBlas(primitive);
    const second = buildReferenceBlas(primitive);
    assert.notEqual(first.bvh, second.bvh);
    assert.deepEqual(snapshot(first.bvh), snapshot(second.bvh));
    assert.equal(JSON.stringify(primitive), before);
    assert.equal(first.verticesUVX, primitive.verticesUVX);
    assert.equal(first.normalsUVY, primitive.normalsUVY);
});

test('structural oracle rejects missing references and broken leaf bounds', () => {
    const built = buildReferenceBlas(primitiveFromPositions([0,0,0, 1,0,0, 0,1,0]));
    built.bvh.m_packed_indices[0] = 9;
    assert.throws(() => inspectReferenceBvh(built.bvh, built.triangleBounds), /PERMUTATION_INVALID/);
    built.bvh.m_packed_indices[0] = 0;
    built.bvh.m_nodes[0].bounds.pmax.x = 0.5;
    assert.throws(() => inspectReferenceBvh(built.bvh, built.triangleBounds), /BOUNDS_INVALID/);
});

test('tree and permutations match isolated upstream TS on the same bounds', async () => {
    const manifest = JSON.parse(readFileSync(new URL('../../src/bvh/reference/SOURCES.json', import.meta.url), 'utf8'));
    const remoteSplit = await import(pathToFileURL(join(manifest.referenceRoot, 'src/bvh/splitBvh.ts')).href);
    const remoteBvh = await import(pathToFileURL(join(manifest.referenceRoot, 'src/bvh/bvh.ts')).href);
    const remoteBox = await import(pathToFileURL(join(manifest.referenceRoot, 'src/bvh/bbox.ts')).href);
    const remoteVector = await import(pathToFileURL(join(manifest.referenceRoot, 'src/math/vec3.ts')).href);
    const positions = [];
    for (let index = 0; index < 128; index++) {
        const offset = (index * 37) % 131;
        positions.push(offset,0,0, offset+1,0,0, offset,1,0);
    }
    const local = buildReferenceBlas(primitiveFromPositions(positions));
    const boxes = local.triangleBounds.map((bounds) => new remoteBox.BBox(new remoteVector.Vec3(...bounds.pmin.toArray()), new remoteVector.Vec3(...bounds.pmax.toArray())));
    const upstream = new remoteSplit.SplitBvh(2,64,0,0.001,0);
    upstream.build(boxes);
    assert.deepEqual(snapshot(local.bvh), snapshot(upstream));
    const localBasic = createReferenceBvh('tlas');
    localBasic.build(local.triangleBounds);
    const upstreamBasic = new remoteBvh.Bvh(10,64,false);
    upstreamBasic.build(boxes);
    assert.deepEqual(snapshot(localBasic), snapshot(upstreamBasic));
});

test('zero-budget profile rejects duplicate references and malformed BLAS inputs', () => {
    const primitive = primitiveFromPositions([0,0,0, 1,0,0, 0,1,0, 2,0,0, 3,0,0, 2,1,0]);
    const built = buildReferenceBlas(primitive);
    built.bvh.m_packed_indices[1] = built.bvh.m_packed_indices[0];
    assert.throws(() => inspectReferenceBvh(built.bvh, built.triangleBounds), /PERMUTATION_INVALID/);
    assert.throws(() => buildReferenceBlas({ verticesUVX: [{}], triangleCount: 0 }), /VERTEX_COUNT_INVALID/);
    assert.throws(() => buildReferenceBlas({ ...primitive, triangleCount: 3 }), /TRIANGLE_COUNT_INVALID/);
    const bad = { ...primitive, verticesUVX: primitive.verticesUVX.map((vertex) => ({ ...vertex })) };
    bad.verticesUVX[0].x = Infinity;
    assert.throws(() => buildReferenceBlas(bad), /POSITION_INVALID/);
});

test('BLAS builder compiles for the browser without distant renderer dependencies', async () => {
    const root = fileURLToPath(new URL('../../', import.meta.url));
    const result = await build({ absWorkingDir: root, entryPoints: ['src/bvh/referenceBlas.js'], bundle: true,
        platform: 'browser', format: 'esm', write: false, metafile: true });
    for (const file of Object.keys(result.metafile.inputs)) {
        assert.ok(file.startsWith('src/bvh/'));
        assert.ok(!/renderer|loaders|materialx|external/.test(file));
    }
    const api = await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].contents).toString('base64')}`);
    const resultMesh = api.buildReferenceBlas(primitiveFromPositions([0,0,0, 1,0,0, 0,1,0]));
    assert.equal(resultMesh.blasStats.packedPrimitiveCount, 1);
});