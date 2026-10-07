import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdir,writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright-core';

const root=process.cwd();
const outputPath=path.join(root,'artifacts/mtlx-reference-alignment/t029-denoiser-runtime.json');
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
    const weightResponses=[];
    page.on('pageerror',(error)=>browserErrors.push(error.message));
    page.on('console',(message)=>{ if(message.type()==='error') browserErrors.push(message.text()); });
    page.on('request',(request)=>requests.push(request.url()));
    page.on('response',(response)=>{
        if(response.url().includes('rt_hdr_small.tza')) weightResponses.push({url:response.url(),status:response.status()});
    });

    await page.goto(`${baseUrl}?renderer_mode=Rasterizer%20MTLX&render_size=max`,{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>window.__openpbrReady===true,null,{timeout:240000});
    const result=await page.evaluate(async()=>{
        const {ReferenceDenoiserAdapter}=await import('./src/denoiser/referenceDenoiserAdapter.js');
        const weightsBaseUrl=new URL('denoiser/tzas',location.href).href.replace(/\/$/,'');
        const adapter=new ReferenceDenoiserAdapter({weightsBaseUrl,backend:'cpu',quality:'fast'});
        const width=64,height=64;
        const rgba=new Float32Array(width*height*4);
        let inputZeroComponents=0,inputFractionalComponents=0;
        for(let y=0;y<height;y++) for(let x=0;x<width;x++) {
            const index=(y*width+x)*4;
            rgba[index]=(x/(width-1))*2.0;
            rgba[index+1]=(y/(height-1))*1.5;
            rgba[index+2]=((x>>3)+(y>>3))%2===0?0.25:4.0;
            rgba[index+3]=1.0;
        }
        for(const value of rgba) {
            if(value===0) inputZeroComponents++;
            if(value!==Math.trunc(value)) inputFractionalComponents++;
        }
        try {
            const output=await adapter.execute(rgba,width,height,{revision:1,isCurrent:(revision)=>revision===1});
            let finiteComponents=0,outputMin=Infinity,outputMax=-Infinity;
            for(const value of output.data) {
                if(Number.isFinite(value)) finiteComponents++;
                outputMin=Math.min(outputMin,value);
                outputMax=Math.max(outputMax,value);
            }
            return {width:output.width,height:output.height,channels:output.channels,
                components:output.data.length,finiteComponents,inputAboveOne:output.aboveOneInput,
                inputZeroComponents,inputFractionalComponents,outputMin,outputMax,
                backend:adapter.backendName,weightsBaseUrl:adapter.weightsBaseUrl};
        } finally {
            await adapter.dispose();
        }
    });

    const externalRequests=requests.filter((url)=>new URL(url).origin!==new URL(baseUrl).origin);
    const report={baseUrl,inputPattern:'asymmetric RGB gradient/checker with zero, fractional, and >1 HDR values',
        execution:result,weightResponses,externalRequests,browserErrors};
    assert.deepEqual([report.execution.width,report.execution.height,report.execution.channels,report.execution.components],[64,64,4,64*64*4]);
    assert.equal(report.execution.finiteComponents,report.execution.components);
    assert.ok(report.execution.inputZeroComponents>0,'known input pattern must include zero-valued components');
    assert.ok(report.execution.inputFractionalComponents>0,'known input pattern must include fractional components');
    assert.ok(report.execution.inputAboveOne>0,'known HDR input pattern did not retain values above one');
    assert.equal(report.execution.backend,'cpu');
    assert.ok(report.execution.weightsBaseUrl.startsWith(new URL(baseUrl).origin),'weights base must be same-origin');
    assert.ok(weightResponses.some((response)=>response.status===200),'local HDR weights were not fetched successfully');
    assert.deepEqual(externalRequests,[],'denoiser smoke made a cross-origin request');
    assert.deepEqual(browserErrors,[],'browser reported an error during denoiser initialization or execution');
    report.result='passed';
    await mkdir(path.dirname(outputPath),{recursive:true});
    await writeFile(outputPath,`${JSON.stringify(report,null,2)}\n`);
    console.log(JSON.stringify(report,null,2));
} finally {
    await browser?.close();
    vite.kill();
}