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

function createRenderTexture(device, data) {
    const texelCount = Math.max(1, Math.ceil(data.length / 4));
    const maxDimension = device.limits.maxTextureDimension2D;
    const preferredWidth = Math.ceil(Math.sqrt(texelCount) / 16) * 16;
    const width = Math.min(maxDimension, Math.max(16, preferredWidth));
    const height = Math.ceil(texelCount / width);
    if (height > maxDimension) {
        throw new Error(`BVH render texture requires ${texelCount} texels, exceeding the device ${maxDimension}x${maxDimension} texture limit.`);
    }
    const texture = device.createTexture({
        size: [width, height, 1],
        format: 'rgba32float',
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
    });
    const paddedTexelCount = width * height;
    const padded = data.length === paddedTexelCount * 4 ? data : new Float32Array(paddedTexelCount * 4);
    if (padded !== data) padded.set(data);
    device.queue.writeTexture(
        { texture },
        padded,
        { bytesPerRow: width * 16, rowsPerImage: height },
        { width, height, depthOrArrayLayers: 1 },
    );
    return texture;
}

function createRenderSampler(device) {
    return device.createSampler({ magFilter: 'nearest', minFilter: 'nearest', mipmapFilter: 'nearest' });
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
    const renderSampler = createRenderSampler(device);
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
        renderSampler,
        renderTextures: {
            nodes: createRenderTexture(device, translated.nodes),
            triangleIndices: createRenderTexture(device, triangleIndices),
            positions: createRenderTexture(device, positions),
            normals: createRenderTexture(device, normals),
            tangents: createRenderTexture(device, tangents),
            uvs: createRenderTexture(device, uvs),
            neutralFlags: createRenderTexture(device, neutralFlags),
        },
        destroy() {
            for (const value of Object.values(this)) {
                if (value?.destroy) value.destroy();
                else if (value && typeof value === 'object') for (const nested of Object.values(value)) if (nested?.destroy) nested.destroy();
            }
        }
    };
}