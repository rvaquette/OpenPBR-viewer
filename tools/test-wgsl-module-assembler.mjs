#!/usr/bin/env node
import assert from 'node:assert/strict';
import { assembleWgslModules } from '../src/webgpu/wgslModuleAssembler.js';

const assembled = assembleWgslModules({
    prelude: 'struct Shared { value: f32, }',
    integrator: 'fn integrate() -> f32 { return 1.0; }',
    material: '@compute @workgroup_size(1) fn main() {}',
    requiredEntryPoints: ['main'],
});
assert.match(assembled.source, /struct Shared/);
assert.ok(assembled.entryPoints.includes('main'));
assert.throws(() => assembleWgslModules({
    prelude: 'struct Collision { value: f32, }',
    integrator: 'struct Collision { other: f32, }',
}), /WGSL declaration collision: Collision/);
console.log(JSON.stringify({ pass: true, declarations: assembled.declarations, entryPoints: assembled.entryPoints }, null, 2));
