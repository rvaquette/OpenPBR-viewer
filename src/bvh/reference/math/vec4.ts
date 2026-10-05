import { Vec3 } from "./vec3.js";

export class Vec4 {
  x: number;
  y: number;
  z: number;
  w: number;

  constructor(
    x: number | Vec3 = 0,
    y: number = 0,
    z: number = 0,
    w: number = 0
  ) {
    if (x instanceof Vec3) {
      this.x = x.x;
      this.y = x.y;
      this.z = x.z;
      this.w = y;
    } else {
      this.x = x;
      this.y = y;
      this.z = z;
      this.w = w;
    }
  }

  get(i: number): number {
    switch (i) {
      case 0:
        return this.x;
      case 1:
        return this.y;
      case 2:
        return this.z;
      case 3:
        return this.w;
      default:
        throw new RangeError("Index out of range for Vec4");
    }
  }

  get xyz(): Vec3 {
    return new Vec3(this.x, this.y, this.z);
  }

  get wxy(): Vec3 {
    return new Vec3(this.w, this.x, this.y);
  }

  toString(): string {
    return `Vec4(${this.x}, ${this.y}, ${this.z}, ${this.w})`;
  }
}
