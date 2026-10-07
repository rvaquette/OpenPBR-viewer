import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdir,writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright-core';

const root=process.cwd();
const adb=process.env.ADB_PATH || 'D:/platform-tools/adb.exe';
const cdpUrl=process.env.T034_CDP_URL || 'http://127.0.0.1:9222';
const expectedAndroidPackage=process.env.T034_EXPECT_PACKAGE || null;
const viteScript=path.join(root,'node_modules/vite/bin/vite.js');
const outputDirectory=path.join(root,'artifacts/mtlx-reference-alignment/t034-adreno');
const reportPath=path.join(outputDirectory,'report.json');
const denoiserEnabled=process.env.T034_DENOISE!=='false';
const deviceList=execFileSync(adb,['devices','-l'],{encoding:'utf8'});
const deviceLine=deviceList.split(/\r?\n/).find((line)=>/^\S+\s+device\s/.test(line));
if(!deviceLine) throw new Error(`T034_DEVICE_NOT_AUTHORIZED: ${deviceList.trim()}`);
const serial=deviceLine.trim().split(/\s+/)[0];
const adbFor=(args)=>execFileSync(adb,['-s',serial,...args],{encoding:'utf8'}).trim();
const readProperty=(key)=>adbFor(['shell','getprop',key]);
const transitionStates=[];

