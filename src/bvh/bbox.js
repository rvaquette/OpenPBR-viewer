export class BBox {
    constructor(minimum = [Infinity, Infinity, Infinity], maximum = [-Infinity, -Infinity, -Infinity]) {
        this.minimum = [...minimum];
        this.maximum = [...maximum];
    }

    growPoint(point) {
        for (let axis = 0; axis < 3; axis++) {
            this.minimum[axis] = Math.min(this.minimum[axis], point[axis]);
            this.maximum[axis] = Math.max(this.maximum[axis], point[axis]);
        }
        return this;
    }

    growBounds(bounds) {
        this.growPoint(bounds.minimum);
        this.growPoint(bounds.maximum);
        return this;
    }

    centroid() {
        return [
            (this.minimum[0] + this.maximum[0]) * 0.5,
            (this.minimum[1] + this.maximum[1]) * 0.5,
            (this.minimum[2] + this.maximum[2]) * 0.5,
        ];
    }

    extent(axis) {
        return this.maximum[axis] - this.minimum[axis];
    }

    surfaceArea() {
        const x = this.extent(0);
        const y = this.extent(1);
        const z = this.extent(2);
        return 2 * (x * y + x * z + y * z);
    }

    maximumAxis() {
        const x = this.extent(0);
        const y = this.extent(1);
        const z = this.extent(2);
        return x >= y && x >= z ? 0 : (y >= z ? 1 : 2);
    }
}