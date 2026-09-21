#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, relative, resolve } from 'node:path';

const root = process.cwd();
const inputPath = resolve(root, process.argv[2] || 'artifacts/webgpu-render-pathtracer/transpilation-report.json');
const outputRoot = resolve(root, process.argv[3] || 'public/mtlx/offline');

if (!existsSync(inputPath)) throw new Error(`Missing transpilation report: ${inputPath}`);
const report = JSON.parse(readFileSync(inputPath, 'utf8'));
const entries = [];

rmSync(outputRoot, { recursive: true, force: true });
for (const fixture of report.fixtures || []) {
    if (fixture.status !== 'transpiled' || !fixture.wgsl || !existsSync(fixture.wgsl)) {
        throw new Error(`WGSL fixture output unavailable: ${fixture.id}/${fixture.route}`);
    }
    const output = resolve(outputRoot, fixture.id, `${fixture.route}.wgsl`);
    mkdirSync(dirname(output), { recursive: true });
    writeFileSync(output, `// openpbr-offline-materialx-wgsl\n${readFileSync(fixture.wgsl, 'utf8')}`, 'utf8');
    entries.push({
        id: fixture.id,
        route: fixture.route,
        material: String(fixture.material || '').replace(/^public\//, ''),
        wgsl: relative(resolve(root, 'public'), output).replaceAll('\\', '/'),
        wgslSha256: fixture.hashes?.wgslSha256 || null,
    });
}

writeFileSync(resolve(outputRoot, 'manifest.json'), `${JSON.stringify({ version: 1, entries }, null, 2)}\n`, 'utf8');
console.log(`Published ${entries.length} offline WGSL fixtures to ${outputRoot}.`);