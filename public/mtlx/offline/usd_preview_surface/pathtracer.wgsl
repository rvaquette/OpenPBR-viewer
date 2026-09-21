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
var<private> base_3: f32;
var<private> base_color_1: vec3<f32>;
var<private> diffuse_roughness_1: f32;
var<private> metalness_1: f32;
var<private> specular_1: f32;
var<private> specular_color_1: vec3<f32>;
var<private> specular_roughness_1: f32;
var<private> specular_IOR_1: f32;
var<private> specular_anisotropy_1: f32;
var<private> specular_rotation_1: f32;
var<private> transmission_1: f32;
var<private> transmission_color_1: vec3<f32>;
var<private> transmission_depth_1: f32;
var<private> transmission_scatter_1: vec3<f32>;
var<private> transmission_scatter_anisotropy_1: f32;
var<private> transmission_dispersion_1: f32;
var<private> transmission_extra_roughness_1: f32;
var<private> subsurface_1: f32;
var<private> subsurface_color_1: vec3<f32>;
var<private> subsurface_radius_1: vec3<f32>;
var<private> subsurface_scale_1: f32;
var<private> subsurface_anisotropy_1: f32;
var<private> sheen_1: f32;
var<private> sheen_color_1: vec3<f32>;
var<private> sheen_roughness_1: f32;
var<private> coat_1: f32;
var<private> coat_color_1: vec3<f32>;
var<private> coat_roughness_1: f32;
var<private> coat_anisotropy_1: f32;
var<private> coat_rotation_1: f32;
var<private> coat_IOR_1: f32;
var<private> coat_affect_color_1: f32;
var<private> coat_affect_roughness_1: f32;
var<private> thin_film_thickness_1: f32;
var<private> thin_film_IOR_1: f32;
var<private> emission_1: f32;
var<private> emission_color_1: vec3<f32>;
var<private> opacity_1: vec3<f32>;
var<private> thin_walled_2: bool;
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
    let _e342 = (*v)[0u];
    let _e344 = (*v)[1u];
    let _e346 = (*v)[2u];
    return min(_e342, min(_e344, _e346));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e342 = (*wiL)[2u];
    if (_e342 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e345 = (*wiL)[2u];
    return (_e345 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_7513_: bool;
    var phi_7531_: bool;

    let _e348 = (*winputL)[2u];
    let _e349 = (_e348 < 0.0000000001f);
    phi_7513_ = _e349;
    if !(_e349) {
        let _e352 = (*woutputL)[2u];
        phi_7513_ = (_e352 < 0.0000000001f);
    }
    let _e355 = phi_7513_;
    if _e355 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e356 = (*woutputL);
    param = _e356;
    let _e357 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e357;
    let _e359 = unnamed.wireframe;
    let _e360 = (_e359 != 0u);
    phi_7531_ = _e360;
    if _e360 {
        let _e362 = (*basis).baryCoord;
        param_1 = _e362;
        let _e363 = minComponent_u0028_vf3_u003b((&param_1));
        phi_7531_ = (_e363 < 0.003f);
    }
    let _e366 = phi_7531_;
    if _e366 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e368 = unnamed.neutral_color;
    return (_e368 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e343 = (*pW_1)[0u];
    let _e345 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e343, -(_e345)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e353 = uv;
    let _e354 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e353, 0.0);
    return _e354.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_7606_: bool;

    let _e348 = (*winputL_1)[2u];
    let _e349 = (_e348 < 0.0000000001f);
    phi_7606_ = _e349;
    if !(_e349) {
        let _e352 = (*woutputL_1)[2u];
        phi_7606_ = (_e352 < 0.0000000001f);
    }
    let _e355 = phi_7606_;
    if _e355 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e356 = (*woutputL_1);
    param_2 = _e356;
    let _e357 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e357;
    let _e358 = (*pW_2);
    param_3 = _e358;
    let _e359 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e359 / vec3(3.1415927f));
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e345 = (*bg);
    let _e346 = (*fg);
    let _e347 = (*mixValue);
    (*result) = mix(_e345, _e346, vec3(_e347));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e345 = (*cosTheta);
    x = clamp((1f - _e345), 0f, 1f);
    let _e348 = (*F0_);
    let _e349 = (*F90_);
    let _e350 = x;
    let _e351 = (*exponent);
    return mix(_e348, _e349, vec3(pow(_e350, _e351)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e343 = (*N);
    let _e344 = (*V);
    if (dot(_e343, _e344) < 0f) {
        let _e347 = (*N);
        local = -(_e347);
    } else {
        let _e349 = (*N);
        local = _e349;
    }
    let _e350 = local;
    return _e350;
}

fn mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(closureData_1: ptr<function, ClosureData>, color0_: ptr<function, vec3<f32>>, color90_: ptr<function, vec3<f32>>, exponent_1: ptr<function, f32>, base: ptr<function, vec3<f32>>, result_1: ptr<function, vec3<f32>>) {
    var N_1: vec3<f32>;
    var param_4: vec3<f32>;
    var param_5: vec3<f32>;
    var NdotV: f32;
    var f: vec3<f32>;
    var param_6: f32;
    var param_7: vec3<f32>;
    var param_8: vec3<f32>;
    var param_9: f32;

    let _e356 = (*closureData_1).closureType;
    if (_e356 == 4i) {
        let _e359 = (*closureData_1).N;
        param_4 = _e359;
        let _e361 = (*closureData_1).V;
        param_5 = _e361;
        let _e362 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_4), (&param_5));
        N_1 = _e362;
        let _e363 = N_1;
        let _e365 = (*closureData_1).V;
        NdotV = clamp(dot(_e363, _e365), 0.00000001f, 1f);
        let _e368 = NdotV;
        param_6 = _e368;
        let _e369 = (*color0_);
        param_7 = _e369;
        let _e370 = (*color90_);
        param_8 = _e370;
        let _e371 = (*exponent_1);
        param_9 = _e371;
        let _e372 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_6), (&param_7), (&param_8), (&param_9));
        f = _e372;
        let _e373 = (*base);
        let _e374 = f;
        (*result_1) = (_e373 * _e374);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e344 = (*in1_);
    let _e345 = (*in2_);
    (*result_2) = (_e344 * _e345);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e344 = (*closureData_3).closureType;
    if (_e344 == 4i) {
        let _e346 = (*color);
        (*result_3) = _e346;
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_4: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e345 = (*in2_1);
    tint = clamp(_e345, vec3(0f), vec3(1f));
    let _e350 = (*in1_1).response;
    let _e351 = tint;
    (*result_4).response = (_e350 * _e351);
    let _e355 = (*in1_1).throughput;
    (*result_4).throughput = _e355;
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_5: ptr<function, BSDF>) {
    let _e345 = (*top).response;
    let _e347 = (*base_1).response;
    let _e349 = (*top).throughput;
    (*result_5).response = (_e345 + (_e347 * _e349));
    let _e354 = (*top).throughput;
    let _e356 = (*base_1).throughput;
    (*result_5).throughput = (_e354 * _e356);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e344 = (*dir)[1u];
    latitude = ((-(asin(_e344)) * 0.31830987f) + 0.5f);
    let _e350 = (*dir)[0u];
    let _e352 = (*dir)[2u];
    longitude = (((atan2(_e350, -(_e352)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e358 = longitude;
    let _e359 = latitude;
    return vec2<f32>(_e358, _e359);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e342 = (*m);
    let _e343 = (*v_1);
    return (_e342 * _e343);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_12: vec3<f32>;

    let _e348 = (*dir_1);
    let _e353 = (*transform);
    param_10 = _e353;
    param_11 = vec4<f32>(_e348.x, _e348.y, _e348.z, 0f);
    let _e354 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_10), (&param_11));
    envDir = normalize(_e354.xyz);
    let _e357 = envDir;
    param_12 = _e357;
    let _e358 = mx_latlong_projection_u0028_vf3_u003b((&param_12));
    uv_1 = _e358;
    let _e359 = uv_1;
    let _e360 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e359, 0.0);
    return _e360.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e343 = a;
    c = cos(_e343);
    let _e345 = a;
    s = sin(_e345);
    let _e347 = c;
    let _e348 = s;
    let _e350 = s;
    let _e351 = c;
    return mat4x4<f32>(vec4<f32>(_e347, 0f, -(_e348), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e350, 0f, _e351, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_13: vec3<f32>;
    var param_14: mat4x4<f32>;
    var param_15: f32;

    let _e345 = mtlxEnvMatrix_u0028_();
    let _e346 = (*N_2);
    param_13 = _e346;
    param_14 = _e345;
    param_15 = 0f;
    let _e347 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_13), (&param_14), (&param_15));
    Li = _e347;
    let _e348 = Li;
    let _e350 = unnamed.skyPower;
    return (_e348 * _e350);
}

fn mx_square_u0028_f1_u003b(x_1: ptr<function, f32>) -> f32 {
    let _e341 = (*x_1);
    let _e342 = (*x_1);
    return (_e341 * _e342);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_16: f32;

    let _e344 = (*roughness);
    let _e347 = (*NdotV_1);
    let _e349 = (*roughness);
    let _e352 = (*roughness);
    param_16 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_16));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e344)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e347) * _e349)) + (vec2<f32>(1.4385f, 2.0315f) * _e353));
    let _e357 = r[0u];
    let _e359 = r[1u];
    return (_e357 / _e359);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_17: f32;
    var param_18: f32;

    let _e345 = (*NdotV_2);
    param_17 = _e345;
    let _e346 = (*roughness_1);
    param_18 = _e346;
    let _e347 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_17), (&param_18));
    dirAlbedo = _e347;
    let _e348 = dirAlbedo;
    return clamp(_e348, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e341 = (*x_2);
    let _e342 = (*x_2);
    return (_e341 * _e342);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e342 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e342)));
    let _e346 = A;
    let _e347 = (*roughness_2);
    return (_e346 * (1f + (0.07248821f * _e347)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_19: f32;
    var G: f32;

    let _e347 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e347)));
    let _e351 = (*roughness_3);
    let _e352 = A_1;
    B = (_e351 * _e352);
    let _e354 = (*cosTheta_1);
    param_19 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_19));
    Si = sqrt(max(0f, (1f - _e355)));
    let _e359 = Si;
    let _e360 = (*cosTheta_1);
    let _e363 = Si;
    let _e364 = (*cosTheta_1);
    let _e368 = Si;
    let _e369 = (*cosTheta_1);
    let _e371 = Si;
    let _e372 = Si;
    let _e374 = Si;
    let _e378 = Si;
    G = ((_e359 * (acos(clamp(_e360, -1f, 1f)) - (_e363 * _e364))) + ((2f * (((_e368 / _e369) * (1f - ((_e371 * _e372) * _e374))) - _e378)) / 3f));
    let _e383 = A_1;
    let _e384 = B;
    let _e385 = G;
    return (_e383 + ((_e384 * _e385) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_20: f32;
    var param_21: f32;
    var avgAlbedo: f32;
    var param_22: f32;
    var colorMultiScatter: vec3<f32>;
    var param_23: vec3<f32>;

    let _e350 = (*cosTheta_2);
    param_20 = _e350;
    let _e351 = (*roughness_4);
    param_21 = _e351;
    let _e352 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_20), (&param_21));
    dirAlbedo_1 = _e352;
    let _e353 = (*roughness_4);
    param_22 = _e353;
    let _e354 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_22));
    avgAlbedo = _e354;
    let _e355 = (*color_1);
    param_23 = _e355;
    let _e356 = mx_square_u0028_vf3_u003b((&param_23));
    let _e357 = avgAlbedo;
    let _e359 = (*color_1);
    let _e360 = avgAlbedo;
    colorMultiScatter = ((_e356 * _e357) / (vec3<f32>(1f, 1f, 1f) - (_e359 * max(0f, (1f - _e360)))));
    let _e366 = colorMultiScatter;
    let _e367 = (*color_1);
    let _e368 = dirAlbedo_1;
    return mix(_e366, _e367, vec3(_e368));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_24: f32;
    var A_2: f32;
    var B_1: f32;

    let _e351 = (*LdotV);
    let _e352 = (*NdotL);
    let _e353 = (*NdotV_3);
    s_1 = (_e351 - (_e352 * _e353));
    let _e356 = s_1;
    if (_e356 > 0f) {
        let _e358 = s_1;
        let _e359 = (*NdotL);
        let _e360 = (*NdotV_3);
        local_1 = (_e358 / max(_e359, _e360));
    } else {
        local_1 = 0f;
    }
    let _e363 = local_1;
    stinv = _e363;
    let _e364 = (*roughness_5);
    param_24 = _e364;
    let _e365 = mx_square_u0028_f1_u003b((&param_24));
    sigma2_ = _e365;
    let _e366 = sigma2_;
    let _e367 = sigma2_;
    A_2 = (1f - (0.5f * (_e366 / (_e367 + 0.33f))));
    let _e372 = sigma2_;
    let _e374 = sigma2_;
    B_1 = ((0.45f * _e372) / (_e374 + 0.09f));
    let _e377 = A_2;
    let _e378 = B_1;
    let _e379 = stinv;
    return (_e377 + (_e378 * _e379));
}

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_4: ptr<function, f32>, NdotL_1: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_2: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_25: f32;
    var param_26: f32;
    var dirAlbedoL: f32;
    var param_27: f32;
    var param_28: f32;
    var avgAlbedo_1: f32;
    var param_29: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_30: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e361 = (*LdotV_1);
    let _e362 = (*NdotL_1);
    let _e363 = (*NdotV_4);
    s_2 = (_e361 - (_e362 * _e363));
    let _e366 = s_2;
    if (_e366 > 0f) {
        let _e368 = s_2;
        let _e369 = (*NdotL_1);
        let _e370 = (*NdotV_4);
        local_2 = (_e368 / max(_e369, _e370));
    } else {
        let _e373 = s_2;
        local_2 = _e373;
    }
    let _e374 = local_2;
    stinv_1 = _e374;
    let _e375 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e375)));
    let _e379 = (*color_2);
    let _e380 = A_3;
    let _e382 = (*roughness_6);
    let _e383 = stinv_1;
    lobeSingleScatter = ((_e379 * _e380) * (1f + (_e382 * _e383)));
    let _e387 = (*NdotV_4);
    param_25 = _e387;
    let _e388 = (*roughness_6);
    param_26 = _e388;
    let _e389 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_25), (&param_26));
    dirAlbedoV = _e389;
    let _e390 = (*NdotL_1);
    param_27 = _e390;
    let _e391 = (*roughness_6);
    param_28 = _e391;
    let _e392 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_27), (&param_28));
    dirAlbedoL = _e392;
    let _e393 = (*roughness_6);
    param_29 = _e393;
    let _e394 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_29));
    avgAlbedo_1 = _e394;
    let _e395 = (*color_2);
    param_30 = _e395;
    let _e396 = mx_square_u0028_vf3_u003b((&param_30));
    let _e397 = avgAlbedo_1;
    let _e399 = (*color_2);
    let _e400 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e396 * _e397) / (vec3<f32>(1f, 1f, 1f) - (_e399 * max(0f, (1f - _e400)))));
    let _e406 = colorMultiScatter_1;
    let _e407 = dirAlbedoV;
    let _e411 = dirAlbedoL;
    let _e415 = avgAlbedo_1;
    lobeMultiScatter = (((_e406 * max(0.00000001f, (1f - _e407))) * max(0.00000001f, (1f - _e411))) / vec3(max(0.00000001f, (1f - _e415))));
    let _e420 = lobeSingleScatter;
    let _e421 = lobeMultiScatter;
    return (_e420 + _e421);
}

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, weight: ptr<function, f32>, color_3: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_3: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L: vec3<f32>;
    var param_31: vec3<f32>;
    var param_32: vec3<f32>;
    var NdotV_5: f32;
    var NdotL_2: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_33: f32;
    var param_34: f32;
    var param_35: f32;
    var param_36: f32;
    var param_37: vec3<f32>;
    var param_38: f32;
    var param_39: f32;
    var param_40: f32;
    var param_41: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_42: f32;
    var param_43: f32;
    var param_44: vec3<f32>;
    var param_45: f32;
    var param_46: f32;
    var Li_1: vec3<f32>;
    var param_47: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e375 = (*weight);
    if (_e375 < 0.00000001f) {
        return;
    }
    let _e378 = (*closureData_6).V;
    V_1 = _e378;
    let _e380 = (*closureData_6).L;
    L = _e380;
    let _e381 = (*N_3);
    param_31 = _e381;
    let _e382 = V_1;
    param_32 = _e382;
    let _e383 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_31), (&param_32));
    (*N_3) = _e383;
    let _e384 = (*N_3);
    let _e385 = V_1;
    NdotV_5 = clamp(dot(_e384, _e385), 0.00000001f, 1f);
    let _e389 = (*closureData_6).closureType;
    if (_e389 == 1i) {
        let _e391 = (*N_3);
        let _e392 = L;
        NdotL_2 = clamp(dot(_e391, _e392), 0.00000001f, 1f);
        let _e395 = L;
        let _e396 = V_1;
        LdotV_2 = clamp(dot(_e395, _e396), 0.00000001f, 1f);
        let _e399 = (*energy_compensation);
        if _e399 {
            let _e400 = NdotV_5;
            param_33 = _e400;
            let _e401 = NdotL_2;
            param_34 = _e401;
            let _e402 = LdotV_2;
            param_35 = _e402;
            let _e403 = (*roughness_7);
            param_36 = _e403;
            let _e404 = (*color_3);
            param_37 = _e404;
            let _e405 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_33), (&param_34), (&param_35), (&param_36), (&param_37));
            local_3 = _e405;
        } else {
            let _e406 = NdotV_5;
            param_38 = _e406;
            let _e407 = NdotL_2;
            param_39 = _e407;
            let _e408 = LdotV_2;
            param_40 = _e408;
            let _e409 = (*roughness_7);
            param_41 = _e409;
            let _e410 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_38), (&param_39), (&param_40), (&param_41));
            let _e411 = (*color_3);
            local_3 = (_e411 * _e410);
        }
        let _e413 = local_3;
        diffuse = _e413;
        let _e414 = diffuse;
        let _e416 = (*closureData_6).occlusion;
        let _e418 = (*weight);
        let _e420 = NdotL_2;
        (*bsdf).response = ((((_e414 * _e416) * _e418) * _e420) * 0.31830987f);
    } else {
        let _e425 = (*closureData_6).closureType;
        if (_e425 == 3i) {
            let _e427 = (*energy_compensation);
            if _e427 {
                let _e428 = NdotV_5;
                param_42 = _e428;
                let _e429 = (*roughness_7);
                param_43 = _e429;
                let _e430 = (*color_3);
                param_44 = _e430;
                let _e431 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_42), (&param_43), (&param_44));
                local_4 = _e431;
            } else {
                let _e432 = NdotV_5;
                param_45 = _e432;
                let _e433 = (*roughness_7);
                param_46 = _e433;
                let _e434 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_45), (&param_46));
                let _e435 = (*color_3);
                local_4 = (_e435 * _e434);
            }
            let _e437 = local_4;
            diffuse_1 = _e437;
            let _e438 = (*N_3);
            param_47 = _e438;
            let _e439 = mx_environment_irradiance_u0028_vf3_u003b((&param_47));
            Li_1 = _e439;
            let _e440 = Li_1;
            let _e441 = diffuse_1;
            let _e443 = (*weight);
            (*bsdf).response = ((_e440 * _e441) * _e443);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_6: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e345 = (*in2_2);
    weight_1 = clamp(_e345, 0f, 1f);
    let _e348 = (*in1_2).response;
    let _e349 = weight_1;
    (*result_6).response = (_e348 * _e349);
    let _e353 = (*in1_2).throughput;
    (*result_6).throughput = _e353;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_7: ptr<function, BSDF>) {
    let _e345 = (*in1_3).response;
    let _e347 = (*in2_3).response;
    (*result_7).response = (_e345 + _e347);
    let _e351 = (*in1_3).throughput;
    let _e353 = (*in2_3).throughput;
    (*result_7).throughput = max(((_e351 + _e353) - vec3(1f)), vec3(0f));
    return;
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e345 = (*shape);
    let _e347 = (*dist);
    num1_ = exp((-(_e345) * _e347));
    let _e350 = (*shape);
    let _e352 = (*dist);
    num2_ = exp(((-(_e350) * _e352) / vec3(3f)));
    let _e357 = (*dist);
    denom = max(_e357, 0.00000001f);
    let _e359 = num1_;
    let _e360 = num2_;
    let _e362 = denom;
    return ((_e359 + _e360) / vec3(_e362));
}

fn mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(N_4: ptr<function, vec3<f32>>, L_1: ptr<function, vec3<f32>>, radius: ptr<function, f32>, mfp: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta: f32;
    var shape_1: vec3<f32>;
    var sumD: vec3<f32>;
    var sumR: vec3<f32>;
    var i: i32;
    var x_3: f32;
    var dist_1: f32;
    var R: vec3<f32>;
    var param_48: f32;
    var param_49: vec3<f32>;

    let _e354 = (*N_4);
    let _e355 = (*L_1);
    theta = acos(dot(_e354, _e355));
    let _e358 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e358, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e362 = i;
        if (_e362 < 32i) {
            let _e364 = i;
            x_3 = (-3.1415927f + ((f32(_e364) + 0.5f) * 0.19634955f));
            let _e369 = (*radius);
            let _e370 = x_3;
            dist_1 = (_e369 * abs((2f * sin((_e370 * 0.5f)))));
            let _e376 = dist_1;
            param_48 = _e376;
            let _e377 = shape_1;
            param_49 = _e377;
            let _e378 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_48), (&param_49));
            R = _e378;
            let _e379 = R;
            let _e380 = theta;
            let _e381 = x_3;
            let _e386 = sumD;
            sumD = (_e386 + (_e379 * max(cos((_e380 + _e381)), 0f)));
            let _e388 = R;
            let _e389 = sumR;
            sumR = (_e389 + _e388);
            continue;
        } else {
            break;
        }
        continuing {
            let _e391 = i;
            i = (_e391 + 1i);
        }
    }
    let _e393 = sumD;
    let _e394 = sumR;
    return (_e393 / _e394);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, L_2: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_50: vec3<f32>;
    var param_51: vec3<f32>;
    var param_52: f32;
    var param_53: vec3<f32>;

    let _e351 = (*N_5);
    let _e352 = fwidth(_e351);
    let _e354 = (*P);
    let _e355 = fwidth(_e354);
    curvature = (length(_e352) / length(_e355));
    let _e358 = curvature;
    radius_1 = (1f / max(_e358, 0.01f));
    let _e361 = (*albedo);
    let _e362 = (*N_5);
    param_50 = _e362;
    let _e363 = (*L_2);
    param_51 = _e363;
    let _e364 = radius_1;
    param_52 = _e364;
    let _e365 = (*mfp_1);
    param_53 = _e365;
    let _e366 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_50), (&param_51), (&param_52), (&param_53));
    return ((_e361 * _e366) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
}

fn mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_9: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color_4: ptr<function, vec3<f32>>, radius_2: ptr<function, vec3<f32>>, anisotropy: ptr<function, f32>, N_6: ptr<function, vec3<f32>>, bsdf_1: ptr<function, BSDF>) {
    var V_2: vec3<f32>;
    var L_3: vec3<f32>;
    var P_1: vec3<f32>;
    var occlusion: f32;
    var param_54: vec3<f32>;
    var param_55: vec3<f32>;
    var sss: vec3<f32>;
    var param_56: vec3<f32>;
    var param_57: vec3<f32>;
    var param_58: vec3<f32>;
    var param_59: vec3<f32>;
    var param_60: vec3<f32>;
    var NdotL_3: f32;
    var visibleOcclusion: f32;
    var Li_2: vec3<f32>;
    var param_61: vec3<f32>;

    (*bsdf_1).throughput = vec3<f32>(0f, 0f, 0f);
    let _e364 = (*weight_2);
    if (_e364 < 0.00000001f) {
        return;
    }
    let _e367 = (*closureData_9).V;
    V_2 = _e367;
    let _e369 = (*closureData_9).L;
    L_3 = _e369;
    let _e371 = (*closureData_9).P;
    P_1 = _e371;
    let _e373 = (*closureData_9).occlusion;
    occlusion = _e373;
    let _e374 = (*N_6);
    param_54 = _e374;
    let _e375 = V_2;
    param_55 = _e375;
    let _e376 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_54), (&param_55));
    (*N_6) = _e376;
    let _e378 = (*closureData_9).closureType;
    if (_e378 == 1i) {
        let _e380 = (*N_6);
        param_56 = _e380;
        let _e381 = L_3;
        param_57 = _e381;
        let _e382 = P_1;
        param_58 = _e382;
        let _e383 = (*color_4);
        param_59 = _e383;
        let _e384 = (*radius_2);
        param_60 = _e384;
        let _e385 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_56), (&param_57), (&param_58), (&param_59), (&param_60));
        sss = _e385;
        let _e386 = (*N_6);
        let _e387 = L_3;
        NdotL_3 = clamp(dot(_e386, _e387), 0.00000001f, 1f);
        let _e390 = NdotL_3;
        let _e391 = occlusion;
        visibleOcclusion = (1f - (_e390 * (1f - _e391)));
        let _e395 = sss;
        let _e396 = visibleOcclusion;
        let _e398 = (*weight_2);
        (*bsdf_1).response = ((_e395 * _e396) * _e398);
    } else {
        let _e402 = (*closureData_9).closureType;
        if (_e402 == 3i) {
            let _e404 = (*N_6);
            param_61 = _e404;
            let _e405 = mx_environment_irradiance_u0028_vf3_u003b((&param_61));
            Li_2 = _e405;
            let _e406 = Li_2;
            let _e407 = (*color_4);
            let _e409 = (*weight_2);
            (*bsdf_1).response = ((_e406 * _e407) * _e409);
        }
    }
    return;
}

