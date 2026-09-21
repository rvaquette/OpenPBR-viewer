#!/usr/bin/env node
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.argv[2] || '../MaterialX-rva/javascript/build/bin');
const required = ['JsMaterialXGenShader.js', 'JsMaterialXGenShader.wasm', 'JsMaterialXGenShader.data'];
const missing = required.filter(file => !existsSync(resolve(root, file)));
const jsPath = resolve(root, 'JsMaterialXGenShader.js');
let runtimeExport = false;
let hostRuntimeExport = false;
let removedHostRuntimeExport = false;
let hostContract = null;
let supportedModels = null;
let failureCodes = null;
let runtimeError = '';
if (missing.length === 0) {
    try {
        const module = await import(`file://${jsPath.replaceAll('\\', '/')}`);
        const factory = module.default || module;
        const instance = await factory({ locateFile: file => resolve(root, file) });
        runtimeExport = Boolean(instance.WgslShaderGenerator?.create);
        hostRuntimeExport = Boolean(instance.MtlxPathTracerHostShaderGenerator?.create);
        removedHostRuntimeExport = Boolean(instance.MtlxPathTracerHostWgslShaderGenerator?.create);
        if (hostRuntimeExport) supportedModels = ['open_pbr_surface', 'standard_surface', 'disney_principled', 'gltf_pbr', 'UsdPreviewSurface'];
    } catch (error) {
        runtimeError = error?.message || String(error);
    }
}
const result = {
    root,
    requiredArtifacts: required,
    missingArtifacts: missing,
    hasWgslShaderGeneratorExport: runtimeExport,
    hasMtlxPathTracerHostShaderGeneratorExport: hostRuntimeExport,
    hasRemovedMtlxPathTracerHostWgslShaderGeneratorExport: removedHostRuntimeExport,
    hostContract,
    supportedMaterialModels: supportedModels,
    failureCodes,
    runtimeError,
    pass: missing.length === 0 && runtimeExport && hostRuntimeExport && !removedHostRuntimeExport && supportedModels?.length === 5
};
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);