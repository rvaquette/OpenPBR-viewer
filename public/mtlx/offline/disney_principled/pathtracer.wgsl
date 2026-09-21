// openpbr-offline-materialx-wgsl
diagnostic(off, derivative_uniformity);
struct Basis {
    nW: vec3<f32>,
    tW: vec3<f32>,
    bW: vec3<f32>,
    baryCoord: vec3<f32>,
    texCoord: vec2<f32>,
}

struct FresnelData {
    model: i32,
    airy: bool,
    ior: vec3<f32>,
    extinction: vec3<f32>,
    F0_: vec3<f32>,
    F82_: vec3<f32>,
    F90_: vec3<f32>,
    exponent: f32,
    tf_thickness: f32,
    tf_ior: f32,
    refraction: bool,
}

struct ClosureData {
    closureType: i32,
    L: vec3<f32>,
    V: vec3<f32>,
    N: vec3<f32>,
    P: vec3<f32>,
    occlusion: f32,
}

struct BSDF {
    response: vec3<f32>,
    throughput: vec3<f32>,
}

struct surfaceshader {
    color: vec3<f32>,
    transparency: vec3<f32>,
}

struct Volume {
    extinction: vec3<f32>,
    albedo: vec3<f32>,
    anisotropy: f32,
}

struct MtlxLight {
    position: vec3<f32>,
    direction: vec3<f32>,
    color: vec3<f32>,
    intensity: f32,
    decayRate: f32,
    innerCone: f32,
    outerCone: f32,
    type_: i32,
    u: vec3<f32>,
    v: vec3<f32>,
}

struct MtlxMaterialUniforms {
    cameraWorldMatrix: mat4x4<f32>,
    invProjectionMatrix: mat4x4<f32>,
    invModelMatrix: mat4x4<f32>,
    resolution: vec2<f32>,
    has_normals_surface: u32,
    has_tangents_surface: u32,
    has_uvs_surface: u32,
    accumulation_weight: f32,
    samples: f32,
    wireframe: u32,
    neutral_color: vec3<f32>,
    smooth_normals: u32,
    bounces: i32,
    max_volume_steps: i32,
    firefly_clamp: f32,
    strict_failure_enabled: u32,
    generated_contract_valid: u32,
    generated_contract_failure_code: i32,
    skyPower: f32,
    skyColor: vec3<f32>,
    sunPower: f32,
    sunAngularSize: f32,
    sunColor: vec3<f32>,
    sunDir: vec3<f32>,
    mtlxDisableSun: u32,
    envMapRes: vec2<f32>,
    envMapTotalSum: f32,
    has_env_cdf: u32,
    mtlxLightCount: i32,
    u_envMatrix: mat4x4<f32>,
    u_envLightIntensity: f32,
    u_envRadianceMips: i32,
    u_envRadianceSamples: i32,
    u_refractionTwoSided: u32,
}

var<private> g_ptOcclusion: f32;
var<private> g_ptEmitEmission: i32;
var<private> g_ptOpacity: f32;
var<private> g_ptEmission: vec3<f32>;
var<private> base_color_1: vec3<f32>;
var<private> metallic_1: f32;
var<private> roughness_18: f32;
var<private> occlusion_3: f32;
var<private> transmission_1: f32;
var<private> specular_1: f32;
var<private> specular_color_1: vec3<f32>;
var<private> ior_7: f32;
var<private> alpha_15: f32;
var<private> alpha_mode_1: i32;
var<private> alpha_cutoff_1: f32;
var<private> iridescence_1: f32;
var<private> iridescence_ior_1: f32;
var<private> iridescence_thickness_1: f32;
var<private> sheen_color_1: vec3<f32>;
var<private> sheen_roughness_1: f32;
var<private> clearcoat_1: f32;
var<private> clearcoat_roughness_1: f32;
var<private> emissive_1: vec3<f32>;
var<private> emissive_strength_1: f32;
var<private> thickness_1: f32;
var<private> attenuation_distance_1: f32;
var<private> attenuation_color_1: vec3<f32>;
var<private> anisotropy_strength_1: f32;
var<private> anisotropy_rotation_1: f32;
var<private> dispersion_1: f32;
@group(0) @binding(18) 
var envMapLatLong_texture: texture_2d<f32>;
@group(0) @binding(19) 
var envMapLatLong_sampler: sampler;
@group(0) @binding(20) 
var envMapIrradiance_texture: texture_2d<f32>;
@group(0) @binding(21) 
var envMapIrradiance_sampler: sampler;
@group(0) @binding(15) 
var<uniform> unnamed: MtlxMaterialUniforms;
var<private> g_ptN: vec3<f32>;
var<private> g_ptV: vec3<f32>;
var<private> g_ptL: vec3<f32>;
var<private> g_ptP: vec3<f32>;
var<private> g_ptClosureType: i32;
var<private> normalWorld: vec3<f32>;
var<private> tangentWorld: vec3<f32>;
var<private> g_ptTangent: vec3<f32>;
var<private> g_ptBitangent: vec3<f32>;
var<private> g_ptTexcoord: vec2<f32>;
@group(0) @binding(22) 
var bvh_surface_nodes_texture: texture_2d<f32>;
@group(0) @binding(23) 
var bvh_surface_nodes_sampler: sampler;
@group(0) @binding(24) 
var bvh_surface_indices_texture: texture_2d<f32>;
@group(0) @binding(25) 
var bvh_surface_indices_sampler: sampler;
@group(0) @binding(26) 
var bvh_surface_positions_texture: texture_2d<f32>;
@group(0) @binding(27) 
var bvh_surface_positions_sampler: sampler;
@group(0) @binding(28) 
var geomN_surface_texture: texture_2d<f32>;
@group(0) @binding(29) 
var geomN_surface_sampler: sampler;
@group(0) @binding(30) 
var geomT_surface_texture: texture_2d<f32>;
@group(0) @binding(31) 
var geomT_surface_sampler: sampler;
@group(0) @binding(32) 
var geomS_surface_texture: texture_2d<f32>;
@group(0) @binding(33) 
var geomS_surface_sampler: sampler;
@group(0) @binding(34) 
var ground_texture_texture: texture_2d<f32>;
@group(0) @binding(35) 
var ground_texture_sampler: sampler;
var<private> sunBasis: Basis;
@group(0) @binding(40) 
var mtlxLightsTex_texture: texture_2d<f32>;
@group(0) @binding(41) 
var mtlxLightsTex_sampler: sampler;
@group(0) @binding(16) 
var envMap_texture: texture_cube<f32>;
@group(0) @binding(17) 
var envMap_sampler: sampler;
@group(0) @binding(38) 
var envMapCDFTex_texture: texture_2d<f32>;
@group(0) @binding(39) 
var envMapCDFTex_sampler: sampler;
@group(0) @binding(36) 
var envMapEquirect_texture: texture_2d<f32>;
@group(0) @binding(37) 
var envMapEquirect_sampler: sampler;
var<private> gl_FragCoord_1: vec4<f32>;
var<private> mtlxFragmentColor: vec4<f32>;
@group(0) @binding(42) 
var u_envRadiance_texture: texture_2d<f32>;
@group(0) @binding(43) 
var u_envRadiance_sampler: sampler;
@group(0) @binding(44) 
var u_envIrradiance_texture: texture_2d<f32>;
@group(0) @binding(45) 
var u_envIrradiance_sampler: sampler;
var<private> vUv_1: vec2<f32>;
var<private> wavelength_nm: f32;