fn mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_10: ptr<function, ClosureData>, weight_3: ptr<function, f32>, color_5: ptr<function, vec3<f32>>, N_7: ptr<function, vec3<f32>>, bsdf_2: ptr<function, BSDF>) {
    var V_3: vec3<f32>;
    var L_4: vec3<f32>;
    var NdotL_4: f32;
    var Li_3: vec3<f32>;
    var param_62: vec3<f32>;

    (*bsdf_2).throughput = vec3<f32>(0f, 0f, 0f);
    let _e351 = (*weight_3);
    if (_e351 < 0.00000001f) {
        return;
    }
    let _e354 = (*closureData_10).V;
    V_3 = _e354;
    let _e356 = (*closureData_10).L;
    L_4 = _e356;
    let _e357 = (*N_7);
    (*N_7) = -(_e357);
    let _e360 = (*closureData_10).closureType;
    if (_e360 == 1i) {
        let _e362 = (*N_7);
        let _e363 = L_4;
        NdotL_4 = clamp(dot(_e362, _e363), 0f, 1f);
        let _e366 = (*color_5);
        let _e367 = (*weight_3);
        let _e369 = NdotL_4;
        (*bsdf_2).response = (((_e366 * _e367) * _e369) * 0.31830987f);
    } else {
        let _e374 = (*closureData_10).closureType;
        if (_e374 == 3i) {
            let _e376 = (*N_7);
            param_62 = _e376;
            let _e377 = mx_environment_irradiance_u0028_vf3_u003b((&param_62));
            Li_3 = _e377;
            let _e378 = Li_3;
            let _e379 = (*color_5);
            let _e381 = (*weight_3);
            (*bsdf_2).response = ((_e378 * _e379) * _e381);
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_4: ptr<function, f32>, y: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_1: f32;
    var o: f32;
    var param_63: f32;

    let _e346 = (*y);
    let _e347 = (*y);
    let _e351 = (*y);
    let _e352 = (*y);
    s_3 = ((_e346 * (0.0206607f + (1.58491f * _e347))) / (0.0379424f + (_e351 * (1.32227f + _e352))));
    let _e357 = (*y);
    let _e358 = (*y);
    let _e359 = (*y);
    let _e360 = (*y);
    let _e362 = (*y);
    let _e370 = (*y);
    m_1 = ((_e357 * (-0.193854f + (_e358 * (-1.14885f + (_e359 * (1.7932f - ((0.95943f * _e360) * _e362))))))) / (0.046391f + _e370));
    let _e373 = (*y);
    let _e374 = (*y);
    let _e377 = (*y);
    let _e381 = (*y);
    let _e382 = (*y);
    o = ((_e373 * (0.000654023f + ((-0.0207818f + (0.119681f * _e374)) * _e377))) / (1.26264f + (_e381 * (-1.92021f + _e382))));
    let _e387 = (*x_4);
    let _e388 = m_1;
    let _e390 = s_3;
    param_63 = ((_e387 - _e388) / _e390);
    let _e392 = mx_square_u0028_f1_u003b((&param_63));
    let _e395 = s_3;
    let _e398 = o;
    return ((exp((-0.5f * _e392)) / (_e395 * 2.5066283f)) + _e398);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_3: ptr<function, f32>) -> f32 {
    let _e341 = (*cosTheta_3);
    return (max(_e341, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_5: ptr<function, f32>, y_1: ptr<function, f32>) -> f32 {
    let _e342 = (*x_5);
    let _e345 = (*y_1);
    let _e348 = (*y_1);
    let _e350 = (*y_1);
    let _e352 = (*y_1);
    let _e354 = (*x_5);
    let _e357 = (*x_5);
    let _e359 = (*y_1);
    let _e362 = (*y_1);
    let _e364 = (*y_1);
    return (((((sqrt((1f - _e342)) * (_e345 - 1f)) * _e348) * _e350) * _e352) / (((0.0000254053f + (1.71228f * _e354)) - ((1.71506f * _e357) * _e359)) + ((1.34174f * _e362) * _e364)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    let _e342 = (*x_6);
    let _e344 = (*y_2);
    let _e347 = (*y_2);
    let _e349 = (*x_6);
    let _e351 = (*x_6);
    let _e354 = (*x_6);
    let _e356 = (*y_2);
    return ((((2.58126f * _e342) + (0.813703f * _e344)) * _e347) / ((1f + ((0.310327f * _e349) * _e351)) + ((2.60994f * _e354) * _e356)));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_2: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e342 = (*m_2);
    let _e343 = (*v_2);
    return (_e342 * _e343);
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_8: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_1: f32;
    var b: f32;
    var X: vec3<f32>;
    var Y: vec3<f32>;

    let _e347 = (*N_8)[2u];
    sign_ = select(1f, -1f, (_e347 < 0f));
    let _e350 = sign_;
    let _e352 = (*N_8)[2u];
    a_1 = (-1f / (_e350 + _e352));
    let _e356 = (*N_8)[0u];
    let _e358 = (*N_8)[1u];
    let _e360 = a_1;
    b = ((_e356 * _e358) * _e360);
    let _e362 = sign_;
    let _e364 = (*N_8)[0u];
    let _e367 = (*N_8)[0u];
    let _e369 = a_1;
    let _e372 = sign_;
    let _e373 = b;
    let _e375 = sign_;
    let _e378 = (*N_8)[0u];
    X = vec3<f32>((1f + (((_e362 * _e364) * _e367) * _e369)), (_e372 * _e373), (-(_e375) * _e378));
    let _e381 = b;
    let _e382 = sign_;
    let _e384 = (*N_8)[1u];
    let _e386 = (*N_8)[1u];
    let _e388 = a_1;
    let _e392 = (*N_8)[1u];
    Y = vec3<f32>(_e381, (_e382 + ((_e384 * _e386) * _e388)), -(_e392));
    let _e395 = X;
    let _e396 = Y;
    let _e397 = (*N_8);
    return mat3x3<f32>(vec3<f32>(_e395.x, _e395.y, _e395.z), vec3<f32>(_e396.x, _e396.y, _e396.z), vec3<f32>(_e397.x, _e397.y, _e397.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_4: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_6: ptr<function, f32>) -> mat3x3<f32> {
    var X_1: vec3<f32>;
    var lenSqr: f32;
    var Y_1: vec3<f32>;
    var param_64: vec3<f32>;

    let _e347 = (*V_4);
    let _e348 = (*N_9);
    let _e349 = (*NdotV_6);
    X_1 = (_e347 - (_e348 * _e349));
    let _e352 = X_1;
    let _e353 = X_1;
    lenSqr = dot(_e352, _e353);
    let _e355 = lenSqr;
    if (_e355 > 0f) {
        let _e357 = lenSqr;
        let _e359 = X_1;
        X_1 = (_e359 * inverseSqrt(_e357));
        let _e361 = (*N_9);
        let _e362 = X_1;
        Y_1 = cross(_e361, _e362);
        let _e364 = X_1;
        let _e365 = Y_1;
        let _e366 = (*N_9);
        return mat3x3<f32>(vec3<f32>(_e364.x, _e364.y, _e364.z), vec3<f32>(_e365.x, _e365.y, _e365.z), vec3<f32>(_e366.x, _e366.y, _e366.z));
    }
    let _e380 = (*N_9);
    param_64 = _e380;
    let _e381 = mx_orthonormal_basis_u0028_vf3_u003b((&param_64));
    return _e381;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_5: ptr<function, vec3<f32>>, V_5: ptr<function, vec3<f32>>, N_10: ptr<function, vec3<f32>>, NdotV_7: ptr<function, f32>, roughness_8: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_65: vec3<f32>;
    var param_66: vec3<f32>;
    var param_67: f32;
    var w: vec3<f32>;
    var param_68: mat3x3<f32>;
    var param_69: vec3<f32>;
    var aInv: f32;
    var param_70: f32;
    var param_71: f32;
    var bInv: f32;
    var param_72: f32;
    var param_73: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_74: f32;
    var param_75: f32;

    let _e362 = (*V_5);
    param_65 = _e362;
    let _e363 = (*N_10);
    param_66 = _e363;
    let _e364 = (*NdotV_7);
    param_67 = _e364;
    let _e365 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_65), (&param_66), (&param_67));
    toLTC = transpose(_e365);
    let _e367 = toLTC;
    param_68 = _e367;
    let _e368 = (*L_5);
    param_69 = _e368;
    let _e369 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_68), (&param_69));
    w = _e369;
    let _e370 = (*NdotV_7);
    param_70 = _e370;
    let _e371 = (*roughness_8);
    param_71 = _e371;
    let _e372 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_70), (&param_71));
    aInv = _e372;
    let _e373 = (*NdotV_7);
    param_72 = _e373;
    let _e374 = (*roughness_8);
    param_73 = _e374;
    let _e375 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_72), (&param_73));
    bInv = _e375;
    let _e376 = aInv;
    let _e378 = w[0u];
    let _e380 = bInv;
    let _e382 = w[2u];
    let _e385 = aInv;
    let _e387 = w[1u];
    let _e390 = w[2u];
    wo = vec3<f32>(((_e376 * _e378) + (_e380 * _e382)), (_e385 * _e387), _e390);
    let _e392 = wo;
    let _e393 = wo;
    lenSqr_1 = dot(_e392, _e393);
    let _e396 = wo[2u];
    param_74 = _e396;
    let _e397 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_74));
    let _e398 = aInv;
    let _e399 = lenSqr_1;
    param_75 = (_e398 / _e399);
    let _e401 = mx_square_u0028_f1_u003b((&param_75));
    return (_e397 * _e401);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_8: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var r_1: vec2<f32>;
    var param_76: f32;
    var param_77: f32;

    let _e345 = (*NdotV_8);
    let _e348 = (*roughness_9);
    let _e351 = (*NdotV_8);
    let _e353 = (*roughness_9);
    let _e356 = (*NdotV_8);
    param_76 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_76));
    let _e360 = (*roughness_9);
    param_77 = _e360;
    let _e361 = mx_square_u0028_f1_u003b((&param_77));
    r_1 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e345)) + (vec2<f32>(799.08826f, 442.7821f) * _e348)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e351) * _e353)) + (vec2<f32>(60.28956f, 121.81241f) * _e357)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e361));
    let _e365 = r_1[0u];
    let _e367 = r_1[1u];
    return (_e365 / _e367);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_9: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var dirAlbedo_2: f32;
    var param_78: f32;
    var param_79: f32;

    let _e345 = (*NdotV_9);
    param_78 = _e345;
    let _e346 = (*roughness_10);
    param_79 = _e346;
    let _e347 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_78), (&param_79));
    dirAlbedo_2 = _e347;
    let _e348 = dirAlbedo_2;
    return clamp(_e348, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e345 = (*roughness_11);
    invRoughness = (1f / max(_e345, 0.005f));
    let _e348 = (*NdotH);
    let _e349 = (*NdotH);
    cos2_ = (_e348 * _e349);
    let _e351 = cos2_;
    sin2_ = (1f - _e351);
    let _e353 = invRoughness;
    let _e355 = sin2_;
    let _e356 = invRoughness;
    return (((2f + _e353) * pow(_e355, (_e356 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_10: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var D: f32;
    var param_80: f32;
    var param_81: f32;
    var F: f32;
    var G_1: f32;

    let _e349 = (*NdotH_1);
    param_80 = _e349;
    let _e350 = (*roughness_12);
    param_81 = _e350;
    let _e351 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_80), (&param_81));
    D = _e351;
    F = 1f;
    G_1 = 1f;
    let _e352 = D;
    let _e353 = F;
    let _e355 = G_1;
    let _e357 = (*NdotL_5);
    let _e358 = (*NdotV_10);
    let _e360 = (*NdotL_5);
    let _e361 = (*NdotV_10);
    return (((_e352 * _e353) * _e355) / (4f * ((_e357 + _e358) - (_e360 * _e361))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_11: ptr<function, ClosureData>, weight_4: ptr<function, f32>, color_6: ptr<function, vec3<f32>>, roughness_13: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_6: vec3<f32>;
    var L_6: vec3<f32>;
    var param_82: vec3<f32>;
    var param_83: vec3<f32>;
    var NdotV_11: f32;
    var H: vec3<f32>;
    var NdotL_6: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_84: f32;
    var param_85: f32;
    var param_86: f32;
    var param_87: f32;
    var dirAlbedo_3: f32;
    var param_88: f32;
    var param_89: f32;
    var fr_1: vec3<f32>;
    var param_90: vec3<f32>;
    var param_91: vec3<f32>;
    var param_92: vec3<f32>;
    var param_93: f32;
    var param_94: f32;
    var param_95: f32;
    var param_96: f32;
    var dirAlbedo_4: f32;
    var param_97: f32;
    var param_98: f32;
    var param_99: f32;
    var param_100: f32;
    var Li_4: vec3<f32>;
    var param_101: vec3<f32>;

    let _e378 = (*weight_4);
    if (_e378 < 0.00000001f) {
        return;
    }
    let _e381 = (*closureData_11).V;
    V_6 = _e381;
    let _e383 = (*closureData_11).L;
    L_6 = _e383;
    let _e384 = (*N_11);
    param_82 = _e384;
    let _e385 = V_6;
    param_83 = _e385;
    let _e386 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_82), (&param_83));
    (*N_11) = _e386;
    let _e387 = (*N_11);
    let _e388 = V_6;
    NdotV_11 = clamp(dot(_e387, _e388), 0.00000001f, 1f);
    let _e392 = (*closureData_11).closureType;
    if (_e392 == 1i) {
        let _e394 = (*mode);
        if (_e394 == 0i) {
            let _e396 = L_6;
            let _e397 = V_6;
            H = normalize((_e396 + _e397));
            let _e400 = (*N_11);
            let _e401 = L_6;
            NdotL_6 = clamp(dot(_e400, _e401), 0.00000001f, 1f);
            let _e404 = (*N_11);
            let _e405 = H;
            NdotH_2 = clamp(dot(_e404, _e405), 0.00000001f, 1f);
            let _e408 = (*color_6);
            let _e409 = NdotL_6;
            param_84 = _e409;
            let _e410 = NdotV_11;
            param_85 = _e410;
            let _e411 = NdotH_2;
            param_86 = _e411;
            let _e412 = (*roughness_13);
            param_87 = _e412;
            let _e413 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_84), (&param_85), (&param_86), (&param_87));
            fr = (_e408 * _e413);
            let _e415 = NdotV_11;
            param_88 = _e415;
            let _e416 = (*roughness_13);
            param_89 = _e416;
            let _e417 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_88), (&param_89));
            dirAlbedo_3 = _e417;
            let _e418 = fr;
            let _e419 = NdotL_6;
            let _e422 = (*closureData_11).occlusion;
            let _e424 = (*weight_4);
            (*bsdf_3).response = (((_e418 * _e419) * _e422) * _e424);
        } else {
            let _e427 = (*roughness_13);
            (*roughness_13) = clamp(_e427, 0.01f, 1f);
            let _e429 = (*color_6);
            let _e430 = L_6;
            param_90 = _e430;
            let _e431 = V_6;
            param_91 = _e431;
            let _e432 = (*N_11);
            param_92 = _e432;
            let _e433 = NdotV_11;
            param_93 = _e433;
            let _e434 = (*roughness_13);
            param_94 = _e434;
            let _e435 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_90), (&param_91), (&param_92), (&param_93), (&param_94));
            fr_1 = (_e429 * _e435);
            let _e437 = NdotV_11;
            param_95 = _e437;
            let _e438 = (*roughness_13);
            param_96 = _e438;
            let _e439 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_95), (&param_96));
            dirAlbedo_3 = _e439;
            let _e440 = dirAlbedo_3;
            let _e441 = fr_1;
            let _e444 = (*closureData_11).occlusion;
            let _e446 = (*weight_4);
            (*bsdf_3).response = (((_e441 * _e440) * _e444) * _e446);
        }
        let _e449 = dirAlbedo_3;
        let _e450 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e449 * _e450)));
    } else {
        let _e456 = (*closureData_11).closureType;
        if (_e456 == 3i) {
            let _e458 = (*mode);
            if (_e458 == 0i) {
                let _e460 = NdotV_11;
                param_97 = _e460;
                let _e461 = (*roughness_13);
                param_98 = _e461;
                let _e462 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_97), (&param_98));
                dirAlbedo_4 = _e462;
            } else {
                let _e463 = (*roughness_13);
                (*roughness_13) = clamp(_e463, 0.01f, 1f);
                let _e465 = NdotV_11;
                param_99 = _e465;
                let _e466 = (*roughness_13);
                param_100 = _e466;
                let _e467 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_99), (&param_100));
                dirAlbedo_4 = _e467;
            }
            let _e468 = (*N_11);
            param_101 = _e468;
            let _e469 = mx_environment_irradiance_u0028_vf3_u003b((&param_101));
            Li_4 = _e469;
            let _e470 = Li_4;
            let _e471 = (*color_6);
            let _e473 = dirAlbedo_4;
            let _e475 = (*weight_4);
            (*bsdf_3).response = (((_e470 * _e471) * _e473) * _e475);
            let _e478 = dirAlbedo_4;
            let _e479 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e478 * _e479)));
        }
    }
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_7: ptr<function, f32>, NdotV_12: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_102: f32;
    var lambdaL: f32;
    var param_103: f32;
    var lambdaV: f32;
    var param_104: f32;

    let _e349 = (*alpha);
    param_102 = _e349;
    let _e350 = mx_square_u0028_f1_u003b((&param_102));
    alpha2_ = _e350;
    let _e351 = alpha2_;
    let _e352 = alpha2_;
    let _e354 = (*NdotL_7);
    param_103 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_103));
    lambdaL = sqrt((_e351 + ((1f - _e352) * _e355)));
    let _e359 = alpha2_;
    let _e360 = alpha2_;
    let _e362 = (*NdotV_12);
    param_104 = _e362;
    let _e363 = mx_square_u0028_f1_u003b((&param_104));
    lambdaV = sqrt((_e359 + ((1f - _e360) * _e363)));
    let _e367 = (*NdotL_7);
    let _e369 = (*NdotV_12);
    let _e371 = lambdaL;
    let _e372 = (*NdotV_12);
    let _e374 = lambdaV;
    let _e375 = (*NdotL_7);
    return (((2f * _e367) * _e369) / ((_e371 * _e372) + (_e374 * _e375)));
}

fn mx_pow6_u0028_f1_u003b(x_7: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_105: f32;
    var param_106: f32;

    let _e344 = (*x_7);
    param_105 = _e344;
    let _e345 = mx_square_u0028_f1_u003b((&param_105));
    x2_ = _e345;
    let _e346 = x2_;
    param_106 = _e346;
    let _e347 = mx_square_u0028_f1_u003b((&param_106));
    let _e348 = x2_;
    return (_e347 * _e348);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_4: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_8: f32;
    var a_2: vec3<f32>;
    var param_107: f32;

    let _e345 = (*cosTheta_4);
    x_8 = clamp(_e345, 0f, 1f);
    let _e348 = (*fd).F0_;
    let _e350 = (*fd).F90_;
    let _e352 = (*fd).exponent;
    let _e357 = (*fd).F82_;
    a_2 = ((mix(_e348, _e350, vec3(pow(0.85714287f, _e352))) * (vec3<f32>(1f, 1f, 1f) - _e357)) * 17.651384f);
    let _e362 = (*fd).F0_;
    let _e364 = (*fd).F90_;
    let _e365 = x_8;
    let _e368 = (*fd).exponent;
    let _e372 = a_2;
    let _e373 = x_8;
    let _e375 = x_8;
    param_107 = (1f - _e375);
    let _e377 = mx_pow6_u0028_f1_u003b((&param_107));
    return (mix(_e362, _e364, vec3(pow((1f - _e365), _e368))) - ((_e372 * _e373) * _e377));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_5: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_108: f32;
    var sinTheta2_: f32;
    var n2_: vec3<f32>;
    var k2_: vec3<f32>;
    var t0_: vec3<f32>;
    var a2plusb2_: vec3<f32>;
    var t1_: vec3<f32>;
    var a_3: vec3<f32>;
    var t2_: vec3<f32>;
    var t3_: vec3<f32>;
    var t4_: vec3<f32>;

    let _e357 = (*cosTheta_5);
    param_108 = clamp(_e357, 0f, 1f);
    let _e359 = mx_square_u0028_f1_u003b((&param_108));
    cosTheta2_ = _e359;
    let _e360 = cosTheta2_;
    sinTheta2_ = (1f - _e360);
    let _e362 = (*n);
    let _e363 = (*n);
    n2_ = (_e362 * _e363);
    let _e365 = (*k);
    let _e366 = (*k);
    k2_ = (_e365 * _e366);
    let _e368 = n2_;
    let _e369 = k2_;
    let _e371 = sinTheta2_;
    t0_ = ((_e368 - _e369) - vec3(_e371));
    let _e374 = t0_;
    let _e375 = t0_;
    let _e377 = n2_;
    let _e379 = k2_;
    a2plusb2_ = sqrt(((_e374 * _e375) + ((_e377 * 4f) * _e379)));
    let _e383 = a2plusb2_;
    let _e384 = cosTheta2_;
    t1_ = (_e383 + vec3(_e384));
    let _e387 = a2plusb2_;
    let _e388 = t0_;
    a_3 = sqrt(max(((_e387 + _e388) * 0.5f), vec3(0f)));
    let _e394 = a_3;
    let _e396 = (*cosTheta_5);
    t2_ = ((_e394 * 2f) * _e396);
    let _e398 = t1_;
    let _e399 = t2_;
    let _e401 = t1_;
    let _e402 = t2_;
    (*Rs) = ((_e398 - _e399) / (_e401 + _e402));
    let _e405 = cosTheta2_;
    let _e406 = a2plusb2_;
    let _e408 = sinTheta2_;
    let _e409 = sinTheta2_;
    t3_ = ((_e406 * _e405) + vec3((_e408 * _e409)));
    let _e413 = t2_;
    let _e414 = sinTheta2_;
    t4_ = (_e413 * _e414);
    let _e416 = (*Rs);
    let _e417 = t3_;
    let _e418 = t4_;
    let _e421 = t3_;
    let _e422 = t4_;
    (*Rp) = ((_e416 * (_e417 - _e418)) / (_e421 + _e422));
    return;
}

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_6: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_109: f32;
    var param_110: vec3<f32>;
    var param_111: vec3<f32>;
    var param_112: vec3<f32>;
    var param_113: vec3<f32>;

    let _e350 = (*cosTheta_6);
    param_109 = _e350;
    let _e351 = (*n_1);
    param_110 = _e351;
    let _e352 = (*k_1);
    param_111 = _e352;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_109), (&param_110), (&param_111), (&param_112), (&param_113));
    let _e353 = param_112;
    Rp_1 = _e353;
    let _e354 = param_113;
    Rs_1 = _e354;
    let _e355 = Rp_1;
    let _e356 = Rs_1;
    return ((_e355 + _e356) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_114: f32;
    var param_115: f32;

    let _e347 = (*cosTheta_7);
    c_1 = _e347;
    let _e348 = (*ior);
    let _e349 = (*ior);
    let _e351 = c_1;
    let _e352 = c_1;
    g2_ = (((_e348 * _e349) + (_e351 * _e352)) - 1f);
    let _e356 = g2_;
    if (_e356 < 0f) {
        return 1f;
    }
    let _e358 = g2_;
    g = sqrt(_e358);
    let _e360 = g;
    let _e361 = c_1;
    let _e363 = g;
    let _e364 = c_1;
    param_114 = ((_e360 - _e361) / (_e363 + _e364));
    let _e367 = mx_square_u0028_f1_u003b((&param_114));
    let _e369 = g;
    let _e370 = c_1;
    let _e372 = c_1;
    let _e375 = g;
    let _e376 = c_1;
    let _e378 = c_1;
    param_115 = ((((_e369 + _e370) * _e372) - 1f) / (((_e375 - _e376) * _e378) + 1f));
    let _e382 = mx_square_u0028_f1_u003b((&param_115));
    return ((0.5f * _e367) * (1f + _e382));
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e347 = (*opd);
    phase = (6.2831855f * _e347);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e349 = val;
    let _e350 = var_;
    let _e354 = pos;
    let _e355 = phase;
    let _e357 = (*shift);
    let _e361 = var_;
    let _e363 = phase;
    let _e365 = phase;
    xyz = (((_e349 * sqrt((_e350 * 6.2831855f))) * cos(((_e354 * _e355) + _e357))) * exp(((-(_e361) * _e363) * _e365)));
    let _e369 = phase;
    let _e372 = (*shift)[0u];
    let _e376 = phase;
    let _e378 = phase;
    let _e383 = xyz[0u];
    xyz[0u] = (_e383 + ((0.00000001644083f * cos(((2239900f * _e369) + _e372))) * exp(((-4528200000f * _e376) * _e378))));
    let _e386 = xyz;
    return (_e386 / vec3(0.00000010685f));
}

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_8: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_116: vec3<f32>;
    var U: vec3<f32>;
    var V_7: vec3<f32>;
    var param_117: f32;
    var param_118: vec3<f32>;

    let _e355 = (*kappa2_);
    let _e356 = (*eta2_);
    k2_1 = (_e355 / _e356);
    let _e358 = (*cosTheta_8);
    let _e359 = (*cosTheta_8);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e358 * _e359)));
    let _e363 = (*eta2_);
    let _e364 = (*eta2_);
    let _e366 = k2_1;
    let _e367 = k2_1;
    let _e371 = (*eta1_);
    let _e372 = (*eta1_);
    let _e374 = sinThetaSqr;
    A_4 = (((_e363 * _e364) * (vec3<f32>(1f, 1f, 1f) - (_e366 * _e367))) - (_e374 * (_e371 * _e372)));
    let _e377 = A_4;
    let _e378 = A_4;
    let _e380 = (*eta2_);
    let _e382 = (*eta2_);
    let _e384 = k2_1;
    param_116 = (((_e380 * 2f) * _e382) * _e384);
    let _e386 = mx_square_u0028_vf3_u003b((&param_116));
    B_2 = sqrt(((_e377 * _e378) + _e386));
    let _e389 = A_4;
    let _e390 = B_2;
    U = sqrt(((_e389 + _e390) / vec3(2f)));
    let _e395 = B_2;
    let _e396 = A_4;
    V_7 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e395 - _e396) / vec3(2f))));
    let _e402 = (*eta1_);
    let _e404 = V_7;
    let _e406 = (*cosTheta_8);
    let _e408 = U;
    let _e409 = U;
    let _e411 = V_7;
    let _e412 = V_7;
    let _e415 = (*eta1_);
    let _e416 = (*cosTheta_8);
    param_117 = (_e415 * _e416);
    let _e418 = mx_square_u0028_f1_u003b((&param_117));
    (*phiS) = atan2(((_e404 * (2f * _e402)) * _e406), (((_e408 * _e409) + (_e411 * _e412)) - vec3(_e418)));
    let _e422 = (*eta1_);
    let _e424 = (*eta2_);
    let _e426 = (*eta2_);
    let _e428 = (*cosTheta_8);
    let _e430 = k2_1;
    let _e432 = U;
    let _e434 = k2_1;
    let _e435 = k2_1;
    let _e438 = V_7;
    let _e442 = (*eta2_);
    let _e443 = (*eta2_);
    let _e445 = k2_1;
    let _e446 = k2_1;
    let _e450 = (*cosTheta_8);
    param_118 = (((_e442 * _e443) * (vec3<f32>(1f, 1f, 1f) + (_e445 * _e446))) * _e450);
    let _e452 = mx_square_u0028_vf3_u003b((&param_118));
    let _e453 = (*eta1_);
    let _e454 = (*eta1_);
    let _e456 = U;
    let _e457 = U;
    let _e459 = V_7;
    let _e460 = V_7;
    (*phiP) = atan2(((((_e424 * (2f * _e422)) * _e426) * _e428) * (((_e430 * 2f) * _e432) - ((vec3<f32>(1f, 1f, 1f) - (_e434 * _e435)) * _e438))), (_e452 - (((_e456 * _e457) + (_e459 * _e460)) * (_e453 * _e454))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_9: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_119: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e352 = (*cosTheta_9);
    param_119 = clamp(_e352, 0f, 1f);
    let _e354 = mx_square_u0028_f1_u003b((&param_119));
    cosTheta2_1 = _e354;
    let _e355 = cosTheta2_1;
    sinTheta2_1 = (1f - _e355);
    let _e357 = (*ior_1);
    let _e358 = (*ior_1);
    let _e360 = sinTheta2_1;
    t0_1 = max(((_e357 * _e358) - _e360), 0f);
    let _e363 = t0_1;
    let _e364 = cosTheta2_1;
    t1_1 = (_e363 + _e364);
    let _e366 = t0_1;
    let _e369 = (*cosTheta_9);
    t2_1 = ((2f * sqrt(_e366)) * _e369);
    let _e371 = t1_1;
    let _e372 = t2_1;
    let _e374 = t1_1;
    let _e375 = t2_1;
    Rs_2 = ((_e371 - _e372) / (_e374 + _e375));
    let _e378 = cosTheta2_1;
    let _e379 = t0_1;
    let _e381 = sinTheta2_1;
    let _e382 = sinTheta2_1;
    t3_1 = ((_e378 * _e379) + (_e381 * _e382));
    let _e385 = t2_1;
    let _e386 = sinTheta2_1;
    t4_1 = (_e385 * _e386);
    let _e388 = Rs_2;
    let _e389 = t3_1;
    let _e390 = t4_1;
    let _e393 = t3_1;
    let _e394 = t4_1;
    Rp_2 = ((_e388 * (_e389 - _e390)) / (_e393 + _e394));
    let _e397 = Rp_2;
    let _e398 = Rs_2;
    return vec2<f32>(_e397, _e398);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e342 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e342, vec3(0.01f), vec3(0.99f)));
    let _e347 = sqrtF0_;
    let _e349 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e347) / (vec3<f32>(1f, 1f, 1f) - _e349));
}

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_10: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_120: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_121: f32;
    var param_122: f32;
    var R12_: vec2<f32>;
    var param_123: f32;
    var param_124: f32;
    var T121_: vec2<f32>;
    var f_1: vec3<f32>;
    var param_125: f32;
    var param_126: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_127: f32;
    var param_128: vec3<f32>;
    var param_129: vec3<f32>;
    var param_130: vec3<f32>;
    var param_131: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_132: f32;
    var param_133: f32;
    var param_134: vec3<f32>;
    var param_135: vec3<f32>;
    var param_136: vec3<f32>;
    var param_137: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_138: f32;
    var Cm: vec3<f32>;
    var m_3: i32;
    var Sm: vec3<f32>;
    var param_139: f32;
    var param_140: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_141: f32;
    var m_4: i32;
    var param_142: f32;
    var param_143: vec3<f32>;
    var param_144: mat3x3<f32>;
    var param_145: vec3<f32>;

    eta1_1 = 1f;
    let _e396 = (*fd_1).tf_ior;
    let _e397 = eta1_1;
    eta2_1 = max(_e396, _e397);
    let _e400 = (*fd_1).model;
    if (_e400 == 2i) {
        let _e403 = (*fd_1).F0_;
        param_120 = _e403;
        let _e404 = mx_f0_to_ior_u0028_vf3_u003b((&param_120));
        local_5 = _e404;
    } else {
        let _e406 = (*fd_1).ior;
        local_5 = _e406;
    }
    let _e407 = local_5;
    eta3_ = _e407;
    let _e409 = (*fd_1).model;
    if (_e409 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e412 = (*fd_1).extinction;
        local_6 = _e412;
    }
    let _e413 = local_6;
    kappa3_ = _e413;
    let _e414 = (*cosTheta_10);
    param_121 = _e414;
    let _e415 = mx_square_u0028_f1_u003b((&param_121));
    let _e417 = eta1_1;
    let _e418 = eta2_1;
    param_122 = (_e417 / _e418);
    let _e420 = mx_square_u0028_f1_u003b((&param_122));
    cosThetaT = sqrt((1f - ((1f - _e415) * _e420)));
    let _e424 = eta2_1;
    let _e425 = eta1_1;
    let _e427 = (*cosTheta_10);
    param_123 = _e427;
    param_124 = (_e424 / _e425);
    let _e428 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_123), (&param_124));
    R12_ = _e428;
    let _e429 = cosThetaT;
    if (_e429 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e431 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e431);
    let _e434 = (*fd_1).model;
    if (_e434 == 2i) {
        let _e436 = cosThetaT;
        param_125 = _e436;
        let _e437 = (*fd_1);
        param_126 = _e437;
        let _e438 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_125), (&param_126));
        f_1 = _e438;
        let _e439 = f_1;
        R23p = (_e439 * 0.5f);
        let _e441 = f_1;
        R23s = (_e441 * 0.5f);
    } else {
        let _e443 = eta3_;
        let _e444 = eta2_1;
        let _e447 = kappa3_;
        let _e448 = eta2_1;
        let _e451 = cosThetaT;
        param_127 = _e451;
        param_128 = (_e443 / vec3(_e444));
        param_129 = (_e447 / vec3(_e448));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_127), (&param_128), (&param_129), (&param_130), (&param_131));
        let _e452 = param_130;
        R23p = _e452;
        let _e453 = param_131;
        R23s = _e453;
    }
    let _e454 = eta2_1;
    let _e455 = eta1_1;
    cosB = cos(atan((_e454 / _e455)));
    let _e459 = (*cosTheta_10);
    let _e460 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e459 < _e460)), 3.1415927f);
    let _e465 = (*fd_1).model;
    if (_e465 == 2i) {
        let _e468 = eta3_[0u];
        let _e469 = eta2_1;
        let _e473 = eta3_[1u];
        let _e474 = eta2_1;
        let _e478 = eta3_[2u];
        let _e479 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e468 < _e469)), select(0f, 3.1415927f, (_e473 < _e474)), select(0f, 3.1415927f, (_e478 < _e479)));
        let _e483 = phi23p;
        phi23s = _e483;
    } else {
        let _e484 = cosThetaT;
        param_132 = _e484;
        let _e485 = eta2_1;
        param_133 = _e485;
        let _e486 = eta3_;
        param_134 = _e486;
        let _e487 = kappa3_;
        param_135 = _e487;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_132), (&param_133), (&param_134), (&param_135), (&param_136), (&param_137));
        let _e488 = param_136;
        phi23p = _e488;
        let _e489 = param_137;
        phi23s = _e489;
    }
    let _e491 = R12_[0u];
    let _e492 = R23p;
    r123p = max(sqrt((_e492 * _e491)), vec3(0f));
    let _e498 = R12_[1u];
    let _e499 = R23s;
    r123s = max(sqrt((_e499 * _e498)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e505 = (*fd_1).tf_thickness;
    distMeters = (_e505 * 0.000000001f);
    let _e507 = eta2_1;
    let _e509 = cosThetaT;
    let _e511 = distMeters;
    opd_1 = (((2f * _e507) * _e509) * _e511);
    let _e514 = T121_[0u];
    param_138 = _e514;
    let _e515 = mx_square_u0028_f1_u003b((&param_138));
    let _e516 = R23p;
    let _e519 = R12_[0u];
    let _e520 = R23p;
    Rs_3 = ((_e516 * _e515) / (vec3<f32>(1f, 1f, 1f) - (_e520 * _e519)));
    let _e525 = R12_[0u];
    let _e526 = Rs_3;
    let _e529 = I;
    I = (_e529 + (vec3(_e525) + _e526));
    let _e531 = Rs_3;
    let _e533 = T121_[0u];
    Cm = (_e531 - vec3(_e533));
    m_3 = 1i;
    loop {
        let _e536 = m_3;
        if (_e536 <= 2i) {
            let _e538 = r123p;
            let _e539 = Cm;
            Cm = (_e539 * _e538);
            let _e541 = m_3;
            let _e543 = opd_1;
            let _e545 = m_3;
            let _e547 = phi23p;
            let _e549 = phi21_[0u];
            param_139 = (f32(_e541) * _e543);
            param_140 = ((_e547 + vec3(_e549)) * f32(_e545));
            let _e553 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_139), (&param_140));
            Sm = (_e553 * 2f);
            let _e555 = Cm;
            let _e556 = Sm;
            let _e558 = I;
            I = (_e558 + (_e555 * _e556));
            continue;
        } else {
            break;
        }
        continuing {
            let _e560 = m_3;
            m_3 = (_e560 + 1i);
        }
    }
    let _e563 = T121_[1u];
    param_141 = _e563;
    let _e564 = mx_square_u0028_f1_u003b((&param_141));
    let _e565 = R23s;
    let _e568 = R12_[1u];
    let _e569 = R23s;
    Rp_3 = ((_e565 * _e564) / (vec3<f32>(1f, 1f, 1f) - (_e569 * _e568)));
    let _e574 = R12_[1u];
    let _e575 = Rp_3;
    let _e578 = I;
    I = (_e578 + (vec3(_e574) + _e575));
    let _e580 = Rp_3;
    let _e582 = T121_[1u];
    Cm = (_e580 - vec3(_e582));
    m_4 = 1i;
    loop {
        let _e585 = m_4;
        if (_e585 <= 2i) {
            let _e587 = r123s;
            let _e588 = Cm;
            Cm = (_e588 * _e587);
            let _e590 = m_4;
            let _e592 = opd_1;
            let _e594 = m_4;
            let _e596 = phi23s;
            let _e598 = phi21_[1u];
            param_142 = (f32(_e590) * _e592);
            param_143 = ((_e596 + vec3(_e598)) * f32(_e594));
            let _e602 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_142), (&param_143));
            Sm = (_e602 * 2f);
            let _e604 = Cm;
            let _e605 = Sm;
            let _e607 = I;
            I = (_e607 + (_e604 * _e605));
            continue;
        } else {
            break;
        }
        continuing {
            let _e609 = m_4;
            m_4 = (_e609 + 1i);
        }
    }
    let _e611 = I;
    I = (_e611 * 0.5f);
    param_144 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e613 = I;
    param_145 = _e613;
    let _e614 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_144), (&param_145));
    I = clamp(_e614, vec3(0f), vec3(1f));
    let _e618 = I;
    return _e618;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_11: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_146: f32;
    var param_147: FresnelData;
    var param_148: f32;
    var param_149: f32;
    var param_150: f32;
    var param_151: vec3<f32>;
    var param_152: vec3<f32>;
    var param_153: f32;
    var param_154: FresnelData;

    let _e352 = (*fd_2).airy;
    if _e352 {
        let _e353 = (*cosTheta_11);
        param_146 = _e353;
        let _e354 = (*fd_2);
        param_147 = _e354;
        let _e355 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_146), (&param_147));
        return _e355;
    } else {
        let _e357 = (*fd_2).model;
        if (_e357 == 0i) {
            let _e359 = (*cosTheta_11);
            param_148 = _e359;
            let _e362 = (*fd_2).ior[0u];
            param_149 = _e362;
            let _e363 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_148), (&param_149));
            return vec3(_e363);
        } else {
            let _e366 = (*fd_2).model;
            if (_e366 == 1i) {
                let _e368 = (*cosTheta_11);
                param_150 = _e368;
                let _e370 = (*fd_2).ior;
                param_151 = _e370;
                let _e372 = (*fd_2).extinction;
                param_152 = _e372;
                let _e373 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_150), (&param_151), (&param_152));
                return _e373;
            } else {
                let _e374 = (*cosTheta_11);
                param_153 = _e374;
                let _e375 = (*fd_2);
                param_154 = _e375;
                let _e376 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_153), (&param_154));
                return _e376;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_155: mat4x4<f32>;
    var param_156: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_157: vec3<f32>;

    let _e348 = (*dir_2);
    let _e353 = (*transform_1);
    param_155 = _e353;
    param_156 = vec4<f32>(_e348.x, _e348.y, _e348.z, 0f);
    let _e354 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_155), (&param_156));
    envDir_1 = normalize(_e354.xyz);
    let _e357 = envDir_1;
    param_157 = _e357;
    let _e358 = mx_latlong_projection_u0028_vf3_u003b((&param_157));
    uv_2 = _e358;
    let _e359 = uv_2;
    let _e360 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e359, 0.0);
    return _e360.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_158: f32;

    let _e347 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e347 - 1.5f);
    let _e350 = (*dir_3)[1u];
    param_158 = _e350;
    let _e351 = mx_square_u0028_f1_u003b((&param_158));
    distortion = sqrt((1f - _e351));
    let _e354 = effectiveMaxMipLevel;
    let _e355 = (*envSamples);
    let _e357 = (*pdf);
    let _e359 = distortion;
    return max((_e354 - (0.5f * log2(((f32(_e355) * _e357) * _e359)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H_1: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_159: f32;
    var param_160: f32;

    let _e346 = (*H_1);
    let _e348 = (*alpha_1);
    He = (_e346.xy / _e348);
    let _e350 = He;
    let _e351 = He;
    let _e354 = (*H_1)[2u];
    param_159 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_159));
    denom_1 = (dot(_e350, _e351) + _e355);
    let _e358 = (*alpha_1)[0u];
    let _e361 = (*alpha_1)[1u];
    let _e363 = denom_1;
    param_160 = _e363;
    let _e364 = mx_square_u0028_f1_u003b((&param_160));
    return (1f / (((3.1415927f * _e358) * _e361) * _e364));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_2: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_13: ptr<function, f32>) -> f32 {
    var param_161: vec3<f32>;
    var param_162: vec2<f32>;

    let _e346 = (*H_2);
    param_161 = _e346;
    let _e347 = (*alpha_2);
    param_162 = _e347;
    let _e348 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_161), (&param_162));
    let _e349 = (*G1V);
    let _e351 = (*NdotV_13);
    return ((_e348 * _e349) / (4f * _e351));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e344 = (*R_1);
    let _e345 = (*N_12);
    let _e346 = (*ior_2);
    (*R_1) = refract(_e344, _e345, (1f / _e346));
    let _e349 = (*R_1);
    let _e350 = (*R_1);
    let _e351 = (*N_12);
    let _e354 = (*N_12);
    N1_ = normalize(((_e349 * dot(_e350, _e351)) - (_e354 * 0.5f)));
    let _e358 = (*R_1);
    let _e359 = N1_;
    let _e360 = (*ior_2);
    return refract(_e358, _e359, _e360);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_8: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_9: f32;
    var y_3: f32;
    var c_2: vec3<f32>;
    var H_3: vec3<f32>;

    let _e350 = (*V_8);
    let _e352 = (*alpha_3);
    let _e353 = (_e350.xy * _e352);
    let _e355 = (*V_8)[2u];
    (*V_8) = normalize(vec3<f32>(_e353.x, _e353.y, _e355));
    let _e361 = (*Xi)[0u];
    phi = (6.2831855f * _e361);
    let _e364 = (*Xi)[1u];
    let _e367 = (*V_8)[2u];
    let _e371 = (*V_8)[2u];
    z = (((1f - _e364) * (1f + _e367)) - _e371);
    let _e373 = z;
    let _e374 = z;
    sinTheta = sqrt(clamp((1f - (_e373 * _e374)), 0f, 1f));
    let _e379 = sinTheta;
    let _e380 = phi;
    x_9 = (_e379 * cos(_e380));
    let _e383 = sinTheta;
    let _e384 = phi;
    y_3 = (_e383 * sin(_e384));
    let _e387 = x_9;
    let _e388 = y_3;
    let _e389 = z;
    c_2 = vec3<f32>(_e387, _e388, _e389);
    let _e391 = c_2;
    let _e392 = (*V_8);
    H_3 = (_e391 + _e392);
    let _e394 = H_3;
    let _e396 = (*alpha_3);
    let _e397 = (_e394.xy * _e396);
    let _e399 = H_3[2u];
    H_3 = normalize(vec3<f32>(_e397.x, _e397.y, max(_e399, 0f)));
    let _e405 = H_3;
    return _e405;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e341 = (*i_1);
    return fract(((f32(_e341) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_163: i32;

    let _e343 = (*i_2);
    let _e346 = (*numSamples);
    let _e349 = (*i_2);
    param_163 = _e349;
    let _e350 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_163));
    return vec2<f32>(((f32(_e343) + 0.5f) / f32(_e346)), _e350);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_12: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_164: f32;
    var tanTheta2_: f32;
    var param_165: f32;

    let _e346 = (*cosTheta_12);
    param_164 = _e346;
    let _e347 = mx_square_u0028_f1_u003b((&param_164));
    cosTheta2_2 = _e347;
    let _e348 = cosTheta2_2;
    let _e350 = cosTheta2_2;
    tanTheta2_ = ((1f - _e348) / _e350);
    let _e352 = (*alpha_4);
    param_165 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_165));
    let _e354 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e353 * _e354)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e342 = (*alpha_5)[0u];
    let _e344 = (*alpha_5)[1u];
    return sqrt((_e342 * _e344));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_13: ptr<function, vec3<f32>>, V_9: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y_2: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_14: f32;
    var avgAlpha: f32;
    var param_166: vec2<f32>;
    var G1V_1: f32;
    var param_167: f32;
    var param_168: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_3: i32;
    var Xi_1: vec2<f32>;
    var param_169: i32;
    var param_170: i32;
    var H_4: vec3<f32>;
    var param_171: vec2<f32>;
    var param_172: vec3<f32>;
    var param_173: vec2<f32>;
    var L_7: vec3<f32>;
    var local_7: vec3<f32>;
    var param_174: vec3<f32>;
    var param_175: vec3<f32>;
    var param_176: f32;
    var NdotL_8: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_177: mat3x3<f32>;
    var param_178: vec3<f32>;
    var pdf_1: f32;
    var param_179: vec3<f32>;
    var param_180: vec2<f32>;
    var param_181: f32;
    var param_182: f32;
    var lod_2: f32;
    var param_183: vec3<f32>;
    var param_184: f32;
    var param_185: f32;
    var param_186: i32;
    var sampleColor: vec3<f32>;
    var param_187: vec3<f32>;
    var param_188: mat4x4<f32>;
    var param_189: f32;
    var F_1: vec3<f32>;
    var param_190: f32;
    var param_191: FresnelData;
    var G_2: f32;
    var param_192: f32;
    var param_193: f32;
    var param_194: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e397 = (*X_2);
    let _e398 = (*X_2);
    let _e399 = (*N_13);
    let _e401 = (*N_13);
    (*X_2) = normalize((_e397 - (_e401 * dot(_e398, _e399))));
    let _e405 = (*N_13);
    let _e406 = (*X_2);
    Y_2 = cross(_e405, _e406);
    let _e408 = (*X_2);
    let _e409 = Y_2;
    let _e410 = (*N_13);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e408.x, _e408.y, _e408.z), vec3<f32>(_e409.x, _e409.y, _e409.z), vec3<f32>(_e410.x, _e410.y, _e410.z));
    let _e424 = (*V_9);
    let _e425 = (*X_2);
    let _e427 = (*V_9);
    let _e428 = Y_2;
    let _e430 = (*V_9);
    let _e431 = (*N_13);
    (*V_9) = vec3<f32>(dot(_e424, _e425), dot(_e427, _e428), dot(_e430, _e431));
    let _e435 = (*V_9)[2u];
    NdotV_14 = clamp(_e435, 0.00000001f, 1f);
    let _e437 = (*alpha_6);
    param_166 = _e437;
    let _e438 = mx_average_alpha_u0028_vf2_u003b((&param_166));
    avgAlpha = _e438;
    let _e439 = NdotV_14;
    param_167 = _e439;
    let _e440 = avgAlpha;
    param_168 = _e440;
    let _e441 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_167), (&param_168));
    G1V_1 = _e441;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e442 = i_3;
        let _e443 = envRadianceSamples;
        if (_e442 < _e443) {
            let _e445 = i_3;
            param_169 = _e445;
            let _e446 = envRadianceSamples;
            param_170 = _e446;
            let _e447 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_169), (&param_170));
            Xi_1 = _e447;
            let _e448 = Xi_1;
            param_171 = _e448;
            let _e449 = (*V_9);
            param_172 = _e449;
            let _e450 = (*alpha_6);
            param_173 = _e450;
            let _e451 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_171), (&param_172), (&param_173));
            H_4 = _e451;
            let _e453 = (*fd_3).refraction;
            if _e453 {
                let _e454 = (*V_9);
                param_174 = -(_e454);
                let _e456 = H_4;
                param_175 = _e456;
                let _e459 = (*fd_3).ior[0u];
                param_176 = _e459;
                let _e460 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_174), (&param_175), (&param_176));
                local_7 = _e460;
            } else {
                let _e461 = (*V_9);
                let _e462 = H_4;
                local_7 = -(reflect(_e461, _e462));
            }
            let _e465 = local_7;
            L_7 = _e465;
            let _e467 = L_7[2u];
            NdotL_8 = clamp(_e467, 0.00000001f, 1f);
            let _e469 = (*V_9);
            let _e470 = H_4;
            VdotH = clamp(dot(_e469, _e470), 0.00000001f, 1f);
            let _e473 = tangentToWorld;
            param_177 = _e473;
            let _e474 = L_7;
            param_178 = _e474;
            let _e475 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_177), (&param_178));
            Lw = _e475;
            let _e476 = H_4;
            param_179 = _e476;
            let _e477 = (*alpha_6);
            param_180 = _e477;
            let _e478 = G1V_1;
            param_181 = _e478;
            let _e479 = NdotV_14;
            param_182 = _e479;
            let _e480 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_179), (&param_180), (&param_181), (&param_182));
            pdf_1 = _e480;
            let _e481 = Lw;
            param_183 = _e481;
            let _e482 = pdf_1;
            param_184 = _e482;
            param_185 = 0f;
            let _e483 = envRadianceSamples;
            param_186 = _e483;
            let _e484 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_183), (&param_184), (&param_185), (&param_186));
            lod_2 = _e484;
            let _e485 = mtlxEnvMatrix_u0028_();
            let _e486 = Lw;
            param_187 = _e486;
            param_188 = _e485;
            let _e487 = lod_2;
            param_189 = _e487;
            let _e488 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_187), (&param_188), (&param_189));
            sampleColor = _e488;
            let _e489 = VdotH;
            param_190 = _e489;
            let _e490 = (*fd_3);
            param_191 = _e490;
            let _e491 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_190), (&param_191));
            F_1 = _e491;
            let _e492 = NdotL_8;
            param_192 = _e492;
            let _e493 = NdotV_14;
            param_193 = _e493;
            let _e494 = avgAlpha;
            param_194 = _e494;
            let _e495 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_192), (&param_193), (&param_194));
            G_2 = _e495;
            let _e497 = (*fd_3).refraction;
            if _e497 {
                let _e498 = F_1;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e498);
            } else {
                let _e500 = F_1;
                let _e501 = G_2;
                local_8 = (_e500 * _e501);
            }
            let _e503 = local_8;
            FG = _e503;
            let _e504 = sampleColor;
            let _e505 = FG;
            let _e507 = radiance;
            radiance = (_e507 + (_e504 * _e505));
            continue;
        } else {
            break;
        }
        continuing {
            let _e509 = i_3;
            i_3 = (_e509 + 1i);
        }
    }
    let _e511 = G1V_1;
    let _e512 = envRadianceSamples;
    let _e515 = radiance;
    radiance = (_e515 / vec3((_e511 * f32(_e512))));
    let _e518 = radiance;
    let _e521 = unnamed.skyPower;
    return (select(_e518, vec3<f32>(0f, 0f, 0f), false) * _e521);
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_15: ptr<function, f32>, alpha_7: ptr<function, f32>, F0_2: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_10: f32;
    var y_4: f32;
    var x2_1: f32;
    var param_195: f32;
    var y2_: f32;
    var param_196: f32;
    var r_2: vec4<f32>;
    var AB: vec2<f32>;

    let _e352 = (*NdotV_15);
    x_10 = _e352;
    let _e353 = (*alpha_7);
    y_4 = _e353;
    let _e354 = x_10;
    param_195 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_195));
    x2_1 = _e355;
    let _e356 = y_4;
    param_196 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_196));
    y2_ = _e357;
    let _e358 = x_10;
    let _e361 = y_4;
    let _e364 = x_10;
    let _e366 = y_4;
    let _e369 = x2_1;
    let _e372 = y2_;
    let _e375 = x2_1;
    let _e377 = y_4;
    let _e380 = x_10;
    let _e382 = y2_;
    let _e385 = x2_1;
    let _e387 = y2_;
    r_2 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e358)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e361)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e364) * _e366)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e369)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e372)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e375) * _e377)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e380) * _e382)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e385) * _e387));
    let _e390 = r_2;
    let _e392 = r_2;
    AB = clamp((_e390.xy / _e392.zw), vec2(0f), vec2(1f));
    let _e398 = (*F0_2);
    let _e400 = AB[0u];
    let _e402 = (*F90_1);
    let _e404 = AB[1u];
    return ((_e398 * _e400) + (_e402 * _e404));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_16: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_197: f32;
    var param_198: f32;
    var param_199: vec3<f32>;
    var param_200: vec3<f32>;

    let _e348 = (*NdotV_16);
    param_197 = _e348;
    let _e349 = (*alpha_8);
    param_198 = _e349;
    let _e350 = (*F0_3);
    param_199 = _e350;
    let _e351 = (*F90_2);
    param_200 = _e351;
    let _e352 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_197), (&param_198), (&param_199), (&param_200));
    return _e352;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_201: f32;
    var param_202: f32;
    var param_203: vec3<f32>;
    var param_204: vec3<f32>;

    let _e348 = (*F0_4);
    let _e350 = (*F90_3);
    let _e352 = (*NdotV_17);
    param_201 = _e352;
    let _e353 = (*alpha_9);
    param_202 = _e353;
    param_203 = vec3(_e348);
    param_204 = vec3(_e350);
    let _e354 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_201), (&param_202), (&param_203), (&param_204));
    return _e354.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_4: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_205: f32;
    var param_206: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3358_: bool;

    param_205 = 1f;
    let _e346 = (*fd_4);
    param_206 = _e346;
    let _e347 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_205), (&param_206));
    F0_5 = _e347;
    let _e349 = (*fd_4).model;
    let _e350 = (_e349 == 2i);
    phi_3358_ = _e350;
    if _e350 {
        let _e352 = (*fd_4).airy;
        phi_3358_ = !(_e352);
    }
    let _e355 = phi_3358_;
    if _e355 {
        let _e357 = (*fd_4).F90_;
        local_9 = _e357;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e358 = local_9;
    F90_4 = _e358;
    let _e359 = F0_5;
    let _e360 = F90_4;
    let _e361 = F0_5;
    return (_e359 + ((_e360 - _e361) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_18: ptr<function, f32>, alpha_10: ptr<function, f32>, fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_207: FresnelData;
    var Ess: f32;
    var param_208: f32;
    var param_209: f32;
    var param_210: f32;
    var param_211: f32;

    let _e350 = (*fd_5);
    param_207 = _e350;
    let _e351 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_207));
    Fss = _e351;
    let _e352 = (*NdotV_18);
    param_208 = _e352;
    let _e353 = (*alpha_10);
    param_209 = _e353;
    param_210 = 1f;
    param_211 = 1f;
    let _e354 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_208), (&param_209), (&param_210), (&param_211));
    Ess = _e354;
    let _e355 = Fss;
    let _e356 = Ess;
    let _e359 = Ess;
    return (vec3(1f) + ((_e355 * (1f - _e356)) / vec3(_e359)));
}

