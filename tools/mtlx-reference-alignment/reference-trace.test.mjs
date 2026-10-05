import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { chromium } from 'playwright-core';

const root = resolve('glsl/pathtracing/mtlx/reference');
const abi = readFileSync(resolve(root, 'closest_hit_abi.glsl'), 'utf8');
const closestHit = readFileSync(resolve(root, 'closest_hit_mtlx.glsl'), 'utf8');
const shader = `#version 300 es
precision highp float;
precision highp int;
#define REFERENCE_BVH_ENABLED
${abi}
${closestHit}
out vec4 outColor;
void main() {
    Ray ray; ray.origin = vec3(0.0); ray.direction = vec3(0.0, 0.0, -1.0);
    State state; state.depth = 0; state.hitDist = INF; state.fhp = vec3(0.0);
    state.normal = vec3(0.0, 0.0, 1.0); state.ffnormal = state.normal;
    state.tangent = vec3(1.0, 0.0, 0.0); state.bitangent = vec3(0.0, 1.0, 0.0);
    state.geometricNormal = state.normal; state.barycentric = vec3(0.0);
    state.triangleIndices = ivec3(-1); state.texCoord = vec2(0.0); state.matID = 0;
    state.isEmitter = false; state.traversalOverflow = false;
    LightSampleRec lightSample; lightSample.pdf = 0.0; lightSample.emission = vec3(0.0);
    bool hit = ClosestHit(ray, state, lightSample);
    outColor = vec4(hit ? state.geometricNormal : vec3(0.0), 1.0);
}`;

test('reference closest-hit adapter exposes trace outputs and bounded traversal', () => {
    assert.match(abi, /#ifdef REFERENCE_BVH_ENABLED/);
    assert.match(abi, /uniform int topBVHIndex/);
    assert.match(abi, /float AABBIntersect\(/);
    assert.match(closestHit, /state\.geometricNormal\s*=/);
    assert.match(closestHit, /state\.barycentric\s*=/);
    assert.match(closestHit, /state\.triangleIndices\s*=/);
    assert.match(closestHit, /state\.traversalOverflow\s*=\s*true/);
    assert.match(closestHit, /uvDeterminant/);
});

test('reference closest-hit adapter compiles and links with the dormant ESSL 3.00 ABI', async () => {
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
        }, shader);
        assert.match(observed.renderer, /SwiftShader/i);
        assert.equal(observed.glError, 0);
    } finally {
        await browser.close();
    }
});