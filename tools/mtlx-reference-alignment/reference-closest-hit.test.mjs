import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const sourcePath = resolve('glsl/pathtracing/mtlx/reference/closest_hit.glsl');
const anyHitSourcePath = resolve('glsl/pathtracing/mtlx/reference/anyhit.glsl');
const glslSourcesPath = resolve('glsl-sources.js');
const expectedSha256 = '864af40b7f85ae4f08c4207231c286c816f41805552f3d183543b17ef329b70b';
const expectedAnyHitSha256 = 'e4ff7cdd408cb550ebddd4e8d4baacc33bd2efdda8b906e2ff3bf7ca9cde915d';

test('closest-hit source stays byte-identical to the pinned MIT upstream and is exported as raw GLSL', () => {
    const source = readFileSync(sourcePath);
    const hash = createHash('sha256').update(source).digest('hex');
    const glslSources = readFileSync(glslSourcesPath, 'utf8');
    assert.equal(hash, expectedSha256);
    assert.match(source.toString('utf8'), /Copyright\(c\) 2019 Asif Ali/);
    assert.match(glslSources, /import glsl_mtlx_reference_closest_hit from '\.\/glsl\/pathtracing\/mtlx\/reference\/closest_hit\.glsl\?raw';/);
    assert.match(glslSources, /\bglsl_mtlx_reference_closest_hit,/);
});

test('any-hit source stays byte-identical to the pinned MIT upstream and is exported as raw GLSL', () => {
    const source = readFileSync(anyHitSourcePath);
    const hash = createHash('sha256').update(source).digest('hex');
    const glslSources = readFileSync(glslSourcesPath, 'utf8');
    assert.equal(hash, expectedAnyHitSha256);
    assert.match(source.toString('utf8'), /Copyright\(c\) 2019 Asif Ali/);
    assert.match(glslSources, /import glsl_mtlx_reference_any_hit from '\.\/glsl\/pathtracing\/mtlx\/reference\/anyhit\.glsl\?raw';/);
    assert.match(glslSources, /\bglsl_mtlx_reference_any_hit,/);
});