async function findPort() {
    const server=net.createServer();
    await new Promise((resolve,reject)=>server.listen(0,'0.0.0.0',resolve).once('error',reject));
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

async function readState(page) {
    return page.evaluate(()=>{
        const state=window.__openpbrGetRendererState?.();
        let linear=null;
        try { linear=window.__openpbrReadLinearRadiance?.() ?? null; } catch {}
        return {...state,sceneStatus:window.__openpbrScene?.status || null,
            sceneUrl:window.__openpbrScene?.url || null,shaderError:window.__openpbrShaderError || null,
            contextLoss:Boolean(window.__openpbrContextLossReport),
            gpuRenderer:window.__openpbrGpuInfo?.renderer || null,
            canvas:(()=>{const canvas=document.querySelector('canvas');return canvas?{width:canvas.width,height:canvas.height}:null;})(),
            linear:linear?{width:linear.width,height:linear.height,samples:linear.samples,
                meanRGB:linear.meanRGB,nonFiniteComponents:linear.nonFiniteComponents}:null,
            denoiser:window.__openpbrDenoiserState || null,
            denoisedAvailable:(window.__openpbrReadDenoisedRadiance?.() instanceof Float32Array)};
    });
}

async function waitForState(page,predicate,description,timeoutMs=240000) {
    const deadline=Date.now()+timeoutMs;
    let state;
    while(Date.now()<deadline) {
        state=await readState(page);
        if(predicate(state)) return state;
        await delay(250);
    }
    throw new Error(`T034_TIMEOUT waiting for ${description}: ${JSON.stringify(state)}`);
}

const serialInfo={serial,model:readProperty('ro.product.model'),soc:readProperty('ro.soc.model'),
    androidRelease:readProperty('ro.build.version.release'),hardware:readProperty('ro.hardware')};
const surfaceFlinger=adbFor(['shell','dumpsys','SurfaceFlinger']);
const gpuLine=surfaceFlinger.split(/\r?\n/).find((line)=>/GLES:.*Adreno/i.test(line)) || '';
if(!/Adreno/i.test(gpuLine)) throw new Error(`T034_ADRENO_GPU_NOT_CONFIRMED: ${gpuLine}`);

const port=await findPort();
const baseUrl=`http://127.0.0.1:${port}/OpenPBR-viewer/`;
const deviceUrl=`http://localhost:${port}/OpenPBR-viewer/`;
const vite=spawn(process.execPath,[viteScript,'--host','0.0.0.0','--port',String(port),'--strictPort'],{
    cwd:root,stdio:'ignore',windowsHide:true,
});
let browser;
let page;
let browserInfo=null;
let currentStage='startup';
let lastState=null;
let reverseInstalled=false;
let forwardInstalled=false;
const browserErrors=[];
const externalRequests=[];
const weightResponses=[];
const requestFailures=[];
const deviceScreenshots=[];
async function captureDeviceScreen(name) {
    const remotePath=`/sdcard/Download/${name}`;
    const localPath=path.join(outputDirectory,name);
    try {
        adbFor(['shell','screencap','-p',remotePath]);
        execFileSync(adb,['-s',serial,'pull',remotePath,localPath],{stdio:'ignore'});
        deviceScreenshots.push(localPath);
    } finally {
        try { adbFor(['shell','rm','-f',remotePath]); } catch {}
    }
}
try {
    await waitForServer(baseUrl,vite);
    const previousReverse=adbFor(['reverse','--list']);
    const reverseKey=`tcp:${port} tcp:${port}`;
    if(!previousReverse.includes(reverseKey)) {
        adbFor(['reverse',`tcp:${port}`,`tcp:${port}`]);
        reverseInstalled=true;
    }
    const previousForward=adbFor(['forward','--list']);
    const forwardKey='tcp:9222 localabstract:chrome_devtools_remote';
    if(!previousForward.includes(forwardKey)) {
        adbFor(['forward','tcp:9222','localabstract:chrome_devtools_remote']);
        forwardInstalled=true;
    }

    const cdpResponse=await fetch(`${cdpUrl}/json/version`);
    if(!cdpResponse.ok) throw new Error(`T034_CDP_UNAVAILABLE: ${cdpUrl} returned HTTP ${cdpResponse.status}`);
    browserInfo=await cdpResponse.json();
    if(expectedAndroidPackage && browserInfo['Android-Package']!==expectedAndroidPackage) {
        throw new Error(`T034_WRONG_ANDROID_BROWSER: expected ${expectedAndroidPackage}, got ${browserInfo['Android-Package']}`);
    }
    browser=await chromium.connectOverCDP(cdpUrl);
    const context=browser.contexts()[0];
    page=await context.newPage();
    await page.addInitScript(() => {
        const diagnostics = [];
        const methods = ['drawArrays','drawElements','drawArraysInstanced','drawElementsInstanced','clear','blitFramebuffer'];
        const errorName = (gl,code) => Object.entries({
            INVALID_ENUM:gl.INVALID_ENUM,INVALID_VALUE:gl.INVALID_VALUE,INVALID_OPERATION:gl.INVALID_OPERATION,
            INVALID_FRAMEBUFFER_OPERATION:gl.INVALID_FRAMEBUFFER_OPERATION,OUT_OF_MEMORY:gl.OUT_OF_MEMORY,
        }).find(([,value])=>value===code)?.[0] || `0x${code.toString(16)}`;
        const record = (gl,method,code,phase) => {
            if (diagnostics.length >= 100) return;
            let framebufferStatus=null;
            try { framebufferStatus=gl.checkFramebufferStatus(gl.FRAMEBUFFER); } catch {}
            diagnostics.push({method,phase,error:errorName(gl,code),framebufferStatus:framebufferStatus===null?null:`0x${framebufferStatus.toString(16)}`,
                viewport:Array.from(gl.getParameter(gl.VIEWPORT)),drawingBuffer:[gl.drawingBufferWidth,gl.drawingBufferHeight],
                canvas:[gl.canvas.width,gl.canvas.height],stack:new Error().stack});
        };
        for (const name of methods) {
            const original=WebGL2RenderingContext.prototype[name];
            if (typeof original !== 'function') continue;
            WebGL2RenderingContext.prototype[name]=function(...args) {
                let code;
                while ((code=this.getError())!==this.NO_ERROR) record(this,name,code,'before');
                const result=original.apply(this,args);
                while ((code=this.getError())!==this.NO_ERROR) record(this,name,code,'after');
                return result;
            };
        }
        Object.defineProperty(window,'__openpbrWebglDiagnostics',{value:diagnostics,configurable:false});
    });
    const initialViewport=await page.evaluate(()=>({width:innerWidth,height:innerHeight,devicePixelRatio}));
    page.on('pageerror',(error)=>browserErrors.push({type:'pageerror',message:error.message}));
    page.on('console',(message)=>{if(message.type()==='error') browserErrors.push({type:'console',message:message.text()});});
    page.on('request',(request)=>{
        if(new URL(request.url()).origin!==new URL(deviceUrl).origin) externalRequests.push(request.url());
    });
    page.on('response',(response)=>{
        if(response.url().includes('rt_hdr_small.tza')) weightResponses.push({url:response.url(),status:response.status()});
    });
    page.on('requestfailed',(request)=>requestFailures.push({url:request.url(),failure:request.failure()?.errorText || ''}));

    const query=new URLSearchParams({
        renderer_mode:'Pathtracer MTLX',scene_url:'/denoiser-smoke/t034-adreno.scene',
        max_samples:'64',render_size:'256x256',paused:'false',skyPower:'0',denoiser_backend:'cpu',linear_radiance_capture:'true',
        env_map_path:'mtlx-input/_env/san_giuseppe_bridge.hdr',
        env_irradiance_path:'mtlx-input/_env/irradiance/san_giuseppe_bridge.hdr',
    });
    await page.goto(`${deviceUrl}?${query}`,{waitUntil:'domcontentloaded',timeout:120000});
    await page.bringToFront();
    const timings=[];
    let started=Date.now();
    const pathInitial=await waitForState(page,(state)=>state.mode==='Pathtracer MTLX' && state.loaded &&
        !state.compiling && state.samples>=64 && state.sceneStatus==='loaded' &&
        state.pathTargetSize?.[0]>0 && state.pathTargetSize?.[1]>0,'Adreno Pathtracer 64 spp');
    timings.push({stage:'pathtracer-64spp',durationMs:Date.now()-started});
    assert.ok(pathInitial.gpuRenderer.includes('Adreno'),`Unexpected renderer: ${pathInitial.gpuRenderer}`);
    assert.equal(pathInitial.shaderError,null);
    assert.equal(pathInitial.contextLoss,false);
    currentStage='pathtracer-64spp';
    lastState=pathInitial;
    await mkdir(outputDirectory,{recursive:true});
    await page.screenshot({path:path.join(outputDirectory,'pathtracer-64spp.png')});
    await captureDeviceScreen('pathtracer-64spp-device.png');

    const rawBefore=await page.evaluate(async()=>{
        const image=window.__openpbrReadLinearRadiance({includePixels:true});
        const bytes=new Uint8Array(image.rgba.buffer,image.rgba.byteOffset,image.rgba.byteLength);
        const digest=await crypto.subtle.digest('SHA-256',bytes);
        return {width:image.width,height:image.height,samples:image.samples,
            sha256:Array.from(new Uint8Array(digest),byte=>byte.toString(16).padStart(2,'0')).join(''),meanRGB:image.meanRGB};
    });

    let denoiserReady=null;
    if(denoiserEnabled) {
        started=Date.now();
        await page.evaluate(()=>window.__openpbrDenoiseCurrent());
        denoiserReady=await waitForState(page,(state)=>state.denoiser?.status==='ready' && state.denoisedAvailable,
            'Adreno denoiser output',240000);
        timings.push({stage:'denoiser',durationMs:Date.now()-started});
        await page.evaluate(()=>window.__openpbrSetDenoisedVisible(true));
        await page.screenshot({path:path.join(outputDirectory,'pathtracer-64spp-denoised.png')});
        await captureDeviceScreen('pathtracer-64spp-denoised-device.png');
        await page.evaluate(()=>window.__openpbrSetDenoisedVisible(false));
    }
    const rawAfter=await page.evaluate(async()=>{
        const image=window.__openpbrReadLinearRadiance({includePixels:true});
        const bytes=new Uint8Array(image.rgba.buffer,image.rgba.byteOffset,image.rgba.byteLength);
        const digest=await crypto.subtle.digest('SHA-256',bytes);
        return {width:image.width,height:image.height,samples:image.samples,
            sha256:Array.from(new Uint8Array(digest),byte=>byte.toString(16).padStart(2,'0')).join(''),meanRGB:image.meanRGB};
    });

    const transitions=[];
    const transition=async(expectedMode,label)=>{
        const before=await readState(page);
        await page.evaluate(()=>document.dispatchEvent(new KeyboardEvent('keydown',{
            key:'r',code:'KeyR',keyCode:82,which:82,bubbles:true,cancelable:true,
        })));
        const after=await waitForState(page,(state)=>state.mode===expectedMode && state.loaded && !state.compiling &&
            state.sceneStatus==='loaded' && state.sceneLoadRevision>before.sceneLoadRevision &&
            state.sampleResetRevision>before.sampleResetRevision && state.samples>=2,'Adreno '+label,240000);
        transitionStates.push({label,before,after});
        assert.ok(after.sampleResetRevision>before.sampleResetRevision,`${label}: samples were not reset`);
        assert.equal(after.shaderError,null,`${label}: shader error`);
        assert.equal(after.contextLoss,false,`${label}: context loss`);
        transitions.push({label,beforeMode:before.mode,mode:after.mode,sceneLoadRevision:after.sceneLoadRevision,
            sampleResetRevision:after.sampleResetRevision,samples:after.samples,resources:after.resources});
        await page.screenshot({path:path.join(outputDirectory,`${label}.png`)});
        await captureDeviceScreen(`${label}-device.png`);
        return after;
    };
    await transition('Rasterizer MTLX','rasterizer-transition');
    await transition('Pathtracer MTLX','pathtracer-return');

    const resizeBefore=await readState(page);
    started=Date.now();
    await page.setViewportSize({width:96,height:80});
    const resized=await waitForState(page,(state)=>state.mode==='Pathtracer MTLX' && state.loaded && !state.compiling &&
        state.sampleResetRevision>resizeBefore.sampleResetRevision && state.pathTargetSize &&
        (state.pathTargetSize[0]!==resizeBefore.pathTargetSize?.[0] || state.pathTargetSize[1]!==resizeBefore.pathTargetSize?.[1]) &&
        state.canvas?.width===state.pathTargetSize[0] && state.canvas?.height===state.pathTargetSize[1] &&
        state.samples>=2,'Adreno render resize',90000);
    timings.push({stage:'resize-96x80',durationMs:Date.now()-started});
    await page.screenshot({path:path.join(outputDirectory,'pathtracer-resized-96x80.png')});
    await captureDeviceScreen('pathtracer-resized-96x80-device.png');

    const report={device:{...serialInfo,gpuRenderer:pathInitial.gpuRenderer,surfaceFlingerGpuLine:gpuLine},
        browser:{androidPackage:browserInfo['Android-Package']||null,version:browserInfo.Browser||null,userAgent:browserInfo['User-Agent']||null,cdpUrl},
        fixture:'/denoiser-smoke/t034-adreno.scene',driver:'Android browser via ADB reverse/CDP',
        initialViewport,renderSize:'256x256',viewportSizes:[[initialViewport.width,initialViewport.height],[96,80]],
        initial:pathInitial,denoiser:denoiserReady?.denoiser ?? null,
        rawBefore,rawAfter,rawPreserved:rawBefore.sha256===rawAfter.sha256,
        transitions,resize:resized,timings,weightResponses,requestFailures,externalRequests,browserErrors,deviceScreenshots,
        webglDiagnostics:await page.evaluate(()=>window.__openpbrWebglDiagnostics||[]),
        webBuildPreflight:'npm run build was verified separately; this report covers actual Android shader/runtime compilation'};
    assert.equal(report.rawPreserved,true,'Adreno denoiser modified the raw accumulation buffer');
    assert.deepEqual([rawBefore.width,rawBefore.height,rawBefore.samples],[pathInitial.pathTargetSize[0],pathInitial.pathTargetSize[1],64]);
    assert.deepEqual([rawAfter.width,rawAfter.height,rawAfter.samples],[rawBefore.width,rawBefore.height,64]);
    assert.ok(transitions.length===2 && transitions[0].mode==='Rasterizer MTLX' && transitions[1].mode==='Pathtracer MTLX');
    assert.deepEqual(externalRequests,[],'T034 browser made a cross-origin request');
    assert.deepEqual(browserErrors,[],'T034 browser reported console/page errors');
    if(denoiserEnabled) assert.ok(weightResponses.some((response)=>response.status===200),'Local denoiser weights did not return HTTP 200');
    report.result='passed';
    await mkdir(outputDirectory,{recursive:true});
    await writeFile(reportPath,`${JSON.stringify(report,null,2)}\n`);
    console.log(JSON.stringify(report,null,2));
} catch(error) {
    const failure={serial,device:serialInfo,browser:browserInfo,currentStage,lastState,error:error?.message||String(error),transitionStates,browserErrors,requestFailures,externalRequests,
        weightResponses,reportPath};
    await mkdir(outputDirectory,{recursive:true});
    await writeFile(path.join(outputDirectory,'failure.json'),`${JSON.stringify(failure,null,2)}\n`);
    throw error;
} finally {
    await page?.close().catch(()=>{});
    if(browser) await browser.close().catch(()=>{});
    vite.kill();
    if(forwardInstalled) { try { adbFor(['forward','--remove','tcp:9222']); } catch {} }
    if(reverseInstalled) { try { adbFor(['reverse','--remove',`tcp:${port}`]); } catch {} }
}
