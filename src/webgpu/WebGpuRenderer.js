import { createWebGpuSceneBuffers } from './sceneBuffers.js';
import { BVH_TRAVERSAL_WGSL } from './bvhTraversal.wgsl.js';
import { INTEGRATOR_WGSL } from './integrator.wgsl.js';
import { REQUIRED_ADAPTER_LIMITS, validateAdapterLimits, validateMaterialTextureLimits } from './adapterLimits.js';
import { assembleWgslModules, compileWgslModule, createMaterialWgslBridge } from './wgslModuleAssembler.js';

const COMPUTE_SHADER = /* wgsl */ `
struct FrameUniforms { width: u32, height: u32, frameIndex: u32, debugMode: u32, nodeCount: u32, triangleCount: u32, lightCount: u32, _padding: u32 }
struct CameraUniforms { worldMatrix: mat4x4<f32>, inverseProjectionMatrix: mat4x4<f32> }
struct LightingUniforms { sunDirection: vec4<f32>, sunColorPower: vec4<f32>, skyColorPower: vec4<f32> }
struct Light { position: vec4<f32>, direction: vec4<f32>, colorIntensity: vec4<f32>, cone: vec4<f32>, edgeU: vec4<f32>, edgeV: vec4<f32> }
@group(0) @binding(0) var outputTexture: texture_storage_2d<rgba16float, write>;
@group(0) @binding(1) var<uniform> frame: FrameUniforms;
@group(0) @binding(2) var<storage, read> bvhNodes: array<BvhNode>;
@group(0) @binding(3) var<storage, read> bvhIndices: array<TriangleIndices>;
@group(0) @binding(4) var<storage, read> bvhPositions: array<vec4<f32>>;
@group(0) @binding(5) var<storage, read_write> bvhStackOverflow: atomic<u32>;
@group(0) @binding(6) var<uniform> camera: CameraUniforms;
@group(0) @binding(7) var previousAccumulation: texture_2d<f32>;
@group(0) @binding(8) var groundTexture: texture_2d<f32>;
@group(0) @binding(9) var groundSampler: sampler;
@group(0) @binding(10) var<storage, read> lights: array<Light>;
@group(0) @binding(11) var<uniform> lighting: LightingUniforms;
@group(0) @binding(12) var environmentTexture: texture_2d<f32>;
@group(0) @binding(13) var environmentSampler: sampler;
@group(0) @binding(14) var<storage, read> bvhNormals: array<vec4<f32>>;

fn cameraRay(uv: vec2<f32>) -> vec3<f32> {
    let ndc = uv * 2.0 - vec2<f32>(1.0, 1.0);
    let origin = (camera.worldMatrix * vec4<f32>(0.0, 0.0, 0.0, 1.0)).xyz;
    var viewPoint = camera.inverseProjectionMatrix * vec4<f32>(ndc, 0.5, 1.0);
    viewPoint /= viewPoint.w;
    return normalize((camera.worldMatrix * viewPoint).xyz - origin);
}

fn diagnosticColor(hit: BvhHit, uv: vec2<f32>) -> vec3<f32> {
    if (frame.debugMode == 5u) {
        let previewPosition = vec3<f32>((uv.x - 0.5) * 100.0, 0.01, (0.5 - uv.y) * 100.0);
        return groundAlbedo(previewPosition);
    }
    if (!hit.found) { return vec3<f32>(0.015, 0.025, 0.05); }
    if (frame.debugMode == 1u) { return vec3<f32>(hit.distance * 0.05); }
    if (frame.debugMode == 2u) { return hit.normal * 0.5 + vec3<f32>(0.5); }
    if (frame.debugMode == 3u) { return vec3<f32>(hit.barycentric.xy, 0.0); }
    if (frame.debugMode == 4u) { return vec3<f32>(f32(hit.triangle.x % 11u) / 10.0, f32(hit.triangle.y % 11u) / 10.0, f32(hit.triangle.z % 11u) / 10.0); }
    if (frame.debugMode == 6u) { return vec3<f32>(cosinePdf(max(hit.normal.y, 0.0)) * 3.14159265359); }
    if (frame.debugMode == 7u) { return vec3<f32>(min(f32(frame.frameIndex) / 8.0, 1.0)); }
    if (frame.debugMode == 8u) { return clamp(lighting.sunColorPower.xyz * lighting.sunColorPower.w * max(hit.normal.y, 0.0), vec3<f32>(0.0), vec3<f32>(1.0)); }
    return vec3<f32>(uv, 0.18);
}

fn evaluateDirectLight(position: vec3<f32>, normal: vec3<f32>) -> vec3<f32> {
    var result = lighting.skyColorPower.xyz * lighting.skyColorPower.w;
    let sunDirection = safeNormalize(-lighting.sunDirection.xyz);
    result += lighting.sunColorPower.xyz * lighting.sunColorPower.w * max(dot(normal, sunDirection), 0.0);
    if (frame.lightCount == 0u) { return result; }
    let selectionPdf = 1.0 / f32(frame.lightCount);
    for (var index = 0u; index < frame.lightCount; index += 1u) {
        let light = lights[index];
        let lightType = u32(light.direction.w + 0.5);
        var direction = vec3<f32>(0.0, 1.0, 0.0);
        var attenuation = 1.0;
        if (lightType == 1u) {
            direction = safeNormalize(-light.direction.xyz);
        } else {
            var lightPoint = light.position.xyz;
            if (lightType == 3u) { lightPoint += 0.5 * (light.edgeU.xyz + light.edgeV.xyz); }
            let toLight = lightPoint - position;
            let lightDistance = max(length(toLight), 1.0e-5);
            direction = toLight / lightDistance;
            attenuation = 1.0 / max(pow(lightDistance + 1.0, light.position.w), 1.0e-5);
            if (lightType == 3u) { attenuation *= length(cross(light.edgeU.xyz, light.edgeV.xyz)) / max(lightDistance * lightDistance, 1.0e-5); }
            if (lightType == 2u) { attenuation *= smoothstep(light.cone.y, light.cone.x, dot(direction, -safeNormalize(light.direction.xyz))); }
        }
        result += light.colorIntensity.xyz * light.colorIntensity.w * max(dot(normal, direction), 0.0) * attenuation / max(selectionPdf, 1.0e-5);
    }
    return result;
}

fn environmentRadiance(direction: vec3<f32>) -> vec3<f32> {
    let d = safeNormalize(direction);
    let uv = vec2<f32>((atan2(d.z, d.x) + 3.14159265359) / 6.28318530718, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
    return pow(textureSampleLevel(environmentTexture, environmentSampler, uv, 0.0).rgb, vec3<f32>(2.2)) * lighting.skyColorPower.xyz * lighting.skyColorPower.w;
}

fn groundHit(origin: vec3<f32>, direction: vec3<f32>) -> f32 {
    if (abs(direction.y) < 1.0e-6) { return 1.0e20; }
    let groundDistanceLocal = (0.01 - origin.y) / direction.y;
    return select(1.0e20, groundDistanceLocal, groundDistanceLocal > 0.0);
}

fn groundAlbedo(position: vec3<f32>) -> vec3<f32> {
    let uv = vec2<f32>(position.x, -position.z) / 200.0 * 2.0 + vec2<f32>(0.5);
    let encoded = textureSampleLevel(groundTexture, groundSampler, uv, 0.0).rgb;
    return pow(encoded, vec3<f32>(2.2));
}

fn lightLoopDiagnostic() -> vec3<f32> {
    var result = vec3<f32>(0.0);
    if (frame.lightCount > 0u) {
        result = vec3<f32>(1.0, 0.0, 0.0);
        for (var index = 0u; index < frame.lightCount; index += 1u) {
            let light = lights[index];
            if (light.colorIntensity.w > 0.0) { result += vec3<f32>(0.0, 1.0, 0.0); }
        }
    }
    return result;
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    if (id.x >= frame.width || id.y >= frame.height) { return; }
    if (frame.debugMode == 11u) {
        textureStore(outputTexture, vec2<i32>(id.xy), vec4<f32>(1.0, 0.0, 0.0, 1.0));
        return;
    }
    let uv = vec2<f32>(
        f32(id.x) / max(1.0, f32(frame.width - 1u)),
        1.0 - f32(id.y) / max(1.0, f32(frame.height - 1u)));
    let cameraPosition = (camera.worldMatrix * vec4<f32>(0.0, 0.0, 0.0, 1.0)).xyz;
    var rayDirection = cameraRay(uv);
    if (frame.debugMode == 12u) { rayDirection = safeNormalize(-cameraPosition); }
    if (frame.debugMode == 13u) { rayDirection = safeNormalize(vec3<f32>(0.0, 3.74, 0.0) - cameraPosition); }
    if (frame.debugMode == 15u || frame.debugMode == 16u || frame.debugMode == 17u || frame.debugMode == 18u) { rayDirection = safeNormalize(vec3<f32>(-7.65328, -0.239299, -4.41851) - cameraPosition); }
    var hit = bvhTrace(cameraPosition, rayDirection, 1.0e20);
    // Geometric normal from cross(edge0, edge1) depends on triangle winding and can
    // face away from the camera; flip it to always face the incoming ray so Lambert
    // shading and direct-light contributions are not silently zeroed by the
    // visibility check in evaluateLambert().
    if (hit.found && dot(hit.normal, rayDirection) > 0.0) { hit.normal = -hit.normal; }
    let groundDistance = groundHit(cameraPosition, rayDirection);
    let useGround = groundDistance < hit.distance;
    let groundPosition = cameraPosition + rayDirection * groundDistance;
    let hitPosition = cameraPosition + rayDirection * hit.distance;
    let basis = makeBasis(hit.normal);
    let viewDirection = safeNormalize(-rayDirection);
    var sampleColor = diagnosticColor(hit, uv);
    if (frame.debugMode == 16u) {
        let p0 = bvhPositions[45u].xyz;
        let p1 = bvhPositions[46u].xyz;
        let p2 = bvhPositions[47u].xyz;
        let e0 = p1 - p0;
        let e1 = p2 - p0;
        let pvec = cross(rayDirection, e1);
        let det = dot(e0, pvec);
        let invDet = 1.0 / det;
        let tvec = cameraPosition - p0;
        let qvec = cross(tvec, e0);
        let u = dot(tvec, pvec) * invDet;
        let v = dot(rayDirection, qvec) * invDet;
        let distance = dot(e1, qvec) * invDet;
        let directHit = abs(det) >= 1.0e-8 && u >= 0.0 && v >= 0.0 && u + v <= 1.0 && distance > 0.0;
        sampleColor = select(vec3<f32>(0.0, 0.0, 1.0), vec3<f32>(1.0, 0.0, 0.0), directHit);
    }
    if (frame.debugMode == 14u) {
        let rootDistance = bvhAabbIntersect(bvhNodes[0].minimum.xyz, bvhNodes[0].maximum.xyz, cameraPosition, rayDirection);
        sampleColor = select(vec3<f32>(0.0, 0.0, 1.0), vec3<f32>(1.0, 0.0, 0.0), rootDistance < 1.0e19);
    }
    if (frame.debugMode == 17u) {
        let leafDistance = bvhAabbIntersect(bvhNodes[12u].minimum.xyz, bvhNodes[12u].maximum.xyz, cameraPosition, rayDirection);
        sampleColor = select(vec3<f32>(0.0, 0.0, 1.0), vec3<f32>(1.0, 0.0, 0.0), leafDistance < 1.0e19);
    }
    if (frame.debugMode == 10u) { sampleColor = lightLoopDiagnostic(); }
    if (frame.debugMode == 9u || frame.debugMode == 12u || frame.debugMode == 13u || frame.debugMode == 15u || frame.debugMode == 18u) {
        if (hit.found) { sampleColor = vec3<f32>(5.0, 0.0, 0.0); }
        else if (useGround) { sampleColor = vec3<f32>(0.0, 0.0, 5.0); }
        else { sampleColor = vec3<f32>(0.0, 5.0, 0.0); }
    }
    if (frame.debugMode == 0u) {
        if (useGround) {
            let groundNormal = vec3<f32>(0.0, 1.0, 0.0);
            sampleColor = evaluateLambert(groundAlbedo(groundPosition), groundNormal, viewDirection, viewDirection) * evaluateDirectLight(groundPosition, groundNormal);
        } else if (hit.found) {
            sampleColor = evaluateLambert(vec3<f32>(0.72, 0.76, 0.82), basis.normal, viewDirection, viewDirection) * evaluateDirectLight(hitPosition, basis.normal);
        } else {
            sampleColor = environmentRadiance(rayDirection);
        }
    }
    let coordinate = vec2<i32>(id.xy);
    var previous = vec3<f32>(0.0);
    if (frame.frameIndex != 0u) { previous = textureLoad(previousAccumulation, coordinate, 0).rgb; }
    let weight = 1.0 / f32(frame.frameIndex + 1u);
    textureStore(outputTexture, coordinate, vec4<f32>(mix(previous, sampleColor, weight), 1.0));
}
${BVH_TRAVERSAL_WGSL}
${INTEGRATOR_WGSL}`;

