const ENTRYPOINT_PATTERN = /\b(?:fn|var)<[^>]+>\s+([A-Za-z_]\w*)|\bfn\s+([A-Za-z_]\w*)\s*\(/g;
const DECLARATION_PATTERN = /\b(?:struct|fn|const|alias|override)\s+([A-Za-z_]\w*)/g;

function collectNames(source) {
    const names = new Set();
    let match;
    while ((match = DECLARATION_PATTERN.exec(source)) !== null) names.add(match[1]);
    return names;
}

function collectEntryPoints(source) {
    const entryPoints = [];
    let match;
    while ((match = ENTRYPOINT_PATTERN.exec(source)) !== null) {
        const name = match[1] || match[2];
        if (name && !entryPoints.includes(name)) entryPoints.push(name);
    }
    return entryPoints;
}

export function validateWgslModuleSignatures(source, { requiredEntryPoints = [], label = 'WGSL module' } = {}) {
    const errors = [];
    const names = collectNames(source);
    const entryPoints = collectEntryPoints(source);
    for (const entryPoint of requiredEntryPoints) {
        if (!entryPoints.includes(entryPoint)) errors.push(`${label}: missing entry point ${entryPoint}`);
    }
    return { errors, names, entryPoints, pass: errors.length === 0 };
}

function findMangledFunction(source, prefix) {
    return source.match(new RegExp(`\\bfn\\s+(${prefix}_u[0-9A-Za-z_]+)\\s*\\(`))?.[1] || null;
}

export function createMaterialWgslBridge(source) {
    const evaluate = findMangledFunction(source, 'mtlxGenEvaluateBsdf');
    const sample = findMangledFunction(source, 'mtlxGenSampleBsdf');
    const initialize = source.match(/\bfn\s+(mtlxMaterialLibrary_\d+)\s*\(/)?.[1] || null;
    if (!evaluate || !sample || !initialize) {
        const error = new Error('MaterialX WGSL is missing its transpiled initialization/evaluate/sample functions.');
        error.code = 'MTLX_WGSL_SIGNATURE_INVALID';
        throw error;
    }
    return `${source.trim()}

struct MtlxBsdfEvaluation {
    response: vec3<f32>,
    pdf: f32,
}

struct MtlxBsdfSample {
    response: vec3<f32>,
    direction: vec3<f32>,
    pdf: f32,
    medium: Volume,
}

fn mtlxGenEvaluateBsdf(position: vec3<f32>, basis: Basis, incoming: vec3<f32>, outgoing: vec3<f32>) -> MtlxBsdfEvaluation {
    ${initialize}();
    var positionValue = position;
    var basisValue = basis;
    var incomingValue = incoming;
    var outgoingValue = outgoing;
    var pdf = 0.0;
    let response = ${evaluate}(&positionValue, &basisValue, &incomingValue, &outgoingValue, &pdf);
    return MtlxBsdfEvaluation(response, pdf);
}

fn mtlxGenSampleBsdf(position: vec3<f32>, basis: Basis, incoming: vec3<f32>, seed: u32) -> MtlxBsdfSample {
    ${initialize}();
    var positionValue = position;
    var basisValue = basis;
    var incomingValue = incoming;
    var seedValue = seed;
    var outgoing = vec3<f32>(0.0, 0.0, 1.0);
    var pdf = 0.0;
    var medium = Volume(vec3<f32>(0.0), vec3<f32>(0.0), 0.0);
    let response = ${sample}(&positionValue, &basisValue, &incomingValue, &seedValue, &outgoing, &pdf, &medium);
    return MtlxBsdfSample(response, outgoing, pdf, medium);
}`;
}

export function assembleWgslModules({ prelude = '', integrator = '', material = '', requiredEntryPoints = [] } = {}) {
    const modules = [
        ['prelude', prelude],
        ['integrator', integrator],
        ['material', material],
    ];
    const errors = [];
    const names = new Map();
    for (const [label, source] of modules) {
        const result = validateWgslModuleSignatures(source, { label });
        for (const name of result.names) {
            if (names.has(name)) errors.push(`WGSL declaration collision: ${name} (${names.get(name)} and ${label})`);
            else names.set(name, label);
        }
    }
    const combined = modules.map(([, source]) => source.trim()).filter(Boolean).join('\n\n');
    const combinedValidation = validateWgslModuleSignatures(combined, { requiredEntryPoints, label: 'assembled WGSL' });
    errors.push(...combinedValidation.errors);
    if (errors.length) {
        const error = new Error(errors.join('\n'));
        error.code = 'MTLX_WGSL_ASSEMBLY_INVALID';
        error.errors = errors;
        throw error;
    }
    return { source: combined, declarations: [...names.keys()], entryPoints: combinedValidation.entryPoints };
}

export function validateHostBindings(source, bindings = []) {
    const errors = [];
    const seen = new Set();
    for (const binding of bindings) {
        const key = `${binding.group}/${binding.binding}`;
        if (seen.has(key)) errors.push(`duplicate host binding ${key}`);
        seen.add(key);
        const declaration = new RegExp(`@group\\(${binding.group}\\)\\s*@binding\\(${binding.binding}\\)`);
        if (!declaration.test(source)) errors.push(`missing host binding ${key} (${binding.name || 'unnamed'})`);
    }
    return { errors, pass: errors.length === 0 };
}

export async function compileWgslModule(device, source, label = 'WGSL module') {
    const module = device.createShaderModule({ code: source });
    const info = await module.getCompilationInfo();
    const errors = info.messages.filter(message => message.type === 'error');
    if (errors.length) {
        const error = new Error(`${label} compilation failed: ${errors.map(message => message.message).join('; ')}`);
        error.code = 'MTLX_WGSL_COMPILE_FAILED';
        error.messages = errors;
        throw error;
    }
    return { module, info };
}
