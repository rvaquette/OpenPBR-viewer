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

struct VDF {
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
var<private> base_weight_1: f32;
var<private> base_color_1: vec3<f32>;
var<private> base_diffuse_roughness_1: f32;
var<private> base_metalness_1: f32;
var<private> specular_weight_1: f32;
var<private> specular_color_1: vec3<f32>;
var<private> specular_roughness_1: f32;
var<private> specular_ior_1: f32;
var<private> specular_roughness_anisotropy_1: f32;
var<private> transmission_weight_1: f32;
var<private> transmission_color_1: vec3<f32>;
var<private> transmission_depth_1: f32;
var<private> transmission_scatter_1: vec3<f32>;
var<private> transmission_scatter_anisotropy_1: f32;
var<private> transmission_dispersion_scale_1: f32;
var<private> transmission_dispersion_abbe_number_1: f32;
var<private> subsurface_weight_1: f32;
var<private> subsurface_color_1: vec3<f32>;
var<private> subsurface_radius_1: f32;
var<private> subsurface_radius_scale_1: vec3<f32>;
var<private> subsurface_scatter_anisotropy_1: f32;
var<private> fuzz_weight_1: f32;
var<private> fuzz_color_1: vec3<f32>;
var<private> fuzz_roughness_1: f32;
var<private> coat_weight_1: f32;
var<private> coat_color_1: vec3<f32>;
var<private> coat_roughness_1: f32;
var<private> coat_roughness_anisotropy_1: f32;
var<private> coat_ior_1: f32;
var<private> coat_darkening_1: f32;
var<private> thin_film_weight_1: f32;
var<private> thin_film_thickness_1: f32;
var<private> thin_film_ior_1: f32;
var<private> emission_luminance_1: f32;
var<private> emission_color_1: vec3<f32>;
var<private> geometry_opacity_1: f32;
var<private> geometry_thin_walled_1: bool;
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
    let _e344 = (*v)[0u];
    let _e346 = (*v)[1u];
    let _e348 = (*v)[2u];
    return min(_e344, min(_e346, _e348));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e344 = (*wiL)[2u];
    if (_e344 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e347 = (*wiL)[2u];
    return (_e347 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_8017_: bool;
    var phi_8035_: bool;

    let _e350 = (*winputL)[2u];
    let _e351 = (_e350 < 0.0000000001f);
    phi_8017_ = _e351;
    if !(_e351) {
        let _e354 = (*woutputL)[2u];
        phi_8017_ = (_e354 < 0.0000000001f);
    }
    let _e357 = phi_8017_;
    if _e357 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e358 = (*woutputL);
    param = _e358;
    let _e359 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e359;
    let _e361 = unnamed.wireframe;
    let _e362 = (_e361 != 0u);
    phi_8035_ = _e362;
    if _e362 {
        let _e364 = (*basis).baryCoord;
        param_1 = _e364;
        let _e365 = minComponent_u0028_vf3_u003b((&param_1));
        phi_8035_ = (_e365 < 0.003f);
    }
    let _e368 = phi_8035_;
    if _e368 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e370 = unnamed.neutral_color;
    return (_e370 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e345 = (*pW_1)[0u];
    let _e347 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e345, -(_e347)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e355 = uv;
    let _e356 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e355, 0.0);
    return _e356.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_8110_: bool;

    let _e350 = (*winputL_1)[2u];
    let _e351 = (_e350 < 0.0000000001f);
    phi_8110_ = _e351;
    if !(_e351) {
        let _e354 = (*woutputL_1)[2u];
        phi_8110_ = (_e354 < 0.0000000001f);
    }
    let _e357 = phi_8110_;
    if _e357 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e358 = (*woutputL_1);
    param_2 = _e358;
    let _e359 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e359;
    let _e360 = (*pW_2);
    param_3 = _e360;
    let _e361 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e361 / vec3(3.1415927f));
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e347 = (*bg);
    let _e348 = (*fg);
    let _e349 = (*mixValue);
    (*result) = mix(_e347, _e348, vec3(_e349));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e347 = (*cosTheta);
    x = clamp((1f - _e347), 0f, 1f);
    let _e350 = (*F0_);
    let _e351 = (*F90_);
    let _e352 = x;
    let _e353 = (*exponent);
    return mix(_e350, _e351, vec3(pow(_e352, _e353)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e345 = (*N);
    let _e346 = (*V);
    if (dot(_e345, _e346) < 0f) {
        let _e349 = (*N);
        local = -(_e349);
    } else {
        let _e351 = (*N);
        local = _e351;
    }
    let _e352 = local;
    return _e352;
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

    let _e358 = (*closureData_1).closureType;
    if (_e358 == 4i) {
        let _e361 = (*closureData_1).N;
        param_4 = _e361;
        let _e363 = (*closureData_1).V;
        param_5 = _e363;
        let _e364 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_4), (&param_5));
        N_1 = _e364;
        let _e365 = N_1;
        let _e367 = (*closureData_1).V;
        NdotV = clamp(dot(_e365, _e367), 0.00000001f, 1f);
        let _e370 = NdotV;
        param_6 = _e370;
        let _e371 = (*color0_);
        param_7 = _e371;
        let _e372 = (*color90_);
        param_8 = _e372;
        let _e373 = (*exponent_1);
        param_9 = _e373;
        let _e374 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_6), (&param_7), (&param_8), (&param_9));
        f = _e374;
        let _e375 = (*base);
        let _e376 = f;
        (*result_1) = (_e375 * _e376);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e346 = (*in1_);
    let _e347 = (*in2_);
    (*result_2) = (_e346 * _e347);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e346 = (*closureData_3).closureType;
    if (_e346 == 4i) {
        let _e348 = (*color);
        (*result_3) = _e348;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_4: ptr<function, BSDF>) {
    let _e347 = (*top).response;
    let _e349 = (*base_1).response;
    let _e351 = (*top).throughput;
    (*result_4).response = (_e347 + (_e349 * _e351));
    let _e356 = (*top).throughput;
    let _e358 = (*base_1).throughput;
    (*result_4).throughput = (_e356 * _e358);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e346 = (*dir)[1u];
    latitude = ((-(asin(_e346)) * 0.31830987f) + 0.5f);
    let _e352 = (*dir)[0u];
    let _e354 = (*dir)[2u];
    longitude = (((atan2(_e352, -(_e354)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e360 = longitude;
    let _e361 = latitude;
    return vec2<f32>(_e360, _e361);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e344 = (*m);
    let _e345 = (*v_1);
    return (_e344 * _e345);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_12: vec3<f32>;

    let _e350 = (*dir_1);
    let _e355 = (*transform);
    param_10 = _e355;
    param_11 = vec4<f32>(_e350.x, _e350.y, _e350.z, 0f);
    let _e356 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_10), (&param_11));
    envDir = normalize(_e356.xyz);
    let _e359 = envDir;
    param_12 = _e359;
    let _e360 = mx_latlong_projection_u0028_vf3_u003b((&param_12));
    uv_1 = _e360;
    let _e361 = uv_1;
    let _e362 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e361, 0.0);
    return _e362.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e345 = a;
    c = cos(_e345);
    let _e347 = a;
    s = sin(_e347);
    let _e349 = c;
    let _e350 = s;
    let _e352 = s;
    let _e353 = c;
    return mat4x4<f32>(vec4<f32>(_e349, 0f, -(_e350), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e352, 0f, _e353, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_13: vec3<f32>;
    var param_14: mat4x4<f32>;
    var param_15: f32;

    let _e347 = mtlxEnvMatrix_u0028_();
    let _e348 = (*N_2);
    param_13 = _e348;
    param_14 = _e347;
    param_15 = 0f;
    let _e349 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_13), (&param_14), (&param_15));
    Li = _e349;
    let _e350 = Li;
    let _e352 = unnamed.skyPower;
    return (_e350 * _e352);
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e347 = (*shape);
    let _e349 = (*dist);
    num1_ = exp((-(_e347) * _e349));
    let _e352 = (*shape);
    let _e354 = (*dist);
    num2_ = exp(((-(_e352) * _e354) / vec3(3f)));
    let _e359 = (*dist);
    denom = max(_e359, 0.00000001f);
    let _e361 = num1_;
    let _e362 = num2_;
    let _e364 = denom;
    return ((_e361 + _e362) / vec3(_e364));
}

fn mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(N_3: ptr<function, vec3<f32>>, L: ptr<function, vec3<f32>>, radius: ptr<function, f32>, mfp: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta: f32;
    var shape_1: vec3<f32>;
    var sumD: vec3<f32>;
    var sumR: vec3<f32>;
    var i: i32;
    var x_1: f32;
    var dist_1: f32;
    var R: vec3<f32>;
    var param_16: f32;
    var param_17: vec3<f32>;

    let _e356 = (*N_3);
    let _e357 = (*L);
    theta = acos(dot(_e356, _e357));
    let _e360 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e360, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e364 = i;
        if (_e364 < 32i) {
            let _e366 = i;
            x_1 = (-3.1415927f + ((f32(_e366) + 0.5f) * 0.19634955f));
            let _e371 = (*radius);
            let _e372 = x_1;
            dist_1 = (_e371 * abs((2f * sin((_e372 * 0.5f)))));
            let _e378 = dist_1;
            param_16 = _e378;
            let _e379 = shape_1;
            param_17 = _e379;
            let _e380 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_16), (&param_17));
            R = _e380;
            let _e381 = R;
            let _e382 = theta;
            let _e383 = x_1;
            let _e388 = sumD;
            sumD = (_e388 + (_e381 * max(cos((_e382 + _e383)), 0f)));
            let _e390 = R;
            let _e391 = sumR;
            sumR = (_e391 + _e390);
            continue;
        } else {
            break;
        }
        continuing {
            let _e393 = i;
            i = (_e393 + 1i);
        }
    }
    let _e395 = sumD;
    let _e396 = sumR;
    return (_e395 / _e396);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_4: ptr<function, vec3<f32>>, L_1: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_18: vec3<f32>;
    var param_19: vec3<f32>;
    var param_20: f32;
    var param_21: vec3<f32>;

    let _e353 = (*N_4);
    let _e354 = fwidth(_e353);
    let _e356 = (*P);
    let _e357 = fwidth(_e356);
    curvature = (length(_e354) / length(_e357));
    let _e360 = curvature;
    radius_1 = (1f / max(_e360, 0.01f));
    let _e363 = (*albedo);
    let _e364 = (*N_4);
    param_18 = _e364;
    let _e365 = (*L_1);
    param_19 = _e365;
    let _e366 = radius_1;
    param_20 = _e366;
    let _e367 = (*mfp_1);
    param_21 = _e367;
    let _e368 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_18), (&param_19), (&param_20), (&param_21));
    return ((_e363 * _e368) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
}

fn mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, weight: ptr<function, f32>, color_1: ptr<function, vec3<f32>>, radius_2: ptr<function, vec3<f32>>, anisotropy: ptr<function, f32>, N_5: ptr<function, vec3<f32>>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L_2: vec3<f32>;
    var P_1: vec3<f32>;
    var occlusion: f32;
    var param_22: vec3<f32>;
    var param_23: vec3<f32>;
    var sss: vec3<f32>;
    var param_24: vec3<f32>;
    var param_25: vec3<f32>;
    var param_26: vec3<f32>;
    var param_27: vec3<f32>;
    var param_28: vec3<f32>;
    var NdotL: f32;
    var visibleOcclusion: f32;
    var Li_1: vec3<f32>;
    var param_29: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e366 = (*weight);
    if (_e366 < 0.00000001f) {
        return;
    }
    let _e369 = (*closureData_5).V;
    V_1 = _e369;
    let _e371 = (*closureData_5).L;
    L_2 = _e371;
    let _e373 = (*closureData_5).P;
    P_1 = _e373;
    let _e375 = (*closureData_5).occlusion;
    occlusion = _e375;
    let _e376 = (*N_5);
    param_22 = _e376;
    let _e377 = V_1;
    param_23 = _e377;
    let _e378 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_22), (&param_23));
    (*N_5) = _e378;
    let _e380 = (*closureData_5).closureType;
    if (_e380 == 1i) {
        let _e382 = (*N_5);
        param_24 = _e382;
        let _e383 = L_2;
        param_25 = _e383;
        let _e384 = P_1;
        param_26 = _e384;
        let _e385 = (*color_1);
        param_27 = _e385;
        let _e386 = (*radius_2);
        param_28 = _e386;
        let _e387 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_24), (&param_25), (&param_26), (&param_27), (&param_28));
        sss = _e387;
        let _e388 = (*N_5);
        let _e389 = L_2;
        NdotL = clamp(dot(_e388, _e389), 0.00000001f, 1f);
        let _e392 = NdotL;
        let _e393 = occlusion;
        visibleOcclusion = (1f - (_e392 * (1f - _e393)));
        let _e397 = sss;
        let _e398 = visibleOcclusion;
        let _e400 = (*weight);
        (*bsdf).response = ((_e397 * _e398) * _e400);
    } else {
        let _e404 = (*closureData_5).closureType;
        if (_e404 == 3i) {
            let _e406 = (*N_5);
            param_29 = _e406;
            let _e407 = mx_environment_irradiance_u0028_vf3_u003b((&param_29));
            Li_1 = _e407;
            let _e408 = Li_1;
            let _e409 = (*color_1);
            let _e411 = (*weight);
            (*bsdf).response = ((_e408 * _e409) * _e411);
        }
    }
    return;
}

fn mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, fg_1: ptr<function, BSDF>, bg_1: ptr<function, BSDF>, mixValue_1: ptr<function, f32>, result_5: ptr<function, BSDF>) {
    let _e348 = (*bg_1).response;
    let _e350 = (*fg_1).response;
    let _e351 = (*mixValue_1);
    (*result_5).response = mix(_e348, _e350, vec3(_e351));
    let _e356 = (*bg_1).throughput;
    let _e358 = (*fg_1).throughput;
    let _e359 = (*mixValue_1);
    (*result_5).throughput = mix(_e356, _e358, vec3(_e359));
    return;
}

fn mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, weight_1: ptr<function, f32>, color_2: ptr<function, vec3<f32>>, N_6: ptr<function, vec3<f32>>, bsdf_1: ptr<function, BSDF>) {
    var V_2: vec3<f32>;
    var L_3: vec3<f32>;
    var NdotL_1: f32;
    var Li_2: vec3<f32>;
    var param_30: vec3<f32>;

    (*bsdf_1).throughput = vec3<f32>(0f, 0f, 0f);
    let _e353 = (*weight_1);
    if (_e353 < 0.00000001f) {
        return;
    }
    let _e356 = (*closureData_7).V;
    V_2 = _e356;
    let _e358 = (*closureData_7).L;
    L_3 = _e358;
    let _e359 = (*N_6);
    (*N_6) = -(_e359);
    let _e362 = (*closureData_7).closureType;
    if (_e362 == 1i) {
        let _e364 = (*N_6);
        let _e365 = L_3;
        NdotL_1 = clamp(dot(_e364, _e365), 0f, 1f);
        let _e368 = (*color_2);
        let _e369 = (*weight_1);
        let _e371 = NdotL_1;
        (*bsdf_1).response = (((_e368 * _e369) * _e371) * 0.31830987f);
    } else {
        let _e376 = (*closureData_7).closureType;
        if (_e376 == 3i) {
            let _e378 = (*N_6);
            param_30 = _e378;
            let _e379 = mx_environment_irradiance_u0028_vf3_u003b((&param_30));
            Li_2 = _e379;
            let _e380 = Li_2;
            let _e381 = (*color_2);
            let _e383 = (*weight_1);
            (*bsdf_1).response = ((_e380 * _e381) * _e383);
        }
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_6: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e347 = (*in2_1);
    tint = clamp(_e347, vec3(0f), vec3(1f));
    let _e352 = (*in1_1).response;
    let _e353 = tint;
    (*result_6).response = (_e352 * _e353);
    let _e357 = (*in1_1).throughput;
    (*result_6).throughput = _e357;
    return;
}

fn mx_square_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    let _e343 = (*x_2);
    let _e344 = (*x_2);
    return (_e343 * _e344);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_31: f32;

    let _e346 = (*roughness);
    let _e349 = (*NdotV_1);
    let _e351 = (*roughness);
    let _e354 = (*roughness);
    param_31 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_31));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e346)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e349) * _e351)) + (vec2<f32>(1.4385f, 2.0315f) * _e355));
    let _e359 = r[0u];
    let _e361 = r[1u];
    return (_e359 / _e361);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_32: f32;
    var param_33: f32;

    let _e347 = (*NdotV_2);
    param_32 = _e347;
    let _e348 = (*roughness_1);
    param_33 = _e348;
    let _e349 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_32), (&param_33));
    dirAlbedo = _e349;
    let _e350 = dirAlbedo;
    return clamp(_e350, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e343 = (*x_3);
    let _e344 = (*x_3);
    return (_e343 * _e344);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e344 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e344)));
    let _e348 = A;
    let _e349 = (*roughness_2);
    return (_e348 * (1f + (0.07248821f * _e349)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_34: f32;
    var G: f32;

    let _e349 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e349)));
    let _e353 = (*roughness_3);
    let _e354 = A_1;
    B = (_e353 * _e354);
    let _e356 = (*cosTheta_1);
    param_34 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_34));
    Si = sqrt(max(0f, (1f - _e357)));
    let _e361 = Si;
    let _e362 = (*cosTheta_1);
    let _e365 = Si;
    let _e366 = (*cosTheta_1);
    let _e370 = Si;
    let _e371 = (*cosTheta_1);
    let _e373 = Si;
    let _e374 = Si;
    let _e376 = Si;
    let _e380 = Si;
    G = ((_e361 * (acos(clamp(_e362, -1f, 1f)) - (_e365 * _e366))) + ((2f * (((_e370 / _e371) * (1f - ((_e373 * _e374) * _e376))) - _e380)) / 3f));
    let _e385 = A_1;
    let _e386 = B;
    let _e387 = G;
    return (_e385 + ((_e386 * _e387) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_35: f32;
    var param_36: f32;
    var avgAlbedo: f32;
    var param_37: f32;
    var colorMultiScatter: vec3<f32>;
    var param_38: vec3<f32>;

    let _e352 = (*cosTheta_2);
    param_35 = _e352;
    let _e353 = (*roughness_4);
    param_36 = _e353;
    let _e354 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_35), (&param_36));
    dirAlbedo_1 = _e354;
    let _e355 = (*roughness_4);
    param_37 = _e355;
    let _e356 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_37));
    avgAlbedo = _e356;
    let _e357 = (*color_3);
    param_38 = _e357;
    let _e358 = mx_square_u0028_vf3_u003b((&param_38));
    let _e359 = avgAlbedo;
    let _e361 = (*color_3);
    let _e362 = avgAlbedo;
    colorMultiScatter = ((_e358 * _e359) / (vec3<f32>(1f, 1f, 1f) - (_e361 * max(0f, (1f - _e362)))));
    let _e368 = colorMultiScatter;
    let _e369 = (*color_3);
    let _e370 = dirAlbedo_1;
    return mix(_e368, _e369, vec3(_e370));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL_2: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_39: f32;
    var A_2: f32;
    var B_1: f32;

    let _e353 = (*LdotV);
    let _e354 = (*NdotL_2);
    let _e355 = (*NdotV_3);
    s_1 = (_e353 - (_e354 * _e355));
    let _e358 = s_1;
    if (_e358 > 0f) {
        let _e360 = s_1;
        let _e361 = (*NdotL_2);
        let _e362 = (*NdotV_3);
        local_1 = (_e360 / max(_e361, _e362));
    } else {
        local_1 = 0f;
    }
    let _e365 = local_1;
    stinv = _e365;
    let _e366 = (*roughness_5);
    param_39 = _e366;
    let _e367 = mx_square_u0028_f1_u003b((&param_39));
    sigma2_ = _e367;
    let _e368 = sigma2_;
    let _e369 = sigma2_;
    A_2 = (1f - (0.5f * (_e368 / (_e369 + 0.33f))));
    let _e374 = sigma2_;
    let _e376 = sigma2_;
    B_1 = ((0.45f * _e374) / (_e376 + 0.09f));
    let _e379 = A_2;
    let _e380 = B_1;
    let _e381 = stinv;
    return (_e379 + (_e380 * _e381));
}

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_4: ptr<function, f32>, NdotL_3: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_4: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_2: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_40: f32;
    var param_41: f32;
    var dirAlbedoL: f32;
    var param_42: f32;
    var param_43: f32;
    var avgAlbedo_1: f32;
    var param_44: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_45: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e363 = (*LdotV_1);
    let _e364 = (*NdotL_3);
    let _e365 = (*NdotV_4);
    s_2 = (_e363 - (_e364 * _e365));
    let _e368 = s_2;
    if (_e368 > 0f) {
        let _e370 = s_2;
        let _e371 = (*NdotL_3);
        let _e372 = (*NdotV_4);
        local_2 = (_e370 / max(_e371, _e372));
    } else {
        let _e375 = s_2;
        local_2 = _e375;
    }
    let _e376 = local_2;
    stinv_1 = _e376;
    let _e377 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e377)));
    let _e381 = (*color_4);
    let _e382 = A_3;
    let _e384 = (*roughness_6);
    let _e385 = stinv_1;
    lobeSingleScatter = ((_e381 * _e382) * (1f + (_e384 * _e385)));
    let _e389 = (*NdotV_4);
    param_40 = _e389;
    let _e390 = (*roughness_6);
    param_41 = _e390;
    let _e391 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_40), (&param_41));
    dirAlbedoV = _e391;
    let _e392 = (*NdotL_3);
    param_42 = _e392;
    let _e393 = (*roughness_6);
    param_43 = _e393;
    let _e394 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_42), (&param_43));
    dirAlbedoL = _e394;
    let _e395 = (*roughness_6);
    param_44 = _e395;
    let _e396 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_44));
    avgAlbedo_1 = _e396;
    let _e397 = (*color_4);
    param_45 = _e397;
    let _e398 = mx_square_u0028_vf3_u003b((&param_45));
    let _e399 = avgAlbedo_1;
    let _e401 = (*color_4);
    let _e402 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e398 * _e399) / (vec3<f32>(1f, 1f, 1f) - (_e401 * max(0f, (1f - _e402)))));
    let _e408 = colorMultiScatter_1;
    let _e409 = dirAlbedoV;
    let _e413 = dirAlbedoL;
    let _e417 = avgAlbedo_1;
    lobeMultiScatter = (((_e408 * max(0.00000001f, (1f - _e409))) * max(0.00000001f, (1f - _e413))) / vec3(max(0.00000001f, (1f - _e417))));
    let _e422 = lobeSingleScatter;
    let _e423 = lobeMultiScatter;
    return (_e422 + _e423);
}

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_9: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color_5: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_7: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf_2: ptr<function, BSDF>) {
    var V_3: vec3<f32>;
    var L_4: vec3<f32>;
    var param_46: vec3<f32>;
    var param_47: vec3<f32>;
    var NdotV_5: f32;
    var NdotL_4: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_48: f32;
    var param_49: f32;
    var param_50: f32;
    var param_51: f32;
    var param_52: vec3<f32>;
    var param_53: f32;
    var param_54: f32;
    var param_55: f32;
    var param_56: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_57: f32;
    var param_58: f32;
    var param_59: vec3<f32>;
    var param_60: f32;
    var param_61: f32;
    var Li_3: vec3<f32>;
    var param_62: vec3<f32>;

    (*bsdf_2).throughput = vec3<f32>(0f, 0f, 0f);
    let _e377 = (*weight_2);
    if (_e377 < 0.00000001f) {
        return;
    }
    let _e380 = (*closureData_9).V;
    V_3 = _e380;
    let _e382 = (*closureData_9).L;
    L_4 = _e382;
    let _e383 = (*N_7);
    param_46 = _e383;
    let _e384 = V_3;
    param_47 = _e384;
    let _e385 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_46), (&param_47));
    (*N_7) = _e385;
    let _e386 = (*N_7);
    let _e387 = V_3;
    NdotV_5 = clamp(dot(_e386, _e387), 0.00000001f, 1f);
    let _e391 = (*closureData_9).closureType;
    if (_e391 == 1i) {
        let _e393 = (*N_7);
        let _e394 = L_4;
        NdotL_4 = clamp(dot(_e393, _e394), 0.00000001f, 1f);
        let _e397 = L_4;
        let _e398 = V_3;
        LdotV_2 = clamp(dot(_e397, _e398), 0.00000001f, 1f);
        let _e401 = (*energy_compensation);
        if _e401 {
            let _e402 = NdotV_5;
            param_48 = _e402;
            let _e403 = NdotL_4;
            param_49 = _e403;
            let _e404 = LdotV_2;
            param_50 = _e404;
            let _e405 = (*roughness_7);
            param_51 = _e405;
            let _e406 = (*color_5);
            param_52 = _e406;
            let _e407 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_48), (&param_49), (&param_50), (&param_51), (&param_52));
            local_3 = _e407;
        } else {
            let _e408 = NdotV_5;
            param_53 = _e408;
            let _e409 = NdotL_4;
            param_54 = _e409;
            let _e410 = LdotV_2;
            param_55 = _e410;
            let _e411 = (*roughness_7);
            param_56 = _e411;
            let _e412 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_53), (&param_54), (&param_55), (&param_56));
            let _e413 = (*color_5);
            local_3 = (_e413 * _e412);
        }
        let _e415 = local_3;
        diffuse = _e415;
        let _e416 = diffuse;
        let _e418 = (*closureData_9).occlusion;
        let _e420 = (*weight_2);
        let _e422 = NdotL_4;
        (*bsdf_2).response = ((((_e416 * _e418) * _e420) * _e422) * 0.31830987f);
    } else {
        let _e427 = (*closureData_9).closureType;
        if (_e427 == 3i) {
            let _e429 = (*energy_compensation);
            if _e429 {
                let _e430 = NdotV_5;
                param_57 = _e430;
                let _e431 = (*roughness_7);
                param_58 = _e431;
                let _e432 = (*color_5);
                param_59 = _e432;
                let _e433 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_57), (&param_58), (&param_59));
                local_4 = _e433;
            } else {
                let _e434 = NdotV_5;
                param_60 = _e434;
                let _e435 = (*roughness_7);
                param_61 = _e435;
                let _e436 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_60), (&param_61));
                let _e437 = (*color_5);
                local_4 = (_e437 * _e436);
            }
            let _e439 = local_4;
            diffuse_1 = _e439;
            let _e440 = (*N_7);
            param_62 = _e440;
            let _e441 = mx_environment_irradiance_u0028_vf3_u003b((&param_62));
            Li_3 = _e441;
            let _e442 = Li_3;
            let _e443 = diffuse_1;
            let _e445 = (*weight_2);
            (*bsdf_2).response = ((_e442 * _e443) * _e445);
        }
    }
    return;
}

fn mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_10: ptr<function, ClosureData>, top_1: ptr<function, BSDF>, base_2: ptr<function, VDF>, result_7: ptr<function, BSDF>) {
    let _e347 = (*top_1).response;
    let _e349 = (*base_2).throughput;
    (*result_7).response = (_e347 * _e349);
    let _e353 = (*top_1).throughput;
    let _e355 = (*base_2).throughput;
    (*result_7).throughput = (_e353 * _e355);
    return;
}