fn minComponent_u0028_vf3_u003b(v: ptr<function, vec3<f32>>) -> f32 {
    let _e327 = (*v)[0u];
    let _e329 = (*v)[1u];
    let _e331 = (*v)[2u];
    return min(_e327, min(_e329, _e331));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e327 = (*wiL)[2u];
    if (_e327 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e330 = (*wiL)[2u];
    return (_e330 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_7078_: bool;
    var phi_7096_: bool;

    let _e333 = (*winputL)[2u];
    let _e334 = (_e333 < 0.0000000001f);
    phi_7078_ = _e334;
    if !(_e334) {
        let _e337 = (*woutputL)[2u];
        phi_7078_ = (_e337 < 0.0000000001f);
    }
    let _e340 = phi_7078_;
    if _e340 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e341 = (*woutputL);
    param = _e341;
    let _e342 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e342;
    let _e344 = unnamed.wireframe;
    let _e345 = (_e344 != 0u);
    phi_7096_ = _e345;
    if _e345 {
        let _e347 = (*basis).baryCoord;
        param_1 = _e347;
        let _e348 = minComponent_u0028_vf3_u003b((&param_1));
        phi_7096_ = (_e348 < 0.003f);
    }
    let _e351 = phi_7096_;
    if _e351 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e353 = unnamed.neutral_color;
    return (_e353 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e328 = (*pW_1)[0u];
    let _e330 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e328, -(_e330)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e338 = uv;
    let _e339 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e338, 0.0);
    return _e339.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_7171_: bool;

    let _e333 = (*winputL_1)[2u];
    let _e334 = (_e333 < 0.0000000001f);
    phi_7171_ = _e334;
    if !(_e334) {
        let _e337 = (*woutputL_1)[2u];
        phi_7171_ = (_e337 < 0.0000000001f);
    }
    let _e340 = phi_7171_;
    if _e340 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e341 = (*woutputL_1);
    param_2 = _e341;
    let _e342 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e342;
    let _e343 = (*pW_2);
    param_3 = _e343;
    let _e344 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e344 / vec3(3.1415927f));
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result: ptr<function, vec3<f32>>) {
    let _e329 = (*closureData).closureType;
    if (_e329 == 4i) {
        let _e331 = (*color);
        (*result) = _e331;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_1: ptr<function, ClosureData>, top: ptr<function, BSDF>, base: ptr<function, BSDF>, result_1: ptr<function, BSDF>) {
    let _e330 = (*top).response;
    let _e332 = (*base).response;
    let _e334 = (*top).throughput;
    (*result_1).response = (_e330 + (_e332 * _e334));
    let _e339 = (*top).throughput;
    let _e341 = (*base).throughput;
    (*result_1).throughput = (_e339 * _e341);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e329 = (*dir)[1u];
    latitude = ((-(asin(_e329)) * 0.31830987f) + 0.5f);
    let _e335 = (*dir)[0u];
    let _e337 = (*dir)[2u];
    longitude = (((atan2(_e335, -(_e337)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e343 = longitude;
    let _e344 = latitude;
    return vec2<f32>(_e343, _e344);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e327 = (*m);
    let _e328 = (*v_1);
    return (_e327 * _e328);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_4: mat4x4<f32>;
    var param_5: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_6: vec3<f32>;

    let _e333 = (*dir_1);
    let _e338 = (*transform);
    param_4 = _e338;
    param_5 = vec4<f32>(_e333.x, _e333.y, _e333.z, 0f);
    let _e339 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_4), (&param_5));
    envDir = normalize(_e339.xyz);
    let _e342 = envDir;
    param_6 = _e342;
    let _e343 = mx_latlong_projection_u0028_vf3_u003b((&param_6));
    uv_1 = _e343;
    let _e344 = uv_1;
    let _e345 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e344, 0.0);
    return _e345.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e328 = a;
    c = cos(_e328);
    let _e330 = a;
    s = sin(_e330);
    let _e332 = c;
    let _e333 = s;
    let _e335 = s;
    let _e336 = c;
    return mat4x4<f32>(vec4<f32>(_e332, 0f, -(_e333), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e335, 0f, _e336, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_7: vec3<f32>;
    var param_8: mat4x4<f32>;
    var param_9: f32;

    let _e330 = mtlxEnvMatrix_u0028_();
    let _e331 = (*N);
    param_7 = _e331;
    param_8 = _e330;
    param_9 = 0f;
    let _e332 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_7), (&param_8), (&param_9));
    Li = _e332;
    let _e333 = Li;
    let _e335 = unnamed.skyPower;
    return (_e333 * _e335);
}

fn mx_square_u0028_f1_u003b(x: ptr<function, f32>) -> f32 {
    let _e326 = (*x);
    let _e327 = (*x);
    return (_e326 * _e327);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_10: f32;

    let _e329 = (*roughness);
    let _e332 = (*NdotV);
    let _e334 = (*roughness);
    let _e337 = (*roughness);
    param_10 = _e337;
    let _e338 = mx_square_u0028_f1_u003b((&param_10));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e329)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e332) * _e334)) + (vec2<f32>(1.4385f, 2.0315f) * _e338));
    let _e342 = r[0u];
    let _e344 = r[1u];
    return (_e342 / _e344);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_11: f32;
    var param_12: f32;

    let _e330 = (*NdotV_1);
    param_11 = _e330;
    let _e331 = (*roughness_1);
    param_12 = _e331;
    let _e332 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_11), (&param_12));
    dirAlbedo = _e332;
    let _e333 = dirAlbedo;
    return clamp(_e333, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e326 = (*x_1);
    let _e327 = (*x_1);
    return (_e326 * _e327);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e327 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e327)));
    let _e331 = A;
    let _e332 = (*roughness_2);
    return (_e331 * (1f + (0.07248821f * _e332)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_13: f32;
    var G: f32;

    let _e332 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e332)));
    let _e336 = (*roughness_3);
    let _e337 = A_1;
    B = (_e336 * _e337);
    let _e339 = (*cosTheta);
    param_13 = _e339;
    let _e340 = mx_square_u0028_f1_u003b((&param_13));
    Si = sqrt(max(0f, (1f - _e340)));
    let _e344 = Si;
    let _e345 = (*cosTheta);
    let _e348 = Si;
    let _e349 = (*cosTheta);
    let _e353 = Si;
    let _e354 = (*cosTheta);
    let _e356 = Si;
    let _e357 = Si;
    let _e359 = Si;
    let _e363 = Si;
    G = ((_e344 * (acos(clamp(_e345, -1f, 1f)) - (_e348 * _e349))) + ((2f * (((_e353 / _e354) * (1f - ((_e356 * _e357) * _e359))) - _e363)) / 3f));
    let _e368 = A_1;
    let _e369 = B;
    let _e370 = G;
    return (_e368 + ((_e369 * _e370) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_1: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_14: f32;
    var param_15: f32;
    var avgAlbedo: f32;
    var param_16: f32;
    var colorMultiScatter: vec3<f32>;
    var param_17: vec3<f32>;

    let _e335 = (*cosTheta_1);
    param_14 = _e335;
    let _e336 = (*roughness_4);
    param_15 = _e336;
    let _e337 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_14), (&param_15));
    dirAlbedo_1 = _e337;
    let _e338 = (*roughness_4);
    param_16 = _e338;
    let _e339 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_16));
    avgAlbedo = _e339;
    let _e340 = (*color_1);
    param_17 = _e340;
    let _e341 = mx_square_u0028_vf3_u003b((&param_17));
    let _e342 = avgAlbedo;
    let _e344 = (*color_1);
    let _e345 = avgAlbedo;
    colorMultiScatter = ((_e341 * _e342) / (vec3<f32>(1f, 1f, 1f) - (_e344 * max(0f, (1f - _e345)))));
    let _e351 = colorMultiScatter;
    let _e352 = (*color_1);
    let _e353 = dirAlbedo_1;
    return mix(_e351, _e352, vec3(_e353));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local: f32;
    var sigma2_: f32;
    var param_18: f32;
    var A_2: f32;
    var B_1: f32;

    let _e336 = (*LdotV);
    let _e337 = (*NdotL);
    let _e338 = (*NdotV_2);
    s_1 = (_e336 - (_e337 * _e338));
    let _e341 = s_1;
    if (_e341 > 0f) {
        let _e343 = s_1;
        let _e344 = (*NdotL);
        let _e345 = (*NdotV_2);
        local = (_e343 / max(_e344, _e345));
    } else {
        local = 0f;
    }
    let _e348 = local;
    stinv = _e348;
    let _e349 = (*roughness_5);
    param_18 = _e349;
    let _e350 = mx_square_u0028_f1_u003b((&param_18));
    sigma2_ = _e350;
    let _e351 = sigma2_;
    let _e352 = sigma2_;
    A_2 = (1f - (0.5f * (_e351 / (_e352 + 0.33f))));
    let _e357 = sigma2_;
    let _e359 = sigma2_;
    B_1 = ((0.45f * _e357) / (_e359 + 0.09f));
    let _e362 = A_2;
    let _e363 = B_1;
    let _e364 = stinv;
    return (_e362 + (_e363 * _e364));
}

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_3: ptr<function, f32>, NdotL_1: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_1: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_19: f32;
    var param_20: f32;
    var dirAlbedoL: f32;
    var param_21: f32;
    var param_22: f32;
    var avgAlbedo_1: f32;
    var param_23: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_24: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e346 = (*LdotV_1);
    let _e347 = (*NdotL_1);
    let _e348 = (*NdotV_3);
    s_2 = (_e346 - (_e347 * _e348));
    let _e351 = s_2;
    if (_e351 > 0f) {
        let _e353 = s_2;
        let _e354 = (*NdotL_1);
        let _e355 = (*NdotV_3);
        local_1 = (_e353 / max(_e354, _e355));
    } else {
        let _e358 = s_2;
        local_1 = _e358;
    }
    let _e359 = local_1;
    stinv_1 = _e359;
    let _e360 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e360)));
    let _e364 = (*color_2);
    let _e365 = A_3;
    let _e367 = (*roughness_6);
    let _e368 = stinv_1;
    lobeSingleScatter = ((_e364 * _e365) * (1f + (_e367 * _e368)));
    let _e372 = (*NdotV_3);
    param_19 = _e372;
    let _e373 = (*roughness_6);
    param_20 = _e373;
    let _e374 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_19), (&param_20));
    dirAlbedoV = _e374;
    let _e375 = (*NdotL_1);
    param_21 = _e375;
    let _e376 = (*roughness_6);
    param_22 = _e376;
    let _e377 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_21), (&param_22));
    dirAlbedoL = _e377;
    let _e378 = (*roughness_6);
    param_23 = _e378;
    let _e379 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_23));
    avgAlbedo_1 = _e379;
    let _e380 = (*color_2);
    param_24 = _e380;
    let _e381 = mx_square_u0028_vf3_u003b((&param_24));
    let _e382 = avgAlbedo_1;
    let _e384 = (*color_2);
    let _e385 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e381 * _e382) / (vec3<f32>(1f, 1f, 1f) - (_e384 * max(0f, (1f - _e385)))));
    let _e391 = colorMultiScatter_1;
    let _e392 = dirAlbedoV;
    let _e396 = dirAlbedoL;
    let _e400 = avgAlbedo_1;
    lobeMultiScatter = (((_e391 * max(0.00000001f, (1f - _e392))) * max(0.00000001f, (1f - _e396))) / vec3(max(0.00000001f, (1f - _e400))));
    let _e405 = lobeSingleScatter;
    let _e406 = lobeMultiScatter;
    return (_e405 + _e406);
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N_1: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local_2: vec3<f32>;

    let _e328 = (*N_1);
    let _e329 = (*V);
    if (dot(_e328, _e329) < 0f) {
        let _e332 = (*N_1);
        local_2 = -(_e332);
    } else {
        let _e334 = (*N_1);
        local_2 = _e334;
    }
    let _e335 = local_2;
    return _e335;
}

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_2: ptr<function, ClosureData>, weight: ptr<function, f32>, color_3: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_2: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L: vec3<f32>;
    var param_25: vec3<f32>;
    var param_26: vec3<f32>;
    var NdotV_4: f32;
    var NdotL_2: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_27: f32;
    var param_28: f32;
    var param_29: f32;
    var param_30: f32;
    var param_31: vec3<f32>;
    var param_32: f32;
    var param_33: f32;
    var param_34: f32;
    var param_35: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_36: f32;
    var param_37: f32;
    var param_38: vec3<f32>;
    var param_39: f32;
    var param_40: f32;
    var Li_1: vec3<f32>;
    var param_41: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e360 = (*weight);
    if (_e360 < 0.00000001f) {
        return;
    }
    let _e363 = (*closureData_2).V;
    V_1 = _e363;
    let _e365 = (*closureData_2).L;
    L = _e365;
    let _e366 = (*N_2);
    param_25 = _e366;
    let _e367 = V_1;
    param_26 = _e367;
    let _e368 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_25), (&param_26));
    (*N_2) = _e368;
    let _e369 = (*N_2);
    let _e370 = V_1;
    NdotV_4 = clamp(dot(_e369, _e370), 0.00000001f, 1f);
    let _e374 = (*closureData_2).closureType;
    if (_e374 == 1i) {
        let _e376 = (*N_2);
        let _e377 = L;
        NdotL_2 = clamp(dot(_e376, _e377), 0.00000001f, 1f);
        let _e380 = L;
        let _e381 = V_1;
        LdotV_2 = clamp(dot(_e380, _e381), 0.00000001f, 1f);
        let _e384 = (*energy_compensation);
        if _e384 {
            let _e385 = NdotV_4;
            param_27 = _e385;
            let _e386 = NdotL_2;
            param_28 = _e386;
            let _e387 = LdotV_2;
            param_29 = _e387;
            let _e388 = (*roughness_7);
            param_30 = _e388;
            let _e389 = (*color_3);
            param_31 = _e389;
            let _e390 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_27), (&param_28), (&param_29), (&param_30), (&param_31));
            local_3 = _e390;
        } else {
            let _e391 = NdotV_4;
            param_32 = _e391;
            let _e392 = NdotL_2;
            param_33 = _e392;
            let _e393 = LdotV_2;
            param_34 = _e393;
            let _e394 = (*roughness_7);
            param_35 = _e394;
            let _e395 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_32), (&param_33), (&param_34), (&param_35));
            let _e396 = (*color_3);
            local_3 = (_e396 * _e395);
        }
        let _e398 = local_3;
        diffuse = _e398;
        let _e399 = diffuse;
        let _e401 = (*closureData_2).occlusion;
        let _e403 = (*weight);
        let _e405 = NdotL_2;
        (*bsdf).response = ((((_e399 * _e401) * _e403) * _e405) * 0.31830987f);
    } else {
        let _e410 = (*closureData_2).closureType;
        if (_e410 == 3i) {
            let _e412 = (*energy_compensation);
            if _e412 {
                let _e413 = NdotV_4;
                param_36 = _e413;
                let _e414 = (*roughness_7);
                param_37 = _e414;
                let _e415 = (*color_3);
                param_38 = _e415;
                let _e416 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_36), (&param_37), (&param_38));
                local_4 = _e416;
            } else {
                let _e417 = NdotV_4;
                param_39 = _e417;
                let _e418 = (*roughness_7);
                param_40 = _e418;
                let _e419 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_39), (&param_40));
                let _e420 = (*color_3);
                local_4 = (_e420 * _e419);
            }
            let _e422 = local_4;
            diffuse_1 = _e422;
            let _e423 = (*N_2);
            param_41 = _e423;
            let _e424 = mx_environment_irradiance_u0028_vf3_u003b((&param_41));
            Li_1 = _e424;
            let _e425 = Li_1;
            let _e426 = diffuse_1;
            let _e428 = (*weight);
            (*bsdf).response = ((_e425 * _e426) * _e428);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_3: ptr<function, ClosureData>, in1_: ptr<function, BSDF>, in2_: ptr<function, f32>, result_2: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e330 = (*in2_);
    weight_1 = clamp(_e330, 0f, 1f);
    let _e333 = (*in1_).response;
    let _e334 = weight_1;
    (*result_2).response = (_e333 * _e334);
    let _e338 = (*in1_).throughput;
    (*result_2).throughput = _e338;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, BSDF>, result_3: ptr<function, BSDF>) {
    let _e330 = (*in1_1).response;
    let _e332 = (*in2_1).response;
    (*result_3).response = (_e330 + _e332);
    let _e336 = (*in1_1).throughput;
    let _e338 = (*in2_1).throughput;
    (*result_3).throughput = max(((_e336 + _e338) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_3: ptr<function, f32>, NdotV_5: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_42: f32;
    var lambdaL: f32;
    var param_43: f32;
    var lambdaV: f32;
    var param_44: f32;

    let _e334 = (*alpha);
    param_42 = _e334;
    let _e335 = mx_square_u0028_f1_u003b((&param_42));
    alpha2_ = _e335;
    let _e336 = alpha2_;
    let _e337 = alpha2_;
    let _e339 = (*NdotL_3);
    param_43 = _e339;
    let _e340 = mx_square_u0028_f1_u003b((&param_43));
    lambdaL = sqrt((_e336 + ((1f - _e337) * _e340)));
    let _e344 = alpha2_;
    let _e345 = alpha2_;
    let _e347 = (*NdotV_5);
    param_44 = _e347;
    let _e348 = mx_square_u0028_f1_u003b((&param_44));
    lambdaV = sqrt((_e344 + ((1f - _e345) * _e348)));
    let _e352 = (*NdotL_3);
    let _e354 = (*NdotV_5);
    let _e356 = lambdaL;
    let _e357 = (*NdotV_5);
    let _e359 = lambdaV;
    let _e360 = (*NdotL_3);
    return (((2f * _e352) * _e354) / ((_e356 * _e357) + (_e359 * _e360)));
}

fn mx_pow6_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_45: f32;
    var param_46: f32;

    let _e329 = (*x_2);
    param_45 = _e329;
    let _e330 = mx_square_u0028_f1_u003b((&param_45));
    x2_ = _e330;
    let _e331 = x2_;
    param_46 = _e331;
    let _e332 = mx_square_u0028_f1_u003b((&param_46));
    let _e333 = x2_;
    return (_e332 * _e333);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_2: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_3: f32;
    var a_1: vec3<f32>;
    var param_47: f32;

    let _e330 = (*cosTheta_2);
    x_3 = clamp(_e330, 0f, 1f);
    let _e333 = (*fd).F0_;
    let _e335 = (*fd).F90_;
    let _e337 = (*fd).exponent;
    let _e342 = (*fd).F82_;
    a_1 = ((mix(_e333, _e335, vec3(pow(0.85714287f, _e337))) * (vec3<f32>(1f, 1f, 1f) - _e342)) * 17.651384f);
    let _e347 = (*fd).F0_;
    let _e349 = (*fd).F90_;
    let _e350 = x_3;
    let _e353 = (*fd).exponent;
    let _e357 = a_1;
    let _e358 = x_3;
    let _e360 = x_3;
    param_47 = (1f - _e360);
    let _e362 = mx_pow6_u0028_f1_u003b((&param_47));
    return (mix(_e347, _e349, vec3(pow((1f - _e350), _e353))) - ((_e357 * _e358) * _e362));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_3: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_48: f32;
    var sinTheta2_: f32;
    var n2_: vec3<f32>;
    var k2_: vec3<f32>;
    var t0_: vec3<f32>;
    var a2plusb2_: vec3<f32>;
    var t1_: vec3<f32>;
    var a_2: vec3<f32>;
    var t2_: vec3<f32>;
    var t3_: vec3<f32>;
    var t4_: vec3<f32>;

    let _e342 = (*cosTheta_3);
    param_48 = clamp(_e342, 0f, 1f);
    let _e344 = mx_square_u0028_f1_u003b((&param_48));
    cosTheta2_ = _e344;
    let _e345 = cosTheta2_;
    sinTheta2_ = (1f - _e345);
    let _e347 = (*n);
    let _e348 = (*n);
    n2_ = (_e347 * _e348);
    let _e350 = (*k);
    let _e351 = (*k);
    k2_ = (_e350 * _e351);
    let _e353 = n2_;
    let _e354 = k2_;
    let _e356 = sinTheta2_;
    t0_ = ((_e353 - _e354) - vec3(_e356));
    let _e359 = t0_;
    let _e360 = t0_;
    let _e362 = n2_;
    let _e364 = k2_;
    a2plusb2_ = sqrt(((_e359 * _e360) + ((_e362 * 4f) * _e364)));
    let _e368 = a2plusb2_;
    let _e369 = cosTheta2_;
    t1_ = (_e368 + vec3(_e369));
    let _e372 = a2plusb2_;
    let _e373 = t0_;
    a_2 = sqrt(max(((_e372 + _e373) * 0.5f), vec3(0f)));
    let _e379 = a_2;
    let _e381 = (*cosTheta_3);
    t2_ = ((_e379 * 2f) * _e381);
    let _e383 = t1_;
    let _e384 = t2_;
    let _e386 = t1_;
    let _e387 = t2_;
    (*Rs) = ((_e383 - _e384) / (_e386 + _e387));
    let _e390 = cosTheta2_;
    let _e391 = a2plusb2_;
    let _e393 = sinTheta2_;
    let _e394 = sinTheta2_;
    t3_ = ((_e391 * _e390) + vec3((_e393 * _e394)));
    let _e398 = t2_;
    let _e399 = sinTheta2_;
    t4_ = (_e398 * _e399);
    let _e401 = (*Rs);
    let _e402 = t3_;
    let _e403 = t4_;
    let _e406 = t3_;
    let _e407 = t4_;
    (*Rp) = ((_e401 * (_e402 - _e403)) / (_e406 + _e407));
    return;
}

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_4: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_49: f32;
    var param_50: vec3<f32>;
    var param_51: vec3<f32>;
    var param_52: vec3<f32>;
    var param_53: vec3<f32>;

    let _e335 = (*cosTheta_4);
    param_49 = _e335;
    let _e336 = (*n_1);
    param_50 = _e336;
    let _e337 = (*k_1);
    param_51 = _e337;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_49), (&param_50), (&param_51), (&param_52), (&param_53));
    let _e338 = param_52;
    Rp_1 = _e338;
    let _e339 = param_53;
    Rs_1 = _e339;
    let _e340 = Rp_1;
    let _e341 = Rs_1;
    return ((_e340 + _e341) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_5: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_54: f32;
    var param_55: f32;

    let _e332 = (*cosTheta_5);
    c_1 = _e332;
    let _e333 = (*ior);
    let _e334 = (*ior);
    let _e336 = c_1;
    let _e337 = c_1;
    g2_ = (((_e333 * _e334) + (_e336 * _e337)) - 1f);
    let _e341 = g2_;
    if (_e341 < 0f) {
        return 1f;
    }
    let _e343 = g2_;
    g = sqrt(_e343);
    let _e345 = g;
    let _e346 = c_1;
    let _e348 = g;
    let _e349 = c_1;
    param_54 = ((_e345 - _e346) / (_e348 + _e349));
    let _e352 = mx_square_u0028_f1_u003b((&param_54));
    let _e354 = g;
    let _e355 = c_1;
    let _e357 = c_1;
    let _e360 = g;
    let _e361 = c_1;
    let _e363 = c_1;
    param_55 = ((((_e354 + _e355) * _e357) - 1f) / (((_e360 - _e361) * _e363) + 1f));
    let _e367 = mx_square_u0028_f1_u003b((&param_55));
    return ((0.5f * _e352) * (1f + _e367));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e327 = (*m_1);
    let _e328 = (*v_2);
    return (_e327 * _e328);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e332 = (*opd);
    phase = (6.2831855f * _e332);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e334 = val;
    let _e335 = var_;
    let _e339 = pos;
    let _e340 = phase;
    let _e342 = (*shift);
    let _e346 = var_;
    let _e348 = phase;
    let _e350 = phase;
    xyz = (((_e334 * sqrt((_e335 * 6.2831855f))) * cos(((_e339 * _e340) + _e342))) * exp(((-(_e346) * _e348) * _e350)));
    let _e354 = phase;
    let _e357 = (*shift)[0u];
    let _e361 = phase;
    let _e363 = phase;
    let _e368 = xyz[0u];
    xyz[0u] = (_e368 + ((0.00000001644083f * cos(((2239900f * _e354) + _e357))) * exp(((-4528200000f * _e361) * _e363))));
    let _e371 = xyz;
    return (_e371 / vec3(0.00000010685f));
}

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_6: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_56: vec3<f32>;
    var U: vec3<f32>;
    var V_2: vec3<f32>;
    var param_57: f32;
    var param_58: vec3<f32>;

    let _e340 = (*kappa2_);
    let _e341 = (*eta2_);
    k2_1 = (_e340 / _e341);
    let _e343 = (*cosTheta_6);
    let _e344 = (*cosTheta_6);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e343 * _e344)));
    let _e348 = (*eta2_);
    let _e349 = (*eta2_);
    let _e351 = k2_1;
    let _e352 = k2_1;
    let _e356 = (*eta1_);
    let _e357 = (*eta1_);
    let _e359 = sinThetaSqr;
    A_4 = (((_e348 * _e349) * (vec3<f32>(1f, 1f, 1f) - (_e351 * _e352))) - (_e359 * (_e356 * _e357)));
    let _e362 = A_4;
    let _e363 = A_4;
    let _e365 = (*eta2_);
    let _e367 = (*eta2_);
    let _e369 = k2_1;
    param_56 = (((_e365 * 2f) * _e367) * _e369);
    let _e371 = mx_square_u0028_vf3_u003b((&param_56));
    B_2 = sqrt(((_e362 * _e363) + _e371));
    let _e374 = A_4;
    let _e375 = B_2;
    U = sqrt(((_e374 + _e375) / vec3(2f)));
    let _e380 = B_2;
    let _e381 = A_4;
    V_2 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e380 - _e381) / vec3(2f))));
    let _e387 = (*eta1_);
    let _e389 = V_2;
    let _e391 = (*cosTheta_6);
    let _e393 = U;
    let _e394 = U;
    let _e396 = V_2;
    let _e397 = V_2;
    let _e400 = (*eta1_);
    let _e401 = (*cosTheta_6);
    param_57 = (_e400 * _e401);
    let _e403 = mx_square_u0028_f1_u003b((&param_57));
    (*phiS) = atan2(((_e389 * (2f * _e387)) * _e391), (((_e393 * _e394) + (_e396 * _e397)) - vec3(_e403)));
    let _e407 = (*eta1_);
    let _e409 = (*eta2_);
    let _e411 = (*eta2_);
    let _e413 = (*cosTheta_6);
    let _e415 = k2_1;
    let _e417 = U;
    let _e419 = k2_1;
    let _e420 = k2_1;
    let _e423 = V_2;
    let _e427 = (*eta2_);
    let _e428 = (*eta2_);
    let _e430 = k2_1;
    let _e431 = k2_1;
    let _e435 = (*cosTheta_6);
    param_58 = (((_e427 * _e428) * (vec3<f32>(1f, 1f, 1f) + (_e430 * _e431))) * _e435);
    let _e437 = mx_square_u0028_vf3_u003b((&param_58));
    let _e438 = (*eta1_);
    let _e439 = (*eta1_);
    let _e441 = U;
    let _e442 = U;
    let _e444 = V_2;
    let _e445 = V_2;
    (*phiP) = atan2(((((_e409 * (2f * _e407)) * _e411) * _e413) * (((_e415 * 2f) * _e417) - ((vec3<f32>(1f, 1f, 1f) - (_e419 * _e420)) * _e423))), (_e437 - (((_e441 * _e442) + (_e444 * _e445)) * (_e438 * _e439))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_59: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e337 = (*cosTheta_7);
    param_59 = clamp(_e337, 0f, 1f);
    let _e339 = mx_square_u0028_f1_u003b((&param_59));
    cosTheta2_1 = _e339;
    let _e340 = cosTheta2_1;
    sinTheta2_1 = (1f - _e340);
    let _e342 = (*ior_1);
    let _e343 = (*ior_1);
    let _e345 = sinTheta2_1;
    t0_1 = max(((_e342 * _e343) - _e345), 0f);
    let _e348 = t0_1;
    let _e349 = cosTheta2_1;
    t1_1 = (_e348 + _e349);
    let _e351 = t0_1;
    let _e354 = (*cosTheta_7);
    t2_1 = ((2f * sqrt(_e351)) * _e354);
    let _e356 = t1_1;
    let _e357 = t2_1;
    let _e359 = t1_1;
    let _e360 = t2_1;
    Rs_2 = ((_e356 - _e357) / (_e359 + _e360));
    let _e363 = cosTheta2_1;
    let _e364 = t0_1;
    let _e366 = sinTheta2_1;
    let _e367 = sinTheta2_1;
    t3_1 = ((_e363 * _e364) + (_e366 * _e367));
    let _e370 = t2_1;
    let _e371 = sinTheta2_1;
    t4_1 = (_e370 * _e371);
    let _e373 = Rs_2;
    let _e374 = t3_1;
    let _e375 = t4_1;
    let _e378 = t3_1;
    let _e379 = t4_1;
    Rp_2 = ((_e373 * (_e374 - _e375)) / (_e378 + _e379));
    let _e382 = Rp_2;
    let _e383 = Rs_2;
    return vec2<f32>(_e382, _e383);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e327 = (*F0_);
    sqrtF0_ = sqrt(clamp(_e327, vec3(0.01f), vec3(0.99f)));
    let _e332 = sqrtF0_;
    let _e334 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e332) / (vec3<f32>(1f, 1f, 1f) - _e334));
}

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_8: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_60: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_61: f32;
    var param_62: f32;
    var R12_: vec2<f32>;
    var param_63: f32;
    var param_64: f32;
    var T121_: vec2<f32>;
    var f: vec3<f32>;
    var param_65: f32;
    var param_66: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_67: f32;
    var param_68: vec3<f32>;
    var param_69: vec3<f32>;
    var param_70: vec3<f32>;
    var param_71: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_72: f32;
    var param_73: f32;
    var param_74: vec3<f32>;
    var param_75: vec3<f32>;
    var param_76: vec3<f32>;
    var param_77: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_78: f32;
    var Cm: vec3<f32>;
    var m_2: i32;
    var Sm: vec3<f32>;
    var param_79: f32;
    var param_80: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_81: f32;
    var m_3: i32;
    var param_82: f32;
    var param_83: vec3<f32>;
    var param_84: mat3x3<f32>;
    var param_85: vec3<f32>;

    eta1_1 = 1f;
    let _e381 = (*fd_1).tf_ior;
    let _e382 = eta1_1;
    eta2_1 = max(_e381, _e382);
    let _e385 = (*fd_1).model;
    if (_e385 == 2i) {
        let _e388 = (*fd_1).F0_;
        param_60 = _e388;
        let _e389 = mx_f0_to_ior_u0028_vf3_u003b((&param_60));
        local_5 = _e389;
    } else {
        let _e391 = (*fd_1).ior;
        local_5 = _e391;
    }
    let _e392 = local_5;
    eta3_ = _e392;
    let _e394 = (*fd_1).model;
    if (_e394 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e397 = (*fd_1).extinction;
        local_6 = _e397;
    }
    let _e398 = local_6;
    kappa3_ = _e398;
    let _e399 = (*cosTheta_8);
    param_61 = _e399;
    let _e400 = mx_square_u0028_f1_u003b((&param_61));
    let _e402 = eta1_1;
    let _e403 = eta2_1;
    param_62 = (_e402 / _e403);
    let _e405 = mx_square_u0028_f1_u003b((&param_62));
    cosThetaT = sqrt((1f - ((1f - _e400) * _e405)));
    let _e409 = eta2_1;
    let _e410 = eta1_1;
    let _e412 = (*cosTheta_8);
    param_63 = _e412;
    param_64 = (_e409 / _e410);
    let _e413 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_63), (&param_64));
    R12_ = _e413;
    let _e414 = cosThetaT;
    if (_e414 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e416 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e416);
    let _e419 = (*fd_1).model;
    if (_e419 == 2i) {
        let _e421 = cosThetaT;
        param_65 = _e421;
        let _e422 = (*fd_1);
        param_66 = _e422;
        let _e423 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_65), (&param_66));
        f = _e423;
        let _e424 = f;
        R23p = (_e424 * 0.5f);
        let _e426 = f;
        R23s = (_e426 * 0.5f);
    } else {
        let _e428 = eta3_;
        let _e429 = eta2_1;
        let _e432 = kappa3_;
        let _e433 = eta2_1;
        let _e436 = cosThetaT;
        param_67 = _e436;
        param_68 = (_e428 / vec3(_e429));
        param_69 = (_e432 / vec3(_e433));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_67), (&param_68), (&param_69), (&param_70), (&param_71));
        let _e437 = param_70;
        R23p = _e437;
        let _e438 = param_71;
        R23s = _e438;
    }
    let _e439 = eta2_1;
    let _e440 = eta1_1;
    cosB = cos(atan((_e439 / _e440)));
    let _e444 = (*cosTheta_8);
    let _e445 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e444 < _e445)), 3.1415927f);
    let _e450 = (*fd_1).model;
    if (_e450 == 2i) {
        let _e453 = eta3_[0u];
        let _e454 = eta2_1;
        let _e458 = eta3_[1u];
        let _e459 = eta2_1;
        let _e463 = eta3_[2u];
        let _e464 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e453 < _e454)), select(0f, 3.1415927f, (_e458 < _e459)), select(0f, 3.1415927f, (_e463 < _e464)));
        let _e468 = phi23p;
        phi23s = _e468;
    } else {
        let _e469 = cosThetaT;
        param_72 = _e469;
        let _e470 = eta2_1;
        param_73 = _e470;
        let _e471 = eta3_;
        param_74 = _e471;
        let _e472 = kappa3_;
        param_75 = _e472;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_72), (&param_73), (&param_74), (&param_75), (&param_76), (&param_77));
        let _e473 = param_76;
        phi23p = _e473;
        let _e474 = param_77;
        phi23s = _e474;
    }
    let _e476 = R12_[0u];
    let _e477 = R23p;
    r123p = max(sqrt((_e477 * _e476)), vec3(0f));
    let _e483 = R12_[1u];
    let _e484 = R23s;
    r123s = max(sqrt((_e484 * _e483)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e490 = (*fd_1).tf_thickness;
    distMeters = (_e490 * 0.000000001f);
    let _e492 = eta2_1;
    let _e494 = cosThetaT;
    let _e496 = distMeters;
    opd_1 = (((2f * _e492) * _e494) * _e496);
    let _e499 = T121_[0u];
    param_78 = _e499;
    let _e500 = mx_square_u0028_f1_u003b((&param_78));
    let _e501 = R23p;
    let _e504 = R12_[0u];
    let _e505 = R23p;
    Rs_3 = ((_e501 * _e500) / (vec3<f32>(1f, 1f, 1f) - (_e505 * _e504)));
    let _e510 = R12_[0u];
    let _e511 = Rs_3;
    let _e514 = I;
    I = (_e514 + (vec3(_e510) + _e511));
    let _e516 = Rs_3;
    let _e518 = T121_[0u];
    Cm = (_e516 - vec3(_e518));
    m_2 = 1i;
    loop {
        let _e521 = m_2;
        if (_e521 <= 2i) {
            let _e523 = r123p;
            let _e524 = Cm;
            Cm = (_e524 * _e523);
            let _e526 = m_2;
            let _e528 = opd_1;
            let _e530 = m_2;
            let _e532 = phi23p;
            let _e534 = phi21_[0u];
            param_79 = (f32(_e526) * _e528);
            param_80 = ((_e532 + vec3(_e534)) * f32(_e530));
            let _e538 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_79), (&param_80));
            Sm = (_e538 * 2f);
            let _e540 = Cm;
            let _e541 = Sm;
            let _e543 = I;
            I = (_e543 + (_e540 * _e541));
            continue;
        } else {
            break;
        }
        continuing {
            let _e545 = m_2;
            m_2 = (_e545 + 1i);
        }
    }
    let _e548 = T121_[1u];
    param_81 = _e548;
    let _e549 = mx_square_u0028_f1_u003b((&param_81));
    let _e550 = R23s;
    let _e553 = R12_[1u];
    let _e554 = R23s;
    Rp_3 = ((_e550 * _e549) / (vec3<f32>(1f, 1f, 1f) - (_e554 * _e553)));
    let _e559 = R12_[1u];
    let _e560 = Rp_3;
    let _e563 = I;
    I = (_e563 + (vec3(_e559) + _e560));
    let _e565 = Rp_3;
    let _e567 = T121_[1u];
    Cm = (_e565 - vec3(_e567));
    m_3 = 1i;
    loop {
        let _e570 = m_3;
        if (_e570 <= 2i) {
            let _e572 = r123s;
            let _e573 = Cm;
            Cm = (_e573 * _e572);
            let _e575 = m_3;
            let _e577 = opd_1;
            let _e579 = m_3;
            let _e581 = phi23s;
            let _e583 = phi21_[1u];
            param_82 = (f32(_e575) * _e577);
            param_83 = ((_e581 + vec3(_e583)) * f32(_e579));
            let _e587 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_82), (&param_83));
            Sm = (_e587 * 2f);
            let _e589 = Cm;
            let _e590 = Sm;
            let _e592 = I;
            I = (_e592 + (_e589 * _e590));
            continue;
        } else {
            break;
        }
        continuing {
            let _e594 = m_3;
            m_3 = (_e594 + 1i);
        }
    }
    let _e596 = I;
    I = (_e596 * 0.5f);
    param_84 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e598 = I;
    param_85 = _e598;
    let _e599 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_84), (&param_85));
    I = clamp(_e599, vec3(0f), vec3(1f));
    let _e603 = I;
    return _e603;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_9: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_86: f32;
    var param_87: FresnelData;
    var param_88: f32;
    var param_89: f32;
    var param_90: f32;
    var param_91: vec3<f32>;
    var param_92: vec3<f32>;
    var param_93: f32;
    var param_94: FresnelData;

    let _e337 = (*fd_2).airy;
    if _e337 {
        let _e338 = (*cosTheta_9);
        param_86 = _e338;
        let _e339 = (*fd_2);
        param_87 = _e339;
        let _e340 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_86), (&param_87));
        return _e340;
    } else {
        let _e342 = (*fd_2).model;
        if (_e342 == 0i) {
            let _e344 = (*cosTheta_9);
            param_88 = _e344;
            let _e347 = (*fd_2).ior[0u];
            param_89 = _e347;
            let _e348 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_88), (&param_89));
            return vec3(_e348);
        } else {
            let _e351 = (*fd_2).model;
            if (_e351 == 1i) {
                let _e353 = (*cosTheta_9);
                param_90 = _e353;
                let _e355 = (*fd_2).ior;
                param_91 = _e355;
                let _e357 = (*fd_2).extinction;
                param_92 = _e357;
                let _e358 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_90), (&param_91), (&param_92));
                return _e358;
            } else {
                let _e359 = (*cosTheta_9);
                param_93 = _e359;
                let _e360 = (*fd_2);
                param_94 = _e360;
                let _e361 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_93), (&param_94));
                return _e361;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_95: mat4x4<f32>;
    var param_96: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_97: vec3<f32>;

    let _e333 = (*dir_2);
    let _e338 = (*transform_1);
    param_95 = _e338;
    param_96 = vec4<f32>(_e333.x, _e333.y, _e333.z, 0f);
    let _e339 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_95), (&param_96));
    envDir_1 = normalize(_e339.xyz);
    let _e342 = envDir_1;
    param_97 = _e342;
    let _e343 = mx_latlong_projection_u0028_vf3_u003b((&param_97));
    uv_2 = _e343;
    let _e344 = uv_2;
    let _e345 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e344, 0.0);
    return _e345.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_98: f32;

    let _e332 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e332 - 1.5f);
    let _e335 = (*dir_3)[1u];
    param_98 = _e335;
    let _e336 = mx_square_u0028_f1_u003b((&param_98));
    distortion = sqrt((1f - _e336));
    let _e339 = effectiveMaxMipLevel;
    let _e340 = (*envSamples);
    let _e342 = (*pdf);
    let _e344 = distortion;
    return max((_e339 - (0.5f * log2(((f32(_e340) * _e342) * _e344)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom: f32;
    var param_99: f32;
    var param_100: f32;

    let _e331 = (*H);
    let _e333 = (*alpha_1);
    He = (_e331.xy / _e333);
    let _e335 = He;
    let _e336 = He;
    let _e339 = (*H)[2u];
    param_99 = _e339;
    let _e340 = mx_square_u0028_f1_u003b((&param_99));
    denom = (dot(_e335, _e336) + _e340);
    let _e343 = (*alpha_1)[0u];
    let _e346 = (*alpha_1)[1u];
    let _e348 = denom;
    param_100 = _e348;
    let _e349 = mx_square_u0028_f1_u003b((&param_100));
    return (1f / (((3.1415927f * _e343) * _e346) * _e349));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_6: ptr<function, f32>) -> f32 {
    var param_101: vec3<f32>;
    var param_102: vec2<f32>;

    let _e331 = (*H_1);
    param_101 = _e331;
    let _e332 = (*alpha_2);
    param_102 = _e332;
    let _e333 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_101), (&param_102));
    let _e334 = (*G1V);
    let _e336 = (*NdotV_6);
    return ((_e333 * _e334) / (4f * _e336));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R: ptr<function, vec3<f32>>, N_3: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e329 = (*R);
    let _e330 = (*N_3);
    let _e331 = (*ior_2);
    (*R) = refract(_e329, _e330, (1f / _e331));
    let _e334 = (*R);
    let _e335 = (*R);
    let _e336 = (*N_3);
    let _e339 = (*N_3);
    N1_ = normalize(((_e334 * dot(_e335, _e336)) - (_e339 * 0.5f)));
    let _e343 = (*R);
    let _e344 = N1_;
    let _e345 = (*ior_2);
    return refract(_e343, _e344, _e345);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_3: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_4: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e335 = (*V_3);
    let _e337 = (*alpha_3);
    let _e338 = (_e335.xy * _e337);
    let _e340 = (*V_3)[2u];
    (*V_3) = normalize(vec3<f32>(_e338.x, _e338.y, _e340));
    let _e346 = (*Xi)[0u];
    phi = (6.2831855f * _e346);
    let _e349 = (*Xi)[1u];
    let _e352 = (*V_3)[2u];
    let _e356 = (*V_3)[2u];
    z = (((1f - _e349) * (1f + _e352)) - _e356);
    let _e358 = z;
    let _e359 = z;
    sinTheta = sqrt(clamp((1f - (_e358 * _e359)), 0f, 1f));
    let _e364 = sinTheta;
    let _e365 = phi;
    x_4 = (_e364 * cos(_e365));
    let _e368 = sinTheta;
    let _e369 = phi;
    y = (_e368 * sin(_e369));
    let _e372 = x_4;
    let _e373 = y;
    let _e374 = z;
    c_2 = vec3<f32>(_e372, _e373, _e374);
    let _e376 = c_2;
    let _e377 = (*V_3);
    H_2 = (_e376 + _e377);
    let _e379 = H_2;
    let _e381 = (*alpha_3);
    let _e382 = (_e379.xy * _e381);
    let _e384 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e382.x, _e382.y, max(_e384, 0f)));
    let _e390 = H_2;
    return _e390;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i: ptr<function, i32>) -> f32 {
    let _e326 = (*i);
    return fract(((f32(_e326) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_1: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_103: i32;

    let _e328 = (*i_1);
    let _e331 = (*numSamples);
    let _e334 = (*i_1);
    param_103 = _e334;
    let _e335 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_103));
    return vec2<f32>(((f32(_e328) + 0.5f) / f32(_e331)), _e335);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_10: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_104: f32;
    var tanTheta2_: f32;
    var param_105: f32;

    let _e331 = (*cosTheta_10);
    param_104 = _e331;
    let _e332 = mx_square_u0028_f1_u003b((&param_104));
    cosTheta2_2 = _e332;
    let _e333 = cosTheta2_2;
    let _e335 = cosTheta2_2;
    tanTheta2_ = ((1f - _e333) / _e335);
    let _e337 = (*alpha_4);
    param_105 = _e337;
    let _e338 = mx_square_u0028_f1_u003b((&param_105));
    let _e339 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e338 * _e339)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e327 = (*alpha_5)[0u];
    let _e329 = (*alpha_5)[1u];
    return sqrt((_e327 * _e329));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_4: ptr<function, vec3<f32>>, V_4: ptr<function, vec3<f32>>, X: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_7: f32;
    var avgAlpha: f32;
    var param_106: vec2<f32>;
    var G1V_1: f32;
    var param_107: f32;
    var param_108: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_2: i32;
    var Xi_1: vec2<f32>;
    var param_109: i32;
    var param_110: i32;
    var H_3: vec3<f32>;
    var param_111: vec2<f32>;
    var param_112: vec3<f32>;
    var param_113: vec2<f32>;
    var L_1: vec3<f32>;
    var local_7: vec3<f32>;
    var param_114: vec3<f32>;
    var param_115: vec3<f32>;
    var param_116: f32;
    var NdotL_4: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_117: mat3x3<f32>;
    var param_118: vec3<f32>;
    var pdf_1: f32;
    var param_119: vec3<f32>;
    var param_120: vec2<f32>;
    var param_121: f32;
    var param_122: f32;
    var lod_2: f32;
    var param_123: vec3<f32>;
    var param_124: f32;
    var param_125: f32;
    var param_126: i32;
    var sampleColor: vec3<f32>;
    var param_127: vec3<f32>;
    var param_128: mat4x4<f32>;
    var param_129: f32;
    var F: vec3<f32>;
    var param_130: f32;
    var param_131: FresnelData;
    var G_1: f32;
    var param_132: f32;
    var param_133: f32;
    var param_134: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e382 = (*X);
    let _e383 = (*X);
    let _e384 = (*N_4);
    let _e386 = (*N_4);
    (*X) = normalize((_e382 - (_e386 * dot(_e383, _e384))));
    let _e390 = (*N_4);
    let _e391 = (*X);
    Y = cross(_e390, _e391);
    let _e393 = (*X);
    let _e394 = Y;
    let _e395 = (*N_4);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e393.x, _e393.y, _e393.z), vec3<f32>(_e394.x, _e394.y, _e394.z), vec3<f32>(_e395.x, _e395.y, _e395.z));
    let _e409 = (*V_4);
    let _e410 = (*X);
    let _e412 = (*V_4);
    let _e413 = Y;
    let _e415 = (*V_4);
    let _e416 = (*N_4);
    (*V_4) = vec3<f32>(dot(_e409, _e410), dot(_e412, _e413), dot(_e415, _e416));
    let _e420 = (*V_4)[2u];
    NdotV_7 = clamp(_e420, 0.00000001f, 1f);
    let _e422 = (*alpha_6);
    param_106 = _e422;
    let _e423 = mx_average_alpha_u0028_vf2_u003b((&param_106));
    avgAlpha = _e423;
    let _e424 = NdotV_7;
    param_107 = _e424;
    let _e425 = avgAlpha;
    param_108 = _e425;
    let _e426 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_107), (&param_108));
    G1V_1 = _e426;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_2 = 0i;
    loop {
        let _e427 = i_2;
        let _e428 = envRadianceSamples;
        if (_e427 < _e428) {
            let _e430 = i_2;
            param_109 = _e430;
            let _e431 = envRadianceSamples;
            param_110 = _e431;
            let _e432 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_109), (&param_110));
            Xi_1 = _e432;
            let _e433 = Xi_1;
            param_111 = _e433;
            let _e434 = (*V_4);
            param_112 = _e434;
            let _e435 = (*alpha_6);
            param_113 = _e435;
            let _e436 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_111), (&param_112), (&param_113));
            H_3 = _e436;
            let _e438 = (*fd_3).refraction;
            if _e438 {
                let _e439 = (*V_4);
                param_114 = -(_e439);
                let _e441 = H_3;
                param_115 = _e441;
                let _e444 = (*fd_3).ior[0u];
                param_116 = _e444;
                let _e445 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_114), (&param_115), (&param_116));
                local_7 = _e445;
            } else {
                let _e446 = (*V_4);
                let _e447 = H_3;
                local_7 = -(reflect(_e446, _e447));
            }
            let _e450 = local_7;
            L_1 = _e450;
            let _e452 = L_1[2u];
            NdotL_4 = clamp(_e452, 0.00000001f, 1f);
            let _e454 = (*V_4);
            let _e455 = H_3;
            VdotH = clamp(dot(_e454, _e455), 0.00000001f, 1f);
            let _e458 = tangentToWorld;
            param_117 = _e458;
            let _e459 = L_1;
            param_118 = _e459;
            let _e460 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_117), (&param_118));
            Lw = _e460;
            let _e461 = H_3;
            param_119 = _e461;
            let _e462 = (*alpha_6);
            param_120 = _e462;
            let _e463 = G1V_1;
            param_121 = _e463;
            let _e464 = NdotV_7;
            param_122 = _e464;
            let _e465 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_119), (&param_120), (&param_121), (&param_122));
            pdf_1 = _e465;
            let _e466 = Lw;
            param_123 = _e466;
            let _e467 = pdf_1;
            param_124 = _e467;
            param_125 = 0f;
            let _e468 = envRadianceSamples;
            param_126 = _e468;
            let _e469 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_123), (&param_124), (&param_125), (&param_126));
            lod_2 = _e469;
            let _e470 = mtlxEnvMatrix_u0028_();
            let _e471 = Lw;
            param_127 = _e471;
            param_128 = _e470;
            let _e472 = lod_2;
            param_129 = _e472;
            let _e473 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_127), (&param_128), (&param_129));
            sampleColor = _e473;
            let _e474 = VdotH;
            param_130 = _e474;
            let _e475 = (*fd_3);
            param_131 = _e475;
            let _e476 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_130), (&param_131));
            F = _e476;
            let _e477 = NdotL_4;
            param_132 = _e477;
            let _e478 = NdotV_7;
            param_133 = _e478;
            let _e479 = avgAlpha;
            param_134 = _e479;
            let _e480 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_132), (&param_133), (&param_134));
            G_1 = _e480;
            let _e482 = (*fd_3).refraction;
            if _e482 {
                let _e483 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e483);
            } else {
                let _e485 = F;
                let _e486 = G_1;
                local_8 = (_e485 * _e486);
            }
            let _e488 = local_8;
            FG = _e488;
            let _e489 = sampleColor;
            let _e490 = FG;
            let _e492 = radiance;
            radiance = (_e492 + (_e489 * _e490));
            continue;
        } else {
            break;
        }
        continuing {
            let _e494 = i_2;
            i_2 = (_e494 + 1i);
        }
    }
    let _e496 = G1V_1;
    let _e497 = envRadianceSamples;
    let _e500 = radiance;
    radiance = (_e500 / vec3((_e496 * f32(_e497))));
    let _e503 = radiance;
    let _e506 = unnamed.skyPower;
    return (select(_e503, vec3<f32>(0f, 0f, 0f), false) * _e506);
}

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, V_5: ptr<function, vec3<f32>>, X_1: ptr<function, vec3<f32>>, alpha_7: ptr<function, vec2<f32>>, distribution_1: ptr<function, i32>, fd_4: ptr<function, FresnelData>, tint: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_135: vec3<f32>;
    var param_136: vec3<f32>;
    var param_137: vec3<f32>;
    var param_138: vec3<f32>;
    var param_139: vec2<f32>;
    var param_140: i32;
    var param_141: FresnelData;

    (*fd_4).refraction = true;
    if false {
        let _e340 = (*tint);
        param_135 = _e340;
        let _e341 = mx_square_u0028_vf3_u003b((&param_135));
        (*tint) = _e341;
    }
    let _e342 = (*N_5);
    param_136 = _e342;
    let _e343 = (*V_5);
    param_137 = _e343;
    let _e344 = (*X_1);
    param_138 = _e344;
    let _e345 = (*alpha_7);
    param_139 = _e345;
    let _e346 = (*distribution_1);
    param_140 = _e346;
    let _e347 = (*fd_4);
    param_141 = _e347;
    let _e348 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_136), (&param_137), (&param_138), (&param_139), (&param_140), (&param_141));
    let _e349 = (*tint);
    return (_e348 * _e349);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_1: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e327 = (*F0_1);
    sqrtF0_1 = sqrt(clamp(_e327, 0.01f, 0.99f));
    let _e330 = sqrtF0_1;
    let _e332 = sqrtF0_1;
    return ((1f + _e330) / (1f - _e332));
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_8: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_2: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_5: f32;
    var y_1: f32;
    var x2_1: f32;
    var param_142: f32;
    var y2_: f32;
    var param_143: f32;
    var r_1: vec4<f32>;
    var AB: vec2<f32>;

    let _e337 = (*NdotV_8);
    x_5 = _e337;
    let _e338 = (*alpha_8);
    y_1 = _e338;
    let _e339 = x_5;
    param_142 = _e339;
    let _e340 = mx_square_u0028_f1_u003b((&param_142));
    x2_1 = _e340;
    let _e341 = y_1;
    param_143 = _e341;
    let _e342 = mx_square_u0028_f1_u003b((&param_143));
    y2_ = _e342;
    let _e343 = x_5;
    let _e346 = y_1;
    let _e349 = x_5;
    let _e351 = y_1;
    let _e354 = x2_1;
    let _e357 = y2_;
    let _e360 = x2_1;
    let _e362 = y_1;
    let _e365 = x_5;
    let _e367 = y2_;
    let _e370 = x2_1;
    let _e372 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e343)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e346)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e349) * _e351)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e354)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e357)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e360) * _e362)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e365) * _e367)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e370) * _e372));
    let _e375 = r_1;
    let _e377 = r_1;
    AB = clamp((_e375.xy / _e377.zw), vec2(0f), vec2(1f));
    let _e383 = (*F0_2);
    let _e385 = AB[0u];
    let _e387 = (*F90_);
    let _e389 = AB[1u];
    return ((_e383 * _e385) + (_e387 * _e389));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_144: f32;
    var param_145: f32;
    var param_146: vec3<f32>;
    var param_147: vec3<f32>;

    let _e333 = (*NdotV_9);
    param_144 = _e333;
    let _e334 = (*alpha_9);
    param_145 = _e334;
    let _e335 = (*F0_3);
    param_146 = _e335;
    let _e336 = (*F90_1);
    param_147 = _e336;
    let _e337 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_144), (&param_145), (&param_146), (&param_147));
    return _e337;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_10: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_4: ptr<function, f32>, F90_2: ptr<function, f32>) -> f32 {
    var param_148: f32;
    var param_149: f32;
    var param_150: vec3<f32>;
    var param_151: vec3<f32>;

    let _e333 = (*F0_4);
    let _e335 = (*F90_2);
    let _e337 = (*NdotV_10);
    param_148 = _e337;
    let _e338 = (*alpha_10);
    param_149 = _e338;
    param_150 = vec3(_e333);
    param_151 = vec3(_e335);
    let _e339 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_148), (&param_149), (&param_150), (&param_151));
    return _e339.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_152: f32;
    var param_153: FresnelData;
    var F90_3: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3262_: bool;

    param_152 = 1f;
    let _e331 = (*fd_5);
    param_153 = _e331;
    let _e332 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_152), (&param_153));
    F0_5 = _e332;
    let _e334 = (*fd_5).model;
    let _e335 = (_e334 == 2i);
    phi_3262_ = _e335;
    if _e335 {
        let _e337 = (*fd_5).airy;
        phi_3262_ = !(_e337);
    }
    let _e340 = phi_3262_;
    if _e340 {
        let _e342 = (*fd_5).F90_;
        local_9 = _e342;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e343 = local_9;
    F90_3 = _e343;
    let _e344 = F0_5;
    let _e345 = F90_3;
    let _e346 = F0_5;
    return (_e344 + ((_e345 - _e346) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_11: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_154: FresnelData;
    var Ess: f32;
    var param_155: f32;
    var param_156: f32;
    var param_157: f32;
    var param_158: f32;

    let _e335 = (*fd_6);
    param_154 = _e335;
    let _e336 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_154));
    Fss = _e336;
    let _e337 = (*NdotV_11);
    param_155 = _e337;
    let _e338 = (*alpha_11);
    param_156 = _e338;
    param_157 = 1f;
    param_158 = 1f;
    let _e339 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_155), (&param_156), (&param_157), (&param_158));
    Ess = _e339;
    let _e340 = Fss;
    let _e341 = Ess;
    let _e344 = Ess;
    return (vec3(1f) + ((_e340 * (1f - _e341)) / vec3(_e344)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_6: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_4: ptr<function, vec3<f32>>, exponent: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e333 = (*tf_thickness);
    fd_7.airy = (_e333 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e338 = (*F0_6);
    fd_7.F0_ = _e338;
    let _e340 = (*F82_);
    fd_7.F82_ = _e340;
    let _e342 = (*F90_4);
    fd_7.F90_ = _e342;
    let _e344 = (*exponent);
    fd_7.exponent = _e344;
    let _e346 = (*tf_thickness);
    fd_7.tf_thickness = _e346;
    let _e348 = (*tf_ior);
    fd_7.tf_ior = _e348;
    fd_7.refraction = false;
    let _e351 = fd_7;
    return _e351;
}

fn mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color0_: ptr<function, vec3<f32>>, color82_: ptr<function, vec3<f32>>, color90_: ptr<function, vec3<f32>>, exponent_1: ptr<function, f32>, roughness_8: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_6: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, distribution_2: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_1: ptr<function, BSDF>) {
    var V_6: vec3<f32>;
    var L_2: vec3<f32>;
    var param_159: vec3<f32>;
    var param_160: vec3<f32>;
    var NdotV_12: f32;
    var safeColor0_: vec3<f32>;
    var safeColor82_: vec3<f32>;
    var safeColor90_: vec3<f32>;
    var fd_8: FresnelData;
    var param_161: vec3<f32>;
    var param_162: vec3<f32>;
    var param_163: vec3<f32>;
    var param_164: f32;
    var param_165: f32;
    var param_166: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_167: vec2<f32>;
    var Y_1: vec3<f32>;
    var H_4: vec3<f32>;
    var NdotL_5: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_1: vec3<f32>;
    var param_168: f32;
    var param_169: FresnelData;
    var D: f32;
    var param_170: vec3<f32>;
    var param_171: vec2<f32>;
    var G_2: f32;
    var param_172: f32;
    var param_173: f32;
    var param_174: f32;
    var comp: vec3<f32>;
    var param_175: f32;
    var param_176: f32;
    var param_177: FresnelData;
    var dirAlbedo_2: vec3<f32>;
    var param_178: f32;
    var param_179: f32;
    var param_180: vec3<f32>;
    var param_181: vec3<f32>;
    var avgDirAlbedo: f32;
    var comp_1: vec3<f32>;
    var param_182: f32;
    var param_183: f32;
    var param_184: FresnelData;
    var dirAlbedo_3: vec3<f32>;
    var param_185: f32;
    var param_186: f32;
    var param_187: vec3<f32>;
    var param_188: vec3<f32>;
    var avgDirAlbedo_1: f32;
    var avgF0_: f32;
    var param_189: f32;
    var param_190: vec3<f32>;
    var param_191: vec3<f32>;
    var param_192: vec3<f32>;
    var param_193: vec2<f32>;
    var param_194: i32;
    var param_195: FresnelData;
    var param_196: vec3<f32>;
    var comp_2: vec3<f32>;
    var param_197: f32;
    var param_198: f32;
    var param_199: FresnelData;
    var dirAlbedo_4: vec3<f32>;
    var param_200: f32;
    var param_201: f32;
    var param_202: vec3<f32>;
    var param_203: vec3<f32>;
    var avgDirAlbedo_2: f32;
    var Li_2: vec3<f32>;
    var param_204: vec3<f32>;
    var param_205: vec3<f32>;
    var param_206: vec3<f32>;
    var param_207: vec2<f32>;
    var param_208: i32;
    var param_209: FresnelData;
    var phi_4930_: bool;

    let _e419 = (*weight_2);
    if (_e419 < 0.00000001f) {
        return;
    }
    let _e422 = (*closureData_5).closureType;
    let _e424 = (*scatter_mode);
    if ((_e422 != 2i) && (_e424 == 1i)) {
        return;
    }
    let _e428 = (*closureData_5).V;
    V_6 = _e428;
    let _e430 = (*closureData_5).L;
    L_2 = _e430;
    let _e431 = (*retroreflective);
    phi_4930_ = _e431;
    if _e431 {
        let _e433 = (*closureData_5).closureType;
        phi_4930_ = (_e433 != 2i);
    }
    let _e436 = phi_4930_;
    if _e436 {
        let _e437 = V_6;
        let _e439 = (*N_6);
        V_6 = reflect(-(_e437), _e439);
    }
    let _e441 = (*N_6);
    param_159 = _e441;
    let _e442 = V_6;
    param_160 = _e442;
    let _e443 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_159), (&param_160));
    (*N_6) = _e443;
    let _e444 = (*N_6);
    let _e445 = V_6;
    NdotV_12 = clamp(dot(_e444, _e445), 0.00000001f, 1f);
    let _e448 = (*color0_);
    safeColor0_ = max(_e448, vec3(0f));
    let _e451 = (*color82_);
    safeColor82_ = max(_e451, vec3(0f));
    let _e454 = (*color90_);
    safeColor90_ = max(_e454, vec3(0f));
    let _e457 = safeColor0_;
    param_161 = _e457;
    let _e458 = safeColor82_;
    param_162 = _e458;
    let _e459 = safeColor90_;
    param_163 = _e459;
    let _e460 = (*exponent_1);
    param_164 = _e460;
    let _e461 = (*thinfilm_thickness);
    param_165 = _e461;
    let _e462 = (*thinfilm_ior);
    param_166 = _e462;
    let _e463 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_161), (&param_162), (&param_163), (&param_164), (&param_165), (&param_166));
    fd_8 = _e463;
    let _e464 = (*roughness_8);
    safeAlpha = clamp(_e464, vec2(0.00000001f), vec2(1f));
    let _e468 = safeAlpha;
    param_167 = _e468;
    let _e469 = mx_average_alpha_u0028_vf2_u003b((&param_167));
    avgAlpha_1 = _e469;
    let _e471 = (*closureData_5).closureType;
    if (_e471 == 1i) {
        let _e473 = (*X_2);
        let _e474 = (*X_2);
        let _e475 = (*N_6);
        let _e477 = (*N_6);
        (*X_2) = normalize((_e473 - (_e477 * dot(_e474, _e475))));
        let _e481 = (*N_6);
        let _e482 = (*X_2);
        Y_1 = cross(_e481, _e482);
        let _e484 = L_2;
        let _e485 = V_6;
        H_4 = normalize((_e484 + _e485));
        let _e488 = (*N_6);
        let _e489 = L_2;
        NdotL_5 = clamp(dot(_e488, _e489), 0.00000001f, 1f);
        let _e492 = V_6;
        let _e493 = H_4;
        VdotH_1 = clamp(dot(_e492, _e493), 0.00000001f, 1f);
        let _e496 = H_4;
        let _e497 = (*X_2);
        let _e499 = H_4;
        let _e500 = Y_1;
        let _e502 = H_4;
        let _e503 = (*N_6);
        Ht = vec3<f32>(dot(_e496, _e497), dot(_e499, _e500), dot(_e502, _e503));
        let _e506 = VdotH_1;
        param_168 = _e506;
        let _e507 = fd_8;
        param_169 = _e507;
        let _e508 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_168), (&param_169));
        F_1 = _e508;
        let _e509 = Ht;
        param_170 = _e509;
        let _e510 = safeAlpha;
        param_171 = _e510;
        let _e511 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_170), (&param_171));
        D = _e511;
        let _e512 = NdotL_5;
        param_172 = _e512;
        let _e513 = NdotV_12;
        param_173 = _e513;
        let _e514 = avgAlpha_1;
        param_174 = _e514;
        let _e515 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_172), (&param_173), (&param_174));
        G_2 = _e515;
        let _e516 = NdotV_12;
        param_175 = _e516;
        let _e517 = avgAlpha_1;
        param_176 = _e517;
        let _e518 = fd_8;
        param_177 = _e518;
        let _e519 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_175), (&param_176), (&param_177));
        comp = _e519;
        let _e520 = NdotV_12;
        param_178 = _e520;
        let _e521 = avgAlpha_1;
        param_179 = _e521;
        let _e522 = safeColor0_;
        param_180 = _e522;
        let _e523 = safeColor90_;
        param_181 = _e523;
        let _e524 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_178), (&param_179), (&param_180), (&param_181));
        let _e525 = comp;
        dirAlbedo_2 = (_e524 * _e525);
        let _e527 = dirAlbedo_2;
        avgDirAlbedo = dot(_e527, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e529 = avgDirAlbedo;
        let _e530 = (*weight_2);
        (*bsdf_1).throughput = vec3((1f - (_e529 * _e530)));
        let _e535 = D;
        let _e536 = F_1;
        let _e538 = G_2;
        let _e540 = comp;
        let _e543 = (*closureData_5).occlusion;
        let _e545 = (*weight_2);
        let _e547 = NdotV_12;
        (*bsdf_1).response = ((((((_e536 * _e535) * _e538) * _e540) * _e543) * _e545) / vec3((4f * _e547)));
    } else {
        let _e553 = (*closureData_5).closureType;
        if (_e553 == 2i) {
            let _e555 = NdotV_12;
            param_182 = _e555;
            let _e556 = avgAlpha_1;
            param_183 = _e556;
            let _e557 = fd_8;
            param_184 = _e557;
            let _e558 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_182), (&param_183), (&param_184));
            comp_1 = _e558;
            let _e559 = NdotV_12;
            param_185 = _e559;
            let _e560 = avgAlpha_1;
            param_186 = _e560;
            let _e561 = safeColor0_;
            param_187 = _e561;
            let _e562 = safeColor90_;
            param_188 = _e562;
            let _e563 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_185), (&param_186), (&param_187), (&param_188));
            let _e564 = comp_1;
            dirAlbedo_3 = (_e563 * _e564);
            let _e566 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e566, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e568 = avgDirAlbedo_1;
            let _e569 = (*weight_2);
            (*bsdf_1).throughput = vec3((1f - (_e568 * _e569)));
            let _e574 = (*scatter_mode);
            if (_e574 != 0i) {
                let _e576 = safeColor0_;
                avgF0_ = dot(_e576, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e578 = avgF0_;
                param_189 = _e578;
                let _e579 = mx_f0_to_ior_u0028_f1_u003b((&param_189));
                fd_8.ior = vec3(_e579);
                let _e582 = (*N_6);
                param_190 = _e582;
                let _e583 = V_6;
                param_191 = _e583;
                let _e584 = (*X_2);
                param_192 = _e584;
                let _e585 = safeAlpha;
                param_193 = _e585;
                let _e586 = (*distribution_2);
                param_194 = _e586;
                let _e587 = fd_8;
                param_195 = _e587;
                param_196 = vec3<f32>(1f, 1f, 1f);
                let _e588 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_190), (&param_191), (&param_192), (&param_193), (&param_194), (&param_195), (&param_196));
                let _e589 = (*weight_2);
                (*bsdf_1).response = (_e588 * _e589);
            }
        } else {
            let _e593 = (*closureData_5).closureType;
            if (_e593 == 3i) {
                let _e595 = NdotV_12;
                param_197 = _e595;
                let _e596 = avgAlpha_1;
                param_198 = _e596;
                let _e597 = fd_8;
                param_199 = _e597;
                let _e598 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_197), (&param_198), (&param_199));
                comp_2 = _e598;
                let _e599 = NdotV_12;
                param_200 = _e599;
                let _e600 = avgAlpha_1;
                param_201 = _e600;
                let _e601 = safeColor0_;
                param_202 = _e601;
                let _e602 = safeColor90_;
                param_203 = _e602;
                let _e603 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_200), (&param_201), (&param_202), (&param_203));
                let _e604 = comp_2;
                dirAlbedo_4 = (_e603 * _e604);
                let _e606 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e606, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e608 = avgDirAlbedo_2;
                let _e609 = (*weight_2);
                (*bsdf_1).throughput = vec3((1f - (_e608 * _e609)));
                let _e614 = (*N_6);
                param_204 = _e614;
                let _e615 = V_6;
                param_205 = _e615;
                let _e616 = (*X_2);
                param_206 = _e616;
                let _e617 = safeAlpha;
                param_207 = _e617;
                let _e618 = (*distribution_2);
                param_208 = _e618;
                let _e619 = fd_8;
                param_209 = _e619;
                let _e620 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_204), (&param_205), (&param_206), (&param_207), (&param_208), (&param_209));
                Li_2 = _e620;
                let _e621 = Li_2;
                let _e622 = comp_2;
                let _e624 = (*weight_2);
                (*bsdf_1).response = ((_e621 * _e622) * _e624);
            }
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_4: f32;
    var o: f32;
    var param_210: f32;

    let _e331 = (*y_2);
    let _e332 = (*y_2);
    let _e336 = (*y_2);
    let _e337 = (*y_2);
    s_3 = ((_e331 * (0.0206607f + (1.58491f * _e332))) / (0.0379424f + (_e336 * (1.32227f + _e337))));
    let _e342 = (*y_2);
    let _e343 = (*y_2);
    let _e344 = (*y_2);
    let _e345 = (*y_2);
    let _e347 = (*y_2);
    let _e355 = (*y_2);
    m_4 = ((_e342 * (-0.193854f + (_e343 * (-1.14885f + (_e344 * (1.7932f - ((0.95943f * _e345) * _e347))))))) / (0.046391f + _e355));
    let _e358 = (*y_2);
    let _e359 = (*y_2);
    let _e362 = (*y_2);
    let _e366 = (*y_2);
    let _e367 = (*y_2);
    o = ((_e358 * (0.000654023f + ((-0.0207818f + (0.119681f * _e359)) * _e362))) / (1.26264f + (_e366 * (-1.92021f + _e367))));
    let _e372 = (*x_6);
    let _e373 = m_4;
    let _e375 = s_3;
    param_210 = ((_e372 - _e373) / _e375);
    let _e377 = mx_square_u0028_f1_u003b((&param_210));
    let _e380 = s_3;
    let _e383 = o;
    return ((exp((-0.5f * _e377)) / (_e380 * 2.5066283f)) + _e383);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_11: ptr<function, f32>) -> f32 {
    let _e326 = (*cosTheta_11);
    return (max(_e326, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_7: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e327 = (*x_7);
    let _e330 = (*y_3);
    let _e333 = (*y_3);
    let _e335 = (*y_3);
    let _e337 = (*y_3);
    let _e339 = (*x_7);
    let _e342 = (*x_7);
    let _e344 = (*y_3);
    let _e347 = (*y_3);
    let _e349 = (*y_3);
    return (((((sqrt((1f - _e327)) * (_e330 - 1f)) * _e333) * _e335) * _e337) / (((0.0000254053f + (1.71228f * _e339)) - ((1.71506f * _e342) * _e344)) + ((1.34174f * _e347) * _e349)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e327 = (*x_8);
    let _e329 = (*y_4);
    let _e332 = (*y_4);
    let _e334 = (*x_8);
    let _e336 = (*x_8);
    let _e339 = (*x_8);
    let _e341 = (*y_4);
    return ((((2.58126f * _e327) + (0.813703f * _e329)) * _e332) / ((1f + ((0.310327f * _e334) * _e336)) + ((2.60994f * _e339) * _e341)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_7: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_3: vec3<f32>;
    var Y_2: vec3<f32>;

    let _e332 = (*N_7)[2u];
    sign_ = select(1f, -1f, (_e332 < 0f));
    let _e335 = sign_;
    let _e337 = (*N_7)[2u];
    a_3 = (-1f / (_e335 + _e337));
    let _e341 = (*N_7)[0u];
    let _e343 = (*N_7)[1u];
    let _e345 = a_3;
    b = ((_e341 * _e343) * _e345);
    let _e347 = sign_;
    let _e349 = (*N_7)[0u];
    let _e352 = (*N_7)[0u];
    let _e354 = a_3;
    let _e357 = sign_;
    let _e358 = b;
    let _e360 = sign_;
    let _e363 = (*N_7)[0u];
    X_3 = vec3<f32>((1f + (((_e347 * _e349) * _e352) * _e354)), (_e357 * _e358), (-(_e360) * _e363));
    let _e366 = b;
    let _e367 = sign_;
    let _e369 = (*N_7)[1u];
    let _e371 = (*N_7)[1u];
    let _e373 = a_3;
    let _e377 = (*N_7)[1u];
    Y_2 = vec3<f32>(_e366, (_e367 + ((_e369 * _e371) * _e373)), -(_e377));
    let _e380 = X_3;
    let _e381 = Y_2;
    let _e382 = (*N_7);
    return mat3x3<f32>(vec3<f32>(_e380.x, _e380.y, _e380.z), vec3<f32>(_e381.x, _e381.y, _e381.z), vec3<f32>(_e382.x, _e382.y, _e382.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_7: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, NdotV_13: ptr<function, f32>) -> mat3x3<f32> {
    var X_4: vec3<f32>;
    var lenSqr: f32;
    var Y_3: vec3<f32>;
    var param_211: vec3<f32>;

    let _e332 = (*V_7);
    let _e333 = (*N_8);
    let _e334 = (*NdotV_13);
    X_4 = (_e332 - (_e333 * _e334));
    let _e337 = X_4;
    let _e338 = X_4;
    lenSqr = dot(_e337, _e338);
    let _e340 = lenSqr;
    if (_e340 > 0f) {
        let _e342 = lenSqr;
        let _e344 = X_4;
        X_4 = (_e344 * inverseSqrt(_e342));
        let _e346 = (*N_8);
        let _e347 = X_4;
        Y_3 = cross(_e346, _e347);
        let _e349 = X_4;
        let _e350 = Y_3;
        let _e351 = (*N_8);
        return mat3x3<f32>(vec3<f32>(_e349.x, _e349.y, _e349.z), vec3<f32>(_e350.x, _e350.y, _e350.z), vec3<f32>(_e351.x, _e351.y, _e351.z));
    }
    let _e365 = (*N_8);
    param_211 = _e365;
    let _e366 = mx_orthonormal_basis_u0028_vf3_u003b((&param_211));
    return _e366;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_3: ptr<function, vec3<f32>>, V_8: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_14: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_212: vec3<f32>;
    var param_213: vec3<f32>;
    var param_214: f32;
    var w: vec3<f32>;
    var param_215: mat3x3<f32>;
    var param_216: vec3<f32>;
    var aInv: f32;
    var param_217: f32;
    var param_218: f32;
    var bInv: f32;
    var param_219: f32;
    var param_220: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_221: f32;
    var param_222: f32;

    let _e347 = (*V_8);
    param_212 = _e347;
    let _e348 = (*N_9);
    param_213 = _e348;
    let _e349 = (*NdotV_14);
    param_214 = _e349;
    let _e350 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_212), (&param_213), (&param_214));
    toLTC = transpose(_e350);
    let _e352 = toLTC;
    param_215 = _e352;
    let _e353 = (*L_3);
    param_216 = _e353;
    let _e354 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_215), (&param_216));
    w = _e354;
    let _e355 = (*NdotV_14);
    param_217 = _e355;
    let _e356 = (*roughness_9);
    param_218 = _e356;
    let _e357 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_217), (&param_218));
    aInv = _e357;
    let _e358 = (*NdotV_14);
    param_219 = _e358;
    let _e359 = (*roughness_9);
    param_220 = _e359;
    let _e360 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_219), (&param_220));
    bInv = _e360;
    let _e361 = aInv;
    let _e363 = w[0u];
    let _e365 = bInv;
    let _e367 = w[2u];
    let _e370 = aInv;
    let _e372 = w[1u];
    let _e375 = w[2u];
    wo = vec3<f32>(((_e361 * _e363) + (_e365 * _e367)), (_e370 * _e372), _e375);
    let _e377 = wo;
    let _e378 = wo;
    lenSqr_1 = dot(_e377, _e378);
    let _e381 = wo[2u];
    param_221 = _e381;
    let _e382 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_221));
    let _e383 = aInv;
    let _e384 = lenSqr_1;
    param_222 = (_e383 / _e384);
    let _e386 = mx_square_u0028_f1_u003b((&param_222));
    return (_e382 * _e386);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_15: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_223: f32;
    var param_224: f32;

    let _e330 = (*NdotV_15);
    let _e333 = (*roughness_10);
    let _e336 = (*NdotV_15);
    let _e338 = (*roughness_10);
    let _e341 = (*NdotV_15);
    param_223 = _e341;
    let _e342 = mx_square_u0028_f1_u003b((&param_223));
    let _e345 = (*roughness_10);
    param_224 = _e345;
    let _e346 = mx_square_u0028_f1_u003b((&param_224));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e330)) + (vec2<f32>(799.08826f, 442.7821f) * _e333)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e336) * _e338)) + (vec2<f32>(60.28956f, 121.81241f) * _e342)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e346));
    let _e350 = r_2[0u];
    let _e352 = r_2[1u];
    return (_e350 / _e352);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_16: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var dirAlbedo_5: f32;
    var param_225: f32;
    var param_226: f32;

    let _e330 = (*NdotV_16);
    param_225 = _e330;
    let _e331 = (*roughness_11);
    param_226 = _e331;
    let _e332 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_225), (&param_226));
    dirAlbedo_5 = _e332;
    let _e333 = dirAlbedo_5;
    return clamp(_e333, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e330 = (*roughness_12);
    invRoughness = (1f / max(_e330, 0.005f));
    let _e333 = (*NdotH);
    let _e334 = (*NdotH);
    cos2_ = (_e333 * _e334);
    let _e336 = cos2_;
    sin2_ = (1f - _e336);
    let _e338 = invRoughness;
    let _e340 = sin2_;
    let _e341 = invRoughness;
    return (((2f + _e338) * pow(_e340, (_e341 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_6: ptr<function, f32>, NdotV_17: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var D_1: f32;
    var param_227: f32;
    var param_228: f32;
    var F_2: f32;
    var G_3: f32;

    let _e334 = (*NdotH_1);
    param_227 = _e334;
    let _e335 = (*roughness_13);
    param_228 = _e335;
    let _e336 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_227), (&param_228));
    D_1 = _e336;
    F_2 = 1f;
    G_3 = 1f;
    let _e337 = D_1;
    let _e338 = F_2;
    let _e340 = G_3;
    let _e342 = (*NdotL_6);
    let _e343 = (*NdotV_17);
    let _e345 = (*NdotL_6);
    let _e346 = (*NdotV_17);
    return (((_e337 * _e338) * _e340) / (4f * ((_e342 + _e343) - (_e345 * _e346))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, weight_3: ptr<function, f32>, color_4: ptr<function, vec3<f32>>, roughness_14: ptr<function, f32>, N_10: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_2: ptr<function, BSDF>) {
    var V_9: vec3<f32>;
    var L_4: vec3<f32>;
    var param_229: vec3<f32>;
    var param_230: vec3<f32>;
    var NdotV_18: f32;
    var H_5: vec3<f32>;
    var NdotL_7: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_231: f32;
    var param_232: f32;
    var param_233: f32;
    var param_234: f32;
    var dirAlbedo_6: f32;
    var param_235: f32;
    var param_236: f32;
    var fr_1: vec3<f32>;
    var param_237: vec3<f32>;
    var param_238: vec3<f32>;
    var param_239: vec3<f32>;
    var param_240: f32;
    var param_241: f32;
    var param_242: f32;
    var param_243: f32;
    var dirAlbedo_7: f32;
    var param_244: f32;
    var param_245: f32;
    var param_246: f32;
    var param_247: f32;
    var Li_3: vec3<f32>;
    var param_248: vec3<f32>;

    let _e363 = (*weight_3);
    if (_e363 < 0.00000001f) {
        return;
    }
    let _e366 = (*closureData_6).V;
    V_9 = _e366;
    let _e368 = (*closureData_6).L;
    L_4 = _e368;
    let _e369 = (*N_10);
    param_229 = _e369;
    let _e370 = V_9;
    param_230 = _e370;
    let _e371 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_229), (&param_230));
    (*N_10) = _e371;
    let _e372 = (*N_10);
    let _e373 = V_9;
    NdotV_18 = clamp(dot(_e372, _e373), 0.00000001f, 1f);
    let _e377 = (*closureData_6).closureType;
    if (_e377 == 1i) {
        let _e379 = (*mode);
        if (_e379 == 0i) {
            let _e381 = L_4;
            let _e382 = V_9;
            H_5 = normalize((_e381 + _e382));
            let _e385 = (*N_10);
            let _e386 = L_4;
            NdotL_7 = clamp(dot(_e385, _e386), 0.00000001f, 1f);
            let _e389 = (*N_10);
            let _e390 = H_5;
            NdotH_2 = clamp(dot(_e389, _e390), 0.00000001f, 1f);
            let _e393 = (*color_4);
            let _e394 = NdotL_7;
            param_231 = _e394;
            let _e395 = NdotV_18;
            param_232 = _e395;
            let _e396 = NdotH_2;
            param_233 = _e396;
            let _e397 = (*roughness_14);
            param_234 = _e397;
            let _e398 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_231), (&param_232), (&param_233), (&param_234));
            fr = (_e393 * _e398);
            let _e400 = NdotV_18;
            param_235 = _e400;
            let _e401 = (*roughness_14);
            param_236 = _e401;
            let _e402 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_235), (&param_236));
            dirAlbedo_6 = _e402;
            let _e403 = fr;
            let _e404 = NdotL_7;
            let _e407 = (*closureData_6).occlusion;
            let _e409 = (*weight_3);
            (*bsdf_2).response = (((_e403 * _e404) * _e407) * _e409);
        } else {
            let _e412 = (*roughness_14);
            (*roughness_14) = clamp(_e412, 0.01f, 1f);
            let _e414 = (*color_4);
            let _e415 = L_4;
            param_237 = _e415;
            let _e416 = V_9;
            param_238 = _e416;
            let _e417 = (*N_10);
            param_239 = _e417;
            let _e418 = NdotV_18;
            param_240 = _e418;
            let _e419 = (*roughness_14);
            param_241 = _e419;
            let _e420 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_237), (&param_238), (&param_239), (&param_240), (&param_241));
            fr_1 = (_e414 * _e420);
            let _e422 = NdotV_18;
            param_242 = _e422;
            let _e423 = (*roughness_14);
            param_243 = _e423;
            let _e424 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_242), (&param_243));
            dirAlbedo_6 = _e424;
            let _e425 = dirAlbedo_6;
            let _e426 = fr_1;
            let _e429 = (*closureData_6).occlusion;
            let _e431 = (*weight_3);
            (*bsdf_2).response = (((_e426 * _e425) * _e429) * _e431);
        }
        let _e434 = dirAlbedo_6;
        let _e435 = (*weight_3);
        (*bsdf_2).throughput = vec3((1f - (_e434 * _e435)));
    } else {
        let _e441 = (*closureData_6).closureType;
        if (_e441 == 3i) {
            let _e443 = (*mode);
            if (_e443 == 0i) {
                let _e445 = NdotV_18;
                param_244 = _e445;
                let _e446 = (*roughness_14);
                param_245 = _e446;
                let _e447 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_244), (&param_245));
                dirAlbedo_7 = _e447;
            } else {
                let _e448 = (*roughness_14);
                (*roughness_14) = clamp(_e448, 0.01f, 1f);
                let _e450 = NdotV_18;
                param_246 = _e450;
                let _e451 = (*roughness_14);
                param_247 = _e451;
                let _e452 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_246), (&param_247));
                dirAlbedo_7 = _e452;
            }
            let _e453 = (*N_10);
            param_248 = _e453;
            let _e454 = mx_environment_irradiance_u0028_vf3_u003b((&param_248));
            Li_3 = _e454;
            let _e455 = Li_3;
            let _e456 = (*color_4);
            let _e458 = dirAlbedo_7;
            let _e460 = (*weight_3);
            (*bsdf_2).response = (((_e455 * _e456) * _e458) * _e460);
            let _e463 = dirAlbedo_7;
            let _e464 = (*weight_3);
            (*bsdf_2).throughput = vec3((1f - (_e463 * _e464)));
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_249: f32;

    let _e327 = (*ior_3);
    let _e329 = (*ior_3);
    param_249 = ((_e327 - 1f) / (_e329 + 1f));
    let _e332 = mx_square_u0028_f1_u003b((&param_249));
    return _e332;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e330 = (*tf_thickness_1);
    fd_9.airy = (_e330 > 0f);
    let _e333 = (*ior_4);
    fd_9.ior = vec3(_e333);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e341 = (*tf_thickness_1);
    fd_9.tf_thickness = _e341;
    let _e343 = (*tf_ior_1);
    fd_9.tf_ior = _e343;
    fd_9.refraction = false;
    let _e346 = fd_9;
    return _e346;
}

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, weight_4: ptr<function, f32>, tint_1: ptr<function, vec3<f32>>, ior_5: ptr<function, f32>, roughness_15: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, X_5: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode_1: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_10: vec3<f32>;
    var L_5: vec3<f32>;
    var param_250: vec3<f32>;
    var param_251: vec3<f32>;
    var NdotV_19: f32;
    var fd_10: FresnelData;
    var param_252: f32;
    var param_253: f32;
    var param_254: f32;
    var F0_7: f32;
    var param_255: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_256: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_4: vec3<f32>;
    var H_6: vec3<f32>;
    var NdotL_8: f32;
    var VdotH_2: f32;
    var Ht_1: vec3<f32>;
    var F_3: vec3<f32>;
    var param_257: f32;
    var param_258: FresnelData;
    var D_2: f32;
    var param_259: vec3<f32>;
    var param_260: vec2<f32>;
    var G_4: f32;
    var param_261: f32;
    var param_262: f32;
    var param_263: f32;
    var comp_3: vec3<f32>;
    var param_264: f32;
    var param_265: f32;
    var param_266: FresnelData;
    var dirAlbedo_8: vec3<f32>;
    var param_267: f32;
    var param_268: f32;
    var param_269: f32;
    var param_270: f32;
    var comp_4: vec3<f32>;
    var param_271: f32;
    var param_272: f32;
    var param_273: FresnelData;
    var dirAlbedo_9: vec3<f32>;
    var param_274: f32;
    var param_275: f32;
    var param_276: f32;
    var param_277: f32;
    var param_278: vec3<f32>;
    var param_279: vec3<f32>;
    var param_280: vec3<f32>;
    var param_281: vec2<f32>;
    var param_282: i32;
    var param_283: FresnelData;
    var param_284: vec3<f32>;
    var comp_5: vec3<f32>;
    var param_285: f32;
    var param_286: f32;
    var param_287: FresnelData;
    var dirAlbedo_10: vec3<f32>;
    var param_288: f32;
    var param_289: f32;
    var param_290: f32;
    var param_291: f32;
    var Li_4: vec3<f32>;
    var param_292: vec3<f32>;
    var param_293: vec3<f32>;
    var param_294: vec3<f32>;
    var param_295: vec2<f32>;
    var param_296: i32;
    var param_297: FresnelData;
    var phi_3747_: bool;

    let _e409 = (*weight_4);
    if (_e409 < 0.00000001f) {
        return;
    }
    let _e412 = (*closureData_7).closureType;
    let _e414 = (*scatter_mode_1);
    if ((_e412 != 2i) && (_e414 == 1i)) {
        return;
    }
    let _e418 = (*closureData_7).V;
    V_10 = _e418;
    let _e420 = (*closureData_7).L;
    L_5 = _e420;
    let _e421 = (*retroreflective_1);
    phi_3747_ = _e421;
    if _e421 {
        let _e423 = (*closureData_7).closureType;
        phi_3747_ = (_e423 != 2i);
    }
    let _e426 = phi_3747_;
    if _e426 {
        let _e427 = V_10;
        let _e429 = (*N_11);
        V_10 = reflect(-(_e427), _e429);
    }
    let _e431 = (*N_11);
    param_250 = _e431;
    let _e432 = V_10;
    param_251 = _e432;
    let _e433 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_250), (&param_251));
    (*N_11) = _e433;
    let _e434 = (*N_11);
    let _e435 = V_10;
    NdotV_19 = clamp(dot(_e434, _e435), 0.00000001f, 1f);
    let _e438 = (*ior_5);
    param_252 = _e438;
    let _e439 = (*thinfilm_thickness_1);
    param_253 = _e439;
    let _e440 = (*thinfilm_ior_1);
    param_254 = _e440;
    let _e441 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_252), (&param_253), (&param_254));
    fd_10 = _e441;
    let _e442 = (*ior_5);
    param_255 = _e442;
    let _e443 = mx_ior_to_f0_u0028_f1_u003b((&param_255));
    F0_7 = _e443;
    let _e444 = (*roughness_15);
    safeAlpha_1 = clamp(_e444, vec2(0.00000001f), vec2(1f));
    let _e448 = safeAlpha_1;
    param_256 = _e448;
    let _e449 = mx_average_alpha_u0028_vf2_u003b((&param_256));
    avgAlpha_2 = _e449;
    let _e450 = (*tint_1);
    safeTint = max(_e450, vec3(0f));
    let _e454 = (*closureData_7).closureType;
    if (_e454 == 1i) {
        let _e456 = (*X_5);
        let _e457 = (*X_5);
        let _e458 = (*N_11);
        let _e460 = (*N_11);
        (*X_5) = normalize((_e456 - (_e460 * dot(_e457, _e458))));
        let _e464 = (*N_11);
        let _e465 = (*X_5);
        Y_4 = cross(_e464, _e465);
        let _e467 = L_5;
        let _e468 = V_10;
        H_6 = normalize((_e467 + _e468));
        let _e471 = (*N_11);
        let _e472 = L_5;
        NdotL_8 = clamp(dot(_e471, _e472), 0.00000001f, 1f);
        let _e475 = V_10;
        let _e476 = H_6;
        VdotH_2 = clamp(dot(_e475, _e476), 0.00000001f, 1f);
        let _e479 = H_6;
        let _e480 = (*X_5);
        let _e482 = H_6;
        let _e483 = Y_4;
        let _e485 = H_6;
        let _e486 = (*N_11);
        Ht_1 = vec3<f32>(dot(_e479, _e480), dot(_e482, _e483), dot(_e485, _e486));
        let _e489 = VdotH_2;
        param_257 = _e489;
        let _e490 = fd_10;
        param_258 = _e490;
        let _e491 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_257), (&param_258));
        F_3 = _e491;
        let _e492 = Ht_1;
        param_259 = _e492;
        let _e493 = safeAlpha_1;
        param_260 = _e493;
        let _e494 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_259), (&param_260));
        D_2 = _e494;
        let _e495 = NdotL_8;
        param_261 = _e495;
        let _e496 = NdotV_19;
        param_262 = _e496;
        let _e497 = avgAlpha_2;
        param_263 = _e497;
        let _e498 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_261), (&param_262), (&param_263));
        G_4 = _e498;
        let _e499 = NdotV_19;
        param_264 = _e499;
        let _e500 = avgAlpha_2;
        param_265 = _e500;
        let _e501 = fd_10;
        param_266 = _e501;
        let _e502 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_264), (&param_265), (&param_266));
        comp_3 = _e502;
        let _e503 = NdotV_19;
        param_267 = _e503;
        let _e504 = avgAlpha_2;
        param_268 = _e504;
        let _e505 = F0_7;
        param_269 = _e505;
        param_270 = 1f;
        let _e506 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_267), (&param_268), (&param_269), (&param_270));
        let _e507 = comp_3;
        dirAlbedo_8 = (_e507 * _e506);
        let _e509 = dirAlbedo_8;
        let _e510 = (*weight_4);
        (*bsdf_3).throughput = (vec3(1f) - (_e509 * _e510));
        let _e515 = D_2;
        let _e516 = F_3;
        let _e518 = G_4;
        let _e520 = comp_3;
        let _e522 = safeTint;
        let _e525 = (*closureData_7).occlusion;
        let _e527 = (*weight_4);
        let _e529 = NdotV_19;
        (*bsdf_3).response = (((((((_e516 * _e515) * _e518) * _e520) * _e522) * _e525) * _e527) / vec3((4f * _e529)));
    } else {
        let _e535 = (*closureData_7).closureType;
        if (_e535 == 2i) {
            let _e537 = NdotV_19;
            param_271 = _e537;
            let _e538 = avgAlpha_2;
            param_272 = _e538;
            let _e539 = fd_10;
            param_273 = _e539;
            let _e540 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_271), (&param_272), (&param_273));
            comp_4 = _e540;
            let _e541 = NdotV_19;
            param_274 = _e541;
            let _e542 = avgAlpha_2;
            param_275 = _e542;
            let _e543 = F0_7;
            param_276 = _e543;
            param_277 = 1f;
            let _e544 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_274), (&param_275), (&param_276), (&param_277));
            let _e545 = comp_4;
            dirAlbedo_9 = (_e545 * _e544);
            let _e547 = dirAlbedo_9;
            let _e548 = (*weight_4);
            (*bsdf_3).throughput = (vec3(1f) - (_e547 * _e548));
            let _e553 = (*scatter_mode_1);
            if (_e553 != 0i) {
                let _e555 = (*N_11);
                param_278 = _e555;
                let _e556 = V_10;
                param_279 = _e556;
                let _e557 = (*X_5);
                param_280 = _e557;
                let _e558 = safeAlpha_1;
                param_281 = _e558;
                let _e559 = (*distribution_3);
                param_282 = _e559;
                let _e560 = fd_10;
                param_283 = _e560;
                let _e561 = safeTint;
                param_284 = _e561;
                let _e562 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_278), (&param_279), (&param_280), (&param_281), (&param_282), (&param_283), (&param_284));
                let _e563 = (*weight_4);
                (*bsdf_3).response = (_e562 * _e563);
            }
        } else {
            let _e567 = (*closureData_7).closureType;
            if (_e567 == 3i) {
                let _e569 = NdotV_19;
                param_285 = _e569;
                let _e570 = avgAlpha_2;
                param_286 = _e570;
                let _e571 = fd_10;
                param_287 = _e571;
                let _e572 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_285), (&param_286), (&param_287));
                comp_5 = _e572;
                let _e573 = NdotV_19;
                param_288 = _e573;
                let _e574 = avgAlpha_2;
                param_289 = _e574;
                let _e575 = F0_7;
                param_290 = _e575;
                param_291 = 1f;
                let _e576 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_288), (&param_289), (&param_290), (&param_291));
                let _e577 = comp_5;
                dirAlbedo_10 = (_e577 * _e576);
                let _e579 = dirAlbedo_10;
                let _e580 = (*weight_4);
                (*bsdf_3).throughput = (vec3(1f) - (_e579 * _e580));
                let _e585 = (*N_11);
                param_292 = _e585;
                let _e586 = V_10;
                param_293 = _e586;
                let _e587 = (*X_5);
                param_294 = _e587;
                let _e588 = safeAlpha_1;
                param_295 = _e588;
                let _e589 = (*distribution_3);
                param_296 = _e589;
                let _e590 = fd_10;
                param_297 = _e590;
                let _e591 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_292), (&param_293), (&param_294), (&param_295), (&param_296), (&param_297));
                Li_4 = _e591;
                let _e592 = Li_4;
                let _e593 = safeTint;
                let _e595 = comp_5;
                let _e597 = (*weight_4);
                (*bsdf_3).response = (((_e592 * _e593) * _e595) * _e597);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_6: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, occlusion: ptr<function, f32>) -> ClosureData {
    let _e331 = (*closureType);
    let _e332 = (*L_6);
    let _e333 = (*V_11);
    let _e334 = (*N_12);
    let _e335 = (*P);
    let _e336 = (*occlusion);
    return ClosureData(_e331, _e332, _e333, _e334, _e335, _e336);
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_4: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e333 = (*axis);
    (*axis) = normalize(_e333);
    let _e335 = (*amount);
    rotationRadians = radians(_e335);
    let _e337 = rotationRadians;
    s_4 = sin(_e337);
    let _e339 = rotationRadians;
    c_3 = cos(_e339);
    let _e341 = c_3;
    oc = (1f - _e341);
    let _e343 = (*_in);
    let _e344 = c_3;
    let _e346 = (*_in);
    let _e347 = (*axis);
    let _e349 = s_4;
    let _e352 = (*axis);
    let _e353 = (*axis);
    let _e354 = (*_in);
    let _e357 = oc;
    (*result_4) = (((_e343 * _e344) + (cross(_e346, _e347) * _e349)) + ((_e352 * dot(_e353, _e354)) * _e357));
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_2: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e333 = (*in1_2)[0u];
    N_extract_0_out = _e333;
    let _e335 = (*in1_2)[1u];
    N_extract_1_out = _e335;
    let _e337 = (*in1_2)[2u];
    N_extract_2_out = _e337;
    let _e338 = N_extract_0_out;
    (*outr) = _e338;
    let _e339 = N_extract_1_out;
    (*outg) = _e339;
    let _e340 = N_extract_2_out;
    (*outb) = _e340;
    return;
}

