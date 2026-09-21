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
    let _e345 = (*v)[0u];
    let _e347 = (*v)[1u];
    let _e349 = (*v)[2u];
    return min(_e345, min(_e347, _e349));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e345 = (*wiL)[2u];
    if (_e345 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e348 = (*wiL)[2u];
    return (_e348 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_7516_: bool;
    var phi_7534_: bool;

    let _e351 = (*winputL)[2u];
    let _e352 = (_e351 < 0.0000000001f);
    phi_7516_ = _e352;
    if !(_e352) {
        let _e355 = (*woutputL)[2u];
        phi_7516_ = (_e355 < 0.0000000001f);
    }
    let _e358 = phi_7516_;
    if _e358 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e359 = (*woutputL);
    param = _e359;
    let _e360 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e360;
    let _e362 = unnamed.wireframe;
    let _e363 = (_e362 != 0u);
    phi_7534_ = _e363;
    if _e363 {
        let _e365 = (*basis).baryCoord;
        param_1 = _e365;
        let _e366 = minComponent_u0028_vf3_u003b((&param_1));
        phi_7534_ = (_e366 < 0.003f);
    }
    let _e369 = phi_7534_;
    if _e369 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e371 = unnamed.neutral_color;
    return (_e371 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e346 = (*pW_1)[0u];
    let _e348 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e346, -(_e348)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e356 = uv;
    let _e357 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e356, 0.0);
    return _e357.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_7609_: bool;

    let _e351 = (*winputL_1)[2u];
    let _e352 = (_e351 < 0.0000000001f);
    phi_7609_ = _e352;
    if !(_e352) {
        let _e355 = (*woutputL_1)[2u];
        phi_7609_ = (_e355 < 0.0000000001f);
    }
    let _e358 = phi_7609_;
    if _e358 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e359 = (*woutputL_1);
    param_2 = _e359;
    let _e360 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e360;
    let _e361 = (*pW_2);
    param_3 = _e361;
    let _e362 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e362 / vec3(3.1415927f));
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e348 = (*bg);
    let _e349 = (*fg);
    let _e350 = (*mixValue);
    (*result) = mix(_e348, _e349, vec3(_e350));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e348 = (*cosTheta);
    x = clamp((1f - _e348), 0f, 1f);
    let _e351 = (*F0_);
    let _e352 = (*F90_);
    let _e353 = x;
    let _e354 = (*exponent);
    return mix(_e351, _e352, vec3(pow(_e353, _e354)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e346 = (*N);
    let _e347 = (*V);
    if (dot(_e346, _e347) < 0f) {
        let _e350 = (*N);
        local = -(_e350);
    } else {
        let _e352 = (*N);
        local = _e352;
    }
    let _e353 = local;
    return _e353;
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

    let _e359 = (*closureData_1).closureType;
    if (_e359 == 4i) {
        let _e362 = (*closureData_1).N;
        param_4 = _e362;
        let _e364 = (*closureData_1).V;
        param_5 = _e364;
        let _e365 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_4), (&param_5));
        N_1 = _e365;
        let _e366 = N_1;
        let _e368 = (*closureData_1).V;
        NdotV = clamp(dot(_e366, _e368), 0.00000001f, 1f);
        let _e371 = NdotV;
        param_6 = _e371;
        let _e372 = (*color0_);
        param_7 = _e372;
        let _e373 = (*color90_);
        param_8 = _e373;
        let _e374 = (*exponent_1);
        param_9 = _e374;
        let _e375 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_6), (&param_7), (&param_8), (&param_9));
        f = _e375;
        let _e376 = (*base);
        let _e377 = f;
        (*result_1) = (_e376 * _e377);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e347 = (*in1_);
    let _e348 = (*in2_);
    (*result_2) = (_e347 * _e348);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e347 = (*closureData_3).closureType;
    if (_e347 == 4i) {
        let _e349 = (*color);
        (*result_3) = _e349;
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_4: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e348 = (*in2_1);
    tint = clamp(_e348, vec3(0f), vec3(1f));
    let _e353 = (*in1_1).response;
    let _e354 = tint;
    (*result_4).response = (_e353 * _e354);
    let _e358 = (*in1_1).throughput;
    (*result_4).throughput = _e358;
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_5: ptr<function, BSDF>) {
    let _e348 = (*top).response;
    let _e350 = (*base_1).response;
    let _e352 = (*top).throughput;
    (*result_5).response = (_e348 + (_e350 * _e352));
    let _e357 = (*top).throughput;
    let _e359 = (*base_1).throughput;
    (*result_5).throughput = (_e357 * _e359);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e347 = (*dir)[1u];
    latitude = ((-(asin(_e347)) * 0.31830987f) + 0.5f);
    let _e353 = (*dir)[0u];
    let _e355 = (*dir)[2u];
    longitude = (((atan2(_e353, -(_e355)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e361 = longitude;
    let _e362 = latitude;
    return vec2<f32>(_e361, _e362);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e345 = (*m);
    let _e346 = (*v_1);
    return (_e345 * _e346);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_12: vec3<f32>;

    let _e351 = (*dir_1);
    let _e356 = (*transform);
    param_10 = _e356;
    param_11 = vec4<f32>(_e351.x, _e351.y, _e351.z, 0f);
    let _e357 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_10), (&param_11));
    envDir = normalize(_e357.xyz);
    let _e360 = envDir;
    param_12 = _e360;
    let _e361 = mx_latlong_projection_u0028_vf3_u003b((&param_12));
    uv_1 = _e361;
    let _e362 = uv_1;
    let _e363 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e362, 0.0);
    return _e363.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e346 = a;
    c = cos(_e346);
    let _e348 = a;
    s = sin(_e348);
    let _e350 = c;
    let _e351 = s;
    let _e353 = s;
    let _e354 = c;
    return mat4x4<f32>(vec4<f32>(_e350, 0f, -(_e351), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e353, 0f, _e354, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_13: vec3<f32>;
    var param_14: mat4x4<f32>;
    var param_15: f32;

    let _e348 = mtlxEnvMatrix_u0028_();
    let _e349 = (*N_2);
    param_13 = _e349;
    param_14 = _e348;
    param_15 = 0f;
    let _e350 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_13), (&param_14), (&param_15));
    Li = _e350;
    let _e351 = Li;
    let _e353 = unnamed.skyPower;
    return (_e351 * _e353);
}

fn mx_square_u0028_f1_u003b(x_1: ptr<function, f32>) -> f32 {
    let _e344 = (*x_1);
    let _e345 = (*x_1);
    return (_e344 * _e345);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_16: f32;

    let _e347 = (*roughness);
    let _e350 = (*NdotV_1);
    let _e352 = (*roughness);
    let _e355 = (*roughness);
    param_16 = _e355;
    let _e356 = mx_square_u0028_f1_u003b((&param_16));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e347)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e350) * _e352)) + (vec2<f32>(1.4385f, 2.0315f) * _e356));
    let _e360 = r[0u];
    let _e362 = r[1u];
    return (_e360 / _e362);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_17: f32;
    var param_18: f32;

    let _e348 = (*NdotV_2);
    param_17 = _e348;
    let _e349 = (*roughness_1);
    param_18 = _e349;
    let _e350 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_17), (&param_18));
    dirAlbedo = _e350;
    let _e351 = dirAlbedo;
    return clamp(_e351, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e344 = (*x_2);
    let _e345 = (*x_2);
    return (_e344 * _e345);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e345 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e345)));
    let _e349 = A;
    let _e350 = (*roughness_2);
    return (_e349 * (1f + (0.07248821f * _e350)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_19: f32;
    var G: f32;

    let _e350 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e350)));
    let _e354 = (*roughness_3);
    let _e355 = A_1;
    B = (_e354 * _e355);
    let _e357 = (*cosTheta_1);
    param_19 = _e357;
    let _e358 = mx_square_u0028_f1_u003b((&param_19));
    Si = sqrt(max(0f, (1f - _e358)));
    let _e362 = Si;
    let _e363 = (*cosTheta_1);
    let _e366 = Si;
    let _e367 = (*cosTheta_1);
    let _e371 = Si;
    let _e372 = (*cosTheta_1);
    let _e374 = Si;
    let _e375 = Si;
    let _e377 = Si;
    let _e381 = Si;
    G = ((_e362 * (acos(clamp(_e363, -1f, 1f)) - (_e366 * _e367))) + ((2f * (((_e371 / _e372) * (1f - ((_e374 * _e375) * _e377))) - _e381)) / 3f));
    let _e386 = A_1;
    let _e387 = B;
    let _e388 = G;
    return (_e386 + ((_e387 * _e388) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_20: f32;
    var param_21: f32;
    var avgAlbedo: f32;
    var param_22: f32;
    var colorMultiScatter: vec3<f32>;
    var param_23: vec3<f32>;

    let _e353 = (*cosTheta_2);
    param_20 = _e353;
    let _e354 = (*roughness_4);
    param_21 = _e354;
    let _e355 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_20), (&param_21));
    dirAlbedo_1 = _e355;
    let _e356 = (*roughness_4);
    param_22 = _e356;
    let _e357 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_22));
    avgAlbedo = _e357;
    let _e358 = (*color_1);
    param_23 = _e358;
    let _e359 = mx_square_u0028_vf3_u003b((&param_23));
    let _e360 = avgAlbedo;
    let _e362 = (*color_1);
    let _e363 = avgAlbedo;
    colorMultiScatter = ((_e359 * _e360) / (vec3<f32>(1f, 1f, 1f) - (_e362 * max(0f, (1f - _e363)))));
    let _e369 = colorMultiScatter;
    let _e370 = (*color_1);
    let _e371 = dirAlbedo_1;
    return mix(_e369, _e370, vec3(_e371));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_24: f32;
    var A_2: f32;
    var B_1: f32;

    let _e354 = (*LdotV);
    let _e355 = (*NdotL);
    let _e356 = (*NdotV_3);
    s_1 = (_e354 - (_e355 * _e356));
    let _e359 = s_1;
    if (_e359 > 0f) {
        let _e361 = s_1;
        let _e362 = (*NdotL);
        let _e363 = (*NdotV_3);
        local_1 = (_e361 / max(_e362, _e363));
    } else {
        local_1 = 0f;
    }
    let _e366 = local_1;
    stinv = _e366;
    let _e367 = (*roughness_5);
    param_24 = _e367;
    let _e368 = mx_square_u0028_f1_u003b((&param_24));
    sigma2_ = _e368;
    let _e369 = sigma2_;
    let _e370 = sigma2_;
    A_2 = (1f - (0.5f * (_e369 / (_e370 + 0.33f))));
    let _e375 = sigma2_;
    let _e377 = sigma2_;
    B_1 = ((0.45f * _e375) / (_e377 + 0.09f));
    let _e380 = A_2;
    let _e381 = B_1;
    let _e382 = stinv;
    return (_e380 + (_e381 * _e382));
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

    let _e364 = (*LdotV_1);
    let _e365 = (*NdotL_1);
    let _e366 = (*NdotV_4);
    s_2 = (_e364 - (_e365 * _e366));
    let _e369 = s_2;
    if (_e369 > 0f) {
        let _e371 = s_2;
        let _e372 = (*NdotL_1);
        let _e373 = (*NdotV_4);
        local_2 = (_e371 / max(_e372, _e373));
    } else {
        let _e376 = s_2;
        local_2 = _e376;
    }
    let _e377 = local_2;
    stinv_1 = _e377;
    let _e378 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e378)));
    let _e382 = (*color_2);
    let _e383 = A_3;
    let _e385 = (*roughness_6);
    let _e386 = stinv_1;
    lobeSingleScatter = ((_e382 * _e383) * (1f + (_e385 * _e386)));
    let _e390 = (*NdotV_4);
    param_25 = _e390;
    let _e391 = (*roughness_6);
    param_26 = _e391;
    let _e392 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_25), (&param_26));
    dirAlbedoV = _e392;
    let _e393 = (*NdotL_1);
    param_27 = _e393;
    let _e394 = (*roughness_6);
    param_28 = _e394;
    let _e395 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_27), (&param_28));
    dirAlbedoL = _e395;
    let _e396 = (*roughness_6);
    param_29 = _e396;
    let _e397 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_29));
    avgAlbedo_1 = _e397;
    let _e398 = (*color_2);
    param_30 = _e398;
    let _e399 = mx_square_u0028_vf3_u003b((&param_30));
    let _e400 = avgAlbedo_1;
    let _e402 = (*color_2);
    let _e403 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e399 * _e400) / (vec3<f32>(1f, 1f, 1f) - (_e402 * max(0f, (1f - _e403)))));
    let _e409 = colorMultiScatter_1;
    let _e410 = dirAlbedoV;
    let _e414 = dirAlbedoL;
    let _e418 = avgAlbedo_1;
    lobeMultiScatter = (((_e409 * max(0.00000001f, (1f - _e410))) * max(0.00000001f, (1f - _e414))) / vec3(max(0.00000001f, (1f - _e418))));
    let _e423 = lobeSingleScatter;
    let _e424 = lobeMultiScatter;
    return (_e423 + _e424);
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
    let _e378 = (*weight);
    if (_e378 < 0.00000001f) {
        return;
    }
    let _e381 = (*closureData_6).V;
    V_1 = _e381;
    let _e383 = (*closureData_6).L;
    L = _e383;
    let _e384 = (*N_3);
    param_31 = _e384;
    let _e385 = V_1;
    param_32 = _e385;
    let _e386 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_31), (&param_32));
    (*N_3) = _e386;
    let _e387 = (*N_3);
    let _e388 = V_1;
    NdotV_5 = clamp(dot(_e387, _e388), 0.00000001f, 1f);
    let _e392 = (*closureData_6).closureType;
    if (_e392 == 1i) {
        let _e394 = (*N_3);
        let _e395 = L;
        NdotL_2 = clamp(dot(_e394, _e395), 0.00000001f, 1f);
        let _e398 = L;
        let _e399 = V_1;
        LdotV_2 = clamp(dot(_e398, _e399), 0.00000001f, 1f);
        let _e402 = (*energy_compensation);
        if _e402 {
            let _e403 = NdotV_5;
            param_33 = _e403;
            let _e404 = NdotL_2;
            param_34 = _e404;
            let _e405 = LdotV_2;
            param_35 = _e405;
            let _e406 = (*roughness_7);
            param_36 = _e406;
            let _e407 = (*color_3);
            param_37 = _e407;
            let _e408 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_33), (&param_34), (&param_35), (&param_36), (&param_37));
            local_3 = _e408;
        } else {
            let _e409 = NdotV_5;
            param_38 = _e409;
            let _e410 = NdotL_2;
            param_39 = _e410;
            let _e411 = LdotV_2;
            param_40 = _e411;
            let _e412 = (*roughness_7);
            param_41 = _e412;
            let _e413 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_38), (&param_39), (&param_40), (&param_41));
            let _e414 = (*color_3);
            local_3 = (_e414 * _e413);
        }
        let _e416 = local_3;
        diffuse = _e416;
        let _e417 = diffuse;
        let _e419 = (*closureData_6).occlusion;
        let _e421 = (*weight);
        let _e423 = NdotL_2;
        (*bsdf).response = ((((_e417 * _e419) * _e421) * _e423) * 0.31830987f);
    } else {
        let _e428 = (*closureData_6).closureType;
        if (_e428 == 3i) {
            let _e430 = (*energy_compensation);
            if _e430 {
                let _e431 = NdotV_5;
                param_42 = _e431;
                let _e432 = (*roughness_7);
                param_43 = _e432;
                let _e433 = (*color_3);
                param_44 = _e433;
                let _e434 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_42), (&param_43), (&param_44));
                local_4 = _e434;
            } else {
                let _e435 = NdotV_5;
                param_45 = _e435;
                let _e436 = (*roughness_7);
                param_46 = _e436;
                let _e437 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_45), (&param_46));
                let _e438 = (*color_3);
                local_4 = (_e438 * _e437);
            }
            let _e440 = local_4;
            diffuse_1 = _e440;
            let _e441 = (*N_3);
            param_47 = _e441;
            let _e442 = mx_environment_irradiance_u0028_vf3_u003b((&param_47));
            Li_1 = _e442;
            let _e443 = Li_1;
            let _e444 = diffuse_1;
            let _e446 = (*weight);
            (*bsdf).response = ((_e443 * _e444) * _e446);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_6: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e348 = (*in2_2);
    weight_1 = clamp(_e348, 0f, 1f);
    let _e351 = (*in1_2).response;
    let _e352 = weight_1;
    (*result_6).response = (_e351 * _e352);
    let _e356 = (*in1_2).throughput;
    (*result_6).throughput = _e356;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_7: ptr<function, BSDF>) {
    let _e348 = (*in1_3).response;
    let _e350 = (*in2_3).response;
    (*result_7).response = (_e348 + _e350);
    let _e354 = (*in1_3).throughput;
    let _e356 = (*in2_3).throughput;
    (*result_7).throughput = max(((_e354 + _e356) - vec3(1f)), vec3(0f));
    return;
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e348 = (*shape);
    let _e350 = (*dist);
    num1_ = exp((-(_e348) * _e350));
    let _e353 = (*shape);
    let _e355 = (*dist);
    num2_ = exp(((-(_e353) * _e355) / vec3(3f)));
    let _e360 = (*dist);
    denom = max(_e360, 0.00000001f);
    let _e362 = num1_;
    let _e363 = num2_;
    let _e365 = denom;
    return ((_e362 + _e363) / vec3(_e365));
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

    let _e357 = (*N_4);
    let _e358 = (*L_1);
    theta = acos(dot(_e357, _e358));
    let _e361 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e361, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e365 = i;
        if (_e365 < 32i) {
            let _e367 = i;
            x_3 = (-3.1415927f + ((f32(_e367) + 0.5f) * 0.19634955f));
            let _e372 = (*radius);
            let _e373 = x_3;
            dist_1 = (_e372 * abs((2f * sin((_e373 * 0.5f)))));
            let _e379 = dist_1;
            param_48 = _e379;
            let _e380 = shape_1;
            param_49 = _e380;
            let _e381 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_48), (&param_49));
            R = _e381;
            let _e382 = R;
            let _e383 = theta;
            let _e384 = x_3;
            let _e389 = sumD;
            sumD = (_e389 + (_e382 * max(cos((_e383 + _e384)), 0f)));
            let _e391 = R;
            let _e392 = sumR;
            sumR = (_e392 + _e391);
            continue;
        } else {
            break;
        }
        continuing {
            let _e394 = i;
            i = (_e394 + 1i);
        }
    }
    let _e396 = sumD;
    let _e397 = sumR;
    return (_e396 / _e397);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, L_2: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_50: vec3<f32>;
    var param_51: vec3<f32>;
    var param_52: f32;
    var param_53: vec3<f32>;

    let _e354 = (*N_5);
    let _e355 = fwidth(_e354);
    let _e357 = (*P);
    let _e358 = fwidth(_e357);
    curvature = (length(_e355) / length(_e358));
    let _e361 = curvature;
    radius_1 = (1f / max(_e361, 0.01f));
    let _e364 = (*albedo);
    let _e365 = (*N_5);
    param_50 = _e365;
    let _e366 = (*L_2);
    param_51 = _e366;
    let _e367 = radius_1;
    param_52 = _e367;
    let _e368 = (*mfp_1);
    param_53 = _e368;
    let _e369 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_50), (&param_51), (&param_52), (&param_53));
    return ((_e364 * _e369) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
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
    let _e367 = (*weight_2);
    if (_e367 < 0.00000001f) {
        return;
    }
    let _e370 = (*closureData_9).V;
    V_2 = _e370;
    let _e372 = (*closureData_9).L;
    L_3 = _e372;
    let _e374 = (*closureData_9).P;
    P_1 = _e374;
    let _e376 = (*closureData_9).occlusion;
    occlusion = _e376;
    let _e377 = (*N_6);
    param_54 = _e377;
    let _e378 = V_2;
    param_55 = _e378;
    let _e379 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_54), (&param_55));
    (*N_6) = _e379;
    let _e381 = (*closureData_9).closureType;
    if (_e381 == 1i) {
        let _e383 = (*N_6);
        param_56 = _e383;
        let _e384 = L_3;
        param_57 = _e384;
        let _e385 = P_1;
        param_58 = _e385;
        let _e386 = (*color_4);
        param_59 = _e386;
        let _e387 = (*radius_2);
        param_60 = _e387;
        let _e388 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_56), (&param_57), (&param_58), (&param_59), (&param_60));
        sss = _e388;
        let _e389 = (*N_6);
        let _e390 = L_3;
        NdotL_3 = clamp(dot(_e389, _e390), 0.00000001f, 1f);
        let _e393 = NdotL_3;
        let _e394 = occlusion;
        visibleOcclusion = (1f - (_e393 * (1f - _e394)));
        let _e398 = sss;
        let _e399 = visibleOcclusion;
        let _e401 = (*weight_2);
        (*bsdf_1).response = ((_e398 * _e399) * _e401);
    } else {
        let _e405 = (*closureData_9).closureType;
        if (_e405 == 3i) {
            let _e407 = (*N_6);
            param_61 = _e407;
            let _e408 = mx_environment_irradiance_u0028_vf3_u003b((&param_61));
            Li_2 = _e408;
            let _e409 = Li_2;
            let _e410 = (*color_4);
            let _e412 = (*weight_2);
            (*bsdf_1).response = ((_e409 * _e410) * _e412);
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
    let _e354 = (*weight_3);
    if (_e354 < 0.00000001f) {
        return;
    }
    let _e357 = (*closureData_10).V;
    V_3 = _e357;
    let _e359 = (*closureData_10).L;
    L_4 = _e359;
    let _e360 = (*N_7);
    (*N_7) = -(_e360);
    let _e363 = (*closureData_10).closureType;
    if (_e363 == 1i) {
        let _e365 = (*N_7);
        let _e366 = L_4;
        NdotL_4 = clamp(dot(_e365, _e366), 0f, 1f);
        let _e369 = (*color_5);
        let _e370 = (*weight_3);
        let _e372 = NdotL_4;
        (*bsdf_2).response = (((_e369 * _e370) * _e372) * 0.31830987f);
    } else {
        let _e377 = (*closureData_10).closureType;
        if (_e377 == 3i) {
            let _e379 = (*N_7);
            param_62 = _e379;
            let _e380 = mx_environment_irradiance_u0028_vf3_u003b((&param_62));
            Li_3 = _e380;
            let _e381 = Li_3;
            let _e382 = (*color_5);
            let _e384 = (*weight_3);
            (*bsdf_2).response = ((_e381 * _e382) * _e384);
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_4: ptr<function, f32>, y: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_1: f32;
    var o: f32;
    var param_63: f32;

    let _e349 = (*y);
    let _e350 = (*y);
    let _e354 = (*y);
    let _e355 = (*y);
    s_3 = ((_e349 * (0.0206607f + (1.58491f * _e350))) / (0.0379424f + (_e354 * (1.32227f + _e355))));
    let _e360 = (*y);
    let _e361 = (*y);
    let _e362 = (*y);
    let _e363 = (*y);
    let _e365 = (*y);
    let _e373 = (*y);
    m_1 = ((_e360 * (-0.193854f + (_e361 * (-1.14885f + (_e362 * (1.7932f - ((0.95943f * _e363) * _e365))))))) / (0.046391f + _e373));
    let _e376 = (*y);
    let _e377 = (*y);
    let _e380 = (*y);
    let _e384 = (*y);
    let _e385 = (*y);
    o = ((_e376 * (0.000654023f + ((-0.0207818f + (0.119681f * _e377)) * _e380))) / (1.26264f + (_e384 * (-1.92021f + _e385))));
    let _e390 = (*x_4);
    let _e391 = m_1;
    let _e393 = s_3;
    param_63 = ((_e390 - _e391) / _e393);
    let _e395 = mx_square_u0028_f1_u003b((&param_63));
    let _e398 = s_3;
    let _e401 = o;
    return ((exp((-0.5f * _e395)) / (_e398 * 2.5066283f)) + _e401);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_3: ptr<function, f32>) -> f32 {
    let _e344 = (*cosTheta_3);
    return (max(_e344, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_5: ptr<function, f32>, y_1: ptr<function, f32>) -> f32 {
    let _e345 = (*x_5);
    let _e348 = (*y_1);
    let _e351 = (*y_1);
    let _e353 = (*y_1);
    let _e355 = (*y_1);
    let _e357 = (*x_5);
    let _e360 = (*x_5);
    let _e362 = (*y_1);
    let _e365 = (*y_1);
    let _e367 = (*y_1);
    return (((((sqrt((1f - _e345)) * (_e348 - 1f)) * _e351) * _e353) * _e355) / (((0.0000254053f + (1.71228f * _e357)) - ((1.71506f * _e360) * _e362)) + ((1.34174f * _e365) * _e367)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    let _e345 = (*x_6);
    let _e347 = (*y_2);
    let _e350 = (*y_2);
    let _e352 = (*x_6);
    let _e354 = (*x_6);
    let _e357 = (*x_6);
    let _e359 = (*y_2);
    return ((((2.58126f * _e345) + (0.813703f * _e347)) * _e350) / ((1f + ((0.310327f * _e352) * _e354)) + ((2.60994f * _e357) * _e359)));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_2: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e345 = (*m_2);
    let _e346 = (*v_2);
    return (_e345 * _e346);
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_8: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_1: f32;
    var b: f32;
    var X: vec3<f32>;
    var Y: vec3<f32>;

    let _e350 = (*N_8)[2u];
    sign_ = select(1f, -1f, (_e350 < 0f));
    let _e353 = sign_;
    let _e355 = (*N_8)[2u];
    a_1 = (-1f / (_e353 + _e355));
    let _e359 = (*N_8)[0u];
    let _e361 = (*N_8)[1u];
    let _e363 = a_1;
    b = ((_e359 * _e361) * _e363);
    let _e365 = sign_;
    let _e367 = (*N_8)[0u];
    let _e370 = (*N_8)[0u];
    let _e372 = a_1;
    let _e375 = sign_;
    let _e376 = b;
    let _e378 = sign_;
    let _e381 = (*N_8)[0u];
    X = vec3<f32>((1f + (((_e365 * _e367) * _e370) * _e372)), (_e375 * _e376), (-(_e378) * _e381));
    let _e384 = b;
    let _e385 = sign_;
    let _e387 = (*N_8)[1u];
    let _e389 = (*N_8)[1u];
    let _e391 = a_1;
    let _e395 = (*N_8)[1u];
    Y = vec3<f32>(_e384, (_e385 + ((_e387 * _e389) * _e391)), -(_e395));
    let _e398 = X;
    let _e399 = Y;
    let _e400 = (*N_8);
    return mat3x3<f32>(vec3<f32>(_e398.x, _e398.y, _e398.z), vec3<f32>(_e399.x, _e399.y, _e399.z), vec3<f32>(_e400.x, _e400.y, _e400.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_4: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_6: ptr<function, f32>) -> mat3x3<f32> {
    var X_1: vec3<f32>;
    var lenSqr: f32;
    var Y_1: vec3<f32>;
    var param_64: vec3<f32>;

    let _e350 = (*V_4);
    let _e351 = (*N_9);
    let _e352 = (*NdotV_6);
    X_1 = (_e350 - (_e351 * _e352));
    let _e355 = X_1;
    let _e356 = X_1;
    lenSqr = dot(_e355, _e356);
    let _e358 = lenSqr;
    if (_e358 > 0f) {
        let _e360 = lenSqr;
        let _e362 = X_1;
        X_1 = (_e362 * inverseSqrt(_e360));
        let _e364 = (*N_9);
        let _e365 = X_1;
        Y_1 = cross(_e364, _e365);
        let _e367 = X_1;
        let _e368 = Y_1;
        let _e369 = (*N_9);
        return mat3x3<f32>(vec3<f32>(_e367.x, _e367.y, _e367.z), vec3<f32>(_e368.x, _e368.y, _e368.z), vec3<f32>(_e369.x, _e369.y, _e369.z));
    }
    let _e383 = (*N_9);
    param_64 = _e383;
    let _e384 = mx_orthonormal_basis_u0028_vf3_u003b((&param_64));
    return _e384;
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

    let _e365 = (*V_5);
    param_65 = _e365;
    let _e366 = (*N_10);
    param_66 = _e366;
    let _e367 = (*NdotV_7);
    param_67 = _e367;
    let _e368 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_65), (&param_66), (&param_67));
    toLTC = transpose(_e368);
    let _e370 = toLTC;
    param_68 = _e370;
    let _e371 = (*L_5);
    param_69 = _e371;
    let _e372 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_68), (&param_69));
    w = _e372;
    let _e373 = (*NdotV_7);
    param_70 = _e373;
    let _e374 = (*roughness_8);
    param_71 = _e374;
    let _e375 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_70), (&param_71));
    aInv = _e375;
    let _e376 = (*NdotV_7);
    param_72 = _e376;
    let _e377 = (*roughness_8);
    param_73 = _e377;
    let _e378 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_72), (&param_73));
    bInv = _e378;
    let _e379 = aInv;
    let _e381 = w[0u];
    let _e383 = bInv;
    let _e385 = w[2u];
    let _e388 = aInv;
    let _e390 = w[1u];
    let _e393 = w[2u];
    wo = vec3<f32>(((_e379 * _e381) + (_e383 * _e385)), (_e388 * _e390), _e393);
    let _e395 = wo;
    let _e396 = wo;
    lenSqr_1 = dot(_e395, _e396);
    let _e399 = wo[2u];
    param_74 = _e399;
    let _e400 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_74));
    let _e401 = aInv;
    let _e402 = lenSqr_1;
    param_75 = (_e401 / _e402);
    let _e404 = mx_square_u0028_f1_u003b((&param_75));
    return (_e400 * _e404);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_8: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var r_1: vec2<f32>;
    var param_76: f32;
    var param_77: f32;

    let _e348 = (*NdotV_8);
    let _e351 = (*roughness_9);
    let _e354 = (*NdotV_8);
    let _e356 = (*roughness_9);
    let _e359 = (*NdotV_8);
    param_76 = _e359;
    let _e360 = mx_square_u0028_f1_u003b((&param_76));
    let _e363 = (*roughness_9);
    param_77 = _e363;
    let _e364 = mx_square_u0028_f1_u003b((&param_77));
    r_1 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e348)) + (vec2<f32>(799.08826f, 442.7821f) * _e351)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e354) * _e356)) + (vec2<f32>(60.28956f, 121.81241f) * _e360)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e364));
    let _e368 = r_1[0u];
    let _e370 = r_1[1u];
    return (_e368 / _e370);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_9: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var dirAlbedo_2: f32;
    var param_78: f32;
    var param_79: f32;

    let _e348 = (*NdotV_9);
    param_78 = _e348;
    let _e349 = (*roughness_10);
    param_79 = _e349;
    let _e350 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_78), (&param_79));
    dirAlbedo_2 = _e350;
    let _e351 = dirAlbedo_2;
    return clamp(_e351, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e348 = (*roughness_11);
    invRoughness = (1f / max(_e348, 0.005f));
    let _e351 = (*NdotH);
    let _e352 = (*NdotH);
    cos2_ = (_e351 * _e352);
    let _e354 = cos2_;
    sin2_ = (1f - _e354);
    let _e356 = invRoughness;
    let _e358 = sin2_;
    let _e359 = invRoughness;
    return (((2f + _e356) * pow(_e358, (_e359 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_10: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var D: f32;
    var param_80: f32;
    var param_81: f32;
    var F: f32;
    var G_1: f32;

    let _e352 = (*NdotH_1);
    param_80 = _e352;
    let _e353 = (*roughness_12);
    param_81 = _e353;
    let _e354 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_80), (&param_81));
    D = _e354;
    F = 1f;
    G_1 = 1f;
    let _e355 = D;
    let _e356 = F;
    let _e358 = G_1;
    let _e360 = (*NdotL_5);
    let _e361 = (*NdotV_10);
    let _e363 = (*NdotL_5);
    let _e364 = (*NdotV_10);
    return (((_e355 * _e356) * _e358) / (4f * ((_e360 + _e361) - (_e363 * _e364))));
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

    let _e381 = (*weight_4);
    if (_e381 < 0.00000001f) {
        return;
    }
    let _e384 = (*closureData_11).V;
    V_6 = _e384;
    let _e386 = (*closureData_11).L;
    L_6 = _e386;
    let _e387 = (*N_11);
    param_82 = _e387;
    let _e388 = V_6;
    param_83 = _e388;
    let _e389 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_82), (&param_83));
    (*N_11) = _e389;
    let _e390 = (*N_11);
    let _e391 = V_6;
    NdotV_11 = clamp(dot(_e390, _e391), 0.00000001f, 1f);
    let _e395 = (*closureData_11).closureType;
    if (_e395 == 1i) {
        let _e397 = (*mode);
        if (_e397 == 0i) {
            let _e399 = L_6;
            let _e400 = V_6;
            H = normalize((_e399 + _e400));
            let _e403 = (*N_11);
            let _e404 = L_6;
            NdotL_6 = clamp(dot(_e403, _e404), 0.00000001f, 1f);
            let _e407 = (*N_11);
            let _e408 = H;
            NdotH_2 = clamp(dot(_e407, _e408), 0.00000001f, 1f);
            let _e411 = (*color_6);
            let _e412 = NdotL_6;
            param_84 = _e412;
            let _e413 = NdotV_11;
            param_85 = _e413;
            let _e414 = NdotH_2;
            param_86 = _e414;
            let _e415 = (*roughness_13);
            param_87 = _e415;
            let _e416 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_84), (&param_85), (&param_86), (&param_87));
            fr = (_e411 * _e416);
            let _e418 = NdotV_11;
            param_88 = _e418;
            let _e419 = (*roughness_13);
            param_89 = _e419;
            let _e420 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_88), (&param_89));
            dirAlbedo_3 = _e420;
            let _e421 = fr;
            let _e422 = NdotL_6;
            let _e425 = (*closureData_11).occlusion;
            let _e427 = (*weight_4);
            (*bsdf_3).response = (((_e421 * _e422) * _e425) * _e427);
        } else {
            let _e430 = (*roughness_13);
            (*roughness_13) = clamp(_e430, 0.01f, 1f);
            let _e432 = (*color_6);
            let _e433 = L_6;
            param_90 = _e433;
            let _e434 = V_6;
            param_91 = _e434;
            let _e435 = (*N_11);
            param_92 = _e435;
            let _e436 = NdotV_11;
            param_93 = _e436;
            let _e437 = (*roughness_13);
            param_94 = _e437;
            let _e438 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_90), (&param_91), (&param_92), (&param_93), (&param_94));
            fr_1 = (_e432 * _e438);
            let _e440 = NdotV_11;
            param_95 = _e440;
            let _e441 = (*roughness_13);
            param_96 = _e441;
            let _e442 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_95), (&param_96));
            dirAlbedo_3 = _e442;
            let _e443 = dirAlbedo_3;
            let _e444 = fr_1;
            let _e447 = (*closureData_11).occlusion;
            let _e449 = (*weight_4);
            (*bsdf_3).response = (((_e444 * _e443) * _e447) * _e449);
        }
        let _e452 = dirAlbedo_3;
        let _e453 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e452 * _e453)));
    } else {
        let _e459 = (*closureData_11).closureType;
        if (_e459 == 3i) {
            let _e461 = (*mode);
            if (_e461 == 0i) {
                let _e463 = NdotV_11;
                param_97 = _e463;
                let _e464 = (*roughness_13);
                param_98 = _e464;
                let _e465 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_97), (&param_98));
                dirAlbedo_4 = _e465;
            } else {
                let _e466 = (*roughness_13);
                (*roughness_13) = clamp(_e466, 0.01f, 1f);
                let _e468 = NdotV_11;
                param_99 = _e468;
                let _e469 = (*roughness_13);
                param_100 = _e469;
                let _e470 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_99), (&param_100));
                dirAlbedo_4 = _e470;
            }
            let _e471 = (*N_11);
            param_101 = _e471;
            let _e472 = mx_environment_irradiance_u0028_vf3_u003b((&param_101));
            Li_4 = _e472;
            let _e473 = Li_4;
            let _e474 = (*color_6);
            let _e476 = dirAlbedo_4;
            let _e478 = (*weight_4);
            (*bsdf_3).response = (((_e473 * _e474) * _e476) * _e478);
            let _e481 = dirAlbedo_4;
            let _e482 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e481 * _e482)));
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

    let _e352 = (*alpha);
    param_102 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_102));
    alpha2_ = _e353;
    let _e354 = alpha2_;
    let _e355 = alpha2_;
    let _e357 = (*NdotL_7);
    param_103 = _e357;
    let _e358 = mx_square_u0028_f1_u003b((&param_103));
    lambdaL = sqrt((_e354 + ((1f - _e355) * _e358)));
    let _e362 = alpha2_;
    let _e363 = alpha2_;
    let _e365 = (*NdotV_12);
    param_104 = _e365;
    let _e366 = mx_square_u0028_f1_u003b((&param_104));
    lambdaV = sqrt((_e362 + ((1f - _e363) * _e366)));
    let _e370 = (*NdotL_7);
    let _e372 = (*NdotV_12);
    let _e374 = lambdaL;
    let _e375 = (*NdotV_12);
    let _e377 = lambdaV;
    let _e378 = (*NdotL_7);
    return (((2f * _e370) * _e372) / ((_e374 * _e375) + (_e377 * _e378)));
}