fn mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b(closureData_11: ptr<function, ClosureData>, absorption: ptr<function, vec3<f32>>, scattering: ptr<function, vec3<f32>>, anisotropy_1: ptr<function, f32>, vdf: ptr<function, VDF>) {
    let _e348 = (*closureData_11).closureType;
    if (_e348 == 2i) {
        (*vdf).response = vec3<f32>(0f, 0f, 0f);
        let _e351 = (*absorption);
        (*vdf).throughput = exp(-(_e351));
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_12: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_8: ptr<function, BSDF>) {
    var weight_3: f32;

    let _e347 = (*in2_2);
    weight_3 = clamp(_e347, 0f, 1f);
    let _e350 = (*in1_2).response;
    let _e351 = weight_3;
    (*result_8).response = (_e350 * _e351);
    let _e355 = (*in1_2).throughput;
    (*result_8).throughput = _e355;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_13: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_9: ptr<function, BSDF>) {
    let _e347 = (*in1_3).response;
    let _e349 = (*in2_3).response;
    (*result_9).response = (_e347 + _e349);
    let _e353 = (*in1_3).throughput;
    let _e355 = (*in2_3).throughput;
    (*result_9).throughput = max(((_e353 + _e355) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_6: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_63: f32;
    var lambdaL: f32;
    var param_64: f32;
    var lambdaV: f32;
    var param_65: f32;

    let _e351 = (*alpha);
    param_63 = _e351;
    let _e352 = mx_square_u0028_f1_u003b((&param_63));
    alpha2_ = _e352;
    let _e353 = alpha2_;
    let _e354 = alpha2_;
    let _e356 = (*NdotL_5);
    param_64 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_64));
    lambdaL = sqrt((_e353 + ((1f - _e354) * _e357)));
    let _e361 = alpha2_;
    let _e362 = alpha2_;
    let _e364 = (*NdotV_6);
    param_65 = _e364;
    let _e365 = mx_square_u0028_f1_u003b((&param_65));
    lambdaV = sqrt((_e361 + ((1f - _e362) * _e365)));
    let _e369 = (*NdotL_5);
    let _e371 = (*NdotV_6);
    let _e373 = lambdaL;
    let _e374 = (*NdotV_6);
    let _e376 = lambdaV;
    let _e377 = (*NdotL_5);
    return (((2f * _e369) * _e371) / ((_e373 * _e374) + (_e376 * _e377)));
}

fn mx_pow6_u0028_f1_u003b(x_4: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_66: f32;
    var param_67: f32;

    let _e346 = (*x_4);
    param_66 = _e346;
    let _e347 = mx_square_u0028_f1_u003b((&param_66));
    x2_ = _e347;
    let _e348 = x2_;
    param_67 = _e348;
    let _e349 = mx_square_u0028_f1_u003b((&param_67));
    let _e350 = x2_;
    return (_e349 * _e350);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_3: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_5: f32;
    var a_1: vec3<f32>;
    var param_68: f32;

    let _e347 = (*cosTheta_3);
    x_5 = clamp(_e347, 0f, 1f);
    let _e350 = (*fd).F0_;
    let _e352 = (*fd).F90_;
    let _e354 = (*fd).exponent;
    let _e359 = (*fd).F82_;
    a_1 = ((mix(_e350, _e352, vec3(pow(0.85714287f, _e354))) * (vec3<f32>(1f, 1f, 1f) - _e359)) * 17.651384f);
    let _e364 = (*fd).F0_;
    let _e366 = (*fd).F90_;
    let _e367 = x_5;
    let _e370 = (*fd).exponent;
    let _e374 = a_1;
    let _e375 = x_5;
    let _e377 = x_5;
    param_68 = (1f - _e377);
    let _e379 = mx_pow6_u0028_f1_u003b((&param_68));
    return (mix(_e364, _e366, vec3(pow((1f - _e367), _e370))) - ((_e374 * _e375) * _e379));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_4: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_69: f32;
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

    let _e359 = (*cosTheta_4);
    param_69 = clamp(_e359, 0f, 1f);
    let _e361 = mx_square_u0028_f1_u003b((&param_69));
    cosTheta2_ = _e361;
    let _e362 = cosTheta2_;
    sinTheta2_ = (1f - _e362);
    let _e364 = (*n);
    let _e365 = (*n);
    n2_ = (_e364 * _e365);
    let _e367 = (*k);
    let _e368 = (*k);
    k2_ = (_e367 * _e368);
    let _e370 = n2_;
    let _e371 = k2_;
    let _e373 = sinTheta2_;
    t0_ = ((_e370 - _e371) - vec3(_e373));
    let _e376 = t0_;
    let _e377 = t0_;
    let _e379 = n2_;
    let _e381 = k2_;
    a2plusb2_ = sqrt(((_e376 * _e377) + ((_e379 * 4f) * _e381)));
    let _e385 = a2plusb2_;
    let _e386 = cosTheta2_;
    t1_ = (_e385 + vec3(_e386));
    let _e389 = a2plusb2_;
    let _e390 = t0_;
    a_2 = sqrt(max(((_e389 + _e390) * 0.5f), vec3(0f)));
    let _e396 = a_2;
    let _e398 = (*cosTheta_4);
    t2_ = ((_e396 * 2f) * _e398);
    let _e400 = t1_;
    let _e401 = t2_;
    let _e403 = t1_;
    let _e404 = t2_;
    (*Rs) = ((_e400 - _e401) / (_e403 + _e404));
    let _e407 = cosTheta2_;
    let _e408 = a2plusb2_;
    let _e410 = sinTheta2_;
    let _e411 = sinTheta2_;
    t3_ = ((_e408 * _e407) + vec3((_e410 * _e411)));
    let _e415 = t2_;
    let _e416 = sinTheta2_;
    t4_ = (_e415 * _e416);
    let _e418 = (*Rs);
    let _e419 = t3_;
    let _e420 = t4_;
    let _e423 = t3_;
    let _e424 = t4_;
    (*Rp) = ((_e418 * (_e419 - _e420)) / (_e423 + _e424));
    return;
}

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_5: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_70: f32;
    var param_71: vec3<f32>;
    var param_72: vec3<f32>;
    var param_73: vec3<f32>;
    var param_74: vec3<f32>;

    let _e352 = (*cosTheta_5);
    param_70 = _e352;
    let _e353 = (*n_1);
    param_71 = _e353;
    let _e354 = (*k_1);
    param_72 = _e354;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_70), (&param_71), (&param_72), (&param_73), (&param_74));
    let _e355 = param_73;
    Rp_1 = _e355;
    let _e356 = param_74;
    Rs_1 = _e356;
    let _e357 = Rp_1;
    let _e358 = Rs_1;
    return ((_e357 + _e358) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_6: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_75: f32;
    var param_76: f32;

    let _e349 = (*cosTheta_6);
    c_1 = _e349;
    let _e350 = (*ior);
    let _e351 = (*ior);
    let _e353 = c_1;
    let _e354 = c_1;
    g2_ = (((_e350 * _e351) + (_e353 * _e354)) - 1f);
    let _e358 = g2_;
    if (_e358 < 0f) {
        return 1f;
    }
    let _e360 = g2_;
    g = sqrt(_e360);
    let _e362 = g;
    let _e363 = c_1;
    let _e365 = g;
    let _e366 = c_1;
    param_75 = ((_e362 - _e363) / (_e365 + _e366));
    let _e369 = mx_square_u0028_f1_u003b((&param_75));
    let _e371 = g;
    let _e372 = c_1;
    let _e374 = c_1;
    let _e377 = g;
    let _e378 = c_1;
    let _e380 = c_1;
    param_76 = ((((_e371 + _e372) * _e374) - 1f) / (((_e377 - _e378) * _e380) + 1f));
    let _e384 = mx_square_u0028_f1_u003b((&param_76));
    return ((0.5f * _e369) * (1f + _e384));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e344 = (*m_1);
    let _e345 = (*v_2);
    return (_e344 * _e345);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e349 = (*opd);
    phase = (6.2831855f * _e349);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e351 = val;
    let _e352 = var_;
    let _e356 = pos;
    let _e357 = phase;
    let _e359 = (*shift);
    let _e363 = var_;
    let _e365 = phase;
    let _e367 = phase;
    xyz = (((_e351 * sqrt((_e352 * 6.2831855f))) * cos(((_e356 * _e357) + _e359))) * exp(((-(_e363) * _e365) * _e367)));
    let _e371 = phase;
    let _e374 = (*shift)[0u];
    let _e378 = phase;
    let _e380 = phase;
    let _e385 = xyz[0u];
    xyz[0u] = (_e385 + ((0.00000001644083f * cos(((2239900f * _e371) + _e374))) * exp(((-4528200000f * _e378) * _e380))));
    let _e388 = xyz;
    return (_e388 / vec3(0.00000010685f));
}

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_7: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_77: vec3<f32>;
    var U: vec3<f32>;
    var V_4: vec3<f32>;
    var param_78: f32;
    var param_79: vec3<f32>;

    let _e357 = (*kappa2_);
    let _e358 = (*eta2_);
    k2_1 = (_e357 / _e358);
    let _e360 = (*cosTheta_7);
    let _e361 = (*cosTheta_7);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e360 * _e361)));
    let _e365 = (*eta2_);
    let _e366 = (*eta2_);
    let _e368 = k2_1;
    let _e369 = k2_1;
    let _e373 = (*eta1_);
    let _e374 = (*eta1_);
    let _e376 = sinThetaSqr;
    A_4 = (((_e365 * _e366) * (vec3<f32>(1f, 1f, 1f) - (_e368 * _e369))) - (_e376 * (_e373 * _e374)));
    let _e379 = A_4;
    let _e380 = A_4;
    let _e382 = (*eta2_);
    let _e384 = (*eta2_);
    let _e386 = k2_1;
    param_77 = (((_e382 * 2f) * _e384) * _e386);
    let _e388 = mx_square_u0028_vf3_u003b((&param_77));
    B_2 = sqrt(((_e379 * _e380) + _e388));
    let _e391 = A_4;
    let _e392 = B_2;
    U = sqrt(((_e391 + _e392) / vec3(2f)));
    let _e397 = B_2;
    let _e398 = A_4;
    V_4 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e397 - _e398) / vec3(2f))));
    let _e404 = (*eta1_);
    let _e406 = V_4;
    let _e408 = (*cosTheta_7);
    let _e410 = U;
    let _e411 = U;
    let _e413 = V_4;
    let _e414 = V_4;
    let _e417 = (*eta1_);
    let _e418 = (*cosTheta_7);
    param_78 = (_e417 * _e418);
    let _e420 = mx_square_u0028_f1_u003b((&param_78));
    (*phiS) = atan2(((_e406 * (2f * _e404)) * _e408), (((_e410 * _e411) + (_e413 * _e414)) - vec3(_e420)));
    let _e424 = (*eta1_);
    let _e426 = (*eta2_);
    let _e428 = (*eta2_);
    let _e430 = (*cosTheta_7);
    let _e432 = k2_1;
    let _e434 = U;
    let _e436 = k2_1;
    let _e437 = k2_1;
    let _e440 = V_4;
    let _e444 = (*eta2_);
    let _e445 = (*eta2_);
    let _e447 = k2_1;
    let _e448 = k2_1;
    let _e452 = (*cosTheta_7);
    param_79 = (((_e444 * _e445) * (vec3<f32>(1f, 1f, 1f) + (_e447 * _e448))) * _e452);
    let _e454 = mx_square_u0028_vf3_u003b((&param_79));
    let _e455 = (*eta1_);
    let _e456 = (*eta1_);
    let _e458 = U;
    let _e459 = U;
    let _e461 = V_4;
    let _e462 = V_4;
    (*phiP) = atan2(((((_e426 * (2f * _e424)) * _e428) * _e430) * (((_e432 * 2f) * _e434) - ((vec3<f32>(1f, 1f, 1f) - (_e436 * _e437)) * _e440))), (_e454 - (((_e458 * _e459) + (_e461 * _e462)) * (_e455 * _e456))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_8: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_80: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e354 = (*cosTheta_8);
    param_80 = clamp(_e354, 0f, 1f);
    let _e356 = mx_square_u0028_f1_u003b((&param_80));
    cosTheta2_1 = _e356;
    let _e357 = cosTheta2_1;
    sinTheta2_1 = (1f - _e357);
    let _e359 = (*ior_1);
    let _e360 = (*ior_1);
    let _e362 = sinTheta2_1;
    t0_1 = max(((_e359 * _e360) - _e362), 0f);
    let _e365 = t0_1;
    let _e366 = cosTheta2_1;
    t1_1 = (_e365 + _e366);
    let _e368 = t0_1;
    let _e371 = (*cosTheta_8);
    t2_1 = ((2f * sqrt(_e368)) * _e371);
    let _e373 = t1_1;
    let _e374 = t2_1;
    let _e376 = t1_1;
    let _e377 = t2_1;
    Rs_2 = ((_e373 - _e374) / (_e376 + _e377));
    let _e380 = cosTheta2_1;
    let _e381 = t0_1;
    let _e383 = sinTheta2_1;
    let _e384 = sinTheta2_1;
    t3_1 = ((_e380 * _e381) + (_e383 * _e384));
    let _e387 = t2_1;
    let _e388 = sinTheta2_1;
    t4_1 = (_e387 * _e388);
    let _e390 = Rs_2;
    let _e391 = t3_1;
    let _e392 = t4_1;
    let _e395 = t3_1;
    let _e396 = t4_1;
    Rp_2 = ((_e390 * (_e391 - _e392)) / (_e395 + _e396));
    let _e399 = Rp_2;
    let _e400 = Rs_2;
    return vec2<f32>(_e399, _e400);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e344 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e344, vec3(0.01f), vec3(0.99f)));
    let _e349 = sqrtF0_;
    let _e351 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e349) / (vec3<f32>(1f, 1f, 1f) - _e351));
}

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_9: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_81: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_82: f32;
    var param_83: f32;
    var R12_: vec2<f32>;
    var param_84: f32;
    var param_85: f32;
    var T121_: vec2<f32>;
    var f_1: vec3<f32>;
    var param_86: f32;
    var param_87: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_88: f32;
    var param_89: vec3<f32>;
    var param_90: vec3<f32>;
    var param_91: vec3<f32>;
    var param_92: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_93: f32;
    var param_94: f32;
    var param_95: vec3<f32>;
    var param_96: vec3<f32>;
    var param_97: vec3<f32>;
    var param_98: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_99: f32;
    var Cm: vec3<f32>;
    var m_2: i32;
    var Sm: vec3<f32>;
    var param_100: f32;
    var param_101: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_102: f32;
    var m_3: i32;
    var param_103: f32;
    var param_104: vec3<f32>;
    var param_105: mat3x3<f32>;
    var param_106: vec3<f32>;

    eta1_1 = 1f;
    let _e398 = (*fd_1).tf_ior;
    let _e399 = eta1_1;
    eta2_1 = max(_e398, _e399);
    let _e402 = (*fd_1).model;
    if (_e402 == 2i) {
        let _e405 = (*fd_1).F0_;
        param_81 = _e405;
        let _e406 = mx_f0_to_ior_u0028_vf3_u003b((&param_81));
        local_5 = _e406;
    } else {
        let _e408 = (*fd_1).ior;
        local_5 = _e408;
    }
    let _e409 = local_5;
    eta3_ = _e409;
    let _e411 = (*fd_1).model;
    if (_e411 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e414 = (*fd_1).extinction;
        local_6 = _e414;
    }
    let _e415 = local_6;
    kappa3_ = _e415;
    let _e416 = (*cosTheta_9);
    param_82 = _e416;
    let _e417 = mx_square_u0028_f1_u003b((&param_82));
    let _e419 = eta1_1;
    let _e420 = eta2_1;
    param_83 = (_e419 / _e420);
    let _e422 = mx_square_u0028_f1_u003b((&param_83));
    cosThetaT = sqrt((1f - ((1f - _e417) * _e422)));
    let _e426 = eta2_1;
    let _e427 = eta1_1;
    let _e429 = (*cosTheta_9);
    param_84 = _e429;
    param_85 = (_e426 / _e427);
    let _e430 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
    R12_ = _e430;
    let _e431 = cosThetaT;
    if (_e431 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e433 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e433);
    let _e436 = (*fd_1).model;
    if (_e436 == 2i) {
        let _e438 = cosThetaT;
        param_86 = _e438;
        let _e439 = (*fd_1);
        param_87 = _e439;
        let _e440 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_86), (&param_87));
        f_1 = _e440;
        let _e441 = f_1;
        R23p = (_e441 * 0.5f);
        let _e443 = f_1;
        R23s = (_e443 * 0.5f);
    } else {
        let _e445 = eta3_;
        let _e446 = eta2_1;
        let _e449 = kappa3_;
        let _e450 = eta2_1;
        let _e453 = cosThetaT;
        param_88 = _e453;
        param_89 = (_e445 / vec3(_e446));
        param_90 = (_e449 / vec3(_e450));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_88), (&param_89), (&param_90), (&param_91), (&param_92));
        let _e454 = param_91;
        R23p = _e454;
        let _e455 = param_92;
        R23s = _e455;
    }
    let _e456 = eta2_1;
    let _e457 = eta1_1;
    cosB = cos(atan((_e456 / _e457)));
    let _e461 = (*cosTheta_9);
    let _e462 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e461 < _e462)), 3.1415927f);
    let _e467 = (*fd_1).model;
    if (_e467 == 2i) {
        let _e470 = eta3_[0u];
        let _e471 = eta2_1;
        let _e475 = eta3_[1u];
        let _e476 = eta2_1;
        let _e480 = eta3_[2u];
        let _e481 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e470 < _e471)), select(0f, 3.1415927f, (_e475 < _e476)), select(0f, 3.1415927f, (_e480 < _e481)));
        let _e485 = phi23p;
        phi23s = _e485;
    } else {
        let _e486 = cosThetaT;
        param_93 = _e486;
        let _e487 = eta2_1;
        param_94 = _e487;
        let _e488 = eta3_;
        param_95 = _e488;
        let _e489 = kappa3_;
        param_96 = _e489;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_93), (&param_94), (&param_95), (&param_96), (&param_97), (&param_98));
        let _e490 = param_97;
        phi23p = _e490;
        let _e491 = param_98;
        phi23s = _e491;
    }
    let _e493 = R12_[0u];
    let _e494 = R23p;
    r123p = max(sqrt((_e494 * _e493)), vec3(0f));
    let _e500 = R12_[1u];
    let _e501 = R23s;
    r123s = max(sqrt((_e501 * _e500)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e507 = (*fd_1).tf_thickness;
    distMeters = (_e507 * 0.000000001f);
    let _e509 = eta2_1;
    let _e511 = cosThetaT;
    let _e513 = distMeters;
    opd_1 = (((2f * _e509) * _e511) * _e513);
    let _e516 = T121_[0u];
    param_99 = _e516;
    let _e517 = mx_square_u0028_f1_u003b((&param_99));
    let _e518 = R23p;
    let _e521 = R12_[0u];
    let _e522 = R23p;
    Rs_3 = ((_e518 * _e517) / (vec3<f32>(1f, 1f, 1f) - (_e522 * _e521)));
    let _e527 = R12_[0u];
    let _e528 = Rs_3;
    let _e531 = I;
    I = (_e531 + (vec3(_e527) + _e528));
    let _e533 = Rs_3;
    let _e535 = T121_[0u];
    Cm = (_e533 - vec3(_e535));
    m_2 = 1i;
    loop {
        let _e538 = m_2;
        if (_e538 <= 2i) {
            let _e540 = r123p;
            let _e541 = Cm;
            Cm = (_e541 * _e540);
            let _e543 = m_2;
            let _e545 = opd_1;
            let _e547 = m_2;
            let _e549 = phi23p;
            let _e551 = phi21_[0u];
            param_100 = (f32(_e543) * _e545);
            param_101 = ((_e549 + vec3(_e551)) * f32(_e547));
            let _e555 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_100), (&param_101));
            Sm = (_e555 * 2f);
            let _e557 = Cm;
            let _e558 = Sm;
            let _e560 = I;
            I = (_e560 + (_e557 * _e558));
            continue;
        } else {
            break;
        }
        continuing {
            let _e562 = m_2;
            m_2 = (_e562 + 1i);
        }
    }
    let _e565 = T121_[1u];
    param_102 = _e565;
    let _e566 = mx_square_u0028_f1_u003b((&param_102));
    let _e567 = R23s;
    let _e570 = R12_[1u];
    let _e571 = R23s;
    Rp_3 = ((_e567 * _e566) / (vec3<f32>(1f, 1f, 1f) - (_e571 * _e570)));
    let _e576 = R12_[1u];
    let _e577 = Rp_3;
    let _e580 = I;
    I = (_e580 + (vec3(_e576) + _e577));
    let _e582 = Rp_3;
    let _e584 = T121_[1u];
    Cm = (_e582 - vec3(_e584));
    m_3 = 1i;
    loop {
        let _e587 = m_3;
        if (_e587 <= 2i) {
            let _e589 = r123s;
            let _e590 = Cm;
            Cm = (_e590 * _e589);
            let _e592 = m_3;
            let _e594 = opd_1;
            let _e596 = m_3;
            let _e598 = phi23s;
            let _e600 = phi21_[1u];
            param_103 = (f32(_e592) * _e594);
            param_104 = ((_e598 + vec3(_e600)) * f32(_e596));
            let _e604 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_103), (&param_104));
            Sm = (_e604 * 2f);
            let _e606 = Cm;
            let _e607 = Sm;
            let _e609 = I;
            I = (_e609 + (_e606 * _e607));
            continue;
        } else {
            break;
        }
        continuing {
            let _e611 = m_3;
            m_3 = (_e611 + 1i);
        }
    }
    let _e613 = I;
    I = (_e613 * 0.5f);
    param_105 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e615 = I;
    param_106 = _e615;
    let _e616 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_105), (&param_106));
    I = clamp(_e616, vec3(0f), vec3(1f));
    let _e620 = I;
    return _e620;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_10: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_107: f32;
    var param_108: FresnelData;
    var param_109: f32;
    var param_110: f32;
    var param_111: f32;
    var param_112: vec3<f32>;
    var param_113: vec3<f32>;
    var param_114: f32;
    var param_115: FresnelData;

    let _e354 = (*fd_2).airy;
    if _e354 {
        let _e355 = (*cosTheta_10);
        param_107 = _e355;
        let _e356 = (*fd_2);
        param_108 = _e356;
        let _e357 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_107), (&param_108));
        return _e357;
    } else {
        let _e359 = (*fd_2).model;
        if (_e359 == 0i) {
            let _e361 = (*cosTheta_10);
            param_109 = _e361;
            let _e364 = (*fd_2).ior[0u];
            param_110 = _e364;
            let _e365 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_109), (&param_110));
            return vec3(_e365);
        } else {
            let _e368 = (*fd_2).model;
            if (_e368 == 1i) {
                let _e370 = (*cosTheta_10);
                param_111 = _e370;
                let _e372 = (*fd_2).ior;
                param_112 = _e372;
                let _e374 = (*fd_2).extinction;
                param_113 = _e374;
                let _e375 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_111), (&param_112), (&param_113));
                return _e375;
            } else {
                let _e376 = (*cosTheta_10);
                param_114 = _e376;
                let _e377 = (*fd_2);
                param_115 = _e377;
                let _e378 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_114), (&param_115));
                return _e378;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_116: mat4x4<f32>;
    var param_117: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_118: vec3<f32>;

    let _e350 = (*dir_2);
    let _e355 = (*transform_1);
    param_116 = _e355;
    param_117 = vec4<f32>(_e350.x, _e350.y, _e350.z, 0f);
    let _e356 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_116), (&param_117));
    envDir_1 = normalize(_e356.xyz);
    let _e359 = envDir_1;
    param_118 = _e359;
    let _e360 = mx_latlong_projection_u0028_vf3_u003b((&param_118));
    uv_2 = _e360;
    let _e361 = uv_2;
    let _e362 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e361, 0.0);
    return _e362.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_119: f32;

    let _e349 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e349 - 1.5f);
    let _e352 = (*dir_3)[1u];
    param_119 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_119));
    distortion = sqrt((1f - _e353));
    let _e356 = effectiveMaxMipLevel;
    let _e357 = (*envSamples);
    let _e359 = (*pdf);
    let _e361 = distortion;
    return max((_e356 - (0.5f * log2(((f32(_e357) * _e359) * _e361)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_120: f32;
    var param_121: f32;

    let _e348 = (*H);
    let _e350 = (*alpha_1);
    He = (_e348.xy / _e350);
    let _e352 = He;
    let _e353 = He;
    let _e356 = (*H)[2u];
    param_120 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_120));
    denom_1 = (dot(_e352, _e353) + _e357);
    let _e360 = (*alpha_1)[0u];
    let _e363 = (*alpha_1)[1u];
    let _e365 = denom_1;
    param_121 = _e365;
    let _e366 = mx_square_u0028_f1_u003b((&param_121));
    return (1f / (((3.1415927f * _e360) * _e363) * _e366));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_7: ptr<function, f32>) -> f32 {
    var param_122: vec3<f32>;
    var param_123: vec2<f32>;

    let _e348 = (*H_1);
    param_122 = _e348;
    let _e349 = (*alpha_2);
    param_123 = _e349;
    let _e350 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_122), (&param_123));
    let _e351 = (*G1V);
    let _e353 = (*NdotV_7);
    return ((_e350 * _e351) / (4f * _e353));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e346 = (*R_1);
    let _e347 = (*N_8);
    let _e348 = (*ior_2);
    (*R_1) = refract(_e346, _e347, (1f / _e348));
    let _e351 = (*R_1);
    let _e352 = (*R_1);
    let _e353 = (*N_8);
    let _e356 = (*N_8);
    N1_ = normalize(((_e351 * dot(_e352, _e353)) - (_e356 * 0.5f)));
    let _e360 = (*R_1);
    let _e361 = N1_;
    let _e362 = (*ior_2);
    return refract(_e360, _e361, _e362);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_5: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_6: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e352 = (*V_5);
    let _e354 = (*alpha_3);
    let _e355 = (_e352.xy * _e354);
    let _e357 = (*V_5)[2u];
    (*V_5) = normalize(vec3<f32>(_e355.x, _e355.y, _e357));
    let _e363 = (*Xi)[0u];
    phi = (6.2831855f * _e363);
    let _e366 = (*Xi)[1u];
    let _e369 = (*V_5)[2u];
    let _e373 = (*V_5)[2u];
    z = (((1f - _e366) * (1f + _e369)) - _e373);
    let _e375 = z;
    let _e376 = z;
    sinTheta = sqrt(clamp((1f - (_e375 * _e376)), 0f, 1f));
    let _e381 = sinTheta;
    let _e382 = phi;
    x_6 = (_e381 * cos(_e382));
    let _e385 = sinTheta;
    let _e386 = phi;
    y = (_e385 * sin(_e386));
    let _e389 = x_6;
    let _e390 = y;
    let _e391 = z;
    c_2 = vec3<f32>(_e389, _e390, _e391);
    let _e393 = c_2;
    let _e394 = (*V_5);
    H_2 = (_e393 + _e394);
    let _e396 = H_2;
    let _e398 = (*alpha_3);
    let _e399 = (_e396.xy * _e398);
    let _e401 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e399.x, _e399.y, max(_e401, 0f)));
    let _e407 = H_2;
    return _e407;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e343 = (*i_1);
    return fract(((f32(_e343) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_124: i32;

    let _e345 = (*i_2);
    let _e348 = (*numSamples);
    let _e351 = (*i_2);
    param_124 = _e351;
    let _e352 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_124));
    return vec2<f32>(((f32(_e345) + 0.5f) / f32(_e348)), _e352);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_11: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_125: f32;
    var tanTheta2_: f32;
    var param_126: f32;

    let _e348 = (*cosTheta_11);
    param_125 = _e348;
    let _e349 = mx_square_u0028_f1_u003b((&param_125));
    cosTheta2_2 = _e349;
    let _e350 = cosTheta2_2;
    let _e352 = cosTheta2_2;
    tanTheta2_ = ((1f - _e350) / _e352);
    let _e354 = (*alpha_4);
    param_126 = _e354;
    let _e355 = mx_square_u0028_f1_u003b((&param_126));
    let _e356 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e355 * _e356)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e344 = (*alpha_5)[0u];
    let _e346 = (*alpha_5)[1u];
    return sqrt((_e344 * _e346));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_9: ptr<function, vec3<f32>>, V_6: ptr<function, vec3<f32>>, X: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_8: f32;
    var avgAlpha: f32;
    var param_127: vec2<f32>;
    var G1V_1: f32;
    var param_128: f32;
    var param_129: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_3: i32;
    var Xi_1: vec2<f32>;
    var param_130: i32;
    var param_131: i32;
    var H_3: vec3<f32>;
    var param_132: vec2<f32>;
    var param_133: vec3<f32>;
    var param_134: vec2<f32>;
    var L_5: vec3<f32>;
    var local_7: vec3<f32>;
    var param_135: vec3<f32>;
    var param_136: vec3<f32>;
    var param_137: f32;
    var NdotL_6: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_138: mat3x3<f32>;
    var param_139: vec3<f32>;
    var pdf_1: f32;
    var param_140: vec3<f32>;
    var param_141: vec2<f32>;
    var param_142: f32;
    var param_143: f32;
    var lod_2: f32;
    var param_144: vec3<f32>;
    var param_145: f32;
    var param_146: f32;
    var param_147: i32;
    var sampleColor: vec3<f32>;
    var param_148: vec3<f32>;
    var param_149: mat4x4<f32>;
    var param_150: f32;
    var F: vec3<f32>;
    var param_151: f32;
    var param_152: FresnelData;
    var G_1: f32;
    var param_153: f32;
    var param_154: f32;
    var param_155: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e399 = (*X);
    let _e400 = (*X);
    let _e401 = (*N_9);
    let _e403 = (*N_9);
    (*X) = normalize((_e399 - (_e403 * dot(_e400, _e401))));
    let _e407 = (*N_9);
    let _e408 = (*X);
    Y = cross(_e407, _e408);
    let _e410 = (*X);
    let _e411 = Y;
    let _e412 = (*N_9);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e410.x, _e410.y, _e410.z), vec3<f32>(_e411.x, _e411.y, _e411.z), vec3<f32>(_e412.x, _e412.y, _e412.z));
    let _e426 = (*V_6);
    let _e427 = (*X);
    let _e429 = (*V_6);
    let _e430 = Y;
    let _e432 = (*V_6);
    let _e433 = (*N_9);
    (*V_6) = vec3<f32>(dot(_e426, _e427), dot(_e429, _e430), dot(_e432, _e433));
    let _e437 = (*V_6)[2u];
    NdotV_8 = clamp(_e437, 0.00000001f, 1f);
    let _e439 = (*alpha_6);
    param_127 = _e439;
    let _e440 = mx_average_alpha_u0028_vf2_u003b((&param_127));
    avgAlpha = _e440;
    let _e441 = NdotV_8;
    param_128 = _e441;
    let _e442 = avgAlpha;
    param_129 = _e442;
    let _e443 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_128), (&param_129));
    G1V_1 = _e443;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e444 = i_3;
        let _e445 = envRadianceSamples;
        if (_e444 < _e445) {
            let _e447 = i_3;
            param_130 = _e447;
            let _e448 = envRadianceSamples;
            param_131 = _e448;
            let _e449 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_130), (&param_131));
            Xi_1 = _e449;
            let _e450 = Xi_1;
            param_132 = _e450;
            let _e451 = (*V_6);
            param_133 = _e451;
            let _e452 = (*alpha_6);
            param_134 = _e452;
            let _e453 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_132), (&param_133), (&param_134));
            H_3 = _e453;
            let _e455 = (*fd_3).refraction;
            if _e455 {
                let _e456 = (*V_6);
                param_135 = -(_e456);
                let _e458 = H_3;
                param_136 = _e458;
                let _e461 = (*fd_3).ior[0u];
                param_137 = _e461;
                let _e462 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_135), (&param_136), (&param_137));
                local_7 = _e462;
            } else {
                let _e463 = (*V_6);
                let _e464 = H_3;
                local_7 = -(reflect(_e463, _e464));
            }
            let _e467 = local_7;
            L_5 = _e467;
            let _e469 = L_5[2u];
            NdotL_6 = clamp(_e469, 0.00000001f, 1f);
            let _e471 = (*V_6);
            let _e472 = H_3;
            VdotH = clamp(dot(_e471, _e472), 0.00000001f, 1f);
            let _e475 = tangentToWorld;
            param_138 = _e475;
            let _e476 = L_5;
            param_139 = _e476;
            let _e477 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_138), (&param_139));
            Lw = _e477;
            let _e478 = H_3;
            param_140 = _e478;
            let _e479 = (*alpha_6);
            param_141 = _e479;
            let _e480 = G1V_1;
            param_142 = _e480;
            let _e481 = NdotV_8;
            param_143 = _e481;
            let _e482 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_140), (&param_141), (&param_142), (&param_143));
            pdf_1 = _e482;
            let _e483 = Lw;
            param_144 = _e483;
            let _e484 = pdf_1;
            param_145 = _e484;
            param_146 = 0f;
            let _e485 = envRadianceSamples;
            param_147 = _e485;
            let _e486 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_144), (&param_145), (&param_146), (&param_147));
            lod_2 = _e486;
            let _e487 = mtlxEnvMatrix_u0028_();
            let _e488 = Lw;
            param_148 = _e488;
            param_149 = _e487;
            let _e489 = lod_2;
            param_150 = _e489;
            let _e490 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_148), (&param_149), (&param_150));
            sampleColor = _e490;
            let _e491 = VdotH;
            param_151 = _e491;
            let _e492 = (*fd_3);
            param_152 = _e492;
            let _e493 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_151), (&param_152));
            F = _e493;
            let _e494 = NdotL_6;
            param_153 = _e494;
            let _e495 = NdotV_8;
            param_154 = _e495;
            let _e496 = avgAlpha;
            param_155 = _e496;
            let _e497 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_153), (&param_154), (&param_155));
            G_1 = _e497;
            let _e499 = (*fd_3).refraction;
            if _e499 {
                let _e500 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e500);
            } else {
                let _e502 = F;
                let _e503 = G_1;
                local_8 = (_e502 * _e503);
            }
            let _e505 = local_8;
            FG = _e505;
            let _e506 = sampleColor;
            let _e507 = FG;
            let _e509 = radiance;
            radiance = (_e509 + (_e506 * _e507));
            continue;
        } else {
            break;
        }
        continuing {
            let _e511 = i_3;
            i_3 = (_e511 + 1i);
        }
    }
    let _e513 = G1V_1;
    let _e514 = envRadianceSamples;
    let _e517 = radiance;
    radiance = (_e517 / vec3((_e513 * f32(_e514))));
    let _e520 = radiance;
    let _e523 = unnamed.skyPower;
    return (select(_e520, vec3<f32>(0f, 0f, 0f), false) * _e523);
}

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_10: ptr<function, vec3<f32>>, V_7: ptr<function, vec3<f32>>, X_1: ptr<function, vec3<f32>>, alpha_7: ptr<function, vec2<f32>>, distribution_1: ptr<function, i32>, fd_4: ptr<function, FresnelData>, tint_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_156: vec3<f32>;
    var param_157: vec3<f32>;
    var param_158: vec3<f32>;
    var param_159: vec3<f32>;
    var param_160: vec2<f32>;
    var param_161: i32;
    var param_162: FresnelData;

    (*fd_4).refraction = true;
    if false {
        let _e357 = (*tint_1);
        param_156 = _e357;
        let _e358 = mx_square_u0028_vf3_u003b((&param_156));
        (*tint_1) = _e358;
    }
    let _e359 = (*N_10);
    param_157 = _e359;
    let _e360 = (*V_7);
    param_158 = _e360;
    let _e361 = (*X_1);
    param_159 = _e361;
    let _e362 = (*alpha_7);
    param_160 = _e362;
    let _e363 = (*distribution_1);
    param_161 = _e363;
    let _e364 = (*fd_4);
    param_162 = _e364;
    let _e365 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_157), (&param_158), (&param_159), (&param_160), (&param_161), (&param_162));
    let _e366 = (*tint_1);
    return (_e365 * _e366);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_2: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e344 = (*F0_2);
    sqrtF0_1 = sqrt(clamp(_e344, 0.01f, 0.99f));
    let _e347 = sqrtF0_1;
    let _e349 = sqrtF0_1;
    return ((1f + _e347) / (1f - _e349));
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_7: f32;
    var y_1: f32;
    var x2_1: f32;
    var param_163: f32;
    var y2_: f32;
    var param_164: f32;
    var r_1: vec4<f32>;
    var AB: vec2<f32>;

    let _e354 = (*NdotV_9);
    x_7 = _e354;
    let _e355 = (*alpha_8);
    y_1 = _e355;
    let _e356 = x_7;
    param_163 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_163));
    x2_1 = _e357;
    let _e358 = y_1;
    param_164 = _e358;
    let _e359 = mx_square_u0028_f1_u003b((&param_164));
    y2_ = _e359;
    let _e360 = x_7;
    let _e363 = y_1;
    let _e366 = x_7;
    let _e368 = y_1;
    let _e371 = x2_1;
    let _e374 = y2_;
    let _e377 = x2_1;
    let _e379 = y_1;
    let _e382 = x_7;
    let _e384 = y2_;
    let _e387 = x2_1;
    let _e389 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e360)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e363)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e366) * _e368)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e371)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e374)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e377) * _e379)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e382) * _e384)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e387) * _e389));
    let _e392 = r_1;
    let _e394 = r_1;
    AB = clamp((_e392.xy / _e394.zw), vec2(0f), vec2(1f));
    let _e400 = (*F0_3);
    let _e402 = AB[0u];
    let _e404 = (*F90_1);
    let _e406 = AB[1u];
    return ((_e400 * _e402) + (_e404 * _e406));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_10: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_165: f32;
    var param_166: f32;
    var param_167: vec3<f32>;
    var param_168: vec3<f32>;

    let _e350 = (*NdotV_10);
    param_165 = _e350;
    let _e351 = (*alpha_9);
    param_166 = _e351;
    let _e352 = (*F0_4);
    param_167 = _e352;
    let _e353 = (*F90_2);
    param_168 = _e353;
    let _e354 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_165), (&param_166), (&param_167), (&param_168));
    return _e354;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_11: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_5: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_169: f32;
    var param_170: f32;
    var param_171: vec3<f32>;
    var param_172: vec3<f32>;

    let _e350 = (*F0_5);
    let _e352 = (*F90_3);
    let _e354 = (*NdotV_11);
    param_169 = _e354;
    let _e355 = (*alpha_10);
    param_170 = _e355;
    param_171 = vec3(_e350);
    param_172 = vec3(_e352);
    let _e356 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_169), (&param_170), (&param_171), (&param_172));
    return _e356.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_6: vec3<f32>;
    var param_173: f32;
    var param_174: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3411_: bool;

    param_173 = 1f;
    let _e348 = (*fd_5);
    param_174 = _e348;
    let _e349 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_173), (&param_174));
    F0_6 = _e349;
    let _e351 = (*fd_5).model;
    let _e352 = (_e351 == 2i);
    phi_3411_ = _e352;
    if _e352 {
        let _e354 = (*fd_5).airy;
        phi_3411_ = !(_e354);
    }
    let _e357 = phi_3411_;
    if _e357 {
        let _e359 = (*fd_5).F90_;
        local_9 = _e359;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e360 = local_9;
    F90_4 = _e360;
    let _e361 = F0_6;
    let _e362 = F90_4;
    let _e363 = F0_6;
    return (_e361 + ((_e362 - _e363) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_12: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_175: FresnelData;
    var Ess: f32;
    var param_176: f32;
    var param_177: f32;
    var param_178: f32;
    var param_179: f32;

    let _e352 = (*fd_6);
    param_175 = _e352;
    let _e353 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_175));
    Fss = _e353;
    let _e354 = (*NdotV_12);
    param_176 = _e354;
    let _e355 = (*alpha_11);
    param_177 = _e355;
    param_178 = 1f;
    param_179 = 1f;
    let _e356 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_176), (&param_177), (&param_178), (&param_179));
    Ess = _e356;
    let _e357 = Fss;
    let _e358 = Ess;
    let _e361 = Ess;
    return (vec3(1f) + ((_e357 * (1f - _e358)) / vec3(_e361)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_7: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_5: ptr<function, vec3<f32>>, exponent_2: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e350 = (*tf_thickness);
    fd_7.airy = (_e350 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e355 = (*F0_7);
    fd_7.F0_ = _e355;
    let _e357 = (*F82_);
    fd_7.F82_ = _e357;
    let _e359 = (*F90_5);
    fd_7.F90_ = _e359;
    let _e361 = (*exponent_2);
    fd_7.exponent = _e361;
    let _e363 = (*tf_thickness);
    fd_7.tf_thickness = _e363;
    let _e365 = (*tf_ior);
    fd_7.tf_ior = _e365;
    fd_7.refraction = false;
    let _e368 = fd_7;
    return _e368;
}

fn mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_14: ptr<function, ClosureData>, weight_4: ptr<function, f32>, color0_1: ptr<function, vec3<f32>>, color82_: ptr<function, vec3<f32>>, color90_1: ptr<function, vec3<f32>>, exponent_3: ptr<function, f32>, roughness_8: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, distribution_2: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_8: vec3<f32>;
    var L_6: vec3<f32>;
    var param_180: vec3<f32>;
    var param_181: vec3<f32>;
    var NdotV_13: f32;
    var safeColor0_: vec3<f32>;
    var safeColor82_: vec3<f32>;
    var safeColor90_: vec3<f32>;
    var fd_8: FresnelData;
    var param_182: vec3<f32>;
    var param_183: vec3<f32>;
    var param_184: vec3<f32>;
    var param_185: f32;
    var param_186: f32;
    var param_187: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_188: vec2<f32>;
    var Y_1: vec3<f32>;
    var H_4: vec3<f32>;
    var NdotL_7: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_1: vec3<f32>;
    var param_189: f32;
    var param_190: FresnelData;
    var D: f32;
    var param_191: vec3<f32>;
    var param_192: vec2<f32>;
    var G_2: f32;
    var param_193: f32;
    var param_194: f32;
    var param_195: f32;
    var comp: vec3<f32>;
    var param_196: f32;
    var param_197: f32;
    var param_198: FresnelData;
    var dirAlbedo_2: vec3<f32>;
    var param_199: f32;
    var param_200: f32;
    var param_201: vec3<f32>;
    var param_202: vec3<f32>;
    var avgDirAlbedo: f32;
    var comp_1: vec3<f32>;
    var param_203: f32;
    var param_204: f32;
    var param_205: FresnelData;
    var dirAlbedo_3: vec3<f32>;
    var param_206: f32;
    var param_207: f32;
    var param_208: vec3<f32>;
    var param_209: vec3<f32>;
    var avgDirAlbedo_1: f32;
    var avgF0_: f32;
    var param_210: f32;
    var param_211: vec3<f32>;
    var param_212: vec3<f32>;
    var param_213: vec3<f32>;
    var param_214: vec2<f32>;
    var param_215: i32;
    var param_216: FresnelData;
    var param_217: vec3<f32>;
    var comp_2: vec3<f32>;
    var param_218: f32;
    var param_219: f32;
    var param_220: FresnelData;
    var dirAlbedo_4: vec3<f32>;
    var param_221: f32;
    var param_222: f32;
    var param_223: vec3<f32>;
    var param_224: vec3<f32>;
    var avgDirAlbedo_2: f32;
    var Li_4: vec3<f32>;
    var param_225: vec3<f32>;
    var param_226: vec3<f32>;
    var param_227: vec3<f32>;
    var param_228: vec2<f32>;
    var param_229: i32;
    var param_230: FresnelData;
    var phi_5422_: bool;

    let _e436 = (*weight_4);
    if (_e436 < 0.00000001f) {
        return;
    }
    let _e439 = (*closureData_14).closureType;
    let _e441 = (*scatter_mode);
    if ((_e439 != 2i) && (_e441 == 1i)) {
        return;
    }
    let _e445 = (*closureData_14).V;
    V_8 = _e445;
    let _e447 = (*closureData_14).L;
    L_6 = _e447;
    let _e448 = (*retroreflective);
    phi_5422_ = _e448;
    if _e448 {
        let _e450 = (*closureData_14).closureType;
        phi_5422_ = (_e450 != 2i);
    }
    let _e453 = phi_5422_;
    if _e453 {
        let _e454 = V_8;
        let _e456 = (*N_11);
        V_8 = reflect(-(_e454), _e456);
    }
    let _e458 = (*N_11);
    param_180 = _e458;
    let _e459 = V_8;
    param_181 = _e459;
    let _e460 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_180), (&param_181));
    (*N_11) = _e460;
    let _e461 = (*N_11);
    let _e462 = V_8;
    NdotV_13 = clamp(dot(_e461, _e462), 0.00000001f, 1f);
    let _e465 = (*color0_1);
    safeColor0_ = max(_e465, vec3(0f));
    let _e468 = (*color82_);
    safeColor82_ = max(_e468, vec3(0f));
    let _e471 = (*color90_1);
    safeColor90_ = max(_e471, vec3(0f));
    let _e474 = safeColor0_;
    param_182 = _e474;
    let _e475 = safeColor82_;
    param_183 = _e475;
    let _e476 = safeColor90_;
    param_184 = _e476;
    let _e477 = (*exponent_3);
    param_185 = _e477;
    let _e478 = (*thinfilm_thickness);
    param_186 = _e478;
    let _e479 = (*thinfilm_ior);
    param_187 = _e479;
    let _e480 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_182), (&param_183), (&param_184), (&param_185), (&param_186), (&param_187));
    fd_8 = _e480;
    let _e481 = (*roughness_8);
    safeAlpha = clamp(_e481, vec2(0.00000001f), vec2(1f));
    let _e485 = safeAlpha;
    param_188 = _e485;
    let _e486 = mx_average_alpha_u0028_vf2_u003b((&param_188));
    avgAlpha_1 = _e486;
    let _e488 = (*closureData_14).closureType;
    if (_e488 == 1i) {
        let _e490 = (*X_2);
        let _e491 = (*X_2);
        let _e492 = (*N_11);
        let _e494 = (*N_11);
        (*X_2) = normalize((_e490 - (_e494 * dot(_e491, _e492))));
        let _e498 = (*N_11);
        let _e499 = (*X_2);
        Y_1 = cross(_e498, _e499);
        let _e501 = L_6;
        let _e502 = V_8;
        H_4 = normalize((_e501 + _e502));
        let _e505 = (*N_11);
        let _e506 = L_6;
        NdotL_7 = clamp(dot(_e505, _e506), 0.00000001f, 1f);
        let _e509 = V_8;
        let _e510 = H_4;
        VdotH_1 = clamp(dot(_e509, _e510), 0.00000001f, 1f);
        let _e513 = H_4;
        let _e514 = (*X_2);
        let _e516 = H_4;
        let _e517 = Y_1;
        let _e519 = H_4;
        let _e520 = (*N_11);
        Ht = vec3<f32>(dot(_e513, _e514), dot(_e516, _e517), dot(_e519, _e520));
        let _e523 = VdotH_1;
        param_189 = _e523;
        let _e524 = fd_8;
        param_190 = _e524;
        let _e525 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_189), (&param_190));
        F_1 = _e525;
        let _e526 = Ht;
        param_191 = _e526;
        let _e527 = safeAlpha;
        param_192 = _e527;
        let _e528 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_191), (&param_192));
        D = _e528;
        let _e529 = NdotL_7;
        param_193 = _e529;
        let _e530 = NdotV_13;
        param_194 = _e530;
        let _e531 = avgAlpha_1;
        param_195 = _e531;
        let _e532 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_193), (&param_194), (&param_195));
        G_2 = _e532;
        let _e533 = NdotV_13;
        param_196 = _e533;
        let _e534 = avgAlpha_1;
        param_197 = _e534;
        let _e535 = fd_8;
        param_198 = _e535;
        let _e536 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_196), (&param_197), (&param_198));
        comp = _e536;
        let _e537 = NdotV_13;
        param_199 = _e537;
        let _e538 = avgAlpha_1;
        param_200 = _e538;
        let _e539 = safeColor0_;
        param_201 = _e539;
        let _e540 = safeColor90_;
        param_202 = _e540;
        let _e541 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_199), (&param_200), (&param_201), (&param_202));
        let _e542 = comp;
        dirAlbedo_2 = (_e541 * _e542);
        let _e544 = dirAlbedo_2;
        avgDirAlbedo = dot(_e544, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e546 = avgDirAlbedo;
        let _e547 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e546 * _e547)));
        let _e552 = D;
        let _e553 = F_1;
        let _e555 = G_2;
        let _e557 = comp;
        let _e560 = (*closureData_14).occlusion;
        let _e562 = (*weight_4);
        let _e564 = NdotV_13;
        (*bsdf_3).response = ((((((_e553 * _e552) * _e555) * _e557) * _e560) * _e562) / vec3((4f * _e564)));
    } else {
        let _e570 = (*closureData_14).closureType;
        if (_e570 == 2i) {
            let _e572 = NdotV_13;
            param_203 = _e572;
            let _e573 = avgAlpha_1;
            param_204 = _e573;
            let _e574 = fd_8;
            param_205 = _e574;
            let _e575 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_203), (&param_204), (&param_205));
            comp_1 = _e575;
            let _e576 = NdotV_13;
            param_206 = _e576;
            let _e577 = avgAlpha_1;
            param_207 = _e577;
            let _e578 = safeColor0_;
            param_208 = _e578;
            let _e579 = safeColor90_;
            param_209 = _e579;
            let _e580 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_206), (&param_207), (&param_208), (&param_209));
            let _e581 = comp_1;
            dirAlbedo_3 = (_e580 * _e581);
            let _e583 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e583, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e585 = avgDirAlbedo_1;
            let _e586 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e585 * _e586)));
            let _e591 = (*scatter_mode);
            if (_e591 != 0i) {
                let _e593 = safeColor0_;
                avgF0_ = dot(_e593, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e595 = avgF0_;
                param_210 = _e595;
                let _e596 = mx_f0_to_ior_u0028_f1_u003b((&param_210));
                fd_8.ior = vec3(_e596);
                let _e599 = (*N_11);
                param_211 = _e599;
                let _e600 = V_8;
                param_212 = _e600;
                let _e601 = (*X_2);
                param_213 = _e601;
                let _e602 = safeAlpha;
                param_214 = _e602;
                let _e603 = (*distribution_2);
                param_215 = _e603;
                let _e604 = fd_8;
                param_216 = _e604;
                param_217 = vec3<f32>(1f, 1f, 1f);
                let _e605 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_211), (&param_212), (&param_213), (&param_214), (&param_215), (&param_216), (&param_217));
                let _e606 = (*weight_4);
                (*bsdf_3).response = (_e605 * _e606);
            }
        } else {
            let _e610 = (*closureData_14).closureType;
            if (_e610 == 3i) {
                let _e612 = NdotV_13;
                param_218 = _e612;
                let _e613 = avgAlpha_1;
                param_219 = _e613;
                let _e614 = fd_8;
                param_220 = _e614;
                let _e615 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_218), (&param_219), (&param_220));
                comp_2 = _e615;
                let _e616 = NdotV_13;
                param_221 = _e616;
                let _e617 = avgAlpha_1;
                param_222 = _e617;
                let _e618 = safeColor0_;
                param_223 = _e618;
                let _e619 = safeColor90_;
                param_224 = _e619;
                let _e620 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_221), (&param_222), (&param_223), (&param_224));
                let _e621 = comp_2;
                dirAlbedo_4 = (_e620 * _e621);
                let _e623 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e623, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e625 = avgDirAlbedo_2;
                let _e626 = (*weight_4);
                (*bsdf_3).throughput = vec3((1f - (_e625 * _e626)));
                let _e631 = (*N_11);
                param_225 = _e631;
                let _e632 = V_8;
                param_226 = _e632;
                let _e633 = (*X_2);
                param_227 = _e633;
                let _e634 = safeAlpha;
                param_228 = _e634;
                let _e635 = (*distribution_2);
                param_229 = _e635;
                let _e636 = fd_8;
                param_230 = _e636;
                let _e637 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_225), (&param_226), (&param_227), (&param_228), (&param_229), (&param_230));
                Li_4 = _e637;
                let _e638 = Li_4;
                let _e639 = comp_2;
                let _e641 = (*weight_4);
                (*bsdf_3).response = ((_e638 * _e639) * _e641);
            }
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_231: f32;

    let _e344 = (*ior_3);
    let _e346 = (*ior_3);
    param_231 = ((_e344 - 1f) / (_e346 + 1f));
    let _e349 = mx_square_u0028_f1_u003b((&param_231));
    return _e349;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e347 = (*tf_thickness_1);
    fd_9.airy = (_e347 > 0f);
    let _e350 = (*ior_4);
    fd_9.ior = vec3(_e350);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e358 = (*tf_thickness_1);
    fd_9.tf_thickness = _e358;
    let _e360 = (*tf_ior_1);
    fd_9.tf_ior = _e360;
    fd_9.refraction = false;
    let _e363 = fd_9;
    return _e363;
}

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_15: ptr<function, ClosureData>, weight_5: ptr<function, f32>, tint_2: ptr<function, vec3<f32>>, ior_5: ptr<function, f32>, roughness_9: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_12: ptr<function, vec3<f32>>, X_3: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode_1: ptr<function, i32>, bsdf_4: ptr<function, BSDF>) {
    var V_9: vec3<f32>;
    var L_7: vec3<f32>;
    var param_232: vec3<f32>;
    var param_233: vec3<f32>;
    var NdotV_14: f32;
    var fd_10: FresnelData;
    var param_234: f32;
    var param_235: f32;
    var param_236: f32;
    var F0_8: f32;
    var param_237: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_238: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_2: vec3<f32>;
    var H_5: vec3<f32>;
    var NdotL_8: f32;
    var VdotH_2: f32;
    var Ht_1: vec3<f32>;
    var F_2: vec3<f32>;
    var param_239: f32;
    var param_240: FresnelData;
    var D_1: f32;
    var param_241: vec3<f32>;
    var param_242: vec2<f32>;
    var G_3: f32;
    var param_243: f32;
    var param_244: f32;
    var param_245: f32;
    var comp_3: vec3<f32>;
    var param_246: f32;
    var param_247: f32;
    var param_248: FresnelData;
    var dirAlbedo_5: vec3<f32>;
    var param_249: f32;
    var param_250: f32;
    var param_251: f32;
    var param_252: f32;
    var comp_4: vec3<f32>;
    var param_253: f32;
    var param_254: f32;
    var param_255: FresnelData;
    var dirAlbedo_6: vec3<f32>;
    var param_256: f32;
    var param_257: f32;
    var param_258: f32;
    var param_259: f32;
    var param_260: vec3<f32>;
    var param_261: vec3<f32>;
    var param_262: vec3<f32>;
    var param_263: vec2<f32>;
    var param_264: i32;
    var param_265: FresnelData;
    var param_266: vec3<f32>;
    var comp_5: vec3<f32>;
    var param_267: f32;
    var param_268: f32;
    var param_269: FresnelData;
    var dirAlbedo_7: vec3<f32>;
    var param_270: f32;
    var param_271: f32;
    var param_272: f32;
    var param_273: f32;
    var Li_5: vec3<f32>;
    var param_274: vec3<f32>;
    var param_275: vec3<f32>;
    var param_276: vec3<f32>;
    var param_277: vec2<f32>;
    var param_278: i32;
    var param_279: FresnelData;
    var phi_4391_: bool;

    let _e426 = (*weight_5);
    if (_e426 < 0.00000001f) {
        return;
    }
    let _e429 = (*closureData_15).closureType;
    let _e431 = (*scatter_mode_1);
    if ((_e429 != 2i) && (_e431 == 1i)) {
        return;
    }
    let _e435 = (*closureData_15).V;
    V_9 = _e435;
    let _e437 = (*closureData_15).L;
    L_7 = _e437;
    let _e438 = (*retroreflective_1);
    phi_4391_ = _e438;
    if _e438 {
        let _e440 = (*closureData_15).closureType;
        phi_4391_ = (_e440 != 2i);
    }
    let _e443 = phi_4391_;
    if _e443 {
        let _e444 = V_9;
        let _e446 = (*N_12);
        V_9 = reflect(-(_e444), _e446);
    }
    let _e448 = (*N_12);
    param_232 = _e448;
    let _e449 = V_9;
    param_233 = _e449;
    let _e450 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_232), (&param_233));
    (*N_12) = _e450;
    let _e451 = (*N_12);
    let _e452 = V_9;
    NdotV_14 = clamp(dot(_e451, _e452), 0.00000001f, 1f);
    let _e455 = (*ior_5);
    param_234 = _e455;
    let _e456 = (*thinfilm_thickness_1);
    param_235 = _e456;
    let _e457 = (*thinfilm_ior_1);
    param_236 = _e457;
    let _e458 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_234), (&param_235), (&param_236));
    fd_10 = _e458;
    let _e459 = (*ior_5);
    param_237 = _e459;
    let _e460 = mx_ior_to_f0_u0028_f1_u003b((&param_237));
    F0_8 = _e460;
    let _e461 = (*roughness_9);
    safeAlpha_1 = clamp(_e461, vec2(0.00000001f), vec2(1f));
    let _e465 = safeAlpha_1;
    param_238 = _e465;
    let _e466 = mx_average_alpha_u0028_vf2_u003b((&param_238));
    avgAlpha_2 = _e466;
    let _e467 = (*tint_2);
    safeTint = max(_e467, vec3(0f));
    let _e471 = (*closureData_15).closureType;
    if (_e471 == 1i) {
        let _e473 = (*X_3);
        let _e474 = (*X_3);
        let _e475 = (*N_12);
        let _e477 = (*N_12);
        (*X_3) = normalize((_e473 - (_e477 * dot(_e474, _e475))));
        let _e481 = (*N_12);
        let _e482 = (*X_3);
        Y_2 = cross(_e481, _e482);
        let _e484 = L_7;
        let _e485 = V_9;
        H_5 = normalize((_e484 + _e485));
        let _e488 = (*N_12);
        let _e489 = L_7;
        NdotL_8 = clamp(dot(_e488, _e489), 0.00000001f, 1f);
        let _e492 = V_9;
        let _e493 = H_5;
        VdotH_2 = clamp(dot(_e492, _e493), 0.00000001f, 1f);
        let _e496 = H_5;
        let _e497 = (*X_3);
        let _e499 = H_5;
        let _e500 = Y_2;
        let _e502 = H_5;
        let _e503 = (*N_12);
        Ht_1 = vec3<f32>(dot(_e496, _e497), dot(_e499, _e500), dot(_e502, _e503));
        let _e506 = VdotH_2;
        param_239 = _e506;
        let _e507 = fd_10;
        param_240 = _e507;
        let _e508 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_239), (&param_240));
        F_2 = _e508;
        let _e509 = Ht_1;
        param_241 = _e509;
        let _e510 = safeAlpha_1;
        param_242 = _e510;
        let _e511 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_241), (&param_242));
        D_1 = _e511;
        let _e512 = NdotL_8;
        param_243 = _e512;
        let _e513 = NdotV_14;
        param_244 = _e513;
        let _e514 = avgAlpha_2;
        param_245 = _e514;
        let _e515 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_243), (&param_244), (&param_245));
        G_3 = _e515;
        let _e516 = NdotV_14;
        param_246 = _e516;
        let _e517 = avgAlpha_2;
        param_247 = _e517;
        let _e518 = fd_10;
        param_248 = _e518;
        let _e519 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_246), (&param_247), (&param_248));
        comp_3 = _e519;
        let _e520 = NdotV_14;
        param_249 = _e520;
        let _e521 = avgAlpha_2;
        param_250 = _e521;
        let _e522 = F0_8;
        param_251 = _e522;
        param_252 = 1f;
        let _e523 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_249), (&param_250), (&param_251), (&param_252));
        let _e524 = comp_3;
        dirAlbedo_5 = (_e524 * _e523);
        let _e526 = dirAlbedo_5;
        let _e527 = (*weight_5);
        (*bsdf_4).throughput = (vec3(1f) - (_e526 * _e527));
        let _e532 = D_1;
        let _e533 = F_2;
        let _e535 = G_3;
        let _e537 = comp_3;
        let _e539 = safeTint;
        let _e542 = (*closureData_15).occlusion;
        let _e544 = (*weight_5);
        let _e546 = NdotV_14;
        (*bsdf_4).response = (((((((_e533 * _e532) * _e535) * _e537) * _e539) * _e542) * _e544) / vec3((4f * _e546)));
    } else {
        let _e552 = (*closureData_15).closureType;
        if (_e552 == 2i) {
            let _e554 = NdotV_14;
            param_253 = _e554;
            let _e555 = avgAlpha_2;
            param_254 = _e555;
            let _e556 = fd_10;
            param_255 = _e556;
            let _e557 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254), (&param_255));
            comp_4 = _e557;
            let _e558 = NdotV_14;
            param_256 = _e558;
            let _e559 = avgAlpha_2;
            param_257 = _e559;
            let _e560 = F0_8;
            param_258 = _e560;
            param_259 = 1f;
            let _e561 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_256), (&param_257), (&param_258), (&param_259));
            let _e562 = comp_4;
            dirAlbedo_6 = (_e562 * _e561);
            let _e564 = dirAlbedo_6;
            let _e565 = (*weight_5);
            (*bsdf_4).throughput = (vec3(1f) - (_e564 * _e565));
            let _e570 = (*scatter_mode_1);
            if (_e570 != 0i) {
                let _e572 = (*N_12);
                param_260 = _e572;
                let _e573 = V_9;
                param_261 = _e573;
                let _e574 = (*X_3);
                param_262 = _e574;
                let _e575 = safeAlpha_1;
                param_263 = _e575;
                let _e576 = (*distribution_3);
                param_264 = _e576;
                let _e577 = fd_10;
                param_265 = _e577;
                let _e578 = safeTint;
                param_266 = _e578;
                let _e579 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_260), (&param_261), (&param_262), (&param_263), (&param_264), (&param_265), (&param_266));
                let _e580 = (*weight_5);
                (*bsdf_4).response = (_e579 * _e580);
            }
        } else {
            let _e584 = (*closureData_15).closureType;
            if (_e584 == 3i) {
                let _e586 = NdotV_14;
                param_267 = _e586;
                let _e587 = avgAlpha_2;
                param_268 = _e587;
                let _e588 = fd_10;
                param_269 = _e588;
                let _e589 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
                comp_5 = _e589;
                let _e590 = NdotV_14;
                param_270 = _e590;
                let _e591 = avgAlpha_2;
                param_271 = _e591;
                let _e592 = F0_8;
                param_272 = _e592;
                param_273 = 1f;
                let _e593 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
                let _e594 = comp_5;
                dirAlbedo_7 = (_e594 * _e593);
                let _e596 = dirAlbedo_7;
                let _e597 = (*weight_5);
                (*bsdf_4).throughput = (vec3(1f) - (_e596 * _e597));
                let _e602 = (*N_12);
                param_274 = _e602;
                let _e603 = V_9;
                param_275 = _e603;
                let _e604 = (*X_3);
                param_276 = _e604;
                let _e605 = safeAlpha_1;
                param_277 = _e605;
                let _e606 = (*distribution_3);
                param_278 = _e606;
                let _e607 = fd_10;
                param_279 = _e607;
                let _e608 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279));
                Li_5 = _e608;
                let _e609 = Li_5;
                let _e610 = safeTint;
                let _e612 = comp_5;
                let _e614 = (*weight_5);
                (*bsdf_4).response = (((_e609 * _e610) * _e612) * _e614);
            }
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_4: f32;
    var o: f32;
    var param_280: f32;

    let _e348 = (*y_2);
    let _e349 = (*y_2);
    let _e353 = (*y_2);
    let _e354 = (*y_2);
    s_3 = ((_e348 * (0.0206607f + (1.58491f * _e349))) / (0.0379424f + (_e353 * (1.32227f + _e354))));
    let _e359 = (*y_2);
    let _e360 = (*y_2);
    let _e361 = (*y_2);
    let _e362 = (*y_2);
    let _e364 = (*y_2);
    let _e372 = (*y_2);
    m_4 = ((_e359 * (-0.193854f + (_e360 * (-1.14885f + (_e361 * (1.7932f - ((0.95943f * _e362) * _e364))))))) / (0.046391f + _e372));
    let _e375 = (*y_2);
    let _e376 = (*y_2);
    let _e379 = (*y_2);
    let _e383 = (*y_2);
    let _e384 = (*y_2);
    o = ((_e375 * (0.000654023f + ((-0.0207818f + (0.119681f * _e376)) * _e379))) / (1.26264f + (_e383 * (-1.92021f + _e384))));
    let _e389 = (*x_8);
    let _e390 = m_4;
    let _e392 = s_3;
    param_280 = ((_e389 - _e390) / _e392);
    let _e394 = mx_square_u0028_f1_u003b((&param_280));
    let _e397 = s_3;
    let _e400 = o;
    return ((exp((-0.5f * _e394)) / (_e397 * 2.5066283f)) + _e400);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_12: ptr<function, f32>) -> f32 {
    let _e343 = (*cosTheta_12);
    return (max(_e343, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_9: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e344 = (*x_9);
    let _e347 = (*y_3);
    let _e350 = (*y_3);
    let _e352 = (*y_3);
    let _e354 = (*y_3);
    let _e356 = (*x_9);
    let _e359 = (*x_9);
    let _e361 = (*y_3);
    let _e364 = (*y_3);
    let _e366 = (*y_3);
    return (((((sqrt((1f - _e344)) * (_e347 - 1f)) * _e350) * _e352) * _e354) / (((0.0000254053f + (1.71228f * _e356)) - ((1.71506f * _e359) * _e361)) + ((1.34174f * _e364) * _e366)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_10: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e344 = (*x_10);
    let _e346 = (*y_4);
    let _e349 = (*y_4);
    let _e351 = (*x_10);
    let _e353 = (*x_10);
    let _e356 = (*x_10);
    let _e358 = (*y_4);
    return ((((2.58126f * _e344) + (0.813703f * _e346)) * _e349) / ((1f + ((0.310327f * _e351) * _e353)) + ((2.60994f * _e356) * _e358)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_13: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_4: vec3<f32>;
    var Y_3: vec3<f32>;

    let _e349 = (*N_13)[2u];
    sign_ = select(1f, -1f, (_e349 < 0f));
    let _e352 = sign_;
    let _e354 = (*N_13)[2u];
    a_3 = (-1f / (_e352 + _e354));
    let _e358 = (*N_13)[0u];
    let _e360 = (*N_13)[1u];
    let _e362 = a_3;
    b = ((_e358 * _e360) * _e362);
    let _e364 = sign_;
    let _e366 = (*N_13)[0u];
    let _e369 = (*N_13)[0u];
    let _e371 = a_3;
    let _e374 = sign_;
    let _e375 = b;
    let _e377 = sign_;
    let _e380 = (*N_13)[0u];
    X_4 = vec3<f32>((1f + (((_e364 * _e366) * _e369) * _e371)), (_e374 * _e375), (-(_e377) * _e380));
    let _e383 = b;
    let _e384 = sign_;
    let _e386 = (*N_13)[1u];
    let _e388 = (*N_13)[1u];
    let _e390 = a_3;
    let _e394 = (*N_13)[1u];
    Y_3 = vec3<f32>(_e383, (_e384 + ((_e386 * _e388) * _e390)), -(_e394));
    let _e397 = X_4;
    let _e398 = Y_3;
    let _e399 = (*N_13);
    return mat3x3<f32>(vec3<f32>(_e397.x, _e397.y, _e397.z), vec3<f32>(_e398.x, _e398.y, _e398.z), vec3<f32>(_e399.x, _e399.y, _e399.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_10: ptr<function, vec3<f32>>, N_14: ptr<function, vec3<f32>>, NdotV_15: ptr<function, f32>) -> mat3x3<f32> {
    var X_5: vec3<f32>;
    var lenSqr: f32;
    var Y_4: vec3<f32>;
    var param_281: vec3<f32>;

    let _e349 = (*V_10);
    let _e350 = (*N_14);
    let _e351 = (*NdotV_15);
    X_5 = (_e349 - (_e350 * _e351));
    let _e354 = X_5;
    let _e355 = X_5;
    lenSqr = dot(_e354, _e355);
    let _e357 = lenSqr;
    if (_e357 > 0f) {
        let _e359 = lenSqr;
        let _e361 = X_5;
        X_5 = (_e361 * inverseSqrt(_e359));
        let _e363 = (*N_14);
        let _e364 = X_5;
        Y_4 = cross(_e363, _e364);
        let _e366 = X_5;
        let _e367 = Y_4;
        let _e368 = (*N_14);
        return mat3x3<f32>(vec3<f32>(_e366.x, _e366.y, _e366.z), vec3<f32>(_e367.x, _e367.y, _e367.z), vec3<f32>(_e368.x, _e368.y, _e368.z));
    }
    let _e382 = (*N_14);
    param_281 = _e382;
    let _e383 = mx_orthonormal_basis_u0028_vf3_u003b((&param_281));
    return _e383;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_8: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_15: ptr<function, vec3<f32>>, NdotV_16: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_282: vec3<f32>;
    var param_283: vec3<f32>;
    var param_284: f32;
    var w: vec3<f32>;
    var param_285: mat3x3<f32>;
    var param_286: vec3<f32>;
    var aInv: f32;
    var param_287: f32;
    var param_288: f32;
    var bInv: f32;
    var param_289: f32;
    var param_290: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_291: f32;
    var param_292: f32;

    let _e364 = (*V_11);
    param_282 = _e364;
    let _e365 = (*N_15);
    param_283 = _e365;
    let _e366 = (*NdotV_16);
    param_284 = _e366;
    let _e367 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_282), (&param_283), (&param_284));
    toLTC = transpose(_e367);
    let _e369 = toLTC;
    param_285 = _e369;
    let _e370 = (*L_8);
    param_286 = _e370;
    let _e371 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_285), (&param_286));
    w = _e371;
    let _e372 = (*NdotV_16);
    param_287 = _e372;
    let _e373 = (*roughness_10);
    param_288 = _e373;
    let _e374 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_287), (&param_288));
    aInv = _e374;
    let _e375 = (*NdotV_16);
    param_289 = _e375;
    let _e376 = (*roughness_10);
    param_290 = _e376;
    let _e377 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_289), (&param_290));
    bInv = _e377;
    let _e378 = aInv;
    let _e380 = w[0u];
    let _e382 = bInv;
    let _e384 = w[2u];
    let _e387 = aInv;
    let _e389 = w[1u];
    let _e392 = w[2u];
    wo = vec3<f32>(((_e378 * _e380) + (_e382 * _e384)), (_e387 * _e389), _e392);
    let _e394 = wo;
    let _e395 = wo;
    lenSqr_1 = dot(_e394, _e395);
    let _e398 = wo[2u];
    param_291 = _e398;
    let _e399 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_291));
    let _e400 = aInv;
    let _e401 = lenSqr_1;
    param_292 = (_e400 / _e401);
    let _e403 = mx_square_u0028_f1_u003b((&param_292));
    return (_e399 * _e403);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_293: f32;
    var param_294: f32;

    let _e347 = (*NdotV_17);
    let _e350 = (*roughness_11);
    let _e353 = (*NdotV_17);
    let _e355 = (*roughness_11);
    let _e358 = (*NdotV_17);
    param_293 = _e358;
    let _e359 = mx_square_u0028_f1_u003b((&param_293));
    let _e362 = (*roughness_11);
    param_294 = _e362;
    let _e363 = mx_square_u0028_f1_u003b((&param_294));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e347)) + (vec2<f32>(799.08826f, 442.7821f) * _e350)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e353) * _e355)) + (vec2<f32>(60.28956f, 121.81241f) * _e359)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e363));
    let _e367 = r_2[0u];
    let _e369 = r_2[1u];
    return (_e367 / _e369);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_18: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var dirAlbedo_8: f32;
    var param_295: f32;
    var param_296: f32;

    let _e347 = (*NdotV_18);
    param_295 = _e347;
    let _e348 = (*roughness_12);
    param_296 = _e348;
    let _e349 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_295), (&param_296));
    dirAlbedo_8 = _e349;
    let _e350 = dirAlbedo_8;
    return clamp(_e350, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e347 = (*roughness_13);
    invRoughness = (1f / max(_e347, 0.005f));
    let _e350 = (*NdotH);
    let _e351 = (*NdotH);
    cos2_ = (_e350 * _e351);
    let _e353 = cos2_;
    sin2_ = (1f - _e353);
    let _e355 = invRoughness;
    let _e357 = sin2_;
    let _e358 = invRoughness;
    return (((2f + _e355) * pow(_e357, (_e358 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_9: ptr<function, f32>, NdotV_19: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_14: ptr<function, f32>) -> f32 {
    var D_2: f32;
    var param_297: f32;
    var param_298: f32;
    var F_3: f32;
    var G_4: f32;

    let _e351 = (*NdotH_1);
    param_297 = _e351;
    let _e352 = (*roughness_14);
    param_298 = _e352;
    let _e353 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_297), (&param_298));
    D_2 = _e353;
    F_3 = 1f;
    G_4 = 1f;
    let _e354 = D_2;
    let _e355 = F_3;
    let _e357 = G_4;
    let _e359 = (*NdotL_9);
    let _e360 = (*NdotV_19);
    let _e362 = (*NdotL_9);
    let _e363 = (*NdotV_19);
    return (((_e354 * _e355) * _e357) / (4f * ((_e359 + _e360) - (_e362 * _e363))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_16: ptr<function, ClosureData>, weight_6: ptr<function, f32>, color_6: ptr<function, vec3<f32>>, roughness_15: ptr<function, f32>, N_16: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_5: ptr<function, BSDF>) {
    var V_12: vec3<f32>;
    var L_9: vec3<f32>;
    var param_299: vec3<f32>;
    var param_300: vec3<f32>;
    var NdotV_20: f32;
    var H_6: vec3<f32>;
    var NdotL_10: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_301: f32;
    var param_302: f32;
    var param_303: f32;
    var param_304: f32;
    var dirAlbedo_9: f32;
    var param_305: f32;
    var param_306: f32;
    var fr_1: vec3<f32>;
    var param_307: vec3<f32>;
    var param_308: vec3<f32>;
    var param_309: vec3<f32>;
    var param_310: f32;
    var param_311: f32;
    var param_312: f32;
    var param_313: f32;
    var dirAlbedo_10: f32;
    var param_314: f32;
    var param_315: f32;
    var param_316: f32;
    var param_317: f32;
    var Li_6: vec3<f32>;
    var param_318: vec3<f32>;

    let _e380 = (*weight_6);
    if (_e380 < 0.00000001f) {
        return;
    }
    let _e383 = (*closureData_16).V;
    V_12 = _e383;
    let _e385 = (*closureData_16).L;
    L_9 = _e385;
    let _e386 = (*N_16);
    param_299 = _e386;
    let _e387 = V_12;
    param_300 = _e387;
    let _e388 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_299), (&param_300));
    (*N_16) = _e388;
    let _e389 = (*N_16);
    let _e390 = V_12;
    NdotV_20 = clamp(dot(_e389, _e390), 0.00000001f, 1f);
    let _e394 = (*closureData_16).closureType;
    if (_e394 == 1i) {
        let _e396 = (*mode);
        if (_e396 == 0i) {
            let _e398 = L_9;
            let _e399 = V_12;
            H_6 = normalize((_e398 + _e399));
            let _e402 = (*N_16);
            let _e403 = L_9;
            NdotL_10 = clamp(dot(_e402, _e403), 0.00000001f, 1f);
            let _e406 = (*N_16);
            let _e407 = H_6;
            NdotH_2 = clamp(dot(_e406, _e407), 0.00000001f, 1f);
            let _e410 = (*color_6);
            let _e411 = NdotL_10;
            param_301 = _e411;
            let _e412 = NdotV_20;
            param_302 = _e412;
            let _e413 = NdotH_2;
            param_303 = _e413;
            let _e414 = (*roughness_15);
            param_304 = _e414;
            let _e415 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_301), (&param_302), (&param_303), (&param_304));
            fr = (_e410 * _e415);
            let _e417 = NdotV_20;
            param_305 = _e417;
            let _e418 = (*roughness_15);
            param_306 = _e418;
            let _e419 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_305), (&param_306));
            dirAlbedo_9 = _e419;
            let _e420 = fr;
            let _e421 = NdotL_10;
            let _e424 = (*closureData_16).occlusion;
            let _e426 = (*weight_6);
            (*bsdf_5).response = (((_e420 * _e421) * _e424) * _e426);
        } else {
            let _e429 = (*roughness_15);
            (*roughness_15) = clamp(_e429, 0.01f, 1f);
            let _e431 = (*color_6);
            let _e432 = L_9;
            param_307 = _e432;
            let _e433 = V_12;
            param_308 = _e433;
            let _e434 = (*N_16);
            param_309 = _e434;
            let _e435 = NdotV_20;
            param_310 = _e435;
            let _e436 = (*roughness_15);
            param_311 = _e436;
            let _e437 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_307), (&param_308), (&param_309), (&param_310), (&param_311));
            fr_1 = (_e431 * _e437);
            let _e439 = NdotV_20;
            param_312 = _e439;
            let _e440 = (*roughness_15);
            param_313 = _e440;
            let _e441 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_312), (&param_313));
            dirAlbedo_9 = _e441;
            let _e442 = dirAlbedo_9;
            let _e443 = fr_1;
            let _e446 = (*closureData_16).occlusion;
            let _e448 = (*weight_6);
            (*bsdf_5).response = (((_e443 * _e442) * _e446) * _e448);
        }
        let _e451 = dirAlbedo_9;
        let _e452 = (*weight_6);
        (*bsdf_5).throughput = vec3((1f - (_e451 * _e452)));
    } else {
        let _e458 = (*closureData_16).closureType;
        if (_e458 == 3i) {
            let _e460 = (*mode);
            if (_e460 == 0i) {
                let _e462 = NdotV_20;
                param_314 = _e462;
                let _e463 = (*roughness_15);
                param_315 = _e463;
                let _e464 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_314), (&param_315));
                dirAlbedo_10 = _e464;
            } else {
                let _e465 = (*roughness_15);
                (*roughness_15) = clamp(_e465, 0.01f, 1f);
                let _e467 = NdotV_20;
                param_316 = _e467;
                let _e468 = (*roughness_15);
                param_317 = _e468;
                let _e469 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_316), (&param_317));
                dirAlbedo_10 = _e469;
            }
            let _e470 = (*N_16);
            param_318 = _e470;
            let _e471 = mx_environment_irradiance_u0028_vf3_u003b((&param_318));
            Li_6 = _e471;
            let _e472 = Li_6;
            let _e473 = (*color_6);
            let _e475 = dirAlbedo_10;
            let _e477 = (*weight_6);
            (*bsdf_5).response = (((_e472 * _e473) * _e475) * _e477);
            let _e480 = dirAlbedo_10;
            let _e481 = (*weight_6);
            (*bsdf_5).throughput = vec3((1f - (_e480 * _e481)));
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e348 = (*closureType);
    let _e349 = (*L_10);
    let _e350 = (*V_13);
    let _e351 = (*N_17);
    let _e352 = (*P_2);
    let _e353 = (*occlusion_1);
    return ClosureData(_e348, _e349, _e350, _e351, _e352, _e353);
}

