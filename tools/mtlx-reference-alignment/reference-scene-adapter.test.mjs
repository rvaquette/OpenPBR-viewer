import test from 'node:test';
import assert from 'node:assert/strict';
import { BufferGeometry, Float32BufferAttribute, Group, Mesh } from 'three';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { loadReferenceSceneResources, prepareReferenceScene, resolveSceneResourceUrl } from '../../src/scene/referenceSceneAdapter.js';
import { externalSceneAssetUrl, externalSceneServer, isWithinSceneRoot } from '../../src/scene/externalSceneServer.mjs';
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { resolve } from 'node:path';

const sceneUrl = 'https://viewer.test/public/scenes/nested/demo.scene';

test('bundled Disney Gold scene loads three local OBJ meshes and distinct materials without external assets', async () => {
    const localUrl = 'https://viewer.test/OpenPBR-viewer/test-material-disney-gold/test_material_disney_gold.scene';
    const root = new URL('../../public/test-material-disney-gold/',import.meta.url);
    const prepared = await prepareReferenceScene(localUrl,{
        fetchImpl:async (url) => {
            assert.equal(url,localUrl);
            return response(readFileSync(new URL('test_material_disney_gold.scene',root),'utf8'));
        },
        createMaterialDocument:async () => '<materialx/>',
    });
    const resources = await loadReferenceSceneResources(prepared,{
        loadObj:async (url) => {
            const path = new URL(url).pathname.split('/test-material-disney-gold/')[1];
            assert.ok(path);
            return new OBJLoader().parse(readFileSync(new URL(path,root),'utf8'));
        },
    });
    assert.equal(resources.objects.length,3);
    assert.deepEqual(resources.objects.map(({materialName}) => materialName),['gold','gold','ground']);
    assert.equal(prepared.environmentUrl,null);
    assert.equal(resources.geometry.attributes.position.count / 3,974);
    const main = readFileSync(new URL('../../main.js',import.meta.url),'utf8');
    assert.match(main,/'Disney Gold Test':\s*'test-material-disney-gold'/);
    assert.match(main,/'test-material-disney-gold':'test-material-disney-gold\/test_material_disney_gold.scene'/);
    assert.match(main,/if \(LOCAL_REFERENCE_SCENES\[v\]\)[\s\S]*?await loadLocalReferenceScene\(v\)/);
});

test('launcher render-size alias selects rectangular canvas and render target dimensions', () => {
    const launcher = readFileSync(new URL('../../launch_render.mjs',import.meta.url),'utf8');
    const assignment = launcher.split(/\r?\n/).find((line) => line.startsWith('options.render_size ??='));
    const viewer = readFileSync(new URL('../../main.js',import.meta.url),'utf8').replace(/\r\n/g,'\n');
    const dimensionsFunction = viewer.match(/function getRenderDimensions\(\)\n\{[\s\S]*?\n\}/)?.[0];
    assert.ok(assignment);
    assert.ok(dimensionsFunction);
    for (const [options, expected] of [
        [{ 'render-size':'320x180' },[320,180]],
        [{ 'render-size':'256x192' },[256,192]],
        [{ 'render-size':'320x180',render_size:'128x64' },[128,64]],
        [{},[256,256]],
        [{render_size:'max'},[640,480]],
    ]) {
        runInNewContext(assignment,{options});
        const result = runInNewContext(`${dimensionsFunction}\ngetRenderDimensions()`,{
            params:{render_size:options.render_size}, activeSceneRenderResolution:null,
            window:{innerWidth:640,innerHeight:480},
        });
        assert.deepEqual([result.w,result.h],expected);
    }
});

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

test('preparation accepts multiple bindings and rejects missing adapters, bad formats and 404s', async () => {
    const fetchScene = (text) => async (url) => url === sceneUrl ? response(text) : response('<materialx/>');
    const multi = sceneText.replace('object "Glass *" main','object "Glass *" other')
        .replace('material main\n{\n materialx_document ../materials/main.mtlx\n}',
            'material main\n{\n materialx_document ../materials/main.mtlx\n}\nmaterial other\n{\n materialx_document ../materials/main.mtlx\n}');
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl:fetchScene(multi)});
    assert.deepEqual(prepared.materials.map(({name,variant}) => [name,variant]),[['main',2],['other',3]]);
    const nonMtlx = sceneText.replace('materialx_document ../materials/main.mtlx','color 0.5 0.5 0.5');
    await assert.rejects(prepareReferenceScene(sceneUrl,{fetchImpl:fetchScene(nonMtlx)}),/SCENE_MATERIAL_BINDING_UNSUPPORTED/);
    const unsupported = sceneText.replace('../models/object.glb','../models/object.fbx');
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

