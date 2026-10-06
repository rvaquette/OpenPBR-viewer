import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { ReferenceDenoiserAdapter, validateLinearRgba } from '../../src/denoiser/referenceDenoiserAdapter.js';
import { compareLinearRadianceRgb } from './denoiser-metrics.mjs';

test('linear RGBA input validates shape/finiteness without clipping HDR values', () => {
    const input = new Float32Array([0,0.5,3,1, 0.1,2,4,1]);
    assert.deepEqual(validateLinearRgba(input,2,1),{width:2,height:1,components:8,aboveOne:3});
    assert.throws(() => validateLinearRgba(input,1,1),/SHAPE_INVALID/);
    assert.throws(() => validateLinearRgba(new Float32Array([0,NaN,0,1]),1,1),/NONFINITE/);
    assert.throws(() => validateLinearRgba(new Uint8Array([0,0,0,255]),1,1),/TYPE_INVALID/);
});

test('adapter waits for input preparation and execute and returns finite HDR Float32 RGBA', async () => {
    const calls = [];
    const denoiser = {
        backendReady:true,timesGenerated:1,
        setInputData:async (_name,data,options) => { calls.push('input-start'); await Promise.resolve(); calls.push('input-ready'); denoiser.input=data; denoiser.options=options; },
        execute:async () => { assert.ok(calls.includes('input-ready')); calls.push('execute'); return denoiser.input.slice(); },
        onBackendReady(){},abort(){},dispose(){},resetInputs(){},
    };
    const adapter = new ReferenceDenoiserAdapter({weightsBaseUrl:'http://localhost/denoiser/tzas',origin:'http://localhost',createDenoiser:async()=>denoiser});
    const input = new Float32Array([0,0.5,3,1]);
    const result = await adapter.execute(input,1,1,{revision:12,isCurrent:(revision)=>revision===12});
    assert.deepEqual(calls,['input-start','input-ready','execute']);
    assert.deepEqual(denoiser.options,{flipY:true});
    assert.equal(denoiser.hdr,true);
    assert.equal(denoiser.srgb,false);
    assert.equal(result.aboveOneInput,1);
    assert.deepEqual([...result.data],[0,0.5,3,1]);
    await adapter.dispose();
});

test('adapter rejects concurrent/stale/invalid executions and disposes the active run', async () => {
    let release;
    const gate = new Promise((resolveGate)=>{release=resolveGate;});
    const denoiser = {
        backendReady:true,timesGenerated:1,
        setInputData:async()=>{},execute:async()=>{await gate;return new Float32Array([0,0,0,1]);},
        onBackendReady(){},abort(){},dispose(){},resetInputs(){},
    };
    const adapter = new ReferenceDenoiserAdapter({weightsBaseUrl:'http://localhost/denoiser/tzas',origin:'http://localhost',createDenoiser:async()=>denoiser});
    const run = adapter.execute(new Float32Array([0,0,0,1]),1,1,{revision:4,isCurrent:()=>false});
    await assert.rejects(adapter.execute(new Float32Array([0,0,0,1]),1,1),/DENOISER_BUSY/);
    release();
    await assert.rejects(run,/DENOISER_RESULT_STALE/);
    await adapter.dispose();
    assert.throws(() => new ReferenceDenoiserAdapter({weightsBaseUrl:'https://cdn.invalid/weights',origin:'http://localhost'}),/WEIGHTS_ORIGIN_INVALID/);
});

test('vendored bundle preparation patch, selected HDR weight hash and notices are pinned', () => {
    const bundle = readFileSync(resolve('src/denoiser/reference/denoiser.mjs'));
    const source = bundle.toString('utf8');
    const weight = readFileSync(resolve('public/denoiser/tzas/rt_hdr_small.tza'));
    const packageLicense = readFileSync(resolve('src/denoiser/reference/LICENSE'),'utf8');
    const weightsLicense = readFileSync(resolve('public/denoiser/tzas/LICENSE.txt'),'utf8');
    assert.equal(createHash('sha256').update(weight).digest('hex'),'c9171947f2bceb4367725b7a0d5b4e0d663ac44108386af42f1b49e4361952e7');
    assert.match(source,/async setInputData\(name, data, options = \{\}\)/);
    assert.match(source,/await handleInputTensors\(this, name, baseTensor, options\)/);
    assert.match(packageLicense,/MIT License/);
    assert.match(weightsLicense,/Apache License/);
});

test('viewer presents denoised data separately and redraws the final quad after accumulation stops', () => {
    const main = readFileSync(resolve('main.js'),'utf8');
    assert.match(main,/renderer\.readRenderTargetPixels\(pathtracingRenderTarget/);
    assert.match(main,/pathtracedFinalQuad\.material\.map = showResult \? denoisedPresentationTexture : pathtracingRenderTarget\?\.texture/);
    assert.match(main,/pathtracedFinalQuad\.render\(renderer\)/);
    assert.match(main,/function invalidateDenoiserResult\(\)[\s\S]*?denoiserRevision\+\+/);
    assert.match(main,/function resetSamples\(\)[\s\S]*?invalidateDenoiserResult\(\)/);
    assert.match(main,/referenceDenoiserAdapter\.execute\(raw\.rgba,width,height/);
});

test('linear RMSE/PSNR metrics preserve HDR values and reject mismatched/nonfinite captures', () => {
    const reference={width:1,height:1,rgba:[2,0.5,4,1]};
    const same=compareLinearRadianceRgb({width:1,height:1,rgba:[2,0.5,4,1]},reference);
    assert.equal(same.rmse,0);
    assert.equal(same.psnr,Infinity);
    assert.equal(same.aboveOneComponents,4);
    const noisy=compareLinearRadianceRgb({width:1,height:1,rgba:[3,0.5,4,1]},reference);
    assert.ok(noisy.rmse>0);
    assert.ok(noisy.psnr<Infinity);
    assert.throws(()=>compareLinearRadianceRgb({width:2,height:1,rgba:new Array(8).fill(0)},reference),/SHAPE_INVALID/);
    assert.throws(()=>compareLinearRadianceRgb({width:1,height:1,rgba:[NaN,0,0,1]},reference),/NONFINITE/);
});