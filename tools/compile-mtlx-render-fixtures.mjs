#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';

const root = process.cwd();
const positionalArguments = process.argv.slice(2).filter(argument => !argument.startsWith('--'));
const runtimeRoot = resolve(positionalArguments[0] || '../MaterialX-rva/javascript/build-t036/bin');
const outputRoot = resolve(positionalArguments[1] || 'artifacts/webgpu-render-pathtracer/glsl-vulkan');
const cliOptions = Object.fromEntries(process.argv.slice(2).filter(argument => argument.startsWith('--')).map(argument => {
    const match = argument.match(/^--([^=]+)=(.*)$/);
    return match ? [match[1], match[2]] : [argument.replace(/^--/, ''), 'true'];
}));
const runtimePath = resolve(runtimeRoot, 'JsMaterialXGenShader.js');
const fixtures = [
    ['open_pbr_surface', 'public/mtlx-library/open_pbr_default.mtlx'],
    ['standard_surface', 'public/mtlx-input/standard_surface_default/standard_surface_default.mtlx'],
    ['disney_principled', 'public/mtlx-input/plastic/plastic.mtlx'],
    ['gltf_pbr', 'public/mtlx-input/metal_brushed/metal_brushed.mtlx'],
    ['usd_preview_surface', 'public/mtlx-input/_chrome_test/_chrome_test.mtlx'],
    ['carpaint', 'public/mtlx-input/carpaint/carpaint.mtlx'],
    ['glass', 'public/mtlx-input/glass/glass.mtlx'],
    ['pearl', 'public/mtlx-input/pearl/pearl.mtlx'],
    ['soapbubble', 'public/mtlx-input/soapbubble/soapbubble.mtlx'],
];
const routeSources = {
    pathtracer: {
        common: resolve(root, 'glsl/pathtracing/mtlx/common.glsl'),
        integrator: resolve(root, 'glsl/pathtracing/mtlx/pathtracer.glsl'),
        bridge: null,
    },
    rasterizer: {
        common: resolve(root, 'glsl/rasterization/mtlx/common.glsl'),
        integrator: resolve(root, 'glsl/rasterization/mtlx/rasterizer.glsl'),
        bridge: null,
    },
};
const bvhShaderSource = readFileSync(resolve(root, 'src/bvh/shader.js'), 'utf8').match(/`([\s\S]*)`/)?.[1] || '';
const selectedFixtures = fixtures.filter(([id]) => !cliOptions.fixture || cliOptions.fixture === id);
if (selectedFixtures.length === 0) throw new Error(`Unknown fixture: ${cliOptions.fixture}`);

if (!existsSync(runtimePath)) throw new Error(`Missing MaterialX runtime: ${runtimePath}`);
mkdirSync(outputRoot, { recursive: true });
const module = await import(`file://${runtimePath.replaceAll('\\', '/')}`);
const factory = module.default || module;
const mx = await factory({ locateFile: file => resolve(runtimeRoot, file) });
const pathHost = mx.MtlxPathTracerHostShaderGenerator;
const rasterHost = mx.EsslHostShaderGenerator;
if (!pathHost?.create || !rasterHost?.create) throw new Error('Required MaterialX host generator export is missing.');
const selectedRoutes = [['pathtracer', pathHost], ['rasterizer', rasterHost]]
    .filter(([route]) => !cliOptions.route || cliOptions.route === route);
if (selectedRoutes.length === 0) throw new Error(`Unknown route: ${cliOptions.route}`);

const vulkanPreamble = `#version 450
#define MAX_LIGHT_SOURCES 1
layout(location = 0) out vec4 mtlxFragmentColor;
#define gl_FragColor mtlxFragmentColor
`;
const rasterHostPreamble = `
#define MAX_LIGHT_SOURCES 1
uniform sampler2D envMapLatLong;
uniform sampler2D envMapIrradiance;
uniform float skyPower;
uniform mat4 cameraWorldMatrix;
uniform int mtlxLightCount;
mat4 mtlxEnvMatrix() {
    float angle = 1.57079632679;
    float c = cos(angle), s = sin(angle);
    return mat4(c, 0., -s, 0., 0., -1., 0., 0., s, 0., c, 0., 0., 0., 0., 1.);
}
#define u_envRadiance envMapLatLong
#define u_envIrradiance envMapIrradiance
#define u_envLightIntensity skyPower
#define u_envRadianceMips 1
#define u_envRadianceSamples 1
#define u_envMatrix mtlxEnvMatrix()
#define u_refractionTwoSided false
#define u_numActiveLightSources mtlxLightCount
#define u_viewPosition cameraWorldMatrix[3].xyz
`;
const results = [];

