import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { adaptSceneLights, intersectSceneLight, LOCAL_MTLX_LIGHT_TYPE, packLocalLightTexels,
    LIGHT_SAMPLING_MODE, quadSolidAnglePdf, SCENE_LIGHT_TYPE, sphereSolidAnglePdf } from '../../src/scene/lightAdapter.js';

const scene = (...lights) => ({ blocks:lights.map((values,index) => ({ type:'light',name:`light-${index}`,values })) });

test('scene light enums map to local directional/quad/sphere IDs with emission kept linear', () => {
    const [quad,sphere,distant] = adaptSceneLights(scene(
        {type:'quad',position:[-1,2,-1],v1:[1,2,-1],v2:[-1,2,1],emission:[4,2,1]},
        {type:'sphere',position:[0,3,0],radius:0.5,emission:[3,2,1]},
        {type:'distant',position:[0,2,0],emission:[1,0.5,0.25]}));
    assert.deepEqual(SCENE_LIGHT_TYPE,{quad:0,sphere:1,distant:2});
    assert.deepEqual([quad.type,sphere.type,distant.type],[LOCAL_MTLX_LIGHT_TYPE.quad,LOCAL_MTLX_LIGHT_TYPE.sphere,LOCAL_MTLX_LIGHT_TYPE.directional]);
    assert.deepEqual(quad.u,[2,0,0]);
    assert.deepEqual(quad.v,[0,0,2]);
    assert.equal(quad.area,4);
    assert.equal(sphere.area,Math.PI);
    assert.deepEqual(distant.sourceDirection,[0,1,0]);
    assert.deepEqual(distant.direction,[0,-1,0]);
    assert.deepEqual(quad.emission,[4,2,1]);
    assert.equal(quad.intensity,1);
});

test('six-texel packing matches the local GetMtlxLight ABI and empty scenes retain a zero sentinel', () => {
    const lights = adaptSceneLights(scene(
        {type:'quad',position:[0,0,0],v1:[2,0,0],v2:[0,0,3],emission:[1,2,3]},
        {type:'sphere',position:[0,2,0],radius:1,emission:[2,3,4]}));
    const packed = packLocalLightTexels(lights);
    assert.deepEqual([packed.width,packed.height,packed.count],[6,2,2]);
    assert.deepEqual(Array.from(packed.data.slice(0,24)),[
        0,0,0,0, 0,0,0,3, 1,2,3,1, 1,1,0,0, 2,0,0,0, 0,0,3,0,
    ]);
    assert.equal(packed.data[24+7],LOCAL_MTLX_LIGHT_TYPE.sphere);
    const empty = packLocalLightTexels([]);
    assert.deepEqual([empty.width,empty.height,empty.count],[6,1,0]);
    assert.ok(empty.data.every((value) => value === 0));
});

test('invalid emission, distant direction, sphere radius, quad geometry and light records fail closed', () => {
    assert.throws(() => adaptSceneLights(scene({type:'quad',position:[0,0,0],v1:[1,0,0],v2:[0,1,0],emission:[1,-1,1]})),/EMISSION_INVALID/);
    assert.throws(() => adaptSceneLights(scene({type:'distant',position:[0,0,0],emission:[1,1,1]})),/DIRECTION_INVALID/);
    assert.throws(() => adaptSceneLights(scene({type:'sphere',position:[0,1,0],radius:0,emission:[1,1,1]})),/RADIUS_INVALID/);
    assert.throws(() => adaptSceneLights(scene({type:'quad',position:[0,0,0],v1:[1,0,0],v2:[1,1,0],emission:[1,1,1]})),/NON_ORTHOGONAL/);
    assert.throws(() => packLocalLightTexels([{position:[0,0,0],direction:[0,0,0],color:[1,1,1]}]),/RECORD_INVALID/);
});

