

import { Scene,
    Vector2, Vector3, Matrix4, Box3, Color,
    Mesh, MeshBasicMaterial, MeshStandardMaterial, MeshLambertMaterial, ShaderMaterial,
    PlaneGeometry,
    PerspectiveCamera, OrthographicCamera,
    DirectionalLight, AmbientLight, DoubleSide,
    LinearSRGBColorSpace, SRGBColorSpace, RGBAFormat, FloatType,
    WebGLRenderer, WebGLRenderTarget, TextureLoader, RepeatWrapping,
    EquirectangularReflectionMapping, CubeReflectionMapping,
    UniformsUtils, UniformsLib, ShaderLib,
    PCFSoftShadowMap, CameraHelper  } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { FullScreenQuad } from 'three/addons/postprocessing/Pass.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { mergeVertices } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import Stats from 'stats.js';

import {
MeshBVH, MeshBVHUniformStruct, FloatVertexAttributeTexture,
shaderStructs, shaderIntersectFunction, SAH, StaticGeometryGenerator
} from 'three-mesh-bvh';

import { GUI } from 'lil-gui';

// MTLX pathtracer host route (feature 003): copied integrator; the per-material
// dispatch (mtlxGen*) is generated at runtime and wired via an inline bridge.
import glsl_mtlx_route_common           from './glsl/pathtracing/mtlx/common.glsl?raw'
import glsl_mtlx_route_pathtracer       from './glsl/pathtracing/mtlx/pathtracer.glsl?raw'

import glsl_legacy_main            from './glsl/pathtracing/legacy/main.glsl?raw'
import glsl_legacy_fuzz_brdf       from './glsl/pathtracing/legacy/fuzz_brdf.glsl?raw'
import glsl_legacy_coat_brdf       from './glsl/pathtracing/legacy/coat_brdf.glsl?raw'
import glsl_legacy_thin_film       from './glsl/pathtracing/legacy/thin-film.glsl?raw'
import glsl_legacy_metal_brdf      from './glsl/pathtracing/legacy/metal_brdf.glsl?raw'
import glsl_legacy_specular_brdf   from './glsl/pathtracing/legacy/specular_brdf.glsl?raw'
import glsl_legacy_specular_btdf   from './glsl/pathtracing/legacy/specular_btdf.glsl?raw'
import glsl_legacy_diffuse_brdf    from './glsl/pathtracing/legacy/diffuse_brdf.glsl?raw'
import glsl_legacy_diffuse_btdf    from './glsl/pathtracing/legacy/diffuse_btdf.glsl?raw'
import glsl_legacy_openpbr_surface from './glsl/pathtracing/legacy/openpbr_surface.glsl?raw'
import glsl_legacy_pathtracer      from './glsl/pathtracing/legacy/pathtracer.glsl?raw'

import glsl_rasterization_openpbr_frag          from './glsl/rasterization/openpbr.frag.glsl?raw'
import glsl_rasterization_openpbr_vert          from './glsl/rasterization/openpbr.vert.glsl?raw'

import glsl_rasterization_neutral_frag          from './glsl/rasterization/neutral.frag.glsl?raw'
import glsl_rasterization_neutral_vert          from './glsl/rasterization/neutral.vert.glsl?raw'

import { Circle } from 'progressbar.js'

class MeshLoader
{
    constructor()
    {
        this.result = null;
        this.loader = new GLTFLoader();
    }

    reset()
    {
        this.result = null;
    }

    async load(path)
    {
        if (this.result) Promise.resolve(this.result);

        let gltf = await this.loader.loadAsync(path);
        let S = Array.isArray( gltf.scene ) ? gltf.scene : [ gltf.scene ];
        const meshes = [];

        for ( let i = 0, l = S.length; i < l; i++ )
        {
            S[i].traverseVisible( c =>
                {
                    if (c.isMesh)
                    {
                        meshes.push(c);
                    }
                }
            )
        }

        if (meshes.length > 0)
        {
            const generator = new StaticGeometryGenerator(meshes);
            generator.attributes = [ 'position', 'color', 'normal', 'tangent', 'uv', 'uv2' ];
            generator.applyWorldTransforms = false;
            let merged_mesh = new Mesh(generator.generate(), new MeshStandardMaterial());

            let bvh = new MeshBVH( merged_mesh.geometry, { strategy: SAH, maxLeafTris: 1 } );
            this.result = {scene:gltf.scene, bvh:bvh, mesh:merged_mesh};
            console.log("==> loaded mesh ", path);
        }

        return this.result;
    }
}

function array_to_vector3(array)
{
    return new Vector3(array[0], array[1], array[2]);
}

var params =
{
    //////////////////////////////////////////////////////
    // renderer params
    //////////////////////////////////////////////////////

    scene_name:                         'standard-shader-ball',
    renderer_mode:                      'Rasterizer',
    smooth_normals:                     true,
    bounces:                            6,
    max_samples:                        512,
    max_volume_steps:                   64,
    firefly_clamp:                      10.0,
    wireframe:                          false,
    neutral_color:                      [0.99, 0.99, 0.99],

    //////////////////////////////////////////////////////
    // lighting params
    //////////////////////////////////////////////////////

    skyPower:                            1.0,
    skyColor:                            [1.0, 1.0, 1.0],
    sunPower:                            0.25,
    sunAngularSize:                      5.0,
    sunLatitude:                         40.0,
    sunLongitude:                        315.0,
    sunColor:                            [1.0, 1.0, 1.0],

    //////////////////////////////////////////////////////
    // OpenPBR surface params
    //////////////////////////////////////////////////////

    base_weight:                         1.0,
    base_color:                          [0.8, 0.8, 0.8],
    base_diffuse_roughness:              0.0,
    base_metalness:                      0.0,

    specular_weight:                     1.0,
    specular_color:                      [1.0, 1.0, 1.0],
    specular_roughness:                  0.1,
    specular_anisotropy:                 0.0,
    specular_ior:                        1.5,
    specular_haze:                       0.0,
    specular_haze_spread:                0.3,
    specular_retroreflectivity:          0.0,

    transmission_weight:                 0.0,
    transmission_color:                  [1.0, 1.0, 1.0],
    transmission_depth:                  0.0,
    transmission_scatter:                [0.0, 0.0, 0.0],
    transmission_scatter_anisotropy:     0.0,
    transmission_dispersion_abbe_number: 20.0,
    transmission_dispersion_scale:       0.0,

    subsurface_weight:                   0.0,
    subsurface_color:                    [0.8, 0.8, 0.8],
    subsurface_radius:                   0.2,
    subsurface_radius_scale:             [1.0, 0.5, 0.25],
    subsurface_anisotropy:               0.0,

    coat_weight:                         0.0,
    coat_color:                          [1.0, 1.0, 1.0],
    coat_roughness:                      0.0,
    coat_anisotropy:                     0.0,
    coat_ior:                            1.6,
    coat_darkening:                      1.0,

    fuzz_weight:                         0.0,
    fuzz_color:                          [1.0, 1.0, 1.0],
    fuzz_roughness:                      0.5,

    emission_weight:                     0.0,
    emission_luminance:                  0.0,
    emission_color:                      [1.0, 1.0, 1.0],

    thin_film_weight:                    0.0,
    thin_film_thickness:                 1000.0,
    thin_film_ior:                       1.4,

    geometry_opacity:                    1.0,
    geometry_thin_walled:                false,

    reset_camera:                        function() { reset_camera(params.scene_name); }

};

var materialDefines = {
    VOLUME_ENABLED: true   // always on; MaterialX handles feature presence internally
};

// Generated GLSL from MaterialX WASM (set before create_materials() is called).
var mtlxGeneratedGlsl = '';
var mtlxRouteDispatchGlsl = '';
var mtlxRouteMaterialSummary = {
    opaque: true,
    thinWalled: false,
    emission: [0.0, 0.0, 0.0],
    thinFilmWeight: 0.0,
    thinFilmThicknessNm: 0.0,
    thinFilmIor: 1.5,
    specularIor: 1.5,
    specularRoughness: 0.3,
    transmissionWeight: 0.0
};

const LEGACY_COMPARISON_ENABLED_BY_DEFAULT = false;
const legacyComparisonEnabled = (() => {
    const search = new URLSearchParams(window.location.search);
    if (search.has('legacy_comparison')) {
        const v = search.get('legacy_comparison');
        return v === 'true' || v === '1';
    }
    return LEGACY_COMPARISON_ENABLED_BY_DEFAULT;
})();

var substitutionRuntimeState = {
    strictFailureEnabled: true,
    contractStatus: 'unknown',
    failureCause: '',
    contractValidationStep: '',
    materialContract: null,
    generatorVersion: 'unknown',
    registry: null
};

let _generatedRegistryModulePromise = null;

function getPublicAssetUrl(relPath)
{
    const origin = window.location.origin;
    const base = import.meta.env.BASE_URL;
    return origin + base + relPath.replace(/^\/+/, '');
}

async function loadGeneratedRegistryModule()
{
    if (_generatedRegistryModulePromise) return _generatedRegistryModulePromise;
    const url = getPublicAssetUrl('mtlx/generated-function-registry.mjs');
    _generatedRegistryModulePromise = import(/* @vite-ignore */ url);
    return _generatedRegistryModulePromise;
}

function extractGeneratorVersionFromGlsl(glsl)
{
    const m = String(glsl || '').match(/generator[_\s-]*version\s*[:=]\s*"([^"]+)"/i);
    return m ? m[1] : 'unknown';
}

async function loadMaterialContract(search, materialId)
{
    let contract = null;
    let contractUrl = search.get('contract_url') || '/mtlx/material-contract.json';
    if (contractUrl.startsWith('/') && !contractUrl.startsWith('//')) {
        contractUrl = import.meta.env.BASE_URL.replace(/\/$/, '') + contractUrl;
    }
    try {
        const resp = await fetch(contractUrl);
        if (resp.ok) {
            const payload = await resp.json();
            if (payload?.materials && payload.materials[materialId]) {
                contract = payload.materials[materialId];
            } else if (Array.isArray(payload?.materials)) {
                contract = payload.materials.find(m => m.materialId === materialId) || null;
            } else {
                contract = payload;
            }
        }
    } catch (e) {
        console.warn('[substitution] material contract load failed:', e?.message || e);
    }

    if (!contract) {
        const mod = await loadGeneratedRegistryModule();
        contract = mod.deriveDefaultMaterialContract(materialId);
    }

    return contract;
}

async function validateGeneratedShadingContract(generatedGlsl, search)
{
    const mod = await loadGeneratedRegistryModule();
    const materialId = search.get('material_id') || 'default-material';
    const generatorVersion = extractGeneratorVersionFromGlsl(generatedGlsl);
    const contract = await loadMaterialContract(search, materialId);
    const registry = mod.buildGeneratedFunctionRegistry(generatedGlsl, { generatorVersion });
    const compatibility = mod.checkRequiredFunctions(registry, contract);

    substitutionRuntimeState.materialContract = contract;
    substitutionRuntimeState.generatorVersion = generatorVersion;
    substitutionRuntimeState.registry = registry.toJSON();

    if (!compatibility.ok) {
        substitutionRuntimeState.contractStatus = 'invalid';
        substitutionRuntimeState.contractValidationStep = 'generated-function-registry-check';
        substitutionRuntimeState.failureCause = compatibility.missingFunctions.length > 0
            ? `missing_required_function:${compatibility.missingFunctions.join(',')}`
            : 'signature_mismatch';
        throw new Error(`[substitution] Contract check failed at ${substitutionRuntimeState.contractValidationStep}: ${substitutionRuntimeState.failureCause}; generator=${generatorVersion}`);
    }

    substitutionRuntimeState.contractStatus = 'valid';
    substitutionRuntimeState.contractValidationStep = 'generated-function-registry-check';
    substitutionRuntimeState.failureCause = '';
}

