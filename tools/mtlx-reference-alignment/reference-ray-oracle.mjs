import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { chromium } from 'playwright-core';
import { BufferGeometry, Float32BufferAttribute, Matrix4, Matrix3, Vector3 } from 'three';
import { adaptReferenceGeometry } from '../../src/bvh/referenceSceneAdapter.js';
import { buildReferenceBlas } from '../../src/bvh/referenceBlas.js';
import { buildReferenceScene } from '../../src/bvh/referenceScene.js';
import { packReferenceScene } from '../../src/bvh/referenceGpuAdapter.js';
import { assertReferenceMaterialCoverage, createReferenceMaterialRegistry } from '../../src/mtlx/referenceMaterialRegistry.js';

const root = resolve('.');
const outputPath = join(root, 'artifacts/mtlx-reference-alignment/t014-reference-ray-oracle.json');
const shadowOutputPath = join(root, 'artifacts/mtlx-reference-alignment/t015-shadow-oracle.json');
const triangles = [
    [[-1,-1,0],[1,-1,0],[-1,1,0]],
    [[1,-1,-1],[3,-1,-1],[1,1,-1]],
    [[3,-1,0],[3,1,0],[3,-1,2]],
    [[-1,-1,-2],[1,-1,-2],[-1,1,-2]],
];
const normalSets = [
    [[0,0,1],[0.05,0,1],[0,0.05,1]],
    [[0,0,1],[0,0.05,1],[0.05,0,1]],
    [[1,0,0],[1,0.05,0],[1,0,0.05]],
    [[0,0,1],[0,0,1],[0,0,1]],
];
const uvSets = [
    [[0,0],[1,0],[0,1]],
    [[0,0],[1,0],[0,1]],
    [[0,0],[1,0],[0,1]],
    [[0.25,0.5],[0.25,0.5],[0.25,0.5]],
];
const positions = triangles.flat();
const normals = normalSets.flat();
const uvs = uvSets.flat();
const geometry = new BufferGeometry();
geometry.setAttribute('position', new Float32BufferAttribute(positions.flat(), 3));
geometry.setAttribute('normal', new Float32BufferAttribute(normals.flat(), 3));
geometry.setAttribute('uv', new Float32BufferAttribute(uvs.flat(), 2));
const primitive = adaptReferenceGeometry(geometry).primitives[0];
const mesh = buildReferenceBlas(primitive);
const transforms = [
    new Matrix4(),
    new Matrix4().compose(new Vector3(-4,1,-0.5), new (await import('three')).Quaternion().setFromAxisAngle(new Vector3(0,1,0), 0.43), new Vector3(-1.2,0.75,1.1)),
];
const instances = [
    { meshID:0, materialID:11, worldTransform:transforms[0] },
    { meshID:0, materialID:23, worldTransform:transforms[1] },
];
const scene = buildReferenceScene([mesh], instances);
const adapter = packReferenceScene(scene, { maxTextureSize:4096, maxTextureImageUnits:32, reservedTextureUnits:0 });
const materialRegistry = createReferenceMaterialRegistry(instances.map((instance) => ({
    sceneMaterialID:instance.materialID, localMaterialID:1, materialKey:'oracle-openpbr', kind:'openpbr', parameterVariant:0,
})), { activeMaterialKey:'oracle-openpbr' });
assertReferenceMaterialCoverage(scene, materialRegistry);
const materialRegistryRowOffset = 1;
const materialRegistryTextureData = new Float32Array(6 * (materialRegistryRowOffset + materialRegistry.entries.length) * 4);
materialRegistry.entries.forEach((entry, index) => materialRegistryTextureData.set(entry
    ? materialRegistry.packedData.subarray(index * 4, index * 4 + 4)
    : [], (materialRegistryRowOffset + index) * 6 * 4));
