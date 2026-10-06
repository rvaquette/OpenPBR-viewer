import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { mapSceneRendererOptions } from '../../src/scene/rendererAdapter.js';

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
    assert.match(main,/rendererOptions\.enablebackground === false \? null : env_map_texture/);
    assert.match(main,/params\.scene_url = ''/);
    assert.match(main,/activeReferenceResources = null/);
});