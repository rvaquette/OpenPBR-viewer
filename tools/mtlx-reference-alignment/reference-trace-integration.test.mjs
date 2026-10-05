import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { chromium } from 'playwright-core';

function extractFunction(source, signature) {
    const start = source.indexOf(signature);
    assert.notEqual(start, -1, `missing function: ${signature}`);
    const open = source.indexOf('{', start);
    let depth = 0;
    for (let index = open; index < source.length; index++) {
        if (source[index] === '{') depth++;
        else if (source[index] === '}' && --depth === 0) return source.slice(start, index + 1);
    }
    throw new Error(`unterminated function: ${signature}`);
}

const referenceDir = resolve('glsl/pathtracing/mtlx/reference');
const abi = readFileSync(resolve(referenceDir, 'closest_hit_abi.glsl'), 'utf8');
const closestHit = readFileSync(resolve(referenceDir, 'closest_hit_mtlx.glsl'), 'utf8');
const anyHit = readFileSync(resolve(referenceDir, 'anyhit_mtlx.glsl'), 'utf8');
const pathtracer = readFileSync(resolve('glsl/pathtracing/mtlx/pathtracer.glsl'), 'utf8');
const routeCommon = readFileSync(resolve('glsl/pathtracing/mtlx/common.glsl'), 'utf8');
const trace = extractFunction(pathtracer, 'bool trace(');
const traceShadow = extractFunction(pathtracer, 'float TraceShadow(');
const materialResolver = extractFunction(routeCommon, 'bool mtlxResolveReferenceMaterial(');
const mainSource = readFileSync(resolve('main.js'), 'utf8');
const fragment = `#version 300 es
precision highp float;
precision highp int;
#define REFERENCE_BVH_ENABLED
${abi}
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
const int MATERIAL_SCENE_LIGHT_BASE = 10000;
struct Basis { vec3 nW; vec3 tW; vec3 bW; vec3 baryCoord; vec2 texCoord; };
Basis makeBasis(vec3 nW, vec3 tW, vec3 baryCoord, vec2 texCoord) {
    Basis basis; basis.nW=nW; basis.tW=tW; basis.bW=cross(nW,tW); basis.baryCoord=baryCoord; basis.texCoord=texCoord; return basis;
}
vec3 worldToLocal(vec3 value, Basis basis) { return vec3(dot(value,basis.tW),dot(value,basis.bW),dot(value,basis.nW)); }
vec3 normalToTangent(vec3 value) { return normalize(cross(abs(value.y)<0.9?vec3(0,1,0):vec3(1,0,0),value)); }
uniform bool ground_enabled;
uniform float ground_y;
vec3 safe_normalize(vec3 value) { float magnitude = length(value); return value / max(magnitude, DENOM_TOLERANCE); }
bool intersectSceneLight(vec3 origin,vec3 direction,float limit,out int index,out float distance,out vec3 normal) {
    index=-1; distance=limit; normal=vec3(0,1,0); return false;
}
${trace}
bool mtlx_openpbr_is_opaque() { return true; }
bool mtlx_openpbr_is_thinwalled() { return false; }
void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed) { rndSeed += 0u; }
${traceShadow}
out vec4 outColor;
void main() {
    vec3 P, Ns, Ng, Ts, bary;
    vec2 uv;
    int material;
    bool hit = trace(vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, -1.0), 100.0,true,
        P, Ns, Ng, Ts, bary, uv, material);
    float visibility = TraceShadow(vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, -1.0), 100.0);
    outColor = vec4(hit ? Ng : vec3(0.0), visibility);
}`;

test('trace() selects reference geometry by macro and preserves local ground and Three.js branches', () => {
    assert.match(trace, /#ifdef REFERENCE_BVH_ENABLED[\s\S]*?ClosestHit\(/);
    assert.match(trace, /dist_surface < maxDistance/);
    assert.match(trace, /#else[\s\S]*?bvhIntersectFirstHitWithinDistance/);
    assert.match(trace, /Ng = safe_normalize\(referenceHitState\.geometricNormal\)/);
    assert.match(trace, /MATERIAL_GROUND/);
    assert.match(anyHit, /uvt\.z < maxDist/);
    assert.match(anyHit, /referenceNodeCount <= 0/);
    assert.doesNotMatch(anyHit, /OPT_ALPHA_TEST|materialsTex|textureMapsArrayTex|OPT_RAYMARCHING|OPT_LIGHTS/);
    assert.match(traceShadow, /AnyHit\(shadowRay, maxDistance\)/);
    assert.match(traceShadow, /mtlx_openpbr_is_thinwalled/);
    assert.match(trace, /mtlxResolveReferenceMaterial\(referenceHitState\.matID/);
    assert.match(mainSource, /glsl_mtlx_reference_closest_hit_abi/);
    assert.match(mainSource, /glsl_mtlx_reference_closest_hit_mtlx/);
    assert.match(mainSource, /glsl_mtlx_reference_any_hit_mtlx/);
    assert.match(mainSource, /#ifdef REFERENCE_BVH_ENABLED[\s\S]*?referenceHitGlsl/);
});

test('actual trace() reference branch compiles and links as an isolated ESSL 3.00 program', async () => {
    const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
        headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
    try {
        const page = await browser.newPage();
        const observed = await page.evaluate((fragmentSource) => {
            const gl = document.createElement('canvas').getContext('webgl2');
            if (!gl) throw new Error('WebGL2 context unavailable');
            const fragment = gl.createShader(gl.FRAGMENT_SHADER);
            gl.shaderSource(fragment, fragmentSource);
            gl.compileShader(fragment);
            if (!gl.getShaderParameter(fragment, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(fragment));
            const vertex = gl.createShader(gl.VERTEX_SHADER);
            gl.shaderSource(vertex, '#version 300 es\nvoid main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);gl_Position=vec4(p*2.0-1.0,0.0,1.0);}');
            gl.compileShader(vertex);
            if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertex));
            const program = gl.createProgram();
            gl.attachShader(program, vertex);
            gl.attachShader(program, fragment);
            gl.linkProgram(program);
            if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
            const debug = gl.getExtension('WEBGL_debug_renderer_info');
            return { renderer: debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER),
                glError: gl.getError() };
        }, fragment);
        assert.match(observed.renderer, /SwiftShader/i);
        assert.equal(observed.glError, 0);
    } finally {
        await browser.close();
    }
});