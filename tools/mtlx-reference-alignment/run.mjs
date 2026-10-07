import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import sharp from 'sharp';

export const root = fileURLToPath(new URL('../../', import.meta.url));
export const corpus = JSON.parse(readFileSync(new URL('./corpus.json', import.meta.url), 'utf8'));
const referenceContract = JSON.parse(readFileSync(new URL('../../specs/005-mtlx-reference-alignment/scene-directives.json', import.meta.url), 'utf8'));
const hash = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');

export function selectCases(target = 'local', ids = []) {
    assert.ok(['local', 'reference', 'all'].includes(target), 'Invalid target');
    const selected = corpus.cases.filter((entry) => (target === 'all' || entry.target === target) && (!ids.length || ids.includes(entry.id)));
    assert.ok(selected.length > 0, 'No cases selected');
    for (const id of ids) assert.ok(selected.some((entry) => entry.id === id), `Unknown or excluded case: ${id}`);
    return selected;
}

export function validateCorpus(referenceRoot = corpus.defaults.referenceRoot) {
    const ids = new Set();
    for (const entry of corpus.cases) {
        assert.match(entry.id, /^[a-z0-9-]+$/);
        assert.ok(!ids.has(entry.id), `Duplicate case: ${entry.id}`);
        ids.add(entry.id);
        assert.ok(['local', 'reference'].includes(entry.target));
        if (entry.target === 'local') {
            if (entry.material) assert.ok(existsSync(join(root, 'public', entry.material)), entry.material);
            for (const resource of entry.resources || []) {
                assert.ok(existsSync(join(root, 'public', dirname(entry.material), resource)), `Missing material resource: ${resource}`);
            }
        } else {
            const fixture = referenceContract.referenceFixtures.find((candidate) => basename(candidate.file) === entry.scene);
            assert.ok(fixture && fixture.mode === 'non-mtlx', `Unapproved reference scene: ${entry.scene}`);
            const sceneFile = join(referenceRoot, fixture.file);
            assert.equal(hash(sceneFile), fixture.sha256, entry.scene);
            assert.ok(!/^\s*materialx_(document|inline_begin)\b/m.test(readFileSync(sceneFile, 'utf8')));
        }
    }
    assert.ok(existsSync(join(root, 'public', corpus.defaults.environment)));
    assert.ok(existsSync(join(referenceRoot, 'scripts/render-scene.mjs')), 'Reference driver missing');
    return { cases: ids.size, local: selectCases('local').length, reference: selectCases('reference').length };
}

export function buildCommand(entry, options) {
    const size = options.size ?? corpus.defaults.size;
    const samples = options.samples ?? corpus.defaults.samples[options.profile || 'smoke'];
    const denoiseEnabled = options.denoise === true;
    assert.ok(entry.target === 'local' || !denoiseEnabled, 'DENOISER_ROUTE_UNSUPPORTED: denoising requires a local Pathtracer MTLX capture');
    assert.ok(Number.isInteger(samples) && samples > 0);
    assert.ok(size.length === 2 && size.every((value) => Number.isInteger(value) && value > 0));
    assert.ok(Number.isInteger(options.timeoutMs ?? corpus.defaults.timeoutMs) && (options.timeoutMs ?? corpus.defaults.timeoutMs) > 0, 'Invalid timeout');
    assert.ok(Number.isInteger(options.port ?? 5181) && (options.port ?? 5181) > 0 && (options.port ?? 5181) <= 65535, 'Invalid port');
    const output = resolve(options.output, entry.id,
        options.denoisePair ? (denoiseEnabled ? 'denoise-on' : 'denoise-off') : '');
    if (entry.target === 'reference') {
        const referenceRoot = resolve(options.referenceRoot || corpus.defaults.referenceRoot);
        return { cwd: referenceRoot, args: [join(root, 'tools/mtlx-reference-alignment/reference-capture.mjs'), '--reference-root', referenceRoot,
            '--scene', entry.scene, '--samples', String(samples), '--size', size.join('x'),
            '--timeout', String(options.timeoutMs || corpus.defaults.timeoutMs), '--dump-dir', join(output, 'glsl'),
            '--output', join(output, 'image.png'), '--report', join(output, 'viewer.json')], output, samples, size };
    }
    const args = [join(root, 'launch_render.mjs'), '--mode=Pathtracer MTLX', '--gpu=false', `--denoise=${denoiseEnabled}`, '--headless=true',
        `--scene=${entry.scene}`, `--spp=${samples}`, `--max_samples=${samples}`, `--size=${size.join('x')}`, `--render_size=${size.join('x')}`,
        `--port=${options.port || 5181}`, `--start-server=${options.startServer === true}`, '--env_irradiance_path=',
        `--envmap=${corpus.defaults.environment}`, '--env_cdf_sampling=false', '--strict_generated_contract=true',
        `--output=${join(output, 'image.png')}`, `--dump-glsl=${join(output, 'glsl')}`, `--report=${join(output, 'viewer.json')}`];
    if (denoiseEnabled) args.push('--denoiser_backend=cpu');
    if (entry.material) args.push(`--mtlx_url=/${entry.material}`);
    return { cwd: root, args, output, samples, size, denoiseEnabled };
}

