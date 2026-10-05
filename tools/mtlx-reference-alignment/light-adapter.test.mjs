import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { adaptSceneLights, intersectSceneLight, LOCAL_MTLX_LIGHT_TYPE, packLocalLightTexels,
    quadSolidAnglePdf, SCENE_LIGHT_TYPE, sphereSolidAnglePdf } from '../../src/scene/lightAdapter.js';

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
    assert.match(shader,/lightIsDelta \? 1\.0 : powerHeuristic/);
    assert.match(shader,/MATERIAL_SCENE_LIGHT_BASE \+ sceneLightIndex/);
    assert.match(shader,/if \(material_next >= MATERIAL_SCENE_LIGHT_BASE\)/);
    assert.match(shader,/vertex > 0 \|\| !sceneHideEmitters/);
    assert.match(shader,/if \(light.type == 3\)/);
    assert.match(shader,/if \(light.type == 4\)/);
    assert.match(shader,/1\.0\/solidAngle : 0\.0/);
});