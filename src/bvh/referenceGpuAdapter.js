import { DataTexture, RGBAFormat, RGBAIntegerFormat, FloatType, IntType,
    NearestFilter, ClampToEdgeWrapping, NoColorSpace } from 'three';

const TEXTURE_NAMES = ['BVH', 'vertexIndicesTex', 'verticesTex', 'normalsTex', 'transformsTex'];

function requireGpu(condition, code, detail) {
    if (!condition) throw new Error(`${code}: ${detail}`);
}

export function referenceTextureLayout(logicalElements, logicalChannels, limits) {
    requireGpu(Number.isSafeInteger(logicalElements) && logicalElements >= 0 && [3,4].includes(logicalChannels) && logicalElements % logicalChannels === 0,
        'REFERENCE_TEXTURE_LAYOUT_INVALID', 'logical element/channel count');
    requireGpu(Number.isSafeInteger(limits.maxTextureSize) && limits.maxTextureSize > 0,
        'REFERENCE_TEXTURE_LIMIT_INVALID', 'MAX_TEXTURE_SIZE');
    const logicalTexels = logicalElements / logicalChannels;
    const width = Math.min(4096, limits.maxTextureSize, Math.max(1, logicalTexels));
    const height = Math.max(1, Math.ceil(logicalTexels / width));
    requireGpu(height <= limits.maxTextureSize, 'REFERENCE_TEXTURE_CAPACITY', `${width}x${height}`);
    const physicalElements = width * height * 4;
    requireGpu(Number.isSafeInteger(physicalElements) && physicalElements <= 0x7fffffff,
        'REFERENCE_TEXTURE_ALLOCATION_LIMIT', 'physical RGBA buffer');
    return { width, height, logicalChannels, physicalChannels: 4, logicalElements, logicalTexels, physicalElements,
        paddingTexels: width * height - logicalTexels, byteLength: physicalElements * 4 };
}

function requireExactInteger(value, maximum, detail) {
    requireGpu(Number.isSafeInteger(value) && value >= 0 && value <= maximum,
        'REFERENCE_GPU_INTEGER_INVALID', detail);
}