export function buildCaptureRuns(entries,options) {
    if(options.denoise==='true')
        assert.ok(entries.every((entry)=>entry.target==='local'),'Denoiser is unsupported for reference captures');
    return entries.flatMap((entry)=>{
        const modes=entry.target==='reference'?[false]
            :options.denoise==='both'?[false,true]:[options.denoise==='true'];
        return modes.map((denoiseEnabled)=>({entry,command:buildCommand(entry,{...options,denoise:denoiseEnabled,
            denoisePair:options.denoise==='both'})}));
    });
}

export function verifyObserved(report, command, entry) {
    assert.equal(report.requestedMode, 'Pathtracer MTLX');
    assert.equal(report.useGpu, false);
    assert.equal(report.denoiseEnabled, command.denoiseEnabled);
    assert.equal(report.observed.ready, true);
    assert.equal(report.observed.shaderError, null);
    assert.equal(report.observed.contextLoss, null);
    assert.equal(report.observed.gpu?.app?.rendererMode, 'Pathtracer MTLX', 'Wrong actual renderer');
    assert.equal(report.observed.gpu?.app?.scene, entry.scene, 'Wrong actual scene');
    assert.ok(report.observed.samples >= command.samples, 'Insufficient samples');
    assert.ok(report.observed.dispatchBytes > 0, 'Missing local MTLX dispatch');
    if (command.denoiseEnabled) {
        const denoiser = report.observed.denoiser;
        assert.equal(denoiser?.status, 'ready', 'Denoiser did not reach ready state');
        assert.ok(denoiser.samples >= command.samples, 'Denoiser sample count is stale');
        assert.deepEqual([denoiser.width,denoiser.height],command.size, 'Denoiser dimensions mismatch');
        assert.ok(report.rawScreenshotPath, 'Missing raw screenshot path');
        assert.equal(new URL(denoiser.weightsBaseUrl).origin,new URL(report.url).origin,
            'Denoiser weights are not same-origin');
    }
    assert.deepEqual(report.browserErrors, [], 'Browser errors');
}

export async function inspectImage(file, size, expectedColor) {
    const image = sharp(file).removeAlpha();
    const metadata = await image.metadata();
    assert.deepEqual([metadata.width, metadata.height], size, 'Wrong capture size');
    const stats = await image.stats();
    assert.ok(stats.channels.some((channel) => channel.stdev > 0.1), 'Blank or constant image');
    const { data, info } = await sharp(file).removeAlpha().toColourspace('srgb').raw().toBuffer({ resolveWithObject: true });
    let chromaticPixels = 0;
    let matchingPixels = 0;
    for (let offset = 0; offset < data.length; offset += info.channels) {
        const [red, green, blue] = data.subarray(offset, offset + 3);
        if (Math.max(red, green, blue) - Math.min(red, green, blue) >= 8) chromaticPixels++;
        if (expectedColor === 'warm' && red > green + 2 && green > blue + 2) matchingPixels++;
        if (expectedColor === 'blue' && blue > red + 8 && blue > green + 4) matchingPixels++;
    }
    const chromaticFraction = chromaticPixels / (info.width * info.height);
    const expectedColorFraction = matchingPixels / (info.width * info.height);
    if (expectedColor) {
        assert.ok(['warm', 'blue'].includes(expectedColor), 'Unsupported color expectation');
        assert.ok(expectedColorFraction >= 0.01, `Expected ${expectedColor} color missing: ${expectedColorFraction}`);
    }
    return { width: metadata.width, height: metadata.height, chromaticFraction, expectedColorFraction,
        channels: stats.channels.map(({ mean, stdev, min, max }) => ({ mean, stdev, min, max })) };
}

