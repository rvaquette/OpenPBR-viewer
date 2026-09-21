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
    let _e323 = (*v)[0u];
    let _e325 = (*v)[1u];
    let _e327 = (*v)[2u];
    return min(_e323, min(_e325, _e327));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e323 = (*wiL)[2u];
    if (_e323 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e326 = (*wiL)[2u];
    return (_e326 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_7074_: bool;
    var phi_7092_: bool;

    let _e329 = (*winputL)[2u];
    let _e330 = (_e329 < 0.0000000001f);
    phi_7074_ = _e330;
    if !(_e330) {
        let _e333 = (*woutputL)[2u];
        phi_7074_ = (_e333 < 0.0000000001f);
    }
    let _e336 = phi_7074_;
    if _e336 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e337 = (*woutputL);
    param = _e337;
    let _e338 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e338;
    let _e340 = unnamed.wireframe;
    let _e341 = (_e340 != 0u);
    phi_7092_ = _e341;
    if _e341 {
        let _e343 = (*basis).baryCoord;
        param_1 = _e343;
        let _e344 = minComponent_u0028_vf3_u003b((&param_1));
        phi_7092_ = (_e344 < 0.003f);
    }
    let _e347 = phi_7092_;
    if _e347 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e349 = unnamed.neutral_color;
    return (_e349 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e324 = (*pW_1)[0u];
    let _e326 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e324, -(_e326)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e334 = uv;
    let _e335 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e334, 0.0);
    return _e335.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_7167_: bool;

    let _e329 = (*winputL_1)[2u];
    let _e330 = (_e329 < 0.0000000001f);
    phi_7167_ = _e330;
    if !(_e330) {
        let _e333 = (*woutputL_1)[2u];
        phi_7167_ = (_e333 < 0.0000000001f);
    }
    let _e336 = phi_7167_;
    if _e336 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e337 = (*woutputL_1);
    param_2 = _e337;
    let _e338 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e338;
    let _e339 = (*pW_2);
    param_3 = _e339;
    let _e340 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e340 / vec3(3.1415927f));
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result: ptr<function, vec3<f32>>) {
    let _e325 = (*closureData).closureType;
    if (_e325 == 4i) {
        let _e327 = (*color);
        (*result) = _e327;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_1: ptr<function, ClosureData>, top: ptr<function, BSDF>, base: ptr<function, BSDF>, result_1: ptr<function, BSDF>) {
    let _e326 = (*top).response;
    let _e328 = (*base).response;
    let _e330 = (*top).throughput;
    (*result_1).response = (_e326 + (_e328 * _e330));
    let _e335 = (*top).throughput;
    let _e337 = (*base).throughput;
    (*result_1).throughput = (_e335 * _e337);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e325 = (*dir)[1u];
    latitude = ((-(asin(_e325)) * 0.31830987f) + 0.5f);
    let _e331 = (*dir)[0u];
    let _e333 = (*dir)[2u];
    longitude = (((atan2(_e331, -(_e333)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e339 = longitude;
    let _e340 = latitude;
    return vec2<f32>(_e339, _e340);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e323 = (*m);
    let _e324 = (*v_1);
    return (_e323 * _e324);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_4: mat4x4<f32>;
    var param_5: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_6: vec3<f32>;

    let _e329 = (*dir_1);
    let _e334 = (*transform);
    param_4 = _e334;
    param_5 = vec4<f32>(_e329.x, _e329.y, _e329.z, 0f);
    let _e335 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_4), (&param_5));
    envDir = normalize(_e335.xyz);
    let _e338 = envDir;
    param_6 = _e338;
    let _e339 = mx_latlong_projection_u0028_vf3_u003b((&param_6));
    uv_1 = _e339;
    let _e340 = uv_1;
    let _e341 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e340, 0.0);
    return _e341.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e324 = a;
    c = cos(_e324);
    let _e326 = a;
    s = sin(_e326);
    let _e328 = c;
    let _e329 = s;
    let _e331 = s;
    let _e332 = c;
    return mat4x4<f32>(vec4<f32>(_e328, 0f, -(_e329), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e331, 0f, _e332, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_7: vec3<f32>;
    var param_8: mat4x4<f32>;
    var param_9: f32;

    let _e326 = mtlxEnvMatrix_u0028_();
    let _e327 = (*N);
    param_7 = _e327;
    param_8 = _e326;
    param_9 = 0f;
    let _e328 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_7), (&param_8), (&param_9));
    Li = _e328;
    let _e329 = Li;
    let _e331 = unnamed.skyPower;
    return (_e329 * _e331);
}

fn mx_square_u0028_f1_u003b(x: ptr<function, f32>) -> f32 {
    let _e322 = (*x);
    let _e323 = (*x);
    return (_e322 * _e323);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_10: f32;

    let _e325 = (*roughness);
    let _e328 = (*NdotV);
    let _e330 = (*roughness);
    let _e333 = (*roughness);
    param_10 = _e333;
    let _e334 = mx_square_u0028_f1_u003b((&param_10));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e325)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e328) * _e330)) + (vec2<f32>(1.4385f, 2.0315f) * _e334));
    let _e338 = r[0u];
    let _e340 = r[1u];
    return (_e338 / _e340);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_11: f32;
    var param_12: f32;

    let _e326 = (*NdotV_1);
    param_11 = _e326;
    let _e327 = (*roughness_1);
    param_12 = _e327;
    let _e328 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_11), (&param_12));
    dirAlbedo = _e328;
    let _e329 = dirAlbedo;
    return clamp(_e329, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e322 = (*x_1);
    let _e323 = (*x_1);
    return (_e322 * _e323);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e323 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e323)));
    let _e327 = A;
    let _e328 = (*roughness_2);
    return (_e327 * (1f + (0.07248821f * _e328)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_13: f32;
    var G: f32;

    let _e328 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e328)));
    let _e332 = (*roughness_3);
    let _e333 = A_1;
    B = (_e332 * _e333);
    let _e335 = (*cosTheta);
    param_13 = _e335;
    let _e336 = mx_square_u0028_f1_u003b((&param_13));
    Si = sqrt(max(0f, (1f - _e336)));
    let _e340 = Si;
    let _e341 = (*cosTheta);
    let _e344 = Si;
    let _e345 = (*cosTheta);
    let _e349 = Si;
    let _e350 = (*cosTheta);
    let _e352 = Si;
    let _e353 = Si;
    let _e355 = Si;
    let _e359 = Si;
    G = ((_e340 * (acos(clamp(_e341, -1f, 1f)) - (_e344 * _e345))) + ((2f * (((_e349 / _e350) * (1f - ((_e352 * _e353) * _e355))) - _e359)) / 3f));
    let _e364 = A_1;
    let _e365 = B;
    let _e366 = G;
    return (_e364 + ((_e365 * _e366) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_1: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_14: f32;
    var param_15: f32;
    var avgAlbedo: f32;
    var param_16: f32;
    var colorMultiScatter: vec3<f32>;
    var param_17: vec3<f32>;

    let _e331 = (*cosTheta_1);
    param_14 = _e331;
    let _e332 = (*roughness_4);
    param_15 = _e332;
    let _e333 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_14), (&param_15));
    dirAlbedo_1 = _e333;
    let _e334 = (*roughness_4);
    param_16 = _e334;
    let _e335 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_16));
    avgAlbedo = _e335;
    let _e336 = (*color_1);
    param_17 = _e336;
    let _e337 = mx_square_u0028_vf3_u003b((&param_17));
    let _e338 = avgAlbedo;
    let _e340 = (*color_1);
    let _e341 = avgAlbedo;
    colorMultiScatter = ((_e337 * _e338) / (vec3<f32>(1f, 1f, 1f) - (_e340 * max(0f, (1f - _e341)))));
    let _e347 = colorMultiScatter;
    let _e348 = (*color_1);
    let _e349 = dirAlbedo_1;
    return mix(_e347, _e348, vec3(_e349));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local: f32;
    var sigma2_: f32;
    var param_18: f32;
    var A_2: f32;
    var B_1: f32;

    let _e332 = (*LdotV);
    let _e333 = (*NdotL);
    let _e334 = (*NdotV_2);
    s_1 = (_e332 - (_e333 * _e334));
    let _e337 = s_1;
    if (_e337 > 0f) {
        let _e339 = s_1;
        let _e340 = (*NdotL);
        let _e341 = (*NdotV_2);
        local = (_e339 / max(_e340, _e341));
    } else {
        local = 0f;
    }
    let _e344 = local;
    stinv = _e344;
    let _e345 = (*roughness_5);
    param_18 = _e345;
    let _e346 = mx_square_u0028_f1_u003b((&param_18));
    sigma2_ = _e346;
    let _e347 = sigma2_;
    let _e348 = sigma2_;
    A_2 = (1f - (0.5f * (_e347 / (_e348 + 0.33f))));
    let _e353 = sigma2_;
    let _e355 = sigma2_;
    B_1 = ((0.45f * _e353) / (_e355 + 0.09f));
    let _e358 = A_2;
    let _e359 = B_1;
    let _e360 = stinv;
    return (_e358 + (_e359 * _e360));
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

    let _e342 = (*LdotV_1);
    let _e343 = (*NdotL_1);
    let _e344 = (*NdotV_3);
    s_2 = (_e342 - (_e343 * _e344));
    let _e347 = s_2;
    if (_e347 > 0f) {
        let _e349 = s_2;
        let _e350 = (*NdotL_1);
        let _e351 = (*NdotV_3);
        local_1 = (_e349 / max(_e350, _e351));
    } else {
        let _e354 = s_2;
        local_1 = _e354;
    }
    let _e355 = local_1;
    stinv_1 = _e355;
    let _e356 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e356)));
    let _e360 = (*color_2);
    let _e361 = A_3;
    let _e363 = (*roughness_6);
    let _e364 = stinv_1;
    lobeSingleScatter = ((_e360 * _e361) * (1f + (_e363 * _e364)));
    let _e368 = (*NdotV_3);
    param_19 = _e368;
    let _e369 = (*roughness_6);
    param_20 = _e369;
    let _e370 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_19), (&param_20));
    dirAlbedoV = _e370;
    let _e371 = (*NdotL_1);
    param_21 = _e371;
    let _e372 = (*roughness_6);
    param_22 = _e372;
    let _e373 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_21), (&param_22));
    dirAlbedoL = _e373;
    let _e374 = (*roughness_6);
    param_23 = _e374;
    let _e375 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_23));
    avgAlbedo_1 = _e375;
    let _e376 = (*color_2);
    param_24 = _e376;
    let _e377 = mx_square_u0028_vf3_u003b((&param_24));
    let _e378 = avgAlbedo_1;
    let _e380 = (*color_2);
    let _e381 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e377 * _e378) / (vec3<f32>(1f, 1f, 1f) - (_e380 * max(0f, (1f - _e381)))));
    let _e387 = colorMultiScatter_1;
    let _e388 = dirAlbedoV;
    let _e392 = dirAlbedoL;
    let _e396 = avgAlbedo_1;
    lobeMultiScatter = (((_e387 * max(0.00000001f, (1f - _e388))) * max(0.00000001f, (1f - _e392))) / vec3(max(0.00000001f, (1f - _e396))));
    let _e401 = lobeSingleScatter;
    let _e402 = lobeMultiScatter;
    return (_e401 + _e402);
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N_1: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local_2: vec3<f32>;

    let _e324 = (*N_1);
    let _e325 = (*V);
    if (dot(_e324, _e325) < 0f) {
        let _e328 = (*N_1);
        local_2 = -(_e328);
    } else {
        let _e330 = (*N_1);
        local_2 = _e330;
    }
    let _e331 = local_2;
    return _e331;
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
    let _e356 = (*weight);
    if (_e356 < 0.00000001f) {
        return;
    }
    let _e359 = (*closureData_2).V;
    V_1 = _e359;
    let _e361 = (*closureData_2).L;
    L = _e361;
    let _e362 = (*N_2);
    param_25 = _e362;
    let _e363 = V_1;
    param_26 = _e363;
    let _e364 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_25), (&param_26));
    (*N_2) = _e364;
    let _e365 = (*N_2);
    let _e366 = V_1;
    NdotV_4 = clamp(dot(_e365, _e366), 0.00000001f, 1f);
    let _e370 = (*closureData_2).closureType;
    if (_e370 == 1i) {
        let _e372 = (*N_2);
        let _e373 = L;
        NdotL_2 = clamp(dot(_e372, _e373), 0.00000001f, 1f);
        let _e376 = L;
        let _e377 = V_1;
        LdotV_2 = clamp(dot(_e376, _e377), 0.00000001f, 1f);
        let _e380 = (*energy_compensation);
        if _e380 {
            let _e381 = NdotV_4;
            param_27 = _e381;
            let _e382 = NdotL_2;
            param_28 = _e382;
            let _e383 = LdotV_2;
            param_29 = _e383;
            let _e384 = (*roughness_7);
            param_30 = _e384;
            let _e385 = (*color_3);
            param_31 = _e385;
            let _e386 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_27), (&param_28), (&param_29), (&param_30), (&param_31));
            local_3 = _e386;
        } else {
            let _e387 = NdotV_4;
            param_32 = _e387;
            let _e388 = NdotL_2;
            param_33 = _e388;
            let _e389 = LdotV_2;
            param_34 = _e389;
            let _e390 = (*roughness_7);
            param_35 = _e390;
            let _e391 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_32), (&param_33), (&param_34), (&param_35));
            let _e392 = (*color_3);
            local_3 = (_e392 * _e391);
        }
        let _e394 = local_3;
        diffuse = _e394;
        let _e395 = diffuse;
        let _e397 = (*closureData_2).occlusion;
        let _e399 = (*weight);
        let _e401 = NdotL_2;
        (*bsdf).response = ((((_e395 * _e397) * _e399) * _e401) * 0.31830987f);
    } else {
        let _e406 = (*closureData_2).closureType;
        if (_e406 == 3i) {
            let _e408 = (*energy_compensation);
            if _e408 {
                let _e409 = NdotV_4;
                param_36 = _e409;
                let _e410 = (*roughness_7);
                param_37 = _e410;
                let _e411 = (*color_3);
                param_38 = _e411;
                let _e412 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_36), (&param_37), (&param_38));
                local_4 = _e412;
            } else {
                let _e413 = NdotV_4;
                param_39 = _e413;
                let _e414 = (*roughness_7);
                param_40 = _e414;
                let _e415 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_39), (&param_40));
                let _e416 = (*color_3);
                local_4 = (_e416 * _e415);
            }
            let _e418 = local_4;
            diffuse_1 = _e418;
            let _e419 = (*N_2);
            param_41 = _e419;
            let _e420 = mx_environment_irradiance_u0028_vf3_u003b((&param_41));
            Li_1 = _e420;
            let _e421 = Li_1;
            let _e422 = diffuse_1;
            let _e424 = (*weight);
            (*bsdf).response = ((_e421 * _e422) * _e424);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_3: ptr<function, ClosureData>, in1_: ptr<function, BSDF>, in2_: ptr<function, f32>, result_2: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e326 = (*in2_);
    weight_1 = clamp(_e326, 0f, 1f);
    let _e329 = (*in1_).response;
    let _e330 = weight_1;
    (*result_2).response = (_e329 * _e330);
    let _e334 = (*in1_).throughput;
    (*result_2).throughput = _e334;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, BSDF>, result_3: ptr<function, BSDF>) {
    let _e326 = (*in1_1).response;
    let _e328 = (*in2_1).response;
    (*result_3).response = (_e326 + _e328);
    let _e332 = (*in1_1).throughput;
    let _e334 = (*in2_1).throughput;
    (*result_3).throughput = max(((_e332 + _e334) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_3: ptr<function, f32>, NdotV_5: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_42: f32;
    var lambdaL: f32;
    var param_43: f32;
    var lambdaV: f32;
    var param_44: f32;

    let _e330 = (*alpha);
    param_42 = _e330;
    let _e331 = mx_square_u0028_f1_u003b((&param_42));
    alpha2_ = _e331;
    let _e332 = alpha2_;
    let _e333 = alpha2_;
    let _e335 = (*NdotL_3);
    param_43 = _e335;
    let _e336 = mx_square_u0028_f1_u003b((&param_43));
    lambdaL = sqrt((_e332 + ((1f - _e333) * _e336)));
    let _e340 = alpha2_;
    let _e341 = alpha2_;
    let _e343 = (*NdotV_5);
    param_44 = _e343;
    let _e344 = mx_square_u0028_f1_u003b((&param_44));
    lambdaV = sqrt((_e340 + ((1f - _e341) * _e344)));
    let _e348 = (*NdotL_3);
    let _e350 = (*NdotV_5);
    let _e352 = lambdaL;
    let _e353 = (*NdotV_5);
    let _e355 = lambdaV;
    let _e356 = (*NdotL_3);
    return (((2f * _e348) * _e350) / ((_e352 * _e353) + (_e355 * _e356)));
}

fn mx_pow6_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_45: f32;
    var param_46: f32;

    let _e325 = (*x_2);
    param_45 = _e325;
    let _e326 = mx_square_u0028_f1_u003b((&param_45));
    x2_ = _e326;
    let _e327 = x2_;
    param_46 = _e327;
    let _e328 = mx_square_u0028_f1_u003b((&param_46));
    let _e329 = x2_;
    return (_e328 * _e329);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_2: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_3: f32;
    var a_1: vec3<f32>;
    var param_47: f32;

    let _e326 = (*cosTheta_2);
    x_3 = clamp(_e326, 0f, 1f);
    let _e329 = (*fd).F0_;
    let _e331 = (*fd).F90_;
    let _e333 = (*fd).exponent;
    let _e338 = (*fd).F82_;
    a_1 = ((mix(_e329, _e331, vec3(pow(0.85714287f, _e333))) * (vec3<f32>(1f, 1f, 1f) - _e338)) * 17.651384f);
    let _e343 = (*fd).F0_;
    let _e345 = (*fd).F90_;
    let _e346 = x_3;
    let _e349 = (*fd).exponent;
    let _e353 = a_1;
    let _e354 = x_3;
    let _e356 = x_3;
    param_47 = (1f - _e356);
    let _e358 = mx_pow6_u0028_f1_u003b((&param_47));
    return (mix(_e343, _e345, vec3(pow((1f - _e346), _e349))) - ((_e353 * _e354) * _e358));
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

    let _e338 = (*cosTheta_3);
    param_48 = clamp(_e338, 0f, 1f);
    let _e340 = mx_square_u0028_f1_u003b((&param_48));
    cosTheta2_ = _e340;
    let _e341 = cosTheta2_;
    sinTheta2_ = (1f - _e341);
    let _e343 = (*n);
    let _e344 = (*n);
    n2_ = (_e343 * _e344);
    let _e346 = (*k);
    let _e347 = (*k);
    k2_ = (_e346 * _e347);
    let _e349 = n2_;
    let _e350 = k2_;
    let _e352 = sinTheta2_;
    t0_ = ((_e349 - _e350) - vec3(_e352));
    let _e355 = t0_;
    let _e356 = t0_;
    let _e358 = n2_;
    let _e360 = k2_;
    a2plusb2_ = sqrt(((_e355 * _e356) + ((_e358 * 4f) * _e360)));
    let _e364 = a2plusb2_;
    let _e365 = cosTheta2_;
    t1_ = (_e364 + vec3(_e365));
    let _e368 = a2plusb2_;
    let _e369 = t0_;
    a_2 = sqrt(max(((_e368 + _e369) * 0.5f), vec3(0f)));
    let _e375 = a_2;
    let _e377 = (*cosTheta_3);
    t2_ = ((_e375 * 2f) * _e377);
    let _e379 = t1_;
    let _e380 = t2_;
    let _e382 = t1_;
    let _e383 = t2_;
    (*Rs) = ((_e379 - _e380) / (_e382 + _e383));
    let _e386 = cosTheta2_;
    let _e387 = a2plusb2_;
    let _e389 = sinTheta2_;
    let _e390 = sinTheta2_;
    t3_ = ((_e387 * _e386) + vec3((_e389 * _e390)));
    let _e394 = t2_;
    let _e395 = sinTheta2_;
    t4_ = (_e394 * _e395);
    let _e397 = (*Rs);
    let _e398 = t3_;
    let _e399 = t4_;
    let _e402 = t3_;
    let _e403 = t4_;
    (*Rp) = ((_e397 * (_e398 - _e399)) / (_e402 + _e403));
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

    let _e331 = (*cosTheta_4);
    param_49 = _e331;
    let _e332 = (*n_1);
    param_50 = _e332;
    let _e333 = (*k_1);
    param_51 = _e333;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_49), (&param_50), (&param_51), (&param_52), (&param_53));
    let _e334 = param_52;
    Rp_1 = _e334;
    let _e335 = param_53;
    Rs_1 = _e335;
    let _e336 = Rp_1;
    let _e337 = Rs_1;
    return ((_e336 + _e337) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_5: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_54: f32;
    var param_55: f32;

    let _e328 = (*cosTheta_5);
    c_1 = _e328;
    let _e329 = (*ior);
    let _e330 = (*ior);
    let _e332 = c_1;
    let _e333 = c_1;
    g2_ = (((_e329 * _e330) + (_e332 * _e333)) - 1f);
    let _e337 = g2_;
    if (_e337 < 0f) {
        return 1f;
    }
    let _e339 = g2_;
    g = sqrt(_e339);
    let _e341 = g;
    let _e342 = c_1;
    let _e344 = g;
    let _e345 = c_1;
    param_54 = ((_e341 - _e342) / (_e344 + _e345));
    let _e348 = mx_square_u0028_f1_u003b((&param_54));
    let _e350 = g;
    let _e351 = c_1;
    let _e353 = c_1;
    let _e356 = g;
    let _e357 = c_1;
    let _e359 = c_1;
    param_55 = ((((_e350 + _e351) * _e353) - 1f) / (((_e356 - _e357) * _e359) + 1f));
    let _e363 = mx_square_u0028_f1_u003b((&param_55));
    return ((0.5f * _e348) * (1f + _e363));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e323 = (*m_1);
    let _e324 = (*v_2);
    return (_e323 * _e324);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e328 = (*opd);
    phase = (6.2831855f * _e328);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e330 = val;
    let _e331 = var_;
    let _e335 = pos;
    let _e336 = phase;
    let _e338 = (*shift);
    let _e342 = var_;
    let _e344 = phase;
    let _e346 = phase;
    xyz = (((_e330 * sqrt((_e331 * 6.2831855f))) * cos(((_e335 * _e336) + _e338))) * exp(((-(_e342) * _e344) * _e346)));
    let _e350 = phase;
    let _e353 = (*shift)[0u];
    let _e357 = phase;
    let _e359 = phase;
    let _e364 = xyz[0u];
    xyz[0u] = (_e364 + ((0.00000001644083f * cos(((2239900f * _e350) + _e353))) * exp(((-4528200000f * _e357) * _e359))));
    let _e367 = xyz;
    return (_e367 / vec3(0.00000010685f));
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

    let _e336 = (*kappa2_);
    let _e337 = (*eta2_);
    k2_1 = (_e336 / _e337);
    let _e339 = (*cosTheta_6);
    let _e340 = (*cosTheta_6);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e339 * _e340)));
    let _e344 = (*eta2_);
    let _e345 = (*eta2_);
    let _e347 = k2_1;
    let _e348 = k2_1;
    let _e352 = (*eta1_);
    let _e353 = (*eta1_);
    let _e355 = sinThetaSqr;
    A_4 = (((_e344 * _e345) * (vec3<f32>(1f, 1f, 1f) - (_e347 * _e348))) - (_e355 * (_e352 * _e353)));
    let _e358 = A_4;
    let _e359 = A_4;
    let _e361 = (*eta2_);
    let _e363 = (*eta2_);
    let _e365 = k2_1;
    param_56 = (((_e361 * 2f) * _e363) * _e365);
    let _e367 = mx_square_u0028_vf3_u003b((&param_56));
    B_2 = sqrt(((_e358 * _e359) + _e367));
    let _e370 = A_4;
    let _e371 = B_2;
    U = sqrt(((_e370 + _e371) / vec3(2f)));
    let _e376 = B_2;
    let _e377 = A_4;
    V_2 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e376 - _e377) / vec3(2f))));
    let _e383 = (*eta1_);
    let _e385 = V_2;
    let _e387 = (*cosTheta_6);
    let _e389 = U;
    let _e390 = U;
    let _e392 = V_2;
    let _e393 = V_2;
    let _e396 = (*eta1_);
    let _e397 = (*cosTheta_6);
    param_57 = (_e396 * _e397);
    let _e399 = mx_square_u0028_f1_u003b((&param_57));
    (*phiS) = atan2(((_e385 * (2f * _e383)) * _e387), (((_e389 * _e390) + (_e392 * _e393)) - vec3(_e399)));
    let _e403 = (*eta1_);
    let _e405 = (*eta2_);
    let _e407 = (*eta2_);
    let _e409 = (*cosTheta_6);
    let _e411 = k2_1;
    let _e413 = U;
    let _e415 = k2_1;
    let _e416 = k2_1;
    let _e419 = V_2;
    let _e423 = (*eta2_);
    let _e424 = (*eta2_);
    let _e426 = k2_1;
    let _e427 = k2_1;
    let _e431 = (*cosTheta_6);
    param_58 = (((_e423 * _e424) * (vec3<f32>(1f, 1f, 1f) + (_e426 * _e427))) * _e431);
    let _e433 = mx_square_u0028_vf3_u003b((&param_58));
    let _e434 = (*eta1_);
    let _e435 = (*eta1_);
    let _e437 = U;
    let _e438 = U;
    let _e440 = V_2;
    let _e441 = V_2;
    (*phiP) = atan2(((((_e405 * (2f * _e403)) * _e407) * _e409) * (((_e411 * 2f) * _e413) - ((vec3<f32>(1f, 1f, 1f) - (_e415 * _e416)) * _e419))), (_e433 - (((_e437 * _e438) + (_e440 * _e441)) * (_e434 * _e435))));
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

    let _e333 = (*cosTheta_7);
    param_59 = clamp(_e333, 0f, 1f);
    let _e335 = mx_square_u0028_f1_u003b((&param_59));
    cosTheta2_1 = _e335;
    let _e336 = cosTheta2_1;
    sinTheta2_1 = (1f - _e336);
    let _e338 = (*ior_1);
    let _e339 = (*ior_1);
    let _e341 = sinTheta2_1;
    t0_1 = max(((_e338 * _e339) - _e341), 0f);
    let _e344 = t0_1;
    let _e345 = cosTheta2_1;
    t1_1 = (_e344 + _e345);
    let _e347 = t0_1;
    let _e350 = (*cosTheta_7);
    t2_1 = ((2f * sqrt(_e347)) * _e350);
    let _e352 = t1_1;
    let _e353 = t2_1;
    let _e355 = t1_1;
    let _e356 = t2_1;
    Rs_2 = ((_e352 - _e353) / (_e355 + _e356));
    let _e359 = cosTheta2_1;
    let _e360 = t0_1;
    let _e362 = sinTheta2_1;
    let _e363 = sinTheta2_1;
    t3_1 = ((_e359 * _e360) + (_e362 * _e363));
    let _e366 = t2_1;
    let _e367 = sinTheta2_1;
    t4_1 = (_e366 * _e367);
    let _e369 = Rs_2;
    let _e370 = t3_1;
    let _e371 = t4_1;
    let _e374 = t3_1;
    let _e375 = t4_1;
    Rp_2 = ((_e369 * (_e370 - _e371)) / (_e374 + _e375));
    let _e378 = Rp_2;
    let _e379 = Rs_2;
    return vec2<f32>(_e378, _e379);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e323 = (*F0_);
    sqrtF0_ = sqrt(clamp(_e323, vec3(0.01f), vec3(0.99f)));
    let _e328 = sqrtF0_;
    let _e330 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e328) / (vec3<f32>(1f, 1f, 1f) - _e330));
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
    let _e377 = (*fd_1).tf_ior;
    let _e378 = eta1_1;
    eta2_1 = max(_e377, _e378);
    let _e381 = (*fd_1).model;
    if (_e381 == 2i) {
        let _e384 = (*fd_1).F0_;
        param_60 = _e384;
        let _e385 = mx_f0_to_ior_u0028_vf3_u003b((&param_60));
        local_5 = _e385;
    } else {
        let _e387 = (*fd_1).ior;
        local_5 = _e387;
    }
    let _e388 = local_5;
    eta3_ = _e388;
    let _e390 = (*fd_1).model;
    if (_e390 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e393 = (*fd_1).extinction;
        local_6 = _e393;
    }
    let _e394 = local_6;
    kappa3_ = _e394;
    let _e395 = (*cosTheta_8);
    param_61 = _e395;
    let _e396 = mx_square_u0028_f1_u003b((&param_61));
    let _e398 = eta1_1;
    let _e399 = eta2_1;
    param_62 = (_e398 / _e399);
    let _e401 = mx_square_u0028_f1_u003b((&param_62));
    cosThetaT = sqrt((1f - ((1f - _e396) * _e401)));
    let _e405 = eta2_1;
    let _e406 = eta1_1;
    let _e408 = (*cosTheta_8);
    param_63 = _e408;
    param_64 = (_e405 / _e406);
    let _e409 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_63), (&param_64));
    R12_ = _e409;
    let _e410 = cosThetaT;
    if (_e410 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e412 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e412);
    let _e415 = (*fd_1).model;
    if (_e415 == 2i) {
        let _e417 = cosThetaT;
        param_65 = _e417;
        let _e418 = (*fd_1);
        param_66 = _e418;
        let _e419 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_65), (&param_66));
        f = _e419;
        let _e420 = f;
        R23p = (_e420 * 0.5f);
        let _e422 = f;
        R23s = (_e422 * 0.5f);
    } else {
        let _e424 = eta3_;
        let _e425 = eta2_1;
        let _e428 = kappa3_;
        let _e429 = eta2_1;
        let _e432 = cosThetaT;
        param_67 = _e432;
        param_68 = (_e424 / vec3(_e425));
        param_69 = (_e428 / vec3(_e429));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_67), (&param_68), (&param_69), (&param_70), (&param_71));
        let _e433 = param_70;
        R23p = _e433;
        let _e434 = param_71;
        R23s = _e434;
    }
    let _e435 = eta2_1;
    let _e436 = eta1_1;
    cosB = cos(atan((_e435 / _e436)));
    let _e440 = (*cosTheta_8);
    let _e441 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e440 < _e441)), 3.1415927f);
    let _e446 = (*fd_1).model;
    if (_e446 == 2i) {
        let _e449 = eta3_[0u];
        let _e450 = eta2_1;
        let _e454 = eta3_[1u];
        let _e455 = eta2_1;
        let _e459 = eta3_[2u];
        let _e460 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e449 < _e450)), select(0f, 3.1415927f, (_e454 < _e455)), select(0f, 3.1415927f, (_e459 < _e460)));
        let _e464 = phi23p;
        phi23s = _e464;
    } else {
        let _e465 = cosThetaT;
        param_72 = _e465;
        let _e466 = eta2_1;
        param_73 = _e466;
        let _e467 = eta3_;
        param_74 = _e467;
        let _e468 = kappa3_;
        param_75 = _e468;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_72), (&param_73), (&param_74), (&param_75), (&param_76), (&param_77));
        let _e469 = param_76;
        phi23p = _e469;
        let _e470 = param_77;
        phi23s = _e470;
    }
    let _e472 = R12_[0u];
    let _e473 = R23p;
    r123p = max(sqrt((_e473 * _e472)), vec3(0f));
    let _e479 = R12_[1u];
    let _e480 = R23s;
    r123s = max(sqrt((_e480 * _e479)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e486 = (*fd_1).tf_thickness;
    distMeters = (_e486 * 0.000000001f);
    let _e488 = eta2_1;
    let _e490 = cosThetaT;
    let _e492 = distMeters;
    opd_1 = (((2f * _e488) * _e490) * _e492);
    let _e495 = T121_[0u];
    param_78 = _e495;
    let _e496 = mx_square_u0028_f1_u003b((&param_78));
    let _e497 = R23p;
    let _e500 = R12_[0u];
    let _e501 = R23p;
    Rs_3 = ((_e497 * _e496) / (vec3<f32>(1f, 1f, 1f) - (_e501 * _e500)));
    let _e506 = R12_[0u];
    let _e507 = Rs_3;
    let _e510 = I;
    I = (_e510 + (vec3(_e506) + _e507));
    let _e512 = Rs_3;
    let _e514 = T121_[0u];
    Cm = (_e512 - vec3(_e514));
    m_2 = 1i;
    loop {
        let _e517 = m_2;
        if (_e517 <= 2i) {
            let _e519 = r123p;
            let _e520 = Cm;
            Cm = (_e520 * _e519);
            let _e522 = m_2;
            let _e524 = opd_1;
            let _e526 = m_2;
            let _e528 = phi23p;
            let _e530 = phi21_[0u];
            param_79 = (f32(_e522) * _e524);
            param_80 = ((_e528 + vec3(_e530)) * f32(_e526));
            let _e534 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_79), (&param_80));
            Sm = (_e534 * 2f);
            let _e536 = Cm;
            let _e537 = Sm;
            let _e539 = I;
            I = (_e539 + (_e536 * _e537));
            continue;
        } else {
            break;
        }
        continuing {
            let _e541 = m_2;
            m_2 = (_e541 + 1i);
        }
    }
    let _e544 = T121_[1u];
    param_81 = _e544;
    let _e545 = mx_square_u0028_f1_u003b((&param_81));
    let _e546 = R23s;
    let _e549 = R12_[1u];
    let _e550 = R23s;
    Rp_3 = ((_e546 * _e545) / (vec3<f32>(1f, 1f, 1f) - (_e550 * _e549)));
    let _e555 = R12_[1u];
    let _e556 = Rp_3;
    let _e559 = I;
    I = (_e559 + (vec3(_e555) + _e556));
    let _e561 = Rp_3;
    let _e563 = T121_[1u];
    Cm = (_e561 - vec3(_e563));
    m_3 = 1i;
    loop {
        let _e566 = m_3;
        if (_e566 <= 2i) {
            let _e568 = r123s;
            let _e569 = Cm;
            Cm = (_e569 * _e568);
            let _e571 = m_3;
            let _e573 = opd_1;
            let _e575 = m_3;
            let _e577 = phi23s;
            let _e579 = phi21_[1u];
            param_82 = (f32(_e571) * _e573);
            param_83 = ((_e577 + vec3(_e579)) * f32(_e575));
            let _e583 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_82), (&param_83));
            Sm = (_e583 * 2f);
            let _e585 = Cm;
            let _e586 = Sm;
            let _e588 = I;
            I = (_e588 + (_e585 * _e586));
            continue;
        } else {
            break;
        }
        continuing {
            let _e590 = m_3;
            m_3 = (_e590 + 1i);
        }
    }
    let _e592 = I;
    I = (_e592 * 0.5f);
    param_84 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e594 = I;
    param_85 = _e594;
    let _e595 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_84), (&param_85));
    I = clamp(_e595, vec3(0f), vec3(1f));
    let _e599 = I;
    return _e599;
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

    let _e333 = (*fd_2).airy;
    if _e333 {
        let _e334 = (*cosTheta_9);
        param_86 = _e334;
        let _e335 = (*fd_2);
        param_87 = _e335;
        let _e336 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_86), (&param_87));
        return _e336;
    } else {
        let _e338 = (*fd_2).model;
        if (_e338 == 0i) {
            let _e340 = (*cosTheta_9);
            param_88 = _e340;
            let _e343 = (*fd_2).ior[0u];
            param_89 = _e343;
            let _e344 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_88), (&param_89));
            return vec3(_e344);
        } else {
            let _e347 = (*fd_2).model;
            if (_e347 == 1i) {
                let _e349 = (*cosTheta_9);
                param_90 = _e349;
                let _e351 = (*fd_2).ior;
                param_91 = _e351;
                let _e353 = (*fd_2).extinction;
                param_92 = _e353;
                let _e354 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_90), (&param_91), (&param_92));
                return _e354;
            } else {
                let _e355 = (*cosTheta_9);
                param_93 = _e355;
                let _e356 = (*fd_2);
                param_94 = _e356;
                let _e357 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_93), (&param_94));
                return _e357;
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

    let _e329 = (*dir_2);
    let _e334 = (*transform_1);
    param_95 = _e334;
    param_96 = vec4<f32>(_e329.x, _e329.y, _e329.z, 0f);
    let _e335 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_95), (&param_96));
    envDir_1 = normalize(_e335.xyz);
    let _e338 = envDir_1;
    param_97 = _e338;
    let _e339 = mx_latlong_projection_u0028_vf3_u003b((&param_97));
    uv_2 = _e339;
    let _e340 = uv_2;
    let _e341 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e340, 0.0);
    return _e341.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_98: f32;

    let _e328 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e328 - 1.5f);
    let _e331 = (*dir_3)[1u];
    param_98 = _e331;
    let _e332 = mx_square_u0028_f1_u003b((&param_98));
    distortion = sqrt((1f - _e332));
    let _e335 = effectiveMaxMipLevel;
    let _e336 = (*envSamples);
    let _e338 = (*pdf);
    let _e340 = distortion;
    return max((_e335 - (0.5f * log2(((f32(_e336) * _e338) * _e340)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom: f32;
    var param_99: f32;
    var param_100: f32;

    let _e327 = (*H);
    let _e329 = (*alpha_1);
    He = (_e327.xy / _e329);
    let _e331 = He;
    let _e332 = He;
    let _e335 = (*H)[2u];
    param_99 = _e335;
    let _e336 = mx_square_u0028_f1_u003b((&param_99));
    denom = (dot(_e331, _e332) + _e336);
    let _e339 = (*alpha_1)[0u];
    let _e342 = (*alpha_1)[1u];
    let _e344 = denom;
    param_100 = _e344;
    let _e345 = mx_square_u0028_f1_u003b((&param_100));
    return (1f / (((3.1415927f * _e339) * _e342) * _e345));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_6: ptr<function, f32>) -> f32 {
    var param_101: vec3<f32>;
    var param_102: vec2<f32>;

    let _e327 = (*H_1);
    param_101 = _e327;
    let _e328 = (*alpha_2);
    param_102 = _e328;
    let _e329 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_101), (&param_102));
    let _e330 = (*G1V);
    let _e332 = (*NdotV_6);
    return ((_e329 * _e330) / (4f * _e332));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R: ptr<function, vec3<f32>>, N_3: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e325 = (*R);
    let _e326 = (*N_3);
    let _e327 = (*ior_2);
    (*R) = refract(_e325, _e326, (1f / _e327));
    let _e330 = (*R);
    let _e331 = (*R);
    let _e332 = (*N_3);
    let _e335 = (*N_3);
    N1_ = normalize(((_e330 * dot(_e331, _e332)) - (_e335 * 0.5f)));
    let _e339 = (*R);
    let _e340 = N1_;
    let _e341 = (*ior_2);
    return refract(_e339, _e340, _e341);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_3: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_4: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e331 = (*V_3);
    let _e333 = (*alpha_3);
    let _e334 = (_e331.xy * _e333);
    let _e336 = (*V_3)[2u];
    (*V_3) = normalize(vec3<f32>(_e334.x, _e334.y, _e336));
    let _e342 = (*Xi)[0u];
    phi = (6.2831855f * _e342);
    let _e345 = (*Xi)[1u];
    let _e348 = (*V_3)[2u];
    let _e352 = (*V_3)[2u];
    z = (((1f - _e345) * (1f + _e348)) - _e352);
    let _e354 = z;
    let _e355 = z;
    sinTheta = sqrt(clamp((1f - (_e354 * _e355)), 0f, 1f));
    let _e360 = sinTheta;
    let _e361 = phi;
    x_4 = (_e360 * cos(_e361));
    let _e364 = sinTheta;
    let _e365 = phi;
    y = (_e364 * sin(_e365));
    let _e368 = x_4;
    let _e369 = y;
    let _e370 = z;
    c_2 = vec3<f32>(_e368, _e369, _e370);
    let _e372 = c_2;
    let _e373 = (*V_3);
    H_2 = (_e372 + _e373);
    let _e375 = H_2;
    let _e377 = (*alpha_3);
    let _e378 = (_e375.xy * _e377);
    let _e380 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e378.x, _e378.y, max(_e380, 0f)));
    let _e386 = H_2;
    return _e386;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i: ptr<function, i32>) -> f32 {
    let _e322 = (*i);
    return fract(((f32(_e322) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_1: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_103: i32;

    let _e324 = (*i_1);
    let _e327 = (*numSamples);
    let _e330 = (*i_1);
    param_103 = _e330;
    let _e331 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_103));
    return vec2<f32>(((f32(_e324) + 0.5f) / f32(_e327)), _e331);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_10: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_104: f32;
    var tanTheta2_: f32;
    var param_105: f32;

    let _e327 = (*cosTheta_10);
    param_104 = _e327;
    let _e328 = mx_square_u0028_f1_u003b((&param_104));
    cosTheta2_2 = _e328;
    let _e329 = cosTheta2_2;
    let _e331 = cosTheta2_2;
    tanTheta2_ = ((1f - _e329) / _e331);
    let _e333 = (*alpha_4);
    param_105 = _e333;
    let _e334 = mx_square_u0028_f1_u003b((&param_105));
    let _e335 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e334 * _e335)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e323 = (*alpha_5)[0u];
    let _e325 = (*alpha_5)[1u];
    return sqrt((_e323 * _e325));
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

    let _e378 = (*X);
    let _e379 = (*X);
    let _e380 = (*N_4);
    let _e382 = (*N_4);
    (*X) = normalize((_e378 - (_e382 * dot(_e379, _e380))));
    let _e386 = (*N_4);
    let _e387 = (*X);
    Y = cross(_e386, _e387);
    let _e389 = (*X);
    let _e390 = Y;
    let _e391 = (*N_4);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e389.x, _e389.y, _e389.z), vec3<f32>(_e390.x, _e390.y, _e390.z), vec3<f32>(_e391.x, _e391.y, _e391.z));
    let _e405 = (*V_4);
    let _e406 = (*X);
    let _e408 = (*V_4);
    let _e409 = Y;
    let _e411 = (*V_4);
    let _e412 = (*N_4);
    (*V_4) = vec3<f32>(dot(_e405, _e406), dot(_e408, _e409), dot(_e411, _e412));
    let _e416 = (*V_4)[2u];
    NdotV_7 = clamp(_e416, 0.00000001f, 1f);
    let _e418 = (*alpha_6);
    param_106 = _e418;
    let _e419 = mx_average_alpha_u0028_vf2_u003b((&param_106));
    avgAlpha = _e419;
    let _e420 = NdotV_7;
    param_107 = _e420;
    let _e421 = avgAlpha;
    param_108 = _e421;
    let _e422 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_107), (&param_108));
    G1V_1 = _e422;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_2 = 0i;
    loop {
        let _e423 = i_2;
        let _e424 = envRadianceSamples;
        if (_e423 < _e424) {
            let _e426 = i_2;
            param_109 = _e426;
            let _e427 = envRadianceSamples;
            param_110 = _e427;
            let _e428 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_109), (&param_110));
            Xi_1 = _e428;
            let _e429 = Xi_1;
            param_111 = _e429;
            let _e430 = (*V_4);
            param_112 = _e430;
            let _e431 = (*alpha_6);
            param_113 = _e431;
            let _e432 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_111), (&param_112), (&param_113));
            H_3 = _e432;
            let _e434 = (*fd_3).refraction;
            if _e434 {
                let _e435 = (*V_4);
                param_114 = -(_e435);
                let _e437 = H_3;
                param_115 = _e437;
                let _e440 = (*fd_3).ior[0u];
                param_116 = _e440;
                let _e441 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_114), (&param_115), (&param_116));
                local_7 = _e441;
            } else {
                let _e442 = (*V_4);
                let _e443 = H_3;
                local_7 = -(reflect(_e442, _e443));
            }
            let _e446 = local_7;
            L_1 = _e446;
            let _e448 = L_1[2u];
            NdotL_4 = clamp(_e448, 0.00000001f, 1f);
            let _e450 = (*V_4);
            let _e451 = H_3;
            VdotH = clamp(dot(_e450, _e451), 0.00000001f, 1f);
            let _e454 = tangentToWorld;
            param_117 = _e454;
            let _e455 = L_1;
            param_118 = _e455;
            let _e456 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_117), (&param_118));
            Lw = _e456;
            let _e457 = H_3;
            param_119 = _e457;
            let _e458 = (*alpha_6);
            param_120 = _e458;
            let _e459 = G1V_1;
            param_121 = _e459;
            let _e460 = NdotV_7;
            param_122 = _e460;
            let _e461 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_119), (&param_120), (&param_121), (&param_122));
            pdf_1 = _e461;
            let _e462 = Lw;
            param_123 = _e462;
            let _e463 = pdf_1;
            param_124 = _e463;
            param_125 = 0f;
            let _e464 = envRadianceSamples;
            param_126 = _e464;
            let _e465 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_123), (&param_124), (&param_125), (&param_126));
            lod_2 = _e465;
            let _e466 = mtlxEnvMatrix_u0028_();
            let _e467 = Lw;
            param_127 = _e467;
            param_128 = _e466;
            let _e468 = lod_2;
            param_129 = _e468;
            let _e469 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_127), (&param_128), (&param_129));
            sampleColor = _e469;
            let _e470 = VdotH;
            param_130 = _e470;
            let _e471 = (*fd_3);
            param_131 = _e471;
            let _e472 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_130), (&param_131));
            F = _e472;
            let _e473 = NdotL_4;
            param_132 = _e473;
            let _e474 = NdotV_7;
            param_133 = _e474;
            let _e475 = avgAlpha;
            param_134 = _e475;
            let _e476 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_132), (&param_133), (&param_134));
            G_1 = _e476;
            let _e478 = (*fd_3).refraction;
            if _e478 {
                let _e479 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e479);
            } else {
                let _e481 = F;
                let _e482 = G_1;
                local_8 = (_e481 * _e482);
            }
            let _e484 = local_8;
            FG = _e484;
            let _e485 = sampleColor;
            let _e486 = FG;
            let _e488 = radiance;
            radiance = (_e488 + (_e485 * _e486));
            continue;
        } else {
            break;
        }
        continuing {
            let _e490 = i_2;
            i_2 = (_e490 + 1i);
        }
    }
    let _e492 = G1V_1;
    let _e493 = envRadianceSamples;
    let _e496 = radiance;
    radiance = (_e496 / vec3((_e492 * f32(_e493))));
    let _e499 = radiance;
    let _e502 = unnamed.skyPower;
    return (select(_e499, vec3<f32>(0f, 0f, 0f), false) * _e502);
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
        let _e336 = (*tint);
        param_135 = _e336;
        let _e337 = mx_square_u0028_vf3_u003b((&param_135));
        (*tint) = _e337;
    }
    let _e338 = (*N_5);
    param_136 = _e338;
    let _e339 = (*V_5);
    param_137 = _e339;
    let _e340 = (*X_1);
    param_138 = _e340;
    let _e341 = (*alpha_7);
    param_139 = _e341;
    let _e342 = (*distribution_1);
    param_140 = _e342;
    let _e343 = (*fd_4);
    param_141 = _e343;
    let _e344 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_136), (&param_137), (&param_138), (&param_139), (&param_140), (&param_141));
    let _e345 = (*tint);
    return (_e344 * _e345);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_1: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e323 = (*F0_1);
    sqrtF0_1 = sqrt(clamp(_e323, 0.01f, 0.99f));
    let _e326 = sqrtF0_1;
    let _e328 = sqrtF0_1;
    return ((1f + _e326) / (1f - _e328));
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

    let _e333 = (*NdotV_8);
    x_5 = _e333;
    let _e334 = (*alpha_8);
    y_1 = _e334;
    let _e335 = x_5;
    param_142 = _e335;
    let _e336 = mx_square_u0028_f1_u003b((&param_142));
    x2_1 = _e336;
    let _e337 = y_1;
    param_143 = _e337;
    let _e338 = mx_square_u0028_f1_u003b((&param_143));
    y2_ = _e338;
    let _e339 = x_5;
    let _e342 = y_1;
    let _e345 = x_5;
    let _e347 = y_1;
    let _e350 = x2_1;
    let _e353 = y2_;
    let _e356 = x2_1;
    let _e358 = y_1;
    let _e361 = x_5;
    let _e363 = y2_;
    let _e366 = x2_1;
    let _e368 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e339)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e342)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e345) * _e347)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e350)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e353)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e356) * _e358)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e361) * _e363)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e366) * _e368));
    let _e371 = r_1;
    let _e373 = r_1;
    AB = clamp((_e371.xy / _e373.zw), vec2(0f), vec2(1f));
    let _e379 = (*F0_2);
    let _e381 = AB[0u];
    let _e383 = (*F90_);
    let _e385 = AB[1u];
    return ((_e379 * _e381) + (_e383 * _e385));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_144: f32;
    var param_145: f32;
    var param_146: vec3<f32>;
    var param_147: vec3<f32>;

    let _e329 = (*NdotV_9);
    param_144 = _e329;
    let _e330 = (*alpha_9);
    param_145 = _e330;
    let _e331 = (*F0_3);
    param_146 = _e331;
    let _e332 = (*F90_1);
    param_147 = _e332;
    let _e333 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_144), (&param_145), (&param_146), (&param_147));
    return _e333;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_10: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_4: ptr<function, f32>, F90_2: ptr<function, f32>) -> f32 {
    var param_148: f32;
    var param_149: f32;
    var param_150: vec3<f32>;
    var param_151: vec3<f32>;

    let _e329 = (*F0_4);
    let _e331 = (*F90_2);
    let _e333 = (*NdotV_10);
    param_148 = _e333;
    let _e334 = (*alpha_10);
    param_149 = _e334;
    param_150 = vec3(_e329);
    param_151 = vec3(_e331);
    let _e335 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_148), (&param_149), (&param_150), (&param_151));
    return _e335.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_152: f32;
    var param_153: FresnelData;
    var F90_3: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3257_: bool;

    param_152 = 1f;
    let _e327 = (*fd_5);
    param_153 = _e327;
    let _e328 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_152), (&param_153));
    F0_5 = _e328;
    let _e330 = (*fd_5).model;
    let _e331 = (_e330 == 2i);
    phi_3257_ = _e331;
    if _e331 {
        let _e333 = (*fd_5).airy;
        phi_3257_ = !(_e333);
    }
    let _e336 = phi_3257_;
    if _e336 {
        let _e338 = (*fd_5).F90_;
        local_9 = _e338;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e339 = local_9;
    F90_3 = _e339;
    let _e340 = F0_5;
    let _e341 = F90_3;
    let _e342 = F0_5;
    return (_e340 + ((_e341 - _e342) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_11: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_154: FresnelData;
    var Ess: f32;
    var param_155: f32;
    var param_156: f32;
    var param_157: f32;
    var param_158: f32;

    let _e331 = (*fd_6);
    param_154 = _e331;
    let _e332 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_154));
    Fss = _e332;
    let _e333 = (*NdotV_11);
    param_155 = _e333;
    let _e334 = (*alpha_11);
    param_156 = _e334;
    param_157 = 1f;
    param_158 = 1f;
    let _e335 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_155), (&param_156), (&param_157), (&param_158));
    Ess = _e335;
    let _e336 = Fss;
    let _e337 = Ess;
    let _e340 = Ess;
    return (vec3(1f) + ((_e336 * (1f - _e337)) / vec3(_e340)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_6: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_4: ptr<function, vec3<f32>>, exponent: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e329 = (*tf_thickness);
    fd_7.airy = (_e329 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e334 = (*F0_6);
    fd_7.F0_ = _e334;
    let _e336 = (*F82_);
    fd_7.F82_ = _e336;
    let _e338 = (*F90_4);
    fd_7.F90_ = _e338;
    let _e340 = (*exponent);
    fd_7.exponent = _e340;
    let _e342 = (*tf_thickness);
    fd_7.tf_thickness = _e342;
    let _e344 = (*tf_ior);
    fd_7.tf_ior = _e344;
    fd_7.refraction = false;
    let _e347 = fd_7;
    return _e347;
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
    var phi_4926_: bool;

    let _e415 = (*weight_2);
    if (_e415 < 0.00000001f) {
        return;
    }
    let _e418 = (*closureData_5).closureType;
    let _e420 = (*scatter_mode);
    if ((_e418 != 2i) && (_e420 == 1i)) {
        return;
    }
    let _e424 = (*closureData_5).V;
    V_6 = _e424;
    let _e426 = (*closureData_5).L;
    L_2 = _e426;
    let _e427 = (*retroreflective);
    phi_4926_ = _e427;
    if _e427 {
        let _e429 = (*closureData_5).closureType;
        phi_4926_ = (_e429 != 2i);
    }
    let _e432 = phi_4926_;
    if _e432 {
        let _e433 = V_6;
        let _e435 = (*N_6);
        V_6 = reflect(-(_e433), _e435);
    }
    let _e437 = (*N_6);
    param_159 = _e437;
    let _e438 = V_6;
    param_160 = _e438;
    let _e439 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_159), (&param_160));
    (*N_6) = _e439;
    let _e440 = (*N_6);
    let _e441 = V_6;
    NdotV_12 = clamp(dot(_e440, _e441), 0.00000001f, 1f);
    let _e444 = (*color0_);
    safeColor0_ = max(_e444, vec3(0f));
    let _e447 = (*color82_);
    safeColor82_ = max(_e447, vec3(0f));
    let _e450 = (*color90_);
    safeColor90_ = max(_e450, vec3(0f));
    let _e453 = safeColor0_;
    param_161 = _e453;
    let _e454 = safeColor82_;
    param_162 = _e454;
    let _e455 = safeColor90_;
    param_163 = _e455;
    let _e456 = (*exponent_1);
    param_164 = _e456;
    let _e457 = (*thinfilm_thickness);
    param_165 = _e457;
    let _e458 = (*thinfilm_ior);
    param_166 = _e458;
    let _e459 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_161), (&param_162), (&param_163), (&param_164), (&param_165), (&param_166));
    fd_8 = _e459;
    let _e460 = (*roughness_8);
    safeAlpha = clamp(_e460, vec2(0.00000001f), vec2(1f));
    let _e464 = safeAlpha;
    param_167 = _e464;
    let _e465 = mx_average_alpha_u0028_vf2_u003b((&param_167));
    avgAlpha_1 = _e465;
    let _e467 = (*closureData_5).closureType;
    if (_e467 == 1i) {
        let _e469 = (*X_2);
        let _e470 = (*X_2);
        let _e471 = (*N_6);
        let _e473 = (*N_6);
        (*X_2) = normalize((_e469 - (_e473 * dot(_e470, _e471))));
        let _e477 = (*N_6);
        let _e478 = (*X_2);
        Y_1 = cross(_e477, _e478);
        let _e480 = L_2;
        let _e481 = V_6;
        H_4 = normalize((_e480 + _e481));
        let _e484 = (*N_6);
        let _e485 = L_2;
        NdotL_5 = clamp(dot(_e484, _e485), 0.00000001f, 1f);
        let _e488 = V_6;
        let _e489 = H_4;
        VdotH_1 = clamp(dot(_e488, _e489), 0.00000001f, 1f);
        let _e492 = H_4;
        let _e493 = (*X_2);
        let _e495 = H_4;
        let _e496 = Y_1;
        let _e498 = H_4;
        let _e499 = (*N_6);
        Ht = vec3<f32>(dot(_e492, _e493), dot(_e495, _e496), dot(_e498, _e499));
        let _e502 = VdotH_1;
        param_168 = _e502;
        let _e503 = fd_8;
        param_169 = _e503;
        let _e504 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_168), (&param_169));
        F_1 = _e504;
        let _e505 = Ht;
        param_170 = _e505;
        let _e506 = safeAlpha;
        param_171 = _e506;
        let _e507 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_170), (&param_171));
        D = _e507;
        let _e508 = NdotL_5;
        param_172 = _e508;
        let _e509 = NdotV_12;
        param_173 = _e509;
        let _e510 = avgAlpha_1;
        param_174 = _e510;
        let _e511 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_172), (&param_173), (&param_174));
        G_2 = _e511;
        let _e512 = NdotV_12;
        param_175 = _e512;
        let _e513 = avgAlpha_1;
        param_176 = _e513;
        let _e514 = fd_8;
        param_177 = _e514;
        let _e515 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_175), (&param_176), (&param_177));
        comp = _e515;
        let _e516 = NdotV_12;
        param_178 = _e516;
        let _e517 = avgAlpha_1;
        param_179 = _e517;
        let _e518 = safeColor0_;
        param_180 = _e518;
        let _e519 = safeColor90_;
        param_181 = _e519;
        let _e520 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_178), (&param_179), (&param_180), (&param_181));
        let _e521 = comp;
        dirAlbedo_2 = (_e520 * _e521);
        let _e523 = dirAlbedo_2;
        avgDirAlbedo = dot(_e523, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e525 = avgDirAlbedo;
        let _e526 = (*weight_2);
        (*bsdf_1).throughput = vec3((1f - (_e525 * _e526)));
        let _e531 = D;
        let _e532 = F_1;
        let _e534 = G_2;
        let _e536 = comp;
        let _e539 = (*closureData_5).occlusion;
        let _e541 = (*weight_2);
        let _e543 = NdotV_12;
        (*bsdf_1).response = ((((((_e532 * _e531) * _e534) * _e536) * _e539) * _e541) / vec3((4f * _e543)));
    } else {
        let _e549 = (*closureData_5).closureType;
        if (_e549 == 2i) {
            let _e551 = NdotV_12;
            param_182 = _e551;
            let _e552 = avgAlpha_1;
            param_183 = _e552;
            let _e553 = fd_8;
            param_184 = _e553;
            let _e554 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_182), (&param_183), (&param_184));
            comp_1 = _e554;
            let _e555 = NdotV_12;
            param_185 = _e555;
            let _e556 = avgAlpha_1;
            param_186 = _e556;
            let _e557 = safeColor0_;
            param_187 = _e557;
            let _e558 = safeColor90_;
            param_188 = _e558;
            let _e559 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_185), (&param_186), (&param_187), (&param_188));
            let _e560 = comp_1;
            dirAlbedo_3 = (_e559 * _e560);
            let _e562 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e562, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e564 = avgDirAlbedo_1;
            let _e565 = (*weight_2);
            (*bsdf_1).throughput = vec3((1f - (_e564 * _e565)));
            let _e570 = (*scatter_mode);
            if (_e570 != 0i) {
                let _e572 = safeColor0_;
                avgF0_ = dot(_e572, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e574 = avgF0_;
                param_189 = _e574;
                let _e575 = mx_f0_to_ior_u0028_f1_u003b((&param_189));
                fd_8.ior = vec3(_e575);
                let _e578 = (*N_6);
                param_190 = _e578;
                let _e579 = V_6;
                param_191 = _e579;
                let _e580 = (*X_2);
                param_192 = _e580;
                let _e581 = safeAlpha;
                param_193 = _e581;
                let _e582 = (*distribution_2);
                param_194 = _e582;
                let _e583 = fd_8;
                param_195 = _e583;
                param_196 = vec3<f32>(1f, 1f, 1f);
                let _e584 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_190), (&param_191), (&param_192), (&param_193), (&param_194), (&param_195), (&param_196));
                let _e585 = (*weight_2);
                (*bsdf_1).response = (_e584 * _e585);
            }
        } else {
            let _e589 = (*closureData_5).closureType;
            if (_e589 == 3i) {
                let _e591 = NdotV_12;
                param_197 = _e591;
                let _e592 = avgAlpha_1;
                param_198 = _e592;
                let _e593 = fd_8;
                param_199 = _e593;
                let _e594 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_197), (&param_198), (&param_199));
                comp_2 = _e594;
                let _e595 = NdotV_12;
                param_200 = _e595;
                let _e596 = avgAlpha_1;
                param_201 = _e596;
                let _e597 = safeColor0_;
                param_202 = _e597;
                let _e598 = safeColor90_;
                param_203 = _e598;
                let _e599 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_200), (&param_201), (&param_202), (&param_203));
                let _e600 = comp_2;
                dirAlbedo_4 = (_e599 * _e600);
                let _e602 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e602, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e604 = avgDirAlbedo_2;
                let _e605 = (*weight_2);
                (*bsdf_1).throughput = vec3((1f - (_e604 * _e605)));
                let _e610 = (*N_6);
                param_204 = _e610;
                let _e611 = V_6;
                param_205 = _e611;
                let _e612 = (*X_2);
                param_206 = _e612;
                let _e613 = safeAlpha;
                param_207 = _e613;
                let _e614 = (*distribution_2);
                param_208 = _e614;
                let _e615 = fd_8;
                param_209 = _e615;
                let _e616 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_204), (&param_205), (&param_206), (&param_207), (&param_208), (&param_209));
                Li_2 = _e616;
                let _e617 = Li_2;
                let _e618 = comp_2;
                let _e620 = (*weight_2);
                (*bsdf_1).response = ((_e617 * _e618) * _e620);
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

    let _e327 = (*y_2);
    let _e328 = (*y_2);
    let _e332 = (*y_2);
    let _e333 = (*y_2);
    s_3 = ((_e327 * (0.0206607f + (1.58491f * _e328))) / (0.0379424f + (_e332 * (1.32227f + _e333))));
    let _e338 = (*y_2);
    let _e339 = (*y_2);
    let _e340 = (*y_2);
    let _e341 = (*y_2);
    let _e343 = (*y_2);
    let _e351 = (*y_2);
    m_4 = ((_e338 * (-0.193854f + (_e339 * (-1.14885f + (_e340 * (1.7932f - ((0.95943f * _e341) * _e343))))))) / (0.046391f + _e351));
    let _e354 = (*y_2);
    let _e355 = (*y_2);
    let _e358 = (*y_2);
    let _e362 = (*y_2);
    let _e363 = (*y_2);
    o = ((_e354 * (0.000654023f + ((-0.0207818f + (0.119681f * _e355)) * _e358))) / (1.26264f + (_e362 * (-1.92021f + _e363))));
    let _e368 = (*x_6);
    let _e369 = m_4;
    let _e371 = s_3;
    param_210 = ((_e368 - _e369) / _e371);
    let _e373 = mx_square_u0028_f1_u003b((&param_210));
    let _e376 = s_3;
    let _e379 = o;
    return ((exp((-0.5f * _e373)) / (_e376 * 2.5066283f)) + _e379);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_11: ptr<function, f32>) -> f32 {
    let _e322 = (*cosTheta_11);
    return (max(_e322, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_7: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e323 = (*x_7);
    let _e326 = (*y_3);
    let _e329 = (*y_3);
    let _e331 = (*y_3);
    let _e333 = (*y_3);
    let _e335 = (*x_7);
    let _e338 = (*x_7);
    let _e340 = (*y_3);
    let _e343 = (*y_3);
    let _e345 = (*y_3);
    return (((((sqrt((1f - _e323)) * (_e326 - 1f)) * _e329) * _e331) * _e333) / (((0.0000254053f + (1.71228f * _e335)) - ((1.71506f * _e338) * _e340)) + ((1.34174f * _e343) * _e345)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e323 = (*x_8);
    let _e325 = (*y_4);
    let _e328 = (*y_4);
    let _e330 = (*x_8);
    let _e332 = (*x_8);
    let _e335 = (*x_8);
    let _e337 = (*y_4);
    return ((((2.58126f * _e323) + (0.813703f * _e325)) * _e328) / ((1f + ((0.310327f * _e330) * _e332)) + ((2.60994f * _e335) * _e337)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_7: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_3: vec3<f32>;
    var Y_2: vec3<f32>;

    let _e328 = (*N_7)[2u];
    sign_ = select(1f, -1f, (_e328 < 0f));
    let _e331 = sign_;
    let _e333 = (*N_7)[2u];
    a_3 = (-1f / (_e331 + _e333));
    let _e337 = (*N_7)[0u];
    let _e339 = (*N_7)[1u];
    let _e341 = a_3;
    b = ((_e337 * _e339) * _e341);
    let _e343 = sign_;
    let _e345 = (*N_7)[0u];
    let _e348 = (*N_7)[0u];
    let _e350 = a_3;
    let _e353 = sign_;
    let _e354 = b;
    let _e356 = sign_;
    let _e359 = (*N_7)[0u];
    X_3 = vec3<f32>((1f + (((_e343 * _e345) * _e348) * _e350)), (_e353 * _e354), (-(_e356) * _e359));
    let _e362 = b;
    let _e363 = sign_;
    let _e365 = (*N_7)[1u];
    let _e367 = (*N_7)[1u];
    let _e369 = a_3;
    let _e373 = (*N_7)[1u];
    Y_2 = vec3<f32>(_e362, (_e363 + ((_e365 * _e367) * _e369)), -(_e373));
    let _e376 = X_3;
    let _e377 = Y_2;
    let _e378 = (*N_7);
    return mat3x3<f32>(vec3<f32>(_e376.x, _e376.y, _e376.z), vec3<f32>(_e377.x, _e377.y, _e377.z), vec3<f32>(_e378.x, _e378.y, _e378.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_7: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, NdotV_13: ptr<function, f32>) -> mat3x3<f32> {
    var X_4: vec3<f32>;
    var lenSqr: f32;
    var Y_3: vec3<f32>;
    var param_211: vec3<f32>;

    let _e328 = (*V_7);
    let _e329 = (*N_8);
    let _e330 = (*NdotV_13);
    X_4 = (_e328 - (_e329 * _e330));
    let _e333 = X_4;
    let _e334 = X_4;
    lenSqr = dot(_e333, _e334);
    let _e336 = lenSqr;
    if (_e336 > 0f) {
        let _e338 = lenSqr;
        let _e340 = X_4;
        X_4 = (_e340 * inverseSqrt(_e338));
        let _e342 = (*N_8);
        let _e343 = X_4;
        Y_3 = cross(_e342, _e343);
        let _e345 = X_4;
        let _e346 = Y_3;
        let _e347 = (*N_8);
        return mat3x3<f32>(vec3<f32>(_e345.x, _e345.y, _e345.z), vec3<f32>(_e346.x, _e346.y, _e346.z), vec3<f32>(_e347.x, _e347.y, _e347.z));
    }
    let _e361 = (*N_8);
    param_211 = _e361;
    let _e362 = mx_orthonormal_basis_u0028_vf3_u003b((&param_211));
    return _e362;
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

    let _e343 = (*V_8);
    param_212 = _e343;
    let _e344 = (*N_9);
    param_213 = _e344;
    let _e345 = (*NdotV_14);
    param_214 = _e345;
    let _e346 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_212), (&param_213), (&param_214));
    toLTC = transpose(_e346);
    let _e348 = toLTC;
    param_215 = _e348;
    let _e349 = (*L_3);
    param_216 = _e349;
    let _e350 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_215), (&param_216));
    w = _e350;
    let _e351 = (*NdotV_14);
    param_217 = _e351;
    let _e352 = (*roughness_9);
    param_218 = _e352;
    let _e353 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_217), (&param_218));
    aInv = _e353;
    let _e354 = (*NdotV_14);
    param_219 = _e354;
    let _e355 = (*roughness_9);
    param_220 = _e355;
    let _e356 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_219), (&param_220));
    bInv = _e356;
    let _e357 = aInv;
    let _e359 = w[0u];
    let _e361 = bInv;
    let _e363 = w[2u];
    let _e366 = aInv;
    let _e368 = w[1u];
    let _e371 = w[2u];
    wo = vec3<f32>(((_e357 * _e359) + (_e361 * _e363)), (_e366 * _e368), _e371);
    let _e373 = wo;
    let _e374 = wo;
    lenSqr_1 = dot(_e373, _e374);
    let _e377 = wo[2u];
    param_221 = _e377;
    let _e378 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_221));
    let _e379 = aInv;
    let _e380 = lenSqr_1;
    param_222 = (_e379 / _e380);
    let _e382 = mx_square_u0028_f1_u003b((&param_222));
    return (_e378 * _e382);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_15: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_223: f32;
    var param_224: f32;

    let _e326 = (*NdotV_15);
    let _e329 = (*roughness_10);
    let _e332 = (*NdotV_15);
    let _e334 = (*roughness_10);
    let _e337 = (*NdotV_15);
    param_223 = _e337;
    let _e338 = mx_square_u0028_f1_u003b((&param_223));
    let _e341 = (*roughness_10);
    param_224 = _e341;
    let _e342 = mx_square_u0028_f1_u003b((&param_224));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e326)) + (vec2<f32>(799.08826f, 442.7821f) * _e329)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e332) * _e334)) + (vec2<f32>(60.28956f, 121.81241f) * _e338)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e342));
    let _e346 = r_2[0u];
    let _e348 = r_2[1u];
    return (_e346 / _e348);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_16: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var dirAlbedo_5: f32;
    var param_225: f32;
    var param_226: f32;

    let _e326 = (*NdotV_16);
    param_225 = _e326;
    let _e327 = (*roughness_11);
    param_226 = _e327;
    let _e328 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_225), (&param_226));
    dirAlbedo_5 = _e328;
    let _e329 = dirAlbedo_5;
    return clamp(_e329, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e326 = (*roughness_12);
    invRoughness = (1f / max(_e326, 0.005f));
    let _e329 = (*NdotH);
    let _e330 = (*NdotH);
    cos2_ = (_e329 * _e330);
    let _e332 = cos2_;
    sin2_ = (1f - _e332);
    let _e334 = invRoughness;
    let _e336 = sin2_;
    let _e337 = invRoughness;
    return (((2f + _e334) * pow(_e336, (_e337 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_6: ptr<function, f32>, NdotV_17: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var D_1: f32;
    var param_227: f32;
    var param_228: f32;
    var F_2: f32;
    var G_3: f32;

    let _e330 = (*NdotH_1);
    param_227 = _e330;
    let _e331 = (*roughness_13);
    param_228 = _e331;
    let _e332 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_227), (&param_228));
    D_1 = _e332;
    F_2 = 1f;
    G_3 = 1f;
    let _e333 = D_1;
    let _e334 = F_2;
    let _e336 = G_3;
    let _e338 = (*NdotL_6);
    let _e339 = (*NdotV_17);
    let _e341 = (*NdotL_6);
    let _e342 = (*NdotV_17);
    return (((_e333 * _e334) * _e336) / (4f * ((_e338 + _e339) - (_e341 * _e342))));
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

    let _e359 = (*weight_3);
    if (_e359 < 0.00000001f) {
        return;
    }
    let _e362 = (*closureData_6).V;
    V_9 = _e362;
    let _e364 = (*closureData_6).L;
    L_4 = _e364;
    let _e365 = (*N_10);
    param_229 = _e365;
    let _e366 = V_9;
    param_230 = _e366;
    let _e367 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_229), (&param_230));
    (*N_10) = _e367;
    let _e368 = (*N_10);
    let _e369 = V_9;
    NdotV_18 = clamp(dot(_e368, _e369), 0.00000001f, 1f);
    let _e373 = (*closureData_6).closureType;
    if (_e373 == 1i) {
        let _e375 = (*mode);
        if (_e375 == 0i) {
            let _e377 = L_4;
            let _e378 = V_9;
            H_5 = normalize((_e377 + _e378));
            let _e381 = (*N_10);
            let _e382 = L_4;
            NdotL_7 = clamp(dot(_e381, _e382), 0.00000001f, 1f);
            let _e385 = (*N_10);
            let _e386 = H_5;
            NdotH_2 = clamp(dot(_e385, _e386), 0.00000001f, 1f);
            let _e389 = (*color_4);
            let _e390 = NdotL_7;
            param_231 = _e390;
            let _e391 = NdotV_18;
            param_232 = _e391;
            let _e392 = NdotH_2;
            param_233 = _e392;
            let _e393 = (*roughness_14);
            param_234 = _e393;
            let _e394 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_231), (&param_232), (&param_233), (&param_234));
            fr = (_e389 * _e394);
            let _e396 = NdotV_18;
            param_235 = _e396;
            let _e397 = (*roughness_14);
            param_236 = _e397;
            let _e398 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_235), (&param_236));
            dirAlbedo_6 = _e398;
            let _e399 = fr;
            let _e400 = NdotL_7;
            let _e403 = (*closureData_6).occlusion;
            let _e405 = (*weight_3);
            (*bsdf_2).response = (((_e399 * _e400) * _e403) * _e405);
        } else {
            let _e408 = (*roughness_14);
            (*roughness_14) = clamp(_e408, 0.01f, 1f);
            let _e410 = (*color_4);
            let _e411 = L_4;
            param_237 = _e411;
            let _e412 = V_9;
            param_238 = _e412;
            let _e413 = (*N_10);
            param_239 = _e413;
            let _e414 = NdotV_18;
            param_240 = _e414;
            let _e415 = (*roughness_14);
            param_241 = _e415;
            let _e416 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_237), (&param_238), (&param_239), (&param_240), (&param_241));
            fr_1 = (_e410 * _e416);
            let _e418 = NdotV_18;
            param_242 = _e418;
            let _e419 = (*roughness_14);
            param_243 = _e419;
            let _e420 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_242), (&param_243));
            dirAlbedo_6 = _e420;
            let _e421 = dirAlbedo_6;
            let _e422 = fr_1;
            let _e425 = (*closureData_6).occlusion;
            let _e427 = (*weight_3);
            (*bsdf_2).response = (((_e422 * _e421) * _e425) * _e427);
        }
        let _e430 = dirAlbedo_6;
        let _e431 = (*weight_3);
        (*bsdf_2).throughput = vec3((1f - (_e430 * _e431)));
    } else {
        let _e437 = (*closureData_6).closureType;
        if (_e437 == 3i) {
            let _e439 = (*mode);
            if (_e439 == 0i) {
                let _e441 = NdotV_18;
                param_244 = _e441;
                let _e442 = (*roughness_14);
                param_245 = _e442;
                let _e443 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_244), (&param_245));
                dirAlbedo_7 = _e443;
            } else {
                let _e444 = (*roughness_14);
                (*roughness_14) = clamp(_e444, 0.01f, 1f);
                let _e446 = NdotV_18;
                param_246 = _e446;
                let _e447 = (*roughness_14);
                param_247 = _e447;
                let _e448 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_246), (&param_247));
                dirAlbedo_7 = _e448;
            }
            let _e449 = (*N_10);
            param_248 = _e449;
            let _e450 = mx_environment_irradiance_u0028_vf3_u003b((&param_248));
            Li_3 = _e450;
            let _e451 = Li_3;
            let _e452 = (*color_4);
            let _e454 = dirAlbedo_7;
            let _e456 = (*weight_3);
            (*bsdf_2).response = (((_e451 * _e452) * _e454) * _e456);
            let _e459 = dirAlbedo_7;
            let _e460 = (*weight_3);
            (*bsdf_2).throughput = vec3((1f - (_e459 * _e460)));
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_249: f32;

    let _e323 = (*ior_3);
    let _e325 = (*ior_3);
    param_249 = ((_e323 - 1f) / (_e325 + 1f));
    let _e328 = mx_square_u0028_f1_u003b((&param_249));
    return _e328;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e326 = (*tf_thickness_1);
    fd_9.airy = (_e326 > 0f);
    let _e329 = (*ior_4);
    fd_9.ior = vec3(_e329);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e337 = (*tf_thickness_1);
    fd_9.tf_thickness = _e337;
    let _e339 = (*tf_ior_1);
    fd_9.tf_ior = _e339;
    fd_9.refraction = false;
    let _e342 = fd_9;
    return _e342;
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
    var phi_3743_: bool;

    let _e405 = (*weight_4);
    if (_e405 < 0.00000001f) {
        return;
    }
    let _e408 = (*closureData_7).closureType;
    let _e410 = (*scatter_mode_1);
    if ((_e408 != 2i) && (_e410 == 1i)) {
        return;
    }
    let _e414 = (*closureData_7).V;
    V_10 = _e414;
    let _e416 = (*closureData_7).L;
    L_5 = _e416;
    let _e417 = (*retroreflective_1);
    phi_3743_ = _e417;
    if _e417 {
        let _e419 = (*closureData_7).closureType;
        phi_3743_ = (_e419 != 2i);
    }
    let _e422 = phi_3743_;
    if _e422 {
        let _e423 = V_10;
        let _e425 = (*N_11);
        V_10 = reflect(-(_e423), _e425);
    }
    let _e427 = (*N_11);
    param_250 = _e427;
    let _e428 = V_10;
    param_251 = _e428;
    let _e429 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_250), (&param_251));
    (*N_11) = _e429;
    let _e430 = (*N_11);
    let _e431 = V_10;
    NdotV_19 = clamp(dot(_e430, _e431), 0.00000001f, 1f);
    let _e434 = (*ior_5);
    param_252 = _e434;
    let _e435 = (*thinfilm_thickness_1);
    param_253 = _e435;
    let _e436 = (*thinfilm_ior_1);
    param_254 = _e436;
    let _e437 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_252), (&param_253), (&param_254));
    fd_10 = _e437;
    let _e438 = (*ior_5);
    param_255 = _e438;
    let _e439 = mx_ior_to_f0_u0028_f1_u003b((&param_255));
    F0_7 = _e439;
    let _e440 = (*roughness_15);
    safeAlpha_1 = clamp(_e440, vec2(0.00000001f), vec2(1f));
    let _e444 = safeAlpha_1;
    param_256 = _e444;
    let _e445 = mx_average_alpha_u0028_vf2_u003b((&param_256));
    avgAlpha_2 = _e445;
    let _e446 = (*tint_1);
    safeTint = max(_e446, vec3(0f));
    let _e450 = (*closureData_7).closureType;
    if (_e450 == 1i) {
        let _e452 = (*X_5);
        let _e453 = (*X_5);
        let _e454 = (*N_11);
        let _e456 = (*N_11);
        (*X_5) = normalize((_e452 - (_e456 * dot(_e453, _e454))));
        let _e460 = (*N_11);
        let _e461 = (*X_5);
        Y_4 = cross(_e460, _e461);
        let _e463 = L_5;
        let _e464 = V_10;
        H_6 = normalize((_e463 + _e464));
        let _e467 = (*N_11);
        let _e468 = L_5;
        NdotL_8 = clamp(dot(_e467, _e468), 0.00000001f, 1f);
        let _e471 = V_10;
        let _e472 = H_6;
        VdotH_2 = clamp(dot(_e471, _e472), 0.00000001f, 1f);
        let _e475 = H_6;
        let _e476 = (*X_5);
        let _e478 = H_6;
        let _e479 = Y_4;
        let _e481 = H_6;
        let _e482 = (*N_11);
        Ht_1 = vec3<f32>(dot(_e475, _e476), dot(_e478, _e479), dot(_e481, _e482));
        let _e485 = VdotH_2;
        param_257 = _e485;
        let _e486 = fd_10;
        param_258 = _e486;
        let _e487 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_257), (&param_258));
        F_3 = _e487;
        let _e488 = Ht_1;
        param_259 = _e488;
        let _e489 = safeAlpha_1;
        param_260 = _e489;
        let _e490 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_259), (&param_260));
        D_2 = _e490;
        let _e491 = NdotL_8;
        param_261 = _e491;
        let _e492 = NdotV_19;
        param_262 = _e492;
        let _e493 = avgAlpha_2;
        param_263 = _e493;
        let _e494 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_261), (&param_262), (&param_263));
        G_4 = _e494;
        let _e495 = NdotV_19;
        param_264 = _e495;
        let _e496 = avgAlpha_2;
        param_265 = _e496;
        let _e497 = fd_10;
        param_266 = _e497;
        let _e498 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_264), (&param_265), (&param_266));
        comp_3 = _e498;
        let _e499 = NdotV_19;
        param_267 = _e499;
        let _e500 = avgAlpha_2;
        param_268 = _e500;
        let _e501 = F0_7;
        param_269 = _e501;
        param_270 = 1f;
        let _e502 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_267), (&param_268), (&param_269), (&param_270));
        let _e503 = comp_3;
        dirAlbedo_8 = (_e503 * _e502);
        let _e505 = dirAlbedo_8;
        let _e506 = (*weight_4);
        (*bsdf_3).throughput = (vec3(1f) - (_e505 * _e506));
        let _e511 = D_2;
        let _e512 = F_3;
        let _e514 = G_4;
        let _e516 = comp_3;
        let _e518 = safeTint;
        let _e521 = (*closureData_7).occlusion;
        let _e523 = (*weight_4);
        let _e525 = NdotV_19;
        (*bsdf_3).response = (((((((_e512 * _e511) * _e514) * _e516) * _e518) * _e521) * _e523) / vec3((4f * _e525)));
    } else {
        let _e531 = (*closureData_7).closureType;
        if (_e531 == 2i) {
            let _e533 = NdotV_19;
            param_271 = _e533;
            let _e534 = avgAlpha_2;
            param_272 = _e534;
            let _e535 = fd_10;
            param_273 = _e535;
            let _e536 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_271), (&param_272), (&param_273));
            comp_4 = _e536;
            let _e537 = NdotV_19;
            param_274 = _e537;
            let _e538 = avgAlpha_2;
            param_275 = _e538;
            let _e539 = F0_7;
            param_276 = _e539;
            param_277 = 1f;
            let _e540 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_274), (&param_275), (&param_276), (&param_277));
            let _e541 = comp_4;
            dirAlbedo_9 = (_e541 * _e540);
            let _e543 = dirAlbedo_9;
            let _e544 = (*weight_4);
            (*bsdf_3).throughput = (vec3(1f) - (_e543 * _e544));
            let _e549 = (*scatter_mode_1);
            if (_e549 != 0i) {
                let _e551 = (*N_11);
                param_278 = _e551;
                let _e552 = V_10;
                param_279 = _e552;
                let _e553 = (*X_5);
                param_280 = _e553;
                let _e554 = safeAlpha_1;
                param_281 = _e554;
                let _e555 = (*distribution_3);
                param_282 = _e555;
                let _e556 = fd_10;
                param_283 = _e556;
                let _e557 = safeTint;
                param_284 = _e557;
                let _e558 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_278), (&param_279), (&param_280), (&param_281), (&param_282), (&param_283), (&param_284));
                let _e559 = (*weight_4);
                (*bsdf_3).response = (_e558 * _e559);
            }
        } else {
            let _e563 = (*closureData_7).closureType;
            if (_e563 == 3i) {
                let _e565 = NdotV_19;
                param_285 = _e565;
                let _e566 = avgAlpha_2;
                param_286 = _e566;
                let _e567 = fd_10;
                param_287 = _e567;
                let _e568 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_285), (&param_286), (&param_287));
                comp_5 = _e568;
                let _e569 = NdotV_19;
                param_288 = _e569;
                let _e570 = avgAlpha_2;
                param_289 = _e570;
                let _e571 = F0_7;
                param_290 = _e571;
                param_291 = 1f;
                let _e572 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_288), (&param_289), (&param_290), (&param_291));
                let _e573 = comp_5;
                dirAlbedo_10 = (_e573 * _e572);
                let _e575 = dirAlbedo_10;
                let _e576 = (*weight_4);
                (*bsdf_3).throughput = (vec3(1f) - (_e575 * _e576));
                let _e581 = (*N_11);
                param_292 = _e581;
                let _e582 = V_10;
                param_293 = _e582;
                let _e583 = (*X_5);
                param_294 = _e583;
                let _e584 = safeAlpha_1;
                param_295 = _e584;
                let _e585 = (*distribution_3);
                param_296 = _e585;
                let _e586 = fd_10;
                param_297 = _e586;
                let _e587 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_292), (&param_293), (&param_294), (&param_295), (&param_296), (&param_297));
                Li_4 = _e587;
                let _e588 = Li_4;
                let _e589 = safeTint;
                let _e591 = comp_5;
                let _e593 = (*weight_4);
                (*bsdf_3).response = (((_e588 * _e589) * _e591) * _e593);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_6: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, occlusion: ptr<function, f32>) -> ClosureData {
    let _e327 = (*closureType);
    let _e328 = (*L_6);
    let _e329 = (*V_11);
    let _e330 = (*N_12);
    let _e331 = (*P);
    let _e332 = (*occlusion);
    return ClosureData(_e327, _e328, _e329, _e330, _e331, _e332);
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_4: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e329 = (*axis);
    (*axis) = normalize(_e329);
    let _e331 = (*amount);
    rotationRadians = radians(_e331);
    let _e333 = rotationRadians;
    s_4 = sin(_e333);
    let _e335 = rotationRadians;
    c_3 = cos(_e335);
    let _e337 = c_3;
    oc = (1f - _e337);
    let _e339 = (*_in);
    let _e340 = c_3;
    let _e342 = (*_in);
    let _e343 = (*axis);
    let _e345 = s_4;
    let _e348 = (*axis);
    let _e349 = (*axis);
    let _e350 = (*_in);
    let _e353 = oc;
    (*result_4) = (((_e339 * _e340) + (cross(_e342, _e343) * _e345)) + ((_e348 * dot(_e349, _e350)) * _e353));
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_2: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e329 = (*in1_2)[0u];
    N_extract_0_out = _e329;
    let _e331 = (*in1_2)[1u];
    N_extract_1_out = _e331;
    let _e333 = (*in1_2)[2u];
    N_extract_2_out = _e333;
    let _e334 = N_extract_0_out;
    (*outr) = _e334;
    let _e335 = N_extract_1_out;
    (*outg) = _e335;
    let _e336 = N_extract_2_out;
    (*outb) = _e336;
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
    let _e332 = (*in1_3);
    param_298 = _e332;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_298), (&param_299), (&param_300), (&param_301));
    let _e333 = param_299;
    N_separate_outr = _e333;
    let _e334 = param_300;
    N_separate_outg = _e334;
    let _e335 = param_301;
    N_separate_outb = _e335;
    let _e336 = N_separate_outr;
    let _e337 = N_separate_outg;
    N_max_01_out = max(_e336, _e337);
    let _e339 = N_max_01_out;
    let _e340 = N_separate_outb;
    N_max_out = max(_e339, _e340);
    let _e342 = N_max_out;
    (*out1_) = _e342;
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy: ptr<function, f32>, result_5: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e326 = (*roughness_16);
    let _e327 = (*roughness_16);
    roughness_sqr = clamp((_e326 * _e327), 0.00000001f, 1f);
    let _e330 = (*anisotropy);
    if (_e330 > 0f) {
        let _e332 = (*anisotropy);
        aspect = sqrt((1f - clamp(_e332, 0f, 0.98f)));
        let _e336 = roughness_sqr;
        let _e337 = aspect;
        (*result_5)[0u] = min((_e336 / _e337), 1f);
        let _e341 = roughness_sqr;
        let _e342 = aspect;
        (*result_5)[1u] = (_e341 * _e342);
    } else {
        let _e345 = roughness_sqr;
        (*result_5)[0u] = _e345;
        let _e347 = roughness_sqr;
        (*result_5)[1u] = _e347;
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
    let _e574 = (*clearcoat_roughness);
    param_302 = _e574;
    param_303 = 0f;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_302), (&param_303), (&param_304));
    let _e575 = param_304;
    clearcoat_roughness_uv_out = _e575;
    sheen_intensity_out = 0f;
    let _e576 = (*sheen_color);
    param_305 = _e576;
    NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b((&param_305), (&param_306));
    let _e577 = param_306;
    sheen_intensity_out = _e577;
    let _e578 = (*sheen_roughness);
    let _e579 = (*sheen_roughness);
    sheen_roughness_sq_out = (_e578 * _e579);
    let _e581 = (*iridescence);
    mix_iridescent_metal_bsdf_fg_weight_out = (1f * _e581);
    let _e583 = (*roughness_17);
    let _e584 = (*roughness_17);
    alpha_roughness_out = (_e583 * _e584);
    let _e586 = (*anisotropy_strength);
    let _e587 = (*anisotropy_strength);
    strength_2_out = (_e586 * _e587);
    let _e589 = (*anisotropy_rotation);
    abs_anisotropy_rotation_out = abs(_e589);
    let _e591 = (*anisotropy_rotation);
    rad_2_deg_out = (_e591 * -57.29578f);
    let _e593 = (*iridescence);
    mix_iridescent_metal_bsdf_mix_inv_out = (1f - _e593);
    let _e595 = (*iridescence);
    mix_iridescent_dielectric_reflection_fg_weight_out = (1f * _e595);
    let _e597 = (*ior_6);
    one_minus_ior_out = (1f - _e597);
    let _e599 = (*ior_6);
    one_plus_ior_out = (1f + _e599);
    let _e601 = (*specular);
    dielectric_f90_out = (vec3<f32>(1f, 1f, 1f) * _e601);
    let _e603 = (*iridescence);
    mix_iridescent_dielectric_reflection_mix_inv_out = (1f - _e603);
    let _e605 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e605);
    let _e607 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e607);
    let _e609 = (*metallic);
    base_mix_mix_inv_out = (1f - _e609);
    let _e611 = (*emissive);
    let _e612 = (*emissive_strength);
    emission_color_out = (_e611 * _e612);
    let _e614 = (*alpha_12);
    let _e615 = (*alpha_cutoff);
    opacity_mask_cutoff_out = select(0f, 1f, (_e614 >= _e615));
    let _e618 = (*sheen_color);
    let _e619 = sheen_intensity_out;
    sheen_color_normalized_out = (_e618 / vec3(_e619));
    let _e622 = alpha_roughness_out;
    clamped_ab_out = clamp(_e622, 0.00001f, 1f);
    let _e624 = alpha_roughness_out;
    let _e625 = strength_2_out;
    at_out = mix(_e624, 1f, _e625);
    rotate_tangent_out = vec3<f32>(0f, 0f, 0f);
    let _e627 = (*tangent);
    param_307 = _e627;
    let _e628 = rad_2_deg_out;
    param_308 = _e628;
    let _e629 = (*normal);
    param_309 = _e629;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_307), (&param_308), (&param_309), (&param_310));
    let _e630 = param_310;
    rotate_tangent_out = _e630;
    let _e631 = mix_iridescent_metal_bsdf_mix_inv_out;
    mix_iridescent_metal_bsdf_bg_weight_out = (1f * _e631);
    let _e633 = one_minus_ior_out;
    let _e634 = one_plus_ior_out;
    ior_div_out = (_e633 / _e634);
    let _e636 = mix_iridescent_dielectric_reflection_mix_inv_out;
    mix_iridescent_dielectric_reflection_bg_weight_out = (1f * _e636);
    let _e638 = transmission_mix_mix_inv_out;
    transmission_mix_bg_weight_out = (1f * _e638);
    let _e640 = (*alpha_mode);
    let _e642 = opacity_mask_cutoff_out;
    let _e643 = (*alpha_12);
    opacity_mask_out = select(_e643, _e642, (_e640 == 1i));
    let _e645 = at_out;
    clamped_at_out = clamp(_e645, 0.00001f, 1f);
    let _e647 = rotate_tangent_out;
    normalize_tangent_out = normalize(_e647);
    let _e649 = ior_div_out;
    let _e650 = ior_div_out;
    dielectric_f0_from_ior_out = (_e649 * _e650);
    let _e652 = (*alpha_mode);
    let _e654 = opacity_mask_out;
    opacity_out = select(_e654, 1f, (_e652 == 0i));
    let _e656 = clamped_at_out;
    let _e657 = clamped_ab_out;
    roughness_uv_out = vec2<f32>(_e656, _e657);
    let _e659 = abs_anisotropy_rotation_out;
    let _e661 = normalize_tangent_out;
    let _e662 = (*tangent);
    selected_tangent_out = select(_e662, _e661, (_e659 > 0f));
    let _e664 = (*specular_color);
    let _e665 = dielectric_f0_from_ior_out;
    dielectric_f0_from_ior_specular_color_out = (_e664 * _e665);
    let _e667 = dielectric_f0_from_ior_specular_color_out;
    clamped_dielectric_f0_from_ior_specular_color_out = min(_e667, vec3(1f));
    let _e670 = clamped_dielectric_f0_from_ior_specular_color_out;
    let _e671 = (*specular);
    dielectric_f0_out = (_e670 * _e671);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e673 = g_ptN;
    N_13 = _e673;
    let _e674 = g_ptV;
    V_12 = _e674;
    let _e675 = g_ptL;
    L_7 = _e675;
    let _e676 = g_ptP;
    P_1 = _e676;
    let _e677 = g_ptOcclusion;
    occlusion_2 = _e677;
    let _e678 = g_ptClosureType;
    param_311 = _e678;
    let _e679 = L_7;
    param_312 = _e679;
    let _e680 = V_12;
    param_313 = _e680;
    let _e681 = N_13;
    param_314 = _e681;
    let _e682 = P_1;
    param_315 = _e682;
    let _e683 = occlusion_2;
    param_316 = _e683;
    let _e684 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_311), (&param_312), (&param_313), (&param_314), (&param_315), (&param_316));
    closureData_8 = _e684;
    clearcoat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e685 = closureData_8;
    param_317 = _e685;
    let _e686 = (*clearcoat);
    param_318 = _e686;
    param_319 = vec3<f32>(1f, 1f, 1f);
    param_320 = 1.5f;
    let _e687 = clearcoat_roughness_uv_out;
    param_321 = _e687;
    param_322 = false;
    param_323 = 0f;
    param_324 = 1.5f;
    let _e688 = (*clearcoat_normal);
    param_325 = _e688;
    let _e689 = (*tangent);
    param_326 = _e689;
    param_327 = 0i;
    param_328 = 0i;
    let _e690 = clearcoat_bsdf_out;
    param_329 = _e690;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_317), (&param_318), (&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325), (&param_326), (&param_327), (&param_328), (&param_329));
    let _e691 = param_329;
    clearcoat_bsdf_out = _e691;
    sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e692 = closureData_8;
    param_330 = _e692;
    let _e693 = sheen_intensity_out;
    param_331 = _e693;
    let _e694 = sheen_color_normalized_out;
    param_332 = _e694;
    let _e695 = sheen_roughness_sq_out;
    param_333 = _e695;
    let _e696 = (*normal);
    param_334 = _e696;
    param_335 = 0i;
    let _e697 = sheen_bsdf_out;
    param_336 = _e697;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336));
    let _e698 = param_336;
    sheen_bsdf_out = _e698;
    tf_metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e699 = closureData_8;
    param_337 = _e699;
    let _e700 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_338 = _e700;
    let _e701 = (*base_color);
    param_339 = _e701;
    param_340 = vec3<f32>(1f, 1f, 1f);
    param_341 = vec3<f32>(1f, 1f, 1f);
    param_342 = 5f;
    let _e702 = roughness_uv_out;
    param_343 = _e702;
    param_344 = false;
    let _e703 = (*iridescence_thickness);
    param_345 = _e703;
    let _e704 = (*iridescence_ior);
    param_346 = _e704;
    let _e705 = (*normal);
    param_347 = _e705;
    let _e706 = selected_tangent_out;
    param_348 = _e706;
    param_349 = 0i;
    param_350 = 0i;
    let _e707 = tf_metal_bsdf_out;
    param_351 = _e707;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_337), (&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350), (&param_351));
    let _e708 = param_351;
    tf_metal_bsdf_out = _e708;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e709 = closureData_8;
    param_352 = _e709;
    let _e710 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_353 = _e710;
    let _e711 = (*base_color);
    param_354 = _e711;
    param_355 = vec3<f32>(1f, 1f, 1f);
    param_356 = vec3<f32>(1f, 1f, 1f);
    param_357 = 5f;
    let _e712 = roughness_uv_out;
    param_358 = _e712;
    param_359 = false;
    param_360 = 0f;
    param_361 = 1.5f;
    let _e713 = (*normal);
    param_362 = _e713;
    let _e714 = selected_tangent_out;
    param_363 = _e714;
    param_364 = 0i;
    param_365 = 0i;
    let _e715 = metal_bsdf_out;
    param_366 = _e715;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365), (&param_366));
    let _e716 = param_366;
    metal_bsdf_out = _e716;
    mix_iridescent_metal_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e717 = closureData_8;
    param_367 = _e717;
    let _e718 = tf_metal_bsdf_out;
    param_368 = _e718;
    let _e719 = metal_bsdf_out;
    param_369 = _e719;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_367), (&param_368), (&param_369), (&param_370));
    let _e720 = param_370;
    mix_iridescent_metal_bsdf_add_out = _e720;
    base_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e721 = closureData_8;
    param_371 = _e721;
    let _e722 = mix_iridescent_metal_bsdf_add_out;
    param_372 = _e722;
    let _e723 = (*metallic);
    param_373 = _e723;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_371), (&param_372), (&param_373), (&param_374));
    let _e724 = param_374;
    base_mix_fg_mul_out = _e724;
    tf_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e725 = closureData_8;
    param_375 = _e725;
    let _e726 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_376 = _e726;
    let _e727 = dielectric_f0_out;
    param_377 = _e727;
    param_378 = vec3<f32>(1f, 1f, 1f);
    let _e728 = dielectric_f90_out;
    param_379 = _e728;
    param_380 = 5f;
    let _e729 = roughness_uv_out;
    param_381 = _e729;
    param_382 = false;
    let _e730 = (*iridescence_thickness);
    param_383 = _e730;
    let _e731 = (*iridescence_ior);
    param_384 = _e731;
    let _e732 = (*normal);
    param_385 = _e732;
    let _e733 = selected_tangent_out;
    param_386 = _e733;
    param_387 = 0i;
    param_388 = 0i;
    let _e734 = tf_reflection_bsdf_out;
    param_389 = _e734;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387), (&param_388), (&param_389));
    let _e735 = param_389;
    tf_reflection_bsdf_out = _e735;
    reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e736 = closureData_8;
    param_390 = _e736;
    let _e737 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_391 = _e737;
    let _e738 = dielectric_f0_out;
    param_392 = _e738;
    param_393 = vec3<f32>(1f, 1f, 1f);
    let _e739 = dielectric_f90_out;
    param_394 = _e739;
    param_395 = 5f;
    let _e740 = roughness_uv_out;
    param_396 = _e740;
    param_397 = false;
    param_398 = 0f;
    param_399 = 1.5f;
    let _e741 = (*normal);
    param_400 = _e741;
    let _e742 = selected_tangent_out;
    param_401 = _e742;
    param_402 = 0i;
    param_403 = 0i;
    let _e743 = reflection_bsdf_out;
    param_404 = _e743;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402), (&param_403), (&param_404));
    let _e744 = param_404;
    reflection_bsdf_out = _e744;
    mix_iridescent_dielectric_reflection_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e745 = closureData_8;
    param_405 = _e745;
    let _e746 = tf_reflection_bsdf_out;
    param_406 = _e746;
    let _e747 = reflection_bsdf_out;
    param_407 = _e747;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_405), (&param_406), (&param_407), (&param_408));
    let _e748 = param_408;
    mix_iridescent_dielectric_reflection_add_out = _e748;
    transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e749 = closureData_8;
    param_409 = _e749;
    let _e750 = transmission_mix_fg_weight_out;
    param_410 = _e750;
    let _e751 = (*base_color);
    param_411 = _e751;
    let _e752 = (*ior_6);
    param_412 = _e752;
    let _e753 = roughness_uv_out;
    param_413 = _e753;
    param_414 = false;
    param_415 = 0f;
    param_416 = 1.5f;
    let _e754 = (*normal);
    param_417 = _e754;
    let _e755 = selected_tangent_out;
    param_418 = _e755;
    param_419 = 0i;
    param_420 = 1i;
    let _e756 = transmission_bsdf_out;
    param_421 = _e756;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_409), (&param_410), (&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420), (&param_421));
    let _e757 = param_421;
    transmission_bsdf_out = _e757;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e758 = closureData_8;
    param_422 = _e758;
    let _e759 = transmission_mix_bg_weight_out;
    param_423 = _e759;
    let _e760 = (*base_color);
    param_424 = _e760;
    param_425 = 0f;
    let _e761 = (*normal);
    param_426 = _e761;
    param_427 = false;
    let _e762 = diffuse_bsdf_out;
    param_428 = _e762;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_422), (&param_423), (&param_424), (&param_425), (&param_426), (&param_427), (&param_428));
    let _e763 = param_428;
    diffuse_bsdf_out = _e763;
    transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e764 = closureData_8;
    param_429 = _e764;
    let _e765 = transmission_bsdf_out;
    param_430 = _e765;
    let _e766 = diffuse_bsdf_out;
    param_431 = _e766;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_429), (&param_430), (&param_431), (&param_432));
    let _e767 = param_432;
    transmission_mix_add_out = _e767;
    iridescent_dielectric_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e768 = closureData_8;
    param_433 = _e768;
    let _e769 = mix_iridescent_dielectric_reflection_add_out;
    param_434 = _e769;
    let _e770 = transmission_mix_add_out;
    param_435 = _e770;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_433), (&param_434), (&param_435), (&param_436));
    let _e771 = param_436;
    iridescent_dielectric_bsdf_out = _e771;
    base_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e772 = closureData_8;
    param_437 = _e772;
    let _e773 = iridescent_dielectric_bsdf_out;
    param_438 = _e773;
    let _e774 = base_mix_mix_inv_out;
    param_439 = _e774;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_437), (&param_438), (&param_439), (&param_440));
    let _e775 = param_440;
    base_mix_bg_mul_out = _e775;
    base_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e776 = closureData_8;
    param_441 = _e776;
    let _e777 = base_mix_fg_mul_out;
    param_442 = _e777;
    let _e778 = base_mix_bg_mul_out;
    param_443 = _e778;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_441), (&param_442), (&param_443), (&param_444));
    let _e779 = param_444;
    base_mix_add_out = _e779;
    sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e780 = closureData_8;
    param_445 = _e780;
    let _e781 = sheen_bsdf_out;
    param_446 = _e781;
    let _e782 = base_mix_add_out;
    param_447 = _e782;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_445), (&param_446), (&param_447), (&param_448));
    let _e783 = param_448;
    sheen_layer_out = _e783;
    clearcoat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e784 = closureData_8;
    param_449 = _e784;
    let _e785 = clearcoat_bsdf_out;
    param_450 = _e785;
    let _e786 = sheen_layer_out;
    param_451 = _e786;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_449), (&param_450), (&param_451), (&param_452));
    let _e787 = param_452;
    clearcoat_layer_out = _e787;
    let _e789 = clearcoat_layer_out.response;
    let _e791 = shader_constructor_out.color;
    shader_constructor_out.color = (_e791 + _e789);
    let _e794 = g_ptEmitEmission;
    if (_e794 != 0i) {
        param_453 = 4i;
        let _e796 = L_7;
        param_454 = _e796;
        let _e797 = V_12;
        param_455 = _e797;
        let _e798 = N_13;
        param_456 = _e798;
        let _e799 = P_1;
        param_457 = _e799;
        let _e800 = occlusion_2;
        param_458 = _e800;
        let _e801 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_453), (&param_454), (&param_455), (&param_456), (&param_457), (&param_458));
        closureData_9 = _e801;
        emission_out = vec3<f32>(0f, 0f, 0f);
        let _e802 = closureData_9;
        param_459 = _e802;
        let _e803 = emission_color_out;
        param_460 = _e803;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_459), (&param_460), (&param_461));
        let _e804 = param_461;
        emission_out = _e804;
        let _e805 = emission_out;
        let _e806 = g_ptEmission;
        g_ptEmission = (_e806 + _e805);
        let _e808 = emission_out;
        let _e810 = shader_constructor_out.color;
        shader_constructor_out.color = (_e810 + _e808);
    }
    let _e813 = shader_constructor_out;
    (*out1_1) = _e813;
    return;
}

