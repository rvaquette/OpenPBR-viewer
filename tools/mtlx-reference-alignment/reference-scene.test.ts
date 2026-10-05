import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { BufferGeometry, BoxGeometry, Float32BufferAttribute, Matrix4, Vector3, Quaternion, Object3D } from 'three';
import { adaptReferenceGeometry } from '../../src/bvh/referenceSceneAdapter.js';
import { buildReferenceBlas } from '../../src/bvh/referenceBlas.js';
import { BvhTranslator } from '../../src/bvh/reference/bvh/bvhTranslator.js';
import { buildReferenceScene, updateReferenceSceneInstances, normalizeReferenceTransform } from '../../src/bvh/referenceScene.js';

function mesh(triangles = 1) {
    const geometry = new BufferGeometry();
    const positions = [];
    for (let index = 0; index < triangles; index++) positions.push(index,0,0, index+1,0,0, index,1,0);
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    return buildReferenceBlas(adaptReferenceGeometry(geometry).primitives[0]);
}

test('two instances share a BLAS and geometry but retain distinct material IDs and transforms', () => {
    const shared = mesh();
    const scene = buildReferenceScene([shared], [
        { meshID: 0, materialID: 11 },
        { meshID: 0, materialID: 22, worldTransform: new Matrix4().makeTranslation(5, 0, 0) },
    ]);
    const leaves = scene.nodes.filter((node) => node.LRLeaf.z < 0);
    assert.equal(scene.geometry.verticesUVX.length, 3);
    assert.deepEqual(leaves.map((node) => node.LRLeaf.y).sort(), [11,22]);
    assert.ok(leaves.every((node) => node.LRLeaf.x === 0));
    assert.deepEqual(leaves.map((node) => node.LRLeaf.z).sort(), [-1,-2]);
    assert.deepEqual(scene.sceneBounds.pmin.toArray(), [0,0,0]);
    assert.deepEqual(scene.sceneBounds.pmax.toArray(), [6,1,0]);
    assert.deepEqual(shared.bvh.bounds().pmax.toArray(), [1,1,0]);
});

test('multiple meshes use global BLAS roots, triangle ranges and vertex offsets', () => {
    const first = mesh();
    const second = mesh(4);
    const scene = buildReferenceScene([first, second], [{ meshID: 0, materialID: 0 }, { meshID: 1, materialID: 7 }]);
    assert.equal(scene.topLevelIndex, first.bvh.m_nodecnt + second.bvh.m_nodecnt);
    assert.equal(scene.geometry.meshRanges[1].nodeOffset, first.bvh.m_nodecnt);
    assert.equal(scene.geometry.meshRanges[1].triangleOffset, 1);
    assert.equal(scene.geometry.meshRanges[1].vertexOffset, 3);
    assert.deepEqual(Array.from(scene.geometry.vertexIndices).slice(3),
        second.bvh.getIndices().flatMap((triangle) => [3+triangle*3, 4+triangle*3, 5+triangle*3]));
    const secondRoot = scene.nodes.find((node) => node.LRLeaf.z < 0 && node.LRLeaf.y === 7);
    assert.equal(secondRoot.LRLeaf.x, first.bvh.m_nodecnt);
    assert.ok(scene.nodes.slice(first.bvh.m_nodecnt, scene.topLevelIndex).filter((node) => node.LRLeaf.z > 0)
        .every((node) => node.LRLeaf.x >= 1));
});

test('world bounds cover all transformed corners with rotation and negative nonuniform scale', () => {
    const matrix = new Matrix4().compose(new Vector3(4,-2,3), new Quaternion().setFromAxisAngle(new Vector3(0,0,1), Math.PI/2), new Vector3(-2,3,0.5));
    const geometry = new BoxGeometry(2,4,6);
    geometry.clearGroups();
    const source = buildReferenceBlas(adaptReferenceGeometry(geometry).primitives[0]);
    const scene = buildReferenceScene([source], [{ meshID: 0, materialID: 2, worldTransform: matrix }]);
    const transform = new Matrix4().fromArray(scene.transforms[0]);
    const expectedMin = new Vector3(Infinity,Infinity,Infinity);
    const expectedMax = new Vector3(-Infinity,-Infinity,-Infinity);
    for (const x of [-1,1]) for (const y of [-2,2]) for (const z of [-3,3]) {
        const corner = new Vector3(x,y,z).applyMatrix4(transform);
        expectedMin.min(corner); expectedMax.max(corner);
    }
    scene.instanceBounds[0].pmin.toArray().forEach((value, index) => assert.ok(Math.abs(value - expectedMin.toArray()[index]) < 1e-6));
    scene.instanceBounds[0].pmax.toArray().forEach((value, index) => assert.ok(Math.abs(value - expectedMax.toArray()[index]) < 1e-6));
});

