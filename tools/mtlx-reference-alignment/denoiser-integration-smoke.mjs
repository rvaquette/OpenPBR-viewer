import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir,writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright-core';

const root=process.cwd();
const outputPath=path.join(root,'artifacts/mtlx-reference-alignment/t030-denoiser-integration.json');
const outputDirectory=path.dirname(outputPath);
const viteScript=path.join(root,'node_modules/vite/bin/vite.js');
const chromePath=process.env.CHROME_PATH || [
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
].find((candidate)=>existsSync(candidate));

async function findPort() {
    const server=net.createServer();
    await new Promise((resolve,reject)=>server.listen(0,'127.0.0.1',resolve).once('error',reject));
    const {port}=server.address();
    await new Promise((resolve,reject)=>server.close((error)=>error?reject(error):resolve()));
    return port;
}

async function waitForServer(url,server) {
    const deadline=Date.now()+30000;
    while(Date.now()<deadline) {
        if(server.exitCode!==null) throw new Error(`Vite exited with ${server.exitCode}`);
        try { if((await fetch(url)).ok) return; } catch {}
        await delay(200);
    }
    throw new Error(`Vite did not become ready at ${url}`);
}

async function waitForState(page,predicate,description,timeoutMs=240000) {
    const deadline=Date.now()+timeoutMs;
    let state;
    while(Date.now()<deadline) {
        state=await page.evaluate(()=>({
            ...window.__openpbrGetRendererState?.(),
            sceneStatus:window.__openpbrScene?.status || null,
            denoiserStatus:window.__openpbrDenoiserState?.status || null,
            denoisedReady:window.__openpbrReadDenoisedRadiance?.() instanceof Float32Array,
        }));
        if(predicate(state)) return state;
        await delay(250);
    }
    throw new Error(`Timed out waiting for ${description}: ${JSON.stringify(state)}`);
}

