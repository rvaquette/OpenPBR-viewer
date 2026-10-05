import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { chromium } from 'playwright-core';

const root = resolve('.');
const sourcePath = join(root, 'glsl/pathtracing/mtlx/reference/closest_hit.glsl');
const output = join(root, 'artifacts/mtlx-reference-alignment/t013-closest-hit-compile.json');
const closestHit = readFileSync(sourcePath, 'utf8');
const harness = `#version 300 es
precision highp float;
precision highp int;
precision highp isampler2D;
const float INF = 1.0e20;
uniform sampler2D BVH;
uniform isampler2D vertexIndicesTex;
uniform sampler2D verticesTex;
uniform sampler2D normalsTex;
uniform sampler2D transformsTex;
uniform sampler2D lightsTex;
uniform int numOfLights;
uniform int topBVHIndex;
struct Ray { vec3 origin; vec3 direction; };
struct State {
    int depth; float hitDist; vec3 fhp; vec3 normal; vec3 ffnormal;
    vec3 tangent; vec3 bitangent; bool isEmitter; vec2 texCoord; int matID;
};
struct LightSampleRec { float pdf; vec3 emission; };
vec4 texelFetch(sampler2D tex, int index) {
    int width = textureSize(tex, 0).x;
    return texelFetch(tex, ivec2(index % width, index / width), 0);
}
ivec4 texelFetchI(isampler2D tex, int index) {
    int width = textureSize(tex, 0).x;
    return texelFetch(tex, ivec2(index % width, index / width), 0);
}
vec4 texelFetch1D(sampler2D tex, int index) { return texelFetch(tex, index); }
float AABBIntersect(vec3 minCorner, vec3 maxCorner, Ray ray) {
    vec3 invDir = 1.0 / ray.direction;
    vec3 f = (maxCorner - ray.origin) * invDir;
    vec3 n = (minCorner - ray.origin) * invDir;
    vec3 tmax = max(f, n);
    vec3 tmin = min(f, n);
    float t1 = min(tmax.x, min(tmax.y, tmax.z));
    float t0 = max(tmin.x, max(tmin.y, tmin.z));
    return (t1 >= t0) ? (t0 > 0.0 ? t0 : t1) : -1.0;
}
${closestHit}
out vec4 outColor;
void main() {
    Ray ray; ray.origin = vec3(0.0); ray.direction = vec3(0.0, 0.0, -1.0);
    State state; state.depth = 0; state.hitDist = INF; state.fhp = vec3(0.0);
    state.normal = vec3(0.0, 0.0, 1.0); state.ffnormal = state.normal;
    state.tangent = vec3(1.0, 0.0, 0.0); state.bitangent = vec3(0.0, 1.0, 0.0);
    state.isEmitter = false; state.texCoord = vec2(0.0); state.matID = 0;
    LightSampleRec lightSample; lightSample.pdf = 0.0; lightSample.emission = vec3(0.0);
    bool hit = ClosestHit(ray, state, lightSample);
    outColor = vec4(hit ? state.normal : vec3(0.0), 1.0);
}`;
const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const report = { task: 'T013', status: 'FAIL', source: 'glsl/pathtracing/mtlx/reference/closest_hit.glsl',
    compileTarget: 'WebGL2 GLSL ES 3.00 isolated ABI harness', errors: [] };
try {
    const page = await browser.newPage();
    report.observed = await page.evaluate((fragmentSource) => {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl2');
        if (!gl) throw new Error('WebGL2 context unavailable');
        const shader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(shader, fragmentSource);
        gl.compileShader(shader);
        const compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
        const log = gl.getShaderInfoLog(shader) ?? '';
        if (!compiled) throw new Error(log);
        const vertex = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertex, `#version 300 es\nvoid main() { vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2); gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0); }`);
        gl.compileShader(vertex);
        if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertex));
        const program = gl.createProgram();
        gl.attachShader(program, vertex);
        gl.attachShader(program, shader);
        gl.linkProgram(program);
        const linked = gl.getProgramParameter(program, gl.LINK_STATUS);
        const linkLog = gl.getProgramInfoLog(program) ?? '';
        if (!linked) throw new Error(linkLog);
        const debug = gl.getExtension('WEBGL_debug_renderer_info');
        const renderer = debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        return { compiled, linked, renderer, glError: gl.getError(), shaderLog: log, linkLog };
    }, harness);
    assert.equal(report.observed.compiled, true);
    assert.equal(report.observed.linked, true);
    assert.equal(report.observed.glError, 0);
    report.status = 'PASS';
    console.log(`PASS T013 closest-hit isolated ESSL 3.00 compile/link on ${report.observed.renderer}.`);
} catch (error) {
    report.errors.push(error.stack ?? error.message);
    process.exitCode = 1;
    console.error(error.message);
} finally {
    mkdirSync(dirname(output), { recursive: true });
    writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
    await browser.close();
}