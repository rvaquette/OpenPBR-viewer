#!/usr/bin/env node
import { readFileSync } from 'node:fs';

const path = process.argv[2] || 'public/mtlx/render-module-contract.json';
const contract = JSON.parse(readFileSync(path, 'utf8'));
const errors = [];
const vertex = contract.stages?.vertex;
const fragment = contract.stages?.fragment;
const interfaceFields = contract.interfaces?.FullscreenVertexOutput;
const bindings = contract.bindings || [];
const bindingKeys = bindings.map(binding => `${binding.group}/${binding.binding}`);

if (contract.pipeline !== 'GPURenderPipeline' || contract.language !== 'wgsl') errors.push('invalid pipeline/language');
if (vertex?.entryPoint !== 'fullscreenTriangleVertex') errors.push('invalid vertex entry point');
if (fragment?.entryPoint !== 'fragmentMain') errors.push('invalid fragment entry point');
if (fragment?.input !== 'FullscreenVertexOutput') errors.push('invalid fragment input interface');
if (interfaceFields?.position !== '@builtin(position) vec4<f32>') errors.push('invalid position interface');
if (interfaceFields?.uv !== '@location(0) vec2<f32>') errors.push('invalid uv interface');
if (fragment?.output !== '@location(0) vec4<f32>') errors.push('invalid fragment output');
if (new Set(bindingKeys).size !== bindingKeys.length) errors.push('duplicate binding');
if (bindings.length !== 15 || bindings.some((binding, index) => binding.group !== 0 || binding.binding !== index)) errors.push('host bindings must cover group 0 bindings 0-14');
if (contract.materialResources?.firstBinding !== 15) errors.push('invalid material first binding');
if (contract.primitive?.vertexCount !== 3 || contract.primitive?.topology !== 'triangle-list') errors.push('invalid fullscreen primitive');

if (errors.length) {
    console.error(JSON.stringify({ pass: false, errors }, null, 2));
    process.exit(1);
}
console.log(JSON.stringify({ pass: true, version: contract.version, hostBindings: bindings.length, firstMaterialBinding: contract.materialResources.firstBinding }, null, 2));
