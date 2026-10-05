import { Vec3 } from "../math/vec3.js";
import { BBox } from "./bbox.js";

export enum NodeType {
    kInternal,
    kLeaf
}

export interface SplitRequest {
    startidx: number;
    numprims: number;
    ptr: Node | null;
    isLeft: boolean;
    bounds: BBox;
    centroid_bounds: BBox;
    level: number;
    index: number;
}

export class Node {
    type: NodeType = NodeType.kInternal;
    bounds: BBox = new BBox();
    index: number = 0;
    startidx: number | null = null;
    numprims: number | null = null;
    lc: Node | null = null;
    rc: Node | null = null;
}

export interface SahSplit {
    dim: number;
    split: number;
    sah: number;
    overlap: number
}

function is_nan(v: number): boolean {
    return v !== v;
}

export class Bvh {
    static readonly kMaxPrimitivesPerLeaf = 1;

    m_bounds: BBox = new BBox();
    m_height: number = 0;
    m_nodes: Node[] = [];
    m_nodecnt: number = 0;
    m_packed_indices: number[] = [];
    m_indices: number[] = [];
    m_usesah: boolean = true;
    m_num_bins: number = 16;
    m_traversal_cost: number = 1.0;

    constructor(traversal_cost: number, num_bins: number = 64, usesah: boolean = false)
    {
        this.m_num_bins = num_bins;
        this.m_usesah = usesah;
        this.m_height = 0;
        this.m_traversal_cost = traversal_cost;
    }

    build(bounds: BBox[]) {
        for (let i = 0; i < bounds.length; ++i) {
            // Calc bbox
            this.m_bounds.grow(bounds[i]);
        }
        this.buildImpl(bounds, bounds.length);
    }

    bounds(): BBox {
        return this.m_bounds;
    }

    initNodeAllocator(maxnum: number) {
        this.m_nodecnt = 0;
        this.m_nodes = new Array(maxnum);
        for (let i = 0; i < maxnum; ++i) {
            this.m_nodes[i] = new Node();
        }
    }

    allocateNode(): Node {
        return this.m_nodes[this.m_nodecnt++];
    }

