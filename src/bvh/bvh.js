import { BBox } from './bbox.js';

const BIN_COUNT = 16;

function surfaceAreaOf(x, y, z) {
    return 2 * (x * y + x * z + y * z);
}

// SAH BVH builder. Per-triangle data is stored as flat typed arrays (SoA) and
// the build partitions triangle indices in place on one shared Uint32Array,
// instead of allocating a BBox object per bin and a left/right array at every
// recursive call -- the original approach made construction take tens of
// seconds (and block the main thread) on meshes with millions of triangles.
export class Bvh {
    constructor(geometry) {
        const position = geometry.attributes.position;
        if (!position || position.count < 3) throw new Error('BVH requires triangle positions.');

        this.geometry = geometry;
        this.nodes = [];
        this.packedTriangleIndices = [];

        const sourceIndices = geometry.index ? geometry.index.array : null;
        const triangleCount = Math.floor(sourceIndices ? sourceIndices.length / 3 : position.count / 3);

        const minX = new Float32Array(triangleCount), minY = new Float32Array(triangleCount), minZ = new Float32Array(triangleCount);
        const maxX = new Float32Array(triangleCount), maxY = new Float32Array(triangleCount), maxZ = new Float32Array(triangleCount);
        const cenX = new Float32Array(triangleCount), cenY = new Float32Array(triangleCount), cenZ = new Float32Array(triangleCount);
        this.triangleVertices = new Array(triangleCount);

        for (let triangle = 0; triangle < triangleCount; triangle++) {
            const base = triangle * 3;
            const i0 = sourceIndices ? sourceIndices[base] : base;
            const i1 = sourceIndices ? sourceIndices[base + 1] : base + 1;
            const i2 = sourceIndices ? sourceIndices[base + 2] : base + 2;
            this.triangleVertices[triangle] = [i0, i1, i2];

            const x0 = position.getX(i0), y0 = position.getY(i0), z0 = position.getZ(i0);
            const x1 = position.getX(i1), y1 = position.getY(i1), z1 = position.getZ(i1);
            const x2 = position.getX(i2), y2 = position.getY(i2), z2 = position.getZ(i2);

            const loX = Math.min(x0, x1, x2), loY = Math.min(y0, y1, y2), loZ = Math.min(z0, z1, z2);
            const hiX = Math.max(x0, x1, x2), hiY = Math.max(y0, y1, y2), hiZ = Math.max(z0, z1, z2);
            minX[triangle] = loX; minY[triangle] = loY; minZ[triangle] = loZ;
            maxX[triangle] = hiX; maxY[triangle] = hiY; maxZ[triangle] = hiZ;
            cenX[triangle] = (loX + hiX) * 0.5;
            cenY[triangle] = (loY + hiY) * 0.5;
            cenZ[triangle] = (loZ + hiZ) * 0.5;
        }

        this._min = [minX, minY, minZ];
        this._max = [maxX, maxY, maxZ];
        this._cen = [cenX, cenY, cenZ];

        if (triangleCount === 0) return;

        // Scratch buffers reused by every findSahSplit() call (one build, not one per node).
        this._binCount = new Int32Array(BIN_COUNT);
        this._binMin = [new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT)];
        this._binMax = [new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT)];
        this._rightCount = new Int32Array(BIN_COUNT);
        this._rightMin = [new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT)];
        this._rightMax = [new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT), new Float32Array(BIN_COUNT)];

        const indices = new Uint32Array(triangleCount);
        for (let i = 0; i < triangleCount; i++) indices[i] = i;
        this.root = this.build(indices, 0, triangleCount);
    }

    boundsOf(indices, start, end) {
        const [minX, minY, minZ] = this._min;
        const [maxX, maxY, maxZ] = this._max;
        let loX = Infinity, loY = Infinity, loZ = Infinity;
        let hiX = -Infinity, hiY = -Infinity, hiZ = -Infinity;
        for (let i = start; i < end; i++) {
            const t = indices[i];
            if (minX[t] < loX) loX = minX[t];
            if (minY[t] < loY) loY = minY[t];
            if (minZ[t] < loZ) loZ = minZ[t];
            if (maxX[t] > hiX) hiX = maxX[t];
            if (maxY[t] > hiY) hiY = maxY[t];
            if (maxZ[t] > hiZ) hiZ = maxZ[t];
        }
        return new BBox([loX, loY, loZ], [hiX, hiY, hiZ]);
    }

    findSahSplit(indices, start, end, bounds) {
        const [cenX, cenY, cenZ] = this._cen;
        let cLoX = Infinity, cLoY = Infinity, cLoZ = Infinity;
        let cHiX = -Infinity, cHiY = -Infinity, cHiZ = -Infinity;
        for (let i = start; i < end; i++) {
            const t = indices[i];
            const x = cenX[t], y = cenY[t], z = cenZ[t];
            if (x < cLoX) cLoX = x; if (x > cHiX) cHiX = x;
            if (y < cLoY) cLoY = y; if (y > cHiY) cHiY = y;
            if (z < cLoZ) cLoZ = z; if (z > cHiZ) cHiZ = z;
        }

        let best = null;
        const parentArea = bounds.surfaceArea();
        if (!Number.isFinite(parentArea) || parentArea <= 0) return best;

        const centroidMin = [cLoX, cLoY, cLoZ];
        const centroidExtent = [cHiX - cLoX, cHiY - cLoY, cHiZ - cLoZ];
        const cen = this._cen, min_ = this._min, max_ = this._max;
        const binCount = this._binCount;
        const [binMinX, binMinY, binMinZ] = this._binMin;
        const [binMaxX, binMaxY, binMaxZ] = this._binMax;
        const rightCount = this._rightCount;
        const [rightMinX, rightMinY, rightMinZ] = this._rightMin;
        const [rightMaxX, rightMaxY, rightMaxZ] = this._rightMax;

        for (let axis = 0; axis < 3; axis++) {
            const extent = centroidExtent[axis];
            if (extent <= 0) continue;

            binCount.fill(0);
            binMinX.fill(Infinity); binMinY.fill(Infinity); binMinZ.fill(Infinity);
            binMaxX.fill(-Infinity); binMaxY.fill(-Infinity); binMaxZ.fill(-Infinity);

            const axisCen = cen[axis];
            const axisMin = centroidMin[axis];
            const invExtent = BIN_COUNT / extent;
            const [tMinX, tMinY, tMinZ] = min_;
            const [tMaxX, tMaxY, tMaxZ] = max_;

            for (let i = start; i < end; i++) {
                const t = indices[i];
                let bin = Math.floor((axisCen[t] - axisMin) * invExtent);
                if (bin >= BIN_COUNT) bin = BIN_COUNT - 1; else if (bin < 0) bin = 0;
                binCount[bin]++;
                if (tMinX[t] < binMinX[bin]) binMinX[bin] = tMinX[t];
                if (tMinY[t] < binMinY[bin]) binMinY[bin] = tMinY[t];
                if (tMinZ[t] < binMinZ[bin]) binMinZ[bin] = tMinZ[t];
                if (tMaxX[t] > binMaxX[bin]) binMaxX[bin] = tMaxX[t];
                if (tMaxY[t] > binMaxY[bin]) binMaxY[bin] = tMaxY[t];
                if (tMaxZ[t] > binMaxZ[bin]) binMaxZ[bin] = tMaxZ[t];
            }

            // Per-bin snapshot (not a single mutated running BBox) so every
            // rightBounds[bin] keeps the correct area for that split point.
            let rMinX = Infinity, rMinY = Infinity, rMinZ = Infinity;
            let rMaxX = -Infinity, rMaxY = -Infinity, rMaxZ = -Infinity;
            let rCount = 0;
            for (let bin = BIN_COUNT - 1; bin > 0; bin--) {
                if (binMinX[bin] < rMinX) rMinX = binMinX[bin];
                if (binMinY[bin] < rMinY) rMinY = binMinY[bin];
                if (binMinZ[bin] < rMinZ) rMinZ = binMinZ[bin];
                if (binMaxX[bin] > rMaxX) rMaxX = binMaxX[bin];
                if (binMaxY[bin] > rMaxY) rMaxY = binMaxY[bin];
                if (binMaxZ[bin] > rMaxZ) rMaxZ = binMaxZ[bin];
                rCount += binCount[bin];
                rightCount[bin - 1] = rCount;
                rightMinX[bin - 1] = rMinX; rightMinY[bin - 1] = rMinY; rightMinZ[bin - 1] = rMinZ;
                rightMaxX[bin - 1] = rMaxX; rightMaxY[bin - 1] = rMaxY; rightMaxZ[bin - 1] = rMaxZ;
            }

            let lMinX = Infinity, lMinY = Infinity, lMinZ = Infinity;
            let lMaxX = -Infinity, lMaxY = -Infinity, lMaxZ = -Infinity;
            let leftCount = 0;
            for (let bin = 0; bin < BIN_COUNT - 1; bin++) {
                if (binMinX[bin] < lMinX) lMinX = binMinX[bin];
                if (binMinY[bin] < lMinY) lMinY = binMinY[bin];
                if (binMinZ[bin] < lMinZ) lMinZ = binMinZ[bin];
                if (binMaxX[bin] > lMaxX) lMaxX = binMaxX[bin];
                if (binMaxY[bin] > lMaxY) lMaxY = binMaxY[bin];
                if (binMaxZ[bin] > lMaxZ) lMaxZ = binMaxZ[bin];
                leftCount += binCount[bin];
                if (leftCount === 0 || rightCount[bin] === 0) continue;

                const leftArea = surfaceAreaOf(lMaxX - lMinX, lMaxY - lMinY, lMaxZ - lMinZ);
                const rightArea = surfaceAreaOf(rightMaxX[bin] - rightMinX[bin], rightMaxY[bin] - rightMinY[bin], rightMaxZ[bin] - rightMinZ[bin]);
                const cost = 1 + (leftCount * leftArea + rightCount[bin] * rightArea) / parentArea;
                if (!best || cost < best.cost) {
                    best = { axis, border: axisMin + extent * (bin + 1) / BIN_COUNT, cost };
                }
            }
        }
        return best;
    }

    // In-place Hoare-style partition of indices[start,end) around split.border;
    // returns the boundary index, or -1 if every triangle landed on one side.
    partition(indices, start, end, split) {
        const cen = this._cen[split.axis];
        let i = start, j = end - 1;
        while (i <= j) {
            while (i <= j && cen[indices[i]] < split.border) i++;
            while (i <= j && cen[indices[j]] >= split.border) j--;
            if (i < j) { const tmp = indices[i]; indices[i] = indices[j]; indices[j] = tmp; i++; j--; }
        }
        return (i === start || i === end) ? -1 : i;
    }

    build(indices, start, end) {
        const bounds = this.boundsOf(indices, start, end);
        const node = { bounds, left: -1, right: -1, offset: -1, count: 0 };
        const nodeIndex = this.nodes.length;
        this.nodes.push(node);

        const count = end - start;
        if (count === 1) {
            node.offset = this.packedTriangleIndices.length;
            node.count = 1;
            this.packedTriangleIndices.push(indices[start]);
            return nodeIndex;
        }

        const split = this.findSahSplit(indices, start, end, bounds);
        let mid = split ? this.partition(indices, start, end, split) : -1;

        if (mid === -1) {
            const axis = bounds.maximumAxis();
            const cen = this._cen[axis];
            indices.subarray(start, end).sort((a, b) => cen[a] - cen[b]);
            mid = start + (count >> 1);
        }

        node.left = this.build(indices, start, mid);
        node.right = this.build(indices, mid, end);
        return nodeIndex;
    }
}

