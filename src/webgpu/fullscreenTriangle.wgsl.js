// Fullscreen triangle shared by the WebGPU render path vertex stage.
export const FULLSCREEN_TRIANGLE_WGSL = /* wgsl */ `
struct FullscreenVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn fullscreenTriangleVertex(@builtin(vertex_index) index: u32) -> FullscreenVertexOutput {
    let positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -3.0),
        vec2<f32>(3.0, 1.0),
        vec2<f32>(-1.0, 1.0),
    );
    var output: FullscreenVertexOutput;
    output.position = vec4<f32>(positions[index], 0.0, 1.0);
    output.uv = output.position.xy * vec2<f32>(0.5, -0.5) + vec2<f32>(0.5);
    return output;
}
`;

export const FULLSCREEN_TRIANGLE_VERTEX_ENTRY_POINT = 'fullscreenTriangleVertex';
export const FULLSCREEN_TRIANGLE_FRAGMENT_INPUT = 'FullscreenVertexOutput';
