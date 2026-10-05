import { Bvh, NodeType } from './reference/bvh/bvh.js';
import { SplitBvh } from './reference/bvh/splitBvh.js';
import { BBox } from './reference/bvh/bbox.js';
import { Vec3 } from './reference/math/vec3.js';

export const REFERENCE_BVH_PROFILES = Object.freeze({
    blas: Object.freeze({ algorithm: 'SplitBvh', traversalCost: 2, bins: 64,
        maxSplitDepth: 0, minOverlap: 0.001, extraReferencesBudget: 0 }),
    tlas: Object.freeze({ algorithm: 'Bvh', traversalCost: 10, bins: 64, useSah: false }),
});

function requireBlas(condition, code, detail) {
    if (!condition) throw new Error(`${code}: ${detail}`);
}

export function createReferenceBvh(profile = 'blas') {
    requireBlas(Object.hasOwn(REFERENCE_BVH_PROFILES, profile), 'REFERENCE_BVH_PROFILE_UNKNOWN', profile);
    const settings = REFERENCE_BVH_PROFILES[profile];
    return profile === 'blas'
        ? new SplitBvh(settings.traversalCost, settings.bins, settings.maxSplitDepth, settings.minOverlap, settings.extraReferencesBudget)
        : new Bvh(settings.traversalCost, settings.bins, settings.useSah);
}

function containsBounds(outer, inner) {
    return ['x', 'y', 'z'].every((axis) => outer.pmin[axis] <= inner.pmin[axis] && outer.pmax[axis] >= inner.pmax[axis]);
}

export function inspectReferenceBvh(bvh, primitiveBounds) {
    const indices = Array.from(bvh.getIndices());
    requireBlas(indices.length === primitiveBounds.length && bvh.getNumIndices() === indices.length,
        'REFERENCE_BVH_COVERAGE_INVALID', 'packed primitive count');
    requireBlas(new Set(indices).size === primitiveBounds.length &&
        indices.every((value) => Number.isInteger(value) && value >= 0 && value < primitiveBounds.length),
        'REFERENCE_BVH_PERMUTATION_INVALID', 'reference profile must not duplicate or lose primitives');
    const seen = new Set();
    const slots = new Set();
    const allocated = new Set(bvh.m_nodes.slice(0, bvh.m_nodecnt));
    const pending = [{ node: bvh.m_nodes[0], depth: 0 }];
    let maxDepth = 0;
    let leaves = 0;
    let maxLeafPrimitives = 0;
    while (pending.length) {
        const { node, depth } = pending.pop();
        requireBlas(node && allocated.has(node) && !seen.has(node), 'REFERENCE_BVH_TREE_INVALID', 'missing, repeated or unallocated node');
        seen.add(node);
        maxDepth = Math.max(maxDepth, depth);
        requireBlas(['x', 'y', 'z'].every((axis) => Number.isFinite(node.bounds.pmin[axis]) &&
            Number.isFinite(node.bounds.pmax[axis]) && node.bounds.pmin[axis] <= node.bounds.pmax[axis]),
            'REFERENCE_BVH_BOUNDS_INVALID', 'node bounds');
        if (node.type === NodeType.kLeaf) {
            requireBlas(Number.isInteger(node.startidx) && Number.isInteger(node.numprims) && node.startidx >= 0 &&
                node.numprims > 0 && node.startidx + node.numprims <= indices.length,
                'REFERENCE_BVH_LEAF_INVALID', 'leaf primitive range');
            leaves++;
            maxLeafPrimitives = Math.max(maxLeafPrimitives, node.numprims);
            for (let slot = node.startidx; slot < node.startidx + node.numprims; slot++) {
                requireBlas(!slots.has(slot), 'REFERENCE_BVH_LEAF_INVALID', 'overlapping leaf ranges');
                slots.add(slot);
                requireBlas(containsBounds(node.bounds, primitiveBounds[indices[slot]]),
                    'REFERENCE_BVH_BOUNDS_INVALID', 'leaf does not contain its primitive');
            }
        } else {
            requireBlas(node.type === NodeType.kInternal && node.lc && node.rc,
                'REFERENCE_BVH_TREE_INVALID', 'internal node children');
            requireBlas(containsBounds(node.bounds, node.lc.bounds) && containsBounds(node.bounds, node.rc.bounds),
                'REFERENCE_BVH_BOUNDS_INVALID', 'parent does not contain children');
            pending.push({ node: node.rc, depth: depth + 1 }, { node: node.lc, depth: depth + 1 });
        }
    }
    requireBlas(seen.size === bvh.m_nodecnt && slots.size === indices.length && maxDepth === bvh.m_height,
        'REFERENCE_BVH_TREE_INVALID', 'node count, leaf coverage or height');
    return { nodeCount: seen.size, leafCount: leaves, maxDepth, maxLeafPrimitives,
        packedPrimitiveCount: indices.length, duplicateReferences: 0 };
}

export function buildReferenceBlas(primitive) {
    requireBlas(Array.isArray(primitive?.verticesUVX) && primitive.verticesUVX.length % 3 === 0,
        'REFERENCE_BLAS_VERTEX_COUNT_INVALID', 'expanded triangle vertices required');
    const triangleCount = primitive.verticesUVX.length / 3;
    requireBlas(primitive.triangleCount === triangleCount, 'REFERENCE_BLAS_TRIANGLE_COUNT_INVALID', 'adapter count differs from vertices');
    if (triangleCount === 0) return { ...primitive, bvh: null, triangleBounds: [], blasStatus: 'empty', blasStats: null };
    const bounds = [];
    for (let triangle = 0; triangle < triangleCount; triangle++) {
        const box = new BBox();
        for (let corner = 0; corner < 3; corner++) {
            const vertex = primitive.verticesUVX[triangle * 3 + corner];
            requireBlas(vertex && [vertex.x, vertex.y, vertex.z].every((value) => Number.isFinite(value) && Number.isFinite(Math.fround(value))),
                'REFERENCE_BLAS_POSITION_INVALID', `triangle ${triangle}`);
            box.grow(new Vec3(vertex.x, vertex.y, vertex.z));
        }
        bounds.push(box);
    }
    const bvh = createReferenceBvh('blas');
    bvh.build(bounds);
    return { ...primitive, bvh, triangleBounds: bounds, blasStatus: 'built',
        blasStats: inspectReferenceBvh(bvh, bounds) };
}