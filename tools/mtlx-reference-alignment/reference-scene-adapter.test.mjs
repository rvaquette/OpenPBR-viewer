import test from 'node:test';
import assert from 'node:assert/strict';
import { BufferGeometry, Float32BufferAttribute, Group, Mesh } from 'three';
import { loadReferenceSceneResources, prepareReferenceScene, resolveSceneResourceUrl } from '../../src/scene/referenceSceneAdapter.js';

const sceneUrl = 'https://viewer.test/public/scenes/nested/demo.scene';
const sceneText = `material main
{
 materialx_document ../materials/main.mtlx
}
mesh
{
 file ../models/object.glb
 material main
 position 2 0 0
}
gltf
{
 file ../models/props.gltf
 object "Glass *" main
}
renderer
{
 envmapfile ../env/studio.hdr
 envmapirradiancefile none
}`.replace(/^\+/gm,'');

function response(body, status = 200) {
    return { ok:status >= 200 && status < 300, status, text:async () => body };
}

test('resource URLs resolve against their owning .scene URL and reject unsafe schemes', () => {
    assert.equal(resolveSceneResourceUrl('../models/a.glb',sceneUrl),'https://viewer.test/public/scenes/models/a.glb');
    assert.equal(resolveSceneResourceUrl('/public/a.glb',sceneUrl),'https://viewer.test/public/a.glb');
    assert.throws(() => resolveSceneResourceUrl('javascript:alert(1)',sceneUrl),/SCENE_RESOURCE_URL_UNSAFE/);
    assert.throws(() => resolveSceneResourceUrl('file:///secret.glb',sceneUrl),/SCENE_RESOURCE_URL_UNSAFE/);
});

test('preparation fetches the scene and MaterialX from their owner paths without loading geometry', async () => {
    const requests = [];
    const fetchImpl = async (url) => {
        requests.push(url);
        if (url === sceneUrl) return response(sceneText);
        if (url === 'https://viewer.test/public/scenes/materials/main.mtlx') return response('<materialx/>');
        return response('',404);
    };
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl});
    assert.deepEqual(requests,[sceneUrl,'https://viewer.test/public/scenes/materials/main.mtlx']);
    assert.equal(prepared.materialName,'main');
    assert.equal(prepared.materialBaseUrl,'https://viewer.test/public/scenes/materials/');
    assert.equal(prepared.geometry[0].url,'https://viewer.test/public/scenes/models/object.glb');
    assert.equal(prepared.geometry[1].url,'https://viewer.test/public/scenes/models/props.gltf');
    assert.equal(prepared.geometry[1].overrides[0].pattern,'Glass *');
    assert.equal(prepared.environmentUrl,'https://viewer.test/public/scenes/env/studio.hdr');
    assert.equal(prepared.irradianceUrl,null);
});

test('preparation fails closed for multiple material bindings, non-MaterialX sources, bad formats and 404s', async () => {
    const fetchScene = (text) => async (url) => url === sceneUrl ? response(text) : response('<materialx/>');
    const multi = sceneText.replace('object "Glass *" main','object "Glass *" other')
        .replace('material main\n{\n materialx_document ../materials/main.mtlx\n}',
            'material main\n{\n materialx_document ../materials/main.mtlx\n}\nmaterial other\n{\n materialx_document ../materials/main.mtlx\n}');
    await assert.rejects(prepareReferenceScene(sceneUrl,{fetchImpl:fetchScene(multi)}),/SCENE_MATERIAL_DISPATCH_UNSUPPORTED/);
    const nonMtlx = sceneText.replace('materialx_document ../materials/main.mtlx','color 0.5 0.5 0.5');
    await assert.rejects(prepareReferenceScene(sceneUrl,{fetchImpl:fetchScene(nonMtlx)}),/SCENE_MATERIAL_BINDING_UNSUPPORTED/);
    const unsupported = sceneText.replace('../models/object.glb','../models/object.obj');
    await assert.rejects(prepareReferenceScene(sceneUrl,{fetchImpl:fetchScene(unsupported)}),/SCENE_MESH_FORMAT_UNSUPPORTED/);
    await assert.rejects(prepareReferenceScene(sceneUrl,{fetchImpl:async () => response('',404)}),/SCENE_DOCUMENT_FETCH_FAILED/);
});

test('resource loading resolves real object globs, composes repeated transforms and loads scene envmaps locally', async () => {
    const fetchImpl = async (url) => url === sceneUrl ? response(sceneText)
        : response('<materialx/>');
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl});
    const calls = [];
    const loadGltf = async (url) => {
        calls.push(url);
        const root = new Group();
        const geometry = new BufferGeometry();
        geometry.setAttribute('position',new Float32BufferAttribute([0,0,0, 1,0,0, 0,1,0],3));
        const mesh = new Mesh(geometry);
        mesh.name = url.endsWith('props.gltf') ? 'Glass Pane' : 'Body';
        root.add(mesh);
        return { scene:root };
    };
    const environmentCalls = [];
    const resources = await loadReferenceSceneResources(prepared,{ loadGltf,
        loadEnvironment:async (url) => { environmentCalls.push(url); return { texture:{ dispose(){} }, importance:null }; } });
    assert.equal(calls.length,2);
    assert.deepEqual(environmentCalls,['https://viewer.test/public/scenes/env/studio.hdr']);
    assert.equal(resources.objectScene.children.length,2);
    resources.geometry.computeBoundingBox();
    assert.equal(resources.geometry.boundingBox.min.x,0);
    assert.equal(resources.geometry.boundingBox.max.x,3);
    assert.equal(prepared.scene.blocks[1].values.material,'main');
});

test('superseded scene loads reject before returning a publishable candidate', async () => {
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl:async (url) => url === sceneUrl
        ? response(sceneText) : response('<materialx/>')});
    const root = new Group();
    const geometry = new BufferGeometry();
    geometry.setAttribute('position',new Float32BufferAttribute([0,0,0, 1,0,0, 0,1,0],3));
    const mesh = new Mesh(geometry);
    mesh.name = 'Glass Pane';
    root.add(mesh);
    await assert.rejects(loadReferenceSceneResources(prepared,{ loadGltf:async () => ({scene:root}),
        loadEnvironment:async () => ({texture:{dispose(){}},importance:null}), isCurrent:() => false }),/SCENE_LOAD_SUPERSEDED/);
});