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

const pathtracer = readFileSync(resolve('glsl/pathtracing/mtlx/pathtracer.glsl'), 'utf8');
const traceShadow = extractFunction(pathtracer, 'float TraceShadow(');
const fragmentSource = `#version 300 es
precision highp float;
precision highp int;
const int MATERIAL_PROPS = 0;
const int MATERIAL_OPENPBR = 1;
const int MATERIAL_GROUND = 2;
uniform bool mockedHit;
uniform int mockedMaterial;
uniform bool mockedOpaque;
uniform bool mockedThinWalled;
bool trace(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance, in bool includeSceneEmitters,
    out vec3 P, out vec3 Ns, out vec3 Ng, out vec3 Ts, out vec3 baryCoord, out vec2 texCoord, out int material) {
    P=vec3(0.0); Ns=vec3(0.0,0.0,1.0); Ng=Ns; Ts=vec3(1.0,0.0,0.0);
    baryCoord=vec3(0.0); texCoord=vec2(0.0); material=mockedMaterial;
    return mockedHit;
}
bool mtlx_openpbr_is_opaque() { return mockedOpaque; }
bool mtlx_openpbr_is_thinwalled() { return mockedThinWalled; }
${traceShadow}
out vec4 outColor;
void main() { outColor=vec4(TraceShadow(vec3(0.0),vec3(0.0,0.0,-1.0),2.0),0.0,0.0,1.0); }`;

test('local TraceShadow keeps opaque blockers and ignores only non-opaque thin-walled OpenPBR', async () => {
    const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
        headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
    try {
        const page = await browser.newPage();
        const results = await page.evaluate((source) => {
            const gl = document.createElement('canvas').getContext('webgl2');
            if (!gl) throw new Error('WebGL2 context unavailable');
            const fragment = gl.createShader(gl.FRAGMENT_SHADER);
            gl.shaderSource(fragment, source); gl.compileShader(fragment);
            if (!gl.getShaderParameter(fragment, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(fragment));
            const vertex = gl.createShader(gl.VERTEX_SHADER);
            gl.shaderSource(vertex, '#version 300 es\nvoid main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);gl_Position=vec4(p*2.0-1.0,0.0,1.0);}');
            gl.compileShader(vertex);
            if (!gl.getShaderParameter(vertex, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertex));
            const program = gl.createProgram(); gl.attachShader(program,vertex); gl.attachShader(program,fragment); gl.linkProgram(program);
            if (!gl.getProgramParameter(program,gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
            gl.useProgram(program); gl.bindVertexArray(gl.createVertexArray()); gl.viewport(0,0,1,1);
            const locations = Object.fromEntries(['mockedHit','mockedMaterial','mockedOpaque','mockedThinWalled']
                .map((name) => [name,gl.getUniformLocation(program,name)]));
            const cases = [
                { name:'miss', hit:false, material:1, opaque:true, thin:false, visible:true },
                { name:'opaque-openpbr', hit:true, material:1, opaque:true, thin:true, visible:false },
                { name:'thinwalled-openpbr', hit:true, material:1, opaque:false, thin:true, visible:true },
                { name:'non-thin-openpbr', hit:true, material:1, opaque:false, thin:false, visible:false },
                { name:'props', hit:true, material:0, opaque:false, thin:true, visible:false },
                { name:'ground', hit:true, material:2, opaque:false, thin:true, visible:false },
            ];
            return cases.map((item) => {
                gl.uniform1i(locations.mockedHit,item.hit ? 1 : 0);
                gl.uniform1i(locations.mockedMaterial,item.material);
                gl.uniform1i(locations.mockedOpaque,item.opaque ? 1 : 0);
                gl.uniform1i(locations.mockedThinWalled,item.thin ? 1 : 0);
                gl.drawArrays(gl.TRIANGLES,0,3);
                const pixel = new Uint8Array(4); gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,pixel);
                return { name:item.name, visible:pixel[0] > 127, expected:item.visible };
            });
        }, fragmentSource);
        assert.deepEqual(results.filter((item) => item.visible !== item.expected), []);
    } finally {
        await browser.close();
    }
});