fn mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(ior_3: ptr<function, vec3<f32>>, extinction: ptr<function, vec3<f32>>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_6: FresnelData;

    fd_6.model = 1i;
    let _e346 = (*tf_thickness);
    fd_6.airy = (_e346 > 0f);
    let _e349 = (*ior_3);
    fd_6.ior = _e349;
    let _e351 = (*extinction);
    fd_6.extinction = _e351;
    fd_6.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_6.exponent = 0f;
    let _e357 = (*tf_thickness);
    fd_6.tf_thickness = _e357;
    let _e359 = (*tf_ior);
    fd_6.tf_ior = _e359;
    fd_6.refraction = false;
    let _e362 = fd_6;
    return _e362;
}

fn mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_12: ptr<function, ClosureData>, weight_5: ptr<function, f32>, ior_n: ptr<function, vec3<f32>>, ior_k: ptr<function, vec3<f32>>, roughness_14: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_14: ptr<function, vec3<f32>>, X_3: ptr<function, vec3<f32>>, distribution_1: ptr<function, i32>, bsdf_4: ptr<function, BSDF>) {
    var V_10: vec3<f32>;
    var L_8: vec3<f32>;
    var local_10: vec3<f32>;
    var param_212: vec3<f32>;
    var param_213: vec3<f32>;
    var NdotV_19: f32;
    var fd_7: FresnelData;
    var param_214: vec3<f32>;
    var param_215: vec3<f32>;
    var param_216: f32;
    var param_217: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_218: vec2<f32>;
    var Y_3: vec3<f32>;
    var H_5: vec3<f32>;
    var NdotL_9: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_2: vec3<f32>;
    var param_219: f32;
    var param_220: FresnelData;
    var D_1: f32;
    var param_221: vec3<f32>;
    var param_222: vec2<f32>;
    var G_3: f32;
    var param_223: f32;
    var param_224: f32;
    var param_225: f32;
    var comp: vec3<f32>;
    var param_226: f32;
    var param_227: f32;
    var param_228: FresnelData;
    var comp_1: vec3<f32>;
    var param_229: f32;
    var param_230: f32;
    var param_231: FresnelData;
    var Li_5: vec3<f32>;
    var param_232: vec3<f32>;
    var param_233: vec3<f32>;
    var param_234: vec3<f32>;
    var param_235: vec2<f32>;
    var param_236: i32;
    var param_237: FresnelData;

    (*bsdf_4).throughput = vec3<f32>(0f, 0f, 0f);
    let _e397 = (*weight_5);
    if (_e397 < 0.00000001f) {
        return;
    }
    let _e400 = (*closureData_12).V;
    V_10 = _e400;
    let _e402 = (*closureData_12).L;
    L_8 = _e402;
    let _e403 = (*retroreflective);
    if _e403 {
        let _e404 = V_10;
        let _e406 = (*N_14);
        local_10 = reflect(-(_e404), _e406);
    } else {
        let _e408 = V_10;
        local_10 = _e408;
    }
    let _e409 = local_10;
    V_10 = _e409;
    let _e410 = (*N_14);
    param_212 = _e410;
    let _e411 = V_10;
    param_213 = _e411;
    let _e412 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_212), (&param_213));
    (*N_14) = _e412;
    let _e413 = (*N_14);
    let _e414 = V_10;
    NdotV_19 = clamp(dot(_e413, _e414), 0.00000001f, 1f);
    let _e417 = (*ior_n);
    param_214 = _e417;
    let _e418 = (*ior_k);
    param_215 = _e418;
    let _e419 = (*thinfilm_thickness);
    param_216 = _e419;
    let _e420 = (*thinfilm_ior);
    param_217 = _e420;
    let _e421 = mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_214), (&param_215), (&param_216), (&param_217));
    fd_7 = _e421;
    let _e422 = (*roughness_14);
    safeAlpha = clamp(_e422, vec2(0.00000001f), vec2(1f));
    let _e426 = safeAlpha;
    param_218 = _e426;
    let _e427 = mx_average_alpha_u0028_vf2_u003b((&param_218));
    avgAlpha_1 = _e427;
    let _e429 = (*closureData_12).closureType;
    if (_e429 == 1i) {
        let _e431 = (*X_3);
        let _e432 = (*X_3);
        let _e433 = (*N_14);
        let _e435 = (*N_14);
        (*X_3) = normalize((_e431 - (_e435 * dot(_e432, _e433))));
        let _e439 = (*N_14);
        let _e440 = (*X_3);
        Y_3 = cross(_e439, _e440);
        let _e442 = L_8;
        let _e443 = V_10;
        H_5 = normalize((_e442 + _e443));
        let _e446 = (*N_14);
        let _e447 = L_8;
        NdotL_9 = clamp(dot(_e446, _e447), 0.00000001f, 1f);
        let _e450 = V_10;
        let _e451 = H_5;
        VdotH_1 = clamp(dot(_e450, _e451), 0.00000001f, 1f);
        let _e454 = H_5;
        let _e455 = (*X_3);
        let _e457 = H_5;
        let _e458 = Y_3;
        let _e460 = H_5;
        let _e461 = (*N_14);
        Ht = vec3<f32>(dot(_e454, _e455), dot(_e457, _e458), dot(_e460, _e461));
        let _e464 = VdotH_1;
        param_219 = _e464;
        let _e465 = fd_7;
        param_220 = _e465;
        let _e466 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_219), (&param_220));
        F_2 = _e466;
        let _e467 = Ht;
        param_221 = _e467;
        let _e468 = safeAlpha;
        param_222 = _e468;
        let _e469 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_221), (&param_222));
        D_1 = _e469;
        let _e470 = NdotL_9;
        param_223 = _e470;
        let _e471 = NdotV_19;
        param_224 = _e471;
        let _e472 = avgAlpha_1;
        param_225 = _e472;
        let _e473 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_223), (&param_224), (&param_225));
        G_3 = _e473;
        let _e474 = NdotV_19;
        param_226 = _e474;
        let _e475 = avgAlpha_1;
        param_227 = _e475;
        let _e476 = fd_7;
        param_228 = _e476;
        let _e477 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_226), (&param_227), (&param_228));
        comp = _e477;
        let _e478 = D_1;
        let _e479 = F_2;
        let _e481 = G_3;
        let _e483 = comp;
        let _e486 = (*closureData_12).occlusion;
        let _e488 = (*weight_5);
        let _e490 = NdotV_19;
        (*bsdf_4).response = ((((((_e479 * _e478) * _e481) * _e483) * _e486) * _e488) / vec3((4f * _e490)));
    } else {
        let _e496 = (*closureData_12).closureType;
        if (_e496 == 3i) {
            let _e498 = NdotV_19;
            param_229 = _e498;
            let _e499 = avgAlpha_1;
            param_230 = _e499;
            let _e500 = fd_7;
            param_231 = _e500;
            let _e501 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_229), (&param_230), (&param_231));
            comp_1 = _e501;
            let _e502 = (*N_14);
            param_232 = _e502;
            let _e503 = V_10;
            param_233 = _e503;
            let _e504 = (*X_3);
            param_234 = _e504;
            let _e505 = safeAlpha;
            param_235 = _e505;
            let _e506 = (*distribution_1);
            param_236 = _e506;
            let _e507 = fd_7;
            param_237 = _e507;
            let _e508 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_232), (&param_233), (&param_234), (&param_235), (&param_236), (&param_237));
            Li_5 = _e508;
            let _e509 = Li_5;
            let _e510 = comp_1;
            let _e512 = (*weight_5);
            (*bsdf_4).response = ((_e509 * _e510) * _e512);
        }
    }
    return;
}

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_15: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, X_4: ptr<function, vec3<f32>>, alpha_11: ptr<function, vec2<f32>>, distribution_2: ptr<function, i32>, fd_8: ptr<function, FresnelData>, tint_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_238: vec3<f32>;
    var param_239: vec3<f32>;
    var param_240: vec3<f32>;
    var param_241: vec3<f32>;
    var param_242: vec2<f32>;
    var param_243: i32;
    var param_244: FresnelData;

    (*fd_8).refraction = true;
    if false {
        let _e355 = (*tint_1);
        param_238 = _e355;
        let _e356 = mx_square_u0028_vf3_u003b((&param_238));
        (*tint_1) = _e356;
    }
    let _e357 = (*N_15);
    param_239 = _e357;
    let _e358 = (*V_11);
    param_240 = _e358;
    let _e359 = (*X_4);
    param_241 = _e359;
    let _e360 = (*alpha_11);
    param_242 = _e360;
    let _e361 = (*distribution_2);
    param_243 = _e361;
    let _e362 = (*fd_8);
    param_244 = _e362;
    let _e363 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_239), (&param_240), (&param_241), (&param_242), (&param_243), (&param_244));
    let _e364 = (*tint_1);
    return (_e363 * _e364);
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_4: ptr<function, f32>) -> f32 {
    var param_245: f32;

    let _e342 = (*ior_4);
    let _e344 = (*ior_4);
    param_245 = ((_e342 - 1f) / (_e344 + 1f));
    let _e347 = mx_square_u0028_f1_u003b((&param_245));
    return _e347;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_5: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e345 = (*tf_thickness_1);
    fd_9.airy = (_e345 > 0f);
    let _e348 = (*ior_5);
    fd_9.ior = vec3(_e348);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e356 = (*tf_thickness_1);
    fd_9.tf_thickness = _e356;
    let _e358 = (*tf_ior_1);
    fd_9.tf_ior = _e358;
    fd_9.refraction = false;
    let _e361 = fd_9;
    return _e361;
}

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_13: ptr<function, ClosureData>, weight_6: ptr<function, f32>, tint_2: ptr<function, vec3<f32>>, ior_6: ptr<function, f32>, roughness_15: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_16: ptr<function, vec3<f32>>, X_5: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_5: ptr<function, BSDF>) {
    var V_12: vec3<f32>;
    var L_9: vec3<f32>;
    var param_246: vec3<f32>;
    var param_247: vec3<f32>;
    var NdotV_20: f32;
    var fd_10: FresnelData;
    var param_248: f32;
    var param_249: f32;
    var param_250: f32;
    var F0_6: f32;
    var param_251: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_252: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_4: vec3<f32>;
    var H_6: vec3<f32>;
    var NdotL_10: f32;
    var VdotH_2: f32;
    var Ht_1: vec3<f32>;
    var F_3: vec3<f32>;
    var param_253: f32;
    var param_254: FresnelData;
    var D_2: f32;
    var param_255: vec3<f32>;
    var param_256: vec2<f32>;
    var G_4: f32;
    var param_257: f32;
    var param_258: f32;
    var param_259: f32;
    var comp_2: vec3<f32>;
    var param_260: f32;
    var param_261: f32;
    var param_262: FresnelData;
    var dirAlbedo_5: vec3<f32>;
    var param_263: f32;
    var param_264: f32;
    var param_265: f32;
    var param_266: f32;
    var comp_3: vec3<f32>;
    var param_267: f32;
    var param_268: f32;
    var param_269: FresnelData;
    var dirAlbedo_6: vec3<f32>;
    var param_270: f32;
    var param_271: f32;
    var param_272: f32;
    var param_273: f32;
    var param_274: vec3<f32>;
    var param_275: vec3<f32>;
    var param_276: vec3<f32>;
    var param_277: vec2<f32>;
    var param_278: i32;
    var param_279: FresnelData;
    var param_280: vec3<f32>;
    var comp_4: vec3<f32>;
    var param_281: f32;
    var param_282: f32;
    var param_283: FresnelData;
    var dirAlbedo_7: vec3<f32>;
    var param_284: f32;
    var param_285: f32;
    var param_286: f32;
    var param_287: f32;
    var Li_6: vec3<f32>;
    var param_288: vec3<f32>;
    var param_289: vec3<f32>;
    var param_290: vec3<f32>;
    var param_291: vec2<f32>;
    var param_292: i32;
    var param_293: FresnelData;
    var phi_4398_: bool;

    let _e424 = (*weight_6);
    if (_e424 < 0.00000001f) {
        return;
    }
    let _e427 = (*closureData_13).closureType;
    let _e429 = (*scatter_mode);
    if ((_e427 != 2i) && (_e429 == 1i)) {
        return;
    }
    let _e433 = (*closureData_13).V;
    V_12 = _e433;
    let _e435 = (*closureData_13).L;
    L_9 = _e435;
    let _e436 = (*retroreflective_1);
    phi_4398_ = _e436;
    if _e436 {
        let _e438 = (*closureData_13).closureType;
        phi_4398_ = (_e438 != 2i);
    }
    let _e441 = phi_4398_;
    if _e441 {
        let _e442 = V_12;
        let _e444 = (*N_16);
        V_12 = reflect(-(_e442), _e444);
    }
    let _e446 = (*N_16);
    param_246 = _e446;
    let _e447 = V_12;
    param_247 = _e447;
    let _e448 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_246), (&param_247));
    (*N_16) = _e448;
    let _e449 = (*N_16);
    let _e450 = V_12;
    NdotV_20 = clamp(dot(_e449, _e450), 0.00000001f, 1f);
    let _e453 = (*ior_6);
    param_248 = _e453;
    let _e454 = (*thinfilm_thickness_1);
    param_249 = _e454;
    let _e455 = (*thinfilm_ior_1);
    param_250 = _e455;
    let _e456 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_248), (&param_249), (&param_250));
    fd_10 = _e456;
    let _e457 = (*ior_6);
    param_251 = _e457;
    let _e458 = mx_ior_to_f0_u0028_f1_u003b((&param_251));
    F0_6 = _e458;
    let _e459 = (*roughness_15);
    safeAlpha_1 = clamp(_e459, vec2(0.00000001f), vec2(1f));
    let _e463 = safeAlpha_1;
    param_252 = _e463;
    let _e464 = mx_average_alpha_u0028_vf2_u003b((&param_252));
    avgAlpha_2 = _e464;
    let _e465 = (*tint_2);
    safeTint = max(_e465, vec3(0f));
    let _e469 = (*closureData_13).closureType;
    if (_e469 == 1i) {
        let _e471 = (*X_5);
        let _e472 = (*X_5);
        let _e473 = (*N_16);
        let _e475 = (*N_16);
        (*X_5) = normalize((_e471 - (_e475 * dot(_e472, _e473))));
        let _e479 = (*N_16);
        let _e480 = (*X_5);
        Y_4 = cross(_e479, _e480);
        let _e482 = L_9;
        let _e483 = V_12;
        H_6 = normalize((_e482 + _e483));
        let _e486 = (*N_16);
        let _e487 = L_9;
        NdotL_10 = clamp(dot(_e486, _e487), 0.00000001f, 1f);
        let _e490 = V_12;
        let _e491 = H_6;
        VdotH_2 = clamp(dot(_e490, _e491), 0.00000001f, 1f);
        let _e494 = H_6;
        let _e495 = (*X_5);
        let _e497 = H_6;
        let _e498 = Y_4;
        let _e500 = H_6;
        let _e501 = (*N_16);
        Ht_1 = vec3<f32>(dot(_e494, _e495), dot(_e497, _e498), dot(_e500, _e501));
        let _e504 = VdotH_2;
        param_253 = _e504;
        let _e505 = fd_10;
        param_254 = _e505;
        let _e506 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254));
        F_3 = _e506;
        let _e507 = Ht_1;
        param_255 = _e507;
        let _e508 = safeAlpha_1;
        param_256 = _e508;
        let _e509 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_255), (&param_256));
        D_2 = _e509;
        let _e510 = NdotL_10;
        param_257 = _e510;
        let _e511 = NdotV_20;
        param_258 = _e511;
        let _e512 = avgAlpha_2;
        param_259 = _e512;
        let _e513 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_257), (&param_258), (&param_259));
        G_4 = _e513;
        let _e514 = NdotV_20;
        param_260 = _e514;
        let _e515 = avgAlpha_2;
        param_261 = _e515;
        let _e516 = fd_10;
        param_262 = _e516;
        let _e517 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_260), (&param_261), (&param_262));
        comp_2 = _e517;
        let _e518 = NdotV_20;
        param_263 = _e518;
        let _e519 = avgAlpha_2;
        param_264 = _e519;
        let _e520 = F0_6;
        param_265 = _e520;
        param_266 = 1f;
        let _e521 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_263), (&param_264), (&param_265), (&param_266));
        let _e522 = comp_2;
        dirAlbedo_5 = (_e522 * _e521);
        let _e524 = dirAlbedo_5;
        let _e525 = (*weight_6);
        (*bsdf_5).throughput = (vec3(1f) - (_e524 * _e525));
        let _e530 = D_2;
        let _e531 = F_3;
        let _e533 = G_4;
        let _e535 = comp_2;
        let _e537 = safeTint;
        let _e540 = (*closureData_13).occlusion;
        let _e542 = (*weight_6);
        let _e544 = NdotV_20;
        (*bsdf_5).response = (((((((_e531 * _e530) * _e533) * _e535) * _e537) * _e540) * _e542) / vec3((4f * _e544)));
    } else {
        let _e550 = (*closureData_13).closureType;
        if (_e550 == 2i) {
            let _e552 = NdotV_20;
            param_267 = _e552;
            let _e553 = avgAlpha_2;
            param_268 = _e553;
            let _e554 = fd_10;
            param_269 = _e554;
            let _e555 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
            comp_3 = _e555;
            let _e556 = NdotV_20;
            param_270 = _e556;
            let _e557 = avgAlpha_2;
            param_271 = _e557;
            let _e558 = F0_6;
            param_272 = _e558;
            param_273 = 1f;
            let _e559 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
            let _e560 = comp_3;
            dirAlbedo_6 = (_e560 * _e559);
            let _e562 = dirAlbedo_6;
            let _e563 = (*weight_6);
            (*bsdf_5).throughput = (vec3(1f) - (_e562 * _e563));
            let _e568 = (*scatter_mode);
            if (_e568 != 0i) {
                let _e570 = (*N_16);
                param_274 = _e570;
                let _e571 = V_12;
                param_275 = _e571;
                let _e572 = (*X_5);
                param_276 = _e572;
                let _e573 = safeAlpha_1;
                param_277 = _e573;
                let _e574 = (*distribution_3);
                param_278 = _e574;
                let _e575 = fd_10;
                param_279 = _e575;
                let _e576 = safeTint;
                param_280 = _e576;
                let _e577 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279), (&param_280));
                let _e578 = (*weight_6);
                (*bsdf_5).response = (_e577 * _e578);
            }
        } else {
            let _e582 = (*closureData_13).closureType;
            if (_e582 == 3i) {
                let _e584 = NdotV_20;
                param_281 = _e584;
                let _e585 = avgAlpha_2;
                param_282 = _e585;
                let _e586 = fd_10;
                param_283 = _e586;
                let _e587 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_281), (&param_282), (&param_283));
                comp_4 = _e587;
                let _e588 = NdotV_20;
                param_284 = _e588;
                let _e589 = avgAlpha_2;
                param_285 = _e589;
                let _e590 = F0_6;
                param_286 = _e590;
                param_287 = 1f;
                let _e591 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_284), (&param_285), (&param_286), (&param_287));
                let _e592 = comp_4;
                dirAlbedo_7 = (_e592 * _e591);
                let _e594 = dirAlbedo_7;
                let _e595 = (*weight_6);
                (*bsdf_5).throughput = (vec3(1f) - (_e594 * _e595));
                let _e600 = (*N_16);
                param_288 = _e600;
                let _e601 = V_12;
                param_289 = _e601;
                let _e602 = (*X_5);
                param_290 = _e602;
                let _e603 = safeAlpha_1;
                param_291 = _e603;
                let _e604 = (*distribution_3);
                param_292 = _e604;
                let _e605 = fd_10;
                param_293 = _e605;
                let _e606 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_288), (&param_289), (&param_290), (&param_291), (&param_292), (&param_293));
                Li_6 = _e606;
                let _e607 = Li_6;
                let _e608 = safeTint;
                let _e610 = comp_4;
                let _e612 = (*weight_6);
                (*bsdf_5).response = (((_e607 * _e608) * _e610) * _e612);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e346 = (*closureType);
    let _e347 = (*L_10);
    let _e348 = (*V_13);
    let _e349 = (*N_17);
    let _e350 = (*P_2);
    let _e351 = (*occlusion_1);
    return ClosureData(_e346, _e347, _e348, _e349, _e350, _e351);
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_4: ptr<function, f32>, out1_: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e343 = (*in1_4);
    combine_out = vec3(_e343);
    let _e345 = combine_out;
    (*out1_) = _e345;
    return;
}

