import test from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import sharp from 'sharp';
import { buildCommand, buildCaptureRuns, corpus, parseOptions, selectCases, validateCorpus, verifyObserved, inspectImage, execute } from './run.mjs';
import { attachPageLogs, withSampleBudget } from './reference-capture.mjs';

test('corpus resources, approved reference scenes and requested coverage', () => {
    assert.deepEqual(validateCorpus(), { cases: 19, local: 16, reference: 3 });
    const tags = new Set(corpus.cases.flatMap((entry) => entry.tags));
    for (const tag of ['open_pbr_surface', 'standard_surface', 'disney_principled', 'gltf_pbr', 'usd_preview_surface', 'normal-map', 'anisotropy', 'transmission', 'thinwalled', 'volume', 'thin-film']) assert.ok(tags.has(tag), tag);
    assert.throws(() => selectCases('local', ['missing']), /Unknown|No cases/);
    assert.equal(selectCases('local', ['disney-gold'])[0].material, 'mtlx-input/disney_principled_gold_test.mtlx');
    assert.equal(selectCases('local', ['disney-gold'])[0].expectedColor, 'warm');
    assert.equal(selectCases('local', ['normal-map'])[0].material, 'mtlx-input/brick_atlas_path/brick_procedural.mtlx');
    assert.ok(selectCases('local', ['normal-map'])[0].resources.includes('textures/brick_normal.jpg'));
});

test('local command fixes the pathtracer, software rendering, raw output and local environment', () => {
    const entry = selectCases('local', ['open-pbr'])[0];
    const command = buildCommand(entry, { output: 'artifacts/test', profile: 'smoke' });
    for (const arg of ['--mode=Pathtracer MTLX', '--gpu=false', '--denoise=false', '--env_irradiance_path=', '--max_samples=32', '--render_size=256x256']) assert.ok(command.args.includes(arg), arg);
    assert.ok(command.args.includes('--mtlx_url=/mtlx-defaults/open_pbr_default.mtlx'));
    assert.throws(() => buildCommand(entry, { output: 'artifacts/test', size: [0, 64] }));
    assert.throws(() => buildCommand(entry, { output: 'artifacts/test', samples: 0 }));
    assert.throws(() => buildCommand(entry, { output: 'artifacts/test', timeoutMs: NaN }));
    assert.throws(() => buildCommand(entry, { output: 'artifacts/test', port: 65536 }));
});

test('local corpus commands can build raw and denoised captures as isolated variants', () => {
    const entry = selectCases('local', ['open-pbr'])[0];
    const raw = buildCommand(entry,{output:'artifacts/test',denoise:false,denoisePair:true});
    const denoised = buildCommand(entry,{output:'artifacts/test',denoise:true,denoisePair:true});
    assert.ok(raw.args.includes('--denoise=false'));
    assert.ok(denoised.args.includes('--denoise=true'));
    assert.ok(denoised.args.includes('--denoiser_backend=cpu'));
    assert.equal(raw.denoiseEnabled,false);
    assert.equal(denoised.denoiseEnabled,true);
    assert.match(raw.output,/open-pbr[\\/]denoise-off$/);
    assert.match(denoised.output,/open-pbr[\\/]denoise-on$/);
    assert.throws(()=>buildCommand(selectCases('reference')[0],{output:'artifacts/test',denoise:true}),/DENOISER_ROUTE_UNSUPPORTED/);
});

test('denoise both expands local corpus cases to isolated raw/denoised runs',()=>{
    const options=parseOptions(['--target=local','--denoise=both','--output=artifacts/test']);
    const runs=buildCaptureRuns(selectCases('local',['open-pbr']),options);
    assert.deepEqual(runs.map(({command})=>command.denoiseEnabled),[false,true]);
    assert.notEqual(runs[0].command.output,runs[1].command.output);
    assert.equal(parseOptions(['--denoise=false']).denoise,'false');
    assert.equal(parseOptions(['--denoise=true']).denoise,'true');
    assert.throws(()=>parseOptions(['--denoise=maybe']),/Invalid denoise mode/);
    assert.throws(()=>buildCaptureRuns(selectCases('reference'),{...options,denoise:'true'}),/unsupported for reference/);
});

