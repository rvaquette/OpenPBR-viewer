#!/usr/bin/env node
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(process.argv[2] || '../MaterialX-rva/javascript/build/bin');
const required = ['JsMaterialXGenShader.js', 'JsMaterialXGenShader.wasm', 'JsMaterialXGenShader.data'];
const missing = required.filter(file => !existsSync(resolve(root, file)));
const jsPath = resolve(root, 'JsMaterialXGenShader.js');
let runtimeExport = false;
let hostRuntimeExport = false;
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
        hostRuntimeExport = Boolean(instance.MtlxPathTracerHostWgslShaderGenerator?.create);
        if (hostRuntimeExport) {
            hostContract = JSON.parse(instance.MtlxPathTracerHostWgslShaderGenerator.requiredHostContract());
            supportedModels = JSON.parse(instance.MtlxPathTracerHostWgslShaderGenerator.supportedMaterialModels());
            failureCodes = JSON.parse(instance.MtlxPathTracerHostWgslShaderGenerator.failureCodes());
        }
    } catch (error) {
        runtimeError = error?.message || String(error);
    }
}
const result = {
    root,
    requiredArtifacts: required,
    missingArtifacts: missing,
    hasWgslShaderGeneratorExport: runtimeExport,
    hasMtlxPathTracerHostWgslShaderGeneratorExport: hostRuntimeExport,
    hostContract,
    supportedMaterialModels: supportedModels,
    failureCodes,
    runtimeError,
    pass: missing.length === 0 && runtimeExport && hostRuntimeExport && hostContract?.version === 1 && hostContract?.language === 'wgsl' && supportedModels?.length === 5 && Object.keys(failureCodes || {}).length >= 7
};
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);