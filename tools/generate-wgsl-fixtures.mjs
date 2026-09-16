#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';

const runtimeRoot = resolve(process.argv[2] || '../MaterialX-rva/javascript/build-t036/bin');
const outputRoot = resolve(process.argv[3] || 'artifacts/webgpu-migration/generated-wgsl');
const fixtures = [
    ['open_pbr_surface', 'public/mtlx-library/open_pbr_default.mtlx'],
    ['standard_surface', 'public/mtlx-input/standard_surface_default/standard_surface_default.mtlx'],
    ['disney_principled', 'public/mtlx-input/plastic/plastic.mtlx'],
    ['gltf_pbr', 'public/mtlx-input/metal_brushed/metal_brushed.mtlx'],
    ['usd_preview_surface', 'public/mtlx-input/_chrome_test/_chrome_test.mtlx'],
    ['carpaint', 'public/mtlx-input/carpaint/carpaint.mtlx'],
    ['glass', 'public/mtlx-input/glass/glass.mtlx'],
    ['pearl', 'public/mtlx-input/pearl/pearl.mtlx'],
    ['soapbubble', 'public/mtlx-input/soapbubble/soapbubble.mtlx'],
    ['synthetic_default', 'public/mtlx-library/open_pbr_default.mtlx']
];

const runtimePath = resolve(runtimeRoot, 'JsMaterialXGenShader.js');
if (!existsSync(runtimePath)) throw new Error(`Missing runtime: ${runtimePath}`);
const module = await import(`file://${runtimePath.replaceAll('\\', '/')}`);
const factory = module.default || module;
const mx = await factory({ locateFile: file => resolve(runtimeRoot, file) });
const Host = mx.MtlxPathTracerHostWgslShaderGenerator;
if (!Host?.create) throw new Error('WGSL host generator export is missing.');
const results = [];
for (const [id, relativePath] of fixtures) {
    const sourcePath = resolve(process.cwd(), relativePath);
    const result = { id, source: relativePath, status: 'failed', output: null, error: null };
    try {
        if (!existsSync(sourcePath)) throw new Error('fixture_missing');
        const generator = Host.create();
        const context = new mx.GenContext(generator);
        const document = mx.createDocument();
        document.importLibrary(mx.loadStandardLibraries(context));
        await mx.readFromXmlString(document, readFileSync(sourcePath, 'utf8'), '');
        const element = mx.findRenderableElement(document);
        if (!element) throw new Error('renderable_missing');
        const shader = generator.generate(element.getNamePath(), element, context);
        const source = shader.getSourceCode('pixel');
        if (!source) throw new Error('wgsl_source_empty');
        const output = resolve(outputRoot, `${id}/generated_dispatch.wgsl`);
        mkdirSync(dirname(output), { recursive: true });
        writeFileSync(output, source, 'utf8');
        result.status = 'generated';
        result.output = output;
        result.sourceLength = source.length;
    } catch (error) {
        result.error = error?.message || String(error);
    }
    results.push(result);
}
mkdirSync(outputRoot, { recursive: true });
writeFileSync(resolve(outputRoot, 'report.json'), `${JSON.stringify({ version: 1, runtimeRoot, results }, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(results, null, 2));
process.exit(results.some(result => result.status === 'failed') ? 1 : 0);