const MATERIAL_HOST_SUPPORT = /* wgsl */ `
fn mtlxHostSafeNormalize(value: vec3<f32>) -> vec3<f32> {
    return value / max(length(value), 1.0e-6);
}

fn mtlxHostMakeBasis(normal: vec3<f32>, barycentric: vec3<f32>) -> Basis {
    let n = mtlxHostSafeNormalize(normal);
    let tangent = select(vec3<f32>(0.0, n.z, -n.y), vec3<f32>(n.z, 0.0, -n.x), abs(n.z) < abs(n.x));
    let t = mtlxHostSafeNormalize(tangent);
    return Basis(n, t, cross(n, t), barycentric, vec2<f32>(0.0));
}

fn mtlxHostWorldToLocal(value: vec3<f32>, basis: Basis) -> vec3<f32> {
    return vec3<f32>(dot(value, basis.tW), dot(value, basis.bW), dot(value, basis.nW));
}

fn mtlxHostLocalToWorld(value: vec3<f32>, basis: Basis) -> vec3<f32> {
    return basis.tW * value.x + basis.bW * value.y + basis.nW * value.z;
}

fn mtlxHostCosinePdf(cosine: f32) -> f32 {
    return max(cosine, 0.0) * 0.31830988618;
}

fn mtlxHostEvaluateLambert(albedo: vec3<f32>, normal: vec3<f32>, incoming: vec3<f32>, outgoing: vec3<f32>) -> vec3<f32> {
    if (dot(normal, incoming) <= 0.0 || dot(normal, outgoing) <= 0.0) { return vec3<f32>(0.0); }
    return albedo * 0.31830988618;
}`;

