export class BvhTranslator {
    constructor(bvh) {
        this.nodes = new Float32Array(bvh.nodes.length * 12);
        this.triangleIndices = new Float32Array(bvh.packedTriangleIndices.length * 4);

        for (let nodeIndex = 0; nodeIndex < bvh.nodes.length; nodeIndex++) {
            const node = bvh.nodes[nodeIndex];
            const base = nodeIndex * 12;
            this.nodes.set(node.bounds.minimum, base);
            this.nodes.set(node.bounds.maximum, base + 4);
            if (node.count > 0) {
                this.nodes[base + 8] = node.offset;
                this.nodes[base + 9] = node.count;
                this.nodes[base + 10] = 1;
            } else {
                this.nodes[base + 8] = node.left;
                this.nodes[base + 9] = node.right;
            }
        }

        for (let packedIndex = 0; packedIndex < bvh.packedTriangleIndices.length; packedIndex++) {
            const triangleIndex = bvh.packedTriangleIndices[packedIndex];
            const vertices = bvh.triangleVertices[triangleIndex];
            this.triangleIndices.set(vertices, packedIndex * 4);
        }
    }
}