test('parent-child world matrix is applied to bounds only once', () => {
    const parent = new Object3D();
    parent.position.set(10,0,0);
    const child = new Object3D();
    child.position.set(2,0,0);
    parent.add(child); parent.updateMatrixWorld(true);
    const scene = buildReferenceScene([mesh()], [{ meshID: 0, materialID: 0, worldTransform: child.matrixWorld }]);
    assert.equal(scene.instanceBounds[0].pmin.x, 12);
    assert.equal(scene.instanceBounds[0].pmax.x, 13);
    assert.equal(scene.geometry.verticesUVX[0].x, 0);
});

test('instance update reuses geometry and BLAS, updates TLAS and handles cardinality changes', () => {
    const source = mesh();
    const scene = buildReferenceScene([source], [{ meshID: 0, materialID: 1 }]);
    const geometry = scene.geometry;
    const translator = scene.translator;
    const root = scene.nodes[0];
    updateReferenceSceneInstances(scene, [{ meshID: 0, materialID: 9, worldTransform: new Matrix4().makeTranslation(8,0,0) }]);
    assert.equal(scene.geometry, geometry);
    assert.equal(scene.meshes[0].bvh, source.bvh);
    assert.equal(scene.translator, translator);
    assert.equal(scene.nodes[0], root);
    assert.equal(scene.sceneBounds.pmin.x, 8);
    assert.equal(scene.nodes[scene.topLevelIndex].LRLeaf.y, 9);
    updateReferenceSceneInstances(scene, [{ meshID: 0, materialID: 2 }, { meshID: 0, materialID: 3 }]);
    assert.notEqual(scene.translator, translator);
    assert.ok(scene.nodes.filter((node) => node.LRLeaf.z < 0).every((node) => node.LRLeaf.x === 0));
});

test('empty scenes and invalid references/transforms have explicit outcomes', () => {
    const empty = buildReferenceScene([], []);
    assert.deepEqual(empty.nodes, []);
    assert.equal(empty.tlas, null);
    assert.equal(empty.sceneBounds, null);
    const source = mesh();
    const dormant = buildReferenceScene([source], []);
    updateReferenceSceneInstances(dormant, [{ meshID: 0, materialID: 0 }]);
    assert.equal(dormant.topLevelIndex, source.bvh.m_nodecnt);
    assert.throws(() => buildReferenceScene([source], [{ meshID: 1, materialID: 0 }]), /MESH_INVALID/);
    assert.throws(() => buildReferenceScene([source], [{ meshID: 0, materialID: null }]), /MATERIAL_INVALID/);
    assert.throws(() => normalizeReferenceTransform(new Matrix4().makeScale(0,1,1)), /SINGULAR/);
    const perspective = new Matrix4(); perspective.elements[3] = 1;
    assert.throws(() => normalizeReferenceTransform(perspective), /NON_AFFINE/);
    assert.throws(() => normalizeReferenceTransform([NaN]), /TRANSFORM_INVALID/);
    const tinyPerspective = new Matrix4(); tinyPerspective.elements[3] = 1e-50;
    assert.throws(() => normalizeReferenceTransform(tinyPerspective), /NON_AFFINE/);
    assert.throws(() => normalizeReferenceTransform({ data: [new Array(16).fill(0)] }), /TRANSFORM_INVALID/);
    assert.deepEqual(Array.from(normalizeReferenceTransform({ data: [[1,0,0,0],[0,1,0,0],[0,0,1,0],[4,5,6,1]] })).slice(12), [4,5,6,1]);
    assert.throws(() => buildReferenceScene([source], [null]), /INSTANCE_INVALID/);
});

test('mesh table rejects repeated records and update rejects changed mesh topology before mutation', () => {
    const source = mesh();
    assert.throws(() => buildReferenceScene([source, source], []), /MESH_TABLE_DUPLICATE/);
    const scene = buildReferenceScene([source], [{ meshID: 0, materialID: 1 }]);
    const previous = scene.tlas;
    assert.throws(() => updateReferenceSceneInstances(scene, [{ meshID: 9, materialID: 1 }]), /MESH_INVALID/);
    assert.equal(scene.tlas, previous);
    source.verticesUVX = [...source.verticesUVX];
    assert.throws(() => updateReferenceSceneInstances(scene, [{ meshID: 0, materialID: 1 }]), /TOPOLOGY_CHANGED/);
});