fn NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b(in1_3: ptr<function, vec3<f32>>, out1_: ptr<function, f32>) {
    var N_separate_outr: f32;
    var N_separate_outg: f32;
    var N_separate_outb: f32;
    var param_298: vec3<f32>;
    var param_299: f32;
    var param_300: f32;
    var param_301: f32;
    var N_max_01_out: f32;
    var N_max_out: f32;

    N_separate_outr = 0f;
    N_separate_outg = 0f;
    N_separate_outb = 0f;
    let _e336 = (*in1_3);
    param_298 = _e336;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_298), (&param_299), (&param_300), (&param_301));
    let _e337 = param_299;
    N_separate_outr = _e337;
    let _e338 = param_300;
    N_separate_outg = _e338;
    let _e339 = param_301;
    N_separate_outb = _e339;
    let _e340 = N_separate_outr;
    let _e341 = N_separate_outg;
    N_max_01_out = max(_e340, _e341);
    let _e343 = N_max_01_out;
    let _e344 = N_separate_outb;
    N_max_out = max(_e343, _e344);
    let _e346 = N_max_out;
    (*out1_) = _e346;
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy: ptr<function, f32>, result_5: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e330 = (*roughness_16);
    let _e331 = (*roughness_16);
    roughness_sqr = clamp((_e330 * _e331), 0.00000001f, 1f);
    let _e334 = (*anisotropy);
    if (_e334 > 0f) {
        let _e336 = (*anisotropy);
        aspect = sqrt((1f - clamp(_e336, 0f, 0.98f)));
        let _e340 = roughness_sqr;
        let _e341 = aspect;
        (*result_5)[0u] = min((_e340 / _e341), 1f);
        let _e345 = roughness_sqr;
        let _e346 = aspect;
        (*result_5)[1u] = (_e345 * _e346);
    } else {
        let _e349 = roughness_sqr;
        (*result_5)[0u] = _e349;
        let _e351 = roughness_sqr;
        (*result_5)[1u] = _e351;
    }
    return;
}

