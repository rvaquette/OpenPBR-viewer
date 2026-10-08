import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseSceneText, resolveSceneReferences, SceneParseError, SCENE_DIRECTIVE_POLICY } from '../../src/scene/sceneLoader.js';

function sceneError(text, pattern, url = 'https://viewer.test/scenes/test.scene') {
    assert.throws(() => parseSceneText(text,{url}), (error) => {
        assert.ok(error instanceof SceneParseError);
        assert.match(error.message, pattern);
        assert.equal(error.url,url);
        return true;
    });
}

test('directive policy matches the pinned JSON contract block-for-block', () => {
    const contract = JSON.parse(readFileSync(resolve('specs/005-mtlx-reference-alignment/scene-directives.json'),'utf8'));
    assert.deepEqual(JSON.parse(JSON.stringify(SCENE_DIRECTIVE_POLICY)),contract.blocks);
});

test('parse supports BOM/CRLF, quoted names, comments, out-of-order references and glTF glob overrides', () => {
    const text = '\uFEFFmesh\r\n{\r\n file "models/ball.glb" # file comment\r\n material "Warm Red"\r\n matrix 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1\r\n position 1 2 3\r\n}\r\ngltf\r\n{\r\n file "models/set.glb"\r\n object "Glass * Left" "Warm Red"\r\n object Glass?Right warm\r\n}\r\nmaterial "Warm Red"\r\n{\r\n color 0.7 0.1 0.03\r\n opacity 1\r\n}\r\nmaterial warm\r\n{\r\n color 0.2 0.3 0.4\r\n}\r\ncamera\r\n{\r\n position 0 0 5\r\n lookat 0 0 0\r\n}\r\nrenderer\r\n{\r\n resolution 320 240\r\n tilewidth 80\r\n tileheight 60\r\n envmapfile none\r\n}';
    const scene = parseSceneText(text,{url:'https://viewer.test/scenes/test.scene'});
    assert.equal(scene.blocks.length,6);
    assert.equal(scene.blocks[0].materialIndex,0);
    assert.equal(scene.blocks[1].repeated[0].materialIndex,0);
    assert.deepEqual(scene.blocks[0].values.position,[1,2,3]);
    assert.equal(scene.blocks[1].repeated[0].pattern,'Glass * Left');
    assert.equal(scene.blocks.find((block)=>block.type==='camera').values.aperture,0);
    assert.equal(scene.blocks.find((block)=>block.type==='camera').values.focaldist,1);
    assert.equal(scene.blocks.find((block)=>block.type==='camera').values.fov,45);
    assert.ok(scene.blocks[0].warnings.includes('MESH_MATRIX_OVERRIDES_TRS'));
    assert.ok(!scene.warnings.some((warning)=>warning.code==='SCENE_OPTION_NO_RUNTIME_EFFECT'));
    assert.equal(scene.blocks.find((block)=>block.type==='renderer').values.envmapfile,'none');
});