test('quad/sphere directional PDFs use area-to-solid-angle and full-sphere interior conventions', () => {
    assert.equal(quadSolidAnglePdf(2,16,0.5),16);
    assert.equal(quadSolidAnglePdf(2,16,0),0);
    assert.ok(Math.abs(sphereSolidAnglePdf(1,0)-1/(4*Math.PI))<1e-12);
    const outsidePdf = sphereSolidAnglePdf(1,5);
    const solidAngle = 2*Math.PI*(1-Math.sqrt(1-1/25));
    assert.ok(Math.abs(outsidePdf-1/solidAngle)<1e-12);
});

test('analytic quad/sphere intersections honor quad sidedness and nearest-hit distance', () => {
    const [quad,sphere] = adaptSceneLights(scene(
        {type:'quad',position:[-1,-1,0],v1:[1,-1,0],v2:[-1,1,0],emission:[2,2,2]},
        {type:'sphere',position:[0,0,-2],radius:0.5,emission:[3,3,3]}));
    const front = intersectSceneLight([quad,sphere],[0,0,2],[0,0,-1]);
    assert.deepEqual([front.lightIndex,front.distance], [0,2]);
    assert.deepEqual(front.normal,[0,0,1]);
    assert.equal(intersectSceneLight([quad],[0,0,-2],[0,0,1]),null);
    const sphereInside = intersectSceneLight([sphere],[0,0,-2],[1,0,0]);
    assert.equal(sphereInside.distance,0.5);
});

test('viewer routes scene lights authoritatively and shader contains NEE/MIS/emitter paths', () => {
    const main = readFileSync(new URL('../../main.js',import.meta.url),'utf8');
    const shader = readFileSync(new URL('../../glsl/pathtracing/mtlx/pathtracer.glsl',import.meta.url),'utf8');
    assert.match(main,/adaptSceneLights\(activeReferenceScene\.scene\)/);
    assert.match(main,/activeReferenceScene \|\| search\.has\('mtlx_lights_json'\)/);
    assert.match(main,/mtlxDisableSun\.value = !!activeReferenceScene/);
    assert.match(main,/data\.set\(packLocalLightTexels\(lights\)\.data\)/);
    assert.match(main,/sceneHideEmitters\.value = rendererBlock\?\.values\.hideemitters === true/);
    assert.match(shader,/mtlxLightDirectionalPdf\(i,pW,shadowW\)/);
    assert.match(shader,/TraceShadow\(shadowOrigin, shadowW, maxDistance\)/);
    assert.match(shader,/P_mtlx \* selectedPower \/ w_mtlx \* mtlxLightDirectionalPdf/);
    assert.match(shader,/lightIsDelta = selectedLight\.type == 0 \|\| selectedLight\.type == 1 \|\| selectedLight\.type == 2/);
    assert.match(shader,/lightIsDelta \|\| sceneLightSamplingMode == 1/);
    assert.match(shader,/MATERIAL_SCENE_LIGHT_BASE \+ sceneLightIndex/);
    assert.match(shader,/if \(material_next >= MATERIAL_SCENE_LIGHT_BASE\)/);
    assert.match(shader,/vertex > 0 \|\| !sceneHideEmitters/);
    assert.match(shader,/if \(light.type == 3\)/);
    assert.match(shader,/if \(light.type == 4\)/);
    assert.match(shader,/1\.0\/solidAngle : 0\.0/);
    assert.match(shader,/sceneLightSamplingMode == 2/);
    assert.match(shader,/sceneLightSamplingMode == 1 && vertex > 0/);
    assert.match(shader,/sceneLightSamplingMode == 0 && vertex > 0/);
    assert.deepEqual(LIGHT_SAMPLING_MODE,{mis:0,nee:1,bsdf:2});
});

function deterministicRandom(seed) {
    let state = seed >>> 0;
    return () => {
        state += 0x6D2B79F5;
        let value = state;
        value = Math.imul(value ^ value >>> 15,value | 1);
        value ^= value + Math.imul(value ^ value >>> 7,value | 61);
        return ((value ^ value >>> 14) >>> 0)/4294967296;
    };
}

