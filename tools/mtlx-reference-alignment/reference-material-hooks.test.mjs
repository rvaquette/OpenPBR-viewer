import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { BufferGeometry, Float32BufferAttribute } from 'three';
import { buildReferenceSurfaceScene } from '../../src/bvh/referenceRuntimeAdapter.js';
import { assertReferenceMaterialCoverage, createReferenceMaterialRegistry } from '../../src/mtlx/referenceMaterialRegistry.js';
import { bindMtlxVariantHookFunctions, emitMtlxMaterialValueFunction, emitMtlxOpenPbrOpaqueFunction,
    validateMtlxVariantFeatures } from '../../src/mtlx/referenceMaterialHooks.js';

const descriptors = [
    { name:'geometry_thin_walled', type:'bool', index:0, tableBacked:true },
    { name:'transmission_weight', type:'float', index:1, tableBacked:true },
    { name:'emission_color', type:'vec3', index:2, tableBacked:true },
    { name:'thin_film_thickness', type:'float', index:3, tableBacked:true },
    { name:'specular_roughness', type:'float', index:4, tableBacked:true },
    { name:'emission_luminance', type:'float', index:5, tableBacked:true },
    { name:'geometry_opacity', type:'float', index:6, tableBacked:true },
];

test('reference runtime builds BLAS/TLAS and preserves neutral and scene parameter variants', () => {
    const geometry = new BufferGeometry();
    geometry.setAttribute('position',new Float32BufferAttribute([
        0,0,0, 1,0,0, 0,1,0,
        2,0,0, 3,0,0, 2,1,0,
        4,0,0, 5,0,0, 4,1,0,
    ],3));
    geometry.setAttribute('neutralFlag',new Float32BufferAttribute([1,1,1,0,0,0,0,0,0],1));
    geometry.setAttribute('materialVariant',new Float32BufferAttribute([0,0,0,2,2,2,3,3,3],1));
    const {scene,records} = buildReferenceSurfaceScene(geometry,{materialKey:'gold',
        variants:[{variant:2,values:[0.02]},{variant:3,values:[0.5]}]});
    assert.equal(scene.instances.length,3);
    assert.deepEqual(records.map(({kind,parameterVariant}) => [kind,parameterVariant]),[
        ['props',0],['openpbr',2],['openpbr',3],
    ]);
    assert.equal(scene.geometry.vertexIndices.length,9);
    assert.equal(geometry.groups.length,0);
    assertReferenceMaterialCoverage(scene,createReferenceMaterialRegistry(records,{activeMaterialKey:'gold'}));
    geometry.attributes.materialVariant.setX(7,2);
    assert.throws(() => buildReferenceSurfaceScene(geometry,{materialKey:'gold'}),/TRIANGLE_MATERIAL_INVALID/);
    geometry.dispose();
});