fn mx_pow6_u0028_f1_u003b(x_7: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_105: f32;
    var param_106: f32;

    let _e347 = (*x_7);
    param_105 = _e347;
    let _e348 = mx_square_u0028_f1_u003b((&param_105));
    x2_ = _e348;
    let _e349 = x2_;
    param_106 = _e349;
    let _e350 = mx_square_u0028_f1_u003b((&param_106));
    let _e351 = x2_;
    return (_e350 * _e351);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_4: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_8: f32;
    var a_2: vec3<f32>;
    var param_107: f32;

    let _e348 = (*cosTheta_4);
    x_8 = clamp(_e348, 0f, 1f);
    let _e351 = (*fd).F0_;
    let _e353 = (*fd).F90_;
    let _e355 = (*fd).exponent;
    let _e360 = (*fd).F82_;
    a_2 = ((mix(_e351, _e353, vec3(pow(0.85714287f, _e355))) * (vec3<f32>(1f, 1f, 1f) - _e360)) * 17.651384f);
    let _e365 = (*fd).F0_;
    let _e367 = (*fd).F90_;
    let _e368 = x_8;
    let _e371 = (*fd).exponent;
    let _e375 = a_2;
    let _e376 = x_8;
    let _e378 = x_8;
    param_107 = (1f - _e378);
    let _e380 = mx_pow6_u0028_f1_u003b((&param_107));
    return (mix(_e365, _e367, vec3(pow((1f - _e368), _e371))) - ((_e375 * _e376) * _e380));
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

    let _e360 = (*cosTheta_5);
    param_108 = clamp(_e360, 0f, 1f);
    let _e362 = mx_square_u0028_f1_u003b((&param_108));
    cosTheta2_ = _e362;
    let _e363 = cosTheta2_;
    sinTheta2_ = (1f - _e363);
    let _e365 = (*n);
    let _e366 = (*n);
    n2_ = (_e365 * _e366);
    let _e368 = (*k);
    let _e369 = (*k);
    k2_ = (_e368 * _e369);
    let _e371 = n2_;
    let _e372 = k2_;
    let _e374 = sinTheta2_;
    t0_ = ((_e371 - _e372) - vec3(_e374));
    let _e377 = t0_;
    let _e378 = t0_;
    let _e380 = n2_;
    let _e382 = k2_;
    a2plusb2_ = sqrt(((_e377 * _e378) + ((_e380 * 4f) * _e382)));
    let _e386 = a2plusb2_;
    let _e387 = cosTheta2_;
    t1_ = (_e386 + vec3(_e387));
    let _e390 = a2plusb2_;
    let _e391 = t0_;
    a_3 = sqrt(max(((_e390 + _e391) * 0.5f), vec3(0f)));
    let _e397 = a_3;
    let _e399 = (*cosTheta_5);
    t2_ = ((_e397 * 2f) * _e399);
    let _e401 = t1_;
    let _e402 = t2_;
    let _e404 = t1_;
    let _e405 = t2_;
    (*Rs) = ((_e401 - _e402) / (_e404 + _e405));
    let _e408 = cosTheta2_;
    let _e409 = a2plusb2_;
    let _e411 = sinTheta2_;
    let _e412 = sinTheta2_;
    t3_ = ((_e409 * _e408) + vec3((_e411 * _e412)));
    let _e416 = t2_;
    let _e417 = sinTheta2_;
    t4_ = (_e416 * _e417);
    let _e419 = (*Rs);
    let _e420 = t3_;
    let _e421 = t4_;
    let _e424 = t3_;
    let _e425 = t4_;
    (*Rp) = ((_e419 * (_e420 - _e421)) / (_e424 + _e425));
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

    let _e353 = (*cosTheta_6);
    param_109 = _e353;
    let _e354 = (*n_1);
    param_110 = _e354;
    let _e355 = (*k_1);
    param_111 = _e355;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_109), (&param_110), (&param_111), (&param_112), (&param_113));
    let _e356 = param_112;
    Rp_1 = _e356;
    let _e357 = param_113;
    Rs_1 = _e357;
    let _e358 = Rp_1;
    let _e359 = Rs_1;
    return ((_e358 + _e359) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_114: f32;
    var param_115: f32;

    let _e350 = (*cosTheta_7);
    c_1 = _e350;
    let _e351 = (*ior);
    let _e352 = (*ior);
    let _e354 = c_1;
    let _e355 = c_1;
    g2_ = (((_e351 * _e352) + (_e354 * _e355)) - 1f);
    let _e359 = g2_;
    if (_e359 < 0f) {
        return 1f;
    }
    let _e361 = g2_;
    g = sqrt(_e361);
    let _e363 = g;
    let _e364 = c_1;
    let _e366 = g;
    let _e367 = c_1;
    param_114 = ((_e363 - _e364) / (_e366 + _e367));
    let _e370 = mx_square_u0028_f1_u003b((&param_114));
    let _e372 = g;
    let _e373 = c_1;
    let _e375 = c_1;
    let _e378 = g;
    let _e379 = c_1;
    let _e381 = c_1;
    param_115 = ((((_e372 + _e373) * _e375) - 1f) / (((_e378 - _e379) * _e381) + 1f));
    let _e385 = mx_square_u0028_f1_u003b((&param_115));
    return ((0.5f * _e370) * (1f + _e385));
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e350 = (*opd);
    phase = (6.2831855f * _e350);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e352 = val;
    let _e353 = var_;
    let _e357 = pos;
    let _e358 = phase;
    let _e360 = (*shift);
    let _e364 = var_;
    let _e366 = phase;
    let _e368 = phase;
    xyz = (((_e352 * sqrt((_e353 * 6.2831855f))) * cos(((_e357 * _e358) + _e360))) * exp(((-(_e364) * _e366) * _e368)));
    let _e372 = phase;
    let _e375 = (*shift)[0u];
    let _e379 = phase;
    let _e381 = phase;
    let _e386 = xyz[0u];
    xyz[0u] = (_e386 + ((0.00000001644083f * cos(((2239900f * _e372) + _e375))) * exp(((-4528200000f * _e379) * _e381))));
    let _e389 = xyz;
    return (_e389 / vec3(0.00000010685f));
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

    let _e358 = (*kappa2_);
    let _e359 = (*eta2_);
    k2_1 = (_e358 / _e359);
    let _e361 = (*cosTheta_8);
    let _e362 = (*cosTheta_8);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e361 * _e362)));
    let _e366 = (*eta2_);
    let _e367 = (*eta2_);
    let _e369 = k2_1;
    let _e370 = k2_1;
    let _e374 = (*eta1_);
    let _e375 = (*eta1_);
    let _e377 = sinThetaSqr;
    A_4 = (((_e366 * _e367) * (vec3<f32>(1f, 1f, 1f) - (_e369 * _e370))) - (_e377 * (_e374 * _e375)));
    let _e380 = A_4;
    let _e381 = A_4;
    let _e383 = (*eta2_);
    let _e385 = (*eta2_);
    let _e387 = k2_1;
    param_116 = (((_e383 * 2f) * _e385) * _e387);
    let _e389 = mx_square_u0028_vf3_u003b((&param_116));
    B_2 = sqrt(((_e380 * _e381) + _e389));
    let _e392 = A_4;
    let _e393 = B_2;
    U = sqrt(((_e392 + _e393) / vec3(2f)));
    let _e398 = B_2;
    let _e399 = A_4;
    V_7 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e398 - _e399) / vec3(2f))));
    let _e405 = (*eta1_);
    let _e407 = V_7;
    let _e409 = (*cosTheta_8);
    let _e411 = U;
    let _e412 = U;
    let _e414 = V_7;
    let _e415 = V_7;
    let _e418 = (*eta1_);
    let _e419 = (*cosTheta_8);
    param_117 = (_e418 * _e419);
    let _e421 = mx_square_u0028_f1_u003b((&param_117));
    (*phiS) = atan2(((_e407 * (2f * _e405)) * _e409), (((_e411 * _e412) + (_e414 * _e415)) - vec3(_e421)));
    let _e425 = (*eta1_);
    let _e427 = (*eta2_);
    let _e429 = (*eta2_);
    let _e431 = (*cosTheta_8);
    let _e433 = k2_1;
    let _e435 = U;
    let _e437 = k2_1;
    let _e438 = k2_1;
    let _e441 = V_7;
    let _e445 = (*eta2_);
    let _e446 = (*eta2_);
    let _e448 = k2_1;
    let _e449 = k2_1;
    let _e453 = (*cosTheta_8);
    param_118 = (((_e445 * _e446) * (vec3<f32>(1f, 1f, 1f) + (_e448 * _e449))) * _e453);
    let _e455 = mx_square_u0028_vf3_u003b((&param_118));
    let _e456 = (*eta1_);
    let _e457 = (*eta1_);
    let _e459 = U;
    let _e460 = U;
    let _e462 = V_7;
    let _e463 = V_7;
    (*phiP) = atan2(((((_e427 * (2f * _e425)) * _e429) * _e431) * (((_e433 * 2f) * _e435) - ((vec3<f32>(1f, 1f, 1f) - (_e437 * _e438)) * _e441))), (_e455 - (((_e459 * _e460) + (_e462 * _e463)) * (_e456 * _e457))));
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

    let _e355 = (*cosTheta_9);
    param_119 = clamp(_e355, 0f, 1f);
    let _e357 = mx_square_u0028_f1_u003b((&param_119));
    cosTheta2_1 = _e357;
    let _e358 = cosTheta2_1;
    sinTheta2_1 = (1f - _e358);
    let _e360 = (*ior_1);
    let _e361 = (*ior_1);
    let _e363 = sinTheta2_1;
    t0_1 = max(((_e360 * _e361) - _e363), 0f);
    let _e366 = t0_1;
    let _e367 = cosTheta2_1;
    t1_1 = (_e366 + _e367);
    let _e369 = t0_1;
    let _e372 = (*cosTheta_9);
    t2_1 = ((2f * sqrt(_e369)) * _e372);
    let _e374 = t1_1;
    let _e375 = t2_1;
    let _e377 = t1_1;
    let _e378 = t2_1;
    Rs_2 = ((_e374 - _e375) / (_e377 + _e378));
    let _e381 = cosTheta2_1;
    let _e382 = t0_1;
    let _e384 = sinTheta2_1;
    let _e385 = sinTheta2_1;
    t3_1 = ((_e381 * _e382) + (_e384 * _e385));
    let _e388 = t2_1;
    let _e389 = sinTheta2_1;
    t4_1 = (_e388 * _e389);
    let _e391 = Rs_2;
    let _e392 = t3_1;
    let _e393 = t4_1;
    let _e396 = t3_1;
    let _e397 = t4_1;
    Rp_2 = ((_e391 * (_e392 - _e393)) / (_e396 + _e397));
    let _e400 = Rp_2;
    let _e401 = Rs_2;
    return vec2<f32>(_e400, _e401);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e345 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e345, vec3(0.01f), vec3(0.99f)));
    let _e350 = sqrtF0_;
    let _e352 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e350) / (vec3<f32>(1f, 1f, 1f) - _e352));
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
    let _e399 = (*fd_1).tf_ior;
    let _e400 = eta1_1;
    eta2_1 = max(_e399, _e400);
    let _e403 = (*fd_1).model;
    if (_e403 == 2i) {
        let _e406 = (*fd_1).F0_;
        param_120 = _e406;
        let _e407 = mx_f0_to_ior_u0028_vf3_u003b((&param_120));
        local_5 = _e407;
    } else {
        let _e409 = (*fd_1).ior;
        local_5 = _e409;
    }
    let _e410 = local_5;
    eta3_ = _e410;
    let _e412 = (*fd_1).model;
    if (_e412 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e415 = (*fd_1).extinction;
        local_6 = _e415;
    }
    let _e416 = local_6;
    kappa3_ = _e416;
    let _e417 = (*cosTheta_10);
    param_121 = _e417;
    let _e418 = mx_square_u0028_f1_u003b((&param_121));
    let _e420 = eta1_1;
    let _e421 = eta2_1;
    param_122 = (_e420 / _e421);
    let _e423 = mx_square_u0028_f1_u003b((&param_122));
    cosThetaT = sqrt((1f - ((1f - _e418) * _e423)));
    let _e427 = eta2_1;
    let _e428 = eta1_1;
    let _e430 = (*cosTheta_10);
    param_123 = _e430;
    param_124 = (_e427 / _e428);
    let _e431 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_123), (&param_124));
    R12_ = _e431;
    let _e432 = cosThetaT;
    if (_e432 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e434 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e434);
    let _e437 = (*fd_1).model;
    if (_e437 == 2i) {
        let _e439 = cosThetaT;
        param_125 = _e439;
        let _e440 = (*fd_1);
        param_126 = _e440;
        let _e441 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_125), (&param_126));
        f_1 = _e441;
        let _e442 = f_1;
        R23p = (_e442 * 0.5f);
        let _e444 = f_1;
        R23s = (_e444 * 0.5f);
    } else {
        let _e446 = eta3_;
        let _e447 = eta2_1;
        let _e450 = kappa3_;
        let _e451 = eta2_1;
        let _e454 = cosThetaT;
        param_127 = _e454;
        param_128 = (_e446 / vec3(_e447));
        param_129 = (_e450 / vec3(_e451));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_127), (&param_128), (&param_129), (&param_130), (&param_131));
        let _e455 = param_130;
        R23p = _e455;
        let _e456 = param_131;
        R23s = _e456;
    }
    let _e457 = eta2_1;
    let _e458 = eta1_1;
    cosB = cos(atan((_e457 / _e458)));
    let _e462 = (*cosTheta_10);
    let _e463 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e462 < _e463)), 3.1415927f);
    let _e468 = (*fd_1).model;
    if (_e468 == 2i) {
        let _e471 = eta3_[0u];
        let _e472 = eta2_1;
        let _e476 = eta3_[1u];
        let _e477 = eta2_1;
        let _e481 = eta3_[2u];
        let _e482 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e471 < _e472)), select(0f, 3.1415927f, (_e476 < _e477)), select(0f, 3.1415927f, (_e481 < _e482)));
        let _e486 = phi23p;
        phi23s = _e486;
    } else {
        let _e487 = cosThetaT;
        param_132 = _e487;
        let _e488 = eta2_1;
        param_133 = _e488;
        let _e489 = eta3_;
        param_134 = _e489;
        let _e490 = kappa3_;
        param_135 = _e490;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_132), (&param_133), (&param_134), (&param_135), (&param_136), (&param_137));
        let _e491 = param_136;
        phi23p = _e491;
        let _e492 = param_137;
        phi23s = _e492;
    }
    let _e494 = R12_[0u];
    let _e495 = R23p;
    r123p = max(sqrt((_e495 * _e494)), vec3(0f));
    let _e501 = R12_[1u];
    let _e502 = R23s;
    r123s = max(sqrt((_e502 * _e501)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e508 = (*fd_1).tf_thickness;
    distMeters = (_e508 * 0.000000001f);
    let _e510 = eta2_1;
    let _e512 = cosThetaT;
    let _e514 = distMeters;
    opd_1 = (((2f * _e510) * _e512) * _e514);
    let _e517 = T121_[0u];
    param_138 = _e517;
    let _e518 = mx_square_u0028_f1_u003b((&param_138));
    let _e519 = R23p;
    let _e522 = R12_[0u];
    let _e523 = R23p;
    Rs_3 = ((_e519 * _e518) / (vec3<f32>(1f, 1f, 1f) - (_e523 * _e522)));
    let _e528 = R12_[0u];
    let _e529 = Rs_3;
    let _e532 = I;
    I = (_e532 + (vec3(_e528) + _e529));
    let _e534 = Rs_3;
    let _e536 = T121_[0u];
    Cm = (_e534 - vec3(_e536));
    m_3 = 1i;
    loop {
        let _e539 = m_3;
        if (_e539 <= 2i) {
            let _e541 = r123p;
            let _e542 = Cm;
            Cm = (_e542 * _e541);
            let _e544 = m_3;
            let _e546 = opd_1;
            let _e548 = m_3;
            let _e550 = phi23p;
            let _e552 = phi21_[0u];
            param_139 = (f32(_e544) * _e546);
            param_140 = ((_e550 + vec3(_e552)) * f32(_e548));
            let _e556 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_139), (&param_140));
            Sm = (_e556 * 2f);
            let _e558 = Cm;
            let _e559 = Sm;
            let _e561 = I;
            I = (_e561 + (_e558 * _e559));
            continue;
        } else {
            break;
        }
        continuing {
            let _e563 = m_3;
            m_3 = (_e563 + 1i);
        }
    }
    let _e566 = T121_[1u];
    param_141 = _e566;
    let _e567 = mx_square_u0028_f1_u003b((&param_141));
    let _e568 = R23s;
    let _e571 = R12_[1u];
    let _e572 = R23s;
    Rp_3 = ((_e568 * _e567) / (vec3<f32>(1f, 1f, 1f) - (_e572 * _e571)));
    let _e577 = R12_[1u];
    let _e578 = Rp_3;
    let _e581 = I;
    I = (_e581 + (vec3(_e577) + _e578));
    let _e583 = Rp_3;
    let _e585 = T121_[1u];
    Cm = (_e583 - vec3(_e585));
    m_4 = 1i;
    loop {
        let _e588 = m_4;
        if (_e588 <= 2i) {
            let _e590 = r123s;
            let _e591 = Cm;
            Cm = (_e591 * _e590);
            let _e593 = m_4;
            let _e595 = opd_1;
            let _e597 = m_4;
            let _e599 = phi23s;
            let _e601 = phi21_[1u];
            param_142 = (f32(_e593) * _e595);
            param_143 = ((_e599 + vec3(_e601)) * f32(_e597));
            let _e605 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_142), (&param_143));
            Sm = (_e605 * 2f);
            let _e607 = Cm;
            let _e608 = Sm;
            let _e610 = I;
            I = (_e610 + (_e607 * _e608));
            continue;
        } else {
            break;
        }
        continuing {
            let _e612 = m_4;
            m_4 = (_e612 + 1i);
        }
    }
    let _e614 = I;
    I = (_e614 * 0.5f);
    param_144 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e616 = I;
    param_145 = _e616;
    let _e617 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_144), (&param_145));
    I = clamp(_e617, vec3(0f), vec3(1f));
    let _e621 = I;
    return _e621;
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

    let _e355 = (*fd_2).airy;
    if _e355 {
        let _e356 = (*cosTheta_11);
        param_146 = _e356;
        let _e357 = (*fd_2);
        param_147 = _e357;
        let _e358 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_146), (&param_147));
        return _e358;
    } else {
        let _e360 = (*fd_2).model;
        if (_e360 == 0i) {
            let _e362 = (*cosTheta_11);
            param_148 = _e362;
            let _e365 = (*fd_2).ior[0u];
            param_149 = _e365;
            let _e366 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_148), (&param_149));
            return vec3(_e366);
        } else {
            let _e369 = (*fd_2).model;
            if (_e369 == 1i) {
                let _e371 = (*cosTheta_11);
                param_150 = _e371;
                let _e373 = (*fd_2).ior;
                param_151 = _e373;
                let _e375 = (*fd_2).extinction;
                param_152 = _e375;
                let _e376 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_150), (&param_151), (&param_152));
                return _e376;
            } else {
                let _e377 = (*cosTheta_11);
                param_153 = _e377;
                let _e378 = (*fd_2);
                param_154 = _e378;
                let _e379 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_153), (&param_154));
                return _e379;
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

    let _e351 = (*dir_2);
    let _e356 = (*transform_1);
    param_155 = _e356;
    param_156 = vec4<f32>(_e351.x, _e351.y, _e351.z, 0f);
    let _e357 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_155), (&param_156));
    envDir_1 = normalize(_e357.xyz);
    let _e360 = envDir_1;
    param_157 = _e360;
    let _e361 = mx_latlong_projection_u0028_vf3_u003b((&param_157));
    uv_2 = _e361;
    let _e362 = uv_2;
    let _e363 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e362, 0.0);
    return _e363.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_158: f32;

    let _e350 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e350 - 1.5f);
    let _e353 = (*dir_3)[1u];
    param_158 = _e353;
    let _e354 = mx_square_u0028_f1_u003b((&param_158));
    distortion = sqrt((1f - _e354));
    let _e357 = effectiveMaxMipLevel;
    let _e358 = (*envSamples);
    let _e360 = (*pdf);
    let _e362 = distortion;
    return max((_e357 - (0.5f * log2(((f32(_e358) * _e360) * _e362)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H_1: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_159: f32;
    var param_160: f32;

    let _e349 = (*H_1);
    let _e351 = (*alpha_1);
    He = (_e349.xy / _e351);
    let _e353 = He;
    let _e354 = He;
    let _e357 = (*H_1)[2u];
    param_159 = _e357;
    let _e358 = mx_square_u0028_f1_u003b((&param_159));
    denom_1 = (dot(_e353, _e354) + _e358);
    let _e361 = (*alpha_1)[0u];
    let _e364 = (*alpha_1)[1u];
    let _e366 = denom_1;
    param_160 = _e366;
    let _e367 = mx_square_u0028_f1_u003b((&param_160));
    return (1f / (((3.1415927f * _e361) * _e364) * _e367));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_2: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_13: ptr<function, f32>) -> f32 {
    var param_161: vec3<f32>;
    var param_162: vec2<f32>;

    let _e349 = (*H_2);
    param_161 = _e349;
    let _e350 = (*alpha_2);
    param_162 = _e350;
    let _e351 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_161), (&param_162));
    let _e352 = (*G1V);
    let _e354 = (*NdotV_13);
    return ((_e351 * _e352) / (4f * _e354));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e347 = (*R_1);
    let _e348 = (*N_12);
    let _e349 = (*ior_2);
    (*R_1) = refract(_e347, _e348, (1f / _e349));
    let _e352 = (*R_1);
    let _e353 = (*R_1);
    let _e354 = (*N_12);
    let _e357 = (*N_12);
    N1_ = normalize(((_e352 * dot(_e353, _e354)) - (_e357 * 0.5f)));
    let _e361 = (*R_1);
    let _e362 = N1_;
    let _e363 = (*ior_2);
    return refract(_e361, _e362, _e363);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_8: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_9: f32;
    var y_3: f32;
    var c_2: vec3<f32>;
    var H_3: vec3<f32>;

    let _e353 = (*V_8);
    let _e355 = (*alpha_3);
    let _e356 = (_e353.xy * _e355);
    let _e358 = (*V_8)[2u];
    (*V_8) = normalize(vec3<f32>(_e356.x, _e356.y, _e358));
    let _e364 = (*Xi)[0u];
    phi = (6.2831855f * _e364);
    let _e367 = (*Xi)[1u];
    let _e370 = (*V_8)[2u];
    let _e374 = (*V_8)[2u];
    z = (((1f - _e367) * (1f + _e370)) - _e374);
    let _e376 = z;
    let _e377 = z;
    sinTheta = sqrt(clamp((1f - (_e376 * _e377)), 0f, 1f));
    let _e382 = sinTheta;
    let _e383 = phi;
    x_9 = (_e382 * cos(_e383));
    let _e386 = sinTheta;
    let _e387 = phi;
    y_3 = (_e386 * sin(_e387));
    let _e390 = x_9;
    let _e391 = y_3;
    let _e392 = z;
    c_2 = vec3<f32>(_e390, _e391, _e392);
    let _e394 = c_2;
    let _e395 = (*V_8);
    H_3 = (_e394 + _e395);
    let _e397 = H_3;
    let _e399 = (*alpha_3);
    let _e400 = (_e397.xy * _e399);
    let _e402 = H_3[2u];
    H_3 = normalize(vec3<f32>(_e400.x, _e400.y, max(_e402, 0f)));
    let _e408 = H_3;
    return _e408;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e344 = (*i_1);
    return fract(((f32(_e344) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_163: i32;

    let _e346 = (*i_2);
    let _e349 = (*numSamples);
    let _e352 = (*i_2);
    param_163 = _e352;
    let _e353 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_163));
    return vec2<f32>(((f32(_e346) + 0.5f) / f32(_e349)), _e353);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_12: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_164: f32;
    var tanTheta2_: f32;
    var param_165: f32;

    let _e349 = (*cosTheta_12);
    param_164 = _e349;
    let _e350 = mx_square_u0028_f1_u003b((&param_164));
    cosTheta2_2 = _e350;
    let _e351 = cosTheta2_2;
    let _e353 = cosTheta2_2;
    tanTheta2_ = ((1f - _e351) / _e353);
    let _e355 = (*alpha_4);
    param_165 = _e355;
    let _e356 = mx_square_u0028_f1_u003b((&param_165));
    let _e357 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e356 * _e357)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e345 = (*alpha_5)[0u];
    let _e347 = (*alpha_5)[1u];
    return sqrt((_e345 * _e347));
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

    let _e400 = (*X_2);
    let _e401 = (*X_2);
    let _e402 = (*N_13);
    let _e404 = (*N_13);
    (*X_2) = normalize((_e400 - (_e404 * dot(_e401, _e402))));
    let _e408 = (*N_13);
    let _e409 = (*X_2);
    Y_2 = cross(_e408, _e409);
    let _e411 = (*X_2);
    let _e412 = Y_2;
    let _e413 = (*N_13);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e411.x, _e411.y, _e411.z), vec3<f32>(_e412.x, _e412.y, _e412.z), vec3<f32>(_e413.x, _e413.y, _e413.z));
    let _e427 = (*V_9);
    let _e428 = (*X_2);
    let _e430 = (*V_9);
    let _e431 = Y_2;
    let _e433 = (*V_9);
    let _e434 = (*N_13);
    (*V_9) = vec3<f32>(dot(_e427, _e428), dot(_e430, _e431), dot(_e433, _e434));
    let _e438 = (*V_9)[2u];
    NdotV_14 = clamp(_e438, 0.00000001f, 1f);
    let _e440 = (*alpha_6);
    param_166 = _e440;
    let _e441 = mx_average_alpha_u0028_vf2_u003b((&param_166));
    avgAlpha = _e441;
    let _e442 = NdotV_14;
    param_167 = _e442;
    let _e443 = avgAlpha;
    param_168 = _e443;
    let _e444 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_167), (&param_168));
    G1V_1 = _e444;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e445 = i_3;
        let _e446 = envRadianceSamples;
        if (_e445 < _e446) {
            let _e448 = i_3;
            param_169 = _e448;
            let _e449 = envRadianceSamples;
            param_170 = _e449;
            let _e450 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_169), (&param_170));
            Xi_1 = _e450;
            let _e451 = Xi_1;
            param_171 = _e451;
            let _e452 = (*V_9);
            param_172 = _e452;
            let _e453 = (*alpha_6);
            param_173 = _e453;
            let _e454 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_171), (&param_172), (&param_173));
            H_4 = _e454;
            let _e456 = (*fd_3).refraction;
            if _e456 {
                let _e457 = (*V_9);
                param_174 = -(_e457);
                let _e459 = H_4;
                param_175 = _e459;
                let _e462 = (*fd_3).ior[0u];
                param_176 = _e462;
                let _e463 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_174), (&param_175), (&param_176));
                local_7 = _e463;
            } else {
                let _e464 = (*V_9);
                let _e465 = H_4;
                local_7 = -(reflect(_e464, _e465));
            }
            let _e468 = local_7;
            L_7 = _e468;
            let _e470 = L_7[2u];
            NdotL_8 = clamp(_e470, 0.00000001f, 1f);
            let _e472 = (*V_9);
            let _e473 = H_4;
            VdotH = clamp(dot(_e472, _e473), 0.00000001f, 1f);
            let _e476 = tangentToWorld;
            param_177 = _e476;
            let _e477 = L_7;
            param_178 = _e477;
            let _e478 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_177), (&param_178));
            Lw = _e478;
            let _e479 = H_4;
            param_179 = _e479;
            let _e480 = (*alpha_6);
            param_180 = _e480;
            let _e481 = G1V_1;
            param_181 = _e481;
            let _e482 = NdotV_14;
            param_182 = _e482;
            let _e483 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_179), (&param_180), (&param_181), (&param_182));
            pdf_1 = _e483;
            let _e484 = Lw;
            param_183 = _e484;
            let _e485 = pdf_1;
            param_184 = _e485;
            param_185 = 0f;
            let _e486 = envRadianceSamples;
            param_186 = _e486;
            let _e487 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_183), (&param_184), (&param_185), (&param_186));
            lod_2 = _e487;
            let _e488 = mtlxEnvMatrix_u0028_();
            let _e489 = Lw;
            param_187 = _e489;
            param_188 = _e488;
            let _e490 = lod_2;
            param_189 = _e490;
            let _e491 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_187), (&param_188), (&param_189));
            sampleColor = _e491;
            let _e492 = VdotH;
            param_190 = _e492;
            let _e493 = (*fd_3);
            param_191 = _e493;
            let _e494 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_190), (&param_191));
            F_1 = _e494;
            let _e495 = NdotL_8;
            param_192 = _e495;
            let _e496 = NdotV_14;
            param_193 = _e496;
            let _e497 = avgAlpha;
            param_194 = _e497;
            let _e498 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_192), (&param_193), (&param_194));
            G_2 = _e498;
            let _e500 = (*fd_3).refraction;
            if _e500 {
                let _e501 = F_1;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e501);
            } else {
                let _e503 = F_1;
                let _e504 = G_2;
                local_8 = (_e503 * _e504);
            }
            let _e506 = local_8;
            FG = _e506;
            let _e507 = sampleColor;
            let _e508 = FG;
            let _e510 = radiance;
            radiance = (_e510 + (_e507 * _e508));
            continue;
        } else {
            break;
        }
        continuing {
            let _e512 = i_3;
            i_3 = (_e512 + 1i);
        }
    }
    let _e514 = G1V_1;
    let _e515 = envRadianceSamples;
    let _e518 = radiance;
    radiance = (_e518 / vec3((_e514 * f32(_e515))));
    let _e521 = radiance;
    let _e524 = unnamed.skyPower;
    return (select(_e521, vec3<f32>(0f, 0f, 0f), false) * _e524);
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

    let _e355 = (*NdotV_15);
    x_10 = _e355;
    let _e356 = (*alpha_7);
    y_4 = _e356;
    let _e357 = x_10;
    param_195 = _e357;
    let _e358 = mx_square_u0028_f1_u003b((&param_195));
    x2_1 = _e358;
    let _e359 = y_4;
    param_196 = _e359;
    let _e360 = mx_square_u0028_f1_u003b((&param_196));
    y2_ = _e360;
    let _e361 = x_10;
    let _e364 = y_4;
    let _e367 = x_10;
    let _e369 = y_4;
    let _e372 = x2_1;
    let _e375 = y2_;
    let _e378 = x2_1;
    let _e380 = y_4;
    let _e383 = x_10;
    let _e385 = y2_;
    let _e388 = x2_1;
    let _e390 = y2_;
    r_2 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e361)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e364)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e367) * _e369)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e372)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e375)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e378) * _e380)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e383) * _e385)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e388) * _e390));
    let _e393 = r_2;
    let _e395 = r_2;
    AB = clamp((_e393.xy / _e395.zw), vec2(0f), vec2(1f));
    let _e401 = (*F0_2);
    let _e403 = AB[0u];
    let _e405 = (*F90_1);
    let _e407 = AB[1u];
    return ((_e401 * _e403) + (_e405 * _e407));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_16: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_197: f32;
    var param_198: f32;
    var param_199: vec3<f32>;
    var param_200: vec3<f32>;

    let _e351 = (*NdotV_16);
    param_197 = _e351;
    let _e352 = (*alpha_8);
    param_198 = _e352;
    let _e353 = (*F0_3);
    param_199 = _e353;
    let _e354 = (*F90_2);
    param_200 = _e354;
    let _e355 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_197), (&param_198), (&param_199), (&param_200));
    return _e355;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_201: f32;
    var param_202: f32;
    var param_203: vec3<f32>;
    var param_204: vec3<f32>;

    let _e351 = (*F0_4);
    let _e353 = (*F90_3);
    let _e355 = (*NdotV_17);
    param_201 = _e355;
    let _e356 = (*alpha_9);
    param_202 = _e356;
    param_203 = vec3(_e351);
    param_204 = vec3(_e353);
    let _e357 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_201), (&param_202), (&param_203), (&param_204));
    return _e357.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_4: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_205: f32;
    var param_206: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3360_: bool;

    param_205 = 1f;
    let _e349 = (*fd_4);
    param_206 = _e349;
    let _e350 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_205), (&param_206));
    F0_5 = _e350;
    let _e352 = (*fd_4).model;
    let _e353 = (_e352 == 2i);
    phi_3360_ = _e353;
    if _e353 {
        let _e355 = (*fd_4).airy;
        phi_3360_ = !(_e355);
    }
    let _e358 = phi_3360_;
    if _e358 {
        let _e360 = (*fd_4).F90_;
        local_9 = _e360;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e361 = local_9;
    F90_4 = _e361;
    let _e362 = F0_5;
    let _e363 = F90_4;
    let _e364 = F0_5;
    return (_e362 + ((_e363 - _e364) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_18: ptr<function, f32>, alpha_10: ptr<function, f32>, fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_207: FresnelData;
    var Ess: f32;
    var param_208: f32;
    var param_209: f32;
    var param_210: f32;
    var param_211: f32;

    let _e353 = (*fd_5);
    param_207 = _e353;
    let _e354 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_207));
    Fss = _e354;
    let _e355 = (*NdotV_18);
    param_208 = _e355;
    let _e356 = (*alpha_10);
    param_209 = _e356;
    param_210 = 1f;
    param_211 = 1f;
    let _e357 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_208), (&param_209), (&param_210), (&param_211));
    Ess = _e357;
    let _e358 = Fss;
    let _e359 = Ess;
    let _e362 = Ess;
    return (vec3(1f) + ((_e358 * (1f - _e359)) / vec3(_e362)));
}

