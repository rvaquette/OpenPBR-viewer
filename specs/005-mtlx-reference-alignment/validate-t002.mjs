import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';
import './validate-t001.mjs';

const referenceRoot = resolve(process.argv[2] || 'D:/WebGL2/GLSL-PathTracer-JS');
const table = JSON.parse(readFileSync(new URL('./scene-directives.json', import.meta.url), 'utf8'));
const contract = readFileSync(new URL('./contracts-t002.md', import.meta.url), 'utf8');
const loader = readFileSync(join(referenceRoot, 'src/core/pathtracer/loaders/sceneLoader.ts'), 'utf8');
const decisions = new Set();
for (const [block, statuses] of Object.entries(table.blocks)) {
    const tokens = new Set();
    for (const status of ['supported', 'adapted', 'rejected']) {
        assert.ok(Array.isArray(statuses[status]), `${block}.${status}`);
        for (const token of statuses[status]) {
            assert.ok(!tokens.has(token), `${block}: duplicate decision for ${token}`);
            tokens.add(token);
            decisions.add(token);
        }
    }
}
const sourceTokens = new Set([...loader.matchAll(/\.split\(' '\)\[0\]\s*==\s*\('([^']+)'\)/g)].map((match) => match[1]));
sourceTokens.delete('#');
for (const token of sourceTokens) assert.ok(decisions.has(token), `Unclassified reference directive: ${token}`);
const blockStarts = [...loader.matchAll(/if \(line\.split\(' '\)\[0\] == \('(material|light|camera|renderer|mesh|gltf)'\)\)/g)];
assert.equal(blockStarts.length, 6);
for (const [index, match] of blockStarts.entries()) {
    const source = loader.slice(match.index, blockStarts[index + 1]?.index || loader.length);
    const block = match[1];
    const tokens = new Set(Object.values(table.blocks[block]).flat());
    for (const directive of source.matchAll(/l\.split\(' '\)\[0\]\s*==\s*\('([^']+)'\)/g)) {
        assert.ok(tokens.has(directive[1]), `${block}: unclassified directive ${directive[1]}`);
    }
}
assert.equal(table.referenceFixtures.length, 3);
for (const fixture of table.referenceFixtures) {
    const bytes = readFileSync(join(referenceRoot, fixture.file));
    assert.equal(createHash('sha256').update(bytes).digest('hex'), fixture.sha256, fixture.file);
    assert.equal(fixture.mode, 'non-mtlx');
    assert.ok(!/^\s*materialx_(document|inline_begin)\b/m.test(bytes.toString('utf8')));
    const owner = fixture.file.slice(0, fixture.file.lastIndexOf('/'));
    for (const reference of bytes.toString('utf8').matchAll(/^\s*file\s+(.+)$/gm)) {
        assert.ok(statSync(join(referenceRoot, owner, reference[1].trim())).isFile());
    }
}
const denoiser = readFileSync(join(referenceRoot, 'src/external/denoiser/denoiser.js'), 'utf8');
assert.ok(denoiser.includes(table.denoiser.referenceDefaultWeightsUrl));
assert.equal(table.denoiser.collection, 'rt_hdr_small');
assert.equal(table.denoiser.hdr, true);
assert.equal(table.denoiser.srgb, false);
const weightSourceRoot = resolve(process.argv[3] || table.denoiser.sourceRepositoryRoot);
const sourceRevision = execFileSync('git', ['-C', weightSourceRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
assert.equal(sourceRevision, table.denoiser.sourceRepositoryRevision);
const sourceFiles = [
    ['packages/denoiser/package.json', table.denoiser.sourcePackageJsonSha256],
    [join(table.denoiser.sourceWeightsDirectory, table.denoiser.weightFile), table.denoiser.sourceWeightSha256],
    [join(table.denoiser.sourceWeightsDirectory, 'rt_ldr_small.tza'), table.denoiser.sourceLdrWeightSha256],
    [table.denoiser.sourceWeightLicensePath, table.denoiser.sourceWeightLicenseSha256],
    [table.denoiser.sourcePackageLicensePath, table.denoiser.sourcePackageLicenseSha256],
];
for (const [file, expectedHash] of sourceFiles) {
    const bytes = readFileSync(join(weightSourceRoot, file));
    assert.equal(createHash('sha256').update(bytes).digest('hex'), expectedHash, file);
    assert.ok(!bytes.subarray(0,80).toString('utf8').startsWith('version https://git-lfs.github.com/spec/v1'));
}
const weightBytes = readFileSync(join(weightSourceRoot, table.denoiser.sourceWeightsDirectory, table.denoiser.weightFile));
assert.equal(weightBytes.length, table.denoiser.sourceWeightBytes);
assert.equal(readdirSync(join(weightSourceRoot, table.denoiser.sourceWeightsDirectory)).filter((file) => file.endsWith('.tza')).length, table.denoiser.sourceWeightsCount);
assert.equal(JSON.parse(readFileSync(join(weightSourceRoot, 'packages/denoiser/package.json'), 'utf8')).version, table.denoiser.sourcePackageVersion);
assert.match(readFileSync(join(weightSourceRoot, table.denoiser.sourceWeightLicensePath), 'utf8'), /Apache License[\s\S]*Version 2\.0/);
assert.match(readFileSync(join(weightSourceRoot, table.denoiser.sourcePackageLicensePath), 'utf8'), /MIT License/);
for (const file of ['tile.glsl', 'preview.glsl']) {
    const shader = readFileSync(join(referenceRoot, 'shaders', file), 'utf8');
    assert.ok(shader.includes('d.y *= resolution.y / resolution.x * scale;'));
    assert.ok(shader.includes('float cam_r2 = rand() * camera.aperture;'));
    assert.ok(shader.includes('sqrt(cam_r2)'));
}
assert.equal(table.policies.materialx, 'local-generator-only');
assert.equal(table.policies.renderer, 'non-mtlx-only-for-reference-execution');
assert.match(contract, /Jalon 0 : COMPLETED/);
assert.match(contract, /Cloture demandee explicitement par l'utilisateur/);
for (const file of ['checkpoints/tasks-to-impl.yaml', 'checkpoints/spec-to-plan.yaml', 'batch-report.yaml']) {
    const metadata = readFileSync(new URL(`./${file}`, import.meta.url), 'utf8');
    assert.match(metadata, /^stage_0_status: completed\r?$/m, file);
    assert.match(metadata, /^stage_0_acceptance: explicit-user-decision-2026-10-04\r?$/m, file);
}
assert.ok(!/[^\x00-\x7f]/.test(contract), 'Contracts must remain ASCII');
assert.ok(table.blocks.material.rejected.includes('specular'));
for (let index = 1; index <= 8; index++) {
    assert.ok(contract.includes(`REQ-${String(index).padStart(3, '0')}`));
    assert.ok(contract.includes(`C${String(index).padStart(2, '0')}`));
}
for (const invariant of ['RGB32I', 'pSelect=1/N', 'hdr=true, srgb=false', 'SCENE_MATERIAL_UNBOUND', 'mtlxLightsTex']) {
    assert.ok(contract.includes(invariant), `Missing invariant: ${invariant}`);
}
console.log(`PASS T002 documentation: ${sourceTokens.size} tokens classified by block; 8 contracts; 3 non-MTLX fixtures; camera; local HDR/LDR weight hashes and MIT/Apache notices. Remaining provenance and runtime gates not implied.`);