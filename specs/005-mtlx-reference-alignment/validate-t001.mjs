import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const referenceRoot = resolve(process.argv[2] || 'D:/WebGL2/GLSL-PathTracer-JS');
const localRoot = fileURLToPath(new URL('../../', import.meta.url));
const report = readFileSync(new URL('./research-t001.md', import.meta.url), 'utf8');
const readReference = (relativePath) => readFileSync(join(referenceRoot, relativePath), 'utf8');
const getHead = (root) => execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
const sources = [...report.matchAll(/^\| ([^|]+?) \| ([a-f0-9]{64}) \|\r?$/gm)];

assert.equal(sources.length, 12, 'Expected 12 pinned source hashes');
for (const [, relativePath, expectedHash] of sources) {
    const hash = createHash('sha256').update(readFileSync(join(referenceRoot, relativePath))).digest('hex');
    assert.equal(hash, expectedHash, relativePath);
}
for (const root of [localRoot, referenceRoot, join(referenceRoot, 'scenes')]) {
    assert.ok(report.includes(getHead(root)), `Revision changed: ${root}`);
}

assert.match(readReference('src/core/mesh.ts'), /new SplitBvh\(2\.0, 64, 0, 0\.001, 0\)/);
assert.match(readReference('src/core/pathtracer/pathtracerScene.ts'), /new Bvh\(10\.0, 64, false\)/);
const renderer = readReference('src/core/renderer.ts');
for (const format of ['RGB32F', 'RGBA32F', 'RGB32I', 'RGBA32I']) {
    assert.ok(renderer.includes(format), `Missing format: ${format}`);
}

function listFiles(directory) {
    return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
        if (entry.name === '.git') return [];
        const fullPath = join(directory, entry.name);
        return entry.isDirectory() ? listFiles(fullPath) : [fullPath];
    });
}

const scenes = listFiles(join(referenceRoot, 'scenes')).filter((file) => file.endsWith('.scene'));
assert.equal(scenes.length, 59, 'Scene corpus count changed');
const sceneTexts = scenes.map((file) => readFileSync(file, 'utf8'));
const directiveCounts = {
    camera: 59,
    renderer: 59,
    mesh: 56,
    gltf: 3,
    light: 38,
    materialx_document: 14,
    materialx_inline_begin: 0,
};
for (const [directive, expectedCount] of Object.entries(directiveCounts)) {
    const pattern = new RegExp(`^\\s*${directive}(?:\\s|$)`, 'm');
    assert.equal(sceneTexts.filter((text) => pattern.test(text)).length, expectedCount, directive);
}

assert.match(readReference('LICENSES/OpenPBR-viewer-rva-MIT.txt'), /MIT License/);
for (const source of ['closest_hit.glsl', 'anyhit.glsl']) {
    assert.match(readReference(`shaders/common/${source}`), /Copyright\(c\) 2019 Asif Ali/);
}
assert.match(readReference('src/external/denoiser/denoiser.js'), /Apache License, Version 2\.0/);
console.log('PASS T001: 12 hashes, 3 revisions, BLAS/TLAS, GPU formats, 59 scenes and license notices. No renderer executed.');