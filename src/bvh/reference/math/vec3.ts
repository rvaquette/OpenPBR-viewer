import { Vec4 } from "./vec4.js";

export class Vec3 {
    x: number;
    y: number;
    z: number;

    constructor(x: number = 0, y: number = 0, z: number = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    toArray(): number[] {
        return [this.x, this.y, this.z];
    }
    
    clone(): Vec3 {
        return new Vec3(this.x, this.y, this.z);
    }

    static fromVec4(b: Vec4): Vec3 {
        return new Vec3(b.x, b.y, b.z);
    }

    multiply(b: Vec3): Vec3 {
        return new Vec3(this.x * b.x, this.y * b.y, this.z * b.z);
    }

    static add(a: Vec3, b: Vec3): Vec3 {
        return a.add(b);
    }

    add(b: Vec3): Vec3 {
        return new Vec3(this.x + b.x, this.y + b.y, this.z + b.z);
    }

    static subtract(a: Vec3, b: Vec3): Vec3 {
        return a.subtract(b);
    }

    subtract(b: Vec3): Vec3 {
        return new Vec3(this.x - b.x, this.y - b.y, this.z - b.z);
    }

    static scale(a: Vec3, b: number): Vec3 {
        return a.scale(b);
    }

    scale(b: number): Vec3 {
        return new Vec3(this.x * b, this.y * b, this.z * b);
    }

    get(i: number): number {
        if (i === 0) return this.x;
        if (i === 1) return this.y;
        return this.z;
    }

    set(i: number, value: number): void {
        if (i === 0) this.x = value;
        else if (i === 1) this.y = value;
        else this.z = value;
    }

    static log(a: Vec3): Vec3 {
        return new Vec3(
            Math.log(a.x),
            Math.log(a.y),
            Math.log(a.z)
        );
    }

    static negate(a: Vec3): Vec3 {
        return new Vec3(
            -a.x,
            -a.y,
            -a.z
        );
    }

    static min(a: Vec3, b: Vec3): Vec3 {
        return new Vec3(
            Math.min(a.x, b.x),
            Math.min(a.y, b.y),
            Math.min(a.z, b.z)
        );
    }

    static max(a: Vec3, b: Vec3): Vec3 {
        return new Vec3(
            Math.max(a.x, b.x),
            Math.max(a.y, b.y),
            Math.max(a.z, b.z)
        );
    }

    static cross(a: Vec3, b: Vec3): Vec3 {
        return new Vec3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        );
    }

    static pow(a: Vec3, exp: number): Vec3 {
        return new Vec3(
            Math.pow(a.x, exp),
            Math.pow(a.y, exp),
            Math.pow(a.z, exp)
        );
    }

    static Length(a: Vec3): number {
        return Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
    }

    static dot(a: Vec3, b: Vec3): number {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    static distance(a: Vec3, b: Vec3): number {
        return Vec3.Length(a.subtract(b));
    }

    static clamp(a: Vec3, min: Vec3, max: Vec3): Vec3 {
        return new Vec3(
            Math.max(min.x, Math.min(a.x, max.x)),
            Math.max(min.y, Math.min(a.y, max.y)),
            Math.max(min.z, Math.min(a.z, max.z))
        );
    }

    static normalize(a: Vec3): Vec3 {
        const l = Vec3.Length(a);
        return new Vec3(a.x / l, a.y / l, a.z / l);
    }
}