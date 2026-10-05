import test from 'node:test';
import assert from 'node:assert/strict';
import { BufferGeometry, Float32BufferAttribute, Matrix4, RGBAIntegerFormat, IntType, NearestFilter, NoColorSpace } from 'three';
import { adaptReferenceGeometry } from '../../src/bvh/referenceSceneAdapter.js';
import { buildReferenceBlas } from '../../src/bvh/referenceBlas.js';
import { buildReferenceScene } from '../../src/bvh/referenceScene.js';
import { referenceTextureLayout, packReferenceScene, createReferenceSceneTextures, uploadReferenceSceneTextures } from '../../src/bvh/referenceGpuAdapter.js';

const limits = { maxTextureSize: 4096, maxTextureImageUnits: 16, reservedTextureUnits: 4 };
function scene() {
    const geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute([0,0,0, 1,0,0, 0,1,0], 3));
    const mesh = buildReferenceBlas(adaptReferenceGeometry(geometry).primitives[0]);
    return buildReferenceScene([mesh], [{ meshID: 0, materialID: 7, worldTransform: new Matrix4().makeTranslation(3,4,5) }]);
}
function logical(buffer) {
    return Array.from({ length: buffer.length }, (_, index) => buffer.data[Math.floor(index / buffer.channels) * 4 + index % buffer.channels]);
}

test('packing preserves reference xyz texel addressing with zero w padding', () => {
    const input = scene();
    const packed = packReferenceScene(input, limits);
    assert.equal(packed.topLevelIndex, input.topLevelIndex);
    assert.equal(packed.counts.nodes, input.activeNodeCount);
    assert.deepEqual(logical(packed.buffers.BVH), input.nodes.slice(0,input.activeNodeCount)
        .flatMap((node) => [...node.bboxmin.toArray(), ...node.bboxmax.toArray(), ...node.LRLeaf.toArray()]));
    assert.deepEqual(logical(packed.buffers.vertexIndicesTex), [0,1,2]);
    assert.deepEqual(logical(packed.buffers.verticesTex), input.geometry.verticesUVX.flatMap((vertex) => [vertex.x,vertex.y,vertex.z,vertex.w]));
    assert.deepEqual(logical(packed.buffers.normalsTex), input.geometry.normalsUVY.flatMap((normal) => [normal.x,normal.y,normal.z,normal.w]));
    assert.deepEqual(logical(packed.buffers.transformsTex), Array.from(input.transforms[0]));
    assert.equal(packed.buffers.vertexIndicesTex.samplerType, 'isampler2D');
    for (const name of ['BVH','vertexIndicesTex']) {
        const buffer = packed.buffers[name];
        for (let offset = 3; offset < buffer.data.length; offset += 4) assert.equal(buffer.data[offset], 0);
    }
});

test('row boundaries, height limits, sampler budget and memory limits are checked', () => {
    assert.deepEqual(referenceTextureLayout(15,3,{ maxTextureSize: 4 }), {
        width:4,height:2,logicalChannels:3,physicalChannels:4,logicalElements:15,logicalTexels:5,physicalElements:32,paddingTexels:3,byteLength:128 });
    assert.throws(() => referenceTextureLayout(51,3,{ maxTextureSize:4 }), /TEXTURE_CAPACITY/);
    assert.throws(() => packReferenceScene(scene(), { ...limits, maxTextureImageUnits:8, reservedTextureUnits:4 }), /UNIT_CAPACITY/);
    assert.throws(() => packReferenceScene(scene(), { ...limits, maxBufferBytes:0 }), /MEMORY_CAPACITY/);
    assert.throws(() => packReferenceScene(scene(), { ...limits, reservedTextureUnits:undefined }), /LIMIT_INVALID/);
    const input = scene();
    const packed = packReferenceScene(input, { ...limits, maxTextureSize:4 });
    assert.equal(packed.buffers.BVH.layout.height, 2);
    assert.deepEqual(Array.from(packed.buffers.BVH.data).slice(16,19), input.nodes[1].bboxmax.toArray());
    assert.deepEqual(Array.from(packed.buffers.BVH.data).slice(24), new Array(8).fill(0));
});

