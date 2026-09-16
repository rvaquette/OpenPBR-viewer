export const MTLX_WGSL_ERROR_CODES = Object.freeze({
    dispatch: 'MTLX_WGSL_DISPATCH_INVALID',
    closure: 'MTLX_WGSL_CLOSURE_UNSUPPORTED',
    texture: 'MTLX_WGSL_TEXTURE_INVALID',
    signature: 'MTLX_WGSL_SIGNATURE_INVALID',
    limits: 'MTLX_WGSL_LIMIT_EXCEEDED',
    compile: 'MTLX_WGSL_COMPILE_FAILED',
    transpile: 'MTLX_WGSL_TRANSPILE_FAILED',
    unavailable: 'MTLX_WGSL_BACKEND_UNAVAILABLE',
});

export function classifyMtlxWgslError(error) {
    const message = String(error?.message || error || 'Unknown WebGPU MaterialX error');
    if (error?.code && Object.values(MTLX_WGSL_ERROR_CODES).includes(error.code)) return error.code;
    if (/texture|sampler|dimension|fetch/i.test(message)) return MTLX_WGSL_ERROR_CODES.texture;
    if (/limit|binding|bind group/i.test(message)) return MTLX_WGSL_ERROR_CODES.limits;
    if (/closure|unsupported model/i.test(message)) return MTLX_WGSL_ERROR_CODES.closure;
    if (/signature|entry point/i.test(message)) return MTLX_WGSL_ERROR_CODES.signature;
    if (/compile|shader module|WGSL/i.test(message)) return MTLX_WGSL_ERROR_CODES.compile;
    if (/transpil|SPIR-V|glslang|naga/i.test(message)) return MTLX_WGSL_ERROR_CODES.transpile;
    return MTLX_WGSL_ERROR_CODES.dispatch;
}

export function formatMtlxWgslError(error) {
    const code = classifyMtlxWgslError(error);
    const message = String(error?.message || error || 'Unknown WebGPU MaterialX error');
    return `[${code}] ${message}`;
}