fn mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(reflectivity: ptr<function, vec3<f32>>, edge_color: ptr<function, vec3<f32>>, ior_7: ptr<function, vec3<f32>>, extinction_1: ptr<function, vec3<f32>>) {
    var r_3: vec3<f32>;
    var r_sqrt: vec3<f32>;
    var n_min: vec3<f32>;
    var n_max: vec3<f32>;
    var np1_: vec3<f32>;
    var nm1_: vec3<f32>;
    var k2_2: vec3<f32>;

    let _e351 = (*reflectivity);
    r_3 = clamp(_e351, vec3(0f), vec3(0.99f));
    let _e355 = r_3;
    r_sqrt = sqrt(_e355);
    let _e357 = r_3;
    let _e360 = r_3;
    n_min = ((vec3(1f) - _e357) / (vec3(1f) + _e360));
    let _e364 = r_sqrt;
    let _e367 = r_sqrt;
    n_max = ((vec3(1f) + _e364) / (vec3(1f) - _e367));
    let _e371 = n_max;
    let _e372 = n_min;
    let _e373 = (*edge_color);
    (*ior_7) = mix(_e371, _e372, _e373);
    let _e375 = (*ior_7);
    np1_ = (_e375 + vec3(1f));
    let _e378 = (*ior_7);
    nm1_ = (_e378 - vec3(1f));
    let _e381 = np1_;
    let _e382 = np1_;
    let _e384 = r_3;
    let _e386 = nm1_;
    let _e387 = nm1_;
    let _e390 = r_3;
    k2_2 = ((((_e381 * _e382) * _e384) - (_e386 * _e387)) / (vec3(1f) - _e390));
    let _e394 = k2_2;
    k2_2 = max(_e394, vec3(0f));
    let _e397 = k2_2;
    (*extinction_1) = sqrt(_e397);
    return;
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_8: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e348 = (*axis);
    (*axis) = normalize(_e348);
    let _e350 = (*amount);
    rotationRadians = radians(_e350);
    let _e352 = rotationRadians;
    s_4 = sin(_e352);
    let _e354 = rotationRadians;
    c_3 = cos(_e354);
    let _e356 = c_3;
    oc = (1f - _e356);
    let _e358 = (*_in);
    let _e359 = c_3;
    let _e361 = (*_in);
    let _e362 = (*axis);
    let _e364 = s_4;
    let _e367 = (*axis);
    let _e368 = (*axis);
    let _e369 = (*_in);
    let _e372 = oc;
    (*result_8) = (((_e358 * _e359) + (cross(_e361, _e362) * _e364)) + ((_e367 * dot(_e368, _e369)) * _e372));
    return;
}

fn mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b(_in_1: ptr<function, vec3<f32>>, lumacoeffs: ptr<function, vec3<f32>>, result_9: ptr<function, vec3<f32>>) {
    let _e343 = (*_in_1);
    let _e344 = (*lumacoeffs);
    (*result_9) = vec3(dot(_e343, _e344));
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_1: ptr<function, f32>, result_10: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e345 = (*roughness_16);
    let _e346 = (*roughness_16);
    roughness_sqr = clamp((_e345 * _e346), 0.00000001f, 1f);
    let _e349 = (*anisotropy_1);
    if (_e349 > 0f) {
        let _e351 = (*anisotropy_1);
        aspect = sqrt((1f - clamp(_e351, 0f, 0.98f)));
        let _e355 = roughness_sqr;
        let _e356 = aspect;
        (*result_10)[0u] = min((_e355 / _e356), 1f);
        let _e360 = roughness_sqr;
        let _e361 = aspect;
        (*result_10)[1u] = (_e360 * _e361);
    } else {
        let _e364 = roughness_sqr;
        (*result_10)[0u] = _e364;
        let _e366 = roughness_sqr;
        (*result_10)[1u] = _e366;
    }
    return;
}

fn NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_2: ptr<function, f32>, base_color: ptr<function, vec3<f32>>, diffuse_roughness: ptr<function, f32>, metalness: ptr<function, f32>, specular: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, specular_roughness: ptr<function, f32>, specular_IOR: ptr<function, f32>, specular_anisotropy: ptr<function, f32>, specular_rotation: ptr<function, f32>, transmission: ptr<function, f32>, transmission_color: ptr<function, vec3<f32>>, transmission_depth: ptr<function, f32>, transmission_scatter: ptr<function, vec3<f32>>, transmission_scatter_anisotropy: ptr<function, f32>, transmission_dispersion: ptr<function, f32>, transmission_extra_roughness: ptr<function, f32>, subsurface: ptr<function, f32>, subsurface_color: ptr<function, vec3<f32>>, subsurface_radius: ptr<function, vec3<f32>>, subsurface_scale: ptr<function, f32>, subsurface_anisotropy: ptr<function, f32>, sheen: ptr<function, f32>, sheen_color: ptr<function, vec3<f32>>, sheen_roughness: ptr<function, f32>, coat: ptr<function, f32>, coat_color: ptr<function, vec3<f32>>, coat_roughness: ptr<function, f32>, coat_anisotropy: ptr<function, f32>, coat_rotation: ptr<function, f32>, coat_IOR: ptr<function, f32>, coat_normal: ptr<function, vec3<f32>>, coat_affect_color: ptr<function, f32>, coat_affect_roughness: ptr<function, f32>, thin_film_thickness: ptr<function, f32>, thin_film_IOR: ptr<function, f32>, emission: ptr<function, f32>, emission_color: ptr<function, vec3<f32>>, opacity: ptr<function, vec3<f32>>, thin_walled: ptr<function, bool>, normal: ptr<function, vec3<f32>>, tangent: ptr<function, vec3<f32>>, out1_1: ptr<function, surfaceshader>) {
    var coat_roughness_vector_out: vec2<f32>;
    var param_294: f32;
    var param_295: f32;
    var param_296: vec2<f32>;
    var coat_tangent_rotate_degree_out: f32;
    var metalness_mix_fg_weight_out: f32;
    var metal_reflectivity_out: vec3<f32>;
    var metal_edgecolor_out: vec3<f32>;
    var coat_affect_roughness_multiply1_out: f32;
    var tangent_rotate_degree_out: f32;
    var transmission_mix_fg_weight_out: f32;
    var transmission_roughness_add_out: f32;
    var subsurface_selector_out: f32;
    var subsurface_color_nonnegative_out: vec3<f32>;
    var coat_clamped_out: f32;
    var subsurface_radius_scaled_out: vec3<f32>;
    var subsurface_mix_mix_inv_out: f32;
    var base_color_nonnegative_out: vec3<f32>;
    var transmission_mix_mix_inv_out: f32;
    var metalness_mix_mix_inv_out: f32;
    var coat_attenuation_out: vec3<f32>;
    var one_minus_coat_ior_out: f32;
    var one_plus_coat_ior_out: f32;
    var emission_weight_out: vec3<f32>;
    var opacity_luminance_out: vec3<f32>;
    var param_297: vec3<f32>;
    var param_298: vec3<f32>;
    var param_299: vec3<f32>;
    var coat_tangent_rotate_out: vec3<f32>;
    var param_300: vec3<f32>;
    var param_301: f32;
    var param_302: vec3<f32>;
    var param_303: vec3<f32>;
    var artistic_ior_ior: vec3<f32>;
    var artistic_ior_extinction: vec3<f32>;
    var param_304: vec3<f32>;
    var param_305: vec3<f32>;
    var param_306: vec3<f32>;
    var param_307: vec3<f32>;
    var coat_affect_roughness_multiply2_out: f32;
    var tangent_rotate_out: vec3<f32>;
    var param_308: vec3<f32>;
    var param_309: f32;
    var param_310: vec3<f32>;
    var param_311: vec3<f32>;
    var transmission_roughness_clamped_out: f32;
    var selected_subsurface_bsdf_mix_inv_out: f32;
    var selected_subsurface_bsdf_fg_weight_out: f32;
    var coat_gamma_multiply_out: f32;
    var subsurface_mix_bg_weight_out: f32;
    var coat_ior_to_F0_sqrt_out: f32;
    var opacity_luminance_float_out: f32;
    var coat_tangent_rotate_normalize_out: vec3<f32>;
    var coat_affected_roughness_out: f32;
    var tangent_rotate_normalize_out: vec3<f32>;
    var coat_affected_transmission_roughness_out: f32;
    var selected_subsurface_bsdf_bg_weight_out: f32;
    var coat_gamma_out: f32;
    var coat_ior_to_F0_out: f32;
    var coat_tangent_out: vec3<f32>;
    var main_roughness_out: vec2<f32>;
    var param_312: f32;
    var param_313: f32;
    var param_314: vec2<f32>;
    var main_tangent_out: vec3<f32>;
    var transmission_roughness_out: vec2<f32>;
    var param_315: f32;
    var param_316: f32;
    var param_317: vec2<f32>;
    var coat_affected_subsurface_color_out: vec3<f32>;
    var coat_affected_diffuse_color_out: vec3<f32>;
    var one_minus_coat_ior_to_F0_out: f32;
    var emission_color0_out: vec3<f32>;
    var param_318: f32;
    var param_319: vec3<f32>;
    var shader_constructor_out: surfaceshader;
    var N_18: vec3<f32>;
    var V_14: vec3<f32>;
    var L_11: vec3<f32>;
    var P_3: vec3<f32>;
    var occlusion_2: f32;
    var closureData_14: ClosureData;
    var param_320: i32;
    var param_321: vec3<f32>;
    var param_322: vec3<f32>;
    var param_323: vec3<f32>;
    var param_324: vec3<f32>;
    var param_325: f32;
    var coat_bsdf_out: BSDF;
    var param_326: ClosureData;
    var param_327: f32;
    var param_328: vec3<f32>;
    var param_329: f32;
    var param_330: vec2<f32>;
    var param_331: bool;
    var param_332: f32;
    var param_333: f32;
    var param_334: vec3<f32>;
    var param_335: vec3<f32>;
    var param_336: i32;
    var param_337: i32;
    var param_338: BSDF;
    var metal_bsdf_out: BSDF;
    var param_339: ClosureData;
    var param_340: f32;
    var param_341: vec3<f32>;
    var param_342: vec3<f32>;
    var param_343: vec2<f32>;
    var param_344: bool;
    var param_345: f32;
    var param_346: f32;
    var param_347: vec3<f32>;
    var param_348: vec3<f32>;
    var param_349: i32;
    var param_350: BSDF;
    var specular_bsdf_out: BSDF;
    var param_351: ClosureData;
    var param_352: f32;
    var param_353: vec3<f32>;
    var param_354: f32;
    var param_355: vec2<f32>;
    var param_356: bool;
    var param_357: f32;
    var param_358: f32;
    var param_359: vec3<f32>;
    var param_360: vec3<f32>;
    var param_361: i32;
    var param_362: i32;
    var param_363: BSDF;
    var transmission_bsdf_out: BSDF;
    var param_364: ClosureData;
    var param_365: f32;
    var param_366: vec3<f32>;
    var param_367: f32;
    var param_368: vec2<f32>;
    var param_369: bool;
    var param_370: f32;
    var param_371: f32;
    var param_372: vec3<f32>;
    var param_373: vec3<f32>;
    var param_374: i32;
    var param_375: i32;
    var param_376: BSDF;
    var sheen_bsdf_out: BSDF;
    var param_377: ClosureData;
    var param_378: f32;
    var param_379: vec3<f32>;
    var param_380: f32;
    var param_381: vec3<f32>;
    var param_382: i32;
    var param_383: BSDF;
    var translucent_bsdf_out: BSDF;
    var param_384: ClosureData;
    var param_385: f32;
    var param_386: vec3<f32>;
    var param_387: vec3<f32>;
    var param_388: BSDF;
    var subsurface_bsdf_out: BSDF;
    var param_389: ClosureData;
    var param_390: f32;
    var param_391: vec3<f32>;
    var param_392: vec3<f32>;
    var param_393: f32;
    var param_394: vec3<f32>;
    var param_395: BSDF;
    var selected_subsurface_bsdf_add_out: BSDF;
    var param_396: ClosureData;
    var param_397: BSDF;
    var param_398: BSDF;
    var param_399: BSDF;
    var subsurface_mix_fg_mul_out: BSDF;
    var param_400: ClosureData;
    var param_401: BSDF;
    var param_402: f32;
    var param_403: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_404: ClosureData;
    var param_405: f32;
    var param_406: vec3<f32>;
    var param_407: f32;
    var param_408: vec3<f32>;
    var param_409: bool;
    var param_410: BSDF;
    var subsurface_mix_add_out: BSDF;
    var param_411: ClosureData;
    var param_412: BSDF;
    var param_413: BSDF;
    var param_414: BSDF;
    var sheen_layer_out: BSDF;
    var param_415: ClosureData;
    var param_416: BSDF;
    var param_417: BSDF;
    var param_418: BSDF;
    var transmission_mix_bg_mul_out: BSDF;
    var param_419: ClosureData;
    var param_420: BSDF;
    var param_421: f32;
    var param_422: BSDF;
    var transmission_mix_add_out: BSDF;
    var param_423: ClosureData;
    var param_424: BSDF;
    var param_425: BSDF;
    var param_426: BSDF;
    var specular_layer_out: BSDF;
    var param_427: ClosureData;
    var param_428: BSDF;
    var param_429: BSDF;
    var param_430: BSDF;
    var metalness_mix_bg_mul_out: BSDF;
    var param_431: ClosureData;
    var param_432: BSDF;
    var param_433: f32;
    var param_434: BSDF;
    var metalness_mix_add_out: BSDF;
    var param_435: ClosureData;
    var param_436: BSDF;
    var param_437: BSDF;
    var param_438: BSDF;
    var thin_film_layer_attenuated_out: BSDF;
    var param_439: ClosureData;
    var param_440: BSDF;
    var param_441: vec3<f32>;
    var param_442: BSDF;
    var coat_layer_out: BSDF;
    var param_443: ClosureData;
    var param_444: BSDF;
    var param_445: BSDF;
    var param_446: BSDF;
    var closureData_15: ClosureData;
    var param_447: i32;
    var param_448: vec3<f32>;
    var param_449: vec3<f32>;
    var param_450: vec3<f32>;
    var param_451: vec3<f32>;
    var param_452: f32;
    var emission_edf_out: vec3<f32>;
    var param_453: ClosureData;
    var param_454: vec3<f32>;
    var param_455: vec3<f32>;
    var coat_tinted_emission_edf_out: vec3<f32>;
    var param_456: ClosureData;
    var param_457: vec3<f32>;
    var param_458: vec3<f32>;
    var param_459: vec3<f32>;
    var coat_emission_edf_out: vec3<f32>;
    var param_460: ClosureData;
    var param_461: vec3<f32>;
    var param_462: vec3<f32>;
    var param_463: f32;
    var param_464: vec3<f32>;
    var param_465: vec3<f32>;
    var blended_coat_emission_edf_out: vec3<f32>;
    var param_466: ClosureData;
    var param_467: vec3<f32>;
    var param_468: vec3<f32>;
    var param_469: f32;
    var param_470: vec3<f32>;

    coat_roughness_vector_out = vec2<f32>(0f, 0f);
    let _e640 = (*coat_roughness);
    param_294 = _e640;
    let _e641 = (*coat_anisotropy);
    param_295 = _e641;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_294), (&param_295), (&param_296));
    let _e642 = param_296;
    coat_roughness_vector_out = _e642;
    let _e643 = (*coat_rotation);
    coat_tangent_rotate_degree_out = (_e643 * 360f);
    let _e645 = (*metalness);
    metalness_mix_fg_weight_out = (1f * _e645);
    let _e647 = (*base_color);
    let _e648 = (*base_2);
    metal_reflectivity_out = (_e647 * _e648);
    let _e650 = (*specular_color);
    let _e651 = (*specular);
    metal_edgecolor_out = (_e650 * _e651);
    let _e653 = (*coat_affect_roughness);
    let _e654 = (*coat);
    coat_affect_roughness_multiply1_out = (_e653 * _e654);
    let _e656 = (*specular_rotation);
    tangent_rotate_degree_out = (_e656 * 360f);
    let _e658 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e658);
    let _e660 = (*specular_roughness);
    let _e661 = (*transmission_extra_roughness);
    transmission_roughness_add_out = (_e660 + _e661);
    let _e663 = (*thin_walled);
    subsurface_selector_out = select(0f, 1f, _e663);
    let _e665 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e665, vec3(0f));
    let _e668 = (*coat);
    coat_clamped_out = clamp(_e668, 0f, 1f);
    let _e670 = (*subsurface_radius);
    let _e671 = (*subsurface_scale);
    subsurface_radius_scaled_out = (_e670 * _e671);
    let _e673 = (*subsurface);
    subsurface_mix_mix_inv_out = (1f - _e673);
    let _e675 = (*base_color);
    base_color_nonnegative_out = max(_e675, vec3(0f));
    let _e678 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e678);
    let _e680 = (*metalness);
    metalness_mix_mix_inv_out = (1f - _e680);
    let _e682 = (*coat_color);
    let _e683 = (*coat);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e682, vec3(_e683));
    let _e686 = (*coat_IOR);
    one_minus_coat_ior_out = (1f - _e686);
    let _e688 = (*coat_IOR);
    one_plus_coat_ior_out = (1f + _e688);
    let _e690 = (*emission_color);
    let _e691 = (*emission);
    emission_weight_out = (_e690 * _e691);
    opacity_luminance_out = vec3<f32>(0f, 0f, 0f);
    let _e693 = (*opacity);
    param_297 = _e693;
    param_298 = vec3<f32>(0.272229f, 0.674082f, 0.053689f);
    mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_297), (&param_298), (&param_299));
    let _e694 = param_299;
    opacity_luminance_out = _e694;
    coat_tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e695 = (*tangent);
    param_300 = _e695;
    let _e696 = coat_tangent_rotate_degree_out;
    param_301 = _e696;
    let _e697 = (*coat_normal);
    param_302 = _e697;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_300), (&param_301), (&param_302), (&param_303));
    let _e698 = param_303;
    coat_tangent_rotate_out = _e698;
    artistic_ior_ior = vec3<f32>(0f, 0f, 0f);
    artistic_ior_extinction = vec3<f32>(0f, 0f, 0f);
    let _e699 = metal_reflectivity_out;
    param_304 = _e699;
    let _e700 = metal_edgecolor_out;
    param_305 = _e700;
    mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_304), (&param_305), (&param_306), (&param_307));
    let _e701 = param_306;
    artistic_ior_ior = _e701;
    let _e702 = param_307;
    artistic_ior_extinction = _e702;
    let _e703 = coat_affect_roughness_multiply1_out;
    let _e704 = (*coat_roughness);
    coat_affect_roughness_multiply2_out = (_e703 * _e704);
    tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e706 = (*tangent);
    param_308 = _e706;
    let _e707 = tangent_rotate_degree_out;
    param_309 = _e707;
    let _e708 = (*normal);
    param_310 = _e708;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_308), (&param_309), (&param_310), (&param_311));
    let _e709 = param_311;
    tangent_rotate_out = _e709;
    let _e710 = transmission_roughness_add_out;
    transmission_roughness_clamped_out = clamp(_e710, 0f, 1f);
    let _e712 = subsurface_selector_out;
    selected_subsurface_bsdf_mix_inv_out = (1f - _e712);
    let _e714 = subsurface_selector_out;
    selected_subsurface_bsdf_fg_weight_out = (1f * _e714);
    let _e716 = coat_clamped_out;
    let _e717 = (*coat_affect_color);
    coat_gamma_multiply_out = (_e716 * _e717);
    let _e719 = (*base_2);
    let _e720 = subsurface_mix_mix_inv_out;
    subsurface_mix_bg_weight_out = (_e719 * _e720);
    let _e722 = one_minus_coat_ior_out;
    let _e723 = one_plus_coat_ior_out;
    coat_ior_to_F0_sqrt_out = (_e722 / _e723);
    let _e726 = opacity_luminance_out[0u];
    opacity_luminance_float_out = _e726;
    let _e727 = coat_tangent_rotate_out;
    coat_tangent_rotate_normalize_out = normalize(_e727);
    let _e729 = (*specular_roughness);
    let _e730 = coat_affect_roughness_multiply2_out;
    coat_affected_roughness_out = mix(_e729, 1f, _e730);
    let _e732 = tangent_rotate_out;
    tangent_rotate_normalize_out = normalize(_e732);
    let _e734 = transmission_roughness_clamped_out;
    let _e735 = coat_affect_roughness_multiply2_out;
    coat_affected_transmission_roughness_out = mix(_e734, 1f, _e735);
    let _e737 = selected_subsurface_bsdf_mix_inv_out;
    selected_subsurface_bsdf_bg_weight_out = (1f * _e737);
    let _e739 = coat_gamma_multiply_out;
    coat_gamma_out = (_e739 + 1f);
    let _e741 = coat_ior_to_F0_sqrt_out;
    let _e742 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e741 * _e742);
    let _e744 = (*coat_anisotropy);
    let _e746 = coat_tangent_rotate_normalize_out;
    let _e747 = (*tangent);
    coat_tangent_out = select(_e747, _e746, (_e744 > 0f));
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e749 = coat_affected_roughness_out;
    param_312 = _e749;
    let _e750 = (*specular_anisotropy);
    param_313 = _e750;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_312), (&param_313), (&param_314));
    let _e751 = param_314;
    main_roughness_out = _e751;
    let _e752 = (*specular_anisotropy);
    let _e754 = tangent_rotate_normalize_out;
    let _e755 = (*tangent);
    main_tangent_out = select(_e755, _e754, (_e752 > 0f));
    transmission_roughness_out = vec2<f32>(0f, 0f);
    let _e757 = coat_affected_transmission_roughness_out;
    param_315 = _e757;
    let _e758 = (*specular_anisotropy);
    param_316 = _e758;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_315), (&param_316), (&param_317));
    let _e759 = param_317;
    transmission_roughness_out = _e759;
    let _e760 = subsurface_color_nonnegative_out;
    let _e761 = coat_gamma_out;
    coat_affected_subsurface_color_out = pow(_e760, vec3(_e761));
    let _e764 = base_color_nonnegative_out;
    let _e765 = coat_gamma_out;
    coat_affected_diffuse_color_out = pow(_e764, vec3(_e765));
    let _e768 = coat_ior_to_F0_out;
    one_minus_coat_ior_to_F0_out = (1f - _e768);
    emission_color0_out = vec3<f32>(0f, 0f, 0f);
    let _e770 = one_minus_coat_ior_to_F0_out;
    param_318 = _e770;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_318), (&param_319));
    let _e771 = param_319;
    emission_color0_out = _e771;
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e772 = g_ptN;
    N_18 = _e772;
    let _e773 = g_ptV;
    V_14 = _e773;
    let _e774 = g_ptL;
    L_11 = _e774;
    let _e775 = g_ptP;
    P_3 = _e775;
    let _e776 = g_ptOcclusion;
    occlusion_2 = _e776;
    let _e777 = g_ptClosureType;
    param_320 = _e777;
    let _e778 = L_11;
    param_321 = _e778;
    let _e779 = V_14;
    param_322 = _e779;
    let _e780 = N_18;
    param_323 = _e780;
    let _e781 = P_3;
    param_324 = _e781;
    let _e782 = occlusion_2;
    param_325 = _e782;
    let _e783 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325));
    closureData_14 = _e783;
    coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e784 = closureData_14;
    param_326 = _e784;
    let _e785 = (*coat);
    param_327 = _e785;
    param_328 = vec3<f32>(1f, 1f, 1f);
    let _e786 = (*coat_IOR);
    param_329 = _e786;
    let _e787 = coat_roughness_vector_out;
    param_330 = _e787;
    param_331 = false;
    param_332 = 0f;
    param_333 = 1.5f;
    let _e788 = (*coat_normal);
    param_334 = _e788;
    let _e789 = coat_tangent_out;
    param_335 = _e789;
    param_336 = 0i;
    param_337 = 0i;
    let _e790 = coat_bsdf_out;
    param_338 = _e790;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_326), (&param_327), (&param_328), (&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336), (&param_337), (&param_338));
    let _e791 = param_338;
    coat_bsdf_out = _e791;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e792 = closureData_14;
    param_339 = _e792;
    let _e793 = metalness_mix_fg_weight_out;
    param_340 = _e793;
    let _e794 = artistic_ior_ior;
    param_341 = _e794;
    let _e795 = artistic_ior_extinction;
    param_342 = _e795;
    let _e796 = main_roughness_out;
    param_343 = _e796;
    param_344 = false;
    let _e797 = (*thin_film_thickness);
    param_345 = _e797;
    let _e798 = (*thin_film_IOR);
    param_346 = _e798;
    let _e799 = (*normal);
    param_347 = _e799;
    let _e800 = main_tangent_out;
    param_348 = _e800;
    param_349 = 0i;
    let _e801 = metal_bsdf_out;
    param_350 = _e801;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350));
    let _e802 = param_350;
    metal_bsdf_out = _e802;
    specular_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e803 = closureData_14;
    param_351 = _e803;
    let _e804 = (*specular);
    param_352 = _e804;
    let _e805 = (*specular_color);
    param_353 = _e805;
    let _e806 = (*specular_IOR);
    param_354 = _e806;
    let _e807 = main_roughness_out;
    param_355 = _e807;
    param_356 = false;
    let _e808 = (*thin_film_thickness);
    param_357 = _e808;
    let _e809 = (*thin_film_IOR);
    param_358 = _e809;
    let _e810 = (*normal);
    param_359 = _e810;
    let _e811 = main_tangent_out;
    param_360 = _e811;
    param_361 = 0i;
    param_362 = 0i;
    let _e812 = specular_bsdf_out;
    param_363 = _e812;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363));
    let _e813 = param_363;
    specular_bsdf_out = _e813;
    transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e814 = closureData_14;
    param_364 = _e814;
    let _e815 = transmission_mix_fg_weight_out;
    param_365 = _e815;
    let _e816 = (*transmission_color);
    param_366 = _e816;
    let _e817 = (*specular_IOR);
    param_367 = _e817;
    let _e818 = transmission_roughness_out;
    param_368 = _e818;
    param_369 = false;
    param_370 = 0f;
    param_371 = 1.5f;
    let _e819 = (*normal);
    param_372 = _e819;
    let _e820 = main_tangent_out;
    param_373 = _e820;
    param_374 = 0i;
    param_375 = 1i;
    let _e821 = transmission_bsdf_out;
    param_376 = _e821;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372), (&param_373), (&param_374), (&param_375), (&param_376));
    let _e822 = param_376;
    transmission_bsdf_out = _e822;
    sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e823 = closureData_14;
    param_377 = _e823;
    let _e824 = (*sheen);
    param_378 = _e824;
    let _e825 = (*sheen_color);
    param_379 = _e825;
    let _e826 = (*sheen_roughness);
    param_380 = _e826;
    let _e827 = (*normal);
    param_381 = _e827;
    param_382 = 0i;
    let _e828 = sheen_bsdf_out;
    param_383 = _e828;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383));
    let _e829 = param_383;
    sheen_bsdf_out = _e829;
    translucent_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e830 = closureData_14;
    param_384 = _e830;
    let _e831 = selected_subsurface_bsdf_fg_weight_out;
    param_385 = _e831;
    let _e832 = coat_affected_subsurface_color_out;
    param_386 = _e832;
    let _e833 = (*normal);
    param_387 = _e833;
    let _e834 = translucent_bsdf_out;
    param_388 = _e834;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_384), (&param_385), (&param_386), (&param_387), (&param_388));
    let _e835 = param_388;
    translucent_bsdf_out = _e835;
    subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e836 = closureData_14;
    param_389 = _e836;
    let _e837 = selected_subsurface_bsdf_bg_weight_out;
    param_390 = _e837;
    let _e838 = coat_affected_subsurface_color_out;
    param_391 = _e838;
    let _e839 = subsurface_radius_scaled_out;
    param_392 = _e839;
    let _e840 = (*subsurface_anisotropy);
    param_393 = _e840;
    let _e841 = (*normal);
    param_394 = _e841;
    let _e842 = subsurface_bsdf_out;
    param_395 = _e842;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395));
    let _e843 = param_395;
    subsurface_bsdf_out = _e843;
    selected_subsurface_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e844 = closureData_14;
    param_396 = _e844;
    let _e845 = translucent_bsdf_out;
    param_397 = _e845;
    let _e846 = subsurface_bsdf_out;
    param_398 = _e846;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_396), (&param_397), (&param_398), (&param_399));
    let _e847 = param_399;
    selected_subsurface_bsdf_add_out = _e847;
    subsurface_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e848 = closureData_14;
    param_400 = _e848;
    let _e849 = selected_subsurface_bsdf_add_out;
    param_401 = _e849;
    let _e850 = (*subsurface);
    param_402 = _e850;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_400), (&param_401), (&param_402), (&param_403));
    let _e851 = param_403;
    subsurface_mix_fg_mul_out = _e851;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e852 = closureData_14;
    param_404 = _e852;
    let _e853 = subsurface_mix_bg_weight_out;
    param_405 = _e853;
    let _e854 = coat_affected_diffuse_color_out;
    param_406 = _e854;
    let _e855 = (*diffuse_roughness);
    param_407 = _e855;
    let _e856 = (*normal);
    param_408 = _e856;
    param_409 = false;
    let _e857 = diffuse_bsdf_out;
    param_410 = _e857;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_404), (&param_405), (&param_406), (&param_407), (&param_408), (&param_409), (&param_410));
    let _e858 = param_410;
    diffuse_bsdf_out = _e858;
    subsurface_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e859 = closureData_14;
    param_411 = _e859;
    let _e860 = subsurface_mix_fg_mul_out;
    param_412 = _e860;
    let _e861 = diffuse_bsdf_out;
    param_413 = _e861;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_411), (&param_412), (&param_413), (&param_414));
    let _e862 = param_414;
    subsurface_mix_add_out = _e862;
    sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e863 = closureData_14;
    param_415 = _e863;
    let _e864 = sheen_bsdf_out;
    param_416 = _e864;
    let _e865 = subsurface_mix_add_out;
    param_417 = _e865;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_415), (&param_416), (&param_417), (&param_418));
    let _e866 = param_418;
    sheen_layer_out = _e866;
    transmission_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e867 = closureData_14;
    param_419 = _e867;
    let _e868 = sheen_layer_out;
    param_420 = _e868;
    let _e869 = transmission_mix_mix_inv_out;
    param_421 = _e869;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_419), (&param_420), (&param_421), (&param_422));
    let _e870 = param_422;
    transmission_mix_bg_mul_out = _e870;
    transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e871 = closureData_14;
    param_423 = _e871;
    let _e872 = transmission_bsdf_out;
    param_424 = _e872;
    let _e873 = transmission_mix_bg_mul_out;
    param_425 = _e873;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_423), (&param_424), (&param_425), (&param_426));
    let _e874 = param_426;
    transmission_mix_add_out = _e874;
    specular_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e875 = closureData_14;
    param_427 = _e875;
    let _e876 = specular_bsdf_out;
    param_428 = _e876;
    let _e877 = transmission_mix_add_out;
    param_429 = _e877;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_427), (&param_428), (&param_429), (&param_430));
    let _e878 = param_430;
    specular_layer_out = _e878;
    metalness_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e879 = closureData_14;
    param_431 = _e879;
    let _e880 = specular_layer_out;
    param_432 = _e880;
    let _e881 = metalness_mix_mix_inv_out;
    param_433 = _e881;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_431), (&param_432), (&param_433), (&param_434));
    let _e882 = param_434;
    metalness_mix_bg_mul_out = _e882;
    metalness_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e883 = closureData_14;
    param_435 = _e883;
    let _e884 = metal_bsdf_out;
    param_436 = _e884;
    let _e885 = metalness_mix_bg_mul_out;
    param_437 = _e885;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_435), (&param_436), (&param_437), (&param_438));
    let _e886 = param_438;
    metalness_mix_add_out = _e886;
    thin_film_layer_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e887 = closureData_14;
    param_439 = _e887;
    let _e888 = metalness_mix_add_out;
    param_440 = _e888;
    let _e889 = coat_attenuation_out;
    param_441 = _e889;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_439), (&param_440), (&param_441), (&param_442));
    let _e890 = param_442;
    thin_film_layer_attenuated_out = _e890;
    coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e891 = closureData_14;
    param_443 = _e891;
    let _e892 = coat_bsdf_out;
    param_444 = _e892;
    let _e893 = thin_film_layer_attenuated_out;
    param_445 = _e893;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_443), (&param_444), (&param_445), (&param_446));
    let _e894 = param_446;
    coat_layer_out = _e894;
    let _e896 = coat_layer_out.response;
    let _e898 = shader_constructor_out.color;
    shader_constructor_out.color = (_e898 + _e896);
    let _e901 = g_ptEmitEmission;
    if (_e901 != 0i) {
        param_447 = 4i;
        let _e903 = L_11;
        param_448 = _e903;
        let _e904 = V_14;
        param_449 = _e904;
        let _e905 = N_18;
        param_450 = _e905;
        let _e906 = P_3;
        param_451 = _e906;
        let _e907 = occlusion_2;
        param_452 = _e907;
        let _e908 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_447), (&param_448), (&param_449), (&param_450), (&param_451), (&param_452));
        closureData_15 = _e908;
        emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e909 = closureData_15;
        param_453 = _e909;
        let _e910 = emission_weight_out;
        param_454 = _e910;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_453), (&param_454), (&param_455));
        let _e911 = param_455;
        emission_edf_out = _e911;
        coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e912 = closureData_15;
        param_456 = _e912;
        let _e913 = emission_edf_out;
        param_457 = _e913;
        let _e914 = (*coat_color);
        param_458 = _e914;
        mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_456), (&param_457), (&param_458), (&param_459));
        let _e915 = param_459;
        coat_tinted_emission_edf_out = _e915;
        coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e916 = closureData_15;
        param_460 = _e916;
        let _e917 = emission_color0_out;
        param_461 = _e917;
        param_462 = vec3<f32>(0f, 0f, 0f);
        param_463 = 5f;
        let _e918 = coat_tinted_emission_edf_out;
        param_464 = _e918;
        mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_460), (&param_461), (&param_462), (&param_463), (&param_464), (&param_465));
        let _e919 = param_465;
        coat_emission_edf_out = _e919;
        blended_coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e920 = closureData_15;
        param_466 = _e920;
        let _e921 = coat_emission_edf_out;
        param_467 = _e921;
        let _e922 = emission_edf_out;
        param_468 = _e922;
        let _e923 = (*coat);
        param_469 = _e923;
        mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_466), (&param_467), (&param_468), (&param_469), (&param_470));
        let _e924 = param_470;
        blended_coat_emission_edf_out = _e924;
        let _e925 = blended_coat_emission_edf_out;
        let _e926 = g_ptEmission;
        g_ptEmission = (_e926 + _e925);
        let _e928 = blended_coat_emission_edf_out;
        let _e930 = shader_constructor_out.color;
        shader_constructor_out.color = (_e930 + _e928);
    }
    let _e933 = shader_constructor_out;
    (*out1_1) = _e933;
    return;
}