const closestHitAbi = readFileSync(join(root, 'glsl/pathtracing/mtlx/reference/closest_hit_abi.glsl'), 'utf8');
const closestHit = readFileSync(join(root, 'glsl/pathtracing/mtlx/reference/closest_hit_mtlx.glsl'), 'utf8');
const anyHit = readFileSync(join(root, 'glsl/pathtracing/mtlx/reference/anyhit_mtlx.glsl'), 'utf8');
const pathtracer = readFileSync(join(root, 'glsl/pathtracing/mtlx/pathtracer.glsl'), 'utf8');
const routeCommon = readFileSync(join(root, 'glsl/pathtracing/mtlx/common.glsl'), 'utf8');
const traceFunction = extractFunction(pathtracer, 'bool trace(');
const traceShadowFunction = extractFunction(pathtracer, 'float TraceShadow(');
const materialResolver = extractFunction(routeCommon, 'bool mtlxResolveReferenceMaterial(');

function extractFunction(source, signature) {
    const start = source.indexOf(signature);
    assert.notEqual(start, -1, `missing function ${signature}`);
    const open = source.indexOf('{', start);
    let depth = 0;
    for (let index = open; index < source.length; index++) {
        if (source[index] === '{') depth++;
        else if (source[index] === '}' && --depth === 0) return source.slice(start, index + 1);
    }
    throw new Error(`unterminated function ${signature}`);
}

let randomState = 0x1234abcd;
function random() {
    randomState ^= randomState << 13;
    randomState ^= randomState >>> 17;
    randomState ^= randomState << 5;
    return (randomState >>> 0) / 0x100000000;
}
function normalize(value) {
    const length = Math.hypot(...value);
    return value.map((component) => component / length);
}
function cross(a, b) { return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]; }
function add(a, b) { return a.map((value, index) => value + b[index]); }
function scale(a, scalar) { return a.map((value) => value * scalar); }
function subtract(a, b) { return a.map((value, index) => value - b[index]); }
function dot(a, b) { return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]; }
function f32vector(value) { return value.map(Math.fround); }

const worldTriangles = instances.map((instance, instanceID) => {
    const matrix = new Matrix4().fromArray(Array.from(scene.transforms[instanceID]));
    const normalMatrix = new Matrix3().getNormalMatrix(matrix);
    return triangles.map((triangle, triangleID) => ({
        instanceID,
        materialID: instance.materialID,
        local: triangle.map((point) => point.map(Math.fround)),
        world: triangle.map((point) => new Vector3(...point).applyMatrix4(matrix).toArray()),
        normals: normalSets[triangleID].map((normal) => new Vector3(...normal).applyMatrix3(normalMatrix).normalize().toArray()),
        uvs: uvSets[triangleID],
    }));
}).flat();

function addRay(origins, directions, origin, direction, maxDistance) {
    origins.push(...f32vector(origin), Math.fround(maxDistance));
    directions.push(...f32vector(normalize(direction)), 0);
}

const rayOrigins = [];
const rayDirections = [];
addRay(rayOrigins, rayDirections, [0,0,1], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [0,0,1], [0,0,-1], 0.5);
addRay(rayOrigins, rayDirections, [0,-0.5,-1.5], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [10,0,1], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [0,-1,1], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [0,0,-1], [0,0,1], 10);
addRay(rayOrigins, rayDirections, [0,-0.5,1], [1,0,-1.0e-5], 20);
addRay(rayOrigins, rayDirections, [0,0,-1], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [-0.2,-0.2,-1], [0,0,-1], 10);
addRay(rayOrigins, rayDirections, [7,-4,0], [0,-1,0], 10);

for (let index = rayOrigins.length / 4; index < 10000; index++) {
    if (index % 10 < 7) {
        const instanceID = index % 2;
        const triangleID = Math.floor(random() * triangles.length);
        const triangle = worldTriangles[instanceID * triangles.length + triangleID];
        let bary = [random(), random(), 0];
        if (bary[0] + bary[1] > 1) { bary[0] = 1 - bary[0]; bary[1] = 1 - bary[1]; }
        bary[2] = 1 - bary[0] - bary[1];
        if (index === 13) bary = [0, 0.5, 0.5];
        const target = triangle.world[0].map((_, axis) => triangle.world.reduce((sum, point, vertex) => sum + point[axis] * bary[vertex], 0));
        const normal = normalize(cross(subtract(triangle.world[1], triangle.world[0]), subtract(triangle.world[2], triangle.world[0])));
        const axis = Math.abs(normal[0]) < 0.8 ? [1,0,0] : [0,1,0];
        const tangent = normalize(cross(axis, normal));
        const bitangent = normalize(cross(normal, tangent));
        const side = index % 2 === 0 ? -1 : 1;
        const direction = normalize(add(scale(normal, side), add(scale(tangent, (random() - 0.5) * 0.8), scale(bitangent, (random() - 0.5) * 0.8))));
        const distance = 0.5 + random() * 5;
        const origin = subtract(target, scale(direction, distance));
        const maxDistance = index % 9 === 0 ? distance * 0.75 : distance * 1.5;
        addRay(rayOrigins, rayDirections, origin, direction, maxDistance);
    } else {
        const origin = [random() * 20 - 10, random() * 12 - 6, random() * 12 - 6];
        const direction = normalize([random() * 2 - 1, random() * 2 - 1, random() * 2 - 1]);
        addRay(rayOrigins, rayDirections, origin, direction, 0.1 + random() * 12);
    }
}

