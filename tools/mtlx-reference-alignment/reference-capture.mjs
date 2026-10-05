import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

export function attachPageLogs(page, log, fail = () => {}) {
    page.on('console', (message) => log(`console-${message.type()}`, message.text()));
    page.on('pageerror', (error) => {
        log('pageerror', error.stack || error.message);
        fail(new Error(`Reference page error: ${error.message}`));
    });
    page.on('request', (request) => {
        if (/\.(scene|obj|gltf|glb|glsl|mtlx|wasm|tza)(?:[?#]|$)/i.test(request.url())) {
            log('request', request.url(), { method: request.method() });
        }
    });
    page.on('requestfailed', (request) => log('requestfailed', request.url(), { error: request.failure()?.errorText }));
    page.on('response', (response) => {
        if (response.status() >= 400 || /\.(scene|obj|gltf|glb|glsl|mtlx|wasm|tza)(?:[?#]|$)/i.test(response.url())) {
            log('response', response.url(), { status: response.status() });
            if (response.status() >= 400 && response.request?.().isNavigationRequest()) {
                fail(new Error(`Reference navigation HTTP ${response.status()}: ${response.url()}`));
            }
        }
    });
    page.on('domcontentloaded', () => log('phase', 'dom-content-loaded', { url: page.url() }));
    page.on('crash', () => { log('crash', 'Reference page crashed'); fail(new Error('Reference page crashed')); });
    page.on('close', () => log('page-close', 'Reference page closed'));
}

export function withSampleBudget(text, samples) {
    assert.ok(Number.isInteger(samples) && samples > 0);
    assert.ok(/\brenderer\s*\{/.test(text), 'Reference renderer block missing');
    return text.replace(/(\brenderer\s*\{)([\s\S]*?)(\})/, (_match, opening, body, closing) => {
        const updated = /^\s*maxspp\s+/m.test(body)
            ? body.replace(/^(\s*)maxspp\s+[^\r\n]*/m, `$1maxspp ${samples}`)
            : `${body}\n    maxspp ${samples}\n`;
        return opening + updated + closing;
    });
}

export async function main(argv = process.argv.slice(2)) {
    const values = {};
    for (let index = 0; index < argv.length; index += 2) {
        const name = argv[index];
        assert.ok(['--reference-root', '--scene', '--samples', '--size', '--timeout', '--output', '--report', '--dump-dir'].includes(name));
        assert.ok(argv[index + 1], `Missing value: ${name}`);
        values[name.slice(2)] = argv[index + 1];
    }
    mkdirSync(dirname(values.report), { recursive: true });
    const eventFile = join(dirname(values.report), 'browser.ndjson');
    const report = { version: 2, status: 'RUNNING', phase: 'preflight', startedAt: new Date().toISOString(),
        scene: values.scene, mode: 'Pathtracer non-MTLX', requestedSamples: Number(values.samples),
        observed: null, generator: null, mtlx: null, browserLog: eventFile };
    writeFileSync(eventFile, '');
    const log = (type, message, details = {}) => {
        const event = { timestamp: new Date().toISOString(), type, message, ...details };
        appendFileSync(eventFile, `${JSON.stringify(event)}\n`);
        if (type === 'phase') report.phase = message;
        report.lastEvent = event;
        writeFileSync(values.report, `${JSON.stringify(report, null, 2)}\n`);
        const output = ['pageerror', 'requestfailed', 'crash', 'error', 'console-error'].includes(type) ? process.stderr : process.stdout;
        output.write(`[reference ${event.timestamp}] ${type}: ${message}${Object.keys(details).length ? ` ${JSON.stringify(details)}` : ''}\n`);
    };
    let chromium;
    let originalLaunch;
    let browser;
    let heartbeat;
    let rejectPageFailure;
    const pageFailure = new Promise((_resolve, reject) => { rejectPageFailure = reject; });
    pageFailure.catch(() => {});
    try {
        log('phase', 'preflight');
        const referenceRoot = resolve(values['reference-root']);
        const sceneFile = join(referenceRoot, 'scenes/pathtracer', values.scene);
        const contract = JSON.parse(readFileSync(new URL('../../specs/005-mtlx-reference-alignment/scene-directives.json', import.meta.url), 'utf8'));
        const fixture = contract.referenceFixtures.find((entry) => entry.file.endsWith(`/${values.scene}`));
        assert.ok(fixture && fixture.mode === 'non-mtlx');
        const sceneBytes = readFileSync(sceneFile);
        assert.equal(createHash('sha256').update(sceneBytes).digest('hex'), fixture.sha256);
        assert.ok(!/^\s*materialx_(document|inline_begin|generator|essl_template)\b/m.test(sceneBytes.toString('utf8')));
        report.sceneSha256 = fixture.sha256;
        const [width, height] = values.size.split('x').map(Number);
        const samples = Number(values.samples);
        const overlayDir = join(dirname(values.report), 'scene-overlay');
        mkdirSync(overlayDir, { recursive: true });
        const overlayText = withSampleBudget(sceneBytes.toString('utf8'), samples);
        writeFileSync(join(overlayDir, values.scene), overlayText);
        report.sceneBudgetOverride = { samples, sourceUnmodified: true,
            overlaySha256: createHash('sha256').update(overlayText).digest('hex') };
        log('phase', 'sample-budget', { samples, overlayDir });
        log('phase', 'load-playwright');
        const requireReference = createRequire(join(referenceRoot, 'package.json'));
        chromium = requireReference('playwright').chromium;
        originalLaunch = chromium.launch;
        const launch = originalLaunch.bind(chromium);
        const chrome = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
        chromium.launch = async (options) => {
            const executablePath = existsSync(chrome) ? chrome : chromium.executablePath();
            log('phase', 'launch-browser', { executablePath });
            browser = await launch({ ...options, executablePath, timeout: 60000 });
            log('phase', 'browser-launched');
            const newPage = browser.newPage.bind(browser);
            browser.newPage = async (options) => {
                const page = await newPage(options);
                attachPageLogs(page, log, rejectPageFailure);
                const goto = page.goto.bind(page);
                page.goto = async (url, options) => { log('phase', 'navigate', { url }); return goto(url, options); };
                log('phase', 'page-created');
                return page;
            };
            return browser;
        };
        heartbeat = setInterval(() => log('heartbeat', report.phase), 30000);
        log('phase', 'import-reference-driver');
        const { renderSceneToPng } = await import(pathToFileURL(join(referenceRoot, 'scripts/render-scene.mjs')).href);
        log('phase', 'render-reference', { root: referenceRoot });
        const observed = await Promise.race([renderSceneToPng({ root: referenceRoot, scene: values.scene, overlayDir,
            samples, width, height, resW: width, resH: height, timeout: Number(values.timeout),
            out: values.output, gpu: false, headed: false, mtlx: null, mtlxAssign: [], generator: null,
            dumpShaders: true, dumpDir: values['dump-dir'] }), pageFailure]);
        report.observed = observed;
        log('phase', 'validate-capture');
        assert.equal(observed.reachedTarget, true, 'Reference did not reach target samples');
        assert.ok(observed.samples >= samples);
        assert.deepEqual(observed.jsErrors, []);
        assert.deepEqual(observed.badResources.filter((resource) => !resource.endsWith('/favicon.ico')), []);
        assert.match(observed.renderer || '', /SwiftShader/i, 'Reference is not using SwiftShader');
        const fragment = readFileSync(join(values['dump-dir'], 'compiled_fragment_full.glsl'), 'utf8');
        assert.ok(!/\b(?:EvalMtlxClosure|SampleMtlxClosure|mtlx_openpbr_bsdf_evaluate)\s*\(/.test(fragment), 'Reference MTLX shading detected');
        assert.ok(!/^\s*#define\s+OPT_MATERIALX\b/m.test(fragment));
        report.status = 'PASS';
        report.completedAt = new Date().toISOString();
        log('phase', 'completed');
    } catch (error) {
        report.status = 'FAIL';
        report.failure = error.stack || error.message;
        log('error', report.failure);
        throw error;
    } finally {
        clearInterval(heartbeat);
        if (browser?.isConnected()) await browser.close();
        if (chromium && originalLaunch) chromium.launch = originalLaunch;
    }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
    main().catch((error) => { console.error(error.message); process.exit(1); });
}