test('OBJ and indexed GLB meshes merge with missing normals and UVs', async () => {
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl:async (url) => url === sceneUrl
        ? response(sceneText.replace('object.glb','object.obj')) : response('<materialx/>')});
    const makeRoot = (indexed) => {
        const root = new Group();
        const geometry = new BufferGeometry();
        geometry.setAttribute('position',new Float32BufferAttribute([0,0,0, 1,0,0, 0,1,0],3));
        if (indexed) geometry.setIndex([0,1,2]);
        const mesh = new Mesh(geometry);
        mesh.name = 'Glass Pane';
        root.add(mesh);
        return root;
    };
    const calls = [];
    const resources = await loadReferenceSceneResources(prepared,{
        loadObj:async (url) => { calls.push(url); return makeRoot(false); },
        loadGltf:async () => ({scene:makeRoot(true)}),
        loadEnvironment:async () => ({texture:{dispose(){}},importance:null}),
    });
    assert.equal(calls[0],'https://viewer.test/public/scenes/models/object.obj');
    assert.equal(resources.geometry.attributes.position.count,6);
    assert.equal(resources.geometry.attributes.normal.count,6);
    assert.equal(resources.geometry.attributes.uv.count,6);
});

test('external scene server serves assets read-only and rejects traversal', async () => {
    const root = resolve('public');
    assert.equal(isWithinSceneRoot(root,resolve(root,'../private')),false);
    let middleware;
    externalSceneServer(root).configureServer({middlewares:{use(handler) { middleware = handler; }}});
    const server = createServer((request,response) => middleware(request,response,() => {
        response.writeHead(404); response.end();
    }));
    await new Promise((done) => server.listen(0,'127.0.0.1',done));
    const base = `http://127.0.0.1:${server.address().port}/external-scenes/`;
    try {
        assert.equal((await fetch(base + 'tmp_material.mtlx')).status,200);
        assert.equal((await fetch(base + '%2e%2e%2fpackage.json')).status,403);
        assert.equal((await fetch(base + 'tmp_material.mtlx',{method:'POST'})).status,405);
        assert.equal((await fetch(base + '%FF')).status,400);
    } finally { await new Promise((done) => server.close(done)); }
});

test('scene lights disable environment and irradiance even when declared in the renderer block', async () => {
    const text = sceneText + '\nlight\n{\n type sphere\n position 0 5 0\n radius 1\n emission 5 5 5\n}';
    const prepared = await prepareReferenceScene(sceneUrl,{fetchImpl:async (url) =>
        response(url === sceneUrl ? text : '<materialx/>')});
    assert.equal(prepared.environmentUrl,null);
    assert.equal(prepared.irradianceUrl,null);
    const withoutEnvironment = await prepareReferenceScene(sceneUrl,{fetchImpl:async (url) =>
        response(url === sceneUrl ? text.replace(' envmapfile ../env/studio.hdr\n','') : '<materialx/>')});
    assert.equal(withoutEnvironment.environmentUrl,null);
    assert.equal(withoutEnvironment.irradianceUrl,null);
});

test('explicit envmaps resolve through the configurable external root without copying assets', async () => {
    const root = resolve('public');
    assert.equal(externalSceneAssetUrl('HDR/studio light.hdr',root),'/external-scenes/HDR/studio%20light.hdr');
    assert.equal(externalSceneAssetUrl(resolve(root,'HDR/studio.hdr'),root),'/external-scenes/HDR/studio.hdr');
    assert.equal(externalSceneAssetUrl('https://assets.test/studio.hdr',root),'https://assets.test/studio.hdr');
    assert.equal(externalSceneAssetUrl('none',root),null);
    assert.throws(() => externalSceneAssetUrl('../private.hdr',root),/must be within/);
    const prepared = await prepareReferenceScene(sceneUrl,{
        fetchImpl:async (url) => response(url === sceneUrl ? sceneText : '<materialx/>'),
        environmentPath:'HDR/studio.hdr', irradiancePath:'HDR/irradiance/studio.hdr',
        environmentBaseUrl:'https://viewer.test/external-scenes/',
    });
    assert.equal(prepared.environmentUrl,'https://viewer.test/external-scenes/HDR/studio.hdr');
    assert.equal(prepared.irradianceUrl,'https://viewer.test/external-scenes/HDR/irradiance/studio.hdr');
});