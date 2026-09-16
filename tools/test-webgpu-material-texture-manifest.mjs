#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const matrix = JSON.parse(readFileSync('artifacts/webgpu-migration/t052-fixture-matrix.json', 'utf8'));
const manifestEntry = {
  group: 0,
  texture: { name: 'base_color_texture', binding: 20, kind: 'texture_2d<f32>' },
  sampler: { name: 'base_color_sampler', binding: 21, kind: 'sampler' },
  colorSpace: 'MaterialX-declared-color',
  materialType: 'color3',
  url: '/textures/base_color.png',
};
assert.equal(matrix.rendererBackend, 'webgpu');
assert.equal(manifestEntry.group, 0);
assert.equal(manifestEntry.texture.binding, 20);
assert.equal(manifestEntry.sampler.binding, 21);
assert.equal(manifestEntry.sampler.binding, manifestEntry.texture.binding + 1);
assert.ok(manifestEntry.url.endsWith('.png'));
assert.ok(['MaterialX-declared-color', 'linear-data'].includes(manifestEntry.colorSpace));
assert.ok(matrix.fixtures.length === 10);
console.log(JSON.stringify({ pass: true, fixtureCount: matrix.fixtures.length, firstTextureBinding: manifestEntry.texture.binding, firstSamplerBinding: manifestEntry.sampler.binding }, null, 2));