fn IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_color: ptr<function, vec3<f32>>, metallic: ptr<function, f32>, roughness_17: ptr<function, f32>, normal: ptr<function, vec3<f32>>, tangent: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>, transmission: ptr<function, f32>, specular: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, ior_6: ptr<function, f32>, alpha_12: ptr<function, f32>, alpha_mode: ptr<function, i32>, alpha_cutoff: ptr<function, f32>, iridescence: ptr<function, f32>, iridescence_ior: ptr<function, f32>, iridescence_thickness: ptr<function, f32>, sheen_color: ptr<function, vec3<f32>>, sheen_roughness: ptr<function, f32>, clearcoat: ptr<function, f32>, clearcoat_roughness: ptr<function, f32>, clearcoat_normal: ptr<function, vec3<f32>>, emissive: ptr<function, vec3<f32>>, emissive_strength: ptr<function, f32>, thickness: ptr<function, f32>, attenuation_distance: ptr<function, f32>, attenuation_color: ptr<function, vec3<f32>>, anisotropy_strength: ptr<function, f32>, anisotropy_rotation: ptr<function, f32>, dispersion: ptr<function, f32>, out1_1: ptr<function, surfaceshader>) {
    var clearcoat_roughness_uv_out: vec2<f32>;
    var param_302: f32;
    var param_303: f32;
    var param_304: vec2<f32>;
    var sheen_intensity_out: f32;
    var param_305: vec3<f32>;
    var param_306: f32;
    var sheen_roughness_sq_out: f32;
    var mix_iridescent_metal_bsdf_fg_weight_out: f32;
    var alpha_roughness_out: f32;
    var strength_2_out: f32;
    var abs_anisotropy_rotation_out: f32;
    var rad_2_deg_out: f32;
    var mix_iridescent_metal_bsdf_mix_inv_out: f32;
    var mix_iridescent_dielectric_reflection_fg_weight_out: f32;
    var one_minus_ior_out: f32;
    var one_plus_ior_out: f32;
    var dielectric_f90_out: vec3<f32>;
    var mix_iridescent_dielectric_reflection_mix_inv_out: f32;
    var transmission_mix_fg_weight_out: f32;
    var transmission_mix_mix_inv_out: f32;
    var base_mix_mix_inv_out: f32;
    var emission_color_out: vec3<f32>;
    var opacity_mask_cutoff_out: f32;
    var sheen_color_normalized_out: vec3<f32>;
    var clamped_ab_out: f32;
    var at_out: f32;
    var rotate_tangent_out: vec3<f32>;
    var param_307: vec3<f32>;
    var param_308: f32;
    var param_309: vec3<f32>;
    var param_310: vec3<f32>;
    var mix_iridescent_metal_bsdf_bg_weight_out: f32;
    var ior_div_out: f32;
    var mix_iridescent_dielectric_reflection_bg_weight_out: f32;
    var transmission_mix_bg_weight_out: f32;
    var opacity_mask_out: f32;
    var clamped_at_out: f32;
    var normalize_tangent_out: vec3<f32>;
    var dielectric_f0_from_ior_out: f32;
    var opacity_out: f32;
    var roughness_uv_out: vec2<f32>;
    var selected_tangent_out: vec3<f32>;
    var dielectric_f0_from_ior_specular_color_out: vec3<f32>;
    var clamped_dielectric_f0_from_ior_specular_color_out: vec3<f32>;
    var dielectric_f0_out: vec3<f32>;
    var shader_constructor_out: surfaceshader;
    var N_13: vec3<f32>;
    var V_12: vec3<f32>;
    var L_7: vec3<f32>;
    var P_1: vec3<f32>;
    var occlusion_2: f32;
    var closureData_8: ClosureData;
    var param_311: i32;
    var param_312: vec3<f32>;
    var param_313: vec3<f32>;
    var param_314: vec3<f32>;
    var param_315: vec3<f32>;
    var param_316: f32;
    var clearcoat_bsdf_out: BSDF;
    var param_317: ClosureData;
    var param_318: f32;
    var param_319: vec3<f32>;
    var param_320: f32;
    var param_321: vec2<f32>;
    var param_322: bool;
    var param_323: f32;
    var param_324: f32;
    var param_325: vec3<f32>;
    var param_326: vec3<f32>;
    var param_327: i32;
    var param_328: i32;
    var param_329: BSDF;
    var sheen_bsdf_out: BSDF;
    var param_330: ClosureData;
    var param_331: f32;
    var param_332: vec3<f32>;
    var param_333: f32;
    var param_334: vec3<f32>;
    var param_335: i32;
    var param_336: BSDF;
    var tf_metal_bsdf_out: BSDF;
    var param_337: ClosureData;
    var param_338: f32;
    var param_339: vec3<f32>;
    var param_340: vec3<f32>;
    var param_341: vec3<f32>;
    var param_342: f32;
    var param_343: vec2<f32>;
    var param_344: bool;
    var param_345: f32;
    var param_346: f32;
    var param_347: vec3<f32>;
    var param_348: vec3<f32>;
    var param_349: i32;
    var param_350: i32;
    var param_351: BSDF;
    var metal_bsdf_out: BSDF;
    var param_352: ClosureData;
    var param_353: f32;
    var param_354: vec3<f32>;
    var param_355: vec3<f32>;
    var param_356: vec3<f32>;
    var param_357: f32;
    var param_358: vec2<f32>;
    var param_359: bool;
    var param_360: f32;
    var param_361: f32;
    var param_362: vec3<f32>;
    var param_363: vec3<f32>;
    var param_364: i32;
    var param_365: i32;
    var param_366: BSDF;
    var mix_iridescent_metal_bsdf_add_out: BSDF;
    var param_367: ClosureData;
    var param_368: BSDF;
    var param_369: BSDF;
    var param_370: BSDF;
    var base_mix_fg_mul_out: BSDF;
    var param_371: ClosureData;
    var param_372: BSDF;
    var param_373: f32;
    var param_374: BSDF;
    var tf_reflection_bsdf_out: BSDF;
    var param_375: ClosureData;
    var param_376: f32;
    var param_377: vec3<f32>;
    var param_378: vec3<f32>;
    var param_379: vec3<f32>;
    var param_380: f32;
    var param_381: vec2<f32>;
    var param_382: bool;
    var param_383: f32;
    var param_384: f32;
    var param_385: vec3<f32>;
    var param_386: vec3<f32>;
    var param_387: i32;
    var param_388: i32;
    var param_389: BSDF;
    var reflection_bsdf_out: BSDF;
    var param_390: ClosureData;
    var param_391: f32;
    var param_392: vec3<f32>;
    var param_393: vec3<f32>;
    var param_394: vec3<f32>;
    var param_395: f32;
    var param_396: vec2<f32>;
    var param_397: bool;
    var param_398: f32;
    var param_399: f32;
    var param_400: vec3<f32>;
    var param_401: vec3<f32>;
    var param_402: i32;
    var param_403: i32;
    var param_404: BSDF;
    var mix_iridescent_dielectric_reflection_add_out: BSDF;
    var param_405: ClosureData;
    var param_406: BSDF;
    var param_407: BSDF;
    var param_408: BSDF;
    var transmission_bsdf_out: BSDF;
    var param_409: ClosureData;
    var param_410: f32;
    var param_411: vec3<f32>;
    var param_412: f32;
    var param_413: vec2<f32>;
    var param_414: bool;
    var param_415: f32;
    var param_416: f32;
    var param_417: vec3<f32>;
    var param_418: vec3<f32>;
    var param_419: i32;
    var param_420: i32;
    var param_421: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_422: ClosureData;
    var param_423: f32;
    var param_424: vec3<f32>;
    var param_425: f32;
    var param_426: vec3<f32>;
    var param_427: bool;
    var param_428: BSDF;
    var transmission_mix_add_out: BSDF;
    var param_429: ClosureData;
    var param_430: BSDF;
    var param_431: BSDF;
    var param_432: BSDF;
    var iridescent_dielectric_bsdf_out: BSDF;
    var param_433: ClosureData;
    var param_434: BSDF;
    var param_435: BSDF;
    var param_436: BSDF;
    var base_mix_bg_mul_out: BSDF;
    var param_437: ClosureData;
    var param_438: BSDF;
    var param_439: f32;
    var param_440: BSDF;
    var base_mix_add_out: BSDF;
    var param_441: ClosureData;
    var param_442: BSDF;
    var param_443: BSDF;
    var param_444: BSDF;
    var sheen_layer_out: BSDF;
    var param_445: ClosureData;
    var param_446: BSDF;
    var param_447: BSDF;
    var param_448: BSDF;
    var clearcoat_layer_out: BSDF;
    var param_449: ClosureData;
    var param_450: BSDF;
    var param_451: BSDF;
    var param_452: BSDF;
    var closureData_9: ClosureData;
    var param_453: i32;
    var param_454: vec3<f32>;
    var param_455: vec3<f32>;
    var param_456: vec3<f32>;
    var param_457: vec3<f32>;
    var param_458: f32;
    var emission_out: vec3<f32>;
    var param_459: ClosureData;
    var param_460: vec3<f32>;
    var param_461: vec3<f32>;

    clearcoat_roughness_uv_out = vec2<f32>(0f, 0f);
    let _e578 = (*clearcoat_roughness);
    param_302 = _e578;
    param_303 = 0f;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_302), (&param_303), (&param_304));
    let _e579 = param_304;
    clearcoat_roughness_uv_out = _e579;
    sheen_intensity_out = 0f;
    let _e580 = (*sheen_color);
    param_305 = _e580;
    NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b((&param_305), (&param_306));
    let _e581 = param_306;
    sheen_intensity_out = _e581;
    let _e582 = (*sheen_roughness);
    let _e583 = (*sheen_roughness);
    sheen_roughness_sq_out = (_e582 * _e583);
    let _e585 = (*iridescence);
    mix_iridescent_metal_bsdf_fg_weight_out = (1f * _e585);
    let _e587 = (*roughness_17);
    let _e588 = (*roughness_17);
    alpha_roughness_out = (_e587 * _e588);
    let _e590 = (*anisotropy_strength);
    let _e591 = (*anisotropy_strength);
    strength_2_out = (_e590 * _e591);
    let _e593 = (*anisotropy_rotation);
    abs_anisotropy_rotation_out = abs(_e593);
    let _e595 = (*anisotropy_rotation);
    rad_2_deg_out = (_e595 * -57.29578f);
    let _e597 = (*iridescence);
    mix_iridescent_metal_bsdf_mix_inv_out = (1f - _e597);
    let _e599 = (*iridescence);
    mix_iridescent_dielectric_reflection_fg_weight_out = (1f * _e599);
    let _e601 = (*ior_6);
    one_minus_ior_out = (1f - _e601);
    let _e603 = (*ior_6);
    one_plus_ior_out = (1f + _e603);
    let _e605 = (*specular);
    dielectric_f90_out = (vec3<f32>(1f, 1f, 1f) * _e605);
    let _e607 = (*iridescence);
    mix_iridescent_dielectric_reflection_mix_inv_out = (1f - _e607);
    let _e609 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e609);
    let _e611 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e611);
    let _e613 = (*metallic);
    base_mix_mix_inv_out = (1f - _e613);
    let _e615 = (*emissive);
    let _e616 = (*emissive_strength);
    emission_color_out = (_e615 * _e616);
    let _e618 = (*alpha_12);
    let _e619 = (*alpha_cutoff);
    opacity_mask_cutoff_out = select(0f, 1f, (_e618 >= _e619));
    let _e622 = (*sheen_color);
    let _e623 = sheen_intensity_out;
    sheen_color_normalized_out = (_e622 / vec3(_e623));
    let _e626 = alpha_roughness_out;
    clamped_ab_out = clamp(_e626, 0.00001f, 1f);
    let _e628 = alpha_roughness_out;
    let _e629 = strength_2_out;
    at_out = mix(_e628, 1f, _e629);
    rotate_tangent_out = vec3<f32>(0f, 0f, 0f);
    let _e631 = (*tangent);
    param_307 = _e631;
    let _e632 = rad_2_deg_out;
    param_308 = _e632;
    let _e633 = (*normal);
    param_309 = _e633;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_307), (&param_308), (&param_309), (&param_310));
    let _e634 = param_310;
    rotate_tangent_out = _e634;
    let _e635 = mix_iridescent_metal_bsdf_mix_inv_out;
    mix_iridescent_metal_bsdf_bg_weight_out = (1f * _e635);
    let _e637 = one_minus_ior_out;
    let _e638 = one_plus_ior_out;
    ior_div_out = (_e637 / _e638);
    let _e640 = mix_iridescent_dielectric_reflection_mix_inv_out;
    mix_iridescent_dielectric_reflection_bg_weight_out = (1f * _e640);
    let _e642 = transmission_mix_mix_inv_out;
    transmission_mix_bg_weight_out = (1f * _e642);
    let _e644 = (*alpha_mode);
    let _e646 = opacity_mask_cutoff_out;
    let _e647 = (*alpha_12);
    opacity_mask_out = select(_e647, _e646, (_e644 == 1i));
    let _e649 = at_out;
    clamped_at_out = clamp(_e649, 0.00001f, 1f);
    let _e651 = rotate_tangent_out;
    normalize_tangent_out = normalize(_e651);
    let _e653 = ior_div_out;
    let _e654 = ior_div_out;
    dielectric_f0_from_ior_out = (_e653 * _e654);
    let _e656 = (*alpha_mode);
    let _e658 = opacity_mask_out;
    opacity_out = select(_e658, 1f, (_e656 == 0i));
    let _e660 = clamped_at_out;
    let _e661 = clamped_ab_out;
    roughness_uv_out = vec2<f32>(_e660, _e661);
    let _e663 = abs_anisotropy_rotation_out;
    let _e665 = normalize_tangent_out;
    let _e666 = (*tangent);
    selected_tangent_out = select(_e666, _e665, (_e663 > 0f));
    let _e668 = (*specular_color);
    let _e669 = dielectric_f0_from_ior_out;
    dielectric_f0_from_ior_specular_color_out = (_e668 * _e669);
    let _e671 = dielectric_f0_from_ior_specular_color_out;
    clamped_dielectric_f0_from_ior_specular_color_out = min(_e671, vec3(1f));
    let _e674 = clamped_dielectric_f0_from_ior_specular_color_out;
    let _e675 = (*specular);
    dielectric_f0_out = (_e674 * _e675);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e677 = g_ptN;
    N_13 = _e677;
    let _e678 = g_ptV;
    V_12 = _e678;
    let _e679 = g_ptL;
    L_7 = _e679;
    let _e680 = g_ptP;
    P_1 = _e680;
    let _e681 = g_ptOcclusion;
    occlusion_2 = _e681;
    let _e682 = g_ptClosureType;
    param_311 = _e682;
    let _e683 = L_7;
    param_312 = _e683;
    let _e684 = V_12;
    param_313 = _e684;
    let _e685 = N_13;
    param_314 = _e685;
    let _e686 = P_1;
    param_315 = _e686;
    let _e687 = occlusion_2;
    param_316 = _e687;
    let _e688 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_311), (&param_312), (&param_313), (&param_314), (&param_315), (&param_316));
    closureData_8 = _e688;
    clearcoat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e689 = closureData_8;
    param_317 = _e689;
    let _e690 = (*clearcoat);
    param_318 = _e690;
    param_319 = vec3<f32>(1f, 1f, 1f);
    param_320 = 1.5f;
    let _e691 = clearcoat_roughness_uv_out;
    param_321 = _e691;
    param_322 = false;
    param_323 = 0f;
    param_324 = 1.5f;
    let _e692 = (*clearcoat_normal);
    param_325 = _e692;
    let _e693 = (*tangent);
    param_326 = _e693;
    param_327 = 0i;
    param_328 = 0i;
    let _e694 = clearcoat_bsdf_out;
    param_329 = _e694;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_317), (&param_318), (&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325), (&param_326), (&param_327), (&param_328), (&param_329));
    let _e695 = param_329;
    clearcoat_bsdf_out = _e695;
    sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e696 = closureData_8;
    param_330 = _e696;
    let _e697 = sheen_intensity_out;
    param_331 = _e697;
    let _e698 = sheen_color_normalized_out;
    param_332 = _e698;
    let _e699 = sheen_roughness_sq_out;
    param_333 = _e699;
    let _e700 = (*normal);
    param_334 = _e700;
    param_335 = 0i;
    let _e701 = sheen_bsdf_out;
    param_336 = _e701;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336));
    let _e702 = param_336;
    sheen_bsdf_out = _e702;
    tf_metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e703 = closureData_8;
    param_337 = _e703;
    let _e704 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_338 = _e704;
    let _e705 = (*base_color);
    param_339 = _e705;
    param_340 = vec3<f32>(1f, 1f, 1f);
    param_341 = vec3<f32>(1f, 1f, 1f);
    param_342 = 5f;
    let _e706 = roughness_uv_out;
    param_343 = _e706;
    param_344 = false;
    let _e707 = (*iridescence_thickness);
    param_345 = _e707;
    let _e708 = (*iridescence_ior);
    param_346 = _e708;
    let _e709 = (*normal);
    param_347 = _e709;
    let _e710 = selected_tangent_out;
    param_348 = _e710;
    param_349 = 0i;
    param_350 = 0i;
    let _e711 = tf_metal_bsdf_out;
    param_351 = _e711;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_337), (&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350), (&param_351));
    let _e712 = param_351;
    tf_metal_bsdf_out = _e712;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e713 = closureData_8;
    param_352 = _e713;
    let _e714 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_353 = _e714;
    let _e715 = (*base_color);
    param_354 = _e715;
    param_355 = vec3<f32>(1f, 1f, 1f);
    param_356 = vec3<f32>(1f, 1f, 1f);
    param_357 = 5f;
    let _e716 = roughness_uv_out;
    param_358 = _e716;
    param_359 = false;
    param_360 = 0f;
    param_361 = 1.5f;
    let _e717 = (*normal);
    param_362 = _e717;
    let _e718 = selected_tangent_out;
    param_363 = _e718;
    param_364 = 0i;
    param_365 = 0i;
    let _e719 = metal_bsdf_out;
    param_366 = _e719;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365), (&param_366));
    let _e720 = param_366;
    metal_bsdf_out = _e720;
    mix_iridescent_metal_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e721 = closureData_8;
    param_367 = _e721;
    let _e722 = tf_metal_bsdf_out;
    param_368 = _e722;
    let _e723 = metal_bsdf_out;
    param_369 = _e723;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_367), (&param_368), (&param_369), (&param_370));
    let _e724 = param_370;
    mix_iridescent_metal_bsdf_add_out = _e724;
    base_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e725 = closureData_8;
    param_371 = _e725;
    let _e726 = mix_iridescent_metal_bsdf_add_out;
    param_372 = _e726;
    let _e727 = (*metallic);
    param_373 = _e727;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_371), (&param_372), (&param_373), (&param_374));
    let _e728 = param_374;
    base_mix_fg_mul_out = _e728;
    tf_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e729 = closureData_8;
    param_375 = _e729;
    let _e730 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_376 = _e730;
    let _e731 = dielectric_f0_out;
    param_377 = _e731;
    param_378 = vec3<f32>(1f, 1f, 1f);
    let _e732 = dielectric_f90_out;
    param_379 = _e732;
    param_380 = 5f;
    let _e733 = roughness_uv_out;
    param_381 = _e733;
    param_382 = false;
    let _e734 = (*iridescence_thickness);
    param_383 = _e734;
    let _e735 = (*iridescence_ior);
    param_384 = _e735;
    let _e736 = (*normal);
    param_385 = _e736;
    let _e737 = selected_tangent_out;
    param_386 = _e737;
    param_387 = 0i;
    param_388 = 0i;
    let _e738 = tf_reflection_bsdf_out;
    param_389 = _e738;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387), (&param_388), (&param_389));
    let _e739 = param_389;
    tf_reflection_bsdf_out = _e739;
    reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e740 = closureData_8;
    param_390 = _e740;
    let _e741 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_391 = _e741;
    let _e742 = dielectric_f0_out;
    param_392 = _e742;
    param_393 = vec3<f32>(1f, 1f, 1f);
    let _e743 = dielectric_f90_out;
    param_394 = _e743;
    param_395 = 5f;
    let _e744 = roughness_uv_out;
    param_396 = _e744;
    param_397 = false;
    param_398 = 0f;
    param_399 = 1.5f;
    let _e745 = (*normal);
    param_400 = _e745;
    let _e746 = selected_tangent_out;
    param_401 = _e746;
    param_402 = 0i;
    param_403 = 0i;
    let _e747 = reflection_bsdf_out;
    param_404 = _e747;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402), (&param_403), (&param_404));
    let _e748 = param_404;
    reflection_bsdf_out = _e748;
    mix_iridescent_dielectric_reflection_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e749 = closureData_8;
    param_405 = _e749;
    let _e750 = tf_reflection_bsdf_out;
    param_406 = _e750;
    let _e751 = reflection_bsdf_out;
    param_407 = _e751;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_405), (&param_406), (&param_407), (&param_408));
    let _e752 = param_408;
    mix_iridescent_dielectric_reflection_add_out = _e752;
    transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e753 = closureData_8;
    param_409 = _e753;
    let _e754 = transmission_mix_fg_weight_out;
    param_410 = _e754;
    let _e755 = (*base_color);
    param_411 = _e755;
    let _e756 = (*ior_6);
    param_412 = _e756;
    let _e757 = roughness_uv_out;
    param_413 = _e757;
    param_414 = false;
    param_415 = 0f;
    param_416 = 1.5f;
    let _e758 = (*normal);
    param_417 = _e758;
    let _e759 = selected_tangent_out;
    param_418 = _e759;
    param_419 = 0i;
    param_420 = 1i;
    let _e760 = transmission_bsdf_out;
    param_421 = _e760;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_409), (&param_410), (&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420), (&param_421));
    let _e761 = param_421;
    transmission_bsdf_out = _e761;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e762 = closureData_8;
    param_422 = _e762;
    let _e763 = transmission_mix_bg_weight_out;
    param_423 = _e763;
    let _e764 = (*base_color);
    param_424 = _e764;
    param_425 = 0f;
    let _e765 = (*normal);
    param_426 = _e765;
    param_427 = false;
    let _e766 = diffuse_bsdf_out;
    param_428 = _e766;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_422), (&param_423), (&param_424), (&param_425), (&param_426), (&param_427), (&param_428));
    let _e767 = param_428;
    diffuse_bsdf_out = _e767;
    transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e768 = closureData_8;
    param_429 = _e768;
    let _e769 = transmission_bsdf_out;
    param_430 = _e769;
    let _e770 = diffuse_bsdf_out;
    param_431 = _e770;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_429), (&param_430), (&param_431), (&param_432));
    let _e771 = param_432;
    transmission_mix_add_out = _e771;
    iridescent_dielectric_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e772 = closureData_8;
    param_433 = _e772;
    let _e773 = mix_iridescent_dielectric_reflection_add_out;
    param_434 = _e773;
    let _e774 = transmission_mix_add_out;
    param_435 = _e774;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_433), (&param_434), (&param_435), (&param_436));
    let _e775 = param_436;
    iridescent_dielectric_bsdf_out = _e775;
    base_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e776 = closureData_8;
    param_437 = _e776;
    let _e777 = iridescent_dielectric_bsdf_out;
    param_438 = _e777;
    let _e778 = base_mix_mix_inv_out;
    param_439 = _e778;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_437), (&param_438), (&param_439), (&param_440));
    let _e779 = param_440;
    base_mix_bg_mul_out = _e779;
    base_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e780 = closureData_8;
    param_441 = _e780;
    let _e781 = base_mix_fg_mul_out;
    param_442 = _e781;
    let _e782 = base_mix_bg_mul_out;
    param_443 = _e782;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_441), (&param_442), (&param_443), (&param_444));
    let _e783 = param_444;
    base_mix_add_out = _e783;
    sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e784 = closureData_8;
    param_445 = _e784;
    let _e785 = sheen_bsdf_out;
    param_446 = _e785;
    let _e786 = base_mix_add_out;
    param_447 = _e786;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_445), (&param_446), (&param_447), (&param_448));
    let _e787 = param_448;
    sheen_layer_out = _e787;
    clearcoat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e788 = closureData_8;
    param_449 = _e788;
    let _e789 = clearcoat_bsdf_out;
    param_450 = _e789;
    let _e790 = sheen_layer_out;
    param_451 = _e790;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_449), (&param_450), (&param_451), (&param_452));
    let _e791 = param_452;
    clearcoat_layer_out = _e791;
    let _e793 = clearcoat_layer_out.response;
    let _e795 = shader_constructor_out.color;
    shader_constructor_out.color = (_e795 + _e793);
    let _e798 = g_ptEmitEmission;
    if (_e798 != 0i) {
        param_453 = 4i;
        let _e800 = L_7;
        param_454 = _e800;
        let _e801 = V_12;
        param_455 = _e801;
        let _e802 = N_13;
        param_456 = _e802;
        let _e803 = P_1;
        param_457 = _e803;
        let _e804 = occlusion_2;
        param_458 = _e804;
        let _e805 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_453), (&param_454), (&param_455), (&param_456), (&param_457), (&param_458));
        closureData_9 = _e805;
        emission_out = vec3<f32>(0f, 0f, 0f);
        let _e806 = closureData_9;
        param_459 = _e806;
        let _e807 = emission_color_out;
        param_460 = _e807;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_459), (&param_460), (&param_461));
        let _e808 = param_461;
        emission_out = _e808;
        let _e809 = emission_out;
        let _e810 = g_ptEmission;
        g_ptEmission = (_e810 + _e809);
        let _e812 = emission_out;
        let _e814 = shader_constructor_out.color;
        shader_constructor_out.color = (_e814 + _e812);
    }
    let _e817 = shader_constructor_out;
    (*out1_1) = _e817;
    return;
}