fn mtlxHostEvalSurface_u0028_() -> surfaceshader {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_glass_out: surfaceshader;
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

    let _e354 = g_ptN;
    normalWorld = _e354;
    let _e355 = g_ptTangent;
    tangentWorld = _e355;
    let _e356 = normalWorld;
    geomprop_Nworld_out = normalize(_e356);
    let _e358 = tangentWorld;
    geomprop_Tworld_out = normalize(_e358);
    SR_glass_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e360 = base_color_1;
    param_462 = _e360;
    let _e361 = metallic_1;
    param_463 = _e361;
    let _e362 = roughness_18;
    param_464 = _e362;
    let _e363 = geomprop_Nworld_out;
    param_465 = _e363;
    let _e364 = geomprop_Tworld_out;
    param_466 = _e364;
    let _e365 = occlusion_3;
    param_467 = _e365;
    let _e366 = transmission_1;
    param_468 = _e366;
    let _e367 = specular_1;
    param_469 = _e367;
    let _e368 = specular_color_1;
    param_470 = _e368;
    let _e369 = ior_7;
    param_471 = _e369;
    let _e370 = alpha_15;
    param_472 = _e370;
    let _e371 = alpha_mode_1;
    param_473 = _e371;
    let _e372 = alpha_cutoff_1;
    param_474 = _e372;
    let _e373 = iridescence_1;
    param_475 = _e373;
    let _e374 = iridescence_ior_1;
    param_476 = _e374;
    let _e375 = iridescence_thickness_1;
    param_477 = _e375;
    let _e376 = sheen_color_1;
    param_478 = _e376;
    let _e377 = sheen_roughness_1;
    param_479 = _e377;
    let _e378 = clearcoat_1;
    param_480 = _e378;
    let _e379 = clearcoat_roughness_1;
    param_481 = _e379;
    let _e380 = geomprop_Nworld_out;
    param_482 = _e380;
    let _e381 = emissive_1;
    param_483 = _e381;
    let _e382 = emissive_strength_1;
    param_484 = _e382;
    let _e383 = thickness_1;
    param_485 = _e383;
    let _e384 = attenuation_distance_1;
    param_486 = _e384;
    let _e385 = attenuation_color_1;
    param_487 = _e385;
    let _e386 = anisotropy_strength_1;
    param_488 = _e386;
    let _e387 = anisotropy_rotation_1;
    param_489 = _e387;
    let _e388 = dispersion_1;
    param_490 = _e388;
    IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_462), (&param_463), (&param_464), (&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491));
    let _e389 = param_491;
    SR_glass_out = _e389;
    let _e390 = SR_glass_out;
    return _e390;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e324 = (*basis_2).tW;
    let _e326 = (*vLocal)[0u];
    let _e329 = (*basis_2).bW;
    let _e331 = (*vLocal)[1u];
    let _e335 = (*basis_2).nW;
    let _e337 = (*vLocal)[2u];
    return (((_e324 * _e326) + (_e329 * _e331)) + (_e335 * _e337));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_492: vec3<f32>;
    var param_493: Basis;
    var param_494: vec3<f32>;
    var param_495: Basis;

    let _e330 = (*pW_3);
    g_ptP = _e330;
    let _e332 = (*basis_3).nW;
    g_ptN = _e332;
    let _e334 = (*basis_3).tW;
    g_ptTangent = _e334;
    let _e336 = (*basis_3).bW;
    g_ptBitangent = _e336;
    let _e337 = (*winputL_2);
    param_492 = _e337;
    let _e338 = (*basis_3);
    param_493 = _e338;
    let _e339 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_492), (&param_493));
    g_ptV = _e339;
    let _e340 = (*woutputL_2);
    param_494 = _e340;
    let _e341 = (*basis_3);
    param_495 = _e341;
    let _e342 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_494), (&param_495));
    g_ptL = _e342;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e344 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e344, 0f) / 3.1415927f);
    let _e347 = mtlxHostEvalSurface_u0028_();
    return _e347.color;
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

    let _e342 = (*surfaceshader_1);
    if (_e342 == 1i) {
        let _e344 = (*pW_4);
        param_496 = _e344;
        let _e345 = (*basis_4);
        param_497 = _e345;
        let _e346 = (*winputL_3);
        param_498 = _e346;
        let _e347 = (*woutputL_3);
        param_499 = _e347;
        let _e348 = (*pdf_woutputL_3);
        param_500 = _e348;
        let _e349 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_496), (&param_497), (&param_498), (&param_499), (&param_500));
        let _e350 = param_500;
        (*pdf_woutputL_3) = _e350;
        return _e349;
    } else {
        let _e351 = (*surfaceshader_1);
        if (_e351 == 2i) {
            let _e353 = (*pW_4);
            param_501 = _e353;
            let _e354 = (*basis_4);
            param_502 = _e354;
            let _e355 = (*winputL_3);
            param_503 = _e355;
            let _e356 = (*woutputL_3);
            param_504 = _e356;
            let _e357 = (*pdf_woutputL_3);
            param_505 = _e357;
            let _e358 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_501), (&param_502), (&param_503), (&param_504), (&param_505));
            let _e359 = param_505;
            (*pdf_woutputL_3) = _e359;
            return _e358;
        } else {
            let _e360 = (*pW_4);
            param_506 = _e360;
            let _e361 = (*basis_4);
            param_507 = _e361;
            let _e362 = (*winputL_3);
            param_508 = _e362;
            let _e363 = (*woutputL_3);
            param_509 = _e363;
            let _e364 = (*pdf_woutputL_3);
            param_510 = _e364;
            let _e365 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_506), (&param_507), (&param_508), (&param_509), (&param_510));
            let _e366 = param_510;
            (*pdf_woutputL_3) = _e366;
            return _e365;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    return false;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e321 = g_ptOpacity;
    return (_e321 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_14: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e323 = (*N_14);
    l = length(_e323);
    let _e325 = (*N_14);
    let _e326 = l;
    return (_e325 / vec3(max(_e326, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_15: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_511: vec3<f32>;

    let _e325 = (*N_15)[2u];
    let _e328 = (*N_15)[0u];
    if (abs(_e325) < abs(_e328)) {
        let _e332 = (*N_15)[2u];
        let _e334 = (*N_15)[0u];
        T = vec3<f32>(_e332, 0f, -(_e334));
    } else {
        let _e338 = (*N_15)[2u];
        let _e340 = (*N_15)[1u];
        T = vec3<f32>(0f, _e338, -(_e340));
    }
    let _e343 = T;
    param_511 = _e343;
    let _e344 = safe_normalize_u0028_vf3_u003b((&param_511));
    T = _e344;
    let _e345 = T;
    return _e345;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e325 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e325).x;
    let _e328 = (*index);
    let _e329 = width;
    let _e337 = (*index);
    let _e338 = width;
    let _e341 = textureLoad(texture, vec2<i32>((_e328 - (i32(floor((f32(_e328) / f32(_e329)))) * _e329)), (_e337 / _e338)), 0i);
    return _e341;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_512: i32;
    var param_513: i32;
    var param_514: i32;

    let _e329 = (*barycoord)[0u];
    let _e331 = (*faceIndices)[0u];
    param_512 = bitcast<i32>(_e331);
    let _e333 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_512));
    let _e336 = (*barycoord)[1u];
    let _e338 = (*faceIndices)[1u];
    param_513 = bitcast<i32>(_e338);
    let _e340 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_513));
    let _e344 = (*barycoord)[2u];
    let _e346 = (*faceIndices)[2u];
    param_514 = bitcast<i32>(_e346);
    let _e348 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_514));
    return (((_e333 * _e329) + (_e340 * _e336)) + (_e348 * _e344));
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

    let _e333 = (*direction);
    inverseDirection = (vec3(1f) / _e333);
    let _e336 = (*minimum);
    let _e337 = (*origin);
    let _e339 = inverseDirection;
    t0_2 = ((_e336 - _e337) * _e339);
    let _e341 = (*maximum);
    let _e342 = (*origin);
    let _e344 = inverseDirection;
    t1_2 = ((_e341 - _e342) * _e344);
    let _e346 = t0_2;
    let _e347 = t1_2;
    entry = min(_e346, _e347);
    let _e349 = t0_2;
    let _e350 = t1_2;
    exit = max(_e349, _e350);
    let _e353 = entry[0u];
    let _e355 = entry[1u];
    let _e357 = entry[2u];
    nearDistance = max(_e353, max(_e355, _e357));
    let _e361 = exit[0u];
    let _e363 = exit[1u];
    let _e365 = exit[2u];
    farDistance = min(_e361, min(_e363, _e365));
    let _e368 = farDistance;
    let _e369 = nearDistance;
    if (_e368 >= max(_e369, 0f)) {
        let _e372 = nearDistance;
        local_10 = max(_e372, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e374 = local_10;
    return _e374;
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
    var phi_1292_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e374 = (*maxDistance);
    closest = _e374;
    found = false;
    loop {
        let _e375 = pointer;
        let _e377 = pointer;
        if ((_e375 >= 0i) && (_e377 < 64i)) {
            let _e380 = pointer;
            pointer = (_e380 - 1i);
            let _e383 = stack[_e380];
            nodeIndex = _e383;
            let _e384 = nodeIndex;
            param_515 = (_e384 * 3i);
            let _e386 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_515));
            minimum_1 = _e386;
            let _e387 = nodeIndex;
            param_516 = ((_e387 * 3i) + 1i);
            let _e390 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_516));
            maximum_1 = _e390;
            let _e391 = nodeIndex;
            param_517 = ((_e391 * 3i) + 2i);
            let _e394 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_517));
            metadata = _e394;
            let _e395 = minimum_1;
            param_518 = _e395.xyz;
            let _e397 = maximum_1;
            param_519 = _e397.xyz;
            let _e399 = (*rayOrigin);
            param_520 = _e399;
            let _e400 = (*rayDirection);
            param_521 = _e400;
            let _e401 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_518), (&param_519), (&param_520), (&param_521));
            let _e402 = closest;
            if (_e401 > _e402) {
                continue;
            }
            let _e405 = metadata[2u];
            if (_e405 > 0.5f) {
                let _e408 = metadata[0u];
                offset = i32((_e408 + 0.5f));
                let _e412 = metadata[1u];
                count = i32((_e412 + 0.5f));
                triangle = 0i;
                loop {
                    let _e415 = triangle;
                    let _e416 = count;
                    if (_e415 < _e416) {
                        let _e418 = offset;
                        let _e419 = triangle;
                        param_522 = (_e418 + _e419);
                        let _e421 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_522));
                        vertexIndices = vec3<u32>((_e421.xyz + vec3(0.5f)));
                        let _e427 = vertexIndices[0u];
                        param_523 = bitcast<i32>(_e427);
                        let _e429 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_523));
                        p0_ = _e429.xyz;
                        let _e432 = vertexIndices[1u];
                        param_524 = bitcast<i32>(_e432);
                        let _e434 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_524));
                        p1_ = _e434.xyz;
                        let _e437 = vertexIndices[2u];
                        param_525 = bitcast<i32>(_e437);
                        let _e439 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_525));
                        p2_ = _e439.xyz;
                        let _e441 = p1_;
                        let _e442 = p0_;
                        edge0_ = (_e441 - _e442);
                        let _e444 = p2_;
                        let _e445 = p0_;
                        edge1_ = (_e444 - _e445);
                        let _e447 = (*rayDirection);
                        let _e448 = edge1_;
                        pvec = cross(_e447, _e448);
                        let _e450 = edge0_;
                        let _e451 = pvec;
                        determinant_ = dot(_e450, _e451);
                        let _e453 = determinant_;
                        if (abs(_e453) < 0.00000001f) {
                            continue;
                        }
                        let _e456 = determinant_;
                        inverseDeterminant = (1f / _e456);
                        let _e458 = (*rayOrigin);
                        let _e459 = p0_;
                        tvec = (_e458 - _e459);
                        let _e461 = tvec;
                        let _e462 = pvec;
                        let _e464 = inverseDeterminant;
                        u = (dot(_e461, _e462) * _e464);
                        let _e466 = tvec;
                        let _e467 = edge0_;
                        qvec = cross(_e466, _e467);
                        let _e469 = (*rayDirection);
                        let _e470 = qvec;
                        let _e472 = inverseDeterminant;
                        v_3 = (dot(_e469, _e470) * _e472);
                        let _e474 = edge1_;
                        let _e475 = qvec;
                        let _e477 = inverseDeterminant;
                        distance_ = (dot(_e474, _e475) * _e477);
                        let _e479 = u;
                        let _e481 = v_3;
                        let _e483 = ((_e479 >= 0f) && (_e481 >= 0f));
                        phi_1292_ = _e483;
                        if _e483 {
                            let _e484 = u;
                            let _e485 = v_3;
                            phi_1292_ = ((_e484 + _e485) <= 1f);
                        }
                        let _e489 = phi_1292_;
                        let _e490 = distance_;
                        let _e493 = distance_;
                        let _e494 = closest;
                        if ((_e489 && (_e490 > 0f)) && (_e493 < _e494)) {
                            let _e497 = distance_;
                            closest = _e497;
                            let _e498 = distance_;
                            (*dist) = _e498;
                            let _e499 = u;
                            let _e501 = v_3;
                            let _e503 = u;
                            let _e504 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e499) - _e501), _e503, _e504);
                            let _e506 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e506.x, _e506.y, _e506.z, 0u);
                            let _e511 = edge0_;
                            let _e512 = edge1_;
                            (*faceNormal) = normalize(cross(_e511, _e512));
                            let _e515 = determinant_;
                            (*side) = select(1f, -1f, (_e515 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e518 = triangle;
                        triangle = (_e518 + 1i);
                    }
                }
            } else {
                let _e521 = metadata[0u];
                left = i32((_e521 + 0.5f));
                let _e525 = metadata[1u];
                right = i32((_e525 + 0.5f));
                let _e528 = pointer;
                if ((_e528 + 2i) >= 64i) {
                    continue;
                }
                let _e531 = pointer;
                let _e532 = (_e531 + 1i);
                pointer = _e532;
                let _e533 = right;
                stack[_e532] = _e533;
                let _e535 = pointer;
                let _e536 = (_e535 + 1i);
                pointer = _e536;
                let _e537 = left;
                stack[_e536] = _e537;
            }
            continue;
        } else {
            break;
        }
    }
    let _e539 = found;
    return _e539;
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

    let _e343 = (*rayOrigin_1);
    param_526 = _e343;
    let _e344 = (*rayDirection_1);
    param_527 = _e344;
    let _e345 = (*maxDistance_1);
    param_528 = _e345;
    let _e346 = (*faceIndices_2);
    param_529 = _e346;
    let _e347 = (*faceNormal_1);
    param_530 = _e347;
    let _e348 = (*barycoord_2);
    param_531 = _e348;
    let _e349 = (*side_1);
    param_532 = _e349;
    let _e350 = (*dist_1);
    param_533 = _e350;
    let _e351 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_526), (&param_527), (&param_528), (&param_529), (&param_530), (&param_531), (&param_532), (&param_533));
    let _e352 = param_529;
    (*faceIndices_2) = _e352;
    let _e353 = param_530;
    (*faceNormal_1) = _e353;
    let _e354 = param_531;
    (*barycoord_2) = _e354;
    let _e355 = param_532;
    (*side_1) = _e355;
    let _e356 = param_533;
    (*dist_1) = _e356;
    return _e351;
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
    var phi_6887_: bool;
    var phi_6909_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e363 = (*rayOrigin_2);
    param_534 = _e363;
    let _e364 = (*rayDir);
    param_535 = _e364;
    let _e365 = (*maxDistance_2);
    param_536 = _e365;
    let _e366 = faceIndices_surface;
    param_537 = _e366;
    let _e367 = faceNormal_surface;
    param_538 = _e367;
    let _e368 = barycoord_surface;
    param_539 = _e368;
    let _e369 = side_surface;
    param_540 = _e369;
    let _e370 = dist_surface;
    param_541 = _e370;
    let _e371 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_534), (&param_535), (&param_536), (&param_537), (&param_538), (&param_539), (&param_540), (&param_541));
    let _e372 = param_537;
    faceIndices_surface = _e372;
    let _e373 = param_538;
    faceNormal_surface = _e373;
    let _e374 = param_539;
    barycoord_surface = _e374;
    let _e375 = param_540;
    side_surface = _e375;
    let _e376 = param_541;
    dist_surface = _e376;
    hit_surface = _e371;
    dist_closest = 100000000000000000000f;
    let _e377 = hit_surface;
    if _e377 {
        let _e378 = dist_closest;
        let _e379 = dist_surface;
        dist_closest = min(_e378, _e379);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e382 = (*rayDir)[1u];
    if (abs(_e382) > 0.0000000001f) {
        let _e386 = (*rayOrigin_2)[1u];
        let _e389 = (*rayDir)[1u];
        t = ((0.01f - _e386) / _e389);
        let _e391 = t;
        let _e392 = (_e391 > 0f);
        phi_6887_ = _e392;
        if _e392 {
            let _e393 = t;
            let _e394 = dist_closest;
            let _e395 = (*maxDistance_2);
            phi_6887_ = (_e393 < min(_e394, _e395));
        }
        let _e399 = phi_6887_;
        if _e399 {
            let _e400 = t;
            dist_ground = _e400;
            hit_ground = true;
        }
    }
    let _e401 = hit_surface;
    let _e402 = hit_ground;
    hit = (_e401 || _e402);
    let _e404 = hit;
    if !(_e404) {
        return false;
    }
    let _e406 = hit_surface;
    phi_6909_ = _e406;
    if _e406 {
        let _e407 = hit_ground;
        let _e409 = dist_surface;
        let _e410 = dist_ground;
        phi_6909_ = (!(_e407) || (_e409 <= _e410));
    }
    let _e414 = phi_6909_;
    if _e414 {
        let _e415 = (*rayOrigin_2);
        let _e416 = dist_surface;
        let _e417 = (*rayDir);
        (*P_2) = (_e415 + (_e417 * _e416));
        let _e420 = barycoord_surface;
        (*baryCoord) = _e420;
        let _e421 = faceNormal_surface;
        param_542 = _e421;
        let _e422 = safe_normalize_u0028_vf3_u003b((&param_542));
        (*Ng) = _e422;
        let _e423 = barycoord_surface;
        param_543 = _e423;
        let _e424 = faceIndices_surface;
        param_544 = _e424.xyz;
        let _e426 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_543), (&param_544));
        gN = _e426;
        let _e427 = barycoord_surface;
        param_545 = _e427;
        let _e428 = faceIndices_surface;
        param_546 = _e428.xyz;
        let _e430 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_545), (&param_546));
        gT = _e430;
        let _e432 = unnamed.has_normals_surface;
        if (_e432 != 0u) {
            let _e434 = gN;
            local_11 = _e434.xyz;
        } else {
            let _e436 = (*Ng);
            local_11 = _e436;
        }
        let _e437 = local_11;
        (*Ns) = _e437;
        let _e439 = unnamed.has_uvs_surface;
        if (_e439 != 0u) {
            let _e442 = gN[3u];
            let _e444 = gT[3u];
            local_12 = vec2<f32>(_e442, _e444);
        } else {
            let _e446 = barycoord_surface;
            local_12 = _e446.xy;
        }
        let _e448 = local_12;
        (*texCoord) = _e448;
        let _e450 = unnamed.has_tangents_surface;
        if (_e450 != 0u) {
            let _e452 = gT;
            local_13 = _e452.xyz;
        } else {
            let _e454 = (*Ns);
            param_547 = _e454;
            let _e455 = normalToTangent_u0028_vf3_u003b((&param_547));
            local_13 = _e455;
        }
        let _e456 = local_13;
        (*Ts) = _e456;
        let _e457 = barycoord_surface;
        param_548 = _e457;
        let _e458 = faceIndices_surface;
        param_549 = _e458.xyz;
        let _e460 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_548), (&param_549));
        (*surfaceshader_2) = select(1i, 0i, (_e460.x > 0.5f));
    } else {
        let _e464 = hit_ground;
        if _e464 {
            let _e465 = (*rayOrigin_2);
            let _e466 = dist_ground;
            let _e467 = (*rayDir);
            (*P_2) = (_e465 + (_e467 * _e466));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e470 = (*Ng);
            (*Ns) = _e470;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e472 = (*P_2)[0u];
            let _e474 = (*P_2)[2u];
            (*texCoord) = (((vec2<f32>(_e472, -(_e474)) / vec2(200f)) * 2f) + vec2(0.5f));
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
    var phi_7053_: bool;
    var phi_7057_: bool;

    let _e342 = (*rayOrigin_3);
    param_550 = _e342;
    let _e343 = (*rayDir_1);
    param_551 = _e343;
    let _e344 = (*maxDistance_3);
    param_552 = _e344;
    let _e345 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555), (&param_556), (&param_557), (&param_558), (&param_559));
    let _e346 = param_553;
    pW_5 = _e346;
    let _e347 = param_554;
    nsW = _e347;
    let _e348 = param_555;
    ngW = _e348;
    let _e349 = param_556;
    TsW = _e349;
    let _e350 = param_557;
    baryCoord_1 = _e350;
    let _e351 = param_558;
    texCoord_1 = _e351;
    let _e352 = param_559;
    surfaceshader_3 = _e352;
    hit_1 = _e345;
    let _e353 = hit_1;
    let _e354 = surfaceshader_3;
    let _e356 = (_e353 && (_e354 == 1i));
    phi_7053_ = _e356;
    if _e356 {
        let _e357 = mtlx_openpbr_is_opaque_u0028_();
        phi_7053_ = !(_e357);
    }
    let _e360 = phi_7053_;
    phi_7057_ = _e360;
    if _e360 {
        let _e361 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_7057_ = _e361;
    }
    let _e363 = phi_7057_;
    if _e363 {
        return 1f;
    }
    let _e364 = hit_1;
    return select(1f, 0f, _e364);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e323 = (*v_4)[0u];
    let _e325 = (*v_4)[1u];
    let _e327 = (*v_4)[2u];
    return max(_e323, max(_e325, _e327));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e323 = (*vWorld);
    let _e325 = (*basis_5).tW;
    let _e327 = (*vWorld);
    let _e329 = (*basis_5).bW;
    let _e331 = (*vWorld);
    let _e333 = (*basis_5).nW;
    return vec3<f32>(dot(_e323, _e325), dot(_e327, _e329), dot(_e331, _e333));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e324 = (*v_5);
    state = ((_e324 * 747796405u) + 2891336453u);
    let _e327 = state;
    let _e328 = state;
    let _e334 = state;
    word = (((_e327 >> bitcast<u32>(((_e328 >> bitcast<u32>(28u)) + 4u))) ^ _e334) * 277803737u);
    let _e337 = word;
    let _e340 = word;
    return ((_e337 >> bitcast<u32>(22u)) ^ _e340);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_560: u32;

    let _e323 = (*seed);
    param_560 = _e323;
    let _e324 = pcg_u0028_u1_u003b((&param_560));
    (*seed) = _e324;
    let _e325 = (*seed);
    return (f32((_e325 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_3: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e329 = (*i_3);
    let _e331 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e329), 0i);
    t0_3 = _e331;
    let _e332 = (*i_3);
    let _e334 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e332), 0i);
    t1_3 = _e334;
    let _e335 = (*i_3);
    let _e337 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e335), 0i);
    t2_2 = _e337;
    let _e338 = (*i_3);
    let _e340 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e338), 0i);
    t3_2 = _e340;
    let _e341 = (*i_3);
    let _e343 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e341), 0i);
    t4_2 = _e343;
    let _e344 = (*i_3);
    let _e346 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e344), 0i);
    t5_ = _e346;
    let _e347 = t0_3;
    l_1.position = _e347.xyz;
    let _e351 = t0_3[3u];
    l_1.decayRate = _e351;
    let _e353 = t1_3;
    l_1.direction = _e353.xyz;
    let _e357 = t1_3[3u];
    l_1.type_ = i32((_e357 + 0.5f));
    let _e361 = t2_2;
    l_1.color = _e361.xyz;
    let _e365 = t2_2[3u];
    l_1.intensity = _e365;
    let _e368 = t3_2[0u];
    l_1.innerCone = _e368;
    let _e371 = t3_2[1u];
    l_1.outerCone = _e371;
    let _e373 = t4_2;
    l_1.u = _e373.xyz;
    let _e376 = t5_;
    l_1.v = _e376.xyz;
    let _e379 = l_1;
    return _e379;
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

    let _e356 = (*index_1);
    param_561 = _e356;
    let _e357 = GetMtlxLight_u0028_i1_u003b((&param_561));
    l_2 = _e357;
    let _e359 = l_2.color;
    let _e361 = l_2.intensity;
    intensity = (_e359 * _e361);
    (*maxDistance_4) = 100000000000000000000f;
    let _e364 = l_2.type_;
    if (_e364 == 1i) {
        let _e367 = l_2.direction;
        param_562 = -(_e367);
        let _e369 = safe_normalize_u0028_vf3_u003b((&param_562));
        (*woutputW) = _e369;
    } else {
        let _e371 = l_2.type_;
        if (_e371 == 3i) {
            let _e373 = (*rndSeed);
            param_563 = _e373;
            let _e374 = rand_u0028_u1_u003b((&param_563));
            let _e375 = param_563;
            (*rndSeed) = _e375;
            let _e376 = (*rndSeed);
            param_564 = _e376;
            let _e377 = rand_u0028_u1_u003b((&param_564));
            let _e378 = param_564;
            (*rndSeed) = _e378;
            xi = vec2<f32>(_e374, _e377);
            let _e381 = l_2.position;
            let _e383 = xi[0u];
            let _e385 = l_2.u;
            let _e389 = xi[1u];
            let _e391 = l_2.v;
            pointOnLight = ((_e381 + (_e385 * _e383)) + (_e391 * _e389));
            let _e395 = l_2.u;
            let _e397 = l_2.v;
            param_565 = cross(_e395, _e397);
            let _e399 = safe_normalize_u0028_vf3_u003b((&param_565));
            lightNormal = _e399;
            let _e401 = l_2.u;
            let _e403 = l_2.v;
            area = length(cross(_e401, _e403));
            let _e406 = pointOnLight;
            let _e407 = (*pW_6);
            toLight = (_e406 - _e407);
            let _e409 = toLight;
            let _e410 = toLight;
            distSq = max(dot(_e409, _e410), 0.0000000001f);
            let _e413 = distSq;
            distanceToLight = sqrt(_e413);
            let _e415 = toLight;
            let _e416 = distanceToLight;
            (*woutputW) = (_e415 / vec3(_e416));
            let _e419 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e419 - 0.0002f));
            let _e422 = lightNormal;
            let _e423 = (*woutputW);
            cosLight = max(dot(_e422, -(_e423)), 0f);
            let _e427 = cosLight;
            let _e429 = area;
            if ((_e427 <= 0f) || (_e429 <= 0f)) {
                let _e432 = (*woutputW);
                param_566 = _e432;
                let _e433 = (*basis_6);
                param_567 = _e433;
                let _e434 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_566), (&param_567));
                (*woutputL_4) = _e434;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e435 = cosLight;
            let _e436 = area;
            let _e438 = distSq;
            let _e440 = intensity;
            intensity = (_e440 * ((_e435 * _e436) / _e438));
            let _e442 = (*woutputW);
            param_568 = _e442;
            let _e443 = (*basis_6);
            param_569 = _e443;
            let _e444 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_568), (&param_569));
            (*woutputL_4) = _e444;
            let _e445 = intensity;
            return _e445;
        } else {
            let _e447 = l_2.position;
            let _e448 = (*pW_6);
            toLight_1 = (_e447 - _e448);
            let _e450 = toLight_1;
            distanceToLight_1 = max(length(_e450), 0.0000000001f);
            let _e453 = toLight_1;
            let _e454 = distanceToLight_1;
            (*woutputW) = (_e453 / vec3(_e454));
            let _e457 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e457 - 0.0002f));
            let _e460 = distanceToLight_1;
            let _e463 = l_2.decayRate;
            attenuation = pow((_e460 + 1f), (_e463 + 0.0000000001f));
            let _e466 = attenuation;
            let _e468 = intensity;
            intensity = (_e468 / vec3(max(_e466, 0.0000000001f)));
            let _e472 = l_2.type_;
            if (_e472 == 2i) {
                let _e474 = (*woutputW);
                let _e476 = l_2.direction;
                param_570 = _e476;
                let _e477 = safe_normalize_u0028_vf3_u003b((&param_570));
                cosDir = dot(_e474, -(_e477));
                let _e481 = l_2.innerCone;
                let _e483 = l_2.outerCone;
                low = min(_e481, _e483);
                let _e486 = l_2.innerCone;
                high = _e486;
                let _e487 = low;
                let _e488 = high;
                let _e489 = cosDir;
                let _e491 = intensity;
                intensity = (_e491 * smoothstep(_e487, _e488, _e489));
            }
        }
    }
    let _e493 = (*woutputW);
    param_571 = _e493;
    let _e494 = (*basis_6);
    param_572 = _e494;
    let _e495 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_571), (&param_572));
    (*woutputL_4) = _e495;
    let _e496 = intensity;
    return _e496;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_573: i32;
    var power: f32;

    let _e325 = (*index_2);
    param_573 = _e325;
    let _e326 = GetMtlxLight_u0028_i1_u003b((&param_573));
    l_3 = _e326;
    let _e328 = l_3.color;
    let _e330 = l_3.intensity;
    power = length((_e328 * _e330));
    let _e334 = l_3.type_;
    if (_e334 == 3i) {
        let _e337 = l_3.u;
        let _e339 = l_3.v;
        let _e342 = power;
        power = (_e342 * length(cross(_e337, _e339)));
    }
    let _e344 = power;
    return _e344;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e326 = unnamed.sunAngularSize;
    theta_max = ((_e326 * 3.1415927f) / 180f);
    let _e329 = (*woutputW_1);
    let _e331 = unnamed.sunDir;
    let _e333 = theta_max;
    if (dot(_e329, _e331) < cos(_e333)) {
        return 0f;
    }
    let _e336 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e336)));
    let _e340 = solid_angle;
    return (1f / _e340);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e324 = unnamed.sunAngularSize;
    theta_max_1 = ((_e324 * 3.1415927f) / 180f);
    let _e327 = (*woutputW_2);
    let _e329 = unnamed.sunDir;
    let _e331 = theta_max_1;
    if (dot(_e327, _e329) < cos(_e331)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e335 = unnamed.sunPower;
    let _e337 = unnamed.sunColor;
    return (_e337 * _e335);
}

