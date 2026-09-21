#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = process.cwd();
const errors = [];
const warnings = [];
const rendererPath = resolve(root, 'src/webgpu/WebGpuRenderer.js');
const mainPath = resolve(root, 'main.js');
const contractPath = resolve(root, 'public/mtlx/render-module-contract.json');
const vertexPath = resolve(root, 'src/webgpu/fullscreenTriangle.wgsl.js');

function source(path) {
    if (!existsSync(path)) { errors.push(`missing file: ${path}`); return ''; }
    return readFileSync(path, 'utf8');
}

const renderer = source(rendererPath);
const main = source(mainPath);
const vertex = source(vertexPath);
let contract = null;
try { contract = JSON.parse(source(contractPath)); } catch (error) { errors.push(`invalid render contract: ${error.message}`); }

for (const match of renderer.matchAll(/pushErrorScope\(([^)]+)\)/g)) {
    const value = match[1].trim();
    if (value === 'scope') continue;
    if (!['validation', "'validation'", '"validation"', 'out-of-memory', "'out-of-memory'", '"out-of-memory"', 'internal', "'internal'", '"internal"'].includes(value)) {
        errors.push(`invalid GPUErrorFilter in pushErrorScope: ${value}`);
    }
}
if (!renderer.includes('createRenderPipelineAsync')) errors.push('render pipeline creation is missing');
if (!renderer.includes('createRenderBindGroups')) errors.push('render bind-group creation is missing');
if (!renderer.includes('getBindGroupLayout(0)')) errors.push('render bind-group layout lookup is missing');
if (renderer.indexOf('this.renderPipeline = pipeline') > renderer.indexOf('getBindGroupLayout(0)')) errors.push('render pipeline is assigned after bind-group layout use');
if (!main.includes("params.webgpu_pipeline === 'render'")) errors.push('webgpu_pipeline=render route is missing');
if (!main.includes("params.webgpu_pipeline:                    'compute'")) warnings.push('compute default declaration not found in expected formatting');
if (!/@vertex\s*\nfn\s+fullscreenTriangleVertex/.test(vertex)) errors.push('fullscreen vertex entry point is missing');

if (contract) {
    if (contract.pipeline !== 'GPURenderPipeline') errors.push('contract pipeline is not GPURenderPipeline');
    if (contract.stages?.vertex?.entryPoint !== 'fullscreenTriangleVertex') errors.push('contract vertex entry point mismatch');
    if (contract.stages?.fragment?.entryPoint !== 'fragmentMain') errors.push('contract fragment entry point mismatch');
    const bindings = contract.bindings || [];
    const keys = bindings.map(binding => `${binding.group}/${binding.binding}`);
    if (new Set(keys).size !== keys.length) errors.push('contract contains duplicate bindings');
    if (bindings.length !== 15 || bindings.some((binding, index) => binding.group !== 0 || binding.binding !== index)) errors.push('contract host bindings must cover 0-14');
    if (contract.materialResources?.firstBinding !== 15) errors.push('contract material binding must start at 15');
}

const result = { pass: errors.length === 0, errors, warnings, browserRequiredChecks: ['GPUAdapter', 'GPUDevice', 'GPUShaderModule compilation', 'driver limits', 'actual render output'] };
console.log(JSON.stringify(result, null, 2));
process.exitCode = errors.length ? 1 : 0;