fn mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(ior_3: ptr<function, vec3<f32>>, extinction: ptr<function, vec3<f32>>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_6: FresnelData;

    fd_6.model = 1i;
    let _e349 = (*tf_thickness);
    fd_6.airy = (_e349 > 0f);
    let _e352 = (*ior_3);
    fd_6.ior = _e352;
    let _e354 = (*extinction);
    fd_6.extinction = _e354;
    fd_6.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_6.exponent = 0f;
    let _e360 = (*tf_thickness);
    fd_6.tf_thickness = _e360;
    let _e362 = (*tf_ior);
    fd_6.tf_ior = _e362;
    fd_6.refraction = false;
    let _e365 = fd_6;
    return _e365;
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
    let _e400 = (*weight_5);
    if (_e400 < 0.00000001f) {
        return;
    }
    let _e403 = (*closureData_12).V;
    V_10 = _e403;
    let _e405 = (*closureData_12).L;
    L_8 = _e405;
    let _e406 = (*retroreflective);
    if _e406 {
        let _e407 = V_10;
        let _e409 = (*N_14);
        local_10 = reflect(-(_e407), _e409);
    } else {
        let _e411 = V_10;
        local_10 = _e411;
    }
    let _e412 = local_10;
    V_10 = _e412;
    let _e413 = (*N_14);
    param_212 = _e413;
    let _e414 = V_10;
    param_213 = _e414;
    let _e415 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_212), (&param_213));
    (*N_14) = _e415;
    let _e416 = (*N_14);
    let _e417 = V_10;
    NdotV_19 = clamp(dot(_e416, _e417), 0.00000001f, 1f);
    let _e420 = (*ior_n);
    param_214 = _e420;
    let _e421 = (*ior_k);
    param_215 = _e421;
    let _e422 = (*thinfilm_thickness);
    param_216 = _e422;
    let _e423 = (*thinfilm_ior);
    param_217 = _e423;
    let _e424 = mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_214), (&param_215), (&param_216), (&param_217));
    fd_7 = _e424;
    let _e425 = (*roughness_14);
    safeAlpha = clamp(_e425, vec2(0.00000001f), vec2(1f));
    let _e429 = safeAlpha;
    param_218 = _e429;
    let _e430 = mx_average_alpha_u0028_vf2_u003b((&param_218));
    avgAlpha_1 = _e430;
    let _e432 = (*closureData_12).closureType;
    if (_e432 == 1i) {
        let _e434 = (*X_3);
        let _e435 = (*X_3);
        let _e436 = (*N_14);
        let _e438 = (*N_14);
        (*X_3) = normalize((_e434 - (_e438 * dot(_e435, _e436))));
        let _e442 = (*N_14);
        let _e443 = (*X_3);
        Y_3 = cross(_e442, _e443);
        let _e445 = L_8;
        let _e446 = V_10;
        H_5 = normalize((_e445 + _e446));
        let _e449 = (*N_14);
        let _e450 = L_8;
        NdotL_9 = clamp(dot(_e449, _e450), 0.00000001f, 1f);
        let _e453 = V_10;
        let _e454 = H_5;
        VdotH_1 = clamp(dot(_e453, _e454), 0.00000001f, 1f);
        let _e457 = H_5;
        let _e458 = (*X_3);
        let _e460 = H_5;
        let _e461 = Y_3;
        let _e463 = H_5;
        let _e464 = (*N_14);
        Ht = vec3<f32>(dot(_e457, _e458), dot(_e460, _e461), dot(_e463, _e464));
        let _e467 = VdotH_1;
        param_219 = _e467;
        let _e468 = fd_7;
        param_220 = _e468;
        let _e469 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_219), (&param_220));
        F_2 = _e469;
        let _e470 = Ht;
        param_221 = _e470;
        let _e471 = safeAlpha;
        param_222 = _e471;
        let _e472 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_221), (&param_222));
        D_1 = _e472;
        let _e473 = NdotL_9;
        param_223 = _e473;
        let _e474 = NdotV_19;
        param_224 = _e474;
        let _e475 = avgAlpha_1;
        param_225 = _e475;
        let _e476 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_223), (&param_224), (&param_225));
        G_3 = _e476;
        let _e477 = NdotV_19;
        param_226 = _e477;
        let _e478 = avgAlpha_1;
        param_227 = _e478;
        let _e479 = fd_7;
        param_228 = _e479;
        let _e480 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_226), (&param_227), (&param_228));
        comp = _e480;
        let _e481 = D_1;
        let _e482 = F_2;
        let _e484 = G_3;
        let _e486 = comp;
        let _e489 = (*closureData_12).occlusion;
        let _e491 = (*weight_5);
        let _e493 = NdotV_19;
        (*bsdf_4).response = ((((((_e482 * _e481) * _e484) * _e486) * _e489) * _e491) / vec3((4f * _e493)));
    } else {
        let _e499 = (*closureData_12).closureType;
        if (_e499 == 3i) {
            let _e501 = NdotV_19;
            param_229 = _e501;
            let _e502 = avgAlpha_1;
            param_230 = _e502;
            let _e503 = fd_7;
            param_231 = _e503;
            let _e504 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_229), (&param_230), (&param_231));
            comp_1 = _e504;
            let _e505 = (*N_14);
            param_232 = _e505;
            let _e506 = V_10;
            param_233 = _e506;
            let _e507 = (*X_3);
            param_234 = _e507;
            let _e508 = safeAlpha;
            param_235 = _e508;
            let _e509 = (*distribution_1);
            param_236 = _e509;
            let _e510 = fd_7;
            param_237 = _e510;
            let _e511 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_232), (&param_233), (&param_234), (&param_235), (&param_236), (&param_237));
            Li_5 = _e511;
            let _e512 = Li_5;
            let _e513 = comp_1;
            let _e515 = (*weight_5);
            (*bsdf_4).response = ((_e512 * _e513) * _e515);
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
        let _e358 = (*tint_1);
        param_238 = _e358;
        let _e359 = mx_square_u0028_vf3_u003b((&param_238));
        (*tint_1) = _e359;
    }
    let _e360 = (*N_15);
    param_239 = _e360;
    let _e361 = (*V_11);
    param_240 = _e361;
    let _e362 = (*X_4);
    param_241 = _e362;
    let _e363 = (*alpha_11);
    param_242 = _e363;
    let _e364 = (*distribution_2);
    param_243 = _e364;
    let _e365 = (*fd_8);
    param_244 = _e365;
    let _e366 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_239), (&param_240), (&param_241), (&param_242), (&param_243), (&param_244));
    let _e367 = (*tint_1);
    return (_e366 * _e367);
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_4: ptr<function, f32>) -> f32 {
    var param_245: f32;

    let _e345 = (*ior_4);
    let _e347 = (*ior_4);
    param_245 = ((_e345 - 1f) / (_e347 + 1f));
    let _e350 = mx_square_u0028_f1_u003b((&param_245));
    return _e350;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_5: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e348 = (*tf_thickness_1);
    fd_9.airy = (_e348 > 0f);
    let _e351 = (*ior_5);
    fd_9.ior = vec3(_e351);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e359 = (*tf_thickness_1);
    fd_9.tf_thickness = _e359;
    let _e361 = (*tf_ior_1);
    fd_9.tf_ior = _e361;
    fd_9.refraction = false;
    let _e364 = fd_9;
    return _e364;
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
    var phi_4400_: bool;

    let _e427 = (*weight_6);
    if (_e427 < 0.00000001f) {
        return;
    }
    let _e430 = (*closureData_13).closureType;
    let _e432 = (*scatter_mode);
    if ((_e430 != 2i) && (_e432 == 1i)) {
        return;
    }
    let _e436 = (*closureData_13).V;
    V_12 = _e436;
    let _e438 = (*closureData_13).L;
    L_9 = _e438;
    let _e439 = (*retroreflective_1);
    phi_4400_ = _e439;
    if _e439 {
        let _e441 = (*closureData_13).closureType;
        phi_4400_ = (_e441 != 2i);
    }
    let _e444 = phi_4400_;
    if _e444 {
        let _e445 = V_12;
        let _e447 = (*N_16);
        V_12 = reflect(-(_e445), _e447);
    }
    let _e449 = (*N_16);
    param_246 = _e449;
    let _e450 = V_12;
    param_247 = _e450;
    let _e451 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_246), (&param_247));
    (*N_16) = _e451;
    let _e452 = (*N_16);
    let _e453 = V_12;
    NdotV_20 = clamp(dot(_e452, _e453), 0.00000001f, 1f);
    let _e456 = (*ior_6);
    param_248 = _e456;
    let _e457 = (*thinfilm_thickness_1);
    param_249 = _e457;
    let _e458 = (*thinfilm_ior_1);
    param_250 = _e458;
    let _e459 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_248), (&param_249), (&param_250));
    fd_10 = _e459;
    let _e460 = (*ior_6);
    param_251 = _e460;
    let _e461 = mx_ior_to_f0_u0028_f1_u003b((&param_251));
    F0_6 = _e461;
    let _e462 = (*roughness_15);
    safeAlpha_1 = clamp(_e462, vec2(0.00000001f), vec2(1f));
    let _e466 = safeAlpha_1;
    param_252 = _e466;
    let _e467 = mx_average_alpha_u0028_vf2_u003b((&param_252));
    avgAlpha_2 = _e467;
    let _e468 = (*tint_2);
    safeTint = max(_e468, vec3(0f));
    let _e472 = (*closureData_13).closureType;
    if (_e472 == 1i) {
        let _e474 = (*X_5);
        let _e475 = (*X_5);
        let _e476 = (*N_16);
        let _e478 = (*N_16);
        (*X_5) = normalize((_e474 - (_e478 * dot(_e475, _e476))));
        let _e482 = (*N_16);
        let _e483 = (*X_5);
        Y_4 = cross(_e482, _e483);
        let _e485 = L_9;
        let _e486 = V_12;
        H_6 = normalize((_e485 + _e486));
        let _e489 = (*N_16);
        let _e490 = L_9;
        NdotL_10 = clamp(dot(_e489, _e490), 0.00000001f, 1f);
        let _e493 = V_12;
        let _e494 = H_6;
        VdotH_2 = clamp(dot(_e493, _e494), 0.00000001f, 1f);
        let _e497 = H_6;
        let _e498 = (*X_5);
        let _e500 = H_6;
        let _e501 = Y_4;
        let _e503 = H_6;
        let _e504 = (*N_16);
        Ht_1 = vec3<f32>(dot(_e497, _e498), dot(_e500, _e501), dot(_e503, _e504));
        let _e507 = VdotH_2;
        param_253 = _e507;
        let _e508 = fd_10;
        param_254 = _e508;
        let _e509 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254));
        F_3 = _e509;
        let _e510 = Ht_1;
        param_255 = _e510;
        let _e511 = safeAlpha_1;
        param_256 = _e511;
        let _e512 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_255), (&param_256));
        D_2 = _e512;
        let _e513 = NdotL_10;
        param_257 = _e513;
        let _e514 = NdotV_20;
        param_258 = _e514;
        let _e515 = avgAlpha_2;
        param_259 = _e515;
        let _e516 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_257), (&param_258), (&param_259));
        G_4 = _e516;
        let _e517 = NdotV_20;
        param_260 = _e517;
        let _e518 = avgAlpha_2;
        param_261 = _e518;
        let _e519 = fd_10;
        param_262 = _e519;
        let _e520 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_260), (&param_261), (&param_262));
        comp_2 = _e520;
        let _e521 = NdotV_20;
        param_263 = _e521;
        let _e522 = avgAlpha_2;
        param_264 = _e522;
        let _e523 = F0_6;
        param_265 = _e523;
        param_266 = 1f;
        let _e524 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_263), (&param_264), (&param_265), (&param_266));
        let _e525 = comp_2;
        dirAlbedo_5 = (_e525 * _e524);
        let _e527 = dirAlbedo_5;
        let _e528 = (*weight_6);
        (*bsdf_5).throughput = (vec3(1f) - (_e527 * _e528));
        let _e533 = D_2;
        let _e534 = F_3;
        let _e536 = G_4;
        let _e538 = comp_2;
        let _e540 = safeTint;
        let _e543 = (*closureData_13).occlusion;
        let _e545 = (*weight_6);
        let _e547 = NdotV_20;
        (*bsdf_5).response = (((((((_e534 * _e533) * _e536) * _e538) * _e540) * _e543) * _e545) / vec3((4f * _e547)));
    } else {
        let _e553 = (*closureData_13).closureType;
        if (_e553 == 2i) {
            let _e555 = NdotV_20;
            param_267 = _e555;
            let _e556 = avgAlpha_2;
            param_268 = _e556;
            let _e557 = fd_10;
            param_269 = _e557;
            let _e558 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
            comp_3 = _e558;
            let _e559 = NdotV_20;
            param_270 = _e559;
            let _e560 = avgAlpha_2;
            param_271 = _e560;
            let _e561 = F0_6;
            param_272 = _e561;
            param_273 = 1f;
            let _e562 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
            let _e563 = comp_3;
            dirAlbedo_6 = (_e563 * _e562);
            let _e565 = dirAlbedo_6;
            let _e566 = (*weight_6);
            (*bsdf_5).throughput = (vec3(1f) - (_e565 * _e566));
            let _e571 = (*scatter_mode);
            if (_e571 != 0i) {
                let _e573 = (*N_16);
                param_274 = _e573;
                let _e574 = V_12;
                param_275 = _e574;
                let _e575 = (*X_5);
                param_276 = _e575;
                let _e576 = safeAlpha_1;
                param_277 = _e576;
                let _e577 = (*distribution_3);
                param_278 = _e577;
                let _e578 = fd_10;
                param_279 = _e578;
                let _e579 = safeTint;
                param_280 = _e579;
                let _e580 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279), (&param_280));
                let _e581 = (*weight_6);
                (*bsdf_5).response = (_e580 * _e581);
            }
        } else {
            let _e585 = (*closureData_13).closureType;
            if (_e585 == 3i) {
                let _e587 = NdotV_20;
                param_281 = _e587;
                let _e588 = avgAlpha_2;
                param_282 = _e588;
                let _e589 = fd_10;
                param_283 = _e589;
                let _e590 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_281), (&param_282), (&param_283));
                comp_4 = _e590;
                let _e591 = NdotV_20;
                param_284 = _e591;
                let _e592 = avgAlpha_2;
                param_285 = _e592;
                let _e593 = F0_6;
                param_286 = _e593;
                param_287 = 1f;
                let _e594 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_284), (&param_285), (&param_286), (&param_287));
                let _e595 = comp_4;
                dirAlbedo_7 = (_e595 * _e594);
                let _e597 = dirAlbedo_7;
                let _e598 = (*weight_6);
                (*bsdf_5).throughput = (vec3(1f) - (_e597 * _e598));
                let _e603 = (*N_16);
                param_288 = _e603;
                let _e604 = V_12;
                param_289 = _e604;
                let _e605 = (*X_5);
                param_290 = _e605;
                let _e606 = safeAlpha_1;
                param_291 = _e606;
                let _e607 = (*distribution_3);
                param_292 = _e607;
                let _e608 = fd_10;
                param_293 = _e608;
                let _e609 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_288), (&param_289), (&param_290), (&param_291), (&param_292), (&param_293));
                Li_6 = _e609;
                let _e610 = Li_6;
                let _e611 = safeTint;
                let _e613 = comp_4;
                let _e615 = (*weight_6);
                (*bsdf_5).response = (((_e610 * _e611) * _e613) * _e615);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e349 = (*closureType);
    let _e350 = (*L_10);
    let _e351 = (*V_13);
    let _e352 = (*N_17);
    let _e353 = (*P_2);
    let _e354 = (*occlusion_1);
    return ClosureData(_e349, _e350, _e351, _e352, _e353, _e354);
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_4: ptr<function, f32>, out1_: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e346 = (*in1_4);
    combine_out = vec3(_e346);
    let _e348 = combine_out;
    (*out1_) = _e348;
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

    let _e354 = (*reflectivity);
    r_3 = clamp(_e354, vec3(0f), vec3(0.99f));
    let _e358 = r_3;
    r_sqrt = sqrt(_e358);
    let _e360 = r_3;
    let _e363 = r_3;
    n_min = ((vec3(1f) - _e360) / (vec3(1f) + _e363));
    let _e367 = r_sqrt;
    let _e370 = r_sqrt;
    n_max = ((vec3(1f) + _e367) / (vec3(1f) - _e370));
    let _e374 = n_max;
    let _e375 = n_min;
    let _e376 = (*edge_color);
    (*ior_7) = mix(_e374, _e375, _e376);
    let _e378 = (*ior_7);
    np1_ = (_e378 + vec3(1f));
    let _e381 = (*ior_7);
    nm1_ = (_e381 - vec3(1f));
    let _e384 = np1_;
    let _e385 = np1_;
    let _e387 = r_3;
    let _e389 = nm1_;
    let _e390 = nm1_;
    let _e393 = r_3;
    k2_2 = ((((_e384 * _e385) * _e387) - (_e389 * _e390)) / (vec3(1f) - _e393));
    let _e397 = k2_2;
    k2_2 = max(_e397, vec3(0f));
    let _e400 = k2_2;
    (*extinction_1) = sqrt(_e400);
    return;
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_8: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e351 = (*axis);
    (*axis) = normalize(_e351);
    let _e353 = (*amount);
    rotationRadians = radians(_e353);
    let _e355 = rotationRadians;
    s_4 = sin(_e355);
    let _e357 = rotationRadians;
    c_3 = cos(_e357);
    let _e359 = c_3;
    oc = (1f - _e359);
    let _e361 = (*_in);
    let _e362 = c_3;
    let _e364 = (*_in);
    let _e365 = (*axis);
    let _e367 = s_4;
    let _e370 = (*axis);
    let _e371 = (*axis);
    let _e372 = (*_in);
    let _e375 = oc;
    (*result_8) = (((_e361 * _e362) + (cross(_e364, _e365) * _e367)) + ((_e370 * dot(_e371, _e372)) * _e375));
    return;
}

