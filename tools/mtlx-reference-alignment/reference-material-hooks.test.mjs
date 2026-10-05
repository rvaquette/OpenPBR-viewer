import test from 'node:test';
import assert from 'node:assert/strict';
import { emitMtlxMaterialValueFunction, emitMtlxOpenPbrOpaqueFunction } from '../../src/mtlx/referenceMaterialHooks.js';

const descriptors = [
    { name:'geometry_thin_walled', type:'bool', index:0, tableBacked:true },
    { name:'transmission_weight', type:'float', index:1, tableBacked:true },
    { name:'emission_color', type:'vec3', index:2, tableBacked:true },
    { name:'thin_film_thickness', type:'float', index:3, tableBacked:true },
    { name:'specular_roughness', type:'float', index:4, tableBacked:true },
    { name:'emission_luminance', type:'float', index:5, tableBacked:true },
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