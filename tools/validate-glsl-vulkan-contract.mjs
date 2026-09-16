#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

function option(name, fallback = null) {
  const arg = process.argv.find(value => value.startsWith(`--${name}=`));
  return arg ? arg.slice(name.length + 3) : fallback;
}

const sourcePath = resolve(process.cwd(), option('source', ''));
const contractPath = resolve(process.cwd(), option('contract', 'public/mtlx/wgsl-host-contract.json'));
if (!existsSync(sourcePath) || !existsSync(contractPath)) {
  throw new Error('GLSL source and contract paths must exist.');
}

const source = readFileSync(sourcePath, 'utf8');
const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
const errors = [];
const layouts = [];
const layoutPattern = /layout\s*\(([^)]*)\)\s*([^;{]+)(?:\{|;)/g;
let match;
while ((match = layoutPattern.exec(source)) !== null) {
  const qualifiers = match[1];
  const declaration = match[2].trim();
  const set = /(?:^|,)\s*set\s*=\s*(\d+)/.exec(qualifiers)?.[1];
  const binding = /(?:^|,)\s*binding\s*=\s*(\d+)/.exec(qualifiers)?.[1];
  if (set === undefined || binding === undefined) {
    errors.push(`resource layout lacks explicit set/binding: layout(${qualifiers}) ${declaration}`);
    continue;
  }
  layouts.push({ set: Number(set), binding: Number(binding), qualifiers, declaration });
  const isUniformBlock = /\buniform\s+[A-Za-z_]\w*\s*(?:\{|$)/.test(declaration) && !/\bsampler/.test(declaration) && !/\bimage/.test(declaration);
  if (isUniformBlock && !/\bstd140\b/.test(qualifiers)) {
    errors.push(`uniform resource binding ${set}/${binding} lacks std140: ${declaration}`);
  }
}

const seen = new Set();
for (const layout of layouts) {
  const key = `${layout.set}/${layout.binding}`;
  if (seen.has(key)) errors.push(`duplicate Vulkan resource binding ${key}`);
  seen.add(key);
}
const expected = contract.vulkan?.bindings || contract.bindings || [];
for (const binding of expected) {
  const key = `${binding.group}/${binding.binding}`;
  if (!seen.has(key)) errors.push(`missing Vulkan resource binding ${key} (${binding.name || binding.type || 'unnamed'})`);
}
if (contract.vulkan?.targetEnv && !source.includes('#version 450')) {
  errors.push('Vulkan GLSL source must declare #version 450');
}
const result = { source: sourcePath, contract: contractPath, layouts, errors, pass: errors.length === 0 };
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);
