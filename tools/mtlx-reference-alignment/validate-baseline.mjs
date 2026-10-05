import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import sharp from 'sharp';
import { corpus, root } from './run.mjs';

const directory = join(root, 'artifacts/mtlx-reference-alignment/01-baseline');
const manifest = JSON.parse(readFileSync(join(directory, 'baseline-manifest.json'), 'utf8'));
const hash = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');
assert.equal(manifest.status, 'PASS-render-capture');
assert.deepEqual(manifest.counts, { local: 16, reference: 3 });
assert.equal(manifest.results.length, corpus.cases.length);
assert.equal(manifest.corpusSha256, hash(join(root, 'tools/mtlx-reference-alignment/corpus.json')));
for (const entry of corpus.cases) {
    const result = manifest.results.find((candidate) => candidate.id === entry.id);
    assert.ok(result, entry.id);
    const caseRoot = join(root, result.directory);
    assert.equal(hash(join(caseRoot, 'image.png')), result.imageSha256, entry.id);
    assert.equal(hash(join(caseRoot, 'viewer.json')), result.viewerSha256, entry.id);
    const viewer = JSON.parse(readFileSync(join(caseRoot, 'viewer.json'), 'utf8'));
    assert.ok(viewer.observed.samples >= 128);
    if (entry.target === 'reference') {
        assert.equal(viewer.status, 'PASS');
        assert.equal(viewer.mode, 'Pathtracer non-MTLX');
        assert.equal(viewer.observed.reachedTarget, true);
    } else {
        assert.equal(viewer.observed.gpu.app.rendererMode, 'Pathtracer MTLX');
        assert.ok(Object.keys(viewer.observed.uniforms).length > 0);
    }
}
const gold = manifest.results.find((entry) => entry.id === 'disney-gold');
const original = await sharp(join(root, gold.directory, 'image.png')).removeAlpha().raw().toBuffer();
const repeat = await sharp(join(directory, 't004-20261005-repeatability/disney-gold/image.png')).removeAlpha().raw().toBuffer();
assert.ok(original.equals(repeat), 'Gold repeatability changed');
assert.ok(existsSync(join(root, manifest.contactSheet)));
const review = readFileSync(join(root, 'specs/005-mtlx-reference-alignment/t004-baseline.md'), 'utf8');
assert.match(review, /Verdict : PASS/);
assert.match(review, /reporte[\s\S]*14-15/);
console.log('PASS T004 capture baseline: 19 pinned captures, 128 SPP, local uniforms, non-MTLX reference, gold repeatability and documented visual review.');