test('reference commands never enable MaterialX or hardware GPU', () => {
    for (const entry of selectCases('reference')) {
        const command = buildCommand(entry, { output: 'artifacts/test' });
        assert.ok(command.args[0].endsWith('reference-capture.mjs'));
        assert.equal(command.cwd, resolve(corpus.defaults.referenceRoot));
        assert.ok(join(command.cwd, '/index.html').startsWith(command.cwd), 'Static server root guard must accept normalized paths');
        assert.equal(command.args[command.args.indexOf('--reference-root') + 1], command.cwd);
        assert.ok(!command.args.some((arg) => /^--(?:mtlx|generator|essl|gpu)/.test(arg)));
    }
});

test('runtime verdict rejects wrong actual mode, shader failure, context loss, errors and low SPP', () => {
    const entry = selectCases('local', ['standard-shader-ball'])[0];
    const command = buildCommand(entry, { output: 'artifacts/test' });
    const report = { requestedMode: 'Pathtracer MTLX', useGpu: false, denoiseEnabled: false, browserErrors: [], observed: {
        ready: true, samples: 32, shaderError: null, contextLoss: null, dispatchBytes: 100,
        gpu: { app: { rendererMode: 'Pathtracer MTLX', scene: entry.scene } },
    } };
    verifyObserved(report, command, entry);
    for (const mutate of [
        (value) => { value.observed.gpu.app.rendererMode = 'Rasterizer MTLX'; },
        (value) => { value.observed.samples = 0; },
        (value) => { value.observed.shaderError = 'compile failed'; },
        (value) => { value.observed.contextLoss = {}; },
        (value) => { value.browserErrors.push({ message: 'error' }); },
    ]) { const invalid = structuredClone(report); mutate(invalid); assert.throws(() => verifyObserved(invalid, command, entry)); }
});

test('denoised runtime verdict requires same-origin weights, ready output, exact dimensions and raw capture', () => {
    const entry=selectCases('local',['open-pbr'])[0];
    const command=buildCommand(entry,{output:'artifacts/test',denoise:true,size:[64,64]});
    const report={requestedMode:'Pathtracer MTLX',useGpu:false,denoiseEnabled:true,
        url:'http://localhost:5181/OpenPBR-viewer/?renderer_mode=Pathtracer%20MTLX',
        rawScreenshotPath:'artifacts/test/raw.png',browserErrors:[],observed:{ready:true,samples:32,
            shaderError:null,contextLoss:null,dispatchBytes:100,
            gpu:{app:{rendererMode:'Pathtracer MTLX',scene:entry.scene}},
            denoiser:{status:'ready',samples:32,width:64,height:64,
                weightsBaseUrl:'http://localhost:5181/OpenPBR-viewer/denoiser/tzas'}}};
    verifyObserved(report,command,entry);
    for(const mutate of [
        (value)=>{value.observed.denoiser.status='running';},
        (value)=>{value.observed.denoiser.width=32;},
        (value)=>{value.observed.denoiser.weightsBaseUrl='https://cdn.invalid/weights';},
        (value)=>{value.rawScreenshotPath=null;},
    ]) { const invalid=structuredClone(report); mutate(invalid); assert.throws(()=>verifyObserved(invalid,command,entry)); }
});

