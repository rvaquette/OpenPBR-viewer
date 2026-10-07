import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { mkdir,writeFile } from 'node:fs/promises';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright-core';

const root = process.cwd();
const outputDirectory = path.join(root,'artifacts/mtlx-reference-alignment');
const viteScript = path.join(root,'node_modules/vite/bin/vite.js');
const chromePath = process.env.CHROME_PATH || [
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
].find((candidate) => existsSync(candidate));

async function findPort() {
    const server = net.createServer();
    await new Promise((resolve,reject) => server.listen(0,'127.0.0.1',resolve).once('error',reject));
    const { port } = server.address();
    await new Promise((resolve,reject) => server.close((error) => error ? reject(error) : resolve()));
    return port;
}

async function waitForServer(url,processHandle) {
    const deadline = Date.now()+30000;
    while (Date.now()<deadline) {
        if (processHandle.exitCode !== null) throw new Error(`Vite exited with ${processHandle.exitCode}`);
        try {
            const response = await fetch(url);
            if (response.ok) return;
        } catch {}
        await delay(200);
    }
    throw new Error(`Vite did not become ready at ${url}`);
}

if (!chromePath) throw new Error('Chrome not found; set CHROME_PATH to a Chrome executable');

const port = await findPort();
const baseUrl = `http://127.0.0.1:${port}/OpenPBR-viewer/`;
const vite = spawn(process.execPath,[viteScript,'--host','127.0.0.1','--port',String(port),'--strictPort'],{
    cwd:root,stdio:'ignore',windowsHide:true,
});
let browser;
try {
    await waitForServer(baseUrl,vite);
    browser = await chromium.launch({
        executablePath:chromePath,
        headless:true,
        args:['--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--use-gl=swiftshader'],
    });
    const page = await browser.newPage({ viewport:{ width:96,height:72 } });
    const browserErrors = [];
    const navigations = [];
    page.on('framenavigated',(frame) => {
        if (frame===page.mainFrame()) navigations.push(frame.url());
    });
    page.on('pageerror',(error) => browserErrors.push({ type:'pageerror',message:error.message }));
    page.on('console',(message) => {
        if (message.type()==='error') browserErrors.push({ type:'console',message:message.text() });
    });

    const query = new URLSearchParams({
        scene_url:'/denoiser-smoke/hdr.scene',
        renderer_mode:'Pathtracer MTLX',
        max_samples:'8',
        render_size:'max',
        paused:'false',
        skyPower:'0',
        linear_radiance_capture:'true',
    });
    await page.goto(`${baseUrl}?${query}`,{ waitUntil:'domcontentloaded' });

    const readState = () => page.evaluate(() => {
        const state = window.__openpbrGetRendererState?.();
        const canvas = document.querySelector('canvas');
        return {
            ...state,
            documentTimeOrigin:performance.timeOrigin,
            sceneStatus:window.__openpbrScene?.status || null,
            sceneUrl:window.__openpbrScene?.url || null,
            shaderError:window.__openpbrShaderError || null,
            contextLoss:Boolean(window.__openpbrContextLossReport),
            gpuRenderer:window.__openpbrGpuInfo?.renderer || null,
            canvas:canvas ? { width:canvas.width,height:canvas.height } : null,
            pathTarget:state?.pathTargetSize || null,
        };
    });

    const waitForState = async (predicate,description,timeoutMs=240000) => {
        const deadline=Date.now()+timeoutMs;
        let state;
        while (Date.now()<deadline) {
            state=await readState();
            if (predicate(state)) return state;
            await delay(250);
        }
        throw new Error(`Timed out waiting for ${description}: ${JSON.stringify(state)}`);
    };

    const waitForReady = async (mode) => {
        return waitForState((state) => state.mode===mode && state.loaded && !state.compiling &&
            state.samples>=2 && state.sceneStatus==='loaded',`${mode} ready with accumulated samples`);
    };

    const saveState = async (name) => {
        const state = await readState();
        await page.screenshot({ path:path.join(outputDirectory,`t028-${name}.png`) });
        return state;
    };

    await waitForReady('Pathtracer MTLX');
    const initialPathtracer = await saveState('A-pathtracer-initial');
    const states = [{ name:'A-pathtracer-initial',...initialPathtracer }];

    const transition = async (expectedMode,name) => {
        const before = await readState();
        await page.keyboard.press('r');
        await waitForState((state) => state.mode===expectedMode && state.sceneLoadRevision>before.sceneLoadRevision &&
            state.sceneStatus==='loaded',`${name} scene load`);
        const state = await waitForReady(expectedMode);
        console.log(JSON.stringify({ transition:name,before,state },null,2));
        assert.ok(state.sampleResetRevision>before.sampleResetRevision,
            `${name} did not reset accumulation after scene readiness (${before.sampleResetRevision} -> ${state.sampleResetRevision}); document ${before.documentTimeOrigin} -> ${state.documentTimeOrigin}`);
        states.push({ name,...(await saveState(name)) });
    };

    await transition('Rasterizer MTLX','B-rasterizer');
    await transition('Pathtracer MTLX','A-pathtracer-return');
    assert.deepEqual(states.at(-1).resources,initialPathtracer.resources,
        'renderer resources grew across the A-B-A cycle');

    const beforeResize = await readState();
    await page.setViewportSize({ width:128,height:80 });
    await waitForState((state) => state.sampleResetRevision>beforeResize.sampleResetRevision &&
        state.canvas?.width===128 && state.canvas?.height===80 &&
        state.pathTarget?.[0]===128 && state.pathTarget?.[1]===80,'render target resize',30000);
    const resized = await waitForReady('Pathtracer MTLX');
    assert.deepEqual(resized.pathTarget,[128,80],'pathtracer target did not resize with the viewport');
    states.push({ name:'A-pathtracer-resized',...(await saveState('A-pathtracer-resized')) });

    assert.ok(states.every((state) => state.sceneStatus==='loaded' && state.loaded && !state.compiling));
    assert.ok(states.every((state) => state.gpuRenderer?.includes('SwiftShader')),'Chrome did not use SwiftShader');
    assert.equal(states[0].samples>=2,true);
    assert.equal(browserErrors.length,0,JSON.stringify(browserErrors));
    const report = { baseUrl,resolutionChanges:[[96,72],[128,80]],navigations,states,browserErrors,result:'passed' };
    await mkdir(outputDirectory,{ recursive:true });
    await writeFile(path.join(outputDirectory,'t028-lifecycle-smoke.json'),`${JSON.stringify(report,null,2)}\n`);
    console.log(JSON.stringify(report,null,2));
} finally {
    await browser?.close();
    vite.kill();
}