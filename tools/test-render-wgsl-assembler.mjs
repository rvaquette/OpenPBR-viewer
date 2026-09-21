#!/usr/bin/env node
import assert from 'node:assert/strict';
import { FULLSCREEN_TRIANGLE_WGSL } from '../src/webgpu/fullscreenTriangle.wgsl.js';
import { assembleRenderWgslModules } from '../src/webgpu/renderWgslModuleAssembler.js';

const fragment = `
struct FullscreenVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@fragment
fn fragmentMain(input: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(input.uv, 0.0, 1.0);
}
`;
const assembled = assembleRenderWgslModules({
    vertex: FULLSCREEN_TRIANGLE_WGSL,
    fragment,
    fragmentEntryPoint: 'fragmentMain',
});
assert.equal(assembled.vertexEntryPoint, 'fullscreenTriangleVertex');
assert.equal(assembled.fragmentEntryPoint, 'fragmentMain');
assert.ok(assembled.source.includes('@vertex'));
assert.ok(assembled.source.includes('@fragment'));
assert.throws(() => assembleRenderWgslModules({
    vertex: FULLSCREEN_TRIANGLE_WGSL,
    fragment,
    prelude: '@group(0) @binding(0) var hostTexture: texture_2d<f32>;',
    hostBindings: [{ group: 0, binding: 0 }],
}), /host binding collision/);
assert.throws(() => assembleRenderWgslModules({
    vertex: FULLSCREEN_TRIANGLE_WGSL,
    fragment: `${fragment}\nconst fullscreenTriangleVertex: f32 = 1.0;`,
    fragmentEntryPoint: 'fragmentMain',
}), /declaration collision/);
assert.throws(() => assembleRenderWgslModules({
    vertex: FULLSCREEN_TRIANGLE_WGSL,
    fragment: fragment.replace('uv: vec2<f32>', 'uv: vec3<f32>'),
    fragmentEntryPoint: 'fragmentMain',
}), /interfaces are incompatible/);
assert.throws(() => assembleRenderWgslModules({
    vertex: FULLSCREEN_TRIANGLE_WGSL,
    fragment: fragment.replace('fragmentMain', 'differentFragment'),
}), /missing entry point/);
console.log(JSON.stringify({ pass: true, entryPoints: assembled.entryPoints, bindings: assembled.bindings }, null, 2));