fn mtlxHostEvalSurface_u0028_() -> surfaceshader {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_plastic_out: surfaceshader;
    var param_462: vec3<f32>;
    var param_463: f32;
    var param_464: f32;
    var param_465: vec3<f32>;
    var param_466: vec3<f32>;
    var param_467: f32;
    var param_468: f32;
    var param_469: f32;
    var param_470: vec3<f32>;
    var param_471: f32;
    var param_472: f32;
    var param_473: i32;
    var param_474: f32;
    var param_475: f32;
    var param_476: f32;
    var param_477: f32;
    var param_478: vec3<f32>;
    var param_479: f32;
    var param_480: f32;
    var param_481: f32;
    var param_482: vec3<f32>;
    var param_483: vec3<f32>;
    var param_484: f32;
    var param_485: f32;
    var param_486: f32;
    var param_487: vec3<f32>;
    var param_488: f32;
    var param_489: f32;
    var param_490: f32;
    var param_491: surfaceshader;

    let _e358 = g_ptN;
    normalWorld = _e358;
    let _e359 = g_ptTangent;
    tangentWorld = _e359;
    let _e360 = normalWorld;
    geomprop_Nworld_out = normalize(_e360);
    let _e362 = tangentWorld;
    geomprop_Tworld_out = normalize(_e362);
    SR_plastic_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e364 = base_color_1;
    param_462 = _e364;
    let _e365 = metallic_1;
    param_463 = _e365;
    let _e366 = roughness_18;
    param_464 = _e366;
    let _e367 = geomprop_Nworld_out;
    param_465 = _e367;
    let _e368 = geomprop_Tworld_out;
    param_466 = _e368;
    let _e369 = occlusion_3;
    param_467 = _e369;
    let _e370 = transmission_1;
    param_468 = _e370;
    let _e371 = specular_1;
    param_469 = _e371;
    let _e372 = specular_color_1;
    param_470 = _e372;
    let _e373 = ior_7;
    param_471 = _e373;
    let _e374 = alpha_15;
    param_472 = _e374;
    let _e375 = alpha_mode_1;
    param_473 = _e375;
    let _e376 = alpha_cutoff_1;
    param_474 = _e376;
    let _e377 = iridescence_1;
    param_475 = _e377;
    let _e378 = iridescence_ior_1;
    param_476 = _e378;
    let _e379 = iridescence_thickness_1;
    param_477 = _e379;
    let _e380 = sheen_color_1;
    param_478 = _e380;
    let _e381 = sheen_roughness_1;
    param_479 = _e381;
    let _e382 = clearcoat_1;
    param_480 = _e382;
    let _e383 = clearcoat_roughness_1;
    param_481 = _e383;
    let _e384 = geomprop_Nworld_out;
    param_482 = _e384;
    let _e385 = emissive_1;
    param_483 = _e385;
    let _e386 = emissive_strength_1;
    param_484 = _e386;
    let _e387 = thickness_1;
    param_485 = _e387;
    let _e388 = attenuation_distance_1;
    param_486 = _e388;
    let _e389 = attenuation_color_1;
    param_487 = _e389;
    let _e390 = anisotropy_strength_1;
    param_488 = _e390;
    let _e391 = anisotropy_rotation_1;
    param_489 = _e391;
    let _e392 = dispersion_1;
    param_490 = _e392;
    IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_462), (&param_463), (&param_464), (&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491));
    let _e393 = param_491;
    SR_plastic_out = _e393;
    let _e394 = SR_plastic_out;
    return _e394;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e328 = (*basis_2).tW;
    let _e330 = (*vLocal)[0u];
    let _e333 = (*basis_2).bW;
    let _e335 = (*vLocal)[1u];
    let _e339 = (*basis_2).nW;
    let _e341 = (*vLocal)[2u];
    return (((_e328 * _e330) + (_e333 * _e335)) + (_e339 * _e341));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_492: vec3<f32>;
    var param_493: Basis;
    var param_494: vec3<f32>;
    var param_495: Basis;

    let _e334 = (*pW_3);
    g_ptP = _e334;
    let _e336 = (*basis_3).nW;
    g_ptN = _e336;
    let _e338 = (*basis_3).tW;
    g_ptTangent = _e338;
    let _e340 = (*basis_3).bW;
    g_ptBitangent = _e340;
    let _e341 = (*winputL_2);
    param_492 = _e341;
    let _e342 = (*basis_3);
    param_493 = _e342;
    let _e343 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_492), (&param_493));
    g_ptV = _e343;
    let _e344 = (*woutputL_2);
    param_494 = _e344;
    let _e345 = (*basis_3);
    param_495 = _e345;
    let _e346 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_494), (&param_495));
    g_ptL = _e346;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e348 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e348, 0f) / 3.1415927f);
    let _e351 = mtlxHostEvalSurface_u0028_();
    return _e351.color;
}

fn evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b(pW_4: ptr<function, vec3<f32>>, basis_4: ptr<function, Basis>, winputL_3: ptr<function, vec3<f32>>, woutputL_3: ptr<function, vec3<f32>>, surfaceshader_1: ptr<function, i32>, pdf_woutputL_3: ptr<function, f32>) -> vec3<f32> {
    var param_496: vec3<f32>;
    var param_497: Basis;
    var param_498: vec3<f32>;
    var param_499: vec3<f32>;
    var param_500: f32;
    var param_501: vec3<f32>;
    var param_502: Basis;
    var param_503: vec3<f32>;
    var param_504: vec3<f32>;
    var param_505: f32;
    var param_506: vec3<f32>;
    var param_507: Basis;
    var param_508: vec3<f32>;
    var param_509: vec3<f32>;
    var param_510: f32;

    let _e346 = (*surfaceshader_1);
    if (_e346 == 1i) {
        let _e348 = (*pW_4);
        param_496 = _e348;
        let _e349 = (*basis_4);
        param_497 = _e349;
        let _e350 = (*winputL_3);
        param_498 = _e350;
        let _e351 = (*woutputL_3);
        param_499 = _e351;
        let _e352 = (*pdf_woutputL_3);
        param_500 = _e352;
        let _e353 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_496), (&param_497), (&param_498), (&param_499), (&param_500));
        let _e354 = param_500;
        (*pdf_woutputL_3) = _e354;
        return _e353;
    } else {
        let _e355 = (*surfaceshader_1);
        if (_e355 == 2i) {
            let _e357 = (*pW_4);
            param_501 = _e357;
            let _e358 = (*basis_4);
            param_502 = _e358;
            let _e359 = (*winputL_3);
            param_503 = _e359;
            let _e360 = (*woutputL_3);
            param_504 = _e360;
            let _e361 = (*pdf_woutputL_3);
            param_505 = _e361;
            let _e362 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_501), (&param_502), (&param_503), (&param_504), (&param_505));
            let _e363 = param_505;
            (*pdf_woutputL_3) = _e363;
            return _e362;
        } else {
            let _e364 = (*pW_4);
            param_506 = _e364;
            let _e365 = (*basis_4);
            param_507 = _e365;
            let _e366 = (*winputL_3);
            param_508 = _e366;
            let _e367 = (*woutputL_3);
            param_509 = _e367;
            let _e368 = (*pdf_woutputL_3);
            param_510 = _e368;
            let _e369 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_506), (&param_507), (&param_508), (&param_509), (&param_510));
            let _e370 = param_510;
            (*pdf_woutputL_3) = _e370;
            return _e369;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    return false;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e325 = g_ptOpacity;
    return (_e325 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_14: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e327 = (*N_14);
    l = length(_e327);
    let _e329 = (*N_14);
    let _e330 = l;
    return (_e329 / vec3(max(_e330, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_15: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_511: vec3<f32>;

    let _e329 = (*N_15)[2u];
    let _e332 = (*N_15)[0u];
    if (abs(_e329) < abs(_e332)) {
        let _e336 = (*N_15)[2u];
        let _e338 = (*N_15)[0u];
        T = vec3<f32>(_e336, 0f, -(_e338));
    } else {
        let _e342 = (*N_15)[2u];
        let _e344 = (*N_15)[1u];
        T = vec3<f32>(0f, _e342, -(_e344));
    }
    let _e347 = T;
    param_511 = _e347;
    let _e348 = safe_normalize_u0028_vf3_u003b((&param_511));
    T = _e348;
    let _e349 = T;
    return _e349;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e329 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e329).x;
    let _e332 = (*index);
    let _e333 = width;
    let _e341 = (*index);
    let _e342 = width;
    let _e345 = textureLoad(texture, vec2<i32>((_e332 - (i32(floor((f32(_e332) / f32(_e333)))) * _e333)), (_e341 / _e342)), 0i);
    return _e345;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_512: i32;
    var param_513: i32;
    var param_514: i32;

    let _e333 = (*barycoord)[0u];
    let _e335 = (*faceIndices)[0u];
    param_512 = bitcast<i32>(_e335);
    let _e337 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_512));
    let _e340 = (*barycoord)[1u];
    let _e342 = (*faceIndices)[1u];
    param_513 = bitcast<i32>(_e342);
    let _e344 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_513));
    let _e348 = (*barycoord)[2u];
    let _e350 = (*faceIndices)[2u];
    param_514 = bitcast<i32>(_e350);
    let _e352 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_514));
    return (((_e337 * _e333) + (_e344 * _e340)) + (_e352 * _e348));
}

fn nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(minimum: ptr<function, vec3<f32>>, maximum: ptr<function, vec3<f32>>, origin: ptr<function, vec3<f32>>, direction: ptr<function, vec3<f32>>) -> f32 {
    var inverseDirection: vec3<f32>;
    var t0_2: vec3<f32>;
    var t1_2: vec3<f32>;
    var entry: vec3<f32>;
    var exit: vec3<f32>;
    var nearDistance: f32;
    var farDistance: f32;
    var local_10: f32;

    let _e337 = (*direction);
    inverseDirection = (vec3(1f) / _e337);
    let _e340 = (*minimum);
    let _e341 = (*origin);
    let _e343 = inverseDirection;
    t0_2 = ((_e340 - _e341) * _e343);
    let _e345 = (*maximum);
    let _e346 = (*origin);
    let _e348 = inverseDirection;
    t1_2 = ((_e345 - _e346) * _e348);
    let _e350 = t0_2;
    let _e351 = t1_2;
    entry = min(_e350, _e351);
    let _e353 = t0_2;
    let _e354 = t1_2;
    exit = max(_e353, _e354);
    let _e357 = entry[0u];
    let _e359 = entry[1u];
    let _e361 = entry[2u];
    nearDistance = max(_e357, max(_e359, _e361));
    let _e365 = exit[0u];
    let _e367 = exit[1u];
    let _e369 = exit[2u];
    farDistance = min(_e365, min(_e367, _e369));
    let _e372 = farDistance;
    let _e373 = nearDistance;
    if (_e372 >= max(_e373, 0f)) {
        let _e376 = nearDistance;
        local_10 = max(_e376, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e378 = local_10;
    return _e378;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_515: i32;
    var maximum_1: vec4<f32>;
    var param_516: i32;
    var metadata: vec4<f32>;
    var param_517: i32;
    var param_518: vec3<f32>;
    var param_519: vec3<f32>;
    var param_520: vec3<f32>;
    var param_521: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_522: i32;
    var p0_: vec3<f32>;
    var param_523: i32;
    var p1_: vec3<f32>;
    var param_524: i32;
    var p2_: vec3<f32>;
    var param_525: i32;
    var edge0_: vec3<f32>;
    var edge1_: vec3<f32>;
    var pvec: vec3<f32>;
    var determinant_: f32;
    var inverseDeterminant: f32;
    var tvec: vec3<f32>;
    var u: f32;
    var qvec: vec3<f32>;
    var v_3: f32;
    var distance_: f32;
    var left: i32;
    var right: i32;
    var phi_1296_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e378 = (*maxDistance);
    closest = _e378;
    found = false;
    loop {
        let _e379 = pointer;
        let _e381 = pointer;
        if ((_e379 >= 0i) && (_e381 < 64i)) {
            let _e384 = pointer;
            pointer = (_e384 - 1i);
            let _e387 = stack[_e384];
            nodeIndex = _e387;
            let _e388 = nodeIndex;
            param_515 = (_e388 * 3i);
            let _e390 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_515));
            minimum_1 = _e390;
            let _e391 = nodeIndex;
            param_516 = ((_e391 * 3i) + 1i);
            let _e394 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_516));
            maximum_1 = _e394;
            let _e395 = nodeIndex;
            param_517 = ((_e395 * 3i) + 2i);
            let _e398 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_517));
            metadata = _e398;
            let _e399 = minimum_1;
            param_518 = _e399.xyz;
            let _e401 = maximum_1;
            param_519 = _e401.xyz;
            let _e403 = (*rayOrigin);
            param_520 = _e403;
            let _e404 = (*rayDirection);
            param_521 = _e404;
            let _e405 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_518), (&param_519), (&param_520), (&param_521));
            let _e406 = closest;
            if (_e405 > _e406) {
                continue;
            }
            let _e409 = metadata[2u];
            if (_e409 > 0.5f) {
                let _e412 = metadata[0u];
                offset = i32((_e412 + 0.5f));
                let _e416 = metadata[1u];
                count = i32((_e416 + 0.5f));
                triangle = 0i;
                loop {
                    let _e419 = triangle;
                    let _e420 = count;
                    if (_e419 < _e420) {
                        let _e422 = offset;
                        let _e423 = triangle;
                        param_522 = (_e422 + _e423);
                        let _e425 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_522));
                        vertexIndices = vec3<u32>((_e425.xyz + vec3(0.5f)));
                        let _e431 = vertexIndices[0u];
                        param_523 = bitcast<i32>(_e431);
                        let _e433 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_523));
                        p0_ = _e433.xyz;
                        let _e436 = vertexIndices[1u];
                        param_524 = bitcast<i32>(_e436);
                        let _e438 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_524));
                        p1_ = _e438.xyz;
                        let _e441 = vertexIndices[2u];
                        param_525 = bitcast<i32>(_e441);
                        let _e443 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_525));
                        p2_ = _e443.xyz;
                        let _e445 = p1_;
                        let _e446 = p0_;
                        edge0_ = (_e445 - _e446);
                        let _e448 = p2_;
                        let _e449 = p0_;
                        edge1_ = (_e448 - _e449);
                        let _e451 = (*rayDirection);
                        let _e452 = edge1_;
                        pvec = cross(_e451, _e452);
                        let _e454 = edge0_;
                        let _e455 = pvec;
                        determinant_ = dot(_e454, _e455);
                        let _e457 = determinant_;
                        if (abs(_e457) < 0.00000001f) {
                            continue;
                        }
                        let _e460 = determinant_;
                        inverseDeterminant = (1f / _e460);
                        let _e462 = (*rayOrigin);
                        let _e463 = p0_;
                        tvec = (_e462 - _e463);
                        let _e465 = tvec;
                        let _e466 = pvec;
                        let _e468 = inverseDeterminant;
                        u = (dot(_e465, _e466) * _e468);
                        let _e470 = tvec;
                        let _e471 = edge0_;
                        qvec = cross(_e470, _e471);
                        let _e473 = (*rayDirection);
                        let _e474 = qvec;
                        let _e476 = inverseDeterminant;
                        v_3 = (dot(_e473, _e474) * _e476);
                        let _e478 = edge1_;
                        let _e479 = qvec;
                        let _e481 = inverseDeterminant;
                        distance_ = (dot(_e478, _e479) * _e481);
                        let _e483 = u;
                        let _e485 = v_3;
                        let _e487 = ((_e483 >= 0f) && (_e485 >= 0f));
                        phi_1296_ = _e487;
                        if _e487 {
                            let _e488 = u;
                            let _e489 = v_3;
                            phi_1296_ = ((_e488 + _e489) <= 1f);
                        }
                        let _e493 = phi_1296_;
                        let _e494 = distance_;
                        let _e497 = distance_;
                        let _e498 = closest;
                        if ((_e493 && (_e494 > 0f)) && (_e497 < _e498)) {
                            let _e501 = distance_;
                            closest = _e501;
                            let _e502 = distance_;
                            (*dist) = _e502;
                            let _e503 = u;
                            let _e505 = v_3;
                            let _e507 = u;
                            let _e508 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e503) - _e505), _e507, _e508);
                            let _e510 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e510.x, _e510.y, _e510.z, 0u);
                            let _e515 = edge0_;
                            let _e516 = edge1_;
                            (*faceNormal) = normalize(cross(_e515, _e516));
                            let _e519 = determinant_;
                            (*side) = select(1f, -1f, (_e519 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e522 = triangle;
                        triangle = (_e522 + 1i);
                    }
                }
            } else {
                let _e525 = metadata[0u];
                left = i32((_e525 + 0.5f));
                let _e529 = metadata[1u];
                right = i32((_e529 + 0.5f));
                let _e532 = pointer;
                if ((_e532 + 2i) >= 64i) {
                    continue;
                }
                let _e535 = pointer;
                let _e536 = (_e535 + 1i);
                pointer = _e536;
                let _e537 = right;
                stack[_e536] = _e537;
                let _e539 = pointer;
                let _e540 = (_e539 + 1i);
                pointer = _e540;
                let _e541 = left;
                stack[_e540] = _e541;
            }
            continue;
        } else {
            break;
        }
    }
    let _e543 = found;
    return _e543;
}

fn bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1: texture_2d<f32>, nodesSampler_1: sampler, indices_1: texture_2d<f32>, indicesSampler_1: sampler, positions_1: texture_2d<f32>, positionsSampler_1: sampler, rayOrigin_1: ptr<function, vec3<f32>>, rayDirection_1: ptr<function, vec3<f32>>, maxDistance_1: ptr<function, f32>, faceIndices_2: ptr<function, vec4<u32>>, faceNormal_1: ptr<function, vec3<f32>>, barycoord_2: ptr<function, vec3<f32>>, side_1: ptr<function, f32>, dist_1: ptr<function, f32>) -> bool {
    var param_526: vec3<f32>;
    var param_527: vec3<f32>;
    var param_528: f32;
    var param_529: vec4<u32>;
    var param_530: vec3<f32>;
    var param_531: vec3<f32>;
    var param_532: f32;
    var param_533: f32;

    let _e347 = (*rayOrigin_1);
    param_526 = _e347;
    let _e348 = (*rayDirection_1);
    param_527 = _e348;
    let _e349 = (*maxDistance_1);
    param_528 = _e349;
    let _e350 = (*faceIndices_2);
    param_529 = _e350;
    let _e351 = (*faceNormal_1);
    param_530 = _e351;
    let _e352 = (*barycoord_2);
    param_531 = _e352;
    let _e353 = (*side_1);
    param_532 = _e353;
    let _e354 = (*dist_1);
    param_533 = _e354;
    let _e355 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_526), (&param_527), (&param_528), (&param_529), (&param_530), (&param_531), (&param_532), (&param_533));
    let _e356 = param_529;
    (*faceIndices_2) = _e356;
    let _e357 = param_530;
    (*faceNormal_1) = _e357;
    let _e358 = param_531;
    (*barycoord_2) = _e358;
    let _e359 = param_532;
    (*side_1) = _e359;
    let _e360 = param_533;
    (*dist_1) = _e360;
    return _e355;
}

fn trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b(rayOrigin_2: ptr<function, vec3<f32>>, rayDir: ptr<function, vec3<f32>>, maxDistance_2: ptr<function, f32>, P_2: ptr<function, vec3<f32>>, Ns: ptr<function, vec3<f32>>, Ng: ptr<function, vec3<f32>>, Ts: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>, surfaceshader_2: ptr<function, i32>) -> bool {
    var faceIndices_surface: vec4<u32>;
    var faceNormal_surface: vec3<f32>;
    var barycoord_surface: vec3<f32>;
    var side_surface: f32;
    var dist_surface: f32;
    var hit_surface: bool;
    var param_534: vec3<f32>;
    var param_535: vec3<f32>;
    var param_536: f32;
    var param_537: vec4<u32>;
    var param_538: vec3<f32>;
    var param_539: vec3<f32>;
    var param_540: f32;
    var param_541: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_542: vec3<f32>;
    var gN: vec4<f32>;
    var param_543: vec3<f32>;
    var param_544: vec3<u32>;
    var gT: vec4<f32>;
    var param_545: vec3<f32>;
    var param_546: vec3<u32>;
    var local_11: vec3<f32>;
    var local_12: vec2<f32>;
    var local_13: vec3<f32>;
    var param_547: vec3<f32>;
    var param_548: vec3<f32>;
    var param_549: vec3<u32>;
    var phi_6891_: bool;
    var phi_6913_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e367 = (*rayOrigin_2);
    param_534 = _e367;
    let _e368 = (*rayDir);
    param_535 = _e368;
    let _e369 = (*maxDistance_2);
    param_536 = _e369;
    let _e370 = faceIndices_surface;
    param_537 = _e370;
    let _e371 = faceNormal_surface;
    param_538 = _e371;
    let _e372 = barycoord_surface;
    param_539 = _e372;
    let _e373 = side_surface;
    param_540 = _e373;
    let _e374 = dist_surface;
    param_541 = _e374;
    let _e375 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_534), (&param_535), (&param_536), (&param_537), (&param_538), (&param_539), (&param_540), (&param_541));
    let _e376 = param_537;
    faceIndices_surface = _e376;
    let _e377 = param_538;
    faceNormal_surface = _e377;
    let _e378 = param_539;
    barycoord_surface = _e378;
    let _e379 = param_540;
    side_surface = _e379;
    let _e380 = param_541;
    dist_surface = _e380;
    hit_surface = _e375;
    dist_closest = 100000000000000000000f;
    let _e381 = hit_surface;
    if _e381 {
        let _e382 = dist_closest;
        let _e383 = dist_surface;
        dist_closest = min(_e382, _e383);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e386 = (*rayDir)[1u];
    if (abs(_e386) > 0.0000000001f) {
        let _e390 = (*rayOrigin_2)[1u];
        let _e393 = (*rayDir)[1u];
        t = ((0.01f - _e390) / _e393);
        let _e395 = t;
        let _e396 = (_e395 > 0f);
        phi_6891_ = _e396;
        if _e396 {
            let _e397 = t;
            let _e398 = dist_closest;
            let _e399 = (*maxDistance_2);
            phi_6891_ = (_e397 < min(_e398, _e399));
        }
        let _e403 = phi_6891_;
        if _e403 {
            let _e404 = t;
            dist_ground = _e404;
            hit_ground = true;
        }
    }
    let _e405 = hit_surface;
    let _e406 = hit_ground;
    hit = (_e405 || _e406);
    let _e408 = hit;
    if !(_e408) {
        return false;
    }
    let _e410 = hit_surface;
    phi_6913_ = _e410;
    if _e410 {
        let _e411 = hit_ground;
        let _e413 = dist_surface;
        let _e414 = dist_ground;
        phi_6913_ = (!(_e411) || (_e413 <= _e414));
    }
    let _e418 = phi_6913_;
    if _e418 {
        let _e419 = (*rayOrigin_2);
        let _e420 = dist_surface;
        let _e421 = (*rayDir);
        (*P_2) = (_e419 + (_e421 * _e420));
        let _e424 = barycoord_surface;
        (*baryCoord) = _e424;
        let _e425 = faceNormal_surface;
        param_542 = _e425;
        let _e426 = safe_normalize_u0028_vf3_u003b((&param_542));
        (*Ng) = _e426;
        let _e427 = barycoord_surface;
        param_543 = _e427;
        let _e428 = faceIndices_surface;
        param_544 = _e428.xyz;
        let _e430 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_543), (&param_544));
        gN = _e430;
        let _e431 = barycoord_surface;
        param_545 = _e431;
        let _e432 = faceIndices_surface;
        param_546 = _e432.xyz;
        let _e434 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_545), (&param_546));
        gT = _e434;
        let _e436 = unnamed.has_normals_surface;
        if (_e436 != 0u) {
            let _e438 = gN;
            local_11 = _e438.xyz;
        } else {
            let _e440 = (*Ng);
            local_11 = _e440;
        }
        let _e441 = local_11;
        (*Ns) = _e441;
        let _e443 = unnamed.has_uvs_surface;
        if (_e443 != 0u) {
            let _e446 = gN[3u];
            let _e448 = gT[3u];
            local_12 = vec2<f32>(_e446, _e448);
        } else {
            let _e450 = barycoord_surface;
            local_12 = _e450.xy;
        }
        let _e452 = local_12;
        (*texCoord) = _e452;
        let _e454 = unnamed.has_tangents_surface;
        if (_e454 != 0u) {
            let _e456 = gT;
            local_13 = _e456.xyz;
        } else {
            let _e458 = (*Ns);
            param_547 = _e458;
            let _e459 = normalToTangent_u0028_vf3_u003b((&param_547));
            local_13 = _e459;
        }
        let _e460 = local_13;
        (*Ts) = _e460;
        let _e461 = barycoord_surface;
        param_548 = _e461;
        let _e462 = faceIndices_surface;
        param_549 = _e462.xyz;
        let _e464 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_548), (&param_549));
        (*surfaceshader_2) = select(1i, 0i, (_e464.x > 0.5f));
    } else {
        let _e468 = hit_ground;
        if _e468 {
            let _e469 = (*rayOrigin_2);
            let _e470 = dist_ground;
            let _e471 = (*rayDir);
            (*P_2) = (_e469 + (_e471 * _e470));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e474 = (*Ng);
            (*Ns) = _e474;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e476 = (*P_2)[0u];
            let _e478 = (*P_2)[2u];
            (*texCoord) = (((vec2<f32>(_e476, -(_e478)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b(rayOrigin_3: ptr<function, vec3<f32>>, rayDir_1: ptr<function, vec3<f32>>, maxDistance_3: ptr<function, f32>) -> f32 {
    var hit_1: bool;
    var pW_5: vec3<f32>;
    var nsW: vec3<f32>;
    var ngW: vec3<f32>;
    var TsW: vec3<f32>;
    var baryCoord_1: vec3<f32>;
    var texCoord_1: vec2<f32>;
    var surfaceshader_3: i32;
    var param_550: vec3<f32>;
    var param_551: vec3<f32>;
    var param_552: f32;
    var param_553: vec3<f32>;
    var param_554: vec3<f32>;
    var param_555: vec3<f32>;
    var param_556: vec3<f32>;
    var param_557: vec3<f32>;
    var param_558: vec2<f32>;
    var param_559: i32;
    var phi_7057_: bool;
    var phi_7061_: bool;

    let _e346 = (*rayOrigin_3);
    param_550 = _e346;
    let _e347 = (*rayDir_1);
    param_551 = _e347;
    let _e348 = (*maxDistance_3);
    param_552 = _e348;
    let _e349 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555), (&param_556), (&param_557), (&param_558), (&param_559));
    let _e350 = param_553;
    pW_5 = _e350;
    let _e351 = param_554;
    nsW = _e351;
    let _e352 = param_555;
    ngW = _e352;
    let _e353 = param_556;
    TsW = _e353;
    let _e354 = param_557;
    baryCoord_1 = _e354;
    let _e355 = param_558;
    texCoord_1 = _e355;
    let _e356 = param_559;
    surfaceshader_3 = _e356;
    hit_1 = _e349;
    let _e357 = hit_1;
    let _e358 = surfaceshader_3;
    let _e360 = (_e357 && (_e358 == 1i));
    phi_7057_ = _e360;
    if _e360 {
        let _e361 = mtlx_openpbr_is_opaque_u0028_();
        phi_7057_ = !(_e361);
    }
    let _e364 = phi_7057_;
    phi_7061_ = _e364;
    if _e364 {
        let _e365 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_7061_ = _e365;
    }
    let _e367 = phi_7061_;
    if _e367 {
        return 1f;
    }
    let _e368 = hit_1;
    return select(1f, 0f, _e368);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e327 = (*v_4)[0u];
    let _e329 = (*v_4)[1u];
    let _e331 = (*v_4)[2u];
    return max(_e327, max(_e329, _e331));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e327 = (*vWorld);
    let _e329 = (*basis_5).tW;
    let _e331 = (*vWorld);
    let _e333 = (*basis_5).bW;
    let _e335 = (*vWorld);
    let _e337 = (*basis_5).nW;
    return vec3<f32>(dot(_e327, _e329), dot(_e331, _e333), dot(_e335, _e337));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e328 = (*v_5);
    state = ((_e328 * 747796405u) + 2891336453u);
    let _e331 = state;
    let _e332 = state;
    let _e338 = state;
    word = (((_e331 >> bitcast<u32>(((_e332 >> bitcast<u32>(28u)) + 4u))) ^ _e338) * 277803737u);
    let _e341 = word;
    let _e344 = word;
    return ((_e341 >> bitcast<u32>(22u)) ^ _e344);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_560: u32;

    let _e327 = (*seed);
    param_560 = _e327;
    let _e328 = pcg_u0028_u1_u003b((&param_560));
    (*seed) = _e328;
    let _e329 = (*seed);
    return (f32((_e329 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_3: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e333 = (*i_3);
    let _e335 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e333), 0i);
    t0_3 = _e335;
    let _e336 = (*i_3);
    let _e338 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e336), 0i);
    t1_3 = _e338;
    let _e339 = (*i_3);
    let _e341 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e339), 0i);
    t2_2 = _e341;
    let _e342 = (*i_3);
    let _e344 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e342), 0i);
    t3_2 = _e344;
    let _e345 = (*i_3);
    let _e347 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e345), 0i);
    t4_2 = _e347;
    let _e348 = (*i_3);
    let _e350 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e348), 0i);
    t5_ = _e350;
    let _e351 = t0_3;
    l_1.position = _e351.xyz;
    let _e355 = t0_3[3u];
    l_1.decayRate = _e355;
    let _e357 = t1_3;
    l_1.direction = _e357.xyz;
    let _e361 = t1_3[3u];
    l_1.type_ = i32((_e361 + 0.5f));
    let _e365 = t2_2;
    l_1.color = _e365.xyz;
    let _e369 = t2_2[3u];
    l_1.intensity = _e369;
    let _e372 = t3_2[0u];
    l_1.innerCone = _e372;
    let _e375 = t3_2[1u];
    l_1.outerCone = _e375;
    let _e377 = t4_2;
    l_1.u = _e377.xyz;
    let _e380 = t5_;
    l_1.v = _e380.xyz;
    let _e383 = l_1;
    return _e383;
}

fn mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(index_1: ptr<function, i32>, pW_6: ptr<function, vec3<f32>>, basis_6: ptr<function, Basis>, woutputL_4: ptr<function, vec3<f32>>, woutputW: ptr<function, vec3<f32>>, maxDistance_4: ptr<function, f32>, rndSeed: ptr<function, u32>) -> vec3<f32> {
    var l_2: MtlxLight;
    var param_561: i32;
    var intensity: vec3<f32>;
    var param_562: vec3<f32>;
    var xi: vec2<f32>;
    var param_563: u32;
    var param_564: u32;
    var pointOnLight: vec3<f32>;
    var lightNormal: vec3<f32>;
    var param_565: vec3<f32>;
    var area: f32;
    var toLight: vec3<f32>;
    var distSq: f32;
    var distanceToLight: f32;
    var cosLight: f32;
    var param_566: vec3<f32>;
    var param_567: Basis;
    var param_568: vec3<f32>;
    var param_569: Basis;
    var toLight_1: vec3<f32>;
    var distanceToLight_1: f32;
    var attenuation: f32;
    var cosDir: f32;
    var param_570: vec3<f32>;
    var low: f32;
    var high: f32;
    var param_571: vec3<f32>;
    var param_572: Basis;

    let _e360 = (*index_1);
    param_561 = _e360;
    let _e361 = GetMtlxLight_u0028_i1_u003b((&param_561));
    l_2 = _e361;
    let _e363 = l_2.color;
    let _e365 = l_2.intensity;
    intensity = (_e363 * _e365);
    (*maxDistance_4) = 100000000000000000000f;
    let _e368 = l_2.type_;
    if (_e368 == 1i) {
        let _e371 = l_2.direction;
        param_562 = -(_e371);
        let _e373 = safe_normalize_u0028_vf3_u003b((&param_562));
        (*woutputW) = _e373;
    } else {
        let _e375 = l_2.type_;
        if (_e375 == 3i) {
            let _e377 = (*rndSeed);
            param_563 = _e377;
            let _e378 = rand_u0028_u1_u003b((&param_563));
            let _e379 = param_563;
            (*rndSeed) = _e379;
            let _e380 = (*rndSeed);
            param_564 = _e380;
            let _e381 = rand_u0028_u1_u003b((&param_564));
            let _e382 = param_564;
            (*rndSeed) = _e382;
            xi = vec2<f32>(_e378, _e381);
            let _e385 = l_2.position;
            let _e387 = xi[0u];
            let _e389 = l_2.u;
            let _e393 = xi[1u];
            let _e395 = l_2.v;
            pointOnLight = ((_e385 + (_e389 * _e387)) + (_e395 * _e393));
            let _e399 = l_2.u;
            let _e401 = l_2.v;
            param_565 = cross(_e399, _e401);
            let _e403 = safe_normalize_u0028_vf3_u003b((&param_565));
            lightNormal = _e403;
            let _e405 = l_2.u;
            let _e407 = l_2.v;
            area = length(cross(_e405, _e407));
            let _e410 = pointOnLight;
            let _e411 = (*pW_6);
            toLight = (_e410 - _e411);
            let _e413 = toLight;
            let _e414 = toLight;
            distSq = max(dot(_e413, _e414), 0.0000000001f);
            let _e417 = distSq;
            distanceToLight = sqrt(_e417);
            let _e419 = toLight;
            let _e420 = distanceToLight;
            (*woutputW) = (_e419 / vec3(_e420));
            let _e423 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e423 - 0.0002f));
            let _e426 = lightNormal;
            let _e427 = (*woutputW);
            cosLight = max(dot(_e426, -(_e427)), 0f);
            let _e431 = cosLight;
            let _e433 = area;
            if ((_e431 <= 0f) || (_e433 <= 0f)) {
                let _e436 = (*woutputW);
                param_566 = _e436;
                let _e437 = (*basis_6);
                param_567 = _e437;
                let _e438 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_566), (&param_567));
                (*woutputL_4) = _e438;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e439 = cosLight;
            let _e440 = area;
            let _e442 = distSq;
            let _e444 = intensity;
            intensity = (_e444 * ((_e439 * _e440) / _e442));
            let _e446 = (*woutputW);
            param_568 = _e446;
            let _e447 = (*basis_6);
            param_569 = _e447;
            let _e448 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_568), (&param_569));
            (*woutputL_4) = _e448;
            let _e449 = intensity;
            return _e449;
        } else {
            let _e451 = l_2.position;
            let _e452 = (*pW_6);
            toLight_1 = (_e451 - _e452);
            let _e454 = toLight_1;
            distanceToLight_1 = max(length(_e454), 0.0000000001f);
            let _e457 = toLight_1;
            let _e458 = distanceToLight_1;
            (*woutputW) = (_e457 / vec3(_e458));
            let _e461 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e461 - 0.0002f));
            let _e464 = distanceToLight_1;
            let _e467 = l_2.decayRate;
            attenuation = pow((_e464 + 1f), (_e467 + 0.0000000001f));
            let _e470 = attenuation;
            let _e472 = intensity;
            intensity = (_e472 / vec3(max(_e470, 0.0000000001f)));
            let _e476 = l_2.type_;
            if (_e476 == 2i) {
                let _e478 = (*woutputW);
                let _e480 = l_2.direction;
                param_570 = _e480;
                let _e481 = safe_normalize_u0028_vf3_u003b((&param_570));
                cosDir = dot(_e478, -(_e481));
                let _e485 = l_2.innerCone;
                let _e487 = l_2.outerCone;
                low = min(_e485, _e487);
                let _e490 = l_2.innerCone;
                high = _e490;
                let _e491 = low;
                let _e492 = high;
                let _e493 = cosDir;
                let _e495 = intensity;
                intensity = (_e495 * smoothstep(_e491, _e492, _e493));
            }
        }
    }
    let _e497 = (*woutputW);
    param_571 = _e497;
    let _e498 = (*basis_6);
    param_572 = _e498;
    let _e499 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_571), (&param_572));
    (*woutputL_4) = _e499;
    let _e500 = intensity;
    return _e500;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_573: i32;
    var power: f32;

    let _e329 = (*index_2);
    param_573 = _e329;
    let _e330 = GetMtlxLight_u0028_i1_u003b((&param_573));
    l_3 = _e330;
    let _e332 = l_3.color;
    let _e334 = l_3.intensity;
    power = length((_e332 * _e334));
    let _e338 = l_3.type_;
    if (_e338 == 3i) {
        let _e341 = l_3.u;
        let _e343 = l_3.v;
        let _e346 = power;
        power = (_e346 * length(cross(_e341, _e343)));
    }
    let _e348 = power;
    return _e348;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e330 = unnamed.sunAngularSize;
    theta_max = ((_e330 * 3.1415927f) / 180f);
    let _e333 = (*woutputW_1);
    let _e335 = unnamed.sunDir;
    let _e337 = theta_max;
    if (dot(_e333, _e335) < cos(_e337)) {
        return 0f;
    }
    let _e340 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e340)));
    let _e344 = solid_angle;
    return (1f / _e344);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e328 = unnamed.sunAngularSize;
    theta_max_1 = ((_e328 * 3.1415927f) / 180f);
    let _e331 = (*woutputW_2);
    let _e333 = unnamed.sunDir;
    let _e335 = theta_max_1;
    if (dot(_e331, _e333) < cos(_e335)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e339 = unnamed.sunPower;
    let _e341 = unnamed.sunColor;
    return (_e341 * _e339);
}