fn mtlxHostEvalSurface_u0028_() -> surfaceshader {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_chrome_out: surfaceshader;
    var param_471: f32;
    var param_472: vec3<f32>;
    var param_473: f32;
    var param_474: f32;
    var param_475: f32;
    var param_476: vec3<f32>;
    var param_477: f32;
    var param_478: f32;
    var param_479: f32;
    var param_480: f32;
    var param_481: f32;
    var param_482: vec3<f32>;
    var param_483: f32;
    var param_484: vec3<f32>;
    var param_485: f32;
    var param_486: f32;
    var param_487: f32;
    var param_488: f32;
    var param_489: vec3<f32>;
    var param_490: vec3<f32>;
    var param_491: f32;
    var param_492: f32;
    var param_493: f32;
    var param_494: vec3<f32>;
    var param_495: f32;
    var param_496: f32;
    var param_497: vec3<f32>;
    var param_498: f32;
    var param_499: f32;
    var param_500: f32;
    var param_501: f32;
    var param_502: vec3<f32>;
    var param_503: f32;
    var param_504: f32;
    var param_505: f32;
    var param_506: f32;
    var param_507: f32;
    var param_508: vec3<f32>;
    var param_509: vec3<f32>;
    var param_510: bool;
    var param_511: vec3<f32>;
    var param_512: vec3<f32>;
    var param_513: surfaceshader;

    let _e386 = g_ptN;
    normalWorld = _e386;
    let _e387 = g_ptTangent;
    tangentWorld = _e387;
    let _e388 = normalWorld;
    geomprop_Nworld_out = normalize(_e388);
    let _e390 = tangentWorld;
    geomprop_Tworld_out = normalize(_e390);
    SR_chrome_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e392 = base_3;
    param_471 = _e392;
    let _e393 = base_color_1;
    param_472 = _e393;
    let _e394 = diffuse_roughness_1;
    param_473 = _e394;
    let _e395 = metalness_1;
    param_474 = _e395;
    let _e396 = specular_1;
    param_475 = _e396;
    let _e397 = specular_color_1;
    param_476 = _e397;
    let _e398 = specular_roughness_1;
    param_477 = _e398;
    let _e399 = specular_IOR_1;
    param_478 = _e399;
    let _e400 = specular_anisotropy_1;
    param_479 = _e400;
    let _e401 = specular_rotation_1;
    param_480 = _e401;
    let _e402 = transmission_1;
    param_481 = _e402;
    let _e403 = transmission_color_1;
    param_482 = _e403;
    let _e404 = transmission_depth_1;
    param_483 = _e404;
    let _e405 = transmission_scatter_1;
    param_484 = _e405;
    let _e406 = transmission_scatter_anisotropy_1;
    param_485 = _e406;
    let _e407 = transmission_dispersion_1;
    param_486 = _e407;
    let _e408 = transmission_extra_roughness_1;
    param_487 = _e408;
    let _e409 = subsurface_1;
    param_488 = _e409;
    let _e410 = subsurface_color_1;
    param_489 = _e410;
    let _e411 = subsurface_radius_1;
    param_490 = _e411;
    let _e412 = subsurface_scale_1;
    param_491 = _e412;
    let _e413 = subsurface_anisotropy_1;
    param_492 = _e413;
    let _e414 = sheen_1;
    param_493 = _e414;
    let _e415 = sheen_color_1;
    param_494 = _e415;
    let _e416 = sheen_roughness_1;
    param_495 = _e416;
    let _e417 = coat_1;
    param_496 = _e417;
    let _e418 = coat_color_1;
    param_497 = _e418;
    let _e419 = coat_roughness_1;
    param_498 = _e419;
    let _e420 = coat_anisotropy_1;
    param_499 = _e420;
    let _e421 = coat_rotation_1;
    param_500 = _e421;
    let _e422 = coat_IOR_1;
    param_501 = _e422;
    let _e423 = geomprop_Nworld_out;
    param_502 = _e423;
    let _e424 = coat_affect_color_1;
    param_503 = _e424;
    let _e425 = coat_affect_roughness_1;
    param_504 = _e425;
    let _e426 = thin_film_thickness_1;
    param_505 = _e426;
    let _e427 = thin_film_IOR_1;
    param_506 = _e427;
    let _e428 = emission_1;
    param_507 = _e428;
    let _e429 = emission_color_1;
    param_508 = _e429;
    let _e430 = opacity_1;
    param_509 = _e430;
    let _e431 = thin_walled_2;
    param_510 = _e431;
    let _e432 = geomprop_Nworld_out;
    param_511 = _e432;
    let _e433 = geomprop_Tworld_out;
    param_512 = _e433;
    NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491), (&param_492), (&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502), (&param_503), (&param_504), (&param_505), (&param_506), (&param_507), (&param_508), (&param_509), (&param_510), (&param_511), (&param_512), (&param_513));
    let _e434 = param_513;
    SR_chrome_out = _e434;
    let _e435 = SR_chrome_out;
    return _e435;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e343 = (*basis_2).tW;
    let _e345 = (*vLocal)[0u];
    let _e348 = (*basis_2).bW;
    let _e350 = (*vLocal)[1u];
    let _e354 = (*basis_2).nW;
    let _e356 = (*vLocal)[2u];
    return (((_e343 * _e345) + (_e348 * _e350)) + (_e354 * _e356));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_514: vec3<f32>;
    var param_515: Basis;
    var param_516: vec3<f32>;
    var param_517: Basis;

    let _e349 = (*pW_3);
    g_ptP = _e349;
    let _e351 = (*basis_3).nW;
    g_ptN = _e351;
    let _e353 = (*basis_3).tW;
    g_ptTangent = _e353;
    let _e355 = (*basis_3).bW;
    g_ptBitangent = _e355;
    let _e356 = (*winputL_2);
    param_514 = _e356;
    let _e357 = (*basis_3);
    param_515 = _e357;
    let _e358 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_514), (&param_515));
    g_ptV = _e358;
    let _e359 = (*woutputL_2);
    param_516 = _e359;
    let _e360 = (*basis_3);
    param_517 = _e360;
    let _e361 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_516), (&param_517));
    g_ptL = _e361;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e363 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e363, 0f) / 3.1415927f);
    let _e366 = mtlxHostEvalSurface_u0028_();
    return _e366.color;
}

fn evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b(pW_4: ptr<function, vec3<f32>>, basis_4: ptr<function, Basis>, winputL_3: ptr<function, vec3<f32>>, woutputL_3: ptr<function, vec3<f32>>, surfaceshader_1: ptr<function, i32>, pdf_woutputL_3: ptr<function, f32>) -> vec3<f32> {
    var param_518: vec3<f32>;
    var param_519: Basis;
    var param_520: vec3<f32>;
    var param_521: vec3<f32>;
    var param_522: f32;
    var param_523: vec3<f32>;
    var param_524: Basis;
    var param_525: vec3<f32>;
    var param_526: vec3<f32>;
    var param_527: f32;
    var param_528: vec3<f32>;
    var param_529: Basis;
    var param_530: vec3<f32>;
    var param_531: vec3<f32>;
    var param_532: f32;

    let _e361 = (*surfaceshader_1);
    if (_e361 == 1i) {
        let _e363 = (*pW_4);
        param_518 = _e363;
        let _e364 = (*basis_4);
        param_519 = _e364;
        let _e365 = (*winputL_3);
        param_520 = _e365;
        let _e366 = (*woutputL_3);
        param_521 = _e366;
        let _e367 = (*pdf_woutputL_3);
        param_522 = _e367;
        let _e368 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_518), (&param_519), (&param_520), (&param_521), (&param_522));
        let _e369 = param_522;
        (*pdf_woutputL_3) = _e369;
        return _e368;
    } else {
        let _e370 = (*surfaceshader_1);
        if (_e370 == 2i) {
            let _e372 = (*pW_4);
            param_523 = _e372;
            let _e373 = (*basis_4);
            param_524 = _e373;
            let _e374 = (*winputL_3);
            param_525 = _e374;
            let _e375 = (*woutputL_3);
            param_526 = _e375;
            let _e376 = (*pdf_woutputL_3);
            param_527 = _e376;
            let _e377 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_523), (&param_524), (&param_525), (&param_526), (&param_527));
            let _e378 = param_527;
            (*pdf_woutputL_3) = _e378;
            return _e377;
        } else {
            let _e379 = (*pW_4);
            param_528 = _e379;
            let _e380 = (*basis_4);
            param_529 = _e380;
            let _e381 = (*winputL_3);
            param_530 = _e381;
            let _e382 = (*woutputL_3);
            param_531 = _e382;
            let _e383 = (*pdf_woutputL_3);
            param_532 = _e383;
            let _e384 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_528), (&param_529), (&param_530), (&param_531), (&param_532));
            let _e385 = param_532;
            (*pdf_woutputL_3) = _e385;
            return _e384;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    let _e340 = thin_walled_2;
    return _e340;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e340 = g_ptOpacity;
    return (_e340 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e342 = (*N_19);
    l = length(_e342);
    let _e344 = (*N_19);
    let _e345 = l;
    return (_e344 / vec3(max(_e345, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_533: vec3<f32>;

    let _e344 = (*N_20)[2u];
    let _e347 = (*N_20)[0u];
    if (abs(_e344) < abs(_e347)) {
        let _e351 = (*N_20)[2u];
        let _e353 = (*N_20)[0u];
        T = vec3<f32>(_e351, 0f, -(_e353));
    } else {
        let _e357 = (*N_20)[2u];
        let _e359 = (*N_20)[1u];
        T = vec3<f32>(0f, _e357, -(_e359));
    }
    let _e362 = T;
    param_533 = _e362;
    let _e363 = safe_normalize_u0028_vf3_u003b((&param_533));
    T = _e363;
    let _e364 = T;
    return _e364;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e344 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e344).x;
    let _e347 = (*index);
    let _e348 = width;
    let _e356 = (*index);
    let _e357 = width;
    let _e360 = textureLoad(texture, vec2<i32>((_e347 - (i32(floor((f32(_e347) / f32(_e348)))) * _e348)), (_e356 / _e357)), 0i);
    return _e360;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_534: i32;
    var param_535: i32;
    var param_536: i32;

    let _e348 = (*barycoord)[0u];
    let _e350 = (*faceIndices)[0u];
    param_534 = bitcast<i32>(_e350);
    let _e352 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_534));
    let _e355 = (*barycoord)[1u];
    let _e357 = (*faceIndices)[1u];
    param_535 = bitcast<i32>(_e357);
    let _e359 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_535));
    let _e363 = (*barycoord)[2u];
    let _e365 = (*faceIndices)[2u];
    param_536 = bitcast<i32>(_e365);
    let _e367 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_536));
    return (((_e352 * _e348) + (_e359 * _e355)) + (_e367 * _e363));
}

fn nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(minimum: ptr<function, vec3<f32>>, maximum: ptr<function, vec3<f32>>, origin: ptr<function, vec3<f32>>, direction: ptr<function, vec3<f32>>) -> f32 {
    var inverseDirection: vec3<f32>;
    var t0_2: vec3<f32>;
    var t1_2: vec3<f32>;
    var entry: vec3<f32>;
    var exit: vec3<f32>;
    var nearDistance: f32;
    var farDistance: f32;
    var local_11: f32;

    let _e352 = (*direction);
    inverseDirection = (vec3(1f) / _e352);
    let _e355 = (*minimum);
    let _e356 = (*origin);
    let _e358 = inverseDirection;
    t0_2 = ((_e355 - _e356) * _e358);
    let _e360 = (*maximum);
    let _e361 = (*origin);
    let _e363 = inverseDirection;
    t1_2 = ((_e360 - _e361) * _e363);
    let _e365 = t0_2;
    let _e366 = t1_2;
    entry = min(_e365, _e366);
    let _e368 = t0_2;
    let _e369 = t1_2;
    exit = max(_e368, _e369);
    let _e372 = entry[0u];
    let _e374 = entry[1u];
    let _e376 = entry[2u];
    nearDistance = max(_e372, max(_e374, _e376));
    let _e380 = exit[0u];
    let _e382 = exit[1u];
    let _e384 = exit[2u];
    farDistance = min(_e380, min(_e382, _e384));
    let _e387 = farDistance;
    let _e388 = nearDistance;
    if (_e387 >= max(_e388, 0f)) {
        let _e391 = nearDistance;
        local_11 = max(_e391, 0f);
    } else {
        local_11 = 100000000000000000000f;
    }
    let _e393 = local_11;
    return _e393;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist_2: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_537: i32;
    var maximum_1: vec4<f32>;
    var param_538: i32;
    var metadata: vec4<f32>;
    var param_539: i32;
    var param_540: vec3<f32>;
    var param_541: vec3<f32>;
    var param_542: vec3<f32>;
    var param_543: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_544: i32;
    var p0_: vec3<f32>;
    var param_545: i32;
    var p1_: vec3<f32>;
    var param_546: i32;
    var p2_: vec3<f32>;
    var param_547: i32;
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
    var phi_1392_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e393 = (*maxDistance);
    closest = _e393;
    found = false;
    loop {
        let _e394 = pointer;
        let _e396 = pointer;
        if ((_e394 >= 0i) && (_e396 < 64i)) {
            let _e399 = pointer;
            pointer = (_e399 - 1i);
            let _e402 = stack[_e399];
            nodeIndex = _e402;
            let _e403 = nodeIndex;
            param_537 = (_e403 * 3i);
            let _e405 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_537));
            minimum_1 = _e405;
            let _e406 = nodeIndex;
            param_538 = ((_e406 * 3i) + 1i);
            let _e409 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_538));
            maximum_1 = _e409;
            let _e410 = nodeIndex;
            param_539 = ((_e410 * 3i) + 2i);
            let _e413 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_539));
            metadata = _e413;
            let _e414 = minimum_1;
            param_540 = _e414.xyz;
            let _e416 = maximum_1;
            param_541 = _e416.xyz;
            let _e418 = (*rayOrigin);
            param_542 = _e418;
            let _e419 = (*rayDirection);
            param_543 = _e419;
            let _e420 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_540), (&param_541), (&param_542), (&param_543));
            let _e421 = closest;
            if (_e420 > _e421) {
                continue;
            }
            let _e424 = metadata[2u];
            if (_e424 > 0.5f) {
                let _e427 = metadata[0u];
                offset = i32((_e427 + 0.5f));
                let _e431 = metadata[1u];
                count = i32((_e431 + 0.5f));
                triangle = 0i;
                loop {
                    let _e434 = triangle;
                    let _e435 = count;
                    if (_e434 < _e435) {
                        let _e437 = offset;
                        let _e438 = triangle;
                        param_544 = (_e437 + _e438);
                        let _e440 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_544));
                        vertexIndices = vec3<u32>((_e440.xyz + vec3(0.5f)));
                        let _e446 = vertexIndices[0u];
                        param_545 = bitcast<i32>(_e446);
                        let _e448 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_545));
                        p0_ = _e448.xyz;
                        let _e451 = vertexIndices[1u];
                        param_546 = bitcast<i32>(_e451);
                        let _e453 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_546));
                        p1_ = _e453.xyz;
                        let _e456 = vertexIndices[2u];
                        param_547 = bitcast<i32>(_e456);
                        let _e458 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_547));
                        p2_ = _e458.xyz;
                        let _e460 = p1_;
                        let _e461 = p0_;
                        edge0_ = (_e460 - _e461);
                        let _e463 = p2_;
                        let _e464 = p0_;
                        edge1_ = (_e463 - _e464);
                        let _e466 = (*rayDirection);
                        let _e467 = edge1_;
                        pvec = cross(_e466, _e467);
                        let _e469 = edge0_;
                        let _e470 = pvec;
                        determinant_ = dot(_e469, _e470);
                        let _e472 = determinant_;
                        if (abs(_e472) < 0.00000001f) {
                            continue;
                        }
                        let _e475 = determinant_;
                        inverseDeterminant = (1f / _e475);
                        let _e477 = (*rayOrigin);
                        let _e478 = p0_;
                        tvec = (_e477 - _e478);
                        let _e480 = tvec;
                        let _e481 = pvec;
                        let _e483 = inverseDeterminant;
                        u = (dot(_e480, _e481) * _e483);
                        let _e485 = tvec;
                        let _e486 = edge0_;
                        qvec = cross(_e485, _e486);
                        let _e488 = (*rayDirection);
                        let _e489 = qvec;
                        let _e491 = inverseDeterminant;
                        v_3 = (dot(_e488, _e489) * _e491);
                        let _e493 = edge1_;
                        let _e494 = qvec;
                        let _e496 = inverseDeterminant;
                        distance_ = (dot(_e493, _e494) * _e496);
                        let _e498 = u;
                        let _e500 = v_3;
                        let _e502 = ((_e498 >= 0f) && (_e500 >= 0f));
                        phi_1392_ = _e502;
                        if _e502 {
                            let _e503 = u;
                            let _e504 = v_3;
                            phi_1392_ = ((_e503 + _e504) <= 1f);
                        }
                        let _e508 = phi_1392_;
                        let _e509 = distance_;
                        let _e512 = distance_;
                        let _e513 = closest;
                        if ((_e508 && (_e509 > 0f)) && (_e512 < _e513)) {
                            let _e516 = distance_;
                            closest = _e516;
                            let _e517 = distance_;
                            (*dist_2) = _e517;
                            let _e518 = u;
                            let _e520 = v_3;
                            let _e522 = u;
                            let _e523 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e518) - _e520), _e522, _e523);
                            let _e525 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e525.x, _e525.y, _e525.z, 0u);
                            let _e530 = edge0_;
                            let _e531 = edge1_;
                            (*faceNormal) = normalize(cross(_e530, _e531));
                            let _e534 = determinant_;
                            (*side) = select(1f, -1f, (_e534 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e537 = triangle;
                        triangle = (_e537 + 1i);
                    }
                }
            } else {
                let _e540 = metadata[0u];
                left = i32((_e540 + 0.5f));
                let _e544 = metadata[1u];
                right = i32((_e544 + 0.5f));
                let _e547 = pointer;
                if ((_e547 + 2i) >= 64i) {
                    continue;
                }
                let _e550 = pointer;
                let _e551 = (_e550 + 1i);
                pointer = _e551;
                let _e552 = right;
                stack[_e551] = _e552;
                let _e554 = pointer;
                let _e555 = (_e554 + 1i);
                pointer = _e555;
                let _e556 = left;
                stack[_e555] = _e556;
            }
            continue;
        } else {
            break;
        }
    }
    let _e558 = found;
    return _e558;
}

fn bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1: texture_2d<f32>, nodesSampler_1: sampler, indices_1: texture_2d<f32>, indicesSampler_1: sampler, positions_1: texture_2d<f32>, positionsSampler_1: sampler, rayOrigin_1: ptr<function, vec3<f32>>, rayDirection_1: ptr<function, vec3<f32>>, maxDistance_1: ptr<function, f32>, faceIndices_2: ptr<function, vec4<u32>>, faceNormal_1: ptr<function, vec3<f32>>, barycoord_2: ptr<function, vec3<f32>>, side_1: ptr<function, f32>, dist_3: ptr<function, f32>) -> bool {
    var param_548: vec3<f32>;
    var param_549: vec3<f32>;
    var param_550: f32;
    var param_551: vec4<u32>;
    var param_552: vec3<f32>;
    var param_553: vec3<f32>;
    var param_554: f32;
    var param_555: f32;

    let _e362 = (*rayOrigin_1);
    param_548 = _e362;
    let _e363 = (*rayDirection_1);
    param_549 = _e363;
    let _e364 = (*maxDistance_1);
    param_550 = _e364;
    let _e365 = (*faceIndices_2);
    param_551 = _e365;
    let _e366 = (*faceNormal_1);
    param_552 = _e366;
    let _e367 = (*barycoord_2);
    param_553 = _e367;
    let _e368 = (*side_1);
    param_554 = _e368;
    let _e369 = (*dist_3);
    param_555 = _e369;
    let _e370 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_548), (&param_549), (&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555));
    let _e371 = param_551;
    (*faceIndices_2) = _e371;
    let _e372 = param_552;
    (*faceNormal_1) = _e372;
    let _e373 = param_553;
    (*barycoord_2) = _e373;
    let _e374 = param_554;
    (*side_1) = _e374;
    let _e375 = param_555;
    (*dist_3) = _e375;
    return _e370;
}

fn trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b(rayOrigin_2: ptr<function, vec3<f32>>, rayDir: ptr<function, vec3<f32>>, maxDistance_2: ptr<function, f32>, P_4: ptr<function, vec3<f32>>, Ns: ptr<function, vec3<f32>>, Ng: ptr<function, vec3<f32>>, Ts: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>, surfaceshader_2: ptr<function, i32>) -> bool {
    var faceIndices_surface: vec4<u32>;
    var faceNormal_surface: vec3<f32>;
    var barycoord_surface: vec3<f32>;
    var side_surface: f32;
    var dist_surface: f32;
    var hit_surface: bool;
    var param_556: vec3<f32>;
    var param_557: vec3<f32>;
    var param_558: f32;
    var param_559: vec4<u32>;
    var param_560: vec3<f32>;
    var param_561: vec3<f32>;
    var param_562: f32;
    var param_563: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_564: vec3<f32>;
    var gN: vec4<f32>;
    var param_565: vec3<f32>;
    var param_566: vec3<u32>;
    var gT: vec4<f32>;
    var param_567: vec3<f32>;
    var param_568: vec3<u32>;
    var local_12: vec3<f32>;
    var local_13: vec2<f32>;
    var local_14: vec3<f32>;
    var param_569: vec3<f32>;
    var param_570: vec3<f32>;
    var param_571: vec3<u32>;
    var phi_7326_: bool;
    var phi_7348_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e382 = (*rayOrigin_2);
    param_556 = _e382;
    let _e383 = (*rayDir);
    param_557 = _e383;
    let _e384 = (*maxDistance_2);
    param_558 = _e384;
    let _e385 = faceIndices_surface;
    param_559 = _e385;
    let _e386 = faceNormal_surface;
    param_560 = _e386;
    let _e387 = barycoord_surface;
    param_561 = _e387;
    let _e388 = side_surface;
    param_562 = _e388;
    let _e389 = dist_surface;
    param_563 = _e389;
    let _e390 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_556), (&param_557), (&param_558), (&param_559), (&param_560), (&param_561), (&param_562), (&param_563));
    let _e391 = param_559;
    faceIndices_surface = _e391;
    let _e392 = param_560;
    faceNormal_surface = _e392;
    let _e393 = param_561;
    barycoord_surface = _e393;
    let _e394 = param_562;
    side_surface = _e394;
    let _e395 = param_563;
    dist_surface = _e395;
    hit_surface = _e390;
    dist_closest = 100000000000000000000f;
    let _e396 = hit_surface;
    if _e396 {
        let _e397 = dist_closest;
        let _e398 = dist_surface;
        dist_closest = min(_e397, _e398);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e401 = (*rayDir)[1u];
    if (abs(_e401) > 0.0000000001f) {
        let _e405 = (*rayOrigin_2)[1u];
        let _e408 = (*rayDir)[1u];
        t = ((0.01f - _e405) / _e408);
        let _e410 = t;
        let _e411 = (_e410 > 0f);
        phi_7326_ = _e411;
        if _e411 {
            let _e412 = t;
            let _e413 = dist_closest;
            let _e414 = (*maxDistance_2);
            phi_7326_ = (_e412 < min(_e413, _e414));
        }
        let _e418 = phi_7326_;
        if _e418 {
            let _e419 = t;
            dist_ground = _e419;
            hit_ground = true;
        }
    }
    let _e420 = hit_surface;
    let _e421 = hit_ground;
    hit = (_e420 || _e421);
    let _e423 = hit;
    if !(_e423) {
        return false;
    }
    let _e425 = hit_surface;
    phi_7348_ = _e425;
    if _e425 {
        let _e426 = hit_ground;
        let _e428 = dist_surface;
        let _e429 = dist_ground;
        phi_7348_ = (!(_e426) || (_e428 <= _e429));
    }
    let _e433 = phi_7348_;
    if _e433 {
        let _e434 = (*rayOrigin_2);
        let _e435 = dist_surface;
        let _e436 = (*rayDir);
        (*P_4) = (_e434 + (_e436 * _e435));
        let _e439 = barycoord_surface;
        (*baryCoord) = _e439;
        let _e440 = faceNormal_surface;
        param_564 = _e440;
        let _e441 = safe_normalize_u0028_vf3_u003b((&param_564));
        (*Ng) = _e441;
        let _e442 = barycoord_surface;
        param_565 = _e442;
        let _e443 = faceIndices_surface;
        param_566 = _e443.xyz;
        let _e445 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_565), (&param_566));
        gN = _e445;
        let _e446 = barycoord_surface;
        param_567 = _e446;
        let _e447 = faceIndices_surface;
        param_568 = _e447.xyz;
        let _e449 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_567), (&param_568));
        gT = _e449;
        let _e451 = unnamed.has_normals_surface;
        if (_e451 != 0u) {
            let _e453 = gN;
            local_12 = _e453.xyz;
        } else {
            let _e455 = (*Ng);
            local_12 = _e455;
        }
        let _e456 = local_12;
        (*Ns) = _e456;
        let _e458 = unnamed.has_uvs_surface;
        if (_e458 != 0u) {
            let _e461 = gN[3u];
            let _e463 = gT[3u];
            local_13 = vec2<f32>(_e461, _e463);
        } else {
            let _e465 = barycoord_surface;
            local_13 = _e465.xy;
        }
        let _e467 = local_13;
        (*texCoord) = _e467;
        let _e469 = unnamed.has_tangents_surface;
        if (_e469 != 0u) {
            let _e471 = gT;
            local_14 = _e471.xyz;
        } else {
            let _e473 = (*Ns);
            param_569 = _e473;
            let _e474 = normalToTangent_u0028_vf3_u003b((&param_569));
            local_14 = _e474;
        }
        let _e475 = local_14;
        (*Ts) = _e475;
        let _e476 = barycoord_surface;
        param_570 = _e476;
        let _e477 = faceIndices_surface;
        param_571 = _e477.xyz;
        let _e479 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_570), (&param_571));
        (*surfaceshader_2) = select(1i, 0i, (_e479.x > 0.5f));
    } else {
        let _e483 = hit_ground;
        if _e483 {
            let _e484 = (*rayOrigin_2);
            let _e485 = dist_ground;
            let _e486 = (*rayDir);
            (*P_4) = (_e484 + (_e486 * _e485));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e489 = (*Ng);
            (*Ns) = _e489;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e491 = (*P_4)[0u];
            let _e493 = (*P_4)[2u];
            (*texCoord) = (((vec2<f32>(_e491, -(_e493)) / vec2(200f)) * 2f) + vec2(0.5f));
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
    var param_572: vec3<f32>;
    var param_573: vec3<f32>;
    var param_574: f32;
    var param_575: vec3<f32>;
    var param_576: vec3<f32>;
    var param_577: vec3<f32>;
    var param_578: vec3<f32>;
    var param_579: vec3<f32>;
    var param_580: vec2<f32>;
    var param_581: i32;
    var phi_7492_: bool;
    var phi_7496_: bool;

    let _e361 = (*rayOrigin_3);
    param_572 = _e361;
    let _e362 = (*rayDir_1);
    param_573 = _e362;
    let _e363 = (*maxDistance_3);
    param_574 = _e363;
    let _e364 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_572), (&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578), (&param_579), (&param_580), (&param_581));
    let _e365 = param_575;
    pW_5 = _e365;
    let _e366 = param_576;
    nsW = _e366;
    let _e367 = param_577;
    ngW = _e367;
    let _e368 = param_578;
    TsW = _e368;
    let _e369 = param_579;
    baryCoord_1 = _e369;
    let _e370 = param_580;
    texCoord_1 = _e370;
    let _e371 = param_581;
    surfaceshader_3 = _e371;
    hit_1 = _e364;
    let _e372 = hit_1;
    let _e373 = surfaceshader_3;
    let _e375 = (_e372 && (_e373 == 1i));
    phi_7492_ = _e375;
    if _e375 {
        let _e376 = mtlx_openpbr_is_opaque_u0028_();
        phi_7492_ = !(_e376);
    }
    let _e379 = phi_7492_;
    phi_7496_ = _e379;
    if _e379 {
        let _e380 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_7496_ = _e380;
    }
    let _e382 = phi_7496_;
    if _e382 {
        return 1f;
    }
    let _e383 = hit_1;
    return select(1f, 0f, _e383);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e342 = (*v_4)[0u];
    let _e344 = (*v_4)[1u];
    let _e346 = (*v_4)[2u];
    return max(_e342, max(_e344, _e346));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e342 = (*vWorld);
    let _e344 = (*basis_5).tW;
    let _e346 = (*vWorld);
    let _e348 = (*basis_5).bW;
    let _e350 = (*vWorld);
    let _e352 = (*basis_5).nW;
    return vec3<f32>(dot(_e342, _e344), dot(_e346, _e348), dot(_e350, _e352));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e343 = (*v_5);
    state = ((_e343 * 747796405u) + 2891336453u);
    let _e346 = state;
    let _e347 = state;
    let _e353 = state;
    word = (((_e346 >> bitcast<u32>(((_e347 >> bitcast<u32>(28u)) + 4u))) ^ _e353) * 277803737u);
    let _e356 = word;
    let _e359 = word;
    return ((_e356 >> bitcast<u32>(22u)) ^ _e359);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_582: u32;

    let _e342 = (*seed);
    param_582 = _e342;
    let _e343 = pcg_u0028_u1_u003b((&param_582));
    (*seed) = _e343;
    let _e344 = (*seed);
    return (f32((_e344 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_4: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e348 = (*i_4);
    let _e350 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e348), 0i);
    t0_3 = _e350;
    let _e351 = (*i_4);
    let _e353 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e351), 0i);
    t1_3 = _e353;
    let _e354 = (*i_4);
    let _e356 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e354), 0i);
    t2_2 = _e356;
    let _e357 = (*i_4);
    let _e359 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e357), 0i);
    t3_2 = _e359;
    let _e360 = (*i_4);
    let _e362 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e360), 0i);
    t4_2 = _e362;
    let _e363 = (*i_4);
    let _e365 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e363), 0i);
    t5_ = _e365;
    let _e366 = t0_3;
    l_1.position = _e366.xyz;
    let _e370 = t0_3[3u];
    l_1.decayRate = _e370;
    let _e372 = t1_3;
    l_1.direction = _e372.xyz;
    let _e376 = t1_3[3u];
    l_1.type_ = i32((_e376 + 0.5f));
    let _e380 = t2_2;
    l_1.color = _e380.xyz;
    let _e384 = t2_2[3u];
    l_1.intensity = _e384;
    let _e387 = t3_2[0u];
    l_1.innerCone = _e387;
    let _e390 = t3_2[1u];
    l_1.outerCone = _e390;
    let _e392 = t4_2;
    l_1.u = _e392.xyz;
    let _e395 = t5_;
    l_1.v = _e395.xyz;
    let _e398 = l_1;
    return _e398;
}