test('Three.js shadow traversal restores the surface material variant on every return path', () => {
    const source = readFileSync(new URL('../../glsl/pathtracing/mtlx/pathtracer.glsl',import.meta.url),'utf8').replace(/\r\n/g,'\n');
    const start = source.indexOf('float TraceShadow(');
    const end = source.indexOf('\n////////////////////////////////////////////////',start);
    const shadow = source.slice(start,end).replace(
        /#ifdef REFERENCE_BVH_ENABLED\n([\s\S]*?)(?:#else\n([\s\S]*?))?#endif/g,
        (_match,_reference,active = '') => active);
    assert.match(shadow,/int previousMaterialVariant = mtlxMaterialVariant;[\s\S]*bool hit = trace\(/);
    assert.match(shadow,/mtlxMaterialVariant = previousMaterialVariant;\s*return 1\.0;/);
    assert.match(shadow,/mtlxMaterialVariant = previousMaterialVariant;\s*return hit \? 0\.0 : 1\.0;/);
});

test('generated material hooks read the active parameter variant instead of frozen document summaries', () => {
    assert.match(emitMtlxMaterialValueFunction('bool','mtlx_openpbr_is_thinwalled','thinWalled',false,descriptors),
        /mtlxGetMaterialParam\(0\)/);
    assert.match(emitMtlxMaterialValueFunction('float','mtlx_openpbr_transmission_weight','transmissionWeight',0,descriptors),
        /mtlxGetMaterialParam\(1\)/);
    assert.match(emitMtlxMaterialValueFunction('float','mtlx_openpbr_specular_roughness','specularRoughness',0.3,descriptors),
        /mtlxGetMaterialParam\(4\)/);
    assert.match(emitMtlxMaterialValueFunction('float','mtlx_openpbr_thin_film_thickness_nm','thinFilmThicknessNm',0,descriptors),
        /mtlxGetMaterialParam\(3\).*1000/);
    assert.match(emitMtlxMaterialValueFunction('vec3','mtlx_openpbr_emission','emission',[0,0,0],descriptors),
        /mtlxGetMaterialParam\(2\)\.xyz.*mtlxGetMaterialParam\(5\)\.x/);
});

test('opacity/thin-walled and sample-medium guards read current variant values', () => {
    const opaque = emitMtlxOpenPbrOpaqueFunction({ thinWalled:false,transmissionWeight:0 }, descriptors);
    const thinWalled = emitMtlxMaterialValueFunction('bool','mtlx_openpbr_is_thinwalled','thinWalled',false,descriptors);
    const transmission = emitMtlxMaterialValueFunction('float','mtlx_openpbr_transmission_weight','transmissionWeight',0,descriptors);
    assert.match(opaque, /mtlxGetMaterialParam\(0\)/);
    assert.match(opaque, /mtlxGetMaterialParam\(1\)/);
    assert.match(thinWalled, /mtlxGetMaterialParam\(0\)/);
    assert.match(transmission, /mtlxGetMaterialParam\(1\)/);
});

test('opaque/thin-walled hooks avoid stale prepare globals and read the active variant directly', () => {
    const generated = `bool mtlx_openpbr_is_opaque() { return g_ptOpacity >= 1.0 - 1.0e-6; }
bool mtlx_openpbr_is_thinwalled() { return geometry_thin_walled; }`;
    const bound = bindMtlxVariantHookFunctions(generated, descriptors);
    assert.match(bound, /mtlx_openpbr_is_opaque\(\) \{ return mtlxGetMaterialParam\(6\)\.x/);
    assert.match(bound, /mtlx_openpbr_is_thinwalled\(\) \{ return mtlxGetMaterialParam\(0\)\.x/);
    assert.doesNotMatch(bound, /g_ptOpacity/);
});

test('variants requiring volume, dispersion or thin-film fail closed when the compiled feature is absent', () => {
    const variantDescriptors = [
        { name:'transmission_weight',value:0,defaultValue:0 },
        { name:'transmission_depth',value:0,defaultValue:0 },
        { name:'geometry_thin_walled',value:false,defaultValue:false },
        { name:'transmission_dispersion_scale',value:0,defaultValue:0 },
        { name:'thin_film_weight',value:0,defaultValue:0 },
    ];
    const registry = (parameterValues) => ({ entries:[{kind:'openpbr',sceneMaterialID:9,parameterVariant:2,parameterValues}] });
    const disabled = { VOLUME_ENABLED:false, TRANSMISSION_ENABLED:false, THIN_FILM_ENABLED:false };
    assert.throws(() => validateMtlxVariantFeatures(registry([0.5,1,false,0,0]),variantDescriptors,disabled), /VOLUME_ENABLED/);
    assert.throws(() => validateMtlxVariantFeatures(registry([0.5,0,false,1,0]),variantDescriptors,disabled), /TRANSMISSION_ENABLED/);
    assert.throws(() => validateMtlxVariantFeatures(registry([0,0,false,0,0.5]),variantDescriptors,disabled), /THIN_FILM_ENABLED/);
    assert.equal(validateMtlxVariantFeatures(registry([0,0,false,0,0]),variantDescriptors,disabled),true);
});