export function execute(command, timeoutMs, onLog) {
    mkdirSync(command.output, { recursive: true });
    const stdoutFile = join(command.output, 'stdout.log');
    const stderrFile = join(command.output, 'stderr.log');
    writeFileSync(stdoutFile, '');
    writeFileSync(stderrFile, '');
    return new Promise((resolveRun, rejectRun) => {
        const child = spawn(process.execPath, command.args, { cwd: command.cwd, windowsHide: true, shell: false });
        let stdout = '';
        let stderr = '';
        let timedOut = false;
        const timer = setTimeout(() => {
            timedOut = true;
            if (process.platform === 'win32') {
                try { execFileSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore' }); } catch { child.kill(); }
            } else child.kill('SIGTERM');
        }, timeoutMs);
        child.stdout.on('data', (data) => {
            stdout += data;
            appendFileSync(stdoutFile, data);
            process.stdout.write(data);
            onLog?.('stdout', data);
        });
        child.stderr.on('data', (data) => {
            stderr += data;
            appendFileSync(stderrFile, data);
            process.stderr.write(data);
            onLog?.('stderr', data);
        });
        child.on('error', (error) => { clearTimeout(timer); rejectRun(error); });
        child.on('close', (code, signal) => { clearTimeout(timer); resolveRun({ code, signal, timedOut, stdout, stderr }); });
    });
}

export function parseOptions(argv) {
    const allowed = new Set(['target', 'case', 'profile', 'samples', 'size', 'output', 'port', 'start-server', 'reference-root', 'timeout-ms', 'validate', 'dry-run', 'denoise']);
    const values = {};
    for (const arg of argv) {
        const match = /^--([a-z-]+)(?:=(.*))?$/.exec(arg);
        assert.ok(match && allowed.has(match[1]), `Unknown argument: ${arg}`);
        values[match[1]] = match[2] ?? 'true';
    }
    assert.ok(!values.profile || ['smoke', 'baseline'].includes(values.profile));
    const denoise = values.denoise || 'false';
    assert.ok(['false','true','both'].includes(denoise),'Invalid denoise mode; use false, true, or both');
    return { values, target: values.target || 'local', ids: values.case ? values.case.split(',') : [],
        profile: values.profile || 'smoke', samples: values.samples ? Number(values.samples) : undefined,
        denoise,
        size: values.size ? values.size.split('x').map(Number) : undefined,
        output: resolve(root, values.output || `artifacts/mtlx-reference-alignment/${values.profile === 'baseline' ? '01-baseline' : 't003-smoke'}/${Date.now()}`),
        port: values.port ? Number(values.port) : 5181, startServer: values['start-server'] === 'true',
        referenceRoot: values['reference-root'] || corpus.defaults.referenceRoot,
        timeoutMs: values['timeout-ms'] ? Number(values['timeout-ms']) : corpus.defaults.timeoutMs };
}

export async function main(argv = process.argv.slice(2)) {
    const options = parseOptions(argv);
    const coverage = validateCorpus(options.referenceRoot);
    const entries = selectCases(options.target, options.ids);
    if (options.values.validate === 'true') { console.log(JSON.stringify({ status: 'PASS', coverage }, null, 2)); return; }
    const commands = buildCaptureRuns(entries,options);
    if (options.values['dry-run'] === 'true') { console.log(JSON.stringify(commands, null, 2)); return; }
    assert.ok(!existsSync(join(options.output, 'report.json')), 'Output already contains a report; choose a new output directory');
    mkdirSync(options.output, { recursive: true });
    const report = { version: 1, startedAt: new Date().toISOString(), node: process.version,
        localRevision: execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(),
        launcherSha256: hash(join(root, 'launch_render.mjs')),
        referenceRevision: execFileSync('git', ['-C', options.referenceRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(),
        corpusSha256: hash(fileURLToPath(new URL('./corpus.json', import.meta.url))), profile: options.profile,
        denoise:options.denoise,coverage,
        scope: 'selected-cases-only-not-full-baseline-signoff', results: [], status: 'RUNNING' };
    const reportFile = join(options.output, 'report.json');
    writeFileSync(reportFile, `${JSON.stringify(report, null, 2)}\n`);
    for (const { entry, command } of commands) {
        mkdirSync(command.output, { recursive: true });
        const result = { id: entry.id,target:entry.target,tags:entry.tags,denoiseEnabled:command.denoiseEnabled,
            command:[process.execPath,...command.args],cwd:command.cwd,status:'RUNNING' };
        if (entry.material) result.materialSha256 = hash(join(root, 'public', entry.material));
        const started = Date.now();
        report.results.push(result);
        writeFileSync(reportFile, `${JSON.stringify(report, null, 2)}\n`);
        try {
            const execution = await execute(command, options.timeoutMs);
            result.exitCode = execution.code;
            assert.ok(!execution.timedOut, 'Render timeout');
            assert.equal(execution.code, 0, `Capture failed: ${execution.signal || execution.code}`);
            if (entry.target === 'local') {
                result.viewer = JSON.parse(readFileSync(join(command.output, 'viewer.json'), 'utf8'));
                verifyObserved(result.viewer, command, entry);
                result.measurements = {
                    captureDurationMs:Date.now()-started,
                    samples:result.viewer.observed.samples,
                    rendererResources:result.viewer.observed.rendererState?.resources ?? null,
                    sceneMetrics:result.viewer.observed.rendererState?.sceneMetrics ?? null,
                    jsHeap:result.viewer.observed.rendererState?.jsHeap ?? result.viewer.observed.gpu?.device?.jsHeap ?? null,
                };
            } else {
                assert.ok(!/\[headless MaterialX\]|MaterialX viewer|MaterialX.*(?:generat|closure)/i.test(execution.stdout), 'Reference MTLX activity detected');
                result.viewer = JSON.parse(readFileSync(join(command.output, 'viewer.json'), 'utf8'));
                assert.equal(result.viewer.mode, 'Pathtracer non-MTLX');
                assert.equal(result.viewer.observed.reachedTarget, true);
                result.referenceModeEvidence = 'pinned scene, observed SwiftShader/SPP, no MTLX closure in compiled GLSL';
            }
            result.image = await inspectImage(join(command.output,'image.png'),command.size,
                command.denoiseEnabled ? undefined : entry.expectedColor);
            if (command.denoiseEnabled) {
                result.rawScreenshotPath = result.viewer.rawScreenshotPath;
                assert.ok(existsSync(result.rawScreenshotPath),'Missing raw denoiser screenshot');
                result.rawImage = await inspectImage(result.rawScreenshotPath,command.size,entry.expectedColor);
            }
            const glslManifest = join(command.output, 'glsl', 'manifest.json');
            result.glslManifest = existsSync(glslManifest) ? glslManifest : null;
            if (entry.target === 'local') assert.ok(result.glslManifest, 'Missing GLSL dump');
            result.status = 'PASS';
        } catch (error) { result.error = error.message; result.status = 'FAIL'; }
        result.durationMs = Date.now() - started;
        report.status = report.results.every((item) => item.status === 'PASS') ? 'PASS' : 'FAIL';
        writeFileSync(reportFile, `${JSON.stringify(report, null, 2)}\n`);
        if (result.status === 'FAIL') throw new Error(`${entry.id}: ${result.error}; report: ${reportFile}`);
    }
    report.completedAt = new Date().toISOString();
    writeFileSync(reportFile, `${JSON.stringify(report, null, 2)}\n`);
    console.log(`PASS ${report.results.length} selected case(s); report: ${reportFile}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
    main().catch((error) => { console.error(error.message); process.exitCode = 1; });
}