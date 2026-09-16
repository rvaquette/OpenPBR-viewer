#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const contractPath = resolve(process.argv[2] || 'public/mtlx/wgsl-host-contract.json');
const contract = JSON.parse(readFileSync(contractPath, 'utf8'));
const requiredHooks = [
    'mtlxGenEvaluateBsdf',
    'mtlxGenSampleBsdf',
    'mtlxGenPrepare',
    'mtlxGenEmission',
    'mtlxGenIsOpaque',
    'mtlxGenIsThinWalled'
];
const requiredModels = [
    'open_pbr_surface',
    'standard_surface',
    'disney_principled',
    'gltf_pbr',
    'UsdPreviewSurface'
];
const requiredBindings = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
const actualHooks = new Set(contract.entryPoints || []);
const actualModels = new Set(contract.materialModels || []);
const actualBindings = new Set((contract.bindings || []).map(binding => binding.binding));
const missingHooks = requiredHooks.filter(hook => !actualHooks.has(hook));
const missingModels = requiredModels.filter(model => !actualModels.has(model));
const missingBindings = requiredBindings.filter(binding => !actualBindings.has(binding));
const result = {
    contractPath,
    version: contract.version,
    language: contract.language,
    missingHooks,
    missingModels,
    missingBindings,
    pass: contract.version === 1 && contract.language === 'wgsl' && missingHooks.length === 0 && missingModels.length === 0 && missingBindings.length === 0
};
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);