fn NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_4: ptr<function, vec3<f32>>, outx: ptr<function, f32>, outy: ptr<function, f32>, outz: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e350 = (*in1_4)[0u];
    N_extract_0_out = _e350;
    let _e352 = (*in1_4)[1u];
    N_extract_1_out = _e352;
    let _e354 = (*in1_4)[2u];
    N_extract_2_out = _e354;
    let _e355 = N_extract_0_out;
    (*outx) = _e355;
    let _e356 = N_extract_1_out;
    (*outy) = _e356;
    let _e357 = N_extract_2_out;
    (*outz) = _e357;
    return;
}

fn NG_mincomponent_vector3_u0028_vf3_u003b_f1_u003b(in1_5: ptr<function, vec3<f32>>, out1_: ptr<function, f32>) {
    var N_separate_outx: f32;
    var N_separate_outy: f32;
    var N_separate_outz: f32;
    var param_319: vec3<f32>;
    var param_320: f32;
    var param_321: f32;
    var param_322: f32;
    var N_min_01_out: f32;
    var N_min_out: f32;

    N_separate_outx = 0f;
    N_separate_outy = 0f;
    N_separate_outz = 0f;
    let _e353 = (*in1_5);
    param_319 = _e353;
    NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322));
    let _e354 = param_320;
    N_separate_outx = _e354;
    let _e355 = param_321;
    N_separate_outy = _e355;
    let _e356 = param_322;
    N_separate_outz = _e356;
    let _e357 = N_separate_outx;
    let _e358 = N_separate_outy;
    N_min_01_out = min(_e357, _e358);
    let _e360 = N_min_01_out;
    let _e361 = N_separate_outz;
    N_min_out = min(_e360, _e361);
    let _e363 = N_min_out;
    (*out1_) = _e363;
    return;
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_6: ptr<function, f32>, out1_1: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e345 = (*in1_6);
    combine_out = vec3(_e345);
    let _e347 = combine_out;
    (*out1_1) = _e347;
    return;
}

fn NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b(in1_7: ptr<function, f32>, out1_2: ptr<function, vec3<f32>>) {
    var combine_out_1: vec3<f32>;

    let _e345 = (*in1_7);
    combine_out_1 = vec3(_e345);
    let _e347 = combine_out_1;
    (*out1_2) = _e347;
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_8: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out_1: f32;
    var N_extract_1_out_1: f32;
    var N_extract_2_out_1: f32;

    let _e350 = (*in1_8)[0u];
    N_extract_0_out_1 = _e350;
    let _e352 = (*in1_8)[1u];
    N_extract_1_out_1 = _e352;
    let _e354 = (*in1_8)[2u];
    N_extract_2_out_1 = _e354;
    let _e355 = N_extract_0_out_1;
    (*outr) = _e355;
    let _e356 = N_extract_1_out_1;
    (*outg) = _e356;
    let _e357 = N_extract_2_out_1;
    (*outb) = _e357;
    return;
}

fn NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b(in1_9: ptr<function, vec3<f32>>, out1_3: ptr<function, vec3<f32>>) {
    var separate_outr: f32;
    var separate_outg: f32;
    var separate_outb: f32;
    var param_323: vec3<f32>;
    var param_324: f32;
    var param_325: f32;
    var param_326: f32;
    var combine_out_2: vec3<f32>;

    separate_outr = 0f;
    separate_outg = 0f;
    separate_outb = 0f;
    let _e352 = (*in1_9);
    param_323 = _e352;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_323), (&param_324), (&param_325), (&param_326));
    let _e353 = param_324;
    separate_outr = _e353;
    let _e354 = param_325;
    separate_outg = _e354;
    let _e355 = param_326;
    separate_outb = _e355;
    let _e356 = separate_outr;
    let _e357 = separate_outg;
    let _e358 = separate_outb;
    combine_out_2 = vec3<f32>(_e356, _e357, _e358);
    let _e360 = combine_out_2;
    (*out1_3) = _e360;
    return;
}

