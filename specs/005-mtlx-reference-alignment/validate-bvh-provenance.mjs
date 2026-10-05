import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import './validate-t001.mjs';

const evidence = JSON.parse(readFileSync(new URL('./bvh-provenance.json', import.meta.url), 'utf8'));
const tsRoot = resolve(process.argv[2] || 'D:/WebGL2/GLSL-PathTracer-JS');
const cppRoot = resolve(process.argv[3] || evidence.cppRepositoryRoot);
const revision = execFileSync('git', ['-C', cppRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
assert.equal(revision, evidence.cppRepositoryRevision);
assert.equal(evidence.upstreamLicense, 'MIT');
assert.equal(evidence.mappings.length, 4);
assert.equal(Object.keys(evidence.cppSourceHashes).length, 8);
for (const [file, expectedHash] of Object.entries(evidence.cppSourceHashes)) {
    const bytes = readFileSync(join(cppRoot, file));
    assert.equal(createHash('sha256').update(bytes).digest('hex'), expectedHash, file);
    const source = bytes.toString('utf8');
    assert.ok(source.includes('2016 Advanced Micro Devices'), file);
    assert.ok(source.includes('Permission is hereby granted, free of charge'), file);
    assert.ok(source.includes('The above copyright notice and this permission notice shall be included'), file);
}
for (const mapping of evidence.mappings) {
    assert.ok(readFileSync(join(tsRoot, mapping.ts), 'utf8').length > 0);
    for (const file of mapping.cpp) assert.ok(file in evidence.cppSourceHashes);
}
const cppTranslator = readFileSync(join(cppRoot, 'thirdparty/RadeonRays/bvh_translator.cpp'), 'utf8');
const tsTranslator = readFileSync(join(tsRoot, 'src/bvh/bvhTranslator.ts'), 'utf8');
assert.ok(cppTranslator.includes(evidence.radeonRaysOriginalUrl));
assert.ok(cppTranslator.includes('curTriIndex + node->startidx'));
assert.ok(tsTranslator.includes('this.curTriIndex + node.startidx'));
assert.ok(cppTranslator.includes('LRLeaf.z = -instanceIndex - 1'));
assert.ok(tsTranslator.includes('LRLeaf.z = -instanceIndex - 1'));
assert.match(readFileSync(join(cppRoot, 'LICENSE'), 'utf8'), /MIT License[\s\S]*2019 Asif Ali/);
assert.equal(evidence.algorithmEquivalenceProven, false);
console.log('PASS BVH provenance: C++ revision, 8 AMD MIT headers/hashes and 4 TS correspondences; no algorithm-equivalence or asset-license claim.');