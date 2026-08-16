import MaterialX from 'file:///D:/WebGL2/GLSL-PathTracer-JS/mtlx/JsMaterialXGenShader.js';
import { readFileSync } from 'fs';
const mx = await MaterialX({ locateFile: p => `D:/WebGL2/GLSL-PathTracer-JS/mtlx/${p}` });
const gen = mx.PathTracerGlslShaderGenerator.create();
const ctx = new mx.GenContext(gen);
const stdlib = mx.loadStandardLibraries(ctx);
const doc = mx.createDocument();
doc.importLibrary(stdlib);
await mx.readFromXmlString(doc, readFileSync('D:/WebGL2/MaterialX/materials/open_pbr_carpaint.mtlx', 'utf8'), '');
const elem = mx.findRenderableElement(doc);
const shader = gen.generate(elem.getNamePath(), elem, ctx);
const glsl = shader.getSourceCode('pixel');
const lines = glsl.split('\n');
// Find pt_InitMaterialSummary and show coat lines
const s = lines.findIndex(l => l.includes('void pt_InitMaterialSummary'));
for (let i = s; i < s+30; i++) console.log(`${i+1}: ${lines[i]}`);