fn NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_2: ptr<function, f32>, out1_4: ptr<function, vec2<f32>>) {
    var rough_sq_out: f32;
    var aniso_invert_out: f32;
    var aniso_invert_sq_out: f32;
    var denom_out: f32;
    var fraction_out: f32;
    var sqrt_out: f32;
    var alpha_x_out: f32;
    var alpha_y_out: f32;
    var result_out: vec2<f32>;

    let _e354 = (*roughness_16);
    let _e355 = (*roughness_16);
    rough_sq_out = (_e354 * _e355);
    let _e357 = (*anisotropy_2);
    aniso_invert_out = (1f - _e357);
    let _e359 = aniso_invert_out;
    let _e360 = aniso_invert_out;
    aniso_invert_sq_out = (_e359 * _e360);
    let _e362 = aniso_invert_sq_out;
    denom_out = (_e362 + 1f);
    let _e364 = denom_out;
    fraction_out = (2f / _e364);
    let _e366 = fraction_out;
    sqrt_out = sqrt(_e366);
    let _e368 = rough_sq_out;
    let _e369 = sqrt_out;
    alpha_x_out = (_e368 * _e369);
    let _e371 = aniso_invert_out;
    let _e372 = alpha_x_out;
    alpha_y_out = (_e371 * _e372);
    let _e374 = alpha_x_out;
    let _e375 = alpha_y_out;
    result_out = vec2<f32>(_e374, _e375);
    let _e377 = result_out;
    (*out1_4) = _e377;
    return;
}

fn NG_open_pbr_surface_surfaceshader_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_b1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_weight: ptr<function, f32>, base_color: ptr<function, vec3<f32>>, base_diffuse_roughness: ptr<function, f32>, base_metalness: ptr<function, f32>, specular_weight: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, specular_roughness: ptr<function, f32>, specular_ior: ptr<function, f32>, specular_roughness_anisotropy: ptr<function, f32>, transmission_weight: ptr<function, f32>, transmission_color: ptr<function, vec3<f32>>, transmission_depth: ptr<function, f32>, transmission_scatter: ptr<function, vec3<f32>>, transmission_scatter_anisotropy: ptr<function, f32>, transmission_dispersion_scale: ptr<function, f32>, transmission_dispersion_abbe_number: ptr<function, f32>, subsurface_weight: ptr<function, f32>, subsurface_color: ptr<function, vec3<f32>>, subsurface_radius: ptr<function, f32>, subsurface_radius_scale: ptr<function, vec3<f32>>, subsurface_scatter_anisotropy: ptr<function, f32>, fuzz_weight: ptr<function, f32>, fuzz_color: ptr<function, vec3<f32>>, fuzz_roughness: ptr<function, f32>, coat_weight: ptr<function, f32>, coat_color: ptr<function, vec3<f32>>, coat_roughness: ptr<function, f32>, coat_roughness_anisotropy: ptr<function, f32>, coat_ior: ptr<function, f32>, coat_darkening: ptr<function, f32>, thin_film_weight: ptr<function, f32>, thin_film_thickness: ptr<function, f32>, thin_film_ior: ptr<function, f32>, emission_luminance: ptr<function, f32>, emission_color: ptr<function, vec3<f32>>, geometry_opacity: ptr<function, f32>, geometry_thin_walled: ptr<function, bool>, geometry_normal: ptr<function, vec3<f32>>, geometry_coat_normal: ptr<function, vec3<f32>>, geometry_tangent: ptr<function, vec3<f32>>, geometry_coat_tangent: ptr<function, vec3<f32>>, out1_5: ptr<function, surfaceshader>) {
    var coat_roughness_vector_out: vec2<f32>;
    var param_327: f32;
    var param_328: f32;
    var param_329: vec2<f32>;
    var metal_bsdf_tf_mix_fg_weight_out: f32;
    var metal_reflectivity_out: vec3<f32>;
    var coat_roughness_to_power_4_out: f32;
    var specular_roughness_to_power_4_out: f32;
    var thin_film_thickness_nm_out: f32;
    var metal_bsdf_tf_mix_mix_inv_out: f32;
    var dielectric_reflection_tf_mix_fg_weight_out: f32;
    var specular_to_coat_ior_ratio_out: f32;
    var coat_to_specular_ior_ratio_out: f32;
    var dielectric_reflection_tf_mix_mix_inv_out: f32;
    var if_transmission_tint_out: vec3<f32>;
    var transmission_color_vector_out: vec3<f32>;
    var param_330: vec3<f32>;
    var param_331: vec3<f32>;
    var transmission_depth_vector_out: vec3<f32>;
    var param_332: f32;
    var param_333: vec3<f32>;
    var transmission_scatter_vector_out: vec3<f32>;
    var param_334: vec3<f32>;
    var param_335: vec3<f32>;
    var subsurface_color_nonnegative_out: vec3<f32>;
    var one_minus_subsurface_scatter_anisotropy_out: f32;
    var one_plus_subsurface_scatter_anisotropy_out: f32;
    var subsurface_selector_out: f32;
    var subsurface_radius_scaled_out: vec3<f32>;
    var opaque_base_mix_inv_out: f32;
    var base_color_nonnegative_out: vec3<f32>;
    var dielectric_substrate_mix_inv_out: f32;
    var base_substrate_mix_inv_out: f32;
    var coat_ior_minus_one_out: f32;
    var coat_ior_plus_one_out: f32;
    var coat_ior_sqr_out: f32;
    var Emetal_out: vec3<f32>;
    var Edielectric_out: vec3<f32>;
    var coat_weight_times_coat_darkening_out: f32;
    var coat_attenuation_out: vec3<f32>;
    var emission_weight_out: vec3<f32>;
    var two_times_coat_roughness_to_power_4_out: f32;
    var metal_bsdf_tf_mix_bg_weight_out: f32;
    var specular_to_coat_ior_ratio_tir_fix_out: f32;
    var dielectric_reflection_tf_mix_bg_weight_out: f32;
    var transmission_color_ln_out: vec3<f32>;
    var scattering_coeff_out: vec3<f32>;
    var subsurface_thin_walled_brdf_factor_out: vec3<f32>;
    var subsurface_thin_walled_btdf_factor_out: vec3<f32>;
    var selected_subsurface_mix_inv_out: f32;
    var opaque_base_bg_weight_out: f32;
    var coat_ior_to_F0_sqrt_out: f32;
    var Ebase_out: vec3<f32>;
    var add_coat_and_spec_roughnesses_to_power_4_out: f32;
    var eta_s_out: f32;
    var extinction_coeff_denom_out: vec3<f32>;
    var if_volume_scattering_out: vec3<f32>;
    var selected_subsurface_bg_weight_out: f32;
    var coat_ior_to_F0_out: f32;
    var min_1_add_coat_and_spec_roughnesses_to_power_4_out: f32;
    var eta_s_minus_one_out: f32;
    var eta_s_plus_one_out: f32;
    var extinction_coeff_out: vec3<f32>;
    var one_minus_coat_F0_out: f32;
    var coat_affected_specular_roughness_out: f32;
    var sign_eta_s_minus_one_out: f32;
    var specular_F0_sqrt_out: f32;
    var absorption_coeff_out: vec3<f32>;
    var one_minus_coat_F0_over_eta2_out: f32;
    var one_minus_coat_F0_color_out: vec3<f32>;
    var param_336: f32;
    var param_337: vec3<f32>;
    var effective_specular_roughness_out: f32;
    var specular_F0_out: f32;
    var absorption_coeff_min_out: f32;
    var param_338: vec3<f32>;
    var param_339: f32;
    var Kcoat_out: f32;
    var main_roughness_out: vec2<f32>;
    var param_340: f32;
    var param_341: f32;
    var param_342: vec2<f32>;
    var scaled_specular_F0_out: f32;
    var absorption_coeff_min_vector_out: vec3<f32>;
    var param_343: f32;
    var param_344: vec3<f32>;
    var one_minus_Kcoat_out: f32;
    var Ebase_Kcoat_out: vec3<f32>;
    var scaled_specular_F0_clamped_out: f32;
    var absorption_coeff_shifted_out: vec3<f32>;
    var one_minus_Kcoat_color_out: vec3<f32>;
    var param_345: f32;
    var param_346: vec3<f32>;
    var one_minus_Ebase_Kcoat_out: vec3<f32>;
    var sqrt_scaled_specular_F0_out: f32;
    var if_absorption_coeff_shifted_out: vec3<f32>;
    var base_darkening_out: vec3<f32>;
    var modulated_eta_s_epsilon_out: f32;
    var if_volume_absorption_out: vec3<f32>;
    var modulated_base_darkening_out: vec3<f32>;
    var one_plus_modulated_eta_s_epsilon_out: f32;
    var one_minus_modulated_eta_s_epsilon_out: f32;
    var modulated_eta_s_out: f32;
    var shader_constructor_out: surfaceshader;
    var N_18: vec3<f32>;
    var V_14: vec3<f32>;
    var L_11: vec3<f32>;
    var P_3: vec3<f32>;
    var occlusion_2: f32;
    var closureData_17: ClosureData;
    var param_347: i32;
    var param_348: vec3<f32>;
    var param_349: vec3<f32>;
    var param_350: vec3<f32>;
    var param_351: vec3<f32>;
    var param_352: f32;
    var fuzz_bsdf_out: BSDF;
    var param_353: ClosureData;
    var param_354: f32;
    var param_355: vec3<f32>;
    var param_356: f32;
    var param_357: vec3<f32>;
    var param_358: i32;
    var param_359: BSDF;
    var coat_bsdf_out: BSDF;
    var param_360: ClosureData;
    var param_361: f32;
    var param_362: vec3<f32>;
    var param_363: f32;
    var param_364: vec2<f32>;
    var param_365: bool;
    var param_366: f32;
    var param_367: f32;
    var param_368: vec3<f32>;
    var param_369: vec3<f32>;
    var param_370: i32;
    var param_371: i32;
    var param_372: BSDF;
    var metal_bsdf_tf_out: BSDF;
    var param_373: ClosureData;
    var param_374: f32;
    var param_375: vec3<f32>;
    var param_376: vec3<f32>;
    var param_377: vec3<f32>;
    var param_378: f32;
    var param_379: vec2<f32>;
    var param_380: bool;
    var param_381: f32;
    var param_382: f32;
    var param_383: vec3<f32>;
    var param_384: vec3<f32>;
    var param_385: i32;
    var param_386: i32;
    var param_387: BSDF;
    var metal_bsdf_out: BSDF;
    var param_388: ClosureData;
    var param_389: f32;
    var param_390: vec3<f32>;
    var param_391: vec3<f32>;
    var param_392: vec3<f32>;
    var param_393: f32;
    var param_394: vec2<f32>;
    var param_395: bool;
    var param_396: f32;
    var param_397: f32;
    var param_398: vec3<f32>;
    var param_399: vec3<f32>;
    var param_400: i32;
    var param_401: i32;
    var param_402: BSDF;
    var metal_bsdf_tf_mix_add_out: BSDF;
    var param_403: ClosureData;
    var param_404: BSDF;
    var param_405: BSDF;
    var param_406: BSDF;
    var base_substrate_fg_mul_out: BSDF;
    var param_407: ClosureData;
    var param_408: BSDF;
    var param_409: f32;
    var param_410: BSDF;
    var dielectric_reflection_tf_out: BSDF;
    var param_411: ClosureData;
    var param_412: f32;
    var param_413: vec3<f32>;
    var param_414: f32;
    var param_415: vec2<f32>;
    var param_416: bool;
    var param_417: f32;
    var param_418: f32;
    var param_419: vec3<f32>;
    var param_420: vec3<f32>;
    var param_421: i32;
    var param_422: i32;
    var param_423: BSDF;
    var dielectric_reflection_out: BSDF;
    var param_424: ClosureData;
    var param_425: f32;
    var param_426: vec3<f32>;
    var param_427: f32;
    var param_428: vec2<f32>;
    var param_429: bool;
    var param_430: f32;
    var param_431: f32;
    var param_432: vec3<f32>;
    var param_433: vec3<f32>;
    var param_434: i32;
    var param_435: i32;
    var param_436: BSDF;
    var dielectric_reflection_tf_mix_add_out: BSDF;
    var param_437: ClosureData;
    var param_438: BSDF;
    var param_439: BSDF;
    var param_440: BSDF;
    var dielectric_transmission_out: BSDF;
    var param_441: ClosureData;
    var param_442: f32;
    var param_443: vec3<f32>;
    var param_444: f32;
    var param_445: vec2<f32>;
    var param_446: bool;
    var param_447: f32;
    var param_448: f32;
    var param_449: vec3<f32>;
    var param_450: vec3<f32>;
    var param_451: i32;
    var param_452: i32;
    var param_453: BSDF;
    var dielectric_volume_out: VDF;
    var param_454: ClosureData;
    var param_455: vec3<f32>;
    var param_456: vec3<f32>;
    var param_457: f32;
    var param_458: VDF;
    var dielectric_volume_transmission_out: BSDF;
    var param_459: ClosureData;
    var param_460: BSDF;
    var param_461: VDF;
    var param_462: BSDF;
    var dielectric_substrate_fg_mul_out: BSDF;
    var param_463: ClosureData;
    var param_464: BSDF;
    var param_465: f32;
    var param_466: BSDF;
    var subsurface_thin_walled_reflection_bsdf_out: BSDF;
    var param_467: ClosureData;
    var param_468: f32;
    var param_469: vec3<f32>;
    var param_470: f32;
    var param_471: vec3<f32>;
    var param_472: bool;
    var param_473: BSDF;
    var subsurface_thin_walled_reflection_out: BSDF;
    var param_474: ClosureData;
    var param_475: BSDF;
    var param_476: vec3<f32>;
    var param_477: BSDF;
    var subsurface_thin_walled_transmission_bsdf_out: BSDF;
    var param_478: ClosureData;
    var param_479: f32;
    var param_480: vec3<f32>;
    var param_481: vec3<f32>;
    var param_482: BSDF;
    var subsurface_thin_walled_transmission_out: BSDF;
    var param_483: ClosureData;
    var param_484: BSDF;
    var param_485: vec3<f32>;
    var param_486: BSDF;
    var subsurface_thin_walled_out: BSDF;
    var param_487: ClosureData;
    var param_488: BSDF;
    var param_489: BSDF;
    var param_490: f32;
    var param_491: BSDF;
    var selected_subsurface_fg_mul_out: BSDF;
    var param_492: ClosureData;
    var param_493: BSDF;
    var param_494: f32;
    var param_495: BSDF;
    var subsurface_bsdf_out: BSDF;
    var param_496: ClosureData;
    var param_497: f32;
    var param_498: vec3<f32>;
    var param_499: vec3<f32>;
    var param_500: f32;
    var param_501: vec3<f32>;
    var param_502: BSDF;
    var selected_subsurface_add_out: BSDF;
    var param_503: ClosureData;
    var param_504: BSDF;
    var param_505: BSDF;
    var param_506: BSDF;
    var opaque_base_fg_mul_out: BSDF;
    var param_507: ClosureData;
    var param_508: BSDF;
    var param_509: f32;
    var param_510: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_511: ClosureData;
    var param_512: f32;
    var param_513: vec3<f32>;
    var param_514: f32;
    var param_515: vec3<f32>;
    var param_516: bool;
    var param_517: BSDF;
    var opaque_base_add_out: BSDF;
    var param_518: ClosureData;
    var param_519: BSDF;
    var param_520: BSDF;
    var param_521: BSDF;
    var dielectric_substrate_bg_mul_out: BSDF;
    var param_522: ClosureData;
    var param_523: BSDF;
    var param_524: f32;
    var param_525: BSDF;
    var dielectric_substrate_add_out: BSDF;
    var param_526: ClosureData;
    var param_527: BSDF;
    var param_528: BSDF;
    var param_529: BSDF;
    var dielectric_base_out: BSDF;
    var param_530: ClosureData;
    var param_531: BSDF;
    var param_532: BSDF;
    var param_533: BSDF;
    var base_substrate_bg_mul_out: BSDF;
    var param_534: ClosureData;
    var param_535: BSDF;
    var param_536: f32;
    var param_537: BSDF;
    var base_substrate_add_out: BSDF;
    var param_538: ClosureData;
    var param_539: BSDF;
    var param_540: BSDF;
    var param_541: BSDF;
    var darkened_base_substrate_out: BSDF;
    var param_542: ClosureData;
    var param_543: BSDF;
    var param_544: vec3<f32>;
    var param_545: BSDF;
    var coat_substrate_attenuated_out: BSDF;
    var param_546: ClosureData;
    var param_547: BSDF;
    var param_548: vec3<f32>;
    var param_549: BSDF;
    var coat_layer_out: BSDF;
    var param_550: ClosureData;
    var param_551: BSDF;
    var param_552: BSDF;
    var param_553: BSDF;
    var fuzz_layer_out: BSDF;
    var param_554: ClosureData;
    var param_555: BSDF;
    var param_556: BSDF;
    var param_557: BSDF;
    var closureData_18: ClosureData;
    var param_558: i32;
    var param_559: vec3<f32>;
    var param_560: vec3<f32>;
    var param_561: vec3<f32>;
    var param_562: vec3<f32>;
    var param_563: f32;
    var uncoated_emission_edf_out: vec3<f32>;
    var param_564: ClosureData;
    var param_565: vec3<f32>;
    var param_566: vec3<f32>;
    var coat_tinted_emission_edf_out: vec3<f32>;
    var param_567: ClosureData;
    var param_568: vec3<f32>;
    var param_569: vec3<f32>;
    var param_570: vec3<f32>;
    var coated_emission_edf_out: vec3<f32>;
    var param_571: ClosureData;
    var param_572: vec3<f32>;
    var param_573: vec3<f32>;
    var param_574: f32;
    var param_575: vec3<f32>;
    var param_576: vec3<f32>;
    var emission_edf_out: vec3<f32>;
    var param_577: ClosureData;
    var param_578: vec3<f32>;
    var param_579: vec3<f32>;
    var param_580: f32;
    var param_581: vec3<f32>;

    coat_roughness_vector_out = vec2<f32>(0f, 0f);
    let _e767 = (*coat_roughness);
    param_327 = _e767;
    let _e768 = (*coat_roughness_anisotropy);
    param_328 = _e768;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_327), (&param_328), (&param_329));
    let _e769 = param_329;
    coat_roughness_vector_out = _e769;
    let _e770 = (*specular_weight);
    let _e771 = (*thin_film_weight);
    metal_bsdf_tf_mix_fg_weight_out = (_e770 * _e771);
    let _e773 = (*base_color);
    let _e774 = (*base_weight);
    metal_reflectivity_out = (_e773 * _e774);
    let _e776 = (*coat_roughness);
    coat_roughness_to_power_4_out = pow(_e776, 4f);
    let _e778 = (*specular_roughness);
    specular_roughness_to_power_4_out = pow(_e778, 4f);
    let _e780 = (*thin_film_thickness);
    thin_film_thickness_nm_out = (_e780 * 1000f);
    let _e782 = (*thin_film_weight);
    metal_bsdf_tf_mix_mix_inv_out = (1f - _e782);
    let _e784 = (*thin_film_weight);
    dielectric_reflection_tf_mix_fg_weight_out = (1f * _e784);
    let _e786 = (*specular_ior);
    let _e787 = (*coat_ior);
    specular_to_coat_ior_ratio_out = (_e786 / _e787);
    let _e789 = (*coat_ior);
    let _e790 = (*specular_ior);
    coat_to_specular_ior_ratio_out = (_e789 / _e790);
    let _e792 = (*thin_film_weight);
    dielectric_reflection_tf_mix_mix_inv_out = (1f - _e792);
    let _e794 = (*transmission_depth);
    let _e796 = (*transmission_color);
    if_transmission_tint_out = select(_e796, vec3<f32>(1f, 1f, 1f), (_e794 > 0f));
    transmission_color_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e798 = (*transmission_color);
    param_330 = _e798;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_330), (&param_331));
    let _e799 = param_331;
    transmission_color_vector_out = _e799;
    transmission_depth_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e800 = (*transmission_depth);
    param_332 = _e800;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_332), (&param_333));
    let _e801 = param_333;
    transmission_depth_vector_out = _e801;
    transmission_scatter_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e802 = (*transmission_scatter);
    param_334 = _e802;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_334), (&param_335));
    let _e803 = param_335;
    transmission_scatter_vector_out = _e803;
    let _e804 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e804, vec3(0f));
    let _e807 = (*subsurface_scatter_anisotropy);
    one_minus_subsurface_scatter_anisotropy_out = (1f - _e807);
    let _e809 = (*subsurface_scatter_anisotropy);
    one_plus_subsurface_scatter_anisotropy_out = (1f + _e809);
    let _e811 = (*geometry_thin_walled);
    subsurface_selector_out = select(0f, 1f, _e811);
    let _e813 = (*subsurface_radius_scale);
    let _e814 = (*subsurface_radius);
    subsurface_radius_scaled_out = (_e813 * _e814);
    let _e816 = (*subsurface_weight);
    opaque_base_mix_inv_out = (1f - _e816);
    let _e818 = (*base_color);
    base_color_nonnegative_out = max(_e818, vec3(0f));
    let _e821 = (*transmission_weight);
    dielectric_substrate_mix_inv_out = (1f - _e821);
    let _e823 = (*base_metalness);
    base_substrate_mix_inv_out = (1f - _e823);
    let _e825 = (*coat_ior);
    coat_ior_minus_one_out = (_e825 - 1f);
    let _e827 = (*coat_ior);
    coat_ior_plus_one_out = (1f + _e827);
    let _e829 = (*coat_ior);
    let _e830 = (*coat_ior);
    coat_ior_sqr_out = (_e829 * _e830);
    let _e832 = (*base_color);
    let _e833 = (*specular_weight);
    Emetal_out = (_e832 * _e833);
    let _e835 = (*base_color);
    let _e836 = (*subsurface_color);
    let _e837 = (*subsurface_weight);
    Edielectric_out = mix(_e835, _e836, vec3(_e837));
    let _e840 = (*coat_weight);
    let _e841 = (*coat_darkening);
    coat_weight_times_coat_darkening_out = (_e840 * _e841);
    let _e843 = (*coat_color);
    let _e844 = (*coat_weight);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e843, vec3(_e844));
    let _e847 = (*emission_color);
    let _e848 = (*emission_luminance);
    emission_weight_out = (_e847 * _e848);
    let _e850 = coat_roughness_to_power_4_out;
    two_times_coat_roughness_to_power_4_out = (_e850 * 2f);
    let _e852 = (*specular_weight);
    let _e853 = metal_bsdf_tf_mix_mix_inv_out;
    metal_bsdf_tf_mix_bg_weight_out = (_e852 * _e853);
    let _e855 = specular_to_coat_ior_ratio_out;
    let _e857 = specular_to_coat_ior_ratio_out;
    let _e858 = coat_to_specular_ior_ratio_out;
    specular_to_coat_ior_ratio_tir_fix_out = select(_e858, _e857, (_e855 > 1f));
    let _e860 = dielectric_reflection_tf_mix_mix_inv_out;
    dielectric_reflection_tf_mix_bg_weight_out = (1f * _e860);
    let _e862 = transmission_color_vector_out;
    transmission_color_ln_out = log(_e862);
    let _e864 = transmission_scatter_vector_out;
    let _e865 = transmission_depth_vector_out;
    scattering_coeff_out = (_e864 / _e865);
    let _e867 = (*subsurface_color);
    let _e868 = one_minus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_brdf_factor_out = (_e867 * _e868);
    let _e870 = (*subsurface_color);
    let _e871 = one_plus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_btdf_factor_out = (_e870 * _e871);
    let _e873 = subsurface_selector_out;
    selected_subsurface_mix_inv_out = (1f - _e873);
    let _e875 = (*base_weight);
    let _e876 = opaque_base_mix_inv_out;
    opaque_base_bg_weight_out = (_e875 * _e876);
    let _e878 = coat_ior_minus_one_out;
    let _e879 = coat_ior_plus_one_out;
    coat_ior_to_F0_sqrt_out = (_e878 / _e879);
    let _e881 = Edielectric_out;
    let _e882 = Emetal_out;
    let _e883 = (*base_metalness);
    Ebase_out = mix(_e881, _e882, vec3(_e883));
    let _e886 = two_times_coat_roughness_to_power_4_out;
    let _e887 = specular_roughness_to_power_4_out;
    add_coat_and_spec_roughnesses_to_power_4_out = (_e886 + _e887);
    let _e889 = (*specular_ior);
    let _e890 = specular_to_coat_ior_ratio_tir_fix_out;
    let _e891 = (*coat_weight);
    eta_s_out = mix(_e889, _e890, _e891);
    let _e893 = transmission_color_ln_out;
    extinction_coeff_denom_out = (_e893 * -1f);
    let _e895 = (*transmission_depth);
    let _e897 = scattering_coeff_out;
    if_volume_scattering_out = select(vec3<f32>(0f, 0f, 0f), _e897, (_e895 > 0f));
    let _e899 = selected_subsurface_mix_inv_out;
    selected_subsurface_bg_weight_out = (1f * _e899);
    let _e901 = coat_ior_to_F0_sqrt_out;
    let _e902 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e901 * _e902);
    let _e904 = add_coat_and_spec_roughnesses_to_power_4_out;
    min_1_add_coat_and_spec_roughnesses_to_power_4_out = min(1f, _e904);
    let _e906 = eta_s_out;
    eta_s_minus_one_out = (_e906 - 1f);
    let _e908 = eta_s_out;
    eta_s_plus_one_out = (_e908 + 1f);
    let _e910 = extinction_coeff_denom_out;
    let _e911 = transmission_depth_vector_out;
    extinction_coeff_out = (_e910 / _e911);
    let _e913 = coat_ior_to_F0_out;
    one_minus_coat_F0_out = (1f - _e913);
    let _e915 = min_1_add_coat_and_spec_roughnesses_to_power_4_out;
    coat_affected_specular_roughness_out = pow(_e915, 0.25f);
    let _e917 = eta_s_minus_one_out;
    sign_eta_s_minus_one_out = sign(_e917);
    let _e919 = eta_s_minus_one_out;
    let _e920 = eta_s_plus_one_out;
    specular_F0_sqrt_out = (_e919 / _e920);
    let _e922 = extinction_coeff_out;
    let _e923 = scattering_coeff_out;
    absorption_coeff_out = (_e922 - _e923);
    let _e925 = one_minus_coat_F0_out;
    let _e926 = coat_ior_sqr_out;
    one_minus_coat_F0_over_eta2_out = (_e925 / _e926);
    one_minus_coat_F0_color_out = vec3<f32>(0f, 0f, 0f);
    let _e928 = one_minus_coat_F0_out;
    param_336 = _e928;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_336), (&param_337));
    let _e929 = param_337;
    one_minus_coat_F0_color_out = _e929;
    let _e930 = (*specular_roughness);
    let _e931 = coat_affected_specular_roughness_out;
    let _e932 = (*coat_weight);
    effective_specular_roughness_out = mix(_e930, _e931, _e932);
    let _e934 = specular_F0_sqrt_out;
    let _e935 = specular_F0_sqrt_out;
    specular_F0_out = (_e934 * _e935);
    absorption_coeff_min_out = 0f;
    let _e937 = absorption_coeff_out;
    param_338 = _e937;
    NG_mincomponent_vector3_u0028_vf3_u003b_f1_u003b((&param_338), (&param_339));
    let _e938 = param_339;
    absorption_coeff_min_out = _e938;
    let _e939 = one_minus_coat_F0_over_eta2_out;
    Kcoat_out = (1f - _e939);
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e941 = effective_specular_roughness_out;
    param_340 = _e941;
    let _e942 = (*specular_roughness_anisotropy);
    param_341 = _e942;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_340), (&param_341), (&param_342));
    let _e943 = param_342;
    main_roughness_out = _e943;
    let _e944 = (*specular_weight);
    let _e945 = specular_F0_out;
    scaled_specular_F0_out = (_e944 * _e945);
    absorption_coeff_min_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e947 = absorption_coeff_min_out;
    param_343 = _e947;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_343), (&param_344));
    let _e948 = param_344;
    absorption_coeff_min_vector_out = _e948;
    let _e949 = Kcoat_out;
    one_minus_Kcoat_out = (1f - _e949);
    let _e951 = Ebase_out;
    let _e952 = Kcoat_out;
    Ebase_Kcoat_out = (_e951 * _e952);
    let _e954 = scaled_specular_F0_out;
    scaled_specular_F0_clamped_out = clamp(_e954, 0f, 0.99999f);
    let _e956 = absorption_coeff_out;
    let _e957 = absorption_coeff_min_vector_out;
    absorption_coeff_shifted_out = (_e956 - _e957);
    one_minus_Kcoat_color_out = vec3<f32>(0f, 0f, 0f);
    let _e959 = one_minus_Kcoat_out;
    param_345 = _e959;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_345), (&param_346));
    let _e960 = param_346;
    one_minus_Kcoat_color_out = _e960;
    let _e961 = Ebase_Kcoat_out;
    one_minus_Ebase_Kcoat_out = (vec3<f32>(1f, 1f, 1f) - _e961);
    let _e963 = scaled_specular_F0_clamped_out;
    sqrt_scaled_specular_F0_out = sqrt(_e963);
    let _e965 = absorption_coeff_min_out;
    let _e967 = absorption_coeff_shifted_out;
    let _e968 = absorption_coeff_out;
    if_absorption_coeff_shifted_out = select(_e968, _e967, (0f > _e965));
    let _e970 = one_minus_Kcoat_color_out;
    let _e971 = one_minus_Ebase_Kcoat_out;
    base_darkening_out = (_e970 / _e971);
    let _e973 = sign_eta_s_minus_one_out;
    let _e974 = sqrt_scaled_specular_F0_out;
    modulated_eta_s_epsilon_out = (_e973 * _e974);
    let _e976 = (*transmission_depth);
    let _e978 = if_absorption_coeff_shifted_out;
    if_volume_absorption_out = select(vec3<f32>(0f, 0f, 0f), _e978, (_e976 > 0f));
    let _e980 = base_darkening_out;
    let _e981 = coat_weight_times_coat_darkening_out;
    modulated_base_darkening_out = mix(vec3<f32>(1f, 1f, 1f), _e980, vec3(_e981));
    let _e984 = modulated_eta_s_epsilon_out;
    one_plus_modulated_eta_s_epsilon_out = (1f + _e984);
    let _e986 = modulated_eta_s_epsilon_out;
    one_minus_modulated_eta_s_epsilon_out = (1f - _e986);
    let _e988 = one_plus_modulated_eta_s_epsilon_out;
    let _e989 = one_minus_modulated_eta_s_epsilon_out;
    modulated_eta_s_out = (_e988 / _e989);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e991 = g_ptN;
    N_18 = _e991;
    let _e992 = g_ptV;
    V_14 = _e992;
    let _e993 = g_ptL;
    L_11 = _e993;
    let _e994 = g_ptP;
    P_3 = _e994;
    let _e995 = g_ptOcclusion;
    occlusion_2 = _e995;
    let _e996 = g_ptClosureType;
    param_347 = _e996;
    let _e997 = L_11;
    param_348 = _e997;
    let _e998 = V_14;
    param_349 = _e998;
    let _e999 = N_18;
    param_350 = _e999;
    let _e1000 = P_3;
    param_351 = _e1000;
    let _e1001 = occlusion_2;
    param_352 = _e1001;
    let _e1002 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_347), (&param_348), (&param_349), (&param_350), (&param_351), (&param_352));
    closureData_17 = _e1002;
    fuzz_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1003 = closureData_17;
    param_353 = _e1003;
    let _e1004 = (*fuzz_weight);
    param_354 = _e1004;
    let _e1005 = (*fuzz_color);
    param_355 = _e1005;
    let _e1006 = (*fuzz_roughness);
    param_356 = _e1006;
    let _e1007 = (*geometry_normal);
    param_357 = _e1007;
    param_358 = 1i;
    let _e1008 = fuzz_bsdf_out;
    param_359 = _e1008;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359));
    let _e1009 = param_359;
    fuzz_bsdf_out = _e1009;
    coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1010 = closureData_17;
    param_360 = _e1010;
    let _e1011 = (*coat_weight);
    param_361 = _e1011;
    param_362 = vec3<f32>(1f, 1f, 1f);
    let _e1012 = (*coat_ior);
    param_363 = _e1012;
    let _e1013 = coat_roughness_vector_out;
    param_364 = _e1013;
    param_365 = false;
    param_366 = 0f;
    param_367 = 1.5f;
    let _e1014 = (*geometry_coat_normal);
    param_368 = _e1014;
    let _e1015 = (*geometry_coat_tangent);
    param_369 = _e1015;
    param_370 = 0i;
    param_371 = 0i;
    let _e1016 = coat_bsdf_out;
    param_372 = _e1016;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372));
    let _e1017 = param_372;
    coat_bsdf_out = _e1017;
    metal_bsdf_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1018 = closureData_17;
    param_373 = _e1018;
    let _e1019 = metal_bsdf_tf_mix_fg_weight_out;
    param_374 = _e1019;
    let _e1020 = metal_reflectivity_out;
    param_375 = _e1020;
    let _e1021 = (*specular_color);
    param_376 = _e1021;
    param_377 = vec3<f32>(1f, 1f, 1f);
    param_378 = 5f;
    let _e1022 = main_roughness_out;
    param_379 = _e1022;
    param_380 = false;
    let _e1023 = thin_film_thickness_nm_out;
    param_381 = _e1023;
    let _e1024 = (*thin_film_ior);
    param_382 = _e1024;
    let _e1025 = (*geometry_normal);
    param_383 = _e1025;
    let _e1026 = (*geometry_tangent);
    param_384 = _e1026;
    param_385 = 0i;
    param_386 = 0i;
    let _e1027 = metal_bsdf_tf_out;
    param_387 = _e1027;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_373), (&param_374), (&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387));
    let _e1028 = param_387;
    metal_bsdf_tf_out = _e1028;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1029 = closureData_17;
    param_388 = _e1029;
    let _e1030 = metal_bsdf_tf_mix_bg_weight_out;
    param_389 = _e1030;
    let _e1031 = metal_reflectivity_out;
    param_390 = _e1031;
    let _e1032 = (*specular_color);
    param_391 = _e1032;
    param_392 = vec3<f32>(1f, 1f, 1f);
    param_393 = 5f;
    let _e1033 = main_roughness_out;
    param_394 = _e1033;
    param_395 = false;
    param_396 = 0f;
    param_397 = 1.5f;
    let _e1034 = (*geometry_normal);
    param_398 = _e1034;
    let _e1035 = (*geometry_tangent);
    param_399 = _e1035;
    param_400 = 0i;
    param_401 = 0i;
    let _e1036 = metal_bsdf_out;
    param_402 = _e1036;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402));
    let _e1037 = param_402;
    metal_bsdf_out = _e1037;
    metal_bsdf_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1038 = closureData_17;
    param_403 = _e1038;
    let _e1039 = metal_bsdf_tf_out;
    param_404 = _e1039;
    let _e1040 = metal_bsdf_out;
    param_405 = _e1040;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_403), (&param_404), (&param_405), (&param_406));
    let _e1041 = param_406;
    metal_bsdf_tf_mix_add_out = _e1041;
    base_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1042 = closureData_17;
    param_407 = _e1042;
    let _e1043 = metal_bsdf_tf_mix_add_out;
    param_408 = _e1043;
    let _e1044 = (*base_metalness);
    param_409 = _e1044;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_407), (&param_408), (&param_409), (&param_410));
    let _e1045 = param_410;
    base_substrate_fg_mul_out = _e1045;
    dielectric_reflection_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1046 = closureData_17;
    param_411 = _e1046;
    let _e1047 = dielectric_reflection_tf_mix_fg_weight_out;
    param_412 = _e1047;
    let _e1048 = (*specular_color);
    param_413 = _e1048;
    let _e1049 = modulated_eta_s_out;
    param_414 = _e1049;
    let _e1050 = main_roughness_out;
    param_415 = _e1050;
    param_416 = false;
    let _e1051 = thin_film_thickness_nm_out;
    param_417 = _e1051;
    let _e1052 = (*thin_film_ior);
    param_418 = _e1052;
    let _e1053 = (*geometry_normal);
    param_419 = _e1053;
    let _e1054 = (*geometry_tangent);
    param_420 = _e1054;
    param_421 = 0i;
    param_422 = 0i;
    let _e1055 = dielectric_reflection_tf_out;
    param_423 = _e1055;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420), (&param_421), (&param_422), (&param_423));
    let _e1056 = param_423;
    dielectric_reflection_tf_out = _e1056;
    dielectric_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1057 = closureData_17;
    param_424 = _e1057;
    let _e1058 = dielectric_reflection_tf_mix_bg_weight_out;
    param_425 = _e1058;
    let _e1059 = (*specular_color);
    param_426 = _e1059;
    let _e1060 = modulated_eta_s_out;
    param_427 = _e1060;
    let _e1061 = main_roughness_out;
    param_428 = _e1061;
    param_429 = false;
    param_430 = 0f;
    param_431 = 1.5f;
    let _e1062 = (*geometry_normal);
    param_432 = _e1062;
    let _e1063 = (*geometry_tangent);
    param_433 = _e1063;
    param_434 = 0i;
    param_435 = 0i;
    let _e1064 = dielectric_reflection_out;
    param_436 = _e1064;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_424), (&param_425), (&param_426), (&param_427), (&param_428), (&param_429), (&param_430), (&param_431), (&param_432), (&param_433), (&param_434), (&param_435), (&param_436));
    let _e1065 = param_436;
    dielectric_reflection_out = _e1065;
    dielectric_reflection_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1066 = closureData_17;
    param_437 = _e1066;
    let _e1067 = dielectric_reflection_tf_out;
    param_438 = _e1067;
    let _e1068 = dielectric_reflection_out;
    param_439 = _e1068;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_437), (&param_438), (&param_439), (&param_440));
    let _e1069 = param_440;
    dielectric_reflection_tf_mix_add_out = _e1069;
    dielectric_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1070 = closureData_17;
    param_441 = _e1070;
    param_442 = 1f;
    let _e1071 = if_transmission_tint_out;
    param_443 = _e1071;
    let _e1072 = modulated_eta_s_out;
    param_444 = _e1072;
    let _e1073 = main_roughness_out;
    param_445 = _e1073;
    param_446 = false;
    param_447 = 0f;
    param_448 = 1.5f;
    let _e1074 = (*geometry_normal);
    param_449 = _e1074;
    let _e1075 = (*geometry_tangent);
    param_450 = _e1075;
    param_451 = 0i;
    param_452 = 1i;
    let _e1076 = dielectric_transmission_out;
    param_453 = _e1076;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_441), (&param_442), (&param_443), (&param_444), (&param_445), (&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451), (&param_452), (&param_453));
    let _e1077 = param_453;
    dielectric_transmission_out = _e1077;
    dielectric_volume_out = VDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1078 = closureData_17;
    param_454 = _e1078;
    let _e1079 = if_volume_absorption_out;
    param_455 = _e1079;
    let _e1080 = if_volume_scattering_out;
    param_456 = _e1080;
    let _e1081 = (*transmission_scatter_anisotropy);
    param_457 = _e1081;
    let _e1082 = dielectric_volume_out;
    param_458 = _e1082;
    mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b((&param_454), (&param_455), (&param_456), (&param_457), (&param_458));
    let _e1083 = param_458;
    dielectric_volume_out = _e1083;
    dielectric_volume_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1084 = closureData_17;
    param_459 = _e1084;
    let _e1085 = dielectric_transmission_out;
    param_460 = _e1085;
    let _e1086 = dielectric_volume_out;
    param_461 = _e1086;
    mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_459), (&param_460), (&param_461), (&param_462));
    let _e1087 = param_462;
    dielectric_volume_transmission_out = _e1087;
    dielectric_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1088 = closureData_17;
    param_463 = _e1088;
    let _e1089 = dielectric_volume_transmission_out;
    param_464 = _e1089;
    let _e1090 = (*transmission_weight);
    param_465 = _e1090;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_463), (&param_464), (&param_465), (&param_466));
    let _e1091 = param_466;
    dielectric_substrate_fg_mul_out = _e1091;
    subsurface_thin_walled_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1092 = closureData_17;
    param_467 = _e1092;
    param_468 = 1f;
    let _e1093 = subsurface_color_nonnegative_out;
    param_469 = _e1093;
    let _e1094 = (*base_diffuse_roughness);
    param_470 = _e1094;
    let _e1095 = (*geometry_normal);
    param_471 = _e1095;
    param_472 = false;
    let _e1096 = subsurface_thin_walled_reflection_bsdf_out;
    param_473 = _e1096;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473));
    let _e1097 = param_473;
    subsurface_thin_walled_reflection_bsdf_out = _e1097;
    subsurface_thin_walled_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1098 = closureData_17;
    param_474 = _e1098;
    let _e1099 = subsurface_thin_walled_reflection_bsdf_out;
    param_475 = _e1099;
    let _e1100 = subsurface_thin_walled_brdf_factor_out;
    param_476 = _e1100;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_474), (&param_475), (&param_476), (&param_477));
    let _e1101 = param_477;
    subsurface_thin_walled_reflection_out = _e1101;
    subsurface_thin_walled_transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1102 = closureData_17;
    param_478 = _e1102;
    param_479 = 1f;
    let _e1103 = subsurface_color_nonnegative_out;
    param_480 = _e1103;
    let _e1104 = (*geometry_normal);
    param_481 = _e1104;
    let _e1105 = subsurface_thin_walled_transmission_bsdf_out;
    param_482 = _e1105;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_478), (&param_479), (&param_480), (&param_481), (&param_482));
    let _e1106 = param_482;
    subsurface_thin_walled_transmission_bsdf_out = _e1106;
    subsurface_thin_walled_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1107 = closureData_17;
    param_483 = _e1107;
    let _e1108 = subsurface_thin_walled_transmission_bsdf_out;
    param_484 = _e1108;
    let _e1109 = subsurface_thin_walled_btdf_factor_out;
    param_485 = _e1109;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_483), (&param_484), (&param_485), (&param_486));
    let _e1110 = param_486;
    subsurface_thin_walled_transmission_out = _e1110;
    subsurface_thin_walled_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1111 = closureData_17;
    param_487 = _e1111;
    let _e1112 = subsurface_thin_walled_reflection_out;
    param_488 = _e1112;
    let _e1113 = subsurface_thin_walled_transmission_out;
    param_489 = _e1113;
    param_490 = 0.5f;
    mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_487), (&param_488), (&param_489), (&param_490), (&param_491));
    let _e1114 = param_491;
    subsurface_thin_walled_out = _e1114;
    selected_subsurface_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1115 = closureData_17;
    param_492 = _e1115;
    let _e1116 = subsurface_thin_walled_out;
    param_493 = _e1116;
    let _e1117 = subsurface_selector_out;
    param_494 = _e1117;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_492), (&param_493), (&param_494), (&param_495));
    let _e1118 = param_495;
    selected_subsurface_fg_mul_out = _e1118;
    subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1119 = closureData_17;
    param_496 = _e1119;
    let _e1120 = selected_subsurface_bg_weight_out;
    param_497 = _e1120;
    let _e1121 = subsurface_color_nonnegative_out;
    param_498 = _e1121;
    let _e1122 = subsurface_radius_scaled_out;
    param_499 = _e1122;
    let _e1123 = (*subsurface_scatter_anisotropy);
    param_500 = _e1123;
    let _e1124 = (*geometry_normal);
    param_501 = _e1124;
    let _e1125 = subsurface_bsdf_out;
    param_502 = _e1125;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502));
    let _e1126 = param_502;
    subsurface_bsdf_out = _e1126;
    selected_subsurface_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1127 = closureData_17;
    param_503 = _e1127;
    let _e1128 = selected_subsurface_fg_mul_out;
    param_504 = _e1128;
    let _e1129 = subsurface_bsdf_out;
    param_505 = _e1129;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_503), (&param_504), (&param_505), (&param_506));
    let _e1130 = param_506;
    selected_subsurface_add_out = _e1130;
    opaque_base_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1131 = closureData_17;
    param_507 = _e1131;
    let _e1132 = selected_subsurface_add_out;
    param_508 = _e1132;
    let _e1133 = (*subsurface_weight);
    param_509 = _e1133;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_507), (&param_508), (&param_509), (&param_510));
    let _e1134 = param_510;
    opaque_base_fg_mul_out = _e1134;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1135 = closureData_17;
    param_511 = _e1135;
    let _e1136 = opaque_base_bg_weight_out;
    param_512 = _e1136;
    let _e1137 = base_color_nonnegative_out;
    param_513 = _e1137;
    let _e1138 = (*base_diffuse_roughness);
    param_514 = _e1138;
    let _e1139 = (*geometry_normal);
    param_515 = _e1139;
    param_516 = true;
    let _e1140 = diffuse_bsdf_out;
    param_517 = _e1140;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_511), (&param_512), (&param_513), (&param_514), (&param_515), (&param_516), (&param_517));
    let _e1141 = param_517;
    diffuse_bsdf_out = _e1141;
    opaque_base_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1142 = closureData_17;
    param_518 = _e1142;
    let _e1143 = opaque_base_fg_mul_out;
    param_519 = _e1143;
    let _e1144 = diffuse_bsdf_out;
    param_520 = _e1144;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_518), (&param_519), (&param_520), (&param_521));
    let _e1145 = param_521;
    opaque_base_add_out = _e1145;
    dielectric_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1146 = closureData_17;
    param_522 = _e1146;
    let _e1147 = opaque_base_add_out;
    param_523 = _e1147;
    let _e1148 = dielectric_substrate_mix_inv_out;
    param_524 = _e1148;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_522), (&param_523), (&param_524), (&param_525));
    let _e1149 = param_525;
    dielectric_substrate_bg_mul_out = _e1149;
    dielectric_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1150 = closureData_17;
    param_526 = _e1150;
    let _e1151 = dielectric_substrate_fg_mul_out;
    param_527 = _e1151;
    let _e1152 = dielectric_substrate_bg_mul_out;
    param_528 = _e1152;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_526), (&param_527), (&param_528), (&param_529));
    let _e1153 = param_529;
    dielectric_substrate_add_out = _e1153;
    dielectric_base_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1154 = closureData_17;
    param_530 = _e1154;
    let _e1155 = dielectric_reflection_tf_mix_add_out;
    param_531 = _e1155;
    let _e1156 = dielectric_substrate_add_out;
    param_532 = _e1156;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_530), (&param_531), (&param_532), (&param_533));
    let _e1157 = param_533;
    dielectric_base_out = _e1157;
    base_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1158 = closureData_17;
    param_534 = _e1158;
    let _e1159 = dielectric_base_out;
    param_535 = _e1159;
    let _e1160 = base_substrate_mix_inv_out;
    param_536 = _e1160;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_534), (&param_535), (&param_536), (&param_537));
    let _e1161 = param_537;
    base_substrate_bg_mul_out = _e1161;
    base_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1162 = closureData_17;
    param_538 = _e1162;
    let _e1163 = base_substrate_fg_mul_out;
    param_539 = _e1163;
    let _e1164 = base_substrate_bg_mul_out;
    param_540 = _e1164;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_538), (&param_539), (&param_540), (&param_541));
    let _e1165 = param_541;
    base_substrate_add_out = _e1165;
    darkened_base_substrate_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1166 = closureData_17;
    param_542 = _e1166;
    let _e1167 = base_substrate_add_out;
    param_543 = _e1167;
    let _e1168 = modulated_base_darkening_out;
    param_544 = _e1168;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_542), (&param_543), (&param_544), (&param_545));
    let _e1169 = param_545;
    darkened_base_substrate_out = _e1169;
    coat_substrate_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1170 = closureData_17;
    param_546 = _e1170;
    let _e1171 = darkened_base_substrate_out;
    param_547 = _e1171;
    let _e1172 = coat_attenuation_out;
    param_548 = _e1172;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_546), (&param_547), (&param_548), (&param_549));
    let _e1173 = param_549;
    coat_substrate_attenuated_out = _e1173;
    coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1174 = closureData_17;
    param_550 = _e1174;
    let _e1175 = coat_bsdf_out;
    param_551 = _e1175;
    let _e1176 = coat_substrate_attenuated_out;
    param_552 = _e1176;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_550), (&param_551), (&param_552), (&param_553));
    let _e1177 = param_553;
    coat_layer_out = _e1177;
    fuzz_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1178 = closureData_17;
    param_554 = _e1178;
    let _e1179 = fuzz_bsdf_out;
    param_555 = _e1179;
    let _e1180 = coat_layer_out;
    param_556 = _e1180;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_554), (&param_555), (&param_556), (&param_557));
    let _e1181 = param_557;
    fuzz_layer_out = _e1181;
    let _e1183 = fuzz_layer_out.response;
    let _e1185 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1185 + _e1183);
    let _e1188 = g_ptEmitEmission;
    if (_e1188 != 0i) {
        param_558 = 4i;
        let _e1190 = L_11;
        param_559 = _e1190;
        let _e1191 = V_14;
        param_560 = _e1191;
        let _e1192 = N_18;
        param_561 = _e1192;
        let _e1193 = P_3;
        param_562 = _e1193;
        let _e1194 = occlusion_2;
        param_563 = _e1194;
        let _e1195 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_558), (&param_559), (&param_560), (&param_561), (&param_562), (&param_563));
        closureData_18 = _e1195;
        uncoated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1196 = closureData_18;
        param_564 = _e1196;
        let _e1197 = emission_weight_out;
        param_565 = _e1197;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_564), (&param_565), (&param_566));
        let _e1198 = param_566;
        uncoated_emission_edf_out = _e1198;
        coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1199 = closureData_18;
        param_567 = _e1199;
        let _e1200 = uncoated_emission_edf_out;
        param_568 = _e1200;
        let _e1201 = (*coat_color);
        param_569 = _e1201;
        mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_567), (&param_568), (&param_569), (&param_570));
        let _e1202 = param_570;
        coat_tinted_emission_edf_out = _e1202;
        coated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1203 = closureData_18;
        param_571 = _e1203;
        let _e1204 = one_minus_coat_F0_color_out;
        param_572 = _e1204;
        param_573 = vec3<f32>(0f, 0f, 0f);
        param_574 = 5f;
        let _e1205 = coat_tinted_emission_edf_out;
        param_575 = _e1205;
        mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_571), (&param_572), (&param_573), (&param_574), (&param_575), (&param_576));
        let _e1206 = param_576;
        coated_emission_edf_out = _e1206;
        emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1207 = closureData_18;
        param_577 = _e1207;
        let _e1208 = coated_emission_edf_out;
        param_578 = _e1208;
        let _e1209 = uncoated_emission_edf_out;
        param_579 = _e1209;
        let _e1210 = (*coat_weight);
        param_580 = _e1210;
        mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_577), (&param_578), (&param_579), (&param_580), (&param_581));
        let _e1211 = param_581;
        emission_edf_out = _e1211;
        let _e1212 = emission_edf_out;
        let _e1213 = g_ptEmission;
        g_ptEmission = (_e1213 + _e1212);
        let _e1215 = emission_edf_out;
        let _e1217 = shader_constructor_out.color;
        shader_constructor_out.color = (_e1217 + _e1215);
    }
    let _e1220 = shader_constructor_out;
    (*out1_5) = _e1220;
    return;
}

