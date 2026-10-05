import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';
import sharp from 'sharp';
import { corpus, root, inspectImage } from './run.mjs';

const directories = process.argv.slice(2).map((directory) => resolve(root, directory));
assert.ok(directories.length > 0, 'Provide capture directories');
const baselineRoot = dirname(directories[0]);
const output = join(baselineRoot, 'baseline-manifest.json');
assert.ok(!existsSync(output), 'Frozen manifest already exists; use a new baseline root');
const hash = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');
const captures = new Map();
const anomalies = [];
for (const directory of directories) {
    const reportFile = join(directory, 'report.json');
    const report = JSON.parse(readFileSync(reportFile, 'utf8'));
    assert.equal(report.profile, 'baseline');
    for (const result of report.results) {
        if (result.status !== 'PASS') { anomalies.push({ id: result.id, error: result.error, report: relative(root, reportFile) }); continue; }
        assert.ok(!captures.has(result.id), `Duplicate successful capture: ${result.id}`);
        captures.set(result.id, { result, directory, reportFile });
    }
}

const results = [];
for (const entry of corpus.cases) {
    const capture = captures.get(entry.id);
    assert.ok(capture, `Missing baseline: ${entry.id}`);
    const { result, directory, reportFile } = capture;
    assert.equal(result.target, entry.target);
    const caseRoot = join(directory, entry.id);
    const image = join(caseRoot, 'image.png');
    const viewer = JSON.parse(readFileSync(join(caseRoot, 'viewer.json'), 'utf8'));
    if (entry.target === 'local') {
        assert.equal(viewer.observed.samples, 128);
        assert.equal(viewer.observed.gpu.app.rendererMode, 'Pathtracer MTLX');
        assert.equal(viewer.observed.gpu.app.scene, entry.scene);
        assert.equal(viewer.denoiseEnabled, false);
        assert.equal(viewer.useGpu, false);
        assert.deepEqual(viewer.browserErrors, []);
        assert.ok(Object.keys(viewer.observed.uniforms).length > 0, 'Missing uniforms');
        if (entry.material) {
            assert.equal(new URL(viewer.url).searchParams.get('mtlx_url'), `/${entry.material}`);
            assert.equal(result.materialSha256, hash(join(root, 'public', entry.material)));
        }
        assert.ok(existsSync(join(caseRoot, 'glsl/wasm-generated-dispatch.glsl')));
    } else {
        assert.equal(viewer.mode, 'Pathtracer non-MTLX');
        assert.ok(viewer.observed.samples >= 128);
        assert.equal(viewer.observed.reachedTarget, true);
        assert.deepEqual(viewer.observed.jsErrors, []);
        assert.match(viewer.observed.renderer, /SwiftShader/i);
        assert.ok(existsSync(join(caseRoot, 'glsl/compiled_fragment_full.glsl')));
    }
    results.push({ id: entry.id, target: entry.target, scene: entry.scene, material: entry.material || null,
        tags: entry.tags, directory: relative(root, caseRoot).replaceAll('\\', '/'),
        report: relative(root, reportFile).replaceAll('\\', '/'), imageSha256: hash(image),
        viewerSha256: hash(join(caseRoot, 'viewer.json')), durationMs: result.durationMs,
        pixelStats: await inspectImage(image, [256, 256], entry.expectedColor) });
}
assert.equal(captures.size, corpus.cases.length);
const columns = 5;
const cellWidth = 160;
const cellHeight = 184;
const tiles = [];
for (const [index, entry] of results.entries()) {
    const left = (index % columns) * cellWidth;
    const top = Math.floor(index / columns) * cellHeight;
    const image = await sharp(join(root, entry.directory, 'image.png')).resize(160, 160).png().toBuffer();
    const label = Buffer.from(`<svg width="160" height="24"><rect width="160" height="24" fill="white"/><text x="4" y="16" font-family="monospace" font-size="11">${entry.id}</text></svg>`);
    tiles.push({ input: image, left, top }, { input: label, left, top: top + 160 });
}
const contactSheet = join(baselineRoot, 'baseline-contact-sheet.png');
await sharp({ create: { width: columns * cellWidth, height: Math.ceil(results.length / columns) * cellHeight,
    channels: 3, background: 'white' } }).composite(tiles).png().toFile(contactSheet);
const manifest = { version: 1, frozenAt: new Date().toISOString(), corpusSha256: hash(join(root, 'tools/mtlx-reference-alignment/corpus.json')),
    status: 'PASS-render-capture', resolution: [256, 256], samples: 128, denoise: false,
    counts: { local: results.filter((entry) => entry.target === 'local').length, reference: results.filter((entry) => entry.target === 'reference').length },
    localOracle: 'local-before-migration', referenceOracle: 'non-MTLX-geometry-camera-lights-only',
    contactSheet: relative(root, contactSheet).replaceAll('\\', '/'),
    performance: { measuredMaxCaptureMs: Math.max(...results.map((entry) => entry.durationMs)),
        captureTimeoutMs: corpus.defaults.timeoutMs,
        proposedPerCaseBudgetMs: Object.fromEntries(results.map((entry) => [entry.id, Math.ceil(entry.durationMs * 1.25)])) },
    pending: ['manual-corpus-review'],
    deferredByUser: { date: '2026-10-05', targetStages: [14, 15],
        checks: ['linear-HDR-low-SPP-denoiser-input-and-denoised-output'] },
    repeatability: { case: 'disney-gold', resolution: [256, 256], samples: 128,
        reference: 't004-20261005-colors/disney-gold/image.png', repeat: 't004-20261005-repeatability/disney-gold/image.png' },
    anomalies, results };
writeFileSync(output, `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`PASS capture freeze: ${results.length} images; manifest: ${output}; listed pending checks are not waived.`);