fn mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b(_in_1: ptr<function, vec3<f32>>, lumacoeffs: ptr<function, vec3<f32>>, result_9: ptr<function, vec3<f32>>) {
    let _e346 = (*_in_1);
    let _e347 = (*lumacoeffs);
    (*result_9) = vec3(dot(_e346, _e347));
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_1: ptr<function, f32>, result_10: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e348 = (*roughness_16);
    let _e349 = (*roughness_16);
    roughness_sqr = clamp((_e348 * _e349), 0.00000001f, 1f);
    let _e352 = (*anisotropy_1);
    if (_e352 > 0f) {
        let _e354 = (*anisotropy_1);
        aspect = sqrt((1f - clamp(_e354, 0f, 0.98f)));
        let _e358 = roughness_sqr;
        let _e359 = aspect;
        (*result_10)[0u] = min((_e358 / _e359), 1f);
        let _e363 = roughness_sqr;
        let _e364 = aspect;
        (*result_10)[1u] = (_e363 * _e364);
    } else {
        let _e367 = roughness_sqr;
        (*result_10)[0u] = _e367;
        let _e369 = roughness_sqr;
        (*result_10)[1u] = _e369;
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
    let _e643 = (*coat_roughness);
    param_294 = _e643;
    let _e644 = (*coat_anisotropy);
    param_295 = _e644;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_294), (&param_295), (&param_296));
    let _e645 = param_296;
    coat_roughness_vector_out = _e645;
    let _e646 = (*coat_rotation);
    coat_tangent_rotate_degree_out = (_e646 * 360f);
    let _e648 = (*metalness);
    metalness_mix_fg_weight_out = (1f * _e648);
    let _e650 = (*base_color);
    let _e651 = (*base_2);
    metal_reflectivity_out = (_e650 * _e651);
    let _e653 = (*specular_color);
    let _e654 = (*specular);
    metal_edgecolor_out = (_e653 * _e654);
    let _e656 = (*coat_affect_roughness);
    let _e657 = (*coat);
    coat_affect_roughness_multiply1_out = (_e656 * _e657);
    let _e659 = (*specular_rotation);
    tangent_rotate_degree_out = (_e659 * 360f);
    let _e661 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e661);
    let _e663 = (*specular_roughness);
    let _e664 = (*transmission_extra_roughness);
    transmission_roughness_add_out = (_e663 + _e664);
    let _e666 = (*thin_walled);
    subsurface_selector_out = select(0f, 1f, _e666);
    let _e668 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e668, vec3(0f));
    let _e671 = (*coat);
    coat_clamped_out = clamp(_e671, 0f, 1f);
    let _e673 = (*subsurface_radius);
    let _e674 = (*subsurface_scale);
    subsurface_radius_scaled_out = (_e673 * _e674);
    let _e676 = (*subsurface);
    subsurface_mix_mix_inv_out = (1f - _e676);
    let _e678 = (*base_color);
    base_color_nonnegative_out = max(_e678, vec3(0f));
    let _e681 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e681);
    let _e683 = (*metalness);
    metalness_mix_mix_inv_out = (1f - _e683);
    let _e685 = (*coat_color);
    let _e686 = (*coat);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e685, vec3(_e686));
    let _e689 = (*coat_IOR);
    one_minus_coat_ior_out = (1f - _e689);
    let _e691 = (*coat_IOR);
    one_plus_coat_ior_out = (1f + _e691);
    let _e693 = (*emission_color);
    let _e694 = (*emission);
    emission_weight_out = (_e693 * _e694);
    opacity_luminance_out = vec3<f32>(0f, 0f, 0f);
    let _e696 = (*opacity);
    param_297 = _e696;
    param_298 = vec3<f32>(0.272229f, 0.674082f, 0.053689f);
    mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_297), (&param_298), (&param_299));
    let _e697 = param_299;
    opacity_luminance_out = _e697;
    coat_tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e698 = (*tangent);
    param_300 = _e698;
    let _e699 = coat_tangent_rotate_degree_out;
    param_301 = _e699;
    let _e700 = (*coat_normal);
    param_302 = _e700;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_300), (&param_301), (&param_302), (&param_303));
    let _e701 = param_303;
    coat_tangent_rotate_out = _e701;
    artistic_ior_ior = vec3<f32>(0f, 0f, 0f);
    artistic_ior_extinction = vec3<f32>(0f, 0f, 0f);
    let _e702 = metal_reflectivity_out;
    param_304 = _e702;
    let _e703 = metal_edgecolor_out;
    param_305 = _e703;
    mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_304), (&param_305), (&param_306), (&param_307));
    let _e704 = param_306;
    artistic_ior_ior = _e704;
    let _e705 = param_307;
    artistic_ior_extinction = _e705;
    let _e706 = coat_affect_roughness_multiply1_out;
    let _e707 = (*coat_roughness);
    coat_affect_roughness_multiply2_out = (_e706 * _e707);
    tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e709 = (*tangent);
    param_308 = _e709;
    let _e710 = tangent_rotate_degree_out;
    param_309 = _e710;
    let _e711 = (*normal);
    param_310 = _e711;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_308), (&param_309), (&param_310), (&param_311));
    let _e712 = param_311;
    tangent_rotate_out = _e712;
    let _e713 = transmission_roughness_add_out;
    transmission_roughness_clamped_out = clamp(_e713, 0f, 1f);
    let _e715 = subsurface_selector_out;
    selected_subsurface_bsdf_mix_inv_out = (1f - _e715);
    let _e717 = subsurface_selector_out;
    selected_subsurface_bsdf_fg_weight_out = (1f * _e717);
    let _e719 = coat_clamped_out;
    let _e720 = (*coat_affect_color);
    coat_gamma_multiply_out = (_e719 * _e720);
    let _e722 = (*base_2);
    let _e723 = subsurface_mix_mix_inv_out;
    subsurface_mix_bg_weight_out = (_e722 * _e723);
    let _e725 = one_minus_coat_ior_out;
    let _e726 = one_plus_coat_ior_out;
    coat_ior_to_F0_sqrt_out = (_e725 / _e726);
    let _e729 = opacity_luminance_out[0u];
    opacity_luminance_float_out = _e729;
    let _e730 = coat_tangent_rotate_out;
    coat_tangent_rotate_normalize_out = normalize(_e730);
    let _e732 = (*specular_roughness);
    let _e733 = coat_affect_roughness_multiply2_out;
    coat_affected_roughness_out = mix(_e732, 1f, _e733);
    let _e735 = tangent_rotate_out;
    tangent_rotate_normalize_out = normalize(_e735);
    let _e737 = transmission_roughness_clamped_out;
    let _e738 = coat_affect_roughness_multiply2_out;
    coat_affected_transmission_roughness_out = mix(_e737, 1f, _e738);
    let _e740 = selected_subsurface_bsdf_mix_inv_out;
    selected_subsurface_bsdf_bg_weight_out = (1f * _e740);
    let _e742 = coat_gamma_multiply_out;
    coat_gamma_out = (_e742 + 1f);
    let _e744 = coat_ior_to_F0_sqrt_out;
    let _e745 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e744 * _e745);
    let _e747 = (*coat_anisotropy);
    let _e749 = coat_tangent_rotate_normalize_out;
    let _e750 = (*tangent);
    coat_tangent_out = select(_e750, _e749, (_e747 > 0f));
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e752 = coat_affected_roughness_out;
    param_312 = _e752;
    let _e753 = (*specular_anisotropy);
    param_313 = _e753;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_312), (&param_313), (&param_314));
    let _e754 = param_314;
    main_roughness_out = _e754;
    let _e755 = (*specular_anisotropy);
    let _e757 = tangent_rotate_normalize_out;
    let _e758 = (*tangent);
    main_tangent_out = select(_e758, _e757, (_e755 > 0f));
    transmission_roughness_out = vec2<f32>(0f, 0f);
    let _e760 = coat_affected_transmission_roughness_out;
    param_315 = _e760;
    let _e761 = (*specular_anisotropy);
    param_316 = _e761;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_315), (&param_316), (&param_317));
    let _e762 = param_317;
    transmission_roughness_out = _e762;
    let _e763 = subsurface_color_nonnegative_out;
    let _e764 = coat_gamma_out;
    coat_affected_subsurface_color_out = pow(_e763, vec3(_e764));
    let _e767 = base_color_nonnegative_out;
    let _e768 = coat_gamma_out;
    coat_affected_diffuse_color_out = pow(_e767, vec3(_e768));
    let _e771 = coat_ior_to_F0_out;
    one_minus_coat_ior_to_F0_out = (1f - _e771);
    emission_color0_out = vec3<f32>(0f, 0f, 0f);
    let _e773 = one_minus_coat_ior_to_F0_out;
    param_318 = _e773;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_318), (&param_319));
    let _e774 = param_319;
    emission_color0_out = _e774;
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e775 = g_ptN;
    N_18 = _e775;
    let _e776 = g_ptV;
    V_14 = _e776;
    let _e777 = g_ptL;
    L_11 = _e777;
    let _e778 = g_ptP;
    P_3 = _e778;
    let _e779 = g_ptOcclusion;
    occlusion_2 = _e779;
    let _e780 = g_ptClosureType;
    param_320 = _e780;
    let _e781 = L_11;
    param_321 = _e781;
    let _e782 = V_14;
    param_322 = _e782;
    let _e783 = N_18;
    param_323 = _e783;
    let _e784 = P_3;
    param_324 = _e784;
    let _e785 = occlusion_2;
    param_325 = _e785;
    let _e786 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325));
    closureData_14 = _e786;
    coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e787 = closureData_14;
    param_326 = _e787;
    let _e788 = (*coat);
    param_327 = _e788;
    param_328 = vec3<f32>(1f, 1f, 1f);
    let _e789 = (*coat_IOR);
    param_329 = _e789;
    let _e790 = coat_roughness_vector_out;
    param_330 = _e790;
    param_331 = false;
    param_332 = 0f;
    param_333 = 1.5f;
    let _e791 = (*coat_normal);
    param_334 = _e791;
    let _e792 = coat_tangent_out;
    param_335 = _e792;
    param_336 = 0i;
    param_337 = 0i;
    let _e793 = coat_bsdf_out;
    param_338 = _e793;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_326), (&param_327), (&param_328), (&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336), (&param_337), (&param_338));
    let _e794 = param_338;
    coat_bsdf_out = _e794;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e795 = closureData_14;
    param_339 = _e795;
    let _e796 = metalness_mix_fg_weight_out;
    param_340 = _e796;
    let _e797 = artistic_ior_ior;
    param_341 = _e797;
    let _e798 = artistic_ior_extinction;
    param_342 = _e798;
    let _e799 = main_roughness_out;
    param_343 = _e799;
    param_344 = false;
    let _e800 = (*thin_film_thickness);
    param_345 = _e800;
    let _e801 = (*thin_film_IOR);
    param_346 = _e801;
    let _e802 = (*normal);
    param_347 = _e802;
    let _e803 = main_tangent_out;
    param_348 = _e803;
    param_349 = 0i;
    let _e804 = metal_bsdf_out;
    param_350 = _e804;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350));
    let _e805 = param_350;
    metal_bsdf_out = _e805;
    specular_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e806 = closureData_14;
    param_351 = _e806;
    let _e807 = (*specular);
    param_352 = _e807;
    let _e808 = (*specular_color);
    param_353 = _e808;
    let _e809 = (*specular_IOR);
    param_354 = _e809;
    let _e810 = main_roughness_out;
    param_355 = _e810;
    param_356 = false;
    let _e811 = (*thin_film_thickness);
    param_357 = _e811;
    let _e812 = (*thin_film_IOR);
    param_358 = _e812;
    let _e813 = (*normal);
    param_359 = _e813;
    let _e814 = main_tangent_out;
    param_360 = _e814;
    param_361 = 0i;
    param_362 = 0i;
    let _e815 = specular_bsdf_out;
    param_363 = _e815;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363));
    let _e816 = param_363;
    specular_bsdf_out = _e816;
    transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e817 = closureData_14;
    param_364 = _e817;
    let _e818 = transmission_mix_fg_weight_out;
    param_365 = _e818;
    let _e819 = (*transmission_color);
    param_366 = _e819;
    let _e820 = (*specular_IOR);
    param_367 = _e820;
    let _e821 = transmission_roughness_out;
    param_368 = _e821;
    param_369 = false;
    param_370 = 0f;
    param_371 = 1.5f;
    let _e822 = (*normal);
    param_372 = _e822;
    let _e823 = main_tangent_out;
    param_373 = _e823;
    param_374 = 0i;
    param_375 = 1i;
    let _e824 = transmission_bsdf_out;
    param_376 = _e824;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372), (&param_373), (&param_374), (&param_375), (&param_376));
    let _e825 = param_376;
    transmission_bsdf_out = _e825;
    sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e826 = closureData_14;
    param_377 = _e826;
    let _e827 = (*sheen);
    param_378 = _e827;
    let _e828 = (*sheen_color);
    param_379 = _e828;
    let _e829 = (*sheen_roughness);
    param_380 = _e829;
    let _e830 = (*normal);
    param_381 = _e830;
    param_382 = 0i;
    let _e831 = sheen_bsdf_out;
    param_383 = _e831;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383));
    let _e832 = param_383;
    sheen_bsdf_out = _e832;
    translucent_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e833 = closureData_14;
    param_384 = _e833;
    let _e834 = selected_subsurface_bsdf_fg_weight_out;
    param_385 = _e834;
    let _e835 = coat_affected_subsurface_color_out;
    param_386 = _e835;
    let _e836 = (*normal);
    param_387 = _e836;
    let _e837 = translucent_bsdf_out;
    param_388 = _e837;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_384), (&param_385), (&param_386), (&param_387), (&param_388));
    let _e838 = param_388;
    translucent_bsdf_out = _e838;
    subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e839 = closureData_14;
    param_389 = _e839;
    let _e840 = selected_subsurface_bsdf_bg_weight_out;
    param_390 = _e840;
    let _e841 = coat_affected_subsurface_color_out;
    param_391 = _e841;
    let _e842 = subsurface_radius_scaled_out;
    param_392 = _e842;
    let _e843 = (*subsurface_anisotropy);
    param_393 = _e843;
    let _e844 = (*normal);
    param_394 = _e844;
    let _e845 = subsurface_bsdf_out;
    param_395 = _e845;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395));
    let _e846 = param_395;
    subsurface_bsdf_out = _e846;
    selected_subsurface_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e847 = closureData_14;
    param_396 = _e847;
    let _e848 = translucent_bsdf_out;
    param_397 = _e848;
    let _e849 = subsurface_bsdf_out;
    param_398 = _e849;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_396), (&param_397), (&param_398), (&param_399));
    let _e850 = param_399;
    selected_subsurface_bsdf_add_out = _e850;
    subsurface_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e851 = closureData_14;
    param_400 = _e851;
    let _e852 = selected_subsurface_bsdf_add_out;
    param_401 = _e852;
    let _e853 = (*subsurface);
    param_402 = _e853;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_400), (&param_401), (&param_402), (&param_403));
    let _e854 = param_403;
    subsurface_mix_fg_mul_out = _e854;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e855 = closureData_14;
    param_404 = _e855;
    let _e856 = subsurface_mix_bg_weight_out;
    param_405 = _e856;
    let _e857 = coat_affected_diffuse_color_out;
    param_406 = _e857;
    let _e858 = (*diffuse_roughness);
    param_407 = _e858;
    let _e859 = (*normal);
    param_408 = _e859;
    param_409 = false;
    let _e860 = diffuse_bsdf_out;
    param_410 = _e860;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_404), (&param_405), (&param_406), (&param_407), (&param_408), (&param_409), (&param_410));
    let _e861 = param_410;
    diffuse_bsdf_out = _e861;
    subsurface_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e862 = closureData_14;
    param_411 = _e862;
    let _e863 = subsurface_mix_fg_mul_out;
    param_412 = _e863;
    let _e864 = diffuse_bsdf_out;
    param_413 = _e864;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_411), (&param_412), (&param_413), (&param_414));
    let _e865 = param_414;
    subsurface_mix_add_out = _e865;
    sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e866 = closureData_14;
    param_415 = _e866;
    let _e867 = sheen_bsdf_out;
    param_416 = _e867;
    let _e868 = subsurface_mix_add_out;
    param_417 = _e868;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_415), (&param_416), (&param_417), (&param_418));
    let _e869 = param_418;
    sheen_layer_out = _e869;
    transmission_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e870 = closureData_14;
    param_419 = _e870;
    let _e871 = sheen_layer_out;
    param_420 = _e871;
    let _e872 = transmission_mix_mix_inv_out;
    param_421 = _e872;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_419), (&param_420), (&param_421), (&param_422));
    let _e873 = param_422;
    transmission_mix_bg_mul_out = _e873;
    transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e874 = closureData_14;
    param_423 = _e874;
    let _e875 = transmission_bsdf_out;
    param_424 = _e875;
    let _e876 = transmission_mix_bg_mul_out;
    param_425 = _e876;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_423), (&param_424), (&param_425), (&param_426));
    let _e877 = param_426;
    transmission_mix_add_out = _e877;
    specular_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e878 = closureData_14;
    param_427 = _e878;
    let _e879 = specular_bsdf_out;
    param_428 = _e879;
    let _e880 = transmission_mix_add_out;
    param_429 = _e880;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_427), (&param_428), (&param_429), (&param_430));
    let _e881 = param_430;
    specular_layer_out = _e881;
    metalness_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e882 = closureData_14;
    param_431 = _e882;
    let _e883 = specular_layer_out;
    param_432 = _e883;
    let _e884 = metalness_mix_mix_inv_out;
    param_433 = _e884;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_431), (&param_432), (&param_433), (&param_434));
    let _e885 = param_434;
    metalness_mix_bg_mul_out = _e885;
    metalness_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e886 = closureData_14;
    param_435 = _e886;
    let _e887 = metal_bsdf_out;
    param_436 = _e887;
    let _e888 = metalness_mix_bg_mul_out;
    param_437 = _e888;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_435), (&param_436), (&param_437), (&param_438));
    let _e889 = param_438;
    metalness_mix_add_out = _e889;
    thin_film_layer_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e890 = closureData_14;
    param_439 = _e890;
    let _e891 = metalness_mix_add_out;
    param_440 = _e891;
    let _e892 = coat_attenuation_out;
    param_441 = _e892;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_439), (&param_440), (&param_441), (&param_442));
    let _e893 = param_442;
    thin_film_layer_attenuated_out = _e893;
    coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e894 = closureData_14;
    param_443 = _e894;
    let _e895 = coat_bsdf_out;
    param_444 = _e895;
    let _e896 = thin_film_layer_attenuated_out;
    param_445 = _e896;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_443), (&param_444), (&param_445), (&param_446));
    let _e897 = param_446;
    coat_layer_out = _e897;
    let _e899 = coat_layer_out.response;
    let _e901 = shader_constructor_out.color;
    shader_constructor_out.color = (_e901 + _e899);
    let _e904 = g_ptEmitEmission;
    if (_e904 != 0i) {
        param_447 = 4i;
        let _e906 = L_11;
        param_448 = _e906;
        let _e907 = V_14;
        param_449 = _e907;
        let _e908 = N_18;
        param_450 = _e908;
        let _e909 = P_3;
        param_451 = _e909;
        let _e910 = occlusion_2;
        param_452 = _e910;
        let _e911 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_447), (&param_448), (&param_449), (&param_450), (&param_451), (&param_452));
        closureData_15 = _e911;
        emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e912 = closureData_15;
        param_453 = _e912;
        let _e913 = emission_weight_out;
        param_454 = _e913;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_453), (&param_454), (&param_455));
        let _e914 = param_455;
        emission_edf_out = _e914;
        coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e915 = closureData_15;
        param_456 = _e915;
        let _e916 = emission_edf_out;
        param_457 = _e916;
        let _e917 = (*coat_color);
        param_458 = _e917;
        mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_456), (&param_457), (&param_458), (&param_459));
        let _e918 = param_459;
        coat_tinted_emission_edf_out = _e918;
        coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e919 = closureData_15;
        param_460 = _e919;
        let _e920 = emission_color0_out;
        param_461 = _e920;
        param_462 = vec3<f32>(0f, 0f, 0f);
        param_463 = 5f;
        let _e921 = coat_tinted_emission_edf_out;
        param_464 = _e921;
        mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_460), (&param_461), (&param_462), (&param_463), (&param_464), (&param_465));
        let _e922 = param_465;
        coat_emission_edf_out = _e922;
        blended_coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e923 = closureData_15;
        param_466 = _e923;
        let _e924 = coat_emission_edf_out;
        param_467 = _e924;
        let _e925 = emission_edf_out;
        param_468 = _e925;
        let _e926 = (*coat);
        param_469 = _e926;
        mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_466), (&param_467), (&param_468), (&param_469), (&param_470));
        let _e927 = param_470;
        blended_coat_emission_edf_out = _e927;
        let _e928 = blended_coat_emission_edf_out;
        let _e929 = g_ptEmission;
        g_ptEmission = (_e929 + _e928);
        let _e931 = blended_coat_emission_edf_out;
        let _e933 = shader_constructor_out.color;
        shader_constructor_out.color = (_e933 + _e931);
    }
    let _e936 = shader_constructor_out;
    (*out1_1) = _e936;
    return;
}

