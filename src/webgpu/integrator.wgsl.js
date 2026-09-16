export const INTEGRATOR_WGSL = /* wgsl */ `
const PI: f32 = 3.14159265359;
const INV_PI: f32 = 0.31830988618;

struct Basis {
    normal: vec3<f32>,
    tangent: vec3<f32>,
    bitangent: vec3<f32>,
}

fn safeNormalize(value: vec3<f32>) -> vec3<f32> {
    return value / max(length(value), 1.0e-6);
}

fn makeBasis(normal: vec3<f32>) -> Basis {
    let n = safeNormalize(normal);
    let tangent = select(vec3<f32>(0.0, n.z, -n.y), vec3<f32>(n.z, 0.0, -n.x), abs(n.z) < abs(n.x));
    let t = safeNormalize(tangent);
    return Basis(n, t, cross(n, t));
}

fn worldToLocal(value: vec3<f32>, basis: Basis) -> vec3<f32> {
    return vec3<f32>(dot(value, basis.tangent), dot(value, basis.bitangent), dot(value, basis.normal));
}

fn localToWorld(value: vec3<f32>, basis: Basis) -> vec3<f32> {
    return basis.tangent * value.x + basis.bitangent * value.y + basis.normal * value.z;
}

fn pcg(value: u32) -> u32 {
    var state = value * 747796405u + 2891336453u;
    let word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

fn random01(state: u32) -> f32 {
    return f32(pcg(state)) / 4294967295.0;
}

fn sampleCosineHemisphere(state: u32) -> vec3<f32> {
    let r = sqrt(random01(state));
    let phi = 2.0 * PI * random01(state + 1u);
    let direction = vec3<f32>(r * cos(phi), r * sin(phi), sqrt(max(0.0, 1.0 - r * r)));
    return direction;
}

fn cosinePdf(cosine: f32) -> f32 {
    return max(cosine, 0.0) * INV_PI;
}

fn fresnelSchlick(cosine: f32, f0: vec3<f32>) -> vec3<f32> {
    return f0 + (vec3<f32>(1.0) - f0) * pow(1.0 - clamp(cosine, 0.0, 1.0), 5.0);
}

fn ggxDistribution(cosine: f32, roughness: f32) -> f32 {
    let alpha = max(roughness * roughness, 1.0e-4);
    let alpha2 = alpha * alpha;
    let cosine2 = cosine * cosine;
    let denominator = PI * pow(cosine2 * (alpha2 - 1.0) + 1.0, 2.0);
    return alpha2 / max(denominator, 1.0e-6);
}

fn evaluateLambert(albedo: vec3<f32>, normal: vec3<f32>, incoming: vec3<f32>, outgoing: vec3<f32>) -> vec3<f32> {
    if (dot(normal, incoming) <= 0.0 || dot(normal, outgoing) <= 0.0) { return vec3<f32>(0.0); }
    return albedo * INV_PI;
}

fn evaluateReferenceLighting(normal: vec3<f32>, position: vec3<f32>, viewDirection: vec3<f32>) -> vec3<f32> {
    let sunDirection = safeNormalize(vec3<f32>(0.35, 0.8, 0.25));
    let sky = vec3<f32>(0.12, 0.16, 0.22);
    let sun = vec3<f32>(1.0, 0.92, 0.78) * max(dot(normal, sunDirection), 0.0) * 1.8;
    let halfVector = safeNormalize(sunDirection + viewDirection);
    let specular = fresnelSchlick(max(dot(normal, viewDirection), 0.0), vec3<f32>(0.04)) * ggxDistribution(max(dot(normal, halfVector), 0.0), 0.35);
    return sky + sun + specular;
}
`;