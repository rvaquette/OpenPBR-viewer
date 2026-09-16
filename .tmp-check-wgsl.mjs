import fs from 'node:fs';
const root = 'D:/WebGL2/MaterialX/MaterialX-rva/javascript/build-t036/bin';
const mod = await import('file://' + root.replace(/\\/g, '/') + '/JsMaterialXGenShader.js');
const mx = await (mod.default || mod)({ locateFile: f => root + '/' + f });
const Host = mx.MtlxPathTracerHostWgslShaderGenerator;
const gen = Host.create();
const context = new mx.GenContext(gen);
const doc = mx.createDocument();
doc.importLibrary(mx.loadStandardLibraries(context));
const xml = fs.readFileSync('D:/WebGL2/MaterialX/OpenPBR-viewer-rva/public/mtlx-library/open_pbr_default.mtlx', 'utf8');
mx.readFromXmlString(doc, xml, '');
const children = doc.getChildren ? doc.getChildren() : [];
const materialCandidates = [];
const walk = (node) => {
  if (!node) return;
  const type = node.getType ? node.getType() : '';
  if (type === 'material' || type === 'surfacematerial') materialCandidates.push(node);
  const kids = node.getChildren ? node.getChildren() : [];
  for (const kid of kids) walk(kid);
};
walk(doc);
console.log('candidate count', materialCandidates.length);
console.log('candidates', materialCandidates.slice(0, 30).map(n => ({ type: n.getType ? n.getType() : '?', name: n.getName ? n.getName() : '?' })));
const element = mx.findRenderableElement(doc) || materialCandidates[0];
console.log('element', !!element, element && element.getName && element.getName(), element && element.getType && element.getType());
if (element) {
  const shader = gen.generate(element.getNamePath(), element, context);
  const src = shader.getSourceCode('pixel') || '';
  console.log('len', src.length);
  console.log('header', src.slice(0, 200));
  console.log('bad', {
    hasVersion: src.includes('#version'),
    hasLayout: src.includes('layout '),
    hasUniform: src.includes('uniform '),
    hasGlPosition: src.includes('gl_Position')
  });
}
