import fs from 'node:fs';

const runtimePath = 'D:/WebGL2/MaterialX/MaterialX-rva/javascript/build-t036/bin/JsMaterialXGenShader.js';
const mod = await import(`file://${runtimePath}`);
const mx = await (mod.default || mod)({ locateFile: p => 'D:/WebGL2/MaterialX/MaterialX-rva/javascript/build-t036/bin/' + p });
const Host = mx.MtlxPathTracerHostWgslShaderGenerator;
const doc = mx.createDocument();
const generator = Host.create();
const context = new mx.GenContext(generator);
doc.importLibrary(mx.loadStandardLibraries(context));
mx.readFromXmlString(doc, fs.readFileSync('public/mtlx-library/open_pbr_default.mtlx', 'utf8'), '');

const walk = (node, acc = []) => {
  if (!node) return acc;
  const type = node.getType ? node.getType() : '';
  const name = node.getName ? node.getName() : '';
  const path = node.getNamePath ? node.getNamePath() : '';
  const category = node.getCategory ? node.getCategory() : '';
  acc.push({ type, name, path, category, inputs: node.getInputs ? node.getInputs().map(i => i.getName ? i.getName() : '') : [] });
  for (const c of node.getChildren ? node.getChildren() : []) walk(c, acc);
  return acc;
};
const nodes = walk(doc);
console.log('totalNodes', nodes.length);
for (const n of nodes.filter(n => n.type === 'surfacematerial' || n.type === 'material' || n.type === 'nodegraph' || n.name.includes('open_pbr') || n.name.includes('surface') || n.path.includes('Default')).slice(0, 80)) {
  console.log(JSON.stringify(n));
}
const renderable = mx.findRenderableElement(doc);
console.log('renderable', renderable && renderable.getType ? renderable.getType() : null, renderable && renderable.getName ? renderable.getName() : null, renderable && renderable.getNamePath ? renderable.getNamePath() : null, renderable && renderable.getCategory ? renderable.getCategory() : null);
if (renderable) {
  const n = renderable.asA ? renderable.asA('Node') : renderable;
  const surfaceInput = n && n.getInput ? n.getInput('surfaceshader') : null;
  let connected = null;
  try { connected = surfaceInput && surfaceInput.getConnectedNode ? surfaceInput.getConnectedNode() : null; } catch (e) { connected = `ERR:${e.message}`; }
  console.log('renderable connected', connected && connected.getName ? connected.getName() : connected, connected && connected.getCategory ? connected.getCategory() : null);
  console.log('renderable input names', n && n.getInputs ? n.getInputs().map(i => i.getName ? i.getName() : '') : null);
}