fn mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(index_1: ptr<function, i32>, pW_6: ptr<function, vec3<f32>>, basis_6: ptr<function, Basis>, woutputL_4: ptr<function, vec3<f32>>, woutputW: ptr<function, vec3<f32>>, maxDistance_4: ptr<function, f32>, rndSeed: ptr<function, u32>) -> vec3<f32> {
    var l_2: MtlxLight;
    var param_583: i32;
    var intensity: vec3<f32>;
    var param_584: vec3<f32>;
    var xi: vec2<f32>;
    var param_585: u32;
    var param_586: u32;
    var pointOnLight: vec3<f32>;
    var lightNormal: vec3<f32>;
    var param_587: vec3<f32>;
    var area: f32;
    var toLight: vec3<f32>;
    var distSq: f32;
    var distanceToLight: f32;
    var cosLight: f32;
    var param_588: vec3<f32>;
    var param_589: Basis;
    var param_590: vec3<f32>;
    var param_591: Basis;
    var toLight_1: vec3<f32>;
    var distanceToLight_1: f32;
    var attenuation: f32;
    var cosDir: f32;
    var param_592: vec3<f32>;
    var low: f32;
    var high: f32;
    var param_593: vec3<f32>;
    var param_594: Basis;

    let _e375 = (*index_1);
    param_583 = _e375;
    let _e376 = GetMtlxLight_u0028_i1_u003b((&param_583));
    l_2 = _e376;
    let _e378 = l_2.color;
    let _e380 = l_2.intensity;
    intensity = (_e378 * _e380);
    (*maxDistance_4) = 100000000000000000000f;
    let _e383 = l_2.type_;
    if (_e383 == 1i) {
        let _e386 = l_2.direction;
        param_584 = -(_e386);
        let _e388 = safe_normalize_u0028_vf3_u003b((&param_584));
        (*woutputW) = _e388;
    } else {
        let _e390 = l_2.type_;
        if (_e390 == 3i) {
            let _e392 = (*rndSeed);
            param_585 = _e392;
            let _e393 = rand_u0028_u1_u003b((&param_585));
            let _e394 = param_585;
            (*rndSeed) = _e394;
            let _e395 = (*rndSeed);
            param_586 = _e395;
            let _e396 = rand_u0028_u1_u003b((&param_586));
            let _e397 = param_586;
            (*rndSeed) = _e397;
            xi = vec2<f32>(_e393, _e396);
            let _e400 = l_2.position;
            let _e402 = xi[0u];
            let _e404 = l_2.u;
            let _e408 = xi[1u];
            let _e410 = l_2.v;
            pointOnLight = ((_e400 + (_e404 * _e402)) + (_e410 * _e408));
            let _e414 = l_2.u;
            let _e416 = l_2.v;
            param_587 = cross(_e414, _e416);
            let _e418 = safe_normalize_u0028_vf3_u003b((&param_587));
            lightNormal = _e418;
            let _e420 = l_2.u;
            let _e422 = l_2.v;
            area = length(cross(_e420, _e422));
            let _e425 = pointOnLight;
            let _e426 = (*pW_6);
            toLight = (_e425 - _e426);
            let _e428 = toLight;
            let _e429 = toLight;
            distSq = max(dot(_e428, _e429), 0.0000000001f);
            let _e432 = distSq;
            distanceToLight = sqrt(_e432);
            let _e434 = toLight;
            let _e435 = distanceToLight;
            (*woutputW) = (_e434 / vec3(_e435));
            let _e438 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e438 - 0.0002f));
            let _e441 = lightNormal;
            let _e442 = (*woutputW);
            cosLight = max(dot(_e441, -(_e442)), 0f);
            let _e446 = cosLight;
            let _e448 = area;
            if ((_e446 <= 0f) || (_e448 <= 0f)) {
                let _e451 = (*woutputW);
                param_588 = _e451;
                let _e452 = (*basis_6);
                param_589 = _e452;
                let _e453 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_588), (&param_589));
                (*woutputL_4) = _e453;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e454 = cosLight;
            let _e455 = area;
            let _e457 = distSq;
            let _e459 = intensity;
            intensity = (_e459 * ((_e454 * _e455) / _e457));
            let _e461 = (*woutputW);
            param_590 = _e461;
            let _e462 = (*basis_6);
            param_591 = _e462;
            let _e463 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_590), (&param_591));
            (*woutputL_4) = _e463;
            let _e464 = intensity;
            return _e464;
        } else {
            let _e466 = l_2.position;
            let _e467 = (*pW_6);
            toLight_1 = (_e466 - _e467);
            let _e469 = toLight_1;
            distanceToLight_1 = max(length(_e469), 0.0000000001f);
            let _e472 = toLight_1;
            let _e473 = distanceToLight_1;
            (*woutputW) = (_e472 / vec3(_e473));
            let _e476 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e476 - 0.0002f));
            let _e479 = distanceToLight_1;
            let _e482 = l_2.decayRate;
            attenuation = pow((_e479 + 1f), (_e482 + 0.0000000001f));
            let _e485 = attenuation;
            let _e487 = intensity;
            intensity = (_e487 / vec3(max(_e485, 0.0000000001f)));
            let _e491 = l_2.type_;
            if (_e491 == 2i) {
                let _e493 = (*woutputW);
                let _e495 = l_2.direction;
                param_592 = _e495;
                let _e496 = safe_normalize_u0028_vf3_u003b((&param_592));
                cosDir = dot(_e493, -(_e496));
                let _e500 = l_2.innerCone;
                let _e502 = l_2.outerCone;
                low = min(_e500, _e502);
                let _e505 = l_2.innerCone;
                high = _e505;
                let _e506 = low;
                let _e507 = high;
                let _e508 = cosDir;
                let _e510 = intensity;
                intensity = (_e510 * smoothstep(_e506, _e507, _e508));
            }
        }
    }
    let _e512 = (*woutputW);
    param_593 = _e512;
    let _e513 = (*basis_6);
    param_594 = _e513;
    let _e514 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_593), (&param_594));
    (*woutputL_4) = _e514;
    let _e515 = intensity;
    return _e515;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_595: i32;
    var power: f32;

    let _e344 = (*index_2);
    param_595 = _e344;
    let _e345 = GetMtlxLight_u0028_i1_u003b((&param_595));
    l_3 = _e345;
    let _e347 = l_3.color;
    let _e349 = l_3.intensity;
    power = length((_e347 * _e349));
    let _e353 = l_3.type_;
    if (_e353 == 3i) {
        let _e356 = l_3.u;
        let _e358 = l_3.v;
        let _e361 = power;
        power = (_e361 * length(cross(_e356, _e358)));
    }
    let _e363 = power;
    return _e363;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e345 = unnamed.sunAngularSize;
    theta_max = ((_e345 * 3.1415927f) / 180f);
    let _e348 = (*woutputW_1);
    let _e350 = unnamed.sunDir;
    let _e352 = theta_max;
    if (dot(_e348, _e350) < cos(_e352)) {
        return 0f;
    }
    let _e355 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e355)));
    let _e359 = solid_angle;
    return (1f / _e359);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e343 = unnamed.sunAngularSize;
    theta_max_1 = ((_e343 * 3.1415927f) / 180f);
    let _e346 = (*woutputW_2);
    let _e348 = unnamed.sunDir;
    let _e350 = theta_max_1;
    if (dot(_e346, _e348) < cos(_e350)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e354 = unnamed.sunPower;
    let _e356 = unnamed.sunColor;
    return (_e356 * _e354);
}

fn envMapLuminance_u0028_vf3_u003b(c_4: ptr<function, vec3<f32>>) -> f32 {
    let _e341 = (*c_4);
    return dot(_e341, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_7: ptr<function, vec3<f32>>) -> f32 {
    var theta_1: f32;
    var s_5: f32;
    var pdf_2: f32;
    var param_596: vec3<f32>;

    let _e347 = (*uv_3)[1u];
    theta_1 = (_e347 * 3.1415927f);
    let _e349 = theta_1;
    s_5 = sin(_e349);
    let _e351 = s_5;
    if (_e351 <= 0f) {
        return 0f;
    }
    let _e353 = (*color_7);
    param_596 = _e353;
    let _e354 = envMapLuminance_u0028_vf3_u003b((&param_596));
    let _e356 = unnamed.envMapTotalSum;
    pdf_2 = (_e354 / max(_e356, 0.0000000001f));
    let _e359 = pdf_2;
    let _e362 = unnamed.envMapRes[0u];
    let _e366 = unnamed.envMapRes[1u];
    let _e368 = s_5;
    return (((_e359 * _e362) * _e366) / (19.739208f * _e368));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_2: f32;
    var s_6: f32;

    let _e345 = (*uv_4)[0u];
    phi_1 = (_e345 * 6.2831855f);
    let _e348 = (*uv_4)[1u];
    theta_2 = (_e348 * 3.1415927f);
    let _e350 = theta_2;
    s_6 = sin(_e350);
    let _e352 = s_6;
    let _e354 = phi_1;
    let _e357 = theta_2;
    let _e359 = s_6;
    let _e361 = phi_1;
    return vec3<f32>((-(_e352) * cos(_e354)), cos(_e357), (-(_e359) * sin(_e361)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_11: i32;

    let _e349 = unnamed.envMapRes;
    res = vec2<i32>(_e349);
    lower = 0i;
    let _e352 = res[1u];
    upper = (_e352 - 1i);
    loop {
        let _e354 = lower;
        let _e355 = upper;
        if (_e354 < _e355) {
            let _e357 = lower;
            let _e358 = upper;
            mid = ((_e357 + _e358) >> bitcast<u32>(1i));
            let _e362 = (*value);
            let _e364 = res[0u];
            let _e366 = mid;
            let _e368 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e364 - 1i), _e366), 0i);
            if (_e362 < _e368.x) {
                let _e371 = mid;
                upper = _e371;
            } else {
                let _e372 = mid;
                lower = (_e372 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e374 = lower;
    let _e376 = res[1u];
    y_5 = clamp(_e374, 0i, (_e376 - 1i));
    lower = 0i;
    let _e380 = res[0u];
    upper = (_e380 - 1i);
    loop {
        let _e382 = lower;
        let _e383 = upper;
        if (_e382 < _e383) {
            let _e385 = lower;
            let _e386 = upper;
            mid_1 = ((_e385 + _e386) >> bitcast<u32>(1i));
            let _e390 = (*value);
            let _e391 = mid_1;
            let _e392 = y_5;
            let _e394 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e391, _e392), 0i);
            if (_e390 < _e394.x) {
                let _e397 = mid_1;
                upper = _e397;
            } else {
                let _e398 = mid_1;
                lower = (_e398 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e400 = lower;
    let _e402 = res[0u];
    x_11 = clamp(_e400, 0i, (_e402 - 1i));
    let _e405 = x_11;
    let _e407 = y_5;
    let _e411 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e405), f32(_e407)) / _e411);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e343 = (*woutputW_3)[0u];
    let _e344 = (*woutputW_3);
    let _e345 = _e344.yz;
    let _e349 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e343, _e345.x, _e345.y), 0f);
    env = _e349;
    let _e350 = env;
    let _e353 = unnamed.skyPower;
    let _e356 = unnamed.skyColor;
    return ((_e350.xyz * _e353) * _e356);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_4: f32;
    var param_597: u32;
    var theta_3: f32;
    var param_598: u32;
    var x_12: f32;
    var y_6: f32;
    var z_1: f32;

    let _e349 = (*rndSeed_1);
    param_597 = _e349;
    let _e350 = rand_u0028_u1_u003b((&param_597));
    let _e351 = param_597;
    (*rndSeed_1) = _e351;
    r_4 = sqrt(_e350);
    let _e353 = (*rndSeed_1);
    param_598 = _e353;
    let _e354 = rand_u0028_u1_u003b((&param_598));
    let _e355 = param_598;
    (*rndSeed_1) = _e355;
    theta_3 = (6.2831855f * _e354);
    let _e357 = r_4;
    let _e358 = theta_3;
    x_12 = (_e357 * cos(_e358));
    let _e361 = r_4;
    let _e362 = theta_3;
    y_6 = (_e361 * sin(_e362));
    let _e365 = x_12;
    let _e366 = x_12;
    let _e369 = y_6;
    let _e370 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e365 * _e366)) - (_e369 * _e370))));
    let _e375 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e375) / 3.1415927f));
    let _e379 = x_12;
    let _e380 = y_6;
    let _e381 = z_1;
    return vec3<f32>(_e379, _e380, _e381);
}

fn skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_7: ptr<function, Basis>, woutputL_6: ptr<function, vec3<f32>>, woutputW_4: ptr<function, vec3<f32>>, pdfDir: ptr<function, f32>, rndSeed_2: ptr<function, u32>) -> vec3<f32> {
    var param_599: u32;
    var param_600: f32;
    var param_601: vec3<f32>;
    var param_602: Basis;
    var param_603: vec3<f32>;
    var uv_5: vec2<f32>;
    var param_604: u32;
    var param_605: f32;
    var param_606: vec2<f32>;
    var param_607: vec3<f32>;
    var param_608: vec3<f32>;
    var param_609: Basis;
    var color_8: vec3<f32>;
    var param_610: vec2<f32>;
    var param_611: vec3<f32>;

    let _e361 = unnamed.has_env_cdf;
    if !((_e361 != 0u)) {
        let _e364 = (*rndSeed_2);
        param_599 = _e364;
        let _e365 = (*pdfDir);
        param_600 = _e365;
        let _e366 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_599), (&param_600));
        let _e367 = param_599;
        (*rndSeed_2) = _e367;
        let _e368 = param_600;
        (*pdfDir) = _e368;
        (*woutputL_6) = _e366;
        let _e369 = (*woutputL_6);
        param_601 = _e369;
        let _e370 = (*basis_7);
        param_602 = _e370;
        let _e371 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_601), (&param_602));
        (*woutputW_4) = _e371;
        let _e372 = (*woutputW_4);
        param_603 = _e372;
        let _e373 = skyRadiance_u0028_vf3_u003b((&param_603));
        return _e373;
    }
    let _e374 = (*rndSeed_2);
    param_604 = _e374;
    let _e375 = rand_u0028_u1_u003b((&param_604));
    let _e376 = param_604;
    (*rndSeed_2) = _e376;
    let _e378 = unnamed.envMapTotalSum;
    param_605 = (_e375 * max(_e378, 0.0000000001f));
    let _e381 = envMapBinarySearch_u0028_f1_u003b((&param_605));
    uv_5 = _e381;
    let _e382 = uv_5;
    param_606 = _e382;
    let _e383 = envMapUvToDir_u0028_vf2_u003b((&param_606));
    param_607 = _e383;
    let _e384 = safe_normalize_u0028_vf3_u003b((&param_607));
    (*woutputW_4) = _e384;
    let _e385 = (*woutputW_4);
    param_608 = _e385;
    let _e386 = (*basis_7);
    param_609 = _e386;
    let _e387 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_608), (&param_609));
    (*woutputL_6) = _e387;
    let _e388 = uv_5;
    let _e389 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e388, 0f);
    color_8 = _e389.xyz;
    let _e391 = uv_5;
    param_610 = _e391;
    let _e392 = color_8;
    param_611 = _e392;
    let _e393 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_610), (&param_611));
    (*pdfDir) = _e393;
    let _e395 = unnamed.skyPower;
    let _e397 = unnamed.skyColor;
    let _e399 = color_8;
    return ((_e397 * _e395) * _e399);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_4: f32;

    let _e343 = (*d)[1u];
    theta_4 = acos(clamp(_e343, -1f, 1f));
    let _e347 = (*d)[2u];
    let _e349 = (*d)[0u];
    let _e353 = theta_4;
    return vec2<f32>(((3.1415927f + atan2(_e347, _e349)) * 0.15915494f), (_e353 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_612: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_613: vec3<f32>;
    var param_614: vec3<f32>;
    var color_9: vec3<f32>;
    var param_615: vec2<f32>;
    var param_616: vec3<f32>;

    let _e350 = unnamed.has_env_cdf;
    if !((_e350 != 0u)) {
        let _e353 = (*woutputL_7);
        param_612 = _e353;
        let _e354 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_612));
        return _e354;
    }
    let _e355 = (*woutputW_5);
    param_613 = _e355;
    let _e356 = safe_normalize_u0028_vf3_u003b((&param_613));
    param_614 = _e356;
    let _e357 = envMapDirToUv_u0028_vf3_u003b((&param_614));
    uv_6 = _e357;
    let _e358 = uv_6;
    let _e359 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e358, 0f);
    color_9 = _e359.xyz;
    let _e361 = uv_6;
    param_615 = _e361;
    let _e362 = color_9;
    param_616 = _e362;
    let _e363 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_615), (&param_616));
    return _e363;
}

fn sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_8: ptr<function, Basis>, woutputL_8: ptr<function, vec3<f32>>, woutputW_6: ptr<function, vec3<f32>>, pdfDir_1: ptr<function, f32>, rndSeed_3: ptr<function, u32>) -> vec3<f32> {
    var theta_max_2: f32;
    var theta_5: f32;
    var param_617: u32;
    var costheta: f32;
    var sintheta: f32;
    var phi_2: f32;
    var param_618: u32;
    var cosphi: f32;
    var sinphi: f32;
    var x_13: f32;
    var y_7: f32;
    var z_2: f32;
    var solid_angle_1: f32;
    var param_619: vec3<f32>;
    var param_620: Basis;
    var param_621: vec3<f32>;
    var param_622: Basis;

    let _e363 = unnamed.sunAngularSize;
    theta_max_2 = ((_e363 * 3.1415927f) / 180f);
    let _e366 = theta_max_2;
    let _e367 = (*rndSeed_3);
    param_617 = _e367;
    let _e368 = rand_u0028_u1_u003b((&param_617));
    let _e369 = param_617;
    (*rndSeed_3) = _e369;
    theta_5 = (_e366 * sqrt(_e368));
    let _e372 = theta_5;
    costheta = cos(_e372);
    let _e374 = costheta;
    let _e375 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e374 * _e375))));
    let _e380 = (*rndSeed_3);
    param_618 = _e380;
    let _e381 = rand_u0028_u1_u003b((&param_618));
    let _e382 = param_618;
    (*rndSeed_3) = _e382;
    phi_2 = (6.2831855f * _e381);
    let _e384 = phi_2;
    cosphi = cos(_e384);
    let _e386 = phi_2;
    sinphi = sin(_e386);
    let _e388 = sintheta;
    let _e389 = cosphi;
    x_13 = (_e388 * _e389);
    let _e391 = sintheta;
    let _e392 = sinphi;
    y_7 = (_e391 * _e392);
    let _e394 = costheta;
    z_2 = _e394;
    let _e395 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e395)));
    let _e399 = solid_angle_1;
    (*pdfDir_1) = (1f / _e399);
    let _e401 = x_13;
    let _e402 = y_7;
    let _e403 = z_2;
    param_619 = vec3<f32>(_e401, _e402, _e403);
    let _e405 = sunBasis;
    param_620 = _e405;
    let _e406 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_619), (&param_620));
    (*woutputW_6) = _e406;
    let _e407 = (*woutputW_6);
    param_621 = _e407;
    let _e408 = (*basis_8);
    param_622 = _e408;
    let _e409 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_621), (&param_622));
    (*woutputL_8) = _e409;
    let _e411 = unnamed.sunPower;
    let _e413 = unnamed.sunColor;
    let _e415 = solid_angle_1;
    return ((_e413 * _e411) / vec3(_e415));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e341 = unnamed.skyPower;
    let _e343 = unnamed.skyColor;
    return (length((_e343 * _e341)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e341 = unnamed.sunPower;
    let _e343 = unnamed.sunColor;
    return length((_e343 * _e341));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_5: i32;
    var param_623: i32;

    power_1 = 0f;
    i_5 = 0i;
    loop {
        let _e343 = i_5;
        if (_e343 < 1i) {
            let _e345 = i_5;
            let _e347 = unnamed.mtlxLightCount;
            if (_e345 >= _e347) {
                break;
            }
            let _e349 = i_5;
            param_623 = _e349;
            let _e350 = mtlxLightTotalPower_u0028_i1_u003b((&param_623));
            let _e351 = power_1;
            power_1 = (_e351 + _e350);
            continue;
        } else {
            break;
        }
        continuing {
            let _e353 = i_5;
            i_5 = (_e353 + 1i);
        }
    }
    let _e355 = power_1;
    return _e355;
}

fn LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(pW_7: ptr<function, vec3<f32>>, basis_9: ptr<function, Basis>, shadowL: ptr<function, vec3<f32>>, shadowW: ptr<function, vec3<f32>>, lightPdf: ptr<function, f32>, rndSeed_4: ptr<function, u32>) -> vec3<f32> {
    var w_mtlx: f32;
    var w_sun: f32;
    var local_15: f32;
    var w_sky: f32;
    var w_total: f32;
    var P_sun: f32;
    var P_sky: f32;
    var P_mtlx: f32;
    var r_5: f32;
    var param_624: u32;
    var maxDistance_5: f32;
    var Li_7: vec3<f32>;
    var pdf_sun: f32;
    var param_625: Basis;
    var param_626: vec3<f32>;
    var param_627: vec3<f32>;
    var param_628: f32;
    var param_629: u32;
    var param_630: vec3<f32>;
    var pdf_sky: f32;
    var param_631: vec3<f32>;
    var param_632: vec3<f32>;
    var param_633: Basis;
    var param_634: vec3<f32>;
    var param_635: vec3<f32>;
    var param_636: f32;
    var param_637: u32;
    var param_638: vec3<f32>;
    var param_639: vec3<f32>;
    var param_640: vec3<f32>;
    var target_: f32;
    var param_641: u32;
    var accum: f32;
    var selected: i32;
    var i_6: i32;
    var param_642: i32;
    var selectedPower: f32;
    var param_643: i32;
    var param_644: i32;
    var param_645: vec3<f32>;
    var param_646: Basis;
    var param_647: vec3<f32>;
    var param_648: vec3<f32>;
    var param_649: f32;
    var param_650: u32;
    var param_651: vec3<f32>;
    var param_652: vec3<f32>;
    var param_653: vec3<f32>;
    var param_654: vec3<f32>;
    var param_655: vec3<f32>;
    var shadowOrigin: vec3<f32>;
    var visibility: f32;
    var param_656: vec3<f32>;
    var param_657: vec3<f32>;
    var param_658: f32;
    var param_659: vec3<f32>;
    var shadowOrigin_1: vec3<f32>;
    var visibility_1: f32;
    var param_660: vec3<f32>;
    var param_661: vec3<f32>;
    var param_662: f32;
    var phi_8544_: bool;

    let _e407 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e407;
    let _e409 = unnamed.mtlxDisableSun;
    let _e410 = (_e409 != 0u);
    phi_8544_ = _e410;
    if !(_e410) {
        let _e413 = unnamed.mtlxLightCount;
        phi_8544_ = (_e413 > 0i);
    }
    let _e416 = phi_8544_;
    if _e416 {
        local_15 = 0f;
    } else {
        let _e417 = sunTotalPower_u0028_();
        local_15 = _e417;
    }
    let _e418 = local_15;
    w_sun = _e418;
    let _e419 = skyTotalPower_u0028_();
    w_sky = _e419;
    let _e420 = w_sun;
    let _e421 = w_sky;
    let _e423 = w_mtlx;
    w_total = max(0.0000000001f, ((_e420 + _e421) + _e423));
    let _e426 = w_sun;
    let _e427 = w_total;
    P_sun = (_e426 / _e427);
    let _e429 = w_sky;
    let _e430 = w_total;
    P_sky = (_e429 / _e430);
    let _e432 = w_mtlx;
    let _e433 = w_total;
    P_mtlx = (_e432 / _e433);
    let _e435 = (*rndSeed_4);
    param_624 = _e435;
    let _e436 = rand_u0028_u1_u003b((&param_624));
    let _e437 = param_624;
    (*rndSeed_4) = _e437;
    r_5 = _e436;
    maxDistance_5 = 100000000000000000000f;
    let _e438 = r_5;
    let _e439 = P_sun;
    if (_e438 < _e439) {
        let _e441 = (*basis_9);
        param_625 = _e441;
        let _e442 = (*shadowL);
        param_626 = _e442;
        let _e443 = (*shadowW);
        param_627 = _e443;
        let _e444 = pdf_sun;
        param_628 = _e444;
        let _e445 = (*rndSeed_4);
        param_629 = _e445;
        let _e446 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_625), (&param_626), (&param_627), (&param_628), (&param_629));
        let _e447 = param_626;
        (*shadowL) = _e447;
        let _e448 = param_627;
        (*shadowW) = _e448;
        let _e449 = param_628;
        pdf_sun = _e449;
        let _e450 = param_629;
        (*rndSeed_4) = _e450;
        Li_7 = _e446;
        let _e451 = (*shadowW);
        param_630 = _e451;
        let _e452 = skyRadiance_u0028_vf3_u003b((&param_630));
        let _e453 = Li_7;
        Li_7 = (_e453 + _e452);
        let _e455 = (*shadowL);
        param_631 = _e455;
        let _e456 = (*shadowW);
        param_632 = _e456;
        let _e457 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_631), (&param_632));
        pdf_sky = _e457;
    } else {
        let _e458 = r_5;
        let _e459 = P_sun;
        let _e460 = P_sky;
        if (_e458 < (_e459 + _e460)) {
            let _e463 = (*basis_9);
            param_633 = _e463;
            let _e464 = (*rndSeed_4);
            param_637 = _e464;
            let _e465 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_633), (&param_634), (&param_635), (&param_636), (&param_637));
            let _e466 = param_634;
            (*shadowL) = _e466;
            let _e467 = param_635;
            (*shadowW) = _e467;
            let _e468 = param_636;
            pdf_sky = _e468;
            let _e469 = param_637;
            (*rndSeed_4) = _e469;
            Li_7 = _e465;
            let _e470 = w_sun;
            if (_e470 > 0f) {
                let _e472 = (*shadowW);
                param_638 = _e472;
                let _e473 = sunRadiance_u0028_vf3_u003b((&param_638));
                let _e474 = Li_7;
                Li_7 = (_e474 + _e473);
            }
            let _e476 = (*shadowL);
            param_639 = _e476;
            let _e477 = (*shadowW);
            param_640 = _e477;
            let _e478 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_639), (&param_640));
            pdf_sun = _e478;
        } else {
            let _e479 = (*rndSeed_4);
            param_641 = _e479;
            let _e480 = rand_u0028_u1_u003b((&param_641));
            let _e481 = param_641;
            (*rndSeed_4) = _e481;
            let _e482 = w_mtlx;
            target_ = (_e480 * max(_e482, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_6 = 0i;
            loop {
                let _e485 = i_6;
                if (_e485 < 1i) {
                    let _e487 = i_6;
                    let _e489 = unnamed.mtlxLightCount;
                    if (_e487 >= _e489) {
                        break;
                    }
                    let _e491 = i_6;
                    param_642 = _e491;
                    let _e492 = mtlxLightTotalPower_u0028_i1_u003b((&param_642));
                    let _e493 = accum;
                    accum = (_e493 + _e492);
                    let _e495 = target_;
                    let _e496 = accum;
                    if (_e495 <= _e496) {
                        let _e498 = i_6;
                        selected = _e498;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e499 = i_6;
                    i_6 = (_e499 + 1i);
                }
            }
            let _e501 = selected;
            param_643 = _e501;
            let _e502 = mtlxLightTotalPower_u0028_i1_u003b((&param_643));
            selectedPower = max(_e502, 0.0000000001f);
            let _e504 = selected;
            param_644 = _e504;
            let _e505 = (*pW_7);
            param_645 = _e505;
            let _e506 = (*basis_9);
            param_646 = _e506;
            let _e507 = (*rndSeed_4);
            param_650 = _e507;
            let _e508 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650));
            let _e509 = param_647;
            (*shadowL) = _e509;
            let _e510 = param_648;
            (*shadowW) = _e510;
            let _e511 = param_649;
            maxDistance_5 = _e511;
            let _e512 = param_650;
            (*rndSeed_4) = _e512;
            Li_7 = _e508;
            let _e513 = (*shadowL);
            param_651 = _e513;
            let _e514 = (*shadowW);
            param_652 = _e514;
            let _e515 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_651), (&param_652));
            pdf_sun = _e515;
            let _e516 = (*shadowL);
            param_653 = _e516;
            let _e517 = (*shadowW);
            param_654 = _e517;
            let _e518 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_653), (&param_654));
            pdf_sky = _e518;
            let _e519 = P_mtlx;
            let _e520 = selectedPower;
            let _e522 = w_mtlx;
            (*lightPdf) = ((_e519 * _e520) / max(_e522, 0.0000000001f));
            let _e526 = (*shadowL)[2u];
            if (_e526 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e528 = Li_7;
            param_655 = _e528;
            let _e529 = maxComponent_u0028_vf3_u003b((&param_655));
            if (_e529 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e531 = (*pW_7);
            let _e533 = (*basis_9).nW;
            let _e534 = (*shadowW);
            let _e536 = (*basis_9).nW;
            shadowOrigin = (_e531 + ((_e533 * sign(dot(_e534, _e536))) * 0.0001f));
            let _e542 = shadowOrigin;
            param_656 = _e542;
            let _e543 = (*shadowW);
            param_657 = _e543;
            let _e544 = maxDistance_5;
            param_658 = _e544;
            let _e545 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_656), (&param_657), (&param_658));
            visibility = _e545;
            let _e546 = visibility;
            let _e547 = Li_7;
            return (_e547 * _e546);
        }
    }
    let _e549 = P_sun;
    let _e550 = pdf_sun;
    let _e552 = P_sky;
    let _e553 = pdf_sky;
    (*lightPdf) = ((_e549 * _e550) + (_e552 * _e553));
    let _e557 = (*shadowL)[2u];
    if (_e557 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e559 = Li_7;
    param_659 = _e559;
    let _e560 = maxComponent_u0028_vf3_u003b((&param_659));
    if (_e560 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e562 = (*pW_7);
    let _e564 = (*basis_9).nW;
    let _e565 = (*shadowW);
    let _e567 = (*basis_9).nW;
    shadowOrigin_1 = (_e562 + ((_e564 * sign(dot(_e565, _e567))) * 0.0001f));
    let _e573 = shadowOrigin_1;
    param_660 = _e573;
    let _e574 = (*shadowW);
    param_661 = _e574;
    param_662 = 100000000000000000000f;
    let _e575 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_660), (&param_661), (&param_662));
    visibility_1 = _e575;
    let _e576 = visibility_1;
    let _e577 = Li_7;
    return (_e577 * _e576);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_663: vec3<f32>;
    var param_664: Basis;

    let _e346 = (*pW_8);
    g_ptP = _e346;
    let _e348 = (*basis_10).nW;
    g_ptN = _e348;
    let _e350 = (*basis_10).tW;
    g_ptTangent = _e350;
    let _e352 = (*basis_10).bW;
    g_ptBitangent = _e352;
    let _e354 = (*basis_10).texCoord;
    g_ptTexcoord = _e354;
    let _e355 = (*winputL_4);
    param_663 = _e355;
    let _e356 = (*basis_10);
    param_664 = _e356;
    let _e357 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_663), (&param_664));
    g_ptV = _e357;
    let _e359 = (*basis_10).nW;
    g_ptL = _e359;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e360 = opacity_1;
    g_ptOpacity = clamp(dot(_e360, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e363 = mtlxHostEvalSurface_u0028_();
    let _e364 = (*rndSeed_5);
    (*rndSeed_5) = (_e364 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_665: vec3<f32>;
    var param_666: Basis;
    var param_667: vec3<f32>;
    var param_668: u32;

    emissionSeed = 0u;
    let _e347 = (*pW_9);
    param_665 = _e347;
    let _e348 = (*basis_11);
    param_666 = _e348;
    param_667 = vec3<f32>(0f, 0f, 1f);
    let _e349 = emissionSeed;
    param_668 = _e349;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_665), (&param_666), (&param_667), (&param_668));
    let _e350 = param_668;
    emissionSeed = _e350;
    let _e351 = g_ptEmission;
    return max(_e351, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_669: vec3<f32>;
    var param_670: Basis;

    let _e345 = (*pW_10);
    param_669 = _e345;
    let _e346 = (*basis_12);
    param_670 = _e346;
    let _e347 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_669), (&param_670));
    return _e347;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_671: u32;
    var param_672: f32;
    var param_673: vec3<f32>;
    var phi_7565_: bool;

    let _e350 = (*winputL_6)[2u];
    if (_e350 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e352 = (*rndSeed_6);
    param_671 = _e352;
    let _e353 = (*pdf_woutputL_4);
    param_672 = _e353;
    let _e354 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_671), (&param_672));
    let _e355 = param_671;
    (*rndSeed_6) = _e355;
    let _e356 = param_672;
    (*pdf_woutputL_4) = _e356;
    (*woutputL_9) = _e354;
    let _e358 = unnamed.wireframe;
    let _e359 = (_e358 != 0u);
    phi_7565_ = _e359;
    if _e359 {
        let _e361 = (*basis_13).baryCoord;
        param_673 = _e361;
        let _e362 = minComponent_u0028_vf3_u003b((&param_673));
        phi_7565_ = (_e362 < 0.003f);
    }
    let _e365 = phi_7565_;
    if _e365 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e367 = unnamed.neutral_color;
    return (_e367 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_674: u32;
    var param_675: f32;
    var param_676: vec3<f32>;

    let _e350 = (*winputL_7)[2u];
    if (_e350 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e352 = (*rndSeed_7);
    param_674 = _e352;
    let _e353 = (*pdf_woutputL_5);
    param_675 = _e353;
    let _e354 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_674), (&param_675));
    let _e355 = param_674;
    (*rndSeed_7) = _e355;
    let _e356 = param_675;
    (*pdf_woutputL_5) = _e356;
    (*woutputL_10) = _e354;
    let _e357 = (*pW_12);
    param_676 = _e357;
    let _e358 = ground_albedo_u0028_vf3_u003b((&param_676));
    return (_e358 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e344 = (*w_1)[2u];
    if (abs(_e344) < 0.00000011920929f) {
        return 0f;
    }
    let _e347 = (*alpha_x);
    let _e349 = (*w_1)[0u];
    let _e351 = (*alpha_x);
    let _e353 = (*w_1)[0u];
    let _e356 = (*alpha_y);
    let _e358 = (*w_1)[1u];
    let _e360 = (*alpha_y);
    let _e362 = (*w_1)[1u];
    let _e367 = (*w_1)[2u];
    let _e369 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e347 * _e349) * (_e351 * _e353)) + ((_e356 * _e358) * (_e360 * _e362))) / (_e367 * _e369))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_677: vec3<f32>;
    var param_678: f32;
    var param_679: f32;
    var param_680: vec3<f32>;
    var param_681: f32;
    var param_682: f32;

    let _e350 = (*woL);
    param_677 = _e350;
    let _e351 = (*alpha_x_1);
    param_678 = _e351;
    let _e352 = (*alpha_y_1);
    param_679 = _e352;
    let _e353 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_677), (&param_678), (&param_679));
    let _e355 = (*wiL_1);
    param_680 = _e355;
    let _e356 = (*alpha_x_1);
    param_681 = _e356;
    let _e357 = (*alpha_y_1);
    param_682 = _e357;
    let _e358 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_680), (&param_681), (&param_682));
    return (1f / ((1f + _e353) + _e358));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e346 = (*alpha_x_2);
    ax = max(_e346, 0.0000000001f);
    let _e348 = (*alpha_y_2);
    ay = max(_e348, 0.0000000001f);
    let _e350 = ax;
    let _e352 = ay;
    let _e355 = (*m_5)[0u];
    let _e356 = ax;
    let _e359 = (*m_5)[0u];
    let _e360 = ax;
    let _e364 = (*m_5)[1u];
    let _e365 = ay;
    let _e368 = (*m_5)[1u];
    let _e369 = ay;
    let _e374 = (*m_5)[2u];
    let _e376 = (*m_5)[2u];
    let _e380 = (*m_5)[0u];
    let _e381 = ax;
    let _e384 = (*m_5)[0u];
    let _e385 = ax;
    let _e389 = (*m_5)[1u];
    let _e390 = ay;
    let _e393 = (*m_5)[1u];
    let _e394 = ay;
    let _e399 = (*m_5)[2u];
    let _e401 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e350) * _e352) * (((((_e355 / _e356) * (_e359 / _e360)) + ((_e364 / _e365) * (_e368 / _e369))) + (_e374 * _e376)) * ((((_e380 / _e381) * (_e384 / _e385)) + ((_e389 / _e390) * (_e393 / _e394))) + (_e399 * _e401))));
    let _e406 = Ddenom;
    return (1f / max(_e406, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_683: vec3<f32>;
    var param_684: f32;
    var param_685: f32;

    let _e346 = (*w_2);
    param_683 = _e346;
    let _e347 = (*alpha_x_3);
    param_684 = _e347;
    let _e348 = (*alpha_y_3);
    param_685 = _e348;
    let _e349 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_683), (&param_684), (&param_685));
    return (1f / (1f + _e349));
}