test('empty buffers use zero 1x1 sentinels with zero counts', () => {
    const packed = packReferenceScene(buildReferenceScene([],[]), limits);
    assert.deepEqual(packed.counts, { nodes:0,vertices:0,triangles:0,instances:0 });
    for (const buffer of Object.values(packed.buffers)) {
        assert.equal(buffer.layout.width, 1);
        assert.equal(buffer.layout.height, 1);
        assert.deepEqual(Array.from(buffer.data), [0,0,0,0]);
    }
});

test('DataTextures are integer/float, nearest, linear-data and disposable exactly once', () => {
    const bundle = createReferenceSceneTextures(scene(), limits);
    const indices = bundle.textures.vertexIndicesTex;
    assert.equal(indices.format, RGBAIntegerFormat);
    assert.equal(indices.type, IntType);
    assert.equal(indices.internalFormat, 'RGBA32I');
    let disposed = 0;
    for (const texture of Object.values(bundle.textures)) {
        assert.equal(texture.minFilter, NearestFilter);
        assert.equal(texture.magFilter, NearestFilter);
        assert.equal(texture.colorSpace, NoColorSpace);
        assert.equal(texture.flipY, false);
        assert.equal(texture.generateMipmaps, false);
        texture.addEventListener('dispose', () => disposed++);
    }
    assert.equal(bundle.uniforms.topBVHIndex.value, bundle.packed.topLevelIndex);
    bundle.dispose(); bundle.dispose();
    assert.equal(disposed, 5);
});

test('invalid root, nonintegral float IDs, nonfinite values and vertex indices are rejected', () => {
    let input = scene(); input.topLevelIndex = input.activeNodeCount;
    assert.throws(() => packReferenceScene(input, limits), /ROOT_INVALID/);
    input = scene(); input.nodes[0].LRLeaf.x = 0.5;
    assert.throws(() => packReferenceScene(input, limits), /INTEGER_INVALID/);
    input = scene(); input.nodes[input.topLevelIndex].LRLeaf.y = 0x1000000;
    assert.throws(() => packReferenceScene(input, limits), /INTEGER_INVALID/);
    input = scene(); input.geometry.verticesUVX[0].x = NaN;
    assert.throws(() => packReferenceScene(input, limits), /FLOAT_INVALID/);
    input = scene(); input.geometry.vertexIndices[0] = 99;
    assert.throws(() => packReferenceScene(input, limits), /INDEX_OUT_OF_BOUNDS/);
    input = scene(); input.nodes[input.topLevelIndex].LRLeaf.y = 8;
    assert.throws(() => packReferenceScene(input, limits), /NODE_INVALID/);
    input = scene(); input.instances = []; input.transforms = [];
    assert.throws(() => packReferenceScene(input, limits), /SCENE_INVALID/);
});

test('upload uses renderer initTexture and releases resources if initialization throws', () => {
    const calls = [];
    const renderer = { capabilities: { isWebGL2:true,maxTextureSize:4096,maxTextures:16 }, initTexture(texture) { calls.push(texture); } };
    const bundle = uploadReferenceSceneTextures(renderer, scene(), { reservedTextureUnits:4 });
    assert.equal(calls.length, 5);
    bundle.dispose();
    let releases = 0;
    const failing = { ...renderer, initTexture(texture) { texture.addEventListener('dispose', () => releases++); throw new Error('upload failure'); } };
    assert.throws(() => uploadReferenceSceneTextures(failing, scene(), { reservedTextureUnits:4 }), /upload failure/);
    assert.equal(releases, 1);
    assert.throws(() => uploadReferenceSceneTextures({ ...renderer, capabilities:{ isWebGL2:false } }, scene(), { reservedTextureUnits:4 }), /WEBGL2_REQUIRED/);
});

test('combined TLAS/BLAS depth is rejected before upload when it can exceed stack[64]', () => {
    const input = scene();
    input.tlasStats.maxDepth = 32;
    input.meshes[0].blasStats.maxDepth = 31;
    assert.throws(() => packReferenceScene(input, limits), /STACK_CAPACITY/);
});