// Native envmap loading (feature 004, Phase 2): replaces three.js's RGBELoader
// addon for .hdr and the RGBELoader/TextureLoader combo used for LDR envmaps,
// while still handing back a plain THREE.Texture/DataTexture so the rest of the
// pipeline (ShaderMaterial uniforms, scene.background, EquirectangularReflectionMapping)
// is unchanged. Also builds the luminance-CDF importance-sampling data for HDR maps
// (feature 004, Phase 5 "envmap" alignment with GLSL-PathTracer-JS's skeleton.glsl).
import { DataTexture, Texture, RGBAFormat, RedFormat, HalfFloatType, FloatType, LinearFilter, NearestFilter, DataUtils } from 'three';
import { loadRadianceHdr } from './hdrLoader.js';

function isHdrPath(path) { return /\.hdr(?:$|[?#])/i.test(path); }

async function loadLdrEnvTexture(url) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Image fetch failed: ${response.status} ${url}`);
    // three.js still applies UNPACK_FLIP_Y_WEBGL per texture.flipY at upload time for
    // ImageBitmap sources, same as the previous <img>-based TextureLoader, so no extra
    // flip is needed here.
    const bitmap = await createImageBitmap(await response.blob());
    const texture = new Texture(bitmap);
    texture.needsUpdate = true;
    // No luminance CDF for LDR envmaps (importance sampling stays on the cosine-hemisphere
    // fallback in glsl/pathtracing/mtlx/pathtracer.glsl for this path).
    return { texture, importance: null };
}

async function loadHdrEnvTexture(url) {
    const { width, height, data, cdf, totalSum } = await loadRadianceHdr(url, DataUtils.toHalfFloat);
    const texture = new DataTexture(data, width, height, RGBAFormat, HalfFloatType);
    texture.minFilter = LinearFilter;
    texture.magFilter = LinearFilter;
    texture.generateMipmaps = false;
    texture.flipY = true;
    texture.needsUpdate = true;

    // Dedicated raw-scanline-order copy (flipY=false) for CDF-based importance sampling:
    // its uv<->direction convention (see envMapBinarySearch/envMapUvToDir in pathtracer.glsl)
    // must match the CDF's row-major layout below, independent of three.js's own
    // flipY=true/asin-based `envMap` convention used for background/reflections.
    const equirectTexture = new DataTexture(data, width, height, RGBAFormat, HalfFloatType);
    equirectTexture.minFilter = LinearFilter;
    equirectTexture.magFilter = LinearFilter;
    equirectTexture.generateMipmaps = false;
    equirectTexture.flipY = false;
    equirectTexture.needsUpdate = true;

    const cdfTexture = new DataTexture(cdf, width, height, RedFormat, FloatType);
    cdfTexture.minFilter = NearestFilter;
    cdfTexture.magFilter = NearestFilter;
    cdfTexture.generateMipmaps = false;
    cdfTexture.flipY = false;
    cdfTexture.needsUpdate = true;

    return { texture, importance: { equirectTexture, cdfTexture, totalSum, width, height } };
}

export function loadEnvironmentTexture(url) {
    return isHdrPath(url) ? loadHdrEnvTexture(url) : loadLdrEnvTexture(url);
}
