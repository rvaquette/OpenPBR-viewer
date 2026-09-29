
    const fileValue = getMtlxInput(imageNode, 'file')?.getAttribute('value');
    if (!fileValue) throw new Error('[mtlx-displacement] displacement image file is missing');
import { Scene,
    Vector2, Vector3, Matrix4, Box3, Color,
    Mesh, MeshBasicMaterial, MeshStandardMaterial, MeshLambertMaterial, ShaderMaterial,
    Float32BufferAttribute, BufferGeometry,
    PlaneGeometry,
    PerspectiveCamera, OrthographicCamera,
    DirectionalLight, AmbientLight, DoubleSide,
    LinearSRGBColorSpace, SRGBColorSpace, RGBAFormat, FloatType,
    WebGLRenderer, WebGLRenderTarget, RepeatWrapping,
    EquirectangularReflectionMapping, CubeReflectionMapping,
    UniformsUtils, UniformsLib, ShaderLib,
    DataTexture, NearestFilter,
    PCFSoftShadowMap, CameraHelper  } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { FullScreenQuad } from 'three/addons/postprocessing/Pass.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';
import { loadEnvironmentTexture } from './src/envmap/envLoader.js';
import { loadNativeTexture } from './src/textures/textureLoader.js';
import { applyMtlxDisplacement } from './src/mtlx/displacement.js';
import { loadMtlxArchive } from './src/mtlx/archive.js';
//import Stats from 'stats.js';

import {
    MeshBVH,
    MeshBVHUniformStruct,
    FloatVertexAttributeTexture,
    shaderStructs,
    shaderIntersectFunction,
    SAH,
} from './src/bvh-compat.js';

import { GUI } from './node_modules/lil-gui/dist/lil-gui.esm.js';

// MTLX pathtracer host route (feature 003): copied integrator; the per-material
// dispatch (mtlxGen*) is generated at runtime and wired via an inline bridge.
import {
    glsl_mtlx_route_common,
    glsl_mtlx_route_pathtracer,
    glsl_rasterization_mtlx_common,
    glsl_rasterization_mtlx_rasterizer,
    glsl_rasterization_legacy_bvh_rasterizer,
    glsl_legacy_main,
    glsl_legacy_fuzz_brdf,
    glsl_legacy_coat_brdf,
    glsl_legacy_thin_film,
    glsl_legacy_metal_brdf,
    glsl_legacy_specular_brdf,
    glsl_legacy_specular_btdf,
    glsl_legacy_diffuse_brdf,
    glsl_legacy_diffuse_btdf,
    glsl_legacy_openpbr_surface,
    glsl_legacy_pathtracer,
    glsl_rasterization_openpbr_frag,
    glsl_rasterization_openpbr_vert,
    glsl_rasterization_neutral_frag,
    glsl_rasterization_neutral_vert
} from './glsl-sources.js';

import { Circle } from 'progressbar.js'

let gpuDebugStage = { name: 'startup', since: performance.now() };

function setGpuDebugStage(name)
{
    if (gpuDebugStage.name === name) return;
    gpuDebugStage = { name, since: performance.now() };
    window.__openpbrGpuStage = gpuDebugStage;
}

function buildBvh(geometry)
{
    setGpuDebugStage('building-bvh');
    const bvh = new MeshBVH(geometry, { strategy: SAH });
    setGpuDebugStage('bvh-built');
    return bvh;
}

function createBvhUniforms(prefix)
{
    return { [prefix]: { value: new MeshBVHUniformStruct() } };
}

function assignBvhUniforms(uniforms, prefix, bvh)
{
    uniforms[prefix].value.updateFrom(bvh);
}

// Rewrites the sampler-based route GLSL into the three-mesh-bvh interface
// (one `BVH` struct uniform + shaderStructs/shaderIntersectFunction).
// The bvhIntersectFirstHitWithinDistance(...) call site is identical text in every
// *.glsl file, so a single pair of regexes covers all of them.
function adaptBvhGlslForEngine(source)
{
    return source
        .replace(
            /uniform sampler2D (\w+)_nodes;\s*uniform sampler2D \1_indices;\s*uniform sampler2D \1_positions;/g,
            (_match, name) => `uniform BVH ${name};`
        )
        .replace(
            /bool bvhIntersectFirstHitWithinDistance\(\s*sampler2D nodes,\s*sampler2D indices,\s*sampler2D positions,\s*vec3 rayOrigin,\s*vec3 rayDirection,\s*in float maxDistance,[\s\S]*?\n\}/,
            ''
        )
        .replace(
            /([ \t]*)bool\s+(\w+)\s*=\s*bvhIntersectFirstHitWithinDistance\(\s*(\w+)_nodes,\s*\3_indices,\s*\3_positions,\s*([^,]+),\s*([^,]+),([\s\S]*?),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+)\s*\);/g,
            (_match, indent, hit, bvh, rayOrigin, rayDirection, maxDistance, faceIndices, faceNormal, barycoord, side, dist) => [
                `${indent}bool ${hit} = bvhIntersectFirstHit(${bvh}.index, ${bvh}.position, ${bvh}.bvhBounds, ${bvh}.bvhContents, ${rayOrigin}, ${rayDirection});`,
                `${indent}if (${hit} && bvhHitDistance < ${maxDistance}) {`,
                `${indent}    ${faceIndices} = bvhHitFaceIndices;`,
                `${indent}    ${faceNormal} = bvhHitFaceNormal;`,
                `${indent}    ${barycoord} = bvhHitBarycoord;`,
                `${indent}    ${side} = bvhHitSide;`,
                `${indent}    ${dist} = bvhHitDistance;`,
                `${indent}} else {`,
                `${indent}    ${hit} = false;`,
                `${indent}}`
            ].join('\n')
        );
}

// GLSL prelude providing the BVH struct/intersection primitives, chosen per engine.
function bvhGlslPrelude()
{
    return shaderStructs + shaderIntersectFunction;
}

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

    async load(path, options = {})
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
            const mergedGeometry = mergeGeometries(meshes.map(mesh => mesh.geometry.clone()), false);
            if (!mergedGeometry) throw new Error('Unable to merge mesh geometries for BVH construction.');
            mergedGeometry.clearGroups();
            let merged_mesh = new Mesh(mergedGeometry, new MeshStandardMaterial());

            let bvh = buildBvh(merged_mesh.geometry);
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
    renderer_mode:                      'Rasterizer MTLX',
    mtlx_directory:                     '',
    mtlx_material:                      '',
    paused:                             true,   // pathtracer accumulation starts paused; toggle in GUI or ?paused=false
    smooth_normals:                     true,
    bounces:                            6,
    max_samples:                        512,
    render_size:                        '256x256',   // render-target size for fullscreen BVH routes; final quad upscales to screen
    max_volume_steps:                   64,
    firefly_clamp:                      10.0,
    wireframe:                          false,
    neutral_color:                      [0.99, 0.99, 0.99],

    //////////////////////////////////////////////////////
    // lighting params
    //////////////////////////////////////////////////////

    skyPower:                            1.0,
    skyColor:                            [1.0, 1.0, 1.0],
    env_map_path:                        'textures/envmaps/Malibu_Overlook_8k.jpg',
    env_map_provided:                    false,
    env_irradiance_path:                 '',
    // Envmap CDF importance sampling (feature 004, Phase 5): opt-in, default off.
    // Known bug: produces a blown-out/white render, not yet root-caused. Cosine-
    // hemisphere sampling (previous behaviour) is used whenever this is false.
    env_cdf_sampling:                    false,
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
    VOLUME_ENABLED: true,  // always on; MaterialX handles feature presence internally
    MAX_MTLX_LIGHTS: 1
};

// Generated GLSL from MaterialX WASM (set before create_materials() is called).
var mtlxGeneratedGlsl = '';
var mtlxRouteDispatchGlsl = '';
var mtlxRouteTextureBindings = [];
var mtlxRouteLights = [];
var mtlxRouteParamDescriptors = [];
var mtlxRouteLightsTexture = null;
var activeMtlxArchiveSource = null;
var mtlxArchiveDisplacement = null;
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
var mtlxMaterialLibrary = [];
var mtlxMaterialDirectories = [];
const generatedMtlxStorageKey = 'openpbr-viewer.generated-mtlx.v1';
const copilotMtlxEndpoint = import.meta.env?.VITE_COPILOT_MTLX_ENDPOINT ||
    window.OPENPBR_COPILOT_MTLX_ENDPOINT || '/api/copilot/mtlx';
const ambientCgArchiveEndpoint = import.meta.env?.VITE_AMBIENTCG_ARCHIVE_ENDPOINT ||
    window.OPENPBR_AMBIENTCG_ARCHIVE_ENDPOINT ||
    (copilotMtlxEndpoint.startsWith('http')
        ? new URL('/api/mtlx/archive', copilotMtlxEndpoint).toString()
        : '/api/mtlx/archive');

const LEGACY_COMPARISON_ENABLED_BY_DEFAULT = false;
const legacyComparisonEnabled = (() => {
    const search = new URLSearchParams(window.location.search);
    if (search.has('legacy_comparison')) {
        const v = search.get('legacy_comparison');
        return v === 'true' || v === '1';
    }
    return LEGACY_COMPARISON_ENABLED_BY_DEFAULT;
})();

