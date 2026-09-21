#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const runtimeRoot = resolve(process.argv[2] || '../MaterialX-rva/javascript/build-t036/bin');
const materialPath = resolve(process.argv[3] || 'public/mtlx-library/open_pbr_default.mtlx');
const runtimePath = resolve(runtimeRoot, 'JsMaterialXGenShader.js');
if (!existsSync(runtimePath) || !existsSync(materialPath)) throw new Error('WGSL runtime or MaterialX fixture is missing.');

const module = await import(`file://${runtimePath.replaceAll('\\', '/')}`);
const factory = module.default || module;
const mx = await factory({ locateFile: file => resolve(runtimeRoot, file) });
const Host = mx.MtlxPathTracerHostShaderGenerator;
if (!Host?.create) throw new Error('MtlxPathTracerHostShaderGenerator export is missing.');
const generator = Host.create();
const context = new mx.GenContext(generator);
const document = mx.createDocument();
document.importLibrary(mx.loadStandardLibraries(context));
await mx.readFromXmlString(document, readFileSync(materialPath, 'utf8'), '');
const element = mx.findRenderableElement(document);
if (!element) throw new Error('No renderable MaterialX element found.');
const shader = generator.generate(element.getNamePath(), element, context);
const stage = 'pixel';
const sources = { pixel: shader.getSourceCode(stage) || '' };
if (!stage) throw new Error('WGSL host generator returned no stage source.');
console.log(JSON.stringify({ material: materialPath, stage, sourceLength: sources[stage].length, generator: 'MtlxPathTracerHostShaderGenerator', pass: true }, null, 2));
