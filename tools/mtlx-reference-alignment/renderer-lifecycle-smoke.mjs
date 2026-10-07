import assert from 'node:assert/strict';
import { mkdirSync,writeFileSync,existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { chromium } from 'playwright-core';

const baseUrl = process.env.OPENPBR_BASE_URL || 'http://127.0.0.1:5182/OpenPBR-viewer/';
const outputDirectory = resolve('artifacts/mtlx-reference-alignment');
const browserPaths = [
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
];
const executablePath = browserPaths.find((path) => existsSync(path));
if (!executablePath) throw new Error('T028_BROWSER_NOT_FOUND: install Chrome or Edge');

const report = {
    fixture: '/denoiser-smoke/hdr.scene',
    backend: 'Chrome ANGLE Vulkan SwiftShader (--disable-gpu --use-gl=swiftshader)',
    transitions: [],
    navigations: [],
    browserErrors: [],
};
let browser;

try {
    browser = await chromium.launch({ executablePath,headless:true,args:[
        '--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--use-gl=swiftshader',
    ] });
    const page = await browser.newPage({ viewport:{ width:64,height:64 } });
    page.on('framenavigated',(frame) => {
        if (frame === page.mainFrame()) report.navigations.push(frame.url());
    });
    page.on('pageerror',(error) => report.browserErrors.push({ type:'pageerror',message:error.message }));
    page.on('console',(message) => {
        if (message.type() === 'error') report.browserErrors.push({ type:'console',message:message.text() });
    });
    const url = new URL(baseUrl);
    url.search = new URLSearchParams({
        scene_url:'/denoiser-smoke/hdr.scene',
        renderer_mode:'Pathtracer MTLX',
        scene_light_sampling_mode:'mis',
        paused:'false',
        max_samples:'8',
        bounces:'2',
        skyPower:'0',
        render_size:'max',
        linear_radiance_capture:'true',
    }).toString();
    await page.goto(url.href,{ waitUntil:'domcontentloaded' });

    const readState = async () => {
        const read = () => page.evaluate(() => {
        let radiance = null;
        try { radiance = window.__openpbrReadLinearRadiance?.() || null; }
        catch { /* The render target does not exist during route initialization. */ }
        return { ...window.__openpbrGetRendererState?.(),scene:window.__openpbrScene?.status || null,
            shaderError:window.__openpbrShaderError || null,gpu:window.__openpbrGpuInfo?.renderer || null,
            radiance,viewport:{ width:window.innerWidth,height:window.innerHeight } };
        });
        try { return await read(); }
        catch (error) {
            if (!/Execution context was destroyed/.test(error.message)) throw error;
            await page.waitForFunction(() => typeof window.__openpbrGetRendererState === 'function',
                null,{ timeout:120_000 });
            return read();
        }
    };
    const waitReady = async (mode,width,height) => {
        await page.waitForFunction(({ expectedMode,expectedWidth,expectedHeight }) => {
            const state = window.__openpbrGetRendererState?.();
            if (state?.mode !== expectedMode || !state.loaded || state.compiling || state.samples < 2 ||
                window.__openpbrScene?.status !== 'loaded') return false;
            if (expectedMode !== 'Pathtracer MTLX') return true;
            try {
                const radiance = window.__openpbrReadLinearRadiance?.();
                return radiance?.width === expectedWidth && radiance?.height === expectedHeight;
            } catch { return false; }
        },{ expectedMode:mode,expectedWidth:width,expectedHeight:height },{ timeout:240_000 });
        const state = await readState();
        assert.equal(state.shaderError,null);
        assert.ok(state.gpu?.includes('SwiftShader'),`Expected SwiftShader, got ${state.gpu}`);
        return state;
    };
    const capture = async (label,state) => {
        const path = resolve(outputDirectory,`t028-${label}.png`);
        await page.locator('canvas').first().screenshot({ path });
        report.transitions.push({ label,mode:state.mode,samples:state.samples,scene:state.scene,
            sampleResetRevision:state.sampleResetRevision,
            width:state.radiance?.width ?? state.viewport.width,
            height:state.radiance?.height ?? state.viewport.height,capture:path });
    };
    const transition = async (mode,label) => {
        const before = await readState();
        await page.keyboard.press('r');
        try {
            await page.waitForFunction(({ expectedMode,previousResetRevision }) => {
                const state = window.__openpbrGetRendererState?.();
                return state?.mode === expectedMode && state.sampleResetRevision > previousResetRevision;
            },{ expectedMode:mode,previousResetRevision:before.sampleResetRevision },{ timeout:60_000 });
        } catch (error) {
            report.failedTransition = { requestedMode:mode,before,after:await readState() };
            throw error;
        }
        const state = await waitReady(mode,64,64);
        await capture(label,state);
        return state;
    };

    await waitReady('Pathtracer MTLX',64,64);
    await capture('A-pathtracer-first',await readState());
    await transition('Rasterizer MTLX','B-rasterizer');
    await transition('Pathtracer MTLX','A-pathtracer-return');

    const beforeResize = await readState();
    await page.setViewportSize({ width:80,height:48 });
    await page.waitForFunction(({ previousResetRevision }) => {
        const state = window.__openpbrGetRendererState?.();
        if (state?.sampleResetRevision <= previousResetRevision) return false;
        try {
            const radiance = window.__openpbrReadLinearRadiance?.();
            return radiance?.width === 80 && radiance?.height === 48;
        } catch { return false; }
    },{ previousResetRevision:beforeResize.sampleResetRevision },{ timeout:60_000 });
    await capture('A-after-resize',await waitReady('Pathtracer MTLX',80,48));

    assert.deepEqual(report.transitions.map(({ mode }) => mode),[
        'Pathtracer MTLX','Rasterizer MTLX','Pathtracer MTLX','Pathtracer MTLX',
    ]);
    assert.equal(report.browserErrors.length,0,JSON.stringify(report.browserErrors));
    report.status = 'passed';
} catch (error) {
    report.status = 'failed';
    report.failure = error?.stack || String(error);
    process.exitCode = 1;
} finally {
    await browser?.close();
    mkdirSync(outputDirectory,{ recursive:true });
    const reportPath = resolve(outputDirectory,'t028-renderer-lifecycle.json');
    writeFileSync(reportPath,`${JSON.stringify(report,null,2)}\n`);
    console.log(JSON.stringify({ ...report,reportPath },null,2));
}
