import { validateWgslModuleSignatures } from './wgslModuleAssembler.js';

const DEFAULT_VERTEX_ENTRY = 'fullscreenTriangleVertex';
const DEFAULT_FRAGMENT_ENTRY = 'fragmentMain';
const SHARED_INTERFACE = 'FullscreenVertexOutput';

function collectBindings(source, label) {
    const bindings = new Map();
    const pattern = /@group\((\d+)\)\s*@binding\((\d+)\)/g;
    let match;
    while ((match = pattern.exec(source)) !== null) {
        const key = `${match[1]}/${match[2]}`;
        if (bindings.has(key)) throw new Error(`Render WGSL duplicate binding ${key} in ${label}`);
        bindings.set(key, label);
    }
    return bindings;
}

function validateVertexInterface(source, entryPoint) {
    const result = validateWgslModuleSignatures(source, {
        requiredEntryPoints: [entryPoint],
        label: 'render vertex',
    });
    const errors = [...result.errors];
    if (!new RegExp(`struct\\s+${SHARED_INTERFACE}\\s*\\{`).test(source)) {
        errors.push(`render vertex: missing ${SHARED_INTERFACE}`);
    }
    if (!/@builtin\(position\)\s+position\s*:\s*vec4<f32>/.test(source)) {
        errors.push('render vertex: missing position builtin');
    }
    if (!/@location\(0\)\s+uv\s*:\s*vec2<f32>/.test(source)) {
        errors.push('render vertex: missing uv location 0');
    }
    return errors;
}

function validateFragmentInterface(source, entryPoint) {
    const result = validateWgslModuleSignatures(source, {
        requiredEntryPoints: [entryPoint],
        label: 'render fragment',
    });
    const errors = [...result.errors];
    if (!new RegExp(`fn\\s+${entryPoint}\\s*\\([^)]*${SHARED_INTERFACE}`).test(source)) {
        errors.push(`render fragment: ${entryPoint} must consume ${SHARED_INTERFACE}`);
    }
    if (!/@location\(0\)/.test(source)) errors.push('render fragment: missing output location 0');
    return errors;
}

function extractStruct(source, name) {
    return source.match(new RegExp(`struct\\s+${name}\\s*\\{([\\s\\S]*?)\\}`))?.[1]
        ?.replace(/\s+/g, ' ').trim() || null;
}

export function assembleRenderWgslModules({
    vertex,
    fragment,
    prelude = '',
    vertexEntryPoint = DEFAULT_VERTEX_ENTRY,
    fragmentEntryPoint = DEFAULT_FRAGMENT_ENTRY,
    hostBindings = [],
} = {}) {
    if (!vertex?.trim()) throw new Error('Render WGSL vertex source is empty.');
    if (!fragment?.trim()) throw new Error('Render WGSL fragment source is empty.');

    const errors = [
        ...validateVertexInterface(vertex, vertexEntryPoint),
        ...validateFragmentInterface(fragment, fragmentEntryPoint),
    ];
    const vertexInterface = extractStruct(vertex, SHARED_INTERFACE);
    const fragmentInterface = extractStruct(fragment, SHARED_INTERFACE);
    if (vertexInterface !== fragmentInterface) {
        errors.push(`render stages: ${SHARED_INTERFACE} vertex/fragment interfaces are incompatible`);
    }
    const vertexNames = validateWgslModuleSignatures(vertex, { label: 'render vertex' }).names;
    const fragmentNames = validateWgslModuleSignatures(fragment, { label: 'render fragment' }).names;
    for (const name of vertexNames) {
        if (fragmentNames.has(name) && name !== SHARED_INTERFACE) {
            errors.push(`Render WGSL declaration collision: ${name} (vertex and fragment)`);
        }
    }
    const bindings = new Map();
    for (const [key, owner] of collectBindings(prelude, 'render prelude')) bindings.set(key, owner);
    for (const [key, owner] of collectBindings(fragment, 'render fragment')) {
        if (bindings.has(key)) errors.push(`Render WGSL duplicate binding ${key} (${bindings.get(key)} and ${owner})`);
        else bindings.set(key, owner);
    }
    for (const binding of hostBindings) {
        const key = `${binding.group}/${binding.binding}`;
        if (bindings.has(key)) errors.push(`Render WGSL host binding collision ${key}`);
        bindings.set(key, 'host contract');
    }

    const combined = [prelude, vertex, fragment].map(source => source.trim()).filter(Boolean).join('\n\n');
    const combinedValidation = validateWgslModuleSignatures(combined, {
        requiredEntryPoints: [vertexEntryPoint, fragmentEntryPoint],
        label: 'assembled render WGSL',
    });
    errors.push(...combinedValidation.errors);
    if (errors.length) {
        const error = new Error(errors.join('\n'));
        error.code = 'MTLX_RENDER_WGSL_ASSEMBLY_INVALID';
        error.errors = errors;
        throw error;
    }
    return {
        source: combined,
        entryPoints: combinedValidation.entryPoints,
        bindings: [...bindings.keys()],
        vertexEntryPoint,
        fragmentEntryPoint,
    };
}