test('translation matches isolated upstream and the local scene builder bundles for browsers', async () => {
    const root = fileURLToPath(new URL('../../', import.meta.url));
    const manifest = JSON.parse(readFileSync(join(root, 'src/bvh/reference/SOURCES.json'), 'utf8'));
    const upstreamFile = join(manifest.referenceRoot, 'src/bvh/bvhTranslator.ts');
    const upstreamSource = readFileSync(upstreamFile, 'utf8').replace('import { Mesh, MeshInstance } from "../core/mesh.js";',
        'import type { Mesh, MeshInstance } from "../core/mesh.js";');
    const upstreamBuild = await build({ stdin: { contents: upstreamSource, resolveDir: dirname(upstreamFile), loader: 'ts' },
        absWorkingDir: root, bundle: true, platform: 'browser', format: 'esm', write: false, metafile: true });
    for (const input of Object.keys(upstreamBuild.metafile.inputs)) assert.ok(!/core[\\/]|renderer|loaders|materialx|external/.test(input));
    const upstream = await import(`data:text/javascript;base64,${Buffer.from(upstreamBuild.outputFiles[0].contents).toString('base64')}`);
    const scene = buildReferenceScene([mesh(), mesh(4)], [{ meshID: 0, materialID: 1 }, { meshID: 1, materialID: 7 }]);
    const translated = new upstream.BvhTranslator();
    translated.process(scene.tlas, scene.meshes, scene.instances);
    const snapshot = (nodes) => nodes.map((node) => [node.bboxmin.toArray(), node.bboxmax.toArray(), node.LRLeaf.toArray()]);
    assert.deepEqual(snapshot(scene.nodes), snapshot(translated.nodes));
    assert.equal(scene.topLevelIndex, translated.topLevelIndex);
    const localBuild = await build({ absWorkingDir: root, entryPoints: ['src/bvh/referenceScene.js'], bundle: true,
        platform: 'browser', format: 'esm', write: false, metafile: true });
    for (const input of Object.keys(localBuild.metafile.inputs)) {
        assert.ok(!/GLSL-PathTracer-JS|renderer|loaders|materialx|external/.test(input));
    }
    const local = await import(`data:text/javascript;base64,${Buffer.from(localBuild.outputFiles[0].contents).toString('base64')}`);
    assert.equal(local.buildReferenceScene([], []).activeNodeCount, 0);
});

function sceneSnapshot(scene) {
    return { topLevelIndex: scene.topLevelIndex, activeNodeCount: scene.activeNodeCount,
        nodes: scene.nodes.slice(0, scene.activeNodeCount).map((node) => [node.bboxmin.toArray(), node.bboxmax.toArray(), node.LRLeaf.toArray()]),
        vertices: scene.geometry.verticesUVX.map((vertex) => [vertex.x, vertex.y, vertex.z, vertex.w]),
        normals: scene.geometry.normalsUVY.map((normal) => [normal.x, normal.y, normal.z, normal.w]),
        indices: Array.from(scene.geometry.vertexIndices),
        transforms: scene.transforms.map((transform) => Array.from(transform)),
        bounds: scene.sceneBounds ? [scene.sceneBounds.pmin.toArray(), scene.sceneBounds.pmax.toArray()] : null };
}

