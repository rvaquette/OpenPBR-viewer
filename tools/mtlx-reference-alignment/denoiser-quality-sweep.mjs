import assert from 'node:assert/strict';
import { existsSync,readFileSync } from 'node:fs';
import { mkdir,writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright-core';

const root=process.cwd();
const artifactDirectory=path.join(root,'artifacts/mtlx-reference-alignment');
const low=JSON.parse(readFileSync(path.join(artifactDirectory,'denoiser-hdr-16spp-linear.json'),'utf8'));
const reference=JSON.parse(readFileSync(path.join(artifactDirectory,'denoiser-hdr-256spp-linear.json'),'utf8'));
const outputPath=path.join(artifactDirectory,'t031-denoiser-exposure-sweep.json');
const scales=[1,0.5,0.25,0.125,0.0625];
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

function metrics(candidate,expected,width,height) {
    const pixelCount=width*height;
    let squared=0,absolute=0,referenceSquared=0,peak=0;
    const sum=[0,0,0],referenceSum=[0,0,0],maximum=[-Infinity,-Infinity,-Infinity];
    for(let pixel=0;pixel<pixelCount;pixel++) for(let channel=0;channel<3;channel++) {
        const index=pixel*4+channel;
        const actual=candidate[index];
        const truth=expected[index];
        if(!Number.isFinite(actual)||!Number.isFinite(truth)) throw new Error('nonfinite metric component');
        const difference=actual-truth;
        squared+=difference*difference;
        absolute+=Math.abs(difference);
        referenceSquared+=truth*truth;
        peak=Math.max(peak,Math.abs(truth));
        sum[channel]+=actual;
        referenceSum[channel]+=truth;
        maximum[channel]=Math.max(maximum[channel],actual);
    }
    const count=pixelCount*3;
    const rmse=Math.sqrt(squared/count);
    return {rmse,mae:absolute/count,relativeRmse:Math.sqrt(squared/Math.max(referenceSquared,1e-30)),
        psnr:rmse===0?Infinity:20*Math.log10(Math.max(peak,1e-30)/rmse),
        meanRGB:sum.map((value)=>value/pixelCount),referenceMeanRGB:referenceSum.map((value)=>value/pixelCount),maxRGB:maximum};
}

if(!chromePath) throw new Error('Chrome not found; set CHROME_PATH to a Chrome executable');
assert.deepEqual([low.width,low.height,reference.width,reference.height],[64,64,64,64]);
const port=await findPort();
const baseUrl=`http://127.0.0.1:${port}/OpenPBR-viewer/`;
const vite=spawn(process.execPath,[viteScript,'--host','127.0.0.1','--port',String(port),'--strictPort'],{
    cwd:root,stdio:'ignore',windowsHide:true,
});
let browser;
try {
    await waitForServer(baseUrl,vite);
    browser=await chromium.launch({executablePath:chromePath,headless:true,
        args:['--no-sandbox','--disable-setuid-sandbox','--disable-gpu','--use-gl=swiftshader']});
    const page=await browser.newPage({viewport:{width:64,height:64}});
    const externalRequests=[];
    const weightResponses=[];
    const browserErrors=[];
    page.on('request',(request)=>{
        if(new URL(request.url()).origin!==new URL(baseUrl).origin) externalRequests.push(request.url());
    });
    page.on('response',(response)=>{
        if(response.url().includes('rt_hdr_small.tza')) weightResponses.push(response.status());
    });
    page.on('pageerror',(error)=>browserErrors.push(error.message));
    page.on('console',(message)=>{if(message.type()==='error') browserErrors.push(message.text());});
    await page.goto(`${baseUrl}?renderer_mode=Rasterizer%20MTLX&render_size=max`,{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>window.__openpbrReady===true,null,{timeout:240000});
    const outputs=await page.evaluate(async({rgba,width,height,scales})=>{
        const {ReferenceDenoiserAdapter}=await import('./src/denoiser/referenceDenoiserAdapter.js');
        const weightsBaseUrl=new URL('denoiser/tzas',location.href).href.replace(/\/$/,'');
        const adapter=new ReferenceDenoiserAdapter({weightsBaseUrl,backend:'cpu',quality:'fast'});
        try {
            const results=[];
            for(const scale of scales) {
                const input=Float32Array.from(rgba,(value)=>value*scale);
                const output=await adapter.execute(input,width,height,{revision:1,isCurrent:(revision)=>revision===1});
                results.push({scale,rgba:Array.from(output.data,(value,index)=>index%4===3?value:value/scale)});
            }
            return {weightsBaseUrl,results};
        } finally {
            await adapter.dispose();
        }
    },{rgba:low.rgba,width:low.width,height:low.height,scales});

    const raw=metrics(low.rgba,reference.rgba,low.width,low.height);
    const sweep=outputs.results.map(({scale,rgba})=>({scale,...metrics(rgba,reference.rgba,low.width,low.height)}));
    const best=[...sweep].sort((left,right)=>left.rmse-right.rmse)[0];
    const report={fixture:'denoiser-smoke/hdr.scene',resolution:[low.width,low.height],inputSamples:low.samples,
        referenceSamples:reference.samples,backend:'TFJS CPU under Chrome SwiftShader',colorSpace:'linear-radiance',
        weightsBaseUrl:outputs.weightsBaseUrl,weightResponses,externalRequests,browserErrors,raw16:raw,sweep,bestScale:best.scale,
        bestRmse:best.rmse,relativeToRawRmse:best.rmse/raw.rmse,
        conclusion:best.rmse<raw.rmse?'exposure-scaling-improves-this-fixture':'no-tested-exposure-scale-beats-raw-input'};
    assert.ok(weightResponses.some((status)=>status===200),'local HDR weights did not return HTTP 200');
    assert.deepEqual(externalRequests,[],'quality sweep made a cross-origin request');
    assert.deepEqual(browserErrors,[],'browser reported an error during exposure sweep');
    assert.ok(sweep.every((entry)=>Number.isFinite(entry.rmse)&&Number.isFinite(entry.psnr)));
    await mkdir(artifactDirectory,{recursive:true});
    await writeFile(outputPath,`${JSON.stringify(report,null,2)}\n`);
    console.log(JSON.stringify(report,null,2));
} finally {
    await browser?.close();
    vite.kill();
}
