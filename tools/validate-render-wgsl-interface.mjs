#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

function fail(message) {
    console.error(JSON.stringify({ pass: false, errors: [message] }, null, 2));
    process.exit(1);
}

function parseArgs(argv) {
    const options = {};
    for (let index = 0; index < argv.length; index++) {
        const argument = argv[index];
        if (argument === '--vertex' || argument === '--fragment' || argument === '--contract') {
            const value = argv[++index];
            if (!value) fail(`Missing value for ${argument}`);
            options[argument.slice(2)] = value;
        } else if (argument === '--help' || argument === '-h') {
            console.log('Usage: node tools/validate-render-wgsl-interface.mjs --vertex vertex.wgsl.js --contract render-host-contract.json [--fragment fragment.wgsl]');
            process.exit(0);
        } else {
            fail(`Unknown argument ${argument}`);
        }
    }
    if (!options.vertex || !options.contract) fail('--vertex and --contract are required');
    return options;
}

function readVertexSource(path) {
    const source = readFileSync(resolve(process.cwd(), path), 'utf8');
    const template = source.match(/`([\s\S]*)`/);
    return template ? template[1] : source;
}

function readText(path) {
    return readFileSync(resolve(process.cwd(), path), 'utf8');
}

const options = parseArgs(process.argv.slice(2));
const vertexPath = resolve(process.cwd(), options.vertex);
const contractPath = resolve(process.cwd(), options.contract);
if (!existsSync(vertexPath)) fail(`Vertex source missing: ${options.vertex}`);
if (!existsSync(contractPath)) fail(`Render contract missing: ${options.contract}`);

const vertex = readVertexSource(options.vertex);
const contract = JSON.parse(readText(options.contract));
const errors = [];
if (!/@vertex\s+fn\s+fullscreenTriangleVertex\s*\(/.test(vertex)) errors.push('vertex entry point fullscreenTriangleVertex is missing');
if (!/@builtin\(position\)\s+position\s*:\s*vec4<f32>/.test(vertex)) errors.push('vertex output position builtin is missing');
if (!/@location\(0\)\s+uv\s*:\s*vec2<f32>/.test(vertex)) errors.push('vertex output uv location 0 is missing');
if (contract.glslVersion !== 450 || contract.targetEnv !== 'vulkan1.2') errors.push('render contract Vulkan version is invalid');
if (contract.entryPoint !== 'main' || contract.output?.location !== 0) errors.push('render contract entry point/output is invalid');
const reserved = contract.hostBindingRange?.reservedBindings || [];
const firstMaterialBinding = contract.hostBindingRange?.firstMaterialBinding;
if (firstMaterialBinding !== 15 || new Set(reserved).size !== reserved.length || reserved.some(binding => binding < 0 || binding >= firstMaterialBinding)) {
    errors.push('host binding range is invalid');
}

let fragmentChecked = false;
if (options.fragment) {
    const fragmentPath = resolve(process.cwd(), options.fragment);
    if (!existsSync(fragmentPath)) errors.push(`Fragment source missing: ${options.fragment}`);
    else {
        const fragment = readText(options.fragment);
        fragmentChecked = true;
        if (!/@fragment\s+fn\s+[A-Za-z_]\w*\s*\(/.test(fragment)) errors.push('fragment entry point is missing');
        if (!/@location\(0\)/.test(fragment)) errors.push('fragment output location 0 is missing');
        const bindings = [...fragment.matchAll(/@group\((\d+)\)\s*@binding\((\d+)\)/g)].map(match => `${match[1]}/${match[2]}`);
        if (new Set(bindings).size !== bindings.length) errors.push('fragment has duplicate group/binding declarations');
    }
}

if (errors.length) {
    console.error(JSON.stringify({ pass: false, fragmentChecked, errors }, null, 2));
    process.exit(1);
}
console.log(JSON.stringify({ pass: true, vertexChecked: true, fragmentChecked, contract: options.contract }, null, 2));