test('pixel validation rejects blank captures and wrong dimensions', async () => {
    const directory = mkdtempSync(join(tmpdir(), 'mtlx-runner-'));
    try {
        const blank = join(directory, 'blank.png');
        await sharp({ create: { width: 2, height: 2, channels: 3, background: '#000000' } }).png().toFile(blank);
        await assert.rejects(inspectImage(blank, [2, 2]), /Blank/);
        await assert.rejects(inspectImage(blank, [4, 4]), /size/);
        const varied = join(directory, 'varied.png');
        await sharp(Buffer.from([0,0,0,255,255,255,0,0,0,255,255,255]), { raw: { width: 2, height: 2, channels: 3 } }).png().toFile(varied);
        assert.equal((await inspectImage(varied, [2, 2])).width, 2);
        await assert.rejects(inspectImage(varied, [2, 2], 'warm'), /color missing/);
        const colored = join(directory, 'colored.png');
        await sharp(Buffer.from([255,180,20,10,10,10,255,180,20,10,10,10]), { raw: { width: 2, height: 2, channels: 3 } }).png().toFile(colored);
        assert.ok((await inspectImage(colored, [2, 2], 'warm')).expectedColorFraction >= 0.5);
    } finally { rmSync(directory, { recursive: true, force: true }); }
});

test('stdout and stderr are persisted while the child is still running', async () => {
    const directory = mkdtempSync(join(tmpdir(), 'mtlx-live-log-'));
    const streams = new Set();
    let observerError;
    try {
        const command = { cwd: directory, output: directory, args: ['-e',
            'process.stdout.write("live-stdout\\n"); process.stderr.write("live-stderr\\n"); setTimeout(() => process.exit(0), 100);'] };
        const result = await execute(command, 5000, (stream) => {
            try {
                assert.ok(readFileSync(join(directory, `${stream}.log`), 'utf8').includes(`live-${stream}`));
                streams.add(stream);
            } catch (error) { observerError = error; }
        });
        if (observerError) throw observerError;
        assert.equal(result.code, 0);
        assert.deepEqual([...streams].sort(), ['stderr', 'stdout']);
    } finally { rmSync(directory, { recursive: true, force: true }); }
});

test('reference logs include headless console, page errors and network failures', () => {
    const page = new EventEmitter();
    page.url = () => 'http://127.0.0.1/index.html';
    const events = [];
    const failures = [];
    attachPageLogs(page, (type, message, details) => events.push({ type, message, details }), (error) => failures.push(error));
    page.emit('console', { type: () => 'log', text: () => 'Building BVH' });
    page.emit('request', { url: () => 'http://127.0.0.1/cornell.scene', method: () => 'GET' });
    page.emit('response', { url: () => 'http://127.0.0.1/missing.obj', status: () => 404 });
    page.emit('requestfailed', { url: () => 'http://127.0.0.1/index.html', failure: () => ({ errorText: 'connection refused' }) });
    page.emit('pageerror', new Error('compile failed'));
    assert.deepEqual(events.map((entry) => entry.type), ['console-log', 'request', 'response', 'requestfailed', 'pageerror']);
    assert.equal(events[2].details.status, 404);
    assert.equal(failures.length, 1);
});

test('reference navigation HTTP errors fail immediately instead of waiting for samples', () => {
    const page = new EventEmitter();
    let failure;
    attachPageLogs(page, () => {}, (error) => { failure = error; });
    page.emit('response', { url: () => 'http://127.0.0.1/index.html', status: () => 404,
        request: () => ({ isNavigationRequest: () => true }) });
    assert.match(failure.message, /navigation HTTP 404/);
});

test('reference sample budget is overridden only in the renderer block', () => {
    const scene = 'renderer\n{\n maxspp 32\n maxdepth 8\n}\nmaterial gold\n{\n roughness 0.2\n}\n';
    const updated = withSampleBudget(scene, 128);
    assert.match(updated, /maxspp 128/);
    assert.ok(updated.endsWith('material gold\n{\n roughness 0.2\n}\n'));
    assert.match(withSampleBudget('renderer\n{\n maxdepth 3\n}', 128), /maxspp 128/);
    assert.throws(() => withSampleBudget(scene, 0));
});