fn mtlxHostEvalSurface_u0028_() -> surfaceshader {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_default_out: surfaceshader;
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

    let _e389 = g_ptN;
    normalWorld = _e389;
    let _e390 = g_ptTangent;
    tangentWorld = _e390;
    let _e391 = normalWorld;
    geomprop_Nworld_out = normalize(_e391);
    let _e393 = tangentWorld;
    geomprop_Tworld_out = normalize(_e393);
    SR_default_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e395 = base_3;
    param_471 = _e395;
    let _e396 = base_color_1;
    param_472 = _e396;
    let _e397 = diffuse_roughness_1;
    param_473 = _e397;
    let _e398 = metalness_1;
    param_474 = _e398;
    let _e399 = specular_1;
    param_475 = _e399;
    let _e400 = specular_color_1;
    param_476 = _e400;
    let _e401 = specular_roughness_1;
    param_477 = _e401;
    let _e402 = specular_IOR_1;
    param_478 = _e402;
    let _e403 = specular_anisotropy_1;
    param_479 = _e403;
    let _e404 = specular_rotation_1;
    param_480 = _e404;
    let _e405 = transmission_1;
    param_481 = _e405;
    let _e406 = transmission_color_1;
    param_482 = _e406;
    let _e407 = transmission_depth_1;
    param_483 = _e407;
    let _e408 = transmission_scatter_1;
    param_484 = _e408;
    let _e409 = transmission_scatter_anisotropy_1;
    param_485 = _e409;
    let _e410 = transmission_dispersion_1;
    param_486 = _e410;
    let _e411 = transmission_extra_roughness_1;
    param_487 = _e411;
    let _e412 = subsurface_1;
    param_488 = _e412;
    let _e413 = subsurface_color_1;
    param_489 = _e413;
    let _e414 = subsurface_radius_1;
    param_490 = _e414;
    let _e415 = subsurface_scale_1;
    param_491 = _e415;
    let _e416 = subsurface_anisotropy_1;
    param_492 = _e416;
    let _e417 = sheen_1;
    param_493 = _e417;
    let _e418 = sheen_color_1;
    param_494 = _e418;
    let _e419 = sheen_roughness_1;
    param_495 = _e419;
    let _e420 = coat_1;
    param_496 = _e420;
    let _e421 = coat_color_1;
    param_497 = _e421;
    let _e422 = coat_roughness_1;
    param_498 = _e422;
    let _e423 = coat_anisotropy_1;
    param_499 = _e423;
    let _e424 = coat_rotation_1;
    param_500 = _e424;
    let _e425 = coat_IOR_1;
    param_501 = _e425;
    let _e426 = geomprop_Nworld_out;
    param_502 = _e426;
    let _e427 = coat_affect_color_1;
    param_503 = _e427;
    let _e428 = coat_affect_roughness_1;
    param_504 = _e428;
    let _e429 = thin_film_thickness_1;
    param_505 = _e429;
    let _e430 = thin_film_IOR_1;
    param_506 = _e430;
    let _e431 = emission_1;
    param_507 = _e431;
    let _e432 = emission_color_1;
    param_508 = _e432;
    let _e433 = opacity_1;
    param_509 = _e433;
    let _e434 = thin_walled_2;
    param_510 = _e434;
    let _e435 = geomprop_Nworld_out;
    param_511 = _e435;
    let _e436 = geomprop_Tworld_out;
    param_512 = _e436;
    NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491), (&param_492), (&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502), (&param_503), (&param_504), (&param_505), (&param_506), (&param_507), (&param_508), (&param_509), (&param_510), (&param_511), (&param_512), (&param_513));
    let _e437 = param_513;
    SR_default_out = _e437;
    let _e438 = SR_default_out;
    return _e438;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e346 = (*basis_2).tW;
    let _e348 = (*vLocal)[0u];
    let _e351 = (*basis_2).bW;
    let _e353 = (*vLocal)[1u];
    let _e357 = (*basis_2).nW;
    let _e359 = (*vLocal)[2u];
    return (((_e346 * _e348) + (_e351 * _e353)) + (_e357 * _e359));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_514: vec3<f32>;
    var param_515: Basis;
    var param_516: vec3<f32>;
    var param_517: Basis;

    let _e352 = (*pW_3);
    g_ptP = _e352;
    let _e354 = (*basis_3).nW;
    g_ptN = _e354;
    let _e356 = (*basis_3).tW;
    g_ptTangent = _e356;
    let _e358 = (*basis_3).bW;
    g_ptBitangent = _e358;
    let _e359 = (*winputL_2);
    param_514 = _e359;
    let _e360 = (*basis_3);
    param_515 = _e360;
    let _e361 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_514), (&param_515));
    g_ptV = _e361;
    let _e362 = (*woutputL_2);
    param_516 = _e362;
    let _e363 = (*basis_3);
    param_517 = _e363;
    let _e364 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_516), (&param_517));
    g_ptL = _e364;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e366 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e366, 0f) / 3.1415927f);
    let _e369 = mtlxHostEvalSurface_u0028_();
    return _e369.color;
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

    let _e364 = (*surfaceshader_1);
    if (_e364 == 1i) {
        let _e366 = (*pW_4);
        param_518 = _e366;
        let _e367 = (*basis_4);
        param_519 = _e367;
        let _e368 = (*winputL_3);
        param_520 = _e368;
        let _e369 = (*woutputL_3);
        param_521 = _e369;
        let _e370 = (*pdf_woutputL_3);
        param_522 = _e370;
        let _e371 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_518), (&param_519), (&param_520), (&param_521), (&param_522));
        let _e372 = param_522;
        (*pdf_woutputL_3) = _e372;
        return _e371;
    } else {
        let _e373 = (*surfaceshader_1);
        if (_e373 == 2i) {
            let _e375 = (*pW_4);
            param_523 = _e375;
            let _e376 = (*basis_4);
            param_524 = _e376;
            let _e377 = (*winputL_3);
            param_525 = _e377;
            let _e378 = (*woutputL_3);
            param_526 = _e378;
            let _e379 = (*pdf_woutputL_3);
            param_527 = _e379;
            let _e380 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_523), (&param_524), (&param_525), (&param_526), (&param_527));
            let _e381 = param_527;
            (*pdf_woutputL_3) = _e381;
            return _e380;
        } else {
            let _e382 = (*pW_4);
            param_528 = _e382;
            let _e383 = (*basis_4);
            param_529 = _e383;
            let _e384 = (*winputL_3);
            param_530 = _e384;
            let _e385 = (*woutputL_3);
            param_531 = _e385;
            let _e386 = (*pdf_woutputL_3);
            param_532 = _e386;
            let _e387 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_528), (&param_529), (&param_530), (&param_531), (&param_532));
            let _e388 = param_532;
            (*pdf_woutputL_3) = _e388;
            return _e387;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    let _e343 = thin_walled_2;
    return _e343;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e343 = g_ptOpacity;
    return (_e343 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e345 = (*N_19);
    l = length(_e345);
    let _e347 = (*N_19);
    let _e348 = l;
    return (_e347 / vec3(max(_e348, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_533: vec3<f32>;

    let _e347 = (*N_20)[2u];
    let _e350 = (*N_20)[0u];
    if (abs(_e347) < abs(_e350)) {
        let _e354 = (*N_20)[2u];
        let _e356 = (*N_20)[0u];
        T = vec3<f32>(_e354, 0f, -(_e356));
    } else {
        let _e360 = (*N_20)[2u];
        let _e362 = (*N_20)[1u];
        T = vec3<f32>(0f, _e360, -(_e362));
    }
    let _e365 = T;
    param_533 = _e365;
    let _e366 = safe_normalize_u0028_vf3_u003b((&param_533));
    T = _e366;
    let _e367 = T;
    return _e367;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e347 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e347).x;
    let _e350 = (*index);
    let _e351 = width;
    let _e359 = (*index);
    let _e360 = width;
    let _e363 = textureLoad(texture, vec2<i32>((_e350 - (i32(floor((f32(_e350) / f32(_e351)))) * _e351)), (_e359 / _e360)), 0i);
    return _e363;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_534: i32;
    var param_535: i32;
    var param_536: i32;

    let _e351 = (*barycoord)[0u];
    let _e353 = (*faceIndices)[0u];
    param_534 = bitcast<i32>(_e353);
    let _e355 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_534));
    let _e358 = (*barycoord)[1u];
    let _e360 = (*faceIndices)[1u];
    param_535 = bitcast<i32>(_e360);
    let _e362 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_535));
    let _e366 = (*barycoord)[2u];
    let _e368 = (*faceIndices)[2u];
    param_536 = bitcast<i32>(_e368);
    let _e370 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_536));
    return (((_e355 * _e351) + (_e362 * _e358)) + (_e370 * _e366));
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

    let _e355 = (*direction);
    inverseDirection = (vec3(1f) / _e355);
    let _e358 = (*minimum);
    let _e359 = (*origin);
    let _e361 = inverseDirection;
    t0_2 = ((_e358 - _e359) * _e361);
    let _e363 = (*maximum);
    let _e364 = (*origin);
    let _e366 = inverseDirection;
    t1_2 = ((_e363 - _e364) * _e366);
    let _e368 = t0_2;
    let _e369 = t1_2;
    entry = min(_e368, _e369);
    let _e371 = t0_2;
    let _e372 = t1_2;
    exit = max(_e371, _e372);
    let _e375 = entry[0u];
    let _e377 = entry[1u];
    let _e379 = entry[2u];
    nearDistance = max(_e375, max(_e377, _e379));
    let _e383 = exit[0u];
    let _e385 = exit[1u];
    let _e387 = exit[2u];
    farDistance = min(_e383, min(_e385, _e387));
    let _e390 = farDistance;
    let _e391 = nearDistance;
    if (_e390 >= max(_e391, 0f)) {
        let _e394 = nearDistance;
        local_11 = max(_e394, 0f);
    } else {
        local_11 = 100000000000000000000f;
    }
    let _e396 = local_11;
    return _e396;
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
    var phi_1394_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e396 = (*maxDistance);
    closest = _e396;
    found = false;
    loop {
        let _e397 = pointer;
        let _e399 = pointer;
        if ((_e397 >= 0i) && (_e399 < 64i)) {
            let _e402 = pointer;
            pointer = (_e402 - 1i);
            let _e405 = stack[_e402];
            nodeIndex = _e405;
            let _e406 = nodeIndex;
            param_537 = (_e406 * 3i);
            let _e408 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_537));
            minimum_1 = _e408;
            let _e409 = nodeIndex;
            param_538 = ((_e409 * 3i) + 1i);
            let _e412 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_538));
            maximum_1 = _e412;
            let _e413 = nodeIndex;
            param_539 = ((_e413 * 3i) + 2i);
            let _e416 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_539));
            metadata = _e416;
            let _e417 = minimum_1;
            param_540 = _e417.xyz;
            let _e419 = maximum_1;
            param_541 = _e419.xyz;
            let _e421 = (*rayOrigin);
            param_542 = _e421;
            let _e422 = (*rayDirection);
            param_543 = _e422;
            let _e423 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_540), (&param_541), (&param_542), (&param_543));
            let _e424 = closest;
            if (_e423 > _e424) {
                continue;
            }
            let _e427 = metadata[2u];
            if (_e427 > 0.5f) {
                let _e430 = metadata[0u];
                offset = i32((_e430 + 0.5f));
                let _e434 = metadata[1u];
                count = i32((_e434 + 0.5f));
                triangle = 0i;
                loop {
                    let _e437 = triangle;
                    let _e438 = count;
                    if (_e437 < _e438) {
                        let _e440 = offset;
                        let _e441 = triangle;
                        param_544 = (_e440 + _e441);
                        let _e443 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_544));
                        vertexIndices = vec3<u32>((_e443.xyz + vec3(0.5f)));
                        let _e449 = vertexIndices[0u];
                        param_545 = bitcast<i32>(_e449);
                        let _e451 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_545));
                        p0_ = _e451.xyz;
                        let _e454 = vertexIndices[1u];
                        param_546 = bitcast<i32>(_e454);
                        let _e456 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_546));
                        p1_ = _e456.xyz;
                        let _e459 = vertexIndices[2u];
                        param_547 = bitcast<i32>(_e459);
                        let _e461 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_547));
                        p2_ = _e461.xyz;
                        let _e463 = p1_;
                        let _e464 = p0_;
                        edge0_ = (_e463 - _e464);
                        let _e466 = p2_;
                        let _e467 = p0_;
                        edge1_ = (_e466 - _e467);
                        let _e469 = (*rayDirection);
                        let _e470 = edge1_;
                        pvec = cross(_e469, _e470);
                        let _e472 = edge0_;
                        let _e473 = pvec;
                        determinant_ = dot(_e472, _e473);
                        let _e475 = determinant_;
                        if (abs(_e475) < 0.00000001f) {
                            continue;
                        }
                        let _e478 = determinant_;
                        inverseDeterminant = (1f / _e478);
                        let _e480 = (*rayOrigin);
                        let _e481 = p0_;
                        tvec = (_e480 - _e481);
                        let _e483 = tvec;
                        let _e484 = pvec;
                        let _e486 = inverseDeterminant;
                        u = (dot(_e483, _e484) * _e486);
                        let _e488 = tvec;
                        let _e489 = edge0_;
                        qvec = cross(_e488, _e489);
                        let _e491 = (*rayDirection);
                        let _e492 = qvec;
                        let _e494 = inverseDeterminant;
                        v_3 = (dot(_e491, _e492) * _e494);
                        let _e496 = edge1_;
                        let _e497 = qvec;
                        let _e499 = inverseDeterminant;
                        distance_ = (dot(_e496, _e497) * _e499);
                        let _e501 = u;
                        let _e503 = v_3;
                        let _e505 = ((_e501 >= 0f) && (_e503 >= 0f));
                        phi_1394_ = _e505;
                        if _e505 {
                            let _e506 = u;
                            let _e507 = v_3;
                            phi_1394_ = ((_e506 + _e507) <= 1f);
                        }
                        let _e511 = phi_1394_;
                        let _e512 = distance_;
                        let _e515 = distance_;
                        let _e516 = closest;
                        if ((_e511 && (_e512 > 0f)) && (_e515 < _e516)) {
                            let _e519 = distance_;
                            closest = _e519;
                            let _e520 = distance_;
                            (*dist_2) = _e520;
                            let _e521 = u;
                            let _e523 = v_3;
                            let _e525 = u;
                            let _e526 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e521) - _e523), _e525, _e526);
                            let _e528 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e528.x, _e528.y, _e528.z, 0u);
                            let _e533 = edge0_;
                            let _e534 = edge1_;
                            (*faceNormal) = normalize(cross(_e533, _e534));
                            let _e537 = determinant_;
                            (*side) = select(1f, -1f, (_e537 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e540 = triangle;
                        triangle = (_e540 + 1i);
                    }
                }
            } else {
                let _e543 = metadata[0u];
                left = i32((_e543 + 0.5f));
                let _e547 = metadata[1u];
                right = i32((_e547 + 0.5f));
                let _e550 = pointer;
                if ((_e550 + 2i) >= 64i) {
                    continue;
                }
                let _e553 = pointer;
                let _e554 = (_e553 + 1i);
                pointer = _e554;
                let _e555 = right;
                stack[_e554] = _e555;
                let _e557 = pointer;
                let _e558 = (_e557 + 1i);
                pointer = _e558;
                let _e559 = left;
                stack[_e558] = _e559;
            }
            continue;
        } else {
            break;
        }
    }
    let _e561 = found;
    return _e561;
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

    let _e365 = (*rayOrigin_1);
    param_548 = _e365;
    let _e366 = (*rayDirection_1);
    param_549 = _e366;
    let _e367 = (*maxDistance_1);
    param_550 = _e367;
    let _e368 = (*faceIndices_2);
    param_551 = _e368;
    let _e369 = (*faceNormal_1);
    param_552 = _e369;
    let _e370 = (*barycoord_2);
    param_553 = _e370;
    let _e371 = (*side_1);
    param_554 = _e371;
    let _e372 = (*dist_3);
    param_555 = _e372;
    let _e373 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_548), (&param_549), (&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555));
    let _e374 = param_551;
    (*faceIndices_2) = _e374;
    let _e375 = param_552;
    (*faceNormal_1) = _e375;
    let _e376 = param_553;
    (*barycoord_2) = _e376;
    let _e377 = param_554;
    (*side_1) = _e377;
    let _e378 = param_555;
    (*dist_3) = _e378;
    return _e373;
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
    var phi_7329_: bool;
    var phi_7351_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e385 = (*rayOrigin_2);
    param_556 = _e385;
    let _e386 = (*rayDir);
    param_557 = _e386;
    let _e387 = (*maxDistance_2);
    param_558 = _e387;
    let _e388 = faceIndices_surface;
    param_559 = _e388;
    let _e389 = faceNormal_surface;
    param_560 = _e389;
    let _e390 = barycoord_surface;
    param_561 = _e390;
    let _e391 = side_surface;
    param_562 = _e391;
    let _e392 = dist_surface;
    param_563 = _e392;
    let _e393 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_556), (&param_557), (&param_558), (&param_559), (&param_560), (&param_561), (&param_562), (&param_563));
    let _e394 = param_559;
    faceIndices_surface = _e394;
    let _e395 = param_560;
    faceNormal_surface = _e395;
    let _e396 = param_561;
    barycoord_surface = _e396;
    let _e397 = param_562;
    side_surface = _e397;
    let _e398 = param_563;
    dist_surface = _e398;
    hit_surface = _e393;
    dist_closest = 100000000000000000000f;
    let _e399 = hit_surface;
    if _e399 {
        let _e400 = dist_closest;
        let _e401 = dist_surface;
        dist_closest = min(_e400, _e401);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e404 = (*rayDir)[1u];
    if (abs(_e404) > 0.0000000001f) {
        let _e408 = (*rayOrigin_2)[1u];
        let _e411 = (*rayDir)[1u];
        t = ((0.01f - _e408) / _e411);
        let _e413 = t;
        let _e414 = (_e413 > 0f);
        phi_7329_ = _e414;
        if _e414 {
            let _e415 = t;
            let _e416 = dist_closest;
            let _e417 = (*maxDistance_2);
            phi_7329_ = (_e415 < min(_e416, _e417));
        }
        let _e421 = phi_7329_;
        if _e421 {
            let _e422 = t;
            dist_ground = _e422;
            hit_ground = true;
        }
    }
    let _e423 = hit_surface;
    let _e424 = hit_ground;
    hit = (_e423 || _e424);
    let _e426 = hit;
    if !(_e426) {
        return false;
    }
    let _e428 = hit_surface;
    phi_7351_ = _e428;
    if _e428 {
        let _e429 = hit_ground;
        let _e431 = dist_surface;
        let _e432 = dist_ground;
        phi_7351_ = (!(_e429) || (_e431 <= _e432));
    }
    let _e436 = phi_7351_;
    if _e436 {
        let _e437 = (*rayOrigin_2);
        let _e438 = dist_surface;
        let _e439 = (*rayDir);
        (*P_4) = (_e437 + (_e439 * _e438));
        let _e442 = barycoord_surface;
        (*baryCoord) = _e442;
        let _e443 = faceNormal_surface;
        param_564 = _e443;
        let _e444 = safe_normalize_u0028_vf3_u003b((&param_564));
        (*Ng) = _e444;
        let _e445 = barycoord_surface;
        param_565 = _e445;
        let _e446 = faceIndices_surface;
        param_566 = _e446.xyz;
        let _e448 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_565), (&param_566));
        gN = _e448;
        let _e449 = barycoord_surface;
        param_567 = _e449;
        let _e450 = faceIndices_surface;
        param_568 = _e450.xyz;
        let _e452 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_567), (&param_568));
        gT = _e452;
        let _e454 = unnamed.has_normals_surface;
        if (_e454 != 0u) {
            let _e456 = gN;
            local_12 = _e456.xyz;
        } else {
            let _e458 = (*Ng);
            local_12 = _e458;
        }
        let _e459 = local_12;
        (*Ns) = _e459;
        let _e461 = unnamed.has_uvs_surface;
        if (_e461 != 0u) {
            let _e464 = gN[3u];
            let _e466 = gT[3u];
            local_13 = vec2<f32>(_e464, _e466);
        } else {
            let _e468 = barycoord_surface;
            local_13 = _e468.xy;
        }
        let _e470 = local_13;
        (*texCoord) = _e470;
        let _e472 = unnamed.has_tangents_surface;
        if (_e472 != 0u) {
            let _e474 = gT;
            local_14 = _e474.xyz;
        } else {
            let _e476 = (*Ns);
            param_569 = _e476;
            let _e477 = normalToTangent_u0028_vf3_u003b((&param_569));
            local_14 = _e477;
        }
        let _e478 = local_14;
        (*Ts) = _e478;
        let _e479 = barycoord_surface;
        param_570 = _e479;
        let _e480 = faceIndices_surface;
        param_571 = _e480.xyz;
        let _e482 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_570), (&param_571));
        (*surfaceshader_2) = select(1i, 0i, (_e482.x > 0.5f));
    } else {
        let _e486 = hit_ground;
        if _e486 {
            let _e487 = (*rayOrigin_2);
            let _e488 = dist_ground;
            let _e489 = (*rayDir);
            (*P_4) = (_e487 + (_e489 * _e488));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e492 = (*Ng);
            (*Ns) = _e492;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e494 = (*P_4)[0u];
            let _e496 = (*P_4)[2u];
            (*texCoord) = (((vec2<f32>(_e494, -(_e496)) / vec2(200f)) * 2f) + vec2(0.5f));
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
    var phi_7495_: bool;
    var phi_7499_: bool;

    let _e364 = (*rayOrigin_3);
    param_572 = _e364;
    let _e365 = (*rayDir_1);
    param_573 = _e365;
    let _e366 = (*maxDistance_3);
    param_574 = _e366;
    let _e367 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_572), (&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578), (&param_579), (&param_580), (&param_581));
    let _e368 = param_575;
    pW_5 = _e368;
    let _e369 = param_576;
    nsW = _e369;
    let _e370 = param_577;
    ngW = _e370;
    let _e371 = param_578;
    TsW = _e371;
    let _e372 = param_579;
    baryCoord_1 = _e372;
    let _e373 = param_580;
    texCoord_1 = _e373;
    let _e374 = param_581;
    surfaceshader_3 = _e374;
    hit_1 = _e367;
    let _e375 = hit_1;
    let _e376 = surfaceshader_3;
    let _e378 = (_e375 && (_e376 == 1i));
    phi_7495_ = _e378;
    if _e378 {
        let _e379 = mtlx_openpbr_is_opaque_u0028_();
        phi_7495_ = !(_e379);
    }
    let _e382 = phi_7495_;
    phi_7499_ = _e382;
    if _e382 {
        let _e383 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_7499_ = _e383;
    }
    let _e385 = phi_7499_;
    if _e385 {
        return 1f;
    }
    let _e386 = hit_1;
    return select(1f, 0f, _e386);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e345 = (*v_4)[0u];
    let _e347 = (*v_4)[1u];
    let _e349 = (*v_4)[2u];
    return max(_e345, max(_e347, _e349));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e345 = (*vWorld);
    let _e347 = (*basis_5).tW;
    let _e349 = (*vWorld);
    let _e351 = (*basis_5).bW;
    let _e353 = (*vWorld);
    let _e355 = (*basis_5).nW;
    return vec3<f32>(dot(_e345, _e347), dot(_e349, _e351), dot(_e353, _e355));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e346 = (*v_5);
    state = ((_e346 * 747796405u) + 2891336453u);
    let _e349 = state;
    let _e350 = state;
    let _e356 = state;
    word = (((_e349 >> bitcast<u32>(((_e350 >> bitcast<u32>(28u)) + 4u))) ^ _e356) * 277803737u);
    let _e359 = word;
    let _e362 = word;
    return ((_e359 >> bitcast<u32>(22u)) ^ _e362);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_582: u32;

    let _e345 = (*seed);
    param_582 = _e345;
    let _e346 = pcg_u0028_u1_u003b((&param_582));
    (*seed) = _e346;
    let _e347 = (*seed);
    return (f32((_e347 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_4: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e351 = (*i_4);
    let _e353 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e351), 0i);
    t0_3 = _e353;
    let _e354 = (*i_4);
    let _e356 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e354), 0i);
    t1_3 = _e356;
    let _e357 = (*i_4);
    let _e359 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e357), 0i);
    t2_2 = _e359;
    let _e360 = (*i_4);
    let _e362 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e360), 0i);
    t3_2 = _e362;
    let _e363 = (*i_4);
    let _e365 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e363), 0i);
    t4_2 = _e365;
    let _e366 = (*i_4);
    let _e368 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e366), 0i);
    t5_ = _e368;
    let _e369 = t0_3;
    l_1.position = _e369.xyz;
    let _e373 = t0_3[3u];
    l_1.decayRate = _e373;
    let _e375 = t1_3;
    l_1.direction = _e375.xyz;
    let _e379 = t1_3[3u];
    l_1.type_ = i32((_e379 + 0.5f));
    let _e383 = t2_2;
    l_1.color = _e383.xyz;
    let _e387 = t2_2[3u];
    l_1.intensity = _e387;
    let _e390 = t3_2[0u];
    l_1.innerCone = _e390;
    let _e393 = t3_2[1u];
    l_1.outerCone = _e393;
    let _e395 = t4_2;
    l_1.u = _e395.xyz;
    let _e398 = t5_;
    l_1.v = _e398.xyz;
    let _e401 = l_1;
    return _e401;
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

    let _e378 = (*index_1);
    param_583 = _e378;
    let _e379 = GetMtlxLight_u0028_i1_u003b((&param_583));
    l_2 = _e379;
    let _e381 = l_2.color;
    let _e383 = l_2.intensity;
    intensity = (_e381 * _e383);
    (*maxDistance_4) = 100000000000000000000f;
    let _e386 = l_2.type_;
    if (_e386 == 1i) {
        let _e389 = l_2.direction;
        param_584 = -(_e389);
        let _e391 = safe_normalize_u0028_vf3_u003b((&param_584));
        (*woutputW) = _e391;
    } else {
        let _e393 = l_2.type_;
        if (_e393 == 3i) {
            let _e395 = (*rndSeed);
            param_585 = _e395;
            let _e396 = rand_u0028_u1_u003b((&param_585));
            let _e397 = param_585;
            (*rndSeed) = _e397;
            let _e398 = (*rndSeed);
            param_586 = _e398;
            let _e399 = rand_u0028_u1_u003b((&param_586));
            let _e400 = param_586;
            (*rndSeed) = _e400;
            xi = vec2<f32>(_e396, _e399);
            let _e403 = l_2.position;
            let _e405 = xi[0u];
            let _e407 = l_2.u;
            let _e411 = xi[1u];
            let _e413 = l_2.v;
            pointOnLight = ((_e403 + (_e407 * _e405)) + (_e413 * _e411));
            let _e417 = l_2.u;
            let _e419 = l_2.v;
            param_587 = cross(_e417, _e419);
            let _e421 = safe_normalize_u0028_vf3_u003b((&param_587));
            lightNormal = _e421;
            let _e423 = l_2.u;
            let _e425 = l_2.v;
            area = length(cross(_e423, _e425));
            let _e428 = pointOnLight;
            let _e429 = (*pW_6);
            toLight = (_e428 - _e429);
            let _e431 = toLight;
            let _e432 = toLight;
            distSq = max(dot(_e431, _e432), 0.0000000001f);
            let _e435 = distSq;
            distanceToLight = sqrt(_e435);
            let _e437 = toLight;
            let _e438 = distanceToLight;
            (*woutputW) = (_e437 / vec3(_e438));
            let _e441 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e441 - 0.0002f));
            let _e444 = lightNormal;
            let _e445 = (*woutputW);
            cosLight = max(dot(_e444, -(_e445)), 0f);
            let _e449 = cosLight;
            let _e451 = area;
            if ((_e449 <= 0f) || (_e451 <= 0f)) {
                let _e454 = (*woutputW);
                param_588 = _e454;
                let _e455 = (*basis_6);
                param_589 = _e455;
                let _e456 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_588), (&param_589));
                (*woutputL_4) = _e456;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e457 = cosLight;
            let _e458 = area;
            let _e460 = distSq;
            let _e462 = intensity;
            intensity = (_e462 * ((_e457 * _e458) / _e460));
            let _e464 = (*woutputW);
            param_590 = _e464;
            let _e465 = (*basis_6);
            param_591 = _e465;
            let _e466 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_590), (&param_591));
            (*woutputL_4) = _e466;
            let _e467 = intensity;
            return _e467;
        } else {
            let _e469 = l_2.position;
            let _e470 = (*pW_6);
            toLight_1 = (_e469 - _e470);
            let _e472 = toLight_1;
            distanceToLight_1 = max(length(_e472), 0.0000000001f);
            let _e475 = toLight_1;
            let _e476 = distanceToLight_1;
            (*woutputW) = (_e475 / vec3(_e476));
            let _e479 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e479 - 0.0002f));
            let _e482 = distanceToLight_1;
            let _e485 = l_2.decayRate;
            attenuation = pow((_e482 + 1f), (_e485 + 0.0000000001f));
            let _e488 = attenuation;
            let _e490 = intensity;
            intensity = (_e490 / vec3(max(_e488, 0.0000000001f)));
            let _e494 = l_2.type_;
            if (_e494 == 2i) {
                let _e496 = (*woutputW);
                let _e498 = l_2.direction;
                param_592 = _e498;
                let _e499 = safe_normalize_u0028_vf3_u003b((&param_592));
                cosDir = dot(_e496, -(_e499));
                let _e503 = l_2.innerCone;
                let _e505 = l_2.outerCone;
                low = min(_e503, _e505);
                let _e508 = l_2.innerCone;
                high = _e508;
                let _e509 = low;
                let _e510 = high;
                let _e511 = cosDir;
                let _e513 = intensity;
                intensity = (_e513 * smoothstep(_e509, _e510, _e511));
            }
        }
    }
    let _e515 = (*woutputW);
    param_593 = _e515;
    let _e516 = (*basis_6);
    param_594 = _e516;
    let _e517 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_593), (&param_594));
    (*woutputL_4) = _e517;
    let _e518 = intensity;
    return _e518;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_595: i32;
    var power: f32;

    let _e347 = (*index_2);
    param_595 = _e347;
    let _e348 = GetMtlxLight_u0028_i1_u003b((&param_595));
    l_3 = _e348;
    let _e350 = l_3.color;
    let _e352 = l_3.intensity;
    power = length((_e350 * _e352));
    let _e356 = l_3.type_;
    if (_e356 == 3i) {
        let _e359 = l_3.u;
        let _e361 = l_3.v;
        let _e364 = power;
        power = (_e364 * length(cross(_e359, _e361)));
    }
    let _e366 = power;
    return _e366;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e348 = unnamed.sunAngularSize;
    theta_max = ((_e348 * 3.1415927f) / 180f);
    let _e351 = (*woutputW_1);
    let _e353 = unnamed.sunDir;
    let _e355 = theta_max;
    if (dot(_e351, _e353) < cos(_e355)) {
        return 0f;
    }
    let _e358 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e358)));
    let _e362 = solid_angle;
    return (1f / _e362);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e346 = unnamed.sunAngularSize;
    theta_max_1 = ((_e346 * 3.1415927f) / 180f);
    let _e349 = (*woutputW_2);
    let _e351 = unnamed.sunDir;
    let _e353 = theta_max_1;
    if (dot(_e349, _e351) < cos(_e353)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e357 = unnamed.sunPower;
    let _e359 = unnamed.sunColor;
    return (_e359 * _e357);
}