function compile(sourcePath, spvPath, logPath) {
    try {
        execFileSync(process.execPath, [
            'tools/compile-glsl-to-spirv.mjs',
            '--input', sourcePath,
            '--output', spvPath,
            '--stage', 'frag',
        ], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
        writeFileSync(logPath, `compiled ${sourcePath} -> ${spvPath}\n`, 'utf8');
        return { status: 'compiled', spv: spvPath };
    } catch (error) {
        const diagnostic = [error.stdout, error.stderr, error.message].filter(Boolean).join('\n');
        writeFileSync(logPath, diagnostic, 'utf8');
        return { status: 'failed', error: diagnostic };
    }
}

function stripGeneratedHostPrimitives(source) {
    let result = source
        .replace(/struct\s+Basis\s*\{[\s\S]*?\}\s*;\s*/g, '')
        .replace(/struct\s+Volume\s*\{[\s\S]*?\}\s*;\s*/g, '')
        .replace(/^\s*const\s+float\s+(?:PI|PDF_EPSILON|DENOM_TOLERANCE|FLT_EPSILON)\s*=.*?;\s*$/gm, '')
        .replace(/^\s*#include\s+.*$/gm, '');
    for (const name of ['localToWorld', 'worldToLocal', 'rand', 'pdfHemisphereCosineWeighted', 'sampleHemisphereCosineWeighted', 'safe_normalize', 'FresnelDielectricReflectance', 'ggx_ndf_eval', 'ggx_ndf_sample', 'ggx_lambda', 'ggx_G1', 'ggx_G2', 'evaluateBsdf', 'sampleBsdf']) {
        const pattern = new RegExp(`(?:vec3|float)\\s+${name}\\s*\\([^)]*\\)\\s*\\{`, 'g');
        let match;
        while ((match = pattern.exec(result)) !== null) {
            const open = result.indexOf('{', match.index);
            let depth = 0;
            let close = -1;
            for (let index = open; index < result.length; index++) {
                if (result[index] === '{') depth++;
                else if (result[index] === '}' && --depth === 0) { close = index; break; }
            }
            if (close < 0) break;
            result = result.slice(0, match.index) + result.slice(close + 1);
            pattern.lastIndex = match.index;
        }
    }
    return result;
}

function prepareRasterHostSource(source) {
    let result = source
        .replace(/^\s*#define\s+material\s+surfaceshader\s*\r?\n/gm, '')
        .replace(/^\s*out\s+vec4\s+out1\s*;\s*\r?\n/gm, 'vec4 mtlxRasterOut;\n')
        .replace(/\bout1\b/g, 'mtlxRasterOut')
        .replace(/^\s*in\s+(\w+)\s+(\w+)\s*;\s*$/gm, '$1 $2;');
    result = result.replace(/\bvoid\s+main\s*\(\s*\)\s*\{/, 'vec4 mtlxRasterMain() {');
    const functionStart = result.indexOf('vec4 mtlxRasterMain()');
    if (functionStart >= 0) {
        const open = result.indexOf('{', functionStart);
        let depth = 0;
        for (let index = open; index < result.length; index++) {
            if (result[index] === '{') depth++;
            else if (result[index] === '}' && --depth === 0) {
                result = result.slice(0, index) + '\n    return mtlxRasterOut;\n}' + result.slice(index + 1);
                break;
            }
        }
    }
    return result;
}

function assembleFinalRenderSource(route, hostSource) {
    const sources = routeSources[route];
    let common = readFileSync(sources.common, 'utf8').replace(/^\s*#include\s+.*$/gm, '');
    let integrator = readFileSync(sources.integrator, 'utf8').replace(/^\s*#include\s+.*$/gm, '');
    let bvh = bvhShaderSource;
    if (route === 'pathtracer' || route === 'rasterizer') {
        common = common
            .replace(/sampler2D nodes, sampler2D indices, sampler2D positions, vec3 rayOrigin/g, 'texture2D nodes, sampler nodesSampler, texture2D indices, sampler indicesSampler, texture2D positions, sampler positionsSampler, vec3 rayOrigin')
            .replace(/nativeBvhIntersectFirstHitWithinDistance\(nodes, indices, positions,/g, 'nativeBvhIntersectFirstHitWithinDistance(nodes, nodesSampler, indices, indicesSampler, positions, positionsSampler,')
            .replace(/bvhIntersectFirstHitWithinDistance\(bvh_surface_nodes,\s*bvh_surface_indices,\s*bvh_surface_positions,/g, 'bvhIntersectFirstHitWithinDistance(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler,')
            .replace(/bvhIntersectFirstHitWithinDistance\(\s*sampler2D\((\w+)_texture,\s*(\w+)_sampler\),\s*sampler2D\((\w+)_texture,\s*(\w+)_sampler\),\s*sampler2D\((\w+)_texture,\s*(\w+)_sampler\),/g, 'bvhIntersectFirstHitWithinDistance($1_texture, $2_sampler, $3_texture, $4_sampler, $5_texture, $6_sampler,');
        integrator = integrator
            .replace(/sampler2D nodes, sampler2D indices, sampler2D positions, vec3 rayOrigin/g, 'texture2D nodes, sampler nodesSampler, texture2D indices, sampler indicesSampler, texture2D positions, sampler positionsSampler, vec3 rayOrigin')
            .replace(/nativeBvhIntersectFirstHitWithinDistance\(nodes, indices, positions,/g, 'nativeBvhIntersectFirstHitWithinDistance(nodes, nodesSampler, indices, indicesSampler, positions, positionsSampler,')
            .replace(/bvhIntersectFirstHitWithinDistance\(\s*bvh_surface_nodes,\s*bvh_surface_indices,\s*bvh_surface_positions,/g, 'bvhIntersectFirstHitWithinDistance(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler,');
        bvh = bvh
            .replace(/nativeBvhTexelFetch1D\(sampler2D texture_, int index\)/g, 'nativeBvhTexelFetch1D(texture2D texture_, sampler sampler_, int index)')
            .replace(/textureSize\(texture_,/g, 'textureSize(sampler2D(texture_, sampler_),')
            .replace(/texelFetch\(texture_,/g, 'texelFetch(sampler2D(texture_, sampler_),')
            .replace(/vec4 textureSampleBarycoord\(sampler2D texture_, vec3 barycoord,/g, 'vec4 textureSampleBarycoord(texture2D texture_, sampler sampler_, vec3 barycoord,')
            .replace(/nativeBvhTexelFetch1D\(texture_,/g, 'nativeBvhTexelFetch1D(texture_, sampler_,')
            .replace(/nativeBvhIntersectFirstHitWithinDistance\(\s*sampler2D nodes, sampler2D indices, sampler2D positions,/g, 'nativeBvhIntersectFirstHitWithinDistance(texture2D nodes, sampler nodesSampler, texture2D indices, sampler indicesSampler, texture2D positions, sampler positionsSampler,')
            .replace(/nativeBvhTexelFetch1D\(nodes,/g, 'nativeBvhTexelFetch1D(nodes, nodesSampler,')
            .replace(/nativeBvhTexelFetch1D\(indices,/g, 'nativeBvhTexelFetch1D(indices, indicesSampler,')
            .replace(/nativeBvhTexelFetch1D\(positions,/g, 'nativeBvhTexelFetch1D(positions, positionsSampler,');
    }
    const bridge = sources.bridge ? readFileSync(sources.bridge, 'utf8') : '';
    const generated = route === 'pathtracer'
        ? stripGeneratedHostPrimitives(hostSource)
        : prepareRasterHostSource(hostSource.replace(rasterHostPreamble, ''));
    const rasterBridge = route === 'rasterizer' ? `
void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed) {}
bool mtlx_openpbr_is_opaque() { return true; }
bool mtlx_openpbr_is_thinwalled() { return false; }
vec3 mtlx_openpbr_raster_color(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL) {
    return mtlxRasterMain().rgb;
}
` : '';
    const envmapHost = '#define MAX_MTLX_LIGHTS 1\nuniform samplerCube envMap;\nuniform sampler2D envMapLatLong;\nuniform sampler2D envMapIrradiance;\nmat4 mtlxEnvMatrix(){float a=1.57079632679;float c=cos(a),s=sin(a);return mat4(c,0.,-s,0.,0.,-1.,0.,0.,s,0.,c,0.,0.,0.,0.,1.);}\n#define u_envMatrix mtlxEnvMatrix()\n#define u_envRadiance envMapLatLong\n#define u_envIrradiance envMapIrradiance\n#define u_envLightIntensity skyPower\n#define u_envRadianceMips 1\n#define u_envRadianceSamples 1\n#define u_refractionTwoSided false\n#define u_numActiveLightSources mtlxLightCount\n#define u_viewPosition cameraWorldMatrix[3].xyz\n';
    return [envmapHost, bvh, common, generated, bridge, rasterBridge, integrator].filter(Boolean).join('\n\n');
}

function adaptGeneratedGlslForVulkan(source) {
    source = source
        .replace(/vec3\s+mx_latlong_map_lookup\(vec3 dir, mat4 transform, float lod,\s*sampler2D tex_sampler\)\s*\{([\s\S]*?)\n\}/, (_, body) => {
            const bodyWithRadiance = body.replace(/textureLod\(tex_sampler,\s*uv,\s*lod\)/g, 'texture(envMapLatLong, uv)').replace(/texture\(tex_sampler,/g, 'texture(envMapLatLong,');
            const bodyWithIrradiance = body.replace(/textureLod\(tex_sampler,\s*uv,\s*lod\)/g, 'texture(envMapIrradiance, uv)').replace(/texture\(tex_sampler,/g, 'texture(envMapIrradiance,');
            return `vec3 mx_latlong_map_lookup_radiance(vec3 dir, mat4 transform, float lod) {${bodyWithRadiance}\n}\nvec3 mx_latlong_map_lookup_irradiance(vec3 dir, mat4 transform, float lod) {${bodyWithIrradiance}\n}`;
        })
        .replace(/mx_latlong_map_lookup\(([^;]*?),\s*u_envIrradiance\)/g, 'mx_latlong_map_lookup_irradiance($1)')
        .replace(/mx_latlong_map_lookup\(([^;]*?),\s*u_envRadiance\)/g, 'mx_latlong_map_lookup_radiance($1)')
        .replace(/return\s+textureLod\(tex_sampler,\s*uv,\s*lod\)\.rgb\s*;/g, 'return texture(tex_sampler, uv).rgb;')
        .replace(/uniform\s+LightData\s+u_lightData\[([^\]]+)\]\s*;/g, 'uniform int u_lightData[$1];')
        .replace(/sampleLightSource\(LightData\s+light\s*,/g, 'sampleLightSource(int light,');
    const blockMembers = [];
    const opaqueUniforms = [];
    const combinedSamplers = [];
    const retainedLines = [];
    const structTypes = new Set();
    let binding = 16;
    for (const line of source.split('\n')) {
        const structArray = line.trim().match(/^uniform\s+([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\[([^\]]+)\]\s*;$/);
        if (structArray) {
            const declarationlessSource = source.replace(line, '');
            const uses = (declarationlessSource.match(new RegExp(`\\b${structArray[2]}\\b`, 'g')) || []).length;
            if (uses > 0) {
                structTypes.add(structArray[1]);
                blockMembers.push(`    ${structArray[1]} ${structArray[2]}[${structArray[3]}];`);
            }
            continue;
        }
        const tokens = line.trim().replace(/;\s*$/, '').split(/\s+/);
        if (tokens.length === 3 && tokens[0] === 'uniform' && /^[A-Za-z_]\w*$/.test(tokens[1]) && /^[A-Za-z_]\w*$/.test(tokens[2])) {
            const [, type, name] = tokens;
            if (/^(?:sampler|image|subpassInput)/.test(type)) {
                if (type === 'sampler2D' || type === 'samplerCube') {
                    const textureName = `${name}_texture`;
                    const samplerName = `${name}_sampler`;
                    const textureType = type === 'samplerCube' ? 'textureCube' : 'texture2D';
                    opaqueUniforms.push(`layout(set = 0, binding = ${binding++}) uniform ${textureType} ${textureName};`);
                    opaqueUniforms.push(`layout(set = 0, binding = ${binding++}) uniform sampler ${samplerName};`);
                    combinedSamplers.push({ name, textureName, samplerName, constructor: type === 'samplerCube' ? 'samplerCube' : 'sampler2D' });
                } else {
                    opaqueUniforms.push(`layout(set = 0, binding = ${binding++}) uniform ${type} ${name};`);
                }
            } else {
                blockMembers.push(`    ${type} ${name};`);
            }
            continue;
        }
        retainedLines.push(line);
    }
    const declarations = [];
    for (const type of structTypes) {
        const definition = source.match(new RegExp(`struct\\s+${type}\\s*\\{[\\s\\S]*?\\}\\s*;`));
        if (definition) declarations.push(definition[0]);
    }
    if (blockMembers.length > 0) {
        declarations.push('layout(set = 0, binding = 15, std140) uniform MtlxMaterialUniforms {');
        declarations.push(...blockMembers, '};');
    }
    declarations.push(...opaqueUniforms);
    let body = retainedLines.map((line, index) => {
        const tokens = line.trim().replace(/;\s*$/, '').split(/\s+/);
        if (tokens.length === 3 && tokens[0] === 'in' && /^[A-Za-z_]\w*$/.test(tokens[1]) && /^[A-Za-z_]\w*$/.test(tokens[2])) {
            return `layout(location = ${index}) in ${tokens[1]} ${tokens[2]};`;
        }
        if (tokens.length === 3 && tokens[0] === 'varying' && /^[A-Za-z_]\w*$/.test(tokens[1]) && /^[A-Za-z_]\w*$/.test(tokens[2])) {
            return `layout(location = ${index}) in ${tokens[1]} ${tokens[2]};`;
        }
        if (tokens.length === 3 && tokens[0] === 'out' && /^[A-Za-z_]\w*$/.test(tokens[1]) && /^[A-Za-z_]\w*$/.test(tokens[2])) {
            return `layout(location = 1) out ${tokens[1]} ${tokens[2]};`;
        }
        return line;
    }).join('\n');
    for (const { name, textureName, samplerName, constructor } of combinedSamplers) {
        body = body.split('\n').map(line => line.trimStart().startsWith('#')
            ? line
            : line.replace(new RegExp(`\\b${name}\\b`, 'g'), `${constructor}(${textureName}, ${samplerName})`)).join('\n');
    }
    body = body.replace(/textureSampleBarycoord\(sampler2D\((\w+)_texture,\s*(\w+)_sampler\),/g, 'textureSampleBarycoord($1_texture, $2_sampler,');
    for (const type of structTypes) {
        body = body.replace(new RegExp(`struct\\s+${type}\\s*\\{[\\s\\S]*?\\}\\s*;`), '');
    }
    if (!/\bvoid\s+main\s*\(/.test(body)) body += '\nvoid main() {}\n';
    return `${vulkanPreamble}${declarations.join('\n')}\n${body}`;
}

for (const [id, materialPath] of selectedFixtures) {
    const fixtureRoot = resolve(outputRoot, id);
    mkdirSync(fixtureRoot, { recursive: true });
    for (const [route, Host] of selectedRoutes) {
        const result = { id, route, material: materialPath, status: 'failed' };
        const sourcePath = resolve(root, materialPath);
        const glslPath = resolve(fixtureRoot, `${route}.frag.glsl`);
        const spvPath = resolve(fixtureRoot, `${route}.frag.spv`);
        const logPath = resolve(fixtureRoot, `${route}.glslang.log`);
        try {
            if (!existsSync(sourcePath)) throw new Error(`fixture_missing: ${materialPath}`);
            const generator = Host.create();
            const context = new mx.GenContext(generator);
            const document = mx.createDocument();
            document.importLibrary(mx.loadStandardLibraries(context));
            await mx.readFromXmlString(document, readFileSync(sourcePath, 'utf8'), '');
            const element = mx.findRenderableElement(document);
            if (!element) throw new Error('renderable_missing');
            const shader = generator.generate(element.getNamePath(), element, context);
            const generated = shader.getSourceCode('pixel') || '';
            if (!generated.trim()) throw new Error('generated_glsl_empty');
            const normalized = generated
                .replace(/^\s*#version[^\n]*\n/gm, '')
                .replace(/^\s*precision[^\n]*\n/gm, '');
            const hostSource = route === 'rasterizer' ? `${rasterHostPreamble}${normalized}` : normalized;
            const finalRenderSource = assembleFinalRenderSource(route, hostSource);
            const source = adaptGeneratedGlslForVulkan(finalRenderSource);
            writeFileSync(glslPath, source, 'utf8');
            const compileResult = compile(glslPath, spvPath, logPath);
            Object.assign(result, compileResult, { glsl: glslPath, log: logPath, sourceLength: source.length });
            shader.delete?.();
            element.delete?.();
            context.delete?.();
            document.delete?.();
        } catch (error) {
            result.error = error?.message || String(error);
            writeFileSync(logPath, result.error, 'utf8');
        }
        results.push(result);
        console.log(`${route}/${id}: ${result.status}${result.error ? ` - ${result.error.split('\n')[0]}` : ''}`);
    }
}

const report = {
    version: 1,
    runtimeRoot,
    outputRoot,
    glslang: 'tools/compile-glsl-to-spirv.mjs',
    fixtures: results,
};
writeFileSync(resolve(outputRoot, 'report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
process.exitCode = results.some(result => result.status !== 'compiled') ? 1 : 0;
