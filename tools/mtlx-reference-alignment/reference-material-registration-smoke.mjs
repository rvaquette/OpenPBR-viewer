import assert from 'node:assert/strict';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { chromium } from 'playwright-core';

const root = resolve('.');
const outputPath = join(root, 'artifacts/mtlx-reference-alignment/t017-material-registration-smoke.json');
const report = { task:'T017', status:'FAIL', errors:[] };
const browser = await chromium.launch({ executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless:true, args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'] });
try {
    const page = await browser.newPage();
    page.on('pageerror', (error) => report.errors.push(error.message));
    await page.goto('http://localhost:5181/OpenPBR-viewer/?renderer_mode=Pathtracer%20MTLX&gpu=false&max_samples=2&render_size=64x64',
        { waitUntil:'domcontentloaded', timeout:30000 });
    await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout:120000 });
    report.observed = await page.evaluate(() => {
        if (typeof window.__openpbrRegisterReferenceMaterialRegistry !== 'function')
            throw new Error('reference material registry API unavailable');
        const scene = { instances:[{instanceID:0,materialID:7},{instanceID:1,materialID:19}] };
        const active = window.__openpbrRegisterReferenceMaterialRegistry(scene, [
            { sceneMaterialID:7, localMaterialID:1, materialKey:'default-material', kind:'openpbr', parameterVariant:0 },
            { sceneMaterialID:19, localMaterialID:1, materialKey:'default-material', kind:'openpbr', parameterVariant:0 },
        ]);
        const values = active.parameterTypes.map((type) => type === 'bool' ? false
            : type === 'int' ? 0
                : type.startsWith('vec') ? Array(Number(type.slice(-1))).fill(0)
                    : 0);
        const set = (name, value) => { values[active.parameterNames.indexOf(name)] = value; };
        set('geometry_thin_walled', true);
        set('transmission_weight', 0.75);
        set('emission_luminance', 2.5);
        set('emission_color', [0.1,0.2,0.3]);
        return window.__openpbrRegisterReferenceMaterialRegistry(scene, [
            { sceneMaterialID:7, localMaterialID:1, materialKey:'default-material', kind:'openpbr', parameterVariant:0 },
            { sceneMaterialID:19, localMaterialID:1, materialKey:'default-material', kind:'openpbr', parameterVariant:2, parameterValues:values },
        ]);
    });
    assert.equal(report.observed.count, 2);
    assert.equal(report.observed.activeMaterialKey, 'default-material');
    for (const parameter of ['geometry_thin_walled','transmission_weight','emission_luminance','emission_color',
        'thin_film_weight','thin_film_thickness','thin_film_ior','specular_ior','specular_roughness'])
        assert.ok(report.observed.parameterNames.includes(parameter), `missing table-backed hook parameter ${parameter}`);
    assert.ok(report.observed.hiddenParameterCount > 0);
    assert.deepEqual(report.observed.packedRecords, [[7,1,1,0],[19,1,1,2]]);
    assert.deepEqual(report.observed.entries.map((entry) => [entry.sceneMaterialID,entry.localMaterialID,entry.parameterVariant]),
        [[7,1,0],[19,1,2]]);
    assert.equal(report.observed.parameterRows[2].geometry_thin_walled[0], 1);
    assert.equal(report.observed.parameterRows[2].transmission_weight[0], 0.75);
    assert.equal(report.observed.parameterRows[2].emission_luminance[0], 2.5);
    assert.deepEqual(report.observed.parameterRows[2].emission_color.slice(0,3), [0.1,0.2,0.3]);
    assert.deepEqual(report.errors, []);
    report.status = 'PASS';
    console.log(`PASS T017 main.js registry smoke: ${report.observed.count} scene IDs registered in active local dispatch.`);
} catch (error) {
    report.errors.push(error.stack ?? error.message);
    process.exitCode = 1;
    console.error(error.message);
} finally {
    mkdirSync(dirname(outputPath), { recursive:true });
    writeFileSync(outputPath, `${JSON.stringify(report,null,2)}\n`);
    await browser.close();
}