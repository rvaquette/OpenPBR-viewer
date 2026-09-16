#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { assembleWgslModules, createMaterialWgslBridge, validateHostBindings } from '../src/webgpu/wgslModuleAssembler.js';

const contract = JSON.parse(readFileSync('public/mtlx/wgsl-host-contract.json', 'utf8'));
const prelude = `struct FrameUniforms { width: u32, height: u32, frameIndex: u32, debugMode: u32, nodeCount: u32, triangleCount: u32, lightCount: u32, padding: u32 }\n@group(0) @binding(0) var outputTexture: texture_storage_2d<rgba16float, write>;`;
const integrator = 'fn integrate() -> vec3<f32> { return vec3<f32>(0.0); }';
const material = '@fragment fn main() -> @location(0) vec4<f32> { return vec4<f32>(integrate(), 1.0); }';
const assembled = assembleWgslModules({ prelude, integrator, material, requiredEntryPoints: ['main'] });
const bindingResult = validateHostBindings(assembled.source, contract.bindings.slice(0, 1));
assert.equal(bindingResult.pass, true);
assert.ok(assembled.entryPoints.includes('main'));
const bridged = createMaterialWgslBridge(`
struct Basis { normal: vec3<f32> }
struct Volume { extinction: vec3<f32>, albedo: vec3<f32>, anisotropy: f32 }
fn mtlxMaterialLibrary_1() {}
fn mtlxGenEvaluateBsdf_u0028_test() -> vec3<f32> { return vec3<f32>(1.0); }
fn mtlxGenSampleBsdf_u0028_test() -> vec3<f32> { return vec3<f32>(1.0); }
`);
assert.equal((bridged.match(/mtlxMaterialLibrary_1\(\);/g) || []).length, 2);
assert.match(bridged, /fn mtlxGenEvaluateBsdf\(/);
assert.match(bridged, /fn mtlxGenSampleBsdf\(/);
console.log(JSON.stringify({ pass: true, entryPoints: assembled.entryPoints, bindingCount: contract.bindings.length, materialInitializationCalls: 2 }, null, 2));
