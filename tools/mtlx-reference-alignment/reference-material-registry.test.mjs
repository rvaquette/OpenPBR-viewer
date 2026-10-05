import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { chromium } from 'playwright-core';
import { assertReferenceMaterialCoverage, assertReferenceMaterialParameterSchema, createReferenceMaterialRegistry } from '../../src/mtlx/referenceMaterialRegistry.js';

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

test('scene material IDs map to distinct local material slots without boolean collapse', () => {
    const registry = createReferenceMaterialRegistry([
        { sceneMaterialID:7, localMaterialID:1, materialKey:'openpbr-main', kind:'openpbr' },
        { sceneMaterialID:19, localMaterialID:1, materialKey:'openpbr-main', kind:'openpbr' },
        { sceneMaterialID:33, localMaterialID:0, materialKey:'neutral-clay', kind:'props' },
    ], { activeMaterialKey:'openpbr-main' });
    assert.deepEqual(registry.entries.map(({ sceneMaterialID, localMaterialID, kindID }) => [sceneMaterialID,localMaterialID,kindID]),
        [[7,1,1],[19,1,1],[33,0,0]]);
    assert.deepEqual(Array.from(registry.packedData), [7,1,1,0,19,1,1,0,33,0,0,0]);
    assert.equal(registry.bySceneMaterialID.get(19).materialKey, 'openpbr-main');
});

test('reference scene coverage is explicit and rejects any unregistered material ID', () => {
    const registry = createReferenceMaterialRegistry([
        { sceneMaterialID:11, localMaterialID:1, materialKey:'active', kind:'openpbr' },
    ], { activeMaterialKey:'active' });
    assert.equal(assertReferenceMaterialCoverage({ instances:[{materialID:11,instanceID:0}] },registry), true);
    assert.throws(() => assertReferenceMaterialCoverage({ instances:[{materialID:12,instanceID:1}] },registry), /ID_UNREGISTERED/);
});

test('registry rejects duplicate IDs, invalid precision, unsupported variants and mismatched closures', () => {
    const openpbr = { sceneMaterialID:1, localMaterialID:1, materialKey:'active', kind:'openpbr' };
    assert.throws(() => createReferenceMaterialRegistry([openpbr,{...openpbr}]), /ID_DUPLICATE/);
    assert.throws(() => createReferenceMaterialRegistry([{...openpbr,sceneMaterialID:0x1000000}]), /ID_INVALID/);
    assert.throws(() => createReferenceMaterialRegistry([{...openpbr,parameterVariant:64}]), /VARIANT_INVALID/);
    assert.throws(() => createReferenceMaterialRegistry([{...openpbr,parameterVariant:2}]), /PARAMETERS_REQUIRED/);
    assert.throws(() => createReferenceMaterialRegistry([{...openpbr,localMaterialID:4}]), /KIND_MISMATCH/);
    assert.throws(() => createReferenceMaterialRegistry([openpbr],{activeMaterialKey:'different'}), /DISPATCH_MISMATCH/);
    assert.throws(() => createReferenceMaterialRegistry(Array.from({length:65},(_,index)=>({...openpbr,sceneMaterialID:index}))), /CAPACITY/);
});

test('parameter variants retain different local values instead of collapsing MTLX IDs', () => {
    const registry = createReferenceMaterialRegistry([
        { sceneMaterialID:4, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:0 },
        { sceneMaterialID:9, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:2,
            parameterValues:[0.17, [0.4,0.5,0.6]] },
    ], { activeMaterialKey:'active' });
    assert.equal(registry.bySceneMaterialID.get(4).parameterVariant, 0);
    assert.equal(registry.bySceneMaterialID.get(9).parameterVariant, 2);
    assert.deepEqual(registry.bySceneMaterialID.get(9).parameterValues, [0.17,[0.4,0.5,0.6]]);
    assert.deepEqual(Array.from(registry.packedData), [4,1,1,0,9,1,1,2]);
});

test('parameter value snapshots preserve finite scalar, vector and boolean values', () => {
    const registry = createReferenceMaterialRegistry([
        { sceneMaterialID:2, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:2,
            parameterValues:[true,0.35,[0.2,0.3,0.4]] },
    ]);
    assert.deepEqual(registry.entries[0].parameterValues, [true,0.35,[0.2,0.3,0.4]]);
    assert.throws(() => createReferenceMaterialRegistry([
        { sceneMaterialID:3, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:2, parameterValues:[NaN] },
    ]), /PARAMETERS_INVALID/);
});