fn envMapLuminance_u0028_vf3_u003b(c_4: ptr<function, vec3<f32>>) -> f32 {
    let _e344 = (*c_4);
    return dot(_e344, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_7: ptr<function, vec3<f32>>) -> f32 {
    var theta_1: f32;
    var s_5: f32;
    var pdf_2: f32;
    var param_596: vec3<f32>;

    let _e350 = (*uv_3)[1u];
    theta_1 = (_e350 * 3.1415927f);
    let _e352 = theta_1;
    s_5 = sin(_e352);
    let _e354 = s_5;
    if (_e354 <= 0f) {
        return 0f;
    }
    let _e356 = (*color_7);
    param_596 = _e356;
    let _e357 = envMapLuminance_u0028_vf3_u003b((&param_596));
    let _e359 = unnamed.envMapTotalSum;
    pdf_2 = (_e357 / max(_e359, 0.0000000001f));
    let _e362 = pdf_2;
    let _e365 = unnamed.envMapRes[0u];
    let _e369 = unnamed.envMapRes[1u];
    let _e371 = s_5;
    return (((_e362 * _e365) * _e369) / (19.739208f * _e371));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_2: f32;
    var s_6: f32;

    let _e348 = (*uv_4)[0u];
    phi_1 = (_e348 * 6.2831855f);
    let _e351 = (*uv_4)[1u];
    theta_2 = (_e351 * 3.1415927f);
    let _e353 = theta_2;
    s_6 = sin(_e353);
    let _e355 = s_6;
    let _e357 = phi_1;
    let _e360 = theta_2;
    let _e362 = s_6;
    let _e364 = phi_1;
    return vec3<f32>((-(_e355) * cos(_e357)), cos(_e360), (-(_e362) * sin(_e364)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_11: i32;

    let _e352 = unnamed.envMapRes;
    res = vec2<i32>(_e352);
    lower = 0i;
    let _e355 = res[1u];
    upper = (_e355 - 1i);
    loop {
        let _e357 = lower;
        let _e358 = upper;
        if (_e357 < _e358) {
            let _e360 = lower;
            let _e361 = upper;
            mid = ((_e360 + _e361) >> bitcast<u32>(1i));
            let _e365 = (*value);
            let _e367 = res[0u];
            let _e369 = mid;
            let _e371 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e367 - 1i), _e369), 0i);
            if (_e365 < _e371.x) {
                let _e374 = mid;
                upper = _e374;
            } else {
                let _e375 = mid;
                lower = (_e375 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e377 = lower;
    let _e379 = res[1u];
    y_5 = clamp(_e377, 0i, (_e379 - 1i));
    lower = 0i;
    let _e383 = res[0u];
    upper = (_e383 - 1i);
    loop {
        let _e385 = lower;
        let _e386 = upper;
        if (_e385 < _e386) {
            let _e388 = lower;
            let _e389 = upper;
            mid_1 = ((_e388 + _e389) >> bitcast<u32>(1i));
            let _e393 = (*value);
            let _e394 = mid_1;
            let _e395 = y_5;
            let _e397 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e394, _e395), 0i);
            if (_e393 < _e397.x) {
                let _e400 = mid_1;
                upper = _e400;
            } else {
                let _e401 = mid_1;
                lower = (_e401 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e403 = lower;
    let _e405 = res[0u];
    x_11 = clamp(_e403, 0i, (_e405 - 1i));
    let _e408 = x_11;
    let _e410 = y_5;
    let _e414 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e408), f32(_e410)) / _e414);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e346 = (*woutputW_3)[0u];
    let _e347 = (*woutputW_3);
    let _e348 = _e347.yz;
    let _e352 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e346, _e348.x, _e348.y), 0f);
    env = _e352;
    let _e353 = env;
    let _e356 = unnamed.skyPower;
    let _e359 = unnamed.skyColor;
    return ((_e353.xyz * _e356) * _e359);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_4: f32;
    var param_597: u32;
    var theta_3: f32;
    var param_598: u32;
    var x_12: f32;
    var y_6: f32;
    var z_1: f32;

    let _e352 = (*rndSeed_1);
    param_597 = _e352;
    let _e353 = rand_u0028_u1_u003b((&param_597));
    let _e354 = param_597;
    (*rndSeed_1) = _e354;
    r_4 = sqrt(_e353);
    let _e356 = (*rndSeed_1);
    param_598 = _e356;
    let _e357 = rand_u0028_u1_u003b((&param_598));
    let _e358 = param_598;
    (*rndSeed_1) = _e358;
    theta_3 = (6.2831855f * _e357);
    let _e360 = r_4;
    let _e361 = theta_3;
    x_12 = (_e360 * cos(_e361));
    let _e364 = r_4;
    let _e365 = theta_3;
    y_6 = (_e364 * sin(_e365));
    let _e368 = x_12;
    let _e369 = x_12;
    let _e372 = y_6;
    let _e373 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e368 * _e369)) - (_e372 * _e373))));
    let _e378 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e378) / 3.1415927f));
    let _e382 = x_12;
    let _e383 = y_6;
    let _e384 = z_1;
    return vec3<f32>(_e382, _e383, _e384);
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

    let _e364 = unnamed.has_env_cdf;
    if !((_e364 != 0u)) {
        let _e367 = (*rndSeed_2);
        param_599 = _e367;
        let _e368 = (*pdfDir);
        param_600 = _e368;
        let _e369 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_599), (&param_600));
        let _e370 = param_599;
        (*rndSeed_2) = _e370;
        let _e371 = param_600;
        (*pdfDir) = _e371;
        (*woutputL_6) = _e369;
        let _e372 = (*woutputL_6);
        param_601 = _e372;
        let _e373 = (*basis_7);
        param_602 = _e373;
        let _e374 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_601), (&param_602));
        (*woutputW_4) = _e374;
        let _e375 = (*woutputW_4);
        param_603 = _e375;
        let _e376 = skyRadiance_u0028_vf3_u003b((&param_603));
        return _e376;
    }
    let _e377 = (*rndSeed_2);
    param_604 = _e377;
    let _e378 = rand_u0028_u1_u003b((&param_604));
    let _e379 = param_604;
    (*rndSeed_2) = _e379;
    let _e381 = unnamed.envMapTotalSum;
    param_605 = (_e378 * max(_e381, 0.0000000001f));
    let _e384 = envMapBinarySearch_u0028_f1_u003b((&param_605));
    uv_5 = _e384;
    let _e385 = uv_5;
    param_606 = _e385;
    let _e386 = envMapUvToDir_u0028_vf2_u003b((&param_606));
    param_607 = _e386;
    let _e387 = safe_normalize_u0028_vf3_u003b((&param_607));
    (*woutputW_4) = _e387;
    let _e388 = (*woutputW_4);
    param_608 = _e388;
    let _e389 = (*basis_7);
    param_609 = _e389;
    let _e390 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_608), (&param_609));
    (*woutputL_6) = _e390;
    let _e391 = uv_5;
    let _e392 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e391, 0f);
    color_8 = _e392.xyz;
    let _e394 = uv_5;
    param_610 = _e394;
    let _e395 = color_8;
    param_611 = _e395;
    let _e396 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_610), (&param_611));
    (*pdfDir) = _e396;
    let _e398 = unnamed.skyPower;
    let _e400 = unnamed.skyColor;
    let _e402 = color_8;
    return ((_e400 * _e398) * _e402);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_4: f32;

    let _e346 = (*d)[1u];
    theta_4 = acos(clamp(_e346, -1f, 1f));
    let _e350 = (*d)[2u];
    let _e352 = (*d)[0u];
    let _e356 = theta_4;
    return vec2<f32>(((3.1415927f + atan2(_e350, _e352)) * 0.15915494f), (_e356 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_612: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_613: vec3<f32>;
    var param_614: vec3<f32>;
    var color_9: vec3<f32>;
    var param_615: vec2<f32>;
    var param_616: vec3<f32>;

    let _e353 = unnamed.has_env_cdf;
    if !((_e353 != 0u)) {
        let _e356 = (*woutputL_7);
        param_612 = _e356;
        let _e357 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_612));
        return _e357;
    }
    let _e358 = (*woutputW_5);
    param_613 = _e358;
    let _e359 = safe_normalize_u0028_vf3_u003b((&param_613));
    param_614 = _e359;
    let _e360 = envMapDirToUv_u0028_vf3_u003b((&param_614));
    uv_6 = _e360;
    let _e361 = uv_6;
    let _e362 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e361, 0f);
    color_9 = _e362.xyz;
    let _e364 = uv_6;
    param_615 = _e364;
    let _e365 = color_9;
    param_616 = _e365;
    let _e366 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_615), (&param_616));
    return _e366;
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

    let _e366 = unnamed.sunAngularSize;
    theta_max_2 = ((_e366 * 3.1415927f) / 180f);
    let _e369 = theta_max_2;
    let _e370 = (*rndSeed_3);
    param_617 = _e370;
    let _e371 = rand_u0028_u1_u003b((&param_617));
    let _e372 = param_617;
    (*rndSeed_3) = _e372;
    theta_5 = (_e369 * sqrt(_e371));
    let _e375 = theta_5;
    costheta = cos(_e375);
    let _e377 = costheta;
    let _e378 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e377 * _e378))));
    let _e383 = (*rndSeed_3);
    param_618 = _e383;
    let _e384 = rand_u0028_u1_u003b((&param_618));
    let _e385 = param_618;
    (*rndSeed_3) = _e385;
    phi_2 = (6.2831855f * _e384);
    let _e387 = phi_2;
    cosphi = cos(_e387);
    let _e389 = phi_2;
    sinphi = sin(_e389);
    let _e391 = sintheta;
    let _e392 = cosphi;
    x_13 = (_e391 * _e392);
    let _e394 = sintheta;
    let _e395 = sinphi;
    y_7 = (_e394 * _e395);
    let _e397 = costheta;
    z_2 = _e397;
    let _e398 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e398)));
    let _e402 = solid_angle_1;
    (*pdfDir_1) = (1f / _e402);
    let _e404 = x_13;
    let _e405 = y_7;
    let _e406 = z_2;
    param_619 = vec3<f32>(_e404, _e405, _e406);
    let _e408 = sunBasis;
    param_620 = _e408;
    let _e409 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_619), (&param_620));
    (*woutputW_6) = _e409;
    let _e410 = (*woutputW_6);
    param_621 = _e410;
    let _e411 = (*basis_8);
    param_622 = _e411;
    let _e412 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_621), (&param_622));
    (*woutputL_8) = _e412;
    let _e414 = unnamed.sunPower;
    let _e416 = unnamed.sunColor;
    let _e418 = solid_angle_1;
    return ((_e416 * _e414) / vec3(_e418));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e344 = unnamed.skyPower;
    let _e346 = unnamed.skyColor;
    return (length((_e346 * _e344)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e344 = unnamed.sunPower;
    let _e346 = unnamed.sunColor;
    return length((_e346 * _e344));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_5: i32;
    var param_623: i32;

    power_1 = 0f;
    i_5 = 0i;
    loop {
        let _e346 = i_5;
        if (_e346 < 1i) {
            let _e348 = i_5;
            let _e350 = unnamed.mtlxLightCount;
            if (_e348 >= _e350) {
                break;
            }
            let _e352 = i_5;
            param_623 = _e352;
            let _e353 = mtlxLightTotalPower_u0028_i1_u003b((&param_623));
            let _e354 = power_1;
            power_1 = (_e354 + _e353);
            continue;
        } else {
            break;
        }
        continuing {
            let _e356 = i_5;
            i_5 = (_e356 + 1i);
        }
    }
    let _e358 = power_1;
    return _e358;
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
    var phi_8547_: bool;

    let _e410 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e410;
    let _e412 = unnamed.mtlxDisableSun;
    let _e413 = (_e412 != 0u);
    phi_8547_ = _e413;
    if !(_e413) {
        let _e416 = unnamed.mtlxLightCount;
        phi_8547_ = (_e416 > 0i);
    }
    let _e419 = phi_8547_;
    if _e419 {
        local_15 = 0f;
    } else {
        let _e420 = sunTotalPower_u0028_();
        local_15 = _e420;
    }
    let _e421 = local_15;
    w_sun = _e421;
    let _e422 = skyTotalPower_u0028_();
    w_sky = _e422;
    let _e423 = w_sun;
    let _e424 = w_sky;
    let _e426 = w_mtlx;
    w_total = max(0.0000000001f, ((_e423 + _e424) + _e426));
    let _e429 = w_sun;
    let _e430 = w_total;
    P_sun = (_e429 / _e430);
    let _e432 = w_sky;
    let _e433 = w_total;
    P_sky = (_e432 / _e433);
    let _e435 = w_mtlx;
    let _e436 = w_total;
    P_mtlx = (_e435 / _e436);
    let _e438 = (*rndSeed_4);
    param_624 = _e438;
    let _e439 = rand_u0028_u1_u003b((&param_624));
    let _e440 = param_624;
    (*rndSeed_4) = _e440;
    r_5 = _e439;
    maxDistance_5 = 100000000000000000000f;
    let _e441 = r_5;
    let _e442 = P_sun;
    if (_e441 < _e442) {
        let _e444 = (*basis_9);
        param_625 = _e444;
        let _e445 = (*shadowL);
        param_626 = _e445;
        let _e446 = (*shadowW);
        param_627 = _e446;
        let _e447 = pdf_sun;
        param_628 = _e447;
        let _e448 = (*rndSeed_4);
        param_629 = _e448;
        let _e449 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_625), (&param_626), (&param_627), (&param_628), (&param_629));
        let _e450 = param_626;
        (*shadowL) = _e450;
        let _e451 = param_627;
        (*shadowW) = _e451;
        let _e452 = param_628;
        pdf_sun = _e452;
        let _e453 = param_629;
        (*rndSeed_4) = _e453;
        Li_7 = _e449;
        let _e454 = (*shadowW);
        param_630 = _e454;
        let _e455 = skyRadiance_u0028_vf3_u003b((&param_630));
        let _e456 = Li_7;
        Li_7 = (_e456 + _e455);
        let _e458 = (*shadowL);
        param_631 = _e458;
        let _e459 = (*shadowW);
        param_632 = _e459;
        let _e460 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_631), (&param_632));
        pdf_sky = _e460;
    } else {
        let _e461 = r_5;
        let _e462 = P_sun;
        let _e463 = P_sky;
        if (_e461 < (_e462 + _e463)) {
            let _e466 = (*basis_9);
            param_633 = _e466;
            let _e467 = (*rndSeed_4);
            param_637 = _e467;
            let _e468 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_633), (&param_634), (&param_635), (&param_636), (&param_637));
            let _e469 = param_634;
            (*shadowL) = _e469;
            let _e470 = param_635;
            (*shadowW) = _e470;
            let _e471 = param_636;
            pdf_sky = _e471;
            let _e472 = param_637;
            (*rndSeed_4) = _e472;
            Li_7 = _e468;
            let _e473 = w_sun;
            if (_e473 > 0f) {
                let _e475 = (*shadowW);
                param_638 = _e475;
                let _e476 = sunRadiance_u0028_vf3_u003b((&param_638));
                let _e477 = Li_7;
                Li_7 = (_e477 + _e476);
            }
            let _e479 = (*shadowL);
            param_639 = _e479;
            let _e480 = (*shadowW);
            param_640 = _e480;
            let _e481 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_639), (&param_640));
            pdf_sun = _e481;
        } else {
            let _e482 = (*rndSeed_4);
            param_641 = _e482;
            let _e483 = rand_u0028_u1_u003b((&param_641));
            let _e484 = param_641;
            (*rndSeed_4) = _e484;
            let _e485 = w_mtlx;
            target_ = (_e483 * max(_e485, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_6 = 0i;
            loop {
                let _e488 = i_6;
                if (_e488 < 1i) {
                    let _e490 = i_6;
                    let _e492 = unnamed.mtlxLightCount;
                    if (_e490 >= _e492) {
                        break;
                    }
                    let _e494 = i_6;
                    param_642 = _e494;
                    let _e495 = mtlxLightTotalPower_u0028_i1_u003b((&param_642));
                    let _e496 = accum;
                    accum = (_e496 + _e495);
                    let _e498 = target_;
                    let _e499 = accum;
                    if (_e498 <= _e499) {
                        let _e501 = i_6;
                        selected = _e501;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e502 = i_6;
                    i_6 = (_e502 + 1i);
                }
            }
            let _e504 = selected;
            param_643 = _e504;
            let _e505 = mtlxLightTotalPower_u0028_i1_u003b((&param_643));
            selectedPower = max(_e505, 0.0000000001f);
            let _e507 = selected;
            param_644 = _e507;
            let _e508 = (*pW_7);
            param_645 = _e508;
            let _e509 = (*basis_9);
            param_646 = _e509;
            let _e510 = (*rndSeed_4);
            param_650 = _e510;
            let _e511 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650));
            let _e512 = param_647;
            (*shadowL) = _e512;
            let _e513 = param_648;
            (*shadowW) = _e513;
            let _e514 = param_649;
            maxDistance_5 = _e514;
            let _e515 = param_650;
            (*rndSeed_4) = _e515;
            Li_7 = _e511;
            let _e516 = (*shadowL);
            param_651 = _e516;
            let _e517 = (*shadowW);
            param_652 = _e517;
            let _e518 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_651), (&param_652));
            pdf_sun = _e518;
            let _e519 = (*shadowL);
            param_653 = _e519;
            let _e520 = (*shadowW);
            param_654 = _e520;
            let _e521 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_653), (&param_654));
            pdf_sky = _e521;
            let _e522 = P_mtlx;
            let _e523 = selectedPower;
            let _e525 = w_mtlx;
            (*lightPdf) = ((_e522 * _e523) / max(_e525, 0.0000000001f));
            let _e529 = (*shadowL)[2u];
            if (_e529 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e531 = Li_7;
            param_655 = _e531;
            let _e532 = maxComponent_u0028_vf3_u003b((&param_655));
            if (_e532 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e534 = (*pW_7);
            let _e536 = (*basis_9).nW;
            let _e537 = (*shadowW);
            let _e539 = (*basis_9).nW;
            shadowOrigin = (_e534 + ((_e536 * sign(dot(_e537, _e539))) * 0.0001f));
            let _e545 = shadowOrigin;
            param_656 = _e545;
            let _e546 = (*shadowW);
            param_657 = _e546;
            let _e547 = maxDistance_5;
            param_658 = _e547;
            let _e548 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_656), (&param_657), (&param_658));
            visibility = _e548;
            let _e549 = visibility;
            let _e550 = Li_7;
            return (_e550 * _e549);
        }
    }
    let _e552 = P_sun;
    let _e553 = pdf_sun;
    let _e555 = P_sky;
    let _e556 = pdf_sky;
    (*lightPdf) = ((_e552 * _e553) + (_e555 * _e556));
    let _e560 = (*shadowL)[2u];
    if (_e560 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e562 = Li_7;
    param_659 = _e562;
    let _e563 = maxComponent_u0028_vf3_u003b((&param_659));
    if (_e563 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e565 = (*pW_7);
    let _e567 = (*basis_9).nW;
    let _e568 = (*shadowW);
    let _e570 = (*basis_9).nW;
    shadowOrigin_1 = (_e565 + ((_e567 * sign(dot(_e568, _e570))) * 0.0001f));
    let _e576 = shadowOrigin_1;
    param_660 = _e576;
    let _e577 = (*shadowW);
    param_661 = _e577;
    param_662 = 100000000000000000000f;
    let _e578 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_660), (&param_661), (&param_662));
    visibility_1 = _e578;
    let _e579 = visibility_1;
    let _e580 = Li_7;
    return (_e580 * _e579);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_663: vec3<f32>;
    var param_664: Basis;

    let _e349 = (*pW_8);
    g_ptP = _e349;
    let _e351 = (*basis_10).nW;
    g_ptN = _e351;
    let _e353 = (*basis_10).tW;
    g_ptTangent = _e353;
    let _e355 = (*basis_10).bW;
    g_ptBitangent = _e355;
    let _e357 = (*basis_10).texCoord;
    g_ptTexcoord = _e357;
    let _e358 = (*winputL_4);
    param_663 = _e358;
    let _e359 = (*basis_10);
    param_664 = _e359;
    let _e360 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_663), (&param_664));
    g_ptV = _e360;
    let _e362 = (*basis_10).nW;
    g_ptL = _e362;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e363 = opacity_1;
    g_ptOpacity = clamp(dot(_e363, vec3<f32>(0.2126f, 0.7152f, 0.0722f)), 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e366 = mtlxHostEvalSurface_u0028_();
    let _e367 = (*rndSeed_5);
    (*rndSeed_5) = (_e367 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_665: vec3<f32>;
    var param_666: Basis;
    var param_667: vec3<f32>;
    var param_668: u32;

    emissionSeed = 0u;
    let _e350 = (*pW_9);
    param_665 = _e350;
    let _e351 = (*basis_11);
    param_666 = _e351;
    param_667 = vec3<f32>(0f, 0f, 1f);
    let _e352 = emissionSeed;
    param_668 = _e352;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_665), (&param_666), (&param_667), (&param_668));
    let _e353 = param_668;
    emissionSeed = _e353;
    let _e354 = g_ptEmission;
    return max(_e354, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_669: vec3<f32>;
    var param_670: Basis;

    let _e348 = (*pW_10);
    param_669 = _e348;
    let _e349 = (*basis_12);
    param_670 = _e349;
    let _e350 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_669), (&param_670));
    return _e350;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_671: u32;
    var param_672: f32;
    var param_673: vec3<f32>;
    var phi_7568_: bool;

    let _e353 = (*winputL_6)[2u];
    if (_e353 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e355 = (*rndSeed_6);
    param_671 = _e355;
    let _e356 = (*pdf_woutputL_4);
    param_672 = _e356;
    let _e357 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_671), (&param_672));
    let _e358 = param_671;
    (*rndSeed_6) = _e358;
    let _e359 = param_672;
    (*pdf_woutputL_4) = _e359;
    (*woutputL_9) = _e357;
    let _e361 = unnamed.wireframe;
    let _e362 = (_e361 != 0u);
    phi_7568_ = _e362;
    if _e362 {
        let _e364 = (*basis_13).baryCoord;
        param_673 = _e364;
        let _e365 = minComponent_u0028_vf3_u003b((&param_673));
        phi_7568_ = (_e365 < 0.003f);
    }
    let _e368 = phi_7568_;
    if _e368 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e370 = unnamed.neutral_color;
    return (_e370 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_674: u32;
    var param_675: f32;
    var param_676: vec3<f32>;

    let _e353 = (*winputL_7)[2u];
    if (_e353 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e355 = (*rndSeed_7);
    param_674 = _e355;
    let _e356 = (*pdf_woutputL_5);
    param_675 = _e356;
    let _e357 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_674), (&param_675));
    let _e358 = param_674;
    (*rndSeed_7) = _e358;
    let _e359 = param_675;
    (*pdf_woutputL_5) = _e359;
    (*woutputL_10) = _e357;
    let _e360 = (*pW_12);
    param_676 = _e360;
    let _e361 = ground_albedo_u0028_vf3_u003b((&param_676));
    return (_e361 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e347 = (*w_1)[2u];
    if (abs(_e347) < 0.00000011920929f) {
        return 0f;
    }
    let _e350 = (*alpha_x);
    let _e352 = (*w_1)[0u];
    let _e354 = (*alpha_x);
    let _e356 = (*w_1)[0u];
    let _e359 = (*alpha_y);
    let _e361 = (*w_1)[1u];
    let _e363 = (*alpha_y);
    let _e365 = (*w_1)[1u];
    let _e370 = (*w_1)[2u];
    let _e372 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e350 * _e352) * (_e354 * _e356)) + ((_e359 * _e361) * (_e363 * _e365))) / (_e370 * _e372))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_677: vec3<f32>;
    var param_678: f32;
    var param_679: f32;
    var param_680: vec3<f32>;
    var param_681: f32;
    var param_682: f32;

    let _e353 = (*woL);
    param_677 = _e353;
    let _e354 = (*alpha_x_1);
    param_678 = _e354;
    let _e355 = (*alpha_y_1);
    param_679 = _e355;
    let _e356 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_677), (&param_678), (&param_679));
    let _e358 = (*wiL_1);
    param_680 = _e358;
    let _e359 = (*alpha_x_1);
    param_681 = _e359;
    let _e360 = (*alpha_y_1);
    param_682 = _e360;
    let _e361 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_680), (&param_681), (&param_682));
    return (1f / ((1f + _e356) + _e361));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e349 = (*alpha_x_2);
    ax = max(_e349, 0.0000000001f);
    let _e351 = (*alpha_y_2);
    ay = max(_e351, 0.0000000001f);
    let _e353 = ax;
    let _e355 = ay;
    let _e358 = (*m_5)[0u];
    let _e359 = ax;
    let _e362 = (*m_5)[0u];
    let _e363 = ax;
    let _e367 = (*m_5)[1u];
    let _e368 = ay;
    let _e371 = (*m_5)[1u];
    let _e372 = ay;
    let _e377 = (*m_5)[2u];
    let _e379 = (*m_5)[2u];
    let _e383 = (*m_5)[0u];
    let _e384 = ax;
    let _e387 = (*m_5)[0u];
    let _e388 = ax;
    let _e392 = (*m_5)[1u];
    let _e393 = ay;
    let _e396 = (*m_5)[1u];
    let _e397 = ay;
    let _e402 = (*m_5)[2u];
    let _e404 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e353) * _e355) * (((((_e358 / _e359) * (_e362 / _e363)) + ((_e367 / _e368) * (_e371 / _e372))) + (_e377 * _e379)) * ((((_e383 / _e384) * (_e387 / _e388)) + ((_e392 / _e393) * (_e396 / _e397))) + (_e402 * _e404))));
    let _e409 = Ddenom;
    return (1f / max(_e409, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_683: vec3<f32>;
    var param_684: f32;
    var param_685: f32;

    let _e349 = (*w_2);
    param_683 = _e349;
    let _e350 = (*alpha_x_3);
    param_684 = _e350;
    let _e351 = (*alpha_y_3);
    param_685 = _e351;
    let _e352 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_683), (&param_684), (&param_685));
    return (1f / (1f + _e352));
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

    let _e359 = (*rndSeed_8);
    param_686 = _e359;
    let _e360 = rand_u0028_u1_u003b((&param_686));
    let _e361 = param_686;
    (*rndSeed_8) = _e361;
    let _e362 = (*rndSeed_8);
    param_687 = _e362;
    let _e363 = rand_u0028_u1_u003b((&param_687));
    let _e364 = param_687;
    (*rndSeed_8) = _e364;
    Xi_2 = vec2<f32>(_e360, _e363);
    let _e366 = (*wiL_2);
    V_15 = _e366;
    let _e367 = (*alpha_x_4);
    let _e368 = (*alpha_y_4);
    alpha_12 = vec2<f32>(_e367, _e368);
    let _e370 = V_15;
    let _e372 = alpha_12;
    let _e373 = (_e370.xy * _e372);
    let _e375 = V_15[2u];
    V_15 = normalize(vec3<f32>(_e373.x, _e373.y, _e375));
    let _e381 = Xi_2[0u];
    phi_3 = (6.2831855f * _e381);
    let _e384 = Xi_2[1u];
    let _e387 = V_15[2u];
    let _e391 = V_15[2u];
    z_3 = (((1f - _e384) * (1f + _e387)) - _e391);
    let _e393 = z_3;
    let _e394 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e393 * _e394)), 0f, 1f));
    let _e399 = sinTheta_1;
    let _e400 = phi_3;
    x_14 = (_e399 * cos(_e400));
    let _e403 = sinTheta_1;
    let _e404 = phi_3;
    y_8 = (_e403 * sin(_e404));
    let _e407 = x_14;
    let _e408 = y_8;
    let _e409 = z_3;
    c_5 = vec3<f32>(_e407, _e408, _e409);
    let _e411 = c_5;
    let _e412 = V_15;
    H_7 = (_e411 + _e412);
    let _e414 = H_7;
    let _e416 = alpha_12;
    let _e417 = (_e414.xy * _e416);
    let _e419 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e417.x, _e417.y, _e419));
    let _e424 = H_7;
    return _e424;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_6: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e348 = (*mui);
    c_6 = _e348;
    let _e349 = (*eta_ti);
    let _e350 = (*eta_ti);
    let _e352 = c_6;
    let _e353 = c_6;
    mut2_ = (((_e349 * _e350) + (_e352 * _e353)) - 1f);
    let _e357 = mut2_;
    if (_e357 <= 0f) {
        return 1f;
    }
    let _e359 = mut2_;
    g_1 = sqrt(_e359);
    let _e361 = g_1;
    let _e362 = c_6;
    let _e364 = g_1;
    let _e365 = c_6;
    let _e368 = g_1;
    let _e369 = c_6;
    let _e371 = g_1;
    let _e372 = c_6;
    let _e377 = g_1;
    let _e378 = c_6;
    let _e380 = c_6;
    let _e383 = g_1;
    let _e384 = c_6;
    let _e386 = c_6;
    let _e390 = g_1;
    let _e391 = c_6;
    let _e393 = c_6;
    let _e396 = g_1;
    let _e397 = c_6;
    let _e399 = c_6;
    return ((0.5f * (((_e361 - _e362) / (_e364 + _e365)) * ((_e368 - _e369) / (_e371 + _e372)))) * (1f + (((((_e377 + _e378) * _e380) - 1f) / (((_e383 - _e384) * _e386) + 1f)) * ((((_e390 + _e391) * _e393) - 1f) / (((_e396 - _e397) * _e399) + 1f)))));
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
    var phi_6762_: bool;
    var phi_6902_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e497 = metalness_1;
    m_metal = clamp(_e497, 0f, 1f);
    let _e499 = specular_roughness_1;
    m_rough = clamp(_e499, 0f, 1f);
    let _e501 = specular_anisotropy_1;
    m_aniso = clamp(_e501, 0f, 0.99f);
    let _e503 = base_color_1;
    let _e504 = base_3;
    m_base = (_e503 * _e504);
    let _e506 = specular_color_1;
    m_specC = _e506;
    let _e507 = specular_1;
    m_specW = _e507;
    let _e508 = specular_IOR_1;
    m_ior = max(_e508, 1.001f);
    let _e510 = coat_1;
    m_coatW = clamp(_e510, 0f, 1f);
    let _e512 = coat_roughness_1;
    m_coatRough = clamp(_e512, 0f, 1f);
    let _e514 = coat_anisotropy_1;
    m_coatAniso = clamp(_e514, 0f, 0.99f);
    let _e516 = coat_IOR_1;
    m_coatIor = max(_e516, 1.001f);
    let _e518 = (*winputL_8);
    V_16 = _e518;
    let _e520 = V_16[2u];
    if (_e520 < 0f) {
        let _e522 = V_16;
        V_16 = -(_e522);
    }
    let _e525 = V_16[2u];
    NdotV_21 = max(_e525, 0.0001f);
    let _e527 = m_rough;
    let _e528 = m_rough;
    alpha_13 = clamp((_e527 * _e528), 0.0001f, 1f);
    let _e531 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e531));
    let _e534 = alpha_13;
    let _e535 = anisoAspect;
    let _e536 = anisoAspect;
    let _e542 = alpha_13;
    let _e543 = anisoAspect;
    let _e545 = anisoAspect;
    let _e546 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e534 * sqrt((2f / ((_e535 * _e536) + 1f)))), ((_e542 * _e543) * sqrt((2f / ((_e545 * _e546) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e554 = m_coatRough;
    let _e555 = m_coatRough;
    coatAlpha = clamp((_e554 * _e555), 0.0001f, 1f);
    let _e558 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e558));
    let _e561 = coatAlpha;
    let _e562 = coatAnisoAspect;
    let _e563 = coatAnisoAspect;
    let _e569 = coatAlpha;
    let _e570 = coatAnisoAspect;
    let _e572 = coatAnisoAspect;
    let _e573 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e561 * sqrt((2f / ((_e562 * _e563) + 1f)))), ((_e569 * _e570) * sqrt((2f / ((_e572 * _e573) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e581 = m_ior;
    let _e583 = m_ior;
    F0d = pow(((_e581 - 1f) / (_e583 + 1f)), 2f);
    let _e587 = F0d;
    let _e589 = m_specC;
    let _e592 = m_specW;
    let _e594 = m_base;
    let _e595 = m_metal;
    F0_7 = mix(((vec3(_e587) * max(_e589, vec3<f32>(0f, 0f, 0f))) * _e592), _e594, vec3(_e595));
    let _e599 = F0_7[0u];
    let _e601 = F0_7[1u];
    let _e603 = F0_7[2u];
    F0lum = max(_e599, max(_e601, _e603));
    let _e606 = F0lum;
    let _e607 = F0lum;
    let _e609 = NdotV_21;
    Fv = (_e606 + ((1f - _e607) * pow((1f - _e609), 5f)));
    let _e614 = NdotV_21;
    param_688 = _e614;
    let _e615 = m_coatIor;
    param_689 = _e615;
    let _e616 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_688), (&param_689));
    coatFv = _e616;
    let _e617 = m_coatW;
    let _e618 = coatFv;
    pCoat = clamp((_e617 * _e618), 0f, 0.75f);
    let _e621 = (*rndSeed_9);
    param_690 = _e621;
    let _e622 = rand_u0028_u1_u003b((&param_690));
    let _e623 = param_690;
    (*rndSeed_9) = _e623;
    xiLobe = _e622;
    pTrans = 0f;
    let _e624 = transmission_1;
    m_transW = clamp(_e624, 0f, 1f);
    let _e626 = transmission_color_1;
    m_transC = _e626;
    let _e627 = transmission_depth_1;
    m_transD = _e627;
    let _e628 = m_transW;
    let _e629 = Fv;
    pTrans = clamp((_e628 * (1f - _e629)), 0f, 0.95f);
    let _e633 = xiLobe;
    let _e634 = pCoat;
    if (_e633 < _e634) {
        let _e636 = V_16;
        param_691 = _e636;
        let _e638 = coatSampleAlpha[0u];
        param_692 = _e638;
        let _e640 = coatSampleAlpha[1u];
        param_693 = _e640;
        let _e641 = (*rndSeed_9);
        param_694 = _e641;
        let _e642 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_691), (&param_692), (&param_693), (&param_694));
        let _e643 = param_694;
        (*rndSeed_9) = _e643;
        Hc = _e642;
        let _e644 = V_16;
        let _e646 = Hc;
        (*woutputL_11) = reflect(-(_e644), _e646);
        let _e649 = (*woutputL_11)[2u];
        if (_e649 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e651 = V_16;
        param_695 = _e651;
        let _e653 = coatSampleAlpha[0u];
        param_696 = _e653;
        let _e655 = coatSampleAlpha[1u];
        param_697 = _e655;
        let _e656 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_695), (&param_696), (&param_697));
        let _e657 = V_16;
        let _e658 = (*woutputL_11);
        param_698 = normalize((_e657 + _e658));
        let _e662 = coatSampleAlpha[0u];
        param_699 = _e662;
        let _e664 = coatSampleAlpha[1u];
        param_700 = _e664;
        let _e665 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_698), (&param_699), (&param_700));
        let _e667 = NdotV_21;
        pdfCoat = ((_e656 * _e665) / (4f * _e667));
        let _e670 = V_16;
        param_701 = _e670;
        let _e672 = sampleAlpha[0u];
        param_702 = _e672;
        let _e674 = sampleAlpha[1u];
        param_703 = _e674;
        let _e675 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_701), (&param_702), (&param_703));
        let _e676 = V_16;
        let _e677 = (*woutputL_11);
        param_704 = normalize((_e676 + _e677));
        let _e681 = sampleAlpha[0u];
        param_705 = _e681;
        let _e683 = sampleAlpha[1u];
        param_706 = _e683;
        let _e684 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_704), (&param_705), (&param_706));
        let _e686 = NdotV_21;
        pdfBaseSpec = ((_e675 * _e684) / (4f * _e686));
        let _e689 = (*woutputL_11);
        param_707 = _e689;
        let _e690 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_707));
        pdfBaseDiff = _e690;
        let _e691 = m_metal;
        let _e693 = m_base;
        diffLumCoat = ((1f - _e691) * dot(_e693, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e696 = Fv;
        let _e697 = Fv;
        let _e698 = Fv;
        let _e700 = diffLumCoat;
        pSpecCoat = clamp((_e696 / ((_e697 + ((1f - _e698) * _e700)) + 0.001f)), 0.05f, 0.95f);
        let _e706 = pCoat;
        let _e707 = pdfCoat;
        let _e709 = pCoat;
        let _e711 = pTrans;
        let _e714 = pSpecCoat;
        let _e715 = pdfBaseSpec;
        let _e717 = pSpecCoat;
        let _e719 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e706 * _e707) + (((1f - _e709) * (1f - _e711)) * ((_e714 * _e715) + ((1f - _e717) * _e719)))), 0.000001f);
        let _e725 = (*pW_13);
        param_708 = _e725;
        let _e726 = (*basis_15);
        param_709 = _e726;
        let _e727 = (*winputL_8);
        param_710 = _e727;
        let _e728 = (*woutputL_11);
        param_711 = _e728;
        let _e729 = ignorePdfCoat;
        param_712 = _e729;
        let _e730 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_708), (&param_709), (&param_710), (&param_711), (&param_712));
        let _e731 = param_712;
        ignorePdfCoat = _e731;
        return _e730;
    }
    let _e732 = xiLobe;
    let _e733 = pCoat;
    let _e734 = pCoat;
    let _e736 = pTrans;
    if (_e732 < (_e733 + ((1f - _e734) * _e736))) {
        let _e741 = (*winputL_8)[2u];
        externalTransmission = (_e741 > 0f);
        let _e743 = externalTransmission;
        if _e743 {
            let _e744 = m_ior;
            local_16 = (1f / _e744);
        } else {
            let _e746 = m_ior;
            local_16 = _e746;
        }
        let _e747 = local_16;
        etaRatio = _e747;
        let _e748 = alpha_13;
        if (_e748 <= 0.001f) {
            let _e750 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e750));
            let _e753 = Hdelta;
            let _e754 = (*winputL_8);
            HdotWiDelta = dot(_e753, _e754);
            let _e756 = etaRatio;
            let _e757 = etaRatio;
            let _e759 = HdotWiDelta;
            let _e760 = HdotWiDelta;
            discrDelta = (1f - ((_e756 * _e757) * (1f - (_e759 * _e760))));
            let _e765 = discrDelta;
            if (_e765 < 0f) {
                let _e767 = (*winputL_8);
                let _e769 = (*winputL_8);
                let _e770 = Hdelta;
                let _e773 = Hdelta;
                (*woutputL_11) = (-(_e767) + (_e773 * (2f * dot(_e769, _e770))));
                let _e776 = pCoat;
                let _e778 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e776) * _e778), 0.000001f);
                let _e781 = m_transW;
                let _e782 = (*pdf_woutputL_6);
                let _e785 = (*woutputL_11)[2u];
                return vec3(((_e781 * _e782) / max(abs(_e785), 0.0000000001f)));
            }
            let _e790 = etaRatio;
            let _e791 = (*winputL_8);
            let _e793 = Hdelta;
            let _e794 = HdotWiDelta;
            let _e797 = etaRatio;
            let _e798 = HdotWiDelta;
            let _e801 = discrDelta;
            beamIncidentDelta = ((_e791 * _e790) - ((_e793 * sign(_e794)) * ((_e797 * abs(_e798)) - sqrt(_e801))));
            let _e806 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e806));
            let _e810 = (*winputL_8)[2u];
            let _e812 = (*woutputL_11)[2u];
            if ((_e810 * _e812) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e815 = m_transD;
            let _e816 = (_e815 > 0f);
            phi_6762_ = _e816;
            if _e816 {
                let _e817 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_6762_ = !(_e817);
            }
            let _e820 = phi_6762_;
            if _e820 {
                let _e821 = m_transC;
                let _e825 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e821))) / vec3(_e825));
                let _e829 = transmission_scatter_1;
                (*internal_medium).albedo = clamp(_e829, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e832 = transmission_scatter_anisotropy_1;
                (*internal_medium).anisotropy = clamp(_e832, -0.99f, 0.99f);
            }
            let _e835 = HdotWiDelta;
            let _e837 = etaRatio;
            param_713 = abs(_e835);
            param_714 = (1f / _e837);
            let _e839 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_713), (&param_714));
            Tdelta = clamp((1f - _e839), 0f, 1f);
            let _e842 = m_transD;
            let _e844 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e844, (_e842 == 0f));
            let _e846 = pCoat;
            let _e848 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e846) * _e848), 0.000001f);
            let _e851 = m_transW;
            let _e852 = tintDelta;
            let _e854 = Tdelta;
            let _e856 = (*pdf_woutputL_6);
            let _e859 = (*woutputL_11)[2u];
            return ((((_e852 * _e851) * _e854) * _e856) / vec3(max(abs(_e859), 0.0000000001f)));
        }
        let _e864 = (*winputL_8);
        Vsample = _e864;
        let _e866 = Vsample[2u];
        if (_e866 < 0f) {
            let _e869 = Vsample[2u];
            Vsample[2u] = (_e869 * -1f);
        }
        let _e872 = Vsample;
        param_715 = _e872;
        let _e874 = sampleAlpha[0u];
        param_716 = _e874;
        let _e876 = sampleAlpha[1u];
        param_717 = _e876;
        let _e877 = (*rndSeed_9);
        param_718 = _e877;
        let _e878 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_715), (&param_716), (&param_717), (&param_718));
        let _e879 = param_718;
        (*rndSeed_9) = _e879;
        Ht_2 = _e878;
        let _e881 = (*winputL_8)[2u];
        if (_e881 < 0f) {
            let _e884 = Ht_2[2u];
            Ht_2[2u] = (_e884 * -1f);
        }
        let _e887 = Ht_2;
        let _e888 = (*winputL_8);
        HdotWi = dot(_e887, _e888);
        let _e890 = etaRatio;
        let _e891 = etaRatio;
        let _e893 = HdotWi;
        let _e894 = HdotWi;
        discr = (1f - ((_e890 * _e891) * (1f - (_e893 * _e894))));
        let _e899 = discr;
        if (_e899 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e901 = etaRatio;
        let _e902 = (*winputL_8);
        let _e904 = Ht_2;
        let _e905 = HdotWi;
        let _e908 = etaRatio;
        let _e909 = HdotWi;
        let _e912 = discr;
        beamIncident = ((_e902 * _e901) - ((_e904 * sign(_e905)) * ((_e908 * abs(_e909)) - sqrt(_e912))));
        let _e917 = beamIncident;
        (*woutputL_11) = -(normalize(_e917));
        let _e921 = (*winputL_8)[2u];
        let _e923 = (*woutputL_11)[2u];
        if ((_e921 * _e923) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e926 = m_transD;
        let _e927 = (_e926 > 0f);
        phi_6902_ = _e927;
        if _e927 {
            let _e928 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_6902_ = !(_e928);
        }
        let _e931 = phi_6902_;
        if _e931 {
            let _e932 = m_transC;
            let _e936 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e932))) / vec3(_e936));
            let _e940 = transmission_scatter_1;
            (*internal_medium).albedo = clamp(_e940, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e943 = transmission_scatter_anisotropy_1;
            (*internal_medium).anisotropy = clamp(_e943, -0.99f, 0.99f);
        }
        let _e946 = V_16;
        let _e947 = m_ior;
        let _e948 = (*woutputL_11);
        Hr = normalize(-((_e946 + (_e948 * _e947))));
        let _e954 = Hr[2u];
        if (_e954 < 0f) {
            let _e956 = Hr;
            Hr = -(_e956);
        }
        let _e958 = (*winputL_8);
        let _e959 = Ht_2;
        VoH = abs(dot(_e958, _e959));
        let _e962 = (*woutputL_11);
        let _e963 = Ht_2;
        LoH = abs(dot(_e962, _e963));
        let _e966 = LoH;
        let _e967 = etaRatio;
        let _e968 = VoH;
        denomT = (_e966 + (_e967 * _e968));
        let _e971 = etaRatio;
        let _e972 = etaRatio;
        let _e974 = VoH;
        let _e976 = denomT;
        let _e977 = denomT;
        jacT = (((_e971 * _e972) * _e974) / max((_e976 * _e977), 0.00000001f));
        let _e981 = Vsample;
        param_719 = _e981;
        let _e983 = sampleAlpha[0u];
        param_720 = _e983;
        let _e985 = sampleAlpha[1u];
        param_721 = _e985;
        let _e986 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_719), (&param_720), (&param_721));
        let _e987 = VoH;
        let _e990 = Ht_2[2u];
        if (abs(_e990) > 0f) {
            let _e994 = Ht_2[0u];
            let _e996 = Ht_2[1u];
            let _e998 = Ht_2[2u];
            local_17 = vec3<f32>(_e994, _e996, abs(_e998));
        } else {
            let _e1001 = Ht_2;
            local_17 = _e1001;
        }
        let _e1002 = local_17;
        param_722 = _e1002;
        let _e1004 = sampleAlpha[0u];
        param_723 = _e1004;
        let _e1006 = sampleAlpha[1u];
        param_724 = _e1006;
        let _e1007 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_722), (&param_723), (&param_724));
        let _e1010 = (*winputL_8)[2u];
        DvT = (((_e986 * _e987) * _e1007) / max(abs(_e1010), 0.0001f));
        let _e1014 = pCoat;
        let _e1016 = pTrans;
        let _e1018 = DvT;
        let _e1020 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e1014) * _e1016) * _e1018) * _e1020), 0.000001f);
        let _e1024 = Ht_2[2u];
        if (abs(_e1024) > 0f) {
            let _e1028 = Ht_2[0u];
            let _e1030 = Ht_2[1u];
            let _e1032 = Ht_2[2u];
            local_18 = vec3<f32>(_e1028, _e1030, abs(_e1032));
        } else {
            let _e1035 = Ht_2;
            local_18 = _e1035;
        }
        let _e1036 = local_18;
        param_725 = _e1036;
        let _e1038 = sampleAlpha[0u];
        param_726 = _e1038;
        let _e1040 = sampleAlpha[1u];
        param_727 = _e1040;
        let _e1041 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_725), (&param_726), (&param_727));
        D_3 = _e1041;
        let _e1042 = (*winputL_8);
        param_728 = _e1042;
        let _e1043 = (*woutputL_11);
        param_729 = _e1043;
        let _e1045 = sampleAlpha[0u];
        param_730 = _e1045;
        let _e1047 = sampleAlpha[1u];
        param_731 = _e1047;
        let _e1048 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_728), (&param_729), (&param_730), (&param_731));
        G2_ = _e1048;
        let _e1049 = etaRatio;
        etaRefl = (1f / _e1049);
        let _e1051 = VoH;
        param_732 = _e1051;
        let _e1052 = etaRefl;
        param_733 = _e1052;
        let _e1053 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_732), (&param_733));
        T_1 = clamp((1f - _e1053), 0f, 1f);
        let _e1056 = m_transD;
        let _e1058 = m_transC;
        tint_3 = select(vec3<f32>(1f, 1f, 1f), _e1058, (_e1056 == 0f));
        let _e1060 = m_transW;
        let _e1061 = tint_3;
        let _e1063 = T_1;
        let _e1065 = VoH;
        let _e1067 = jacT;
        let _e1069 = D_3;
        let _e1071 = G2_;
        let _e1074 = (*woutputL_11)[2u];
        let _e1077 = (*winputL_8)[2u];
        return (((((((_e1061 * _e1060) * _e1063) * _e1065) * _e1067) * _e1069) * _e1071) / vec3(max((abs(_e1074) * abs(_e1077)), 0.0000000001f)));
    }
    let _e1083 = m_metal;
    let _e1085 = m_base;
    diffLum = ((1f - _e1083) * dot(_e1085, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1088 = Fv;
    let _e1089 = Fv;
    let _e1090 = Fv;
    let _e1092 = diffLum;
    pSpec = clamp((_e1088 / ((_e1089 + ((1f - _e1090) * _e1092)) + 0.001f)), 0.05f, 0.95f);
    let _e1098 = (*rndSeed_9);
    param_734 = _e1098;
    let _e1099 = rand_u0028_u1_u003b((&param_734));
    let _e1100 = param_734;
    (*rndSeed_9) = _e1100;
    let _e1101 = pSpec;
    if (_e1099 < _e1101) {
        let _e1103 = V_16;
        param_735 = _e1103;
        let _e1105 = sampleAlpha[0u];
        param_736 = _e1105;
        let _e1107 = sampleAlpha[1u];
        param_737 = _e1107;
        let _e1108 = (*rndSeed_9);
        param_738 = _e1108;
        let _e1109 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_735), (&param_736), (&param_737), (&param_738));
        let _e1110 = param_738;
        (*rndSeed_9) = _e1110;
        H_8 = _e1109;
        let _e1111 = V_16;
        let _e1113 = H_8;
        (*woutputL_11) = reflect(-(_e1111), _e1113);
    } else {
        let _e1115 = (*rndSeed_9);
        param_739 = _e1115;
        let _e1116 = pdfTmp;
        param_740 = _e1116;
        let _e1117 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_739), (&param_740));
        let _e1118 = param_739;
        (*rndSeed_9) = _e1118;
        let _e1119 = param_740;
        pdfTmp = _e1119;
        (*woutputL_11) = _e1117;
    }
    let _e1121 = (*woutputL_11)[2u];
    if (_e1121 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1123 = V_16;
    let _e1124 = (*woutputL_11);
    Hh = normalize((_e1123 + _e1124));
    let _e1127 = V_16;
    param_741 = _e1127;
    let _e1129 = sampleAlpha[0u];
    param_742 = _e1129;
    let _e1131 = sampleAlpha[1u];
    param_743 = _e1131;
    let _e1132 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_741), (&param_742), (&param_743));
    let _e1133 = Hh;
    param_744 = _e1133;
    let _e1135 = sampleAlpha[0u];
    param_745 = _e1135;
    let _e1137 = sampleAlpha[1u];
    param_746 = _e1137;
    let _e1138 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_744), (&param_745), (&param_746));
    let _e1140 = NdotV_21;
    pdfSpec = ((_e1132 * _e1138) / (4f * _e1140));
    let _e1143 = (*woutputL_11);
    param_747 = _e1143;
    let _e1144 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_747));
    pdfDiff = _e1144;
    let _e1145 = V_16;
    param_748 = _e1145;
    let _e1147 = coatSampleAlpha[0u];
    param_749 = _e1147;
    let _e1149 = coatSampleAlpha[1u];
    param_750 = _e1149;
    let _e1150 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_748), (&param_749), (&param_750));
    let _e1151 = Hh;
    param_751 = _e1151;
    let _e1153 = coatSampleAlpha[0u];
    param_752 = _e1153;
    let _e1155 = coatSampleAlpha[1u];
    param_753 = _e1155;
    let _e1156 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_751), (&param_752), (&param_753));
    let _e1158 = NdotV_21;
    pdfCoat_1 = ((_e1150 * _e1156) / (4f * _e1158));
    let _e1161 = pCoat;
    let _e1162 = pdfCoat_1;
    let _e1164 = pCoat;
    let _e1166 = pTrans;
    let _e1169 = pSpec;
    let _e1170 = pdfSpec;
    let _e1172 = pSpec;
    let _e1174 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1161 * _e1162) + (((1f - _e1164) * (1f - _e1166)) * ((_e1169 * _e1170) + ((1f - _e1172) * _e1174)))), 0.000001f);
    let _e1180 = (*pW_13);
    param_754 = _e1180;
    let _e1181 = (*basis_15);
    param_755 = _e1181;
    let _e1182 = (*winputL_8);
    param_756 = _e1182;
    let _e1183 = (*woutputL_11);
    param_757 = _e1183;
    let _e1184 = ignorePdf;
    param_758 = _e1184;
    let _e1185 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_754), (&param_755), (&param_756), (&param_757), (&param_758));
    let _e1186 = param_758;
    ignorePdf = _e1186;
    return _e1185;
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

    let _e370 = (*surfaceshader_4);
    if (_e370 == 1i) {
        let _e372 = (*pW_14);
        param_759 = _e372;
        let _e373 = (*basis_16);
        param_760 = _e373;
        let _e374 = (*winputL_9);
        param_761 = _e374;
        let _e375 = (*rndSeed_10);
        param_762 = _e375;
        let _e376 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765));
        let _e377 = param_762;
        (*rndSeed_10) = _e377;
        let _e378 = param_763;
        (*woutputL_12) = _e378;
        let _e379 = param_764;
        (*pdf_woutputL_7) = _e379;
        let _e380 = param_765;
        (*internal_medium_1) = _e380;
        return _e376;
    } else {
        let _e381 = (*surfaceshader_4);
        if (_e381 == 2i) {
            let _e383 = (*pW_14);
            param_766 = _e383;
            let _e384 = (*basis_16);
            param_767 = _e384;
            let _e385 = (*winputL_9);
            param_768 = _e385;
            let _e386 = (*rndSeed_10);
            param_769 = _e386;
            let _e387 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_766), (&param_767), (&param_768), (&param_769), (&param_770), (&param_771));
            let _e388 = param_769;
            (*rndSeed_10) = _e388;
            let _e389 = param_770;
            (*woutputL_12) = _e389;
            let _e390 = param_771;
            (*pdf_woutputL_7) = _e390;
            return _e387;
        } else {
            let _e391 = (*pW_14);
            param_772 = _e391;
            let _e392 = (*basis_16);
            param_773 = _e392;
            let _e393 = (*winputL_9);
            param_774 = _e393;
            let _e394 = (*rndSeed_10);
            param_775 = _e394;
            let _e395 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_772), (&param_773), (&param_774), (&param_775), (&param_776), (&param_777));
            let _e396 = param_775;
            (*rndSeed_10) = _e396;
            let _e397 = param_776;
            (*woutputL_12) = _e397;
            let _e398 = param_777;
            (*pdf_woutputL_7) = _e398;
            return _e395;
        }
    }
}