fn ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b(wiL_2: ptr<function, vec3<f32>>, alpha_x_4: ptr<function, f32>, alpha_y_4: ptr<function, f32>, rndSeed_8: ptr<function, u32>) -> vec3<f32> {
    var Xi_2: vec2<f32>;
    var param_686: u32;
    var param_687: u32;
    var V_15: vec3<f32>;
    var alpha_12: vec2<f32>;
    var phi_3: f32;
    var z_3: f32;
    var sinTheta_1: f32;
    var x_14: f32;
    var y_8: f32;
    var c_5: vec3<f32>;
    var H_7: vec3<f32>;

    let _e356 = (*rndSeed_8);
    param_686 = _e356;
    let _e357 = rand_u0028_u1_u003b((&param_686));
    let _e358 = param_686;
    (*rndSeed_8) = _e358;
    let _e359 = (*rndSeed_8);
    param_687 = _e359;
    let _e360 = rand_u0028_u1_u003b((&param_687));
    let _e361 = param_687;
    (*rndSeed_8) = _e361;
    Xi_2 = vec2<f32>(_e357, _e360);
    let _e363 = (*wiL_2);
    V_15 = _e363;
    let _e364 = (*alpha_x_4);
    let _e365 = (*alpha_y_4);
    alpha_12 = vec2<f32>(_e364, _e365);
    let _e367 = V_15;
    let _e369 = alpha_12;
    let _e370 = (_e367.xy * _e369);
    let _e372 = V_15[2u];
    V_15 = normalize(vec3<f32>(_e370.x, _e370.y, _e372));
    let _e378 = Xi_2[0u];
    phi_3 = (6.2831855f * _e378);
    let _e381 = Xi_2[1u];
    let _e384 = V_15[2u];
    let _e388 = V_15[2u];
    z_3 = (((1f - _e381) * (1f + _e384)) - _e388);
    let _e390 = z_3;
    let _e391 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e390 * _e391)), 0f, 1f));
    let _e396 = sinTheta_1;
    let _e397 = phi_3;
    x_14 = (_e396 * cos(_e397));
    let _e400 = sinTheta_1;
    let _e401 = phi_3;
    y_8 = (_e400 * sin(_e401));
    let _e404 = x_14;
    let _e405 = y_8;
    let _e406 = z_3;
    c_5 = vec3<f32>(_e404, _e405, _e406);
    let _e408 = c_5;
    let _e409 = V_15;
    H_7 = (_e408 + _e409);
    let _e411 = H_7;
    let _e413 = alpha_12;
    let _e414 = (_e411.xy * _e413);
    let _e416 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e414.x, _e414.y, _e416));
    let _e421 = H_7;
    return _e421;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_6: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e345 = (*mui);
    c_6 = _e345;
    let _e346 = (*eta_ti);
    let _e347 = (*eta_ti);
    let _e349 = c_6;
    let _e350 = c_6;
    mut2_ = (((_e346 * _e347) + (_e349 * _e350)) - 1f);
    let _e354 = mut2_;
    if (_e354 <= 0f) {
        return 1f;
    }
    let _e356 = mut2_;
    g_1 = sqrt(_e356);
    let _e358 = g_1;
    let _e359 = c_6;
    let _e361 = g_1;
    let _e362 = c_6;
    let _e365 = g_1;
    let _e366 = c_6;
    let _e368 = g_1;
    let _e369 = c_6;
    let _e374 = g_1;
    let _e375 = c_6;
    let _e377 = c_6;
    let _e380 = g_1;
    let _e381 = c_6;
    let _e383 = c_6;
    let _e387 = g_1;
    let _e388 = c_6;
    let _e390 = c_6;
    let _e393 = g_1;
    let _e394 = c_6;
    let _e396 = c_6;
    return ((0.5f * (((_e358 - _e359) / (_e361 + _e362)) * ((_e365 - _e366) / (_e368 + _e369)))) * (1f + (((((_e374 + _e375) * _e377) - 1f) / (((_e380 - _e381) * _e383) + 1f)) * ((((_e387 + _e388) * _e390) - 1f) / (((_e393 - _e394) * _e396) + 1f)))));
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
    var V_16: vec3<f32>;
    var NdotV_21: f32;
    var alpha_13: f32;
    var anisoAspect: f32;
    var sampleAlpha: vec2<f32>;
    var coatAlpha: f32;
    var coatAnisoAspect: f32;
    var coatSampleAlpha: vec2<f32>;
    var F0d: f32;
    var F0_7: vec3<f32>;
    var F0lum: f32;
    var Fv: f32;
    var coatFv: f32;
    var param_688: f32;
    var param_689: f32;
    var pCoat: f32;
    var xiLobe: f32;
    var param_690: u32;
    var pTrans: f32;
    var m_transW: f32;
    var m_transC: vec3<f32>;
    var m_transD: f32;
    var Hc: vec3<f32>;
    var param_691: vec3<f32>;
    var param_692: f32;
    var param_693: f32;
    var param_694: u32;
    var pdfCoat: f32;
    var param_695: vec3<f32>;
    var param_696: f32;
    var param_697: f32;
    var param_698: vec3<f32>;
    var param_699: f32;
    var param_700: f32;
    var pdfBaseSpec: f32;
    var param_701: vec3<f32>;
    var param_702: f32;
    var param_703: f32;
    var param_704: vec3<f32>;
    var param_705: f32;
    var param_706: f32;
    var pdfBaseDiff: f32;
    var param_707: vec3<f32>;
    var diffLumCoat: f32;
    var pSpecCoat: f32;
    var ignorePdfCoat: f32;
    var param_708: vec3<f32>;
    var param_709: Basis;
    var param_710: vec3<f32>;
    var param_711: vec3<f32>;
    var param_712: f32;
    var externalTransmission: bool;
    var etaRatio: f32;
    var local_16: f32;
    var Hdelta: vec3<f32>;
    var HdotWiDelta: f32;
    var discrDelta: f32;
    var beamIncidentDelta: vec3<f32>;
    var Tdelta: f32;
    var param_713: f32;
    var param_714: f32;
    var tintDelta: vec3<f32>;
    var Vsample: vec3<f32>;
    var Ht_2: vec3<f32>;
    var param_715: vec3<f32>;
    var param_716: f32;
    var param_717: f32;
    var param_718: u32;
    var HdotWi: f32;
    var discr: f32;
    var beamIncident: vec3<f32>;
    var Hr: vec3<f32>;
    var VoH: f32;
    var LoH: f32;
    var denomT: f32;
    var jacT: f32;
    var DvT: f32;
    var param_719: vec3<f32>;
    var param_720: f32;
    var param_721: f32;
    var local_17: vec3<f32>;
    var param_722: vec3<f32>;
    var param_723: f32;
    var param_724: f32;
    var D_3: f32;
    var local_18: vec3<f32>;
    var param_725: vec3<f32>;
    var param_726: f32;
    var param_727: f32;
    var G2_: f32;
    var param_728: vec3<f32>;
    var param_729: vec3<f32>;
    var param_730: f32;
    var param_731: f32;
    var etaRefl: f32;
    var T_1: f32;
    var param_732: f32;
    var param_733: f32;
    var tint_3: vec3<f32>;
    var diffLum: f32;
    var pSpec: f32;
    var param_734: u32;
    var H_8: vec3<f32>;
    var param_735: vec3<f32>;
    var param_736: f32;
    var param_737: f32;
    var param_738: u32;
    var pdfTmp: f32;
    var param_739: u32;
    var param_740: f32;
    var Hh: vec3<f32>;
    var pdfSpec: f32;
    var param_741: vec3<f32>;
    var param_742: f32;
    var param_743: f32;
    var param_744: vec3<f32>;
    var param_745: f32;
    var param_746: f32;
    var pdfDiff: f32;
    var param_747: vec3<f32>;
    var pdfCoat_1: f32;
    var param_748: vec3<f32>;
    var param_749: f32;
    var param_750: f32;
    var param_751: vec3<f32>;
    var param_752: f32;
    var param_753: f32;
    var ignorePdf: f32;
    var param_754: vec3<f32>;
    var param_755: Basis;
    var param_756: vec3<f32>;
    var param_757: vec3<f32>;
    var param_758: f32;
    var phi_6759_: bool;
    var phi_6899_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e494 = metalness_1;
    m_metal = clamp(_e494, 0f, 1f);
    let _e496 = specular_roughness_1;
    m_rough = clamp(_e496, 0f, 1f);
    let _e498 = specular_anisotropy_1;
    m_aniso = clamp(_e498, 0f, 0.99f);
    let _e500 = base_color_1;
    let _e501 = base_3;
    m_base = (_e500 * _e501);
    let _e503 = specular_color_1;
    m_specC = _e503;
    let _e504 = specular_1;
    m_specW = _e504;
    let _e505 = specular_IOR_1;
    m_ior = max(_e505, 1.001f);
    let _e507 = coat_1;
    m_coatW = clamp(_e507, 0f, 1f);
    let _e509 = coat_roughness_1;
    m_coatRough = clamp(_e509, 0f, 1f);
    let _e511 = coat_anisotropy_1;
    m_coatAniso = clamp(_e511, 0f, 0.99f);
    let _e513 = coat_IOR_1;
    m_coatIor = max(_e513, 1.001f);
    let _e515 = (*winputL_8);
    V_16 = _e515;
    let _e517 = V_16[2u];
    if (_e517 < 0f) {
        let _e519 = V_16;
        V_16 = -(_e519);
    }
    let _e522 = V_16[2u];
    NdotV_21 = max(_e522, 0.0001f);
    let _e524 = m_rough;
    let _e525 = m_rough;
    alpha_13 = clamp((_e524 * _e525), 0.0001f, 1f);
    let _e528 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e528));
    let _e531 = alpha_13;
    let _e532 = anisoAspect;
    let _e533 = anisoAspect;
    let _e539 = alpha_13;
    let _e540 = anisoAspect;
    let _e542 = anisoAspect;
    let _e543 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e531 * sqrt((2f / ((_e532 * _e533) + 1f)))), ((_e539 * _e540) * sqrt((2f / ((_e542 * _e543) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e551 = m_coatRough;
    let _e552 = m_coatRough;
    coatAlpha = clamp((_e551 * _e552), 0.0001f, 1f);
    let _e555 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e555));
    let _e558 = coatAlpha;
    let _e559 = coatAnisoAspect;
    let _e560 = coatAnisoAspect;
    let _e566 = coatAlpha;
    let _e567 = coatAnisoAspect;
    let _e569 = coatAnisoAspect;
    let _e570 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e558 * sqrt((2f / ((_e559 * _e560) + 1f)))), ((_e566 * _e567) * sqrt((2f / ((_e569 * _e570) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e578 = m_ior;
    let _e580 = m_ior;
    F0d = pow(((_e578 - 1f) / (_e580 + 1f)), 2f);
    let _e584 = F0d;
    let _e586 = m_specC;
    let _e589 = m_specW;
    let _e591 = m_base;
    let _e592 = m_metal;
    F0_7 = mix(((vec3(_e584) * max(_e586, vec3<f32>(0f, 0f, 0f))) * _e589), _e591, vec3(_e592));
    let _e596 = F0_7[0u];
    let _e598 = F0_7[1u];
    let _e600 = F0_7[2u];
    F0lum = max(_e596, max(_e598, _e600));
    let _e603 = F0lum;
    let _e604 = F0lum;
    let _e606 = NdotV_21;
    Fv = (_e603 + ((1f - _e604) * pow((1f - _e606), 5f)));
    let _e611 = NdotV_21;
    param_688 = _e611;
    let _e612 = m_coatIor;
    param_689 = _e612;
    let _e613 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_688), (&param_689));
    coatFv = _e613;
    let _e614 = m_coatW;
    let _e615 = coatFv;
    pCoat = clamp((_e614 * _e615), 0f, 0.75f);
    let _e618 = (*rndSeed_9);
    param_690 = _e618;
    let _e619 = rand_u0028_u1_u003b((&param_690));
    let _e620 = param_690;
    (*rndSeed_9) = _e620;
    xiLobe = _e619;
    pTrans = 0f;
    let _e621 = transmission_1;
    m_transW = clamp(_e621, 0f, 1f);
    let _e623 = transmission_color_1;
    m_transC = _e623;
    let _e624 = transmission_depth_1;
    m_transD = _e624;
    let _e625 = m_transW;
    let _e626 = Fv;
    pTrans = clamp((_e625 * (1f - _e626)), 0f, 0.95f);
    let _e630 = xiLobe;
    let _e631 = pCoat;
    if (_e630 < _e631) {
        let _e633 = V_16;
        param_691 = _e633;
        let _e635 = coatSampleAlpha[0u];
        param_692 = _e635;
        let _e637 = coatSampleAlpha[1u];
        param_693 = _e637;
        let _e638 = (*rndSeed_9);
        param_694 = _e638;
        let _e639 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_691), (&param_692), (&param_693), (&param_694));
        let _e640 = param_694;
        (*rndSeed_9) = _e640;
        Hc = _e639;
        let _e641 = V_16;
        let _e643 = Hc;
        (*woutputL_11) = reflect(-(_e641), _e643);
        let _e646 = (*woutputL_11)[2u];
        if (_e646 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e648 = V_16;
        param_695 = _e648;
        let _e650 = coatSampleAlpha[0u];
        param_696 = _e650;
        let _e652 = coatSampleAlpha[1u];
        param_697 = _e652;
        let _e653 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_695), (&param_696), (&param_697));
        let _e654 = V_16;
        let _e655 = (*woutputL_11);
        param_698 = normalize((_e654 + _e655));
        let _e659 = coatSampleAlpha[0u];
        param_699 = _e659;
        let _e661 = coatSampleAlpha[1u];
        param_700 = _e661;
        let _e662 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_698), (&param_699), (&param_700));
        let _e664 = NdotV_21;
        pdfCoat = ((_e653 * _e662) / (4f * _e664));
        let _e667 = V_16;
        param_701 = _e667;
        let _e669 = sampleAlpha[0u];
        param_702 = _e669;
        let _e671 = sampleAlpha[1u];
        param_703 = _e671;
        let _e672 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_701), (&param_702), (&param_703));
        let _e673 = V_16;
        let _e674 = (*woutputL_11);
        param_704 = normalize((_e673 + _e674));
        let _e678 = sampleAlpha[0u];
        param_705 = _e678;
        let _e680 = sampleAlpha[1u];
        param_706 = _e680;
        let _e681 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_704), (&param_705), (&param_706));
        let _e683 = NdotV_21;
        pdfBaseSpec = ((_e672 * _e681) / (4f * _e683));
        let _e686 = (*woutputL_11);
        param_707 = _e686;
        let _e687 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_707));
        pdfBaseDiff = _e687;
        let _e688 = m_metal;
        let _e690 = m_base;
        diffLumCoat = ((1f - _e688) * dot(_e690, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e693 = Fv;
        let _e694 = Fv;
        let _e695 = Fv;
        let _e697 = diffLumCoat;
        pSpecCoat = clamp((_e693 / ((_e694 + ((1f - _e695) * _e697)) + 0.001f)), 0.05f, 0.95f);
        let _e703 = pCoat;
        let _e704 = pdfCoat;
        let _e706 = pCoat;
        let _e708 = pTrans;
        let _e711 = pSpecCoat;
        let _e712 = pdfBaseSpec;
        let _e714 = pSpecCoat;
        let _e716 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e703 * _e704) + (((1f - _e706) * (1f - _e708)) * ((_e711 * _e712) + ((1f - _e714) * _e716)))), 0.000001f);
        let _e722 = (*pW_13);
        param_708 = _e722;
        let _e723 = (*basis_15);
        param_709 = _e723;
        let _e724 = (*winputL_8);
        param_710 = _e724;
        let _e725 = (*woutputL_11);
        param_711 = _e725;
        let _e726 = ignorePdfCoat;
        param_712 = _e726;
        let _e727 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_708), (&param_709), (&param_710), (&param_711), (&param_712));
        let _e728 = param_712;
        ignorePdfCoat = _e728;
        return _e727;
    }
    let _e729 = xiLobe;
    let _e730 = pCoat;
    let _e731 = pCoat;
    let _e733 = pTrans;
    if (_e729 < (_e730 + ((1f - _e731) * _e733))) {
        let _e738 = (*winputL_8)[2u];
        externalTransmission = (_e738 > 0f);
        let _e740 = externalTransmission;
        if _e740 {
            let _e741 = m_ior;
            local_16 = (1f / _e741);
        } else {
            let _e743 = m_ior;
            local_16 = _e743;
        }
        let _e744 = local_16;
        etaRatio = _e744;
        let _e745 = alpha_13;
        if (_e745 <= 0.001f) {
            let _e747 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e747));
            let _e750 = Hdelta;
            let _e751 = (*winputL_8);
            HdotWiDelta = dot(_e750, _e751);
            let _e753 = etaRatio;
            let _e754 = etaRatio;
            let _e756 = HdotWiDelta;
            let _e757 = HdotWiDelta;
            discrDelta = (1f - ((_e753 * _e754) * (1f - (_e756 * _e757))));
            let _e762 = discrDelta;
            if (_e762 < 0f) {
                let _e764 = (*winputL_8);
                let _e766 = (*winputL_8);
                let _e767 = Hdelta;
                let _e770 = Hdelta;
                (*woutputL_11) = (-(_e764) + (_e770 * (2f * dot(_e766, _e767))));
                let _e773 = pCoat;
                let _e775 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e773) * _e775), 0.000001f);
                let _e778 = m_transW;
                let _e779 = (*pdf_woutputL_6);
                let _e782 = (*woutputL_11)[2u];
                return vec3(((_e778 * _e779) / max(abs(_e782), 0.0000000001f)));
            }
            let _e787 = etaRatio;
            let _e788 = (*winputL_8);
            let _e790 = Hdelta;
            let _e791 = HdotWiDelta;
            let _e794 = etaRatio;
            let _e795 = HdotWiDelta;
            let _e798 = discrDelta;
            beamIncidentDelta = ((_e788 * _e787) - ((_e790 * sign(_e791)) * ((_e794 * abs(_e795)) - sqrt(_e798))));
            let _e803 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e803));
            let _e807 = (*winputL_8)[2u];
            let _e809 = (*woutputL_11)[2u];
            if ((_e807 * _e809) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e812 = m_transD;
            let _e813 = (_e812 > 0f);
            phi_6759_ = _e813;
            if _e813 {
                let _e814 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_6759_ = !(_e814);
            }
            let _e817 = phi_6759_;
            if _e817 {
                let _e818 = m_transC;
                let _e822 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e818))) / vec3(_e822));
                let _e826 = transmission_scatter_1;
                (*internal_medium).albedo = clamp(_e826, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e829 = transmission_scatter_anisotropy_1;
                (*internal_medium).anisotropy = clamp(_e829, -0.99f, 0.99f);
            }
            let _e832 = HdotWiDelta;
            let _e834 = etaRatio;
            param_713 = abs(_e832);
            param_714 = (1f / _e834);
            let _e836 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_713), (&param_714));
            Tdelta = clamp((1f - _e836), 0f, 1f);
            let _e839 = m_transD;
            let _e841 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e841, (_e839 == 0f));
            let _e843 = pCoat;
            let _e845 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e843) * _e845), 0.000001f);
            let _e848 = m_transW;
            let _e849 = tintDelta;
            let _e851 = Tdelta;
            let _e853 = (*pdf_woutputL_6);
            let _e856 = (*woutputL_11)[2u];
            return ((((_e849 * _e848) * _e851) * _e853) / vec3(max(abs(_e856), 0.0000000001f)));
        }
        let _e861 = (*winputL_8);
        Vsample = _e861;
        let _e863 = Vsample[2u];
        if (_e863 < 0f) {
            let _e866 = Vsample[2u];
            Vsample[2u] = (_e866 * -1f);
        }
        let _e869 = Vsample;
        param_715 = _e869;
        let _e871 = sampleAlpha[0u];
        param_716 = _e871;
        let _e873 = sampleAlpha[1u];
        param_717 = _e873;
        let _e874 = (*rndSeed_9);
        param_718 = _e874;
        let _e875 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_715), (&param_716), (&param_717), (&param_718));
        let _e876 = param_718;
        (*rndSeed_9) = _e876;
        Ht_2 = _e875;
        let _e878 = (*winputL_8)[2u];
        if (_e878 < 0f) {
            let _e881 = Ht_2[2u];
            Ht_2[2u] = (_e881 * -1f);
        }
        let _e884 = Ht_2;
        let _e885 = (*winputL_8);
        HdotWi = dot(_e884, _e885);
        let _e887 = etaRatio;
        let _e888 = etaRatio;
        let _e890 = HdotWi;
        let _e891 = HdotWi;
        discr = (1f - ((_e887 * _e888) * (1f - (_e890 * _e891))));
        let _e896 = discr;
        if (_e896 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e898 = etaRatio;
        let _e899 = (*winputL_8);
        let _e901 = Ht_2;
        let _e902 = HdotWi;
        let _e905 = etaRatio;
        let _e906 = HdotWi;
        let _e909 = discr;
        beamIncident = ((_e899 * _e898) - ((_e901 * sign(_e902)) * ((_e905 * abs(_e906)) - sqrt(_e909))));
        let _e914 = beamIncident;
        (*woutputL_11) = -(normalize(_e914));
        let _e918 = (*winputL_8)[2u];
        let _e920 = (*woutputL_11)[2u];
        if ((_e918 * _e920) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e923 = m_transD;
        let _e924 = (_e923 > 0f);
        phi_6899_ = _e924;
        if _e924 {
            let _e925 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_6899_ = !(_e925);
        }
        let _e928 = phi_6899_;
        if _e928 {
            let _e929 = m_transC;
            let _e933 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e929))) / vec3(_e933));
            let _e937 = transmission_scatter_1;
            (*internal_medium).albedo = clamp(_e937, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e940 = transmission_scatter_anisotropy_1;
            (*internal_medium).anisotropy = clamp(_e940, -0.99f, 0.99f);
        }
        let _e943 = V_16;
        let _e944 = m_ior;
        let _e945 = (*woutputL_11);
        Hr = normalize(-((_e943 + (_e945 * _e944))));
        let _e951 = Hr[2u];
        if (_e951 < 0f) {
            let _e953 = Hr;
            Hr = -(_e953);
        }
        let _e955 = (*winputL_8);
        let _e956 = Ht_2;
        VoH = abs(dot(_e955, _e956));
        let _e959 = (*woutputL_11);
        let _e960 = Ht_2;
        LoH = abs(dot(_e959, _e960));
        let _e963 = LoH;
        let _e964 = etaRatio;
        let _e965 = VoH;
        denomT = (_e963 + (_e964 * _e965));
        let _e968 = etaRatio;
        let _e969 = etaRatio;
        let _e971 = VoH;
        let _e973 = denomT;
        let _e974 = denomT;
        jacT = (((_e968 * _e969) * _e971) / max((_e973 * _e974), 0.00000001f));
        let _e978 = Vsample;
        param_719 = _e978;
        let _e980 = sampleAlpha[0u];
        param_720 = _e980;
        let _e982 = sampleAlpha[1u];
        param_721 = _e982;
        let _e983 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_719), (&param_720), (&param_721));
        let _e984 = VoH;
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
        param_722 = _e999;
        let _e1001 = sampleAlpha[0u];
        param_723 = _e1001;
        let _e1003 = sampleAlpha[1u];
        param_724 = _e1003;
        let _e1004 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_722), (&param_723), (&param_724));
        let _e1007 = (*winputL_8)[2u];
        DvT = (((_e983 * _e984) * _e1004) / max(abs(_e1007), 0.0001f));
        let _e1011 = pCoat;
        let _e1013 = pTrans;
        let _e1015 = DvT;
        let _e1017 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e1011) * _e1013) * _e1015) * _e1017), 0.000001f);
        let _e1021 = Ht_2[2u];
        if (abs(_e1021) > 0f) {
            let _e1025 = Ht_2[0u];
            let _e1027 = Ht_2[1u];
            let _e1029 = Ht_2[2u];
            local_18 = vec3<f32>(_e1025, _e1027, abs(_e1029));
        } else {
            let _e1032 = Ht_2;
            local_18 = _e1032;
        }
        let _e1033 = local_18;
        param_725 = _e1033;
        let _e1035 = sampleAlpha[0u];
        param_726 = _e1035;
        let _e1037 = sampleAlpha[1u];
        param_727 = _e1037;
        let _e1038 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_725), (&param_726), (&param_727));
        D_3 = _e1038;
        let _e1039 = (*winputL_8);
        param_728 = _e1039;
        let _e1040 = (*woutputL_11);
        param_729 = _e1040;
        let _e1042 = sampleAlpha[0u];
        param_730 = _e1042;
        let _e1044 = sampleAlpha[1u];
        param_731 = _e1044;
        let _e1045 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_728), (&param_729), (&param_730), (&param_731));
        G2_ = _e1045;
        let _e1046 = etaRatio;
        etaRefl = (1f / _e1046);
        let _e1048 = VoH;
        param_732 = _e1048;
        let _e1049 = etaRefl;
        param_733 = _e1049;
        let _e1050 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_732), (&param_733));
        T_1 = clamp((1f - _e1050), 0f, 1f);
        let _e1053 = m_transD;
        let _e1055 = m_transC;
        tint_3 = select(vec3<f32>(1f, 1f, 1f), _e1055, (_e1053 == 0f));
        let _e1057 = m_transW;
        let _e1058 = tint_3;
        let _e1060 = T_1;
        let _e1062 = VoH;
        let _e1064 = jacT;
        let _e1066 = D_3;
        let _e1068 = G2_;
        let _e1071 = (*woutputL_11)[2u];
        let _e1074 = (*winputL_8)[2u];
        return (((((((_e1058 * _e1057) * _e1060) * _e1062) * _e1064) * _e1066) * _e1068) / vec3(max((abs(_e1071) * abs(_e1074)), 0.0000000001f)));
    }
    let _e1080 = m_metal;
    let _e1082 = m_base;
    diffLum = ((1f - _e1080) * dot(_e1082, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1085 = Fv;
    let _e1086 = Fv;
    let _e1087 = Fv;
    let _e1089 = diffLum;
    pSpec = clamp((_e1085 / ((_e1086 + ((1f - _e1087) * _e1089)) + 0.001f)), 0.05f, 0.95f);
    let _e1095 = (*rndSeed_9);
    param_734 = _e1095;
    let _e1096 = rand_u0028_u1_u003b((&param_734));
    let _e1097 = param_734;
    (*rndSeed_9) = _e1097;
    let _e1098 = pSpec;
    if (_e1096 < _e1098) {
        let _e1100 = V_16;
        param_735 = _e1100;
        let _e1102 = sampleAlpha[0u];
        param_736 = _e1102;
        let _e1104 = sampleAlpha[1u];
        param_737 = _e1104;
        let _e1105 = (*rndSeed_9);
        param_738 = _e1105;
        let _e1106 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_735), (&param_736), (&param_737), (&param_738));
        let _e1107 = param_738;
        (*rndSeed_9) = _e1107;
        H_8 = _e1106;
        let _e1108 = V_16;
        let _e1110 = H_8;
        (*woutputL_11) = reflect(-(_e1108), _e1110);
    } else {
        let _e1112 = (*rndSeed_9);
        param_739 = _e1112;
        let _e1113 = pdfTmp;
        param_740 = _e1113;
        let _e1114 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_739), (&param_740));
        let _e1115 = param_739;
        (*rndSeed_9) = _e1115;
        let _e1116 = param_740;
        pdfTmp = _e1116;
        (*woutputL_11) = _e1114;
    }
    let _e1118 = (*woutputL_11)[2u];
    if (_e1118 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1120 = V_16;
    let _e1121 = (*woutputL_11);
    Hh = normalize((_e1120 + _e1121));
    let _e1124 = V_16;
    param_741 = _e1124;
    let _e1126 = sampleAlpha[0u];
    param_742 = _e1126;
    let _e1128 = sampleAlpha[1u];
    param_743 = _e1128;
    let _e1129 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_741), (&param_742), (&param_743));
    let _e1130 = Hh;
    param_744 = _e1130;
    let _e1132 = sampleAlpha[0u];
    param_745 = _e1132;
    let _e1134 = sampleAlpha[1u];
    param_746 = _e1134;
    let _e1135 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_744), (&param_745), (&param_746));
    let _e1137 = NdotV_21;
    pdfSpec = ((_e1129 * _e1135) / (4f * _e1137));
    let _e1140 = (*woutputL_11);
    param_747 = _e1140;
    let _e1141 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_747));
    pdfDiff = _e1141;
    let _e1142 = V_16;
    param_748 = _e1142;
    let _e1144 = coatSampleAlpha[0u];
    param_749 = _e1144;
    let _e1146 = coatSampleAlpha[1u];
    param_750 = _e1146;
    let _e1147 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_748), (&param_749), (&param_750));
    let _e1148 = Hh;
    param_751 = _e1148;
    let _e1150 = coatSampleAlpha[0u];
    param_752 = _e1150;
    let _e1152 = coatSampleAlpha[1u];
    param_753 = _e1152;
    let _e1153 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_751), (&param_752), (&param_753));
    let _e1155 = NdotV_21;
    pdfCoat_1 = ((_e1147 * _e1153) / (4f * _e1155));
    let _e1158 = pCoat;
    let _e1159 = pdfCoat_1;
    let _e1161 = pCoat;
    let _e1163 = pTrans;
    let _e1166 = pSpec;
    let _e1167 = pdfSpec;
    let _e1169 = pSpec;
    let _e1171 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1158 * _e1159) + (((1f - _e1161) * (1f - _e1163)) * ((_e1166 * _e1167) + ((1f - _e1169) * _e1171)))), 0.000001f);
    let _e1177 = (*pW_13);
    param_754 = _e1177;
    let _e1178 = (*basis_15);
    param_755 = _e1178;
    let _e1179 = (*winputL_8);
    param_756 = _e1179;
    let _e1180 = (*woutputL_11);
    param_757 = _e1180;
    let _e1181 = ignorePdf;
    param_758 = _e1181;
    let _e1182 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_754), (&param_755), (&param_756), (&param_757), (&param_758));
    let _e1183 = param_758;
    ignorePdf = _e1183;
    return _e1182;
}

fn sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b(pW_14: ptr<function, vec3<f32>>, basis_16: ptr<function, Basis>, winputL_9: ptr<function, vec3<f32>>, rndSeed_10: ptr<function, u32>, surfaceshader_4: ptr<function, i32>, woutputL_12: ptr<function, vec3<f32>>, pdf_woutputL_7: ptr<function, f32>, internal_medium_1: ptr<function, Volume>) -> vec3<f32> {
    var param_759: vec3<f32>;
    var param_760: Basis;
    var param_761: vec3<f32>;
    var param_762: u32;
    var param_763: vec3<f32>;
    var param_764: f32;
    var param_765: Volume;
    var param_766: vec3<f32>;
    var param_767: Basis;
    var param_768: vec3<f32>;
    var param_769: u32;
    var param_770: vec3<f32>;
    var param_771: f32;
    var param_772: vec3<f32>;
    var param_773: Basis;
    var param_774: vec3<f32>;
    var param_775: u32;
    var param_776: vec3<f32>;
    var param_777: f32;

    let _e367 = (*surfaceshader_4);
    if (_e367 == 1i) {
        let _e369 = (*pW_14);
        param_759 = _e369;
        let _e370 = (*basis_16);
        param_760 = _e370;
        let _e371 = (*winputL_9);
        param_761 = _e371;
        let _e372 = (*rndSeed_10);
        param_762 = _e372;
        let _e373 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765));
        let _e374 = param_762;
        (*rndSeed_10) = _e374;
        let _e375 = param_763;
        (*woutputL_12) = _e375;
        let _e376 = param_764;
        (*pdf_woutputL_7) = _e376;
        let _e377 = param_765;
        (*internal_medium_1) = _e377;
        return _e373;
    } else {
        let _e378 = (*surfaceshader_4);
        if (_e378 == 2i) {
            let _e380 = (*pW_14);
            param_766 = _e380;
            let _e381 = (*basis_16);
            param_767 = _e381;
            let _e382 = (*winputL_9);
            param_768 = _e382;
            let _e383 = (*rndSeed_10);
            param_769 = _e383;
            let _e384 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_766), (&param_767), (&param_768), (&param_769), (&param_770), (&param_771));
            let _e385 = param_769;
            (*rndSeed_10) = _e385;
            let _e386 = param_770;
            (*woutputL_12) = _e386;
            let _e387 = param_771;
            (*pdf_woutputL_7) = _e387;
            return _e384;
        } else {
            let _e388 = (*pW_14);
            param_772 = _e388;
            let _e389 = (*basis_16);
            param_773 = _e389;
            let _e390 = (*winputL_9);
            param_774 = _e390;
            let _e391 = (*rndSeed_10);
            param_775 = _e391;
            let _e392 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_772), (&param_773), (&param_774), (&param_775), (&param_776), (&param_777));
            let _e393 = param_775;
            (*rndSeed_10) = _e393;
            let _e394 = param_776;
            (*woutputL_12) = _e394;
            let _e395 = param_777;
            (*pdf_woutputL_7) = _e395;
            return _e392;
        }
    }
}

