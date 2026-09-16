import fs from 'node:fs';

const runtimePath = 'D:/WebGL2/MaterialX/MaterialX-rva/javascript/build-t036/bin/JsMaterialXGenShader.js';
const mod = await import(`file://${runtimePath}`);
const mx = await (mod.default || mod)({ locateFile: p => 'D:/WebGL2/MaterialX/MaterialX-rva/javascript/build-t036/bin/' + p });
const Host = mx.MtlxPathTracerHostWgslShaderGenerator;
const gen = Host.create();
const context = new mx.GenContext(gen);
const doc = mx.createDocument();
doc.importLibrary(mx.loadStandardLibraries(context));
mx.readFromXmlString(doc, fs.readFileSync('public/mtlx-library/open_pbr_default.mtlx', 'utf8'), '');

const visited = new Set();
const candidates = [];
const walk = (node) => {
  if (!node) return;
  const key = node.getNamePath ? node.getNamePath() : String(Math.random());
  if (visited.has(key)) return;
  visited.add(key);
  const type = node.getType ? node.getType() : '';
  const category = node.getCategory ? node.getCategory() : '';
  const name = node.getName ? node.getName() : '';
  if (type || category || name) candidates.push({ type, category, name, path: node.getNamePath ? node.getNamePath() : '' });
  const children = node.getChildren ? node.getChildren() : [];
  for (const c of children) walk(c);
};
walk(doc);
console.log('candidateCount', candidates.length);
for (const c of candidates.slice(0, 80)) {
  if (c.category || c.type || c.name.includes('open_pbr') || c.name.includes('surface')) {
    console.log('CAND', JSON.stringify(c));
  }
}

let found = null;
for (const c of candidates) {
  if (!c.category) continue;
  if (['open_pbr_surface','standard_surface','disney_principled','gltf_pbr','UsdPreviewSurface'].includes(c.category)) {
    found = c;
    break;
  }
}
console.log('matchedCategory', found ? JSON.stringify(found) : 'none');

if (found) {
  const target = doc.getChildren ? doc.getChildren().find(n => n.getName && n.getName() === found.name) : null;
  console.log('targetResolved', !!target, target && target.getName && target.getName());
  try {
    const shader = gen.generate(found.name, target || found, context);
    const source = shader.getSourceCode('pixel') || '';
    console.log('SUCCESS', source.slice(0, 120).replace(/\n/g, '\\n'));
  } catch (e) {
    console.log('GEN_FAIL', String(e && e.message || e));
  }
}