function createMaterialComputeHostShader() {
    const objectLambert = 'sampleColor = mtlxHostEvaluateLambert(vec3<f32>(0.72, 0.76, 0.82), basis.nW, viewDirection, viewDirection) * evaluateDirectLight(hitPosition, basis.nW);';
    const objectMaterial = `let localViewDirection = mtlxHostWorldToLocal(viewDirection, basis);
            let materialEvaluation = mtlxGenEvaluateBsdf(hitPosition, basis, localViewDirection, localViewDirection);
            let materialSeed = id.x + id.y * frame.width + frame.frameIndex * frame.width * frame.height + 1u;
            let materialSample = mtlxGenSampleBsdf(hitPosition, basis, localViewDirection, materialSeed);
            let sampledWorldDirection = mtlxHostSafeNormalize(mtlxHostLocalToWorld(materialSample.direction, basis));
            let sampledThroughput = materialSample.response * abs(materialSample.direction.z) / max(materialSample.pdf, 1.0e-6);
            sampleColor = materialEvaluation.response * evaluateDirectLight(hitPosition, basis.nW) + sampledThroughput * environmentRadiance(sampledWorldDirection);`;
    return COMPUTE_SHADER
        .replace(INTEGRATOR_WGSL, MATERIAL_HOST_SUPPORT)
        .replaceAll('safeNormalize', 'mtlxHostSafeNormalize')
        .replaceAll('makeBasis(hit.normal)', 'mtlxHostMakeBasis(hit.normal, hit.barycentric)')
        .replaceAll('cosinePdf', 'mtlxHostCosinePdf')
        .replaceAll('evaluateLambert', 'mtlxHostEvaluateLambert')
        .replaceAll('basis.normal', 'basis.nW')
        .replace(objectLambert, objectMaterial);
}

const PRESENT_SHADER = /* wgsl */ `
@group(0) @binding(0) var sourceTexture: texture_2d<f32>;
struct VertexOutput { @builtin(position) position: vec4<f32>, @location(0) uv: vec2<f32> }

@vertex
fn vertexMain(@builtin(vertex_index) index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 3>(vec2<f32>(-1.0, -3.0), vec2<f32>(3.0, 1.0), vec2<f32>(-1.0, 1.0));
    var output: VertexOutput;
    output.position = vec4<f32>(positions[index], 0.0, 1.0);
    output.uv = output.position.xy * vec2<f32>(0.5, -0.5) + vec2<f32>(0.5);
    return output;
}

@fragment
fn fragmentMain(input: VertexOutput) -> @location(0) vec4<f32> {
    let dimensions = textureDimensions(sourceTexture);
    let coordinate = vec2<i32>(clamp(input.uv * vec2<f32>(dimensions), vec2<f32>(0.0), vec2<f32>(dimensions - vec2<u32>(1u))));
    let color = textureLoad(sourceTexture, coordinate, 0).rgb;
    let mapped = color / (vec3<f32>(1.0) + color);
    return vec4<f32>(pow(mapped, vec3<f32>(1.0 / 2.2)), 1.0);
}`;

const LIGHT_READBACK_SHADER = /* wgsl */ `
struct Light { position: vec4<f32>, direction: vec4<f32>, colorIntensity: vec4<f32>, cone: vec4<f32>, edgeU: vec4<f32>, edgeV: vec4<f32> }
@group(0) @binding(0) var<storage, read> lights: array<Light>;
@group(0) @binding(1) var<storage, read_write> output: array<vec4<f32>>;

@compute @workgroup_size(1)
fn main() {
    let light = lights[0];
    output[0] = vec4<f32>(light.position.xyz, light.position.w);
    output[1] = vec4<f32>(light.direction.xyz, light.direction.w);
    output[2] = light.colorIntensity;
    output[3] = light.cone;
    output[4] = light.edgeU;
    output[5] = light.edgeV;
}
`;

export class WebGpuRenderer {
    constructor({ onStatus, onError } = {}) {
        this.onStatus = onStatus || (() => {});
        this.onError = onError || (() => {});
        this.canvas = document.createElement('canvas');
        this.canvas.id = 'openpbr-webgpu-canvas';
        this.canvas.style.cssText = 'position:absolute;top:0;left:0;z-index:1;display:none;';
        this.ready = false;
        this.destroyed = false;
        this.pendingBvh = null;
        this.pendingGroundTextureUrl = null;
        this.pendingLights = null;
        this.pendingEnvironmentUrl = null;
        this.pendingMaterialTextureManifest = null;
        this.pendingMaterialComputeModule = null;
        this.lightDiagnostics = null;
        this.lightReadbackPipeline = null;
        this.materialTextureResources = [];
        this.materialComputePipeline = null;
        this.materialComputeBindGroup = null;
        this.materialExpectedBindings = [];
    }