function powerHeuristic(firstPdf,secondPdf) {
    const firstSquared = firstPdf*firstPdf;
    return firstSquared/(firstSquared+secondPdf*secondPdf);
}

function estimateDiffuseQuad(mode,sampleCount) {
    const random = deterministicRandom(0x51a7);
    const albedo = 0.8;
    const emission = 5.0;
    const contributions = [];
    for (let sampleIndex=0; sampleIndex<sampleCount; sampleIndex++) {
        let contribution = 0;
        if (mode !== 'bsdf') {
            const lightX = random()-0.5;
            const lightY = random()-0.5;
            const distanceSquared = lightX*lightX+lightY*lightY+4;
            const distance = Math.sqrt(distanceSquared);
            const cosSurface = 2/distance;
            const cosLight = cosSurface;
            const lightPdf = quadSolidAnglePdf(1,distanceSquared,cosLight);
            const bsdfPdf = cosSurface/Math.PI;
            const misWeight = mode === 'mis' ? powerHeuristic(lightPdf,bsdfPdf) : 1;
            contribution += albedo/Math.PI*emission*cosSurface/lightPdf*misWeight;
        }
        if (mode !== 'nee') {
            const radialSample = Math.sqrt(random());
            const azimuth = 2*Math.PI*random();
            const directionX = radialSample*Math.cos(azimuth);
            const directionY = radialSample*Math.sin(azimuth);
            const directionZ = Math.sqrt(Math.max(0,1-radialSample*radialSample));
            const distance = 2/directionZ;
            const hitX = directionX*distance;
            const hitY = directionY*distance;
            if (Math.abs(hitX)<=0.5 && Math.abs(hitY)<=0.5) {
                const distanceSquared = distance*distance;
                const lightPdf = quadSolidAnglePdf(1,distanceSquared,directionZ);
                const bsdfPdf = directionZ/Math.PI;
                const misWeight = mode === 'mis' ? powerHeuristic(bsdfPdf,lightPdf) : 1;
                contribution += albedo*emission*misWeight;
            }
        }
        contributions.push(contribution);
    }
    const mean = contributions.reduce((sum,value) => sum+value,0)/sampleCount;
    const variance = contributions.reduce((sum,value) => sum+(value-mean)*(value-mean),0)/(sampleCount-1);
    return { mean,variance };
}

function analyticDiffuseQuad() {
    const subdivisions = 512;
    const albedo = 0.8;
    const emission = 5.0;
    let integral = 0;
    for (let row=0; row<subdivisions; row++) {
        const y = (row+0.5)/subdivisions-0.5;
        for (let column=0; column<subdivisions; column++) {
            const x = (column+0.5)/subdivisions-0.5;
            const distanceSquared = x*x+y*y+4;
            integral += albedo/Math.PI*emission*4/(distanceSquared*distanceSquared);
        }
    }
    return integral/(subdivisions*subdivisions);
}

test('NEE-only, BSDF-only and MIS converge to the analytic diffuse/quad reference', () => {
    const sampleCount = 100000;
    const reference = analyticDiffuseQuad();
    const nee = estimateDiffuseQuad('nee',sampleCount);
    const bsdf = estimateDiffuseQuad('bsdf',sampleCount);
    const mis = estimateDiffuseQuad('mis',sampleCount);
    for (const [name,estimate] of [['NEE',nee],['BSDF',bsdf],['MIS',mis]]) {
        assert.ok(Math.abs(estimate.mean-reference)/reference < 0.015,
            `${name} mean ${estimate.mean} diverges from analytic ${reference}`);
    }
    assert.ok(mis.variance < bsdf.variance,`MIS variance ${mis.variance} should beat BSDF-only ${bsdf.variance}`);
});