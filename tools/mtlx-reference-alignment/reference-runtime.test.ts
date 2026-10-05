import test from 'node:test';
import assert from 'node:assert/strict';
import { BBox } from '../../src/bvh/reference/bvh/bbox.js';
import { Bvh } from '../../src/bvh/reference/bvh/bvh.js';
import { SplitBvh } from '../../src/bvh/reference/bvh/splitBvh.js';
import { BvhTranslator } from '../../src/bvh/reference/bvh/bvhTranslator.js';
import { Vec3 } from '../../src/bvh/reference/math/vec3.js';
import { Vec4 } from '../../src/bvh/reference/math/vec4.js';

test('TS runner resolves upstream .js imports to local TS modules', () => {
    const direction = new Vec3(1, 2, 3);
    assert.deepEqual(new Vec4(direction, 4).xyz.toArray(), [1, 2, 3]);
    const bounds = new BBox(new Vec3(0, 0, 0), new Vec3(2, 4, 6));
    assert.deepEqual(bounds.center().toArray(), [1, 2, 3]);
    assert.deepEqual(bounds.extents().toArray(), [2, 4, 6]);
});

test('TS BVH and translator execute directly without the distant engine', () => {
    const bounds = [new BBox(new Vec3(0, 0, 0), new Vec3(1, 1, 1)),
        new BBox(new Vec3(2, 2, 2), new Vec3(3, 3, 3))];
    const blas = new SplitBvh(2, 64, 0, 0.001, 0);
    blas.build(bounds);
    const tlas = new Bvh(10, 64, false);
    tlas.build([new BBox(new Vec3(0, 0, 0), new Vec3(3, 3, 3))]);
    const translator = new BvhTranslator();
    translator.process(tlas, [{ bvh: blas }], [{ meshID: 0, materialID: 11 }]);
    assert.equal(blas.getNumIndices(), 2);
    assert.equal(translator.topLevelIndex, blas.m_nodecnt);
    assert.equal(translator.nodes[translator.topLevelIndex].LRLeaf.y, 11);
    assert.equal(translator.nodes[translator.topLevelIndex].LRLeaf.z, -1);
});