export function packReferenceScene(scene, limits) {
    requireGpu(scene?.version === 1 && scene.geometry && Array.isArray(scene.instances), 'REFERENCE_GPU_SCENE_INVALID', 'reference CPU scene required');
    requireExactInteger(scene.activeNodeCount, 0xffffff, 'active nodes');
    requireExactInteger(scene.topLevelIndex, 0xffffff, 'TLAS root');
    requireGpu(scene.nodes.length >= scene.activeNodeCount && (scene.activeNodeCount === 0 ? scene.topLevelIndex === 0 : scene.topLevelIndex < scene.activeNodeCount),
        'REFERENCE_GPU_ROOT_INVALID', 'TLAS root outside active nodes');
    requireGpu(scene.geometry.vertexIndices instanceof Int32Array && scene.geometry.vertexIndices.length % 3 === 0,
        'REFERENCE_GPU_INDICES_INVALID', 'Int32 triangle records');
    const vertexCount = scene.geometry.verticesUVX.length;
    const triangleCount = scene.geometry.vertexIndices.length / 3;
    requireExactInteger(vertexCount, 0x7fffffff, 'vertices');
    requireExactInteger(triangleCount, 0xffffff, 'triangles');
    requireExactInteger(scene.instances.length, 0xffffff, 'instances');
    requireGpu((scene.activeNodeCount === 0) === (scene.instances.length === 0),
        'REFERENCE_GPU_SCENE_INVALID', 'active nodes and instance count disagree');
    requireGpu(scene.geometry.normalsUVY.length === vertexCount && scene.transforms.length === scene.instances.length,
        'REFERENCE_GPU_RECORD_COUNT_INVALID', 'normals/transforms');
    let stackRequirement = 0;
    if (scene.instances.length > 0) {
        requireGpu(Number.isSafeInteger(scene.tlasStats?.maxDepth) && Array.isArray(scene.meshes),
            'REFERENCE_GPU_STACK_METADATA_INVALID', 'TLAS/BLAS depth metadata required');
        const maxBlasDepth = scene.instances.reduce((maximum, instance) => {
            const depth = scene.meshes[instance.meshID]?.blasStats?.maxDepth;
            requireGpu(Number.isSafeInteger(depth) && depth >= 0, 'REFERENCE_GPU_STACK_METADATA_INVALID', `BLAS depth for mesh ${instance.meshID}`);
            return Math.max(maximum, depth);
        }, 0);
        stackRequirement = scene.tlasStats.maxDepth + maxBlasDepth + 2;
        requireGpu(stackRequirement <= 64, 'REFERENCE_GPU_STACK_CAPACITY', `combined TLAS/BLAS stack requirement ${stackRequirement} exceeds 64`);
    }
    requireGpu(Number.isSafeInteger(limits.maxTextureImageUnits) && limits.maxTextureImageUnits >= 0 &&
        Number.isSafeInteger(limits.reservedTextureUnits) && limits.reservedTextureUnits >= 0,
        'REFERENCE_TEXTURE_LIMIT_INVALID', 'sampler budget must include existing material/environment bindings');
    requireGpu(TEXTURE_NAMES.length + limits.reservedTextureUnits <= limits.maxTextureImageUnits,
        'REFERENCE_TEXTURE_UNIT_CAPACITY', 'five reference samplers plus existing bindings');
    const definitions = [
        { name: 'BVH', channels: 3, length: scene.activeNodeCount * 9, integer: false },
        { name: 'vertexIndicesTex', channels: 3, length: triangleCount * 3, integer: true },
        { name: 'verticesTex', channels: 4, length: vertexCount * 4, integer: false },
        { name: 'normalsTex', channels: 4, length: vertexCount * 4, integer: false },
        { name: 'transformsTex', channels: 4, length: scene.instances.length * 16, integer: false },
    ].map((definition) => ({ ...definition, layout: referenceTextureLayout(definition.length, definition.channels, limits) }));
    const byteLength = definitions.reduce((bytes, definition) => bytes + definition.layout.byteLength, 0);
    if (limits.maxBufferBytes !== undefined) {
        requireGpu(Number.isSafeInteger(limits.maxBufferBytes) && limits.maxBufferBytes >= 0,
            'REFERENCE_TEXTURE_LIMIT_INVALID', 'buffer memory budget');
        requireGpu(byteLength <= limits.maxBufferBytes, 'REFERENCE_TEXTURE_MEMORY_CAPACITY', 'RGBA buffers exceed requested budget');
    }
    const buffers = {};
    for (const definition of definitions) {
        const data = definition.integer ? new Int32Array(definition.layout.physicalElements) : new Float32Array(definition.layout.physicalElements);
        buffers[definition.name] = { ...definition, data, internalFormat: definition.integer ? 'RGBA32I' : 'RGBA32F',
            samplerType: definition.integer ? 'isampler2D' : 'sampler2D' };
    }
    const put = (name, logicalIndex, value) => {
        const buffer = buffers[name];
        requireGpu(Number.isFinite(value) && Number.isFinite(Math.fround(value)), 'REFERENCE_GPU_FLOAT_INVALID', `${name} value`);
        const physicalIndex = Math.floor(logicalIndex / buffer.channels) * 4 + logicalIndex % buffer.channels;
        buffer.data[physicalIndex] = value;
    };
    for (let nodeIndex = 0; nodeIndex < scene.activeNodeCount; nodeIndex++) {
        const node = scene.nodes[nodeIndex];
        requireGpu(node?.bboxmin && node.bboxmax && node.LRLeaf, 'REFERENCE_GPU_NODE_INVALID', `node ${nodeIndex}`);
        const values = [...node.bboxmin.toArray(), ...node.bboxmax.toArray(), ...node.LRLeaf.toArray()];
        for (const axis of ['x','y','z']) requireGpu(node.bboxmin[axis] <= node.bboxmax[axis], 'REFERENCE_GPU_BOUNDS_INVALID', `node ${nodeIndex}`);
        const [left, right, leaf] = node.LRLeaf.toArray();
        requireExactInteger(left, 0xffffff, 'node left/offset');
        requireExactInteger(right, 0xffffff, 'node right/count/material');
        requireGpu(Number.isSafeInteger(leaf) && Math.abs(leaf) <= 0xffffff, 'REFERENCE_GPU_INTEGER_INVALID', 'node leaf tag');
        if (leaf === 0) {
            const blas = nodeIndex < scene.topLevelIndex;
            requireGpu(left < scene.activeNodeCount && right < scene.activeNodeCount && left !== nodeIndex && right !== nodeIndex &&
                (left < scene.topLevelIndex) === blas && (right < scene.topLevelIndex) === blas,
                'REFERENCE_GPU_NODE_INVALID', 'child indices or BLAS/TLAS partition');
        } else if (leaf > 0) {
            requireGpu(nodeIndex < scene.topLevelIndex && leaf === 1 && right > 0 && left + right <= triangleCount,
                'REFERENCE_GPU_NODE_INVALID', 'BLAS primitive range');
        } else {
            const instance = scene.instances[-leaf - 1];
            const range = instance && scene.geometry.meshRanges[instance.meshID];
            requireGpu(nodeIndex >= scene.topLevelIndex && left < scene.topLevelIndex && range &&
                left === range.nodeOffset && right === instance.materialID,
                'REFERENCE_GPU_NODE_INVALID', 'TLAS instance/root/material');
        }
        values.forEach((value, offset) => put('BVH', nodeIndex * 9 + offset, value));
    }
    scene.geometry.vertexIndices.forEach((value, index) => {
        requireExactInteger(value, 0x7fffffff, 'vertex index');
        requireGpu(value < vertexCount, 'REFERENCE_GPU_INDEX_OUT_OF_BOUNDS', `index ${index}`);
        put('vertexIndicesTex', index, value);
    });
    for (const [name, vectors] of [['verticesTex', scene.geometry.verticesUVX], ['normalsTex', scene.geometry.normalsUVY]]) {
        vectors.forEach((vector, index) => [vector.x, vector.y, vector.z, vector.w].forEach((value, component) => put(name, index * 4 + component, value)));
    }
    scene.transforms.forEach((matrix, index) => {
        requireGpu(matrix.length === 16, 'REFERENCE_GPU_TRANSFORM_INVALID', `instance ${index}`);
        Array.from(matrix).forEach((value, component) => put('transformsTex', index * 16 + component, value));
    });
    return { version: 1, physicalFormat: 'RGBA-with-logical-RGB-ABI', buffers, byteLength, stackRequirement,
        counts: { nodes: scene.activeNodeCount, vertices: vertexCount, triangles: triangleCount, instances: scene.instances.length },
        topLevelIndex: scene.topLevelIndex, meshRanges: scene.geometry.meshRanges };
}