fn mtlxHostEvalSurface_u0028_() -> surfaceshader {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var open_pbr_surface_surfaceshader_out: surfaceshader;
    var param_582: f32;
    var param_583: vec3<f32>;
    var param_584: f32;
    var param_585: f32;
    var param_586: f32;
    var param_587: vec3<f32>;
    var param_588: f32;
    var param_589: f32;
    var param_590: f32;
    var param_591: f32;
    var param_592: vec3<f32>;
    var param_593: f32;
    var param_594: vec3<f32>;
    var param_595: f32;
    var param_596: f32;
    var param_597: f32;
    var param_598: f32;
    var param_599: vec3<f32>;
    var param_600: f32;
    var param_601: vec3<f32>;
    var param_602: f32;
    var param_603: f32;
    var param_604: vec3<f32>;
    var param_605: f32;
    var param_606: f32;
    var param_607: vec3<f32>;
    var param_608: f32;
    var param_609: f32;
    var param_610: f32;
    var param_611: f32;
    var param_612: f32;
    var param_613: f32;
    var param_614: f32;
    var param_615: f32;
    var param_616: vec3<f32>;
    var param_617: f32;
    var param_618: bool;
    var param_619: vec3<f32>;
    var param_620: vec3<f32>;
    var param_621: vec3<f32>;
    var param_622: vec3<f32>;
    var param_623: surfaceshader;

    let _e387 = g_ptN;
    normalWorld = _e387;
    let _e388 = g_ptTangent;
    tangentWorld = _e388;
    let _e389 = normalWorld;
    geomprop_Nworld_out = normalize(_e389);
    let _e391 = tangentWorld;
    geomprop_Tworld_out = normalize(_e391);
    open_pbr_surface_surfaceshader_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e393 = base_weight_1;
    param_582 = _e393;
    let _e394 = base_color_1;
    param_583 = _e394;
    let _e395 = base_diffuse_roughness_1;
    param_584 = _e395;
    let _e396 = base_metalness_1;
    param_585 = _e396;
    let _e397 = specular_weight_1;
    param_586 = _e397;
    let _e398 = specular_color_1;
    param_587 = _e398;
    let _e399 = specular_roughness_1;
    param_588 = _e399;
    let _e400 = specular_ior_1;
    param_589 = _e400;
    let _e401 = specular_roughness_anisotropy_1;
    param_590 = _e401;
    let _e402 = transmission_weight_1;
    param_591 = _e402;
    let _e403 = transmission_color_1;
    param_592 = _e403;
    let _e404 = transmission_depth_1;
    param_593 = _e404;
    let _e405 = transmission_scatter_1;
    param_594 = _e405;
    let _e406 = transmission_scatter_anisotropy_1;
    param_595 = _e406;
    let _e407 = transmission_dispersion_scale_1;
    param_596 = _e407;
    let _e408 = transmission_dispersion_abbe_number_1;
    param_597 = _e408;
    let _e409 = subsurface_weight_1;
    param_598 = _e409;
    let _e410 = subsurface_color_1;
    param_599 = _e410;
    let _e411 = subsurface_radius_1;
    param_600 = _e411;
    let _e412 = subsurface_radius_scale_1;
    param_601 = _e412;
    let _e413 = subsurface_scatter_anisotropy_1;
    param_602 = _e413;
    let _e414 = fuzz_weight_1;
    param_603 = _e414;
    let _e415 = fuzz_color_1;
    param_604 = _e415;
    let _e416 = fuzz_roughness_1;
    param_605 = _e416;
    let _e417 = coat_weight_1;
    param_606 = _e417;
    let _e418 = coat_color_1;
    param_607 = _e418;
    let _e419 = coat_roughness_1;
    param_608 = _e419;
    let _e420 = coat_roughness_anisotropy_1;
    param_609 = _e420;
    let _e421 = coat_ior_1;
    param_610 = _e421;
    let _e422 = coat_darkening_1;
    param_611 = _e422;
    let _e423 = thin_film_weight_1;
    param_612 = _e423;
    let _e424 = thin_film_thickness_1;
    param_613 = _e424;
    let _e425 = thin_film_ior_1;
    param_614 = _e425;
    let _e426 = emission_luminance_1;
    param_615 = _e426;
    let _e427 = emission_color_1;
    param_616 = _e427;
    let _e428 = geometry_opacity_1;
    param_617 = _e428;
    let _e429 = geometry_thin_walled_1;
    param_618 = _e429;
    let _e430 = geomprop_Nworld_out;
    param_619 = _e430;
    let _e431 = geomprop_Nworld_out;
    param_620 = _e431;
    let _e432 = geomprop_Tworld_out;
    param_621 = _e432;
    let _e433 = geomprop_Tworld_out;
    param_622 = _e433;
    NG_open_pbr_surface_surfaceshader_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_b1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_582), (&param_583), (&param_584), (&param_585), (&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591), (&param_592), (&param_593), (&param_594), (&param_595), (&param_596), (&param_597), (&param_598), (&param_599), (&param_600), (&param_601), (&param_602), (&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615), (&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621), (&param_622), (&param_623));
    let _e434 = param_623;
    open_pbr_surface_surfaceshader_out = _e434;
    let _e435 = open_pbr_surface_surfaceshader_out;
    return _e435;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e345 = (*basis_2).tW;
    let _e347 = (*vLocal)[0u];
    let _e350 = (*basis_2).bW;
    let _e352 = (*vLocal)[1u];
    let _e356 = (*basis_2).nW;
    let _e358 = (*vLocal)[2u];
    return (((_e345 * _e347) + (_e350 * _e352)) + (_e356 * _e358));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_624: vec3<f32>;
    var param_625: Basis;
    var param_626: vec3<f32>;
    var param_627: Basis;

    let _e351 = (*pW_3);
    g_ptP = _e351;
    let _e353 = (*basis_3).nW;
    g_ptN = _e353;
    let _e355 = (*basis_3).tW;
    g_ptTangent = _e355;
    let _e357 = (*basis_3).bW;
    g_ptBitangent = _e357;
    let _e358 = (*winputL_2);
    param_624 = _e358;
    let _e359 = (*basis_3);
    param_625 = _e359;
    let _e360 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_624), (&param_625));
    g_ptV = _e360;
    let _e361 = (*woutputL_2);
    param_626 = _e361;
    let _e362 = (*basis_3);
    param_627 = _e362;
    let _e363 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_626), (&param_627));
    g_ptL = _e363;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e365 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e365, 0f) / 3.1415927f);
    let _e368 = mtlxHostEvalSurface_u0028_();
    return _e368.color;
}

fn evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b(pW_4: ptr<function, vec3<f32>>, basis_4: ptr<function, Basis>, winputL_3: ptr<function, vec3<f32>>, woutputL_3: ptr<function, vec3<f32>>, surfaceshader_1: ptr<function, i32>, pdf_woutputL_3: ptr<function, f32>) -> vec3<f32> {
    var param_628: vec3<f32>;
    var param_629: Basis;
    var param_630: vec3<f32>;
    var param_631: vec3<f32>;
    var param_632: f32;
    var param_633: vec3<f32>;
    var param_634: Basis;
    var param_635: vec3<f32>;
    var param_636: vec3<f32>;
    var param_637: f32;
    var param_638: vec3<f32>;
    var param_639: Basis;
    var param_640: vec3<f32>;
    var param_641: vec3<f32>;
    var param_642: f32;

    let _e363 = (*surfaceshader_1);
    if (_e363 == 1i) {
        let _e365 = (*pW_4);
        param_628 = _e365;
        let _e366 = (*basis_4);
        param_629 = _e366;
        let _e367 = (*winputL_3);
        param_630 = _e367;
        let _e368 = (*woutputL_3);
        param_631 = _e368;
        let _e369 = (*pdf_woutputL_3);
        param_632 = _e369;
        let _e370 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_628), (&param_629), (&param_630), (&param_631), (&param_632));
        let _e371 = param_632;
        (*pdf_woutputL_3) = _e371;
        return _e370;
    } else {
        let _e372 = (*surfaceshader_1);
        if (_e372 == 2i) {
            let _e374 = (*pW_4);
            param_633 = _e374;
            let _e375 = (*basis_4);
            param_634 = _e375;
            let _e376 = (*winputL_3);
            param_635 = _e376;
            let _e377 = (*woutputL_3);
            param_636 = _e377;
            let _e378 = (*pdf_woutputL_3);
            param_637 = _e378;
            let _e379 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_633), (&param_634), (&param_635), (&param_636), (&param_637));
            let _e380 = param_637;
            (*pdf_woutputL_3) = _e380;
            return _e379;
        } else {
            let _e381 = (*pW_4);
            param_638 = _e381;
            let _e382 = (*basis_4);
            param_639 = _e382;
            let _e383 = (*winputL_3);
            param_640 = _e383;
            let _e384 = (*woutputL_3);
            param_641 = _e384;
            let _e385 = (*pdf_woutputL_3);
            param_642 = _e385;
            let _e386 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_638), (&param_639), (&param_640), (&param_641), (&param_642));
            let _e387 = param_642;
            (*pdf_woutputL_3) = _e387;
            return _e386;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    let _e342 = geometry_thin_walled_1;
    return _e342;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e342 = g_ptOpacity;
    return (_e342 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e344 = (*N_19);
    l = length(_e344);
    let _e346 = (*N_19);
    let _e347 = l;
    return (_e346 / vec3(max(_e347, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_643: vec3<f32>;

    let _e346 = (*N_20)[2u];
    let _e349 = (*N_20)[0u];
    if (abs(_e346) < abs(_e349)) {
        let _e353 = (*N_20)[2u];
        let _e355 = (*N_20)[0u];
        T = vec3<f32>(_e353, 0f, -(_e355));
    } else {
        let _e359 = (*N_20)[2u];
        let _e361 = (*N_20)[1u];
        T = vec3<f32>(0f, _e359, -(_e361));
    }
    let _e364 = T;
    param_643 = _e364;
    let _e365 = safe_normalize_u0028_vf3_u003b((&param_643));
    T = _e365;
    let _e366 = T;
    return _e366;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e346 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e346).x;
    let _e349 = (*index);
    let _e350 = width;
    let _e358 = (*index);
    let _e359 = width;
    let _e362 = textureLoad(texture, vec2<i32>((_e349 - (i32(floor((f32(_e349) / f32(_e350)))) * _e350)), (_e358 / _e359)), 0i);
    return _e362;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_644: i32;
    var param_645: i32;
    var param_646: i32;

    let _e350 = (*barycoord)[0u];
    let _e352 = (*faceIndices)[0u];
    param_644 = bitcast<i32>(_e352);
    let _e354 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_644));
    let _e357 = (*barycoord)[1u];
    let _e359 = (*faceIndices)[1u];
    param_645 = bitcast<i32>(_e359);
    let _e361 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_645));
    let _e365 = (*barycoord)[2u];
    let _e367 = (*faceIndices)[2u];
    param_646 = bitcast<i32>(_e367);
    let _e369 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_646));
    return (((_e354 * _e350) + (_e361 * _e357)) + (_e369 * _e365));
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

    let _e354 = (*direction);
    inverseDirection = (vec3(1f) / _e354);
    let _e357 = (*minimum);
    let _e358 = (*origin);
    let _e360 = inverseDirection;
    t0_2 = ((_e357 - _e358) * _e360);
    let _e362 = (*maximum);
    let _e363 = (*origin);
    let _e365 = inverseDirection;
    t1_2 = ((_e362 - _e363) * _e365);
    let _e367 = t0_2;
    let _e368 = t1_2;
    entry = min(_e367, _e368);
    let _e370 = t0_2;
    let _e371 = t1_2;
    exit = max(_e370, _e371);
    let _e374 = entry[0u];
    let _e376 = entry[1u];
    let _e378 = entry[2u];
    nearDistance = max(_e374, max(_e376, _e378));
    let _e382 = exit[0u];
    let _e384 = exit[1u];
    let _e386 = exit[2u];
    farDistance = min(_e382, min(_e384, _e386));
    let _e389 = farDistance;
    let _e390 = nearDistance;
    if (_e389 >= max(_e390, 0f)) {
        let _e393 = nearDistance;
        local_10 = max(_e393, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e395 = local_10;
    return _e395;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist_2: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_647: i32;
    var maximum_1: vec4<f32>;
    var param_648: i32;
    var metadata: vec4<f32>;
    var param_649: i32;
    var param_650: vec3<f32>;
    var param_651: vec3<f32>;
    var param_652: vec3<f32>;
    var param_653: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_654: i32;
    var p0_: vec3<f32>;
    var param_655: i32;
    var p1_: vec3<f32>;
    var param_656: i32;
    var p2_: vec3<f32>;
    var param_657: i32;
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
    var phi_1433_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e395 = (*maxDistance);
    closest = _e395;
    found = false;
    loop {
        let _e396 = pointer;
        let _e398 = pointer;
        if ((_e396 >= 0i) && (_e398 < 64i)) {
            let _e401 = pointer;
            pointer = (_e401 - 1i);
            let _e404 = stack[_e401];
            nodeIndex = _e404;
            let _e405 = nodeIndex;
            param_647 = (_e405 * 3i);
            let _e407 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_647));
            minimum_1 = _e407;
            let _e408 = nodeIndex;
            param_648 = ((_e408 * 3i) + 1i);
            let _e411 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_648));
            maximum_1 = _e411;
            let _e412 = nodeIndex;
            param_649 = ((_e412 * 3i) + 2i);
            let _e415 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_649));
            metadata = _e415;
            let _e416 = minimum_1;
            param_650 = _e416.xyz;
            let _e418 = maximum_1;
            param_651 = _e418.xyz;
            let _e420 = (*rayOrigin);
            param_652 = _e420;
            let _e421 = (*rayDirection);
            param_653 = _e421;
            let _e422 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_650), (&param_651), (&param_652), (&param_653));
            let _e423 = closest;
            if (_e422 > _e423) {
                continue;
            }
            let _e426 = metadata[2u];
            if (_e426 > 0.5f) {
                let _e429 = metadata[0u];
                offset = i32((_e429 + 0.5f));
                let _e433 = metadata[1u];
                count = i32((_e433 + 0.5f));
                triangle = 0i;
                loop {
                    let _e436 = triangle;
                    let _e437 = count;
                    if (_e436 < _e437) {
                        let _e439 = offset;
                        let _e440 = triangle;
                        param_654 = (_e439 + _e440);
                        let _e442 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_654));
                        vertexIndices = vec3<u32>((_e442.xyz + vec3(0.5f)));
                        let _e448 = vertexIndices[0u];
                        param_655 = bitcast<i32>(_e448);
                        let _e450 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_655));
                        p0_ = _e450.xyz;
                        let _e453 = vertexIndices[1u];
                        param_656 = bitcast<i32>(_e453);
                        let _e455 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_656));
                        p1_ = _e455.xyz;
                        let _e458 = vertexIndices[2u];
                        param_657 = bitcast<i32>(_e458);
                        let _e460 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_657));
                        p2_ = _e460.xyz;
                        let _e462 = p1_;
                        let _e463 = p0_;
                        edge0_ = (_e462 - _e463);
                        let _e465 = p2_;
                        let _e466 = p0_;
                        edge1_ = (_e465 - _e466);
                        let _e468 = (*rayDirection);
                        let _e469 = edge1_;
                        pvec = cross(_e468, _e469);
                        let _e471 = edge0_;
                        let _e472 = pvec;
                        determinant_ = dot(_e471, _e472);
                        let _e474 = determinant_;
                        if (abs(_e474) < 0.00000001f) {
                            continue;
                        }
                        let _e477 = determinant_;
                        inverseDeterminant = (1f / _e477);
                        let _e479 = (*rayOrigin);
                        let _e480 = p0_;
                        tvec = (_e479 - _e480);
                        let _e482 = tvec;
                        let _e483 = pvec;
                        let _e485 = inverseDeterminant;
                        u = (dot(_e482, _e483) * _e485);
                        let _e487 = tvec;
                        let _e488 = edge0_;
                        qvec = cross(_e487, _e488);
                        let _e490 = (*rayDirection);
                        let _e491 = qvec;
                        let _e493 = inverseDeterminant;
                        v_3 = (dot(_e490, _e491) * _e493);
                        let _e495 = edge1_;
                        let _e496 = qvec;
                        let _e498 = inverseDeterminant;
                        distance_ = (dot(_e495, _e496) * _e498);
                        let _e500 = u;
                        let _e502 = v_3;
                        let _e504 = ((_e500 >= 0f) && (_e502 >= 0f));
                        phi_1433_ = _e504;
                        if _e504 {
                            let _e505 = u;
                            let _e506 = v_3;
                            phi_1433_ = ((_e505 + _e506) <= 1f);
                        }
                        let _e510 = phi_1433_;
                        let _e511 = distance_;
                        let _e514 = distance_;
                        let _e515 = closest;
                        if ((_e510 && (_e511 > 0f)) && (_e514 < _e515)) {
                            let _e518 = distance_;
                            closest = _e518;
                            let _e519 = distance_;
                            (*dist_2) = _e519;
                            let _e520 = u;
                            let _e522 = v_3;
                            let _e524 = u;
                            let _e525 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e520) - _e522), _e524, _e525);
                            let _e527 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e527.x, _e527.y, _e527.z, 0u);
                            let _e532 = edge0_;
                            let _e533 = edge1_;
                            (*faceNormal) = normalize(cross(_e532, _e533));
                            let _e536 = determinant_;
                            (*side) = select(1f, -1f, (_e536 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e539 = triangle;
                        triangle = (_e539 + 1i);
                    }
                }
            } else {
                let _e542 = metadata[0u];
                left = i32((_e542 + 0.5f));
                let _e546 = metadata[1u];
                right = i32((_e546 + 0.5f));
                let _e549 = pointer;
                if ((_e549 + 2i) >= 64i) {
                    continue;
                }
                let _e552 = pointer;
                let _e553 = (_e552 + 1i);
                pointer = _e553;
                let _e554 = right;
                stack[_e553] = _e554;
                let _e556 = pointer;
                let _e557 = (_e556 + 1i);
                pointer = _e557;
                let _e558 = left;
                stack[_e557] = _e558;
            }
            continue;
        } else {
            break;
        }
    }
    let _e560 = found;
    return _e560;
}

fn bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1: texture_2d<f32>, nodesSampler_1: sampler, indices_1: texture_2d<f32>, indicesSampler_1: sampler, positions_1: texture_2d<f32>, positionsSampler_1: sampler, rayOrigin_1: ptr<function, vec3<f32>>, rayDirection_1: ptr<function, vec3<f32>>, maxDistance_1: ptr<function, f32>, faceIndices_2: ptr<function, vec4<u32>>, faceNormal_1: ptr<function, vec3<f32>>, barycoord_2: ptr<function, vec3<f32>>, side_1: ptr<function, f32>, dist_3: ptr<function, f32>) -> bool {
    var param_658: vec3<f32>;
    var param_659: vec3<f32>;
    var param_660: f32;
    var param_661: vec4<u32>;
    var param_662: vec3<f32>;
    var param_663: vec3<f32>;
    var param_664: f32;
    var param_665: f32;

    let _e364 = (*rayOrigin_1);
    param_658 = _e364;
    let _e365 = (*rayDirection_1);
    param_659 = _e365;
    let _e366 = (*maxDistance_1);
    param_660 = _e366;
    let _e367 = (*faceIndices_2);
    param_661 = _e367;
    let _e368 = (*faceNormal_1);
    param_662 = _e368;
    let _e369 = (*barycoord_2);
    param_663 = _e369;
    let _e370 = (*side_1);
    param_664 = _e370;
    let _e371 = (*dist_3);
    param_665 = _e371;
    let _e372 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_658), (&param_659), (&param_660), (&param_661), (&param_662), (&param_663), (&param_664), (&param_665));
    let _e373 = param_661;
    (*faceIndices_2) = _e373;
    let _e374 = param_662;
    (*faceNormal_1) = _e374;
    let _e375 = param_663;
    (*barycoord_2) = _e375;
    let _e376 = param_664;
    (*side_1) = _e376;
    let _e377 = param_665;
    (*dist_3) = _e377;
    return _e372;
}