test('ESSL material registry lookup returns distinct local IDs and parameter variants by scene ID', async () => {
    const common = readFileSync(resolve('glsl/pathtracing/mtlx/common.glsl'), 'utf8');
    const resolver = extractFunction(common, 'bool mtlxResolveReferenceMaterial(');
    const shader = `#version 300 es
precision highp float;
precision highp int;
uniform sampler2D mtlxLightsTex;
uniform int mtlxReferenceMaterialRegistryCount;
uniform int mtlxReferenceMaterialRegistryRowOffset;
${resolver}
uniform int probeID;
out vec4 outColor;
void main() {
    int kind, localID, variant;
    bool found = mtlxResolveReferenceMaterial(probeID, kind, localID, variant);
    outColor = vec4(found ? float(kind + 1) / 4.0 : 0.0,
        found ? float(localID) / 255.0 : 0.0, found ? float(variant) / 63.0 : 0.0, found ? 1.0 : 0.0);
}`;
    const registry = createReferenceMaterialRegistry([
        { sceneMaterialID:7, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:0 },
        { sceneMaterialID:19, localMaterialID:1, materialKey:'active', kind:'openpbr', parameterVariant:2, parameterValues:[0.25] },
        { sceneMaterialID:33, localMaterialID:0, materialKey:'props', kind:'props' },
    ], { activeMaterialKey:'active' });
    const textureData = new Float32Array(6 * 4 * 4);
    registry.entries.forEach((_entry, index) => textureData.set(registry.packedData.subarray(index*4,index*4+4), (index+1)*6*4));
    const browser = await chromium.launch({ executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',
        headless:true, args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'] });
    try {
        const page = await browser.newPage();
        const observed = await page.evaluate(({ source, data, count }) => {
            const canvas = document.createElement('canvas'); canvas.width=1; canvas.height=1;
            const gl = canvas.getContext('webgl2');
            if (!gl) throw new Error('WebGL2 context unavailable');
            const vertex = gl.createShader(gl.VERTEX_SHADER);
            gl.shaderSource(vertex,'#version 300 es\nvoid main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);gl_Position=vec4(p*2.0-1.0,0.0,1.0);}');
            gl.compileShader(vertex); if(!gl.getShaderParameter(vertex,gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertex));
            const fragment = gl.createShader(gl.FRAGMENT_SHADER); gl.shaderSource(fragment,source); gl.compileShader(fragment);
            if(!gl.getShaderParameter(fragment,gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(fragment));
            const program=gl.createProgram(); gl.attachShader(program,vertex); gl.attachShader(program,fragment); gl.linkProgram(program);
            if(!gl.getProgramParameter(program,gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
            gl.useProgram(program); gl.bindVertexArray(gl.createVertexArray());
            const texture=gl.createTexture(); gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D,texture);
            gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST); gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);
            gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA32F,6,4,0,gl.RGBA,gl.FLOAT,new Float32Array(data));
            gl.uniform1i(gl.getUniformLocation(program,'mtlxLightsTex'),0);
            gl.uniform1i(gl.getUniformLocation(program,'mtlxReferenceMaterialRegistryCount'),count);
            gl.uniform1i(gl.getUniformLocation(program,'mtlxReferenceMaterialRegistryRowOffset'),1);
            gl.bindVertexArray(gl.createVertexArray()); gl.viewport(0,0,1,1);
            const idLocation=gl.getUniformLocation(program,'probeID');
            const ids=[7,19,33,404];
            return ids.map((id) => {
                gl.uniform1i(idLocation,id); gl.drawArrays(gl.TRIANGLES,0,3);
                const pixel=new Uint8Array(4); gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,pixel);
                return { id, kind:pixel[0] ? Math.round(pixel[0]/255*4)-1 : -1,
                    localID:Math.round(pixel[1]/255*255), variant:Math.round(pixel[2]/255*63), found:pixel[3]>127 };
            });
        }, { source:shader, data:Array.from(textureData), count:registry.entries.length });
        assert.deepEqual(observed, [
            {id:7,kind:1,localID:1,variant:0,found:true},
            {id:19,kind:1,localID:1,variant:2,found:true},
            {id:33,kind:0,localID:0,variant:0,found:true},
            {id:404,kind:-1,localID:0,variant:0,found:false},
        ]);
    } finally {
        await browser.close();
    }
});

test('registry pins ordered local parameter schema and rejects incompatible dispatch signatures', () => {
    const registry = createReferenceMaterialRegistry([
        {sceneMaterialID:5,localMaterialID:1,materialKey:'active',kind:'openpbr'},
    ], {parameterSchema:[{name:'geometry_thin_walled',type:'bool'},{name:'transmission_weight',type:'float'}]});
    assert.equal(assertReferenceMaterialParameterSchema(registry,[
        {name:'geometry_thin_walled',type:'bool'},{name:'transmission_weight',type:'float'},
    ]),true);
    assert.throws(() => assertReferenceMaterialParameterSchema(registry,[
        {name:'transmission_weight',type:'float'},{name:'geometry_thin_walled',type:'bool'},
    ]),/SCHEMA_MISMATCH/);
    assert.throws(() => assertReferenceMaterialParameterSchema(registry,[
        {name:'geometry_thin_walled',type:'float'},{name:'transmission_weight',type:'float'},
    ]),/SCHEMA_MISMATCH/);
});

test('OpenPBR registry entries may explicitly select the generated default parameter block', () => {
    const registry = createReferenceMaterialRegistry([
        {sceneMaterialID:6,localMaterialID:1,materialKey:'active',kind:'openpbr',parameterVariant:1},
    ]);
    assert.equal(registry.bySceneMaterialID.get(6).parameterVariant, 1);
});