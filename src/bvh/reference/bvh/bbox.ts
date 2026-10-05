import { Vec3 } from "../math/vec3.js";

export class BBox {
    pmin: Vec3;
    pmax: Vec3;

    constructor();
    constructor(p: Vec3);
    constructor(p1: Vec3, p2: Vec3);
    constructor(p1?: Vec3, p2?: Vec3) {
        if (p1 === undefined && p2 === undefined) {
            this.pmin = new Vec3(Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY);
            this.pmax = new Vec3(Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY);
        } else if (p1 !== undefined && p2 === undefined) {
            this.pmin = p1.clone();
            this.pmax = p1.clone();
        } else if (p1 !== undefined && p2 !== undefined) {
            this.pmin = Vec3.min(p1, p2);
            this.pmax = Vec3.max(p1, p2);
        } else {
            throw new Error('Invalid constructor arguments');
        }
    }

    clone(): BBox {
        return new BBox(this.pmin.clone(), this.pmax.clone());
    }

    center(): Vec3 {
        return this.pmin.add(this.pmax).scale(0.5);
    }

    extents(): Vec3 {
        return this.pmax.subtract(this.pmin);
    }

    surfaceArea(): number {
        const ext = this.extents();
        return 2 * (ext.x * ext.y + ext.x * ext.z + ext.y * ext.z);
    }

    grow(p: Vec3): void;
    grow(b: BBox): void;
    grow(arg: Vec3 | BBox): void {
        if (arg instanceof Vec3) {
            this.pmin = Vec3.min(this.pmin, arg);
            this.pmax = Vec3.max(this.pmax, arg);
        } else if (arg instanceof BBox) {
            this.pmin = Vec3.min(this.pmin, arg.pmin);
            this.pmax = Vec3.max(this.pmax, arg.pmax);
        }
    }

    contains(p: Vec3): boolean {
        let radius = this.extents().scale(0.5);
        return Math.abs(this.center().x - p.x) <= radius.x &&
            Math.abs(this.center().y - p.y) <= radius.y &&
            Math.abs(this.center().z - p.z) <= radius.z;
    }

    maxdim(): number {
        const ext = this.extents();
        if (ext.x >= ext.y && ext.x >= ext.z) return 0;
        if (ext.y >= ext.x && ext.y >= ext.z) return 1;
        if (ext.z >= ext.x && ext.z >= ext.y) return 2;
        return 0;
    }

    get(i: number): Vec3 {
        if (i === 0) return this.pmin;
        if (i === 1) return this.pmax;
        throw new Error('Index out of bounds');
    }

}

// Standalone functions

export function bboxUnion(box1: BBox, box2: BBox): BBox {
    return new BBox(Vec3.min(box1.pmin, box2.pmin), Vec3.max(box1.pmax, box2.pmax));
}

export function intersection(box1: BBox, box2: BBox): BBox {
    return new BBox(Vec3.max(box1.pmin, box2.pmin), Vec3.min(box1.pmax, box2.pmax));
}

export function intersectionInto(box1: BBox, box2: BBox, box: BBox): void {
    box.pmin = Vec3.max(box1.pmin, box2.pmin);
    box.pmax = Vec3.min(box1.pmax, box2.pmax);
}

const BBOX_INTERSECTION_EPS = 0.;

export function intersects(box1: BBox, box2: BBox): boolean {
    let b1c = box1.center();
    let b1r = box1.extents().scale(0.5);
    let b2c = box2.center();
    let b2r = box2.extents().scale(0.5);

    return (Math.abs(b2c.x - b1c.x) - (b1r.x + b2r.x)) <= BBOX_INTERSECTION_EPS &&
        (Math.abs(b2c.y - b1c.y) - (b1r.y + b2r.y)) <= BBOX_INTERSECTION_EPS &&
        (Math.abs(b2c.z - b1c.z) - (b1r.z + b2r.z)) <= BBOX_INTERSECTION_EPS;
}

export function contains(box1: BBox, box2: BBox): boolean {
    return box1.contains(box2.pmin) && box1.contains(box2.pmax);
}