fn trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b(rayOrigin_2: ptr<function, vec3<f32>>, rayDir: ptr<function, vec3<f32>>, maxDistance_2: ptr<function, f32>, P_4: ptr<function, vec3<f32>>, Ns: ptr<function, vec3<f32>>, Ng: ptr<function, vec3<f32>>, Ts: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>, surfaceshader_2: ptr<function, i32>) -> bool {
    var faceIndices_surface: vec4<u32>;
    var faceNormal_surface: vec3<f32>;
    var barycoord_surface: vec3<f32>;
    var side_surface: f32;
    var dist_surface: f32;
    var hit_surface: bool;
    var param_666: vec3<f32>;
    var param_667: vec3<f32>;
    var param_668: f32;
    var param_669: vec4<u32>;
    var param_670: vec3<f32>;
    var param_671: vec3<f32>;
    var param_672: f32;
    var param_673: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_674: vec3<f32>;
    var gN: vec4<f32>;
    var param_675: vec3<f32>;
    var param_676: vec3<u32>;
    var gT: vec4<f32>;
    var param_677: vec3<f32>;
    var param_678: vec3<u32>;
    var local_11: vec3<f32>;
    var local_12: vec2<f32>;
    var local_13: vec3<f32>;
    var param_679: vec3<f32>;
    var param_680: vec3<f32>;
    var param_681: vec3<u32>;
    var phi_7830_: bool;
    var phi_7852_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e384 = (*rayOrigin_2);
    param_666 = _e384;
    let _e385 = (*rayDir);
    param_667 = _e385;
    let _e386 = (*maxDistance_2);
    param_668 = _e386;
    let _e387 = faceIndices_surface;
    param_669 = _e387;
    let _e388 = faceNormal_surface;
    param_670 = _e388;
    let _e389 = barycoord_surface;
    param_671 = _e389;
    let _e390 = side_surface;
    param_672 = _e390;
    let _e391 = dist_surface;
    param_673 = _e391;
    let _e392 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_666), (&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672), (&param_673));
    let _e393 = param_669;
    faceIndices_surface = _e393;
    let _e394 = param_670;
    faceNormal_surface = _e394;
    let _e395 = param_671;
    barycoord_surface = _e395;
    let _e396 = param_672;
    side_surface = _e396;
    let _e397 = param_673;
    dist_surface = _e397;
    hit_surface = _e392;
    dist_closest = 100000000000000000000f;
    let _e398 = hit_surface;
    if _e398 {
        let _e399 = dist_closest;
        let _e400 = dist_surface;
        dist_closest = min(_e399, _e400);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e403 = (*rayDir)[1u];
    if (abs(_e403) > 0.0000000001f) {
        let _e407 = (*rayOrigin_2)[1u];
        let _e410 = (*rayDir)[1u];
        t = ((0.01f - _e407) / _e410);
        let _e412 = t;
        let _e413 = (_e412 > 0f);
        phi_7830_ = _e413;
        if _e413 {
            let _e414 = t;
            let _e415 = dist_closest;
            let _e416 = (*maxDistance_2);
            phi_7830_ = (_e414 < min(_e415, _e416));
        }
        let _e420 = phi_7830_;
        if _e420 {
            let _e421 = t;
            dist_ground = _e421;
            hit_ground = true;
        }
    }
    let _e422 = hit_surface;
    let _e423 = hit_ground;
    hit = (_e422 || _e423);
    let _e425 = hit;
    if !(_e425) {
        return false;
    }
    let _e427 = hit_surface;
    phi_7852_ = _e427;
    if _e427 {
        let _e428 = hit_ground;
        let _e430 = dist_surface;
        let _e431 = dist_ground;
        phi_7852_ = (!(_e428) || (_e430 <= _e431));
    }
    let _e435 = phi_7852_;
    if _e435 {
        let _e436 = (*rayOrigin_2);
        let _e437 = dist_surface;
        let _e438 = (*rayDir);
        (*P_4) = (_e436 + (_e438 * _e437));
        let _e441 = barycoord_surface;
        (*baryCoord) = _e441;
        let _e442 = faceNormal_surface;
        param_674 = _e442;
        let _e443 = safe_normalize_u0028_vf3_u003b((&param_674));
        (*Ng) = _e443;
        let _e444 = barycoord_surface;
        param_675 = _e444;
        let _e445 = faceIndices_surface;
        param_676 = _e445.xyz;
        let _e447 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_675), (&param_676));
        gN = _e447;
        let _e448 = barycoord_surface;
        param_677 = _e448;
        let _e449 = faceIndices_surface;
        param_678 = _e449.xyz;
        let _e451 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_677), (&param_678));
        gT = _e451;
        let _e453 = unnamed.has_normals_surface;
        if (_e453 != 0u) {
            let _e455 = gN;
            local_11 = _e455.xyz;
        } else {
            let _e457 = (*Ng);
            local_11 = _e457;
        }
        let _e458 = local_11;
        (*Ns) = _e458;
        let _e460 = unnamed.has_uvs_surface;
        if (_e460 != 0u) {
            let _e463 = gN[3u];
            let _e465 = gT[3u];
            local_12 = vec2<f32>(_e463, _e465);
        } else {
            let _e467 = barycoord_surface;
            local_12 = _e467.xy;
        }
        let _e469 = local_12;
        (*texCoord) = _e469;
        let _e471 = unnamed.has_tangents_surface;
        if (_e471 != 0u) {
            let _e473 = gT;
            local_13 = _e473.xyz;
        } else {
            let _e475 = (*Ns);
            param_679 = _e475;
            let _e476 = normalToTangent_u0028_vf3_u003b((&param_679));
            local_13 = _e476;
        }
        let _e477 = local_13;
        (*Ts) = _e477;
        let _e478 = barycoord_surface;
        param_680 = _e478;
        let _e479 = faceIndices_surface;
        param_681 = _e479.xyz;
        let _e481 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_680), (&param_681));
        (*surfaceshader_2) = select(1i, 0i, (_e481.x > 0.5f));
    } else {
        let _e485 = hit_ground;
        if _e485 {
            let _e486 = (*rayOrigin_2);
            let _e487 = dist_ground;
            let _e488 = (*rayDir);
            (*P_4) = (_e486 + (_e488 * _e487));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e491 = (*Ng);
            (*Ns) = _e491;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e493 = (*P_4)[0u];
            let _e495 = (*P_4)[2u];
            (*texCoord) = (((vec2<f32>(_e493, -(_e495)) / vec2(200f)) * 2f) + vec2(0.5f));
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
    var param_682: vec3<f32>;
    var param_683: vec3<f32>;
    var param_684: f32;
    var param_685: vec3<f32>;
    var param_686: vec3<f32>;
    var param_687: vec3<f32>;
    var param_688: vec3<f32>;
    var param_689: vec3<f32>;
    var param_690: vec2<f32>;
    var param_691: i32;
    var phi_7996_: bool;
    var phi_8000_: bool;

    let _e363 = (*rayOrigin_3);
    param_682 = _e363;
    let _e364 = (*rayDir_1);
    param_683 = _e364;
    let _e365 = (*maxDistance_3);
    param_684 = _e365;
    let _e366 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687), (&param_688), (&param_689), (&param_690), (&param_691));
    let _e367 = param_685;
    pW_5 = _e367;
    let _e368 = param_686;
    nsW = _e368;
    let _e369 = param_687;
    ngW = _e369;
    let _e370 = param_688;
    TsW = _e370;
    let _e371 = param_689;
    baryCoord_1 = _e371;
    let _e372 = param_690;
    texCoord_1 = _e372;
    let _e373 = param_691;
    surfaceshader_3 = _e373;
    hit_1 = _e366;
    let _e374 = hit_1;
    let _e375 = surfaceshader_3;
    let _e377 = (_e374 && (_e375 == 1i));
    phi_7996_ = _e377;
    if _e377 {
        let _e378 = mtlx_openpbr_is_opaque_u0028_();
        phi_7996_ = !(_e378);
    }
    let _e381 = phi_7996_;
    phi_8000_ = _e381;
    if _e381 {
        let _e382 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_8000_ = _e382;
    }
    let _e384 = phi_8000_;
    if _e384 {
        return 1f;
    }
    let _e385 = hit_1;
    return select(1f, 0f, _e385);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e344 = (*v_4)[0u];
    let _e346 = (*v_4)[1u];
    let _e348 = (*v_4)[2u];
    return max(_e344, max(_e346, _e348));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e344 = (*vWorld);
    let _e346 = (*basis_5).tW;
    let _e348 = (*vWorld);
    let _e350 = (*basis_5).bW;
    let _e352 = (*vWorld);
    let _e354 = (*basis_5).nW;
    return vec3<f32>(dot(_e344, _e346), dot(_e348, _e350), dot(_e352, _e354));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e345 = (*v_5);
    state = ((_e345 * 747796405u) + 2891336453u);
    let _e348 = state;
    let _e349 = state;
    let _e355 = state;
    word = (((_e348 >> bitcast<u32>(((_e349 >> bitcast<u32>(28u)) + 4u))) ^ _e355) * 277803737u);
    let _e358 = word;
    let _e361 = word;
    return ((_e358 >> bitcast<u32>(22u)) ^ _e361);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_692: u32;

    let _e344 = (*seed);
    param_692 = _e344;
    let _e345 = pcg_u0028_u1_u003b((&param_692));
    (*seed) = _e345;
    let _e346 = (*seed);
    return (f32((_e346 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_4: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e350 = (*i_4);
    let _e352 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e350), 0i);
    t0_3 = _e352;
    let _e353 = (*i_4);
    let _e355 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e353), 0i);
    t1_3 = _e355;
    let _e356 = (*i_4);
    let _e358 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e356), 0i);
    t2_2 = _e358;
    let _e359 = (*i_4);
    let _e361 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e359), 0i);
    t3_2 = _e361;
    let _e362 = (*i_4);
    let _e364 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e362), 0i);
    t4_2 = _e364;
    let _e365 = (*i_4);
    let _e367 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e365), 0i);
    t5_ = _e367;
    let _e368 = t0_3;
    l_1.position = _e368.xyz;
    let _e372 = t0_3[3u];
    l_1.decayRate = _e372;
    let _e374 = t1_3;
    l_1.direction = _e374.xyz;
    let _e378 = t1_3[3u];
    l_1.type_ = i32((_e378 + 0.5f));
    let _e382 = t2_2;
    l_1.color = _e382.xyz;
    let _e386 = t2_2[3u];
    l_1.intensity = _e386;
    let _e389 = t3_2[0u];
    l_1.innerCone = _e389;
    let _e392 = t3_2[1u];
    l_1.outerCone = _e392;
    let _e394 = t4_2;
    l_1.u = _e394.xyz;
    let _e397 = t5_;
    l_1.v = _e397.xyz;
    let _e400 = l_1;
    return _e400;
}

fn mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(index_1: ptr<function, i32>, pW_6: ptr<function, vec3<f32>>, basis_6: ptr<function, Basis>, woutputL_4: ptr<function, vec3<f32>>, woutputW: ptr<function, vec3<f32>>, maxDistance_4: ptr<function, f32>, rndSeed: ptr<function, u32>) -> vec3<f32> {
    var l_2: MtlxLight;
    var param_693: i32;
    var intensity: vec3<f32>;
    var param_694: vec3<f32>;
    var xi: vec2<f32>;
    var param_695: u32;
    var param_696: u32;
    var pointOnLight: vec3<f32>;
    var lightNormal: vec3<f32>;
    var param_697: vec3<f32>;
    var area: f32;
    var toLight: vec3<f32>;
    var distSq: f32;
    var distanceToLight: f32;
    var cosLight: f32;
    var param_698: vec3<f32>;
    var param_699: Basis;
    var param_700: vec3<f32>;
    var param_701: Basis;
    var toLight_1: vec3<f32>;
    var distanceToLight_1: f32;
    var attenuation: f32;
    var cosDir: f32;
    var param_702: vec3<f32>;
    var low: f32;
    var high: f32;
    var param_703: vec3<f32>;
    var param_704: Basis;

    let _e377 = (*index_1);
    param_693 = _e377;
    let _e378 = GetMtlxLight_u0028_i1_u003b((&param_693));
    l_2 = _e378;
    let _e380 = l_2.color;
    let _e382 = l_2.intensity;
    intensity = (_e380 * _e382);
    (*maxDistance_4) = 100000000000000000000f;
    let _e385 = l_2.type_;
    if (_e385 == 1i) {
        let _e388 = l_2.direction;
        param_694 = -(_e388);
        let _e390 = safe_normalize_u0028_vf3_u003b((&param_694));
        (*woutputW) = _e390;
    } else {
        let _e392 = l_2.type_;
        if (_e392 == 3i) {
            let _e394 = (*rndSeed);
            param_695 = _e394;
            let _e395 = rand_u0028_u1_u003b((&param_695));
            let _e396 = param_695;
            (*rndSeed) = _e396;
            let _e397 = (*rndSeed);
            param_696 = _e397;
            let _e398 = rand_u0028_u1_u003b((&param_696));
            let _e399 = param_696;
            (*rndSeed) = _e399;
            xi = vec2<f32>(_e395, _e398);
            let _e402 = l_2.position;
            let _e404 = xi[0u];
            let _e406 = l_2.u;
            let _e410 = xi[1u];
            let _e412 = l_2.v;
            pointOnLight = ((_e402 + (_e406 * _e404)) + (_e412 * _e410));
            let _e416 = l_2.u;
            let _e418 = l_2.v;
            param_697 = cross(_e416, _e418);
            let _e420 = safe_normalize_u0028_vf3_u003b((&param_697));
            lightNormal = _e420;
            let _e422 = l_2.u;
            let _e424 = l_2.v;
            area = length(cross(_e422, _e424));
            let _e427 = pointOnLight;
            let _e428 = (*pW_6);
            toLight = (_e427 - _e428);
            let _e430 = toLight;
            let _e431 = toLight;
            distSq = max(dot(_e430, _e431), 0.0000000001f);
            let _e434 = distSq;
            distanceToLight = sqrt(_e434);
            let _e436 = toLight;
            let _e437 = distanceToLight;
            (*woutputW) = (_e436 / vec3(_e437));
            let _e440 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e440 - 0.0002f));
            let _e443 = lightNormal;
            let _e444 = (*woutputW);
            cosLight = max(dot(_e443, -(_e444)), 0f);
            let _e448 = cosLight;
            let _e450 = area;
            if ((_e448 <= 0f) || (_e450 <= 0f)) {
                let _e453 = (*woutputW);
                param_698 = _e453;
                let _e454 = (*basis_6);
                param_699 = _e454;
                let _e455 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_698), (&param_699));
                (*woutputL_4) = _e455;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e456 = cosLight;
            let _e457 = area;
            let _e459 = distSq;
            let _e461 = intensity;
            intensity = (_e461 * ((_e456 * _e457) / _e459));
            let _e463 = (*woutputW);
            param_700 = _e463;
            let _e464 = (*basis_6);
            param_701 = _e464;
            let _e465 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_700), (&param_701));
            (*woutputL_4) = _e465;
            let _e466 = intensity;
            return _e466;
        } else {
            let _e468 = l_2.position;
            let _e469 = (*pW_6);
            toLight_1 = (_e468 - _e469);
            let _e471 = toLight_1;
            distanceToLight_1 = max(length(_e471), 0.0000000001f);
            let _e474 = toLight_1;
            let _e475 = distanceToLight_1;
            (*woutputW) = (_e474 / vec3(_e475));
            let _e478 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e478 - 0.0002f));
            let _e481 = distanceToLight_1;
            let _e484 = l_2.decayRate;
            attenuation = pow((_e481 + 1f), (_e484 + 0.0000000001f));
            let _e487 = attenuation;
            let _e489 = intensity;
            intensity = (_e489 / vec3(max(_e487, 0.0000000001f)));
            let _e493 = l_2.type_;
            if (_e493 == 2i) {
                let _e495 = (*woutputW);
                let _e497 = l_2.direction;
                param_702 = _e497;
                let _e498 = safe_normalize_u0028_vf3_u003b((&param_702));
                cosDir = dot(_e495, -(_e498));
                let _e502 = l_2.innerCone;
                let _e504 = l_2.outerCone;
                low = min(_e502, _e504);
                let _e507 = l_2.innerCone;
                high = _e507;
                let _e508 = low;
                let _e509 = high;
                let _e510 = cosDir;
                let _e512 = intensity;
                intensity = (_e512 * smoothstep(_e508, _e509, _e510));
            }
        }
    }
    let _e514 = (*woutputW);
    param_703 = _e514;
    let _e515 = (*basis_6);
    param_704 = _e515;
    let _e516 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_703), (&param_704));
    (*woutputL_4) = _e516;
    let _e517 = intensity;
    return _e517;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_705: i32;
    var power: f32;

    let _e346 = (*index_2);
    param_705 = _e346;
    let _e347 = GetMtlxLight_u0028_i1_u003b((&param_705));
    l_3 = _e347;
    let _e349 = l_3.color;
    let _e351 = l_3.intensity;
    power = length((_e349 * _e351));
    let _e355 = l_3.type_;
    if (_e355 == 3i) {
        let _e358 = l_3.u;
        let _e360 = l_3.v;
        let _e363 = power;
        power = (_e363 * length(cross(_e358, _e360)));
    }
    let _e365 = power;
    return _e365;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e347 = unnamed.sunAngularSize;
    theta_max = ((_e347 * 3.1415927f) / 180f);
    let _e350 = (*woutputW_1);
    let _e352 = unnamed.sunDir;
    let _e354 = theta_max;
    if (dot(_e350, _e352) < cos(_e354)) {
        return 0f;
    }
    let _e357 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e357)));
    let _e361 = solid_angle;
    return (1f / _e361);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e345 = unnamed.sunAngularSize;
    theta_max_1 = ((_e345 * 3.1415927f) / 180f);
    let _e348 = (*woutputW_2);
    let _e350 = unnamed.sunDir;
    let _e352 = theta_max_1;
    if (dot(_e348, _e350) < cos(_e352)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e356 = unnamed.sunPower;
    let _e358 = unnamed.sunColor;
    return (_e358 * _e356);
}

fn envMapLuminance_u0028_vf3_u003b(c_3: ptr<function, vec3<f32>>) -> f32 {
    let _e343 = (*c_3);
    return dot(_e343, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_7: ptr<function, vec3<f32>>) -> f32 {
    var theta_1: f32;
    var s_4: f32;
    var pdf_2: f32;
    var param_706: vec3<f32>;

    let _e349 = (*uv_3)[1u];
    theta_1 = (_e349 * 3.1415927f);
    let _e351 = theta_1;
    s_4 = sin(_e351);
    let _e353 = s_4;
    if (_e353 <= 0f) {
        return 0f;
    }
    let _e355 = (*color_7);
    param_706 = _e355;
    let _e356 = envMapLuminance_u0028_vf3_u003b((&param_706));
    let _e358 = unnamed.envMapTotalSum;
    pdf_2 = (_e356 / max(_e358, 0.0000000001f));
    let _e361 = pdf_2;
    let _e364 = unnamed.envMapRes[0u];
    let _e368 = unnamed.envMapRes[1u];
    let _e370 = s_4;
    return (((_e361 * _e364) * _e368) / (19.739208f * _e370));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_2: f32;
    var s_5: f32;

    let _e347 = (*uv_4)[0u];
    phi_1 = (_e347 * 6.2831855f);
    let _e350 = (*uv_4)[1u];
    theta_2 = (_e350 * 3.1415927f);
    let _e352 = theta_2;
    s_5 = sin(_e352);
    let _e354 = s_5;
    let _e356 = phi_1;
    let _e359 = theta_2;
    let _e361 = s_5;
    let _e363 = phi_1;
    return vec3<f32>((-(_e354) * cos(_e356)), cos(_e359), (-(_e361) * sin(_e363)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_11: i32;

    let _e351 = unnamed.envMapRes;
    res = vec2<i32>(_e351);
    lower = 0i;
    let _e354 = res[1u];
    upper = (_e354 - 1i);
    loop {
        let _e356 = lower;
        let _e357 = upper;
        if (_e356 < _e357) {
            let _e359 = lower;
            let _e360 = upper;
            mid = ((_e359 + _e360) >> bitcast<u32>(1i));
            let _e364 = (*value);
            let _e366 = res[0u];
            let _e368 = mid;
            let _e370 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e366 - 1i), _e368), 0i);
            if (_e364 < _e370.x) {
                let _e373 = mid;
                upper = _e373;
            } else {
                let _e374 = mid;
                lower = (_e374 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e376 = lower;
    let _e378 = res[1u];
    y_5 = clamp(_e376, 0i, (_e378 - 1i));
    lower = 0i;
    let _e382 = res[0u];
    upper = (_e382 - 1i);
    loop {
        let _e384 = lower;
        let _e385 = upper;
        if (_e384 < _e385) {
            let _e387 = lower;
            let _e388 = upper;
            mid_1 = ((_e387 + _e388) >> bitcast<u32>(1i));
            let _e392 = (*value);
            let _e393 = mid_1;
            let _e394 = y_5;
            let _e396 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e393, _e394), 0i);
            if (_e392 < _e396.x) {
                let _e399 = mid_1;
                upper = _e399;
            } else {
                let _e400 = mid_1;
                lower = (_e400 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e402 = lower;
    let _e404 = res[0u];
    x_11 = clamp(_e402, 0i, (_e404 - 1i));
    let _e407 = x_11;
    let _e409 = y_5;
    let _e413 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e407), f32(_e409)) / _e413);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e345 = (*woutputW_3)[0u];
    let _e346 = (*woutputW_3);
    let _e347 = _e346.yz;
    let _e351 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e345, _e347.x, _e347.y), 0f);
    env = _e351;
    let _e352 = env;
    let _e355 = unnamed.skyPower;
    let _e358 = unnamed.skyColor;
    return ((_e352.xyz * _e355) * _e358);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_3: f32;
    var param_707: u32;
    var theta_3: f32;
    var param_708: u32;
    var x_12: f32;
    var y_6: f32;
    var z_1: f32;

    let _e351 = (*rndSeed_1);
    param_707 = _e351;
    let _e352 = rand_u0028_u1_u003b((&param_707));
    let _e353 = param_707;
    (*rndSeed_1) = _e353;
    r_3 = sqrt(_e352);
    let _e355 = (*rndSeed_1);
    param_708 = _e355;
    let _e356 = rand_u0028_u1_u003b((&param_708));
    let _e357 = param_708;
    (*rndSeed_1) = _e357;
    theta_3 = (6.2831855f * _e356);
    let _e359 = r_3;
    let _e360 = theta_3;
    x_12 = (_e359 * cos(_e360));
    let _e363 = r_3;
    let _e364 = theta_3;
    y_6 = (_e363 * sin(_e364));
    let _e367 = x_12;
    let _e368 = x_12;
    let _e371 = y_6;
    let _e372 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e367 * _e368)) - (_e371 * _e372))));
    let _e377 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e377) / 3.1415927f));
    let _e381 = x_12;
    let _e382 = y_6;
    let _e383 = z_1;
    return vec3<f32>(_e381, _e382, _e383);
}

fn skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_7: ptr<function, Basis>, woutputL_6: ptr<function, vec3<f32>>, woutputW_4: ptr<function, vec3<f32>>, pdfDir: ptr<function, f32>, rndSeed_2: ptr<function, u32>) -> vec3<f32> {
    var param_709: u32;
    var param_710: f32;
    var param_711: vec3<f32>;
    var param_712: Basis;
    var param_713: vec3<f32>;
    var uv_5: vec2<f32>;
    var param_714: u32;
    var param_715: f32;
    var param_716: vec2<f32>;
    var param_717: vec3<f32>;
    var param_718: vec3<f32>;
    var param_719: Basis;
    var color_8: vec3<f32>;
    var param_720: vec2<f32>;
    var param_721: vec3<f32>;

    let _e363 = unnamed.has_env_cdf;
    if !((_e363 != 0u)) {
        let _e366 = (*rndSeed_2);
        param_709 = _e366;
        let _e367 = (*pdfDir);
        param_710 = _e367;
        let _e368 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_709), (&param_710));
        let _e369 = param_709;
        (*rndSeed_2) = _e369;
        let _e370 = param_710;
        (*pdfDir) = _e370;
        (*woutputL_6) = _e368;
        let _e371 = (*woutputL_6);
        param_711 = _e371;
        let _e372 = (*basis_7);
        param_712 = _e372;
        let _e373 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_711), (&param_712));
        (*woutputW_4) = _e373;
        let _e374 = (*woutputW_4);
        param_713 = _e374;
        let _e375 = skyRadiance_u0028_vf3_u003b((&param_713));
        return _e375;
    }
    let _e376 = (*rndSeed_2);
    param_714 = _e376;
    let _e377 = rand_u0028_u1_u003b((&param_714));
    let _e378 = param_714;
    (*rndSeed_2) = _e378;
    let _e380 = unnamed.envMapTotalSum;
    param_715 = (_e377 * max(_e380, 0.0000000001f));
    let _e383 = envMapBinarySearch_u0028_f1_u003b((&param_715));
    uv_5 = _e383;
    let _e384 = uv_5;
    param_716 = _e384;
    let _e385 = envMapUvToDir_u0028_vf2_u003b((&param_716));
    param_717 = _e385;
    let _e386 = safe_normalize_u0028_vf3_u003b((&param_717));
    (*woutputW_4) = _e386;
    let _e387 = (*woutputW_4);
    param_718 = _e387;
    let _e388 = (*basis_7);
    param_719 = _e388;
    let _e389 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_718), (&param_719));
    (*woutputL_6) = _e389;
    let _e390 = uv_5;
    let _e391 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e390, 0f);
    color_8 = _e391.xyz;
    let _e393 = uv_5;
    param_720 = _e393;
    let _e394 = color_8;
    param_721 = _e394;
    let _e395 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_720), (&param_721));
    (*pdfDir) = _e395;
    let _e397 = unnamed.skyPower;
    let _e399 = unnamed.skyColor;
    let _e401 = color_8;
    return ((_e399 * _e397) * _e401);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_4: f32;

    let _e345 = (*d)[1u];
    theta_4 = acos(clamp(_e345, -1f, 1f));
    let _e349 = (*d)[2u];
    let _e351 = (*d)[0u];
    let _e355 = theta_4;
    return vec2<f32>(((3.1415927f + atan2(_e349, _e351)) * 0.15915494f), (_e355 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_722: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_723: vec3<f32>;
    var param_724: vec3<f32>;
    var color_9: vec3<f32>;
    var param_725: vec2<f32>;
    var param_726: vec3<f32>;

    let _e352 = unnamed.has_env_cdf;
    if !((_e352 != 0u)) {
        let _e355 = (*woutputL_7);
        param_722 = _e355;
        let _e356 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_722));
        return _e356;
    }
    let _e357 = (*woutputW_5);
    param_723 = _e357;
    let _e358 = safe_normalize_u0028_vf3_u003b((&param_723));
    param_724 = _e358;
    let _e359 = envMapDirToUv_u0028_vf3_u003b((&param_724));
    uv_6 = _e359;
    let _e360 = uv_6;
    let _e361 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e360, 0f);
    color_9 = _e361.xyz;
    let _e363 = uv_6;
    param_725 = _e363;
    let _e364 = color_9;
    param_726 = _e364;
    let _e365 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_725), (&param_726));
    return _e365;
}

fn sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b(basis_8: ptr<function, Basis>, woutputL_8: ptr<function, vec3<f32>>, woutputW_6: ptr<function, vec3<f32>>, pdfDir_1: ptr<function, f32>, rndSeed_3: ptr<function, u32>) -> vec3<f32> {
    var theta_max_2: f32;
    var theta_5: f32;
    var param_727: u32;
    var costheta: f32;
    var sintheta: f32;
    var phi_2: f32;
    var param_728: u32;
    var cosphi: f32;
    var sinphi: f32;
    var x_13: f32;
    var y_7: f32;
    var z_2: f32;
    var solid_angle_1: f32;
    var param_729: vec3<f32>;
    var param_730: Basis;
    var param_731: vec3<f32>;
    var param_732: Basis;

    let _e365 = unnamed.sunAngularSize;
    theta_max_2 = ((_e365 * 3.1415927f) / 180f);
    let _e368 = theta_max_2;
    let _e369 = (*rndSeed_3);
    param_727 = _e369;
    let _e370 = rand_u0028_u1_u003b((&param_727));
    let _e371 = param_727;
    (*rndSeed_3) = _e371;
    theta_5 = (_e368 * sqrt(_e370));
    let _e374 = theta_5;
    costheta = cos(_e374);
    let _e376 = costheta;
    let _e377 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e376 * _e377))));
    let _e382 = (*rndSeed_3);
    param_728 = _e382;
    let _e383 = rand_u0028_u1_u003b((&param_728));
    let _e384 = param_728;
    (*rndSeed_3) = _e384;
    phi_2 = (6.2831855f * _e383);
    let _e386 = phi_2;
    cosphi = cos(_e386);
    let _e388 = phi_2;
    sinphi = sin(_e388);
    let _e390 = sintheta;
    let _e391 = cosphi;
    x_13 = (_e390 * _e391);
    let _e393 = sintheta;
    let _e394 = sinphi;
    y_7 = (_e393 * _e394);
    let _e396 = costheta;
    z_2 = _e396;
    let _e397 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e397)));
    let _e401 = solid_angle_1;
    (*pdfDir_1) = (1f / _e401);
    let _e403 = x_13;
    let _e404 = y_7;
    let _e405 = z_2;
    param_729 = vec3<f32>(_e403, _e404, _e405);
    let _e407 = sunBasis;
    param_730 = _e407;
    let _e408 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_729), (&param_730));
    (*woutputW_6) = _e408;
    let _e409 = (*woutputW_6);
    param_731 = _e409;
    let _e410 = (*basis_8);
    param_732 = _e410;
    let _e411 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_731), (&param_732));
    (*woutputL_8) = _e411;
    let _e413 = unnamed.sunPower;
    let _e415 = unnamed.sunColor;
    let _e417 = solid_angle_1;
    return ((_e415 * _e413) / vec3(_e417));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e343 = unnamed.skyPower;
    let _e345 = unnamed.skyColor;
    return (length((_e345 * _e343)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e343 = unnamed.sunPower;
    let _e345 = unnamed.sunColor;
    return length((_e345 * _e343));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_5: i32;
    var param_733: i32;

    power_1 = 0f;
    i_5 = 0i;
    loop {
        let _e345 = i_5;
        if (_e345 < 1i) {
            let _e347 = i_5;
            let _e349 = unnamed.mtlxLightCount;
            if (_e347 >= _e349) {
                break;
            }
            let _e351 = i_5;
            param_733 = _e351;
            let _e352 = mtlxLightTotalPower_u0028_i1_u003b((&param_733));
            let _e353 = power_1;
            power_1 = (_e353 + _e352);
            continue;
        } else {
            break;
        }
        continuing {
            let _e355 = i_5;
            i_5 = (_e355 + 1i);
        }
    }
    let _e357 = power_1;
    return _e357;
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
    var param_734: u32;
    var maxDistance_5: f32;
    var Li_7: vec3<f32>;
    var pdf_sun: f32;
    var param_735: Basis;
    var param_736: vec3<f32>;
    var param_737: vec3<f32>;
    var param_738: f32;
    var param_739: u32;
    var param_740: vec3<f32>;
    var pdf_sky: f32;
    var param_741: vec3<f32>;
    var param_742: vec3<f32>;
    var param_743: Basis;
    var param_744: vec3<f32>;
    var param_745: vec3<f32>;
    var param_746: f32;
    var param_747: u32;
    var param_748: vec3<f32>;
    var param_749: vec3<f32>;
    var param_750: vec3<f32>;
    var target_: f32;
    var param_751: u32;
    var accum: f32;
    var selected: i32;
    var i_6: i32;
    var param_752: i32;
    var selectedPower: f32;
    var param_753: i32;
    var param_754: i32;
    var param_755: vec3<f32>;
    var param_756: Basis;
    var param_757: vec3<f32>;
    var param_758: vec3<f32>;
    var param_759: f32;
    var param_760: u32;
    var param_761: vec3<f32>;
    var param_762: vec3<f32>;
    var param_763: vec3<f32>;
    var param_764: vec3<f32>;
    var param_765: vec3<f32>;
    var shadowOrigin: vec3<f32>;
    var visibility: f32;
    var param_766: vec3<f32>;
    var param_767: vec3<f32>;
    var param_768: f32;
    var param_769: vec3<f32>;
    var shadowOrigin_1: vec3<f32>;
    var visibility_1: f32;
    var param_770: vec3<f32>;
    var param_771: vec3<f32>;
    var param_772: f32;
    var phi_9048_: bool;

    let _e409 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e409;
    let _e411 = unnamed.mtlxDisableSun;
    let _e412 = (_e411 != 0u);
    phi_9048_ = _e412;
    if !(_e412) {
        let _e415 = unnamed.mtlxLightCount;
        phi_9048_ = (_e415 > 0i);
    }
    let _e418 = phi_9048_;
    if _e418 {
        local_14 = 0f;
    } else {
        let _e419 = sunTotalPower_u0028_();
        local_14 = _e419;
    }
    let _e420 = local_14;
    w_sun = _e420;
    let _e421 = skyTotalPower_u0028_();
    w_sky = _e421;
    let _e422 = w_sun;
    let _e423 = w_sky;
    let _e425 = w_mtlx;
    w_total = max(0.0000000001f, ((_e422 + _e423) + _e425));
    let _e428 = w_sun;
    let _e429 = w_total;
    P_sun = (_e428 / _e429);
    let _e431 = w_sky;
    let _e432 = w_total;
    P_sky = (_e431 / _e432);
    let _e434 = w_mtlx;
    let _e435 = w_total;
    P_mtlx = (_e434 / _e435);
    let _e437 = (*rndSeed_4);
    param_734 = _e437;
    let _e438 = rand_u0028_u1_u003b((&param_734));
    let _e439 = param_734;
    (*rndSeed_4) = _e439;
    r_4 = _e438;
    maxDistance_5 = 100000000000000000000f;
    let _e440 = r_4;
    let _e441 = P_sun;
    if (_e440 < _e441) {
        let _e443 = (*basis_9);
        param_735 = _e443;
        let _e444 = (*shadowL);
        param_736 = _e444;
        let _e445 = (*shadowW);
        param_737 = _e445;
        let _e446 = pdf_sun;
        param_738 = _e446;
        let _e447 = (*rndSeed_4);
        param_739 = _e447;
        let _e448 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_735), (&param_736), (&param_737), (&param_738), (&param_739));
        let _e449 = param_736;
        (*shadowL) = _e449;
        let _e450 = param_737;
        (*shadowW) = _e450;
        let _e451 = param_738;
        pdf_sun = _e451;
        let _e452 = param_739;
        (*rndSeed_4) = _e452;
        Li_7 = _e448;
        let _e453 = (*shadowW);
        param_740 = _e453;
        let _e454 = skyRadiance_u0028_vf3_u003b((&param_740));
        let _e455 = Li_7;
        Li_7 = (_e455 + _e454);
        let _e457 = (*shadowL);
        param_741 = _e457;
        let _e458 = (*shadowW);
        param_742 = _e458;
        let _e459 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_741), (&param_742));
        pdf_sky = _e459;
    } else {
        let _e460 = r_4;
        let _e461 = P_sun;
        let _e462 = P_sky;
        if (_e460 < (_e461 + _e462)) {
            let _e465 = (*basis_9);
            param_743 = _e465;
            let _e466 = (*rndSeed_4);
            param_747 = _e466;
            let _e467 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_743), (&param_744), (&param_745), (&param_746), (&param_747));
            let _e468 = param_744;
            (*shadowL) = _e468;
            let _e469 = param_745;
            (*shadowW) = _e469;
            let _e470 = param_746;
            pdf_sky = _e470;
            let _e471 = param_747;
            (*rndSeed_4) = _e471;
            Li_7 = _e467;
            let _e472 = w_sun;
            if (_e472 > 0f) {
                let _e474 = (*shadowW);
                param_748 = _e474;
                let _e475 = sunRadiance_u0028_vf3_u003b((&param_748));
                let _e476 = Li_7;
                Li_7 = (_e476 + _e475);
            }
            let _e478 = (*shadowL);
            param_749 = _e478;
            let _e479 = (*shadowW);
            param_750 = _e479;
            let _e480 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_749), (&param_750));
            pdf_sun = _e480;
        } else {
            let _e481 = (*rndSeed_4);
            param_751 = _e481;
            let _e482 = rand_u0028_u1_u003b((&param_751));
            let _e483 = param_751;
            (*rndSeed_4) = _e483;
            let _e484 = w_mtlx;
            target_ = (_e482 * max(_e484, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_6 = 0i;
            loop {
                let _e487 = i_6;
                if (_e487 < 1i) {
                    let _e489 = i_6;
                    let _e491 = unnamed.mtlxLightCount;
                    if (_e489 >= _e491) {
                        break;
                    }
                    let _e493 = i_6;
                    param_752 = _e493;
                    let _e494 = mtlxLightTotalPower_u0028_i1_u003b((&param_752));
                    let _e495 = accum;
                    accum = (_e495 + _e494);
                    let _e497 = target_;
                    let _e498 = accum;
                    if (_e497 <= _e498) {
                        let _e500 = i_6;
                        selected = _e500;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e501 = i_6;
                    i_6 = (_e501 + 1i);
                }
            }
            let _e503 = selected;
            param_753 = _e503;
            let _e504 = mtlxLightTotalPower_u0028_i1_u003b((&param_753));
            selectedPower = max(_e504, 0.0000000001f);
            let _e506 = selected;
            param_754 = _e506;
            let _e507 = (*pW_7);
            param_755 = _e507;
            let _e508 = (*basis_9);
            param_756 = _e508;
            let _e509 = (*rndSeed_4);
            param_760 = _e509;
            let _e510 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760));
            let _e511 = param_757;
            (*shadowL) = _e511;
            let _e512 = param_758;
            (*shadowW) = _e512;
            let _e513 = param_759;
            maxDistance_5 = _e513;
            let _e514 = param_760;
            (*rndSeed_4) = _e514;
            Li_7 = _e510;
            let _e515 = (*shadowL);
            param_761 = _e515;
            let _e516 = (*shadowW);
            param_762 = _e516;
            let _e517 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_761), (&param_762));
            pdf_sun = _e517;
            let _e518 = (*shadowL);
            param_763 = _e518;
            let _e519 = (*shadowW);
            param_764 = _e519;
            let _e520 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_763), (&param_764));
            pdf_sky = _e520;
            let _e521 = P_mtlx;
            let _e522 = selectedPower;
            let _e524 = w_mtlx;
            (*lightPdf) = ((_e521 * _e522) / max(_e524, 0.0000000001f));
            let _e528 = (*shadowL)[2u];
            if (_e528 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e530 = Li_7;
            param_765 = _e530;
            let _e531 = maxComponent_u0028_vf3_u003b((&param_765));
            if (_e531 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e533 = (*pW_7);
            let _e535 = (*basis_9).nW;
            let _e536 = (*shadowW);
            let _e538 = (*basis_9).nW;
            shadowOrigin = (_e533 + ((_e535 * sign(dot(_e536, _e538))) * 0.0001f));
            let _e544 = shadowOrigin;
            param_766 = _e544;
            let _e545 = (*shadowW);
            param_767 = _e545;
            let _e546 = maxDistance_5;
            param_768 = _e546;
            let _e547 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_766), (&param_767), (&param_768));
            visibility = _e547;
            let _e548 = visibility;
            let _e549 = Li_7;
            return (_e549 * _e548);
        }
    }
    let _e551 = P_sun;
    let _e552 = pdf_sun;
    let _e554 = P_sky;
    let _e555 = pdf_sky;
    (*lightPdf) = ((_e551 * _e552) + (_e554 * _e555));
    let _e559 = (*shadowL)[2u];
    if (_e559 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e561 = Li_7;
    param_769 = _e561;
    let _e562 = maxComponent_u0028_vf3_u003b((&param_769));
    if (_e562 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e564 = (*pW_7);
    let _e566 = (*basis_9).nW;
    let _e567 = (*shadowW);
    let _e569 = (*basis_9).nW;
    shadowOrigin_1 = (_e564 + ((_e566 * sign(dot(_e567, _e569))) * 0.0001f));
    let _e575 = shadowOrigin_1;
    param_770 = _e575;
    let _e576 = (*shadowW);
    param_771 = _e576;
    param_772 = 100000000000000000000f;
    let _e577 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_770), (&param_771), (&param_772));
    visibility_1 = _e577;
    let _e578 = visibility_1;
    let _e579 = Li_7;
    return (_e579 * _e578);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_773: vec3<f32>;
    var param_774: Basis;

    let _e348 = (*pW_8);
    g_ptP = _e348;
    let _e350 = (*basis_10).nW;
    g_ptN = _e350;
    let _e352 = (*basis_10).tW;
    g_ptTangent = _e352;
    let _e354 = (*basis_10).bW;
    g_ptBitangent = _e354;
    let _e356 = (*basis_10).texCoord;
    g_ptTexcoord = _e356;
    let _e357 = (*winputL_4);
    param_773 = _e357;
    let _e358 = (*basis_10);
    param_774 = _e358;
    let _e359 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_773), (&param_774));
    g_ptV = _e359;
    let _e361 = (*basis_10).nW;
    g_ptL = _e361;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e362 = geometry_opacity_1;
    g_ptOpacity = clamp(_e362, 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e364 = mtlxHostEvalSurface_u0028_();
    let _e365 = (*rndSeed_5);
    (*rndSeed_5) = (_e365 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_775: vec3<f32>;
    var param_776: Basis;
    var param_777: vec3<f32>;
    var param_778: u32;

    emissionSeed = 0u;
    let _e349 = (*pW_9);
    param_775 = _e349;
    let _e350 = (*basis_11);
    param_776 = _e350;
    param_777 = vec3<f32>(0f, 0f, 1f);
    let _e351 = emissionSeed;
    param_778 = _e351;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_775), (&param_776), (&param_777), (&param_778));
    let _e352 = param_778;
    emissionSeed = _e352;
    let _e353 = g_ptEmission;
    return max(_e353, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_779: vec3<f32>;
    var param_780: Basis;

    let _e347 = (*pW_10);
    param_779 = _e347;
    let _e348 = (*basis_12);
    param_780 = _e348;
    let _e349 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_779), (&param_780));
    return _e349;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_781: u32;
    var param_782: f32;
    var param_783: vec3<f32>;
    var phi_8069_: bool;

    let _e352 = (*winputL_6)[2u];
    if (_e352 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e354 = (*rndSeed_6);
    param_781 = _e354;
    let _e355 = (*pdf_woutputL_4);
    param_782 = _e355;
    let _e356 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_781), (&param_782));
    let _e357 = param_781;
    (*rndSeed_6) = _e357;
    let _e358 = param_782;
    (*pdf_woutputL_4) = _e358;
    (*woutputL_9) = _e356;
    let _e360 = unnamed.wireframe;
    let _e361 = (_e360 != 0u);
    phi_8069_ = _e361;
    if _e361 {
        let _e363 = (*basis_13).baryCoord;
        param_783 = _e363;
        let _e364 = minComponent_u0028_vf3_u003b((&param_783));
        phi_8069_ = (_e364 < 0.003f);
    }
    let _e367 = phi_8069_;
    if _e367 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e369 = unnamed.neutral_color;
    return (_e369 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_784: u32;
    var param_785: f32;
    var param_786: vec3<f32>;

    let _e352 = (*winputL_7)[2u];
    if (_e352 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e354 = (*rndSeed_7);
    param_784 = _e354;
    let _e355 = (*pdf_woutputL_5);
    param_785 = _e355;
    let _e356 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_784), (&param_785));
    let _e357 = param_784;
    (*rndSeed_7) = _e357;
    let _e358 = param_785;
    (*pdf_woutputL_5) = _e358;
    (*woutputL_10) = _e356;
    let _e359 = (*pW_12);
    param_786 = _e359;
    let _e360 = ground_albedo_u0028_vf3_u003b((&param_786));
    return (_e360 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e346 = (*w_1)[2u];
    if (abs(_e346) < 0.00000011920929f) {
        return 0f;
    }
    let _e349 = (*alpha_x);
    let _e351 = (*w_1)[0u];
    let _e353 = (*alpha_x);
    let _e355 = (*w_1)[0u];
    let _e358 = (*alpha_y);
    let _e360 = (*w_1)[1u];
    let _e362 = (*alpha_y);
    let _e364 = (*w_1)[1u];
    let _e369 = (*w_1)[2u];
    let _e371 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e349 * _e351) * (_e353 * _e355)) + ((_e358 * _e360) * (_e362 * _e364))) / (_e369 * _e371))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_787: vec3<f32>;
    var param_788: f32;
    var param_789: f32;
    var param_790: vec3<f32>;
    var param_791: f32;
    var param_792: f32;

    let _e352 = (*woL);
    param_787 = _e352;
    let _e353 = (*alpha_x_1);
    param_788 = _e353;
    let _e354 = (*alpha_y_1);
    param_789 = _e354;
    let _e355 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_787), (&param_788), (&param_789));
    let _e357 = (*wiL_1);
    param_790 = _e357;
    let _e358 = (*alpha_x_1);
    param_791 = _e358;
    let _e359 = (*alpha_y_1);
    param_792 = _e359;
    let _e360 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_790), (&param_791), (&param_792));
    return (1f / ((1f + _e355) + _e360));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e348 = (*alpha_x_2);
    ax = max(_e348, 0.0000000001f);
    let _e350 = (*alpha_y_2);
    ay = max(_e350, 0.0000000001f);
    let _e352 = ax;
    let _e354 = ay;
    let _e357 = (*m_5)[0u];
    let _e358 = ax;
    let _e361 = (*m_5)[0u];
    let _e362 = ax;
    let _e366 = (*m_5)[1u];
    let _e367 = ay;
    let _e370 = (*m_5)[1u];
    let _e371 = ay;
    let _e376 = (*m_5)[2u];
    let _e378 = (*m_5)[2u];
    let _e382 = (*m_5)[0u];
    let _e383 = ax;
    let _e386 = (*m_5)[0u];
    let _e387 = ax;
    let _e391 = (*m_5)[1u];
    let _e392 = ay;
    let _e395 = (*m_5)[1u];
    let _e396 = ay;
    let _e401 = (*m_5)[2u];
    let _e403 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e352) * _e354) * (((((_e357 / _e358) * (_e361 / _e362)) + ((_e366 / _e367) * (_e370 / _e371))) + (_e376 * _e378)) * ((((_e382 / _e383) * (_e386 / _e387)) + ((_e391 / _e392) * (_e395 / _e396))) + (_e401 * _e403))));
    let _e408 = Ddenom;
    return (1f / max(_e408, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_793: vec3<f32>;
    var param_794: f32;
    var param_795: f32;

    let _e348 = (*w_2);
    param_793 = _e348;
    let _e349 = (*alpha_x_3);
    param_794 = _e349;
    let _e350 = (*alpha_y_3);
    param_795 = _e350;
    let _e351 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_793), (&param_794), (&param_795));
    return (1f / (1f + _e351));
}