test('inline MaterialX is opaque to comments/braces and source ambiguity is rejected', () => {
    const scene = parseSceneText(`material inline\n{\n material_type materialx\n materialx_inline_begin\n<materialx>\n  <!-- # still xml } -->\n</materialx>\nmaterialx_inline_end\n}`);
    assert.match(scene.blocks[0].values.materialx_inline, /# still xml }/);
    sceneError(`material bad\n{\n materialx_document a.mtlx\n materialx_inline_begin\n<x/>\nmaterialx_inline_end\n}`,/SOURCE_AMBIGUOUS/);
    sceneError(`material bad\n{\n material_type materialx\n}`,/SOURCE_REQUIRED/);
    sceneError(`material bad\n{\n materialx_inline_begin\n<x/>\n}`,/INLINE_TERMINATOR_MISSING/);
    sceneError(`material bad\n{\n materialx_inline_begin\n\n materialx_inline_end\n}`,/SOURCE_EMPTY/);
});

test('unknown/rejected directives, duplicates, arity, nonfinite values and malformed blocks carry locations', () => {
    sceneError(`camera\n{\n position 0 0 1\n lookat 0 0 0\n mystery 1\n}`,/DIRECTIVE_UNKNOWN.*unknown camera directive/);
    sceneError(`material bad\n{\n specular NaN\n}`,/VALUE_INVALID/);
    sceneError(`materialx_generator pathtracer`,/DIRECTIVE_REJECTED.*root directive/);
    sceneError(`camera\n{\n position 0 0 NaN\n lookat 0 0 0\n}`,/VALUE_ARITY_INVALID/);
    sceneError(`renderer\n{\n resolution 640\n}`,/VALUE_ARITY_INVALID/);
    sceneError(`renderer\n{\n maxspp Infinity\n}`,/VALUE_INVALID/);
    sceneError(`camera\n{\n position 0 0 1\n position 1 1 1\n lookat 0 0 0\n}`,/DUPLICATE_DIRECTIVE/);
    sceneError(`camera\n{\n position 0 0 1\n lookat 0 0 0\n}\ncamera\n{\n position 0 0 2\n lookat 0 0 0\n}`,/DUPLICATE_BLOCK/);
    sceneError(`renderer\n{\n}\nrenderer\n{\n}`,/DUPLICATE_BLOCK/);
    sceneError(`material duplicate\n{\n}\nmaterial duplicate\n{\n}`,/DUPLICATE_MATERIAL/);
    sceneError(`camera\n{\n position 0 0 1\n lookat 0 0 0\n`,/BLOCK_UNCLOSED/);
    sceneError(`camera name\n{\n}`,/BLOCK_HEADER_INVALID/);
});

test('material source and light/camera/renderer semantic constraints are checked before resources', () => {
    sceneError(`light\n{\n emission 1 1 1\n}`,/REQUIRED_DIRECTIVE.*light type/);
    sceneError(`light\n{\n type sphere\n radius 0\n}`,/sphere radius must be positive/);
    sceneError(`light\n{\n type quad\n position 0 0 0\n v1 1 0 0\n v2 1 1 0\n}`,/LIGHT_QUAD_NON_ORTHOGONAL/);
    sceneError(`camera\n{\n position 0 0 0\n lookat 0 0 0\n}`,/position and lookat must differ/);
    sceneError(`mesh\n{\n file mesh.glb\n}`,/mesh requires an explicit material binding/);
    sceneError(`material typed\n{\n material_type materialx\n}`,/SOURCE_REQUIRED/);
    sceneError(`mesh\n{\n file file:///C:/secret.glb\n material X\n}`,/URL_UNSAFE/);
    sceneError(`mesh\n{\n file javascript:alert(1)\n material X\n}`,/URL_UNSAFE/);
    sceneError(`light\n{\n type distant\n position 0 0 0\n}`,/nonzero direction/);
});

test('references resolve independent of declaration order and object globs reject zero matches', () => {
    const scene = parseSceneText(`gltf\n{\n file set.glb\n object *Glass* Red\n}\nmesh\n{\n file ball.obj\n material Red\n}\nmaterial Red\n{\n color 1 0 0\n}`);
    assert.deepEqual(scene.blocks[0].repeated.map((override)=>override.materialIndex),[0]);
    assert.equal(scene.blocks[1].materialIndex,0);
    assert.throws(()=>resolveSceneReferences(scene,new Map([[0,['Plastic','Metal']]])),/OVERRIDE_NO_MATCH/);
    assert.throws(()=>parseSceneText(`mesh\n{\n file ball.obj\n material Missing\n}`),/REFERENCE_UNKNOWN/);
});

test('approved distant non-MTLX fixtures parse including Disney specular', () => {
    const corpus = JSON.parse(readFileSync(resolve('tools/mtlx-reference-alignment/corpus.json'),'utf8'));
    const referenceRoot = corpus.defaults.referenceRoot;
    for (const filename of ['cornell_box_orig.scene','cornell_box_sphere.scene']) {
        const source = readFileSync(join(referenceRoot,'scenes/pathtracer',filename),'utf8');
        const scene = parseSceneText(source,{url:`https://reference.test/scenes/pathtracer/${filename}`});
        assert.ok(scene.blocks.some((block)=>block.type==='camera'));
        assert.ok(scene.blocks.some((block)=>block.type==='renderer'));
        assert.ok(scene.blocks.some((block)=>block.type==='mesh'));
        assert.ok(scene.blocks.every((block)=>block.type!=='material' || block.effectiveMaterialType!=='materialx'));
    }
    const disneyGold = readFileSync(join(referenceRoot,'scenes/pathtracer/test_material_disney_gold.scene'),'utf8');
    const goldScene = parseSceneText(disneyGold,{url:'https://reference.test/scenes/pathtracer/test_material_disney_gold.scene'});
    assert.equal(goldScene.blocks.find((block) => block.name === 'ground').values.specular,1);
});