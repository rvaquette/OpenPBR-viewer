// Minimum WebGPU adapter/device limits required by the MTLX path tracer compute pipeline.
// Counts reflect the group(0) bindings declared in WebGpuRenderer's compute shader:
// 1 storage texture, 4 uniform buffers (frame/camera/lighting/MaterialX private),
// 5 storage buffers/atomics, 5 sampled textures and 4 samplers before authored
// MaterialX file textures are added at bindings 20+.
export const REQUIRED_ADAPTER_LIMITS = Object.freeze({
    maxBindGroups: 1,
    maxBindingsPerBindGroup: 20,
    maxStorageBuffersPerShaderStage: 5,
    maxUniformBuffersPerShaderStage: 4,
    maxSampledTexturesPerShaderStage: 5,
    maxSamplersPerShaderStage: 4,
    maxStorageTexturesPerShaderStage: 1,
});

/**
 * Validates that a requested/available adapter reports limits sufficient for the
 * path tracer compute pipeline. Throws an explicit, actionable error rather than
 * letting pipeline creation fail later with an opaque WebGPU validation error.
 */
export function validateAdapterLimits(adapter) {
    if (!adapter) throw new Error('WebGPU adapter limits validation failed: no adapter was provided.');
    const limits = adapter.limits;
    const missing = [];
    for (const [name, required] of Object.entries(REQUIRED_ADAPTER_LIMITS)) {
        const actual = limits?.[name];
        if (typeof actual !== 'number' || actual < required) {
            missing.push(`${name} (required >= ${required}, adapter reports ${actual})`);
        }
    }
    if (missing.length) {
        throw new Error(`WebGPU adapter does not meet the limits required by the Pathtracer MTLX compute pipeline: ${missing.join(', ')}`);
    }
    return limits;
}

export function validateMaterialTextureLimits(adapter, manifest = []) {
    if (!adapter?.limits) throw new Error('WebGPU MaterialX texture limit validation failed: adapter limits are unavailable.');
    const limits = adapter.limits;
    const groupCount = 1;
    const bindingCount = 20 + manifest.reduce((count, entry) => count + (entry?.texture && entry?.sampler ? 2 : 0), 0);
    const textureCount = 5 + manifest.length;
    const samplerCount = 4 + manifest.length;
    const failures = [];
    if (groupCount > limits.maxBindGroups) failures.push(`maxBindGroups (required >= ${groupCount}, adapter reports ${limits.maxBindGroups})`);
    if (bindingCount > limits.maxBindingsPerBindGroup) failures.push(`maxBindingsPerBindGroup (required >= ${bindingCount}, adapter reports ${limits.maxBindingsPerBindGroup})`);
    if (textureCount > limits.maxSampledTexturesPerShaderStage) failures.push(`maxSampledTexturesPerShaderStage (required >= ${textureCount}, adapter reports ${limits.maxSampledTexturesPerShaderStage})`);
    if (samplerCount > limits.maxSamplersPerShaderStage) failures.push(`maxSamplersPerShaderStage (required >= ${samplerCount}, adapter reports ${limits.maxSamplersPerShaderStage})`);
    if (failures.length) {
        const error = new Error(`WebGPU adapter limits are insufficient for the MaterialX texture manifest: ${failures.join(', ')}. Reduce texture resources or use an adapter with higher limits.`);
        error.code = 'MTLX_WGSL_LIMIT_EXCEEDED';
        throw error;
    }
    return { groupCount, bindingCount, textureCount, samplerCount };
}