fn ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b(wiL_2: ptr<function, vec3<f32>>, alpha_x_4: ptr<function, f32>, alpha_y_4: ptr<function, f32>, rndSeed_8: ptr<function, u32>) -> vec3<f32> {
    var Xi_2: vec2<f32>;
    var param_796: u32;
    var param_797: u32;
    var V_15: vec3<f32>;
    var alpha_12: vec2<f32>;
    var phi_3: f32;
    var z_3: f32;
    var sinTheta_1: f32;
    var x_14: f32;
    var y_8: f32;
    var c_4: vec3<f32>;
    var H_7: vec3<f32>;

    let _e358 = (*rndSeed_8);
    param_796 = _e358;
    let _e359 = rand_u0028_u1_u003b((&param_796));
    let _e360 = param_796;
    (*rndSeed_8) = _e360;
    let _e361 = (*rndSeed_8);
    param_797 = _e361;
    let _e362 = rand_u0028_u1_u003b((&param_797));
    let _e363 = param_797;
    (*rndSeed_8) = _e363;
    Xi_2 = vec2<f32>(_e359, _e362);
    let _e365 = (*wiL_2);
    V_15 = _e365;
    let _e366 = (*alpha_x_4);
    let _e367 = (*alpha_y_4);
    alpha_12 = vec2<f32>(_e366, _e367);
    let _e369 = V_15;
    let _e371 = alpha_12;
    let _e372 = (_e369.xy * _e371);
    let _e374 = V_15[2u];
    V_15 = normalize(vec3<f32>(_e372.x, _e372.y, _e374));
    let _e380 = Xi_2[0u];
    phi_3 = (6.2831855f * _e380);
    let _e383 = Xi_2[1u];
    let _e386 = V_15[2u];
    let _e390 = V_15[2u];
    z_3 = (((1f - _e383) * (1f + _e386)) - _e390);
    let _e392 = z_3;
    let _e393 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e392 * _e393)), 0f, 1f));
    let _e398 = sinTheta_1;
    let _e399 = phi_3;
    x_14 = (_e398 * cos(_e399));
    let _e402 = sinTheta_1;
    let _e403 = phi_3;
    y_8 = (_e402 * sin(_e403));
    let _e406 = x_14;
    let _e407 = y_8;
    let _e408 = z_3;
    c_4 = vec3<f32>(_e406, _e407, _e408);
    let _e410 = c_4;
    let _e411 = V_15;
    H_7 = (_e410 + _e411);
    let _e413 = H_7;
    let _e415 = alpha_12;
    let _e416 = (_e413.xy * _e415);
    let _e418 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e416.x, _e416.y, _e418));
    let _e423 = H_7;
    return _e423;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_5: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e347 = (*mui);
    c_5 = _e347;
    let _e348 = (*eta_ti);
    let _e349 = (*eta_ti);
    let _e351 = c_5;
    let _e352 = c_5;
    mut2_ = (((_e348 * _e349) + (_e351 * _e352)) - 1f);
    let _e356 = mut2_;
    if (_e356 <= 0f) {
        return 1f;
    }
    let _e358 = mut2_;
    g_1 = sqrt(_e358);
    let _e360 = g_1;
    let _e361 = c_5;
    let _e363 = g_1;
    let _e364 = c_5;
    let _e367 = g_1;
    let _e368 = c_5;
    let _e370 = g_1;
    let _e371 = c_5;
    let _e376 = g_1;
    let _e377 = c_5;
    let _e379 = c_5;
    let _e382 = g_1;
    let _e383 = c_5;
    let _e385 = c_5;
    let _e389 = g_1;
    let _e390 = c_5;
    let _e392 = c_5;
    let _e395 = g_1;
    let _e396 = c_5;
    let _e398 = c_5;
    return ((0.5f * (((_e360 - _e361) / (_e363 + _e364)) * ((_e367 - _e368) / (_e370 + _e371)))) * (1f + (((((_e376 + _e377) * _e379) - 1f) / (((_e382 - _e383) * _e385) + 1f)) * ((((_e389 + _e390) * _e392) - 1f) / (((_e395 - _e396) * _e398) + 1f)))));
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
    var F0_9: vec3<f32>;
    var F0lum: f32;
    var Fv: f32;
    var coatFv: f32;
    var param_798: f32;
    var param_799: f32;
    var pCoat: f32;
    var xiLobe: f32;
    var param_800: u32;
    var pTrans: f32;
    var m_transW: f32;
    var m_transC: vec3<f32>;
    var m_transD: f32;
    var Hc: vec3<f32>;
    var param_801: vec3<f32>;
    var param_802: f32;
    var param_803: f32;
    var param_804: u32;
    var pdfCoat: f32;
    var param_805: vec3<f32>;
    var param_806: f32;
    var param_807: f32;
    var param_808: vec3<f32>;
    var param_809: f32;
    var param_810: f32;
    var pdfBaseSpec: f32;
    var param_811: vec3<f32>;
    var param_812: f32;
    var param_813: f32;
    var param_814: vec3<f32>;
    var param_815: f32;
    var param_816: f32;
    var pdfBaseDiff: f32;
    var param_817: vec3<f32>;
    var diffLumCoat: f32;
    var pSpecCoat: f32;
    var ignorePdfCoat: f32;
    var param_818: vec3<f32>;
    var param_819: Basis;
    var param_820: vec3<f32>;
    var param_821: vec3<f32>;
    var param_822: f32;
    var externalTransmission: bool;
    var etaRatio: f32;
    var local_15: f32;
    var Hdelta: vec3<f32>;
    var HdotWiDelta: f32;
    var discrDelta: f32;
    var beamIncidentDelta: vec3<f32>;
    var Tdelta: f32;
    var param_823: f32;
    var param_824: f32;
    var tintDelta: vec3<f32>;
    var Vsample: vec3<f32>;
    var Ht_2: vec3<f32>;
    var param_825: vec3<f32>;
    var param_826: f32;
    var param_827: f32;
    var param_828: u32;
    var HdotWi: f32;
    var discr: f32;
    var beamIncident: vec3<f32>;
    var Hr: vec3<f32>;
    var VoH: f32;
    var LoH: f32;
    var denomT: f32;
    var jacT: f32;
    var DvT: f32;
    var param_829: vec3<f32>;
    var param_830: f32;
    var param_831: f32;
    var local_16: vec3<f32>;
    var param_832: vec3<f32>;
    var param_833: f32;
    var param_834: f32;
    var D_3: f32;
    var local_17: vec3<f32>;
    var param_835: vec3<f32>;
    var param_836: f32;
    var param_837: f32;
    var G2_: f32;
    var param_838: vec3<f32>;
    var param_839: vec3<f32>;
    var param_840: f32;
    var param_841: f32;
    var etaRefl: f32;
    var T_1: f32;
    var param_842: f32;
    var param_843: f32;
    var tint_3: vec3<f32>;
    var diffLum: f32;
    var pSpec: f32;
    var param_844: u32;
    var H_8: vec3<f32>;
    var param_845: vec3<f32>;
    var param_846: f32;
    var param_847: f32;
    var param_848: u32;
    var pdfTmp: f32;
    var param_849: u32;
    var param_850: f32;
    var Hh: vec3<f32>;
    var pdfSpec: f32;
    var param_851: vec3<f32>;
    var param_852: f32;
    var param_853: f32;
    var param_854: vec3<f32>;
    var param_855: f32;
    var param_856: f32;
    var pdfDiff: f32;
    var param_857: vec3<f32>;
    var pdfCoat_1: f32;
    var param_858: vec3<f32>;
    var param_859: f32;
    var param_860: f32;
    var param_861: vec3<f32>;
    var param_862: f32;
    var param_863: f32;
    var ignorePdf: f32;
    var param_864: vec3<f32>;
    var param_865: Basis;
    var param_866: vec3<f32>;
    var param_867: vec3<f32>;
    var param_868: f32;
    var phi_7263_: bool;
    var phi_7403_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e496 = base_metalness_1;
    m_metal = clamp(_e496, 0f, 1f);
    let _e498 = specular_roughness_1;
    m_rough = clamp(_e498, 0f, 1f);
    let _e500 = specular_roughness_anisotropy_1;
    m_aniso = clamp(_e500, 0f, 0.99f);
    let _e502 = base_color_1;
    let _e503 = base_weight_1;
    m_base = (_e502 * _e503);
    let _e505 = specular_color_1;
    m_specC = _e505;
    let _e506 = specular_weight_1;
    m_specW = _e506;
    let _e507 = specular_ior_1;
    m_ior = max(_e507, 1.001f);
    let _e509 = coat_weight_1;
    m_coatW = clamp(_e509, 0f, 1f);
    let _e511 = coat_roughness_1;
    m_coatRough = clamp(_e511, 0f, 1f);
    let _e513 = coat_roughness_anisotropy_1;
    m_coatAniso = clamp(_e513, 0f, 0.99f);
    let _e515 = coat_ior_1;
    m_coatIor = max(_e515, 1.001f);
    let _e517 = (*winputL_8);
    V_16 = _e517;
    let _e519 = V_16[2u];
    if (_e519 < 0f) {
        let _e521 = V_16;
        V_16 = -(_e521);
    }
    let _e524 = V_16[2u];
    NdotV_21 = max(_e524, 0.0001f);
    let _e526 = m_rough;
    let _e527 = m_rough;
    alpha_13 = clamp((_e526 * _e527), 0.0001f, 1f);
    let _e530 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e530));
    let _e533 = alpha_13;
    let _e534 = anisoAspect;
    let _e535 = anisoAspect;
    let _e541 = alpha_13;
    let _e542 = anisoAspect;
    let _e544 = anisoAspect;
    let _e545 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e533 * sqrt((2f / ((_e534 * _e535) + 1f)))), ((_e541 * _e542) * sqrt((2f / ((_e544 * _e545) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e553 = m_coatRough;
    let _e554 = m_coatRough;
    coatAlpha = clamp((_e553 * _e554), 0.0001f, 1f);
    let _e557 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e557));
    let _e560 = coatAlpha;
    let _e561 = coatAnisoAspect;
    let _e562 = coatAnisoAspect;
    let _e568 = coatAlpha;
    let _e569 = coatAnisoAspect;
    let _e571 = coatAnisoAspect;
    let _e572 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e560 * sqrt((2f / ((_e561 * _e562) + 1f)))), ((_e568 * _e569) * sqrt((2f / ((_e571 * _e572) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e580 = m_ior;
    let _e582 = m_ior;
    F0d = pow(((_e580 - 1f) / (_e582 + 1f)), 2f);
    let _e586 = F0d;
    let _e588 = m_specC;
    let _e591 = m_specW;
    let _e593 = m_base;
    let _e594 = m_metal;
    F0_9 = mix(((vec3(_e586) * max(_e588, vec3<f32>(0f, 0f, 0f))) * _e591), _e593, vec3(_e594));
    let _e598 = F0_9[0u];
    let _e600 = F0_9[1u];
    let _e602 = F0_9[2u];
    F0lum = max(_e598, max(_e600, _e602));
    let _e605 = F0lum;
    let _e606 = F0lum;
    let _e608 = NdotV_21;
    Fv = (_e605 + ((1f - _e606) * pow((1f - _e608), 5f)));
    let _e613 = NdotV_21;
    param_798 = _e613;
    let _e614 = m_coatIor;
    param_799 = _e614;
    let _e615 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_798), (&param_799));
    coatFv = _e615;
    let _e616 = m_coatW;
    let _e617 = coatFv;
    pCoat = clamp((_e616 * _e617), 0f, 0.75f);
    let _e620 = (*rndSeed_9);
    param_800 = _e620;
    let _e621 = rand_u0028_u1_u003b((&param_800));
    let _e622 = param_800;
    (*rndSeed_9) = _e622;
    xiLobe = _e621;
    pTrans = 0f;
    let _e623 = transmission_weight_1;
    m_transW = clamp(_e623, 0f, 1f);
    let _e625 = transmission_color_1;
    m_transC = _e625;
    let _e626 = transmission_depth_1;
    m_transD = _e626;
    let _e627 = m_transW;
    let _e628 = Fv;
    pTrans = clamp((_e627 * (1f - _e628)), 0f, 0.95f);
    let _e632 = xiLobe;
    let _e633 = pCoat;
    if (_e632 < _e633) {
        let _e635 = V_16;
        param_801 = _e635;
        let _e637 = coatSampleAlpha[0u];
        param_802 = _e637;
        let _e639 = coatSampleAlpha[1u];
        param_803 = _e639;
        let _e640 = (*rndSeed_9);
        param_804 = _e640;
        let _e641 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_801), (&param_802), (&param_803), (&param_804));
        let _e642 = param_804;
        (*rndSeed_9) = _e642;
        Hc = _e641;
        let _e643 = V_16;
        let _e645 = Hc;
        (*woutputL_11) = reflect(-(_e643), _e645);
        let _e648 = (*woutputL_11)[2u];
        if (_e648 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e650 = V_16;
        param_805 = _e650;
        let _e652 = coatSampleAlpha[0u];
        param_806 = _e652;
        let _e654 = coatSampleAlpha[1u];
        param_807 = _e654;
        let _e655 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_805), (&param_806), (&param_807));
        let _e656 = V_16;
        let _e657 = (*woutputL_11);
        param_808 = normalize((_e656 + _e657));
        let _e661 = coatSampleAlpha[0u];
        param_809 = _e661;
        let _e663 = coatSampleAlpha[1u];
        param_810 = _e663;
        let _e664 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_808), (&param_809), (&param_810));
        let _e666 = NdotV_21;
        pdfCoat = ((_e655 * _e664) / (4f * _e666));
        let _e669 = V_16;
        param_811 = _e669;
        let _e671 = sampleAlpha[0u];
        param_812 = _e671;
        let _e673 = sampleAlpha[1u];
        param_813 = _e673;
        let _e674 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_811), (&param_812), (&param_813));
        let _e675 = V_16;
        let _e676 = (*woutputL_11);
        param_814 = normalize((_e675 + _e676));
        let _e680 = sampleAlpha[0u];
        param_815 = _e680;
        let _e682 = sampleAlpha[1u];
        param_816 = _e682;
        let _e683 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_814), (&param_815), (&param_816));
        let _e685 = NdotV_21;
        pdfBaseSpec = ((_e674 * _e683) / (4f * _e685));
        let _e688 = (*woutputL_11);
        param_817 = _e688;
        let _e689 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_817));
        pdfBaseDiff = _e689;
        let _e690 = m_metal;
        let _e692 = m_base;
        diffLumCoat = ((1f - _e690) * dot(_e692, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e695 = Fv;
        let _e696 = Fv;
        let _e697 = Fv;
        let _e699 = diffLumCoat;
        pSpecCoat = clamp((_e695 / ((_e696 + ((1f - _e697) * _e699)) + 0.001f)), 0.05f, 0.95f);
        let _e705 = pCoat;
        let _e706 = pdfCoat;
        let _e708 = pCoat;
        let _e710 = pTrans;
        let _e713 = pSpecCoat;
        let _e714 = pdfBaseSpec;
        let _e716 = pSpecCoat;
        let _e718 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e705 * _e706) + (((1f - _e708) * (1f - _e710)) * ((_e713 * _e714) + ((1f - _e716) * _e718)))), 0.000001f);
        let _e724 = (*pW_13);
        param_818 = _e724;
        let _e725 = (*basis_15);
        param_819 = _e725;
        let _e726 = (*winputL_8);
        param_820 = _e726;
        let _e727 = (*woutputL_11);
        param_821 = _e727;
        let _e728 = ignorePdfCoat;
        param_822 = _e728;
        let _e729 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_818), (&param_819), (&param_820), (&param_821), (&param_822));
        let _e730 = param_822;
        ignorePdfCoat = _e730;
        return _e729;
    }
    let _e731 = xiLobe;
    let _e732 = pCoat;
    let _e733 = pCoat;
    let _e735 = pTrans;
    if (_e731 < (_e732 + ((1f - _e733) * _e735))) {
        let _e740 = (*winputL_8)[2u];
        externalTransmission = (_e740 > 0f);
        let _e742 = externalTransmission;
        if _e742 {
            let _e743 = m_ior;
            local_15 = (1f / _e743);
        } else {
            let _e745 = m_ior;
            local_15 = _e745;
        }
        let _e746 = local_15;
        etaRatio = _e746;
        let _e747 = alpha_13;
        if (_e747 <= 0.001f) {
            let _e749 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e749));
            let _e752 = Hdelta;
            let _e753 = (*winputL_8);
            HdotWiDelta = dot(_e752, _e753);
            let _e755 = etaRatio;
            let _e756 = etaRatio;
            let _e758 = HdotWiDelta;
            let _e759 = HdotWiDelta;
            discrDelta = (1f - ((_e755 * _e756) * (1f - (_e758 * _e759))));
            let _e764 = discrDelta;
            if (_e764 < 0f) {
                let _e766 = (*winputL_8);
                let _e768 = (*winputL_8);
                let _e769 = Hdelta;
                let _e772 = Hdelta;
                (*woutputL_11) = (-(_e766) + (_e772 * (2f * dot(_e768, _e769))));
                let _e775 = pCoat;
                let _e777 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e775) * _e777), 0.000001f);
                let _e780 = m_transW;
                let _e781 = (*pdf_woutputL_6);
                let _e784 = (*woutputL_11)[2u];
                return vec3(((_e780 * _e781) / max(abs(_e784), 0.0000000001f)));
            }
            let _e789 = etaRatio;
            let _e790 = (*winputL_8);
            let _e792 = Hdelta;
            let _e793 = HdotWiDelta;
            let _e796 = etaRatio;
            let _e797 = HdotWiDelta;
            let _e800 = discrDelta;
            beamIncidentDelta = ((_e790 * _e789) - ((_e792 * sign(_e793)) * ((_e796 * abs(_e797)) - sqrt(_e800))));
            let _e805 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e805));
            let _e809 = (*winputL_8)[2u];
            let _e811 = (*woutputL_11)[2u];
            if ((_e809 * _e811) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e814 = m_transD;
            let _e815 = (_e814 > 0f);
            phi_7263_ = _e815;
            if _e815 {
                let _e816 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_7263_ = !(_e816);
            }
            let _e819 = phi_7263_;
            if _e819 {
                let _e820 = m_transC;
                let _e824 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e820))) / vec3(_e824));
                let _e828 = transmission_scatter_1;
                (*internal_medium).albedo = clamp(_e828, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e831 = transmission_scatter_anisotropy_1;
                (*internal_medium).anisotropy = clamp(_e831, -0.99f, 0.99f);
            }
            let _e834 = HdotWiDelta;
            let _e836 = etaRatio;
            param_823 = abs(_e834);
            param_824 = (1f / _e836);
            let _e838 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_823), (&param_824));
            Tdelta = clamp((1f - _e838), 0f, 1f);
            let _e841 = m_transD;
            let _e843 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e843, (_e841 == 0f));
            let _e845 = pCoat;
            let _e847 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e845) * _e847), 0.000001f);
            let _e850 = m_transW;
            let _e851 = tintDelta;
            let _e853 = Tdelta;
            let _e855 = (*pdf_woutputL_6);
            let _e858 = (*woutputL_11)[2u];
            return ((((_e851 * _e850) * _e853) * _e855) / vec3(max(abs(_e858), 0.0000000001f)));
        }
        let _e863 = (*winputL_8);
        Vsample = _e863;
        let _e865 = Vsample[2u];
        if (_e865 < 0f) {
            let _e868 = Vsample[2u];
            Vsample[2u] = (_e868 * -1f);
        }
        let _e871 = Vsample;
        param_825 = _e871;
        let _e873 = sampleAlpha[0u];
        param_826 = _e873;
        let _e875 = sampleAlpha[1u];
        param_827 = _e875;
        let _e876 = (*rndSeed_9);
        param_828 = _e876;
        let _e877 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_825), (&param_826), (&param_827), (&param_828));
        let _e878 = param_828;
        (*rndSeed_9) = _e878;
        Ht_2 = _e877;
        let _e880 = (*winputL_8)[2u];
        if (_e880 < 0f) {
            let _e883 = Ht_2[2u];
            Ht_2[2u] = (_e883 * -1f);
        }
        let _e886 = Ht_2;
        let _e887 = (*winputL_8);
        HdotWi = dot(_e886, _e887);
        let _e889 = etaRatio;
        let _e890 = etaRatio;
        let _e892 = HdotWi;
        let _e893 = HdotWi;
        discr = (1f - ((_e889 * _e890) * (1f - (_e892 * _e893))));
        let _e898 = discr;
        if (_e898 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e900 = etaRatio;
        let _e901 = (*winputL_8);
        let _e903 = Ht_2;
        let _e904 = HdotWi;
        let _e907 = etaRatio;
        let _e908 = HdotWi;
        let _e911 = discr;
        beamIncident = ((_e901 * _e900) - ((_e903 * sign(_e904)) * ((_e907 * abs(_e908)) - sqrt(_e911))));
        let _e916 = beamIncident;
        (*woutputL_11) = -(normalize(_e916));
        let _e920 = (*winputL_8)[2u];
        let _e922 = (*woutputL_11)[2u];
        if ((_e920 * _e922) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e925 = m_transD;
        let _e926 = (_e925 > 0f);
        phi_7403_ = _e926;
        if _e926 {
            let _e927 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_7403_ = !(_e927);
        }
        let _e930 = phi_7403_;
        if _e930 {
            let _e931 = m_transC;
            let _e935 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e931))) / vec3(_e935));
            let _e939 = transmission_scatter_1;
            (*internal_medium).albedo = clamp(_e939, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e942 = transmission_scatter_anisotropy_1;
            (*internal_medium).anisotropy = clamp(_e942, -0.99f, 0.99f);
        }
        let _e945 = V_16;
        let _e946 = m_ior;
        let _e947 = (*woutputL_11);
        Hr = normalize(-((_e945 + (_e947 * _e946))));
        let _e953 = Hr[2u];
        if (_e953 < 0f) {
            let _e955 = Hr;
            Hr = -(_e955);
        }
        let _e957 = (*winputL_8);
        let _e958 = Ht_2;
        VoH = abs(dot(_e957, _e958));
        let _e961 = (*woutputL_11);
        let _e962 = Ht_2;
        LoH = abs(dot(_e961, _e962));
        let _e965 = LoH;
        let _e966 = etaRatio;
        let _e967 = VoH;
        denomT = (_e965 + (_e966 * _e967));
        let _e970 = etaRatio;
        let _e971 = etaRatio;
        let _e973 = VoH;
        let _e975 = denomT;
        let _e976 = denomT;
        jacT = (((_e970 * _e971) * _e973) / max((_e975 * _e976), 0.00000001f));
        let _e980 = Vsample;
        param_829 = _e980;
        let _e982 = sampleAlpha[0u];
        param_830 = _e982;
        let _e984 = sampleAlpha[1u];
        param_831 = _e984;
        let _e985 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_829), (&param_830), (&param_831));
        let _e986 = VoH;
        let _e989 = Ht_2[2u];
        if (abs(_e989) > 0f) {
            let _e993 = Ht_2[0u];
            let _e995 = Ht_2[1u];
            let _e997 = Ht_2[2u];
            local_16 = vec3<f32>(_e993, _e995, abs(_e997));
        } else {
            let _e1000 = Ht_2;
            local_16 = _e1000;
        }
        let _e1001 = local_16;
        param_832 = _e1001;
        let _e1003 = sampleAlpha[0u];
        param_833 = _e1003;
        let _e1005 = sampleAlpha[1u];
        param_834 = _e1005;
        let _e1006 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_832), (&param_833), (&param_834));
        let _e1009 = (*winputL_8)[2u];
        DvT = (((_e985 * _e986) * _e1006) / max(abs(_e1009), 0.0001f));
        let _e1013 = pCoat;
        let _e1015 = pTrans;
        let _e1017 = DvT;
        let _e1019 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e1013) * _e1015) * _e1017) * _e1019), 0.000001f);
        let _e1023 = Ht_2[2u];
        if (abs(_e1023) > 0f) {
            let _e1027 = Ht_2[0u];
            let _e1029 = Ht_2[1u];
            let _e1031 = Ht_2[2u];
            local_17 = vec3<f32>(_e1027, _e1029, abs(_e1031));
        } else {
            let _e1034 = Ht_2;
            local_17 = _e1034;
        }
        let _e1035 = local_17;
        param_835 = _e1035;
        let _e1037 = sampleAlpha[0u];
        param_836 = _e1037;
        let _e1039 = sampleAlpha[1u];
        param_837 = _e1039;
        let _e1040 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_835), (&param_836), (&param_837));
        D_3 = _e1040;
        let _e1041 = (*winputL_8);
        param_838 = _e1041;
        let _e1042 = (*woutputL_11);
        param_839 = _e1042;
        let _e1044 = sampleAlpha[0u];
        param_840 = _e1044;
        let _e1046 = sampleAlpha[1u];
        param_841 = _e1046;
        let _e1047 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_838), (&param_839), (&param_840), (&param_841));
        G2_ = _e1047;
        let _e1048 = etaRatio;
        etaRefl = (1f / _e1048);
        let _e1050 = VoH;
        param_842 = _e1050;
        let _e1051 = etaRefl;
        param_843 = _e1051;
        let _e1052 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_842), (&param_843));
        T_1 = clamp((1f - _e1052), 0f, 1f);
        let _e1055 = m_transD;
        let _e1057 = m_transC;
        tint_3 = select(vec3<f32>(1f, 1f, 1f), _e1057, (_e1055 == 0f));
        let _e1059 = m_transW;
        let _e1060 = tint_3;
        let _e1062 = T_1;
        let _e1064 = VoH;
        let _e1066 = jacT;
        let _e1068 = D_3;
        let _e1070 = G2_;
        let _e1073 = (*woutputL_11)[2u];
        let _e1076 = (*winputL_8)[2u];
        return (((((((_e1060 * _e1059) * _e1062) * _e1064) * _e1066) * _e1068) * _e1070) / vec3(max((abs(_e1073) * abs(_e1076)), 0.0000000001f)));
    }
    let _e1082 = m_metal;
    let _e1084 = m_base;
    diffLum = ((1f - _e1082) * dot(_e1084, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1087 = Fv;
    let _e1088 = Fv;
    let _e1089 = Fv;
    let _e1091 = diffLum;
    pSpec = clamp((_e1087 / ((_e1088 + ((1f - _e1089) * _e1091)) + 0.001f)), 0.05f, 0.95f);
    let _e1097 = (*rndSeed_9);
    param_844 = _e1097;
    let _e1098 = rand_u0028_u1_u003b((&param_844));
    let _e1099 = param_844;
    (*rndSeed_9) = _e1099;
    let _e1100 = pSpec;
    if (_e1098 < _e1100) {
        let _e1102 = V_16;
        param_845 = _e1102;
        let _e1104 = sampleAlpha[0u];
        param_846 = _e1104;
        let _e1106 = sampleAlpha[1u];
        param_847 = _e1106;
        let _e1107 = (*rndSeed_9);
        param_848 = _e1107;
        let _e1108 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_845), (&param_846), (&param_847), (&param_848));
        let _e1109 = param_848;
        (*rndSeed_9) = _e1109;
        H_8 = _e1108;
        let _e1110 = V_16;
        let _e1112 = H_8;
        (*woutputL_11) = reflect(-(_e1110), _e1112);
    } else {
        let _e1114 = (*rndSeed_9);
        param_849 = _e1114;
        let _e1115 = pdfTmp;
        param_850 = _e1115;
        let _e1116 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_849), (&param_850));
        let _e1117 = param_849;
        (*rndSeed_9) = _e1117;
        let _e1118 = param_850;
        pdfTmp = _e1118;
        (*woutputL_11) = _e1116;
    }
    let _e1120 = (*woutputL_11)[2u];
    if (_e1120 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1122 = V_16;
    let _e1123 = (*woutputL_11);
    Hh = normalize((_e1122 + _e1123));
    let _e1126 = V_16;
    param_851 = _e1126;
    let _e1128 = sampleAlpha[0u];
    param_852 = _e1128;
    let _e1130 = sampleAlpha[1u];
    param_853 = _e1130;
    let _e1131 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_851), (&param_852), (&param_853));
    let _e1132 = Hh;
    param_854 = _e1132;
    let _e1134 = sampleAlpha[0u];
    param_855 = _e1134;
    let _e1136 = sampleAlpha[1u];
    param_856 = _e1136;
    let _e1137 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_854), (&param_855), (&param_856));
    let _e1139 = NdotV_21;
    pdfSpec = ((_e1131 * _e1137) / (4f * _e1139));
    let _e1142 = (*woutputL_11);
    param_857 = _e1142;
    let _e1143 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_857));
    pdfDiff = _e1143;
    let _e1144 = V_16;
    param_858 = _e1144;
    let _e1146 = coatSampleAlpha[0u];
    param_859 = _e1146;
    let _e1148 = coatSampleAlpha[1u];
    param_860 = _e1148;
    let _e1149 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_858), (&param_859), (&param_860));
    let _e1150 = Hh;
    param_861 = _e1150;
    let _e1152 = coatSampleAlpha[0u];
    param_862 = _e1152;
    let _e1154 = coatSampleAlpha[1u];
    param_863 = _e1154;
    let _e1155 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_861), (&param_862), (&param_863));
    let _e1157 = NdotV_21;
    pdfCoat_1 = ((_e1149 * _e1155) / (4f * _e1157));
    let _e1160 = pCoat;
    let _e1161 = pdfCoat_1;
    let _e1163 = pCoat;
    let _e1165 = pTrans;
    let _e1168 = pSpec;
    let _e1169 = pdfSpec;
    let _e1171 = pSpec;
    let _e1173 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1160 * _e1161) + (((1f - _e1163) * (1f - _e1165)) * ((_e1168 * _e1169) + ((1f - _e1171) * _e1173)))), 0.000001f);
    let _e1179 = (*pW_13);
    param_864 = _e1179;
    let _e1180 = (*basis_15);
    param_865 = _e1180;
    let _e1181 = (*winputL_8);
    param_866 = _e1181;
    let _e1182 = (*woutputL_11);
    param_867 = _e1182;
    let _e1183 = ignorePdf;
    param_868 = _e1183;
    let _e1184 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_864), (&param_865), (&param_866), (&param_867), (&param_868));
    let _e1185 = param_868;
    ignorePdf = _e1185;
    return _e1184;
}

