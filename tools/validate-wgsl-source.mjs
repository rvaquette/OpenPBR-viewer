#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

function option(name) {
    const arg = process.argv.find(value => value.startsWith(`--${name}=`));
    return arg ? arg.slice(name.length + 3) : null;
}

const materialModule = process.argv.includes('--material-module');

const sourcePath = resolve(process.cwd(), option('source') || '');
const contractPath = resolve(process.cwd(), option('contract') || 'public/mtlx/wgsl-host-contract.json');
if (!existsSync(sourcePath) || !existsSync(contractPath)) throw new Error('WGSL source and contract paths must exist.');

const source = readFileSync(sourcePath, 'utf8');
const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
const errors = [];
const forbidden = [/#[a-zA-Z_]+/, /\bgl_(?:Position|FragCoord|VertexID)\b/, /\buniform\s+(?:sampler|mat[234]|vec[234])/];
for (const pattern of forbidden) if (pattern.test(source)) errors.push(`forbidden GLSL syntax: ${pattern}`);
if (materialModule) {
    if (!/@fragment\s*\n?fn\s+mtlxMaterialLibrary\s*\(/.test(source)) errors.push('missing MaterialX library entrypoint: @fragment fn mtlxMaterialLibrary');
    const materialForbidden = [/\bgl_(?:Position|FragCoord|VertexID)\b/, /\buniform\s+(?:sampler|mat[234]|vec[234])/];
    for (const pattern of materialForbidden) if (pattern.test(source)) errors.push(`forbidden material WGSL syntax: ${pattern}`);
} else {
    for (const entryPoint of contract.entryPoints || []) {
        if (!new RegExp(`\\b${entryPoint}\\s*\\(`).test(source)) errors.push(`missing entrypoint: ${entryPoint}`);
    }
    for (const [name, structure] of Object.entries(contract.structures || {})) {
        if (!new RegExp(`\\bstruct\\s+${name}\\s*\\{`).test(source)) errors.push(`missing structure: ${name}`);
        for (const field of structure.fields || []) {
            const [fieldName] = field.split(':');
            if (!new RegExp(`\\b${fieldName}\\s*:`).test(source)) errors.push(`missing ${name} field: ${fieldName}`);
        }
    }
    for (const binding of contract.bindings || []) {
        const declaration = new RegExp(`@group\\(${binding.group}\\)\\s*@binding\\(${binding.binding}\\)`);
        if (!declaration.test(source)) errors.push(`missing binding: group ${binding.group}, binding ${binding.binding}`);
    }
}
const result = { source: sourcePath, contract: contractPath, errors, pass: errors.length === 0 };
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);
