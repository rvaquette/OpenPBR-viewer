#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const root = process.cwd();
const reportPath = resolve(process.argv[2] || 'artifacts/webgpu-render-pathtracer/transpilation-report.json');
const outputPath = resolve(process.argv[3] || 'artifacts/webgpu-render-pathtracer/render-binding-reflection.json');
const input = JSON.parse(readFileSync(reportPath, 'utf8'));
const fixtures = [];
const errors = [];

for (const item of input.fixtures || []) {
    const result = { id: item.id, route: item.route, status: 'failed', bindings: [] };
    try {
        if (item.status !== 'transpiled' || !item.wgsl || !existsSync(item.wgsl)) throw new Error('WGSL fixture output unavailable');
        const source = readFileSync(item.wgsl, 'utf8');
        const bindings = [...source.matchAll(/@group\((\d+)\)\s*@binding\((\d+)\)\s*var(?:<[^>]+>)?\s+([A-Za-z_]\w*)\s*:/g)]
            .map(match => ({ group: Number(match[1]), binding: Number(match[2]), name: match[3] }));
        const keys = bindings.map(binding => `${binding.group}/${binding.binding}`);
        if (new Set(keys).size !== keys.length) throw new Error('duplicate group/binding declaration');
        const invalid = bindings.filter(binding => binding.group !== 0 || binding.binding < 15);
        if (invalid.length) throw new Error(`MaterialX binding overlaps host range: ${invalid.map(binding => `${binding.name}@${binding.binding}`).join(', ')}`);
        result.status = 'reflected';
        result.bindings = bindings;
        result.firstMaterialBinding = bindings.length ? Math.min(...bindings.map(binding => binding.binding)) : null;
        result.lastMaterialBinding = bindings.length ? Math.max(...bindings.map(binding => binding.binding)) : null;
    } catch (error) {
        result.error = error?.message || String(error);
        errors.push(`${item.route}/${item.id}: ${result.error}`);
    }
    fixtures.push(result);
}

const output = {
    version: 1,
    contract: 'webgpu-render-materialx-bindings',
    hostBindingRange: { group: 0, reserved: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] },
    materialFirstBinding: 15,
    status: errors.length ? 'blocked' : 'pass',
    fixtures,
    errors,
};
writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
console.log(JSON.stringify({ status: output.status, fixtures: fixtures.length, reflected: fixtures.filter(item => item.status === 'reflected').length, errors: errors.length, output: outputPath }, null, 2));
process.exitCode = errors.length ? 1 : 0;