fn envMapLuminance_u0028_vf3_u003b(c_4: ptr<function, vec3<f32>>) -> f32 {
    let _e326 = (*c_4);
    return dot(_e326, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_5: ptr<function, vec3<f32>>) -> f32 {
    var theta: f32;
    var s_5: f32;
    var pdf_2: f32;
    var param_574: vec3<f32>;

    let _e332 = (*uv_3)[1u];
    theta = (_e332 * 3.1415927f);
    let _e334 = theta;
    s_5 = sin(_e334);
    let _e336 = s_5;
    if (_e336 <= 0f) {
        return 0f;
    }
    let _e338 = (*color_5);
    param_574 = _e338;
    let _e339 = envMapLuminance_u0028_vf3_u003b((&param_574));
    let _e341 = unnamed.envMapTotalSum;
    pdf_2 = (_e339 / max(_e341, 0.0000000001f));
    let _e344 = pdf_2;
    let _e347 = unnamed.envMapRes[0u];
    let _e351 = unnamed.envMapRes[1u];
    let _e353 = s_5;
    return (((_e344 * _e347) * _e351) / (19.739208f * _e353));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_1: f32;
    var s_6: f32;

    let _e330 = (*uv_4)[0u];
    phi_1 = (_e330 * 6.2831855f);
    let _e333 = (*uv_4)[1u];
    theta_1 = (_e333 * 3.1415927f);
    let _e335 = theta_1;
    s_6 = sin(_e335);
    let _e337 = s_6;
    let _e339 = phi_1;
    let _e342 = theta_1;
    let _e344 = s_6;
    let _e346 = phi_1;
    return vec3<f32>((-(_e337) * cos(_e339)), cos(_e342), (-(_e344) * sin(_e346)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_9: i32;

    let _e334 = unnamed.envMapRes;
    res = vec2<i32>(_e334);
    lower = 0i;
    let _e337 = res[1u];
    upper = (_e337 - 1i);
    loop {
        let _e339 = lower;
        let _e340 = upper;
        if (_e339 < _e340) {
            let _e342 = lower;
            let _e343 = upper;
            mid = ((_e342 + _e343) >> bitcast<u32>(1i));
            let _e347 = (*value);
            let _e349 = res[0u];
            let _e351 = mid;
            let _e353 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e349 - 1i), _e351), 0i);
            if (_e347 < _e353.x) {
                let _e356 = mid;
                upper = _e356;
            } else {
                let _e357 = mid;
                lower = (_e357 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e359 = lower;
    let _e361 = res[1u];
    y_5 = clamp(_e359, 0i, (_e361 - 1i));
    lower = 0i;
    let _e365 = res[0u];
    upper = (_e365 - 1i);
    loop {
        let _e367 = lower;
        let _e368 = upper;
        if (_e367 < _e368) {
            let _e370 = lower;
            let _e371 = upper;
            mid_1 = ((_e370 + _e371) >> bitcast<u32>(1i));
            let _e375 = (*value);
            let _e376 = mid_1;
            let _e377 = y_5;
            let _e379 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e376, _e377), 0i);
            if (_e375 < _e379.x) {
                let _e382 = mid_1;
                upper = _e382;
            } else {
                let _e383 = mid_1;
                lower = (_e383 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e385 = lower;
    let _e387 = res[0u];
    x_9 = clamp(_e385, 0i, (_e387 - 1i));
    let _e390 = x_9;
    let _e392 = y_5;
    let _e396 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e390), f32(_e392)) / _e396);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e328 = (*woutputW_3)[0u];
    let _e329 = (*woutputW_3);
    let _e330 = _e329.yz;
    let _e334 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e328, _e330.x, _e330.y), 0f);
    env = _e334;
    let _e335 = env;
    let _e338 = unnamed.skyPower;
    let _e341 = unnamed.skyColor;
    return ((_e335.xyz * _e338) * _e341);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_3: f32;
    var param_575: u32;
    var theta_2: f32;
    var param_576: u32;
    var x_10: f32;
    var y_6: f32;
    var z_1: f32;

    let _e334 = (*rndSeed_1);
    param_575 = _e334;
    let _e335 = rand_u0028_u1_u003b((&param_575));
    let _e336 = param_575;
    (*rndSeed_1) = _e336;
    r_3 = sqrt(_e335);
    let _e338 = (*rndSeed_1);
    param_576 = _e338;
    let _e339 = rand_u0028_u1_u003b((&param_576));
    let _e340 = param_576;
    (*rndSeed_1) = _e340;
    theta_2 = (6.2831855f * _e339);
    let _e342 = r_3;
    let _e343 = theta_2;
    x_10 = (_e342 * cos(_e343));
    let _e346 = r_3;
    let _e347 = theta_2;
    y_6 = (_e346 * sin(_e347));
    let _e350 = x_10;
    let _e351 = x_10;
    let _e354 = y_6;
    let _e355 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e350 * _e351)) - (_e354 * _e355))));
    let _e360 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e360) / 3.1415927f));
    let _e364 = x_10;
    let _e365 = y_6;
    let _e366 = z_1;
    return vec3<f32>(_e364, _e365, _e366);
}

fn skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_7: ptr<function, Basis>, woutputL_6: ptr<function, vec3<f32>>, woutputW_4: ptr<function, vec3<f32>>, pdfDir: ptr<function, f32>, rndSeed_2: ptr<function, u32>) -> vec3<f32> {
    var param_577: u32;
    var param_578: f32;
    var param_579: vec3<f32>;
    var param_580: Basis;
    var param_581: vec3<f32>;
    var uv_5: vec2<f32>;
    var param_582: u32;
    var param_583: f32;
    var param_584: vec2<f32>;
    var param_585: vec3<f32>;
    var param_586: vec3<f32>;
    var param_587: Basis;
    var color_6: vec3<f32>;
    var param_588: vec2<f32>;
    var param_589: vec3<f32>;

    let _e346 = unnamed.has_env_cdf;
    if !((_e346 != 0u)) {
        let _e349 = (*rndSeed_2);
        param_577 = _e349;
        let _e350 = (*pdfDir);
        param_578 = _e350;
        let _e351 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_577), (&param_578));
        let _e352 = param_577;
        (*rndSeed_2) = _e352;
        let _e353 = param_578;
        (*pdfDir) = _e353;
        (*woutputL_6) = _e351;
        let _e354 = (*woutputL_6);
        param_579 = _e354;
        let _e355 = (*basis_7);
        param_580 = _e355;
        let _e356 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_579), (&param_580));
        (*woutputW_4) = _e356;
        let _e357 = (*woutputW_4);
        param_581 = _e357;
        let _e358 = skyRadiance_u0028_vf3_u003b((&param_581));
        return _e358;
    }
    let _e359 = (*rndSeed_2);
    param_582 = _e359;
    let _e360 = rand_u0028_u1_u003b((&param_582));
    let _e361 = param_582;
    (*rndSeed_2) = _e361;
    let _e363 = unnamed.envMapTotalSum;
    param_583 = (_e360 * max(_e363, 0.0000000001f));
    let _e366 = envMapBinarySearch_u0028_f1_u003b((&param_583));
    uv_5 = _e366;
    let _e367 = uv_5;
    param_584 = _e367;
    let _e368 = envMapUvToDir_u0028_vf2_u003b((&param_584));
    param_585 = _e368;
    let _e369 = safe_normalize_u0028_vf3_u003b((&param_585));
    (*woutputW_4) = _e369;
    let _e370 = (*woutputW_4);
    param_586 = _e370;
    let _e371 = (*basis_7);
    param_587 = _e371;
    let _e372 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_586), (&param_587));
    (*woutputL_6) = _e372;
    let _e373 = uv_5;
    let _e374 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e373, 0f);
    color_6 = _e374.xyz;
    let _e376 = uv_5;
    param_588 = _e376;
    let _e377 = color_6;
    param_589 = _e377;
    let _e378 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_588), (&param_589));
    (*pdfDir) = _e378;
    let _e380 = unnamed.skyPower;
    let _e382 = unnamed.skyColor;
    let _e384 = color_6;
    return ((_e382 * _e380) * _e384);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_3: f32;

    let _e328 = (*d)[1u];
    theta_3 = acos(clamp(_e328, -1f, 1f));
    let _e332 = (*d)[2u];
    let _e334 = (*d)[0u];
    let _e338 = theta_3;
    return vec2<f32>(((3.1415927f + atan2(_e332, _e334)) * 0.15915494f), (_e338 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_590: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_591: vec3<f32>;
    var param_592: vec3<f32>;
    var color_7: vec3<f32>;
    var param_593: vec2<f32>;
    var param_594: vec3<f32>;

    let _e335 = unnamed.has_env_cdf;
    if !((_e335 != 0u)) {
        let _e338 = (*woutputL_7);
        param_590 = _e338;
        let _e339 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_590));
        return _e339;
    }
    let _e340 = (*woutputW_5);
    param_591 = _e340;
    let _e341 = safe_normalize_u0028_vf3_u003b((&param_591));
    param_592 = _e341;
    let _e342 = envMapDirToUv_u0028_vf3_u003b((&param_592));
    uv_6 = _e342;
    let _e343 = uv_6;
    let _e344 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e343, 0f);
    color_7 = _e344.xyz;
    let _e346 = uv_6;
    param_593 = _e346;
    let _e347 = color_7;
    param_594 = _e347;
    let _e348 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_593), (&param_594));
    return _e348;
}

fn sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_8: ptr<function, Basis>, woutputL_8: ptr<function, vec3<f32>>, woutputW_6: ptr<function, vec3<f32>>, pdfDir_1: ptr<function, f32>, rndSeed_3: ptr<function, u32>) -> vec3<f32> {
    var theta_max_2: f32;
    var theta_4: f32;
    var param_595: u32;
    var costheta: f32;
    var sintheta: f32;
    var phi_2: f32;
    var param_596: u32;
    var cosphi: f32;
    var sinphi: f32;
    var x_11: f32;
    var y_7: f32;
    var z_2: f32;
    var solid_angle_1: f32;
    var param_597: vec3<f32>;
    var param_598: Basis;
    var param_599: vec3<f32>;
    var param_600: Basis;

    let _e348 = unnamed.sunAngularSize;
    theta_max_2 = ((_e348 * 3.1415927f) / 180f);
    let _e351 = theta_max_2;
    let _e352 = (*rndSeed_3);
    param_595 = _e352;
    let _e353 = rand_u0028_u1_u003b((&param_595));
    let _e354 = param_595;
    (*rndSeed_3) = _e354;
    theta_4 = (_e351 * sqrt(_e353));
    let _e357 = theta_4;
    costheta = cos(_e357);
    let _e359 = costheta;
    let _e360 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e359 * _e360))));
    let _e365 = (*rndSeed_3);
    param_596 = _e365;
    let _e366 = rand_u0028_u1_u003b((&param_596));
    let _e367 = param_596;
    (*rndSeed_3) = _e367;
    phi_2 = (6.2831855f * _e366);
    let _e369 = phi_2;
    cosphi = cos(_e369);
    let _e371 = phi_2;
    sinphi = sin(_e371);
    let _e373 = sintheta;
    let _e374 = cosphi;
    x_11 = (_e373 * _e374);
    let _e376 = sintheta;
    let _e377 = sinphi;
    y_7 = (_e376 * _e377);
    let _e379 = costheta;
    z_2 = _e379;
    let _e380 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e380)));
    let _e384 = solid_angle_1;
    (*pdfDir_1) = (1f / _e384);
    let _e386 = x_11;
    let _e387 = y_7;
    let _e388 = z_2;
    param_597 = vec3<f32>(_e386, _e387, _e388);
    let _e390 = sunBasis;
    param_598 = _e390;
    let _e391 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_597), (&param_598));
    (*woutputW_6) = _e391;
    let _e392 = (*woutputW_6);
    param_599 = _e392;
    let _e393 = (*basis_8);
    param_600 = _e393;
    let _e394 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_599), (&param_600));
    (*woutputL_8) = _e394;
    let _e396 = unnamed.sunPower;
    let _e398 = unnamed.sunColor;
    let _e400 = solid_angle_1;
    return ((_e398 * _e396) / vec3(_e400));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e326 = unnamed.skyPower;
    let _e328 = unnamed.skyColor;
    return (length((_e328 * _e326)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e326 = unnamed.sunPower;
    let _e328 = unnamed.sunColor;
    return length((_e328 * _e326));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_4: i32;
    var param_601: i32;

    power_1 = 0f;
    i_4 = 0i;
    loop {
        let _e328 = i_4;
        if (_e328 < 1i) {
            let _e330 = i_4;
            let _e332 = unnamed.mtlxLightCount;
            if (_e330 >= _e332) {
                break;
            }
            let _e334 = i_4;
            param_601 = _e334;
            let _e335 = mtlxLightTotalPower_u0028_i1_u003b((&param_601));
            let _e336 = power_1;
            power_1 = (_e336 + _e335);
            continue;
        } else {
            break;
        }
        continuing {
            let _e338 = i_4;
            i_4 = (_e338 + 1i);
        }
    }
    let _e340 = power_1;
    return _e340;
}

fn LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(pW_7: ptr<function, vec3<f32>>, basis_9: ptr<function, Basis>, shadowL: ptr<function, vec3<f32>>, shadowW: ptr<function, vec3<f32>>, lightPdf: ptr<function, f32>, rndSeed_4: ptr<function, u32>) -> vec3<f32> {
    var w_mtlx: f32;
    var w_sun: f32;
    var local_14: f32;
    var w_sky: f32;
    var w_total: f32;
    var P_sun: f32;
    var P_sky: f32;
    var P_mtlx: f32;
    var r_4: f32;
    var param_602: u32;
    var maxDistance_5: f32;
    var Li_5: vec3<f32>;
    var pdf_sun: f32;
    var param_603: Basis;
    var param_604: vec3<f32>;
    var param_605: vec3<f32>;
    var param_606: f32;
    var param_607: u32;
    var param_608: vec3<f32>;
    var pdf_sky: f32;
    var param_609: vec3<f32>;
    var param_610: vec3<f32>;
    var param_611: Basis;
    var param_612: vec3<f32>;
    var param_613: vec3<f32>;
    var param_614: f32;
    var param_615: u32;
    var param_616: vec3<f32>;
    var param_617: vec3<f32>;
    var param_618: vec3<f32>;
    var target_: f32;
    var param_619: u32;
    var accum: f32;
    var selected: i32;
    var i_5: i32;
    var param_620: i32;
    var selectedPower: f32;
    var param_621: i32;
    var param_622: i32;
    var param_623: vec3<f32>;
    var param_624: Basis;
    var param_625: vec3<f32>;
    var param_626: vec3<f32>;
    var param_627: f32;
    var param_628: u32;
    var param_629: vec3<f32>;
    var param_630: vec3<f32>;
    var param_631: vec3<f32>;
    var param_632: vec3<f32>;
    var param_633: vec3<f32>;
    var shadowOrigin: vec3<f32>;
    var visibility: f32;
    var param_634: vec3<f32>;
    var param_635: vec3<f32>;
    var param_636: f32;
    var param_637: vec3<f32>;
    var shadowOrigin_1: vec3<f32>;
    var visibility_1: f32;
    var param_638: vec3<f32>;
    var param_639: vec3<f32>;
    var param_640: f32;
    var phi_8109_: bool;

    let _e392 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e392;
    let _e394 = unnamed.mtlxDisableSun;
    let _e395 = (_e394 != 0u);
    phi_8109_ = _e395;
    if !(_e395) {
        let _e398 = unnamed.mtlxLightCount;
        phi_8109_ = (_e398 > 0i);
    }
    let _e401 = phi_8109_;
    if _e401 {
        local_14 = 0f;
    } else {
        let _e402 = sunTotalPower_u0028_();
        local_14 = _e402;
    }
    let _e403 = local_14;
    w_sun = _e403;
    let _e404 = skyTotalPower_u0028_();
    w_sky = _e404;
    let _e405 = w_sun;
    let _e406 = w_sky;
    let _e408 = w_mtlx;
    w_total = max(0.0000000001f, ((_e405 + _e406) + _e408));
    let _e411 = w_sun;
    let _e412 = w_total;
    P_sun = (_e411 / _e412);
    let _e414 = w_sky;
    let _e415 = w_total;
    P_sky = (_e414 / _e415);
    let _e417 = w_mtlx;
    let _e418 = w_total;
    P_mtlx = (_e417 / _e418);
    let _e420 = (*rndSeed_4);
    param_602 = _e420;
    let _e421 = rand_u0028_u1_u003b((&param_602));
    let _e422 = param_602;
    (*rndSeed_4) = _e422;
    r_4 = _e421;
    maxDistance_5 = 100000000000000000000f;
    let _e423 = r_4;
    let _e424 = P_sun;
    if (_e423 < _e424) {
        let _e426 = (*basis_9);
        param_603 = _e426;
        let _e427 = (*shadowL);
        param_604 = _e427;
        let _e428 = (*shadowW);
        param_605 = _e428;
        let _e429 = pdf_sun;
        param_606 = _e429;
        let _e430 = (*rndSeed_4);
        param_607 = _e430;
        let _e431 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607));
        let _e432 = param_604;
        (*shadowL) = _e432;
        let _e433 = param_605;
        (*shadowW) = _e433;
        let _e434 = param_606;
        pdf_sun = _e434;
        let _e435 = param_607;
        (*rndSeed_4) = _e435;
        Li_5 = _e431;
        let _e436 = (*shadowW);
        param_608 = _e436;
        let _e437 = skyRadiance_u0028_vf3_u003b((&param_608));
        let _e438 = Li_5;
        Li_5 = (_e438 + _e437);
        let _e440 = (*shadowL);
        param_609 = _e440;
        let _e441 = (*shadowW);
        param_610 = _e441;
        let _e442 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_609), (&param_610));
        pdf_sky = _e442;
    } else {
        let _e443 = r_4;
        let _e444 = P_sun;
        let _e445 = P_sky;
        if (_e443 < (_e444 + _e445)) {
            let _e448 = (*basis_9);
            param_611 = _e448;
            let _e449 = (*rndSeed_4);
            param_615 = _e449;
            let _e450 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_611), (&param_612), (&param_613), (&param_614), (&param_615));
            let _e451 = param_612;
            (*shadowL) = _e451;
            let _e452 = param_613;
            (*shadowW) = _e452;
            let _e453 = param_614;
            pdf_sky = _e453;
            let _e454 = param_615;
            (*rndSeed_4) = _e454;
            Li_5 = _e450;
            let _e455 = w_sun;
            if (_e455 > 0f) {
                let _e457 = (*shadowW);
                param_616 = _e457;
                let _e458 = sunRadiance_u0028_vf3_u003b((&param_616));
                let _e459 = Li_5;
                Li_5 = (_e459 + _e458);
            }
            let _e461 = (*shadowL);
            param_617 = _e461;
            let _e462 = (*shadowW);
            param_618 = _e462;
            let _e463 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_617), (&param_618));
            pdf_sun = _e463;
        } else {
            let _e464 = (*rndSeed_4);
            param_619 = _e464;
            let _e465 = rand_u0028_u1_u003b((&param_619));
            let _e466 = param_619;
            (*rndSeed_4) = _e466;
            let _e467 = w_mtlx;
            target_ = (_e465 * max(_e467, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_5 = 0i;
            loop {
                let _e470 = i_5;
                if (_e470 < 1i) {
                    let _e472 = i_5;
                    let _e474 = unnamed.mtlxLightCount;
                    if (_e472 >= _e474) {
                        break;
                    }
                    let _e476 = i_5;
                    param_620 = _e476;
                    let _e477 = mtlxLightTotalPower_u0028_i1_u003b((&param_620));
                    let _e478 = accum;
                    accum = (_e478 + _e477);
                    let _e480 = target_;
                    let _e481 = accum;
                    if (_e480 <= _e481) {
                        let _e483 = i_5;
                        selected = _e483;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e484 = i_5;
                    i_5 = (_e484 + 1i);
                }
            }
            let _e486 = selected;
            param_621 = _e486;
            let _e487 = mtlxLightTotalPower_u0028_i1_u003b((&param_621));
            selectedPower = max(_e487, 0.0000000001f);
            let _e489 = selected;
            param_622 = _e489;
            let _e490 = (*pW_7);
            param_623 = _e490;
            let _e491 = (*basis_9);
            param_624 = _e491;
            let _e492 = (*rndSeed_4);
            param_628 = _e492;
            let _e493 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627), (&param_628));
            let _e494 = param_625;
            (*shadowL) = _e494;
            let _e495 = param_626;
            (*shadowW) = _e495;
            let _e496 = param_627;
            maxDistance_5 = _e496;
            let _e497 = param_628;
            (*rndSeed_4) = _e497;
            Li_5 = _e493;
            let _e498 = (*shadowL);
            param_629 = _e498;
            let _e499 = (*shadowW);
            param_630 = _e499;
            let _e500 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_629), (&param_630));
            pdf_sun = _e500;
            let _e501 = (*shadowL);
            param_631 = _e501;
            let _e502 = (*shadowW);
            param_632 = _e502;
            let _e503 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_631), (&param_632));
            pdf_sky = _e503;
            let _e504 = P_mtlx;
            let _e505 = selectedPower;
            let _e507 = w_mtlx;
            (*lightPdf) = ((_e504 * _e505) / max(_e507, 0.0000000001f));
            let _e511 = (*shadowL)[2u];
            if (_e511 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e513 = Li_5;
            param_633 = _e513;
            let _e514 = maxComponent_u0028_vf3_u003b((&param_633));
            if (_e514 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e516 = (*pW_7);
            let _e518 = (*basis_9).nW;
            let _e519 = (*shadowW);
            let _e521 = (*basis_9).nW;
            shadowOrigin = (_e516 + ((_e518 * sign(dot(_e519, _e521))) * 0.0001f));
            let _e527 = shadowOrigin;
            param_634 = _e527;
            let _e528 = (*shadowW);
            param_635 = _e528;
            let _e529 = maxDistance_5;
            param_636 = _e529;
            let _e530 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_634), (&param_635), (&param_636));
            visibility = _e530;
            let _e531 = visibility;
            let _e532 = Li_5;
            return (_e532 * _e531);
        }
    }
    let _e534 = P_sun;
    let _e535 = pdf_sun;
    let _e537 = P_sky;
    let _e538 = pdf_sky;
    (*lightPdf) = ((_e534 * _e535) + (_e537 * _e538));
    let _e542 = (*shadowL)[2u];
    if (_e542 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e544 = Li_5;
    param_637 = _e544;
    let _e545 = maxComponent_u0028_vf3_u003b((&param_637));
    if (_e545 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e547 = (*pW_7);
    let _e549 = (*basis_9).nW;
    let _e550 = (*shadowW);
    let _e552 = (*basis_9).nW;
    shadowOrigin_1 = (_e547 + ((_e549 * sign(dot(_e550, _e552))) * 0.0001f));
    let _e558 = shadowOrigin_1;
    param_638 = _e558;
    let _e559 = (*shadowW);
    param_639 = _e559;
    param_640 = 100000000000000000000f;
    let _e560 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_638), (&param_639), (&param_640));
    visibility_1 = _e560;
    let _e561 = visibility_1;
    let _e562 = Li_5;
    return (_e562 * _e561);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_641: vec3<f32>;
    var param_642: Basis;

    let _e331 = (*pW_8);
    g_ptP = _e331;
    let _e333 = (*basis_10).nW;
    g_ptN = _e333;
    let _e335 = (*basis_10).tW;
    g_ptTangent = _e335;
    let _e337 = (*basis_10).bW;
    g_ptBitangent = _e337;
    let _e339 = (*basis_10).texCoord;
    g_ptTexcoord = _e339;
    let _e340 = (*winputL_4);
    param_641 = _e340;
    let _e341 = (*basis_10);
    param_642 = _e341;
    let _e342 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_641), (&param_642));
    g_ptV = _e342;
    let _e344 = (*basis_10).nW;
    g_ptL = _e344;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e345 = alpha_15;
    g_ptOpacity = clamp(_e345, 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e347 = mtlxHostEvalSurface_u0028_();
    let _e348 = (*rndSeed_5);
    (*rndSeed_5) = (_e348 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_643: vec3<f32>;
    var param_644: Basis;
    var param_645: vec3<f32>;
    var param_646: u32;

    emissionSeed = 0u;
    let _e332 = (*pW_9);
    param_643 = _e332;
    let _e333 = (*basis_11);
    param_644 = _e333;
    param_645 = vec3<f32>(0f, 0f, 1f);
    let _e334 = emissionSeed;
    param_646 = _e334;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_643), (&param_644), (&param_645), (&param_646));
    let _e335 = param_646;
    emissionSeed = _e335;
    let _e336 = g_ptEmission;
    return max(_e336, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_647: vec3<f32>;
    var param_648: Basis;

    let _e330 = (*pW_10);
    param_647 = _e330;
    let _e331 = (*basis_12);
    param_648 = _e331;
    let _e332 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_647), (&param_648));
    return _e332;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_649: u32;
    var param_650: f32;
    var param_651: vec3<f32>;
    var phi_7130_: bool;

    let _e335 = (*winputL_6)[2u];
    if (_e335 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e337 = (*rndSeed_6);
    param_649 = _e337;
    let _e338 = (*pdf_woutputL_4);
    param_650 = _e338;
    let _e339 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_649), (&param_650));
    let _e340 = param_649;
    (*rndSeed_6) = _e340;
    let _e341 = param_650;
    (*pdf_woutputL_4) = _e341;
    (*woutputL_9) = _e339;
    let _e343 = unnamed.wireframe;
    let _e344 = (_e343 != 0u);
    phi_7130_ = _e344;
    if _e344 {
        let _e346 = (*basis_13).baryCoord;
        param_651 = _e346;
        let _e347 = minComponent_u0028_vf3_u003b((&param_651));
        phi_7130_ = (_e347 < 0.003f);
    }
    let _e350 = phi_7130_;
    if _e350 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e352 = unnamed.neutral_color;
    return (_e352 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_652: u32;
    var param_653: f32;
    var param_654: vec3<f32>;

    let _e335 = (*winputL_7)[2u];
    if (_e335 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e337 = (*rndSeed_7);
    param_652 = _e337;
    let _e338 = (*pdf_woutputL_5);
    param_653 = _e338;
    let _e339 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_652), (&param_653));
    let _e340 = param_652;
    (*rndSeed_7) = _e340;
    let _e341 = param_653;
    (*pdf_woutputL_5) = _e341;
    (*woutputL_10) = _e339;
    let _e342 = (*pW_12);
    param_654 = _e342;
    let _e343 = ground_albedo_u0028_vf3_u003b((&param_654));
    return (_e343 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e329 = (*w_1)[2u];
    if (abs(_e329) < 0.00000011920929f) {
        return 0f;
    }
    let _e332 = (*alpha_x);
    let _e334 = (*w_1)[0u];
    let _e336 = (*alpha_x);
    let _e338 = (*w_1)[0u];
    let _e341 = (*alpha_y);
    let _e343 = (*w_1)[1u];
    let _e345 = (*alpha_y);
    let _e347 = (*w_1)[1u];
    let _e352 = (*w_1)[2u];
    let _e354 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e332 * _e334) * (_e336 * _e338)) + ((_e341 * _e343) * (_e345 * _e347))) / (_e352 * _e354))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_655: vec3<f32>;
    var param_656: f32;
    var param_657: f32;
    var param_658: vec3<f32>;
    var param_659: f32;
    var param_660: f32;

    let _e335 = (*woL);
    param_655 = _e335;
    let _e336 = (*alpha_x_1);
    param_656 = _e336;
    let _e337 = (*alpha_y_1);
    param_657 = _e337;
    let _e338 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_655), (&param_656), (&param_657));
    let _e340 = (*wiL_1);
    param_658 = _e340;
    let _e341 = (*alpha_x_1);
    param_659 = _e341;
    let _e342 = (*alpha_y_1);
    param_660 = _e342;
    let _e343 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_658), (&param_659), (&param_660));
    return (1f / ((1f + _e338) + _e343));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e331 = (*alpha_x_2);
    ax = max(_e331, 0.0000000001f);
    let _e333 = (*alpha_y_2);
    ay = max(_e333, 0.0000000001f);
    let _e335 = ax;
    let _e337 = ay;
    let _e340 = (*m_5)[0u];
    let _e341 = ax;
    let _e344 = (*m_5)[0u];
    let _e345 = ax;
    let _e349 = (*m_5)[1u];
    let _e350 = ay;
    let _e353 = (*m_5)[1u];
    let _e354 = ay;
    let _e359 = (*m_5)[2u];
    let _e361 = (*m_5)[2u];
    let _e365 = (*m_5)[0u];
    let _e366 = ax;
    let _e369 = (*m_5)[0u];
    let _e370 = ax;
    let _e374 = (*m_5)[1u];
    let _e375 = ay;
    let _e378 = (*m_5)[1u];
    let _e379 = ay;
    let _e384 = (*m_5)[2u];
    let _e386 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e335) * _e337) * (((((_e340 / _e341) * (_e344 / _e345)) + ((_e349 / _e350) * (_e353 / _e354))) + (_e359 * _e361)) * ((((_e365 / _e366) * (_e369 / _e370)) + ((_e374 / _e375) * (_e378 / _e379))) + (_e384 * _e386))));
    let _e391 = Ddenom;
    return (1f / max(_e391, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_661: vec3<f32>;
    var param_662: f32;
    var param_663: f32;

    let _e331 = (*w_2);
    param_661 = _e331;
    let _e332 = (*alpha_x_3);
    param_662 = _e332;
    let _e333 = (*alpha_y_3);
    param_663 = _e333;
    let _e334 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_661), (&param_662), (&param_663));
    return (1f / (1f + _e334));
}