fn envMapLuminance_u0028_vf3_u003b(c_4: ptr<function, vec3<f32>>) -> f32 {
    let _e322 = (*c_4);
    return dot(_e322, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_5: ptr<function, vec3<f32>>) -> f32 {
    var theta: f32;
    var s_5: f32;
    var pdf_2: f32;
    var param_574: vec3<f32>;

    let _e328 = (*uv_3)[1u];
    theta = (_e328 * 3.1415927f);
    let _e330 = theta;
    s_5 = sin(_e330);
    let _e332 = s_5;
    if (_e332 <= 0f) {
        return 0f;
    }
    let _e334 = (*color_5);
    param_574 = _e334;
    let _e335 = envMapLuminance_u0028_vf3_u003b((&param_574));
    let _e337 = unnamed.envMapTotalSum;
    pdf_2 = (_e335 / max(_e337, 0.0000000001f));
    let _e340 = pdf_2;
    let _e343 = unnamed.envMapRes[0u];
    let _e347 = unnamed.envMapRes[1u];
    let _e349 = s_5;
    return (((_e340 * _e343) * _e347) / (19.739208f * _e349));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_1: f32;
    var s_6: f32;

    let _e326 = (*uv_4)[0u];
    phi_1 = (_e326 * 6.2831855f);
    let _e329 = (*uv_4)[1u];
    theta_1 = (_e329 * 3.1415927f);
    let _e331 = theta_1;
    s_6 = sin(_e331);
    let _e333 = s_6;
    let _e335 = phi_1;
    let _e338 = theta_1;
    let _e340 = s_6;
    let _e342 = phi_1;
    return vec3<f32>((-(_e333) * cos(_e335)), cos(_e338), (-(_e340) * sin(_e342)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_9: i32;

    let _e330 = unnamed.envMapRes;
    res = vec2<i32>(_e330);
    lower = 0i;
    let _e333 = res[1u];
    upper = (_e333 - 1i);
    loop {
        let _e335 = lower;
        let _e336 = upper;
        if (_e335 < _e336) {
            let _e338 = lower;
            let _e339 = upper;
            mid = ((_e338 + _e339) >> bitcast<u32>(1i));
            let _e343 = (*value);
            let _e345 = res[0u];
            let _e347 = mid;
            let _e349 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e345 - 1i), _e347), 0i);
            if (_e343 < _e349.x) {
                let _e352 = mid;
                upper = _e352;
            } else {
                let _e353 = mid;
                lower = (_e353 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e355 = lower;
    let _e357 = res[1u];
    y_5 = clamp(_e355, 0i, (_e357 - 1i));
    lower = 0i;
    let _e361 = res[0u];
    upper = (_e361 - 1i);
    loop {
        let _e363 = lower;
        let _e364 = upper;
        if (_e363 < _e364) {
            let _e366 = lower;
            let _e367 = upper;
            mid_1 = ((_e366 + _e367) >> bitcast<u32>(1i));
            let _e371 = (*value);
            let _e372 = mid_1;
            let _e373 = y_5;
            let _e375 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e372, _e373), 0i);
            if (_e371 < _e375.x) {
                let _e378 = mid_1;
                upper = _e378;
            } else {
                let _e379 = mid_1;
                lower = (_e379 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e381 = lower;
    let _e383 = res[0u];
    x_9 = clamp(_e381, 0i, (_e383 - 1i));
    let _e386 = x_9;
    let _e388 = y_5;
    let _e392 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e386), f32(_e388)) / _e392);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e324 = (*woutputW_3)[0u];
    let _e325 = (*woutputW_3);
    let _e326 = _e325.yz;
    let _e330 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e324, _e326.x, _e326.y), 0f);
    env = _e330;
    let _e331 = env;
    let _e334 = unnamed.skyPower;
    let _e337 = unnamed.skyColor;
    return ((_e331.xyz * _e334) * _e337);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_3: f32;
    var param_575: u32;
    var theta_2: f32;
    var param_576: u32;
    var x_10: f32;
    var y_6: f32;
    var z_1: f32;

    let _e330 = (*rndSeed_1);
    param_575 = _e330;
    let _e331 = rand_u0028_u1_u003b((&param_575));
    let _e332 = param_575;
    (*rndSeed_1) = _e332;
    r_3 = sqrt(_e331);
    let _e334 = (*rndSeed_1);
    param_576 = _e334;
    let _e335 = rand_u0028_u1_u003b((&param_576));
    let _e336 = param_576;
    (*rndSeed_1) = _e336;
    theta_2 = (6.2831855f * _e335);
    let _e338 = r_3;
    let _e339 = theta_2;
    x_10 = (_e338 * cos(_e339));
    let _e342 = r_3;
    let _e343 = theta_2;
    y_6 = (_e342 * sin(_e343));
    let _e346 = x_10;
    let _e347 = x_10;
    let _e350 = y_6;
    let _e351 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e346 * _e347)) - (_e350 * _e351))));
    let _e356 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e356) / 3.1415927f));
    let _e360 = x_10;
    let _e361 = y_6;
    let _e362 = z_1;
    return vec3<f32>(_e360, _e361, _e362);
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

    let _e342 = unnamed.has_env_cdf;
    if !((_e342 != 0u)) {
        let _e345 = (*rndSeed_2);
        param_577 = _e345;
        let _e346 = (*pdfDir);
        param_578 = _e346;
        let _e347 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_577), (&param_578));
        let _e348 = param_577;
        (*rndSeed_2) = _e348;
        let _e349 = param_578;
        (*pdfDir) = _e349;
        (*woutputL_6) = _e347;
        let _e350 = (*woutputL_6);
        param_579 = _e350;
        let _e351 = (*basis_7);
        param_580 = _e351;
        let _e352 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_579), (&param_580));
        (*woutputW_4) = _e352;
        let _e353 = (*woutputW_4);
        param_581 = _e353;
        let _e354 = skyRadiance_u0028_vf3_u003b((&param_581));
        return _e354;
    }
    let _e355 = (*rndSeed_2);
    param_582 = _e355;
    let _e356 = rand_u0028_u1_u003b((&param_582));
    let _e357 = param_582;
    (*rndSeed_2) = _e357;
    let _e359 = unnamed.envMapTotalSum;
    param_583 = (_e356 * max(_e359, 0.0000000001f));
    let _e362 = envMapBinarySearch_u0028_f1_u003b((&param_583));
    uv_5 = _e362;
    let _e363 = uv_5;
    param_584 = _e363;
    let _e364 = envMapUvToDir_u0028_vf2_u003b((&param_584));
    param_585 = _e364;
    let _e365 = safe_normalize_u0028_vf3_u003b((&param_585));
    (*woutputW_4) = _e365;
    let _e366 = (*woutputW_4);
    param_586 = _e366;
    let _e367 = (*basis_7);
    param_587 = _e367;
    let _e368 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_586), (&param_587));
    (*woutputL_6) = _e368;
    let _e369 = uv_5;
    let _e370 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e369, 0f);
    color_6 = _e370.xyz;
    let _e372 = uv_5;
    param_588 = _e372;
    let _e373 = color_6;
    param_589 = _e373;
    let _e374 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_588), (&param_589));
    (*pdfDir) = _e374;
    let _e376 = unnamed.skyPower;
    let _e378 = unnamed.skyColor;
    let _e380 = color_6;
    return ((_e378 * _e376) * _e380);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_3: f32;

    let _e324 = (*d)[1u];
    theta_3 = acos(clamp(_e324, -1f, 1f));
    let _e328 = (*d)[2u];
    let _e330 = (*d)[0u];
    let _e334 = theta_3;
    return vec2<f32>(((3.1415927f + atan2(_e328, _e330)) * 0.15915494f), (_e334 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_590: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_591: vec3<f32>;
    var param_592: vec3<f32>;
    var color_7: vec3<f32>;
    var param_593: vec2<f32>;
    var param_594: vec3<f32>;

    let _e331 = unnamed.has_env_cdf;
    if !((_e331 != 0u)) {
        let _e334 = (*woutputL_7);
        param_590 = _e334;
        let _e335 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_590));
        return _e335;
    }
    let _e336 = (*woutputW_5);
    param_591 = _e336;
    let _e337 = safe_normalize_u0028_vf3_u003b((&param_591));
    param_592 = _e337;
    let _e338 = envMapDirToUv_u0028_vf3_u003b((&param_592));
    uv_6 = _e338;
    let _e339 = uv_6;
    let _e340 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e339, 0f);
    color_7 = _e340.xyz;
    let _e342 = uv_6;
    param_593 = _e342;
    let _e343 = color_7;
    param_594 = _e343;
    let _e344 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_593), (&param_594));
    return _e344;
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

    let _e344 = unnamed.sunAngularSize;
    theta_max_2 = ((_e344 * 3.1415927f) / 180f);
    let _e347 = theta_max_2;
    let _e348 = (*rndSeed_3);
    param_595 = _e348;
    let _e349 = rand_u0028_u1_u003b((&param_595));
    let _e350 = param_595;
    (*rndSeed_3) = _e350;
    theta_4 = (_e347 * sqrt(_e349));
    let _e353 = theta_4;
    costheta = cos(_e353);
    let _e355 = costheta;
    let _e356 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e355 * _e356))));
    let _e361 = (*rndSeed_3);
    param_596 = _e361;
    let _e362 = rand_u0028_u1_u003b((&param_596));
    let _e363 = param_596;
    (*rndSeed_3) = _e363;
    phi_2 = (6.2831855f * _e362);
    let _e365 = phi_2;
    cosphi = cos(_e365);
    let _e367 = phi_2;
    sinphi = sin(_e367);
    let _e369 = sintheta;
    let _e370 = cosphi;
    x_11 = (_e369 * _e370);
    let _e372 = sintheta;
    let _e373 = sinphi;
    y_7 = (_e372 * _e373);
    let _e375 = costheta;
    z_2 = _e375;
    let _e376 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e376)));
    let _e380 = solid_angle_1;
    (*pdfDir_1) = (1f / _e380);
    let _e382 = x_11;
    let _e383 = y_7;
    let _e384 = z_2;
    param_597 = vec3<f32>(_e382, _e383, _e384);
    let _e386 = sunBasis;
    param_598 = _e386;
    let _e387 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_597), (&param_598));
    (*woutputW_6) = _e387;
    let _e388 = (*woutputW_6);
    param_599 = _e388;
    let _e389 = (*basis_8);
    param_600 = _e389;
    let _e390 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_599), (&param_600));
    (*woutputL_8) = _e390;
    let _e392 = unnamed.sunPower;
    let _e394 = unnamed.sunColor;
    let _e396 = solid_angle_1;
    return ((_e394 * _e392) / vec3(_e396));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e322 = unnamed.skyPower;
    let _e324 = unnamed.skyColor;
    return (length((_e324 * _e322)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e322 = unnamed.sunPower;
    let _e324 = unnamed.sunColor;
    return length((_e324 * _e322));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_4: i32;
    var param_601: i32;

    power_1 = 0f;
    i_4 = 0i;
    loop {
        let _e324 = i_4;
        if (_e324 < 1i) {
            let _e326 = i_4;
            let _e328 = unnamed.mtlxLightCount;
            if (_e326 >= _e328) {
                break;
            }
            let _e330 = i_4;
            param_601 = _e330;
            let _e331 = mtlxLightTotalPower_u0028_i1_u003b((&param_601));
            let _e332 = power_1;
            power_1 = (_e332 + _e331);
            continue;
        } else {
            break;
        }
        continuing {
            let _e334 = i_4;
            i_4 = (_e334 + 1i);
        }
    }
    let _e336 = power_1;
    return _e336;
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
    var phi_8105_: bool;

    let _e388 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e388;
    let _e390 = unnamed.mtlxDisableSun;
    let _e391 = (_e390 != 0u);
    phi_8105_ = _e391;
    if !(_e391) {
        let _e394 = unnamed.mtlxLightCount;
        phi_8105_ = (_e394 > 0i);
    }
    let _e397 = phi_8105_;
    if _e397 {
        local_14 = 0f;
    } else {
        let _e398 = sunTotalPower_u0028_();
        local_14 = _e398;
    }
    let _e399 = local_14;
    w_sun = _e399;
    let _e400 = skyTotalPower_u0028_();
    w_sky = _e400;
    let _e401 = w_sun;
    let _e402 = w_sky;
    let _e404 = w_mtlx;
    w_total = max(0.0000000001f, ((_e401 + _e402) + _e404));
    let _e407 = w_sun;
    let _e408 = w_total;
    P_sun = (_e407 / _e408);
    let _e410 = w_sky;
    let _e411 = w_total;
    P_sky = (_e410 / _e411);
    let _e413 = w_mtlx;
    let _e414 = w_total;
    P_mtlx = (_e413 / _e414);
    let _e416 = (*rndSeed_4);
    param_602 = _e416;
    let _e417 = rand_u0028_u1_u003b((&param_602));
    let _e418 = param_602;
    (*rndSeed_4) = _e418;
    r_4 = _e417;
    maxDistance_5 = 100000000000000000000f;
    let _e419 = r_4;
    let _e420 = P_sun;
    if (_e419 < _e420) {
        let _e422 = (*basis_9);
        param_603 = _e422;
        let _e423 = (*shadowL);
        param_604 = _e423;
        let _e424 = (*shadowW);
        param_605 = _e424;
        let _e425 = pdf_sun;
        param_606 = _e425;
        let _e426 = (*rndSeed_4);
        param_607 = _e426;
        let _e427 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607));
        let _e428 = param_604;
        (*shadowL) = _e428;
        let _e429 = param_605;
        (*shadowW) = _e429;
        let _e430 = param_606;
        pdf_sun = _e430;
        let _e431 = param_607;
        (*rndSeed_4) = _e431;
        Li_5 = _e427;
        let _e432 = (*shadowW);
        param_608 = _e432;
        let _e433 = skyRadiance_u0028_vf3_u003b((&param_608));
        let _e434 = Li_5;
        Li_5 = (_e434 + _e433);
        let _e436 = (*shadowL);
        param_609 = _e436;
        let _e437 = (*shadowW);
        param_610 = _e437;
        let _e438 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_609), (&param_610));
        pdf_sky = _e438;
    } else {
        let _e439 = r_4;
        let _e440 = P_sun;
        let _e441 = P_sky;
        if (_e439 < (_e440 + _e441)) {
            let _e444 = (*basis_9);
            param_611 = _e444;
            let _e445 = (*rndSeed_4);
            param_615 = _e445;
            let _e446 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_611), (&param_612), (&param_613), (&param_614), (&param_615));
            let _e447 = param_612;
            (*shadowL) = _e447;
            let _e448 = param_613;
            (*shadowW) = _e448;
            let _e449 = param_614;
            pdf_sky = _e449;
            let _e450 = param_615;
            (*rndSeed_4) = _e450;
            Li_5 = _e446;
            let _e451 = w_sun;
            if (_e451 > 0f) {
                let _e453 = (*shadowW);
                param_616 = _e453;
                let _e454 = sunRadiance_u0028_vf3_u003b((&param_616));
                let _e455 = Li_5;
                Li_5 = (_e455 + _e454);
            }
            let _e457 = (*shadowL);
            param_617 = _e457;
            let _e458 = (*shadowW);
            param_618 = _e458;
            let _e459 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_617), (&param_618));
            pdf_sun = _e459;
        } else {
            let _e460 = (*rndSeed_4);
            param_619 = _e460;
            let _e461 = rand_u0028_u1_u003b((&param_619));
            let _e462 = param_619;
            (*rndSeed_4) = _e462;
            let _e463 = w_mtlx;
            target_ = (_e461 * max(_e463, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_5 = 0i;
            loop {
                let _e466 = i_5;
                if (_e466 < 1i) {
                    let _e468 = i_5;
                    let _e470 = unnamed.mtlxLightCount;
                    if (_e468 >= _e470) {
                        break;
                    }
                    let _e472 = i_5;
                    param_620 = _e472;
                    let _e473 = mtlxLightTotalPower_u0028_i1_u003b((&param_620));
                    let _e474 = accum;
                    accum = (_e474 + _e473);
                    let _e476 = target_;
                    let _e477 = accum;
                    if (_e476 <= _e477) {
                        let _e479 = i_5;
                        selected = _e479;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e480 = i_5;
                    i_5 = (_e480 + 1i);
                }
            }
            let _e482 = selected;
            param_621 = _e482;
            let _e483 = mtlxLightTotalPower_u0028_i1_u003b((&param_621));
            selectedPower = max(_e483, 0.0000000001f);
            let _e485 = selected;
            param_622 = _e485;
            let _e486 = (*pW_7);
            param_623 = _e486;
            let _e487 = (*basis_9);
            param_624 = _e487;
            let _e488 = (*rndSeed_4);
            param_628 = _e488;
            let _e489 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627), (&param_628));
            let _e490 = param_625;
            (*shadowL) = _e490;
            let _e491 = param_626;
            (*shadowW) = _e491;
            let _e492 = param_627;
            maxDistance_5 = _e492;
            let _e493 = param_628;
            (*rndSeed_4) = _e493;
            Li_5 = _e489;
            let _e494 = (*shadowL);
            param_629 = _e494;
            let _e495 = (*shadowW);
            param_630 = _e495;
            let _e496 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_629), (&param_630));
            pdf_sun = _e496;
            let _e497 = (*shadowL);
            param_631 = _e497;
            let _e498 = (*shadowW);
            param_632 = _e498;
            let _e499 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_631), (&param_632));
            pdf_sky = _e499;
            let _e500 = P_mtlx;
            let _e501 = selectedPower;
            let _e503 = w_mtlx;
            (*lightPdf) = ((_e500 * _e501) / max(_e503, 0.0000000001f));
            let _e507 = (*shadowL)[2u];
            if (_e507 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e509 = Li_5;
            param_633 = _e509;
            let _e510 = maxComponent_u0028_vf3_u003b((&param_633));
            if (_e510 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e512 = (*pW_7);
            let _e514 = (*basis_9).nW;
            let _e515 = (*shadowW);
            let _e517 = (*basis_9).nW;
            shadowOrigin = (_e512 + ((_e514 * sign(dot(_e515, _e517))) * 0.0001f));
            let _e523 = shadowOrigin;
            param_634 = _e523;
            let _e524 = (*shadowW);
            param_635 = _e524;
            let _e525 = maxDistance_5;
            param_636 = _e525;
            let _e526 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_634), (&param_635), (&param_636));
            visibility = _e526;
            let _e527 = visibility;
            let _e528 = Li_5;
            return (_e528 * _e527);
        }
    }
    let _e530 = P_sun;
    let _e531 = pdf_sun;
    let _e533 = P_sky;
    let _e534 = pdf_sky;
    (*lightPdf) = ((_e530 * _e531) + (_e533 * _e534));
    let _e538 = (*shadowL)[2u];
    if (_e538 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e540 = Li_5;
    param_637 = _e540;
    let _e541 = maxComponent_u0028_vf3_u003b((&param_637));
    if (_e541 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e543 = (*pW_7);
    let _e545 = (*basis_9).nW;
    let _e546 = (*shadowW);
    let _e548 = (*basis_9).nW;
    shadowOrigin_1 = (_e543 + ((_e545 * sign(dot(_e546, _e548))) * 0.0001f));
    let _e554 = shadowOrigin_1;
    param_638 = _e554;
    let _e555 = (*shadowW);
    param_639 = _e555;
    param_640 = 100000000000000000000f;
    let _e556 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_638), (&param_639), (&param_640));
    visibility_1 = _e556;
    let _e557 = visibility_1;
    let _e558 = Li_5;
    return (_e558 * _e557);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_641: vec3<f32>;
    var param_642: Basis;

    let _e327 = (*pW_8);
    g_ptP = _e327;
    let _e329 = (*basis_10).nW;
    g_ptN = _e329;
    let _e331 = (*basis_10).tW;
    g_ptTangent = _e331;
    let _e333 = (*basis_10).bW;
    g_ptBitangent = _e333;
    let _e335 = (*basis_10).texCoord;
    g_ptTexcoord = _e335;
    let _e336 = (*winputL_4);
    param_641 = _e336;
    let _e337 = (*basis_10);
    param_642 = _e337;
    let _e338 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_641), (&param_642));
    g_ptV = _e338;
    let _e340 = (*basis_10).nW;
    g_ptL = _e340;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e341 = alpha_15;
    g_ptOpacity = clamp(_e341, 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e343 = mtlxHostEvalSurface_u0028_();
    let _e344 = (*rndSeed_5);
    (*rndSeed_5) = (_e344 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_643: vec3<f32>;
    var param_644: Basis;
    var param_645: vec3<f32>;
    var param_646: u32;

    emissionSeed = 0u;
    let _e328 = (*pW_9);
    param_643 = _e328;
    let _e329 = (*basis_11);
    param_644 = _e329;
    param_645 = vec3<f32>(0f, 0f, 1f);
    let _e330 = emissionSeed;
    param_646 = _e330;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_643), (&param_644), (&param_645), (&param_646));
    let _e331 = param_646;
    emissionSeed = _e331;
    let _e332 = g_ptEmission;
    return max(_e332, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_647: vec3<f32>;
    var param_648: Basis;

    let _e326 = (*pW_10);
    param_647 = _e326;
    let _e327 = (*basis_12);
    param_648 = _e327;
    let _e328 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_647), (&param_648));
    return _e328;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_649: u32;
    var param_650: f32;
    var param_651: vec3<f32>;
    var phi_7126_: bool;

    let _e331 = (*winputL_6)[2u];
    if (_e331 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e333 = (*rndSeed_6);
    param_649 = _e333;
    let _e334 = (*pdf_woutputL_4);
    param_650 = _e334;
    let _e335 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_649), (&param_650));
    let _e336 = param_649;
    (*rndSeed_6) = _e336;
    let _e337 = param_650;
    (*pdf_woutputL_4) = _e337;
    (*woutputL_9) = _e335;
    let _e339 = unnamed.wireframe;
    let _e340 = (_e339 != 0u);
    phi_7126_ = _e340;
    if _e340 {
        let _e342 = (*basis_13).baryCoord;
        param_651 = _e342;
        let _e343 = minComponent_u0028_vf3_u003b((&param_651));
        phi_7126_ = (_e343 < 0.003f);
    }
    let _e346 = phi_7126_;
    if _e346 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e348 = unnamed.neutral_color;
    return (_e348 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_652: u32;
    var param_653: f32;
    var param_654: vec3<f32>;

    let _e331 = (*winputL_7)[2u];
    if (_e331 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e333 = (*rndSeed_7);
    param_652 = _e333;
    let _e334 = (*pdf_woutputL_5);
    param_653 = _e334;
    let _e335 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_652), (&param_653));
    let _e336 = param_652;
    (*rndSeed_7) = _e336;
    let _e337 = param_653;
    (*pdf_woutputL_5) = _e337;
    (*woutputL_10) = _e335;
    let _e338 = (*pW_12);
    param_654 = _e338;
    let _e339 = ground_albedo_u0028_vf3_u003b((&param_654));
    return (_e339 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e325 = (*w_1)[2u];
    if (abs(_e325) < 0.00000011920929f) {
        return 0f;
    }
    let _e328 = (*alpha_x);
    let _e330 = (*w_1)[0u];
    let _e332 = (*alpha_x);
    let _e334 = (*w_1)[0u];
    let _e337 = (*alpha_y);
    let _e339 = (*w_1)[1u];
    let _e341 = (*alpha_y);
    let _e343 = (*w_1)[1u];
    let _e348 = (*w_1)[2u];
    let _e350 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e328 * _e330) * (_e332 * _e334)) + ((_e337 * _e339) * (_e341 * _e343))) / (_e348 * _e350))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_655: vec3<f32>;
    var param_656: f32;
    var param_657: f32;
    var param_658: vec3<f32>;
    var param_659: f32;
    var param_660: f32;

    let _e331 = (*woL);
    param_655 = _e331;
    let _e332 = (*alpha_x_1);
    param_656 = _e332;
    let _e333 = (*alpha_y_1);
    param_657 = _e333;
    let _e334 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_655), (&param_656), (&param_657));
    let _e336 = (*wiL_1);
    param_658 = _e336;
    let _e337 = (*alpha_x_1);
    param_659 = _e337;
    let _e338 = (*alpha_y_1);
    param_660 = _e338;
    let _e339 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_658), (&param_659), (&param_660));
    return (1f / ((1f + _e334) + _e339));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e327 = (*alpha_x_2);
    ax = max(_e327, 0.0000000001f);
    let _e329 = (*alpha_y_2);
    ay = max(_e329, 0.0000000001f);
    let _e331 = ax;
    let _e333 = ay;
    let _e336 = (*m_5)[0u];
    let _e337 = ax;
    let _e340 = (*m_5)[0u];
    let _e341 = ax;
    let _e345 = (*m_5)[1u];
    let _e346 = ay;
    let _e349 = (*m_5)[1u];
    let _e350 = ay;
    let _e355 = (*m_5)[2u];
    let _e357 = (*m_5)[2u];
    let _e361 = (*m_5)[0u];
    let _e362 = ax;
    let _e365 = (*m_5)[0u];
    let _e366 = ax;
    let _e370 = (*m_5)[1u];
    let _e371 = ay;
    let _e374 = (*m_5)[1u];
    let _e375 = ay;
    let _e380 = (*m_5)[2u];
    let _e382 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e331) * _e333) * (((((_e336 / _e337) * (_e340 / _e341)) + ((_e345 / _e346) * (_e349 / _e350))) + (_e355 * _e357)) * ((((_e361 / _e362) * (_e365 / _e366)) + ((_e370 / _e371) * (_e374 / _e375))) + (_e380 * _e382))));
    let _e387 = Ddenom;
    return (1f / max(_e387, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_661: vec3<f32>;
    var param_662: f32;
    var param_663: f32;

    let _e327 = (*w_2);
    param_661 = _e327;
    let _e328 = (*alpha_x_3);
    param_662 = _e328;
    let _e329 = (*alpha_y_3);
    param_663 = _e329;
    let _e330 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_661), (&param_662), (&param_663));
    return (1f / (1f + _e330));
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

    let _e337 = (*rndSeed_8);
    param_664 = _e337;
    let _e338 = rand_u0028_u1_u003b((&param_664));
    let _e339 = param_664;
    (*rndSeed_8) = _e339;
    let _e340 = (*rndSeed_8);
    param_665 = _e340;
    let _e341 = rand_u0028_u1_u003b((&param_665));
    let _e342 = param_665;
    (*rndSeed_8) = _e342;
    Xi_2 = vec2<f32>(_e338, _e341);
    let _e344 = (*wiL_2);
    V_13 = _e344;
    let _e345 = (*alpha_x_4);
    let _e346 = (*alpha_y_4);
    alpha_13 = vec2<f32>(_e345, _e346);
    let _e348 = V_13;
    let _e350 = alpha_13;
    let _e351 = (_e348.xy * _e350);
    let _e353 = V_13[2u];
    V_13 = normalize(vec3<f32>(_e351.x, _e351.y, _e353));
    let _e359 = Xi_2[0u];
    phi_3 = (6.2831855f * _e359);
    let _e362 = Xi_2[1u];
    let _e365 = V_13[2u];
    let _e369 = V_13[2u];
    z_3 = (((1f - _e362) * (1f + _e365)) - _e369);
    let _e371 = z_3;
    let _e372 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e371 * _e372)), 0f, 1f));
    let _e377 = sinTheta_1;
    let _e378 = phi_3;
    x_12 = (_e377 * cos(_e378));
    let _e381 = sinTheta_1;
    let _e382 = phi_3;
    y_8 = (_e381 * sin(_e382));
    let _e385 = x_12;
    let _e386 = y_8;
    let _e387 = z_3;
    c_5 = vec3<f32>(_e385, _e386, _e387);
    let _e389 = c_5;
    let _e390 = V_13;
    H_7 = (_e389 + _e390);
    let _e392 = H_7;
    let _e394 = alpha_13;
    let _e395 = (_e392.xy * _e394);
    let _e397 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e395.x, _e395.y, _e397));
    let _e402 = H_7;
    return _e402;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_6: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e326 = (*mui);
    c_6 = _e326;
    let _e327 = (*eta_ti);
    let _e328 = (*eta_ti);
    let _e330 = c_6;
    let _e331 = c_6;
    mut2_ = (((_e327 * _e328) + (_e330 * _e331)) - 1f);
    let _e335 = mut2_;
    if (_e335 <= 0f) {
        return 1f;
    }
    let _e337 = mut2_;
    g_1 = sqrt(_e337);
    let _e339 = g_1;
    let _e340 = c_6;
    let _e342 = g_1;
    let _e343 = c_6;
    let _e346 = g_1;
    let _e347 = c_6;
    let _e349 = g_1;
    let _e350 = c_6;
    let _e355 = g_1;
    let _e356 = c_6;
    let _e358 = c_6;
    let _e361 = g_1;
    let _e362 = c_6;
    let _e364 = c_6;
    let _e368 = g_1;
    let _e369 = c_6;
    let _e371 = c_6;
    let _e374 = g_1;
    let _e375 = c_6;
    let _e377 = c_6;
    return ((0.5f * (((_e339 - _e340) / (_e342 + _e343)) * ((_e346 - _e347) / (_e349 + _e350)))) * (1f + (((((_e355 + _e356) * _e358) - 1f) / (((_e361 - _e362) * _e364) + 1f)) * ((((_e368 + _e369) * _e371) - 1f) / (((_e374 - _e375) * _e377) + 1f)))));
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
    var phi_6329_: bool;
    var phi_6464_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e475 = metallic_1;
    m_metal = clamp(_e475, 0f, 1f);
    let _e477 = roughness_18;
    m_rough = clamp(_e477, 0f, 1f);
    m_aniso = 0f;
    let _e479 = base_color_1;
    m_base = (_e479 * 1f);
    let _e481 = specular_color_1;
    m_specC = _e481;
    let _e482 = specular_1;
    m_specW = _e482;
    let _e483 = ior_7;
    m_ior = max(_e483, 1.001f);
    m_coatW = 0f;
    m_coatRough = 0f;
    m_coatAniso = 0f;
    m_coatIor = 1.5f;
    let _e485 = (*winputL_8);
    V_14 = _e485;
    let _e487 = V_14[2u];
    if (_e487 < 0f) {
        let _e489 = V_14;
        V_14 = -(_e489);
    }
    let _e492 = V_14[2u];
    NdotV_20 = max(_e492, 0.0001f);
    let _e494 = m_rough;
    let _e495 = m_rough;
    alpha_14 = clamp((_e494 * _e495), 0.0001f, 1f);
    let _e498 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e498));
    let _e501 = alpha_14;
    let _e502 = anisoAspect;
    let _e503 = anisoAspect;
    let _e509 = alpha_14;
    let _e510 = anisoAspect;
    let _e512 = anisoAspect;
    let _e513 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e501 * sqrt((2f / ((_e502 * _e503) + 1f)))), ((_e509 * _e510) * sqrt((2f / ((_e512 * _e513) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e521 = m_coatRough;
    let _e522 = m_coatRough;
    coatAlpha = clamp((_e521 * _e522), 0.0001f, 1f);
    let _e525 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e525));
    let _e528 = coatAlpha;
    let _e529 = coatAnisoAspect;
    let _e530 = coatAnisoAspect;
    let _e536 = coatAlpha;
    let _e537 = coatAnisoAspect;
    let _e539 = coatAnisoAspect;
    let _e540 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e528 * sqrt((2f / ((_e529 * _e530) + 1f)))), ((_e536 * _e537) * sqrt((2f / ((_e539 * _e540) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e548 = m_ior;
    let _e550 = m_ior;
    F0d = pow(((_e548 - 1f) / (_e550 + 1f)), 2f);
    let _e554 = F0d;
    let _e556 = m_specC;
    let _e559 = m_specW;
    let _e561 = m_base;
    let _e562 = m_metal;
    F0_8 = mix(((vec3(_e554) * max(_e556, vec3<f32>(0f, 0f, 0f))) * _e559), _e561, vec3(_e562));
    let _e566 = F0_8[0u];
    let _e568 = F0_8[1u];
    let _e570 = F0_8[2u];
    F0lum = max(_e566, max(_e568, _e570));
    let _e573 = F0lum;
    let _e574 = F0lum;
    let _e576 = NdotV_20;
    Fv = (_e573 + ((1f - _e574) * pow((1f - _e576), 5f)));
    let _e581 = NdotV_20;
    param_666 = _e581;
    let _e582 = m_coatIor;
    param_667 = _e582;
    let _e583 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_666), (&param_667));
    coatFv = _e583;
    let _e584 = m_coatW;
    let _e585 = coatFv;
    pCoat = clamp((_e584 * _e585), 0f, 0.75f);
    let _e588 = (*rndSeed_9);
    param_668 = _e588;
    let _e589 = rand_u0028_u1_u003b((&param_668));
    let _e590 = param_668;
    (*rndSeed_9) = _e590;
    xiLobe = _e589;
    pTrans = 0f;
    let _e591 = transmission_1;
    m_transW = clamp(_e591, 0f, 1f);
    let _e593 = attenuation_color_1;
    m_transC = _e593;
    let _e594 = attenuation_distance_1;
    m_transD = _e594;
    let _e595 = m_transW;
    let _e596 = Fv;
    pTrans = clamp((_e595 * (1f - _e596)), 0f, 0.95f);
    let _e600 = xiLobe;
    let _e601 = pCoat;
    if (_e600 < _e601) {
        let _e603 = V_14;
        param_669 = _e603;
        let _e605 = coatSampleAlpha[0u];
        param_670 = _e605;
        let _e607 = coatSampleAlpha[1u];
        param_671 = _e607;
        let _e608 = (*rndSeed_9);
        param_672 = _e608;
        let _e609 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_669), (&param_670), (&param_671), (&param_672));
        let _e610 = param_672;
        (*rndSeed_9) = _e610;
        Hc = _e609;
        let _e611 = V_14;
        let _e613 = Hc;
        (*woutputL_11) = reflect(-(_e611), _e613);
        let _e616 = (*woutputL_11)[2u];
        if (_e616 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e618 = V_14;
        param_673 = _e618;
        let _e620 = coatSampleAlpha[0u];
        param_674 = _e620;
        let _e622 = coatSampleAlpha[1u];
        param_675 = _e622;
        let _e623 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_673), (&param_674), (&param_675));
        let _e624 = V_14;
        let _e625 = (*woutputL_11);
        param_676 = normalize((_e624 + _e625));
        let _e629 = coatSampleAlpha[0u];
        param_677 = _e629;
        let _e631 = coatSampleAlpha[1u];
        param_678 = _e631;
        let _e632 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_676), (&param_677), (&param_678));
        let _e634 = NdotV_20;
        pdfCoat = ((_e623 * _e632) / (4f * _e634));
        let _e637 = V_14;
        param_679 = _e637;
        let _e639 = sampleAlpha[0u];
        param_680 = _e639;
        let _e641 = sampleAlpha[1u];
        param_681 = _e641;
        let _e642 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_679), (&param_680), (&param_681));
        let _e643 = V_14;
        let _e644 = (*woutputL_11);
        param_682 = normalize((_e643 + _e644));
        let _e648 = sampleAlpha[0u];
        param_683 = _e648;
        let _e650 = sampleAlpha[1u];
        param_684 = _e650;
        let _e651 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_682), (&param_683), (&param_684));
        let _e653 = NdotV_20;
        pdfBaseSpec = ((_e642 * _e651) / (4f * _e653));
        let _e656 = (*woutputL_11);
        param_685 = _e656;
        let _e657 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_685));
        pdfBaseDiff = _e657;
        let _e658 = m_metal;
        let _e660 = m_base;
        diffLumCoat = ((1f - _e658) * dot(_e660, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e663 = Fv;
        let _e664 = Fv;
        let _e665 = Fv;
        let _e667 = diffLumCoat;
        pSpecCoat = clamp((_e663 / ((_e664 + ((1f - _e665) * _e667)) + 0.001f)), 0.05f, 0.95f);
        let _e673 = pCoat;
        let _e674 = pdfCoat;
        let _e676 = pCoat;
        let _e678 = pTrans;
        let _e681 = pSpecCoat;
        let _e682 = pdfBaseSpec;
        let _e684 = pSpecCoat;
        let _e686 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e673 * _e674) + (((1f - _e676) * (1f - _e678)) * ((_e681 * _e682) + ((1f - _e684) * _e686)))), 0.000001f);
        let _e692 = (*pW_13);
        param_686 = _e692;
        let _e693 = (*basis_15);
        param_687 = _e693;
        let _e694 = (*winputL_8);
        param_688 = _e694;
        let _e695 = (*woutputL_11);
        param_689 = _e695;
        let _e696 = ignorePdfCoat;
        param_690 = _e696;
        let _e697 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_686), (&param_687), (&param_688), (&param_689), (&param_690));
        let _e698 = param_690;
        ignorePdfCoat = _e698;
        return _e697;
    }
    let _e699 = xiLobe;
    let _e700 = pCoat;
    let _e701 = pCoat;
    let _e703 = pTrans;
    if (_e699 < (_e700 + ((1f - _e701) * _e703))) {
        let _e708 = (*winputL_8)[2u];
        externalTransmission = (_e708 > 0f);
        let _e710 = externalTransmission;
        if _e710 {
            let _e711 = m_ior;
            local_15 = (1f / _e711);
        } else {
            let _e713 = m_ior;
            local_15 = _e713;
        }
        let _e714 = local_15;
        etaRatio = _e714;
        let _e715 = alpha_14;
        if (_e715 <= 0.001f) {
            let _e717 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e717));
            let _e720 = Hdelta;
            let _e721 = (*winputL_8);
            HdotWiDelta = dot(_e720, _e721);
            let _e723 = etaRatio;
            let _e724 = etaRatio;
            let _e726 = HdotWiDelta;
            let _e727 = HdotWiDelta;
            discrDelta = (1f - ((_e723 * _e724) * (1f - (_e726 * _e727))));
            let _e732 = discrDelta;
            if (_e732 < 0f) {
                let _e734 = (*winputL_8);
                let _e736 = (*winputL_8);
                let _e737 = Hdelta;
                let _e740 = Hdelta;
                (*woutputL_11) = (-(_e734) + (_e740 * (2f * dot(_e736, _e737))));
                let _e743 = pCoat;
                let _e745 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e743) * _e745), 0.000001f);
                let _e748 = m_transW;
                let _e749 = (*pdf_woutputL_6);
                let _e752 = (*woutputL_11)[2u];
                return vec3(((_e748 * _e749) / max(abs(_e752), 0.0000000001f)));
            }
            let _e757 = etaRatio;
            let _e758 = (*winputL_8);
            let _e760 = Hdelta;
            let _e761 = HdotWiDelta;
            let _e764 = etaRatio;
            let _e765 = HdotWiDelta;
            let _e768 = discrDelta;
            beamIncidentDelta = ((_e758 * _e757) - ((_e760 * sign(_e761)) * ((_e764 * abs(_e765)) - sqrt(_e768))));
            let _e773 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e773));
            let _e777 = (*winputL_8)[2u];
            let _e779 = (*woutputL_11)[2u];
            if ((_e777 * _e779) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e782 = m_transD;
            let _e783 = (_e782 > 0f);
            phi_6329_ = _e783;
            if _e783 {
                let _e784 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_6329_ = !(_e784);
            }
            let _e787 = phi_6329_;
            if _e787 {
                let _e788 = m_transC;
                let _e792 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e788))) / vec3(_e792));
                (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
                (*internal_medium).anisotropy = 0f;
            }
            let _e798 = HdotWiDelta;
            let _e800 = etaRatio;
            param_691 = abs(_e798);
            param_692 = (1f / _e800);
            let _e802 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_691), (&param_692));
            Tdelta = clamp((1f - _e802), 0f, 1f);
            let _e805 = m_transD;
            let _e807 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e807, (_e805 == 0f));
            let _e809 = pCoat;
            let _e811 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e809) * _e811), 0.000001f);
            let _e814 = m_transW;
            let _e815 = tintDelta;
            let _e817 = Tdelta;
            let _e819 = (*pdf_woutputL_6);
            let _e822 = (*woutputL_11)[2u];
            return ((((_e815 * _e814) * _e817) * _e819) / vec3(max(abs(_e822), 0.0000000001f)));
        }
        let _e827 = (*winputL_8);
        Vsample = _e827;
        let _e829 = Vsample[2u];
        if (_e829 < 0f) {
            let _e832 = Vsample[2u];
            Vsample[2u] = (_e832 * -1f);
        }
        let _e835 = Vsample;
        param_693 = _e835;
        let _e837 = sampleAlpha[0u];
        param_694 = _e837;
        let _e839 = sampleAlpha[1u];
        param_695 = _e839;
        let _e840 = (*rndSeed_9);
        param_696 = _e840;
        let _e841 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_693), (&param_694), (&param_695), (&param_696));
        let _e842 = param_696;
        (*rndSeed_9) = _e842;
        Ht_2 = _e841;
        let _e844 = (*winputL_8)[2u];
        if (_e844 < 0f) {
            let _e847 = Ht_2[2u];
            Ht_2[2u] = (_e847 * -1f);
        }
        let _e850 = Ht_2;
        let _e851 = (*winputL_8);
        HdotWi = dot(_e850, _e851);
        let _e853 = etaRatio;
        let _e854 = etaRatio;
        let _e856 = HdotWi;
        let _e857 = HdotWi;
        discr = (1f - ((_e853 * _e854) * (1f - (_e856 * _e857))));
        let _e862 = discr;
        if (_e862 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e864 = etaRatio;
        let _e865 = (*winputL_8);
        let _e867 = Ht_2;
        let _e868 = HdotWi;
        let _e871 = etaRatio;
        let _e872 = HdotWi;
        let _e875 = discr;
        beamIncident = ((_e865 * _e864) - ((_e867 * sign(_e868)) * ((_e871 * abs(_e872)) - sqrt(_e875))));
        let _e880 = beamIncident;
        (*woutputL_11) = -(normalize(_e880));
        let _e884 = (*winputL_8)[2u];
        let _e886 = (*woutputL_11)[2u];
        if ((_e884 * _e886) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e889 = m_transD;
        let _e890 = (_e889 > 0f);
        phi_6464_ = _e890;
        if _e890 {
            let _e891 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_6464_ = !(_e891);
        }
        let _e894 = phi_6464_;
        if _e894 {
            let _e895 = m_transC;
            let _e899 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e895))) / vec3(_e899));
            (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
            (*internal_medium).anisotropy = 0f;
        }
        let _e905 = V_14;
        let _e906 = m_ior;
        let _e907 = (*woutputL_11);
        Hr = normalize(-((_e905 + (_e907 * _e906))));
        let _e913 = Hr[2u];
        if (_e913 < 0f) {
            let _e915 = Hr;
            Hr = -(_e915);
        }
        let _e917 = (*winputL_8);
        let _e918 = Ht_2;
        VoH = abs(dot(_e917, _e918));
        let _e921 = (*woutputL_11);
        let _e922 = Ht_2;
        LoH = abs(dot(_e921, _e922));
        let _e925 = LoH;
        let _e926 = etaRatio;
        let _e927 = VoH;
        denomT = (_e925 + (_e926 * _e927));
        let _e930 = etaRatio;
        let _e931 = etaRatio;
        let _e933 = VoH;
        let _e935 = denomT;
        let _e936 = denomT;
        jacT = (((_e930 * _e931) * _e933) / max((_e935 * _e936), 0.00000001f));
        let _e940 = Vsample;
        param_697 = _e940;
        let _e942 = sampleAlpha[0u];
        param_698 = _e942;
        let _e944 = sampleAlpha[1u];
        param_699 = _e944;
        let _e945 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_697), (&param_698), (&param_699));
        let _e946 = VoH;
        let _e949 = Ht_2[2u];
        if (abs(_e949) > 0f) {
            let _e953 = Ht_2[0u];
            let _e955 = Ht_2[1u];
            let _e957 = Ht_2[2u];
            local_16 = vec3<f32>(_e953, _e955, abs(_e957));
        } else {
            let _e960 = Ht_2;
            local_16 = _e960;
        }
        let _e961 = local_16;
        param_700 = _e961;
        let _e963 = sampleAlpha[0u];
        param_701 = _e963;
        let _e965 = sampleAlpha[1u];
        param_702 = _e965;
        let _e966 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_700), (&param_701), (&param_702));
        let _e969 = (*winputL_8)[2u];
        DvT = (((_e945 * _e946) * _e966) / max(abs(_e969), 0.0001f));
        let _e973 = pCoat;
        let _e975 = pTrans;
        let _e977 = DvT;
        let _e979 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e973) * _e975) * _e977) * _e979), 0.000001f);
        let _e983 = Ht_2[2u];
        if (abs(_e983) > 0f) {
            let _e987 = Ht_2[0u];
            let _e989 = Ht_2[1u];
            let _e991 = Ht_2[2u];
            local_17 = vec3<f32>(_e987, _e989, abs(_e991));
        } else {
            let _e994 = Ht_2;
            local_17 = _e994;
        }
        let _e995 = local_17;
        param_703 = _e995;
        let _e997 = sampleAlpha[0u];
        param_704 = _e997;
        let _e999 = sampleAlpha[1u];
        param_705 = _e999;
        let _e1000 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_703), (&param_704), (&param_705));
        D_3 = _e1000;
        let _e1001 = (*winputL_8);
        param_706 = _e1001;
        let _e1002 = (*woutputL_11);
        param_707 = _e1002;
        let _e1004 = sampleAlpha[0u];
        param_708 = _e1004;
        let _e1006 = sampleAlpha[1u];
        param_709 = _e1006;
        let _e1007 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_706), (&param_707), (&param_708), (&param_709));
        G2_ = _e1007;
        let _e1008 = etaRatio;
        etaRefl = (1f / _e1008);
        let _e1010 = VoH;
        param_710 = _e1010;
        let _e1011 = etaRefl;
        param_711 = _e1011;
        let _e1012 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_710), (&param_711));
        T_1 = clamp((1f - _e1012), 0f, 1f);
        let _e1015 = m_transD;
        let _e1017 = m_transC;
        tint_2 = select(vec3<f32>(1f, 1f, 1f), _e1017, (_e1015 == 0f));
        let _e1019 = m_transW;
        let _e1020 = tint_2;
        let _e1022 = T_1;
        let _e1024 = VoH;
        let _e1026 = jacT;
        let _e1028 = D_3;
        let _e1030 = G2_;
        let _e1033 = (*woutputL_11)[2u];
        let _e1036 = (*winputL_8)[2u];
        return (((((((_e1020 * _e1019) * _e1022) * _e1024) * _e1026) * _e1028) * _e1030) / vec3(max((abs(_e1033) * abs(_e1036)), 0.0000000001f)));
    }
    let _e1042 = m_metal;
    let _e1044 = m_base;
    diffLum = ((1f - _e1042) * dot(_e1044, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1047 = Fv;
    let _e1048 = Fv;
    let _e1049 = Fv;
    let _e1051 = diffLum;
    pSpec = clamp((_e1047 / ((_e1048 + ((1f - _e1049) * _e1051)) + 0.001f)), 0.05f, 0.95f);
    let _e1057 = (*rndSeed_9);
    param_712 = _e1057;
    let _e1058 = rand_u0028_u1_u003b((&param_712));
    let _e1059 = param_712;
    (*rndSeed_9) = _e1059;
    let _e1060 = pSpec;
    if (_e1058 < _e1060) {
        let _e1062 = V_14;
        param_713 = _e1062;
        let _e1064 = sampleAlpha[0u];
        param_714 = _e1064;
        let _e1066 = sampleAlpha[1u];
        param_715 = _e1066;
        let _e1067 = (*rndSeed_9);
        param_716 = _e1067;
        let _e1068 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_713), (&param_714), (&param_715), (&param_716));
        let _e1069 = param_716;
        (*rndSeed_9) = _e1069;
        H_8 = _e1068;
        let _e1070 = V_14;
        let _e1072 = H_8;
        (*woutputL_11) = reflect(-(_e1070), _e1072);
    } else {
        let _e1074 = (*rndSeed_9);
        param_717 = _e1074;
        let _e1075 = pdfTmp;
        param_718 = _e1075;
        let _e1076 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_717), (&param_718));
        let _e1077 = param_717;
        (*rndSeed_9) = _e1077;
        let _e1078 = param_718;
        pdfTmp = _e1078;
        (*woutputL_11) = _e1076;
    }
    let _e1080 = (*woutputL_11)[2u];
    if (_e1080 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1082 = V_14;
    let _e1083 = (*woutputL_11);
    Hh = normalize((_e1082 + _e1083));
    let _e1086 = V_14;
    param_719 = _e1086;
    let _e1088 = sampleAlpha[0u];
    param_720 = _e1088;
    let _e1090 = sampleAlpha[1u];
    param_721 = _e1090;
    let _e1091 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_719), (&param_720), (&param_721));
    let _e1092 = Hh;
    param_722 = _e1092;
    let _e1094 = sampleAlpha[0u];
    param_723 = _e1094;
    let _e1096 = sampleAlpha[1u];
    param_724 = _e1096;
    let _e1097 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_722), (&param_723), (&param_724));
    let _e1099 = NdotV_20;
    pdfSpec = ((_e1091 * _e1097) / (4f * _e1099));
    let _e1102 = (*woutputL_11);
    param_725 = _e1102;
    let _e1103 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_725));
    pdfDiff = _e1103;
    let _e1104 = V_14;
    param_726 = _e1104;
    let _e1106 = coatSampleAlpha[0u];
    param_727 = _e1106;
    let _e1108 = coatSampleAlpha[1u];
    param_728 = _e1108;
    let _e1109 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_726), (&param_727), (&param_728));
    let _e1110 = Hh;
    param_729 = _e1110;
    let _e1112 = coatSampleAlpha[0u];
    param_730 = _e1112;
    let _e1114 = coatSampleAlpha[1u];
    param_731 = _e1114;
    let _e1115 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_729), (&param_730), (&param_731));
    let _e1117 = NdotV_20;
    pdfCoat_1 = ((_e1109 * _e1115) / (4f * _e1117));
    let _e1120 = pCoat;
    let _e1121 = pdfCoat_1;
    let _e1123 = pCoat;
    let _e1125 = pTrans;
    let _e1128 = pSpec;
    let _e1129 = pdfSpec;
    let _e1131 = pSpec;
    let _e1133 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1120 * _e1121) + (((1f - _e1123) * (1f - _e1125)) * ((_e1128 * _e1129) + ((1f - _e1131) * _e1133)))), 0.000001f);
    let _e1139 = (*pW_13);
    param_732 = _e1139;
    let _e1140 = (*basis_15);
    param_733 = _e1140;
    let _e1141 = (*winputL_8);
    param_734 = _e1141;
    let _e1142 = (*woutputL_11);
    param_735 = _e1142;
    let _e1143 = ignorePdf;
    param_736 = _e1143;
    let _e1144 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_732), (&param_733), (&param_734), (&param_735), (&param_736));
    let _e1145 = param_736;
    ignorePdf = _e1145;
    return _e1144;
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

    let _e348 = (*surfaceshader_4);
    if (_e348 == 1i) {
        let _e350 = (*pW_14);
        param_737 = _e350;
        let _e351 = (*basis_16);
        param_738 = _e351;
        let _e352 = (*winputL_9);
        param_739 = _e352;
        let _e353 = (*rndSeed_10);
        param_740 = _e353;
        let _e354 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_737), (&param_738), (&param_739), (&param_740), (&param_741), (&param_742), (&param_743));
        let _e355 = param_740;
        (*rndSeed_10) = _e355;
        let _e356 = param_741;
        (*woutputL_12) = _e356;
        let _e357 = param_742;
        (*pdf_woutputL_7) = _e357;
        let _e358 = param_743;
        (*internal_medium_1) = _e358;
        return _e354;
    } else {
        let _e359 = (*surfaceshader_4);
        if (_e359 == 2i) {
            let _e361 = (*pW_14);
            param_744 = _e361;
            let _e362 = (*basis_16);
            param_745 = _e362;
            let _e363 = (*winputL_9);
            param_746 = _e363;
            let _e364 = (*rndSeed_10);
            param_747 = _e364;
            let _e365 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_744), (&param_745), (&param_746), (&param_747), (&param_748), (&param_749));
            let _e366 = param_747;
            (*rndSeed_10) = _e366;
            let _e367 = param_748;
            (*woutputL_12) = _e367;
            let _e368 = param_749;
            (*pdf_woutputL_7) = _e368;
            return _e365;
        } else {
            let _e369 = (*pW_14);
            param_750 = _e369;
            let _e370 = (*basis_16);
            param_751 = _e370;
            let _e371 = (*winputL_9);
            param_752 = _e371;
            let _e372 = (*rndSeed_10);
            param_753 = _e372;
            let _e373 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755));
            let _e374 = param_753;
            (*rndSeed_10) = _e374;
            let _e375 = param_754;
            (*woutputL_12) = _e375;
            let _e376 = param_755;
            (*pdf_woutputL_7) = _e376;
            return _e373;
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
    let _e321 = ior_7;
    return max(_e321, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e321 = roughness_18;
    return clamp(_e321, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    return 0f;
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e321 = transmission_1;
    return clamp(_e321, 0f, 1f);
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

    let _e338 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e338) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e340 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e340 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e342 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e342 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e344 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e344 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e347 = (*winputL_10)[2u];
    cosI = clamp(abs(_e347), 0.0001f, 1f);
    let _e350 = mtlx_openpbr_specular_ior_u0028_();
    let _e352 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e353 = mtlx_openpbr_thin_film_ior_u0028_();
    param_756 = max(_e350, 1.001f);
    param_757 = _e352;
    param_758 = _e353;
    let _e354 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_756), (&param_757), (&param_758));
    fd_11 = _e354;
    let _e355 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e356 = cosI;
    param_759 = _e356;
    let _e357 = fd_11;
    param_760 = _e357;
    let _e358 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_759), (&param_760));
    F_4 = (_e358 * _e355);
    let _e360 = (*winputL_10);
    reflectedL = reflect(-(_e360), vec3<f32>(0f, 0f, 1f));
    let _e364 = reflectedL[2u];
    if (_e364 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e366 = reflectedL;
    param_761 = _e366;
    let _e367 = (*basis_17);
    param_762 = _e367;
    let _e368 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_761), (&param_762));
    reflectedW = _e368;
    let _e369 = reflectedW;
    param_763 = _e369;
    let _e370 = sunRadiance_u0028_vf3_u003b((&param_763));
    let _e371 = reflectedW;
    param_764 = _e371;
    let _e372 = skyRadiance_u0028_vf3_u003b((&param_764));
    envRadiance = (_e370 + _e372);
    let _e374 = envRadiance;
    let _e376 = unnamed.skyPower;
    let _e379 = unnamed.skyColor;
    envRadiance = max(_e374, (_e379 * (0.25f * _e376)));
    let _e382 = F_4;
    let _e383 = envRadiance;
    return (_e382 * _e383);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_765: vec3<f32>;
    var param_766: vec3<f32>;

    let _e328 = (*nW);
    param_765 = _e328;
    let _e329 = safe_normalize_u0028_vf3_u003b((&param_765));
    basis_18.nW = _e329;
    let _e331 = (*tW);
    param_766 = _e331;
    let _e332 = safe_normalize_u0028_vf3_u003b((&param_766));
    basis_18.tW = _e332;
    let _e335 = basis_18.nW;
    let _e337 = basis_18.tW;
    basis_18.bW = cross(_e335, _e337);
    let _e340 = (*baryCoord_2);
    basis_18.baryCoord = _e340;
    let _e342 = (*texCoord_2);
    basis_18.texCoord = _e342;
    let _e344 = basis_18;
    return _e344;
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
    var phi_8393_: bool;

    let _e339 = (*shadowW_1);
    param_767 = _e339;
    let _e340 = (*basis_19);
    param_768 = _e340;
    let _e341 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_767), (&param_768));
    shadowL_1 = _e341;
    let _e342 = shadowL_1;
    param_769 = _e342;
    let _e343 = (*shadowW_1);
    param_770 = _e343;
    let _e344 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_769), (&param_770));
    pdf_sky_1 = _e344;
    let _e345 = shadowL_1;
    param_771 = _e345;
    let _e346 = (*shadowW_1);
    param_772 = _e346;
    let _e347 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_771), (&param_772));
    pdf_sun_1 = _e347;
    let _e349 = unnamed.mtlxDisableSun;
    let _e350 = (_e349 != 0u);
    phi_8393_ = _e350;
    if !(_e350) {
        let _e353 = unnamed.mtlxLightCount;
        phi_8393_ = (_e353 > 0i);
    }
    let _e356 = phi_8393_;
    if _e356 {
        local_18 = 0f;
    } else {
        let _e357 = sunTotalPower_u0028_();
        local_18 = _e357;
    }
    let _e358 = local_18;
    w_sun_1 = _e358;
    let _e359 = skyTotalPower_u0028_();
    w_sky_1 = _e359;
    let _e360 = w_sun_1;
    let _e361 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e360 + _e361));
    let _e364 = w_sun_1;
    let _e365 = w_total_1;
    P_sun_1 = (_e364 / _e365);
    let _e367 = w_sky_1;
    let _e368 = w_total_1;
    P_sky_1 = (_e367 / _e368);
    let _e370 = P_sun_1;
    let _e371 = pdf_sun_1;
    let _e373 = P_sky_1;
    let _e374 = pdf_sky_1;
    lightPdf_1 = ((_e370 * _e371) + (_e373 * _e374));
    let _e377 = lightPdf_1;
    return _e377;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_773: vec3<f32>;
    var param_774: vec3<f32>;

    let _e325 = (*nW_1);
    param_773 = _e325;
    let _e326 = safe_normalize_u0028_vf3_u003b((&param_773));
    basis_20.nW = _e326;
    let _e328 = (*nW_1);
    param_774 = _e328;
    let _e329 = normalToTangent_u0028_vf3_u003b((&param_774));
    basis_20.tW = _e329;
    let _e332 = basis_20.nW;
    let _e334 = basis_20.tW;
    basis_20.bW = cross(_e332, _e334);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e339 = basis_20;
    return _e339;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e331 = (*cameraWorld);
    lookDirection = (_e331 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e333 = (*inverseProjection);
    nearVector = (_e333 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e336 = nearVector[2u];
    let _e338 = nearVector[3u];
    nearDistance_1 = abs((_e336 / _e338));
    let _e341 = (*cameraWorld);
    origin_1 = (_e341 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e343 = (*inverseProjection);
    let _e344 = (*coordinate);
    direction_1 = (_e343 * vec4<f32>(_e344.x, _e344.y, 0.5f, 1f));
    let _e350 = direction_1[3u];
    let _e351 = direction_1;
    direction_1 = (_e351 / vec4(_e350));
    let _e354 = (*cameraWorld);
    let _e355 = direction_1;
    let _e357 = origin_1;
    direction_1 = ((_e354 * _e355) - _e357);
    let _e359 = direction_1;
    let _e361 = nearDistance_1;
    let _e363 = direction_1;
    let _e364 = lookDirection;
    let _e368 = origin_1;
    let _e370 = (_e368.xyz + ((_e359.xyz * _e361) / vec3(dot(_e363, _e364))));
    origin_1[0u] = _e370.x;
    origin_1[1u] = _e370.y;
    origin_1[2u] = _e370.z;
    let _e377 = origin_1;
    (*rayOrigin_4) = _e377.xyz;
    let _e379 = direction_1;
    (*rayDirection_2) = _e379.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_19: f32;

    let _e323 = (*xi_1);
    if (_e323 < 0.5f) {
        let _e325 = (*xi_1);
        local_19 = (sqrt((2f * _e325)) - 1f);
    } else {
        let _e329 = (*xi_1);
        local_19 = (1f - sqrt((2f - (2f * _e329))));
    }
    let _e334 = local_19;
    return _e334;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e322 = (*seed_1);
    let _e325 = (*seed_1);
    (*seed_1) = (_e325 ^ (_e322 << bitcast<u32>(13u)));
    let _e327 = (*seed_1);
    let _e330 = (*seed_1);
    (*seed_1) = (_e330 ^ (_e327 >> bitcast<u32>(17u)));
    let _e332 = (*seed_1);
    let _e335 = (*seed_1);
    (*seed_1) = (_e335 ^ (_e332 << bitcast<u32>(5u)));
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
    var phi_8728_: bool;
    var phi_8740_: bool;
    var phi_8741_: bool;
    var phi_8774_: bool;
    var phi_8781_: bool;
    var phi_8912_: bool;
    var phi_9003_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_color_1 = vec3<f32>(1f, 1f, 1f);
    metallic_1 = 0f;
    roughness_18 = 0.01f;
    occlusion_3 = 1f;
    transmission_1 = 1f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    ior_7 = 1.52f;
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
    let _e462 = gl_FragCoord_1;
    frag = _e462.xy;
    let _e465 = frag[0u];
    let _e467 = frag[1u];
    let _e470 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e465 + (_e467 * _e470)));
    let _e474 = rndSeed_11;
    param_775 = _e474;
    xorshift_u0028_u1_u003b((&param_775));
    let _e475 = param_775;
    rndSeed_11 = _e475;
    let _e477 = unnamed.samples;
    let _e479 = rndSeed_11;
    rndSeed_11 = (_e479 ^ u32(_e477));
    let _e481 = rndSeed_11;
    param_776 = _e481;
    let _e482 = rand_u0028_u1_u003b((&param_776));
    let _e483 = param_776;
    rndSeed_11 = _e483;
    param_777 = _e482;
    let _e484 = sample_triangle_filter_u0028_f1_u003b((&param_777));
    jx = (0.5f * _e484);
    let _e486 = rndSeed_11;
    param_778 = _e486;
    let _e487 = rand_u0028_u1_u003b((&param_778));
    let _e488 = param_778;
    rndSeed_11 = _e488;
    param_779 = _e487;
    let _e489 = sample_triangle_filter_u0028_f1_u003b((&param_779));
    jy = (0.5f * _e489);
    let _e491 = frag;
    let _e492 = jx;
    let _e493 = jy;
    pixel = (_e491 + vec2<f32>(_e492, _e493));
    let _e496 = pixel;
    let _e498 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e496 / _e498) * 2f));
    let _e504 = unnamed.invModelMatrix;
    let _e506 = unnamed.cameraWorldMatrix;
    let _e508 = ndc;
    param_780 = _e508;
    param_781 = (_e504 * _e506);
    let _e510 = unnamed.invProjectionMatrix;
    param_782 = _e510;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_780), (&param_781), (&param_782), (&param_783), (&param_784));
    let _e511 = param_783;
    pW_15 = _e511;
    let _e512 = param_784;
    dW = _e512;
    let _e513 = dW;
    dW = normalize(_e513);
    let _e516 = unnamed.sunDir;
    param_785 = _e516;
    let _e517 = makeBasis_u0028_vf3_u003b((&param_785));
    sunBasis = _e517;
    L_8 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e518 = vertex;
        let _e520 = unnamed.bounces;
        if (_e518 <= _e520) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e522 = inside_scattering_volume;
            if !(_e522) {
                let _e524 = pW_15;
                param_786 = _e524;
                let _e525 = dW;
                param_787 = _e525;
                param_788 = 100000000000000000000f;
                let _e526 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_786), (&param_787), (&param_788), (&param_789), (&param_790), (&param_791), (&param_792), (&param_793), (&param_794), (&param_795));
                let _e527 = param_789;
                pW_next = _e527;
                let _e528 = param_790;
                NsW_next = _e528;
                let _e529 = param_791;
                NgW_next = _e529;
                let _e530 = param_792;
                TsW_next = _e530;
                let _e531 = param_793;
                baryCoord_next = _e531;
                let _e532 = param_794;
                texCoord_next = _e532;
                let _e533 = param_795;
                material_next = _e533;
                surface_hit = _e526;
            }
            let _e534 = surface_hit;
            if !(_e534) {
                misWeightLight = 1f;
                let _e536 = vertex;
                let _e538 = inside_scattering_volume;
                if ((_e536 > 0i) && !(_e538)) {
                    let _e541 = dW;
                    param_796 = _e541;
                    let _e542 = basis_21;
                    param_797 = _e542;
                    let _e543 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_796), (&param_797));
                    lightPdf_2 = _e543;
                    let _e544 = bsdfPdf_continuation;
                    let _e545 = lightPdf_2;
                    let _e546 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e544, _e545);
                    misWeightLight = _e546;
                }
                let _e547 = throughput;
                let _e548 = misWeightLight;
                let _e550 = dW;
                param_798 = _e550;
                let _e551 = sunRadiance_u0028_vf3_u003b((&param_798));
                let _e552 = dW;
                param_799 = _e552;
                let _e553 = skyRadiance_u0028_vf3_u003b((&param_799));
                Lenv = ((_e547 * _e548) * (_e551 + _e553));
                let _e556 = Lenv;
                param_800 = _e556;
                let _e557 = maxComponent_u0028_vf3_u003b((&param_800));
                maxLenv = _e557;
                let _e558 = maxLenv;
                let _e560 = unnamed.firefly_clamp;
                if (_e558 > _e560) {
                    let _e563 = unnamed.firefly_clamp;
                    let _e564 = maxLenv;
                    let _e566 = Lenv;
                    Lenv = (_e566 * (_e563 / _e564));
                }
                let _e568 = Lenv;
                let _e569 = L_8;
                L_8 = (_e569 + _e568);
                break;
            }
            let _e571 = vertex;
            let _e573 = unnamed.bounces;
            if (_e571 == _e573) {
                break;
            }
            let _e575 = pW_next;
            pW_15 = _e575;
            let _e576 = NsW_next;
            NsW = _e576;
            let _e577 = NgW_next;
            NgW = _e577;
            let _e578 = TsW_next;
            TsW_1 = _e578;
            let _e579 = baryCoord_next;
            baryCoord_3 = _e579;
            let _e580 = texCoord_next;
            texCoord_3 = _e580;
            let _e581 = material_next;
            surfaceshader_5 = _e581;
            let _e582 = surfaceshader_5;
            if (_e582 == 1i) {
                let _e584 = in_dielectric;
                phi_8728_ = _e584;
                if _e584 {
                    let _e585 = NsW;
                    let _e586 = dW;
                    phi_8728_ = (dot(_e585, _e586) < 0f);
                }
                let _e590 = phi_8728_;
                phi_8741_ = _e590;
                if !(_e590) {
                    let _e592 = in_dielectric;
                    let _e593 = !(_e592);
                    phi_8740_ = _e593;
                    if _e593 {
                        let _e594 = NsW;
                        let _e595 = dW;
                        phi_8740_ = (dot(_e594, _e595) > 0f);
                    }
                    let _e599 = phi_8740_;
                    phi_8741_ = _e599;
                }
                let _e601 = phi_8741_;
                if _e601 {
                    let _e602 = NsW;
                    NsW = (_e602 * -1f);
                }
            } else {
                let _e604 = NsW;
                let _e605 = dW;
                if (dot(_e604, _e605) > 0f) {
                    let _e608 = NsW;
                    NsW = (_e608 * -1f);
                }
            }
            let _e610 = NgW;
            let _e611 = NsW;
            if (dot(_e610, _e611) < 0f) {
                let _e614 = NgW;
                NgW = (_e614 * -1f);
            }
            let _e617 = unnamed.smooth_normals;
            if (_e617 != 0u) {
                let _e619 = surfaceshader_5;
                let _e620 = (_e619 == 1i);
                phi_8774_ = _e620;
                if _e620 {
                    let _e621 = mtlx_openpbr_is_opaque_u0028_();
                    phi_8774_ = _e621;
                }
                let _e623 = phi_8774_;
                phi_8781_ = _e623;
                if _e623 {
                    let _e624 = NsW;
                    let _e625 = dW;
                    phi_8781_ = (dot(_e624, _e625) > 0f);
                }
                let _e629 = phi_8781_;
                if _e629 {
                    let _e630 = NgW;
                    let _e632 = NgW;
                    let _e633 = NsW;
                    let _e636 = NsW;
                    NsW = (((_e630 * 2f) * dot(_e632, _e633)) - _e636);
                }
                let _e638 = NsW;
                param_801 = _e638;
                let _e639 = TsW_next;
                param_802 = _e639;
                let _e640 = baryCoord_3;
                param_803 = _e640;
                let _e641 = texCoord_3;
                param_804 = _e641;
                let _e642 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_801), (&param_802), (&param_803), (&param_804));
                basis_21 = _e642;
            } else {
                let _e643 = NgW;
                param_805 = _e643;
                let _e644 = TsW_next;
                param_806 = _e644;
                let _e645 = baryCoord_3;
                param_807 = _e645;
                let _e646 = texCoord_3;
                param_808 = _e646;
                let _e647 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_805), (&param_806), (&param_807), (&param_808));
                basis_21 = _e647;
            }
            let _e648 = dW;
            winputW = -(_e648);
            let _e650 = winputW;
            param_809 = _e650;
            let _e651 = basis_21;
            param_810 = _e651;
            let _e652 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_809), (&param_810));
            winputL_11 = _e652;
            let _e654 = winputL_11[2u];
            if (abs(_e654) < 0.001f) {
                break;
            }
            thin_walled = false;
            let _e657 = surfaceshader_5;
            if (_e657 == 1i) {
                let _e659 = pW_15;
                param_811 = _e659;
                let _e660 = basis_21;
                param_812 = _e660;
                let _e661 = winputL_11;
                param_813 = _e661;
                let _e662 = rndSeed_11;
                param_814 = _e662;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_811), (&param_812), (&param_813), (&param_814));
                let _e663 = param_814;
                rndSeed_11 = _e663;
                let _e664 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled = _e664;
            }
            let _e665 = surfaceshader_5;
            if (_e665 == 1i) {
                let _e667 = throughput;
                let _e668 = basis_21;
                param_815 = _e668;
                let _e669 = winputL_11;
                param_816 = _e669;
                let _e670 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_815), (&param_816));
                Ltf = (_e667 * _e670);
                let _e672 = Ltf;
                param_817 = _e672;
                let _e673 = maxComponent_u0028_vf3_u003b((&param_817));
                maxLtf = _e673;
                let _e674 = maxLtf;
                let _e676 = unnamed.firefly_clamp;
                if (_e674 > _e676) {
                    let _e679 = unnamed.firefly_clamp;
                    let _e680 = maxLtf;
                    let _e682 = Ltf;
                    Ltf = (_e682 * (_e679 / _e680));
                }
                let _e684 = Ltf;
                let _e685 = L_8;
                L_8 = (_e685 + _e684);
            }
            let _e687 = pW_15;
            param_818 = _e687;
            let _e688 = basis_21;
            param_819 = _e688;
            let _e689 = winputL_11;
            param_820 = _e689;
            let _e690 = rndSeed_11;
            param_821 = _e690;
            let _e691 = surfaceshader_5;
            param_822 = _e691;
            let _e692 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_818), (&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825));
            let _e693 = param_821;
            rndSeed_11 = _e693;
            let _e694 = param_823;
            woutputL_13 = _e694;
            let _e695 = param_824;
            bsdfPdf_continuation = _e695;
            let _e696 = param_825;
            internal_medium_2 = _e696;
            f_1 = _e692;
            let _e697 = woutputL_13;
            param_826 = _e697;
            let _e698 = basis_21;
            param_827 = _e698;
            let _e699 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_826), (&param_827));
            woutputW_7 = _e699;
            let _e700 = surfaceshader_5;
            let _e701 = (_e700 == 1i);
            phi_8912_ = _e701;
            if _e701 {
                let _e703 = winputL_11[2u];
                let _e705 = woutputL_13[2u];
                phi_8912_ = ((_e703 * _e705) < 0f);
            }
            let _e709 = phi_8912_;
            transmitted_sample = _e709;
            let _e710 = surfaceshader_5;
            let _e712 = transmitted_sample;
            if ((_e710 == 1i) && !(_e712)) {
                local_20 = 1f;
            } else {
                let _e715 = woutputW_7;
                let _e717 = basis_21.nW;
                local_20 = abs(dot(_e715, _e717));
            }
            let _e720 = local_20;
            cos_out = _e720;
            let _e721 = f_1;
            let _e722 = bsdfPdf_continuation;
            let _e726 = cos_out;
            surface_throughput = ((_e721 / vec3(max(0.000001f, _e722))) * _e726);
            let _e728 = surface_throughput;
            param_828 = _e728;
            let _e729 = maxComponent_u0028_vf3_u003b((&param_828));
            maxComp = _e729;
            let _e730 = maxComp;
            let _e732 = unnamed.firefly_clamp;
            if (_e730 > _e732) {
                let _e735 = unnamed.firefly_clamp;
                let _e736 = maxComp;
                let _e738 = surface_throughput;
                surface_throughput = (_e738 * (_e735 / _e736));
            }
            let _e740 = woutputW_7;
            dW = _e740;
            let _e741 = surfaceshader_5;
            if (_e741 == 1i) {
                let _e743 = throughput;
                let _e744 = pW_15;
                param_829 = _e744;
                let _e745 = basis_21;
                param_830 = _e745;
                let _e746 = winputL_11;
                param_831 = _e746;
                let _e747 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_829), (&param_830), (&param_831));
                Le = (_e743 * _e747);
                let _e749 = Le;
                param_832 = _e749;
                let _e750 = maxComponent_u0028_vf3_u003b((&param_832));
                maxLe = _e750;
                let _e751 = maxLe;
                let _e753 = unnamed.firefly_clamp;
                if (_e751 > _e753) {
                    let _e756 = unnamed.firefly_clamp;
                    let _e757 = maxLe;
                    let _e759 = Le;
                    Le = (_e759 * (_e756 / _e757));
                }
                let _e761 = Le;
                let _e762 = L_8;
                L_8 = (_e762 + _e761);
            }
            let _e764 = thin_walled;
            let _e766 = surfaceshader_5;
            let _e768 = (!(_e764) && (_e766 == 1i));
            phi_9003_ = _e768;
            if _e768 {
                let _e769 = winputW;
                let _e770 = NgW;
                let _e772 = dW;
                let _e773 = NgW;
                phi_9003_ = ((dot(_e769, _e770) * dot(_e772, _e773)) < 0f);
            }
            let _e778 = phi_9003_;
            transmitted = _e778;
            let _e779 = transmitted;
            if _e779 {
                let _e780 = in_dielectric;
                in_dielectric = !(_e780);
            }
            let _e782 = in_dielectric;
            let _e784 = transmitted;
            if (!(_e782) && !(_e784)) {
                let _e787 = pW_15;
                param_833 = _e787;
                let _e788 = basis_21;
                param_834 = _e788;
                let _e789 = rndSeed_11;
                param_838 = _e789;
                let _e790 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_833), (&param_834), (&param_835), (&param_836), (&param_837), (&param_838));
                let _e791 = param_835;
                shadowL_2 = _e791;
                let _e792 = param_836;
                shadowW_2 = _e792;
                let _e793 = param_837;
                lightPdf_3 = _e793;
                let _e794 = param_838;
                rndSeed_11 = _e794;
                Li_6 = _e790;
                let _e795 = Li_6;
                param_839 = _e795;
                let _e796 = maxComponent_u0028_vf3_u003b((&param_839));
                if (_e796 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e798 = pW_15;
                    param_840 = _e798;
                    let _e799 = basis_21;
                    param_841 = _e799;
                    let _e800 = winputL_11;
                    param_842 = _e800;
                    let _e801 = shadowL_2;
                    param_843 = _e801;
                    let _e802 = surfaceshader_5;
                    param_844 = _e802;
                    let _e803 = bsdfPdf_shadow;
                    param_845 = _e803;
                    let _e804 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844), (&param_845));
                    let _e805 = param_845;
                    bsdfPdf_shadow = _e805;
                    fshadow = _e804;
                    let _e806 = lightPdf_3;
                    let _e807 = bsdfPdf_shadow;
                    let _e808 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e806, _e807);
                    misWeightLight_1 = _e808;
                    let _e809 = surfaceshader_5;
                    if (_e809 == 1i) {
                        local_21 = 1f;
                    } else {
                        let _e811 = shadowW_2;
                        let _e813 = basis_21.nW;
                        local_21 = abs(dot(_e811, _e813));
                    }
                    let _e816 = local_21;
                    cos_shadow = _e816;
                    let _e817 = misWeightLight_1;
                    let _e818 = fshadow;
                    let _e820 = cos_shadow;
                    let _e822 = Li_6;
                    let _e824 = lightPdf_3;
                    Ld = ((((_e818 * _e817) * _e820) * _e822) / vec3(max(0.000001f, _e824)));
                    let _e828 = throughput;
                    let _e829 = Ld;
                    Lcontrib = (_e828 * _e829);
                    let _e831 = Lcontrib;
                    param_846 = _e831;
                    let _e832 = maxComponent_u0028_vf3_u003b((&param_846));
                    maxLcontrib = _e832;
                    let _e833 = maxLcontrib;
                    let _e835 = unnamed.firefly_clamp;
                    if (_e833 > _e835) {
                        let _e838 = unnamed.firefly_clamp;
                        let _e839 = maxLcontrib;
                        let _e841 = Lcontrib;
                        Lcontrib = (_e841 * (_e838 / _e839));
                    }
                    let _e843 = Lcontrib;
                    let _e844 = L_8;
                    L_8 = (_e844 + _e843);
                }
            }
            let _e846 = NgW;
            let _e847 = dW;
            let _e848 = NgW;
            let _e853 = pW_15;
            pW_15 = (_e853 + ((_e846 * sign(dot(_e847, _e848))) * 0.0001f));
            let _e855 = surface_throughput;
            let _e856 = throughput;
            throughput = (_e856 * _e855);
            let _e858 = throughput;
            param_847 = _e858;
            let _e859 = maxComponent_u0028_vf3_u003b((&param_847));
            maxTP = _e859;
            let _e860 = maxTP;
            let _e862 = unnamed.firefly_clamp;
            if (_e860 > _e862) {
                let _e865 = unnamed.firefly_clamp;
                let _e866 = maxTP;
                let _e868 = throughput;
                throughput = (_e868 * (_e865 / _e866));
            }
            let _e870 = throughput;
            param_848 = _e870;
            let _e871 = maxComponent_u0028_vf3_u003b((&param_848));
            let _e873 = vertex;
            if ((_e871 < 1f) && (_e873 > 1i)) {
                let _e876 = throughput;
                param_849 = _e876;
                let _e877 = maxComponent_u0028_vf3_u003b((&param_849));
                q = max(0f, (1f - _e877));
                let _e880 = rndSeed_11;
                param_850 = _e880;
                let _e881 = rand_u0028_u1_u003b((&param_850));
                let _e882 = param_850;
                rndSeed_11 = _e882;
                let _e883 = q;
                if (_e881 < _e883) {
                    break;
                }
                let _e885 = q;
                let _e887 = throughput;
                throughput = (_e887 / vec3((1f - _e885)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e890 = vertex;
            vertex = (_e890 + 1i);
        }
    }
    let _e892 = L_8;
    mtlxFragmentColor[0u] = _e892.x;
    mtlxFragmentColor[1u] = _e892.y;
    mtlxFragmentColor[2u] = _e892.z;
    let _e900 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e900;
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
