#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const runtimeRoot = resolve(process.cwd(), '../MaterialX-rva/javascript/build-t036/bin');
const outputRoot = resolve(process.cwd(), 'artifacts/webgpu-migration/generated-wgsl');
const materialRoot = resolve(process.cwd(), 'public/mtlx-library');

const synthetic = [
  ['open_pbr_surface', resolve(materialRoot, 'open_pbr_default.mtlx')],
  ['standard_surface', resolve(process.cwd(), 'public/mtlx-input/standard_surface_default/standard_surface_default.mtlx')],
  ['disney_principled', resolve(process.cwd(), 'public/mtlx-input/plastic/plastic.mtlx')],
  ['gltf_pbr', resolve(process.cwd(), 'public/mtlx-input/metal_brushed/metal_brushed.mtlx')],
  ['usd_preview_surface', resolve(process.cwd(), 'public/mtlx-input/_chrome_test/_chrome_test.mtlx')],
];

const carpaint = [
  ['carpaint', resolve(process.cwd(), 'public/mtlx-input/carpaint/carpaint.mtlx')],
  ['glass', resolve(process.cwd(), 'public/mtlx-input/glass/glass.mtlx')],
  ['pearl', resolve(process.cwd(), 'public/mtlx-input/pearl/pearl.mtlx')],
  ['soapbubble', resolve(process.cwd(), 'public/mtlx-input/soapbubble/soapbubble.mtlx')],
  ['synthetic_default', resolve(materialRoot, 'open_pbr_default.mtlx')],
];

const runtimePath = resolve(runtimeRoot, 'JsMaterialXGenShader.js');
if (!existsSync(runtimePath)) throw new Error(`Missing runtime: ${runtimePath}`);
const module = await import(`file://${runtimePath.replaceAll('\\', '/')}`);
const factory = module.default || module;
const mx = await factory({ locateFile: file => resolve(runtimeRoot, file) });
const Host = mx.MtlxPathTracerHostWgslShaderGenerator;
if (!Host?.create) throw new Error('MtlxPathTracerHostWgslShaderGenerator export is missing.');

