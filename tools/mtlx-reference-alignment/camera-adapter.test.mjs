import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createSceneCamera, generatePrimaryRay, parseSceneCameraOverrides, verticalFovFromHorizontal } from '../../src/scene/cameraAdapter.js';

const cameraBlock = (values) => ({ type:'camera',values });
const close = (actual,expected,tolerance = 1.0e-10) => assert.ok(Math.abs(actual-expected) <= tolerance,`${actual} != ${expected}`);
const closeVector = (actual,expected,tolerance = 1.0e-10) => actual.forEach((value,index) => close(value,expected[index],tolerance));

test('horizontal scene FOV converts to vertical FOV for square, landscape and portrait aspect ratios', () => {
    for (const aspect of [1,16/9,9/16]) {
        const camera = createSceneCamera(cameraBlock({position:[0,0,5],lookat:[0,0,0],fov:60}),{aspect});
        close(2*Math.atan(Math.tan(camera.fovVertical*Math.PI/360)*aspect)*180/Math.PI,60);
        assert.ok(camera.fovVertical > 0 && camera.fovVertical < 180);
    }
    close(verticalFovFromHorizontal(60,1),60);
    assert.throws(() => verticalFovFromHorizontal(0,1),/FOV_INVALID/);
    assert.throws(() => verticalFovFromHorizontal(60,0),/ASPECT_INVALID/);
});

test('row-major camera matrix uses translation and third-column forward while dropping roll explicitly', () => {
    const matrix = [0,1,0,4, -1,0,0,5, 0,0,1,6, 0,0,0,1];
    const camera = createSceneCamera(cameraBlock({matrix,fov:45}),{aspect:1});
    closeVector(camera.position,[4,5,6]);
    closeVector(camera.forward,[0,0,1]);
    assert.ok(camera.warnings.includes('CAMERA_ROLL_DROPPED'));
    assert.throws(() => createSceneCamera(cameraBlock({matrix:[...matrix.slice(0,12),1,0,0,0]})),/MATRIX_NOT_AFFINE/);
});

test('scene camera wins over bounds, explicit URL overrides win over scene values', () => {
    const scene = cameraBlock({position:[1,2,3],lookat:[1,2,0],fov:40,aperture:0.04,focaldist:7});
    const fromScene = createSceneCamera(scene,{aspect:1,bounds:{min:[-20,-20,-20],max:[20,20,20]}});
    assert.equal(fromScene.source,'scene');
    closeVector(fromScene.position,[1,2,3]);
    const overridden = createSceneCamera(scene,{aspect:2,overrides:{position:[5,2,3],lookat:[0,2,3],fov:70,aperture:0,focaldist:2}});
    closeVector(overridden.position,[5,2,3]);
    closeVector(overridden.forward,[-1,0,0]);
    assert.equal(overridden.fovHorizontal,70);
    assert.equal(overridden.aperture,0);
    assert.equal(overridden.focaldist,2);
});

test('only explicit camera URL options override the scene and invalid overrides fail closed', () => {
    const params = new URLSearchParams('camera_fov=72&camera_position=1,2,3&camera_aperture=0.1');
    assert.deepEqual(parseSceneCameraOverrides(params),{ fov:72,position:[1,2,3],aperture:0.1 });
    assert.deepEqual(parseSceneCameraOverrides(new URLSearchParams()),{});
    assert.throws(() => parseSceneCameraOverrides(new URLSearchParams('camera_lookat=1,2')),/OVERRIDE_INVALID/);
    assert.throws(() => parseSceneCameraOverrides(new URLSearchParams('camera_focaldist=0')),/OVERRIDE_INVALID/);
});

test('missing scene camera frames local bounds and a vertical view uses a stable alternate up axis', () => {
    const fallback = createSceneCamera(null,{aspect:1,bounds:{min:[-2,-1,-4],max:[2,1,4]}});
    assert.equal(fallback.source,'bounds');
    closeVector(fallback.target,[0,0,0]);
    assert.ok(fallback.warnings.includes('SCENE_CAMERA_FRAMED_TO_BOUNDS'));
    const vertical = createSceneCamera(cameraBlock({position:[0,0,0],lookat:[0,1,0]}));
    close(dot(vertical.right,vertical.up),0);
    assert.throws(() => createSceneCamera(cameraBlock({position:[0,0,0],lookat:[0,0,0]})),/POSE_INVALID/);
});

function dot(a,b) { return a.reduce((sum,value,index) => sum + value*b[index],0); }

test('pinhole ray remains unchanged at aperture zero; depth-of-field rays converge at the focal point', () => {
    const pinhole = createSceneCamera(cameraBlock({position:[0,0,5],lookat:[0,0,0],fov:60,aperture:0,focaldist:4}),{aspect:16/9});
    const center = generatePrimaryRay(pinhole,[0,0],[0.75,0.25]);
    closeVector(center.origin,[0,0,5]);
    closeVector(center.direction,[0,0,-1]);
    const corner = generatePrimaryRay(pinhole,[1,1]);
    close(Math.atan2(dot(corner.direction,pinhole.right),dot(corner.direction,pinhole.forward))*180/Math.PI,30);

    const dof = createSceneCamera(cameraBlock({position:[0,0,5],lookat:[0,0,0],fov:60,aperture:0.25,focaldist:4}),{aspect:16/9});
    const ray = generatePrimaryRay(dof,[0.4,-0.3],[0.8,0.25]);
    assert.notDeepEqual(ray.origin,dof.position);
    const along = dot(subtract(ray.focalPoint,ray.origin),ray.direction);
    closeVector(add(ray.origin,scale(ray.direction,along)),ray.focalPoint,1.0e-9);
});

test('DOF uniforms belong to the pathtracer route and the shader gates lens sampling on positive aperture', () => {
    const main = readFileSync(new URL('../../main.js',import.meta.url),'utf8');
    const common = readFileSync(new URL('../../glsl/pathtracing/mtlx/common.glsl',import.meta.url),'utf8');
    const pathtracer = readFileSync(new URL('../../glsl/pathtracing/mtlx/pathtracer.glsl',import.meta.url),'utf8');
    const rasterMaterialStart = main.indexOf('openpbrMaterial = new ShaderMaterial');
    const pathtracerMaterialStart = main.indexOf('pathtracedMaterial = new ShaderMaterial');
    assert.ok(rasterMaterialStart >= 0 && pathtracerMaterialStart > rasterMaterialStart);
    assert.doesNotMatch(main.slice(rasterMaterialStart,pathtracerMaterialStart),/cameraAperture|cameraFocalDist/);
    assert.match(main.slice(pathtracerMaterialStart,pathtracerMaterialStart+16000),/cameraAperture:\s*\{ value: 0\.0 \}/);
    assert.match(main.slice(pathtracerMaterialStart,pathtracerMaterialStart+16000),/cameraFocalDist:\s*\{ value: 1\.0 \}/);
    assert.match(common,/uniform float cameraAperture;/);
    assert.match(common,/uniform float cameraFocalDist;/);
    assert.match(pathtracer,/if \(cameraAperture > 0\.0\)/);
    assert.match(pathtracer,/focalPoint - rayOrigin/);
});

function subtract(a,b) { return a.map((value,index) => value-b[index]); }
function add(a,b) { return a.map((value,index) => value+b[index]); }
function scale(vector,factor) { return vector.map((value) => value*factor); }