fn mtlx_openpbr_thin_film_ior_u0028_() -> f32 {
    let _e340 = thin_film_IOR_1;
    return max(_e340, 1f);
}

fn mtlx_openpbr_thin_film_thickness_nm_u0028_() -> f32 {
    let _e340 = thin_film_thickness_1;
    return max(_e340, 0f);
}

fn mtlx_openpbr_specular_ior_u0028_() -> f32 {
    let _e340 = specular_IOR_1;
    return max(_e340, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e340 = specular_roughness_1;
    return clamp(_e340, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    let _e340 = thin_film_thickness_1;
    return clamp(select(0f, 1f, (_e340 > 0f)), 0f, 1f);
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e340 = transmission_1;
    return clamp(_e340, 0f, 1f);
}

fn evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(basis_17: ptr<function, Basis>, winputL_10: ptr<function, vec3<f32>>) -> vec3<f32> {
    var cosI: f32;
    var fd_11: FresnelData;
    var param_778: f32;
    var param_779: f32;
    var param_780: f32;
    var F_4: vec3<f32>;
    var param_781: f32;
    var param_782: FresnelData;
    var reflectedL: vec3<f32>;
    var reflectedW: vec3<f32>;
    var param_783: vec3<f32>;
    var param_784: Basis;
    var envRadiance: vec3<f32>;
    var param_785: vec3<f32>;
    var param_786: vec3<f32>;

    let _e357 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e357) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e359 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e359 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e361 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e361 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e363 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e363 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e366 = (*winputL_10)[2u];
    cosI = clamp(abs(_e366), 0.0001f, 1f);
    let _e369 = mtlx_openpbr_specular_ior_u0028_();
    let _e371 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e372 = mtlx_openpbr_thin_film_ior_u0028_();
    param_778 = max(_e369, 1.001f);
    param_779 = _e371;
    param_780 = _e372;
    let _e373 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_778), (&param_779), (&param_780));
    fd_11 = _e373;
    let _e374 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e375 = cosI;
    param_781 = _e375;
    let _e376 = fd_11;
    param_782 = _e376;
    let _e377 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_781), (&param_782));
    F_4 = (_e377 * _e374);
    let _e379 = (*winputL_10);
    reflectedL = reflect(-(_e379), vec3<f32>(0f, 0f, 1f));
    let _e383 = reflectedL[2u];
    if (_e383 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e385 = reflectedL;
    param_783 = _e385;
    let _e386 = (*basis_17);
    param_784 = _e386;
    let _e387 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_783), (&param_784));
    reflectedW = _e387;
    let _e388 = reflectedW;
    param_785 = _e388;
    let _e389 = sunRadiance_u0028_vf3_u003b((&param_785));
    let _e390 = reflectedW;
    param_786 = _e390;
    let _e391 = skyRadiance_u0028_vf3_u003b((&param_786));
    envRadiance = (_e389 + _e391);
    let _e393 = envRadiance;
    let _e395 = unnamed.skyPower;
    let _e398 = unnamed.skyColor;
    envRadiance = max(_e393, (_e398 * (0.25f * _e395)));
    let _e401 = F_4;
    let _e402 = envRadiance;
    return (_e401 * _e402);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_787: vec3<f32>;
    var param_788: vec3<f32>;

    let _e347 = (*nW);
    param_787 = _e347;
    let _e348 = safe_normalize_u0028_vf3_u003b((&param_787));
    basis_18.nW = _e348;
    let _e350 = (*tW);
    param_788 = _e350;
    let _e351 = safe_normalize_u0028_vf3_u003b((&param_788));
    basis_18.tW = _e351;
    let _e354 = basis_18.nW;
    let _e356 = basis_18.tW;
    basis_18.bW = cross(_e354, _e356);
    let _e359 = (*baryCoord_2);
    basis_18.baryCoord = _e359;
    let _e361 = (*texCoord_2);
    basis_18.texCoord = _e361;
    let _e363 = basis_18;
    return _e363;
}

fn powerHeuristic_u0028_f1_u003b_f1_u003b(a_4: f32, b_1: f32) -> f32 {
    return ((a_4 * a_4) / max(0.0000000001f, ((a_4 * a_4) + (b_1 * b_1))));
}

fn LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(shadowW_1: ptr<function, vec3<f32>>, basis_19: ptr<function, Basis>) -> f32 {
    var shadowL_1: vec3<f32>;
    var param_789: vec3<f32>;
    var param_790: Basis;
    var pdf_sky_1: f32;
    var param_791: vec3<f32>;
    var param_792: vec3<f32>;
    var pdf_sun_1: f32;
    var param_793: vec3<f32>;
    var param_794: vec3<f32>;
    var w_sun_1: f32;
    var local_19: f32;
    var w_sky_1: f32;
    var w_total_1: f32;
    var P_sun_1: f32;
    var P_sky_1: f32;
    var lightPdf_1: f32;
    var phi_8832_: bool;

    let _e358 = (*shadowW_1);
    param_789 = _e358;
    let _e359 = (*basis_19);
    param_790 = _e359;
    let _e360 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_789), (&param_790));
    shadowL_1 = _e360;
    let _e361 = shadowL_1;
    param_791 = _e361;
    let _e362 = (*shadowW_1);
    param_792 = _e362;
    let _e363 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_791), (&param_792));
    pdf_sky_1 = _e363;
    let _e364 = shadowL_1;
    param_793 = _e364;
    let _e365 = (*shadowW_1);
    param_794 = _e365;
    let _e366 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_793), (&param_794));
    pdf_sun_1 = _e366;
    let _e368 = unnamed.mtlxDisableSun;
    let _e369 = (_e368 != 0u);
    phi_8832_ = _e369;
    if !(_e369) {
        let _e372 = unnamed.mtlxLightCount;
        phi_8832_ = (_e372 > 0i);
    }
    let _e375 = phi_8832_;
    if _e375 {
        local_19 = 0f;
    } else {
        let _e376 = sunTotalPower_u0028_();
        local_19 = _e376;
    }
    let _e377 = local_19;
    w_sun_1 = _e377;
    let _e378 = skyTotalPower_u0028_();
    w_sky_1 = _e378;
    let _e379 = w_sun_1;
    let _e380 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e379 + _e380));
    let _e383 = w_sun_1;
    let _e384 = w_total_1;
    P_sun_1 = (_e383 / _e384);
    let _e386 = w_sky_1;
    let _e387 = w_total_1;
    P_sky_1 = (_e386 / _e387);
    let _e389 = P_sun_1;
    let _e390 = pdf_sun_1;
    let _e392 = P_sky_1;
    let _e393 = pdf_sky_1;
    lightPdf_1 = ((_e389 * _e390) + (_e392 * _e393));
    let _e396 = lightPdf_1;
    return _e396;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_795: vec3<f32>;
    var param_796: vec3<f32>;

    let _e344 = (*nW_1);
    param_795 = _e344;
    let _e345 = safe_normalize_u0028_vf3_u003b((&param_795));
    basis_20.nW = _e345;
    let _e347 = (*nW_1);
    param_796 = _e347;
    let _e348 = normalToTangent_u0028_vf3_u003b((&param_796));
    basis_20.tW = _e348;
    let _e351 = basis_20.nW;
    let _e353 = basis_20.tW;
    basis_20.bW = cross(_e351, _e353);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e358 = basis_20;
    return _e358;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e350 = (*cameraWorld);
    lookDirection = (_e350 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e352 = (*inverseProjection);
    nearVector = (_e352 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e355 = nearVector[2u];
    let _e357 = nearVector[3u];
    nearDistance_1 = abs((_e355 / _e357));
    let _e360 = (*cameraWorld);
    origin_1 = (_e360 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e362 = (*inverseProjection);
    let _e363 = (*coordinate);
    direction_1 = (_e362 * vec4<f32>(_e363.x, _e363.y, 0.5f, 1f));
    let _e369 = direction_1[3u];
    let _e370 = direction_1;
    direction_1 = (_e370 / vec4(_e369));
    let _e373 = (*cameraWorld);
    let _e374 = direction_1;
    let _e376 = origin_1;
    direction_1 = ((_e373 * _e374) - _e376);
    let _e378 = direction_1;
    let _e380 = nearDistance_1;
    let _e382 = direction_1;
    let _e383 = lookDirection;
    let _e387 = origin_1;
    let _e389 = (_e387.xyz + ((_e378.xyz * _e380) / vec3(dot(_e382, _e383))));
    origin_1[0u] = _e389.x;
    origin_1[1u] = _e389.y;
    origin_1[2u] = _e389.z;
    let _e396 = origin_1;
    (*rayOrigin_4) = _e396.xyz;
    let _e398 = direction_1;
    (*rayDirection_2) = _e398.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_20: f32;

    let _e342 = (*xi_1);
    if (_e342 < 0.5f) {
        let _e344 = (*xi_1);
        local_20 = (sqrt((2f * _e344)) - 1f);
    } else {
        let _e348 = (*xi_1);
        local_20 = (1f - sqrt((2f - (2f * _e348))));
    }
    let _e353 = local_20;
    return _e353;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e341 = (*seed_1);
    let _e344 = (*seed_1);
    (*seed_1) = (_e344 ^ (_e341 << bitcast<u32>(13u)));
    let _e346 = (*seed_1);
    let _e349 = (*seed_1);
    (*seed_1) = (_e349 ^ (_e346 >> bitcast<u32>(17u)));
    let _e351 = (*seed_1);
    let _e354 = (*seed_1);
    (*seed_1) = (_e354 ^ (_e351 << bitcast<u32>(5u)));
    return;
}

fn main_1() {
    var frag: vec2<f32>;
    var rndSeed_11: u32;
    var param_797: u32;
    var jx: f32;
    var param_798: u32;
    var param_799: f32;
    var jy: f32;
    var param_800: u32;
    var param_801: f32;
    var pixel: vec2<f32>;
    var ndc: vec2<f32>;
    var pW_15: vec3<f32>;
    var dW: vec3<f32>;
    var param_802: vec2<f32>;
    var param_803: mat4x4<f32>;
    var param_804: mat4x4<f32>;
    var param_805: vec3<f32>;
    var param_806: vec3<f32>;
    var param_807: vec3<f32>;
    var L_12: vec3<f32>;
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
    var param_808: vec3<f32>;
    var param_809: vec3<f32>;
    var param_810: f32;
    var param_811: vec3<f32>;
    var param_812: vec3<f32>;
    var param_813: vec3<f32>;
    var param_814: vec3<f32>;
    var param_815: vec3<f32>;
    var param_816: vec2<f32>;
    var param_817: i32;
    var misWeightLight: f32;
    var lightPdf_2: f32;
    var basis_21: Basis;
    var param_818: vec3<f32>;
    var param_819: Basis;
    var Lenv: vec3<f32>;
    var param_820: vec3<f32>;
    var param_821: vec3<f32>;
    var maxLenv: f32;
    var param_822: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW_1: vec3<f32>;
    var baryCoord_3: vec3<f32>;
    var texCoord_3: vec2<f32>;
    var surfaceshader_5: i32;
    var param_823: vec3<f32>;
    var param_824: vec3<f32>;
    var param_825: vec3<f32>;
    var param_826: vec2<f32>;
    var param_827: vec3<f32>;
    var param_828: vec3<f32>;
    var param_829: vec3<f32>;
    var param_830: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_11: vec3<f32>;
    var param_831: vec3<f32>;
    var param_832: Basis;
    var thin_walled_1: bool;
    var param_833: vec3<f32>;
    var param_834: Basis;
    var param_835: vec3<f32>;
    var param_836: u32;
    var Ltf: vec3<f32>;
    var param_837: Basis;
    var param_838: vec3<f32>;
    var maxLtf: f32;
    var param_839: vec3<f32>;
    var f_2: vec3<f32>;
    var woutputL_13: vec3<f32>;
    var internal_medium_2: Volume;
    var param_840: vec3<f32>;
    var param_841: Basis;
    var param_842: vec3<f32>;
    var param_843: u32;
    var param_844: i32;
    var param_845: vec3<f32>;
    var param_846: f32;
    var param_847: Volume;
    var woutputW_7: vec3<f32>;
    var param_848: vec3<f32>;
    var param_849: Basis;
    var transmitted_sample: bool;
    var cos_out: f32;
    var local_21: f32;
    var surface_throughput: vec3<f32>;
    var maxComp: f32;
    var param_850: vec3<f32>;
    var Le: vec3<f32>;
    var param_851: vec3<f32>;
    var param_852: Basis;
    var param_853: vec3<f32>;
    var maxLe: f32;
    var param_854: vec3<f32>;
    var transmitted: bool;
    var Li_8: vec3<f32>;
    var shadowL_2: vec3<f32>;
    var shadowW_2: vec3<f32>;
    var lightPdf_3: f32;
    var param_855: vec3<f32>;
    var param_856: Basis;
    var param_857: vec3<f32>;
    var param_858: vec3<f32>;
    var param_859: f32;
    var param_860: u32;
    var param_861: vec3<f32>;
    var bsdfPdf_shadow: f32;
    var fshadow: vec3<f32>;
    var param_862: vec3<f32>;
    var param_863: Basis;
    var param_864: vec3<f32>;
    var param_865: vec3<f32>;
    var param_866: i32;
    var param_867: f32;
    var misWeightLight_1: f32;
    var cos_shadow: f32;
    var local_22: f32;
    var Ld: vec3<f32>;
    var Lcontrib: vec3<f32>;
    var maxLcontrib: f32;
    var param_868: vec3<f32>;
    var maxTP: f32;
    var param_869: vec3<f32>;
    var param_870: vec3<f32>;
    var q: f32;
    var param_871: vec3<f32>;
    var param_872: u32;
    var phi_9167_: bool;
    var phi_9179_: bool;
    var phi_9180_: bool;
    var phi_9213_: bool;
    var phi_9220_: bool;
    var phi_9351_: bool;
    var phi_9442_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_3 = 1f;
    base_color_1 = vec3<f32>(1f, 1f, 1f);
    diffuse_roughness_1 = 0f;
    metalness_1 = 1f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    specular_roughness_1 = 0.001f;
    specular_IOR_1 = 1.5f;
    specular_anisotropy_1 = 0f;
    specular_rotation_1 = 0f;
    transmission_1 = 0f;
    transmission_color_1 = vec3<f32>(1f, 1f, 1f);
    transmission_depth_1 = 0f;
    transmission_scatter_1 = vec3<f32>(0f, 0f, 0f);
    transmission_scatter_anisotropy_1 = 0f;
    transmission_dispersion_1 = 0f;
    transmission_extra_roughness_1 = 0f;
    subsurface_1 = 0f;
    subsurface_color_1 = vec3<f32>(1f, 1f, 1f);
    subsurface_radius_1 = vec3<f32>(1f, 1f, 1f);
    subsurface_scale_1 = 1f;
    subsurface_anisotropy_1 = 0f;
    sheen_1 = 0f;
    sheen_color_1 = vec3<f32>(1f, 1f, 1f);
    sheen_roughness_1 = 0.3f;
    coat_1 = 0f;
    coat_color_1 = vec3<f32>(1f, 1f, 1f);
    coat_roughness_1 = 0.1f;
    coat_anisotropy_1 = 0f;
    coat_rotation_1 = 0f;
    coat_IOR_1 = 1.5f;
    coat_affect_color_1 = 0f;
    coat_affect_roughness_1 = 0f;
    thin_film_thickness_1 = 0f;
    thin_film_IOR_1 = 1.5f;
    emission_1 = 0f;
    emission_color_1 = vec3<f32>(1f, 1f, 1f);
    opacity_1 = vec3<f32>(1f, 1f, 1f);
    thin_walled_2 = false;
    let _e481 = gl_FragCoord_1;
    frag = _e481.xy;
    let _e484 = frag[0u];
    let _e486 = frag[1u];
    let _e489 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e484 + (_e486 * _e489)));
    let _e493 = rndSeed_11;
    param_797 = _e493;
    xorshift_u0028_u1_u003b((&param_797));
    let _e494 = param_797;
    rndSeed_11 = _e494;
    let _e496 = unnamed.samples;
    let _e498 = rndSeed_11;
    rndSeed_11 = (_e498 ^ u32(_e496));
    let _e500 = rndSeed_11;
    param_798 = _e500;
    let _e501 = rand_u0028_u1_u003b((&param_798));
    let _e502 = param_798;
    rndSeed_11 = _e502;
    param_799 = _e501;
    let _e503 = sample_triangle_filter_u0028_f1_u003b((&param_799));
    jx = (0.5f * _e503);
    let _e505 = rndSeed_11;
    param_800 = _e505;
    let _e506 = rand_u0028_u1_u003b((&param_800));
    let _e507 = param_800;
    rndSeed_11 = _e507;
    param_801 = _e506;
    let _e508 = sample_triangle_filter_u0028_f1_u003b((&param_801));
    jy = (0.5f * _e508);
    let _e510 = frag;
    let _e511 = jx;
    let _e512 = jy;
    pixel = (_e510 + vec2<f32>(_e511, _e512));
    let _e515 = pixel;
    let _e517 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e515 / _e517) * 2f));
    let _e523 = unnamed.invModelMatrix;
    let _e525 = unnamed.cameraWorldMatrix;
    let _e527 = ndc;
    param_802 = _e527;
    param_803 = (_e523 * _e525);
    let _e529 = unnamed.invProjectionMatrix;
    param_804 = _e529;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_802), (&param_803), (&param_804), (&param_805), (&param_806));
    let _e530 = param_805;
    pW_15 = _e530;
    let _e531 = param_806;
    dW = _e531;
    let _e532 = dW;
    dW = normalize(_e532);
    let _e535 = unnamed.sunDir;
    param_807 = _e535;
    let _e536 = makeBasis_u0028_vf3_u003b((&param_807));
    sunBasis = _e536;
    L_12 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e537 = vertex;
        let _e539 = unnamed.bounces;
        if (_e537 <= _e539) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e541 = inside_scattering_volume;
            if !(_e541) {
                let _e543 = pW_15;
                param_808 = _e543;
                let _e544 = dW;
                param_809 = _e544;
                param_810 = 100000000000000000000f;
                let _e545 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_808), (&param_809), (&param_810), (&param_811), (&param_812), (&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
                let _e546 = param_811;
                pW_next = _e546;
                let _e547 = param_812;
                NsW_next = _e547;
                let _e548 = param_813;
                NgW_next = _e548;
                let _e549 = param_814;
                TsW_next = _e549;
                let _e550 = param_815;
                baryCoord_next = _e550;
                let _e551 = param_816;
                texCoord_next = _e551;
                let _e552 = param_817;
                material_next = _e552;
                surface_hit = _e545;
            }
            let _e553 = surface_hit;
            if !(_e553) {
                misWeightLight = 1f;
                let _e555 = vertex;
                let _e557 = inside_scattering_volume;
                if ((_e555 > 0i) && !(_e557)) {
                    let _e560 = dW;
                    param_818 = _e560;
                    let _e561 = basis_21;
                    param_819 = _e561;
                    let _e562 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_818), (&param_819));
                    lightPdf_2 = _e562;
                    let _e563 = bsdfPdf_continuation;
                    let _e564 = lightPdf_2;
                    let _e565 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e563, _e564);
                    misWeightLight = _e565;
                }
                let _e566 = throughput;
                let _e567 = misWeightLight;
                let _e569 = dW;
                param_820 = _e569;
                let _e570 = sunRadiance_u0028_vf3_u003b((&param_820));
                let _e571 = dW;
                param_821 = _e571;
                let _e572 = skyRadiance_u0028_vf3_u003b((&param_821));
                Lenv = ((_e566 * _e567) * (_e570 + _e572));
                let _e575 = Lenv;
                param_822 = _e575;
                let _e576 = maxComponent_u0028_vf3_u003b((&param_822));
                maxLenv = _e576;
                let _e577 = maxLenv;
                let _e579 = unnamed.firefly_clamp;
                if (_e577 > _e579) {
                    let _e582 = unnamed.firefly_clamp;
                    let _e583 = maxLenv;
                    let _e585 = Lenv;
                    Lenv = (_e585 * (_e582 / _e583));
                }
                let _e587 = Lenv;
                let _e588 = L_12;
                L_12 = (_e588 + _e587);
                break;
            }
            let _e590 = vertex;
            let _e592 = unnamed.bounces;
            if (_e590 == _e592) {
                break;
            }
            let _e594 = pW_next;
            pW_15 = _e594;
            let _e595 = NsW_next;
            NsW = _e595;
            let _e596 = NgW_next;
            NgW = _e596;
            let _e597 = TsW_next;
            TsW_1 = _e597;
            let _e598 = baryCoord_next;
            baryCoord_3 = _e598;
            let _e599 = texCoord_next;
            texCoord_3 = _e599;
            let _e600 = material_next;
            surfaceshader_5 = _e600;
            let _e601 = surfaceshader_5;
            if (_e601 == 1i) {
                let _e603 = in_dielectric;
                phi_9167_ = _e603;
                if _e603 {
                    let _e604 = NsW;
                    let _e605 = dW;
                    phi_9167_ = (dot(_e604, _e605) < 0f);
                }
                let _e609 = phi_9167_;
                phi_9180_ = _e609;
                if !(_e609) {
                    let _e611 = in_dielectric;
                    let _e612 = !(_e611);
                    phi_9179_ = _e612;
                    if _e612 {
                        let _e613 = NsW;
                        let _e614 = dW;
                        phi_9179_ = (dot(_e613, _e614) > 0f);
                    }
                    let _e618 = phi_9179_;
                    phi_9180_ = _e618;
                }
                let _e620 = phi_9180_;
                if _e620 {
                    let _e621 = NsW;
                    NsW = (_e621 * -1f);
                }
            } else {
                let _e623 = NsW;
                let _e624 = dW;
                if (dot(_e623, _e624) > 0f) {
                    let _e627 = NsW;
                    NsW = (_e627 * -1f);
                }
            }
            let _e629 = NgW;
            let _e630 = NsW;
            if (dot(_e629, _e630) < 0f) {
                let _e633 = NgW;
                NgW = (_e633 * -1f);
            }
            let _e636 = unnamed.smooth_normals;
            if (_e636 != 0u) {
                let _e638 = surfaceshader_5;
                let _e639 = (_e638 == 1i);
                phi_9213_ = _e639;
                if _e639 {
                    let _e640 = mtlx_openpbr_is_opaque_u0028_();
                    phi_9213_ = _e640;
                }
                let _e642 = phi_9213_;
                phi_9220_ = _e642;
                if _e642 {
                    let _e643 = NsW;
                    let _e644 = dW;
                    phi_9220_ = (dot(_e643, _e644) > 0f);
                }
                let _e648 = phi_9220_;
                if _e648 {
                    let _e649 = NgW;
                    let _e651 = NgW;
                    let _e652 = NsW;
                    let _e655 = NsW;
                    NsW = (((_e649 * 2f) * dot(_e651, _e652)) - _e655);
                }
                let _e657 = NsW;
                param_823 = _e657;
                let _e658 = TsW_next;
                param_824 = _e658;
                let _e659 = baryCoord_3;
                param_825 = _e659;
                let _e660 = texCoord_3;
                param_826 = _e660;
                let _e661 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_823), (&param_824), (&param_825), (&param_826));
                basis_21 = _e661;
            } else {
                let _e662 = NgW;
                param_827 = _e662;
                let _e663 = TsW_next;
                param_828 = _e663;
                let _e664 = baryCoord_3;
                param_829 = _e664;
                let _e665 = texCoord_3;
                param_830 = _e665;
                let _e666 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_827), (&param_828), (&param_829), (&param_830));
                basis_21 = _e666;
            }
            let _e667 = dW;
            winputW = -(_e667);
            let _e669 = winputW;
            param_831 = _e669;
            let _e670 = basis_21;
            param_832 = _e670;
            let _e671 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_831), (&param_832));
            winputL_11 = _e671;
            let _e673 = winputL_11[2u];
            if (abs(_e673) < 0.001f) {
                break;
            }
            thin_walled_1 = false;
            let _e676 = surfaceshader_5;
            if (_e676 == 1i) {
                let _e678 = pW_15;
                param_833 = _e678;
                let _e679 = basis_21;
                param_834 = _e679;
                let _e680 = winputL_11;
                param_835 = _e680;
                let _e681 = rndSeed_11;
                param_836 = _e681;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_833), (&param_834), (&param_835), (&param_836));
                let _e682 = param_836;
                rndSeed_11 = _e682;
                let _e683 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled_1 = _e683;
            }
            let _e684 = surfaceshader_5;
            if (_e684 == 1i) {
                let _e686 = throughput;
                let _e687 = basis_21;
                param_837 = _e687;
                let _e688 = winputL_11;
                param_838 = _e688;
                let _e689 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_837), (&param_838));
                Ltf = (_e686 * _e689);
                let _e691 = Ltf;
                param_839 = _e691;
                let _e692 = maxComponent_u0028_vf3_u003b((&param_839));
                maxLtf = _e692;
                let _e693 = maxLtf;
                let _e695 = unnamed.firefly_clamp;
                if (_e693 > _e695) {
                    let _e698 = unnamed.firefly_clamp;
                    let _e699 = maxLtf;
                    let _e701 = Ltf;
                    Ltf = (_e701 * (_e698 / _e699));
                }
                let _e703 = Ltf;
                let _e704 = L_12;
                L_12 = (_e704 + _e703);
            }
            let _e706 = pW_15;
            param_840 = _e706;
            let _e707 = basis_21;
            param_841 = _e707;
            let _e708 = winputL_11;
            param_842 = _e708;
            let _e709 = rndSeed_11;
            param_843 = _e709;
            let _e710 = surfaceshader_5;
            param_844 = _e710;
            let _e711 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844), (&param_845), (&param_846), (&param_847));
            let _e712 = param_843;
            rndSeed_11 = _e712;
            let _e713 = param_845;
            woutputL_13 = _e713;
            let _e714 = param_846;
            bsdfPdf_continuation = _e714;
            let _e715 = param_847;
            internal_medium_2 = _e715;
            f_2 = _e711;
            let _e716 = woutputL_13;
            param_848 = _e716;
            let _e717 = basis_21;
            param_849 = _e717;
            let _e718 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_848), (&param_849));
            woutputW_7 = _e718;
            let _e719 = surfaceshader_5;
            let _e720 = (_e719 == 1i);
            phi_9351_ = _e720;
            if _e720 {
                let _e722 = winputL_11[2u];
                let _e724 = woutputL_13[2u];
                phi_9351_ = ((_e722 * _e724) < 0f);
            }
            let _e728 = phi_9351_;
            transmitted_sample = _e728;
            let _e729 = surfaceshader_5;
            let _e731 = transmitted_sample;
            if ((_e729 == 1i) && !(_e731)) {
                local_21 = 1f;
            } else {
                let _e734 = woutputW_7;
                let _e736 = basis_21.nW;
                local_21 = abs(dot(_e734, _e736));
            }
            let _e739 = local_21;
            cos_out = _e739;
            let _e740 = f_2;
            let _e741 = bsdfPdf_continuation;
            let _e745 = cos_out;
            surface_throughput = ((_e740 / vec3(max(0.000001f, _e741))) * _e745);
            let _e747 = surface_throughput;
            param_850 = _e747;
            let _e748 = maxComponent_u0028_vf3_u003b((&param_850));
            maxComp = _e748;
            let _e749 = maxComp;
            let _e751 = unnamed.firefly_clamp;
            if (_e749 > _e751) {
                let _e754 = unnamed.firefly_clamp;
                let _e755 = maxComp;
                let _e757 = surface_throughput;
                surface_throughput = (_e757 * (_e754 / _e755));
            }
            let _e759 = woutputW_7;
            dW = _e759;
            let _e760 = surfaceshader_5;
            if (_e760 == 1i) {
                let _e762 = throughput;
                let _e763 = pW_15;
                param_851 = _e763;
                let _e764 = basis_21;
                param_852 = _e764;
                let _e765 = winputL_11;
                param_853 = _e765;
                let _e766 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_851), (&param_852), (&param_853));
                Le = (_e762 * _e766);
                let _e768 = Le;
                param_854 = _e768;
                let _e769 = maxComponent_u0028_vf3_u003b((&param_854));
                maxLe = _e769;
                let _e770 = maxLe;
                let _e772 = unnamed.firefly_clamp;
                if (_e770 > _e772) {
                    let _e775 = unnamed.firefly_clamp;
                    let _e776 = maxLe;
                    let _e778 = Le;
                    Le = (_e778 * (_e775 / _e776));
                }
                let _e780 = Le;
                let _e781 = L_12;
                L_12 = (_e781 + _e780);
            }
            let _e783 = thin_walled_1;
            let _e785 = surfaceshader_5;
            let _e787 = (!(_e783) && (_e785 == 1i));
            phi_9442_ = _e787;
            if _e787 {
                let _e788 = winputW;
                let _e789 = NgW;
                let _e791 = dW;
                let _e792 = NgW;
                phi_9442_ = ((dot(_e788, _e789) * dot(_e791, _e792)) < 0f);
            }
            let _e797 = phi_9442_;
            transmitted = _e797;
            let _e798 = transmitted;
            if _e798 {
                let _e799 = in_dielectric;
                in_dielectric = !(_e799);
            }
            let _e801 = in_dielectric;
            let _e803 = transmitted;
            if (!(_e801) && !(_e803)) {
                let _e806 = pW_15;
                param_855 = _e806;
                let _e807 = basis_21;
                param_856 = _e807;
                let _e808 = rndSeed_11;
                param_860 = _e808;
                let _e809 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_855), (&param_856), (&param_857), (&param_858), (&param_859), (&param_860));
                let _e810 = param_857;
                shadowL_2 = _e810;
                let _e811 = param_858;
                shadowW_2 = _e811;
                let _e812 = param_859;
                lightPdf_3 = _e812;
                let _e813 = param_860;
                rndSeed_11 = _e813;
                Li_8 = _e809;
                let _e814 = Li_8;
                param_861 = _e814;
                let _e815 = maxComponent_u0028_vf3_u003b((&param_861));
                if (_e815 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e817 = pW_15;
                    param_862 = _e817;
                    let _e818 = basis_21;
                    param_863 = _e818;
                    let _e819 = winputL_11;
                    param_864 = _e819;
                    let _e820 = shadowL_2;
                    param_865 = _e820;
                    let _e821 = surfaceshader_5;
                    param_866 = _e821;
                    let _e822 = bsdfPdf_shadow;
                    param_867 = _e822;
                    let _e823 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_862), (&param_863), (&param_864), (&param_865), (&param_866), (&param_867));
                    let _e824 = param_867;
                    bsdfPdf_shadow = _e824;
                    fshadow = _e823;
                    let _e825 = lightPdf_3;
                    let _e826 = bsdfPdf_shadow;
                    let _e827 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e825, _e826);
                    misWeightLight_1 = _e827;
                    let _e828 = surfaceshader_5;
                    if (_e828 == 1i) {
                        local_22 = 1f;
                    } else {
                        let _e830 = shadowW_2;
                        let _e832 = basis_21.nW;
                        local_22 = abs(dot(_e830, _e832));
                    }
                    let _e835 = local_22;
                    cos_shadow = _e835;
                    let _e836 = misWeightLight_1;
                    let _e837 = fshadow;
                    let _e839 = cos_shadow;
                    let _e841 = Li_8;
                    let _e843 = lightPdf_3;
                    Ld = ((((_e837 * _e836) * _e839) * _e841) / vec3(max(0.000001f, _e843)));
                    let _e847 = throughput;
                    let _e848 = Ld;
                    Lcontrib = (_e847 * _e848);
                    let _e850 = Lcontrib;
                    param_868 = _e850;
                    let _e851 = maxComponent_u0028_vf3_u003b((&param_868));
                    maxLcontrib = _e851;
                    let _e852 = maxLcontrib;
                    let _e854 = unnamed.firefly_clamp;
                    if (_e852 > _e854) {
                        let _e857 = unnamed.firefly_clamp;
                        let _e858 = maxLcontrib;
                        let _e860 = Lcontrib;
                        Lcontrib = (_e860 * (_e857 / _e858));
                    }
                    let _e862 = Lcontrib;
                    let _e863 = L_12;
                    L_12 = (_e863 + _e862);
                }
            }
            let _e865 = NgW;
            let _e866 = dW;
            let _e867 = NgW;
            let _e872 = pW_15;
            pW_15 = (_e872 + ((_e865 * sign(dot(_e866, _e867))) * 0.0001f));
            let _e874 = surface_throughput;
            let _e875 = throughput;
            throughput = (_e875 * _e874);
            let _e877 = throughput;
            param_869 = _e877;
            let _e878 = maxComponent_u0028_vf3_u003b((&param_869));
            maxTP = _e878;
            let _e879 = maxTP;
            let _e881 = unnamed.firefly_clamp;
            if (_e879 > _e881) {
                let _e884 = unnamed.firefly_clamp;
                let _e885 = maxTP;
                let _e887 = throughput;
                throughput = (_e887 * (_e884 / _e885));
            }
            let _e889 = throughput;
            param_870 = _e889;
            let _e890 = maxComponent_u0028_vf3_u003b((&param_870));
            let _e892 = vertex;
            if ((_e890 < 1f) && (_e892 > 1i)) {
                let _e895 = throughput;
                param_871 = _e895;
                let _e896 = maxComponent_u0028_vf3_u003b((&param_871));
                q = max(0f, (1f - _e896));
                let _e899 = rndSeed_11;
                param_872 = _e899;
                let _e900 = rand_u0028_u1_u003b((&param_872));
                let _e901 = param_872;
                rndSeed_11 = _e901;
                let _e902 = q;
                if (_e900 < _e902) {
                    break;
                }
                let _e904 = q;
                let _e906 = throughput;
                throughput = (_e906 / vec3((1f - _e904)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e909 = vertex;
            vertex = (_e909 + 1i);
        }
    }
    let _e911 = L_12;
    mtlxFragmentColor[0u] = _e911.x;
    mtlxFragmentColor[1u] = _e911.y;
    mtlxFragmentColor[2u] = _e911.z;
    let _e919 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e919;
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