function validateTranslatedScene(scene) {
    if (!scene.instances.length) {
        assert.equal(scene.activeNodeCount, 0);
        assert.deepEqual(scene.nodes, []);
        return;
    }
    const leaves = scene.nodes.slice(scene.topLevelIndex, scene.activeNodeCount).filter((node) => node.LRLeaf.z < 0);
    assert.equal(leaves.length, scene.instances.length);
    for (const node of scene.nodes.slice(scene.topLevelIndex, scene.activeNodeCount)) {
        if (node.LRLeaf.z === 0) {
            for (const child of [node.LRLeaf.x, node.LRLeaf.y]) {
                assert.ok(child >= scene.topLevelIndex && child < scene.activeNodeCount);
                assert.notEqual(scene.nodes[child], node);
                for (const axis of ['x','y','z']) {
                    assert.ok(node.bboxmin[axis] <= scene.nodes[child].bboxmin[axis]);
                    assert.ok(node.bboxmax[axis] >= scene.nodes[child].bboxmax[axis]);
                }
            }
        } else assert.ok(node.LRLeaf.z < 0, 'TLAS must not contain a BLAS leaf');
    }
    const instanceIDs = new Set();
    for (const leaf of leaves) {
        const instanceID = -leaf.LRLeaf.z - 1;
        assert.ok(!instanceIDs.has(instanceID));
        instanceIDs.add(instanceID);
        const instance = scene.instances[instanceID];
        const range = scene.geometry.meshRanges[instance.meshID];
        assert.equal(leaf.LRLeaf.x, range.nodeOffset);
        assert.equal(leaf.LRLeaf.y, instance.materialID);
        assert.deepEqual(leaf.bboxmin.toArray(), scene.instanceBounds[instanceID].pmin.toArray());
        assert.deepEqual(leaf.bboxmax.toArray(), scene.instanceBounds[instanceID].pmax.toArray());
    }
    for (const range of scene.geometry.meshRanges) {
        const end = range.nodeOffset + scene.meshes[range.meshID].bvh.m_nodecnt;
        for (const node of scene.nodes.slice(range.nodeOffset, end)) {
            if (node.LRLeaf.z === 0) {
                assert.ok(node.LRLeaf.x >= range.nodeOffset && node.LRLeaf.x < end);
                assert.ok(node.LRLeaf.y >= range.nodeOffset && node.LRLeaf.y < end);
            } else {
                assert.equal(node.LRLeaf.z, 1);
                assert.ok(node.LRLeaf.x >= range.triangleOffset);
                assert.ok(node.LRLeaf.x + node.LRLeaf.y <= range.triangleOffset + range.triangleCount);
            }
        }
    }
}

test('64 transform/material/mesh-ID updates match fresh builds without rebuilding or rewriting BLAS', () => {
    const meshes = [mesh(1), mesh(9)];
    const inputs = [{ meshID: 0, materialID: 1 }, { meshID: 1, materialID: 2 }];
    const scene = buildReferenceScene(meshes, inputs);
    const translator = scene.translator;
    const geometry = scene.geometry;
    const prefix = scene.nodes.slice(0, scene.topLevelIndex);
    const originalBlas = meshes.map((source) => ({ bvh: source.bvh, nodes: source.bvh.m_nodes,
        indices: [...source.bvh.getIndices()], vertices: source.verticesUVX,
        treeSnapshot: JSON.stringify(source.bvh),
        attributeSnapshot: JSON.stringify({ vertices: source.verticesUVX, normals: source.normalsUVY,
            tangents: source.tangents, extraAttributes: source.extraAttributes }) }));
    for (let iteration = 0; iteration < 64; iteration++) {
        const updated = [0,1].map((instanceID) => ({ meshID: (iteration + instanceID) % 2, materialID: iteration * 2 + instanceID,
            worldTransform: new Matrix4().compose(new Vector3(iteration-instanceID,instanceID-iteration,iteration%7),
                new Quaternion().setFromAxisAngle(new Vector3(0,0,1), iteration*0.07),
                new Vector3(iteration%2 ? -2 : 1, 1+instanceID, 0.5)) }));
        updateReferenceSceneInstances(scene, updated);
        const fresh = buildReferenceScene(meshes, updated);
        assert.deepEqual(sceneSnapshot(scene), sceneSnapshot(fresh), `update ${iteration}`);
        assert.equal(scene.translator, translator);
        assert.equal(scene.geometry, geometry);
        prefix.forEach((node, index) => assert.equal(scene.nodes[index], node));
        meshes.forEach((source, index) => {
            assert.equal(source.bvh, originalBlas[index].bvh);
            assert.equal(source.bvh.m_nodes, originalBlas[index].nodes);
            assert.equal(source.verticesUVX, originalBlas[index].vertices);
            assert.deepEqual(source.bvh.getIndices(), originalBlas[index].indices);
            assert.equal(JSON.stringify(source.bvh), originalBlas[index].treeSnapshot);
            assert.equal(JSON.stringify({ vertices: source.verticesUVX, normals: source.normalsUVY,
                tangents: source.tangents, extraAttributes: source.extraAttributes }), originalBlas[index].attributeSnapshot);
        });
        validateTranslatedScene(scene);
    }
});