const requestedFixture = process.env.T043_FIXTURE_ID;
const fixtures = [...synthetic, ...carpaint].filter(([id]) => !requestedFixture || id === requestedFixture);
if (!fixtures.length) throw new Error(`Unknown T043 fixture: ${requestedFixture}`);
const supportedModels = new Set(['open_pbr_surface', 'standard_surface', 'disney_principled', 'gltf_pbr', 'UsdPreviewSurface']);
const reports = [];
for (const [id, materialPath] of fixtures) {
  if (!existsSync(materialPath)) {
    reports.push({ id, kind: id.includes('carpaint') ? 'carpaint' : 'synthetic', materialPath, status: 'missing', error: 'fixture missing' });
    continue;
  }

  try {
    const generator = Host.create();
    const context = new mx.GenContext(generator);
    const document = mx.createDocument();
    document.importLibrary(mx.loadStandardLibraries(context));
    const materialXml = readFileSync(materialPath, 'utf8');
    await mx.readFromXmlString(document, materialXml, '');

    const walk = (node, acc = []) => {
          if (!node) return acc;
          const type = node.getType ? node.getType() : '';
          const category = node.getCategory ? node.getCategory() : '';
          const name = node.getName ? node.getName() : '';
          if (type === 'surfaceshader' && supportedModels.has(category) && !/^ND_|^NG_/.test(name)) acc.push(node);
          const children = node.getChildren ? node.getChildren() : [];
          for (const child of children) walk(child, acc);
          return acc;
    };

    let element = null;
    const materialCandidates = walk(document);
    if (!materialCandidates.length && document.getChild) {
      const shaderTags = [...materialXml.matchAll(/<([A-Za-z_][\w.-]*)\b([^>]*)>/g)];
      for (const [, category, attributes] of shaderTags) {
        const name = attributes.match(/\bname="([^"]+)"/)?.[1];
        const type = attributes.match(/\btype="([^"]+)"/)?.[1];
        if (!name || type !== 'surfaceshader') continue;
        if (!supportedModels.has(category)) continue;
        const shaderElement = document.getChild(name);
        if (shaderElement) { materialCandidates.push(shaderElement); break; }
      }
    }
        if (materialCandidates.length) element = materialCandidates[0];
    if (!element && mx.findRenderableElement) {
      element = mx.findRenderableElement(document);
    }
    if (!element) throw new Error('no renderable element');
    const shader = generator.generate(element.getNamePath(), element, context);
    const source = shader.getSourceCode('pixel') || '';
    if (!source.trim()) throw new Error('empty generated GLSL source');
    const fixtureRoot = resolve(outputRoot, id);
    const glslFile = resolve(fixtureRoot, 'generated_dispatch.glsl');
    const wgslFile = resolve(fixtureRoot, 'generated_dispatch.wgsl');
    const artifactsDir = resolve(fixtureRoot, 'transpile-artifacts');
    mkdirSync(dirname(glslFile), { recursive: true });
    writeFileSync(glslFile, source, 'utf8');
    const stage = /\bmtlxGenEvaluateBsdf\s*\(/.test(source) ? 'frag' : /#pragma\s+shader_stage\(fragment\)/.test(source) ? 'frag' : /#pragma\s+shader_stage\(vertex\)/.test(source) ? 'vert' : 'comp';
    const report = {
      id,
      kind: id.includes('carpaint') ? 'carpaint' : 'synthetic',
      materialPath,
      sourceLength: source.length,
      generation: { status: 'pass', output: glslFile },
      spirv: { status: 'pending' },
      transpile: { status: 'pending' },
      contract: { status: 'pending' },
    };

    try {
      execFileSync(process.execPath, ['tools/transpile-glsl-to-wgsl.mjs', '--input', glslFile, '--output', wgslFile, '--stage', stage, '--entry-point', 'mtlxMaterialLibrary', '--artifacts-dir', artifactsDir], {
        cwd: process.cwd(),
        stdio: 'pipe',
        encoding: 'utf8',
      });
      report.spirv = { status: 'pass', stage, output: resolve(artifactsDir, `generated_dispatch.${stage}.spv`) };
      report.transpile = { status: 'pass', output: wgslFile };
    } catch (transpileError) {
      const detail = transpileError.stdout || transpileError.stderr || transpileError.message;
      const text = String(detail).trim();
      report.spirv = { status: text.includes('MTLX_WGSL_GLSLANG') ? 'fail' : 'pass', log: resolve(artifactsDir, 'glslang.log'), error: text };
      report.transpile = { status: text.includes('MTLX_WGSL_NAGA') ? 'fail' : 'blocked', log: resolve(artifactsDir, 'naga.log'), error: text };
      reports.push({ ...report, status: 'fail' });
      continue;
    }

    try {
      execFileSync(process.execPath, ['tools/validate-wgsl-source.mjs', `--source=${wgslFile}`, '--contract=public/mtlx/wgsl-host-contract.json', '--material-module'], {
        cwd: process.cwd(),
        stdio: 'pipe',
        encoding: 'utf8',
      });
      report.contract = { status: 'pass', output: wgslFile };
    } catch (validationError) {
      const detail = validationError.stdout || validationError.stderr || validationError.message;
      report.contract = { status: 'fail', error: String(detail).trim() };
    }
    reports.push({ ...report, status: report.contract.status === 'pass' ? 'pass' : 'fail' });
  } catch (error) {
    reports.push({ id, kind: id.includes('carpaint') ? 'carpaint' : 'synthetic', materialPath, status: 'fail', error: String(error?.message || error) });
  }
}

const reportPath = resolve(outputRoot, 't043-validation-report.json');
writeFileSync(reportPath, JSON.stringify({ generatedAt: new Date().toISOString(), runtimeRoot, fixtures: reports }, null, 2), 'utf8');
console.log(JSON.stringify({ total: reports.length, passed: reports.filter(r => r.status === 'pass').length, failed: reports.filter(r => r.status !== 'pass').length, reportPath }, null, 2));
process.exit(reports.some(r => r.status !== 'pass') ? 1 : 0);
