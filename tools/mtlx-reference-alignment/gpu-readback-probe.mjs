import assert from 'node:assert/strict';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { chromium } from 'playwright-core';

const root = fileURLToPath(new URL('../../', import.meta.url));
const output = join(root, 'artifacts/mtlx-reference-alignment/t012-gpu-readback.json');
const bundle = await build({ stdin: { loader: 'ts', resolveDir: root, contents: [
    'export { BufferGeometry, Float32BufferAttribute, Matrix4 } from "three";',
    'export { adaptReferenceGeometry } from "./src/bvh/referenceSceneAdapter.js";',
    'export { buildReferenceBlas } from "./src/bvh/referenceBlas.js";',
    'export { buildReferenceScene } from "./src/bvh/referenceScene.js";',
    'export { packReferenceScene, referenceTextureLayout } from "./src/bvh/referenceGpuAdapter.js";',
].join('\n') }, absWorkingDir: root, platform: 'browser', format: 'esm', bundle: true, write: false });
const moduleUrl = `data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].contents).toString('base64')}`;
const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const report = { task: 'T012', status: 'FAIL', timestamp: new Date().toISOString(), observed: null, errors: [] };

try {
    const page = await browser.newPage();
    page.on('pageerror', (error) => report.errors.push(error.message));
    report.observed = await page.evaluate(async (moduleUrl) => {
        const api = await import(moduleUrl);
        const geometry = new api.BufferGeometry();
        const positions = [];
        for (let triangle = 0; triangle < 12; triangle++) {
            const x = triangle * 1.25;
            positions.push(x,0,0, x+1,0,0, x,1,0);
        }
        geometry.setAttribute('position', new api.Float32BufferAttribute(positions, 3));
        const primitive = api.adaptReferenceGeometry(geometry).primitives[0];
        const mesh = api.buildReferenceBlas(primitive);
        const scene = api.buildReferenceScene([mesh], [
            { meshID: 0, materialID: 0xffffff, worldTransform: new api.Matrix4().makeTranslation(1.25, 2.5, 3.75) },
            { meshID: 0, materialID: 7, worldTransform: new api.Matrix4().makeScale(-1, 2, 0.5) },
            { meshID: 0, materialID: 8, worldTransform: new api.Matrix4().makeTranslation(-4, 1, 2) },
        ]);
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl2', { antialias: false, alpha: false, preserveDrawingBuffer: true });
        if (!gl) throw new Error('WebGL2 context unavailable');
        const rendererInfo = gl.getExtension('WEBGL_debug_renderer_info');
        const rendererName = rendererInfo ? gl.getParameter(rendererInfo.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        const maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
        const maxTextureImageUnits = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
        if (maxTextureSize < 4) throw new Error(`MAX_TEXTURE_SIZE=${maxTextureSize} is below probe fixture requirement`);
        const limits = { maxTextureSize: 8, maxTextureImageUnits, reservedTextureUnits: maxTextureImageUnits - 5 };
        const precisionScene = api.packReferenceScene(scene, limits);
        if (!precisionScene.buffers.BVH.data.includes(0xffffff)) throw new Error('largest exact float32 ID was not preserved');
        const invalidNode = scene.nodes.find((node) => node.LRLeaf.z < 0);
        invalidNode.LRLeaf.y = 0x1000000;
        const invalidPrecision = scene;
        let precisionRejected = false;
        try { api.packReferenceScene(invalidPrecision, limits); } catch (error) { precisionRejected = /INTEGER_INVALID/.test(error.message); }
        if (!precisionRejected) throw new Error('float32 ID above 2^24 was not rejected');
        let samplerBudgetRejected = false;
        try { api.packReferenceScene(scene, { ...limits, reservedTextureUnits: maxTextureImageUnits - 4 }); }
        catch (error) { samplerBudgetRejected = /UNIT_CAPACITY/.test(error.message); }
        if (!samplerBudgetRejected) throw new Error('insufficient sampler budget was not rejected');
        let textureLimitRejected = false;
        try { api.referenceTextureLayout(255, 3, { maxTextureSize: 4 }); }
        catch (error) { textureLimitRejected = /TEXTURE_CAPACITY/.test(error.message); }
        if (!textureLimitRejected) throw new Error('MAX_TEXTURE_SIZE overflow was not rejected');

        const vertexShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertexShader, `#version 300 es
            void main() { vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2); gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0); }`);
        gl.compileShader(vertexShader);
        if (!gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(vertexShader));
        const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragmentShader, `#version 300 es
            precision highp float;
            precision highp int;
            precision highp isampler2D;
            uniform sampler2D floatTexture;
            uniform isampler2D integerTexture;
            uniform ivec2 texelCoord;
            uniform int integerMode;
            out vec4 outColor;
            void main() {
                int lane = int(gl_FragCoord.x);
                uint bits = integerMode == 1
                    ? uint(texelFetch(integerTexture, texelCoord, 0)[lane])
                    : floatBitsToUint(texelFetch(floatTexture, texelCoord, 0)[lane]);
                outColor = vec4(float(bits & 255u), float((bits >> 8u) & 255u),
                    float((bits >> 16u) & 255u), float((bits >> 24u) & 255u)) / 255.0;
            }`);
        gl.compileShader(fragmentShader);
        if (!gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(fragmentShader));
        const program = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
        gl.useProgram(program);
        gl.bindVertexArray(gl.createVertexArray());
        gl.uniform1i(gl.getUniformLocation(program, 'floatTexture'), 0);
        gl.uniform1i(gl.getUniformLocation(program, 'integerTexture'), 1);
        const floatTextureLocation = gl.getUniformLocation(program, 'floatTexture');
        const integerTextureLocation = gl.getUniformLocation(program, 'integerTexture');
        const coordLocation = gl.getUniformLocation(program, 'texelCoord');
        const modeLocation = gl.getUniformLocation(program, 'integerMode');
        const outputTexture = gl.createTexture();
        gl.activeTexture(gl.TEXTURE2);
        gl.bindTexture(gl.TEXTURE_2D, outputTexture);
        gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RGBA8, 4, 1);
        const framebuffer = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, outputTexture, 0);
        if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) throw new Error('RGBA8 readback framebuffer incomplete');
        const dummyTextures = [];
        for (const [unit, integer] of [[gl.TEXTURE0, false], [gl.TEXTURE1, true]]) {
            const dummy = gl.createTexture();
            gl.activeTexture(unit);
            gl.bindTexture(gl.TEXTURE_2D, dummy);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texImage2D(gl.TEXTURE_2D, 0, integer ? gl.RGBA32I : gl.RGBA32F, 1, 1, 0,
                integer ? gl.RGBA_INTEGER : gl.RGBA, integer ? gl.INT : gl.FLOAT,
                integer ? new Int32Array(4) : new Float32Array(4));
            dummyTextures.push(dummy);
        }
        gl.viewport(0, 0, 4, 1);
        gl.disable(gl.DITHER);
        gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
        gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);
        const unpackFlipY = gl.getParameter(gl.UNPACK_FLIP_Y_WEBGL);
        const unpackColorspaceConversion = gl.getParameter(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL);
        if (unpackFlipY !== false || unpackColorspaceConversion !== gl.NONE) throw new Error('pixel unpack orientation/color conversion is enabled');
        const byteView = new DataView(new ArrayBuffer(4));
        const results = [];
        for (const name of ['BVH', 'vertexIndicesTex', 'verticesTex', 'normalsTex', 'transformsTex']) {
            const buffer = precisionScene.buffers[name];
            const texture = gl.createTexture();
            const unit = buffer.integer ? gl.TEXTURE1 : gl.TEXTURE0;
            gl.activeTexture(unit);
            gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texImage2D(gl.TEXTURE_2D, 0, buffer.integer ? gl.RGBA32I : gl.RGBA32F,
                buffer.layout.width, buffer.layout.height, 0, buffer.integer ? gl.RGBA_INTEGER : gl.RGBA,
                buffer.integer ? gl.INT : gl.FLOAT, buffer.data);
            const sampler = gl.createSampler();
            gl.samplerParameteri(sampler, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.samplerParameteri(sampler, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.samplerParameteri(sampler, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.samplerParameteri(sampler, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.bindSampler(buffer.integer ? 1 : 0, sampler);
            gl.uniform1i(modeLocation, buffer.integer ? 1 : 0);
            gl.uniform1i(buffer.integer ? integerTextureLocation : floatTextureLocation, buffer.integer ? 1 : 0);
            const filter = gl.getTexParameter(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER);
            const wrap = gl.getTexParameter(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S);
            if (filter !== gl.NEAREST || wrap !== gl.CLAMP_TO_EDGE) throw new Error(`${name}: texture sampling state mismatch`);
            let checkedTexels = 0;
            for (let y = 0; y < buffer.layout.height; y++) {
                for (let x = 0; x < buffer.layout.width; x++) {
                    gl.uniform2i(coordLocation, x, y);
                    gl.drawArrays(gl.TRIANGLES, 0, 3);
                    const bytes = new Uint8Array(16);
                    gl.readPixels(0, 0, 4, 1, gl.RGBA, gl.UNSIGNED_BYTE, bytes);
                    for (let lane = 0; lane < 4; lane++) {
                        const offset = (y * buffer.layout.width + x) * 4 + lane;
                        const bits = new DataView(bytes.buffer, bytes.byteOffset + lane * 4, 4).getUint32(0, true);
                        byteView.setUint32(0, bits, true);
                        const actual = buffer.integer ? byteView.getInt32(0, true) : byteView.getFloat32(0, true);
                        if (!Object.is(actual, buffer.data[offset])) {
                            throw new Error(`${name} GPU mismatch at texel(${x},${y}) lane ${lane}: ${actual} != ${buffer.data[offset]}`);
                        }
                    }
                    checkedTexels++;
                }
            }
            const logicalRows = Math.ceil(buffer.layout.logicalTexels / buffer.layout.width);
            const rowCrossingTexel = buffer.layout.logicalTexels > buffer.layout.width ? buffer.layout.width : null;
            const zeroW = buffer.channels === 3 && Array.from({ length: buffer.layout.width * buffer.layout.height },
                (_, index) => buffer.data[index * 4 + 3]).every((value) => value === 0);
            if (buffer.channels === 3 && !zeroW) throw new Error(`${name}: RGB ABI w padding is nonzero`);
            results.push({ name, internalFormat: buffer.internalFormat, samplerType: buffer.samplerType,
                width: buffer.layout.width, height: buffer.layout.height, logicalTexels: buffer.layout.logicalTexels,
                checkedTexels, firstTexel: [0,0],
                lastLogicalTexel: [(buffer.layout.logicalTexels - 1) % buffer.layout.width,
                    Math.floor((buffer.layout.logicalTexels - 1) / buffer.layout.width)],
                lastAllocatedTexel: [buffer.layout.width - 1, buffer.layout.height - 1],
                rowCrossingTexel, logicalRows, zeroW: buffer.channels === 3 ? zeroW : null,
                nearest: filter === gl.NEAREST, clampToEdge: wrap === gl.CLAMP_TO_EDGE });
            gl.deleteSampler(sampler);
            gl.deleteTexture(texture);
            if (gl.getError() !== gl.NO_ERROR) throw new Error(`${name}: GL error during fetch/readback`);
        }
        const observed = { rendererName, webgl2: true, maxTextureSize, maxTextureImageUnits,
            forcedPackingMaxTextureSize: limits.maxTextureSize, readPixelsFormat: 'RGBA8 encoded component bit patterns',
            unpackFlipY, unpackColorspaceConversion: unpackColorspaceConversion === gl.NONE ? 'NONE' : unpackColorspaceConversion,
            precisionBoundary: { largestExactID: 0xffffff, aboveBoundaryRejected: precisionRejected },
            samplerBudgetRejected, textureLimitRejected, buffers: results,
            verifiedFetches: results.reduce((total, result) => total + result.checkedTexels, 0),
            glError: gl.getError(),
        };
        gl.deleteFramebuffer(framebuffer);
        gl.deleteTexture(outputTexture);
        dummyTextures.forEach((texture) => gl.deleteTexture(texture));
        gl.deleteProgram(program);
        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);
        return observed;
    }, moduleUrl);
    assert.match(report.observed.rendererName, /SwiftShader/i);
    assert.equal(report.observed.webgl2, true);
    assert.equal(report.observed.glError, 0);
    assert.equal(report.observed.buffers.length, 5);
    assert.ok(report.observed.buffers.every((buffer) => buffer.checkedTexels > 0 && buffer.nearest && buffer.clampToEdge));
    assert.ok(report.observed.buffers.every((buffer) => buffer.rowCrossingTexel !== null));
    assert.equal(report.observed.samplerBudgetRejected, true);
    assert.equal(report.observed.textureLimitRejected, true);
    assert.deepEqual(report.errors, []);
    report.status = 'PASS';
    console.log(`PASS T012 GPU readback: ${report.observed.verifiedFetches} RGBA texels matched bitwise across five samplers.`);
} catch (error) {
    report.errors.push(error.message);
    process.exitCode = 1;
    console.error(error.stack ?? error.message);
} finally {
    mkdirSync(dirname(output), { recursive: true });
    writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
    await browser.close();
}