function getRendererModes()
{
    const modes = ['Rasterizer', 'Pathtracer', 'Pathtracer MTLX'];
    if (legacyComparisonEnabled) modes.push('Pathtracer legacy');
    return modes;
}

function is_mtlx_route() { return params.renderer_mode === 'Pathtracer MTLX'; }

function is_pathtracing_route()
{
    return params.renderer_mode === 'Pathtracer' ||
           params.renderer_mode === 'Pathtracer MTLX' ||
           params.renderer_mode === 'Pathtracer legacy';
}

// Assemble the MTLX route fragment: the generated per-material dispatch
// (MtlxPathTracerHostShaderGenerator output, renamed to mtlxGen*), a thin bridge
// mapping the integrator's mtlx_openpbr_* hooks onto it, then the copied
// integrator. Fails explicitly if the generated dispatch is missing, per the MTLX
// viewer route contract (no legacy fallback).
function assemble_mtlx_route_dispatch()
{
    const dispatch = (mtlxRouteDispatchGlsl || '').trim();
    const hasEval = /\bvec3\s+mtlxGenEvaluateBsdf\s*\(/.test(dispatch);
    const hasSample = /\bvec3\s+mtlxGenSampleBsdf\s*\(/.test(dispatch);
    if (!dispatch || !hasEval || !hasSample)
    {
        substitutionRuntimeState.contractStatus = 'invalid';
        substitutionRuntimeState.contractValidationStep = 'mtlx-route-dispatch-assembly';
        substitutionRuntimeState.failureCause = 'missing_generated_dispatch';
        throw new Error('[mtlx-route] generated BSDF dispatch missing; refusing legacy fallback');
    }
    const opaque = mtlxRouteMaterialSummary.opaque ? 'true' : 'false';
    const thinWalled = mtlxRouteMaterialSummary.thinWalled ? 'true' : 'false';
    const emission = mtlxRouteMaterialSummary.emission;
    const thinFilmWeight = mtlxRouteMaterialSummary.thinFilmWeight;
    const thinFilmThicknessNm = mtlxRouteMaterialSummary.thinFilmThicknessNm;
    const thinFilmIor = mtlxRouteMaterialSummary.thinFilmIor;
    const specularIor = mtlxRouteMaterialSummary.specularIor;
    const specularRoughness = mtlxRouteMaterialSummary.specularRoughness;
    const transmissionWeight = mtlxRouteMaterialSummary.transmissionWeight;
    const bridge = `
vec3 mtlx_openpbr_bsdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL, inout float pdf_woutputL) {
    return mtlxGenEvaluateBsdf(pW, basis, winputL, woutputL, MATERIAL_OPENPBR, pdf_woutputL);
}
vec3 mtlx_openpbr_bsdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed, out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium) {
    return mtlxGenSampleBsdf(pW, basis, winputL, rndSeed, MATERIAL_OPENPBR, woutputL, pdf_woutputL, internal_medium);
}
void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed) {}
bool mtlx_openpbr_is_opaque() { return ${opaque}; }
bool mtlx_openpbr_is_thinwalled() { return ${thinWalled}; }
vec3 mtlx_openpbr_emission() { return vec3(${emission[0].toFixed(8)}, ${emission[1].toFixed(8)}, ${emission[2].toFixed(8)}); }
float mtlx_openpbr_thin_film_weight() { return ${thinFilmWeight.toFixed(8)}; }
float mtlx_openpbr_thin_film_thickness_nm() { return ${thinFilmThicknessNm.toFixed(8)}; }
float mtlx_openpbr_thin_film_ior() { return ${thinFilmIor.toFixed(8)}; }
float mtlx_openpbr_specular_ior() { return ${specularIor.toFixed(8)}; }
float mtlx_openpbr_specular_roughness() { return ${specularRoughness.toFixed(8)}; }
float mtlx_openpbr_transmission_weight() { return ${transmissionWeight.toFixed(8)}; }
`;
    return mtlxRouteDispatchGlsl + bridge + glsl_mtlx_route_pathtracer;
}

// Minimal default OpenPBR material used when no .mtlx file is supplied.
const DEFAULT_MTLX = `<?xml version="1.0"?>
<materialx version="1.39">
  <open_pbr_surface name="default_mtl" type="surfaceshader">
    <input name="base_color" type="color3" value="0.8, 0.8, 0.8" />
    <input name="specular_roughness" type="float" value="0.3" />
  </open_pbr_surface>
  <surfacematerial name="default_mat" type="material">
    <input name="surfaceshader" type="surfaceshader" nodename="default_mtl" />
  </surfacematerial>
</materialx>`;

// Load (and cache) the MaterialX WASM generator module.
let _mtlxModulePromise = null;
async function loadMtlxModule() {
    if (_mtlxModulePromise) return _mtlxModulePromise;
    // Construct full http:// URL at runtime so Vite's static analyzer
    // does not intercept the import as a /public/ module (which it rejects).
    // BASE_URL = '/OpenPBR-viewer/' — public files are served under the base in Vite 5.
    const origin = window.location.origin;
    const base   = import.meta.env.BASE_URL; // e.g. '/OpenPBR-viewer/'
    const jsUrl  = origin + base + 'mtlx/JsMaterialXGenShader.js';
    _mtlxModulePromise = import(/* @vite-ignore */ jsUrl)
        .then(mod => mod.default({
            locateFile: p => origin + base + 'mtlx/' + p
        }));
    return _mtlxModulePromise;
}

// Generate GLSL for the path tracer from a .mtlx XML string.
async function generateMtlxGlsl(mtlxText) {
    const mx = await loadMtlxModule();
    const gen = mx.PathTracerGlslShaderGenerator.create();
    const ctx = new mx.GenContext(gen);
    const stdlib = mx.loadStandardLibraries(ctx);
    const doc = mx.createDocument();
    doc.importLibrary(stdlib);
    await mx.readFromXmlString(doc, mtlxText, '');
    const elem = mx.findRenderableElement(doc);
    if (!elem) throw new Error('No renderable element found in .mtlx');
    const shader = gen.generate(elem.getNamePath(), elem, ctx);
    let glsl = shader.getSourceCode('pixel');
    // Strip #version / precision directives (host shader provides its own).
    glsl = glsl.replace(/^[ \t]*#version[^\n]*\n/gm, '').replace(/^[ \t]*precision[^\n]*\n/gm, '');
    // Remap MaterialX env-map uniforms to the viewer's symbols.
    glsl = glsl
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envIrradiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envLightIntensity[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envMatrix[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceMips[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceSamples[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+bool[ \t]+u_refractionTwoSided[ \t]*;[ \t]*\r?\n/gm, '');
    const envPreamble =
        'mat4 mtlxEnvMatrix() {\n' +
        '    float a = 1.57079632679;\n' +   // fixed +90° to match the viewer convention
        '    float c = cos(a), s = sin(a);\n' +
        '    return mat4(c,0.,-s,0., 0.,1.,0.,0., s,0.,c,0., 0.,0.,0.,1.);\n' +
        '}\n' +
        '#define u_envMatrix    mtlxEnvMatrix()\n' +
        '#define u_envRadiance  envMapLatLong\n' +
        '#define u_envIrradiance envMapLatLong\n' +
        '#define u_envLightIntensity skyPower\n' +
        '#define u_envRadianceMips   1\n' +
        '#define u_envRadianceSamples 1\n' +
        '#define u_refractionTwoSided false\n';
    glsl = envPreamble + glsl;

    // Extract scalar param values from the __MTLX_PARAMS_BEGIN__ block to drive shader defines.
    const extractParam = (name, fallback) => {
        const m = glsl.match(new RegExp(`\\b(?:float|bool)\\s+${name}\\s*=\\s*([^;]+);`));
        if (!m) return fallback;
        const v = m[1].trim();
        return v === 'true' ? true : v === 'false' ? false : parseFloat(v);
    };
    const mtlxParams = {
        transmissionWeight:    extractParam('transmission_weight',    0),
        transmissionDepth:     extractParam('transmission_depth',     0),
        dispersionScale:       extractParam('transmission_dispersion_scale', 0),
        thinFilmWeight:        extractParam('thin_film_weight',       0),
        geometry_thin_walled:  extractParam('geometry_thin_walled',  false),
    };

    // Clean up embind handles.
    try { shader.delete?.(); } catch {}
    try { elem.delete?.();   } catch {}
    try { stdlib.delete?.(); } catch {}
    try { ctx.delete?.();    } catch {}
    try { gen.delete?.();    } catch {}
    try { doc.delete?.();    } catch {}
    return { glsl, mtlxParams };
}
// MtlxPathTracerHostShaderGenerator (feature 003). Unlike generateMtlxGlsl (which
// uses the forbidden PathTracerGlslShaderGenerator for the substitution path),
// this emits a model-agnostic evaluateBsdf/sampleBsdf with all params folded as
// literals. The functions are renamed to mtlxGen* so the route integrator's own
// evaluateBsdf/sampleBsdf dispatchers can call them via the mtlx_openpbr_* hooks.
async function generateMtlxRouteDispatch(mtlxText) {
    const mx = await loadMtlxModule();
    if (typeof mx.MtlxPathTracerHostShaderGenerator === 'undefined') {
        throw new Error('[mtlx-route] MtlxPathTracerHostShaderGenerator not exposed by WASM build');
    }
    const gen = mx.MtlxPathTracerHostShaderGenerator.create();
    const ctx = new mx.GenContext(gen);
    const stdlib = mx.loadStandardLibraries(ctx);
    const doc = mx.createDocument();
    doc.importLibrary(stdlib);
    await mx.readFromXmlString(doc, mtlxText, '');
    const elem = mx.findRenderableElement(doc);
    if (!elem) throw new Error('[mtlx-route] No renderable element found in .mtlx');
    const shader = gen.generate(elem.getNamePath(), elem, ctx);
    let glsl = shader.getSourceCode('pixel');

    // Strip #version / precision (route provides its own) and the MaterialX
    // `#define material surfaceshader` alias, which would clobber the integrator's
    // `int material` dispatch parameter.
    glsl = glsl
        .replace(/^[ \t]*#version[^\n]*\n/gm, '')
        .replace(/^[ \t]*precision[^\n]*\n/gm, '')
        .replace(/^[ \t]*#define[ \t]+material[ \t]+surfaceshader[ \t]*\r?\n/gm, '');
    // Remap MaterialX env-map uniforms to the viewer's symbols (as in generateMtlxGlsl).
    glsl = glsl
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envIrradiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envLightIntensity[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envMatrix[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceMips[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceSamples[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+bool[ \t]+u_refractionTwoSided[ \t]*;[ \t]*\r?\n/gm, '');
    const envPreamble =
        'uniform sampler2D envMapLatLong;\n' +
        'mat4 mtlxEnvMatrix() {\n' +
        '    float a = 1.57079632679;\n' +
        '    float c = cos(a), s = sin(a);\n' +
        '    return mat4(c,0.,-s,0., 0.,1.,0.,0., s,0.,c,0., 0.,0.,0.,1.);\n' +
        '}\n' +
        '#define u_envMatrix    mtlxEnvMatrix()\n' +
        '#define u_envRadiance  envMapLatLong\n' +
        '#define u_envIrradiance envMapLatLong\n' +
        '#define u_envLightIntensity skyPower\n' +
        '#define u_envRadianceMips   1\n' +
        '#define u_envRadianceSamples 1\n' +
        '#define u_refractionTwoSided false\n';
    glsl = envPreamble + glsl;

    // Rename the generated entry points so they don't collide with the route
    // integrator's own evaluateBsdf/sampleBsdf dispatchers.
    glsl = glsl
        .replace(/\bevaluateBsdf\b/g, 'mtlxGenEvaluateBsdf')
        .replace(/\bsampleBsdf\b/g, 'mtlxGenSampleBsdf');

    glsl = glsl.replace(
        `    float F0d = pow((m_ior - 1.0) / (m_ior + 1.0), 2.0);
    vec3 F0 = mix(vec3(F0d) * max(m_specC, vec3(0.0)) * m_specW, m_base, m_metal);
    float F0lum = max(F0.x, max(F0.y, F0.z));
    float Fv = F0lum + (1.0 - F0lum) * pow(1.0 - NdotV, 5.0);`,
        `    float F0d = pow((m_ior - 1.0) / (m_ior + 1.0), 2.0);
    vec3 F0NoFilm = mix(vec3(F0d) * max(m_specC, vec3(0.0)) * m_specW, m_base, m_metal);
    vec3 FFilm = mx_compute_fresnel(NdotV, mx_init_fresnel_dielectric(m_ior, thin_film_thickness * 1000.0, thin_film_ior));
    vec3 F0Film = mix(FFilm * max(m_specC, vec3(0.0)) * m_specW, m_base, m_metal);
    vec3 F0 = mix(F0NoFilm, F0Film, clamp(thin_film_weight, 0.0, 1.0));
    float Fv = clamp(max(F0.x, max(F0.y, F0.z)), 0.0, 1.0);`
    );

    const extractParam = (name, fallback) => {
        const m = glsl.match(new RegExp(`\\b(?:float|bool)\\s+${name}\\s*=\\s*([^;]+);`));
        if (!m) return fallback;
        const v = m[1].trim();
        return v === 'true' ? true : v === 'false' ? false : parseFloat(v);
    };
    const extractVec3Param = (name, fallback) => {
        const m = glsl.match(new RegExp(`\\bvec3\\s+${name}\\s*=\\s*vec3\\(([^)]+)\\);`));
        if (!m) return fallback;
        const values = m[1].split(',').map(v => parseFloat(v.trim()));
        return values.length === 3 && values.every(Number.isFinite) ? values : fallback;
    };
    const emissionColor = extractVec3Param('emission_color', [1, 1, 1]);
    const emissionScale = extractParam('emission_luminance', extractParam('emission', 0));
    const thinFilmThickness = extractParam('thin_film_thickness', 0);
    const thinFilmIor = extractParam('thin_film_ior', extractParam('thin_film_IOR', 1.5));
    const mtlxParams = {
        transmissionWeight:   extractParam('transmission_weight', extractParam('transmission', 0)),
        transmissionDepth:    extractParam('transmission_depth',    0),
        dispersionScale:      extractParam('transmission_dispersion_scale', 0),
        thinFilmWeight:       extractParam('thin_film_weight',      0),
        thinFilmThicknessNm:  thinFilmThickness * 1000.0,
        thinFilmIor:          thinFilmIor,
        specularIor:          extractParam('specular_ior', extractParam('specular_IOR', 1.5)),
        specularRoughness:    extractParam('specular_roughness', 0.3),
        geometry_thin_walled: extractParam('geometry_thin_walled', extractParam('thin_walled', false)),
        emission:             emissionColor.map(v => v * emissionScale),
    };

    try { shader.delete?.(); } catch {}
    try { elem.delete?.();   } catch {}
    try { stdlib.delete?.(); } catch {}
    try { ctx.delete?.();    } catch {}
    try { gen.delete?.();    } catch {}
    try { doc.delete?.();    } catch {}
    return { glsl, mtlxParams };
}

var mesh_loader;
var renderer, camera, orbitControls, scene, gui, stats;
var pathtracedQuad, pathtracedFinalQuad, pathtracingRenderTarget;
var pathtracedMaterial = null;
var pathtracedMaterial_legacy = null;
var openpbrMaterial = null;
var neutralMaterial = null;
var directionalLight, ambientLight;
var camera_initialized = false;
var env_map_texture = null;

var MESH_SURFACE;
var MESH_PROPS;
var BVH_SURFACE;
var BVH_PROPS;

var progress_bar;
var progress_finished_timer;

var LOADED;
var COMPILING;
var PATHTRACING;
var samples = 0;

function is_legacy_pt() { return params.renderer_mode === 'Pathtracer legacy'; }
function active_pathtrace_material() { return is_legacy_pt() ? pathtracedMaterial_legacy : pathtracedMaterial; }

function updateSunDir()
{
    let latTheta = (90.0-params.sunLatitude) * Math.PI/180.0;
    let lonPhi = params.sunLongitude * Math.PI/180.0;
    let costheta = Math.cos(latTheta);
    let sintheta = Math.sin(latTheta);
    let cosphi = Math.cos(lonPhi);
    let sinphi = Math.sin(lonPhi);
    let x = sintheta * cosphi;
    let z = sintheta * sinphi;
    let y = costheta;
    params.sunDir = [x, y, z];
}

var scene_names = {
    'Standard Shader Ball': 'standard-shader-ball',
    'Glavenus':             'glavenus',
    'Terrain':              'terrain',
    'Bearded Man':          'bearded-man'
};

// ---------------------------------------------------------------------------
// Apply URL query parameters to override params defaults before init()
// Usage: ?renderer_mode=Pathtracing&base_color=1,0,0&base_metalness=1
// For MaterialX: ?mtlx_url=/path/to/material.mtlx
// ---------------------------------------------------------------------------
(async function applyUrlParams() {
    const search = new URLSearchParams(window.location.search);

    if (search.has('strict_generated_contract')) {
        const v = search.get('strict_generated_contract');
        substitutionRuntimeState.strictFailureEnabled = (v === 'true' || v === '1');
    }

    for (const [key, rawVal] of search) {
        if (!(key in params)) continue;
        const current = params[key];
        if (Array.isArray(current)) {
            params[key] = rawVal.split(',').map(Number);
        } else if (typeof current === 'boolean') {
            params[key] = (rawVal === 'true' || rawVal === '1');
        } else if (typeof current === 'number') {
            params[key] = parseFloat(rawVal);
        } else if (typeof current === 'string') {
            params[key] = rawVal;
        }
    }
    if (search.has('renderer_mode')) {
        console.log('[URL params] renderer_mode =', params.renderer_mode);
    }
    if (!legacyComparisonEnabled && params.renderer_mode === 'Pathtracer legacy') {
        console.warn('[substitution] Pathtracer legacy mode disabled by default; forcing Pathtracer. Use ?legacy_comparison=true to enable manual comparison mode.');
        params.renderer_mode = 'Pathtracer';
    }

    // Generate GLSL from .mtlx before building the first shader.
    let mtlxText = DEFAULT_MTLX;
    if (search.has('mtlx_url')) {
        try {
            let mtlxUrl = search.get('mtlx_url');
            // Relative paths need BASE_URL prefix: Vite serves public files under the base.
            if (mtlxUrl.startsWith('/') && !mtlxUrl.startsWith('//')) {
                mtlxUrl = import.meta.env.BASE_URL.replace(/\/$/, '') + mtlxUrl;
            }
            const resp = await fetch(mtlxUrl);
            if (resp.ok) mtlxText = await resp.text();
            else console.warn('[mtlx] fetch failed:', resp.status, mtlxUrl);
        } catch (e) {
            console.warn('[mtlx] fetch error:', e);
        }
    }
    try {
        if (is_pathtracing_route()) {
            // MTLX route: use the MtlxPathTracerHostShaderGenerator dispatch (feature 003).
            const result = await generateMtlxRouteDispatch(mtlxText);
            mtlxRouteDispatchGlsl = result.glsl;
            const p = result.mtlxParams;
            const hasTransmission = p.transmissionWeight > 0;
            mtlxRouteMaterialSummary = {
                opaque: !hasTransmission && p.geometry_thin_walled !== true,
                thinWalled: p.geometry_thin_walled === true,
                emission: p.emission,
                thinFilmWeight: p.thinFilmWeight,
                thinFilmThicknessNm: p.thinFilmThicknessNm,
                thinFilmIor: p.thinFilmIor,
                specularIor: p.specularIor,
                specularRoughness: p.specularRoughness,
                transmissionWeight: p.transmissionWeight
            };
            materialDefines.VOLUME_ENABLED       = hasTransmission && p.transmissionDepth > 0 && !p.geometry_thin_walled;
            materialDefines.TRANSMISSION_ENABLED = hasTransmission && p.dispersionScale > 0;
            materialDefines.THIN_FILM_ENABLED    = p.thinFilmWeight > 0;
            console.log('[mtlx-route] generated', mtlxRouteDispatchGlsl.split('\n').length, 'lines of dispatch GLSL');
        } else {
            const result = await generateMtlxGlsl(mtlxText);
            mtlxGeneratedGlsl = result.glsl;
            const p = result.mtlxParams;

            // Set shader defines based on the material's actual parameter values.
            const hasTransmission = p.transmissionWeight > 0;
            const hasVolume       = hasTransmission && p.transmissionDepth > 0 && !p.geometry_thin_walled;
            const hasDispersion   = hasTransmission && p.dispersionScale > 0;
            const hasThinFilm     = p.thinFilmWeight > 0;

            materialDefines.VOLUME_ENABLED       = hasVolume;
            materialDefines.TRANSMISSION_ENABLED = hasDispersion;
            materialDefines.THIN_FILM_ENABLED    = hasThinFilm;

            console.log('[mtlx] generated', mtlxGeneratedGlsl.split('\n').length, 'lines of GLSL',
                '| volume:', hasVolume, '| dispersion:', hasDispersion, '| thin-film:', hasThinFilm);

            await validateGeneratedShadingContract(mtlxGeneratedGlsl, search);
            console.log('[substitution] contract=valid generatorVersion=', substitutionRuntimeState.generatorVersion);
        }
    } catch (e) {
        substitutionRuntimeState.contractStatus = 'invalid';
        substitutionRuntimeState.contractValidationStep = substitutionRuntimeState.contractValidationStep || 'glsl-generation';
        substitutionRuntimeState.failureCause = substitutionRuntimeState.failureCause || 'generated_shading_unavailable';
        console.error('[mtlx] strict generated shading init failed:', e);
    }

    init();
    render();
})();

function create_materials()
{
    renderer.outputColorSpace = LinearSRGBColorSpace;

    if (openpbrMaterial)
        openpbrMaterial.dispose();

    if (neutralMaterial)
        neutralMaterial.dispose();

    if (pathtracedMaterial)
        pathtracedMaterial.dispose();
    // pathtracedMaterial_legacy is rebuilt separately inside create_materials()

    if (!PATHTRACING)
    {
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // openpbrMaterial (for rasterization)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        openpbrMaterial = new ShaderMaterial( {

            defines: materialDefines,

            uniforms: UniformsUtils.merge( [

                    UniformsUtils.clone(ShaderLib.phong.uniforms),
                    {
                        cameraWorldMatrix:     { value: new Matrix4() },
                        invProjectionMatrix:   { value: new Matrix4() },
                        invModelMatrix:        { value: new Matrix4() },
                        resolution:            { value: new Vector2() },
                        samples:               { value: 0 },
                        accumulation_weight:   { value: 1 },

                        //////////////////////////////////////////////////////
                        // renderer
                        //////////////////////////////////////////////////////

                        wireframe:                           { value: params.wireframe, },
                        neutral_color:                       { value: new Vector3().fromArray(params.neutral_color) },
                        smooth_normals:                      { value: params.smooth_normals, },

                        //////////////////////////////////////////////////////
                        // lighting
                        //////////////////////////////////////////////////////

                        skyPower:                            { value: params.skyPower, },
                        skyColor:                            { value: array_to_vector3(params.skyColor) },

                        sunPower:                            { value: Math.pow(10.0,params.sunPower), },
                        sunAngularSize:                      { value: params.sunAngularSize, },
                        sunColor:                            { value: array_to_vector3(params.sunColor) },
                        sunDir:                              { value: array_to_vector3([0,0,0]) },

                        //////////////////////////////////////////////////////
                        // material
                        //////////////////////////////////////////////////////

                        base_weight:                         { value: params.base_weight },
                        base_color:                          { value: array_to_vector3(params.base_color) },
                        base_diffuse_roughness:              { value: params.base_diffuse_roughness },
                        base_metalness:                      { value: params.base_metalness },

                        specular_weight:                     { value: params.specular_weight, },
                        specular_color:                      { value: array_to_vector3(params.specular_color) },
                        specular_roughness:                  { value: params.specular_roughness },
                        specular_anisotropy:                 { value: params.specular_anisotropy },
                        specular_ior:                        { value: params.specular_ior  },
                        specular_haze:                       { value: params.specular_haze },
                        specular_haze_spread:                { value: params.specular_haze_spread },
                        specular_retroreflectivity:          { value: params.specular_retroreflectivity },

                        transmission_weight:                 { value: params.transmission_weight, },
                        transmission_color:                  { value: array_to_vector3(params.transmission_color) },
                        transmission_depth:                  { value: params.transmission_depth },
                        transmission_scatter:                { value: array_to_vector3(params.transmission_scatter) },
                        transmission_scatter_anisotropy:     { value: params.transmission_scatter_anisotropy },
                        transmission_dispersion_abbe_number: { value: params.transmission_dispersion_abbe_number },
                        transmission_dispersion_scale:       { value: params.transmission_dispersion_scale },

                        subsurface_weight:                   { value: params.subsurface_weight },
                        subsurface_color:                    { value: array_to_vector3(params.subsurface_color) },
                        subsurface_radius:                   { value: params.subsurface_radius },
                        subsurface_radius_scale:             { value: array_to_vector3(params.subsurface_radius_scale) },
                        subsurface_anisotropy:               { value: params.subsurface_anisotropy },

                        coat_weight:                         { value: params.coat_weight },
                        coat_color:                          { value: array_to_vector3(params.coat_color) },
                        coat_roughness:                      { value: params.coat_roughness },
                        coat_anisotropy:                     { value: params.coat_anisotropy },
                        coat_ior:                            { value: params.coat_ior  },
                        coat_darkening:                      { value: params.coat_darkening  },

                        fuzz_weight:                         { value: params.fuzz_weight },
                        fuzz_color:                          { value: array_to_vector3(params.fuzz_color) },
                        fuzz_roughness:                      { value: params.fuzz_roughness },

                        emission_weight:                     { value: params.emission_weight },
                        emission_luminance:                  { value: params.emission_luminance },
                        emission_color:                      { value: array_to_vector3(params.emission_color) },

                        thin_film_weight:                    { value: params.thin_film_weight },
                        thin_film_thickness:                 { value: params.thin_film_thickness },
                        thin_film_ior:                       { value: params.thin_film_ior },

                        geometry_opacity:                    { value: params.geometry_opacity },
                        geometry_thin_walled:                { value: params.geometry_thin_walled },

                    }
                ] ),

                vertexShader:   glsl_rasterization_openpbr_vert,
                fragmentShader: glsl_rasterization_openpbr_frag,
                lights: true
            } );


        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // neutralMaterial (for rasterization)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        neutralMaterial = new ShaderMaterial( {

        defines: materialDefines,

        uniforms: UniformsUtils.merge( [

            UniformsUtils.clone(ShaderLib.phong.uniforms),
            {
                cameraWorldMatrix:     { value: new Matrix4() },
                invProjectionMatrix:   { value: new Matrix4() },
                invModelMatrix:        { value: new Matrix4() },
                resolution:            { value: new Vector2() },
                samples:               { value: 0 },
                accumulation_weight:   { value: 1 },

                //////////////////////////////////////////////////////
                // renderer
                //////////////////////////////////////////////////////

                wireframe:                           { value: params.wireframe, },
                smooth_normals:                      { value: params.smooth_normals, },

                //////////////////////////////////////////////////////
                // lighting
                //////////////////////////////////////////////////////

                skyPower:                            { value: params.skyPower, },
                skyColor:                            { value: array_to_vector3(params.skyColor) },
                sunPower:                            { value: Math.pow(10.0,params.sunPower), },
                sunAngularSize:                      { value: params.sunAngularSize, },
                sunColor:                            { value: array_to_vector3(params.sunColor) },
                sunDir:                              { value: array_to_vector3([0,0,0]) },

                //////////////////////////////////////////////////////
                // material
                //////////////////////////////////////////////////////

                neutral_color:                       { value: new Vector3().fromArray(params.neutral_color) }
            }
        ] ),

        vertexShader:   glsl_rasterization_neutral_vert,
        fragmentShader: glsl_rasterization_neutral_frag,
        lights: true
        } );
    }

    if (PATHTRACING)
    {
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // pathtracedMaterial (for pathtracing shader)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        pathtracedMaterial = new ShaderMaterial( {

        defines: materialDefines,

        uniforms: UniformsUtils.merge( [

            UniformsUtils.clone(ShaderLib.phong.uniforms),
            {
                bvh_surface:             { value: new MeshBVHUniformStruct() },
                normalAttribute_surface: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_surface:{ value: new FloatVertexAttributeTexture() },
                has_normals_surface:     { value: 1 },
                has_tangents_surface:    { value: 0 },

                bvh_props:             { value: new MeshBVHUniformStruct() },
                normalAttribute_props: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_props:{ value: new FloatVertexAttributeTexture() },
                has_normals_props:     { value: 1 },
                has_tangents_props:    { value: 0 },

                ground_texture:        { value: null },

                cameraWorldMatrix:     { value: new Matrix4() },
                invProjectionMatrix:   { value: new Matrix4() },
                invModelMatrix:        { value: new Matrix4() },
                resolution:            { value: new Vector2() },

                samples:               { value: 0 },
                accumulation_weight:   { value: 1 },

                //////////////////////////////////////////////////////
                // renderer
                //////////////////////////////////////////////////////

                wireframe:                           { value: params.wireframe, },
                neutral_color:                       { value: new Vector3().fromArray(params.neutral_color) },
                smooth_normals:                      { value: params.smooth_normals, },
                bounces:                             { value: params.bounces },
                max_volume_steps:                    { value: params.max_volume_steps },
                firefly_clamp:                       { value: params.firefly_clamp },
                strict_failure_enabled:              { value: substitutionRuntimeState.strictFailureEnabled },
                generated_contract_valid:            { value: substitutionRuntimeState.contractStatus === 'valid' },
                generated_contract_failure_code:     { value: substitutionRuntimeState.contractStatus === 'valid' ? 0 : 1 },

                //////////////////////////////////////////////////////
                // lighting
                //////////////////////////////////////////////////////

                skyPower:                            { value: params.skyPower, },
                skyColor:                            { value: array_to_vector3(params.skyColor) },

                sunPower:                            { value: Math.pow(10.0,params.sunPower), },
                sunAngularSize:                      { value: params.sunAngularSize, },
                sunColor:                            { value: array_to_vector3(params.sunColor) },
                sunDir:                              { value: array_to_vector3([0,0,0]) },

                // Raw equirectangular env map for MaterialX IBL (sampler2D, not samplerCube).
                envMapLatLong:                       { value: null },

                // Material params are now folded as globals by the MaterialX WASM generator.
                // No per-parameter uniforms needed.

            },
        ] ),

        vertexShader: `
            varying vec2 vUv;
            void main()
            {
                vec4 mvPosition = vec4( position, 1.0 );
                mvPosition = modelViewMatrix * mvPosition;
                gl_Position = projectionMatrix * mvPosition;
                vUv = uv;
            }
        `,

        fragmentShader: `precision highp isampler2D;
                            precision highp usampler2D;
                            precision highp int;
                            ${ shaderStructs }
                            ${ shaderIntersectFunction }
                        `
                        + glsl_mtlx_route_common + '\n'
                        + assemble_mtlx_route_dispatch()

        } );

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // pathtracedMaterial_legacy (handwritten OpenPBR BSDF, pre-MaterialX)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        if (pathtracedMaterial_legacy) pathtracedMaterial_legacy.dispose();

        const legacyDefines = {
            FUZZ_ENABLED:         true,
            COAT_ENABLED:         true,
            TRANSMISSION_ENABLED: true,
            VOLUME_ENABLED:       true,
            THIN_FILM_ENABLED:    true,
            HAZE_ENABLED:         false,
            RETRO_ENABLED:        false,
            SUBSURFACE_ENABLED:   false,
        };

        pathtracedMaterial_legacy = new ShaderMaterial( {

        defines: legacyDefines,

        uniforms: UniformsUtils.merge( [
            UniformsUtils.clone(ShaderLib.phong.uniforms),
            {
                bvh_surface:             { value: new MeshBVHUniformStruct() },
                normalAttribute_surface: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_surface:{ value: new FloatVertexAttributeTexture() },
                has_normals_surface:     { value: 1 },
                has_tangents_surface:    { value: 0 },
                bvh_props:             { value: new MeshBVHUniformStruct() },
                normalAttribute_props: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_props:{ value: new FloatVertexAttributeTexture() },
                has_normals_props:     { value: 1 },
                has_tangents_props:    { value: 0 },
                ground_texture:        { value: null },
                cameraWorldMatrix:     { value: new Matrix4() },
                invProjectionMatrix:   { value: new Matrix4() },
                invModelMatrix:        { value: new Matrix4() },
                resolution:            { value: new Vector2() },
                samples:               { value: 0 },
                accumulation_weight:   { value: 1 },
                wireframe:             { value: params.wireframe },
                neutral_color:         { value: new Vector3().fromArray(params.neutral_color) },
                smooth_normals:        { value: params.smooth_normals },
                bounces:               { value: params.bounces },
                max_volume_steps:      { value: params.max_volume_steps },
                firefly_clamp:         { value: params.firefly_clamp },
                skyPower:              { value: params.skyPower },
                skyColor:              { value: array_to_vector3(params.skyColor) },
                sunPower:              { value: Math.pow(10.0, params.sunPower) },
                sunAngularSize:        { value: params.sunAngularSize },
                sunColor:              { value: array_to_vector3(params.sunColor) },
                sunDir:                { value: array_to_vector3([0,0,0]) },
                base_weight:                         { value: params.base_weight ?? 1.0 },
                base_color:                          { value: array_to_vector3(params.base_color ?? [0.8,0.8,0.8]) },
                base_diffuse_roughness:              { value: params.base_diffuse_roughness ?? 0.0 },
                base_metalness:                      { value: params.base_metalness ?? 0.0 },
                specular_weight:                     { value: params.specular_weight ?? 1.0 },
                specular_color:                      { value: array_to_vector3(params.specular_color ?? [1,1,1]) },
                specular_roughness:                  { value: params.specular_roughness ?? 0.3 },
                specular_anisotropy:                 { value: params.specular_anisotropy ?? 0.0 },
                specular_ior:                        { value: params.specular_ior ?? 1.5 },
                specular_haze:                       { value: params.specular_haze ?? 0.0 },
                specular_haze_spread:                { value: params.specular_haze_spread ?? 0.3 },
                specular_retroreflectivity:          { value: params.specular_retroreflectivity ?? 0.0 },
                transmission_weight:                 { value: params.transmission_weight ?? 0.0 },
                transmission_color:                  { value: array_to_vector3(params.transmission_color ?? [1,1,1]) },
                transmission_depth:                  { value: params.transmission_depth ?? 0.0 },
                transmission_scatter:                { value: array_to_vector3(params.transmission_scatter ?? [0,0,0]) },
                transmission_scatter_anisotropy:     { value: params.transmission_scatter_anisotropy ?? 0.0 },
                transmission_dispersion_abbe_number: { value: params.transmission_dispersion_abbe_number ?? 20.0 },
                transmission_dispersion_scale:       { value: params.transmission_dispersion_scale ?? 0.0 },
                subsurface_weight:                   { value: params.subsurface_weight ?? 0.0 },
                subsurface_color:                    { value: array_to_vector3(params.subsurface_color ?? [0.8,0.8,0.8]) },
                subsurface_radius:                   { value: params.subsurface_radius ?? 0.2 },
                subsurface_radius_scale:             { value: array_to_vector3(params.subsurface_radius_scale ?? [1,0.5,0.25]) },
                subsurface_anisotropy:               { value: params.subsurface_anisotropy ?? 0.0 },
                coat_weight:                         { value: params.coat_weight ?? 0.0 },
                coat_color:                          { value: array_to_vector3(params.coat_color ?? [1,1,1]) },
                coat_roughness:                      { value: params.coat_roughness ?? 0.0 },
                coat_anisotropy:                     { value: params.coat_anisotropy ?? 0.0 },
                coat_ior:                            { value: params.coat_ior ?? 1.6 },
                coat_darkening:                      { value: params.coat_darkening ?? 1.0 },
                fuzz_weight:                         { value: params.fuzz_weight ?? 0.0 },
                fuzz_color:                          { value: array_to_vector3(params.fuzz_color ?? [1,1,1]) },
                fuzz_roughness:                      { value: params.fuzz_roughness ?? 0.5 },
                emission_weight:                     { value: params.emission_weight ?? 0.0 },
                emission_luminance:                  { value: params.emission_luminance ?? 0.0 },
                emission_color:                      { value: array_to_vector3(params.emission_color ?? [1,1,1]) },
                thin_film_weight:                    { value: params.thin_film_weight ?? 0.0 },
                thin_film_thickness:                 { value: params.thin_film_thickness ?? 1000.0 },
                thin_film_ior:                       { value: params.thin_film_ior ?? 1.4 },
                geometry_opacity:                    { value: params.geometry_opacity ?? 1.0 },
                geometry_thin_walled:                { value: params.geometry_thin_walled ?? false },
            },
        ] ),

        vertexShader: `
            varying vec2 vUv;
            void main()
            {
                vec4 mvPosition = vec4( position, 1.0 );
                mvPosition = modelViewMatrix * mvPosition;
                gl_Position = projectionMatrix * mvPosition;
                vUv = uv;
            }
        `,

        fragmentShader: `precision highp isampler2D;
                            precision highp usampler2D;
                            precision highp int;
                            ${ shaderStructs }
                            ${ shaderIntersectFunction }
                        `
                        + glsl_legacy_main
                        + glsl_legacy_fuzz_brdf
                        + glsl_legacy_coat_brdf
                        + glsl_legacy_thin_film
                        + glsl_legacy_specular_brdf
                        + glsl_legacy_specular_btdf
                        + glsl_legacy_metal_brdf
                        + glsl_legacy_diffuse_brdf
                        + glsl_legacy_diffuse_btdf
                        + glsl_legacy_openpbr_surface
                        + glsl_legacy_pathtracer

        } );
    }
}

function init()
{
    // Setup progress bar spinner
    progress_bar = new Circle('#progress_overlay',
    {
        color: 'rgba(255, 128, 64, 0.75)',
        strokeWidth: 5.0,
        trailColor: 'rgba(255, 128, 64, 0.333)',
        trailWidth: 3.0,
        svgStyle: {
            display: 'block',
            width: '100%'
        },
        text: {
            value: '',
            className: 'progressbar__label',
            style: {
                color: 'rgba(169, 85, 42, 1.0)',
                position: 'absolute',
                fontWeight: 'bold',
                left: '50%',
                top: '50%',
                padding: 0,
                margin: 0,
                transform: {
                    prefix: true,
                    value: 'translate(-50%, -50%)'
                }
            },
            autoStyleContainer: true,
            alignToBottom: true
        },
        fill: null,
        duration: 2000.0,
        easing: 'linear',
        from: { color: 'rgba( 0,   0,  0, 0.0)' },
        to: {   color: 'rgba(32, 255, 32, 1.0)' },
        warnings: true
    });
    progress_bar.set(0.0);
    progress_bar.setText('');

    LOADED = false;
    MESH_SURFACE = null;
    MESH_PROPS = null;
    BVH_SURFACE = null;
    BVH_PROPS = null;

    // renderer setup
    renderer = new WebGLRenderer( { antialias: true, preserveDrawingBuffer: true } );
    renderer.setPixelRatio( window.devicePixelRatio );
    renderer.setClearColor( 0x09141a );
    renderer.setSize( window.innerWidth, window.innerHeight );
    renderer.outputColorSpace = LinearSRGBColorSpace;
    renderer.shadowMap.enabled = true;
    renderer.shadowMapSoft = true;
    renderer.shadowMap.type = PCFSoftShadowMap; // default THREE.PCFShadowMap
    renderer.physicallyBasedShading = true;

    // Intercept GLSL compilation errors with full driver log + line numbers
    renderer.debug.onShaderError = function(gl, program, vertexShader, fragmentShader) {
        const vertLog = gl.getShaderInfoLog(vertexShader);
        const fragLog = gl.getShaderInfoLog(fragmentShader);
        let msg = '';
        if (vertLog && vertLog.trim().length > 0) {
            console.error('[GLSL vertex shader error]\n' + vertLog);
            msg += '── VERTEX SHADER ──\n' + vertLog.trim() + '\n\n';
        }
        if (fragLog && fragLog.trim().length > 0) {
            console.error('[GLSL fragment shader error]\n' + fragLog);
            msg += '── FRAGMENT SHADER ──\n' + fragLog.trim();
        }
        if (msg.length > 0) {
            window.__openpbrShaderError = msg;
            const overlay = document.getElementById('shader-error');
            document.getElementById('shader-error-content').textContent = msg;
            overlay.style.display = 'block';
        }
    };

    // Enable parallel shader compilation if available
    const gl = renderer.getContext();
    const parallelShaderCompileExt = gl.getExtension('KHR_parallel_shader_compile');
    if (parallelShaderCompileExt) {
        console.log('Parallel shader compilation enabled');
    } else {
        console.log('Parallel shader compilation not supported - shader compilation may be slow');
    }

    document.body.appendChild( renderer.domElement );

    PATHTRACING = (params.renderer_mode === 'Pathtracer' || params.renderer_mode === 'Pathtracer MTLX' || params.renderer_mode === 'Pathtracer legacy');

    // stats setup
    stats = new Stats();
    stats.dom.id = 'stats-panel';
    document.body.appendChild( stats.dom );

    // Samples count text
    let samples_txt = document.getElementById('samples');
    samples_txt.style.visibility = 'visible';

    // Info text
    let info_txt = document.getElementById('info');
    info_txt.style.visibility = 'visible';

    gui = null;
    camera_initialized = false;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // initialize the scene and update the material properties with the bvh, materials, etc
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    mesh_loader = new MeshLoader();

    load_scene(params.scene_name);
}

function load_geometry(scene_name)
{
    scene.background = env_map_texture;
    env_map_texture.mapping = EquirectangularReflectionMapping ;
    env_map_texture.colorSpace = SRGBColorSpace;
    if (!PATHTRACING)
    {
        neutralMaterial.envMap                = env_map_texture;
        neutralMaterial.uniforms.envMap.value = env_map_texture;
        openpbrMaterial.envMap                = env_map_texture;
        openpbrMaterial.uniforms.envMap.value = env_map_texture;
    }
    else
    {
        pathtracedMaterial.envMap                = env_map_texture;
        pathtracedMaterial.uniforms.envMap.value = env_map_texture;
        pathtracedMaterial.uniforms.envMapLatLong.value = env_map_texture;
        pathtracedMaterial_legacy.envMap                = env_map_texture;
        pathtracedMaterial_legacy.uniforms.envMap.value = env_map_texture;
    }

    // Load "neutral" objects (i.e. Lambert shaded background stuff)
    mesh_loader.load(scene_name + '/neutral_objects.glb').then( () => {

        if (!PATHTRACING)
        {
            // Set up mesh properties for rasterization
            mesh_loader.result.scene.traverse((o) => {
                if (o.isMesh)
                {
                    o.material = neutralMaterial;
                    o.receiveShadow = true;
                    o.castShadow = false;
                    o.material.side = DoubleSide;
                }
            });
        }

        scene.add(mesh_loader.result.scene);

        MESH_PROPS = mesh_loader.result.mesh;

        if (PATHTRACING)
        {
            // Set up mesh properties for pathtracing
            BVH_PROPS  = mesh_loader.result.bvh;
            for (const pm of [pathtracedMaterial, pathtracedMaterial_legacy]) {
                pm.uniforms.bvh_props.value.updateFrom( BVH_PROPS );
                pm.uniforms.has_normals_props.value = false;
                pm.uniforms.has_tangents_props.value = false;
                if (MESH_PROPS.geometry.attributes.normal)
                {
                    pm.uniforms.normalAttribute_props.value.updateFrom( MESH_PROPS.geometry.attributes.normal );
                    pm.uniforms.has_normals_props.value = true;
                }
                if (MESH_PROPS.geometry.attributes.tangent)
                {
                    pm.uniforms.tangentAttribute_props.value.updateFrom( MESH_PROPS.geometry.attributes.tangent );
                    pm.uniforms.has_tangents_props.value = true;
                }
            }
            console.log("  has_normals_scene:  ", pathtracedMaterial.uniforms.has_normals_props);
            console.log("  has_tangents_scene: ", pathtracedMaterial.uniforms.has_tangents_props);
        }

        progress_bar.animate(0.5);
        mesh_loader.reset();

        // Load OpenPBR-shaded objects
        mesh_loader.load(scene_name + '/openpbr_objects.glb').then( () => {

            if (!PATHTRACING)
            {
                // Set up mesh properties for rasterization
                mesh_loader.result.scene.traverse((o) => {
                    if (o.isMesh)
                    {
                        o.material = openpbrMaterial;
                        o.receiveShadow = true;
                        o.castShadow = true;
                    }
                });
            }

            scene.add(mesh_loader.result.scene);

            MESH_SURFACE = mesh_loader.result.mesh;

            if (PATHTRACING)
            {
                // Set up mesh properties for pathtracing
                BVH_SURFACE  = mesh_loader.result.bvh;
                for (const pm of [pathtracedMaterial, pathtracedMaterial_legacy]) {
                    pm.uniforms.bvh_surface.value.updateFrom( BVH_SURFACE );
                    pm.uniforms.has_normals_surface.value = false;
                    pm.uniforms.has_tangents_surface.value = false;
                    if (MESH_SURFACE.geometry.attributes.normal)
                    {
                        pm.uniforms.normalAttribute_surface.value.updateFrom( MESH_SURFACE.geometry.attributes.normal );
                        pm.uniforms.has_normals_surface.value = true;
                    }
                    if (MESH_SURFACE.geometry.attributes.tangent)
                    {
                        pm.uniforms.tangentAttribute_surface.value.updateFrom( MESH_SURFACE.geometry.attributes.tangent );
                        pm.uniforms.has_tangents_surface.value = true;
                    }
                }
                console.log("  has_normals_surface:  ", pathtracedMaterial.uniforms.has_normals_surface);
                console.log("  has_tangents_surface: ", pathtracedMaterial.uniforms.has_tangents_surface);
                console.log("===> LOADED");
            }

            // Ground plane texture
            const groundTexLoader = new TextureLoader();
            const groundTex = groundTexLoader.load('textures/ground.png');
            groundTex.wrapS = RepeatWrapping;
            groundTex.wrapT = RepeatWrapping;
            groundTex.colorSpace = SRGBColorSpace;

            if (!PATHTRACING)
            {
                // Rasterizer: add ground plane mesh
                groundTex.repeat.set(2, 2);
                groundTex.offset.set(0.5, 0.5);
                const groundGeom = new PlaneGeometry(200, 200);
                const groundMat = new MeshLambertMaterial({ map: groundTex, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -1 });
                const groundMesh = new Mesh(groundGeom, groundMat);
                groundMesh.rotation.x = -Math.PI / 2;
                groundMesh.position.y = 0.01;
                groundMesh.receiveShadow = true;
                scene.add(groundMesh);
            }
            else
            {
                // Pathtracer: pass texture as uniform (UV mapping done in shader)
                pathtracedMaterial.uniforms.ground_texture.value = groundTex;
                pathtracedMaterial_legacy.uniforms.ground_texture.value = groundTex;
            }

            LOADED = true;

            post_load_setup();

            progress_bar.animate(1.0);
            let progress_overlay = document.getElementById('progress_overlay');
            progress_finished_timer = performance.now();

        } )

    } );
}

function load_scene(scene_name)
{
    console.log('Loading scene: ', scene_name);
    LOADED = false;

    PATHTRACING = (params.renderer_mode === 'Pathtracer' || params.renderer_mode === 'Pathtracer MTLX' || params.renderer_mode === 'Pathtracer legacy');

    create_materials()

    ////////////////////////////////////////////////////////////////////////////////////
    // Create three.js scene
    scene = new Scene();
    ////////////////////////////////////////////////////////////////////////////////////

    progress_bar.setText('loading meshes...');
    progress_bar.animate(0.0);

    // Load env map
    if (!env_map_texture)
    {
        const textureLoader = new TextureLoader();
        let env_map_path = 'textures/envmaps/etzwihl_16k.jpg';
        let textureEquirec = textureLoader.load(env_map_path,
            function (texture) {
                console.log('-> loaded env map: ', env_map_path);
                    env_map_texture = texture;
                    load_geometry(scene_name);
                }
        );
    }
    else
        load_geometry(scene_name);
}

function reset_camera(scene_name)
{
    let camera_fov = 23.6701655;
    let camera_near = 0.01;
    let camera_far = 1000.0;
    camera = new PerspectiveCamera( camera_fov, window.innerWidth / window.innerHeight, camera_near, camera_far );

    orbitControls = new OrbitControls( camera, renderer.domElement );
    orbitControls.addEventListener( 'change', () => { resetSamples(); } );
    let matrixWorld = new Matrix4();

    if (scene_name == 'standard-shader-ball')
    {
        // Set camera default orientation according to the Standard Shader Ball USD asset description:
        matrixWorld.set( 0.9396926207859084,                  0, -0.3420201433256687, 0,
                        -0.2203032561704394, 0.7649214009184319, -0.6052782217606094, 0,
                        0.26161852717499334, 0.6441236297613865,  0.7187909959242699, 0,
                        6.531538924716362,               19.5,  17.948521838355774, 1 );
    }
    else if (scene_name == 'glavenus')
    {
        matrixWorld.set( 0.4848291963218869, -6.938893903907228e-18, -0.8746088556571293,   0,
                        -0.07533009256065425, 0.9962839037303908,    -0.041758356319859954, 0,
                            0.8713587249512548,  0.08613003638530015,    0.4830275243540376,   0,
                        23.076273094000275,   6.7653774216248,        14.822630983786677,   1);

    }
    else if (scene_name == 'terrain')
    {
        matrixWorld.set( 0.7242953632536803, -1.1102230246251565e-16, -0.6894898307946385, 0,
                        -0.4511571209928634,  0.7562050657737049,     -0.4739315886028461, 0,
                            0.5213957028463604,  0.6543346991396579,      0.5477158228088388, 0,
                            8.561709328489492,  11.460860759783042,       8.95672568146927,   1);
    }
    else if (scene_name == 'bearded-man')
    {
        matrixWorld.set(0.6586894440882616, -1.3877787807814457e-17, 0.752414922929295,   0,
                        0.13367205033823076, 0.9840924050751759,    -0.11702102901499911, 0,
                        -0.7404458111199431,  0.17765736200156684,    0.648211279230448,   0,
                        -20.089277049402824,   9.131027464916848,     18.02162149148976,    1);
    }

    matrixWorld.transpose();
    camera.matrixAutoUpdate = false;
    camera.applyMatrix4(matrixWorld);
    camera.matrixAutoUpdate = true;
    camera.updateMatrixWorld();

    let dir = new Vector3();
    camera.getWorldDirection(dir);
    let cam_target = camera.position.clone();
    cam_target.addScaledVector(dir, 23.39613);
    orbitControls.target.copy(cam_target);

    orbitControls.zoomSpeed = 1.5;
    orbitControls.flySpeed = 0.01;
    orbitControls.update();
}


function setup_gui()
{
    if (gui)
        gui.destroy()
    gui = new GUI({ width: 300 });

    ///// Material folder /////////////////////////////////////
    const material_folder = gui.addFolder('Material');

    // Base folder
    const base_folder = material_folder.addFolder('Base');
    base_folder.add(params,          'base_weight', 0.0, 1.0).onChange(                               v => { resetSamples(); });
    base_folder.addColor(params,     'base_color').onChange(                                          v => { resetSamples(); });
    base_folder.add(params,          'base_diffuse_roughness', 0.0, 1.0).onChange(                    v => { resetSamples(); });
    base_folder.add(params,          'base_metalness', 0.0, 1.0).onChange(                            v => { resetSamples(); });

    // Specular folder
    const specular_folder = material_folder.addFolder('Specular');
    specular_folder.add(params,      'specular_weight', 0.0, 1.0).onChange(                           v => { resetSamples(); });
    specular_folder.addColor(params, 'specular_color').onChange(                                      v => { resetSamples(); });
    specular_folder.add(params,      'specular_roughness', 0.0, 1.0).onChange(                        v => { resetSamples(); });
    specular_folder.add(params,      'specular_ior', 1.0, 5.0).onChange(                              v => { resetSamples(); });
    specular_folder.add(params,      'specular_anisotropy', 0.0, 1.0).onChange(                       v => { resetSamples(); });
    specular_folder.add(params,      'specular_haze', 0.0, 1.0).onChange(                            v => { resetSamples(); });
    specular_folder.add(params,      'specular_haze_spread', 0.0, 1.0).onChange(                     v => { resetSamples(); });
    specular_folder.add(params,      'specular_retroreflectivity', 0.0, 1.0).onChange(               v => { resetSamples(); });

    // Transmission folder
    const transmission_folder = material_folder.addFolder('Transmission');
    transmission_folder.add(params,      'transmission_weight', 0.0, 1.0).onChange(                   v => { resetSamples(); });
    transmission_folder.addColor(params, 'transmission_color').onChange(                              v => { resetSamples(); });
    transmission_folder.add(params,      'transmission_depth', 0.0, 1.0).onChange(                    v => { resetSamples(); });
    transmission_folder.addColor(params, 'transmission_scatter').onChange(                            v => { resetSamples(); });
    transmission_folder.add(params,      'transmission_scatter_anisotropy', -1.0, 1.0).onChange(      v => { resetSamples(); });
    transmission_folder.add(params,      'transmission_dispersion_abbe_number', 9.0, 91.0).onChange(  v => { resetSamples(); });
    transmission_folder.add(params,      'transmission_dispersion_scale', 0.0, 1.0).onChange(         v => { resetSamples(); });
    transmission_folder.close();

    // Subsurface folder
    const subsurface_folder = material_folder.addFolder('Subsurface');
    subsurface_folder.add(params,      'subsurface_weight', 0.0, 1.0).onChange(                       v => { resetSamples(); });
    subsurface_folder.addColor(params, 'subsurface_color').onChange(                                  v => { resetSamples(); });
    subsurface_folder.add(params,      'subsurface_radius', 0.0, 1.0).onChange(                       v => { resetSamples(); });
    subsurface_folder.addColor(params, 'subsurface_radius_scale').onChange(                           v => { resetSamples(); });
    subsurface_folder.add(params,      'subsurface_anisotropy', -1.0, 1.0).onChange(                  v => { resetSamples(); });
    subsurface_folder.close();

    // Coat folder
    const coat_folder = material_folder.addFolder('Coat');
    coat_folder.add(params,          'coat_weight', 0.0, 1.0).onChange(                               v => { resetSamples(); });
    coat_folder.addColor(params,     'coat_color').onChange(                                          v => { resetSamples(); });
    coat_folder.add(params,          'coat_roughness', 0.0, 1.0).onChange(                            v => { resetSamples(); });
    coat_folder.add(params,          'coat_ior', 1.0, 3.0).onChange(                                  v => { resetSamples(); });
    coat_folder.add(params,          'coat_anisotropy', 0.0, 1.0).onChange(                           v => { resetSamples(); });
    coat_folder.add(params,          'coat_darkening', 0.0, 1.0).onChange(                            v => { resetSamples(); });
    coat_folder.close();

    // Fuzz folder
    const fuzz_folder = material_folder.addFolder('Fuzz');
    fuzz_folder.add(params,          'fuzz_weight', 0.0, 1.0).onChange(                               v => { resetSamples(); });
    fuzz_folder.addColor(params,     'fuzz_color').onChange(                                          v => { resetSamples(); });
    fuzz_folder.add(params,          'fuzz_roughness', 0.0, 1.0).onChange(                            v => { resetSamples(); });
    fuzz_folder.close();

    // Emission folder
    const emission_folder = material_folder.addFolder('Emission');
    emission_folder.add(params,          'emission_weight', 0.0, 1.0).onChange(                       v => { resetSamples(); });
    emission_folder.add(params,          'emission_luminance', 0.0, 10.0).onChange(                   v => { resetSamples(); });
    emission_folder.addColor(params,     'emission_color').onChange(                                  v => { resetSamples(); });
    emission_folder.close();

    // Thin-film folder
    const thin_film_folder = material_folder.addFolder('Thin Film');
    thin_film_folder.add(params,          'thin_film_weight', 0.0, 1.0).onChange(                     v => { resetSamples(); });
    thin_film_folder.add(params,          'thin_film_thickness', 0.0, 20000.0).onChange(               v => { resetSamples(); });
    thin_film_folder.add(params,          'thin_film_ior', 1.0, 3.0).onChange(                        v => { resetSamples(); });
    thin_film_folder.close();

    // geometry folder
    const geometry_folder = material_folder.addFolder('Geometry');
    geometry_folder.add(params,      'geometry_opacity', 0.0, 1.0).onChange(                          v => { resetSamples(); });
    geometry_folder.add(params,      'geometry_thin_walled').onChange(                                v => { resetSamples(); });
    geometry_folder.close();

    ///// Lighting folder /////////////////////////////////////
    const lighting_folder = gui.addFolder('Lighting');
    lighting_folder.add(params, 'skyPower', 0.0, 2.0).onChange(                                       v => { resetSamples(); });
    lighting_folder.addColor(params, 'skyColor').onChange(                                            v => { resetSamples(); });
    lighting_folder.add(params, 'sunPower', -4.0, 4.0).onChange(                                      v => { resetSamples(); });
    lighting_folder.add(params, 'sunAngularSize', 0.0, 40.0).onChange(                                v => { resetSamples(); });
    lighting_folder.add(params, 'sunLatitude', 0.0, 90.0).onChange(                                   v => { resetSamples(); });
    lighting_folder.add(params, 'sunLongitude', 0.0, 360.0).onChange(                                 v => { resetSamples(); });
    lighting_folder.addColor(params, 'sunColor').onChange(                                            v => { resetSamples(); });
    lighting_folder.close();

    ///// Renderer folder /////////////////////////////////////
    const renderer_folder = gui.addFolder('Renderer');
    renderer_folder.add(params, 'renderer_mode', getRendererModes()).onChange(                           v => { load_scene(params.scene_name); });
    renderer_folder.add(params, 'scene_name', scene_names).onChange(                                  v => { load_scene(v); });
    renderer_folder.add( params, 'smooth_normals' ).onChange(                                         v => { resetSamples(); });
    renderer_folder.add( params, 'wireframe' ).onChange(                                              v => { resetSamples(); });
    renderer_folder.addColor(params, 'neutral_color').onChange(                                       v => { resetSamples(); });
    renderer_folder.add( params, 'bounces', 0, 100, 1 ).onChange(                                     v => { resetSamples(); } );
    renderer_folder.add( params, 'max_samples' ).onChange(                                            v => { load_scene(params.scene_name); });
    renderer_folder.add( params, 'max_volume_steps', 1, 100, 1 ).onChange(                            v => { resetSamples(); } );
    renderer_folder.add( params, 'firefly_clamp', 1, 1000 ).onChange(                                v => { resetSamples(); } );
    renderer_folder.close();

    gui.add( params, 'reset_camera' );
    gui.open();
}

function post_load_setup()
{
    console.log(scene);

    if (!PATHTRACING)
    {
        //////////////////////////////////////////////////////////
        // Setup THREE.js lighting
        //////////////////////////////////////////////////////////

        directionalLight = new DirectionalLight(0xffffff, 1.0);

        updateSunDir()
        let dL = 20.0;
        directionalLight.position.set(MESH_PROPS.position[0] + dL*params.sunDir[0],
                                      MESH_PROPS.position[1] + dL*params.sunDir[1],
                                      MESH_PROPS.position[2] + dL*params.sunDir[2]);
        directionalLight.target.position.copy( MESH_PROPS.position );
        directionalLight.castShadow = true; // default false

        //Set up shadow properties for the directionalLight
        directionalLight.shadow.mapSize.width  = 2048; // default
        directionalLight.shadow.mapSize.height = 2048; // default

        let shadow_extent = 9.0;
        directionalLight.shadow.camera.left   = -shadow_extent;
        directionalLight.shadow.camera.right  =  shadow_extent;
        directionalLight.shadow.camera.bottom = -shadow_extent;
        directionalLight.shadow.camera.top    =  shadow_extent;
        directionalLight.shadow.camera.near = 10.0; // default
        directionalLight.shadow.camera.far = 100.0; // default
        directionalLight.shadowDarkness = 0.0;
        scene.add( directionalLight );

        ambientLight = new AmbientLight( 0x0 );
        scene.add( ambientLight );

        // NB, add this helper to debug shadow map issues
        //const helper = new CameraHelper(directionalLight.shadow.camera);
        //scene.add(helper);
    }

    if (PATHTRACING)
    {
        //////////////////////////////////////////////////////////
        // Setup framebuffers for pathtracing
        //////////////////////////////////////////////////////////
        pathtracedQuad = new FullScreenQuad( active_pathtrace_material() );

        const pt = active_pathtrace_material();
        pt.transparent = true;
        pt.depthWrite = false;

        pathtracingRenderTarget = new WebGLRenderTarget(1, 1, {format: RGBAFormat, type: FloatType, colorSpace: LinearSRGBColorSpace});
        pathtracedFinalQuad = new FullScreenQuad( new MeshBasicMaterial({map: pathtracingRenderTarget.texture}) );
    }

    // Trigger initial shader compile
    trigger_recompile();

    //////////////////////////////////////////////////////////
    // Setup camera
    //////////////////////////////////////////////////////////
    if (!camera_initialized)
        reset_camera(params.scene_name);
    camera_initialized = true;

    //////////////////////////////////////////////////////////
    // Setup GUI
    //////////////////////////////////////////////////////////
    setup_gui();

    //////////////////////////////////////////////////////////
    // Setup window
    //////////////////////////////////////////////////////////
    window.addEventListener( 'resize', resize, false );
    resize();
}

const SHADER_COMPILE_WARN_MS  = 10000;  // avertissement après 10 s
const SHADER_COMPILE_ABORT_MS = 600000;  // timeout d'abandon après 600 s

function trigger_recompile()
{
    let tmp_cam = new OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );
    startCompilationProgress();

    let promises = [renderer.compileAsync(scene, tmp_cam)];

    // FullScreenQuad meshes aren't in the scene, so compile them separately
    if (PATHTRACING && pathtracedQuad) {
        promises.push(renderer.compileAsync(pathtracedQuad._mesh, tmp_cam));
    }

    // Avertissement progressif si la compilation est longue
    const warnTimer = setTimeout(() => {
        progress_bar.setText('shaders compiling… (long shader, please wait)');
        console.warn('Shader compilation taking longer than expected (> ' + (SHADER_COMPILE_WARN_MS/1000) + 's)');
    }, SHADER_COMPILE_WARN_MS);

    // Timeout d'abandon : arrêter d'attendre et afficher une erreur
    let aborted = false;
    const abortTimer = setTimeout(() => {
        aborted = true;
        clearTimeout(warnTimer);
        finishCompilationProgress();
        const overlay = document.getElementById('shader-error');
        document.getElementById('shader-error-content').textContent =
            'Shader compilation timeout (' + (SHADER_COMPILE_ABORT_MS/1000) + 's).\n' +
            'La compilation GPU ne s\'est pas terminée dans le délai imparti.\n' +
            'Essayez de recharger la page ou de réduire la complexité des shaders.';
        overlay.style.display = 'block';
        console.error('Shader compilation timed out after ' + (SHADER_COMPILE_ABORT_MS/1000) + 's.');
    }, SHADER_COMPILE_ABORT_MS);

    Promise.all(promises).then(() => {
        if (aborted) return;
        clearTimeout(warnTimer);
        clearTimeout(abortTimer);
        console.log('shaders successfully compiled.');
        // Warm-up render to flush any remaining GPU pipeline stalls
        if (PATHTRACING && pathtracedQuad && pathtracingRenderTarget) {
            renderer.setRenderTarget(pathtracingRenderTarget);
            pathtracedQuad.render(renderer);
            renderer.setRenderTarget(null);
            resetSamples();
        }
        finishCompilationProgress();
    }).catch((err) => {
        clearTimeout(warnTimer);
        clearTimeout(abortTimer);
        console.log('shader compilation error: ' + err);
    });
}

function startCompilationProgress()
{
    console.log('startCompilationProgress');
    // Hide any previous shader error
    document.getElementById('shader-error').style.display = 'none';
    document.getElementById('shader-error-content').textContent = '';
    let progress_overlay = document.getElementById('progress_overlay');
    progress_overlay.style.display = 'block';
    progress_overlay.style.opacity = 1;
    progress_bar.set(0.0);
    progress_bar.setText('shaders compiling...');
    COMPILING = true;
}

function finishCompilationProgress()
{
    console.log('finishCompilationProgress');
    progress_bar.set(1.0);
    progress_finished_timer = performance.now();
    COMPILING = false;
    // Signal headless readiness (used by launch_render.mjs)
    window.__openpbrReady   = true;
    window.__openpbrSamples = 0;
}

function resize()
{
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    const w = window.innerWidth;
    const h = window.innerHeight;
    renderer.setSize( w, h );
    renderer.setPixelRatio(1.0);
    if (PATHTRACING)
        pathtracingRenderTarget.setSize(w, h);
    resetSamples();
}

function get_vector3(array3)
{
    return new Vector3(array3[0], array3[1], array3[2]);
}

function resetSamples()
{
    samples = 0;
}

function fadeOutProgressBar(time_ms)
{
    let progress_overlay = document.getElementById('progress_overlay');
    var fadeOutEffect = setInterval(function () {
    if (!progress_overlay.style.opacity) {
        progress_overlay.style.opacity = 1;
    }
    if (progress_overlay.style.opacity > 0) {
        progress_overlay.style.opacity -= 0.025;
    } else {
        progress_overlay.style.display = 'none';
        progress_overlay.style.opacity = 0;
        clearInterval(fadeOutEffect);
    }
    }, time_ms);
}

function sync_shader_uniforms(uniforms)
{
    const w = window.innerWidth;
    const h = window.innerHeight;

    // sync camera
    uniforms.cameraWorldMatrix.value.copy( camera.matrixWorld );
    uniforms.invProjectionMatrix.value.copy( camera.projectionMatrixInverse );
    uniforms.invModelMatrix.value.copy( scene.matrixWorld ).invert();

    // sync renderer params
    let resolution = new Vector2(w, h);
    uniforms.resolution.value.copy(resolution);
    uniforms.accumulation_weight.value                    = 1.0 / (samples + 1.0); // implements Monte-Carlo accumulation
    uniforms.samples.value                                = samples;

    uniforms.wireframe.value                              = params.wireframe;
    uniforms.neutral_color.value.copy(get_vector3(          params.neutral_color));
    uniforms.smooth_normals.value                         = params.smooth_normals;
    if (uniforms.bounces)           uniforms.bounces.value           = params.bounces;
    if (uniforms.max_volume_steps)  uniforms.max_volume_steps.value  = params.max_volume_steps;
    if (uniforms.firefly_clamp)     uniforms.firefly_clamp.value     = params.firefly_clamp;

    // sync material params
    // (material params are now folded as GLSL globals by the MaterialX WASM generator;
    //  no per-parameter uniforms to update at runtime)

    // sync lighting params
    uniforms.skyPower.value                               = params.skyPower;
    uniforms.skyColor.value.copy(get_vector3(               params.skyColor));

    uniforms.sunPower.value                               = Math.pow(10.0, params.sunPower);
    uniforms.sunAngularSize.value                         = params.sunAngularSize;
    uniforms.sunColor.value.copy(get_vector3(               params.sunColor));
    updateSunDir();
    uniforms.sunDir.value.copy(get_vector3(                 params.sunDir));

    // Extra uniforms for the legacy pathtracer (material params as uniforms, not GLSL globals).
    if (uniforms.base_weight !== undefined) {
        uniforms.base_weight.value                            = params.base_weight ?? 1.0;
        uniforms.base_color.value.copy(get_vector3(             params.base_color ?? [0.8,0.8,0.8]));
        uniforms.base_diffuse_roughness.value                 = params.base_diffuse_roughness ?? 0.0;
        uniforms.base_metalness.value                         = params.base_metalness ?? 0.0;
        uniforms.specular_weight.value                        = params.specular_weight ?? 1.0;
        uniforms.specular_color.value.copy(get_vector3(         params.specular_color ?? [1,1,1]));
        uniforms.specular_roughness.value                     = params.specular_roughness ?? 0.3;
        uniforms.specular_anisotropy.value                    = params.specular_anisotropy ?? 0.0;
        uniforms.specular_ior.value                           = params.specular_ior ?? 1.5;
        uniforms.transmission_weight.value                    = params.transmission_weight ?? 0.0;
        uniforms.transmission_color.value.copy(get_vector3(     params.transmission_color ?? [1,1,1]));
        uniforms.transmission_depth.value                     = params.transmission_depth ?? 0.0;
        uniforms.transmission_scatter.value.copy(get_vector3(   params.transmission_scatter ?? [0,0,0]));
        uniforms.transmission_scatter_anisotropy.value        = params.transmission_scatter_anisotropy ?? 0.0;
        uniforms.coat_weight.value                            = params.coat_weight ?? 0.0;
        uniforms.coat_color.value.copy(get_vector3(             params.coat_color ?? [1,1,1]));
        uniforms.coat_roughness.value                         = params.coat_roughness ?? 0.0;
        uniforms.coat_ior.value                               = params.coat_ior ?? 1.6;
        uniforms.coat_darkening.value                         = params.coat_darkening ?? 1.0;
        uniforms.fuzz_weight.value                            = params.fuzz_weight ?? 0.0;
        uniforms.fuzz_color.value.copy(get_vector3(             params.fuzz_color ?? [1,1,1]));
        uniforms.fuzz_roughness.value                         = params.fuzz_roughness ?? 0.5;
        uniforms.emission_weight.value                        = params.emission_weight ?? 0.0;
        uniforms.emission_luminance.value                     = params.emission_luminance ?? 0.0;
        uniforms.emission_color.value.copy(get_vector3(         params.emission_color ?? [1,1,1]));
        uniforms.geometry_opacity.value                       = params.geometry_opacity ?? 1.0;
        uniforms.geometry_thin_walled.value                   = params.geometry_thin_walled ?? false;
    }
}

function render()
{
    if (!LOADED)
    {
        console.log('not LOADED')
        requestAnimationFrame( render );
        return;
    }

    renderer.domElement.style.imageRendering = 'auto';

    if (samples >= params.max_samples)
    {
        requestAnimationFrame( render );
        return;
    }

    if (!COMPILING && LOADED)
    {
        camera.updateMatrixWorld();

        //////////////////////////////////////////////////////
        // render framebuffer
        //////////////////////////////////////////////////////

        if (PATHTRACING)
        {
            sync_shader_uniforms(active_pathtrace_material().uniforms);

            // render float target
            renderer.autoClear = (samples === 0);
            renderer.setRenderTarget( pathtracingRenderTarget );
            pathtracedQuad.render( renderer );

            // render to screen
            renderer.setRenderTarget( null );
            renderer.autoClear = true;
            pathtracedFinalQuad.render( renderer );

            samples++;
            window.__openpbrSamples = samples;
        }
        else
        {

            renderer.setRenderTarget( null );
            sync_shader_uniforms(openpbrMaterial.uniforms);
            neutralMaterial.uniforms.neutral_color.value.copy(get_vector3(params.neutral_color));
            neutralMaterial.uniforms.skyPower.value                               = params.skyPower;
            neutralMaterial.uniforms.skyColor.value.copy(get_vector3(               params.skyColor));
            neutralMaterial.uniforms.sunPower.value                               = Math.pow(10.0, params.sunPower);
            neutralMaterial.uniforms.sunColor.value.copy(get_vector3(               params.sunColor));
            neutralMaterial.uniforms.sunDir.value.copy(get_vector3(                 params.sunDir));

            let dL = 20.0;
            directionalLight.position.set(MESH_PROPS.position.x + dL*params.sunDir[0],
                                          MESH_PROPS.position.y + dL*params.sunDir[1],
                                          MESH_PROPS.position.z + dL*params.sunDir[2]);
            directionalLight.intensity = Math.pow(10.0, params.sunPower);
            let sunColor3 = new Color(params.sunColor[0], params.sunColor[1], params.sunColor[2]);
            directionalLight.color.copy(sunColor3);
            directionalLight.updateMatrix();

            let skyColor3 = new Color(params.skyColor[0], params.skyColor[1], params.skyColor[2]);
            ambientLight.color.copy(skyColor3);
            ambientLight.intensity = params.skyPower;

            renderer.shadowMap.needsUpdate = true;

            camera.updateProjectionMatrix();
            camera.clearViewOffset();

            renderer.setRenderTarget( null );
            renderer.autoClear = true;
            renderer.render( scene, camera );
        }
    }
    else
    {
        resetSamples();
        camera.updateProjectionMatrix();
        camera.clearViewOffset();
        renderer.render( scene, camera );
        renderer.autoClear = true;
    }

    // Text HUD update
    let samples_txt = document.getElementById('samples');
    let    info_txt = document.getElementById('info');
    if (PATHTRACING)
    {
        samples_txt.style.visibility = 'visible';
        samples_txt.innerText = `samples: ${ samples }`;
        const modeLabel = is_legacy_pt() ? 'pathtracing (legacy)' : 'pathtracing (MaterialX)';
        info_txt.innerText = `OpenPBR viewer, ${modeLabel} (press 'R' to cycle mode)`;
    }
    else
    {
        samples_txt.style.visibility = 'hidden';
        info_txt.innerText = `OpenPBR viewer, rasterization mode (press 'R' to cycle mode)`;
    }

    // Progress spinner update
    if (!COMPILING)
    {
        let progress_overlay = document.getElementById('progress_overlay');
        let progress_bar_visible = progress_overlay.style.display != 'none';
        if (progress_bar_visible)
        {
            let time_since_progress_finished_ms = performance.now() - progress_finished_timer;
            if (time_since_progress_finished_ms > 300.0)
                fadeOutProgressBar(300);
        }
    }
    if (COMPILING)
    {
        console.log('COMPILING...');
        if (progress_bar.value() < 0.01)
            progress_bar.animate(1.0);
        else if (progress_bar.value() > 0.99)
        {
            progress_bar.set(0.0);
            progress_bar.animate(1.0);
        }
    }

    stats.update();

    requestAnimationFrame( render );
}


document.onkeydown = function (event)
{
    event = event || window.event;
    var charCode = (event.which) ? event.which : event.keyCode;
    switch (charCode)
    {
        case 122: // F11 key: go fullscreen
        {
            var element	= document.body;
            if      ( 'webkitCancelFullScreen' in document ) element.webkitRequestFullScreen();
            else if ( 'mozCancelFullScreen'    in document ) element.mozRequestFullScreen();
            else console.assert(false);
            orbitControls.update();
            resetSamples();
            break;
        }
        case 70: // F key: reset cam
        {
            reset_camera(params.scene_name);
            break;
        }
        case 72: // H key: toggle hide/show gui
        {
            gui.show( gui._hidden );
            if (document.body.contains(stats.dom)) document.body.removeChild( stats.dom );
            else                                   document.body.appendChild( stats.dom );
            let info_txt = document.getElementById('info');
            if (info_txt.style.visibility == 'visible') info_txt.style.visibility = 'hidden';
            else                                        info_txt.style.visibility = 'visible';
            let samples_txt = document.getElementById('samples');
            if (samples_txt.style.visibility == 'visible') samples_txt.style.visibility = 'hidden';
            else                                           samples_txt.style.visibility = 'visible';
            break;
        }
        case 87: // W key: cam forward
        {
            let toTarget = new Vector3();
            toTarget.copy(orbitControls.target);
            toTarget.sub(camera.position);
            let distToTarget = toTarget.length();
            toTarget.normalize();
            var move = new Vector3();
            move.copy(toTarget);
            move.multiplyScalar(orbitControls.flySpeed*distToTarget);
            camera.position.add(move);
            orbitControls.target.add(move);
            orbitControls.update();
            resetSamples();
            break;
        }
        case 65: // A key: cam left
        {
            let toTarget = new Vector3();
            toTarget.copy(orbitControls.target);
            toTarget.sub(camera.position);
            let distToTarget = toTarget.length();
            var localX = new Vector3(1.0, 0.0, 0.0);
            var worldX = localX.transformDirection( camera.matrix );
            var move = new Vector3();
            move.copy(worldX);
            move.multiplyScalar(-orbitControls.flySpeed*distToTarget);
            camera.position.add(move);
            orbitControls.target.add(move);
            orbitControls.update();
            resetSamples();
            break;
        }
        case 83: // S key: cam back
        {
            let toTarget = new Vector3();
            toTarget.copy(orbitControls.target);
            toTarget.sub(camera.position);
            let distToTarget = toTarget.length();
            toTarget.normalize();
            var move = new Vector3();
            move.copy(toTarget);
            move.multiplyScalar(-orbitControls.flySpeed*distToTarget);
            camera.position.add(move);
            orbitControls.target.add(move);
            orbitControls.update();
            resetSamples();
            break;
        }
        case 68: // D key: cam right
        {
            let toTarget = new Vector3();
            toTarget.copy(orbitControls.target);
            toTarget.sub(camera.position);
            let distToTarget = toTarget.length();
            var localX = new Vector3(1.0, 0.0, 0.0);
            var worldX = localX.transformDirection( camera.matrix );
            var move = new Vector3();
            move.copy(worldX);
            move.multiplyScalar(orbitControls.flySpeed*distToTarget);
            camera.position.add(move);
            orbitControls.target.add(move);
            orbitControls.update();
            resetSamples();
            break;
        }
        case 80: // P key: save current image to disk
        {
            var link = document.createElement('a');
            let filename = `openpbr-viewer-screenshot.png`;
            link.download = filename;
            renderer.domElement.toBlob(function(blob){
                    link.href = URL.createObjectURL(blob);
                    var event = new MouseEvent('click');
                    link.dispatchEvent(event);
                    requestAnimationFrame( render );
                },'image/png', 1);
            break;
        }

        case 82: // R key: cycle available renderer modes
        {
            const modes = getRendererModes();
            params.renderer_mode = modes[(modes.indexOf(params.renderer_mode) + 1) % modes.length];
            PATHTRACING = (params.renderer_mode !== 'Rasterizer');
            load_scene(params.scene_name);
            break;
        }
    }
}