import MaterialX from 'file:///D:/WebGL2/MaterialX/OpenPBR-viewer-rva/public/mtlx/JsMaterialXGenShader.js';
import { readFileSync, writeFileSync } from 'fs';
const mx = await MaterialX({ locateFile: p => `D:/WebGL2/MaterialX/OpenPBR-viewer-rva/public/mtlx/${p}` });
const gen = mx.PathTracerGlslShaderGenerator.create();
const ctx = new mx.GenContext(gen);
const stdlib = mx.loadStandardLibraries(ctx);
const doc = mx.createDocument();
doc.importLibrary(stdlib);
await mx.readFromXmlString(doc, readFileSync('D:/WebGL2/MaterialX/materials/open_pbr_carpaint.mtlx', 'utf8'), '');
const elem = mx.findRenderableElement(doc);
const shader = gen.generate(elem.getNamePath(), elem, ctx);
const glsl = shader.getSourceCode('pixel');
writeFileSync('D:/WebGL2/MaterialX/OpenPBR-viewer-rva/tmp_carp2.glsl', glsl);
const lines = glsl.split('\n');
// pt_InitMaterialSummary
const s = lines.findIndex(l => l.includes('void pt_InitMaterialSummary'));
console.log('=== pt_InitMaterialSummary ===');
for (let i = s; i < s+35; i++) console.log(`${i+1}: ${lines[i]}`);
// pt_pCoat in SampleMtlxClosure
const s2 = lines.findIndex(l => l.includes('pt_pCoat_s'));
console.log('\n=== SampleMtlxClosure coat lines ===');
for (let i = s2-2; i < s2+5; i++) console.log(`${i+1}: ${lines[i]}`);