function intersectTriangle(origin, direction, triangle, maxDistance) {
    const edge1 = subtract(triangle.world[1], triangle.world[0]);
    const edge2 = subtract(triangle.world[2], triangle.world[0]);
    const pvec = cross(direction, edge2);
    const determinant = dot(edge1, pvec);
    if (Math.abs(determinant) <= 1.0e-20) return null;
    const inverse = 1 / determinant;
    const tvec = subtract(origin, triangle.world[0]);
    const u = dot(tvec, pvec) * inverse;
    const qvec = cross(tvec, edge1);
    const v = dot(direction, qvec) * inverse;
    const distance = dot(edge2, qvec) * inverse;
    if (u < -1.0e-6 || v < -1.0e-6 || u + v > 1 + 1.0e-6 || distance <= 0 || distance >= maxDistance) return null;
    const bary = [Math.max(0, 1 - u - v), Math.max(0, u), Math.max(0, v)];
    const barySum = bary[0] + bary[1] + bary[2];
    return { distance, bary:bary.map((value) => value / barySum) };
}

function fallbackTangent(normal) {
    const axis = Math.abs(normal[2]) < Math.abs(normal[0]) ? [0,0,1] : [1,0,0];
    return normalize(cross(axis, normal));
}

function evaluateHit(origin, direction, maxDistance) {
    let closest = null;
    for (const triangle of worldTriangles) {
        const hit = intersectTriangle(origin, direction, triangle, maxDistance);
        if (hit && (!closest || hit.distance < closest.distance)) closest = { ...hit, triangle };
    }
    let groundDistance = Infinity;
    if (Math.abs(direction[1]) > 1.0e-10) {
        const distance = (-3 - origin[1]) / direction[1];
        if (distance > 0 && distance < Math.min(closest?.distance ?? Infinity, maxDistance)) groundDistance = distance;
    }
    if (groundDistance < Infinity) {
        const point = add(origin, scale(direction, groundDistance));
        return { hit:true, distance:groundDistance, point, ng:[0,1,0], ns:[0,1,0], bary:[0,0,0], uv:[point[0] / 100 + 0.5, point[2] / 100 + 0.5], tangent:[1,0,0], material:2 };
    }
    if (!closest) return { hit:false, distance:-1, point:[0,0,0], ng:[0,0,0], ns:[0,0,0], bary:[0,0,0], uv:[0,0], tangent:[0,0,0], material:-1 };

    const { triangle, bary, distance } = closest;
    const point = add(origin, scale(direction, distance));
    const ng = normalize(cross(subtract(triangle.world[1], triangle.world[0]), subtract(triangle.world[2], triangle.world[0])));
    const ns = normalize(triangle.normals[0].map((_, axis) => triangle.normals.reduce((sum, normal, vertex) => sum + normal[axis] * bary[vertex], 0)));
    const uv = [0,1].map((axis) => triangle.uvs.reduce((sum, coord, vertex) => sum + coord[axis] * bary[vertex], 0));
    const deltaPos1 = subtract(triangle.local[1], triangle.local[0]);
    const deltaPos2 = subtract(triangle.local[2], triangle.local[0]);
    const deltaUv1 = subtract(triangle.uvs[1], triangle.uvs[0]);
    const deltaUv2 = subtract(triangle.uvs[2], triangle.uvs[0]);
    const determinant = deltaUv1[0] * deltaUv2[1] - deltaUv1[1] * deltaUv2[0];
    let tangent;
    if (Math.abs(determinant) > 1.0e-12) {
        const localTangent = scale(subtract(scale(deltaPos1, deltaUv2[1]), scale(deltaPos2, deltaUv1[1])), 1 / determinant);
        const matrix = new Matrix4().fromArray(Array.from(scene.transforms[triangle.instanceID]));
        tangent = normalize(new Vector3(...localTangent).transformDirection(matrix).toArray());
    } else tangent = fallbackTangent(ns);
    return { hit:true, distance, point, ng, ns, bary, uv, tangent,
        material:materialRegistry.bySceneMaterialID.get(triangle.materialID).localMaterialID };
}