fn mtlx_openpbr_thin_film_ior_u0028_() -> f32 {
    let _e343 = thin_film_IOR_1;
    return max(_e343, 1f);
}

fn mtlx_openpbr_thin_film_thickness_nm_u0028_() -> f32 {
    let _e343 = thin_film_thickness_1;
    return max(_e343, 0f);
}

fn mtlx_openpbr_specular_ior_u0028_() -> f32 {
    let _e343 = specular_IOR_1;
    return max(_e343, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e343 = specular_roughness_1;
    return clamp(_e343, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    let _e343 = thin_film_thickness_1;
    return clamp(select(0f, 1f, (_e343 > 0f)), 0f, 1f);
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e343 = transmission_1;
    return clamp(_e343, 0f, 1f);
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

    let _e360 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e360) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e362 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e362 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e364 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e364 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e366 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e366 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e369 = (*winputL_10)[2u];
    cosI = clamp(abs(_e369), 0.0001f, 1f);
    let _e372 = mtlx_openpbr_specular_ior_u0028_();
    let _e374 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e375 = mtlx_openpbr_thin_film_ior_u0028_();
    param_778 = max(_e372, 1.001f);
    param_779 = _e374;
    param_780 = _e375;
    let _e376 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_778), (&param_779), (&param_780));
    fd_11 = _e376;
    let _e377 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e378 = cosI;
    param_781 = _e378;
    let _e379 = fd_11;
    param_782 = _e379;
    let _e380 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_781), (&param_782));
    F_4 = (_e380 * _e377);
    let _e382 = (*winputL_10);
    reflectedL = reflect(-(_e382), vec3<f32>(0f, 0f, 1f));
    let _e386 = reflectedL[2u];
    if (_e386 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e388 = reflectedL;
    param_783 = _e388;
    let _e389 = (*basis_17);
    param_784 = _e389;
    let _e390 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_783), (&param_784));
    reflectedW = _e390;
    let _e391 = reflectedW;
    param_785 = _e391;
    let _e392 = sunRadiance_u0028_vf3_u003b((&param_785));
    let _e393 = reflectedW;
    param_786 = _e393;
    let _e394 = skyRadiance_u0028_vf3_u003b((&param_786));
    envRadiance = (_e392 + _e394);
    let _e396 = envRadiance;
    let _e398 = unnamed.skyPower;
    let _e401 = unnamed.skyColor;
    envRadiance = max(_e396, (_e401 * (0.25f * _e398)));
    let _e404 = F_4;
    let _e405 = envRadiance;
    return (_e404 * _e405);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_787: vec3<f32>;
    var param_788: vec3<f32>;

    let _e350 = (*nW);
    param_787 = _e350;
    let _e351 = safe_normalize_u0028_vf3_u003b((&param_787));
    basis_18.nW = _e351;
    let _e353 = (*tW);
    param_788 = _e353;
    let _e354 = safe_normalize_u0028_vf3_u003b((&param_788));
    basis_18.tW = _e354;
    let _e357 = basis_18.nW;
    let _e359 = basis_18.tW;
    basis_18.bW = cross(_e357, _e359);
    let _e362 = (*baryCoord_2);
    basis_18.baryCoord = _e362;
    let _e364 = (*texCoord_2);
    basis_18.texCoord = _e364;
    let _e366 = basis_18;
    return _e366;
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
    var phi_8835_: bool;

    let _e361 = (*shadowW_1);
    param_789 = _e361;
    let _e362 = (*basis_19);
    param_790 = _e362;
    let _e363 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_789), (&param_790));
    shadowL_1 = _e363;
    let _e364 = shadowL_1;
    param_791 = _e364;
    let _e365 = (*shadowW_1);
    param_792 = _e365;
    let _e366 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_791), (&param_792));
    pdf_sky_1 = _e366;
    let _e367 = shadowL_1;
    param_793 = _e367;
    let _e368 = (*shadowW_1);
    param_794 = _e368;
    let _e369 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_793), (&param_794));
    pdf_sun_1 = _e369;
    let _e371 = unnamed.mtlxDisableSun;
    let _e372 = (_e371 != 0u);
    phi_8835_ = _e372;
    if !(_e372) {
        let _e375 = unnamed.mtlxLightCount;
        phi_8835_ = (_e375 > 0i);
    }
    let _e378 = phi_8835_;
    if _e378 {
        local_19 = 0f;
    } else {
        let _e379 = sunTotalPower_u0028_();
        local_19 = _e379;
    }
    let _e380 = local_19;
    w_sun_1 = _e380;
    let _e381 = skyTotalPower_u0028_();
    w_sky_1 = _e381;
    let _e382 = w_sun_1;
    let _e383 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e382 + _e383));
    let _e386 = w_sun_1;
    let _e387 = w_total_1;
    P_sun_1 = (_e386 / _e387);
    let _e389 = w_sky_1;
    let _e390 = w_total_1;
    P_sky_1 = (_e389 / _e390);
    let _e392 = P_sun_1;
    let _e393 = pdf_sun_1;
    let _e395 = P_sky_1;
    let _e396 = pdf_sky_1;
    lightPdf_1 = ((_e392 * _e393) + (_e395 * _e396));
    let _e399 = lightPdf_1;
    return _e399;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_795: vec3<f32>;
    var param_796: vec3<f32>;

    let _e347 = (*nW_1);
    param_795 = _e347;
    let _e348 = safe_normalize_u0028_vf3_u003b((&param_795));
    basis_20.nW = _e348;
    let _e350 = (*nW_1);
    param_796 = _e350;
    let _e351 = normalToTangent_u0028_vf3_u003b((&param_796));
    basis_20.tW = _e351;
    let _e354 = basis_20.nW;
    let _e356 = basis_20.tW;
    basis_20.bW = cross(_e354, _e356);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e361 = basis_20;
    return _e361;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e353 = (*cameraWorld);
    lookDirection = (_e353 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e355 = (*inverseProjection);
    nearVector = (_e355 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e358 = nearVector[2u];
    let _e360 = nearVector[3u];
    nearDistance_1 = abs((_e358 / _e360));
    let _e363 = (*cameraWorld);
    origin_1 = (_e363 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e365 = (*inverseProjection);
    let _e366 = (*coordinate);
    direction_1 = (_e365 * vec4<f32>(_e366.x, _e366.y, 0.5f, 1f));
    let _e372 = direction_1[3u];
    let _e373 = direction_1;
    direction_1 = (_e373 / vec4(_e372));
    let _e376 = (*cameraWorld);
    let _e377 = direction_1;
    let _e379 = origin_1;
    direction_1 = ((_e376 * _e377) - _e379);
    let _e381 = direction_1;
    let _e383 = nearDistance_1;
    let _e385 = direction_1;
    let _e386 = lookDirection;
    let _e390 = origin_1;
    let _e392 = (_e390.xyz + ((_e381.xyz * _e383) / vec3(dot(_e385, _e386))));
    origin_1[0u] = _e392.x;
    origin_1[1u] = _e392.y;
    origin_1[2u] = _e392.z;
    let _e399 = origin_1;
    (*rayOrigin_4) = _e399.xyz;
    let _e401 = direction_1;
    (*rayDirection_2) = _e401.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_20: f32;

    let _e345 = (*xi_1);
    if (_e345 < 0.5f) {
        let _e347 = (*xi_1);
        local_20 = (sqrt((2f * _e347)) - 1f);
    } else {
        let _e351 = (*xi_1);
        local_20 = (1f - sqrt((2f - (2f * _e351))));
    }
    let _e356 = local_20;
    return _e356;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e344 = (*seed_1);
    let _e347 = (*seed_1);
    (*seed_1) = (_e347 ^ (_e344 << bitcast<u32>(13u)));
    let _e349 = (*seed_1);
    let _e352 = (*seed_1);
    (*seed_1) = (_e352 ^ (_e349 >> bitcast<u32>(17u)));
    let _e354 = (*seed_1);
    let _e357 = (*seed_1);
    (*seed_1) = (_e357 ^ (_e354 << bitcast<u32>(5u)));
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
    var phi_9170_: bool;
    var phi_9182_: bool;
    var phi_9183_: bool;
    var phi_9216_: bool;
    var phi_9223_: bool;
    var phi_9354_: bool;
    var phi_9445_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_3 = 1f;
    base_color_1 = vec3<f32>(0.8f, 0.8f, 0.8f);
    diffuse_roughness_1 = 0f;
    metalness_1 = 0f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    specular_roughness_1 = 0.2f;
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
    let _e484 = gl_FragCoord_1;
    frag = _e484.xy;
    let _e487 = frag[0u];
    let _e489 = frag[1u];
    let _e492 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e487 + (_e489 * _e492)));
    let _e496 = rndSeed_11;
    param_797 = _e496;
    xorshift_u0028_u1_u003b((&param_797));
    let _e497 = param_797;
    rndSeed_11 = _e497;
    let _e499 = unnamed.samples;
    let _e501 = rndSeed_11;
    rndSeed_11 = (_e501 ^ u32(_e499));
    let _e503 = rndSeed_11;
    param_798 = _e503;
    let _e504 = rand_u0028_u1_u003b((&param_798));
    let _e505 = param_798;
    rndSeed_11 = _e505;
    param_799 = _e504;
    let _e506 = sample_triangle_filter_u0028_f1_u003b((&param_799));
    jx = (0.5f * _e506);
    let _e508 = rndSeed_11;
    param_800 = _e508;
    let _e509 = rand_u0028_u1_u003b((&param_800));
    let _e510 = param_800;
    rndSeed_11 = _e510;
    param_801 = _e509;
    let _e511 = sample_triangle_filter_u0028_f1_u003b((&param_801));
    jy = (0.5f * _e511);
    let _e513 = frag;
    let _e514 = jx;
    let _e515 = jy;
    pixel = (_e513 + vec2<f32>(_e514, _e515));
    let _e518 = pixel;
    let _e520 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e518 / _e520) * 2f));
    let _e526 = unnamed.invModelMatrix;
    let _e528 = unnamed.cameraWorldMatrix;
    let _e530 = ndc;
    param_802 = _e530;
    param_803 = (_e526 * _e528);
    let _e532 = unnamed.invProjectionMatrix;
    param_804 = _e532;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_802), (&param_803), (&param_804), (&param_805), (&param_806));
    let _e533 = param_805;
    pW_15 = _e533;
    let _e534 = param_806;
    dW = _e534;
    let _e535 = dW;
    dW = normalize(_e535);
    let _e538 = unnamed.sunDir;
    param_807 = _e538;
    let _e539 = makeBasis_u0028_vf3_u003b((&param_807));
    sunBasis = _e539;
    L_12 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e540 = vertex;
        let _e542 = unnamed.bounces;
        if (_e540 <= _e542) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e544 = inside_scattering_volume;
            if !(_e544) {
                let _e546 = pW_15;
                param_808 = _e546;
                let _e547 = dW;
                param_809 = _e547;
                param_810 = 100000000000000000000f;
                let _e548 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_808), (&param_809), (&param_810), (&param_811), (&param_812), (&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
                let _e549 = param_811;
                pW_next = _e549;
                let _e550 = param_812;
                NsW_next = _e550;
                let _e551 = param_813;
                NgW_next = _e551;
                let _e552 = param_814;
                TsW_next = _e552;
                let _e553 = param_815;
                baryCoord_next = _e553;
                let _e554 = param_816;
                texCoord_next = _e554;
                let _e555 = param_817;
                material_next = _e555;
                surface_hit = _e548;
            }
            let _e556 = surface_hit;
            if !(_e556) {
                misWeightLight = 1f;
                let _e558 = vertex;
                let _e560 = inside_scattering_volume;
                if ((_e558 > 0i) && !(_e560)) {
                    let _e563 = dW;
                    param_818 = _e563;
                    let _e564 = basis_21;
                    param_819 = _e564;
                    let _e565 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_818), (&param_819));
                    lightPdf_2 = _e565;
                    let _e566 = bsdfPdf_continuation;
                    let _e567 = lightPdf_2;
                    let _e568 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e566, _e567);
                    misWeightLight = _e568;
                }
                let _e569 = throughput;
                let _e570 = misWeightLight;
                let _e572 = dW;
                param_820 = _e572;
                let _e573 = sunRadiance_u0028_vf3_u003b((&param_820));
                let _e574 = dW;
                param_821 = _e574;
                let _e575 = skyRadiance_u0028_vf3_u003b((&param_821));
                Lenv = ((_e569 * _e570) * (_e573 + _e575));
                let _e578 = Lenv;
                param_822 = _e578;
                let _e579 = maxComponent_u0028_vf3_u003b((&param_822));
                maxLenv = _e579;
                let _e580 = maxLenv;
                let _e582 = unnamed.firefly_clamp;
                if (_e580 > _e582) {
                    let _e585 = unnamed.firefly_clamp;
                    let _e586 = maxLenv;
                    let _e588 = Lenv;
                    Lenv = (_e588 * (_e585 / _e586));
                }
                let _e590 = Lenv;
                let _e591 = L_12;
                L_12 = (_e591 + _e590);
                break;
            }
            let _e593 = vertex;
            let _e595 = unnamed.bounces;
            if (_e593 == _e595) {
                break;
            }
            let _e597 = pW_next;
            pW_15 = _e597;
            let _e598 = NsW_next;
            NsW = _e598;
            let _e599 = NgW_next;
            NgW = _e599;
            let _e600 = TsW_next;
            TsW_1 = _e600;
            let _e601 = baryCoord_next;
            baryCoord_3 = _e601;
            let _e602 = texCoord_next;
            texCoord_3 = _e602;
            let _e603 = material_next;
            surfaceshader_5 = _e603;
            let _e604 = surfaceshader_5;
            if (_e604 == 1i) {
                let _e606 = in_dielectric;
                phi_9170_ = _e606;
                if _e606 {
                    let _e607 = NsW;
                    let _e608 = dW;
                    phi_9170_ = (dot(_e607, _e608) < 0f);
                }
                let _e612 = phi_9170_;
                phi_9183_ = _e612;
                if !(_e612) {
                    let _e614 = in_dielectric;
                    let _e615 = !(_e614);
                    phi_9182_ = _e615;
                    if _e615 {
                        let _e616 = NsW;
                        let _e617 = dW;
                        phi_9182_ = (dot(_e616, _e617) > 0f);
                    }
                    let _e621 = phi_9182_;
                    phi_9183_ = _e621;
                }
                let _e623 = phi_9183_;
                if _e623 {
                    let _e624 = NsW;
                    NsW = (_e624 * -1f);
                }
            } else {
                let _e626 = NsW;
                let _e627 = dW;
                if (dot(_e626, _e627) > 0f) {
                    let _e630 = NsW;
                    NsW = (_e630 * -1f);
                }
            }
            let _e632 = NgW;
            let _e633 = NsW;
            if (dot(_e632, _e633) < 0f) {
                let _e636 = NgW;
                NgW = (_e636 * -1f);
            }
            let _e639 = unnamed.smooth_normals;
            if (_e639 != 0u) {
                let _e641 = surfaceshader_5;
                let _e642 = (_e641 == 1i);
                phi_9216_ = _e642;
                if _e642 {
                    let _e643 = mtlx_openpbr_is_opaque_u0028_();
                    phi_9216_ = _e643;
                }
                let _e645 = phi_9216_;
                phi_9223_ = _e645;
                if _e645 {
                    let _e646 = NsW;
                    let _e647 = dW;
                    phi_9223_ = (dot(_e646, _e647) > 0f);
                }
                let _e651 = phi_9223_;
                if _e651 {
                    let _e652 = NgW;
                    let _e654 = NgW;
                    let _e655 = NsW;
                    let _e658 = NsW;
                    NsW = (((_e652 * 2f) * dot(_e654, _e655)) - _e658);
                }
                let _e660 = NsW;
                param_823 = _e660;
                let _e661 = TsW_next;
                param_824 = _e661;
                let _e662 = baryCoord_3;
                param_825 = _e662;
                let _e663 = texCoord_3;
                param_826 = _e663;
                let _e664 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_823), (&param_824), (&param_825), (&param_826));
                basis_21 = _e664;
            } else {
                let _e665 = NgW;
                param_827 = _e665;
                let _e666 = TsW_next;
                param_828 = _e666;
                let _e667 = baryCoord_3;
                param_829 = _e667;
                let _e668 = texCoord_3;
                param_830 = _e668;
                let _e669 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_827), (&param_828), (&param_829), (&param_830));
                basis_21 = _e669;
            }
            let _e670 = dW;
            winputW = -(_e670);
            let _e672 = winputW;
            param_831 = _e672;
            let _e673 = basis_21;
            param_832 = _e673;
            let _e674 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_831), (&param_832));
            winputL_11 = _e674;
            let _e676 = winputL_11[2u];
            if (abs(_e676) < 0.001f) {
                break;
            }
            thin_walled_1 = false;
            let _e679 = surfaceshader_5;
            if (_e679 == 1i) {
                let _e681 = pW_15;
                param_833 = _e681;
                let _e682 = basis_21;
                param_834 = _e682;
                let _e683 = winputL_11;
                param_835 = _e683;
                let _e684 = rndSeed_11;
                param_836 = _e684;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_833), (&param_834), (&param_835), (&param_836));
                let _e685 = param_836;
                rndSeed_11 = _e685;
                let _e686 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled_1 = _e686;
            }
            let _e687 = surfaceshader_5;
            if (_e687 == 1i) {
                let _e689 = throughput;
                let _e690 = basis_21;
                param_837 = _e690;
                let _e691 = winputL_11;
                param_838 = _e691;
                let _e692 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_837), (&param_838));
                Ltf = (_e689 * _e692);
                let _e694 = Ltf;
                param_839 = _e694;
                let _e695 = maxComponent_u0028_vf3_u003b((&param_839));
                maxLtf = _e695;
                let _e696 = maxLtf;
                let _e698 = unnamed.firefly_clamp;
                if (_e696 > _e698) {
                    let _e701 = unnamed.firefly_clamp;
                    let _e702 = maxLtf;
                    let _e704 = Ltf;
                    Ltf = (_e704 * (_e701 / _e702));
                }
                let _e706 = Ltf;
                let _e707 = L_12;
                L_12 = (_e707 + _e706);
            }
            let _e709 = pW_15;
            param_840 = _e709;
            let _e710 = basis_21;
            param_841 = _e710;
            let _e711 = winputL_11;
            param_842 = _e711;
            let _e712 = rndSeed_11;
            param_843 = _e712;
            let _e713 = surfaceshader_5;
            param_844 = _e713;
            let _e714 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844), (&param_845), (&param_846), (&param_847));
            let _e715 = param_843;
            rndSeed_11 = _e715;
            let _e716 = param_845;
            woutputL_13 = _e716;
            let _e717 = param_846;
            bsdfPdf_continuation = _e717;
            let _e718 = param_847;
            internal_medium_2 = _e718;
            f_2 = _e714;
            let _e719 = woutputL_13;
            param_848 = _e719;
            let _e720 = basis_21;
            param_849 = _e720;
            let _e721 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_848), (&param_849));
            woutputW_7 = _e721;
            let _e722 = surfaceshader_5;
            let _e723 = (_e722 == 1i);
            phi_9354_ = _e723;
            if _e723 {
                let _e725 = winputL_11[2u];
                let _e727 = woutputL_13[2u];
                phi_9354_ = ((_e725 * _e727) < 0f);
            }
            let _e731 = phi_9354_;
            transmitted_sample = _e731;
            let _e732 = surfaceshader_5;
            let _e734 = transmitted_sample;
            if ((_e732 == 1i) && !(_e734)) {
                local_21 = 1f;
            } else {
                let _e737 = woutputW_7;
                let _e739 = basis_21.nW;
                local_21 = abs(dot(_e737, _e739));
            }
            let _e742 = local_21;
            cos_out = _e742;
            let _e743 = f_2;
            let _e744 = bsdfPdf_continuation;
            let _e748 = cos_out;
            surface_throughput = ((_e743 / vec3(max(0.000001f, _e744))) * _e748);
            let _e750 = surface_throughput;
            param_850 = _e750;
            let _e751 = maxComponent_u0028_vf3_u003b((&param_850));
            maxComp = _e751;
            let _e752 = maxComp;
            let _e754 = unnamed.firefly_clamp;
            if (_e752 > _e754) {
                let _e757 = unnamed.firefly_clamp;
                let _e758 = maxComp;
                let _e760 = surface_throughput;
                surface_throughput = (_e760 * (_e757 / _e758));
            }
            let _e762 = woutputW_7;
            dW = _e762;
            let _e763 = surfaceshader_5;
            if (_e763 == 1i) {
                let _e765 = throughput;
                let _e766 = pW_15;
                param_851 = _e766;
                let _e767 = basis_21;
                param_852 = _e767;
                let _e768 = winputL_11;
                param_853 = _e768;
                let _e769 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_851), (&param_852), (&param_853));
                Le = (_e765 * _e769);
                let _e771 = Le;
                param_854 = _e771;
                let _e772 = maxComponent_u0028_vf3_u003b((&param_854));
                maxLe = _e772;
                let _e773 = maxLe;
                let _e775 = unnamed.firefly_clamp;
                if (_e773 > _e775) {
                    let _e778 = unnamed.firefly_clamp;
                    let _e779 = maxLe;
                    let _e781 = Le;
                    Le = (_e781 * (_e778 / _e779));
                }
                let _e783 = Le;
                let _e784 = L_12;
                L_12 = (_e784 + _e783);
            }
            let _e786 = thin_walled_1;
            let _e788 = surfaceshader_5;
            let _e790 = (!(_e786) && (_e788 == 1i));
            phi_9445_ = _e790;
            if _e790 {
                let _e791 = winputW;
                let _e792 = NgW;
                let _e794 = dW;
                let _e795 = NgW;
                phi_9445_ = ((dot(_e791, _e792) * dot(_e794, _e795)) < 0f);
            }
            let _e800 = phi_9445_;
            transmitted = _e800;
            let _e801 = transmitted;
            if _e801 {
                let _e802 = in_dielectric;
                in_dielectric = !(_e802);
            }
            let _e804 = in_dielectric;
            let _e806 = transmitted;
            if (!(_e804) && !(_e806)) {
                let _e809 = pW_15;
                param_855 = _e809;
                let _e810 = basis_21;
                param_856 = _e810;
                let _e811 = rndSeed_11;
                param_860 = _e811;
                let _e812 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_855), (&param_856), (&param_857), (&param_858), (&param_859), (&param_860));
                let _e813 = param_857;
                shadowL_2 = _e813;
                let _e814 = param_858;
                shadowW_2 = _e814;
                let _e815 = param_859;
                lightPdf_3 = _e815;
                let _e816 = param_860;
                rndSeed_11 = _e816;
                Li_8 = _e812;
                let _e817 = Li_8;
                param_861 = _e817;
                let _e818 = maxComponent_u0028_vf3_u003b((&param_861));
                if (_e818 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e820 = pW_15;
                    param_862 = _e820;
                    let _e821 = basis_21;
                    param_863 = _e821;
                    let _e822 = winputL_11;
                    param_864 = _e822;
                    let _e823 = shadowL_2;
                    param_865 = _e823;
                    let _e824 = surfaceshader_5;
                    param_866 = _e824;
                    let _e825 = bsdfPdf_shadow;
                    param_867 = _e825;
                    let _e826 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_862), (&param_863), (&param_864), (&param_865), (&param_866), (&param_867));
                    let _e827 = param_867;
                    bsdfPdf_shadow = _e827;
                    fshadow = _e826;
                    let _e828 = lightPdf_3;
                    let _e829 = bsdfPdf_shadow;
                    let _e830 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e828, _e829);
                    misWeightLight_1 = _e830;
                    let _e831 = surfaceshader_5;
                    if (_e831 == 1i) {
                        local_22 = 1f;
                    } else {
                        let _e833 = shadowW_2;
                        let _e835 = basis_21.nW;
                        local_22 = abs(dot(_e833, _e835));
                    }
                    let _e838 = local_22;
                    cos_shadow = _e838;
                    let _e839 = misWeightLight_1;
                    let _e840 = fshadow;
                    let _e842 = cos_shadow;
                    let _e844 = Li_8;
                    let _e846 = lightPdf_3;
                    Ld = ((((_e840 * _e839) * _e842) * _e844) / vec3(max(0.000001f, _e846)));
                    let _e850 = throughput;
                    let _e851 = Ld;
                    Lcontrib = (_e850 * _e851);
                    let _e853 = Lcontrib;
                    param_868 = _e853;
                    let _e854 = maxComponent_u0028_vf3_u003b((&param_868));
                    maxLcontrib = _e854;
                    let _e855 = maxLcontrib;
                    let _e857 = unnamed.firefly_clamp;
                    if (_e855 > _e857) {
                        let _e860 = unnamed.firefly_clamp;
                        let _e861 = maxLcontrib;
                        let _e863 = Lcontrib;
                        Lcontrib = (_e863 * (_e860 / _e861));
                    }
                    let _e865 = Lcontrib;
                    let _e866 = L_12;
                    L_12 = (_e866 + _e865);
                }
            }
            let _e868 = NgW;
            let _e869 = dW;
            let _e870 = NgW;
            let _e875 = pW_15;
            pW_15 = (_e875 + ((_e868 * sign(dot(_e869, _e870))) * 0.0001f));
            let _e877 = surface_throughput;
            let _e878 = throughput;
            throughput = (_e878 * _e877);
            let _e880 = throughput;
            param_869 = _e880;
            let _e881 = maxComponent_u0028_vf3_u003b((&param_869));
            maxTP = _e881;
            let _e882 = maxTP;
            let _e884 = unnamed.firefly_clamp;
            if (_e882 > _e884) {
                let _e887 = unnamed.firefly_clamp;
                let _e888 = maxTP;
                let _e890 = throughput;
                throughput = (_e890 * (_e887 / _e888));
            }
            let _e892 = throughput;
            param_870 = _e892;
            let _e893 = maxComponent_u0028_vf3_u003b((&param_870));
            let _e895 = vertex;
            if ((_e893 < 1f) && (_e895 > 1i)) {
                let _e898 = throughput;
                param_871 = _e898;
                let _e899 = maxComponent_u0028_vf3_u003b((&param_871));
                q = max(0f, (1f - _e899));
                let _e902 = rndSeed_11;
                param_872 = _e902;
                let _e903 = rand_u0028_u1_u003b((&param_872));
                let _e904 = param_872;
                rndSeed_11 = _e904;
                let _e905 = q;
                if (_e903 < _e905) {
                    break;
                }
                let _e907 = q;
                let _e909 = throughput;
                throughput = (_e909 / vec3((1f - _e907)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e912 = vertex;
            vertex = (_e912 + 1i);
        }
    }
    let _e914 = L_12;
    mtlxFragmentColor[0u] = _e914.x;
    mtlxFragmentColor[1u] = _e914.y;
    mtlxFragmentColor[2u] = _e914.z;
    let _e922 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e922;
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