if(!chromePath) throw new Error('Chrome not found; set CHROME_PATH to a Chrome executable');
const port=await findPort();
const baseUrl=`http://127.0.0.1:${port}/OpenPBR-viewer/`;
const vite=spawn(process.execPath,[viteScript,'--host','127.0.0.1','--port',String(port),'--strictPort'],{
    cwd:root,stdio:'ignore',windowsHide:true,
});
let browser;
try {
    await waitForServer(baseUrl,vite);
    browser=await chromium.launch({ executablePath:chromePath,headless:true,
        args:['--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--use-gl=swiftshader'] });
    const page=await browser.newPage({viewport:{width:64,height:64}});
    const browserErrors=[];
    const requests=[];
    page.on('pageerror',(error)=>browserErrors.push(error.message));
    page.on('console',(message)=>{ if(message.type()==='error') browserErrors.push(message.text()); });
    page.on('request',(request)=>requests.push(request.url()));

    const query=new URLSearchParams({
        renderer_mode:'Pathtracer MTLX',
        scene_url:'/denoiser-smoke/hdr.scene',
        scene_light_sampling_mode:'mis',
        skyPower:'0',
        max_samples:'16',
        render_size:'max',
        paused:'false',
        denoiser_backend:'cpu',
        linear_radiance_capture:'true',
    });
    await page.goto(`${baseUrl}?${query}`,{waitUntil:'domcontentloaded'});
    await waitForState(page,(state)=>state.mode==='Pathtracer MTLX' && state.loaded && !state.compiling &&
        state.samples>=16 && state.sceneStatus==='loaded','raw pathtracer accumulation');

    const captureRaw=async()=>page.evaluate(async()=>{
        const image=window.__openpbrReadLinearRadiance({includePixels:true});
        const bytes=new Uint8Array(image.rgba.buffer,image.rgba.byteOffset,image.rgba.byteLength);
        const digest=await crypto.subtle.digest('SHA-256',bytes);
        return {width:image.width,height:image.height,samples:image.samples,
            sha256:Array.from(new Uint8Array(digest),byte=>byte.toString(16).padStart(2,'0')).join('')};
    });
    const rawBefore=await captureRaw();
    const rawScreenshot=await page.locator('canvas').screenshot();
    await page.evaluate(()=>window.__openpbrDenoiseCurrent());
    const denoiser=await waitForState(page,(state)=>state.denoiserStatus==='ready' && state.denoisedReady,
        'denoiser output');
    const denoiserExecution=await page.evaluate(()=>({...window.__openpbrDenoiserState}));
    const denoised=await page.evaluate(()=>{
        const data=window.__openpbrReadDenoisedRadiance();
        let finiteComponents=0,min=Infinity,max=-Infinity;
        for(const value of data) {
            if(Number.isFinite(value)) finiteComponents++;
            min=Math.min(min,value);
            max=Math.max(max,value);
        }
        return {components:data.length,finiteComponents,min,max};
    });

    await page.evaluate(()=>window.__openpbrSetDenoisedVisible(true));
    const denoisedScreenshot=await page.locator('canvas').screenshot();
    await page.evaluate(()=>window.__openpbrSetDenoisedVisible(false));
    const restoredScreenshot=await page.locator('canvas').screenshot();
    const rawAfter=await captureRaw();

    const revisionBeforeCamera=await page.evaluate(()=>window.__openpbrGetRendererState().sampleResetRevision);
    await page.locator('canvas').evaluate((canvas)=>{
        const event=(type,x,y,buttons)=>new PointerEvent(type,{pointerId:1,pointerType:'mouse',isPrimary:true,
            button:buttons?0:-1,buttons,clientX:x,clientY:y,bubbles:true,cancelable:true});
        canvas.dispatchEvent(event('pointerdown',20,20,1));
        canvas.dispatchEvent(event('pointermove',29,25,1));
        canvas.dispatchEvent(event('pointerup',29,25,0));
    });
    const invalidated=await waitForState(page,(state)=>state.sampleResetRevision>revisionBeforeCamera &&
        !state.denoisedReady,'camera-change denoiser invalidation',30000);
    await waitForState(page,(state)=>state.mode==='Pathtracer MTLX' && state.loaded && !state.compiling &&
        state.samples>=2 && state.pathTargetSize?.[0]===64 && state.pathTargetSize?.[1]===64,
        'pathtracer resumption after camera movement');

    const externalRequests=requests.filter((url)=>new URL(url).origin!==new URL(baseUrl).origin);
    const pngHash=(buffer)=>createHash('sha256').update(buffer).digest('hex');
    const report={baseUrl,resolution:[64,64],rawBefore,rawAfter,denoiser:{...denoiserExecution,...denoised},
        canvasHashes:{raw:pngHash(rawScreenshot),denoised:pngHash(denoisedScreenshot),restored:pngHash(restoredScreenshot)},
        cameraInvalidation:{revisionBefore:revisionBeforeCamera,revisionAfter:invalidated.sampleResetRevision,
            denoisedCleared:!invalidated.denoisedReady},externalRequests,browserErrors};

    assert.deepEqual([rawBefore.width,rawBefore.height,rawAfter.width,rawAfter.height],[64,64,64,64]);
    assert.equal(rawAfter.samples,rawBefore.samples);
    assert.equal(rawAfter.sha256,rawBefore.sha256,'denoising modified the accumulation target');
    assert.equal(denoiserExecution.samples,rawBefore.samples);
    assert.deepEqual([denoiserExecution.width,denoiserExecution.height,denoised.components,denoised.finiteComponents],[64,64,64*64*4,64*64*4]);
    assert.notEqual(report.canvasHashes.raw,report.canvasHashes.denoised,'show_denoised did not change presentation');
    assert.equal(report.canvasHashes.restored,report.canvasHashes.raw,'hiding denoised output did not restore raw presentation');
    assert.equal(report.cameraInvalidation.denoisedCleared,true);
    assert.deepEqual(externalRequests,[],'denoiser integration made a cross-origin request');
    assert.deepEqual(browserErrors,[],'browser reported an error during denoiser integration');
    report.result='passed';

    await mkdir(outputDirectory,{recursive:true});
    await writeFile(outputPath,`${JSON.stringify(report,null,2)}\n`);
    await page.locator('canvas').screenshot({path:path.join(outputDirectory,'t030-denoiser-integration.png')});
    console.log(JSON.stringify(report,null,2));
} finally {
    await browser?.close();
    vite.kill();
}