const fragmentShader = `#version 300 es
precision highp float;
precision highp int;
#define REFERENCE_BVH_ENABLED
#define REFERENCE_BVH_DEBUG
${closestHitAbi}
${closestHit}
${anyHit}
uniform sampler2D mtlxLightsTex;
uniform int mtlxReferenceMaterialRegistryCount;
uniform int mtlxReferenceMaterialRegistryRowOffset;
int mtlxMaterialVariant = 0;
int referenceLocalMaterialID = -1;
${materialResolver}
const float HUGE_DIST = 1.0e20;
const float DENOM_TOLERANCE = 1.0e-10;
const int MATERIAL_PROPS = 0;
const int MATERIAL_OPENPBR = 1;
const int MATERIAL_GROUND = 2;
uniform bool ground_enabled;
uniform float ground_y;
uniform bool shadowOpaque;
uniform bool shadowThinWalled;
uniform sampler2D rayOriginTexture;
uniform sampler2D rayDirectionTexture;
uniform int rayTextureWidth;
uniform int resultPass;
uniform int traceWidth;
vec3 safe_normalize(vec3 value) { float magnitude = length(value); return value / max(magnitude, DENOM_TOLERANCE); }
${traceFunction}
bool mtlx_openpbr_is_opaque() { return shadowOpaque; }
bool mtlx_openpbr_is_thinwalled() { return shadowThinWalled; }
${traceShadowFunction}
layout(location=0) out vec4 out0;
layout(location=1) out vec4 out1;
layout(location=2) out vec4 out2;
layout(location=3) out vec4 out3;
void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    int rayIndex = pixel.y * traceWidth + pixel.x;
    ivec2 rayCoord = ivec2(rayIndex % rayTextureWidth, rayIndex / rayTextureWidth);
    vec4 rayOrigin = texelFetch(rayOriginTexture, rayCoord, 0);
    vec3 rayDirection = texelFetch(rayDirectionTexture, rayCoord, 0).xyz;
    if (resultPass == 2) {
        Ray shadowRay; shadowRay.origin=rayOrigin.xyz; shadowRay.direction=rayDirection;
        bool geometryOccluded=AnyHit(shadowRay,rayOrigin.w);
        out0=vec4(geometryOccluded?1.0:0.0,0.0,0.0,1.0);
        out1=vec4(0.0); out2=vec4(0.0); out3=vec4(0.0);
        return;
    }
    if (resultPass == 3) {
        float visibility=TraceShadow(rayOrigin.xyz,rayDirection,rayOrigin.w);
        out0=vec4(visibility,0.0,0.0,1.0);
        out1=vec4(0.0); out2=vec4(0.0); out3=vec4(0.0);
        return;
    }
    if (resultPass == 4) {
        if (rayIndex != 0) { out0=vec4(0.0); out1=vec4(0.0); out2=vec4(0.0); out3=vec4(0.0); return; }
        vec3 rootLeaf = texelFetch(BVH, topBVHIndex * 3 + 2).xyz;
        Ray debugRay; debugRay.origin=rayOrigin.xyz; debugRay.direction=rayDirection;
        State debugState; debugState.depth=0; debugState.hitDist=HUGE_DIST; debugState.fhp=vec3(0.0);
        debugState.normal=vec3(0.0,0.0,1.0); debugState.ffnormal=debugState.normal;
        debugState.tangent=vec3(1.0,0.0,0.0); debugState.bitangent=vec3(0.0,1.0,0.0);
        debugState.geometricNormal=debugState.normal; debugState.barycentric=vec3(0.0);
        debugState.triangleIndices=ivec3(-1); debugState.texCoord=vec2(0.0); debugState.matID=-1;
        debugState.isEmitter=false; debugState.traversalOverflow=false;
        LightSampleRec debugLight; debugLight.pdf=0.0; debugLight.emission=vec3(0.0);
        bool directHit=ClosestHit(debugRay,debugState,debugLight);
        out0=vec4(float(topBVHIndex),rootLeaf);
        vec3 blasRootLeaf=texelFetch(BVH,2).xyz;
        Ray localRay; localRay.origin=vec3(0.0,0.0,1.0); localRay.direction=vec3(0.0,0.0,-1.0);
        vec3 child1Min=texelFetch(BVH,3).xyz, child1Max=texelFetch(BVH,4).xyz;
        vec3 child2Min=texelFetch(BVH,6).xyz, child2Max=texelFetch(BVH,7).xyz;
        out1=vec4(AABBIntersect(child1Min,child1Max,localRay),AABBIntersect(child2Min,child2Max,localRay),
            float(texelFetch(BVH,3).x),float(texelFetch(BVH,6).x));
        out2=vec4(directHit?1.0:0.0,debugState.hitDist,debugState.traversalOverflow?1.0:0.0,float(debugState.matID));
        ivec3 firstIndices=texelFetchI(vertexIndicesTex,0).xyz;
        vec3 v0=texelFetch(verticesTex,firstIndices.x).xyz;
        vec3 v1=texelFetch(verticesTex,firstIndices.y).xyz;
        vec3 v2=texelFetch(verticesTex,firstIndices.z).xyz;
        vec3 edge0=v1-v0, edge1=v2-v0, pv=cross(localRay.direction,edge1);
        float determinant=dot(edge0,pv);
        vec3 tv=localRay.origin-v0, qv=cross(tv,edge0);
        out3=vec4(float(debugState.debugNode),float(debugState.debugLeaf),float(debugState.debugTriangles),debugState.debugUvt.z);
        return;
    }
    vec3 P = vec3(0.0), Ns = vec3(0.0), Ng = vec3(0.0), Ts = vec3(0.0), bary = vec3(0.0);
    vec2 uv = vec2(0.0);
    int material = -1;
    bool hit = trace(rayOrigin.xyz, rayDirection, rayOrigin.w, P, Ns, Ng, Ts, bary, uv, material);
    float distance = hit ? dot(P - rayOrigin.xyz, rayDirection) / dot(rayDirection, rayDirection) : -1.0;
    if (resultPass == 0) {
        out0 = vec4(distance, P);
        out1 = vec4(Ng, Ns.x);
        out2 = vec4(Ns.y, Ns.z, bary.x, bary.y);
        out3 = vec4(bary.z, uv, float(material));
    } else {
        out0 = vec4(Ts, hit ? 1.0 : 0.0);
        out1 = vec4(0.0); out2 = vec4(0.0); out3 = vec4(0.0);
    }
}`;