export function createReferenceSceneTextures(scene, limits) {
    const packed = packReferenceScene(scene, limits);
    const textures = {};
    const uniforms = {};
    for (const [name, buffer] of Object.entries(packed.buffers)) {
        const texture = new DataTexture(buffer.data, buffer.layout.width, buffer.layout.height,
            buffer.integer ? RGBAIntegerFormat : RGBAFormat, buffer.integer ? IntType : FloatType);
        Object.assign(texture, { name: `reference-${name}`, internalFormat: buffer.internalFormat,
            minFilter: NearestFilter, magFilter: NearestFilter, wrapS: ClampToEdgeWrapping, wrapT: ClampToEdgeWrapping,
            generateMipmaps: false, flipY: false, colorSpace: NoColorSpace, unpackAlignment: 1 });
        texture.needsUpdate = true;
        textures[name] = texture;
        uniforms[name] = { value: texture };
    }
    uniforms.topBVHIndex = { value: packed.topLevelIndex };
    uniforms.referenceNodeCount = { value: packed.counts.nodes };
    uniforms.referenceInstanceCount = { value: packed.counts.instances };
    let disposed = false;
    return { packed, textures, uniforms, dispose() {
        if (disposed) return;
        for (const texture of Object.values(textures)) texture.dispose();
        disposed = true;
    } };
}

export function uploadReferenceSceneTextures(renderer, scene, options = {}) {
    requireGpu(renderer?.capabilities?.isWebGL2 === true && typeof renderer.initTexture === 'function',
        'REFERENCE_GPU_WEBGL2_REQUIRED', 'WebGL2 renderer with initTexture required');
    const bundle = createReferenceSceneTextures(scene, { maxTextureSize: renderer.capabilities.maxTextureSize,
        maxTextureImageUnits: renderer.capabilities.maxTextures, reservedTextureUnits: options.reservedTextureUnits,
        maxBufferBytes: options.maxBufferBytes });
    try {
        for (const texture of Object.values(bundle.textures)) renderer.initTexture(texture);
        return bundle;
    } catch (error) {
        bundle.dispose();
        throw error;
    }
}