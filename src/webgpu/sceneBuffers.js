import { BvhTranslator } from '../bvh/bvhTranslator.js';

function attributeToVec4(attribute, fallback) {
    const values = new Float32Array((attribute?.count || 0) * 4);
    for (let index = 0; index < (attribute?.count || 0); index++) {
        values[index * 4] = attribute.getX(index);
        values[index * 4 + 1] = attribute.itemSize > 1 ? attribute.getY(index) : fallback[1];
        values[index * 4 + 2] = attribute.itemSize > 2 ? attribute.getZ(index) : fallback[2];
        values[index * 4 + 3] = attribute.itemSize > 3 ? attribute.getW(index) : fallback[3];
    }
    return values;
}

function createStorageBuffer(device, data) {
    const buffer = device.createBuffer({ size: Math.max(4, Math.ceil(data.byteLength / 4) * 4), usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST | GPUBufferUsage.COPY_SRC });
    if (data.byteLength) device.queue.writeBuffer(buffer, 0, data);
    return buffer;
}

export function createWebGpuSceneBuffers(device, bvh) {
    const translated = new BvhTranslator(bvh);
    const triangleIndices = new Uint32Array(translated.triangleIndices.length);
    for (let index = 0; index < translated.triangleIndices.length; index++) triangleIndices[index] = translated.triangleIndices[index];
    const attributes = bvh.geometry.attributes;
    const positions = attributeToVec4(attributes.position, [0, 0, 0, 1]);
    const normals = attributeToVec4(attributes.normal, [0, 0, 1, 0]);
    const tangents = attributeToVec4(attributes.tangent, [1, 0, 0, 1]);
    const uvs = attributeToVec4(attributes.uv, [0, 0, 0, 0]);
    const neutralFlags = attributeToVec4(attributes.neutralFlag, [0, 0, 0, 0]);
    return {
        nodeCount: bvh.nodes.length,
        triangleCount: bvh.packedTriangleIndices.length,
        vertexCount: attributes.position.count,
        nodes: createStorageBuffer(device, translated.nodes),
        triangleIndices: createStorageBuffer(device, triangleIndices),
        positions: createStorageBuffer(device, positions),
        normals: createStorageBuffer(device, normals),
        tangents: createStorageBuffer(device, tangents),
        uvs: createStorageBuffer(device, uvs),
        neutralFlags: createStorageBuffer(device, neutralFlags),
        destroy() { for (const value of Object.values(this)) if (value?.destroy) value.destroy(); }
    };
}