test('40 cardinality/empty transitions match new scenes and retain no stale TLAS leaves', () => {
    const meshes = [mesh(2), mesh(7)];
    const scene = buildReferenceScene(meshes, []);
    const geometry = scene.geometry;
    const cardinalities = [0,1,5,2,0,3,3,1];
    for (let iteration = 0; iteration < 40; iteration++) {
        const inputs = Array.from({ length: cardinalities[iteration % cardinalities.length] }, (_, instanceID) => ({
            meshID: instanceID % 2, materialID: iteration*10+instanceID,
            worldTransform: new Matrix4().makeTranslation(iteration,instanceID,0) }));
        updateReferenceSceneInstances(scene, inputs);
        assert.deepEqual(sceneSnapshot(scene), sceneSnapshot(buildReferenceScene(meshes, inputs)), `transition ${iteration}`);
        assert.equal(scene.geometry, geometry);
        validateTranslatedScene(scene);
    }
});

test('32 A-B-A complete rebuilds with reordered mesh tables do not accumulate translator roots', () => {
    const first = mesh(1), second = mesh(11);
    const instances = [{ meshID: 0, materialID: 7 }, { meshID: 1, materialID: 9 }];
    const expected = sceneSnapshot(buildReferenceScene([first,second], instances));
    for (let iteration = 0; iteration < 32; iteration++) {
        const sceneA = buildReferenceScene([first,second], instances);
        const sceneB = buildReferenceScene([second,first], instances);
        const returnA = buildReferenceScene([first,second], instances);
        assert.notEqual(sceneA.translator, sceneB.translator);
        assert.notEqual(sceneB.translator, returnA.translator);
        assert.deepEqual(sceneSnapshot(returnA), expected);
        validateTranslatedScene(sceneB);
        validateTranslatedScene(returnA);
    }
});

test('invalid updates preserve the previous scene and its translator before publication', () => {
    const meshes = [mesh(4)];
    const scene = buildReferenceScene(meshes, [{ meshID: 0, materialID: 2 }]);
    const snapshot = sceneSnapshot(scene);
    const translator = scene.translator;
    const tlas = scene.tlas;
    const invalidInputs = [
        [{ meshID: 0, materialID: 9 }, { meshID: 99, materialID: 1 }],
        [{ meshID: 0, materialID: -1 }],
        [{ meshID: 0, materialID: 0x1000000 }],
        [{ meshID: 0, materialID: 3, worldTransform: new Matrix4().makeScale(0,1,1) }],
        [{ meshID: 0, materialID: 3, worldTransform: Float32Array.from({ length: 16 }, () => NaN) }],
    ];
    for (const invalid of invalidInputs) {
        assert.throws(() => updateReferenceSceneInstances(scene, invalid), /REFERENCE_/);
        assert.deepEqual(sceneSnapshot(scene), snapshot);
        assert.equal(scene.translator, translator);
        assert.equal(scene.tlas, tlas);
    }
});

test('input matrices and published snapshots are independent across subsequent updates', () => {
    const matrix = new Matrix4().makeTranslation(2,3,4);
    const scene = buildReferenceScene([mesh()], [{ meshID: 0, materialID: 1, worldTransform: matrix }]);
    const oldTransformReference = scene.transforms[0];
    const oldTransform = Array.from(oldTransformReference);
    matrix.elements[12] = 20;
    assert.deepEqual(Array.from(scene.transforms[0]), oldTransform);
    updateReferenceSceneInstances(scene, [{ meshID: 0, materialID: 1, worldTransform: matrix }]);
    assert.equal(scene.transforms[0][12], 20);
    assert.notEqual(scene.transforms[0], oldTransformReference);
    assert.deepEqual(Array.from(oldTransformReference), oldTransform);
    assert.deepEqual(scene.geometry.verticesUVX[0].xyz.toArray(), [0,0,0]);
});

test('upstream process reuse reproduces stale roots while the scene owner uses fresh translators', () => {
    const first = mesh(1), second = mesh(11);
    const inputs = [{ meshID: 0, materialID: 7 }, { meshID: 1, materialID: 9 }];
    const sceneA = buildReferenceScene([first,second], inputs);
    const sceneB = buildReferenceScene([second,first], inputs);
    const reused = new BvhTranslator();
    reused.process(sceneA.tlas, sceneA.meshes, sceneA.instances);
    reused.process(sceneB.tlas, sceneB.meshes, sceneB.instances);
    const staleLeaf = reused.nodes.find((node) => node.LRLeaf.z < 0 && node.LRLeaf.y === 9);
    assert.notEqual(staleLeaf.LRLeaf.x, sceneB.geometry.meshRanges[1].nodeOffset,
        'Recorded upstream behavior changed; revisit the fresh-translator boundary');
    validateTranslatedScene(sceneB);
});