// GPU path tracer is opt-in: by default the viewer stays on the lightweight
// Rasterizer route and never compiles the heavy path-tracing shaders. Enable it
// explicitly with ?gpu=true (or ?gpu=1).
const GPU_PATHTRACER_ENABLED_BY_DEFAULT = false;
const gpuPathtracerEnabled = (() => {
    const search = new URLSearchParams(window.location.search);
    if (search.has('gpu')) {
        const v = search.get('gpu');
        return v === 'true' || v === '1';
    }
    return GPU_PATHTRACER_ENABLED_BY_DEFAULT;
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
const APP_BASE_URL = import.meta.env?.BASE_URL || '/public/';

function getPublicAssetUrl(relPath)
{
    const origin = window.location.origin;
    return origin + APP_BASE_URL + relPath.replace(/^\/+/, '');
}

function resolveViewerAssetUrl(url)
{
    if (!url) return url;
    if (/^(?:[a-z]+:)?\/\//i.test(url)) return url;
    if (url.startsWith(APP_BASE_URL)) return url;
    if (url.startsWith('/')) return APP_BASE_URL.replace(/\/$/, '') + url;
    return url;
}

function readXmlAttr(attrs, name)
{
    const m = String(attrs || '').match(new RegExp(`\\b${name}="([^"]*)"`));
    return m ? m[1] : '';
}

function resolveMtlxTextureUrl(fileValue, materialBaseUrl, textureResolver = null)
{
    const archiveUrl = textureResolver?.(fileValue);
    if (archiveUrl) return archiveUrl;
    if (/^(?:[a-z]+:)?\/\//i.test(fileValue)) return fileValue;
    const libraryRoot = new URL(getPublicAssetUrl('mtlx-library/'));
    if (fileValue.startsWith('/')) {
        const absoluteUrl = new URL(getPublicAssetUrl(fileValue));
        if (absoluteUrl.pathname.includes('/mtlx-library/')) return absoluteUrl.toString();
        return new URL(fileValue.replace(/^\/+/, ''), libraryRoot).toString();
    }

    const relativeUrl = new URL(fileValue, materialBaseUrl || libraryRoot).toString();
    if (relativeUrl.includes('/mtlx-library/')) return relativeUrl;

    // Keep legacy paths such as ../../Images/... inside the replacement library.
    const libraryRelativePath = fileValue
        .replace(/^(?:\.\.\/)+/, '')
        .replace(/^Images\//i, '')
        .replace(/^textures\//i, 'textures/');
    return new URL(libraryRelativePath, libraryRoot).toString();
}

function extractMtlxTextureBindings(mtlxText, materialBaseUrl, archiveSource = null)
{
    // Type-agnostic: bind every <input type="filename"> to its enclosing node,
    // whatever that node is (image, tiledimage, hextiledimage, triplanar, custom...).
    // Walk the document keeping an element stack so nested nodegraphs resolve the
    // correct parent name; the generated sampler uniform is `${parentName}_file`.
    const bindings = [];
    const stack = [];
    const tagRe = /<(\/?)([A-Za-z_][\w.\-]*)\b([^>]*?)(\/?)>/g;
    let m;
    while ((m = tagRe.exec(mtlxText)) !== null) {
        const closing = m[1] === '/';
        const tag = m[2];
        const attrs = m[3];
        const selfClose = m[4] === '/';
        if (closing) { stack.pop(); continue; }
        if (tag === 'input') {
            if (readXmlAttr(attrs, 'type') === 'filename') {
                const fileValue = readXmlAttr(attrs, 'value');
                const parent = stack[stack.length - 1];
                if (fileValue && parent && parent.name) {
                    bindings.push({
                        sampler: `${parent.name}_file`,
                        url: resolveMtlxTextureUrl(fileValue, materialBaseUrl, archiveSource?.resolveTexture),
                        source: fileValue,
                        type: parent.type,
                        archiveSource
                    });
                }
            }
            continue; // <input> is always self-closing
        }
        if (!selfClose) {
            stack.push({ tag, name: readXmlAttr(attrs, 'name'), type: readXmlAttr(attrs, 'type') });
        }
    }
    return bindings;
}

function isMtlxColorTexture(binding)
{
    if (binding.type !== 'color3' && binding.type !== 'color4') return false;
    const text = `${binding.sampler} ${binding.source}`.toLowerCase();
    return !/(normal|rough|metal|mask|height|bump|ao|occlusion|opacity|alpha|dirt|variation)/.test(text);
}

function createMtlxRouteTextureUniforms()
{
    const uniforms = {};
    if (mtlxRouteTextureBindings.length === 0) return uniforms;
    for (const binding of mtlxRouteTextureBindings) {
        let settled = false;
        const finishArchiveTextureLoad = () => {
            if (settled || !binding.archiveSource) return;
            settled = true;
            const source = binding.archiveSource;
            source.textureLoadsPending = Math.max(0, source.textureLoadsPending - 1);
            if (source.retired && source.textureLoadsPending === 0) source.release();
        };
        const texture = loadNativeTexture(binding.url, finishArchiveTextureLoad, finishArchiveTextureLoad);
        texture.wrapS = RepeatWrapping;
        texture.wrapT = RepeatWrapping;
        texture.flipY = false;
        // Keep textures raw (no hardware sRGB decode): the MaterialX-generated GLSL
        // applies its own colorspace conversion per the .mtlx (srgb_texture), so tagging
        // SRGBColorSpace here would double-decode and darken color textures.
        texture.colorSpace = LinearSRGBColorSpace;
        uniforms[binding.sampler] = { value: texture };
    }
    return uniforms;
}

function getMtlxInput(node, inputName)
{
    return Array.from(node?.children || []).find(child =>
        child.tagName === 'input' && child.getAttribute('name') === inputName
    ) || null;
}

function findMtlxNodeByName(document, name)
{
    if (!name) return null;
    return Array.from(document.getElementsByTagName('*')).find(element =>
        !['input', 'output', 'nodedef', 'implementation'].includes(element.tagName) &&
        element.getAttribute('name') === name
    ) || null;
}

async function loadMtlxDisplacement(mtlxText, archiveSource)
{
    const xmlDocument = new DOMParser().parseFromString(mtlxText, 'application/xml');
    if (xmlDocument.querySelector('parsererror'))
        throw new Error('[mtlx-displacement] invalid MaterialX XML');

    const material = Array.from(xmlDocument.querySelectorAll('surfacematerial, material')).find(node =>
        getMtlxInput(node, 'displacementshader')
    );
    const shaderInput = getMtlxInput(material, 'displacementshader');
    if (!shaderInput?.getAttribute('nodename')) return null;

    const displacementNode = findMtlxNodeByName(xmlDocument, shaderInput.getAttribute('nodename'));
    if (displacementNode?.tagName !== 'displacement')
        throw new Error('[mtlx-displacement] expected a displacement node connected to surfacematerial');
    const valueInput = getMtlxInput(displacementNode, 'displacement');
    if (valueInput?.getAttribute('type') !== 'float')
        throw new Error('[mtlx-displacement] only scalar displacement nodes are supported');

    const scale = Number(getMtlxInput(displacementNode, 'scale')?.getAttribute('value') ?? 1);
    if (!Number.isFinite(scale)) throw new Error('[mtlx-displacement] scale must be finite');
    const valueNodeName = valueInput.getAttribute('nodename');
    if (!valueNodeName) {
        const value = Number(valueInput.getAttribute('value') ?? 0);
        if (!Number.isFinite(value)) throw new Error('[mtlx-displacement] value must be finite');
        return { value, scale };
    }

    const imageNode = findMtlxNodeByName(xmlDocument, valueNodeName);
    if (!['image', 'tiledimage'].includes(imageNode?.tagName) || imageNode.getAttribute('type') !== 'float')
        throw new Error('[mtlx-displacement] displacement must connect directly to image or tiledimage float');
    const texcoordInput = getMtlxInput(imageNode, 'texcoord');
    if (texcoordInput?.getAttribute('nodename') || texcoordInput?.getAttribute('nodegraph'))
        throw new Error('[mtlx-displacement] custom texture coordinates are not supported; use UV0');

    const fileValue = getMtlxInput(imageNode, 'file')?.getAttribute('value');
    const imageUrl = archiveSource?.resolveTexture(fileValue) || resolveMtlxTextureUrl(fileValue, getPublicAssetUrl(''));
    if (!imageUrl) throw new Error('[mtlx-displacement] displacement image file is missing');
    const response = await fetch(imageUrl);
    if (!response.ok) throw new Error(`[mtlx-displacement] image fetch failed (${response.status})`);
    const bitmap = await createImageBitmap(await response.blob());
    const width = bitmap.width;
    const height = bitmap.height;
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext('2d', { willReadFrequently: true });
    if (!context) {
        bitmap.close?.();
        throw new Error('[mtlx-displacement] unable to read image pixels');
    }
    context.drawImage(bitmap, 0, 0);
    const pixels = context.getImageData(0, 0, width, height).data;
    bitmap.close?.();

    const readVector2 = (name, fallback) => {
        const raw = getMtlxInput(imageNode, name)?.getAttribute('value');
        if (!raw) return fallback;
        const values = raw.split(',').map(value => Number(value.trim()));
        return values.length === 2 && values.every(Number.isFinite) ? values : fallback;
    };
    return {
        pixels,
        width: bitmap.width,
        width,
        height,
        scale,
        uvtiling: readVector2('uvtiling', [1, 1]),
        uvoffset: readVector2('uvoffset', [0, 0]),
        uaddressmode: getMtlxInput(imageNode, 'uaddressmode')?.getAttribute('value') || 'periodic',
        vaddressmode: getMtlxInput(imageNode, 'vaddressmode')?.getAttribute('value') || 'periodic',
        filtertype: getMtlxInput(imageNode, 'filtertype')?.getAttribute('value') || 'linear'
    };
}

function retireMtlxArchiveSource(source)
{
    if (!source) return;
    source.retired = true;
    if (source.textureLoadsPending === 0) source.release();
}

function parseNumberList(value, fallback, expectedLength)
{
    if (!value) return fallback;
    const parsed = value.split(',').map(v => parseFloat(v.trim()));
    if (parsed.length !== expectedLength || parsed.some(v => !Number.isFinite(v))) return fallback;
    return parsed;
}

function parseLightInputMap(innerXml)
{
    const inputs = new Map();
    const inputRe = /<input\b([^>]*)\/>/g;
    let inputMatch;
    while ((inputMatch = inputRe.exec(innerXml || '')) !== null) {
        const attrs = inputMatch[1];
        const name = readXmlAttr(attrs, 'name');
        const value = readXmlAttr(attrs, 'value');
        if (name && value !== '') inputs.set(name, value);
    }
    return inputs;
}

function angleInputToCos(value, fallback)
{
    const parsed = parseFloat(value);
    if (!Number.isFinite(parsed)) return fallback;
    if (parsed >= -1.0 && parsed <= 1.0) return parsed;
    return Math.cos(parsed * Math.PI / 180.0);
}

function normalizeVec3(values, fallback)
{
    const length = Math.hypot(values[0], values[1], values[2]);
    if (length <= 1.0e-8) return fallback;
    return values.map(v => v / length);
}

function extractMtlxLights(mtlxText)
{
    const lights = [];
    const lightRe = /<(point_light|directional_light|spot_light|quad_light)\b([^>]*)>([\s\S]*?)<\/\1>|<(point_light|directional_light|spot_light|quad_light)\b([^>]*)\/>/g;
    let lightMatch;
    while ((lightMatch = lightRe.exec(mtlxText || '')) !== null) {
        const kind = lightMatch[1] || lightMatch[4];
        const attrs = lightMatch[2] || lightMatch[5] || '';
        const inner = lightMatch[3] || '';
        const inputs = parseLightInputMap(inner);
        const name = readXmlAttr(attrs, 'name') || kind;
        if (kind === 'quad_light') {
            // Best-effort MaterialX quad_light convention (position=center, normal,
            // width, height); untested against a real generated fixture (none of the
            // mtlx-input/* materials currently define a light node) -- prefer the
            // ?mtlx_lights_json= override (corner/u/v, unambiguous) for testing.
            const normal = normalizeVec3(parseNumberList(inputs.get('normal'), [0, -1, 0], 3), [0, -1, 0]);
            const width = Number.parseFloat(inputs.get('width') ?? '1') || 1;
            const height = Number.parseFloat(inputs.get('height') ?? '1') || 1;
            const center = parseNumberList(inputs.get('position'), [0, 5, 0], 3);
            const tangent = normalToTangentJs(normal);
            const bitangent = crossJs(normal, tangent);
            const corner = center.map((c, i) => c - 0.5 * width * tangent[i] - 0.5 * height * bitangent[i]);
            lights.push({
                name, type: 3,
                position: corner,
                direction: [0, -1, 0],
                color: parseNumberList(inputs.get('color'), [1, 1, 1], 3),
                intensity: Number.parseFloat(inputs.get('intensity') ?? '1') || 0,
                decayRate: 0, innerCone: 1, outerCone: 1,
                u: tangent.map(v => v * width), v: bitangent.map(v => v * height),
            });
            continue;
        }
        const type = kind === 'directional_light' ? 1 : kind === 'spot_light' ? 2 : 0;
        lights.push({
            name,
            type,
            position: parseNumberList(inputs.get('position'), [0, 5, 0], 3),
            direction: normalizeVec3(parseNumberList(inputs.get('direction'), [0, -1, 0], 3), [0, -1, 0]),
            color: parseNumberList(inputs.get('color'), [1, 1, 1], 3),
            intensity: Number.parseFloat(inputs.get('intensity') ?? '1') || 0,
            decayRate: Number.parseFloat(inputs.get('decay_rate') ?? '2') || 0,
            innerCone: angleInputToCos(inputs.get('inner_angle'), Math.cos(20.0 * Math.PI / 180.0)),
            outerCone: angleInputToCos(inputs.get('outer_angle'), Math.cos(30.0 * Math.PI / 180.0)),
        });
    }
    return lights;
}

// Minimal vec3 helpers (kept separate from THREE.Vector3 so extractMtlxLights can
// build plain-array light records the same way whether parsed from XML or JSON).
function normalToTangentJs(n)
{
    const t = Math.abs(n[2]) < Math.abs(n[0]) ? [n[2], 0, -n[0]] : [0, n[2], -n[1]];
    const len = Math.hypot(t[0], t[1], t[2]) || 1;
    return t.map(v => v / len);
}
function crossJs(a, b)
{
    return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
}

function extractMtlxLightOverrides(search)
{
    if (!search.has('mtlx_lights_json')) return [];
    try {
        const raw = JSON.parse(search.get('mtlx_lights_json'));
        if (!Array.isArray(raw)) return [];
        return raw.map(light => {
            const isQuad = light.type === 'quad' || light.type === 3;
            const type = isQuad ? 3 : (light.type === 'directional' || light.type === 1 ? 1 : light.type === 'spot' || light.type === 2 ? 2 : 0);
            const corner = Array.isArray(light.corner) ? parseNumberList(light.corner.join(','), [0, 5, 0], 3) : [0, 5, 0];
            return {
                name: String(light.name || 'cli_light'),
                type,
                position: isQuad ? corner : (Array.isArray(light.position) ? parseNumberList(light.position.join(','), [0, 5, 0], 3) : [0, 5, 0]),
                direction: normalizeVec3(Array.isArray(light.direction) ? parseNumberList(light.direction.join(','), [0, -1, 0], 3) : [0, -1, 0], [0, -1, 0]),
                color: Array.isArray(light.color) ? parseNumberList(light.color.join(','), [1, 1, 1], 3) : [1, 1, 1],
                intensity: Number.parseFloat(light.intensity ?? '1') || 0,
                decayRate: Number.parseFloat(light.decay_rate ?? light.decayRate ?? '2') || 0,
                innerCone: angleInputToCos(String(light.inner_angle ?? light.innerCone ?? ''), Math.cos(20.0 * Math.PI / 180.0)),
                outerCone: angleInputToCos(String(light.outer_angle ?? light.outerCone ?? ''), Math.cos(30.0 * Math.PI / 180.0)),
                u: Array.isArray(light.u) ? parseNumberList(light.u.join(','), [1, 0, 0], 3) : [1, 0, 0],
                v: Array.isArray(light.v) ? parseNumberList(light.v.join(','), [0, 0, 1], 3) : [0, 0, 1],
            };
        });
    } catch (e) {
        console.warn('[mtlx-route] invalid mtlx_lights_json:', e?.message || e);
        return [];
    }
}

// Packs the light list into a (6 x N) RGBA float texture read via GetMtlxLight(i)
// in glsl/pathtracing/mtlx/pathtracer.glsl -- replaces the old fixed-size
// mtlxLight*[MAX_MTLX_LIGHTS] uniform arrays (feature 004, Phase 5 "lights"
// alignment with GLSL-PathTracer-JS's lightsTex). No shader recompile needed
// when the light count changes; only mtlxLightCount (scalar) still uses defines.
const MTLX_LIGHT_TEXELS_PER_LIGHT = 6;

function createMtlxLightsTexture()
{
    const lights = mtlxRouteLights;
    const parameterRowOffset = Math.max(1, lights.length);
    const height = parameterRowOffset + mtlxRouteParamDescriptors.length;
    const data = new Float32Array(MTLX_LIGHT_TEXELS_PER_LIGHT * height * 4);
    lights.forEach((l, i) => {
        const base = i * MTLX_LIGHT_TEXELS_PER_LIGHT * 4;
        data[base + 0] = l.position[0]; data[base + 1] = l.position[1]; data[base + 2] = l.position[2]; data[base + 3] = l.decayRate;
        data[base + 4] = l.direction[0]; data[base + 5] = l.direction[1]; data[base + 6] = l.direction[2]; data[base + 7] = l.type;
        data[base + 8] = l.color[0]; data[base + 9] = l.color[1]; data[base + 10] = l.color[2]; data[base + 11] = l.intensity;
        data[base + 12] = l.innerCone; data[base + 13] = l.outerCone; data[base + 14] = 0; data[base + 15] = 0;
        const u = l.u || [0, 0, 0]; const v = l.v || [0, 0, 0];
        data[base + 16] = u[0]; data[base + 17] = u[1]; data[base + 18] = u[2]; data[base + 19] = 0;
        data[base + 20] = v[0]; data[base + 21] = v[1]; data[base + 22] = v[2]; data[base + 23] = 0;
    });
    mtlxRouteParamDescriptors.forEach((parameter, i) => {
        const base = (parameterRowOffset + i) * MTLX_LIGHT_TEXELS_PER_LIGHT * 4;
        const values = Array.isArray(parameter.value) ? parameter.value : [parameter.value];
        values.forEach((value, component) => {
            if (component < 4) data[base + component] = Number(value);
        });
    });
    mtlxRouteLightsTexture = new DataTexture(data, MTLX_LIGHT_TEXELS_PER_LIGHT, height, RGBAFormat, FloatType);
    mtlxRouteLightsTexture.minFilter = NearestFilter;
    mtlxRouteLightsTexture.magFilter = NearestFilter;
    mtlxRouteLightsTexture.generateMipmaps = false;
    mtlxRouteLightsTexture.needsUpdate = true;
    return mtlxRouteLightsTexture;
}

function createMtlxLightUniforms()
{
    return {
        mtlxLightCount: { value: mtlxRouteLights.length },
        mtlxLightsTex:  { value: createMtlxLightsTexture() },
    };
}


function escapeRegExp(text)
{
    return String(text).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function replaceIdentifiers(source, replacements)
{
    let result = source;
    for (const [from, to] of replacements) {
        result = result.replace(new RegExp(`\\b${escapeRegExp(from)}\\b`, 'g'), to);
    }
    return result;
}

function parseMtlxParameterDefault(type, expression)
{
    const value = String(expression || '').trim();
    if (type === 'bool') return value === 'true' ? true : value === 'false' ? false : null;
    if (type === 'float' || type === 'int') {
        const number = Number(value);
        return Number.isFinite(number) ? (type === 'int' ? Math.trunc(number) : number) : null;
    }
    const vectorMatch = value.match(/^vec([234])\s*\(([^)]+)\)$/);
    if (!vectorMatch) return null;
    const size = Number(vectorMatch[1]);
    const components = vectorMatch[2].split(',').map(component => Number(component.trim()));
    if (components.length === 1) return Array(size).fill(components[0]);
    return components.length === size && components.every(Number.isFinite) ? components : null;
}

function extractMtlxParameterMetadata(mtlxText)
{
    const metadata = new Map();
    try {
        const document = new DOMParser().parseFromString(mtlxText, 'application/xml');
        for (const input of Array.from(document.getElementsByTagName('input'))) {
            const name = input.getAttribute('name');
            if (!name) continue;
            const candidate = {
                type: input.getAttribute('type') || '',
                name: input.getAttribute('uiname') || '',
                folder: input.getAttribute('uifolder') || '',
                min: Number.parseFloat(input.getAttribute('uisoftmin') ?? input.getAttribute('uimin')),
                max: Number.parseFloat(input.getAttribute('uisoftmax') ?? input.getAttribute('uimax')),
                step: Number.parseFloat(input.getAttribute('uisoftstep')),
            };
            const current = metadata.get(name);
            if (!current || (!current.name && candidate.name) || (!current.folder && candidate.folder))
                metadata.set(name, candidate);
        }
    } catch (error) {
        console.warn('[mtlx-route] unable to read UI metadata:', error?.message || error);
    }
    return metadata;
}

function bindMtlxParametersToTexture(glsl, mtlxText)
{
    if (/\bIMPL_gltf_pbr_surfaceshader\b/.test(String(glsl || ''))) {
        return { glsl, parameters: [] };
    }

    const blockPattern = /\/\/\s*__MTLX_PARAMS_BEGIN__([\s\S]*?)\/\/\s*__MTLX_PARAMS_END__/;
    const block = String(glsl || '').match(blockPattern);
    if (!block) return { glsl, parameters: [] };

    const metadata = extractMtlxParameterMetadata(mtlxText);
    const parameters = [];
    const replacements = [];
    const retainedLines = [];
    const declarationPattern = /^([ \t]*)(float|int|bool|vec[234])\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+);\s*$/;

    for (const line of block[1].split('\n')) {
        const declaration = line.match(declarationPattern);
        if (!declaration) {
            retainedLines.push(line);
            continue;
        }
        const [, , type, name, expression] = declaration;
        const value = parseMtlxParameterDefault(type, expression);
        if (value === null) {
            retainedLines.push(line);
            continue;
        }

        const info = metadata.get(name) || {};
        const parameter = {
            index: parameters.length,
            name,
            type,
            value: Array.isArray(value) ? [...value] : value,
            uiType: info.type || '',
            uiName: info.name || formatMtlxParameterLabel(name),
            uiFolder: info.folder || 'Surface',
            min: Number.isFinite(info.min) ? info.min : null,
            max: Number.isFinite(info.max) ? info.max : null,
            step: Number.isFinite(info.step) ? info.step : null,
        };
        parameters.push(parameter);

        const texel = `mtlxGetMaterialParam(${parameter.index})`;
        const accessor = type === 'bool' ? `(${texel}.x > 0.5)`
            : type === 'int' ? `int(${texel}.x)`
            : type === 'vec2' ? `${texel}.xy`
            : type === 'vec3' ? `${texel}.xyz`
            : type === 'vec4' ? texel
            : `${texel}.x`;
        replacements.push([name, accessor]);
    }

    const transformedBlock = `// __MTLX_PARAMS_BEGIN__\n${retainedLines.join('\n')}\n// __MTLX_PARAMS_END__`;
    const transformedGlsl = String(glsl).replace(blockPattern, transformedBlock);
    return { glsl: replaceMtlxParameterReferences(transformedGlsl, replacements), parameters };
}

function updateMtlxParameterTexture(parameter)
{
    const texture = mtlxRouteLightsTexture;
    if (!texture) return;
    const row = Math.max(1, mtlxRouteLights.length) + parameter.index;
    const offset = row * MTLX_LIGHT_TEXELS_PER_LIGHT * 4;
    const data = texture.image.data;
    data.fill(0, offset, offset + 4);
    const values = Array.isArray(parameter.value) ? parameter.value : [parameter.value];
    values.forEach((value, component) => {
        if (component < 4) data[offset + component] = Number(value);
    });
    texture.needsUpdate = true;
    resetSamples();
}

function findMatchingBrace(source, openIndex)
{
    let depth = 0;
    for (let i = openIndex; i < source.length; ++i) {
        const ch = source[i];
        if (ch === '{') depth++;
        else if (ch === '}') {
            depth--;
            if (depth === 0) return i;
        }
    }
    return -1;
}

function extractFunctionBlocks(source)
{
    const blocks = [];
    const re = /(^|\n)([A-Za-z_][A-Za-z0-9_<>]*\s+(?:[A-Za-z_][A-Za-z0-9_<>]*\s+)*)([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{}]*\)\s*\{/g;
    let match;
    while ((match = re.exec(source)) !== null) {
        const name = match[3];
        const start = match.index + match[1].length;
        const open = source.indexOf('{', re.lastIndex - 1);
        const close = findMatchingBrace(source, open);
        if (close < 0) continue;
        const end = close + 1;
        const signature = source.slice(start, open).replace(/\s+/g, ' ').trim();
        blocks.push({ name, signature, start, end, text: source.slice(start, end) });
        re.lastIndex = end;
    }
    return blocks;
}

function replaceMtlxParameterReferences(source, replacements)
{
    let result = source;
    const blocks = extractFunctionBlocks(source);
    for (const block of [...blocks].sort((a, b) => b.start - a.start)) {
        const open = source.indexOf('{', block.start);
        const close = block.end - 1;
        if (open < 0 || close <= open) continue;

        const parametersStart = block.signature.indexOf('(');
        const parametersEnd = block.signature.lastIndexOf(')');
        const parameterNames = new Set();
        if (parametersStart >= 0 && parametersEnd > parametersStart) {
            for (const declaration of block.signature.slice(parametersStart + 1, parametersEnd).split(',')) {
                const tokens = declaration.trim().split(/\s+/);
                const name = tokens[tokens.length - 1]?.replace(/\[.*$/, '');
                if (name) parameterNames.add(name);
            }
        }

        const body = source.slice(open + 1, close);
        const bodyReplacements = replacements.filter(([name]) => {
            if (parameterNames.has(name)) return false;
            const escapedName = escapeRegExp(name);
            return !new RegExp(`\\b(?:float|int|bool|vec[234])\\s+${escapedName}\\b`).test(body);
        });
        const updatedBody = replaceIdentifiers(body, bodyReplacements);
        result = result.slice(0, open + 1) + updatedBody + result.slice(close);
    }
    return result;
}

function removeFunctionBlocks(source, removeBlocks)
{
    let result = source;
    for (const block of [...removeBlocks].sort((a, b) => b.start - a.start)) {
        result = result.slice(0, block.start) + result.slice(block.end);
    }
    return result;
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
        contractUrl = APP_BASE_URL.replace(/\/$/, '') + contractUrl;
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
    return [
        // 'Rasterizer legacy',
        'Rasterizer MTLX',
        'Pathtracer MTLX',
        // 'Pathtracer legacy'
    ];
}

function getRendererModeOptions()
{
    return {
        // 'Rasterizer legacy': 'Rasterizer legacy',
        'Rasterizer MTLX':   'Rasterizer MTLX',
        'Pathtracer MTLX':   'Pathtracer MTLX'
        // 'Pathtracer legacy': 'Pathtracer legacy'
    };
}

function is_mtlx_route() { return params.renderer_mode === 'Pathtracer MTLX'; }
function is_mtlx_bvh_raster_route() { return params.renderer_mode === 'Rasterizer MTLX'; }
function is_legacy_bvh_raster_route() { return params.renderer_mode === 'Rasterizer legacy'; }
function uses_mtlx_fullscreen_shader() { return is_mtlx_route() || is_mtlx_bvh_raster_route(); }

function is_pathtracing_route()
{
    return params.renderer_mode === 'Pathtracer MTLX' ||
           params.renderer_mode === 'Pathtracer legacy';
}

function is_fullscreen_bvh_route()
{
    return is_pathtracing_route() || is_mtlx_bvh_raster_route() || is_legacy_bvh_raster_route();
}

// Pack per-vertex attributes into 3 RGBA textures for the MTLX fullscreen route,
// keeping the sampler count under MAX_TEXTURE_IMAGE_UNITS(16):
//   geomN = (normal.xyz, uv.x), geomT = (tangent.xyz, uv.y), geomS = (neutralFlag, 0, 0, 0)
function packSurfaceGeom(geometry)
{
    const pos  = geometry.attributes.position;
    const N    = pos.count;
    const nrm  = geometry.attributes.normal || null;
    const tan  = geometry.attributes.tangent || null;
    const uv   = geometry.attributes.uv || null;
    const neutral = geometry.attributes.neutralFlag || null;
    const gN = new Float32Array(N * 4);
    const gT = new Float32Array(N * 4);
    const gS = new Float32Array(N * 4);
    for (let i = 0; i < N; i++)
    {
        gN[4*i+0] = nrm ? nrm.getX(i) : 0.0;
        gN[4*i+1] = nrm ? nrm.getY(i) : 0.0;
        gN[4*i+2] = nrm ? nrm.getZ(i) : 1.0;
        gN[4*i+3] = uv  ? uv.getX(i)  : 0.0;
        gT[4*i+0] = tan ? tan.getX(i) : 1.0;
        gT[4*i+1] = tan ? tan.getY(i) : 0.0;
        gT[4*i+2] = tan ? tan.getZ(i) : 0.0;
        gT[4*i+3] = uv  ? uv.getY(i)  : 0.0;
        gS[4*i+0] = neutral ? neutral.getX(i) : 0.0;
    }
    return {
        gN: new Float32BufferAttribute(gN, 4),
        gT: new Float32BufferAttribute(gT, 4),
        gS: new Float32BufferAttribute(gS, 4),
        has_normals: !!nrm, has_tangents: !!tan, has_uvs: !!uv,
    };
}

// Merge the neutral (props) and openpbr (surface) geometries into a single
// non-indexed BufferGeometry for the MTLX route, tagging each vertex with a
// neutralFlag (1 = neutral/default material, 0 = openpbr). This lets one BVH
// cover both object sets so neutral objects render with the default material,
// without adding any texture samplers (flag rides in geomS.y).
function buildCombinedSurfaceGeometry(neutralGeom, surfaceGeom)
{
    const toNI = g => (g && g.index) ? g.toNonIndexed() : g;
    const A = neutralGeom ? toNI(neutralGeom) : null;   // neutral -> flag 1
    const B = toNI(surfaceGeom);                        // openpbr -> flag 0
    const countA = A ? A.attributes.position.count : 0;
    const countB = B.attributes.position.count;
    const N = countA + countB;
    const pos  = new Float32Array(N * 3);
    const nrm  = new Float32Array(N * 3);
    const tan  = new Float32Array(N * 4);
    const uv   = new Float32Array(N * 2);
    const neu  = new Float32Array(N);
    let hasN = false, hasT = false, hasU = false;
    const copy = (G, base, flag) => {
        if (!G) return;
        const p = G.attributes.position, n = G.attributes.normal, t = G.attributes.tangent,
              u = G.attributes.uv;
        if (n) hasN = true; if (t) hasT = true; if (u) hasU = true;
        for (let i = 0; i < p.count; i++) {
            const j = base + i;
            pos[j*3+0] = p.getX(i); pos[j*3+1] = p.getY(i); pos[j*3+2] = p.getZ(i);
            if (n) { nrm[j*3+0] = n.getX(i); nrm[j*3+1] = n.getY(i); nrm[j*3+2] = n.getZ(i); }
            if (t) { tan[j*4+0] = t.getX(i); tan[j*4+1] = t.getY(i); tan[j*4+2] = t.getZ(i); tan[j*4+3] = t.itemSize > 3 ? t.getW(i) : 1.0; }
            if (u) { uv[j*2+0] = u.getX(i); uv[j*2+1] = u.getY(i); }
            neu[j] = flag; // Keep the neutral flag
        }
    };
    copy(A, 0, 1.0);
    copy(B, countA, 0.0);
    const g = new BufferGeometry();
    g.setAttribute('position', new Float32BufferAttribute(pos, 3));
    if (hasN) g.setAttribute('normal', new Float32BufferAttribute(nrm, 3));
    if (hasT) g.setAttribute('tangent', new Float32BufferAttribute(tan, 4));
    if (hasU) g.setAttribute('uv', new Float32BufferAttribute(uv, 2));
    g.setAttribute('neutralFlag', new Float32BufferAttribute(neu, 1));
    return g;
}

function stripGlslMain(source)
{
    const match = source.match(/\bvoid\s+main\s*\(\s*\)\s*\{/);
    if (!match) return source;
    const start = match.index;
    const open = source.indexOf('{', start);
    const close = findMatchingBrace(source, open);
    if (close < 0) return source;
    return source.slice(0, start) + source.slice(close + 1);
}

function stripFunctionsByName(source, names)
{
    const nameSet = new Set(names);
    return removeFunctionBlocks(source, extractFunctionBlocks(source).filter(block => nameSet.has(block.name)));
}

function stripGeneratedBsdfEntrypoints(source)
{
    let result = source;
    const nameRe = /\bmtlx(?:Mat\d+_)?mtlxGen(?:Evaluate|Sample)Bsdf\s*\(/g;
    let match;
    const blocks = [];
    while ((match = nameRe.exec(result)) !== null) {
        const nameStart = match.index;
        const lineStart = result.lastIndexOf('\n', nameStart) + 1;
        const open = result.indexOf('{', match.index);
        if (open < 0) continue;
        const close = findMatchingBrace(result, open);
        if (close < 0) continue;
        blocks.push({ start: lineStart, end: close + 1 });
        nameRe.lastIndex = close + 1;
    }
    for (const block of blocks.sort((a, b) => b.start - a.start)) {
        result = result.slice(0, block.start) + result.slice(block.end);
    }
    return result;
}

function transformGeneratedMainToFunction(source, functionName)
{
    const match = source.match(/\bvoid\s+main\s*\(\s*\)\s*\{/);
    if (!match) return source;
    const start = match.index;
    const open = source.indexOf('{', start);
    const close = findMatchingBrace(source, open);
    if (close < 0) return source;
    const body = source.slice(open + 1, close);
    return source.slice(0, start) + `vec4 ${functionName}()\n{` + body + `\n    return mtlxRasterOut;\n}` + source.slice(close + 1);
}

function emitRasterGeneratedInputAssignments(prefix = '')
{
    const source = mtlxRouteDispatchGlsl;
    const target = name => `${prefix}${name}`;
    const lines = [];
    if (new RegExp(`\\b${escapeRegExp(target('texcoord_0'))}\\b`).test(source)) lines.push(`    ${target('texcoord_0')} = basis.texCoord;`);
    if (new RegExp(`\\b${escapeRegExp(target('normalWorld'))}\\b`).test(source)) lines.push(`    ${target('normalWorld')} = basis.nW;`);
    if (new RegExp(`\\b${escapeRegExp(target('tangentWorld'))}\\b`).test(source)) lines.push(`    ${target('tangentWorld')} = basis.tW;`);
    if (new RegExp(`\\b${escapeRegExp(target('bitangentWorld'))}\\b`).test(source)) lines.push(`    ${target('bitangentWorld')} = basis.bW;`);
    if (new RegExp(`\\b${escapeRegExp(target('positionWorld'))}\\b`).test(source)) lines.push(`    ${target('positionWorld')} = pW;`);
    if (new RegExp(`\\b${escapeRegExp(target('positionObject'))}\\b`).test(source)) lines.push(`    ${target('positionObject')} = pW;`);
    return lines.join('\n');
}

function summarizeMtlxRouteMaterialParams(p)
{
    const hasTransmission = p.transmissionWeight > 0;
    return {
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
}

function emitMtlxMaterialValueFunction(type, name, key, defaultValue)
{
    const value = mtlxRouteMaterialSummary[key] ?? defaultValue;
    if (type === 'vec3') {
        const v = Array.isArray(value) ? value : defaultValue;
        return `vec3 ${name}() { return vec3(${Number(v[0]).toFixed(8)}, ${Number(v[1]).toFixed(8)}, ${Number(v[2]).toFixed(8)}); }`;
    }
    return `${type} ${name}() { return ${type === 'bool' ? Boolean(value) : Number(value).toFixed(8)}; }`;
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
    if (!dispatch || (!is_mtlx_bvh_raster_route() && (!hasEval || !hasSample)))
    {
        substitutionRuntimeState.contractStatus = 'invalid';
        substitutionRuntimeState.contractValidationStep = 'mtlx-route-dispatch-assembly';
        substitutionRuntimeState.failureCause = 'missing_generated_dispatch';
        throw new Error('[mtlx-route] generated BSDF dispatch missing; refusing legacy fallback');
    }
    const bridge = is_mtlx_bvh_raster_route() ? `
void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed) {}
vec3 mtlx_openpbr_raster_color(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL) {
${emitRasterGeneratedInputAssignments('')}
    return mtlxRasterMain().rgb;
}
${emitMtlxMaterialValueFunction('bool', 'mtlx_openpbr_is_opaque', 'opaque', true)}
${emitMtlxMaterialValueFunction('bool', 'mtlx_openpbr_is_thinwalled', 'thinWalled', false)}
` : `
vec3 mtlx_openpbr_bsdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL, inout float pdf_woutputL) {
    return mtlxGenEvaluateBsdf(pW, basis, winputL, woutputL, MATERIAL_OPENPBR, pdf_woutputL);
}
vec3 mtlx_openpbr_bsdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed, out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium) {
    return mtlxGenSampleBsdf(pW, basis, winputL, rndSeed, MATERIAL_OPENPBR, woutputL, pdf_woutputL, internal_medium);
}
void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed) {}
vec3 mtlx_openpbr_raster_color(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL) {
    g_ptP = pW;
    g_ptN = basis.nW;
    g_ptTangent = basis.tW;
    g_ptBitangent = basis.bW;
    g_ptTexcoord = basis.texCoord;
    g_ptV = localToWorld(winputL, basis);
    g_ptL = localToWorld(woutputL, basis);
    g_ptOcclusion = 1.0;
    g_ptEmitEmission = 1;
    g_ptClosureType = CLOSURE_TYPE_INDIRECT;
    return mtlxHostEvalSurface().color;
}
// Spatial emission: evaluate the generated surface with the EMISSION closure so only
// the (possibly graph-driven) emission term contributes -> per-hit emissive bands.
vec3 mtlx_openpbr_emission_at(in vec3 pW, in Basis basis) {
    g_ptP = pW;
    g_ptN = basis.nW;
    g_ptTangent = basis.tW;
    g_ptBitangent = basis.bW;
    g_ptTexcoord = basis.texCoord;
    g_ptV = basis.nW;
    g_ptL = basis.nW;
    g_ptOcclusion = 1.0;
    g_ptEmitEmission = 1;
    g_ptClosureType = CLOSURE_TYPE_EMISSION;
    return mtlxHostEvalSurface().color;
}
${emitMtlxMaterialValueFunction('bool', 'mtlx_openpbr_is_opaque', 'opaque', true)}
${emitMtlxMaterialValueFunction('bool', 'mtlx_openpbr_is_thinwalled', 'thinWalled', false)}
${emitMtlxMaterialValueFunction('vec3', 'mtlx_openpbr_emission', 'emission', [0, 0, 0])}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_thin_film_weight', 'thinFilmWeight', 0)}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_thin_film_thickness_nm', 'thinFilmThicknessNm', 0)}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_thin_film_ior', 'thinFilmIor', 1.5)}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_specular_ior', 'specularIor', 1.5)}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_specular_roughness', 'specularRoughness', 0.3)}
${emitMtlxMaterialValueFunction('float', 'mtlx_openpbr_transmission_weight', 'transmissionWeight', 0)}
`;
    const dispatchBody = is_mtlx_bvh_raster_route()
        ? stripGeneratedBsdfEntrypoints(mtlxRouteDispatchGlsl)
        : mtlxRouteDispatchGlsl;
    const routeBody = is_mtlx_bvh_raster_route()
        ? glsl_rasterization_mtlx_rasterizer
        : glsl_mtlx_route_pathtracer;
    if (typeof window !== 'undefined') window.__openpbrMtlxDispatch = mtlxRouteDispatchGlsl;
    return dispatchBody + bridge + routeBody;
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
// Bump on every republish of the public/mtlx bundle so clients never mix a cached
// .js offset table with a differently-versioned .data payload.
const MTLX_RUNTIME_VERSION = '2026-08-31';
let _mtlxModulePromise = null;
async function loadMtlxModule() {
    if (_mtlxModulePromise) return _mtlxModulePromise;
    // Construct full http:// URL at runtime so Vite's static analyzer
    // does not intercept the import as a /public/ module (which it rejects).
    // BASE_URL = '/OpenPBR-viewer/' — public files are served under the base in Vite 5.
    const origin = window.location.origin;
    const base   = APP_BASE_URL; // e.g. '/OpenPBR-viewer/'
    // Version tag so .js (byte-offset table), .data (bytes) and .wasm are always
    // fetched as a matched set. A stale cached .js against a fresh .data mis-slices
    // the embedded libraries and yields XML "Start-end tags mismatch" parse errors.
    const v = `?v=${MTLX_RUNTIME_VERSION}`;
    const jsUrl  = origin + base + 'mtlx/JsMaterialXGenShader.js' + v;
    _mtlxModulePromise = import(/* @vite-ignore */ jsUrl)
        .then(mod => mod.default({
            locateFile: p => origin + base + 'mtlx/' + p + v
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
    glsl = glsl.replace(/^[ \t]*sampler2D[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*;[ \t]*\r?\n/gm, 'uniform sampler2D $1;\n');
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

async function generateMtlxRasterDispatch(mtlxText) {
    const mx = await loadMtlxModule();
    if (typeof mx.EsslHostShaderGenerator === 'undefined') {
        throw new Error('[mtlx-raster] EsslHostShaderGenerator not exposed by WASM build');
    }
    const gen = mx.EsslHostShaderGenerator.create();
    const ctx = new mx.GenContext(gen);
    const stdlib = mx.loadStandardLibraries(ctx);
    const doc = mx.createDocument();
    doc.importLibrary(stdlib);
    await mx.readFromXmlString(doc, mtlxText, '');
    const elem = mx.findRenderableElement(doc);
    if (!elem) throw new Error('[mtlx-raster] No renderable element found in .mtlx');
    const shader = gen.generate(elem.getNamePath(), elem, ctx);
    let glsl = shader.getSourceCode('pixel');

    glsl = glsl
        .replace(/^[ \t]*#version[^\n]*\n/gm, '')
        .replace(/^[ \t]*precision[^\n]*\n/gm, '')
        .replace(/^[ \t]*#define[ \t]+material[ \t]+surfaceshader[ \t]*\r?\n/gm, '');
    glsl = glsl
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envIrradiance[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envLightIntensity[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envMatrix[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceMips[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+\w+[ \t]+u_envRadianceSamples[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+bool[ \t]+u_refractionTwoSided[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+vec3[ \t]+u_viewPosition[ \t]*;[ \t]*\r?\n/gm, '')
        .replace(/^[ \t]*uniform[ \t]+int[ \t]+u_numActiveLightSources[ \t]*;[ \t]*\r?\n/gm, '');
    glsl = glsl.replace(/^[ \t]*sampler2D[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*;[ \t]*\r?\n/gm, 'uniform sampler2D $1;\n');
    glsl = glsl.replace(/^[ \t]*in[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*;[ \t]*\r?\n/gm, '$1 $2;\n');
    glsl = glsl.replace(/^[ \t]*out[ \t]+vec4[ \t]+out1[ \t]*;[ \t]*\r?\n/gm, 'vec4 mtlxRasterOut;\n');
    glsl = glsl.replace(/\bout1\b/g, 'mtlxRasterOut');
    glsl = transformGeneratedMainToFunction(glsl, 'mtlxRasterMain');
    const envPreamble =
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
        '#define u_refractionTwoSided false\n' +
        '#define u_numActiveLightSources mtlxLightCount\n' +
        '#define u_viewPosition cameraWorldMatrix[3].xyz\n';
    glsl = envPreamble + glsl;

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
        transmissionDepth:    extractParam('transmission_depth', 0),
        dispersionScale:      extractParam('transmission_dispersion_scale', 0),
        thinFilmWeight:       extractParam('thin_film_weight', 0),
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
    glsl = glsl.replace(/^[ \t]*sampler2D[ \t]+([A-Za-z_][A-Za-z0-9_]*)[ \t]*;[ \t]*\r?\n/gm, 'uniform sampler2D $1;\n');
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
    glsl = glsl.replace(/(g_ptBitangent[ \t]*=[ \t]*basis\.bW;\r?\n)/g, '$1    g_ptTexcoord = basis.texCoord;\n');

    // Floor folded roughness literals: a perfectly smooth metal/specular (roughness 0)
    // makes the host GGX BSDF near-delta, which is unsampleable against IBL in the
    // pathtracer -> black/high-variance. A small minimum keeps it clean and metallic.
    glsl = glsl.replace(/\b(specular_roughness|coat_roughness)(\s*=\s*)([0-9]*\.?[0-9]+)(\s*;)/g,
        (m, name, eq, num, semi) => `${name}${eq}${Math.max(parseFloat(num), 0.02).toFixed(6)}${semi}`);

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

async function loadMtlxMaterialLibrary()
{
    try {
        const resp = await fetch(APP_BASE_URL + 'mtlx-library.json');
        if (!resp.ok) {
            console.warn('[mtlx-library] manifest fetch failed:', resp.status);
            mtlxMaterialLibrary = [];
            return;
        }
        const payload = await resp.json();
        mtlxMaterialDirectories = Array.isArray(payload?.directories) ? payload.directories : [];
        mtlxMaterialLibrary = mtlxMaterialDirectories.flatMap(directory =>
            (Array.isArray(directory.materials) ? directory.materials : []).map(material => ({
                ...material,
                directory: directory.name,
                directoryPath: directory.path
            }))
        );
        if (mtlxMaterialDirectories.length === 0 && Array.isArray(payload?.materials)) {
            mtlxMaterialLibrary = payload.materials;
        }
        console.log('[mtlx-library] loaded', mtlxMaterialLibrary.length, 'materials');
    } catch (e) {
        console.warn('[mtlx-library] manifest fetch error:', e?.message || e);
        mtlxMaterialLibrary = [];
    }
}

function getMtlxDirectoryOptions()
{
    const options = {};
    for (const directory of mtlxMaterialDirectories) {
        options[directory.name || directory.path] = directory.path;
    }
    return options;
}

function getMtlxMaterialOptions(directoryPath)
{
    const options = { 'Select material': '' };
    const directory = mtlxMaterialDirectories.find(item => item.path === directoryPath);
    for (const material of directory?.materials || []) {
        options[material.name || material.file] = material.url;
    }
    return options;
}

let mtlxPickerElements = null;
let loadedMtlxArchiveBundle = null;

function ensureMtlxPicker()
{
    if (mtlxPickerElements) return mtlxPickerElements;

    const style = document.createElement('style');
    style.textContent = `
        .mtlx-picker {
            position: fixed;
            inset: 0;
            z-index: 11000;
            display: none;
            flex-direction: column;
            background: #101315;
            color: #e7ecec;
            font: 14px/1.35 monospace;
        }
        .mtlx-picker.is-open { display: flex; }
        .mtlx-picker__header {
            display: flex;
            align-items: center;
            gap: 12px;
            min-height: 52px;
            padding: 8px 14px;
            background: #182022;
            border-bottom: 1px solid #334044;
        }
        .mtlx-picker__title { flex: 1; font-weight: 700; }
        .mtlx-picker__close,
        .mtlx-picker__back {
            min-width: 42px;
            min-height: 38px;
            border: 1px solid #526267;
            border-radius: 4px;
            background: #273237;
            color: inherit;
            font: inherit;
            cursor: pointer;
        }
        .mtlx-picker__back { display: none; }
        .mtlx-picker__archive {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 7px 10px;
            padding: 12px 14px;
            border-bottom: 1px solid #334044;
        }
        .mtlx-picker__archive-label,
        .mtlx-picker__archive-status,
        .mtlx-picker__archive-list { grid-column: 1 / -1; }
        .mtlx-picker__archive-label { color: #a9b9bc; }
        .mtlx-picker__archive-url {
            box-sizing: border-box;
            width: 100%;
            min-width: 0;
            padding: 10px;
            border: 1px solid #526267;
            border-radius: 4px;
            background: #0b0e0f;
            color: inherit;
            font: inherit;
        }
        .mtlx-picker__archive-load {
            min-width: 110px;
            border: 1px solid #6caab5;
            border-radius: 4px;
            background: #28606a;
            color: inherit;
            font: inherit;
            cursor: pointer;
        }
        .mtlx-picker__archive-load:disabled { opacity: 0.6; cursor: wait; }
        .mtlx-picker__archive-status { min-height: 1.35em; color: #a9b9bc; }
        .mtlx-picker__archive-status[data-state="error"] { color: #ff9d91; }
        .mtlx-picker__archive-list { display: flex; flex-wrap: wrap; gap: 5px; }
        .mtlx-picker__body {
            display: grid;
            grid-template-columns: minmax(240px, 0.85fr) minmax(280px, 1.15fr);
            min-height: 0;
            flex: 1;
        }
        .mtlx-picker__pane {
            display: flex;
            flex-direction: column;
            min-width: 0;
            padding: 12px;
        }
        .mtlx-picker__pane + .mtlx-picker__pane { border-left: 1px solid #334044; }
        .mtlx-picker__label { margin-bottom: 7px; color: #a9b9bc; }
        .mtlx-picker__search {
            width: 100%;
            box-sizing: border-box;
            margin-bottom: 10px;
            padding: 10px;
            border: 1px solid #526267;
            border-radius: 4px;
            background: #0b0e0f;
            color: inherit;
            font: inherit;
        }
        .mtlx-picker__list {
            display: flex;
            flex-direction: column;
            gap: 5px;
            min-height: 0;
            overflow: auto;
            overscroll-behavior: contain;
        }
        .mtlx-picker__item {
            width: 100%;
            padding: 10px;
            border: 1px solid #334044;
            border-radius: 4px;
            background: #1a2225;
            color: inherit;
            text-align: left;
            font: inherit;
            cursor: pointer;
        }
        .mtlx-picker__item:hover,
        .mtlx-picker__item.is-selected { background: #29434a; border-color: #6caab5; }
        .mtlx-picker__empty { padding: 10px 2px; color: #87979a; }
        @media (max-width: 600px) {
            .mtlx-picker__body { display: block; }
            .mtlx-picker__pane { height: 100%; box-sizing: border-box; }
            .mtlx-picker__pane + .mtlx-picker__pane { display: none; border-left: 0; }
            .mtlx-picker.is-materials .mtlx-picker__pane--directories { display: none; }
            .mtlx-picker.is-materials .mtlx-picker__pane--materials { display: flex; }
            .mtlx-picker.is-materials .mtlx-picker__back { display: block; }
        }
    `;
    document.head.appendChild(style);

    const picker = document.createElement('section');
    picker.className = 'mtlx-picker';
    picker.setAttribute('aria-label', 'MaterialX library');
    picker.innerHTML = `
        <header class="mtlx-picker__header">
            <button class="mtlx-picker__back" type="button" aria-label="Back">&lt;</button>
            <div class="mtlx-picker__title">MaterialX library</div>
            <button class="mtlx-picker__close" type="button" aria-label="Close">X</button>
        </header>
        <section class="mtlx-picker__archive">
            <label class="mtlx-picker__archive-label" for="mtlx-picker-archive-url">AmbientCG ZIP URL</label>
            <input class="mtlx-picker__archive-url" id="mtlx-picker-archive-url" type="url" placeholder="https://ambientcg.com/get?file=Ground112_1K-JPG.zip">
            <button class="mtlx-picker__archive-load" type="button">Load ZIP</button>
            <div class="mtlx-picker__archive-status" role="status" aria-live="polite"></div>
            <div class="mtlx-picker__archive-list"></div>
        </section>
        <div class="mtlx-picker__body">
            <section class="mtlx-picker__pane mtlx-picker__pane--directories">
                <div class="mtlx-picker__label">Directory</div>
                <input class="mtlx-picker__search mtlx-picker__directory-search" type="search" placeholder="Filter directories">
                <div class="mtlx-picker__list mtlx-picker__directory-list"></div>
            </section>
            <section class="mtlx-picker__pane mtlx-picker__pane--materials">
                <div class="mtlx-picker__label mtlx-picker__material-label">Material</div>
                <input class="mtlx-picker__search mtlx-picker__material-search" type="search" placeholder="Filter materials">
                <div class="mtlx-picker__list mtlx-picker__material-list"></div>
            </section>
        </div>
    `;
    document.body.appendChild(picker);

    const elements = {
        picker,
        directorySearch: picker.querySelector('.mtlx-picker__directory-search'),
        directoryList: picker.querySelector('.mtlx-picker__directory-list'),
        materialSearch: picker.querySelector('.mtlx-picker__material-search'),
        materialList: picker.querySelector('.mtlx-picker__material-list'),
        materialLabel: picker.querySelector('.mtlx-picker__material-label'),
        archiveUrl: picker.querySelector('.mtlx-picker__archive-url'),
        archiveLoad: picker.querySelector('.mtlx-picker__archive-load'),
        archiveStatus: picker.querySelector('.mtlx-picker__archive-status'),
        archiveList: picker.querySelector('.mtlx-picker__archive-list'),
    };
    picker.querySelector('.mtlx-picker__close').addEventListener('click', () => picker.classList.remove('is-open'));
    picker.querySelector('.mtlx-picker__back').addEventListener('click', () => picker.classList.remove('is-materials'));
    elements.directorySearch.addEventListener('input', () => renderMtlxPickerDirectories(elements));
    elements.materialSearch.addEventListener('input', () => renderMtlxPickerMaterials(elements));
    elements.archiveLoad.addEventListener('click', () => loadAmbientCgArchive(elements));
    elements.archiveUrl.addEventListener('keydown', event => {
        if (event.key === 'Enter') loadAmbientCgArchive(elements);
    });
    mtlxPickerElements = elements;
    return elements;
}

function setMtlxArchiveStatus(elements, message, state = '')
{
    elements.archiveStatus.textContent = message;
    elements.archiveStatus.dataset.state = state;
}

async function loadAmbientCgArchive(elements)
{
    const url = elements.archiveUrl.value.trim();
    if (!url) {
        setMtlxArchiveStatus(elements, 'Enter an AmbientCG ZIP URL.', 'error');
        return;
    }

    elements.archiveLoad.disabled = true;
    elements.archiveList.replaceChildren();
    setMtlxArchiveStatus(elements, 'Downloading and inspecting ZIP...');
    try {
        const archive = await loadMtlxArchive(url, ambientCgArchiveEndpoint);
        loadedMtlxArchiveBundle = archive;
        const label = archive.materials.length === 1
            ? 'MaterialX file found:'
            : `${archive.materials.length} MaterialX files found:`;
        setMtlxArchiveStatus(elements, label);

        for (const material of archive.materials) {
            const button = document.createElement('button');
            button.className = 'mtlx-picker__item';
            button.type = 'button';
            button.textContent = material.path;
            button.addEventListener('click', async () => {
                try {
                    await applyMtlxArchiveMaterial(archive, material, elements);
                } catch (error) {
                    setMtlxArchiveStatus(elements, error.message || String(error), 'error');
                }
            });
            elements.archiveList.appendChild(button);
        }
        if (archive.materials.length === 1)
            await applyMtlxArchiveMaterial(archive, archive.materials[0], elements);
    } catch (error) {
        setMtlxArchiveStatus(elements, error.message || String(error), 'error');
    } finally {
        elements.archiveLoad.disabled = false;
    }
}

async function applyMtlxArchiveMaterial(archive, material, elements)
{
    const archiveSource = await archive.selectMaterial(material.path);
    const previousArchiveSource = activeMtlxArchiveSource;
    elements.archiveLoad.disabled = true;
    setMtlxArchiveStatus(elements, `Loading ${material.name}...`);
    try {
        params.mtlx_material = '';
        params.renderer_mode = 'Rasterizer MTLX';
        setPaused(true);
        await configureSingleMtlxMaterial('', material.name, archiveSource.mtlxText, archiveSource);
        activeMtlxArchiveSource = archiveSource;
        retireMtlxArchiveSource(previousArchiveSource);
        load_scene(params.scene_name);
        elements.picker.classList.remove('is-open', 'is-materials');
        setMtlxArchiveStatus(elements, `Loaded ${material.name}.`);
    } catch (error) {
        retireMtlxArchiveSource(archiveSource);
        throw error;
    } finally {
        elements.archiveLoad.disabled = false;
    }
}

function renderMtlxPickerDirectories(elements)
{
    const query = elements.directorySearch.value.trim().toLowerCase();
    elements.directoryList.replaceChildren();
    const directories = mtlxMaterialDirectories.filter(directory =>
        (directory.path || directory.name || '').toLowerCase().includes(query)
    );
    if (directories.length === 0) {
        elements.directoryList.innerHTML = '<div class="mtlx-picker__empty">No directory found</div>';
        return;
    }
    for (const directory of directories) {
        const button = document.createElement('button');
        button.className = 'mtlx-picker__item';
        button.type = 'button';
        button.textContent = `${directory.path} (${directory.materials?.length || 0})`;
        button.addEventListener('click', () => {
            params.mtlx_directory = directory.path;
            elements.materialLabel.textContent = directory.path;
            elements.materialSearch.value = '';
            renderMtlxPickerMaterials(elements);
            elements.picker.classList.add('is-materials');
        });
        elements.directoryList.appendChild(button);
    }
}

function renderMtlxPickerMaterials(elements)
{
    const directory = mtlxMaterialDirectories.find(item => item.path === params.mtlx_directory);
    const query = elements.materialSearch.value.trim().toLowerCase();
    elements.materialList.replaceChildren();
    const materials = (directory?.materials || []).filter(material =>
        `${material.name} ${material.file}`.toLowerCase().includes(query)
    );
    if (materials.length === 0) {
        elements.materialList.innerHTML = '<div class="mtlx-picker__empty">No material found</div>';
        return;
    }
    for (const material of materials) {
        const button = document.createElement('button');
        button.className = 'mtlx-picker__item';
        button.type = 'button';
        button.textContent = material.name || material.file;
        button.addEventListener('click', async () => {
            elements.picker.classList.remove('is-open', 'is-materials');
            await applyMtlxMaterialFromLibrary(material.url);
        });
        elements.materialList.appendChild(button);
    }
}

function getGeneratedMtlxMaterials()
{
    try {
        const materials = JSON.parse(localStorage.getItem(generatedMtlxStorageKey) || '[]');
        return Array.isArray(materials) ? materials : [];
    } catch {
        return [];
    }
}

function setGeneratedMtlxMaterials(materials)
{
    localStorage.setItem(generatedMtlxStorageKey, JSON.stringify(materials));
}

function validateGeneratedMtlx(mtlxText)
{
    const document = new DOMParser().parseFromString(mtlxText, 'application/xml');
    const parserError = document.querySelector('parsererror');
    const root = document.documentElement;
    if (parserError || !root || root.nodeName !== 'materialx') {
        throw new Error('The Copilot response is not valid MaterialX XML.');
    }
    if (!document.querySelector('surfacematerial, material')) {
        throw new Error('The generated MaterialX document has no material element.');
    }
}

function extractCopilotMtlxText(payload)
{
    if (typeof payload === 'string') return payload;
    const text = payload?.mtlx || payload?.xml || payload?.content || payload?.message;
    if (typeof text !== 'string') throw new Error('The Copilot endpoint did not return MTLX text.');
    return text.replace(/^```xml\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
}

async function generateMtlxWithCopilot(prompt)
{
    /*
    const response = await fetch(copilotMtlxEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            prompt,
            format: 'materialx-1.39',
            instruction: 'Return only a complete MaterialX 1.39 XML document with a surfacematerial and no Markdown fences.'
        })
    });
    if (!response.ok) throw new Error(`Copilot endpoint failed: ${response.status}`);
    const responseText = await response.text();
    let payload = responseText;
    try { payload = JSON.parse(responseText); } catch {}
    const mtlxText = extractCopilotMtlxText(payload);
    */
    const mtlxText = prompt;
    validateGeneratedMtlx(mtlxText);
    return mtlxText;
}

async function applyGeneratedMtlx(mtlxText, materialName)
{
    const previousArchiveSource = activeMtlxArchiveSource;
    params.mtlx_material = '';
    params.renderer_mode = 'Rasterizer MTLX';
    setPaused(true);
    await configureSingleMtlxMaterial('', materialName || 'copilot-generated', mtlxText);
    activeMtlxArchiveSource = null;
    retireMtlxArchiveSource(previousArchiveSource);
    load_scene(params.scene_name);
}

function openMtlxCopilotDialog()
{
    ensureMtlxCopilotDialog();
    const dialog = document.getElementById('mtlx-copilot-dialog');
    if (!dialog) return;
    dialog.showModal();
    dialog.querySelector('[data-copilot-prompt]').focus();
    renderGeneratedMtlxList(dialog);
}

function renderGeneratedMtlxList(dialog)
{
    const list = dialog.querySelector('[data-generated-mtlx-list]');
    list.replaceChildren();
    for (const material of getGeneratedMtlxMaterials()) {
        const button = document.createElement('button');
        button.type = 'button';
        button.textContent = material.name;
        button.addEventListener('click', async () => {
            try {
                await applyGeneratedMtlx(material.mtlx, material.name);
                dialog.close();
            } catch (error) {
                dialog.querySelector('[data-copilot-status]').textContent = error.message;
            }
        });
        list.appendChild(button);
    }
}

function ensureMtlxCopilotDialog()
{
    if (document.getElementById('mtlx-copilot-dialog')) return;
    const style = document.createElement('style');
    style.textContent = `
        #mtlx-copilot-dialog { width: min(680px, calc(100vw - 28px)); max-height: calc(100dvh - 28px); padding: 0; border: 1px solid #526267; border-radius: 6px; background: #101315; color: #e7ecec; font: 14px/1.4 monospace; }
        #mtlx-copilot-dialog::backdrop { background: rgba(0, 0, 0, .7); }
        .mtlx-copilot__header, .mtlx-copilot__footer { display: flex; align-items: center; gap: 10px; padding: 12px 14px; background: #182022; }
        .mtlx-copilot__header { border-bottom: 1px solid #334044; }
        .mtlx-copilot__footer { border-top: 1px solid #334044; justify-content: flex-end; }
        .mtlx-copilot__title { flex: 1; font-weight: 700; }
        .mtlx-copilot__body { display: grid; gap: 10px; padding: 14px; overflow: auto; }
        .mtlx-copilot__body label { display: grid; gap: 6px; color: #a9b9bc; }
        .mtlx-copilot__body input, .mtlx-copilot__body textarea { box-sizing: border-box; width: 100%; padding: 10px; border: 1px solid #526267; border-radius: 4px; background: #0b0e0f; color: #e7ecec; font: inherit; }
        .mtlx-copilot__body textarea { min-height: 130px; resize: vertical; }
        .mtlx-copilot__button { padding: 9px 12px; border: 1px solid #526267; border-radius: 4px; background: #273237; color: inherit; font: inherit; cursor: pointer; }
        .mtlx-copilot__button--primary { background: #28606a; border-color: #6caab5; }
        .mtlx-copilot__status { min-height: 1.4em; color: #e5bd69; white-space: pre-wrap; }
        .mtlx-copilot__saved { display: flex; flex-wrap: wrap; gap: 6px; }
    `;
    document.head.appendChild(style);
    const dialog = document.createElement('dialog');
    dialog.id = 'mtlx-copilot-dialog';
    dialog.innerHTML = `
        <header class="mtlx-copilot__header"><div class="mtlx-copilot__title">Generate MaterialX with GitHub Copilot</div><button class="mtlx-copilot__button" type="button" data-copilot-close>Close</button></header>
        <form class="mtlx-copilot__body" method="dialog">
            <label>Name for this material <input data-copilot-name required maxlength="80" placeholder="e.g. translucent blue ceramic"></label>
            <label>Material description <textarea data-copilot-prompt required placeholder="Describe color, roughness, metallic, coat, transmission, thin film, textures..."></textarea></label>
            <div class="mtlx-copilot__status" data-copilot-status></div>
            <div><div>Saved generated materials</div><div class="mtlx-copilot__saved" data-generated-mtlx-list></div></div>
        </form>
        <footer class="mtlx-copilot__footer"><button class="mtlx-copilot__button" type="button" data-copilot-cancel>Cancel</button><button class="mtlx-copilot__button mtlx-copilot__button--primary" type="button" data-copilot-generate>Generate and render</button></footer>
    `;
    document.body.appendChild(dialog);
    dialog.querySelector('[data-copilot-close]').addEventListener('click', () => dialog.close());
    dialog.querySelector('[data-copilot-cancel]').addEventListener('click', () => dialog.close());
    dialog.querySelector('[data-copilot-generate]').addEventListener('click', async () => {
        const name = dialog.querySelector('[data-copilot-name]').value.trim();
        const prompt = dialog.querySelector('[data-copilot-prompt]').value.trim();
        const status = dialog.querySelector('[data-copilot-status]');
        if (!name || !prompt) return;
        status.textContent = 'Generating and compiling...';
        try {
            const mtlxText = await generateMtlxWithCopilot(prompt);
            const materials = getGeneratedMtlxMaterials().filter(item => item.name !== name);
            materials.unshift({ name, mtlx: mtlxText, savedAt: new Date().toISOString() });
            setGeneratedMtlxMaterials(materials);
            await applyGeneratedMtlx(mtlxText, name);
            status.textContent = 'Rendered successfully.';
            renderGeneratedMtlxList(dialog);
        } catch (error) {
            status.textContent = error.message || String(error);
        }
    });
}

function openMtlxPicker()
{
    const elements = ensureMtlxPicker();
    elements.picker.classList.add('is-open');
    elements.picker.classList.remove('is-materials');
    elements.directorySearch.value = '';
    renderMtlxPickerDirectories(elements);
    elements.directorySearch.focus();
}

function showMtlxLibraryError(error)
{
    const message = `[mtlx-library] ${error?.message || error}`;
    console.error(message, error);
    window.__openpbrShaderError = message;
    window.__openpbrReady = true;
    const overlay = document.getElementById('shader-error');
    const content = document.getElementById('shader-error-content');
    if (overlay && content) {
        content.textContent = message;
        overlay.style.display = 'block';
    }
}

async function configureSingleMtlxMaterial(mtlxUrl, materialId, inlineMtlxText = null, archiveSource = null)
{
    let mtlxText = inlineMtlxText || DEFAULT_MTLX;
    let mtlxMaterialBaseUrl = getPublicAssetUrl('');
    if (mtlxUrl && !inlineMtlxText) {
        const resolvedUrl = resolveViewerAssetUrl(mtlxUrl);
        mtlxMaterialBaseUrl = new URL(resolvedUrl, window.location.origin).toString().replace(/[^/]*$/, '');
        const resp = await fetch(resolvedUrl);
        if (!resp.ok) throw new Error(`material fetch failed: ${resp.status} ${resolvedUrl}`);
        mtlxText = await resp.text();
    }

    const result = is_mtlx_bvh_raster_route()
        ? await generateMtlxRasterDispatch(mtlxText)
        : await generateMtlxRouteDispatch(mtlxText);
    const summary = summarizeMtlxRouteMaterialParams(result.mtlxParams);
    const hasTransmission = result.mtlxParams.transmissionWeight > 0;

    mtlxRouteTextureBindings = extractMtlxTextureBindings(mtlxText, mtlxMaterialBaseUrl, archiveSource);
    if (archiveSource) {
        archiveSource.textureLoadsPending = mtlxRouteTextureBindings.length;
        archiveSource.retired = false;
    }
    mtlxArchiveDisplacement = await loadMtlxDisplacement(mtlxText, archiveSource);
    mtlxRouteLights = extractMtlxLights(mtlxText);
    mtlxRouteMaterialSummary = summary;
    const parameterBinding = bindMtlxParametersToTexture(result.glsl, mtlxText);
    mtlxRouteParamDescriptors = parameterBinding.parameters;
    mtlxRouteDispatchGlsl = parameterBinding.glsl;

    materialDefines.MAX_MTLX_LIGHTS = Math.max(1, mtlxRouteLights.length);
    materialDefines.VOLUME_ENABLED = hasTransmission && result.mtlxParams.transmissionDepth > 0 && !result.mtlxParams.geometry_thin_walled;
    materialDefines.TRANSMISSION_ENABLED = hasTransmission && result.mtlxParams.dispersionScale > 0;
    materialDefines.THIN_FILM_ENABLED = result.mtlxParams.thinFilmWeight > 0;
    substitutionRuntimeState.contractStatus = 'valid';
    substitutionRuntimeState.contractValidationStep = 'mtlx-library-material-generation';
    substitutionRuntimeState.failureCause = '';

    if (mtlxRouteTextureBindings.length > 0) {
        console.log('[mtlx-library] textures', mtlxRouteTextureBindings.map(t => `${t.sampler}=${t.source}`).join(', '));
    }
    console.log('[mtlx-library] applied', materialId || 'default-material', '| dispatch lines:', mtlxRouteDispatchGlsl.split('\n').length);
}

async function applyMtlxMaterialFromLibrary(value)
{
    try {
        const previousArchiveSource = activeMtlxArchiveSource;
        const material = mtlxMaterialLibrary.find(item => item.url === value || item.file === value || item.name === value);
        const url = material?.url || value || '';
        const materialId = material?.name || 'default-material';
        params.mtlx_material = url;
        params.renderer_mode = 'Pathtracer MTLX';
        setPaused(true);
        await configureSingleMtlxMaterial(url, materialId);
        activeMtlxArchiveSource = null;
        retireMtlxArchiveSource(previousArchiveSource);
        load_scene(params.scene_name);
    } catch (e) {
        showMtlxLibraryError(e);
    }
}

// Regenerate the MTLX route dispatch GLSL for the current renderer route. The
// dispatch is generated at startup only for the startup route (default
// 'Rasterizer'), so switching into an MTLX route at runtime would otherwise find
// mtlxRouteDispatchGlsl empty and assemble_mtlx_route_dispatch() would throw.
async function ensureMtlxRouteDispatch()
{
    if (!uses_mtlx_fullscreen_shader()) return;

    if (activeMtlxArchiveSource) {
        const source = activeMtlxArchiveSource;
        await configureSingleMtlxMaterial('', source.materialId, source.mtlxText, source);
        return;
    }

    const material = mtlxMaterialLibrary.find(item => item.url === params.mtlx_material || item.name === params.mtlx_material);
    const materialId = material?.name || 'default-material';
    await configureSingleMtlxMaterial(params.mtlx_material || '', materialId);
}

var mesh_loader;
var renderer, camera, orbitControls, scene, gui;//, stats;
var pathtracedQuad, pathtracedFinalQuad, pathtracingRenderTarget;
var pathtracedMaterial = null;
var pathtracedMaterial_legacy = null;
var openpbrMaterial = null;
var neutralMaterial = null;
var directionalLight, ambientLight;
var camera_initialized = false;
var env_map_texture = null;
var env_irradiance_texture = null;
var env_map_latlong_texture = null;
var env_irradiance_latlong_texture = null;
var env_map_importance = null; // { equirectTexture, cdfTexture, totalSum, width, height } | null
var sceneGroundY = 0.01;

var MESH_SURFACE;
var MESH_PROPS;
var BVH_SURFACE;
var BVH_PROPS;

var progress_bar;
var progress_finished_timer;

var LOADED;
var COMPILING;
var FULLSCREEN_BVH_ROUTE;
var samples = 0;
const PATH_TRACER_TILE_SIZE = 64;
const PATH_TRACER_INTERACTIVE_SCALE = 0.25;
const PATH_TRACER_CAMERA_SETTLE_MS = 200;
let pathtracerTileIndex = 0;
let pathtracerInteractivePreview = false;
let pathtracerCameraIdleTimer = null;
var pauseController = null;

function installWebGLDiagnostics(gl)
{
    const contextLossStorageKey = 'openpbr-last-context-loss';
    const canvas = renderer.domElement;
    const debugRendererInfo = gl.getExtension('WEBGL_debug_renderer_info');
    const robustness = gl.getExtension('WEBGL_robustness');

    const getParameter = (parameter) => {
        try { return parameter === undefined ? null : gl.getParameter(parameter); }
        catch { return null; }
    };
    const getResetStatus = () => {
        if (!robustness?.getGraphicsResetStatus) return 'unavailable';
        const status = robustness.getGraphicsResetStatus();
        if (status === gl.NO_ERROR) return 'NO_ERROR';
        if (status === robustness.GUILTY_CONTEXT_RESET_WEBGL) return 'GUILTY_CONTEXT_RESET_WEBGL';
        if (status === robustness.INNOCENT_CONTEXT_RESET_WEBGL) return 'INNOCENT_CONTEXT_RESET_WEBGL';
        if (status === robustness.UNKNOWN_CONTEXT_RESET_WEBGL) return 'UNKNOWN_CONTEXT_RESET_WEBGL';
        return `0x${status.toString(16)}`;
    };
    const createReport = () => ({
        timestamp: new Date().toISOString(),
        stage: gpuDebugStage.name,
        stageDurationMs: Math.round(performance.now() - gpuDebugStage.since),
        resetStatus: getResetStatus(),
        contextLost: gl.isContextLost(),
        renderer: debugRendererInfo
            ? getParameter(debugRendererInfo.UNMASKED_RENDERER_WEBGL)
            : getParameter(gl.RENDERER),
        vendor: debugRendererInfo
            ? getParameter(debugRendererInfo.UNMASKED_VENDOR_WEBGL)
            : getParameter(gl.VENDOR),
        version: getParameter(gl.VERSION),
        limits: {
            maxTextureSize: getParameter(gl.MAX_TEXTURE_SIZE),
            maxCubeMapTextureSize: getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE),
            maxRenderbufferSize: getParameter(gl.MAX_RENDERBUFFER_SIZE),
            maxTextureImageUnits: getParameter(gl.MAX_TEXTURE_IMAGE_UNITS),
            maxCombinedTextureImageUnits: getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
        },
        canvas: {
            width: canvas.width,
            height: canvas.height,
            cssWidth: canvas.clientWidth,
            cssHeight: canvas.clientHeight,
            devicePixelRatio: window.devicePixelRatio
        },
        three: {
            geometries: renderer.info.memory.geometries,
            textures: renderer.info.memory.textures,
            programs: renderer.info.programs?.length ?? null,
            calls: renderer.info.render.calls,
            triangles: renderer.info.render.triangles
        },
        app: {
            scene: params.scene_name,
            rendererMode: params.renderer_mode,
            bvhEngine: 'threejs',
            renderSize: params.render_size,
            loaded: LOADED,
            compiling: COMPILING
        },
        device: {
            userAgent: navigator.userAgent,
            deviceMemoryGiB: navigator.deviceMemory ?? null,
            hardwareConcurrency: navigator.hardwareConcurrency ?? null,
            jsHeap: performance.memory ? {
                used: performance.memory.usedJSHeapSize,
                total: performance.memory.totalJSHeapSize,
                limit: performance.memory.jsHeapSizeLimit
            } : null
        }
    });

    try {
        const previousReport = localStorage.getItem(contextLossStorageKey);
        window.__openpbrPreviousContextLossReport = previousReport ? JSON.parse(previousReport) : null;
    } catch {
        window.__openpbrPreviousContextLossReport = null;
    }

    window.__openpbrGpuInfo = createReport();
    console.info('[WebGL GPU info]', window.__openpbrGpuInfo);

    canvas.addEventListener('webglcontextlost', (event) => {
        event.preventDefault();
        const report = createReport();
        window.__openpbrContextLossReport = report;
        try { localStorage.setItem(contextLossStorageKey, JSON.stringify(report)); }
        catch { /* Diagnostics must not interfere with context recovery. */ }
        console.error('[WebGL context lost]', report);
    }, false);
    canvas.addEventListener('webglcontextrestored', () => {
        setGpuDebugStage('context-restored');
        console.warn('[WebGL context restored]');
    }, false);
}

function is_legacy_pt() { return params.renderer_mode === 'Pathtracer legacy'; }
function uses_legacy_fullscreen_shader() { return is_legacy_pt() || is_legacy_bvh_raster_route(); }
function active_pathtrace_material() { return uses_legacy_fullscreen_shader() ? pathtracedMaterial_legacy : pathtracedMaterial; }
function get_pathtrace_materials() { return [pathtracedMaterial, pathtracedMaterial_legacy].filter(Boolean); }

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
        if (!getRendererModes().includes(params.renderer_mode)) {
            params.renderer_mode = 'Rasterizer MTLX';
            console.warn('[URL params] legacy renderer disabled; using Rasterizer MTLX');
        }
        console.log('[URL params] renderer_mode =', params.renderer_mode);
    }

    // Generate GLSL from .mtlx before building the first shader.
    let mtlxText = DEFAULT_MTLX;
    let mtlxMaterialBaseUrl = getPublicAssetUrl('');
    if (search.has('mtlx_url')) {
        try {
            let mtlxUrl = search.get('mtlx_url');
            // Relative paths need BASE_URL prefix: Vite serves public files under the base.
            if (mtlxUrl.startsWith('/') && !mtlxUrl.startsWith('//')) {
                mtlxUrl = APP_BASE_URL.replace(/\/$/, '') + mtlxUrl;
            }
            mtlxMaterialBaseUrl = new URL(mtlxUrl, window.location.origin).toString().replace(/[^/]*$/, '');
            const resp = await fetch(mtlxUrl);
            if (resp.ok) mtlxText = await resp.text();
            else console.warn('[mtlx] fetch failed:', resp.status, mtlxUrl);
        } catch (e) {
            console.warn('[mtlx] fetch error:', e);
        }
    }
    try {
        if (is_mtlx_route() || is_mtlx_bvh_raster_route()) {
            // MTLX BVH routes: pathtracer uses MtlxPathTracerHostShaderGenerator;
            // raster uses EsslHostShaderGenerator and calls its generated main().
            mtlxRouteTextureBindings = [];
            mtlxRouteLights = [];
            const result = is_mtlx_bvh_raster_route()
                ? await generateMtlxRasterDispatch(mtlxText)
                : await generateMtlxRouteDispatch(mtlxText);
            const parameterBinding = bindMtlxParametersToTexture(result.glsl, mtlxText);
            mtlxRouteParamDescriptors = parameterBinding.parameters;
            mtlxRouteDispatchGlsl = parameterBinding.glsl;
            mtlxRouteMaterialSummary = summarizeMtlxRouteMaterialParams(result.mtlxParams);
            mtlxRouteTextureBindings = extractMtlxTextureBindings(mtlxText, mtlxMaterialBaseUrl);
            mtlxRouteLights = extractMtlxLights(mtlxText);

            mtlxRouteLights.push(...extractMtlxLightOverrides(search));
            if (mtlxRouteTextureBindings.length > 0) {
                console.log('[mtlx-route] textures', mtlxRouteTextureBindings.map(t => `${t.sampler}=${t.source}`).join(', '));
            }
            materialDefines.MAX_MTLX_LIGHTS = Math.max(1, mtlxRouteLights.length);
            if (mtlxRouteLights.length > 0) {
                console.log('[mtlx-route] lights', mtlxRouteLights.map(l => `${l.name}:type=${l.type},intensity=${l.intensity}`).join(', '));
            }
            const p = result.mtlxParams;
            const hasTransmission = p.transmissionWeight > 0;
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

    await loadMtlxMaterialLibrary();
    init();
    render();
})();

function create_materials()
{
    renderer.outputColorSpace = SRGBColorSpace;

    if (mtlxRouteLightsTexture) {
        mtlxRouteLightsTexture.dispose();
        mtlxRouteLightsTexture = null;
    }

    if (openpbrMaterial)
        openpbrMaterial.dispose();

    if (neutralMaterial)
        neutralMaterial.dispose();

    if (pathtracedMaterial)
        pathtracedMaterial.dispose();
    // pathtracedMaterial_legacy is rebuilt separately inside create_materials()

    if (!FULLSCREEN_BVH_ROUTE)
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

    if (FULLSCREEN_BVH_ROUTE)
    {
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // pathtracedMaterial (for pathtracing shader)
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        if (uses_mtlx_fullscreen_shader()) {
            const mtlxRouteCommon = is_mtlx_bvh_raster_route()
                ? glsl_rasterization_mtlx_common
                : glsl_mtlx_route_common;
            const mtlxFragmentShader = `precision highp isampler2D;
                            precision highp usampler2D;
                            precision highp int;
                            ${ bvhGlslPrelude() }
                        `
                        + adaptBvhGlslForEngine(mtlxRouteCommon + '\n' + assemble_mtlx_route_dispatch());

            if (is_mtlx_bvh_raster_route()) {
                console.log('[mtlx-raster] fragment shader lines', mtlxFragmentShader.split('\n').length);
                window.__openpbrMtlxRasterFragmentShader = mtlxFragmentShader;
            }

            pathtracedMaterial = new ShaderMaterial( {

        defines: materialDefines,

        uniforms: UniformsUtils.merge( [

            UniformsUtils.clone(ShaderLib.phong.uniforms),
            {
                ...createBvhUniforms('bvh_surface'),
                geomN_surface:           { value: new FloatVertexAttributeTexture() },
                geomT_surface:           { value: new FloatVertexAttributeTexture() },
                geomS_surface:           { value: new FloatVertexAttributeTexture() },
                has_normals_surface:     { value: 1 },
                has_tangents_surface:    { value: 0 },
                has_uvs_surface:         { value: 0 },

                ground_texture:        { value: null },
                ground_y:              { value: sceneGroundY },

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
                mtlxDisableSun:                      { value: params.env_map_provided === true },
                ...createMtlxLightUniforms(),

                // Raw equirectangular env map for MaterialX IBL (sampler2D, not samplerCube).
                envMapLatLong:                       { value: null },
                envMapIrradiance:                    { value: null },

                // Dedicated raw-orientation env map + luminance CDF for NEE importance
                // sampling (feature 004, Phase 5 "envmap" alignment). Independent of
                // envMapLatLong/envMap above: those keep three.js's flipY=true convention.
                envMapEquirect:                      { value: null },
                envMapCDFTex:                        { value: null },
                envMapRes:                           { value: new Vector2(1, 1) },
                envMapTotalSum:                      { value: 0.0 },
                has_env_cdf:                          { value: false },
                // MTLX material textures are assigned AFTER construction (see below):
                // UniformsUtils.merge clones texture uniforms, which decouples them from
                // the async TextureLoader (needsUpdate lands on the original, not the clone).

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

        fragmentShader: mtlxFragmentShader

            } );
            // Assign texture uniforms directly (not via UniformsUtils.merge, which would
            // clone them and miss async TextureLoader updates -> black samplers).
            Object.assign(pathtracedMaterial.uniforms, createMtlxRouteTextureUniforms());
            if (pathtracedMaterial.uniforms.mtlxLightsTex)
                pathtracedMaterial.uniforms.mtlxLightsTex.value = mtlxRouteLightsTexture;
        }
        else {
            pathtracedMaterial = null;
        }

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
                ...createBvhUniforms('bvh_surface'),
                normalAttribute_surface: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_surface:{ value: new FloatVertexAttributeTexture() },
                has_normals_surface:     { value: 1 },
                has_tangents_surface:    { value: 0 },
                ...createBvhUniforms('bvh_props'),
                normalAttribute_props: { value: new FloatVertexAttributeTexture() },
                tangentAttribute_props:{ value: new FloatVertexAttributeTexture() },
                has_normals_props:     { value: 1 },
                has_tangents_props:    { value: 0 },
                ground_texture:        { value: null },
                ground_y:              { value: sceneGroundY },
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
                            ${ bvhGlslPrelude() }
                        `
                        + adaptBvhGlslForEngine(
                            glsl_legacy_main
                            + glsl_legacy_fuzz_brdf
                            + glsl_legacy_coat_brdf
                            + glsl_legacy_thin_film
                            + glsl_legacy_specular_brdf
                            + glsl_legacy_specular_btdf
                            + glsl_legacy_metal_brdf
                            + glsl_legacy_diffuse_brdf
                            + glsl_legacy_diffuse_btdf
                            + glsl_legacy_openpbr_surface
                            + (is_legacy_bvh_raster_route() ? glsl_rasterization_legacy_bvh_rasterizer : glsl_legacy_pathtracer)
                        )

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
    setGpuDebugStage('creating-renderer');
    renderer = new WebGLRenderer( { antialias: true, preserveDrawingBuffer: true } );
    renderer.setPixelRatio( window.devicePixelRatio );
    renderer.setClearColor( 0x09141a );
    renderer.setSize( window.innerWidth, window.innerHeight );
    renderer.outputColorSpace = SRGBColorSpace;
    renderer.shadowMap.enabled = true;
    renderer.shadowMapSoft = true;
    renderer.shadowMap.type = PCFSoftShadowMap; // default THREE.PCFShadowMap
    renderer.physicallyBasedShading = true;

    // Intercept GLSL compilation errors with full driver log + line numbers.
    // Mobile GPUs often fail at link time (uniform/varying/instruction limits,
    // highp precision), whose message lives in the PROGRAM info log, not the
    // shader logs -- and some drivers omit the word "ERROR" or return empty logs.
    renderer.debug.onShaderError = function(gl, program, vertexShader, fragmentShader) {
        const vertLog = gl.getShaderInfoLog(vertexShader) || '';
        const fragLog = gl.getShaderInfoLog(fragmentShader) || '';
        const progLog = gl.getProgramInfoLog(program) || '';
        const vertOK  = gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS);
        const fragOK  = gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS);
        const linked  = gl.getProgramParameter(program, gl.LINK_STATUS);
        const failed  = vertOK === false || fragOK === false || linked === false
                     || /\bERROR\b/i.test(vertLog) || /\bERROR\b/i.test(fragLog) || /\bERROR\b/i.test(progLog);
        if (!failed) {
            const warningLog = [progLog, vertLog, fragLog].filter(log => log.trim().length > 0).join('\n');
            if (warningLog) console.warn('[GLSL shader warning]\n' + warningLog);
            return;
        }
        let msg = '';
        if (progLog.trim().length > 0) {
            console.error('[GLSL program/link error]\n' + progLog);
            msg += '── PROGRAM / LINK ──\n' + progLog.trim() + '\n\n';
        }
        if (vertLog.trim().length > 0) {
            console.error('[GLSL vertex shader error]\n' + vertLog);
            msg += '── VERTEX SHADER ──\n' + vertLog.trim() + '\n\n';
        }
        if (fragLog.trim().length > 0) {
            console.error('[GLSL fragment shader error]\n' + fragLog);
            msg += '── FRAGMENT SHADER ──\n' + fragLog.trim() + '\n\n';
        }
        if (msg.trim().length === 0) {
            // Driver reported a failure but gave no log (common on mobile).
            msg = 'Shader program failed to compile/link but the GPU driver returned no log.\n' +
                  `compile vertex=${vertOK} fragment=${fragOK} link=${linked}`;
            console.error('[GLSL shader error] ' + msg);
        }
        // Dump the full GLSL source (line-numbered) so the failing program can be inspected.
        const numberLines = (src) => (src || '').split('\n')
            .map((line, i) => String(i + 1).padStart(4, ' ') + ' | ' + line).join('\n');
        const vertSrc = gl.getShaderSource(vertexShader) || '';
        const fragSrc = gl.getShaderSource(fragmentShader) || '';
        window.__openpbrShaderSource = { vertex: vertSrc, fragment: fragSrc };
        console.error('[GLSL vertex shader source]\n' + numberLines(vertSrc));
        console.error('[GLSL fragment shader source]\n' + numberLines(fragSrc));
        window.__openpbrShaderError = msg;
        const overlay = document.getElementById('shader-error');
        document.getElementById('shader-error-content').textContent = msg;
        overlay.style.display = 'block';
    };

    // Enable parallel shader compilation if available
    const gl = renderer.getContext();
    installWebGLDiagnostics(gl);
    setGpuDebugStage('renderer-ready');
    const parallelShaderCompileExt = gl.getExtension('KHR_parallel_shader_compile');
    if (parallelShaderCompileExt) {
        console.log('Parallel shader compilation enabled');
    } else {
        console.log('Parallel shader compilation not supported - shader compilation may be slow');
    }

    document.body.appendChild( renderer.domElement );

    FULLSCREEN_BVH_ROUTE = is_fullscreen_bvh_route();

    //// stats setup
    //stats = new Stats();
    //stats.dom.id = 'stats-panel';
    //document.body.appendChild( stats.dom );

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
    setGpuDebugStage('loading-geometry');
    scene.background = env_map_texture;
    env_map_texture.mapping = EquirectangularReflectionMapping ;
    env_map_texture.colorSpace = SRGBColorSpace;
    if (!FULLSCREEN_BVH_ROUTE)
    {
        neutralMaterial.envMap                = env_map_texture;
        neutralMaterial.uniforms.envMap.value = env_map_texture;
        openpbrMaterial.envMap                = env_map_texture;
        openpbrMaterial.uniforms.envMap.value = env_map_texture;
    }
    else
    {
        for (const pm of get_pathtrace_materials()) {
            if (pm.uniforms.envMapLatLong) pm.uniforms.envMapLatLong.value = env_map_latlong_texture;
            if (pm.uniforms.envMapIrradiance) pm.uniforms.envMapIrradiance.value = env_irradiance_latlong_texture || env_map_latlong_texture;
            if (pm.uniforms.has_env_cdf) {
                const importance = env_map_importance;
                // Gated behind an explicit opt-in (default off): the CDF importance-sampling
                // path has a known bug (blown-out/white render) not yet root-caused -- see
                // specs/004-threejs-bvh-removal/plan.md Phase 5 "envmap".
                pm.uniforms.has_env_cdf.value = params.env_cdf_sampling === true && !!importance;
                pm.uniforms.envMapEquirect.value = importance ? importance.equirectTexture : null;
                pm.uniforms.envMapCDFTex.value = importance ? importance.cdfTexture : null;
                pm.uniforms.envMapRes.value.set(importance ? importance.width : 1, importance ? importance.height : 1);
                pm.uniforms.envMapTotalSum.value = importance ? importance.totalSum : 0.0;
            }
        }
    }

    // Load "neutral" objects (i.e. Lambert shaded background stuff)
    mesh_loader.load(getPublicAssetUrl(scene_name + '/neutral_objects.glb')).then( () => {

        if (!FULLSCREEN_BVH_ROUTE)
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

        if (FULLSCREEN_BVH_ROUTE)
        {
            // Set up mesh properties for pathtracing
                    if (uses_mtlx_fullscreen_shader() && mtlxArchiveDisplacement)
                    {
                        MESH_SURFACE.geometry = applyMtlxDisplacement(MESH_SURFACE.geometry, mtlxArchiveDisplacement);
                        console.log('[mtlx-displacement] deformed vertices', MESH_SURFACE.geometry.attributes.position.count,
                            '| scale:', mtlxArchiveDisplacement.scale);
                    }
            BVH_PROPS  = mesh_loader.result.bvh;
                for (const pm of get_pathtrace_materials()) {
                if (!pm.uniforms.bvh_props) continue; // MTLX route dropped the props BVH
                assignBvhUniforms(pm.uniforms, 'bvh_props', BVH_PROPS);
                pm.uniforms.has_normals_props.value = false;
                pm.uniforms.has_tangents_props.value = false;
                if (pm.uniforms.has_uvs_props) pm.uniforms.has_uvs_props.value = false;
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
                if (pm.uniforms.uvAttribute_props && MESH_PROPS.geometry.attributes.uv)
                {
                    pm.uniforms.uvAttribute_props.value.updateFrom( MESH_PROPS.geometry.attributes.uv );
                    pm.uniforms.has_uvs_props.value = true;
                }
            }
                const pt = active_pathtrace_material();
                console.log("  has_normals_scene:  ", pt.uniforms.has_normals_props);
                console.log("  has_tangents_scene: ", pt.uniforms.has_tangents_props);
        }

        progress_bar.animate(0.5);
        mesh_loader.reset();

        // Load OpenPBR-shaded objects
        mesh_loader.load(getPublicAssetUrl(scene_name + '/openpbr_objects.glb'), {
        }).then( () => {

            if (!FULLSCREEN_BVH_ROUTE)
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
            if (uses_mtlx_fullscreen_shader() && mtlxArchiveDisplacement)
            {
                MESH_SURFACE.geometry = applyMtlxDisplacement(MESH_SURFACE.geometry, mtlxArchiveDisplacement);
                console.log('[mtlx-displacement] deformed vertices', MESH_SURFACE.geometry.attributes.position.count,
                    '| scale:', mtlxArchiveDisplacement.scale);
            }

            if (FULLSCREEN_BVH_ROUTE)
            {
                // Set up mesh properties for pathtracing
                BVH_SURFACE  = mesh_loader.result.bvh;
                let combinedSurface = null;   // MTLX route: neutral+openpbr merged BVH (cached)
                for (const pm of get_pathtrace_materials()) {
                    if (pm.uniforms.geomN_surface)
                    {
                        // MTLX route: merge neutral (props) + openpbr into one BVH.
                        if (!combinedSurface)
                        {
                            const geom = buildCombinedSurfaceGeometry(MESH_PROPS ? MESH_PROPS.geometry : null, MESH_SURFACE.geometry);
                            combinedSurface = { bvh: buildBvh(geom), packed: packSurfaceGeom(geom) };
                        }
                        assignBvhUniforms(pm.uniforms, 'bvh_surface', combinedSurface.bvh);
                        pm.uniforms.geomN_surface.value.updateFrom( combinedSurface.packed.gN );
                        pm.uniforms.geomT_surface.value.updateFrom( combinedSurface.packed.gT );
                        pm.uniforms.geomS_surface.value.updateFrom( combinedSurface.packed.gS );
                        pm.uniforms.has_normals_surface.value  = combinedSurface.packed.has_normals;
                        pm.uniforms.has_tangents_surface.value = combinedSurface.packed.has_tangents;
                        pm.uniforms.has_uvs_surface.value      = combinedSurface.packed.has_uvs;
                        continue;
                    }
                    assignBvhUniforms(pm.uniforms, 'bvh_surface', BVH_SURFACE);
                    pm.uniforms.has_normals_surface.value = false;
                    pm.uniforms.has_tangents_surface.value = false;
                    if (pm.uniforms.has_uvs_surface) pm.uniforms.has_uvs_surface.value = false;
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
                    if (pm.uniforms.uvAttribute_surface && MESH_SURFACE.geometry.attributes.uv)
                    {
                        pm.uniforms.uvAttribute_surface.value.updateFrom( MESH_SURFACE.geometry.attributes.uv );
                        pm.uniforms.has_uvs_surface.value = true;
                    }
                }
                const pt = active_pathtrace_material();
                console.log("  has_normals_surface:  ", pt.uniforms.has_normals_surface);
                console.log("  has_tangents_surface: ", pt.uniforms.has_tangents_surface);
                console.log("===> LOADED");
            }

            const groundBounds = new Box3();
            for (const mesh of [MESH_PROPS, MESH_SURFACE])
            {
                if (!mesh?.geometry) continue;
                mesh.geometry.computeBoundingBox();
                if (mesh.geometry.boundingBox) groundBounds.union(mesh.geometry.boundingBox);
            }
            sceneGroundY = groundBounds.isEmpty() ? 0.01 : groundBounds.min.y - 0.01;

            // Ground plane texture
            const groundTex = loadNativeTexture(getPublicAssetUrl('textures/ground.png'));
            groundTex.wrapS = RepeatWrapping;
            groundTex.wrapT = RepeatWrapping;
            groundTex.colorSpace = SRGBColorSpace;

            if (!FULLSCREEN_BVH_ROUTE)
            {
                // Rasterizer: add ground plane mesh
                groundTex.repeat.set(2, 2);
                groundTex.offset.set(0.5, 0.5);
                const groundGeom = new PlaneGeometry(200, 200);
                const groundMat = new MeshLambertMaterial({ map: groundTex, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -1 });
                const groundMesh = new Mesh(groundGeom, groundMat);
                groundMesh.rotation.x = -Math.PI / 2;
                groundMesh.position.y = sceneGroundY;
                groundMesh.receiveShadow = true;
                scene.add(groundMesh);
            }
            else
            {
                // Pathtracer: pass texture as uniform (UV mapping done in shader)
                for (const pm of get_pathtrace_materials()) {
                    pm.uniforms.ground_texture.value = groundTex;
                }
            }

            LOADED = true;
            setGpuDebugStage('scene-loaded');

            post_load_setup();

            progress_bar.animate(1.0);
            let progress_overlay = document.getElementById('progress_overlay');
            progress_finished_timer = performance.now();

        } )

    } );
}

function load_scene(scene_name)
{
    setGpuDebugStage('loading-scene');
    console.log('Loading scene: ', scene_name);
    LOADED = false;

    FULLSCREEN_BVH_ROUTE = is_fullscreen_bvh_route();

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
        const failStartup = (message) => {
            console.error(message);
            window.__openpbrShaderError = message;
            window.__openpbrReady = true;
        };
        const normalizeAssetPath = (path) => {
            if (!path) return path;
            if (/^(?:[a-z]+:)?\/\//i.test(path)) return path;
            return getPublicAssetUrl(path);
        };
        const loadEnvTexture = (path, onLoad) => {
            const assetPath = normalizeAssetPath(path);
            loadEnvironmentTexture(assetPath).then(({ texture, importance }) => {
                const latLongTexture = texture.clone();
                latLongTexture.needsUpdate = true;
                texture.mapping = EquirectangularReflectionMapping;
                if (!/\.hdr(?:$|[?#])/i.test(assetPath)) {
                    texture.colorSpace = SRGBColorSpace;
                    latLongTexture.colorSpace = SRGBColorSpace;
                }
                onLoad(texture, importance, latLongTexture);
            }).catch(err => {
                failStartup(`[envmap] failed to load ${assetPath}: ${err?.message || err || 'unknown error'}`);
            });
        };
        const env_map_path = params.env_map_path || 'textures/envmaps/etzwihl_4k.jpg';
        loadEnvTexture(env_map_path, (texture, importance, latLongTexture) => {
            console.log('-> loaded env map: ', env_map_path);
            env_map_texture = texture;
            env_map_latlong_texture = latLongTexture;
            env_map_importance = importance;
            const irradiancePath = params.env_irradiance_path || '';
            if (irradiancePath) {
                loadEnvTexture(irradiancePath, (irradianceTexture, _importance, irradianceLatLongTexture) => {
                    console.log('-> loaded env irradiance map: ', irradiancePath);
                    env_irradiance_texture = irradianceTexture;
                    env_irradiance_latlong_texture = irradianceLatLongTexture;
                    load_geometry(scene_name);
                });
            }
            else {
                env_irradiance_texture = env_map_texture;
                env_irradiance_latlong_texture = env_map_latlong_texture;
                load_geometry(scene_name);
            }
        });
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
    orbitControls.addEventListener( 'change', handleCameraChange );
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

    const bounds = new Box3();
    const framingMesh = MESH_SURFACE || MESH_PROPS;
    if (framingMesh?.geometry)
    {
        framingMesh.geometry.computeBoundingBox();
        if (framingMesh.geometry.boundingBox) bounds.union(framingMesh.geometry.boundingBox);
    }

    let dir = new Vector3();
    camera.getWorldDirection(dir);
    let cam_target = camera.position.clone();
    cam_target.addScaledVector(dir, 23.39613);
    if (!bounds.isEmpty()) bounds.getCenter(cam_target);
    orbitControls.target.copy(cam_target);

    orbitControls.zoomSpeed = 1.5;
    orbitControls.flySpeed = 0.01;
    orbitControls.update();

    if (params.render_size !== 'max')
    {
        if (!bounds.isEmpty())
        {
            const renderDimensions = getRenderDimensions();
            const aspect = renderDimensions.w / renderDimensions.h;
            const tanHalfVerticalFov = Math.tan(camera.fov * Math.PI / 360.0);
            const tanHalfHorizontalFov = tanHalfVerticalFov * aspect;
            const forward = new Vector3();
            camera.getWorldDirection(forward);
            const right = new Vector3().setFromMatrixColumn(camera.matrixWorld, 0).normalize();
            const up = new Vector3().setFromMatrixColumn(camera.matrixWorld, 1).normalize();
            const corner = new Vector3();
            const offset = new Vector3();
            let requiredRetreat = 0.0;
            const margin = 1.25;

            for (let cornerIndex = 0; cornerIndex < 8; cornerIndex++)
            {
                corner.set(
                    cornerIndex & 1 ? bounds.max.x : bounds.min.x,
                    cornerIndex & 2 ? bounds.max.y : bounds.min.y,
                    cornerIndex & 4 ? bounds.max.z : bounds.min.z
                );
                offset.subVectors(corner, camera.position);
                const depth = offset.dot(forward);
                requiredRetreat = Math.max(
                    requiredRetreat,
                    Math.abs(offset.dot(right)) * margin / tanHalfHorizontalFov - depth,
                    Math.abs(offset.dot(up)) * margin / tanHalfVerticalFov - depth,
                    camera.near * 2.0 - depth
                );
            }

            if (requiredRetreat > 0.0)
            {
                camera.position.addScaledVector(forward, -requiredRetreat);
                camera.updateMatrixWorld();
                orbitControls.update();
            }
        }
    }
}


function formatMtlxParameterLabel(name)
{
    return String(name).replace(/_/g, ' ').replace(/\b\w/g, character => character.toUpperCase());
}

function setupMtlxParameterControls(materialFolder)
{
    const parametersFolder = materialFolder.addFolder('Material Parameters');
    const folders = new Map();

    for (const parameter of mtlxRouteParamDescriptors)
    {
        const folderName = parameter.uiFolder || 'Surface';
        let folder = folders.get(folderName);
        if (!folder)
        {
            folder = parametersFolder.addFolder(folderName);
            folders.set(folderName, folder);
        }

        const label = parameter.uiName || formatMtlxParameterLabel(parameter.name);
        const isColor = parameter.uiType === 'color3' || parameter.uiType === 'color4' || /_color$/.test(parameter.name);
        const assignValue = value => {
            parameter.value = Array.isArray(value) ? value.map(Number)
                : parameter.type === 'bool' ? Boolean(value)
                : parameter.type === 'int' ? Math.trunc(Number(value))
                : Number(value);
            updateMtlxParameterTexture(parameter);
        };

        if (Array.isArray(parameter.value) && !isColor)
        {
            const vectorFolder = folder.addFolder(label);
            const componentNames = ['X', 'Y', 'Z', 'W'];
            parameter.value.forEach((component, index) => {
                const control = { value: component };
                vectorFolder.add(control, 'value').name(componentNames[index]).onChange(value => {
                    parameter.value[index] = Number(value);
                    updateMtlxParameterTexture(parameter);
                });
            });
            continue;
        }

        const control = { value: Array.isArray(parameter.value) ? [...parameter.value] : parameter.value };
        let controller;
        if (isColor && Array.isArray(parameter.value) && parameter.value.length >= 3)
        {
            controller = folder.addColor(control, 'value');
        }
        else if (Number.isFinite(parameter.min) && Number.isFinite(parameter.max))
        {
            const step = Number.isFinite(parameter.step) ? parameter.step : (parameter.type === 'int' ? 1 : undefined);
            controller = step === undefined
                ? folder.add(control, 'value', parameter.min, parameter.max)
                : folder.add(control, 'value', parameter.min, parameter.max, step);
        }
        else
        {
            controller = folder.add(control, 'value');
        }
        controller.name(label).onChange(assignValue);
    }

    parametersFolder.open();
}

function makeGuiDraggable()
{
    const panel = gui.domElement;
    const handle = panel.querySelector(':scope > .title');
    if (!handle) return;

    let dragState = null;

    handle.style.cursor = 'move';
    handle.style.touchAction = 'none';
    handle.style.userSelect = 'none';
    handle.addEventListener('pointerdown', event => {
        if (event.button !== 0) return;

        const bounds = panel.getBoundingClientRect();
        dragState = {
            offsetX: event.clientX - bounds.left,
            offsetY: event.clientY - bounds.top,
            width: bounds.width,
            height: bounds.height
        };
        panel.style.left = `${bounds.left}px`;
        panel.style.top = `${bounds.top}px`;
        panel.style.right = 'auto';
        panel.style.bottom = 'auto';
        handle.setPointerCapture(event.pointerId);
        event.preventDefault();
    });

    handle.addEventListener('pointermove', event => {
        if (!dragState) return;

        const maxLeft = Math.max(0, window.innerWidth - dragState.width);
        const maxTop = Math.max(0, window.innerHeight - dragState.height);
        const left = Math.min(maxLeft, Math.max(0, event.clientX - dragState.offsetX));
        const top = Math.min(maxTop, Math.max(0, event.clientY - dragState.offsetY));
        panel.style.left = `${left}px`;
        panel.style.top = `${top}px`;
    });

    const stopDragging = event => {
        if (!dragState) return;
        dragState = null;
        if (handle.hasPointerCapture(event.pointerId)) {
            handle.releasePointerCapture(event.pointerId);
        }
    };
    handle.addEventListener('pointerup', stopDragging);
    handle.addEventListener('pointercancel', stopDragging);
}

function setup_gui()
{
    if (gui)
        gui.destroy()
    gui = new GUI({ width: 300 });

    // Top-level pause toggle (freeze/resume the pathtracer accumulation).
    pauseController = gui.add(params, 'paused').name('pause (arrêt / relance)');

    ///// Material folder /////////////////////////////////////
    const material_folder = gui.addFolder('Material');
    const mtlx_library_folder = material_folder.addFolder('MaterialX Library');
    mtlx_library_folder.add({ open: openMtlxPicker }, 'open').name('choose material');
    mtlx_library_folder.add({ open: openMtlxCopilotDialog }, 'open').name('generate with Copilot');
    mtlx_library_folder.close();

    if (uses_mtlx_fullscreen_shader()) setupMtlxParameterControls(material_folder);
    else
    {
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
    }

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
    renderer_folder.add(params, 'renderer_mode', getRendererModeOptions()).onChange(              async v => {
        try { await ensureMtlxRouteDispatch(); }
        catch (e) { showMtlxLibraryError(e); return; }
        load_scene(params.scene_name);
    });
    renderer_folder.add(params, 'scene_name', scene_names).onChange(                                  v => { setPaused(true); load_scene(v); });
    renderer_folder.add( params, 'smooth_normals' ).onChange(                                         v => { resetSamples(); });
    renderer_folder.add( params, 'wireframe' ).onChange(                                              v => { resetSamples(); });
    renderer_folder.addColor(params, 'neutral_color').onChange(                                       v => { resetSamples(); });
    renderer_folder.add( params, 'bounces', 0, 100, 1 ).onChange(                                     v => { resetSamples(); } );
    renderer_folder.add( params, 'max_samples' ).onChange(                                            v => { load_scene(params.scene_name); });
    renderer_folder.add( params, 'render_size', ['256x256', '512x512', 'max'] ).name('render size').onChange( v => { resize(); });
    renderer_folder.add( params, 'max_volume_steps', 1, 100, 1 ).onChange(                            v => { resetSamples(); } );
    renderer_folder.add( params, 'firefly_clamp', 1, 1000 ).onChange(                                v => { resetSamples(); } );
    renderer_folder.close();

    gui.add( params, 'reset_camera' );
    gui.open();
    makeGuiDraggable();
}

function post_load_setup()
{
    console.log(scene);

    if (!FULLSCREEN_BVH_ROUTE)
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

    if (FULLSCREEN_BVH_ROUTE)
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
    setGpuDebugStage('compiling-shaders');
    let tmp_cam = new OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );
    startCompilationProgress();

    let promises = [renderer.compileAsync(scene, tmp_cam)];

    // FullScreenQuad meshes aren't in the scene, so compile them separately
    if (FULLSCREEN_BVH_ROUTE && pathtracedQuad) {
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
        if (FULLSCREEN_BVH_ROUTE && pathtracedQuad && pathtracingRenderTarget) {
            setGpuDebugStage('warmup-render');
            camera.updateMatrixWorld();
            sync_shader_uniforms(active_pathtrace_material().uniforms);
            renderer.setRenderTarget(pathtracingRenderTarget);
            pathtracedQuad.render(renderer);
            renderer.setRenderTarget(null);
            resetSamples();
        }
        setGpuDebugStage('shaders-ready');
        finishCompilationProgress();
    }).catch((err) => {
        clearTimeout(warnTimer);
        clearTimeout(abortTimer);
        console.error('shader compilation error: ' + err);
        const overlay = document.getElementById('shader-error');
        document.getElementById('shader-error-content').textContent =
            'Shader compilation error:\n' + (err && err.stack ? err.stack : String(err));
        overlay.style.display = 'block';
        finishCompilationProgress();
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
    _progressFading = false;
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
    const progress_overlay = document.getElementById('progress_overlay');
    progress_overlay.style.display = 'none';
    progress_overlay.style.opacity = 0;
    // Signal headless readiness (used by launch_render.mjs)
    window.__openpbrReady   = true;
    window.__openpbrSamples = 0;
}

// Canvas size for the selected render_size. '256x256'/'512x512' are literal pixel
// sizes (square, centered), 'max' fills the window at its native resolution.
function getRenderDimensions()
{
    const W = window.innerWidth, H = window.innerHeight;
    if (params.render_size === 'max') return { w: W, h: H };
    const side = params.render_size === '512x512' ? 512 : 256;
    return { w: Math.min(side, W), h: Math.min(side, H) };
}

function getPathtracerRenderDimensions()
{
    const dimensions = getRenderDimensions();
    if (!pathtracerInteractivePreview) return dimensions;
    return {
        w: Math.max(1, Math.round(dimensions.w * PATH_TRACER_INTERACTIVE_SCALE)),
        h: Math.max(1, Math.round(dimensions.h * PATH_TRACER_INTERACTIVE_SCALE)),
    };
}

function updatePathtracingRenderTargetSize()
{
    if (!pathtracingRenderTarget) return;
    const dimensions = getPathtracerRenderDimensions();
    if (pathtracingRenderTarget.width !== dimensions.w || pathtracingRenderTarget.height !== dimensions.h)
        pathtracingRenderTarget.setSize(dimensions.w, dimensions.h);
}

function handleCameraChange()
{
    resetSamples();
    if (!is_pathtracing_route()) return;

    pathtracerInteractivePreview = true;
    updatePathtracingRenderTargetSize();
    clearTimeout(pathtracerCameraIdleTimer);
    pathtracerCameraIdleTimer = setTimeout(() => {
        pathtracerInteractivePreview = false;
        pathtracerCameraIdleTimer = null;
        updatePathtracingRenderTargetSize();
        resetSamples();
    }, PATH_TRACER_CAMERA_SETTLE_MS);
}

function resize()
{
    // render_size drives the actual canvas size. updateStyle=true makes three set the
    // canvas CSS size in px to match the drawing buffer, so the render is shown 1:1 at
    // its real size (a 256x256 / 512x512 square) instead of being stretched to the window.
    const rd = getRenderDimensions();
    camera.aspect = rd.w / rd.h;
    camera.updateProjectionMatrix();
    renderer.setPixelRatio(1.0);
    renderer.setSize( rd.w, rd.h, true );          // true: set inline px style = buffer size
    if (params.render_size === 'max') {
        renderer.domElement.style.width  = '100%';
        renderer.domElement.style.height = '100%';
    }
    // Anchor the (possibly small) canvas to the top-left of the window.
    renderer.domElement.style.position = 'absolute';
    renderer.domElement.style.top = '0';
    renderer.domElement.style.left = '0';
    renderer.domElement.style.transform = 'none';
    if (FULLSCREEN_BVH_ROUTE) updatePathtracingRenderTargetSize();
    resetSamples();
}

function get_vector3(array3)
{
    return new Vector3(array3[0], array3[1], array3[2]);
}

function resetSamples()
{
    samples = 0;
    pathtracerTileIndex = 0;
}

// Force the render into (or out of) pause and keep the GUI toggle in sync.
function setPaused(state)
{
    params.paused = state;
    if (pauseController) pauseController.updateDisplay();
}

let _progressFading = false;
function fadeOutProgressBar(time_ms)
{
    if (_progressFading) return;   // avoid stacking intervals when called every frame
    _progressFading = true;
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
        _progressFading = false;
    }
    }, time_ms);
}

// Drives the shader-compilation overlay: spin while COMPILING, fade out once done.
// Called both in the normal render path and in the paused branch (which returns early).
function updateProgressOverlay()
{
    if (COMPILING)
    {
        if (progress_bar.value() < 0.01)
            progress_bar.animate(1.0);
        else if (progress_bar.value() > 0.99)
        {
            progress_bar.set(0.0);
            progress_bar.animate(1.0);
        }
        return;
    }
    const progress_overlay = document.getElementById('progress_overlay');
    if (progress_overlay.style.display != 'none' && performance.now() - progress_finished_timer > 300.0)
        fadeOutProgressBar(300);
}

function sync_shader_uniforms(uniforms)
{
    // Resolution must match the canvas / render target the shader draws into.
    const rd = is_pathtracing_route() ? getPathtracerRenderDimensions() : getRenderDimensions();

    // sync camera
    uniforms.cameraWorldMatrix.value.copy( camera.matrixWorld );
    uniforms.invProjectionMatrix.value.copy( camera.projectionMatrixInverse );
    uniforms.invModelMatrix.value.copy( scene.matrixWorld ).invert();

    // sync renderer params
    let resolution = new Vector2(rd.w, rd.h);
    uniforms.resolution.value.copy(resolution);
    uniforms.accumulation_weight.value                    = 1.0 / (samples + 1.0); // implements Monte-Carlo accumulation
    uniforms.samples.value                                = samples;
    if (uniforms.ground_y) uniforms.ground_y.value         = sceneGroundY;

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
    if (uniforms.mtlxDisableSun) uniforms.mtlxDisableSun.value = params.env_map_provided === true;

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
        if (!window.__openpbrLoggedNotLoaded) {
            console.log('not LOADED');
            window.__openpbrLoggedNotLoaded = true;
        }
        requestAnimationFrame( render );
        return;
    }

    setGpuDebugStage('rendering');
    renderer.domElement.style.imageRendering = 'auto';

    if (samples >= params.max_samples)
    {
        requestAnimationFrame( render );
        return;
    }

    // Paused: freeze the pathtracer accumulation, keep the last frame on screen.
    // The rasterizer route is single-pass/cheap and keeps rendering normally.
    if (params.paused && is_pathtracing_route())
    {
        if (pathtracedFinalQuad) {
            renderer.setRenderTarget( null );
            renderer.autoClear = true;
            pathtracedFinalQuad.render( renderer );
        }
        let samples_txt = document.getElementById('samples');
        if (samples_txt) { samples_txt.style.visibility = 'visible'; samples_txt.innerText = `samples: ${ samples } (paused)`; }
        updateProgressOverlay();
        requestAnimationFrame( render );
        return;
    }

    if (!COMPILING && LOADED)
    {
        camera.updateMatrixWorld();

        //////////////////////////////////////////////////////
        // render framebuffer
        //////////////////////////////////////////////////////

        if (FULLSCREEN_BVH_ROUTE)
        {
            const pathtracing = is_pathtracing_route();
            const dimensions = getRenderDimensions();
            const renderDimensions = pathtracing ? getPathtracerRenderDimensions() : dimensions;
            const tiledPathtracing = pathtracing && !pathtracerInteractivePreview;
            const tilesX = Math.ceil(renderDimensions.w / PATH_TRACER_TILE_SIZE);
            const tilesY = Math.ceil(renderDimensions.h / PATH_TRACER_TILE_SIZE);
            const tileX = tiledPathtracing ? pathtracerTileIndex % tilesX : 0;
            const tileY = tiledPathtracing ? Math.floor(pathtracerTileIndex / tilesX) : 0;
            const viewportX = tileX * PATH_TRACER_TILE_SIZE;
            const viewportY = tileY * PATH_TRACER_TILE_SIZE;
            const viewportWidth = tiledPathtracing
                ? Math.min(PATH_TRACER_TILE_SIZE, renderDimensions.w - viewportX)
                : renderDimensions.w;
            const viewportHeight = tiledPathtracing
                ? Math.min(PATH_TRACER_TILE_SIZE, renderDimensions.h - viewportY)
                : renderDimensions.h;

            sync_shader_uniforms(active_pathtrace_material().uniforms);

            // Clear once at the start of accumulation, then render one pathtrace tile per frame.
            renderer.autoClear = samples === 0 && (!tiledPathtracing || pathtracerTileIndex === 0);
            renderer.setRenderTarget( pathtracingRenderTarget );
            renderer.setViewport(viewportX, viewportY, viewportWidth, viewportHeight);
            pathtracedQuad.render( renderer );

            // render to screen
            renderer.setRenderTarget( null );
            renderer.setViewport(0, 0, dimensions.w, dimensions.h);
            renderer.autoClear = true;
            pathtracedFinalQuad.render( renderer );

            if (tiledPathtracing) {
                pathtracerTileIndex++;
                if (pathtracerTileIndex >= tilesX * tilesY) {
                    pathtracerTileIndex = 0;
                    samples++;
                    window.__openpbrSamples = samples;
                }
            } else if (!pathtracing) {
                samples++;
                window.__openpbrSamples = samples;
            }
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
    if (FULLSCREEN_BVH_ROUTE)
    {
        samples_txt.style.visibility = 'visible';
        samples_txt.innerText = `samples: ${ samples }`;
        const modeLabel = is_mtlx_bvh_raster_route() ? 'rasterization (MaterialX BVH)' : is_legacy_pt() ? 'pathtracing (legacy)' : 'pathtracing (MaterialX)';
        info_txt.innerText = `OpenPBR viewer, ${modeLabel} (press 'R' to cycle mode)`;
    }
    else
    {
        samples_txt.style.visibility = 'hidden';
        info_txt.innerText = `OpenPBR viewer, rasterization mode (press 'R' to cycle mode)`;
    }

    // Progress spinner update
    updateProgressOverlay();

    //stats.update();

    requestAnimationFrame( render );
}


document.onkeydown = async function (event)
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
            //if (document.body.contains(stats.dom)) document.body.removeChild( stats.dom );
            //else                                   document.body.appendChild( stats.dom );
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
            try { await ensureMtlxRouteDispatch(); }
            catch (error) { showMtlxLibraryError(error); return; }
            load_scene(params.scene_name);
            break;
        }
    }
}
