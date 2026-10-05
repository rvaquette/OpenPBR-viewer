import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const referenceRoot = resolve(process.argv[2] || 'D:/WebGL2/GLSL-PathTracer-JS');
const cppRoot = resolve(process.argv[3] || 'D:/WebGL2/GLSL-PathTracer');
const destination = join(root, 'src/bvh/reference');
const sources = {
    'bvh/bbox.ts': '7800495505574207fa6f379aaf05436cc2bbfa6e36b1187c92bd628983d30214',
    'bvh/bvh.ts': '69c1098ec447e321a4acda04f7f2a80254d1b12098868557eb9a84e02a8a0cc3',
    'bvh/splitBvh.ts': 'b2ce6a9a313b75a446881089790c12b345be69cd0aad50762f85091bf025b08d',
    'bvh/bvhTranslator.ts': '1e74bbc9ccca4ab324b826553d768815913e84008c2ec5775caf423277e9e49f',
    'math/vec3.ts': '0e8e2b761f9ff63f020eeae89698d1d6c3a20cdbba361c70e56f6f77a82f685f',
    'math/vec4.ts': '77b020512143e2286c7a21de4bacd8144e8c5bdcef349645540add3fa64be420',
};
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
const records = [];
const copies = [];
for (const [file, expectedHash] of Object.entries(sources)) {
    const bytes = readFileSync(join(referenceRoot, 'src', file));
    assert.equal(hash(bytes), expectedHash, `Source changed: ${file}`);
    const adapted = file === 'bvh/bvhTranslator.ts';
    const content = adapted
        ? Buffer.from(bytes.toString('utf8').replace('import { Mesh, MeshInstance } from "../core/mesh.js";', 'import type { Mesh, MeshInstance } from "../core/mesh.js";'))
        : bytes;
    const target = join(destination, file);
    if (existsSync(target)) assert.equal(hash(readFileSync(target)), hash(content), `Refusing to overwrite changes: ${target}`);
    copies.push({ target, content });
    records.push({ source: `src/${file}`, target: file, sourceSha256: expectedHash, localSha256: hash(content),
        adaptation: adapted ? 'mesh-import-type-only' : 'none' });
}
const provenance = JSON.parse(readFileSync(join(root, 'specs/005-mtlx-reference-alignment/bvh-provenance.json'), 'utf8'));
const headerBytes = readFileSync(join(cppRoot, 'thirdparty/RadeonRays/bvh.h'));
assert.equal(hash(headerBytes), provenance.cppSourceHashes['thirdparty/RadeonRays/bvh.h']);
const amdNotice = headerBytes.toString('utf8').match(/^\/\*[\s\S]*?\*\//)?.[0];
assert.ok(amdNotice?.includes('2016 Advanced Micro Devices'));
const asifNotice = readFileSync(join(cppRoot, 'LICENSE'), 'utf8');
assert.match(asifNotice, /MIT License[\s\S]*2019 Asif Ali/);
const notice = `${amdNotice}\n\n${asifNotice}`;
const manifest = { version: 1, task: 'T005', referenceRoot, referenceRevision:
    execFileSync('git', ['-C', referenceRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(),
    files: records, algorithmChanges: false, backendActivated: false,
    typeBoundary: 'core/mesh.ts defines only the fields consumed by BvhTranslator',
    notices: { file: 'UPSTREAM-NOTICES.txt', sha256: hash(Buffer.from(notice)), sourceCppRevision: provenance.cppRepositoryRevision } };
const writes = [...copies, { target: join(destination, 'UPSTREAM-NOTICES.txt'), content: Buffer.from(notice) },
    { target: join(destination, 'SOURCES.json'), content: Buffer.from(`${JSON.stringify(manifest, null, 2)}\n`) }];
for (const { target, content } of writes) {
    if (existsSync(target)) assert.equal(hash(readFileSync(target)), hash(content), `Refusing to overwrite changes: ${target}`);
}
for (const { target, content } of writes) {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
}
console.log('PASS import T005: 6 pinned TS sources, type-only mesh boundary and retained AMD/Asif MIT notices; no backend activated.');