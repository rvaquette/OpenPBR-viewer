import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { compareLinearRadianceRgb } from './denoiser-metrics.mjs';

const artifactDirectory=path.resolve('artifacts/mtlx-reference-alignment');
const cases=[
    {name:'hdr-quad',low:'denoiser-hdr-16spp-linear.json',reference:'denoiser-hdr-256spp-linear.json'},
    {name:'brick-texture-normal-quad50-aces',low:'t031-brick50-16spp-linear.json',reference:'t031-brick50-256spp-linear.json'},
    {name:'emissive-marble-quad50-aces',low:'t031-emissive50-16spp-linear.json',reference:'t031-emissive50-256spp-linear.json'},
    {name:'soapbubble-transmission-film-quad50-aces',low:'t031-transmission-film50-16spp-linear.json',reference:'t031-transmission-film50-256spp-linear.json'},
];

const read=(filename)=>JSON.parse(readFileSync(path.join(artifactDirectory,filename),'utf8'));
function meanRgb(rgba,width,height) {
    const sum=[0,0,0];
    const pixels=width*height;
    for(let pixel=0;pixel<pixels;pixel++) for(let channel=0;channel<3;channel++)
        sum[channel]+=rgba[pixel*4+channel];
    return sum.map((value)=>value/pixels);
}
function maxRgb(rgba,width,height) {
    const maximum=[-Infinity,-Infinity,-Infinity];
    const pixels=width*height;
    for(let pixel=0;pixel<pixels;pixel++) for(let channel=0;channel<3;channel++)
        maximum[channel]=Math.max(maximum[channel],rgba[pixel*4+channel]);
    return maximum;
}

const results=cases.map(({name,low:lowFile,reference:referenceFile})=>{
    const low=read(lowFile);
    const reference=read(referenceFile);
    assert.deepEqual([low.width,low.height],[reference.width,reference.height],`${name}: dimensions differ`);
    assert.ok(low.samples<reference.samples,`${name}: reference must use more samples`);
    assert.ok(Array.isArray(low.denoised),`${name}: missing denoised Float32 capture`);
    const shape={width:low.width,height:low.height};
    const rawMetrics=compareLinearRadianceRgb({...shape,rgba:low.rgba},{...shape,rgba:reference.rgba});
    const denoisedMetrics=compareLinearRadianceRgb({...shape,rgba:low.denoised},{...shape,rgba:reference.rgba});
    const referenceMeanRgb=meanRgb(reference.rgba,reference.width,reference.height);
    const denoisedMeanRgb=meanRgb(low.denoised,low.width,low.height);
    const signedEnergyBiasRgb=denoisedMeanRgb.map((value,index)=>value-referenceMeanRgb[index]);
    return {
        name,resolution:[low.width,low.height],lowSamples:low.samples,referenceSamples:reference.samples,
        colorSpace:'linear-radiance',quadEmission: name==='hdr-quad'?500:50,presentationToneMapping:'ACES',
        referenceKind:'same-scene Monte Carlo estimate, not analytic oracle',
        raw:{...rawMetrics,meanRGB:meanRgb(low.rgba,low.width,low.height)},
        denoised:{...denoisedMetrics,meanRGB:denoisedMeanRgb,maxRGB:maxRgb(low.denoised,low.width,low.height),
            signedEnergyBiasRgb,rmseRatioToRaw:denoisedMetrics.rmse/rawMetrics.rmse,
            improvesRmse:denoisedMetrics.rmse<rawMetrics.rmse},
        captures:{low:lowFile,reference:referenceFile},
    };
});

const hdr16=read('denoiser-hdr-16spp-linear.json');
const hdr64=read('denoiser-hdr-64spp-linear.json');
const hdr256=read('denoiser-hdr-256spp-linear.json');
const hdrRawConvergence={
    samples:[hdr16.samples,hdr64.samples,hdr256.samples],
    means:[hdr16.meanRGB,hdr64.meanRGB,hdr256.meanRGB],
    rmse16Vs256:compareLinearRadianceRgb({width:hdr16.width,height:hdr16.height,rgba:hdr16.rgba},
        {width:hdr256.width,height:hdr256.height,rgba:hdr256.rgba}).rmse,
    rmse64Vs256:compareLinearRadianceRgb({width:hdr64.width,height:hdr64.height,rgba:hdr64.rgba},
        {width:hdr256.width,height:hdr256.height,rgba:hdr256.rgba}).rmse,
};
const exposureSweep=read('t031-denoiser-exposure-sweep.json');
const qualityGatePassed=results.every((result)=>result.denoised.improvesRmse);
const report={version:1,generatedBy:'tools/mtlx-reference-alignment/denoiser-quality-summary.mjs',
    fixturePolicy:'16 spp candidate and denoised output versus same-fixture raw 256 spp reference; report results per fixture without assuming denoising must win',
    results,hdrRawConvergence,exposureSweep:{scales:exposureSweep.sweep.map(({scale,rmse,psnr})=>({scale,rmse,psnr})),
        bestScale:exposureSweep.bestScale,bestRmse:exposureSweep.bestRmse,rawRmse:exposureSweep.raw16.rmse,
        conclusion:exposureSweep.conclusion},
    qualityGatePassed,qualityVerdict:qualityGatePassed?'passed':'failed: denoised RMSE exceeds raw in one or more fixtures'};
process.stdout.write(`${JSON.stringify(report,null,2)}\n`);
