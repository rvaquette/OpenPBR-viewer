import test from 'node:test';
import assert from 'node:assert/strict';
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