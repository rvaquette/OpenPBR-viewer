import { Vec3 } from "../math/vec3.js";
import { BBox, intersection, bboxUnion } from "./bbox.js";
import { Bvh, Node, NodeType, SahSplit, SplitRequest } from "./bvh.js";

type Nullable<T> = T | null;

export enum SplitType {
    kObject,
    kSpatial
}

export interface PrimRef {
    bounds: BBox;
    center: Vec3;
    idx: number;
}

export type PrimRefArray = PrimRef[];

export class SplitBvh extends Bvh {
    m_max_split_depth: number;
    m_num_nodes_for_regular: number;
    m_num_nodes_required: number;
    m_extra_refs_budget: number;
    m_min_overlap: number;

    m_num_nodes_archived: number;
    m_node_archive: Node[][] = [];

    constructor(
        traversal_cost: number,
        num_bins: number,
        max_split_depth: number,
        min_overlap: number,
        extra_refs_budget: number
    ) {
        super(traversal_cost, num_bins, true);
        this.m_max_split_depth = max_split_depth;
        this.m_min_overlap = min_overlap;
        this.m_extra_refs_budget = extra_refs_budget;
        this.m_num_nodes_required = 0;
        this.m_num_nodes_for_regular = 0;
        this.m_num_nodes_archived = 0;
    }

    buildImpl(bounds: BBox[], numbounds: number) {
        const primrefs: PrimRefArray = new Array(numbounds);
        const centroids: Vec3[] = new Array(numbounds);
        let centroid_bounds = new BBox();

        for (let i = 0; i < numbounds; ++i) {
            const c = bounds[i].center();
            primrefs[i] = { bounds: bounds[i], center: c, idx: i };
            centroid_bounds.grow(c);
        }

        this.m_num_nodes_for_regular = (2 * numbounds - 1);
        this.m_num_nodes_required = Math.floor(this.m_num_nodes_for_regular * (1.0 + this.m_extra_refs_budget));

        this.initNodeAllocator(this.m_num_nodes_required);

        const init: SplitRequest = {
            startidx: 0,
            numprims: numbounds,
            ptr: null,
            isLeft: false,
            bounds: this.m_bounds,
            centroid_bounds: centroid_bounds,
            level: 0,
            index: 0
        };

        this.buildNodeSplit(init, primrefs);
    }