const traceWidth = 100;
const traceHeight = 100;
const rayTextureWidth = 128;
const rayTextureHeight = Math.ceil(10000 / rayTextureWidth);
const rayOriginTextureData = new Float32Array(rayTextureWidth * rayTextureHeight * 4);
const rayDirectionTextureData = new Float32Array(rayTextureWidth * rayTextureHeight * 4);
rayOriginTextureData.set(rayOrigins);
rayDirectionTextureData.set(rayDirections);
const packedBuffers = Object.fromEntries(Object.entries(adapter.buffers).map(([name, buffer]) => [name, {
    width:buffer.layout.width, height:buffer.layout.height, integer:buffer.integer, data:Array.from(buffer.data),
}]));
const browser = await chromium.launch({ executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless:true, args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'] });
const report = { task:'T014', status:'FAIL', renderer:null, rayCount:10000, comparisonTolerance:2.0e-4,
    hitMismatches:0, valueMismatches:0, anyHitMismatches:0, shadowMismatches:0,
    materialRegistryEntries:materialRegistry.entries.map(({sceneMaterialID,kindID,localMaterialID,parameterVariant}) =>
        ({sceneMaterialID,kindID,localMaterialID,parameterVariant})),
    hitSamples:[], valueSamples:[], anyHitSamples:[], shadowSamples:[], errors:[] };
try {
    const page = await browser.newPage();
    const observed = await page.evaluate(({ buffers, origins, directions, registryData, registryCount, registryRowOffset, fragmentShader, traceWidth, traceHeight, rayTextureWidth, rayTextureHeight }) => {
        const gl = document.createElement('canvas').getContext('webgl2');
        if (!gl) throw new Error('WebGL2 context unavailable');
        if (!gl.getExtension('EXT_color_buffer_float')) throw new Error('EXT_color_buffer_float unavailable for oracle targets');
        const debug = gl.getExtension('WEBGL_debug_renderer_info');
        const renderer = debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        const vertex = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertex, '#version 300 es\nvoid main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);gl_Position=vec4(p*2.0-1.0,0.0,1.0);}');
        gl.compileShader(vertex);
        if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertex));
        const fragment = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragment, fragmentShader);
        gl.compileShader(fragment);
        if (!gl.getShaderParameter(fragment, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(fragment));
        const program = gl.createProgram();
        gl.attachShader(program, vertex); gl.attachShader(program, fragment); gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
        gl.useProgram(program);
        gl.bindVertexArray(gl.createVertexArray());
        const textureByName = {};
        for (const [index, name] of ['BVH','vertexIndicesTex','verticesTex','normalsTex','transformsTex'].entries()) {
            const buffer = buffers[name];
            const texture = gl.createTexture();
            gl.activeTexture(gl.TEXTURE0 + index); gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texImage2D(gl.TEXTURE_2D, 0, buffer.integer ? gl.RGBA32I : gl.RGBA32F, buffer.width, buffer.height, 0,
                buffer.integer ? gl.RGBA_INTEGER : gl.RGBA, buffer.integer ? gl.INT : gl.FLOAT,
                buffer.integer ? new Int32Array(buffer.data) : new Float32Array(buffer.data));
            textureByName[name] = texture;
            gl.uniform1i(gl.getUniformLocation(program, name), index);
        }
        const uploadInput = (unit, name, data) => {
            const texture = gl.createTexture();
            gl.activeTexture(gl.TEXTURE0 + unit); gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, rayTextureWidth, rayTextureHeight, 0, gl.RGBA, gl.FLOAT, data);
            gl.uniform1i(gl.getUniformLocation(program, name), unit);
            return texture;
        };
        const originTexture = uploadInput(5, 'rayOriginTexture', new Float32Array(origins));
        const directionTexture = uploadInput(6, 'rayDirectionTexture', new Float32Array(directions));
        const materialTexture = gl.createTexture();
        gl.activeTexture(gl.TEXTURE7); gl.bindTexture(gl.TEXTURE_2D, materialTexture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, 6, registryData.length / 24, 0, gl.RGBA, gl.FLOAT, new Float32Array(registryData));
        gl.uniform1i(gl.getUniformLocation(program, 'mtlxLightsTex'), 7);
        gl.uniform1i(gl.getUniformLocation(program, 'mtlxReferenceMaterialRegistryCount'), registryCount);
        gl.uniform1i(gl.getUniformLocation(program, 'mtlxReferenceMaterialRegistryRowOffset'), registryRowOffset);
        gl.uniform1i(gl.getUniformLocation(program, 'rayTextureWidth'), rayTextureWidth);
        gl.uniform1i(gl.getUniformLocation(program, 'traceWidth'), traceWidth);
        gl.uniform1i(gl.getUniformLocation(program, 'topBVHIndex'), buffers.topBVHIndex);
        gl.uniform1i(gl.getUniformLocation(program, 'referenceNodeCount'), buffers.counts.nodes);
        gl.uniform1i(gl.getUniformLocation(program, 'referenceInstanceCount'), buffers.counts.instances);
        gl.uniform1i(gl.getUniformLocation(program, 'ground_enabled'), 1);
        gl.uniform1f(gl.getUniformLocation(program, 'ground_y'), -3.0);
        gl.uniform1i(gl.getUniformLocation(program, 'shadowOpaque'), 1);
        gl.uniform1i(gl.getUniformLocation(program, 'shadowThinWalled'), 0);
        const framebuffer = gl.createFramebuffer(); gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
        const outputs = [];
        gl.activeTexture(gl.TEXTURE8);
        for (let index = 0; index < 4; index++) {
            const texture = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RGBA32F, traceWidth, traceHeight);
            gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0 + index, gl.TEXTURE_2D, texture, 0);
            outputs.push(texture);
        }
        gl.drawBuffers([gl.COLOR_ATTACHMENT0,gl.COLOR_ATTACHMENT1,gl.COLOR_ATTACHMENT2,gl.COLOR_ATTACHMENT3]);
        if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) throw new Error('RGBA32F oracle framebuffer incomplete');
        gl.viewport(0,0,traceWidth,traceHeight);
        const attachments = [];
        for (let pass = 0; pass < 5; pass++) {
            gl.uniform1i(gl.getUniformLocation(program, 'resultPass'), pass);
            gl.drawArrays(gl.TRIANGLES,0,3);
            const groups = [];
            for (let index = 0; index < (pass === 0 || pass === 4 ? 4 : 1); index++) {
                gl.readBuffer(gl.COLOR_ATTACHMENT0 + index);
                const values = new Float32Array(traceWidth * traceHeight * 4);
                gl.readPixels(0,0,traceWidth,traceHeight,gl.RGBA,gl.FLOAT,values);
                groups.push(Array.from(values));
            }
            attachments.push(groups);
        }
        const glError = gl.getError();
        const maxColorAttachments = gl.getParameter(gl.MAX_COLOR_ATTACHMENTS);
        gl.deleteFramebuffer(framebuffer); gl.deleteProgram(program); gl.deleteShader(vertex); gl.deleteShader(fragment);
        [...outputs, originTexture, directionTexture, materialTexture, ...Object.values(textureByName)].forEach((texture) => gl.deleteTexture(texture));
            return { renderer, glError, maxColorAttachments, attachments };
    }, { buffers:{ ...packedBuffers, topBVHIndex:adapter.topLevelIndex, counts:adapter.counts }, origins:rayOriginTextureData,
        registryData:Array.from(materialRegistryTextureData), registryCount:materialRegistry.entries.length, registryRowOffset:materialRegistryRowOffset,
        directions:rayDirectionTextureData, fragmentShader, traceWidth, traceHeight, rayTextureWidth, rayTextureHeight });

    report.renderer = observed.renderer;
    report.glError = observed.glError;
        report.sceneDebug = { topLevelIndex:scene.topLevelIndex, activeNodeCount:scene.activeNodeCount,
            nodes:scene.nodes.slice(0,scene.activeNodeCount).map((node) => ({ min:node.bboxmin.toArray(), max:node.bboxmax.toArray(), LRLeaf:node.LRLeaf.toArray() })),
            gpuRoot:observed.attachments[4].map((group) => group.slice(0,4)),
            stackRequirement:adapter.stackRequirement };
    assert.match(observed.renderer, /SwiftShader/i);
    assert.equal(observed.glError, 0);
    const cpuRays = Array.from({ length:10000 }, (_, index) => ({
        origin:rayOrigins.slice(index*4,index*4+3), direction:rayDirections.slice(index*4,index*4+3), maxDistance:rayOrigins[index*4+3],
    }));
    let hitCount = 0;
    let missCount = 0;
    let clippedHits = 0;
    let maxError = 0;
    for (let index = 0; index < cpuRays.length; index++) {
        const ray = cpuRays[index];
        const expected = evaluateHit(ray.origin, ray.direction, ray.maxDistance);
        const expectedAnyHit = worldTriangles.some((triangle) => intersectTriangle(ray.origin, ray.direction, triangle, ray.maxDistance) !== null);
        const gpuAnyHit = observed.attachments[2][0][index*4] > 0.5;
        if (gpuAnyHit !== expectedAnyHit) {
            report.anyHitMismatches++;
            if (report.anyHitSamples.length < 12) report.anyHitSamples.push({ ray:index, actual:gpuAnyHit, expected:expectedAnyHit });
        }
        const gpuVisibility = observed.attachments[3][0][index*4];
        const expectedVisibility = expected.hit ? 0 : 1;
        if (gpuVisibility !== expectedVisibility) {
            report.shadowMismatches++;
            if (report.shadowSamples.length < 12) report.shadowSamples.push({ ray:index, actual:gpuVisibility, expected:expectedVisibility });
        }
        const gpu = (group, component) => observed.attachments[0][group][index*4+component];
        const gpuT = gpu(0,0);
        const gpuP = [gpu(0,1),gpu(0,2),gpu(0,3)];
        const gpuNg = [gpu(1,0),gpu(1,1),gpu(1,2)];
        const gpuNs = [gpu(1,3),gpu(2,0),gpu(2,1)];
        const gpuBary = [gpu(2,2),gpu(2,3),gpu(3,0)];
        const gpuUv = [gpu(3,1),gpu(3,2)];
        const gpuMaterial = gpu(3,3);
        const tangentValues = observed.attachments[1][0];
        const gpuTangent = [tangentValues[index*4],tangentValues[index*4+1],tangentValues[index*4+2]];
        const gpuHit = tangentValues[index*4+3] > 0.5;
        const expectedHit = expected.hit;
        if (expectedHit) hitCount++; else missCount++;
        if (!expectedHit && worldTriangles.some((triangle) => intersectTriangle(ray.origin, ray.direction, triangle, 1.0e20)?.distance >= ray.maxDistance)) clippedHits++;
        let rayError = 0;
        const compare = (actual, wanted, label, epsilon = 2.0e-4) => {
            const error = Math.abs(actual - wanted);
            maxError = Math.max(maxError, error);
            rayError = Math.max(rayError, error);
            if (error > epsilon * Math.max(1, Math.abs(wanted))) {
                report.valueMismatches++;
                if (report.valueSamples.length < 12) report.valueSamples.push({ ray:index, label, actual, expected:wanted, error });
            }
        };
        if (gpuHit !== expectedHit) {
            report.hitMismatches++;
            if (report.hitSamples.length < 12) report.hitSamples.push({ ray:index, actual:gpuHit, expected:expectedHit });
        }
        if (expectedHit && gpuHit) {
            compare(gpuT, expected.distance, 't');
            gpuP.forEach((value, axis) => compare(value, expected.point[axis], `P${axis}`));
            gpuNg.forEach((value, axis) => compare(value, expected.ng[axis], `Ng${axis}`));
            gpuNs.forEach((value, axis) => compare(value, expected.ns[axis], `Ns${axis}`));
            gpuBary.forEach((value, axis) => compare(value, expected.bary[axis], `bary${axis}`));
            gpuUv.forEach((value, axis) => compare(value, expected.uv[axis], `uv${axis}`));
            gpuTangent.forEach((value, axis) => compare(value, expected.tangent[axis], `T${axis}`, 5.0e-4));
            compare(gpuMaterial, expected.material, 'material', 0);
        }
        if (rayError > 0.02 && report.valueSamples.length < 12) report.valueSamples.push({ ray:index, label:'large-error', error:rayError });
    }
    report.hitCount = hitCount;
    report.missCount = missCount;
    report.clippedHits = clippedHits;
    report.maxAbsoluteError = maxError;
    assert.ok(hitCount > 1000 && missCount > 1000, `coverage hit=${hitCount} miss=${missCount}`);
    assert.equal(report.hitMismatches, 0);
    assert.equal(report.valueMismatches, 0);
    assert.equal(report.anyHitMismatches, 0);
    assert.equal(report.shadowMismatches, 0);
    assert.deepEqual(report.hitSamples, []);
    assert.deepEqual(report.valueSamples, []);
    report.status = 'PASS';
    console.log(`PASS closest/any-hit/TraceShadow: 10,000 WebGL2 rays match CPU oracle; ${hitCount} hits, ${missCount} misses, max error ${maxError}.`);
} catch (error) {
    report.errors.push(error.stack ?? error.message);
    process.exitCode = 1;
    console.error(error.stack ?? error.message);
} finally {
    mkdirSync(dirname(outputPath), { recursive:true });
    writeFileSync(outputPath, `${JSON.stringify(report,null,2)}\n`);
    writeFileSync(shadowOutputPath, `${JSON.stringify({ task:'T015', status:report.status, renderer:report.renderer,
        rays:report.rayCount, any_hit_mismatches:report.anyHitMismatches, trace_shadow_mismatches:report.shadowMismatches,
        any_hit_samples:report.anyHitSamples ?? [], shadow_samples:report.shadowSamples ?? [], errors:report.errors },null,2)}\n`);
    await browser.close();
}