    async initialize() {
        if (!navigator.gpu) throw new Error('WebGPU is unavailable: navigator.gpu is not exposed by this browser.');
        this.destroyed = false;
        this.context = this.canvas.getContext('webgpu');
        console.log('[webgpu] initialize: requestAdapter');
        this.adapter = await navigator.gpu.requestAdapter();
        if (!this.context || !this.adapter) throw new Error('WebGPU adapter or canvas context creation failed.');
        validateAdapterLimits(this.adapter);
        console.log('[webgpu] initialize: requestDevice');
        this.device = await this.adapter.requestDevice({ requiredLimits: REQUIRED_ADAPTER_LIMITS });
        this.lastGpuError = null;
        this.device.addEventListener('uncapturederror', event => {
            this.lastGpuError = { message: event.error?.message || 'unknown GPU validation error', type: event.error?.constructor?.name || 'GPUError' };
            this.onError(this.lastGpuError.message);
        });
        this.device.lost.then(info => {
            // Our own destroy() calls device.destroy(), which resolves this promise
            // intentionally; do not report that expected teardown as a runtime error.
            if (this.destroyed) return;
            this.onError(`WebGPU device lost: ${info.message || info.reason || 'unknown reason'}`);
        });
        this.format = navigator.gpu.getPreferredCanvasFormat();
        this.context.configure({ device: this.device, format: this.format, alphaMode: 'opaque' });
        this.emptyNodeBuffer = this.device.createBuffer({ size: 48, usage: GPUBufferUsage.STORAGE });
        this.emptyIndexBuffer = this.device.createBuffer({ size: 16, usage: GPUBufferUsage.STORAGE });
        this.emptyPositionBuffer = this.device.createBuffer({ size: 16, usage: GPUBufferUsage.STORAGE });
        this.stackOverflowBuffer = this.device.createBuffer({ size: 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST | GPUBufferUsage.COPY_SRC });
        this.cameraBuffer = this.device.createBuffer({ size: 128, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
        this.lightingBuffer = this.device.createBuffer({ size: 48, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
        // Storage buffers that receive per-frame data via queue.writeBuffer() must
        // include COPY_DST; without this, the light array uploads can silently fail
        // even when frame.lightCount and the JS-side packing look correct.
        this.emptyLightsBuffer = this.device.createBuffer({ size: 96, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST });
        this.lightsBuffer = this.emptyLightsBuffer;
        this.groundTexture = this.device.createTexture({ size: [1, 1], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.writeTexture({ texture: this.groundTexture }, new Uint8Array([128, 128, 128, 255]), { bytesPerRow: 4, rowsPerImage: 1 }, [1, 1]);
        this.groundSampler = this.device.createSampler({ addressModeU: 'repeat', addressModeV: 'repeat', magFilter: 'linear', minFilter: 'linear' });
        this.environmentTexture = this.device.createTexture({ size: [1, 1], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.writeTexture({ texture: this.environmentTexture }, new Uint8Array([20, 30, 50, 255]), { bytesPerRow: 4, rowsPerImage: 1 }, [1, 1]);
        this.environmentSampler = this.device.createSampler({ addressModeU: 'repeat', addressModeV: 'clamp-to-edge', magFilter: 'linear', minFilter: 'linear' });
        this.environmentIrradianceTexture = this.device.createTexture({ size: [1, 1], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.writeTexture({ texture: this.environmentIrradianceTexture }, new Uint8Array([20, 30, 50, 255]), { bytesPerRow: 4, rowsPerImage: 1 }, [1, 1]);
        this.environmentIrradianceSampler = this.device.createSampler({ addressModeU: 'repeat', addressModeV: 'clamp-to-edge', magFilter: 'linear', minFilter: 'linear' });
        this.materialPrivateUniformBuffer = this.device.createBuffer({ size: 80, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
        const materialPrivateUniforms = new ArrayBuffer(80);
        const materialPrivateView = new DataView(materialPrivateUniforms);
        for (let index = 0; index < 4; index++) materialPrivateView.setFloat32(index * 20, 1, true);
        materialPrivateView.setFloat32(64, 1, true);
        materialPrivateView.setInt32(68, 1, true);
        materialPrivateView.setInt32(72, 16, true);
        materialPrivateView.setUint32(76, 0, true);
        this.device.queue.writeBuffer(this.materialPrivateUniformBuffer, 0, materialPrivateUniforms);
        this.environmentTextureInfo = { url: null, width: 1, height: 1, fallback: true };
        this.environmentIrradianceTextureInfo = { url: null, width: 1, height: 1, fallback: true };
        this.groundTextureInfo = { url: null, width: 1, height: 1, fallback: true };
        console.log('[webgpu] initialize: computePipeline');
        this.computePipeline = await this.createComputePipeline();
        console.log('[webgpu] initialize: presentPipeline');
        this.presentPipeline = await this.createPresentPipeline();
        this.ready = true;
        this.canvas.style.display = 'block';
        this.onStatus({ state: 'ready', adapter: this.adapter.info || null, format: this.format });
        if (this.pendingBvh) {
            const bvh = this.pendingBvh;
            this.pendingBvh = null;
            this.setSceneBvh(bvh);
        }
        if (this.pendingGroundTextureUrl) {
            const url = this.pendingGroundTextureUrl;
            this.pendingGroundTextureUrl = null;
            await this.setGroundTexture(url);
        }
        if (this.pendingLights) {
            const { lights, params } = this.pendingLights;
            this.pendingLights = null;
            this.setLights(lights, params);
        }
        if (this.pendingEnvironmentUrl) {
            const url = this.pendingEnvironmentUrl;
            this.pendingEnvironmentUrl = null;
            await this.setEnvironmentTexture(url);
        }
        if (this.pendingMaterialTextureManifest) {
            const manifest = this.pendingMaterialTextureManifest;
            this.pendingMaterialTextureManifest = null;
            await this.setMaterialTextureManifest(manifest);
        }
        if (this.pendingMaterialComputeModule) {
            const source = this.pendingMaterialComputeModule;
            this.pendingMaterialComputeModule = null;
            await this.setMaterialComputeModule(source);
        }
    }

    async createComputePipeline() {
        const { module } = await compileWgslModule(this.device, COMPUTE_SHADER, 'WebGPU compute shader');
        return this.withValidationScope(() => this.device.createComputePipeline({ layout: 'auto', compute: { module, entryPoint: 'main' } }));
    }

    async setMaterialComputeModule(source) {
        const pipelineStart = performance.now();
        if (!source || !source.trim()) {
            const error = new Error('MaterialX WGSL compute source is empty.');
            error.code = 'MTLX_WGSL_INVALID_SOURCE';
            throw error;
        }
        if (!this.device) {
            this.pendingMaterialComputeModule = source;
            return { pending: true };
        }

        // A fragment module from MaterialX is not a compute bridge. Require the
        // generated host contract before touching the live pipeline so a failed
        // material never leaves the renderer with a partially replaced layout.
        let assembled;
        try {
            const material = createMaterialWgslBridge(source);
            assembled = assembleWgslModules({
                prelude: createMaterialComputeHostShader(),
                material,
                requiredEntryPoints: ['main', 'mtlxGenEvaluateBsdf', 'mtlxGenSampleBsdf'],
            });
        } catch (error) {
            error.code = error.code || 'MTLX_WGSL_ASSEMBLY_INVALID';
            this.onError(error.message);
            throw error;
        }

        const { module } = await compileWgslModule(this.device, assembled.source, 'MaterialX compute shader');
        const pipeline = await this.withValidationScope(() => this.device.createComputePipelineAsync({
            layout: 'auto',
            compute: { module, entryPoint: 'main' },
        }));
        this.materialComputePipeline = pipeline;
        this.materialPipelineDurationMs = performance.now() - pipelineStart;
        this.materialComputeSource = assembled.source;
        this.materialComputeEntryPoints = assembled.entryPoints;
        this.materialExpectedBindings = [...assembled.source.matchAll(/@group\(0\)\s*@binding\((\d+)\)/g)].map(match => Number(match[1]));
        this.createBindGroups();
        if (typeof window !== 'undefined') window.__openpbrWebGpuMaterialPipeline = true;
        this.onStatus({ state: 'ready', materialComputePipeline: true, materialBindGroup: Boolean(this.materialComputeBindGroup), materialPipelineDurationMs: this.materialPipelineDurationMs, entryPoints: assembled.entryPoints });
        return { pending: false, entryPoints: assembled.entryPoints };
    }

    async createPresentPipeline() {
        const module = this.device.createShaderModule({ code: PRESENT_SHADER });
        const info = await module.getCompilationInfo();
        const errors = info.messages.filter(message => message.type === 'error');
        if (errors.length) throw new Error(errors.map(message => message.message).join('\n'));
        return this.withValidationScope(() => this.device.createRenderPipelineAsync({
            layout: 'auto', vertex: { module, entryPoint: 'vertexMain' },
            fragment: { module, entryPoint: 'fragmentMain', targets: [{ format: this.format }] },
            primitive: { topology: 'triangle-list' }
        }));
    }

    async withValidationScope(createResource, scope = 'validation') {
        this.device.pushErrorScope(scope);
        const resource = await createResource();
        const error = await this.device.popErrorScope();
        if (error) throw new Error(`WebGPU ${scope} error: ${error.message}`);
        return resource;
    }

    resize(width, height) {
        if (!this.ready || !Number.isInteger(width) || !Number.isInteger(height) || width < 1 || height < 1 || (width === this.width && height === this.height)) return;
        this.width = width;
        this.height = height;
        this.canvas.width = width;
        this.canvas.height = height;
        this.accumulationTextures?.forEach(texture => texture.destroy());
        this.frameBuffer?.destroy();
        this.device.pushErrorScope('out-of-memory');
        this.accumulationTextures = [0, 1].map(() => this.device.createTexture({ size: [width, height], format: 'rgba16float', usage: GPUTextureUsage.STORAGE_BINDING | GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_SRC }));
        this.device.popErrorScope().then(error => { if (error) this.onError(`WebGPU out-of-memory error while resizing to ${width}x${height}: ${error.message}`); });
        this.accumulationIndex = 0;
        this.frameBuffer = this.device.createBuffer({ size: 32, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
        this.createBindGroups();
    }

    createBindGroups() {
        const output = this.accumulationTextures[this.accumulationIndex];
        const previous = this.accumulationTextures[1 - this.accumulationIndex];
        const hostEntries = [
            { binding: 0, resource: output.createView() }, { binding: 1, resource: { buffer: this.frameBuffer } },
            { binding: 2, resource: { buffer: this.sceneBuffers?.nodes || this.emptyNodeBuffer } }, { binding: 3, resource: { buffer: this.sceneBuffers?.triangleIndices || this.emptyIndexBuffer } },
            { binding: 4, resource: { buffer: this.sceneBuffers?.positions || this.emptyPositionBuffer } }, { binding: 5, resource: { buffer: this.stackOverflowBuffer } },
            { binding: 6, resource: { buffer: this.cameraBuffer } }, { binding: 7, resource: previous.createView() },
            { binding: 8, resource: this.groundTexture.createView() }, { binding: 9, resource: this.groundSampler },
            { binding: 10, resource: { buffer: this.lightsBuffer } }, { binding: 11, resource: { buffer: this.lightingBuffer } },
            { binding: 12, resource: this.environmentTexture.createView() }, { binding: 13, resource: this.environmentSampler },
            { binding: 14, resource: { buffer: this.sceneBuffers?.normals || this.emptyPositionBuffer } }
        ];
        this.computeBindGroup = this.device.createBindGroup({ layout: this.computePipeline.getBindGroupLayout(0), entries: hostEntries });
        this.materialComputeBindGroup = null;
        if (typeof window !== 'undefined') window.__openpbrWebGpuMaterialBindGroup = false;
        if (this.materialComputePipeline && this.materialPrivateUniformBuffer) {
            const materialEntries = [
                { binding: 15, resource: { buffer: this.materialPrivateUniformBuffer } },
                { binding: 16, resource: this.environmentTexture.createView() },
                { binding: 17, resource: this.environmentSampler },
                { binding: 18, resource: this.environmentIrradianceTexture.createView() },
                { binding: 19, resource: this.environmentIrradianceSampler },
                ...this.materialTextureResources.flatMap(resource => [
                    { binding: resource.textureBinding, resource: resource.texture.createView() },
                    { binding: resource.samplerBinding, resource: resource.samplerResource },
                ]),
            ];
            const suppliedBindings = new Set([...hostEntries, ...materialEntries].map(entry => entry.binding));
            if (this.materialExpectedBindings.every(binding => suppliedBindings.has(binding))) {
                const expectedBindings = new Set(this.materialExpectedBindings);
                this.materialComputeBindGroup = this.device.createBindGroup({
                    layout: this.materialComputePipeline.getBindGroupLayout(0),
                    entries: [...hostEntries, ...materialEntries].filter(entry => expectedBindings.has(entry.binding)),
                });
                if (typeof window !== 'undefined') window.__openpbrWebGpuMaterialBindGroup = true;
            }
        }
        this.presentBindGroup = this.device.createBindGroup({ layout: this.presentPipeline.getBindGroupLayout(0), entries: [{ binding: 0, resource: output.createView() }] });
    }

    async setGroundTexture(url) {
        if (!url) return;
        if (!this.device) {
            this.pendingGroundTextureUrl = url;
            return;
        }
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Ground texture fetch failed: ${response.status} ${url}`);
        const bitmap = await createImageBitmap(await response.blob());
        const texture = this.device.createTexture({ size: [bitmap.width, bitmap.height], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.copyExternalImageToTexture({ source: bitmap, flipY: true }, { texture }, [bitmap.width, bitmap.height]);
        this.groundTexture?.destroy();
        this.groundTexture = texture;
        this.groundTextureInfo = { url, width: bitmap.width, height: bitmap.height, fallback: false };
        bitmap.close();
        this.onStatus({ state: 'ready', groundTexture: this.groundTextureInfo });
        if (this.accumulationTextures) this.createBindGroups();
    }

    async setEnvironmentTexture(url) {
        if (!url) return;
        if (/\.hdr(?:$|[?#])/i.test(url)) {
            this.environmentTextureInfo = { url, width: 1, height: 1, fallback: true, unsupported: 'hdr-native-upload-not-yet-implemented' };
            this.onStatus({ state: 'ready', environmentTexture: this.environmentTextureInfo });
            if (this.accumulationTextures) this.createBindGroups();
            return;
        }
        if (!this.device) { this.pendingEnvironmentUrl = url; return; }
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Environment texture fetch failed: ${response.status} ${url}`);
        const bitmap = await createImageBitmap(await response.blob());
        const texture = this.device.createTexture({ size: [bitmap.width, bitmap.height], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.copyExternalImageToTexture({ source: bitmap }, { texture }, [bitmap.width, bitmap.height]);
        this.environmentTexture?.destroy();
        this.environmentTexture = texture;
        this.environmentTextureInfo = { url, width: bitmap.width, height: bitmap.height, fallback: false };
        bitmap.close();
        this.onStatus({ state: 'ready', environmentTexture: this.environmentTextureInfo });
        if (this.accumulationTextures) this.createBindGroups();
    }

    async setEnvironmentIrradianceTexture(url) {
        if (!url) return;
        if (/\.hdr(?:$|[?#])/i.test(url)) {
            this.environmentIrradianceTextureInfo = { url, width: 1, height: 1, fallback: true, unsupported: 'hdr-native-upload-not-yet-implemented' };
            this.onStatus({ state: 'ready', environmentIrradianceTexture: this.environmentIrradianceTextureInfo });
            if (this.accumulationTextures) this.createBindGroups();
            return;
        }
        if (!this.device) return;
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Environment irradiance texture fetch failed: ${response.status} ${url}`);
        const bitmap = await createImageBitmap(await response.blob());
        const texture = this.device.createTexture({ size: [bitmap.width, bitmap.height], format: 'rgba8unorm', usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT });
        this.device.queue.copyExternalImageToTexture({ source: bitmap }, { texture }, [bitmap.width, bitmap.height]);
        this.environmentIrradianceTexture?.destroy();
        this.environmentIrradianceTexture = texture;
        const info = { url, width: bitmap.width, height: bitmap.height, fallback: false };
        this.environmentIrradianceTextureInfo = info;
        bitmap.close();
        this.onStatus({ state: 'ready', environmentIrradianceTexture: info });
        if (this.accumulationTextures) this.createBindGroups();
    }

    async setMaterialTextureManifest(manifest = []) {
        if (!this.device) {
            this.pendingMaterialTextureManifest = manifest;
            return { pending: true, count: manifest.length };
        }
        if (!Array.isArray(manifest)) throw new Error('WebGPU MaterialX texture manifest must be an array.');
        const limitSummary = validateMaterialTextureLimits(this.adapter, manifest);
        const seenBindings = new Set();
        const resources = [];
        for (const entry of manifest) {
            if (!entry?.url || entry.group !== 0 || !entry.texture || !entry.sampler) {
                throw new Error(`Invalid WebGPU MaterialX texture manifest entry: ${JSON.stringify(entry)}`);
            }
            if (entry.texture.binding < 20 || entry.sampler.binding !== entry.texture.binding + 1) {
                throw new Error(`Invalid WebGPU MaterialX texture bindings for ${entry.texture.name}.`);
            }
            for (const binding of [entry.texture.binding, entry.sampler.binding]) {
                if (seenBindings.has(binding)) throw new Error(`Duplicate WebGPU MaterialX texture binding ${binding}.`);
                seenBindings.add(binding);
            }
            const response = await fetch(entry.url);
            if (!response.ok) throw new Error(`MaterialX texture fetch failed: ${response.status} ${entry.url}`);
            const bitmap = await createImageBitmap(await response.blob());
            if (bitmap.width < 1 || bitmap.height < 1) {
                bitmap.close();
                throw new Error(`MaterialX texture has invalid dimensions: ${entry.url}`);
            }
            const width = bitmap.width;
            const height = bitmap.height;
            const texture = this.device.createTexture({
                size: [width, height],
                format: 'rgba8unorm',
                usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
            });
            this.device.queue.copyExternalImageToTexture({ source: bitmap }, { texture }, [width, height]);
            bitmap.close();
            resources.push({
                ...entry,
                width,
                height,
                textureName: entry.texture.name,
                textureBinding: entry.texture.binding,
                texture,
                samplerResource: this.device.createSampler({ addressModeU: 'repeat', addressModeV: 'repeat', magFilter: 'linear', minFilter: 'linear' }),
                samplerBinding: entry.sampler.binding,
            });
        }
        this.materialTextureResources.forEach(resource => resource.texture.destroy());
        this.materialTextureResources = resources;
        if (this.accumulationTextures) this.createBindGroups();
        this.onStatus({ state: 'ready', materialBindGroup: Boolean(this.materialComputeBindGroup), materialTextures: resources.map(resource => ({ name: resource.textureName, width: resource.width, height: resource.height, group: resource.group, textureBinding: resource.textureBinding, samplerBinding: resource.samplerBinding, colorSpace: resource.colorSpace })) });
        return { pending: false, count: resources.length, limits: limitSummary };
    }

    createMaterialTextureBindGroup(pipeline) {
        if (!pipeline) throw new Error('A MaterialX WebGPU pipeline is required to bind textures.');
        if (pipeline !== this.materialComputePipeline) throw new Error('MaterialX texture bindings must target the active MaterialX compute pipeline.');
        this.createBindGroups();
        if (!this.materialComputeBindGroup) throw new Error('MaterialX bind group is incomplete: one or more declared resources are missing.');
        return this.materialComputeBindGroup;
    }

    setLights(lights = [], params = {}) {
        if (!this.device) { this.pendingLights = { lights, params }; return; }
        if (this.lightsBuffer !== this.emptyLightsBuffer) this.lightsBuffer?.destroy();
        // WGSL struct layout:
        // Light { position: vec4<f32>, direction: vec4<f32>, colorIntensity: vec4<f32>, cone: vec4<f32>, edgeU: vec4<f32>, edgeV: vec4<f32> }
        // => 6 vec4 slots = 96 bytes per light (24 floats), matching the shader's array<Light> expectation.
        const lightStride = 24;
        const data = new Float32Array(Math.max(1, lights.length) * lightStride);
        const packedLights = [];
        for (let index = 0; index < lights.length; index++) {
            const light = lights[index];
            const base = index * lightStride;
            const position = Array.isArray(light.position) && light.position.length >= 3 ? light.position : [0, 0, 0];
            const direction = Array.isArray(light.direction) && light.direction.length >= 3 ? light.direction : [0, -1, 0];
            const color = Array.isArray(light.color) && light.color.length >= 3 ? light.color : [1, 1, 1];
            const u = Array.isArray(light.u) && light.u.length >= 3 ? light.u : [0, 0, 0];
            const v = Array.isArray(light.v) && light.v.length >= 3 ? light.v : [0, 0, 0];
            data[base + 0] = position[0];
            data[base + 1] = position[1];
            data[base + 2] = position[2];
            data[base + 3] = Number.isFinite(light.decayRate) ? light.decayRate : 0;
            data[base + 4] = direction[0];
            data[base + 5] = direction[1];
            data[base + 6] = direction[2];
            data[base + 7] = Number.isFinite(light.type) ? light.type : 0;
            data[base + 8] = color[0];
            data[base + 9] = color[1];
            data[base + 10] = color[2];
            data[base + 11] = Number.isFinite(light.intensity) ? light.intensity : 0;
            data[base + 12] = Number.isFinite(light.innerCone) ? light.innerCone : 1;
            data[base + 13] = Number.isFinite(light.outerCone) ? light.outerCone : 1;
            data[base + 14] = 0;
            data[base + 15] = 0;
            data[base + 16] = u[0];
            data[base + 17] = u[1];
            data[base + 18] = u[2];
            data[base + 19] = 0;
            data[base + 20] = v[0];
            data[base + 21] = v[1];
            data[base + 22] = v[2];
            data[base + 23] = 0;
            packedLights.push({
                index,
                name: String(light.name || ''),
                type: data[base + 7],
                position: Array.from(data.slice(base, base + 3)),
                intensity: data[base + 11],
                direction: Array.from(data.slice(base + 4, base + 7)),
                decayRate: data[base + 3],
                innerCone: data[base + 12],
                outerCone: data[base + 13],
                u: Array.from(data.slice(base + 16, base + 19)),
                v: Array.from(data.slice(base + 20, base + 23)),
            });
        }
        this.lightsBuffer = this.device.createBuffer({ size: data.byteLength, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST });
        this.device.queue.writeBuffer(this.lightsBuffer, 0, data);
        this.lightCount = lights.length;
        this.lightDiagnostics = {
            lightCount: lights.length,
            strideFloats: lightStride,
            strideBytes: lightStride * Float32Array.BYTES_PER_ELEMENT,
            bufferSizeBytes: data.byteLength,
            bufferUsage: ['STORAGE', 'COPY_DST'],
            lights: packedLights,
        };
        this.device.queue.writeBuffer(this.lightingBuffer, 0, new Float32Array([
            ...(params.sunDir || [0.35, 0.8, 0.25]), 0,
            ...(params.sunColor || [1, 1, 1]), Math.pow(10, params.sunPower ?? 0.25),
            ...(params.skyColor || [1, 1, 1]), params.skyPower ?? 1
        ]));
        if (this.accumulationTextures) this.createBindGroups();
    }

    getLightsDiagnostic() {
        return this.lightDiagnostics ? JSON.parse(JSON.stringify(this.lightDiagnostics)) : null;
    }

    async readLightsGpuDiagnostic() {
        if (!this.device || !this.lightsBuffer || !this.lightDiagnostics) return null;
        if (!this.lightReadbackPipeline) {
            const module = this.device.createShaderModule({ code: LIGHT_READBACK_SHADER });
            const info = await module.getCompilationInfo();
            const errors = info.messages.filter(message => message.type === 'error');
            if (errors.length) throw new Error(errors.map(message => message.message).join('\n'));
            this.lightReadbackPipeline = await this.device.createComputePipelineAsync({
                layout: 'auto',
                compute: { module, entryPoint: 'main' },
            });
        }
        const outputBuffer = this.device.createBuffer({
            size: 96,
            usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC,
        });
        const readbackBuffer = this.device.createBuffer({
            size: 96,
            usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST,
        });
        const bindGroup = this.device.createBindGroup({
            layout: this.lightReadbackPipeline.getBindGroupLayout(0),
            entries: [
                { binding: 0, resource: { buffer: this.lightsBuffer } },
                { binding: 1, resource: { buffer: outputBuffer } },
            ],
        });
        const encoder = this.device.createCommandEncoder();
        const pass = encoder.beginComputePass();
        pass.setPipeline(this.lightReadbackPipeline);
        pass.setBindGroup(0, bindGroup);
        pass.dispatchWorkgroups(1);
        pass.end();
        encoder.copyBufferToBuffer(outputBuffer, 0, readbackBuffer, 0, 96);
        this.device.queue.submit([encoder.finish()]);
        await readbackBuffer.mapAsync(GPUMapMode.READ);
        const values = Array.from(new Float32Array(readbackBuffer.getMappedRange()));
        readbackBuffer.unmap();
        outputBuffer.destroy();
        readbackBuffer.destroy();
        return {
            lightCount: this.lightDiagnostics.lightCount,
            position: values.slice(0, 4),
            direction: values.slice(4, 8),
            colorIntensity: values.slice(8, 12),
            cone: values.slice(12, 16),
            edgeU: values.slice(16, 20),
            edgeV: values.slice(20, 24),
        };
    }

    render(frameIndex, camera, debugMode = 'hit') {
        if (!this.ready || !this.accumulationTextures) return false;
        const debugModes = { hit: 0, distance: 1, normal: 2, uv: 3, material: 4, ground: 5, pdf: 6, bounces: 7, lights: 8, hitcheck: 9, lightLoop: 10, constant: 11, fixedRay: 12, fixedCenterRay: 13, rootAabb: 14, fixedTriangleRay: 15, directTriangle: 16, leafAabb: 17, leafVisit: 18 };
        this.device.queue.writeBuffer(this.frameBuffer, 0, new Uint32Array([
            this.width, this.height, frameIndex, debugModes[debugMode] ?? 0,
            this.sceneBuffers?.nodeCount || 0, this.sceneBuffers?.triangleCount || 0, this.lightCount || 0, 0
        ]));
        this.device.queue.writeBuffer(this.cameraBuffer, 0, new Float32Array([...camera.matrixWorld.elements, ...camera.projectionMatrixInverse.elements]));
        const encoder = this.device.createCommandEncoder();
        const computePass = encoder.beginComputePass();
        const useMaterialPipeline = Boolean(this.materialComputePipeline && this.materialComputeBindGroup);
        computePass.setPipeline(useMaterialPipeline ? this.materialComputePipeline : this.computePipeline);
        computePass.setBindGroup(0, useMaterialPipeline ? this.materialComputeBindGroup : this.computeBindGroup);
        computePass.dispatchWorkgroups(Math.ceil(this.width / 8), Math.ceil(this.height / 8));
        computePass.end();
        const renderPass = encoder.beginRenderPass({ colorAttachments: [{ view: this.context.getCurrentTexture().createView(), loadOp: 'clear', storeOp: 'store', clearValue: [0, 0, 0, 1] }] });
        renderPass.setPipeline(this.presentPipeline);
        renderPass.setBindGroup(0, this.presentBindGroup);
        renderPass.draw(3);
        renderPass.end();
        this.device.queue.submit([encoder.finish()]);
        this.accumulationIndex = 1 - this.accumulationIndex;
        this.createBindGroups();
        return true;
    }

    async readAccumulationPixel(x = 0, y = 0) {
        if (!this.device || !this.accumulationTextures?.length) return null;
        await this.device.queue.onSubmittedWorkDone();
        const bytesPerRow = 256;
        const buffer = this.device.createBuffer({ size: bytesPerRow, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
        const encoder = this.device.createCommandEncoder();
        encoder.copyTextureToBuffer({ texture: this.accumulationTextures[1 - this.accumulationIndex], origin: { x, y, z: 0 } }, { buffer, bytesPerRow, rowsPerImage: 1 }, { width: 1, height: 1, depthOrArrayLayers: 1 });
        this.device.queue.submit([encoder.finish()]);
        await this.device.queue.onSubmittedWorkDone();
        await buffer.mapAsync(GPUMapMode.READ);
        const halfToFloat = half => {
            const sign = (half & 0x8000) ? -1 : 1;
            const exponent = (half >> 10) & 0x1f;
            const fraction = half & 0x3ff;
            if (exponent === 0) return sign * 2 ** -14 * (fraction / 1024);
            if (exponent === 0x1f) return fraction ? NaN : sign * Infinity;
            return sign * 2 ** (exponent - 15) * (1 + fraction / 1024);
        };
        const values = Array.from(new Uint16Array(buffer.getMappedRange().slice(0, 8)), halfToFloat);
        buffer.unmap();
        buffer.destroy();
        return values;
    }

    async readBvhDebug() {
        if (!this.device || !this.sceneBuffers) return null;
        await this.device.queue.onSubmittedWorkDone();
        const read = async (source, size, sourceOffset = 0) => {
            const buffer = this.device.createBuffer({ size, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
            const encoder = this.device.createCommandEncoder();
            encoder.copyBufferToBuffer(source, sourceOffset, buffer, 0, size);
            this.device.queue.submit([encoder.finish()]);
            await this.device.queue.onSubmittedWorkDone();
            await buffer.mapAsync(GPUMapMode.READ);
            const values = Array.from(new Uint32Array(buffer.getMappedRange().slice(0, size)));
            buffer.unmap();
            buffer.destroy();
            return values;
        };
        return {
            root: await read(this.sceneBuffers.nodes, 48),
            leftRoot: await read(this.sceneBuffers.nodes, 48, 48),
            rightRoot: await read(this.sceneBuffers.nodes, 48, 9874 * 48),
            firstLeafIndex: this.firstLeafIndex,
            firstLeaf: this.firstLeafIndex >= 0 ? await read(this.sceneBuffers.nodes, 48, this.firstLeafIndex * 48) : null,
            triangle: await read(this.sceneBuffers.triangleIndices, 16),
            positions: await read(this.sceneBuffers.positions, 48, 45 * 16),
        };
    }

    async readBvhStackOverflow() {
        if (!this.device || !this.stackOverflowBuffer) return null;
        await this.device.queue.onSubmittedWorkDone();
        const buffer = this.device.createBuffer({ size: 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
        const encoder = this.device.createCommandEncoder();
        encoder.copyBufferToBuffer(this.stackOverflowBuffer, 0, buffer, 0, 4);
        this.device.queue.submit([encoder.finish()]);
        await this.device.queue.onSubmittedWorkDone();
        await buffer.mapAsync(GPUMapMode.READ);
        const value = new Uint32Array(buffer.getMappedRange())[0];
        buffer.unmap();
        buffer.destroy();
        return value;
    }

    setSceneBvh(bvh) {
        if (!bvh) return;
        if (!this.ready) {
            this.pendingBvh = bvh;
            return;
        }
        this.sceneBuffers?.destroy();
        this.sceneBuffers = createWebGpuSceneBuffers(this.device, bvh);
        this.firstLeafIndex = bvh.nodes.findIndex(node => node.count > 0);
        bvh.geometry.computeBoundingBox?.();
        this.sceneBounds = bvh.geometry.boundingBox ? {
            min: bvh.geometry.boundingBox.min.toArray(),
            max: bvh.geometry.boundingBox.max.toArray(),
        } : null;
        if (!Number.isInteger(this.width) || !Number.isInteger(this.height)) return;
        const width = this.width;
        const height = this.height;
        this.width = 0;
        this.resize(width, height);
        this.onStatus({
            state: 'ready',
            adapter: this.adapter.info || null,
            format: this.format,
            sceneBuffers: {
                nodes: this.sceneBuffers.nodeCount,
                triangles: this.sceneBuffers.triangleCount,
                vertices: this.sceneBuffers.vertexCount
            }
        });
    }

    destroy() {
        if (this.destroyed) return;
        this.destroyed = true;
        this.ready = false;
        this.pendingBvh = null;
        this.sceneBuffers?.destroy();
        this.sceneBuffers = null;
        this.emptyNodeBuffer?.destroy();
        this.emptyNodeBuffer = null;
        this.emptyIndexBuffer?.destroy();
        this.emptyIndexBuffer = null;
        this.emptyPositionBuffer?.destroy();
        this.emptyPositionBuffer = null;
        this.stackOverflowBuffer?.destroy();
        this.stackOverflowBuffer = null;
        this.cameraBuffer?.destroy();
        this.cameraBuffer = null;
        this.groundTexture?.destroy();
        this.groundTexture = null;
        this.environmentTexture?.destroy();
        this.environmentTexture = null;
        this.environmentIrradianceTexture?.destroy();
        this.environmentIrradianceTexture = null;
        this.materialPrivateUniformBuffer?.destroy();
        this.materialPrivateUniformBuffer = null;
        this.materialTextureResources.forEach(resource => resource.texture.destroy());
        this.materialTextureResources = [];
        this.accumulationTextures?.forEach(texture => texture.destroy());
        this.accumulationTextures = null;
        this.frameBuffer?.destroy();
        this.frameBuffer = null;
        this.canvas.remove();
        if (this.lightsBuffer !== this.emptyLightsBuffer) this.lightsBuffer?.destroy();
        this.lightsBuffer = null;
        this.emptyLightsBuffer?.destroy();
        this.emptyLightsBuffer = null;
        this.lightingBuffer?.destroy();
        this.lightingBuffer = null;
        // Release the GPUDevice itself so a subsequent requestAdapter/requestDevice
        // (recreate) is not left waiting on resources tied to a live-but-unused device.
        this.device?.destroy();
        this.device = null;
        this.adapter = null;
    }
}