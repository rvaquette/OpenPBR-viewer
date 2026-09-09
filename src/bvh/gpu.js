import {
    ClampToEdgeWrapping,
    DataTexture,
    FloatType,
    NearestFilter,
    RGBAFormat,
} from 'three';
import { BvhTranslator } from './bvhTranslator.js';

function textureDimensions(texelCount) {
    const width = Math.max(1, Math.ceil(Math.sqrt(texelCount)));
    return { width, height: Math.max(1, Math.ceil(texelCount / width)) };
}

function makeTexture(data, texelCount, format, type) {
    const { width, height } = textureDimensions(texelCount);
    const padded = new data.constructor(width * height * 4);
    padded.set(data);
    const texture = new DataTexture(padded, width, height, format, type);
    texture.minFilter = NearestFilter;
    texture.magFilter = NearestFilter;
    texture.wrapS = ClampToEdgeWrapping;
    texture.wrapT = ClampToEdgeWrapping;
    texture.generateMipmaps = false;
    texture.needsUpdate = true;
    return texture;
}

export class NativeAttributeTexture extends DataTexture {
    constructor() {
        super(new Float32Array(4), 1, 1, RGBAFormat, FloatType);
        this.minFilter = NearestFilter;
        this.magFilter = NearestFilter;
        this.generateMipmaps = false;
    }

    updateFrom(attribute) {
        const data = new Float32Array(attribute.count * 4);
        for (let index = 0; index < attribute.count; index++) {
            data[index * 4] = attribute.getX(index);
            if (attribute.itemSize > 1) data[index * 4 + 1] = attribute.getY(index);
            if (attribute.itemSize > 2) data[index * 4 + 2] = attribute.getZ(index);
            if (attribute.itemSize > 3) data[index * 4 + 3] = attribute.getW(index);
        }
        const texture = makeTexture(data, attribute.count, RGBAFormat, FloatType);
        this.image = texture.image;
        this.needsUpdate = true;
        texture.dispose();
        return this;
    }
}

export function createNativeBvhTextures(bvh) {
    const translated = new BvhTranslator(bvh);
    return {
        nodes: makeTexture(translated.nodes, bvh.nodes.length * 3, RGBAFormat, FloatType),
        indices: makeTexture(translated.triangleIndices, bvh.packedTriangleIndices.length, RGBAFormat, FloatType),
        positions: new NativeAttributeTexture().updateFrom(bvh.geometry.attributes.position),
    };
}

export function createNativeBvhUniforms(prefix) {
    return {
        [`${prefix}_nodes`]: { value: null },
        [`${prefix}_indices`]: { value: null },
        [`${prefix}_positions`]: { value: null },
    };
}

export function assignNativeBvhUniforms(uniforms, prefix, bvh) {
    const textures = createNativeBvhTextures(bvh);
    uniforms[`${prefix}_nodes`].value = textures.nodes;
    uniforms[`${prefix}_indices`].value = textures.indices;
    uniforms[`${prefix}_positions`].value = textures.positions;
    return textures;
}