    private buildNode(req: SplitRequest, bounds: BBox[], centroids: Vec3[], primindices: number[]) {
        this.m_height = Math.max(this.m_height, req.level);

        const node = this.allocateNode();
        node.bounds = req.bounds;
        node.index = req.index;

        // Create leaf node if we have enough prims
        if (req.numprims < 2) {
            node.type = NodeType.kLeaf;
            node.startidx = this.m_packed_indices.length;
            node.numprims = req.numprims;
            for (let i = 0; i < req.numprims; ++i) {
                this.m_packed_indices.push(primindices[req.startidx + i]);
            }
        } else {
            // Choose the maximum extent
            let axis = req.centroid_bounds.maxdim();
            let border = req.centroid_bounds.center().get(axis);

            if (this.m_usesah) {
                const ss = this.findSahSplit(req, bounds, centroids, primindices);
                if (!is_nan(ss.split)) {
                    axis = ss.dim;
                    border = ss.split;
                    if (req.numprims < ss.sah && req.numprims < Bvh.kMaxPrimitivesPerLeaf) {
                        node.type = NodeType.kLeaf;
                        node.startidx = this.m_packed_indices.length;
                        node.numprims = req.numprims;
                        for (let i = 0; i < req.numprims; ++i) {
                            this.m_packed_indices.push(primindices[req.startidx + i]);
                        }
                        if (req.ptr) {
                            if (req.isLeft) req.ptr.lc = node;
                            else req.ptr.rc = node;
                        }
                        return;
                    }
                }
            }

            node.type = NodeType.kInternal;

            // Start partitioning and updating extents for children at the same time
            let leftbounds = new BBox();
            let rightbounds = new BBox();
            let leftcentroid_bounds = new BBox();
            let rightcentroid_bounds = new BBox();
            let splitidx = req.startidx;

            const near2far = ((req.numprims + req.startidx) & 0x1) !== 0;

            if (req.centroid_bounds.extents().get(axis) > 0.0) {
                let first = req.startidx;
                let last = req.startidx + req.numprims;

                if (near2far) {
                    while (true) {
                        while ((first !== last) && centroids[primindices[first]].get(axis) < border) {
                            leftbounds.grow(bounds[primindices[first]]);
                            leftcentroid_bounds.grow(centroids[primindices[first]]);
                            ++first;
                        }
                        if (first === last--) break;
                        rightbounds.grow(bounds[primindices[first]]);
                        rightcentroid_bounds.grow(centroids[primindices[first]]);
                        while ((first !== last) && centroids[primindices[last]].get(axis) >= border) {
                            rightbounds.grow(bounds[primindices[last]]);
                            rightcentroid_bounds.grow(centroids[primindices[last]]);
                            --last;
                        }
                        if (first === last) break;
                        leftbounds.grow(bounds[primindices[last]]);
                        leftcentroid_bounds.grow(centroids[primindices[last]]);
                        [primindices[first++], primindices[last]] = [primindices[last], primindices[first]];
                    }
                } else {
                    while (true) {
                        while ((first !== last) && centroids[primindices[first]].get(axis) >= border) {
                            leftbounds.grow(bounds[primindices[first]]);
                            leftcentroid_bounds.grow(centroids[primindices[first]]);
                            ++first;
                        }
                        if (first === last--) break;
                        rightbounds.grow(bounds[primindices[first]]);
                        rightcentroid_bounds.grow(centroids[primindices[first]]);
                        while ((first !== last) && centroids[primindices[last]].get(axis) < border) {
                            rightbounds.grow(bounds[primindices[last]]);
                            rightcentroid_bounds.grow(centroids[primindices[last]]);
                            --last;
                        }
                        if (first === last) break;
                        leftbounds.grow(bounds[primindices[last]]);
                        leftcentroid_bounds.grow(centroids[primindices[last]]);
                        [primindices[first++], primindices[last]] = [primindices[last], primindices[first]];
                    }
                }
                splitidx = first;
            }

            if (splitidx === req.startidx || splitidx === req.startidx + req.numprims) {
                splitidx = req.startidx + (req.numprims >> 1);
                for (let i = req.startidx; i < splitidx; ++i) {
                    leftbounds.grow(bounds[primindices[i]]);
                    leftcentroid_bounds.grow(centroids[primindices[i]]);
                }
                for (let i = splitidx; i < req.startidx + req.numprims; ++i) {
                    rightbounds.grow(bounds[primindices[i]]);
                    rightcentroid_bounds.grow(centroids[primindices[i]]);
                }
            }

            const leftrequest: SplitRequest = {
                startidx: req.startidx,
                numprims: splitidx - req.startidx,
                ptr: node,
                isLeft: true,
                bounds: leftbounds,
                centroid_bounds: leftcentroid_bounds,
                level: req.level + 1,
                index: (req.index << 1)
            };
            const rightrequest: SplitRequest = {
                startidx: splitidx,
                numprims: req.numprims - (splitidx - req.startidx),
                ptr: node,
                isLeft: false,
                bounds: rightbounds,
                centroid_bounds: rightcentroid_bounds,
                level: req.level + 1,
                index: (req.index << 1) + 1
            };

            this.buildNode(leftrequest, bounds, centroids, primindices);
            this.buildNode(rightrequest, bounds, centroids, primindices);
        }

        if (req.ptr) {
            if (req.isLeft) req.ptr.lc = node;
            else req.ptr.rc = node;
        }
    }