fn sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b(pW_14: ptr<function, vec3<f32>>, basis_16: ptr<function, Basis>, winputL_9: ptr<function, vec3<f32>>, rndSeed_10: ptr<function, u32>, surfaceshader_4: ptr<function, i32>, woutputL_12: ptr<function, vec3<f32>>, pdf_woutputL_7: ptr<function, f32>, internal_medium_1: ptr<function, Volume>) -> vec3<f32> {
    var param_869: vec3<f32>;
    var param_870: Basis;
    var param_871: vec3<f32>;
    var param_872: u32;
    var param_873: vec3<f32>;
    var param_874: f32;
    var param_875: Volume;
    var param_876: vec3<f32>;
    var param_877: Basis;
    var param_878: vec3<f32>;
    var param_879: u32;
    var param_880: vec3<f32>;
    var param_881: f32;
    var param_882: vec3<f32>;
    var param_883: Basis;
    var param_884: vec3<f32>;
    var param_885: u32;
    var param_886: vec3<f32>;
    var param_887: f32;

    let _e369 = (*surfaceshader_4);
    if (_e369 == 1i) {
        let _e371 = (*pW_14);
        param_869 = _e371;
        let _e372 = (*basis_16);
        param_870 = _e372;
        let _e373 = (*winputL_9);
        param_871 = _e373;
        let _e374 = (*rndSeed_10);
        param_872 = _e374;
        let _e375 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_869), (&param_870), (&param_871), (&param_872), (&param_873), (&param_874), (&param_875));
        let _e376 = param_872;
        (*rndSeed_10) = _e376;
        let _e377 = param_873;
        (*woutputL_12) = _e377;
        let _e378 = param_874;
        (*pdf_woutputL_7) = _e378;
        let _e379 = param_875;
        (*internal_medium_1) = _e379;
        return _e375;
    } else {
        let _e380 = (*surfaceshader_4);
        if (_e380 == 2i) {
            let _e382 = (*pW_14);
            param_876 = _e382;
            let _e383 = (*basis_16);
            param_877 = _e383;
            let _e384 = (*winputL_9);
            param_878 = _e384;
            let _e385 = (*rndSeed_10);
            param_879 = _e385;
            let _e386 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_876), (&param_877), (&param_878), (&param_879), (&param_880), (&param_881));
            let _e387 = param_879;
            (*rndSeed_10) = _e387;
            let _e388 = param_880;
            (*woutputL_12) = _e388;
            let _e389 = param_881;
            (*pdf_woutputL_7) = _e389;
            return _e386;
        } else {
            let _e390 = (*pW_14);
            param_882 = _e390;
            let _e391 = (*basis_16);
            param_883 = _e391;
            let _e392 = (*winputL_9);
            param_884 = _e392;
            let _e393 = (*rndSeed_10);
            param_885 = _e393;
            let _e394 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_882), (&param_883), (&param_884), (&param_885), (&param_886), (&param_887));
            let _e395 = param_885;
            (*rndSeed_10) = _e395;
            let _e396 = param_886;
            (*woutputL_12) = _e396;
            let _e397 = param_887;
            (*pdf_woutputL_7) = _e397;
            return _e394;
        }
    }
}

fn mtlx_openpbr_thin_film_ior_u0028_() -> f32 {
    let _e342 = thin_film_ior_1;
    return max(_e342, 1f);
}

fn mtlx_openpbr_thin_film_thickness_nm_u0028_() -> f32 {
    let _e342 = thin_film_thickness_1;
    return max((1000f * _e342), 0f);
}

fn mtlx_openpbr_specular_ior_u0028_() -> f32 {
    let _e342 = specular_ior_1;
    return max(_e342, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e342 = specular_roughness_1;
    return clamp(_e342, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    let _e342 = thin_film_weight_1;
    return clamp(_e342, 0f, 1f);
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e342 = transmission_weight_1;
    return clamp(_e342, 0f, 1f);
}

fn evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(basis_17: ptr<function, Basis>, winputL_10: ptr<function, vec3<f32>>) -> vec3<f32> {
    var cosI: f32;
    var fd_11: FresnelData;
    var param_888: f32;
    var param_889: f32;
    var param_890: f32;
    var F_4: vec3<f32>;
    var param_891: f32;
    var param_892: FresnelData;
    var reflectedL: vec3<f32>;
    var reflectedW: vec3<f32>;
    var param_893: vec3<f32>;
    var param_894: Basis;
    var envRadiance: vec3<f32>;
    var param_895: vec3<f32>;
    var param_896: vec3<f32>;

    let _e359 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e359) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e361 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e361 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e363 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e363 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e365 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e365 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e368 = (*winputL_10)[2u];
    cosI = clamp(abs(_e368), 0.0001f, 1f);
    let _e371 = mtlx_openpbr_specular_ior_u0028_();
    let _e373 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e374 = mtlx_openpbr_thin_film_ior_u0028_();
    param_888 = max(_e371, 1.001f);
    param_889 = _e373;
    param_890 = _e374;
    let _e375 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_888), (&param_889), (&param_890));
    fd_11 = _e375;
    let _e376 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e377 = cosI;
    param_891 = _e377;
    let _e378 = fd_11;
    param_892 = _e378;
    let _e379 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_891), (&param_892));
    F_4 = (_e379 * _e376);
    let _e381 = (*winputL_10);
    reflectedL = reflect(-(_e381), vec3<f32>(0f, 0f, 1f));
    let _e385 = reflectedL[2u];
    if (_e385 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e387 = reflectedL;
    param_893 = _e387;
    let _e388 = (*basis_17);
    param_894 = _e388;
    let _e389 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_893), (&param_894));
    reflectedW = _e389;
    let _e390 = reflectedW;
    param_895 = _e390;
    let _e391 = sunRadiance_u0028_vf3_u003b((&param_895));
    let _e392 = reflectedW;
    param_896 = _e392;
    let _e393 = skyRadiance_u0028_vf3_u003b((&param_896));
    envRadiance = (_e391 + _e393);
    let _e395 = envRadiance;
    let _e397 = unnamed.skyPower;
    let _e400 = unnamed.skyColor;
    envRadiance = max(_e395, (_e400 * (0.25f * _e397)));
    let _e403 = F_4;
    let _e404 = envRadiance;
    return (_e403 * _e404);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_897: vec3<f32>;
    var param_898: vec3<f32>;

    let _e349 = (*nW);
    param_897 = _e349;
    let _e350 = safe_normalize_u0028_vf3_u003b((&param_897));
    basis_18.nW = _e350;
    let _e352 = (*tW);
    param_898 = _e352;
    let _e353 = safe_normalize_u0028_vf3_u003b((&param_898));
    basis_18.tW = _e353;
    let _e356 = basis_18.nW;
    let _e358 = basis_18.tW;
    basis_18.bW = cross(_e356, _e358);
    let _e361 = (*baryCoord_2);
    basis_18.baryCoord = _e361;
    let _e363 = (*texCoord_2);
    basis_18.texCoord = _e363;
    let _e365 = basis_18;
    return _e365;
}

fn powerHeuristic_u0028_f1_u003b_f1_u003b(a_4: f32, b_1: f32) -> f32 {
    return ((a_4 * a_4) / max(0.0000000001f, ((a_4 * a_4) + (b_1 * b_1))));
}

fn LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(shadowW_1: ptr<function, vec3<f32>>, basis_19: ptr<function, Basis>) -> f32 {
    var shadowL_1: vec3<f32>;
    var param_899: vec3<f32>;
    var param_900: Basis;
    var pdf_sky_1: f32;
    var param_901: vec3<f32>;
    var param_902: vec3<f32>;
    var pdf_sun_1: f32;
    var param_903: vec3<f32>;
    var param_904: vec3<f32>;
    var w_sun_1: f32;
    var local_18: f32;
    var w_sky_1: f32;
    var w_total_1: f32;
    var P_sun_1: f32;
    var P_sky_1: f32;
    var lightPdf_1: f32;
    var phi_9336_: bool;

    let _e360 = (*shadowW_1);
    param_899 = _e360;
    let _e361 = (*basis_19);
    param_900 = _e361;
    let _e362 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_899), (&param_900));
    shadowL_1 = _e362;
    let _e363 = shadowL_1;
    param_901 = _e363;
    let _e364 = (*shadowW_1);
    param_902 = _e364;
    let _e365 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_901), (&param_902));
    pdf_sky_1 = _e365;
    let _e366 = shadowL_1;
    param_903 = _e366;
    let _e367 = (*shadowW_1);
    param_904 = _e367;
    let _e368 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_903), (&param_904));
    pdf_sun_1 = _e368;
    let _e370 = unnamed.mtlxDisableSun;
    let _e371 = (_e370 != 0u);
    phi_9336_ = _e371;
    if !(_e371) {
        let _e374 = unnamed.mtlxLightCount;
        phi_9336_ = (_e374 > 0i);
    }
    let _e377 = phi_9336_;
    if _e377 {
        local_18 = 0f;
    } else {
        let _e378 = sunTotalPower_u0028_();
        local_18 = _e378;
    }
    let _e379 = local_18;
    w_sun_1 = _e379;
    let _e380 = skyTotalPower_u0028_();
    w_sky_1 = _e380;
    let _e381 = w_sun_1;
    let _e382 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e381 + _e382));
    let _e385 = w_sun_1;
    let _e386 = w_total_1;
    P_sun_1 = (_e385 / _e386);
    let _e388 = w_sky_1;
    let _e389 = w_total_1;
    P_sky_1 = (_e388 / _e389);
    let _e391 = P_sun_1;
    let _e392 = pdf_sun_1;
    let _e394 = P_sky_1;
    let _e395 = pdf_sky_1;
    lightPdf_1 = ((_e391 * _e392) + (_e394 * _e395));
    let _e398 = lightPdf_1;
    return _e398;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_905: vec3<f32>;
    var param_906: vec3<f32>;

    let _e346 = (*nW_1);
    param_905 = _e346;
    let _e347 = safe_normalize_u0028_vf3_u003b((&param_905));
    basis_20.nW = _e347;
    let _e349 = (*nW_1);
    param_906 = _e349;
    let _e350 = normalToTangent_u0028_vf3_u003b((&param_906));
    basis_20.tW = _e350;
    let _e353 = basis_20.nW;
    let _e355 = basis_20.tW;
    basis_20.bW = cross(_e353, _e355);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e360 = basis_20;
    return _e360;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e352 = (*cameraWorld);
    lookDirection = (_e352 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e354 = (*inverseProjection);
    nearVector = (_e354 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e357 = nearVector[2u];
    let _e359 = nearVector[3u];
    nearDistance_1 = abs((_e357 / _e359));
    let _e362 = (*cameraWorld);
    origin_1 = (_e362 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e364 = (*inverseProjection);
    let _e365 = (*coordinate);
    direction_1 = (_e364 * vec4<f32>(_e365.x, _e365.y, 0.5f, 1f));
    let _e371 = direction_1[3u];
    let _e372 = direction_1;
    direction_1 = (_e372 / vec4(_e371));
    let _e375 = (*cameraWorld);
    let _e376 = direction_1;
    let _e378 = origin_1;
    direction_1 = ((_e375 * _e376) - _e378);
    let _e380 = direction_1;
    let _e382 = nearDistance_1;
    let _e384 = direction_1;
    let _e385 = lookDirection;
    let _e389 = origin_1;
    let _e391 = (_e389.xyz + ((_e380.xyz * _e382) / vec3(dot(_e384, _e385))));
    origin_1[0u] = _e391.x;
    origin_1[1u] = _e391.y;
    origin_1[2u] = _e391.z;
    let _e398 = origin_1;
    (*rayOrigin_4) = _e398.xyz;
    let _e400 = direction_1;
    (*rayDirection_2) = _e400.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_19: f32;

    let _e344 = (*xi_1);
    if (_e344 < 0.5f) {
        let _e346 = (*xi_1);
        local_19 = (sqrt((2f * _e346)) - 1f);
    } else {
        let _e350 = (*xi_1);
        local_19 = (1f - sqrt((2f - (2f * _e350))));
    }
    let _e355 = local_19;
    return _e355;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e343 = (*seed_1);
    let _e346 = (*seed_1);
    (*seed_1) = (_e346 ^ (_e343 << bitcast<u32>(13u)));
    let _e348 = (*seed_1);
    let _e351 = (*seed_1);
    (*seed_1) = (_e351 ^ (_e348 >> bitcast<u32>(17u)));
    let _e353 = (*seed_1);
    let _e356 = (*seed_1);
    (*seed_1) = (_e356 ^ (_e353 << bitcast<u32>(5u)));
    return;
}

fn main_1() {
    var frag: vec2<f32>;
    var rndSeed_11: u32;
    var param_907: u32;
    var jx: f32;
    var param_908: u32;
    var param_909: f32;
    var jy: f32;
    var param_910: u32;
    var param_911: f32;
    var pixel: vec2<f32>;
    var ndc: vec2<f32>;
    var pW_15: vec3<f32>;
    var dW: vec3<f32>;
    var param_912: vec2<f32>;
    var param_913: mat4x4<f32>;
    var param_914: mat4x4<f32>;
    var param_915: vec3<f32>;
    var param_916: vec3<f32>;
    var param_917: vec3<f32>;
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
    var param_918: vec3<f32>;
    var param_919: vec3<f32>;
    var param_920: f32;
    var param_921: vec3<f32>;
    var param_922: vec3<f32>;
    var param_923: vec3<f32>;
    var param_924: vec3<f32>;
    var param_925: vec3<f32>;
    var param_926: vec2<f32>;
    var param_927: i32;
    var misWeightLight: f32;
    var lightPdf_2: f32;
    var basis_21: Basis;
    var param_928: vec3<f32>;
    var param_929: Basis;
    var Lenv: vec3<f32>;
    var param_930: vec3<f32>;
    var param_931: vec3<f32>;
    var maxLenv: f32;
    var param_932: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW_1: vec3<f32>;
    var baryCoord_3: vec3<f32>;
    var texCoord_3: vec2<f32>;
    var surfaceshader_5: i32;
    var param_933: vec3<f32>;
    var param_934: vec3<f32>;
    var param_935: vec3<f32>;
    var param_936: vec2<f32>;
    var param_937: vec3<f32>;
    var param_938: vec3<f32>;
    var param_939: vec3<f32>;
    var param_940: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_11: vec3<f32>;
    var param_941: vec3<f32>;
    var param_942: Basis;
    var thin_walled: bool;
    var param_943: vec3<f32>;
    var param_944: Basis;
    var param_945: vec3<f32>;
    var param_946: u32;
    var Ltf: vec3<f32>;
    var param_947: Basis;
    var param_948: vec3<f32>;
    var maxLtf: f32;
    var param_949: vec3<f32>;
    var f_2: vec3<f32>;
    var woutputL_13: vec3<f32>;
    var internal_medium_2: Volume;
    var param_950: vec3<f32>;
    var param_951: Basis;
    var param_952: vec3<f32>;
    var param_953: u32;
    var param_954: i32;
    var param_955: vec3<f32>;
    var param_956: f32;
    var param_957: Volume;
    var woutputW_7: vec3<f32>;
    var param_958: vec3<f32>;
    var param_959: Basis;
    var transmitted_sample: bool;
    var cos_out: f32;
    var local_20: f32;
    var surface_throughput: vec3<f32>;
    var maxComp: f32;
    var param_960: vec3<f32>;
    var Le: vec3<f32>;
    var param_961: vec3<f32>;
    var param_962: Basis;
    var param_963: vec3<f32>;
    var maxLe: f32;
    var param_964: vec3<f32>;
    var transmitted: bool;
    var Li_8: vec3<f32>;
    var shadowL_2: vec3<f32>;
    var shadowW_2: vec3<f32>;
    var lightPdf_3: f32;
    var param_965: vec3<f32>;
    var param_966: Basis;
    var param_967: vec3<f32>;
    var param_968: vec3<f32>;
    var param_969: f32;
    var param_970: u32;
    var param_971: vec3<f32>;
    var bsdfPdf_shadow: f32;
    var fshadow: vec3<f32>;
    var param_972: vec3<f32>;
    var param_973: Basis;
    var param_974: vec3<f32>;
    var param_975: vec3<f32>;
    var param_976: i32;
    var param_977: f32;
    var misWeightLight_1: f32;
    var cos_shadow: f32;
    var local_21: f32;
    var Ld: vec3<f32>;
    var Lcontrib: vec3<f32>;
    var maxLcontrib: f32;
    var param_978: vec3<f32>;
    var maxTP: f32;
    var param_979: vec3<f32>;
    var param_980: vec3<f32>;
    var q: f32;
    var param_981: vec3<f32>;
    var param_982: u32;
    var phi_9670_: bool;
    var phi_9682_: bool;
    var phi_9683_: bool;
    var phi_9716_: bool;
    var phi_9723_: bool;
    var phi_9854_: bool;
    var phi_9945_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_weight_1 = 1f;
    base_color_1 = vec3<f32>(0.8f, 0.8f, 0.8f);
    base_diffuse_roughness_1 = 0f;
    base_metalness_1 = 0f;
    specular_weight_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    specular_roughness_1 = 0f;
    specular_ior_1 = 1f;
    specular_roughness_anisotropy_1 = 0f;
    transmission_weight_1 = 1f;
    transmission_color_1 = vec3<f32>(1f, 1f, 1f);
    transmission_depth_1 = 0f;
    transmission_scatter_1 = vec3<f32>(0f, 0f, 0f);
    transmission_scatter_anisotropy_1 = 0f;
    transmission_dispersion_scale_1 = 0f;
    transmission_dispersion_abbe_number_1 = 20f;
    subsurface_weight_1 = 0f;
    subsurface_color_1 = vec3<f32>(0.8f, 0.8f, 0.8f);
    subsurface_radius_1 = 1f;
    subsurface_radius_scale_1 = vec3<f32>(1f, 0.5f, 0.25f);
    subsurface_scatter_anisotropy_1 = 0f;
    fuzz_weight_1 = 0f;
    fuzz_color_1 = vec3<f32>(1f, 1f, 1f);
    fuzz_roughness_1 = 0.5f;
    coat_weight_1 = 0f;
    coat_color_1 = vec3<f32>(1f, 1f, 1f);
    coat_roughness_1 = 0f;
    coat_roughness_anisotropy_1 = 0f;
    coat_ior_1 = 1.6f;
    coat_darkening_1 = 1f;
    thin_film_weight_1 = 1f;
    thin_film_thickness_1 = 0.5f;
    thin_film_ior_1 = 1.4f;
    emission_luminance_1 = 0f;
    emission_color_1 = vec3<f32>(1f, 1f, 1f);
    geometry_opacity_1 = 1f;
    geometry_thin_walled_1 = true;
    let _e483 = gl_FragCoord_1;
    frag = _e483.xy;
    let _e486 = frag[0u];
    let _e488 = frag[1u];
    let _e491 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e486 + (_e488 * _e491)));
    let _e495 = rndSeed_11;
    param_907 = _e495;
    xorshift_u0028_u1_u003b((&param_907));
    let _e496 = param_907;
    rndSeed_11 = _e496;
    let _e498 = unnamed.samples;
    let _e500 = rndSeed_11;
    rndSeed_11 = (_e500 ^ u32(_e498));
    let _e502 = rndSeed_11;
    param_908 = _e502;
    let _e503 = rand_u0028_u1_u003b((&param_908));
    let _e504 = param_908;
    rndSeed_11 = _e504;
    param_909 = _e503;
    let _e505 = sample_triangle_filter_u0028_f1_u003b((&param_909));
    jx = (0.5f * _e505);
    let _e507 = rndSeed_11;
    param_910 = _e507;
    let _e508 = rand_u0028_u1_u003b((&param_910));
    let _e509 = param_910;
    rndSeed_11 = _e509;
    param_911 = _e508;
    let _e510 = sample_triangle_filter_u0028_f1_u003b((&param_911));
    jy = (0.5f * _e510);
    let _e512 = frag;
    let _e513 = jx;
    let _e514 = jy;
    pixel = (_e512 + vec2<f32>(_e513, _e514));
    let _e517 = pixel;
    let _e519 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e517 / _e519) * 2f));
    let _e525 = unnamed.invModelMatrix;
    let _e527 = unnamed.cameraWorldMatrix;
    let _e529 = ndc;
    param_912 = _e529;
    param_913 = (_e525 * _e527);
    let _e531 = unnamed.invProjectionMatrix;
    param_914 = _e531;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_912), (&param_913), (&param_914), (&param_915), (&param_916));
    let _e532 = param_915;
    pW_15 = _e532;
    let _e533 = param_916;
    dW = _e533;
    let _e534 = dW;
    dW = normalize(_e534);
    let _e537 = unnamed.sunDir;
    param_917 = _e537;
    let _e538 = makeBasis_u0028_vf3_u003b((&param_917));
    sunBasis = _e538;
    L_12 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e539 = vertex;
        let _e541 = unnamed.bounces;
        if (_e539 <= _e541) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e543 = inside_scattering_volume;
            if !(_e543) {
                let _e545 = pW_15;
                param_918 = _e545;
                let _e546 = dW;
                param_919 = _e546;
                param_920 = 100000000000000000000f;
                let _e547 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_918), (&param_919), (&param_920), (&param_921), (&param_922), (&param_923), (&param_924), (&param_925), (&param_926), (&param_927));
                let _e548 = param_921;
                pW_next = _e548;
                let _e549 = param_922;
                NsW_next = _e549;
                let _e550 = param_923;
                NgW_next = _e550;
                let _e551 = param_924;
                TsW_next = _e551;
                let _e552 = param_925;
                baryCoord_next = _e552;
                let _e553 = param_926;
                texCoord_next = _e553;
                let _e554 = param_927;
                material_next = _e554;
                surface_hit = _e547;
            }
            let _e555 = surface_hit;
            if !(_e555) {
                misWeightLight = 1f;
                let _e557 = vertex;
                let _e559 = inside_scattering_volume;
                if ((_e557 > 0i) && !(_e559)) {
                    let _e562 = dW;
                    param_928 = _e562;
                    let _e563 = basis_21;
                    param_929 = _e563;
                    let _e564 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_928), (&param_929));
                    lightPdf_2 = _e564;
                    let _e565 = bsdfPdf_continuation;
                    let _e566 = lightPdf_2;
                    let _e567 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e565, _e566);
                    misWeightLight = _e567;
                }
                let _e568 = throughput;
                let _e569 = misWeightLight;
                let _e571 = dW;
                param_930 = _e571;
                let _e572 = sunRadiance_u0028_vf3_u003b((&param_930));
                let _e573 = dW;
                param_931 = _e573;
                let _e574 = skyRadiance_u0028_vf3_u003b((&param_931));
                Lenv = ((_e568 * _e569) * (_e572 + _e574));
                let _e577 = Lenv;
                param_932 = _e577;
                let _e578 = maxComponent_u0028_vf3_u003b((&param_932));
                maxLenv = _e578;
                let _e579 = maxLenv;
                let _e581 = unnamed.firefly_clamp;
                if (_e579 > _e581) {
                    let _e584 = unnamed.firefly_clamp;
                    let _e585 = maxLenv;
                    let _e587 = Lenv;
                    Lenv = (_e587 * (_e584 / _e585));
                }
                let _e589 = Lenv;
                let _e590 = L_12;
                L_12 = (_e590 + _e589);
                break;
            }
            let _e592 = vertex;
            let _e594 = unnamed.bounces;
            if (_e592 == _e594) {
                break;
            }
            let _e596 = pW_next;
            pW_15 = _e596;
            let _e597 = NsW_next;
            NsW = _e597;
            let _e598 = NgW_next;
            NgW = _e598;
            let _e599 = TsW_next;
            TsW_1 = _e599;
            let _e600 = baryCoord_next;
            baryCoord_3 = _e600;
            let _e601 = texCoord_next;
            texCoord_3 = _e601;
            let _e602 = material_next;
            surfaceshader_5 = _e602;
            let _e603 = surfaceshader_5;
            if (_e603 == 1i) {
                let _e605 = in_dielectric;
                phi_9670_ = _e605;
                if _e605 {
                    let _e606 = NsW;
                    let _e607 = dW;
                    phi_9670_ = (dot(_e606, _e607) < 0f);
                }
                let _e611 = phi_9670_;
                phi_9683_ = _e611;
                if !(_e611) {
                    let _e613 = in_dielectric;
                    let _e614 = !(_e613);
                    phi_9682_ = _e614;
                    if _e614 {
                        let _e615 = NsW;
                        let _e616 = dW;
                        phi_9682_ = (dot(_e615, _e616) > 0f);
                    }
                    let _e620 = phi_9682_;
                    phi_9683_ = _e620;
                }
                let _e622 = phi_9683_;
                if _e622 {
                    let _e623 = NsW;
                    NsW = (_e623 * -1f);
                }
            } else {
                let _e625 = NsW;
                let _e626 = dW;
                if (dot(_e625, _e626) > 0f) {
                    let _e629 = NsW;
                    NsW = (_e629 * -1f);
                }
            }
            let _e631 = NgW;
            let _e632 = NsW;
            if (dot(_e631, _e632) < 0f) {
                let _e635 = NgW;
                NgW = (_e635 * -1f);
            }
            let _e638 = unnamed.smooth_normals;
            if (_e638 != 0u) {
                let _e640 = surfaceshader_5;
                let _e641 = (_e640 == 1i);
                phi_9716_ = _e641;
                if _e641 {
                    let _e642 = mtlx_openpbr_is_opaque_u0028_();
                    phi_9716_ = _e642;
                }
                let _e644 = phi_9716_;
                phi_9723_ = _e644;
                if _e644 {
                    let _e645 = NsW;
                    let _e646 = dW;
                    phi_9723_ = (dot(_e645, _e646) > 0f);
                }
                let _e650 = phi_9723_;
                if _e650 {
                    let _e651 = NgW;
                    let _e653 = NgW;
                    let _e654 = NsW;
                    let _e657 = NsW;
                    NsW = (((_e651 * 2f) * dot(_e653, _e654)) - _e657);
                }
                let _e659 = NsW;
                param_933 = _e659;
                let _e660 = TsW_next;
                param_934 = _e660;
                let _e661 = baryCoord_3;
                param_935 = _e661;
                let _e662 = texCoord_3;
                param_936 = _e662;
                let _e663 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_933), (&param_934), (&param_935), (&param_936));
                basis_21 = _e663;
            } else {
                let _e664 = NgW;
                param_937 = _e664;
                let _e665 = TsW_next;
                param_938 = _e665;
                let _e666 = baryCoord_3;
                param_939 = _e666;
                let _e667 = texCoord_3;
                param_940 = _e667;
                let _e668 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_937), (&param_938), (&param_939), (&param_940));
                basis_21 = _e668;
            }
            let _e669 = dW;
            winputW = -(_e669);
            let _e671 = winputW;
            param_941 = _e671;
            let _e672 = basis_21;
            param_942 = _e672;
            let _e673 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_941), (&param_942));
            winputL_11 = _e673;
            let _e675 = winputL_11[2u];
            if (abs(_e675) < 0.001f) {
                break;
            }
            thin_walled = false;
            let _e678 = surfaceshader_5;
            if (_e678 == 1i) {
                let _e680 = pW_15;
                param_943 = _e680;
                let _e681 = basis_21;
                param_944 = _e681;
                let _e682 = winputL_11;
                param_945 = _e682;
                let _e683 = rndSeed_11;
                param_946 = _e683;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_943), (&param_944), (&param_945), (&param_946));
                let _e684 = param_946;
                rndSeed_11 = _e684;
                let _e685 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled = _e685;
            }
            let _e686 = surfaceshader_5;
            if (_e686 == 1i) {
                let _e688 = throughput;
                let _e689 = basis_21;
                param_947 = _e689;
                let _e690 = winputL_11;
                param_948 = _e690;
                let _e691 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_947), (&param_948));
                Ltf = (_e688 * _e691);
                let _e693 = Ltf;
                param_949 = _e693;
                let _e694 = maxComponent_u0028_vf3_u003b((&param_949));
                maxLtf = _e694;
                let _e695 = maxLtf;
                let _e697 = unnamed.firefly_clamp;
                if (_e695 > _e697) {
                    let _e700 = unnamed.firefly_clamp;
                    let _e701 = maxLtf;
                    let _e703 = Ltf;
                    Ltf = (_e703 * (_e700 / _e701));
                }
                let _e705 = Ltf;
                let _e706 = L_12;
                L_12 = (_e706 + _e705);
            }
            let _e708 = pW_15;
            param_950 = _e708;
            let _e709 = basis_21;
            param_951 = _e709;
            let _e710 = winputL_11;
            param_952 = _e710;
            let _e711 = rndSeed_11;
            param_953 = _e711;
            let _e712 = surfaceshader_5;
            param_954 = _e712;
            let _e713 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_950), (&param_951), (&param_952), (&param_953), (&param_954), (&param_955), (&param_956), (&param_957));
            let _e714 = param_953;
            rndSeed_11 = _e714;
            let _e715 = param_955;
            woutputL_13 = _e715;
            let _e716 = param_956;
            bsdfPdf_continuation = _e716;
            let _e717 = param_957;
            internal_medium_2 = _e717;
            f_2 = _e713;
            let _e718 = woutputL_13;
            param_958 = _e718;
            let _e719 = basis_21;
            param_959 = _e719;
            let _e720 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_958), (&param_959));
            woutputW_7 = _e720;
            let _e721 = surfaceshader_5;
            let _e722 = (_e721 == 1i);
            phi_9854_ = _e722;
            if _e722 {
                let _e724 = winputL_11[2u];
                let _e726 = woutputL_13[2u];
                phi_9854_ = ((_e724 * _e726) < 0f);
            }
            let _e730 = phi_9854_;
            transmitted_sample = _e730;
            let _e731 = surfaceshader_5;
            let _e733 = transmitted_sample;
            if ((_e731 == 1i) && !(_e733)) {
                local_20 = 1f;
            } else {
                let _e736 = woutputW_7;
                let _e738 = basis_21.nW;
                local_20 = abs(dot(_e736, _e738));
            }
            let _e741 = local_20;
            cos_out = _e741;
            let _e742 = f_2;
            let _e743 = bsdfPdf_continuation;
            let _e747 = cos_out;
            surface_throughput = ((_e742 / vec3(max(0.000001f, _e743))) * _e747);
            let _e749 = surface_throughput;
            param_960 = _e749;
            let _e750 = maxComponent_u0028_vf3_u003b((&param_960));
            maxComp = _e750;
            let _e751 = maxComp;
            let _e753 = unnamed.firefly_clamp;
            if (_e751 > _e753) {
                let _e756 = unnamed.firefly_clamp;
                let _e757 = maxComp;
                let _e759 = surface_throughput;
                surface_throughput = (_e759 * (_e756 / _e757));
            }
            let _e761 = woutputW_7;
            dW = _e761;
            let _e762 = surfaceshader_5;
            if (_e762 == 1i) {
                let _e764 = throughput;
                let _e765 = pW_15;
                param_961 = _e765;
                let _e766 = basis_21;
                param_962 = _e766;
                let _e767 = winputL_11;
                param_963 = _e767;
                let _e768 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_961), (&param_962), (&param_963));
                Le = (_e764 * _e768);
                let _e770 = Le;
                param_964 = _e770;
                let _e771 = maxComponent_u0028_vf3_u003b((&param_964));
                maxLe = _e771;
                let _e772 = maxLe;
                let _e774 = unnamed.firefly_clamp;
                if (_e772 > _e774) {
                    let _e777 = unnamed.firefly_clamp;
                    let _e778 = maxLe;
                    let _e780 = Le;
                    Le = (_e780 * (_e777 / _e778));
                }
                let _e782 = Le;
                let _e783 = L_12;
                L_12 = (_e783 + _e782);
            }
            let _e785 = thin_walled;
            let _e787 = surfaceshader_5;
            let _e789 = (!(_e785) && (_e787 == 1i));
            phi_9945_ = _e789;
            if _e789 {
                let _e790 = winputW;
                let _e791 = NgW;
                let _e793 = dW;
                let _e794 = NgW;
                phi_9945_ = ((dot(_e790, _e791) * dot(_e793, _e794)) < 0f);
            }
            let _e799 = phi_9945_;
            transmitted = _e799;
            let _e800 = transmitted;
            if _e800 {
                let _e801 = in_dielectric;
                in_dielectric = !(_e801);
            }
            let _e803 = in_dielectric;
            let _e805 = transmitted;
            if (!(_e803) && !(_e805)) {
                let _e808 = pW_15;
                param_965 = _e808;
                let _e809 = basis_21;
                param_966 = _e809;
                let _e810 = rndSeed_11;
                param_970 = _e810;
                let _e811 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_965), (&param_966), (&param_967), (&param_968), (&param_969), (&param_970));
                let _e812 = param_967;
                shadowL_2 = _e812;
                let _e813 = param_968;
                shadowW_2 = _e813;
                let _e814 = param_969;
                lightPdf_3 = _e814;
                let _e815 = param_970;
                rndSeed_11 = _e815;
                Li_8 = _e811;
                let _e816 = Li_8;
                param_971 = _e816;
                let _e817 = maxComponent_u0028_vf3_u003b((&param_971));
                if (_e817 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e819 = pW_15;
                    param_972 = _e819;
                    let _e820 = basis_21;
                    param_973 = _e820;
                    let _e821 = winputL_11;
                    param_974 = _e821;
                    let _e822 = shadowL_2;
                    param_975 = _e822;
                    let _e823 = surfaceshader_5;
                    param_976 = _e823;
                    let _e824 = bsdfPdf_shadow;
                    param_977 = _e824;
                    let _e825 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_972), (&param_973), (&param_974), (&param_975), (&param_976), (&param_977));
                    let _e826 = param_977;
                    bsdfPdf_shadow = _e826;
                    fshadow = _e825;
                    let _e827 = lightPdf_3;
                    let _e828 = bsdfPdf_shadow;
                    let _e829 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e827, _e828);
                    misWeightLight_1 = _e829;
                    let _e830 = surfaceshader_5;
                    if (_e830 == 1i) {
                        local_21 = 1f;
                    } else {
                        let _e832 = shadowW_2;
                        let _e834 = basis_21.nW;
                        local_21 = abs(dot(_e832, _e834));
                    }
                    let _e837 = local_21;
                    cos_shadow = _e837;
                    let _e838 = misWeightLight_1;
                    let _e839 = fshadow;
                    let _e841 = cos_shadow;
                    let _e843 = Li_8;
                    let _e845 = lightPdf_3;
                    Ld = ((((_e839 * _e838) * _e841) * _e843) / vec3(max(0.000001f, _e845)));
                    let _e849 = throughput;
                    let _e850 = Ld;
                    Lcontrib = (_e849 * _e850);
                    let _e852 = Lcontrib;
                    param_978 = _e852;
                    let _e853 = maxComponent_u0028_vf3_u003b((&param_978));
                    maxLcontrib = _e853;
                    let _e854 = maxLcontrib;
                    let _e856 = unnamed.firefly_clamp;
                    if (_e854 > _e856) {
                        let _e859 = unnamed.firefly_clamp;
                        let _e860 = maxLcontrib;
                        let _e862 = Lcontrib;
                        Lcontrib = (_e862 * (_e859 / _e860));
                    }
                    let _e864 = Lcontrib;
                    let _e865 = L_12;
                    L_12 = (_e865 + _e864);
                }
            }
            let _e867 = NgW;
            let _e868 = dW;
            let _e869 = NgW;
            let _e874 = pW_15;
            pW_15 = (_e874 + ((_e867 * sign(dot(_e868, _e869))) * 0.0001f));
            let _e876 = surface_throughput;
            let _e877 = throughput;
            throughput = (_e877 * _e876);
            let _e879 = throughput;
            param_979 = _e879;
            let _e880 = maxComponent_u0028_vf3_u003b((&param_979));
            maxTP = _e880;
            let _e881 = maxTP;
            let _e883 = unnamed.firefly_clamp;
            if (_e881 > _e883) {
                let _e886 = unnamed.firefly_clamp;
                let _e887 = maxTP;
                let _e889 = throughput;
                throughput = (_e889 * (_e886 / _e887));
            }
            let _e891 = throughput;
            param_980 = _e891;
            let _e892 = maxComponent_u0028_vf3_u003b((&param_980));
            let _e894 = vertex;
            if ((_e892 < 1f) && (_e894 > 1i)) {
                let _e897 = throughput;
                param_981 = _e897;
                let _e898 = maxComponent_u0028_vf3_u003b((&param_981));
                q = max(0f, (1f - _e898));
                let _e901 = rndSeed_11;
                param_982 = _e901;
                let _e902 = rand_u0028_u1_u003b((&param_982));
                let _e903 = param_982;
                rndSeed_11 = _e903;
                let _e904 = q;
                if (_e902 < _e904) {
                    break;
                }
                let _e906 = q;
                let _e908 = throughput;
                throughput = (_e908 / vec3((1f - _e906)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e911 = vertex;
            vertex = (_e911 + 1i);
        }
    }
    let _e913 = L_12;
    mtlxFragmentColor[0u] = _e913.x;
    mtlxFragmentColor[1u] = _e913.y;
    mtlxFragmentColor[2u] = _e913.z;
    let _e921 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e921;
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
