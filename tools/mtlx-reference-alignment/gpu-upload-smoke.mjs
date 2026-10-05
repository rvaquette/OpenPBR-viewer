import assert from 'node:assert/strict';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { chromium } from 'playwright-core';

const root = fileURLToPath(new URL('../../', import.meta.url));
const output = join(root, 'artifacts/mtlx-reference-alignment/t011-upload-smoke.json');
const bundle = await build({ stdin: { loader: 'ts', resolveDir: root, contents: [
    'export { WebGLRenderer, BufferGeometry, Float32BufferAttribute } from "three";',
    'export { adaptReferenceGeometry } from "./src/bvh/referenceSceneAdapter.js";',
    'export { buildReferenceBlas } from "./src/bvh/referenceBlas.js";',
    'export { buildReferenceScene } from "./src/bvh/referenceScene.js";',
    'export { uploadReferenceSceneTextures } from "./src/bvh/referenceGpuAdapter.js";',
].join('\n') }, absWorkingDir: root, platform: 'browser', format: 'esm', bundle: true, write: false });
const moduleUrl = `data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].contents).toString('base64')}`;
const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const report = { task: 'T011', status: 'FAIL', readbackPerformed: false, timestamp: new Date().toISOString(), observed: null, errors: [] };
try {
    const page = await browser.newPage();
    page.on('pageerror', (error) => report.errors.push(error.message));
    report.observed = await page.evaluate(async (moduleUrl) => {
        const api = await import(moduleUrl);
        const renderer = new api.WebGLRenderer();
        const gl = renderer.getContext();
        const debug = gl.getExtension('WEBGL_debug_renderer_info');
        const rendererName = debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        const geometry = new api.BufferGeometry();
        geometry.setAttribute('position', new api.Float32BufferAttribute([0,0,0, 1,0,0, 0,1,0], 3));
        const mesh = api.buildReferenceBlas(api.adaptReferenceGeometry(geometry).primitives[0]);
        const scene = api.buildReferenceScene([mesh], [{ meshID: 0, materialID: 7 }]);
        const uploads = [];
        for (const input of [scene, api.buildReferenceScene([],[])]) {
            const textures = api.uploadReferenceSceneTextures(renderer, input, { reservedTextureUnits:4 });
            uploads.push({ counts: textures.packed.counts, byteLength: textures.packed.byteLength,
                glError: gl.getError(), formats: Object.fromEntries(Object.entries(textures.textures).map(([name, texture]) => [name, texture.internalFormat])) });
            textures.dispose();
        }
        const observed = { rendererName, webgl2: renderer.capabilities.isWebGL2,
            maxTextureSize: renderer.capabilities.maxTextureSize, maxTextureImageUnits: renderer.capabilities.maxTextures, uploads };
        renderer.dispose();
        return observed;
    }, moduleUrl);
    assert.match(report.observed.rendererName, /SwiftShader/i);
    assert.equal(report.observed.webgl2, true);
    assert.ok(report.observed.uploads.every((upload) => upload.glError === 0));
    assert.deepEqual(report.errors, []);
    report.status = 'PASS';
    console.log('PASS T011 SwiftShader upload: populated/empty scene textures initialized, no GL errors; no readback performed.');
} catch (error) {
    report.errors.push(error.message);
    process.exitCode = 1;
    console.error(error.message);
} finally {
    mkdirSync(dirname(output), { recursive: true });
    writeFileSync(output, `${JSON.stringify(report, null, 2)}\n`);
    await browser.close();
}