    findSahSplit(req: SplitRequest, bounds: BBox[], centroids: Vec3[], primindices: number[]): SahSplit {
        let splitidx = -1;
        let sah = Number.POSITIVE_INFINITY;
        let split = { dim: 0, split: NaN, sah: sah, overlap: 0 };

        const centroid_extents = req.centroid_bounds.extents();
        if (Vec3.dot(centroid_extents, centroid_extents) === 0.0) {
            return split;
        }

        type Bin = { bounds: BBox; count: number };
        const bins: Bin[][] = [[], [], []];
        bins[0] = Array(this.m_num_bins).fill(0).map(() => ({ bounds: new BBox(), count: 0 }));
        bins[1] = Array(this.m_num_bins).fill(0).map(() => ({ bounds: new BBox(), count: 0 }));
        bins[2] = Array(this.m_num_bins).fill(0).map(() => ({ bounds: new BBox(), count: 0 }));

        const invarea = 1.0 / req.bounds.surfaceArea();
        const rootmin = req.centroid_bounds.pmin;

        for (let axis = 0; axis < 3; ++axis) {
            const rootminc = rootmin.get(axis);
            const centroid_rng = centroid_extents.get(axis);
            const invcentroid_rng = 1.0 / centroid_rng;
            if (centroid_rng === 0.0) continue;

            for (let i = 0; i < this.m_num_bins; ++i) {
                bins[axis][i].count = 0;
                bins[axis][i].bounds = new BBox();
            }

            for (let i = req.startidx; i < req.startidx + req.numprims; ++i) {
                const idx = primindices[i];
                const binidx = Math.min(
                    Math.floor(this.m_num_bins * ((centroids[idx].get(axis) - rootminc) * invcentroid_rng)),
                    this.m_num_bins - 1
                );
                bins[axis][binidx].count++;
                bins[axis][binidx].bounds.grow(bounds[idx]);
            }

            const rightbounds: BBox[] = new Array(this.m_num_bins - 1);
            let rightbox = new BBox();
            for (let i = this.m_num_bins - 1; i > 0; --i) {
                rightbox.grow(bins[axis][i].bounds);
                rightbounds[i - 1] = new BBox();
                rightbounds[i - 1].pmin = rightbox.pmin;
                rightbounds[i - 1].pmax = rightbox.pmax;
            }

            let leftbox = new BBox();
            let leftcount = 0;
            let rightcount = req.numprims;

            for (let i = 0; i < this.m_num_bins - 1; ++i) {
                leftbox.grow(bins[axis][i].bounds);
                leftcount += bins[axis][i].count;
                rightcount -= bins[axis][i].count;

                const sahtmp = this.m_traversal_cost +
                    (leftcount * leftbox.surfaceArea() + rightcount * rightbounds[i].surfaceArea()) * invarea;

                if (sahtmp < sah) {
                    split.dim = axis;
                    splitidx = i;
                    split.sah = sah = sahtmp;
                }
            }
        }

        if (splitidx !== -1) {
            split.split = rootmin.get(split.dim) + (splitidx + 1) * (centroid_extents.get(split.dim) / this.m_num_bins);
        }

        return split;
    }

    buildImpl(bounds: BBox[], numbounds: number) {
        this.initNodeAllocator(2 * numbounds - 1);

        const centroids: Vec3[] = new Array(numbounds);
        this.m_indices = new Array(numbounds);
        for (let i = 0; i < numbounds; ++i) this.m_indices[i] = i;

        let centroid_bounds = new BBox();
        for (let i = 0; i < numbounds; ++i) {
            const c = bounds[i].center();
            centroid_bounds.grow(c);
            centroids[i] = c;
        }

        const init: SplitRequest = {
            startidx: 0,
            numprims: numbounds,
            ptr: null,
            isLeft: false,
            bounds: this.m_bounds,
            centroid_bounds: centroid_bounds,
            level: 0,
            index: 1
        };

        this.buildNode(init, bounds, centroids, this.m_indices);
    }

    printStatistics(): void {
        console.log("Class name: Bvh");
        console.log("SAH:", this.m_usesah ? "enabled" : "disabled");
        console.log("SAH bins:", this.m_num_bins);
        console.log("Number of triangles:", this.m_indices.length);
        console.log("Number of nodes:", this.m_nodecnt);
        console.log("Tree height:", this.m_height);
    }

    getIndices(): number[] {
        return this.m_packed_indices;
    }

    getNumIndices(): number {
        return this.m_packed_indices.length;
    }
}