    private buildNodeSplit(req: SplitRequest, primrefs: PrimRefArray) {
        this.m_height = Math.max(this.m_height, req.level);

        const node = this.allocateNode();
        node.bounds = req.bounds;

        if (req.numprims < 4) {
            node.type = NodeType.kLeaf;
            node.startidx = this.m_packed_indices.length;
            node.numprims = req.numprims;

            for (let i = req.startidx; i < req.startidx + req.numprims; ++i) {
                this.m_packed_indices.push(primrefs[i].idx);
            }
        } else {
            node.type = NodeType.kInternal;

            let axis = req.centroid_bounds.maxdim();
            let border = req.centroid_bounds.center().get(axis);

            const os = this.findObjectSahSplit(req, primrefs);
            let ss: SahSplit = { dim: 0, split: NaN, sah: Number.MAX_VALUE, overlap: 0 };
            let split_type = SplitType.kObject;

            if (req.level < this.m_max_split_depth && this.m_nodecnt < this.m_num_nodes_required && os.overlap > this.m_min_overlap) {
                ss = this.findSpatialSahSplit(req, primrefs);

                if (!isNaN(ss.split) && ss.sah < os.sah) {
                    split_type = SplitType.kSpatial;
                }
            }

            if (split_type === SplitType.kSpatial) {
                const elems = req.startidx + req.numprims * 2;
                if (primrefs.length < elems) {
                    primrefs.length = elems;
                }

                let extra_refs = 0;
                this.splitPrimRefs(ss, req, primrefs, (v) => { extra_refs = v; });
                req.numprims += extra_refs;
                border = ss.split;
                axis = ss.dim;
            } else {
                border = !isNaN(os.split) ? os.split : border;
                axis = !isNaN(os.split) ? os.dim : axis;
            }

            let leftbounds = new BBox();
            let rightbounds = new BBox();
            let leftcentroid_bounds = new BBox();
            let rightcentroid_bounds = new BBox();
            let splitidx = req.startidx;

            const near2far = (req.numprims + req.startidx) & 0x1;

            const cmpl = (a: number, b: number) => a < b;
            const cmpge = (a: number, b: number) => a >= b;
            const cmp1 = near2far ? cmpl : cmpge;
            const cmp2 = near2far ? cmpge : cmpl;

            if (req.centroid_bounds.extents().get(axis) > 0.0) {
                let first = req.startidx;
                let last = req.startidx + req.numprims;

                while (true) {
                    while ((first !== last) && cmp1(primrefs[first].center.get(axis), border)) {
                        leftbounds.grow(primrefs[first].bounds);
                        leftcentroid_bounds.grow(primrefs[first].center);
                        ++first;
                    }

                    if (first === last--) break;

                    rightbounds.grow(primrefs[first].bounds);
                    rightcentroid_bounds.grow(primrefs[first].center);

                    while ((first !== last) && cmp2(primrefs[last].center.get(axis), border)) {
                        rightbounds.grow(primrefs[last].bounds);
                        rightcentroid_bounds.grow(primrefs[last].center);
                        --last;
                    }

                    if (first === last) break;

                    leftbounds.grow(primrefs[last].bounds);
                    leftcentroid_bounds.grow(primrefs[last].center);

                    [primrefs[first++], primrefs[last]] = [primrefs[last], primrefs[first]];
                }

                splitidx = first;
            }

            if (splitidx === req.startidx || splitidx === req.startidx + req.numprims) {
                splitidx = req.startidx + (req.numprims >> 1);

                for (let i = req.startidx; i < splitidx; ++i) {
                    leftbounds.grow(primrefs[i].bounds);
                    leftcentroid_bounds.grow(primrefs[i].center);
                }

                for (let i = splitidx; i < req.startidx + req.numprims; ++i) {
                    rightbounds.grow(primrefs[i].bounds);
                    rightcentroid_bounds.grow(primrefs[i].center);
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
                index: 0
            };
            const rightrequest: SplitRequest = {
                startidx: splitidx,
                numprims: req.numprims - (splitidx - req.startidx),
                ptr: node,
                isLeft: false,
                bounds: rightbounds,
                centroid_bounds: rightcentroid_bounds,
                level: req.level + 1,
                index: 0
            };

            this.buildNodeSplit(rightrequest, primrefs);
            this.buildNodeSplit(leftrequest, primrefs);
        }

        if (req.ptr) {
            if (req.isLeft) req.ptr.lc = node;
            else req.ptr.rc = node;
        }
    }

    findObjectSahSplit(req: SplitRequest, refs: PrimRefArray): SahSplit {
        let splitidx = -1;
        let sah = Number.MAX_VALUE;
        const split = {
            dim: 0,
            split: NaN,
            sah: sah,
            overlap: 0
        };

        const centroid_extents = req.centroid_bounds.extents();
        if (Vec3.dot(centroid_extents, centroid_extents) === 0.0) {
            return split;
        }

        type Bin = { bounds: BBox; count: number; };
        const bins: Bin[][] = [[], [], []];
        bins[0] = Array(this.m_num_bins).fill(null).map(() => ({ bounds: new BBox(), count: 0 }));
        bins[1] = Array(this.m_num_bins).fill(null).map(() => ({ bounds: new BBox(), count: 0 }));
        bins[2] = Array(this.m_num_bins).fill(null).map(() => ({ bounds: new BBox(), count: 0 }));

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
                const idx = i;
                const binidx = Math.min(
                    Math.floor(this.m_num_bins * ((refs[idx].center.get(axis) - rootminc) * invcentroid_rng)),
                    this.m_num_bins - 1
                );
                bins[axis][binidx].count++;
                bins[axis][binidx].bounds.grow(refs[idx].bounds);
            }

            const rightbounds: BBox[] = new Array(this.m_num_bins - 1);
            let rightbox = new BBox();
            for (let i = this.m_num_bins - 1; i > 0; --i) {
                rightbox.grow(bins[axis][i].bounds);
                rightbounds[i - 1] = rightbox.clone();
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
                    sah = sahtmp;
                    split.overlap = intersection(leftbox, rightbounds[i]).surfaceArea() * invarea;
                }
            }
        }

        if (splitidx !== -1) {
            split.split = rootmin.get(split.dim) + (splitidx + 1) * (centroid_extents.get(split.dim) / this.m_num_bins);
            split.sah = sah;
        }

        return split;
    }

    findSpatialSahSplit(req: SplitRequest, refs: PrimRefArray): SahSplit {
        const kNumBins = 128;
        let sah = Number.MAX_VALUE;
        const split = {
            dim: 0,
            split: NaN,
            sah: sah,
            overlap: 0
        };

        const extents = req.bounds.extents();
        const invarea = 1.0 / req.bounds.surfaceArea();

        if (Vec3.dot(extents, extents) === 0.0) {
            return split;
        }

        type Bin = { bounds: BBox; enter: number; exit: number; };
        const bins: Bin[][] = [[], [], []];
        for (let axis = 0; axis < 3; ++axis) {
            bins[axis] = Array(kNumBins).fill(null).map(() => ({ bounds: new BBox(), enter: 0, exit: 0 }));
        }

        const origin = req.bounds.pmin;
        const binsize = req.bounds.extents().scale(1.0 / kNumBins);
        const invbinsize = new Vec3(1.0 / binsize.x, 1.0 / binsize.y, 1.0 / binsize.z);

        for (let i = req.startidx; i < req.startidx + req.numprims; ++i) {
            const primref = refs[i];
            const firstbin = Vec3.clamp(
                primref.bounds.pmin.subtract(origin).multiply(invbinsize),
                new Vec3(0, 0, 0),
                new Vec3(kNumBins - 1, kNumBins - 1, kNumBins - 1)
            );
            const lastbin = Vec3.clamp(
                primref.bounds.pmax.subtract(origin).multiply(invbinsize),
                firstbin,
                new Vec3(kNumBins - 1, kNumBins - 1, kNumBins - 1)
            );
            for (let axis = 0; axis < 3; ++axis) {
                if (extents.get(axis) === 0.0) continue;
                let tempref = primref;

                for (let j = firstbin.get(axis); j < lastbin.get(axis); ++j) {
                    let leftref: PrimRef = { ...tempref }, rightref: PrimRef = { ...tempref };
                    const splitval = origin.get(axis) + binsize.get(axis) * (j + 1);
                    if (this.splitPrimRef(tempref, axis, splitval, leftref, rightref)) {
                        bins[axis][j].bounds.grow(leftref.bounds);
                        tempref = rightref;
                    }
                }
                bins[axis][lastbin.get(axis)].bounds.grow(tempref.bounds);
                bins[axis][firstbin.get(axis)].enter++;
                bins[axis][lastbin.get(axis)].exit++;
            }
        }

        const rightbounds: BBox[] = new Array(kNumBins - 1);

        for (let axis = 0; axis < 3; ++axis) {
            if (extents.get(axis) === 0.0) continue;

            let rightbox = new BBox();
            for (let i = kNumBins - 1; i > 0; --i) {
                rightbox = bboxUnion(rightbox, bins[axis][i].bounds);
                rightbounds[i - 1] = rightbox.clone();
            }

            let leftbox = new BBox();
            let leftcount = 0;
            let rightcount = req.numprims;

            for (let i = 1; i < kNumBins; ++i) {
                leftbox.grow(bins[axis][i - 1].bounds);
                leftcount += bins[axis][i - 1].enter;
                rightcount -= bins[axis][i - 1].exit;
                const sah = this.m_traversal_cost +
                    (leftbox.surfaceArea() + rightbounds[i - 1].surfaceArea() * rightcount) * invarea;

                if (sah < split.sah) {
                    split.sah = sah;
                    split.dim = axis;
                    split.split = origin.get(axis) + binsize.get(axis) * i;
                    split.overlap = 0.0;
                }
            }
        }

        return split;
    }

    splitPrimRef(ref: PrimRef, axis: number, split: number, leftref: PrimRef, rightref: PrimRef): boolean {
        leftref.idx = rightref.idx = ref.idx;
        leftref.bounds = ref.bounds.clone();
        rightref.bounds = ref.bounds.clone();

        if (split > ref.bounds.pmin.get(axis) && split < ref.bounds.pmax.get(axis)) {
            leftref.bounds.pmax.set(axis, split);
            rightref.bounds.pmin.set(axis, split);
            return true;
        }
        return false;
    }

    splitPrimRefs(split: SahSplit, req: SplitRequest, refs: PrimRefArray, setExtraRefs: (v: number) => void) {
        let appendprims = req.numprims;

        for (let i = req.startidx; i < req.startidx + req.numprims; ++i) {
            if (req.startidx + appendprims >= refs.length) throw new Error('Out of bounds');

            let leftref: PrimRef = { ...refs[i] }, rightref: PrimRef = { ...refs[i] };
            if (this.splitPrimRef(refs[i], split.dim, split.split, leftref, rightref)) {
                refs[i] = leftref;
                refs[req.startidx + appendprims++] = rightref;
            }
        }

        setExtraRefs(appendprims - req.numprims);
    }

    allocateNode(): Node {
        if (this.m_nodecnt - this.m_num_nodes_archived >= this.m_num_nodes_for_regular) {
            this.m_node_archive.push(this.m_nodes);
            this.m_num_nodes_archived += this.m_num_nodes_for_regular;
            this.m_nodes = new Array(this.m_num_nodes_for_regular);
            for (let i = 0; i < this.m_num_nodes_for_regular; ++i) {
                this.m_nodes[i] = new Node();
            }
        }
        return this.m_nodes[this.m_nodecnt++ - this.m_num_nodes_archived];
    }

    initNodeAllocator(maxnum: number) {
        this.m_node_archive = [];
        this.m_nodecnt = 0;
        this.m_nodes = new Array(maxnum);
        for (let i = 0; i < maxnum; ++i) {
            this.m_nodes[i] = new Node();
        }
    }

    printStatistics(): string {
        const num_triangles = Math.floor((this.m_num_nodes_for_regular + 1) / 2);
        const num_refs = this.m_packed_indices.length;
        return [
            `Class name: SplitBvh`,
            `SAH: enabled (forced)`,
            `SAH bins: ${this.m_num_bins}`,
            `Max split depth: ${this.m_max_split_depth}`,
            `Min node overlap: ${this.m_min_overlap}`,
            `Number of triangles: ${num_triangles}`,
            `Number of triangle refs: ${num_refs}`,
            `Ref duplication: ${((num_refs - num_triangles) / num_triangles) * 100.0}%`,
            `Number of nodes: ${this.m_nodecnt}`,
            `Number of nodes in corresponding non-split BVH: ${this.m_num_nodes_for_regular}`,
            `Node overhead: ${((this.m_nodecnt - this.m_num_nodes_for_regular) / this.m_num_nodes_for_regular) * 100.0}%`,
            `Tree height: ${this.getHeight()}`
        ].join('\n');
    }

    getHeight(): number {
        return this.m_height;
    }
}