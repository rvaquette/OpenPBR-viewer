import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { getPathtracerTileGrid, mapSceneRendererOptions, parsePathtracerTileSize } from '../../src/scene/rendererAdapter.js';

test('shader compilation uses parallel support when available and preserves fallback errors', async () => {
    const source = readFileSync(new URL('../../main.js',import.meta.url),'utf8').replace(/\r\n/g,'\n');
    const compileFunction = source.match(/function compileShaderObject\(object,camera\)\n\{[\s\S]*?\n\}/)?.[0];
    assert.ok(compileFunction);
    const object = {};
    const camera = {};
    for (const supported of [false,true]) {
        const calls = [];
        const renderer = {
            extensions:{has(name) { assert.equal(name,'KHR_parallel_shader_compile'); return supported; }},
            compile(mesh,view) { assert.equal(mesh,object); assert.equal(view,camera); calls.push('sync'); },
            compileAsync(mesh,view) { assert.equal(mesh,object); assert.equal(view,camera); calls.push('async'); return Promise.resolve(); },
        };
        await runInNewContext(`${compileFunction}\ncompileShaderObject(object,camera)`,{renderer,object,camera});
        assert.deepEqual(calls,[supported ? 'async' : 'sync']);
    }
    const renderer = { extensions:{has:() => false},compile() { throw new Error('compilation failed'); } };
    await assert.rejects(runInNewContext(`${compileFunction}\ncompileShaderObject(object,camera)`,
        {renderer,object,camera}),/compilation failed/);
});

test('scene renderer options map supported limits, color and display settings', () => {
    assert.deepEqual(mapSceneRendererOptions({
        resolution:[640,360],maxdepth:5,maxvolumesteps:24,fireflyclamp:12,maxspp:256,
        envmapintensity:0.4,hideemitters:true,enablebackground:false,backgroundcolor:[0.1,0.2,0.3],
        enabletonemap:true,enableaces:true,
    }),{
        resolution:[640,360],bounces:5,max_volume_steps:24,firefly_clamp:12,max_samples:256,skyPower:0.4,
        hideemitters:true,enablebackground:false,backgroundColor:[0.1,0.2,0.3],enabletonemap:true,enableaces:true,
    });
});

test('explicit URL/GUI keys override scene renderer values, absent keys preserve scene authority', () => {
    assert.deepEqual(mapSceneRendererOptions({resolution:[640,360],maxdepth:5,envmapintensity:0.4},
        new Set(['render_size','bounces'])),{skyPower:0.4});
    assert.deepEqual(mapSceneRendererOptions({maxspp:100},new Set()),{max_samples:100});
});

test('unsupported renderer semantics fail closed instead of silently changing the image', () => {
    assert.throws(() => mapSceneRendererOptions({transparentbackground:true}),/TRANSPARENT_BACKGROUND_UNSUPPORTED/);
    assert.throws(() => mapSceneRendererOptions({enableaces:true,enabletonemap:false}),/OPTION_CONFLICT/);
    assert.throws(() => mapSceneRendererOptions({envmaprotation:30}),/ENV_ROTATION_UNSUPPORTED/);
    assert.throws(() => mapSceneRendererOptions({openglnormalmap:true}),/NORMALMAP_CONVENTION_UNSUPPORTED/);
});

test('viewer consumes scene renderer mappings, applies resize/tone settings and keeps named scenes resettable', () => {
    const main = readFileSync(new URL('../../main.js',import.meta.url),'utf8');
    assert.match(main,/mapSceneRendererOptions\(sceneRenderer,explicitRendererOverrides\)/);
    assert.match(main,/if \(activeSceneRenderResolution\) return/);
    assert.match(main,/params\[key\] = activeSceneRendererOptions\[key\]/);
    assert.match(main,/renderer\.toneMapping = ACESFilmicToneMapping/);
    assert.match(main,/renderer\.toneMapping = LinearToneMapping/);
    assert.match(main,/rendererOptions\.enablebackground === false \|\| is_pathtracing_route\(\) \? null : env_map_texture/);
    assert.match(main,/getPathtracerTileGrid\(\s*renderDimensions,activeSceneRendererOptions \|\| \{\},params\.tile_size\)/);
    assert.match(main,/Math\.min\(tileWidth, renderDimensions\.w - viewportX\)/);
    assert.match(main,/Math\.min\(tileHeight, renderDimensions\.h - viewportY\)/);
    assert.match(main,/params\.scene_url = ''/);
    assert.match(main,/activeReferenceResources = null/);
});

test('scene tile dimensions drive a dynamic grid at the actual render resolution', () => {
    const settings = mapSceneRendererOptions({tilewidth:256,tileheight:144});
    assert.deepEqual(settings,{tileWidth:256,tileHeight:144});
    assert.deepEqual(getPathtracerTileGrid({w:320,h:180},settings),{
        tileWidth:256,tileHeight:144,columns:2,rows:2,
    });
    assert.deepEqual(getPathtracerTileGrid({w:1280,h:720},settings),{
        tileWidth:256,tileHeight:144,columns:5,rows:5,
    });
    assert.deepEqual(getPathtracerTileGrid({w:320,h:180}),{
        tileWidth:64,tileHeight:64,columns:5,rows:3,
    });
    assert.deepEqual(getPathtracerTileGrid({w:32,h:18},settings),{
        tileWidth:256,tileHeight:144,columns:1,rows:1,
    });
    for (const invalid of [0,-1,1.5,Infinity])
        assert.throws(() => mapSceneRendererOptions({tilewidth:invalid}),/TILE_SIZE_INVALID/);
});

test('explicit tile-size overrides scene tiles and validates positive integer dimensions', () => {
    const settings = mapSceneRendererOptions({tilewidth:256,tileheight:144});
    assert.deepEqual(getPathtracerTileGrid({w:320,h:180},settings,'64x64'),{
        tileWidth:64,tileHeight:64,columns:5,rows:3,
    });
    assert.deepEqual(getPathtracerTileGrid({w:320,h:180},{},'128x72'),{
        tileWidth:128,tileHeight:72,columns:3,rows:3,
    });
    assert.deepEqual(parsePathtracerTileSize('32X16'),{tileWidth:32,tileHeight:16});
    for (const invalid of ['0x64','64x0','-1x64','1.5x64','64','64x64x64','Infinityx64','99999999999999999x64'])
        assert.throws(() => parsePathtracerTileSize(invalid),/PATHTRACER_TILE_SIZE_INVALID/);
});

test('launcher normalizes tile-size and tile_size before starting the server', () => {
    const source = readFileSync(new URL('../../launch_render.mjs',import.meta.url),'utf8').replace(/\r\n/g,'\n');
    const block = source.match(/if \(options\['tile-size'\][^\n]*\n[\s\S]*?\n\}/)?.[0];
    assert.ok(block);
    assert.ok(source.indexOf(block) < source.indexOf('let viteProcess = null'));
    for (const [options,expected] of [
        [{'tile-size':'32X16'},'32x16'],
        [{tile_size:'128x72'},'128x72'],
        [{'tile-size':'32x16',tile_size:'64x64'},'64x64'],
        [{},undefined],
    ]) {
        runInNewContext(block,{options,parsePathtracerTileSize});
        assert.equal(options.tile_size,expected);
        assert.equal(options['tile-size'],undefined);
    }
    assert.throws(() => runInNewContext(block,{options:{'tile-size':'0x64'},parsePathtracerTileSize}),
        /PATHTRACER_TILE_SIZE_INVALID/);
});