fn ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b(wiL_2: ptr<function, vec3<f32>>, alpha_x_4: ptr<function, f32>, alpha_y_4: ptr<function, f32>, rndSeed_8: ptr<function, u32>) -> vec3<f32> {
    var Xi_2: vec2<f32>;
    var param_664: u32;
    var param_665: u32;
    var V_13: vec3<f32>;
    var alpha_13: vec2<f32>;
    var phi_3: f32;
    var z_3: f32;
    var sinTheta_1: f32;
    var x_12: f32;
    var y_8: f32;
    var c_5: vec3<f32>;
    var H_7: vec3<f32>;

    let _e341 = (*rndSeed_8);
    param_664 = _e341;
    let _e342 = rand_u0028_u1_u003b((&param_664));
    let _e343 = param_664;
    (*rndSeed_8) = _e343;
    let _e344 = (*rndSeed_8);
    param_665 = _e344;
    let _e345 = rand_u0028_u1_u003b((&param_665));
    let _e346 = param_665;
    (*rndSeed_8) = _e346;
    Xi_2 = vec2<f32>(_e342, _e345);
    let _e348 = (*wiL_2);
    V_13 = _e348;
    let _e349 = (*alpha_x_4);
    let _e350 = (*alpha_y_4);
    alpha_13 = vec2<f32>(_e349, _e350);
    let _e352 = V_13;
    let _e354 = alpha_13;
    let _e355 = (_e352.xy * _e354);
    let _e357 = V_13[2u];
    V_13 = normalize(vec3<f32>(_e355.x, _e355.y, _e357));
    let _e363 = Xi_2[0u];
    phi_3 = (6.2831855f * _e363);
    let _e366 = Xi_2[1u];
    let _e369 = V_13[2u];
    let _e373 = V_13[2u];
    z_3 = (((1f - _e366) * (1f + _e369)) - _e373);
    let _e375 = z_3;
    let _e376 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e375 * _e376)), 0f, 1f));
    let _e381 = sinTheta_1;
    let _e382 = phi_3;
    x_12 = (_e381 * cos(_e382));
    let _e385 = sinTheta_1;
    let _e386 = phi_3;
    y_8 = (_e385 * sin(_e386));
    let _e389 = x_12;
    let _e390 = y_8;
    let _e391 = z_3;
    c_5 = vec3<f32>(_e389, _e390, _e391);
    let _e393 = c_5;
    let _e394 = V_13;
    H_7 = (_e393 + _e394);
    let _e396 = H_7;
    let _e398 = alpha_13;
    let _e399 = (_e396.xy * _e398);
    let _e401 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e399.x, _e399.y, _e401));
    let _e406 = H_7;
    return _e406;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_6: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e330 = (*mui);
    c_6 = _e330;
    let _e331 = (*eta_ti);
    let _e332 = (*eta_ti);
    let _e334 = c_6;
    let _e335 = c_6;
    mut2_ = (((_e331 * _e332) + (_e334 * _e335)) - 1f);
    let _e339 = mut2_;
    if (_e339 <= 0f) {
        return 1f;
    }
    let _e341 = mut2_;
    g_1 = sqrt(_e341);
    let _e343 = g_1;
    let _e344 = c_6;
    let _e346 = g_1;
    let _e347 = c_6;
    let _e350 = g_1;
    let _e351 = c_6;
    let _e353 = g_1;
    let _e354 = c_6;
    let _e359 = g_1;
    let _e360 = c_6;
    let _e362 = c_6;
    let _e365 = g_1;
    let _e366 = c_6;
    let _e368 = c_6;
    let _e372 = g_1;
    let _e373 = c_6;
    let _e375 = c_6;
    let _e378 = g_1;
    let _e379 = c_6;
    let _e381 = c_6;
    return ((0.5f * (((_e343 - _e344) / (_e346 + _e347)) * ((_e350 - _e351) / (_e353 + _e354)))) * (1f + (((((_e359 + _e360) * _e362) - 1f) / (((_e365 - _e366) * _e368) + 1f)) * ((((_e372 + _e373) * _e375) - 1f) / (((_e378 - _e379) * _e381) + 1f)))));
}

fn mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b(pW_13: ptr<function, vec3<f32>>, basis_15: ptr<function, Basis>, winputL_8: ptr<function, vec3<f32>>, rndSeed_9: ptr<function, u32>, woutputL_11: ptr<function, vec3<f32>>, pdf_woutputL_6: ptr<function, f32>, internal_medium: ptr<function, Volume>) -> vec3<f32> {
    var m_metal: f32;
    var m_rough: f32;
    var m_aniso: f32;
    var m_base: vec3<f32>;
    var m_specC: vec3<f32>;
    var m_specW: f32;
    var m_ior: f32;
    var m_coatW: f32;
    var m_coatRough: f32;
    var m_coatAniso: f32;
    var m_coatIor: f32;
    var V_14: vec3<f32>;
    var NdotV_20: f32;
    var alpha_14: f32;
    var anisoAspect: f32;
    var sampleAlpha: vec2<f32>;
    var coatAlpha: f32;
    var coatAnisoAspect: f32;
    var coatSampleAlpha: vec2<f32>;
    var F0d: f32;
    var F0_8: vec3<f32>;
    var F0lum: f32;
    var Fv: f32;
    var coatFv: f32;
    var param_666: f32;
    var param_667: f32;
    var pCoat: f32;
    var xiLobe: f32;
    var param_668: u32;
    var pTrans: f32;
    var m_transW: f32;
    var m_transC: vec3<f32>;
    var m_transD: f32;
    var Hc: vec3<f32>;
    var param_669: vec3<f32>;
    var param_670: f32;
    var param_671: f32;
    var param_672: u32;
    var pdfCoat: f32;
    var param_673: vec3<f32>;
    var param_674: f32;
    var param_675: f32;
    var param_676: vec3<f32>;
    var param_677: f32;
    var param_678: f32;
    var pdfBaseSpec: f32;
    var param_679: vec3<f32>;
    var param_680: f32;
    var param_681: f32;
    var param_682: vec3<f32>;
    var param_683: f32;
    var param_684: f32;
    var pdfBaseDiff: f32;
    var param_685: vec3<f32>;
    var diffLumCoat: f32;
    var pSpecCoat: f32;
    var ignorePdfCoat: f32;
    var param_686: vec3<f32>;
    var param_687: Basis;
    var param_688: vec3<f32>;
    var param_689: vec3<f32>;
    var param_690: f32;
    var externalTransmission: bool;
    var etaRatio: f32;
    var local_15: f32;
    var Hdelta: vec3<f32>;
    var HdotWiDelta: f32;
    var discrDelta: f32;
    var beamIncidentDelta: vec3<f32>;
    var Tdelta: f32;
    var param_691: f32;
    var param_692: f32;
    var tintDelta: vec3<f32>;
    var Vsample: vec3<f32>;
    var Ht_2: vec3<f32>;
    var param_693: vec3<f32>;
    var param_694: f32;
    var param_695: f32;
    var param_696: u32;
    var HdotWi: f32;
    var discr: f32;
    var beamIncident: vec3<f32>;
    var Hr: vec3<f32>;
    var VoH: f32;
    var LoH: f32;
    var denomT: f32;
    var jacT: f32;
    var DvT: f32;
    var param_697: vec3<f32>;
    var param_698: f32;
    var param_699: f32;
    var local_16: vec3<f32>;
    var param_700: vec3<f32>;
    var param_701: f32;
    var param_702: f32;
    var D_3: f32;
    var local_17: vec3<f32>;
    var param_703: vec3<f32>;
    var param_704: f32;
    var param_705: f32;
    var G2_: f32;
    var param_706: vec3<f32>;
    var param_707: vec3<f32>;
    var param_708: f32;
    var param_709: f32;
    var etaRefl: f32;
    var T_1: f32;
    var param_710: f32;
    var param_711: f32;
    var tint_2: vec3<f32>;
    var diffLum: f32;
    var pSpec: f32;
    var param_712: u32;
    var H_8: vec3<f32>;
    var param_713: vec3<f32>;
    var param_714: f32;
    var param_715: f32;
    var param_716: u32;
    var pdfTmp: f32;
    var param_717: u32;
    var param_718: f32;
    var Hh: vec3<f32>;
    var pdfSpec: f32;
    var param_719: vec3<f32>;
    var param_720: f32;
    var param_721: f32;
    var param_722: vec3<f32>;
    var param_723: f32;
    var param_724: f32;
    var pdfDiff: f32;
    var param_725: vec3<f32>;
    var pdfCoat_1: f32;
    var param_726: vec3<f32>;
    var param_727: f32;
    var param_728: f32;
    var param_729: vec3<f32>;
    var param_730: f32;
    var param_731: f32;
    var ignorePdf: f32;
    var param_732: vec3<f32>;
    var param_733: Basis;
    var param_734: vec3<f32>;
    var param_735: vec3<f32>;
    var param_736: f32;
    var phi_6333_: bool;
    var phi_6468_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e479 = metallic_1;
    m_metal = clamp(_e479, 0f, 1f);
    let _e481 = roughness_18;
    m_rough = clamp(_e481, 0f, 1f);
    m_aniso = 0f;
    let _e483 = base_color_1;
    m_base = (_e483 * 1f);
    let _e485 = specular_color_1;
    m_specC = _e485;
    let _e486 = specular_1;
    m_specW = _e486;
    let _e487 = ior_7;
    m_ior = max(_e487, 1.001f);
    m_coatW = 0f;
    m_coatRough = 0f;
    m_coatAniso = 0f;
    m_coatIor = 1.5f;
    let _e489 = (*winputL_8);
    V_14 = _e489;
    let _e491 = V_14[2u];
    if (_e491 < 0f) {
        let _e493 = V_14;
        V_14 = -(_e493);
    }
    let _e496 = V_14[2u];
    NdotV_20 = max(_e496, 0.0001f);
    let _e498 = m_rough;
    let _e499 = m_rough;
    alpha_14 = clamp((_e498 * _e499), 0.0001f, 1f);
    let _e502 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e502));
    let _e505 = alpha_14;
    let _e506 = anisoAspect;
    let _e507 = anisoAspect;
    let _e513 = alpha_14;
    let _e514 = anisoAspect;
    let _e516 = anisoAspect;
    let _e517 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e505 * sqrt((2f / ((_e506 * _e507) + 1f)))), ((_e513 * _e514) * sqrt((2f / ((_e516 * _e517) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e525 = m_coatRough;
    let _e526 = m_coatRough;
    coatAlpha = clamp((_e525 * _e526), 0.0001f, 1f);
    let _e529 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e529));
    let _e532 = coatAlpha;
    let _e533 = coatAnisoAspect;
    let _e534 = coatAnisoAspect;
    let _e540 = coatAlpha;
    let _e541 = coatAnisoAspect;
    let _e543 = coatAnisoAspect;
    let _e544 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e532 * sqrt((2f / ((_e533 * _e534) + 1f)))), ((_e540 * _e541) * sqrt((2f / ((_e543 * _e544) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e552 = m_ior;
    let _e554 = m_ior;
    F0d = pow(((_e552 - 1f) / (_e554 + 1f)), 2f);
    let _e558 = F0d;
    let _e560 = m_specC;
    let _e563 = m_specW;
    let _e565 = m_base;
    let _e566 = m_metal;
    F0_8 = mix(((vec3(_e558) * max(_e560, vec3<f32>(0f, 0f, 0f))) * _e563), _e565, vec3(_e566));
    let _e570 = F0_8[0u];
    let _e572 = F0_8[1u];
    let _e574 = F0_8[2u];
    F0lum = max(_e570, max(_e572, _e574));
    let _e577 = F0lum;
    let _e578 = F0lum;
    let _e580 = NdotV_20;
    Fv = (_e577 + ((1f - _e578) * pow((1f - _e580), 5f)));
    let _e585 = NdotV_20;
    param_666 = _e585;
    let _e586 = m_coatIor;
    param_667 = _e586;
    let _e587 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_666), (&param_667));
    coatFv = _e587;
    let _e588 = m_coatW;
    let _e589 = coatFv;
    pCoat = clamp((_e588 * _e589), 0f, 0.75f);
    let _e592 = (*rndSeed_9);
    param_668 = _e592;
    let _e593 = rand_u0028_u1_u003b((&param_668));
    let _e594 = param_668;
    (*rndSeed_9) = _e594;
    xiLobe = _e593;
    pTrans = 0f;
    let _e595 = transmission_1;
    m_transW = clamp(_e595, 0f, 1f);
    let _e597 = attenuation_color_1;
    m_transC = _e597;
    let _e598 = attenuation_distance_1;
    m_transD = _e598;
    let _e599 = m_transW;
    let _e600 = Fv;
    pTrans = clamp((_e599 * (1f - _e600)), 0f, 0.95f);
    let _e604 = xiLobe;
    let _e605 = pCoat;
    if (_e604 < _e605) {
        let _e607 = V_14;
        param_669 = _e607;
        let _e609 = coatSampleAlpha[0u];
        param_670 = _e609;
        let _e611 = coatSampleAlpha[1u];
        param_671 = _e611;
        let _e612 = (*rndSeed_9);
        param_672 = _e612;
        let _e613 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_669), (&param_670), (&param_671), (&param_672));
        let _e614 = param_672;
        (*rndSeed_9) = _e614;
        Hc = _e613;
        let _e615 = V_14;
        let _e617 = Hc;
        (*woutputL_11) = reflect(-(_e615), _e617);
        let _e620 = (*woutputL_11)[2u];
        if (_e620 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e622 = V_14;
        param_673 = _e622;
        let _e624 = coatSampleAlpha[0u];
        param_674 = _e624;
        let _e626 = coatSampleAlpha[1u];
        param_675 = _e626;
        let _e627 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_673), (&param_674), (&param_675));
        let _e628 = V_14;
        let _e629 = (*woutputL_11);
        param_676 = normalize((_e628 + _e629));
        let _e633 = coatSampleAlpha[0u];
        param_677 = _e633;
        let _e635 = coatSampleAlpha[1u];
        param_678 = _e635;
        let _e636 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_676), (&param_677), (&param_678));
        let _e638 = NdotV_20;
        pdfCoat = ((_e627 * _e636) / (4f * _e638));
        let _e641 = V_14;
        param_679 = _e641;
        let _e643 = sampleAlpha[0u];
        param_680 = _e643;
        let _e645 = sampleAlpha[1u];
        param_681 = _e645;
        let _e646 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_679), (&param_680), (&param_681));
        let _e647 = V_14;
        let _e648 = (*woutputL_11);
        param_682 = normalize((_e647 + _e648));
        let _e652 = sampleAlpha[0u];
        param_683 = _e652;
        let _e654 = sampleAlpha[1u];
        param_684 = _e654;
        let _e655 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_682), (&param_683), (&param_684));
        let _e657 = NdotV_20;
        pdfBaseSpec = ((_e646 * _e655) / (4f * _e657));
        let _e660 = (*woutputL_11);
        param_685 = _e660;
        let _e661 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_685));
        pdfBaseDiff = _e661;
        let _e662 = m_metal;
        let _e664 = m_base;
        diffLumCoat = ((1f - _e662) * dot(_e664, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e667 = Fv;
        let _e668 = Fv;
        let _e669 = Fv;
        let _e671 = diffLumCoat;
        pSpecCoat = clamp((_e667 / ((_e668 + ((1f - _e669) * _e671)) + 0.001f)), 0.05f, 0.95f);
        let _e677 = pCoat;
        let _e678 = pdfCoat;
        let _e680 = pCoat;
        let _e682 = pTrans;
        let _e685 = pSpecCoat;
        let _e686 = pdfBaseSpec;
        let _e688 = pSpecCoat;
        let _e690 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e677 * _e678) + (((1f - _e680) * (1f - _e682)) * ((_e685 * _e686) + ((1f - _e688) * _e690)))), 0.000001f);
        let _e696 = (*pW_13);
        param_686 = _e696;
        let _e697 = (*basis_15);
        param_687 = _e697;
        let _e698 = (*winputL_8);
        param_688 = _e698;
        let _e699 = (*woutputL_11);
        param_689 = _e699;
        let _e700 = ignorePdfCoat;
        param_690 = _e700;
        let _e701 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_686), (&param_687), (&param_688), (&param_689), (&param_690));
        let _e702 = param_690;
        ignorePdfCoat = _e702;
        return _e701;
    }
    let _e703 = xiLobe;
    let _e704 = pCoat;
    let _e705 = pCoat;
    let _e707 = pTrans;
    if (_e703 < (_e704 + ((1f - _e705) * _e707))) {
        let _e712 = (*winputL_8)[2u];
        externalTransmission = (_e712 > 0f);
        let _e714 = externalTransmission;
        if _e714 {
            let _e715 = m_ior;
            local_15 = (1f / _e715);
        } else {
            let _e717 = m_ior;
            local_15 = _e717;
        }
        let _e718 = local_15;
        etaRatio = _e718;
        let _e719 = alpha_14;
        if (_e719 <= 0.001f) {
            let _e721 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e721));
            let _e724 = Hdelta;
            let _e725 = (*winputL_8);
            HdotWiDelta = dot(_e724, _e725);
            let _e727 = etaRatio;
            let _e728 = etaRatio;
            let _e730 = HdotWiDelta;
            let _e731 = HdotWiDelta;
            discrDelta = (1f - ((_e727 * _e728) * (1f - (_e730 * _e731))));
            let _e736 = discrDelta;
            if (_e736 < 0f) {
                let _e738 = (*winputL_8);
                let _e740 = (*winputL_8);
                let _e741 = Hdelta;
                let _e744 = Hdelta;
                (*woutputL_11) = (-(_e738) + (_e744 * (2f * dot(_e740, _e741))));
                let _e747 = pCoat;
                let _e749 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e747) * _e749), 0.000001f);
                let _e752 = m_transW;
                let _e753 = (*pdf_woutputL_6);
                let _e756 = (*woutputL_11)[2u];
                return vec3(((_e752 * _e753) / max(abs(_e756), 0.0000000001f)));
            }
            let _e761 = etaRatio;
            let _e762 = (*winputL_8);
            let _e764 = Hdelta;
            let _e765 = HdotWiDelta;
            let _e768 = etaRatio;
            let _e769 = HdotWiDelta;
            let _e772 = discrDelta;
            beamIncidentDelta = ((_e762 * _e761) - ((_e764 * sign(_e765)) * ((_e768 * abs(_e769)) - sqrt(_e772))));
            let _e777 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e777));
            let _e781 = (*winputL_8)[2u];
            let _e783 = (*woutputL_11)[2u];
            if ((_e781 * _e783) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e786 = m_transD;
            let _e787 = (_e786 > 0f);
            phi_6333_ = _e787;
            if _e787 {
                let _e788 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_6333_ = !(_e788);
            }
            let _e791 = phi_6333_;
            if _e791 {
                let _e792 = m_transC;
                let _e796 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e792))) / vec3(_e796));
                (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
                (*internal_medium).anisotropy = 0f;
            }
            let _e802 = HdotWiDelta;
            let _e804 = etaRatio;
            param_691 = abs(_e802);
            param_692 = (1f / _e804);
            let _e806 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_691), (&param_692));
            Tdelta = clamp((1f - _e806), 0f, 1f);
            let _e809 = m_transD;
            let _e811 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e811, (_e809 == 0f));
            let _e813 = pCoat;
            let _e815 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e813) * _e815), 0.000001f);
            let _e818 = m_transW;
            let _e819 = tintDelta;
            let _e821 = Tdelta;
            let _e823 = (*pdf_woutputL_6);
            let _e826 = (*woutputL_11)[2u];
            return ((((_e819 * _e818) * _e821) * _e823) / vec3(max(abs(_e826), 0.0000000001f)));
        }
        let _e831 = (*winputL_8);
        Vsample = _e831;
        let _e833 = Vsample[2u];
        if (_e833 < 0f) {
            let _e836 = Vsample[2u];
            Vsample[2u] = (_e836 * -1f);
        }
        let _e839 = Vsample;
        param_693 = _e839;
        let _e841 = sampleAlpha[0u];
        param_694 = _e841;
        let _e843 = sampleAlpha[1u];
        param_695 = _e843;
        let _e844 = (*rndSeed_9);
        param_696 = _e844;
        let _e845 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_693), (&param_694), (&param_695), (&param_696));
        let _e846 = param_696;
        (*rndSeed_9) = _e846;
        Ht_2 = _e845;
        let _e848 = (*winputL_8)[2u];
        if (_e848 < 0f) {
            let _e851 = Ht_2[2u];
            Ht_2[2u] = (_e851 * -1f);
        }
        let _e854 = Ht_2;
        let _e855 = (*winputL_8);
        HdotWi = dot(_e854, _e855);
        let _e857 = etaRatio;
        let _e858 = etaRatio;
        let _e860 = HdotWi;
        let _e861 = HdotWi;
        discr = (1f - ((_e857 * _e858) * (1f - (_e860 * _e861))));
        let _e866 = discr;
        if (_e866 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e868 = etaRatio;
        let _e869 = (*winputL_8);
        let _e871 = Ht_2;
        let _e872 = HdotWi;
        let _e875 = etaRatio;
        let _e876 = HdotWi;
        let _e879 = discr;
        beamIncident = ((_e869 * _e868) - ((_e871 * sign(_e872)) * ((_e875 * abs(_e876)) - sqrt(_e879))));
        let _e884 = beamIncident;
        (*woutputL_11) = -(normalize(_e884));
        let _e888 = (*winputL_8)[2u];
        let _e890 = (*woutputL_11)[2u];
        if ((_e888 * _e890) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e893 = m_transD;
        let _e894 = (_e893 > 0f);
        phi_6468_ = _e894;
        if _e894 {
            let _e895 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_6468_ = !(_e895);
        }
        let _e898 = phi_6468_;
        if _e898 {
            let _e899 = m_transC;
            let _e903 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e899))) / vec3(_e903));
            (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
            (*internal_medium).anisotropy = 0f;
        }
        let _e909 = V_14;
        let _e910 = m_ior;
        let _e911 = (*woutputL_11);
        Hr = normalize(-((_e909 + (_e911 * _e910))));
        let _e917 = Hr[2u];
        if (_e917 < 0f) {
            let _e919 = Hr;
            Hr = -(_e919);
        }
        let _e921 = (*winputL_8);
        let _e922 = Ht_2;
        VoH = abs(dot(_e921, _e922));
        let _e925 = (*woutputL_11);
        let _e926 = Ht_2;
        LoH = abs(dot(_e925, _e926));
        let _e929 = LoH;
        let _e930 = etaRatio;
        let _e931 = VoH;
        denomT = (_e929 + (_e930 * _e931));
        let _e934 = etaRatio;
        let _e935 = etaRatio;
        let _e937 = VoH;
        let _e939 = denomT;
        let _e940 = denomT;
        jacT = (((_e934 * _e935) * _e937) / max((_e939 * _e940), 0.00000001f));
        let _e944 = Vsample;
        param_697 = _e944;
        let _e946 = sampleAlpha[0u];
        param_698 = _e946;
        let _e948 = sampleAlpha[1u];
        param_699 = _e948;
        let _e949 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_697), (&param_698), (&param_699));
        let _e950 = VoH;
        let _e953 = Ht_2[2u];
        if (abs(_e953) > 0f) {
            let _e957 = Ht_2[0u];
            let _e959 = Ht_2[1u];
            let _e961 = Ht_2[2u];
            local_16 = vec3<f32>(_e957, _e959, abs(_e961));
        } else {
            let _e964 = Ht_2;
            local_16 = _e964;
        }
        let _e965 = local_16;
        param_700 = _e965;
        let _e967 = sampleAlpha[0u];
        param_701 = _e967;
        let _e969 = sampleAlpha[1u];
        param_702 = _e969;
        let _e970 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_700), (&param_701), (&param_702));
        let _e973 = (*winputL_8)[2u];
        DvT = (((_e949 * _e950) * _e970) / max(abs(_e973), 0.0001f));
        let _e977 = pCoat;
        let _e979 = pTrans;
        let _e981 = DvT;
        let _e983 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e977) * _e979) * _e981) * _e983), 0.000001f);
        let _e987 = Ht_2[2u];
        if (abs(_e987) > 0f) {
            let _e991 = Ht_2[0u];
            let _e993 = Ht_2[1u];
            let _e995 = Ht_2[2u];
            local_17 = vec3<f32>(_e991, _e993, abs(_e995));
        } else {
            let _e998 = Ht_2;
            local_17 = _e998;
        }
        let _e999 = local_17;
        param_703 = _e999;
        let _e1001 = sampleAlpha[0u];
        param_704 = _e1001;
        let _e1003 = sampleAlpha[1u];
        param_705 = _e1003;
        let _e1004 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_703), (&param_704), (&param_705));
        D_3 = _e1004;
        let _e1005 = (*winputL_8);
        param_706 = _e1005;
        let _e1006 = (*woutputL_11);
        param_707 = _e1006;
        let _e1008 = sampleAlpha[0u];
        param_708 = _e1008;
        let _e1010 = sampleAlpha[1u];
        param_709 = _e1010;
        let _e1011 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_706), (&param_707), (&param_708), (&param_709));
        G2_ = _e1011;
        let _e1012 = etaRatio;
        etaRefl = (1f / _e1012);
        let _e1014 = VoH;
        param_710 = _e1014;
        let _e1015 = etaRefl;
        param_711 = _e1015;
        let _e1016 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_710), (&param_711));
        T_1 = clamp((1f - _e1016), 0f, 1f);
        let _e1019 = m_transD;
        let _e1021 = m_transC;
        tint_2 = select(vec3<f32>(1f, 1f, 1f), _e1021, (_e1019 == 0f));
        let _e1023 = m_transW;
        let _e1024 = tint_2;
        let _e1026 = T_1;
        let _e1028 = VoH;
        let _e1030 = jacT;
        let _e1032 = D_3;
        let _e1034 = G2_;
        let _e1037 = (*woutputL_11)[2u];
        let _e1040 = (*winputL_8)[2u];
        return (((((((_e1024 * _e1023) * _e1026) * _e1028) * _e1030) * _e1032) * _e1034) / vec3(max((abs(_e1037) * abs(_e1040)), 0.0000000001f)));
    }
    let _e1046 = m_metal;
    let _e1048 = m_base;
    diffLum = ((1f - _e1046) * dot(_e1048, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1051 = Fv;
    let _e1052 = Fv;
    let _e1053 = Fv;
    let _e1055 = diffLum;
    pSpec = clamp((_e1051 / ((_e1052 + ((1f - _e1053) * _e1055)) + 0.001f)), 0.05f, 0.95f);
    let _e1061 = (*rndSeed_9);
    param_712 = _e1061;
    let _e1062 = rand_u0028_u1_u003b((&param_712));
    let _e1063 = param_712;
    (*rndSeed_9) = _e1063;
    let _e1064 = pSpec;
    if (_e1062 < _e1064) {
        let _e1066 = V_14;
        param_713 = _e1066;
        let _e1068 = sampleAlpha[0u];
        param_714 = _e1068;
        let _e1070 = sampleAlpha[1u];
        param_715 = _e1070;
        let _e1071 = (*rndSeed_9);
        param_716 = _e1071;
        let _e1072 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_713), (&param_714), (&param_715), (&param_716));
        let _e1073 = param_716;
        (*rndSeed_9) = _e1073;
        H_8 = _e1072;
        let _e1074 = V_14;
        let _e1076 = H_8;
        (*woutputL_11) = reflect(-(_e1074), _e1076);
    } else {
        let _e1078 = (*rndSeed_9);
        param_717 = _e1078;
        let _e1079 = pdfTmp;
        param_718 = _e1079;
        let _e1080 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_717), (&param_718));
        let _e1081 = param_717;
        (*rndSeed_9) = _e1081;
        let _e1082 = param_718;
        pdfTmp = _e1082;
        (*woutputL_11) = _e1080;
    }
    let _e1084 = (*woutputL_11)[2u];
    if (_e1084 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1086 = V_14;
    let _e1087 = (*woutputL_11);
    Hh = normalize((_e1086 + _e1087));
    let _e1090 = V_14;
    param_719 = _e1090;
    let _e1092 = sampleAlpha[0u];
    param_720 = _e1092;
    let _e1094 = sampleAlpha[1u];
    param_721 = _e1094;
    let _e1095 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_719), (&param_720), (&param_721));
    let _e1096 = Hh;
    param_722 = _e1096;
    let _e1098 = sampleAlpha[0u];
    param_723 = _e1098;
    let _e1100 = sampleAlpha[1u];
    param_724 = _e1100;
    let _e1101 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_722), (&param_723), (&param_724));
    let _e1103 = NdotV_20;
    pdfSpec = ((_e1095 * _e1101) / (4f * _e1103));
    let _e1106 = (*woutputL_11);
    param_725 = _e1106;
    let _e1107 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_725));
    pdfDiff = _e1107;
    let _e1108 = V_14;
    param_726 = _e1108;
    let _e1110 = coatSampleAlpha[0u];
    param_727 = _e1110;
    let _e1112 = coatSampleAlpha[1u];
    param_728 = _e1112;
    let _e1113 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_726), (&param_727), (&param_728));
    let _e1114 = Hh;
    param_729 = _e1114;
    let _e1116 = coatSampleAlpha[0u];
    param_730 = _e1116;
    let _e1118 = coatSampleAlpha[1u];
    param_731 = _e1118;
    let _e1119 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_729), (&param_730), (&param_731));
    let _e1121 = NdotV_20;
    pdfCoat_1 = ((_e1113 * _e1119) / (4f * _e1121));
    let _e1124 = pCoat;
    let _e1125 = pdfCoat_1;
    let _e1127 = pCoat;
    let _e1129 = pTrans;
    let _e1132 = pSpec;
    let _e1133 = pdfSpec;
    let _e1135 = pSpec;
    let _e1137 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1124 * _e1125) + (((1f - _e1127) * (1f - _e1129)) * ((_e1132 * _e1133) + ((1f - _e1135) * _e1137)))), 0.000001f);
    let _e1143 = (*pW_13);
    param_732 = _e1143;
    let _e1144 = (*basis_15);
    param_733 = _e1144;
    let _e1145 = (*winputL_8);
    param_734 = _e1145;
    let _e1146 = (*woutputL_11);
    param_735 = _e1146;
    let _e1147 = ignorePdf;
    param_736 = _e1147;
    let _e1148 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_732), (&param_733), (&param_734), (&param_735), (&param_736));
    let _e1149 = param_736;
    ignorePdf = _e1149;
    return _e1148;
}

fn sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b(pW_14: ptr<function, vec3<f32>>, basis_16: ptr<function, Basis>, winputL_9: ptr<function, vec3<f32>>, rndSeed_10: ptr<function, u32>, surfaceshader_4: ptr<function, i32>, woutputL_12: ptr<function, vec3<f32>>, pdf_woutputL_7: ptr<function, f32>, internal_medium_1: ptr<function, Volume>) -> vec3<f32> {
    var param_737: vec3<f32>;
    var param_738: Basis;
    var param_739: vec3<f32>;
    var param_740: u32;
    var param_741: vec3<f32>;
    var param_742: f32;
    var param_743: Volume;
    var param_744: vec3<f32>;
    var param_745: Basis;
    var param_746: vec3<f32>;
    var param_747: u32;
    var param_748: vec3<f32>;
    var param_749: f32;
    var param_750: vec3<f32>;
    var param_751: Basis;
    var param_752: vec3<f32>;
    var param_753: u32;
    var param_754: vec3<f32>;
    var param_755: f32;

    let _e352 = (*surfaceshader_4);
    if (_e352 == 1i) {
        let _e354 = (*pW_14);
        param_737 = _e354;
        let _e355 = (*basis_16);
        param_738 = _e355;
        let _e356 = (*winputL_9);
        param_739 = _e356;
        let _e357 = (*rndSeed_10);
        param_740 = _e357;
        let _e358 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_737), (&param_738), (&param_739), (&param_740), (&param_741), (&param_742), (&param_743));
        let _e359 = param_740;
        (*rndSeed_10) = _e359;
        let _e360 = param_741;
        (*woutputL_12) = _e360;
        let _e361 = param_742;
        (*pdf_woutputL_7) = _e361;
        let _e362 = param_743;
        (*internal_medium_1) = _e362;
        return _e358;
    } else {
        let _e363 = (*surfaceshader_4);
        if (_e363 == 2i) {
            let _e365 = (*pW_14);
            param_744 = _e365;
            let _e366 = (*basis_16);
            param_745 = _e366;
            let _e367 = (*winputL_9);
            param_746 = _e367;
            let _e368 = (*rndSeed_10);
            param_747 = _e368;
            let _e369 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_744), (&param_745), (&param_746), (&param_747), (&param_748), (&param_749));
            let _e370 = param_747;
            (*rndSeed_10) = _e370;
            let _e371 = param_748;
            (*woutputL_12) = _e371;
            let _e372 = param_749;
            (*pdf_woutputL_7) = _e372;
            return _e369;
        } else {
            let _e373 = (*pW_14);
            param_750 = _e373;
            let _e374 = (*basis_16);
            param_751 = _e374;
            let _e375 = (*winputL_9);
            param_752 = _e375;
            let _e376 = (*rndSeed_10);
            param_753 = _e376;
            let _e377 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755));
            let _e378 = param_753;
            (*rndSeed_10) = _e378;
            let _e379 = param_754;
            (*woutputL_12) = _e379;
            let _e380 = param_755;
            (*pdf_woutputL_7) = _e380;
            return _e377;
        }
    }
}

fn mtlx_openpbr_thin_film_ior_u0028_() -> f32 {
    return 1.5f;
}

fn mtlx_openpbr_thin_film_thickness_nm_u0028_() -> f32 {
    return 0f;
}

