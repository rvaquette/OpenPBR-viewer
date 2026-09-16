export const GPU_LAYOUTS = Object.freeze({
    CameraUniforms: { size: 128, alignment: 16, fields: { worldMatrix: 0, inverseProjectionMatrix: 64 } },
    RenderUniforms: { size: 16, alignment: 16, fields: { width: 0, height: 4, frameIndex: 8, debugMode: 12 } },
    BvhNode: { size: 48, alignment: 16, fields: { minimum: 0, maximum: 16, metadata: 32 } },
    TriangleIndices: { size: 16, alignment: 16, fields: { indices: 0 } },
    VertexAttribute: { size: 16, alignment: 16, fields: { value: 0 } }
});

export const WGSL_LAYOUT_DECLARATIONS = /* wgsl */ `
struct CameraUniforms { worldMatrix: mat4x4<f32>, inverseProjectionMatrix: mat4x4<f32> }
struct RenderUniforms { width: u32, height: u32, frameIndex: u32, debugMode: u32 }
struct BvhNode { minimum: vec4<f32>, maximum: vec4<f32>, metadata: vec4<f32> }
struct TriangleIndices { indices: vec4<u32> }
struct VertexAttribute { value: vec4<f32> }
`;

export function assertGpuLayouts() {
    for (const [name, layout] of Object.entries(GPU_LAYOUTS)) {
        if (layout.size % layout.alignment !== 0) throw new Error(`${name} size is not aligned.`);
        for (const [field, offset] of Object.entries(layout.fields)) {
            if (offset % 4 !== 0 || offset >= layout.size) throw new Error(`${name}.${field} has an invalid offset.`);
        }
    }
    return true;
}