fn mtlx_openpbr_specular_ior_u0028_() -> f32 {
    let _e325 = ior_7;
    return max(_e325, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e325 = roughness_18;
    return clamp(_e325, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    return 0f;
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e325 = transmission_1;
    return clamp(_e325, 0f, 1f);
}

fn evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(basis_17: ptr<function, Basis>, winputL_10: ptr<function, vec3<f32>>) -> vec3<f32> {
    var cosI: f32;
    var fd_11: FresnelData;
    var param_756: f32;
    var param_757: f32;
    var param_758: f32;
    var F_4: vec3<f32>;
    var param_759: f32;
    var param_760: FresnelData;
    var reflectedL: vec3<f32>;
    var reflectedW: vec3<f32>;
    var param_761: vec3<f32>;
    var param_762: Basis;
    var envRadiance: vec3<f32>;
    var param_763: vec3<f32>;
    var param_764: vec3<f32>;

    let _e342 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e342) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e344 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e344 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e346 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e346 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e348 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e348 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e351 = (*winputL_10)[2u];
    cosI = clamp(abs(_e351), 0.0001f, 1f);
    let _e354 = mtlx_openpbr_specular_ior_u0028_();
    let _e356 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e357 = mtlx_openpbr_thin_film_ior_u0028_();
    param_756 = max(_e354, 1.001f);
    param_757 = _e356;
    param_758 = _e357;
    let _e358 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_756), (&param_757), (&param_758));
    fd_11 = _e358;
    let _e359 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e360 = cosI;
    param_759 = _e360;
    let _e361 = fd_11;
    param_760 = _e361;
    let _e362 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_759), (&param_760));
    F_4 = (_e362 * _e359);
    let _e364 = (*winputL_10);
    reflectedL = reflect(-(_e364), vec3<f32>(0f, 0f, 1f));
    let _e368 = reflectedL[2u];
    if (_e368 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e370 = reflectedL;
    param_761 = _e370;
    let _e371 = (*basis_17);
    param_762 = _e371;
    let _e372 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_761), (&param_762));
    reflectedW = _e372;
    let _e373 = reflectedW;
    param_763 = _e373;
    let _e374 = sunRadiance_u0028_vf3_u003b((&param_763));
    let _e375 = reflectedW;
    param_764 = _e375;
    let _e376 = skyRadiance_u0028_vf3_u003b((&param_764));
    envRadiance = (_e374 + _e376);
    let _e378 = envRadiance;
    let _e380 = unnamed.skyPower;
    let _e383 = unnamed.skyColor;
    envRadiance = max(_e378, (_e383 * (0.25f * _e380)));
    let _e386 = F_4;
    let _e387 = envRadiance;
    return (_e386 * _e387);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_765: vec3<f32>;
    var param_766: vec3<f32>;

    let _e332 = (*nW);
    param_765 = _e332;
    let _e333 = safe_normalize_u0028_vf3_u003b((&param_765));
    basis_18.nW = _e333;
    let _e335 = (*tW);
    param_766 = _e335;
    let _e336 = safe_normalize_u0028_vf3_u003b((&param_766));
    basis_18.tW = _e336;
    let _e339 = basis_18.nW;
    let _e341 = basis_18.tW;
    basis_18.bW = cross(_e339, _e341);
    let _e344 = (*baryCoord_2);
    basis_18.baryCoord = _e344;
    let _e346 = (*texCoord_2);
    basis_18.texCoord = _e346;
    let _e348 = basis_18;
    return _e348;
}

fn powerHeuristic_u0028_f1_u003b_f1_u003b(a_4: f32, b_1: f32) -> f32 {
    return ((a_4 * a_4) / max(0.0000000001f, ((a_4 * a_4) + (b_1 * b_1))));
}

fn LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(shadowW_1: ptr<function, vec3<f32>>, basis_19: ptr<function, Basis>) -> f32 {
    var shadowL_1: vec3<f32>;
    var param_767: vec3<f32>;
    var param_768: Basis;
    var pdf_sky_1: f32;
    var param_769: vec3<f32>;
    var param_770: vec3<f32>;
    var pdf_sun_1: f32;
    var param_771: vec3<f32>;
    var param_772: vec3<f32>;
    var w_sun_1: f32;
    var local_18: f32;
    var w_sky_1: f32;
    var w_total_1: f32;
    var P_sun_1: f32;
    var P_sky_1: f32;
    var lightPdf_1: f32;
    var phi_8397_: bool;

    let _e343 = (*shadowW_1);
    param_767 = _e343;
    let _e344 = (*basis_19);
    param_768 = _e344;
    let _e345 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_767), (&param_768));
    shadowL_1 = _e345;
    let _e346 = shadowL_1;
    param_769 = _e346;
    let _e347 = (*shadowW_1);
    param_770 = _e347;
    let _e348 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_769), (&param_770));
    pdf_sky_1 = _e348;
    let _e349 = shadowL_1;
    param_771 = _e349;
    let _e350 = (*shadowW_1);
    param_772 = _e350;
    let _e351 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_771), (&param_772));
    pdf_sun_1 = _e351;
    let _e353 = unnamed.mtlxDisableSun;
    let _e354 = (_e353 != 0u);
    phi_8397_ = _e354;
    if !(_e354) {
        let _e357 = unnamed.mtlxLightCount;
        phi_8397_ = (_e357 > 0i);
    }
    let _e360 = phi_8397_;
    if _e360 {
        local_18 = 0f;
    } else {
        let _e361 = sunTotalPower_u0028_();
        local_18 = _e361;
    }
    let _e362 = local_18;
    w_sun_1 = _e362;
    let _e363 = skyTotalPower_u0028_();
    w_sky_1 = _e363;
    let _e364 = w_sun_1;
    let _e365 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e364 + _e365));
    let _e368 = w_sun_1;
    let _e369 = w_total_1;
    P_sun_1 = (_e368 / _e369);
    let _e371 = w_sky_1;
    let _e372 = w_total_1;
    P_sky_1 = (_e371 / _e372);
    let _e374 = P_sun_1;
    let _e375 = pdf_sun_1;
    let _e377 = P_sky_1;
    let _e378 = pdf_sky_1;
    lightPdf_1 = ((_e374 * _e375) + (_e377 * _e378));
    let _e381 = lightPdf_1;
    return _e381;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_773: vec3<f32>;
    var param_774: vec3<f32>;

    let _e329 = (*nW_1);
    param_773 = _e329;
    let _e330 = safe_normalize_u0028_vf3_u003b((&param_773));
    basis_20.nW = _e330;
    let _e332 = (*nW_1);
    param_774 = _e332;
    let _e333 = normalToTangent_u0028_vf3_u003b((&param_774));
    basis_20.tW = _e333;
    let _e336 = basis_20.nW;
    let _e338 = basis_20.tW;
    basis_20.bW = cross(_e336, _e338);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e343 = basis_20;
    return _e343;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e335 = (*cameraWorld);
    lookDirection = (_e335 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e337 = (*inverseProjection);
    nearVector = (_e337 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e340 = nearVector[2u];
    let _e342 = nearVector[3u];
    nearDistance_1 = abs((_e340 / _e342));
    let _e345 = (*cameraWorld);
    origin_1 = (_e345 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e347 = (*inverseProjection);
    let _e348 = (*coordinate);
    direction_1 = (_e347 * vec4<f32>(_e348.x, _e348.y, 0.5f, 1f));
    let _e354 = direction_1[3u];
    let _e355 = direction_1;
    direction_1 = (_e355 / vec4(_e354));
    let _e358 = (*cameraWorld);
    let _e359 = direction_1;
    let _e361 = origin_1;
    direction_1 = ((_e358 * _e359) - _e361);
    let _e363 = direction_1;
    let _e365 = nearDistance_1;
    let _e367 = direction_1;
    let _e368 = lookDirection;
    let _e372 = origin_1;
    let _e374 = (_e372.xyz + ((_e363.xyz * _e365) / vec3(dot(_e367, _e368))));
    origin_1[0u] = _e374.x;
    origin_1[1u] = _e374.y;
    origin_1[2u] = _e374.z;
    let _e381 = origin_1;
    (*rayOrigin_4) = _e381.xyz;
    let _e383 = direction_1;
    (*rayDirection_2) = _e383.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_19: f32;

    let _e327 = (*xi_1);
    if (_e327 < 0.5f) {
        let _e329 = (*xi_1);
        local_19 = (sqrt((2f * _e329)) - 1f);
    } else {
        let _e333 = (*xi_1);
        local_19 = (1f - sqrt((2f - (2f * _e333))));
    }
    let _e338 = local_19;
    return _e338;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e326 = (*seed_1);
    let _e329 = (*seed_1);
    (*seed_1) = (_e329 ^ (_e326 << bitcast<u32>(13u)));
    let _e331 = (*seed_1);
    let _e334 = (*seed_1);
    (*seed_1) = (_e334 ^ (_e331 >> bitcast<u32>(17u)));
    let _e336 = (*seed_1);
    let _e339 = (*seed_1);
    (*seed_1) = (_e339 ^ (_e336 << bitcast<u32>(5u)));
    return;
}

fn main_1() {
    var frag: vec2<f32>;
    var rndSeed_11: u32;
    var param_775: u32;
    var jx: f32;
    var param_776: u32;
    var param_777: f32;
    var jy: f32;
    var param_778: u32;
    var param_779: f32;
    var pixel: vec2<f32>;
    var ndc: vec2<f32>;
    var pW_15: vec3<f32>;
    var dW: vec3<f32>;
    var param_780: vec2<f32>;
    var param_781: mat4x4<f32>;
    var param_782: mat4x4<f32>;
    var param_783: vec3<f32>;
    var param_784: vec3<f32>;
    var param_785: vec3<f32>;
    var L_8: vec3<f32>;
    var throughput: vec3<f32>;
    var bsdfPdf_continuation: f32;
    var in_dielectric: bool;
    var vertex: i32;
    var inside_volume: bool;
    var inside_scattering_volume: bool;
    var surface_hit: bool;
    var pW_next: vec3<f32>;
    var NsW_next: vec3<f32>;
    var NgW_next: vec3<f32>;
    var TsW_next: vec3<f32>;
    var baryCoord_next: vec3<f32>;
    var texCoord_next: vec2<f32>;
    var material_next: i32;
    var param_786: vec3<f32>;
    var param_787: vec3<f32>;
    var param_788: f32;
    var param_789: vec3<f32>;
    var param_790: vec3<f32>;
    var param_791: vec3<f32>;
    var param_792: vec3<f32>;
    var param_793: vec3<f32>;
    var param_794: vec2<f32>;
    var param_795: i32;
    var misWeightLight: f32;
    var lightPdf_2: f32;
    var basis_21: Basis;
    var param_796: vec3<f32>;
    var param_797: Basis;
    var Lenv: vec3<f32>;
    var param_798: vec3<f32>;
    var param_799: vec3<f32>;
    var maxLenv: f32;
    var param_800: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW_1: vec3<f32>;
    var baryCoord_3: vec3<f32>;
    var texCoord_3: vec2<f32>;
    var surfaceshader_5: i32;
    var param_801: vec3<f32>;
    var param_802: vec3<f32>;
    var param_803: vec3<f32>;
    var param_804: vec2<f32>;
    var param_805: vec3<f32>;
    var param_806: vec3<f32>;
    var param_807: vec3<f32>;
    var param_808: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_11: vec3<f32>;
    var param_809: vec3<f32>;
    var param_810: Basis;
    var thin_walled: bool;
    var param_811: vec3<f32>;
    var param_812: Basis;
    var param_813: vec3<f32>;
    var param_814: u32;
    var Ltf: vec3<f32>;
    var param_815: Basis;
    var param_816: vec3<f32>;
    var maxLtf: f32;
    var param_817: vec3<f32>;
    var f_1: vec3<f32>;
    var woutputL_13: vec3<f32>;
    var internal_medium_2: Volume;
    var param_818: vec3<f32>;
    var param_819: Basis;
    var param_820: vec3<f32>;
    var param_821: u32;
    var param_822: i32;
    var param_823: vec3<f32>;
    var param_824: f32;
    var param_825: Volume;
    var woutputW_7: vec3<f32>;
    var param_826: vec3<f32>;
    var param_827: Basis;
    var transmitted_sample: bool;
    var cos_out: f32;
    var local_20: f32;
    var surface_throughput: vec3<f32>;
    var maxComp: f32;
    var param_828: vec3<f32>;
    var Le: vec3<f32>;
    var param_829: vec3<f32>;
    var param_830: Basis;
    var param_831: vec3<f32>;
    var maxLe: f32;
    var param_832: vec3<f32>;
    var transmitted: bool;
    var Li_6: vec3<f32>;
    var shadowL_2: vec3<f32>;
    var shadowW_2: vec3<f32>;
    var lightPdf_3: f32;
    var param_833: vec3<f32>;
    var param_834: Basis;
    var param_835: vec3<f32>;
    var param_836: vec3<f32>;
    var param_837: f32;
    var param_838: u32;
    var param_839: vec3<f32>;
    var bsdfPdf_shadow: f32;
    var fshadow: vec3<f32>;
    var param_840: vec3<f32>;
    var param_841: Basis;
    var param_842: vec3<f32>;
    var param_843: vec3<f32>;
    var param_844: i32;
    var param_845: f32;
    var misWeightLight_1: f32;
    var cos_shadow: f32;
    var local_21: f32;
    var Ld: vec3<f32>;
    var Lcontrib: vec3<f32>;
    var maxLcontrib: f32;
    var param_846: vec3<f32>;
    var maxTP: f32;
    var param_847: vec3<f32>;
    var param_848: vec3<f32>;
    var q: f32;
    var param_849: vec3<f32>;
    var param_850: u32;
    var phi_8732_: bool;
    var phi_8744_: bool;
    var phi_8745_: bool;
    var phi_8778_: bool;
    var phi_8785_: bool;
    var phi_8916_: bool;
    var phi_9007_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_color_1 = vec3<f32>(0.104704f, 0.241883f, 0.818f);
    metallic_1 = 0f;
    roughness_18 = 0.324675f;
    occlusion_3 = 1f;
    transmission_1 = 0f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    ior_7 = 1.5f;
    alpha_15 = 1f;
    alpha_mode_1 = 0i;
    alpha_cutoff_1 = 0.5f;
    iridescence_1 = 0f;
    iridescence_ior_1 = 1.3f;
    iridescence_thickness_1 = 100f;
    sheen_color_1 = vec3<f32>(0f, 0f, 0f);
    sheen_roughness_1 = 0f;
    clearcoat_1 = 0f;
    clearcoat_roughness_1 = 0f;
    emissive_1 = vec3<f32>(0f, 0f, 0f);
    emissive_strength_1 = 1f;
    thickness_1 = 0f;
    attenuation_distance_1 = 0f;
    attenuation_color_1 = vec3<f32>(1f, 1f, 1f);
    anisotropy_strength_1 = 0f;
    anisotropy_rotation_1 = 0f;
    dispersion_1 = 0f;
    let _e466 = gl_FragCoord_1;
    frag = _e466.xy;
    let _e469 = frag[0u];
    let _e471 = frag[1u];
    let _e474 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e469 + (_e471 * _e474)));
    let _e478 = rndSeed_11;
    param_775 = _e478;
    xorshift_u0028_u1_u003b((&param_775));
    let _e479 = param_775;
    rndSeed_11 = _e479;
    let _e481 = unnamed.samples;
    let _e483 = rndSeed_11;
    rndSeed_11 = (_e483 ^ u32(_e481));
    let _e485 = rndSeed_11;
    param_776 = _e485;
    let _e486 = rand_u0028_u1_u003b((&param_776));
    let _e487 = param_776;
    rndSeed_11 = _e487;
    param_777 = _e486;
    let _e488 = sample_triangle_filter_u0028_f1_u003b((&param_777));
    jx = (0.5f * _e488);
    let _e490 = rndSeed_11;
    param_778 = _e490;
    let _e491 = rand_u0028_u1_u003b((&param_778));
    let _e492 = param_778;
    rndSeed_11 = _e492;
    param_779 = _e491;
    let _e493 = sample_triangle_filter_u0028_f1_u003b((&param_779));
    jy = (0.5f * _e493);
    let _e495 = frag;
    let _e496 = jx;
    let _e497 = jy;
    pixel = (_e495 + vec2<f32>(_e496, _e497));
    let _e500 = pixel;
    let _e502 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e500 / _e502) * 2f));
    let _e508 = unnamed.invModelMatrix;
    let _e510 = unnamed.cameraWorldMatrix;
    let _e512 = ndc;
    param_780 = _e512;
    param_781 = (_e508 * _e510);
    let _e514 = unnamed.invProjectionMatrix;
    param_782 = _e514;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_780), (&param_781), (&param_782), (&param_783), (&param_784));
    let _e515 = param_783;
    pW_15 = _e515;
    let _e516 = param_784;
    dW = _e516;
    let _e517 = dW;
    dW = normalize(_e517);
    let _e520 = unnamed.sunDir;
    param_785 = _e520;
    let _e521 = makeBasis_u0028_vf3_u003b((&param_785));
    sunBasis = _e521;
    L_8 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e522 = vertex;
        let _e524 = unnamed.bounces;
        if (_e522 <= _e524) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e526 = inside_scattering_volume;
            if !(_e526) {
                let _e528 = pW_15;
                param_786 = _e528;
                let _e529 = dW;
                param_787 = _e529;
                param_788 = 100000000000000000000f;
                let _e530 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_786), (&param_787), (&param_788), (&param_789), (&param_790), (&param_791), (&param_792), (&param_793), (&param_794), (&param_795));
                let _e531 = param_789;
                pW_next = _e531;
                let _e532 = param_790;
                NsW_next = _e532;
                let _e533 = param_791;
                NgW_next = _e533;
                let _e534 = param_792;
                TsW_next = _e534;
                let _e535 = param_793;
                baryCoord_next = _e535;
                let _e536 = param_794;
                texCoord_next = _e536;
                let _e537 = param_795;
                material_next = _e537;
                surface_hit = _e530;
            }
            let _e538 = surface_hit;
            if !(_e538) {
                misWeightLight = 1f;
                let _e540 = vertex;
                let _e542 = inside_scattering_volume;
                if ((_e540 > 0i) && !(_e542)) {
                    let _e545 = dW;
                    param_796 = _e545;
                    let _e546 = basis_21;
                    param_797 = _e546;
                    let _e547 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_796), (&param_797));
                    lightPdf_2 = _e547;
                    let _e548 = bsdfPdf_continuation;
                    let _e549 = lightPdf_2;
                    let _e550 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e548, _e549);
                    misWeightLight = _e550;
                }
                let _e551 = throughput;
                let _e552 = misWeightLight;
                let _e554 = dW;
                param_798 = _e554;
                let _e555 = sunRadiance_u0028_vf3_u003b((&param_798));
                let _e556 = dW;
                param_799 = _e556;
                let _e557 = skyRadiance_u0028_vf3_u003b((&param_799));
                Lenv = ((_e551 * _e552) * (_e555 + _e557));
                let _e560 = Lenv;
                param_800 = _e560;
                let _e561 = maxComponent_u0028_vf3_u003b((&param_800));
                maxLenv = _e561;
                let _e562 = maxLenv;
                let _e564 = unnamed.firefly_clamp;
                if (_e562 > _e564) {
                    let _e567 = unnamed.firefly_clamp;
                    let _e568 = maxLenv;
                    let _e570 = Lenv;
                    Lenv = (_e570 * (_e567 / _e568));
                }
                let _e572 = Lenv;
                let _e573 = L_8;
                L_8 = (_e573 + _e572);
                break;
            }
            let _e575 = vertex;
            let _e577 = unnamed.bounces;
            if (_e575 == _e577) {
                break;
            }
            let _e579 = pW_next;
            pW_15 = _e579;
            let _e580 = NsW_next;
            NsW = _e580;
            let _e581 = NgW_next;
            NgW = _e581;
            let _e582 = TsW_next;
            TsW_1 = _e582;
            let _e583 = baryCoord_next;
            baryCoord_3 = _e583;
            let _e584 = texCoord_next;
            texCoord_3 = _e584;
            let _e585 = material_next;
            surfaceshader_5 = _e585;
            let _e586 = surfaceshader_5;
            if (_e586 == 1i) {
                let _e588 = in_dielectric;
                phi_8732_ = _e588;
                if _e588 {
                    let _e589 = NsW;
                    let _e590 = dW;
                    phi_8732_ = (dot(_e589, _e590) < 0f);
                }
                let _e594 = phi_8732_;
                phi_8745_ = _e594;
                if !(_e594) {
                    let _e596 = in_dielectric;
                    let _e597 = !(_e596);
                    phi_8744_ = _e597;
                    if _e597 {
                        let _e598 = NsW;
                        let _e599 = dW;
                        phi_8744_ = (dot(_e598, _e599) > 0f);
                    }
                    let _e603 = phi_8744_;
                    phi_8745_ = _e603;
                }
                let _e605 = phi_8745_;
                if _e605 {
                    let _e606 = NsW;
                    NsW = (_e606 * -1f);
                }
            } else {
                let _e608 = NsW;
                let _e609 = dW;
                if (dot(_e608, _e609) > 0f) {
                    let _e612 = NsW;
                    NsW = (_e612 * -1f);
                }
            }
            let _e614 = NgW;
            let _e615 = NsW;
            if (dot(_e614, _e615) < 0f) {
                let _e618 = NgW;
                NgW = (_e618 * -1f);
            }
            let _e621 = unnamed.smooth_normals;
            if (_e621 != 0u) {
                let _e623 = surfaceshader_5;
                let _e624 = (_e623 == 1i);
                phi_8778_ = _e624;
                if _e624 {
                    let _e625 = mtlx_openpbr_is_opaque_u0028_();
                    phi_8778_ = _e625;
                }
                let _e627 = phi_8778_;
                phi_8785_ = _e627;
                if _e627 {
                    let _e628 = NsW;
                    let _e629 = dW;
                    phi_8785_ = (dot(_e628, _e629) > 0f);
                }
                let _e633 = phi_8785_;
                if _e633 {
                    let _e634 = NgW;
                    let _e636 = NgW;
                    let _e637 = NsW;
                    let _e640 = NsW;
                    NsW = (((_e634 * 2f) * dot(_e636, _e637)) - _e640);
                }
                let _e642 = NsW;
                param_801 = _e642;
                let _e643 = TsW_next;
                param_802 = _e643;
                let _e644 = baryCoord_3;
                param_803 = _e644;
                let _e645 = texCoord_3;
                param_804 = _e645;
                let _e646 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_801), (&param_802), (&param_803), (&param_804));
                basis_21 = _e646;
            } else {
                let _e647 = NgW;
                param_805 = _e647;
                let _e648 = TsW_next;
                param_806 = _e648;
                let _e649 = baryCoord_3;
                param_807 = _e649;
                let _e650 = texCoord_3;
                param_808 = _e650;
                let _e651 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_805), (&param_806), (&param_807), (&param_808));
                basis_21 = _e651;
            }
            let _e652 = dW;
            winputW = -(_e652);
            let _e654 = winputW;
            param_809 = _e654;
            let _e655 = basis_21;
            param_810 = _e655;
            let _e656 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_809), (&param_810));
            winputL_11 = _e656;
            let _e658 = winputL_11[2u];
            if (abs(_e658) < 0.001f) {
                break;
            }
            thin_walled = false;
            let _e661 = surfaceshader_5;
            if (_e661 == 1i) {
                let _e663 = pW_15;
                param_811 = _e663;
                let _e664 = basis_21;
                param_812 = _e664;
                let _e665 = winputL_11;
                param_813 = _e665;
                let _e666 = rndSeed_11;
                param_814 = _e666;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_811), (&param_812), (&param_813), (&param_814));
                let _e667 = param_814;
                rndSeed_11 = _e667;
                let _e668 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled = _e668;
            }
            let _e669 = surfaceshader_5;
            if (_e669 == 1i) {
                let _e671 = throughput;
                let _e672 = basis_21;
                param_815 = _e672;
                let _e673 = winputL_11;
                param_816 = _e673;
                let _e674 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_815), (&param_816));
                Ltf = (_e671 * _e674);
                let _e676 = Ltf;
                param_817 = _e676;
                let _e677 = maxComponent_u0028_vf3_u003b((&param_817));
                maxLtf = _e677;
                let _e678 = maxLtf;
                let _e680 = unnamed.firefly_clamp;
                if (_e678 > _e680) {
                    let _e683 = unnamed.firefly_clamp;
                    let _e684 = maxLtf;
                    let _e686 = Ltf;
                    Ltf = (_e686 * (_e683 / _e684));
                }
                let _e688 = Ltf;
                let _e689 = L_8;
                L_8 = (_e689 + _e688);
            }
            let _e691 = pW_15;
            param_818 = _e691;
            let _e692 = basis_21;
            param_819 = _e692;
            let _e693 = winputL_11;
            param_820 = _e693;
            let _e694 = rndSeed_11;
            param_821 = _e694;
            let _e695 = surfaceshader_5;
            param_822 = _e695;
            let _e696 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_818), (&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825));
            let _e697 = param_821;
            rndSeed_11 = _e697;
            let _e698 = param_823;
            woutputL_13 = _e698;
            let _e699 = param_824;
            bsdfPdf_continuation = _e699;
            let _e700 = param_825;
            internal_medium_2 = _e700;
            f_1 = _e696;
            let _e701 = woutputL_13;
            param_826 = _e701;
            let _e702 = basis_21;
            param_827 = _e702;
            let _e703 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_826), (&param_827));
            woutputW_7 = _e703;
            let _e704 = surfaceshader_5;
            let _e705 = (_e704 == 1i);
            phi_8916_ = _e705;
            if _e705 {
                let _e707 = winputL_11[2u];
                let _e709 = woutputL_13[2u];
                phi_8916_ = ((_e707 * _e709) < 0f);
            }
            let _e713 = phi_8916_;
            transmitted_sample = _e713;
            let _e714 = surfaceshader_5;
            let _e716 = transmitted_sample;
            if ((_e714 == 1i) && !(_e716)) {
                local_20 = 1f;
            } else {
                let _e719 = woutputW_7;
                let _e721 = basis_21.nW;
                local_20 = abs(dot(_e719, _e721));
            }
            let _e724 = local_20;
            cos_out = _e724;
            let _e725 = f_1;
            let _e726 = bsdfPdf_continuation;
            let _e730 = cos_out;
            surface_throughput = ((_e725 / vec3(max(0.000001f, _e726))) * _e730);
            let _e732 = surface_throughput;
            param_828 = _e732;
            let _e733 = maxComponent_u0028_vf3_u003b((&param_828));
            maxComp = _e733;
            let _e734 = maxComp;
            let _e736 = unnamed.firefly_clamp;
            if (_e734 > _e736) {
                let _e739 = unnamed.firefly_clamp;
                let _e740 = maxComp;
                let _e742 = surface_throughput;
                surface_throughput = (_e742 * (_e739 / _e740));
            }
            let _e744 = woutputW_7;
            dW = _e744;
            let _e745 = surfaceshader_5;
            if (_e745 == 1i) {
                let _e747 = throughput;
                let _e748 = pW_15;
                param_829 = _e748;
                let _e749 = basis_21;
                param_830 = _e749;
                let _e750 = winputL_11;
                param_831 = _e750;
                let _e751 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_829), (&param_830), (&param_831));
                Le = (_e747 * _e751);
                let _e753 = Le;
                param_832 = _e753;
                let _e754 = maxComponent_u0028_vf3_u003b((&param_832));
                maxLe = _e754;
                let _e755 = maxLe;
                let _e757 = unnamed.firefly_clamp;
                if (_e755 > _e757) {
                    let _e760 = unnamed.firefly_clamp;
                    let _e761 = maxLe;
                    let _e763 = Le;
                    Le = (_e763 * (_e760 / _e761));
                }
                let _e765 = Le;
                let _e766 = L_8;
                L_8 = (_e766 + _e765);
            }
            let _e768 = thin_walled;
            let _e770 = surfaceshader_5;
            let _e772 = (!(_e768) && (_e770 == 1i));
            phi_9007_ = _e772;
            if _e772 {
                let _e773 = winputW;
                let _e774 = NgW;
                let _e776 = dW;
                let _e777 = NgW;
                phi_9007_ = ((dot(_e773, _e774) * dot(_e776, _e777)) < 0f);
            }
            let _e782 = phi_9007_;
            transmitted = _e782;
            let _e783 = transmitted;
            if _e783 {
                let _e784 = in_dielectric;
                in_dielectric = !(_e784);
            }
            let _e786 = in_dielectric;
            let _e788 = transmitted;
            if (!(_e786) && !(_e788)) {
                let _e791 = pW_15;
                param_833 = _e791;
                let _e792 = basis_21;
                param_834 = _e792;
                let _e793 = rndSeed_11;
                param_838 = _e793;
                let _e794 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_833), (&param_834), (&param_835), (&param_836), (&param_837), (&param_838));
                let _e795 = param_835;
                shadowL_2 = _e795;
                let _e796 = param_836;
                shadowW_2 = _e796;
                let _e797 = param_837;
                lightPdf_3 = _e797;
                let _e798 = param_838;
                rndSeed_11 = _e798;
                Li_6 = _e794;
                let _e799 = Li_6;
                param_839 = _e799;
                let _e800 = maxComponent_u0028_vf3_u003b((&param_839));
                if (_e800 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e802 = pW_15;
                    param_840 = _e802;
                    let _e803 = basis_21;
                    param_841 = _e803;
                    let _e804 = winputL_11;
                    param_842 = _e804;
                    let _e805 = shadowL_2;
                    param_843 = _e805;
                    let _e806 = surfaceshader_5;
                    param_844 = _e806;
                    let _e807 = bsdfPdf_shadow;
                    param_845 = _e807;
                    let _e808 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844), (&param_845));
                    let _e809 = param_845;
                    bsdfPdf_shadow = _e809;
                    fshadow = _e808;
                    let _e810 = lightPdf_3;
                    let _e811 = bsdfPdf_shadow;
                    let _e812 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e810, _e811);
                    misWeightLight_1 = _e812;
                    let _e813 = surfaceshader_5;
                    if (_e813 == 1i) {
                        local_21 = 1f;
                    } else {
                        let _e815 = shadowW_2;
                        let _e817 = basis_21.nW;
                        local_21 = abs(dot(_e815, _e817));
                    }
                    let _e820 = local_21;
                    cos_shadow = _e820;
                    let _e821 = misWeightLight_1;
                    let _e822 = fshadow;
                    let _e824 = cos_shadow;
                    let _e826 = Li_6;
                    let _e828 = lightPdf_3;
                    Ld = ((((_e822 * _e821) * _e824) * _e826) / vec3(max(0.000001f, _e828)));
                    let _e832 = throughput;
                    let _e833 = Ld;
                    Lcontrib = (_e832 * _e833);
                    let _e835 = Lcontrib;
                    param_846 = _e835;
                    let _e836 = maxComponent_u0028_vf3_u003b((&param_846));
                    maxLcontrib = _e836;
                    let _e837 = maxLcontrib;
                    let _e839 = unnamed.firefly_clamp;
                    if (_e837 > _e839) {
                        let _e842 = unnamed.firefly_clamp;
                        let _e843 = maxLcontrib;
                        let _e845 = Lcontrib;
                        Lcontrib = (_e845 * (_e842 / _e843));
                    }
                    let _e847 = Lcontrib;
                    let _e848 = L_8;
                    L_8 = (_e848 + _e847);
                }
            }
            let _e850 = NgW;
            let _e851 = dW;
            let _e852 = NgW;
            let _e857 = pW_15;
            pW_15 = (_e857 + ((_e850 * sign(dot(_e851, _e852))) * 0.0001f));
            let _e859 = surface_throughput;
            let _e860 = throughput;
            throughput = (_e860 * _e859);
            let _e862 = throughput;
            param_847 = _e862;
            let _e863 = maxComponent_u0028_vf3_u003b((&param_847));
            maxTP = _e863;
            let _e864 = maxTP;
            let _e866 = unnamed.firefly_clamp;
            if (_e864 > _e866) {
                let _e869 = unnamed.firefly_clamp;
                let _e870 = maxTP;
                let _e872 = throughput;
                throughput = (_e872 * (_e869 / _e870));
            }
            let _e874 = throughput;
            param_848 = _e874;
            let _e875 = maxComponent_u0028_vf3_u003b((&param_848));
            let _e877 = vertex;
            if ((_e875 < 1f) && (_e877 > 1i)) {
                let _e880 = throughput;
                param_849 = _e880;
                let _e881 = maxComponent_u0028_vf3_u003b((&param_849));
                q = max(0f, (1f - _e881));
                let _e884 = rndSeed_11;
                param_850 = _e884;
                let _e885 = rand_u0028_u1_u003b((&param_850));
                let _e886 = param_850;
                rndSeed_11 = _e886;
                let _e887 = q;
                if (_e885 < _e887) {
                    break;
                }
                let _e889 = q;
                let _e891 = throughput;
                throughput = (_e891 / vec3((1f - _e889)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e894 = vertex;
            vertex = (_e894 + 1i);
        }
    }
    let _e896 = L_8;
    mtlxFragmentColor[0u] = _e896.x;
    mtlxFragmentColor[1u] = _e896.y;
    mtlxFragmentColor[2u] = _e896.z;
    let _e904 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e904;
    return;
}

@fragment 
fn main(@builtin(position) gl_FragCoord: vec4<f32>, @location(149) vUv: vec2<f32>) -> @location(0) vec4<f32> {
    gl_FragCoord_1 = gl_FragCoord;
    vUv_1 = vUv;
    main_1();
    let _e5 = mtlxFragmentColor;
    return _e5;
}
