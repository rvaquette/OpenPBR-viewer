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
    let _e348 = (*v)[0u];
    let _e350 = (*v)[1u];
    let _e352 = (*v)[2u];
    return min(_e348, min(_e350, _e352));
}

fn pdfHemisphereCosineWeighted_u0028_vf3_u003b(wiL: ptr<function, vec3<f32>>) -> f32 {
    let _e348 = (*wiL)[2u];
    if (_e348 <= 0.000001f) {
        return 0.00000031830987f;
    }
    let _e351 = (*wiL)[2u];
    return (_e351 / 3.1415927f);
}

fn neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>, pdf_woutputL: ptr<function, f32>) -> vec3<f32> {
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var phi_8021_: bool;
    var phi_8039_: bool;

    let _e354 = (*winputL)[2u];
    let _e355 = (_e354 < 0.0000000001f);
    phi_8021_ = _e355;
    if !(_e355) {
        let _e358 = (*woutputL)[2u];
        phi_8021_ = (_e358 < 0.0000000001f);
    }
    let _e361 = phi_8021_;
    if _e361 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e362 = (*woutputL);
    param = _e362;
    let _e363 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param));
    (*pdf_woutputL) = _e363;
    let _e365 = unnamed.wireframe;
    let _e366 = (_e365 != 0u);
    phi_8039_ = _e366;
    if _e366 {
        let _e368 = (*basis).baryCoord;
        param_1 = _e368;
        let _e369 = minComponent_u0028_vf3_u003b((&param_1));
        phi_8039_ = (_e369 < 0.003f);
    }
    let _e372 = phi_8039_;
    if _e372 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e374 = unnamed.neutral_color;
    return (_e374 / vec3(3.1415927f));
}

fn ground_albedo_u0028_vf3_u003b(pW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e349 = (*pW_1)[0u];
    let _e351 = (*pW_1)[2u];
    uv = (((vec2<f32>(_e349, -(_e351)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e359 = uv;
    let _e360 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e359, 0.0);
    return _e360.xyz;
}

fn ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, woutputL_1: ptr<function, vec3<f32>>, pdf_woutputL_1: ptr<function, f32>) -> vec3<f32> {
    var param_2: vec3<f32>;
    var param_3: vec3<f32>;
    var phi_8114_: bool;

    let _e354 = (*winputL_1)[2u];
    let _e355 = (_e354 < 0.0000000001f);
    phi_8114_ = _e355;
    if !(_e355) {
        let _e358 = (*woutputL_1)[2u];
        phi_8114_ = (_e358 < 0.0000000001f);
    }
    let _e361 = phi_8114_;
    if _e361 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e362 = (*woutputL_1);
    param_2 = _e362;
    let _e363 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_2));
    (*pdf_woutputL_1) = _e363;
    let _e364 = (*pW_2);
    param_3 = _e364;
    let _e365 = ground_albedo_u0028_vf3_u003b((&param_3));
    return (_e365 / vec3(3.1415927f));
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e351 = (*bg);
    let _e352 = (*fg);
    let _e353 = (*mixValue);
    (*result) = mix(_e351, _e352, vec3(_e353));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e351 = (*cosTheta);
    x = clamp((1f - _e351), 0f, 1f);
    let _e354 = (*F0_);
    let _e355 = (*F90_);
    let _e356 = x;
    let _e357 = (*exponent);
    return mix(_e354, _e355, vec3(pow(_e356, _e357)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e349 = (*N);
    let _e350 = (*V);
    if (dot(_e349, _e350) < 0f) {
        let _e353 = (*N);
        local = -(_e353);
    } else {
        let _e355 = (*N);
        local = _e355;
    }
    let _e356 = local;
    return _e356;
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

    let _e362 = (*closureData_1).closureType;
    if (_e362 == 4i) {
        let _e365 = (*closureData_1).N;
        param_4 = _e365;
        let _e367 = (*closureData_1).V;
        param_5 = _e367;
        let _e368 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_4), (&param_5));
        N_1 = _e368;
        let _e369 = N_1;
        let _e371 = (*closureData_1).V;
        NdotV = clamp(dot(_e369, _e371), 0.00000001f, 1f);
        let _e374 = NdotV;
        param_6 = _e374;
        let _e375 = (*color0_);
        param_7 = _e375;
        let _e376 = (*color90_);
        param_8 = _e376;
        let _e377 = (*exponent_1);
        param_9 = _e377;
        let _e378 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_6), (&param_7), (&param_8), (&param_9));
        f = _e378;
        let _e379 = (*base);
        let _e380 = f;
        (*result_1) = (_e379 * _e380);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e350 = (*in1_);
    let _e351 = (*in2_);
    (*result_2) = (_e350 * _e351);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e350 = (*closureData_3).closureType;
    if (_e350 == 4i) {
        let _e352 = (*color);
        (*result_3) = _e352;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_4: ptr<function, BSDF>) {
    let _e351 = (*top).response;
    let _e353 = (*base_1).response;
    let _e355 = (*top).throughput;
    (*result_4).response = (_e351 + (_e353 * _e355));
    let _e360 = (*top).throughput;
    let _e362 = (*base_1).throughput;
    (*result_4).throughput = (_e360 * _e362);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e350 = (*dir)[1u];
    latitude = ((-(asin(_e350)) * 0.31830987f) + 0.5f);
    let _e356 = (*dir)[0u];
    let _e358 = (*dir)[2u];
    longitude = (((atan2(_e356, -(_e358)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e364 = longitude;
    let _e365 = latitude;
    return vec2<f32>(_e364, _e365);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e348 = (*m);
    let _e349 = (*v_1);
    return (_e348 * _e349);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_12: vec3<f32>;

    let _e354 = (*dir_1);
    let _e359 = (*transform);
    param_10 = _e359;
    param_11 = vec4<f32>(_e354.x, _e354.y, _e354.z, 0f);
    let _e360 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_10), (&param_11));
    envDir = normalize(_e360.xyz);
    let _e363 = envDir;
    param_12 = _e363;
    let _e364 = mx_latlong_projection_u0028_vf3_u003b((&param_12));
    uv_1 = _e364;
    let _e365 = uv_1;
    let _e366 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e365, 0.0);
    return _e366.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e349 = a;
    c = cos(_e349);
    let _e351 = a;
    s = sin(_e351);
    let _e353 = c;
    let _e354 = s;
    let _e356 = s;
    let _e357 = c;
    return mat4x4<f32>(vec4<f32>(_e353, 0f, -(_e354), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e356, 0f, _e357, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_13: vec3<f32>;
    var param_14: mat4x4<f32>;
    var param_15: f32;

    let _e351 = mtlxEnvMatrix_u0028_();
    let _e352 = (*N_2);
    param_13 = _e352;
    param_14 = _e351;
    param_15 = 0f;
    let _e353 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_13), (&param_14), (&param_15));
    Li = _e353;
    let _e354 = Li;
    let _e356 = unnamed.skyPower;
    return (_e354 * _e356);
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e351 = (*shape);
    let _e353 = (*dist);
    num1_ = exp((-(_e351) * _e353));
    let _e356 = (*shape);
    let _e358 = (*dist);
    num2_ = exp(((-(_e356) * _e358) / vec3(3f)));
    let _e363 = (*dist);
    denom = max(_e363, 0.00000001f);
    let _e365 = num1_;
    let _e366 = num2_;
    let _e368 = denom;
    return ((_e365 + _e366) / vec3(_e368));
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

    let _e360 = (*N_3);
    let _e361 = (*L);
    theta = acos(dot(_e360, _e361));
    let _e364 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e364, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e368 = i;
        if (_e368 < 32i) {
            let _e370 = i;
            x_1 = (-3.1415927f + ((f32(_e370) + 0.5f) * 0.19634955f));
            let _e375 = (*radius);
            let _e376 = x_1;
            dist_1 = (_e375 * abs((2f * sin((_e376 * 0.5f)))));
            let _e382 = dist_1;
            param_16 = _e382;
            let _e383 = shape_1;
            param_17 = _e383;
            let _e384 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_16), (&param_17));
            R = _e384;
            let _e385 = R;
            let _e386 = theta;
            let _e387 = x_1;
            let _e392 = sumD;
            sumD = (_e392 + (_e385 * max(cos((_e386 + _e387)), 0f)));
            let _e394 = R;
            let _e395 = sumR;
            sumR = (_e395 + _e394);
            continue;
        } else {
            break;
        }
        continuing {
            let _e397 = i;
            i = (_e397 + 1i);
        }
    }
    let _e399 = sumD;
    let _e400 = sumR;
    return (_e399 / _e400);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_4: ptr<function, vec3<f32>>, L_1: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_18: vec3<f32>;
    var param_19: vec3<f32>;
    var param_20: f32;
    var param_21: vec3<f32>;

    let _e357 = (*N_4);
    let _e358 = fwidth(_e357);
    let _e360 = (*P);
    let _e361 = fwidth(_e360);
    curvature = (length(_e358) / length(_e361));
    let _e364 = curvature;
    radius_1 = (1f / max(_e364, 0.01f));
    let _e367 = (*albedo);
    let _e368 = (*N_4);
    param_18 = _e368;
    let _e369 = (*L_1);
    param_19 = _e369;
    let _e370 = radius_1;
    param_20 = _e370;
    let _e371 = (*mfp_1);
    param_21 = _e371;
    let _e372 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_18), (&param_19), (&param_20), (&param_21));
    return ((_e367 * _e372) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
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
    let _e370 = (*weight);
    if (_e370 < 0.00000001f) {
        return;
    }
    let _e373 = (*closureData_5).V;
    V_1 = _e373;
    let _e375 = (*closureData_5).L;
    L_2 = _e375;
    let _e377 = (*closureData_5).P;
    P_1 = _e377;
    let _e379 = (*closureData_5).occlusion;
    occlusion = _e379;
    let _e380 = (*N_5);
    param_22 = _e380;
    let _e381 = V_1;
    param_23 = _e381;
    let _e382 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_22), (&param_23));
    (*N_5) = _e382;
    let _e384 = (*closureData_5).closureType;
    if (_e384 == 1i) {
        let _e386 = (*N_5);
        param_24 = _e386;
        let _e387 = L_2;
        param_25 = _e387;
        let _e388 = P_1;
        param_26 = _e388;
        let _e389 = (*color_1);
        param_27 = _e389;
        let _e390 = (*radius_2);
        param_28 = _e390;
        let _e391 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_24), (&param_25), (&param_26), (&param_27), (&param_28));
        sss = _e391;
        let _e392 = (*N_5);
        let _e393 = L_2;
        NdotL = clamp(dot(_e392, _e393), 0.00000001f, 1f);
        let _e396 = NdotL;
        let _e397 = occlusion;
        visibleOcclusion = (1f - (_e396 * (1f - _e397)));
        let _e401 = sss;
        let _e402 = visibleOcclusion;
        let _e404 = (*weight);
        (*bsdf).response = ((_e401 * _e402) * _e404);
    } else {
        let _e408 = (*closureData_5).closureType;
        if (_e408 == 3i) {
            let _e410 = (*N_5);
            param_29 = _e410;
            let _e411 = mx_environment_irradiance_u0028_vf3_u003b((&param_29));
            Li_1 = _e411;
            let _e412 = Li_1;
            let _e413 = (*color_1);
            let _e415 = (*weight);
            (*bsdf).response = ((_e412 * _e413) * _e415);
        }
    }
    return;
}

fn mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, fg_1: ptr<function, BSDF>, bg_1: ptr<function, BSDF>, mixValue_1: ptr<function, f32>, result_5: ptr<function, BSDF>) {
    let _e352 = (*bg_1).response;
    let _e354 = (*fg_1).response;
    let _e355 = (*mixValue_1);
    (*result_5).response = mix(_e352, _e354, vec3(_e355));
    let _e360 = (*bg_1).throughput;
    let _e362 = (*fg_1).throughput;
    let _e363 = (*mixValue_1);
    (*result_5).throughput = mix(_e360, _e362, vec3(_e363));
    return;
}

fn mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, weight_1: ptr<function, f32>, color_2: ptr<function, vec3<f32>>, N_6: ptr<function, vec3<f32>>, bsdf_1: ptr<function, BSDF>) {
    var V_2: vec3<f32>;
    var L_3: vec3<f32>;
    var NdotL_1: f32;
    var Li_2: vec3<f32>;
    var param_30: vec3<f32>;

    (*bsdf_1).throughput = vec3<f32>(0f, 0f, 0f);
    let _e357 = (*weight_1);
    if (_e357 < 0.00000001f) {
        return;
    }
    let _e360 = (*closureData_7).V;
    V_2 = _e360;
    let _e362 = (*closureData_7).L;
    L_3 = _e362;
    let _e363 = (*N_6);
    (*N_6) = -(_e363);
    let _e366 = (*closureData_7).closureType;
    if (_e366 == 1i) {
        let _e368 = (*N_6);
        let _e369 = L_3;
        NdotL_1 = clamp(dot(_e368, _e369), 0f, 1f);
        let _e372 = (*color_2);
        let _e373 = (*weight_1);
        let _e375 = NdotL_1;
        (*bsdf_1).response = (((_e372 * _e373) * _e375) * 0.31830987f);
    } else {
        let _e380 = (*closureData_7).closureType;
        if (_e380 == 3i) {
            let _e382 = (*N_6);
            param_30 = _e382;
            let _e383 = mx_environment_irradiance_u0028_vf3_u003b((&param_30));
            Li_2 = _e383;
            let _e384 = Li_2;
            let _e385 = (*color_2);
            let _e387 = (*weight_1);
            (*bsdf_1).response = ((_e384 * _e385) * _e387);
        }
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_6: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e351 = (*in2_1);
    tint = clamp(_e351, vec3(0f), vec3(1f));
    let _e356 = (*in1_1).response;
    let _e357 = tint;
    (*result_6).response = (_e356 * _e357);
    let _e361 = (*in1_1).throughput;
    (*result_6).throughput = _e361;
    return;
}

fn mx_square_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    let _e347 = (*x_2);
    let _e348 = (*x_2);
    return (_e347 * _e348);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_31: f32;

    let _e350 = (*roughness);
    let _e353 = (*NdotV_1);
    let _e355 = (*roughness);
    let _e358 = (*roughness);
    param_31 = _e358;
    let _e359 = mx_square_u0028_f1_u003b((&param_31));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e350)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e353) * _e355)) + (vec2<f32>(1.4385f, 2.0315f) * _e359));
    let _e363 = r[0u];
    let _e365 = r[1u];
    return (_e363 / _e365);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_32: f32;
    var param_33: f32;

    let _e351 = (*NdotV_2);
    param_32 = _e351;
    let _e352 = (*roughness_1);
    param_33 = _e352;
    let _e353 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_32), (&param_33));
    dirAlbedo = _e353;
    let _e354 = dirAlbedo;
    return clamp(_e354, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e347 = (*x_3);
    let _e348 = (*x_3);
    return (_e347 * _e348);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e348 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e348)));
    let _e352 = A;
    let _e353 = (*roughness_2);
    return (_e352 * (1f + (0.07248821f * _e353)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_34: f32;
    var G: f32;

    let _e353 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e353)));
    let _e357 = (*roughness_3);
    let _e358 = A_1;
    B = (_e357 * _e358);
    let _e360 = (*cosTheta_1);
    param_34 = _e360;
    let _e361 = mx_square_u0028_f1_u003b((&param_34));
    Si = sqrt(max(0f, (1f - _e361)));
    let _e365 = Si;
    let _e366 = (*cosTheta_1);
    let _e369 = Si;
    let _e370 = (*cosTheta_1);
    let _e374 = Si;
    let _e375 = (*cosTheta_1);
    let _e377 = Si;
    let _e378 = Si;
    let _e380 = Si;
    let _e384 = Si;
    G = ((_e365 * (acos(clamp(_e366, -1f, 1f)) - (_e369 * _e370))) + ((2f * (((_e374 / _e375) * (1f - ((_e377 * _e378) * _e380))) - _e384)) / 3f));
    let _e389 = A_1;
    let _e390 = B;
    let _e391 = G;
    return (_e389 + ((_e390 * _e391) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_35: f32;
    var param_36: f32;
    var avgAlbedo: f32;
    var param_37: f32;
    var colorMultiScatter: vec3<f32>;
    var param_38: vec3<f32>;

    let _e356 = (*cosTheta_2);
    param_35 = _e356;
    let _e357 = (*roughness_4);
    param_36 = _e357;
    let _e358 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_35), (&param_36));
    dirAlbedo_1 = _e358;
    let _e359 = (*roughness_4);
    param_37 = _e359;
    let _e360 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_37));
    avgAlbedo = _e360;
    let _e361 = (*color_3);
    param_38 = _e361;
    let _e362 = mx_square_u0028_vf3_u003b((&param_38));
    let _e363 = avgAlbedo;
    let _e365 = (*color_3);
    let _e366 = avgAlbedo;
    colorMultiScatter = ((_e362 * _e363) / (vec3<f32>(1f, 1f, 1f) - (_e365 * max(0f, (1f - _e366)))));
    let _e372 = colorMultiScatter;
    let _e373 = (*color_3);
    let _e374 = dirAlbedo_1;
    return mix(_e372, _e373, vec3(_e374));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL_2: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_39: f32;
    var A_2: f32;
    var B_1: f32;

    let _e357 = (*LdotV);
    let _e358 = (*NdotL_2);
    let _e359 = (*NdotV_3);
    s_1 = (_e357 - (_e358 * _e359));
    let _e362 = s_1;
    if (_e362 > 0f) {
        let _e364 = s_1;
        let _e365 = (*NdotL_2);
        let _e366 = (*NdotV_3);
        local_1 = (_e364 / max(_e365, _e366));
    } else {
        local_1 = 0f;
    }
    let _e369 = local_1;
    stinv = _e369;
    let _e370 = (*roughness_5);
    param_39 = _e370;
    let _e371 = mx_square_u0028_f1_u003b((&param_39));
    sigma2_ = _e371;
    let _e372 = sigma2_;
    let _e373 = sigma2_;
    A_2 = (1f - (0.5f * (_e372 / (_e373 + 0.33f))));
    let _e378 = sigma2_;
    let _e380 = sigma2_;
    B_1 = ((0.45f * _e378) / (_e380 + 0.09f));
    let _e383 = A_2;
    let _e384 = B_1;
    let _e385 = stinv;
    return (_e383 + (_e384 * _e385));
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

    let _e367 = (*LdotV_1);
    let _e368 = (*NdotL_3);
    let _e369 = (*NdotV_4);
    s_2 = (_e367 - (_e368 * _e369));
    let _e372 = s_2;
    if (_e372 > 0f) {
        let _e374 = s_2;
        let _e375 = (*NdotL_3);
        let _e376 = (*NdotV_4);
        local_2 = (_e374 / max(_e375, _e376));
    } else {
        let _e379 = s_2;
        local_2 = _e379;
    }
    let _e380 = local_2;
    stinv_1 = _e380;
    let _e381 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e381)));
    let _e385 = (*color_4);
    let _e386 = A_3;
    let _e388 = (*roughness_6);
    let _e389 = stinv_1;
    lobeSingleScatter = ((_e385 * _e386) * (1f + (_e388 * _e389)));
    let _e393 = (*NdotV_4);
    param_40 = _e393;
    let _e394 = (*roughness_6);
    param_41 = _e394;
    let _e395 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_40), (&param_41));
    dirAlbedoV = _e395;
    let _e396 = (*NdotL_3);
    param_42 = _e396;
    let _e397 = (*roughness_6);
    param_43 = _e397;
    let _e398 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_42), (&param_43));
    dirAlbedoL = _e398;
    let _e399 = (*roughness_6);
    param_44 = _e399;
    let _e400 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_44));
    avgAlbedo_1 = _e400;
    let _e401 = (*color_4);
    param_45 = _e401;
    let _e402 = mx_square_u0028_vf3_u003b((&param_45));
    let _e403 = avgAlbedo_1;
    let _e405 = (*color_4);
    let _e406 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e402 * _e403) / (vec3<f32>(1f, 1f, 1f) - (_e405 * max(0f, (1f - _e406)))));
    let _e412 = colorMultiScatter_1;
    let _e413 = dirAlbedoV;
    let _e417 = dirAlbedoL;
    let _e421 = avgAlbedo_1;
    lobeMultiScatter = (((_e412 * max(0.00000001f, (1f - _e413))) * max(0.00000001f, (1f - _e417))) / vec3(max(0.00000001f, (1f - _e421))));
    let _e426 = lobeSingleScatter;
    let _e427 = lobeMultiScatter;
    return (_e426 + _e427);
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
    let _e381 = (*weight_2);
    if (_e381 < 0.00000001f) {
        return;
    }
    let _e384 = (*closureData_9).V;
    V_3 = _e384;
    let _e386 = (*closureData_9).L;
    L_4 = _e386;
    let _e387 = (*N_7);
    param_46 = _e387;
    let _e388 = V_3;
    param_47 = _e388;
    let _e389 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_46), (&param_47));
    (*N_7) = _e389;
    let _e390 = (*N_7);
    let _e391 = V_3;
    NdotV_5 = clamp(dot(_e390, _e391), 0.00000001f, 1f);
    let _e395 = (*closureData_9).closureType;
    if (_e395 == 1i) {
        let _e397 = (*N_7);
        let _e398 = L_4;
        NdotL_4 = clamp(dot(_e397, _e398), 0.00000001f, 1f);
        let _e401 = L_4;
        let _e402 = V_3;
        LdotV_2 = clamp(dot(_e401, _e402), 0.00000001f, 1f);
        let _e405 = (*energy_compensation);
        if _e405 {
            let _e406 = NdotV_5;
            param_48 = _e406;
            let _e407 = NdotL_4;
            param_49 = _e407;
            let _e408 = LdotV_2;
            param_50 = _e408;
            let _e409 = (*roughness_7);
            param_51 = _e409;
            let _e410 = (*color_5);
            param_52 = _e410;
            let _e411 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_48), (&param_49), (&param_50), (&param_51), (&param_52));
            local_3 = _e411;
        } else {
            let _e412 = NdotV_5;
            param_53 = _e412;
            let _e413 = NdotL_4;
            param_54 = _e413;
            let _e414 = LdotV_2;
            param_55 = _e414;
            let _e415 = (*roughness_7);
            param_56 = _e415;
            let _e416 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_53), (&param_54), (&param_55), (&param_56));
            let _e417 = (*color_5);
            local_3 = (_e417 * _e416);
        }
        let _e419 = local_3;
        diffuse = _e419;
        let _e420 = diffuse;
        let _e422 = (*closureData_9).occlusion;
        let _e424 = (*weight_2);
        let _e426 = NdotL_4;
        (*bsdf_2).response = ((((_e420 * _e422) * _e424) * _e426) * 0.31830987f);
    } else {
        let _e431 = (*closureData_9).closureType;
        if (_e431 == 3i) {
            let _e433 = (*energy_compensation);
            if _e433 {
                let _e434 = NdotV_5;
                param_57 = _e434;
                let _e435 = (*roughness_7);
                param_58 = _e435;
                let _e436 = (*color_5);
                param_59 = _e436;
                let _e437 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_57), (&param_58), (&param_59));
                local_4 = _e437;
            } else {
                let _e438 = NdotV_5;
                param_60 = _e438;
                let _e439 = (*roughness_7);
                param_61 = _e439;
                let _e440 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_60), (&param_61));
                let _e441 = (*color_5);
                local_4 = (_e441 * _e440);
            }
            let _e443 = local_4;
            diffuse_1 = _e443;
            let _e444 = (*N_7);
            param_62 = _e444;
            let _e445 = mx_environment_irradiance_u0028_vf3_u003b((&param_62));
            Li_3 = _e445;
            let _e446 = Li_3;
            let _e447 = diffuse_1;
            let _e449 = (*weight_2);
            (*bsdf_2).response = ((_e446 * _e447) * _e449);
        }
    }
    return;
}

fn mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_10: ptr<function, ClosureData>, top_1: ptr<function, BSDF>, base_2: ptr<function, VDF>, result_7: ptr<function, BSDF>) {
    let _e351 = (*top_1).response;
    let _e353 = (*base_2).throughput;
    (*result_7).response = (_e351 * _e353);
    let _e357 = (*top_1).throughput;
    let _e359 = (*base_2).throughput;
    (*result_7).throughput = (_e357 * _e359);
    return;
}

fn mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b(closureData_11: ptr<function, ClosureData>, absorption: ptr<function, vec3<f32>>, scattering: ptr<function, vec3<f32>>, anisotropy_1: ptr<function, f32>, vdf: ptr<function, VDF>) {
    let _e352 = (*closureData_11).closureType;
    if (_e352 == 2i) {
        (*vdf).response = vec3<f32>(0f, 0f, 0f);
        let _e355 = (*absorption);
        (*vdf).throughput = exp(-(_e355));
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_12: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_8: ptr<function, BSDF>) {
    var weight_3: f32;

    let _e351 = (*in2_2);
    weight_3 = clamp(_e351, 0f, 1f);
    let _e354 = (*in1_2).response;
    let _e355 = weight_3;
    (*result_8).response = (_e354 * _e355);
    let _e359 = (*in1_2).throughput;
    (*result_8).throughput = _e359;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_13: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_9: ptr<function, BSDF>) {
    let _e351 = (*in1_3).response;
    let _e353 = (*in2_3).response;
    (*result_9).response = (_e351 + _e353);
    let _e357 = (*in1_3).throughput;
    let _e359 = (*in2_3).throughput;
    (*result_9).throughput = max(((_e357 + _e359) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_6: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_63: f32;
    var lambdaL: f32;
    var param_64: f32;
    var lambdaV: f32;
    var param_65: f32;

    let _e355 = (*alpha);
    param_63 = _e355;
    let _e356 = mx_square_u0028_f1_u003b((&param_63));
    alpha2_ = _e356;
    let _e357 = alpha2_;
    let _e358 = alpha2_;
    let _e360 = (*NdotL_5);
    param_64 = _e360;
    let _e361 = mx_square_u0028_f1_u003b((&param_64));
    lambdaL = sqrt((_e357 + ((1f - _e358) * _e361)));
    let _e365 = alpha2_;
    let _e366 = alpha2_;
    let _e368 = (*NdotV_6);
    param_65 = _e368;
    let _e369 = mx_square_u0028_f1_u003b((&param_65));
    lambdaV = sqrt((_e365 + ((1f - _e366) * _e369)));
    let _e373 = (*NdotL_5);
    let _e375 = (*NdotV_6);
    let _e377 = lambdaL;
    let _e378 = (*NdotV_6);
    let _e380 = lambdaV;
    let _e381 = (*NdotL_5);
    return (((2f * _e373) * _e375) / ((_e377 * _e378) + (_e380 * _e381)));
}

fn mx_pow6_u0028_f1_u003b(x_4: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_66: f32;
    var param_67: f32;

    let _e350 = (*x_4);
    param_66 = _e350;
    let _e351 = mx_square_u0028_f1_u003b((&param_66));
    x2_ = _e351;
    let _e352 = x2_;
    param_67 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_67));
    let _e354 = x2_;
    return (_e353 * _e354);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_3: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_5: f32;
    var a_1: vec3<f32>;
    var param_68: f32;

    let _e351 = (*cosTheta_3);
    x_5 = clamp(_e351, 0f, 1f);
    let _e354 = (*fd).F0_;
    let _e356 = (*fd).F90_;
    let _e358 = (*fd).exponent;
    let _e363 = (*fd).F82_;
    a_1 = ((mix(_e354, _e356, vec3(pow(0.85714287f, _e358))) * (vec3<f32>(1f, 1f, 1f) - _e363)) * 17.651384f);
    let _e368 = (*fd).F0_;
    let _e370 = (*fd).F90_;
    let _e371 = x_5;
    let _e374 = (*fd).exponent;
    let _e378 = a_1;
    let _e379 = x_5;
    let _e381 = x_5;
    param_68 = (1f - _e381);
    let _e383 = mx_pow6_u0028_f1_u003b((&param_68));
    return (mix(_e368, _e370, vec3(pow((1f - _e371), _e374))) - ((_e378 * _e379) * _e383));
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

    let _e363 = (*cosTheta_4);
    param_69 = clamp(_e363, 0f, 1f);
    let _e365 = mx_square_u0028_f1_u003b((&param_69));
    cosTheta2_ = _e365;
    let _e366 = cosTheta2_;
    sinTheta2_ = (1f - _e366);
    let _e368 = (*n);
    let _e369 = (*n);
    n2_ = (_e368 * _e369);
    let _e371 = (*k);
    let _e372 = (*k);
    k2_ = (_e371 * _e372);
    let _e374 = n2_;
    let _e375 = k2_;
    let _e377 = sinTheta2_;
    t0_ = ((_e374 - _e375) - vec3(_e377));
    let _e380 = t0_;
    let _e381 = t0_;
    let _e383 = n2_;
    let _e385 = k2_;
    a2plusb2_ = sqrt(((_e380 * _e381) + ((_e383 * 4f) * _e385)));
    let _e389 = a2plusb2_;
    let _e390 = cosTheta2_;
    t1_ = (_e389 + vec3(_e390));
    let _e393 = a2plusb2_;
    let _e394 = t0_;
    a_2 = sqrt(max(((_e393 + _e394) * 0.5f), vec3(0f)));
    let _e400 = a_2;
    let _e402 = (*cosTheta_4);
    t2_ = ((_e400 * 2f) * _e402);
    let _e404 = t1_;
    let _e405 = t2_;
    let _e407 = t1_;
    let _e408 = t2_;
    (*Rs) = ((_e404 - _e405) / (_e407 + _e408));
    let _e411 = cosTheta2_;
    let _e412 = a2plusb2_;
    let _e414 = sinTheta2_;
    let _e415 = sinTheta2_;
    t3_ = ((_e412 * _e411) + vec3((_e414 * _e415)));
    let _e419 = t2_;
    let _e420 = sinTheta2_;
    t4_ = (_e419 * _e420);
    let _e422 = (*Rs);
    let _e423 = t3_;
    let _e424 = t4_;
    let _e427 = t3_;
    let _e428 = t4_;
    (*Rp) = ((_e422 * (_e423 - _e424)) / (_e427 + _e428));
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

    let _e356 = (*cosTheta_5);
    param_70 = _e356;
    let _e357 = (*n_1);
    param_71 = _e357;
    let _e358 = (*k_1);
    param_72 = _e358;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_70), (&param_71), (&param_72), (&param_73), (&param_74));
    let _e359 = param_73;
    Rp_1 = _e359;
    let _e360 = param_74;
    Rs_1 = _e360;
    let _e361 = Rp_1;
    let _e362 = Rs_1;
    return ((_e361 + _e362) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_6: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_75: f32;
    var param_76: f32;

    let _e353 = (*cosTheta_6);
    c_1 = _e353;
    let _e354 = (*ior);
    let _e355 = (*ior);
    let _e357 = c_1;
    let _e358 = c_1;
    g2_ = (((_e354 * _e355) + (_e357 * _e358)) - 1f);
    let _e362 = g2_;
    if (_e362 < 0f) {
        return 1f;
    }
    let _e364 = g2_;
    g = sqrt(_e364);
    let _e366 = g;
    let _e367 = c_1;
    let _e369 = g;
    let _e370 = c_1;
    param_75 = ((_e366 - _e367) / (_e369 + _e370));
    let _e373 = mx_square_u0028_f1_u003b((&param_75));
    let _e375 = g;
    let _e376 = c_1;
    let _e378 = c_1;
    let _e381 = g;
    let _e382 = c_1;
    let _e384 = c_1;
    param_76 = ((((_e375 + _e376) * _e378) - 1f) / (((_e381 - _e382) * _e384) + 1f));
    let _e388 = mx_square_u0028_f1_u003b((&param_76));
    return ((0.5f * _e373) * (1f + _e388));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e348 = (*m_1);
    let _e349 = (*v_2);
    return (_e348 * _e349);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e353 = (*opd);
    phase = (6.2831855f * _e353);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e355 = val;
    let _e356 = var_;
    let _e360 = pos;
    let _e361 = phase;
    let _e363 = (*shift);
    let _e367 = var_;
    let _e369 = phase;
    let _e371 = phase;
    xyz = (((_e355 * sqrt((_e356 * 6.2831855f))) * cos(((_e360 * _e361) + _e363))) * exp(((-(_e367) * _e369) * _e371)));
    let _e375 = phase;
    let _e378 = (*shift)[0u];
    let _e382 = phase;
    let _e384 = phase;
    let _e389 = xyz[0u];
    xyz[0u] = (_e389 + ((0.00000001644083f * cos(((2239900f * _e375) + _e378))) * exp(((-4528200000f * _e382) * _e384))));
    let _e392 = xyz;
    return (_e392 / vec3(0.00000010685f));
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

    let _e361 = (*kappa2_);
    let _e362 = (*eta2_);
    k2_1 = (_e361 / _e362);
    let _e364 = (*cosTheta_7);
    let _e365 = (*cosTheta_7);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e364 * _e365)));
    let _e369 = (*eta2_);
    let _e370 = (*eta2_);
    let _e372 = k2_1;
    let _e373 = k2_1;
    let _e377 = (*eta1_);
    let _e378 = (*eta1_);
    let _e380 = sinThetaSqr;
    A_4 = (((_e369 * _e370) * (vec3<f32>(1f, 1f, 1f) - (_e372 * _e373))) - (_e380 * (_e377 * _e378)));
    let _e383 = A_4;
    let _e384 = A_4;
    let _e386 = (*eta2_);
    let _e388 = (*eta2_);
    let _e390 = k2_1;
    param_77 = (((_e386 * 2f) * _e388) * _e390);
    let _e392 = mx_square_u0028_vf3_u003b((&param_77));
    B_2 = sqrt(((_e383 * _e384) + _e392));
    let _e395 = A_4;
    let _e396 = B_2;
    U = sqrt(((_e395 + _e396) / vec3(2f)));
    let _e401 = B_2;
    let _e402 = A_4;
    V_4 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e401 - _e402) / vec3(2f))));
    let _e408 = (*eta1_);
    let _e410 = V_4;
    let _e412 = (*cosTheta_7);
    let _e414 = U;
    let _e415 = U;
    let _e417 = V_4;
    let _e418 = V_4;
    let _e421 = (*eta1_);
    let _e422 = (*cosTheta_7);
    param_78 = (_e421 * _e422);
    let _e424 = mx_square_u0028_f1_u003b((&param_78));
    (*phiS) = atan2(((_e410 * (2f * _e408)) * _e412), (((_e414 * _e415) + (_e417 * _e418)) - vec3(_e424)));
    let _e428 = (*eta1_);
    let _e430 = (*eta2_);
    let _e432 = (*eta2_);
    let _e434 = (*cosTheta_7);
    let _e436 = k2_1;
    let _e438 = U;
    let _e440 = k2_1;
    let _e441 = k2_1;
    let _e444 = V_4;
    let _e448 = (*eta2_);
    let _e449 = (*eta2_);
    let _e451 = k2_1;
    let _e452 = k2_1;
    let _e456 = (*cosTheta_7);
    param_79 = (((_e448 * _e449) * (vec3<f32>(1f, 1f, 1f) + (_e451 * _e452))) * _e456);
    let _e458 = mx_square_u0028_vf3_u003b((&param_79));
    let _e459 = (*eta1_);
    let _e460 = (*eta1_);
    let _e462 = U;
    let _e463 = U;
    let _e465 = V_4;
    let _e466 = V_4;
    (*phiP) = atan2(((((_e430 * (2f * _e428)) * _e432) * _e434) * (((_e436 * 2f) * _e438) - ((vec3<f32>(1f, 1f, 1f) - (_e440 * _e441)) * _e444))), (_e458 - (((_e462 * _e463) + (_e465 * _e466)) * (_e459 * _e460))));
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

    let _e358 = (*cosTheta_8);
    param_80 = clamp(_e358, 0f, 1f);
    let _e360 = mx_square_u0028_f1_u003b((&param_80));
    cosTheta2_1 = _e360;
    let _e361 = cosTheta2_1;
    sinTheta2_1 = (1f - _e361);
    let _e363 = (*ior_1);
    let _e364 = (*ior_1);
    let _e366 = sinTheta2_1;
    t0_1 = max(((_e363 * _e364) - _e366), 0f);
    let _e369 = t0_1;
    let _e370 = cosTheta2_1;
    t1_1 = (_e369 + _e370);
    let _e372 = t0_1;
    let _e375 = (*cosTheta_8);
    t2_1 = ((2f * sqrt(_e372)) * _e375);
    let _e377 = t1_1;
    let _e378 = t2_1;
    let _e380 = t1_1;
    let _e381 = t2_1;
    Rs_2 = ((_e377 - _e378) / (_e380 + _e381));
    let _e384 = cosTheta2_1;
    let _e385 = t0_1;
    let _e387 = sinTheta2_1;
    let _e388 = sinTheta2_1;
    t3_1 = ((_e384 * _e385) + (_e387 * _e388));
    let _e391 = t2_1;
    let _e392 = sinTheta2_1;
    t4_1 = (_e391 * _e392);
    let _e394 = Rs_2;
    let _e395 = t3_1;
    let _e396 = t4_1;
    let _e399 = t3_1;
    let _e400 = t4_1;
    Rp_2 = ((_e394 * (_e395 - _e396)) / (_e399 + _e400));
    let _e403 = Rp_2;
    let _e404 = Rs_2;
    return vec2<f32>(_e403, _e404);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e348 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e348, vec3(0.01f), vec3(0.99f)));
    let _e353 = sqrtF0_;
    let _e355 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e353) / (vec3<f32>(1f, 1f, 1f) - _e355));
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
    let _e402 = (*fd_1).tf_ior;
    let _e403 = eta1_1;
    eta2_1 = max(_e402, _e403);
    let _e406 = (*fd_1).model;
    if (_e406 == 2i) {
        let _e409 = (*fd_1).F0_;
        param_81 = _e409;
        let _e410 = mx_f0_to_ior_u0028_vf3_u003b((&param_81));
        local_5 = _e410;
    } else {
        let _e412 = (*fd_1).ior;
        local_5 = _e412;
    }
    let _e413 = local_5;
    eta3_ = _e413;
    let _e415 = (*fd_1).model;
    if (_e415 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e418 = (*fd_1).extinction;
        local_6 = _e418;
    }
    let _e419 = local_6;
    kappa3_ = _e419;
    let _e420 = (*cosTheta_9);
    param_82 = _e420;
    let _e421 = mx_square_u0028_f1_u003b((&param_82));
    let _e423 = eta1_1;
    let _e424 = eta2_1;
    param_83 = (_e423 / _e424);
    let _e426 = mx_square_u0028_f1_u003b((&param_83));
    cosThetaT = sqrt((1f - ((1f - _e421) * _e426)));
    let _e430 = eta2_1;
    let _e431 = eta1_1;
    let _e433 = (*cosTheta_9);
    param_84 = _e433;
    param_85 = (_e430 / _e431);
    let _e434 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
    R12_ = _e434;
    let _e435 = cosThetaT;
    if (_e435 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e437 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e437);
    let _e440 = (*fd_1).model;
    if (_e440 == 2i) {
        let _e442 = cosThetaT;
        param_86 = _e442;
        let _e443 = (*fd_1);
        param_87 = _e443;
        let _e444 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_86), (&param_87));
        f_1 = _e444;
        let _e445 = f_1;
        R23p = (_e445 * 0.5f);
        let _e447 = f_1;
        R23s = (_e447 * 0.5f);
    } else {
        let _e449 = eta3_;
        let _e450 = eta2_1;
        let _e453 = kappa3_;
        let _e454 = eta2_1;
        let _e457 = cosThetaT;
        param_88 = _e457;
        param_89 = (_e449 / vec3(_e450));
        param_90 = (_e453 / vec3(_e454));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_88), (&param_89), (&param_90), (&param_91), (&param_92));
        let _e458 = param_91;
        R23p = _e458;
        let _e459 = param_92;
        R23s = _e459;
    }
    let _e460 = eta2_1;
    let _e461 = eta1_1;
    cosB = cos(atan((_e460 / _e461)));
    let _e465 = (*cosTheta_9);
    let _e466 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e465 < _e466)), 3.1415927f);
    let _e471 = (*fd_1).model;
    if (_e471 == 2i) {
        let _e474 = eta3_[0u];
        let _e475 = eta2_1;
        let _e479 = eta3_[1u];
        let _e480 = eta2_1;
        let _e484 = eta3_[2u];
        let _e485 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e474 < _e475)), select(0f, 3.1415927f, (_e479 < _e480)), select(0f, 3.1415927f, (_e484 < _e485)));
        let _e489 = phi23p;
        phi23s = _e489;
    } else {
        let _e490 = cosThetaT;
        param_93 = _e490;
        let _e491 = eta2_1;
        param_94 = _e491;
        let _e492 = eta3_;
        param_95 = _e492;
        let _e493 = kappa3_;
        param_96 = _e493;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_93), (&param_94), (&param_95), (&param_96), (&param_97), (&param_98));
        let _e494 = param_97;
        phi23p = _e494;
        let _e495 = param_98;
        phi23s = _e495;
    }
    let _e497 = R12_[0u];
    let _e498 = R23p;
    r123p = max(sqrt((_e498 * _e497)), vec3(0f));
    let _e504 = R12_[1u];
    let _e505 = R23s;
    r123s = max(sqrt((_e505 * _e504)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e511 = (*fd_1).tf_thickness;
    distMeters = (_e511 * 0.000000001f);
    let _e513 = eta2_1;
    let _e515 = cosThetaT;
    let _e517 = distMeters;
    opd_1 = (((2f * _e513) * _e515) * _e517);
    let _e520 = T121_[0u];
    param_99 = _e520;
    let _e521 = mx_square_u0028_f1_u003b((&param_99));
    let _e522 = R23p;
    let _e525 = R12_[0u];
    let _e526 = R23p;
    Rs_3 = ((_e522 * _e521) / (vec3<f32>(1f, 1f, 1f) - (_e526 * _e525)));
    let _e531 = R12_[0u];
    let _e532 = Rs_3;
    let _e535 = I;
    I = (_e535 + (vec3(_e531) + _e532));
    let _e537 = Rs_3;
    let _e539 = T121_[0u];
    Cm = (_e537 - vec3(_e539));
    m_2 = 1i;
    loop {
        let _e542 = m_2;
        if (_e542 <= 2i) {
            let _e544 = r123p;
            let _e545 = Cm;
            Cm = (_e545 * _e544);
            let _e547 = m_2;
            let _e549 = opd_1;
            let _e551 = m_2;
            let _e553 = phi23p;
            let _e555 = phi21_[0u];
            param_100 = (f32(_e547) * _e549);
            param_101 = ((_e553 + vec3(_e555)) * f32(_e551));
            let _e559 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_100), (&param_101));
            Sm = (_e559 * 2f);
            let _e561 = Cm;
            let _e562 = Sm;
            let _e564 = I;
            I = (_e564 + (_e561 * _e562));
            continue;
        } else {
            break;
        }
        continuing {
            let _e566 = m_2;
            m_2 = (_e566 + 1i);
        }
    }
    let _e569 = T121_[1u];
    param_102 = _e569;
    let _e570 = mx_square_u0028_f1_u003b((&param_102));
    let _e571 = R23s;
    let _e574 = R12_[1u];
    let _e575 = R23s;
    Rp_3 = ((_e571 * _e570) / (vec3<f32>(1f, 1f, 1f) - (_e575 * _e574)));
    let _e580 = R12_[1u];
    let _e581 = Rp_3;
    let _e584 = I;
    I = (_e584 + (vec3(_e580) + _e581));
    let _e586 = Rp_3;
    let _e588 = T121_[1u];
    Cm = (_e586 - vec3(_e588));
    m_3 = 1i;
    loop {
        let _e591 = m_3;
        if (_e591 <= 2i) {
            let _e593 = r123s;
            let _e594 = Cm;
            Cm = (_e594 * _e593);
            let _e596 = m_3;
            let _e598 = opd_1;
            let _e600 = m_3;
            let _e602 = phi23s;
            let _e604 = phi21_[1u];
            param_103 = (f32(_e596) * _e598);
            param_104 = ((_e602 + vec3(_e604)) * f32(_e600));
            let _e608 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_103), (&param_104));
            Sm = (_e608 * 2f);
            let _e610 = Cm;
            let _e611 = Sm;
            let _e613 = I;
            I = (_e613 + (_e610 * _e611));
            continue;
        } else {
            break;
        }
        continuing {
            let _e615 = m_3;
            m_3 = (_e615 + 1i);
        }
    }
    let _e617 = I;
    I = (_e617 * 0.5f);
    param_105 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e619 = I;
    param_106 = _e619;
    let _e620 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_105), (&param_106));
    I = clamp(_e620, vec3(0f), vec3(1f));
    let _e624 = I;
    return _e624;
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

    let _e358 = (*fd_2).airy;
    if _e358 {
        let _e359 = (*cosTheta_10);
        param_107 = _e359;
        let _e360 = (*fd_2);
        param_108 = _e360;
        let _e361 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_107), (&param_108));
        return _e361;
    } else {
        let _e363 = (*fd_2).model;
        if (_e363 == 0i) {
            let _e365 = (*cosTheta_10);
            param_109 = _e365;
            let _e368 = (*fd_2).ior[0u];
            param_110 = _e368;
            let _e369 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_109), (&param_110));
            return vec3(_e369);
        } else {
            let _e372 = (*fd_2).model;
            if (_e372 == 1i) {
                let _e374 = (*cosTheta_10);
                param_111 = _e374;
                let _e376 = (*fd_2).ior;
                param_112 = _e376;
                let _e378 = (*fd_2).extinction;
                param_113 = _e378;
                let _e379 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_111), (&param_112), (&param_113));
                return _e379;
            } else {
                let _e380 = (*cosTheta_10);
                param_114 = _e380;
                let _e381 = (*fd_2);
                param_115 = _e381;
                let _e382 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_114), (&param_115));
                return _e382;
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

    let _e354 = (*dir_2);
    let _e359 = (*transform_1);
    param_116 = _e359;
    param_117 = vec4<f32>(_e354.x, _e354.y, _e354.z, 0f);
    let _e360 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_116), (&param_117));
    envDir_1 = normalize(_e360.xyz);
    let _e363 = envDir_1;
    param_118 = _e363;
    let _e364 = mx_latlong_projection_u0028_vf3_u003b((&param_118));
    uv_2 = _e364;
    let _e365 = uv_2;
    let _e366 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e365, 0.0);
    return _e366.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_119: f32;

    let _e353 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e353 - 1.5f);
    let _e356 = (*dir_3)[1u];
    param_119 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_119));
    distortion = sqrt((1f - _e357));
    let _e360 = effectiveMaxMipLevel;
    let _e361 = (*envSamples);
    let _e363 = (*pdf);
    let _e365 = distortion;
    return max((_e360 - (0.5f * log2(((f32(_e361) * _e363) * _e365)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_120: f32;
    var param_121: f32;

    let _e352 = (*H);
    let _e354 = (*alpha_1);
    He = (_e352.xy / _e354);
    let _e356 = He;
    let _e357 = He;
    let _e360 = (*H)[2u];
    param_120 = _e360;
    let _e361 = mx_square_u0028_f1_u003b((&param_120));
    denom_1 = (dot(_e356, _e357) + _e361);
    let _e364 = (*alpha_1)[0u];
    let _e367 = (*alpha_1)[1u];
    let _e369 = denom_1;
    param_121 = _e369;
    let _e370 = mx_square_u0028_f1_u003b((&param_121));
    return (1f / (((3.1415927f * _e364) * _e367) * _e370));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_7: ptr<function, f32>) -> f32 {
    var param_122: vec3<f32>;
    var param_123: vec2<f32>;

    let _e352 = (*H_1);
    param_122 = _e352;
    let _e353 = (*alpha_2);
    param_123 = _e353;
    let _e354 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_122), (&param_123));
    let _e355 = (*G1V);
    let _e357 = (*NdotV_7);
    return ((_e354 * _e355) / (4f * _e357));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e350 = (*R_1);
    let _e351 = (*N_8);
    let _e352 = (*ior_2);
    (*R_1) = refract(_e350, _e351, (1f / _e352));
    let _e355 = (*R_1);
    let _e356 = (*R_1);
    let _e357 = (*N_8);
    let _e360 = (*N_8);
    N1_ = normalize(((_e355 * dot(_e356, _e357)) - (_e360 * 0.5f)));
    let _e364 = (*R_1);
    let _e365 = N1_;
    let _e366 = (*ior_2);
    return refract(_e364, _e365, _e366);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_5: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_6: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e356 = (*V_5);
    let _e358 = (*alpha_3);
    let _e359 = (_e356.xy * _e358);
    let _e361 = (*V_5)[2u];
    (*V_5) = normalize(vec3<f32>(_e359.x, _e359.y, _e361));
    let _e367 = (*Xi)[0u];
    phi = (6.2831855f * _e367);
    let _e370 = (*Xi)[1u];
    let _e373 = (*V_5)[2u];
    let _e377 = (*V_5)[2u];
    z = (((1f - _e370) * (1f + _e373)) - _e377);
    let _e379 = z;
    let _e380 = z;
    sinTheta = sqrt(clamp((1f - (_e379 * _e380)), 0f, 1f));
    let _e385 = sinTheta;
    let _e386 = phi;
    x_6 = (_e385 * cos(_e386));
    let _e389 = sinTheta;
    let _e390 = phi;
    y = (_e389 * sin(_e390));
    let _e393 = x_6;
    let _e394 = y;
    let _e395 = z;
    c_2 = vec3<f32>(_e393, _e394, _e395);
    let _e397 = c_2;
    let _e398 = (*V_5);
    H_2 = (_e397 + _e398);
    let _e400 = H_2;
    let _e402 = (*alpha_3);
    let _e403 = (_e400.xy * _e402);
    let _e405 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e403.x, _e403.y, max(_e405, 0f)));
    let _e411 = H_2;
    return _e411;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e347 = (*i_1);
    return fract(((f32(_e347) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_124: i32;

    let _e349 = (*i_2);
    let _e352 = (*numSamples);
    let _e355 = (*i_2);
    param_124 = _e355;
    let _e356 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_124));
    return vec2<f32>(((f32(_e349) + 0.5f) / f32(_e352)), _e356);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_11: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_125: f32;
    var tanTheta2_: f32;
    var param_126: f32;

    let _e352 = (*cosTheta_11);
    param_125 = _e352;
    let _e353 = mx_square_u0028_f1_u003b((&param_125));
    cosTheta2_2 = _e353;
    let _e354 = cosTheta2_2;
    let _e356 = cosTheta2_2;
    tanTheta2_ = ((1f - _e354) / _e356);
    let _e358 = (*alpha_4);
    param_126 = _e358;
    let _e359 = mx_square_u0028_f1_u003b((&param_126));
    let _e360 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e359 * _e360)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e348 = (*alpha_5)[0u];
    let _e350 = (*alpha_5)[1u];
    return sqrt((_e348 * _e350));
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

    let _e403 = (*X);
    let _e404 = (*X);
    let _e405 = (*N_9);
    let _e407 = (*N_9);
    (*X) = normalize((_e403 - (_e407 * dot(_e404, _e405))));
    let _e411 = (*N_9);
    let _e412 = (*X);
    Y = cross(_e411, _e412);
    let _e414 = (*X);
    let _e415 = Y;
    let _e416 = (*N_9);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e414.x, _e414.y, _e414.z), vec3<f32>(_e415.x, _e415.y, _e415.z), vec3<f32>(_e416.x, _e416.y, _e416.z));
    let _e430 = (*V_6);
    let _e431 = (*X);
    let _e433 = (*V_6);
    let _e434 = Y;
    let _e436 = (*V_6);
    let _e437 = (*N_9);
    (*V_6) = vec3<f32>(dot(_e430, _e431), dot(_e433, _e434), dot(_e436, _e437));
    let _e441 = (*V_6)[2u];
    NdotV_8 = clamp(_e441, 0.00000001f, 1f);
    let _e443 = (*alpha_6);
    param_127 = _e443;
    let _e444 = mx_average_alpha_u0028_vf2_u003b((&param_127));
    avgAlpha = _e444;
    let _e445 = NdotV_8;
    param_128 = _e445;
    let _e446 = avgAlpha;
    param_129 = _e446;
    let _e447 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_128), (&param_129));
    G1V_1 = _e447;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e448 = i_3;
        let _e449 = envRadianceSamples;
        if (_e448 < _e449) {
            let _e451 = i_3;
            param_130 = _e451;
            let _e452 = envRadianceSamples;
            param_131 = _e452;
            let _e453 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_130), (&param_131));
            Xi_1 = _e453;
            let _e454 = Xi_1;
            param_132 = _e454;
            let _e455 = (*V_6);
            param_133 = _e455;
            let _e456 = (*alpha_6);
            param_134 = _e456;
            let _e457 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_132), (&param_133), (&param_134));
            H_3 = _e457;
            let _e459 = (*fd_3).refraction;
            if _e459 {
                let _e460 = (*V_6);
                param_135 = -(_e460);
                let _e462 = H_3;
                param_136 = _e462;
                let _e465 = (*fd_3).ior[0u];
                param_137 = _e465;
                let _e466 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_135), (&param_136), (&param_137));
                local_7 = _e466;
            } else {
                let _e467 = (*V_6);
                let _e468 = H_3;
                local_7 = -(reflect(_e467, _e468));
            }
            let _e471 = local_7;
            L_5 = _e471;
            let _e473 = L_5[2u];
            NdotL_6 = clamp(_e473, 0.00000001f, 1f);
            let _e475 = (*V_6);
            let _e476 = H_3;
            VdotH = clamp(dot(_e475, _e476), 0.00000001f, 1f);
            let _e479 = tangentToWorld;
            param_138 = _e479;
            let _e480 = L_5;
            param_139 = _e480;
            let _e481 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_138), (&param_139));
            Lw = _e481;
            let _e482 = H_3;
            param_140 = _e482;
            let _e483 = (*alpha_6);
            param_141 = _e483;
            let _e484 = G1V_1;
            param_142 = _e484;
            let _e485 = NdotV_8;
            param_143 = _e485;
            let _e486 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_140), (&param_141), (&param_142), (&param_143));
            pdf_1 = _e486;
            let _e487 = Lw;
            param_144 = _e487;
            let _e488 = pdf_1;
            param_145 = _e488;
            param_146 = 0f;
            let _e489 = envRadianceSamples;
            param_147 = _e489;
            let _e490 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_144), (&param_145), (&param_146), (&param_147));
            lod_2 = _e490;
            let _e491 = mtlxEnvMatrix_u0028_();
            let _e492 = Lw;
            param_148 = _e492;
            param_149 = _e491;
            let _e493 = lod_2;
            param_150 = _e493;
            let _e494 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_148), (&param_149), (&param_150));
            sampleColor = _e494;
            let _e495 = VdotH;
            param_151 = _e495;
            let _e496 = (*fd_3);
            param_152 = _e496;
            let _e497 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_151), (&param_152));
            F = _e497;
            let _e498 = NdotL_6;
            param_153 = _e498;
            let _e499 = NdotV_8;
            param_154 = _e499;
            let _e500 = avgAlpha;
            param_155 = _e500;
            let _e501 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_153), (&param_154), (&param_155));
            G_1 = _e501;
            let _e503 = (*fd_3).refraction;
            if _e503 {
                let _e504 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e504);
            } else {
                let _e506 = F;
                let _e507 = G_1;
                local_8 = (_e506 * _e507);
            }
            let _e509 = local_8;
            FG = _e509;
            let _e510 = sampleColor;
            let _e511 = FG;
            let _e513 = radiance;
            radiance = (_e513 + (_e510 * _e511));
            continue;
        } else {
            break;
        }
        continuing {
            let _e515 = i_3;
            i_3 = (_e515 + 1i);
        }
    }
    let _e517 = G1V_1;
    let _e518 = envRadianceSamples;
    let _e521 = radiance;
    radiance = (_e521 / vec3((_e517 * f32(_e518))));
    let _e524 = radiance;
    let _e527 = unnamed.skyPower;
    return (select(_e524, vec3<f32>(0f, 0f, 0f), false) * _e527);
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
        let _e361 = (*tint_1);
        param_156 = _e361;
        let _e362 = mx_square_u0028_vf3_u003b((&param_156));
        (*tint_1) = _e362;
    }
    let _e363 = (*N_10);
    param_157 = _e363;
    let _e364 = (*V_7);
    param_158 = _e364;
    let _e365 = (*X_1);
    param_159 = _e365;
    let _e366 = (*alpha_7);
    param_160 = _e366;
    let _e367 = (*distribution_1);
    param_161 = _e367;
    let _e368 = (*fd_4);
    param_162 = _e368;
    let _e369 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_157), (&param_158), (&param_159), (&param_160), (&param_161), (&param_162));
    let _e370 = (*tint_1);
    return (_e369 * _e370);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_2: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e348 = (*F0_2);
    sqrtF0_1 = sqrt(clamp(_e348, 0.01f, 0.99f));
    let _e351 = sqrtF0_1;
    let _e353 = sqrtF0_1;
    return ((1f + _e351) / (1f - _e353));
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

    let _e358 = (*NdotV_9);
    x_7 = _e358;
    let _e359 = (*alpha_8);
    y_1 = _e359;
    let _e360 = x_7;
    param_163 = _e360;
    let _e361 = mx_square_u0028_f1_u003b((&param_163));
    x2_1 = _e361;
    let _e362 = y_1;
    param_164 = _e362;
    let _e363 = mx_square_u0028_f1_u003b((&param_164));
    y2_ = _e363;
    let _e364 = x_7;
    let _e367 = y_1;
    let _e370 = x_7;
    let _e372 = y_1;
    let _e375 = x2_1;
    let _e378 = y2_;
    let _e381 = x2_1;
    let _e383 = y_1;
    let _e386 = x_7;
    let _e388 = y2_;
    let _e391 = x2_1;
    let _e393 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e364)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e367)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e370) * _e372)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e375)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e378)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e381) * _e383)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e386) * _e388)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e391) * _e393));
    let _e396 = r_1;
    let _e398 = r_1;
    AB = clamp((_e396.xy / _e398.zw), vec2(0f), vec2(1f));
    let _e404 = (*F0_3);
    let _e406 = AB[0u];
    let _e408 = (*F90_1);
    let _e410 = AB[1u];
    return ((_e404 * _e406) + (_e408 * _e410));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_10: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_165: f32;
    var param_166: f32;
    var param_167: vec3<f32>;
    var param_168: vec3<f32>;

    let _e354 = (*NdotV_10);
    param_165 = _e354;
    let _e355 = (*alpha_9);
    param_166 = _e355;
    let _e356 = (*F0_4);
    param_167 = _e356;
    let _e357 = (*F90_2);
    param_168 = _e357;
    let _e358 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_165), (&param_166), (&param_167), (&param_168));
    return _e358;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_11: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_5: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_169: f32;
    var param_170: f32;
    var param_171: vec3<f32>;
    var param_172: vec3<f32>;

    let _e354 = (*F0_5);
    let _e356 = (*F90_3);
    let _e358 = (*NdotV_11);
    param_169 = _e358;
    let _e359 = (*alpha_10);
    param_170 = _e359;
    param_171 = vec3(_e354);
    param_172 = vec3(_e356);
    let _e360 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_169), (&param_170), (&param_171), (&param_172));
    return _e360.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_6: vec3<f32>;
    var param_173: f32;
    var param_174: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3416_: bool;

    param_173 = 1f;
    let _e352 = (*fd_5);
    param_174 = _e352;
    let _e353 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_173), (&param_174));
    F0_6 = _e353;
    let _e355 = (*fd_5).model;
    let _e356 = (_e355 == 2i);
    phi_3416_ = _e356;
    if _e356 {
        let _e358 = (*fd_5).airy;
        phi_3416_ = !(_e358);
    }
    let _e361 = phi_3416_;
    if _e361 {
        let _e363 = (*fd_5).F90_;
        local_9 = _e363;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e364 = local_9;
    F90_4 = _e364;
    let _e365 = F0_6;
    let _e366 = F90_4;
    let _e367 = F0_6;
    return (_e365 + ((_e366 - _e367) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_12: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_175: FresnelData;
    var Ess: f32;
    var param_176: f32;
    var param_177: f32;
    var param_178: f32;
    var param_179: f32;

    let _e356 = (*fd_6);
    param_175 = _e356;
    let _e357 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_175));
    Fss = _e357;
    let _e358 = (*NdotV_12);
    param_176 = _e358;
    let _e359 = (*alpha_11);
    param_177 = _e359;
    param_178 = 1f;
    param_179 = 1f;
    let _e360 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_176), (&param_177), (&param_178), (&param_179));
    Ess = _e360;
    let _e361 = Fss;
    let _e362 = Ess;
    let _e365 = Ess;
    return (vec3(1f) + ((_e361 * (1f - _e362)) / vec3(_e365)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_7: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_5: ptr<function, vec3<f32>>, exponent_2: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e354 = (*tf_thickness);
    fd_7.airy = (_e354 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e359 = (*F0_7);
    fd_7.F0_ = _e359;
    let _e361 = (*F82_);
    fd_7.F82_ = _e361;
    let _e363 = (*F90_5);
    fd_7.F90_ = _e363;
    let _e365 = (*exponent_2);
    fd_7.exponent = _e365;
    let _e367 = (*tf_thickness);
    fd_7.tf_thickness = _e367;
    let _e369 = (*tf_ior);
    fd_7.tf_ior = _e369;
    fd_7.refraction = false;
    let _e372 = fd_7;
    return _e372;
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
    var phi_5426_: bool;

    let _e440 = (*weight_4);
    if (_e440 < 0.00000001f) {
        return;
    }
    let _e443 = (*closureData_14).closureType;
    let _e445 = (*scatter_mode);
    if ((_e443 != 2i) && (_e445 == 1i)) {
        return;
    }
    let _e449 = (*closureData_14).V;
    V_8 = _e449;
    let _e451 = (*closureData_14).L;
    L_6 = _e451;
    let _e452 = (*retroreflective);
    phi_5426_ = _e452;
    if _e452 {
        let _e454 = (*closureData_14).closureType;
        phi_5426_ = (_e454 != 2i);
    }
    let _e457 = phi_5426_;
    if _e457 {
        let _e458 = V_8;
        let _e460 = (*N_11);
        V_8 = reflect(-(_e458), _e460);
    }
    let _e462 = (*N_11);
    param_180 = _e462;
    let _e463 = V_8;
    param_181 = _e463;
    let _e464 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_180), (&param_181));
    (*N_11) = _e464;
    let _e465 = (*N_11);
    let _e466 = V_8;
    NdotV_13 = clamp(dot(_e465, _e466), 0.00000001f, 1f);
    let _e469 = (*color0_1);
    safeColor0_ = max(_e469, vec3(0f));
    let _e472 = (*color82_);
    safeColor82_ = max(_e472, vec3(0f));
    let _e475 = (*color90_1);
    safeColor90_ = max(_e475, vec3(0f));
    let _e478 = safeColor0_;
    param_182 = _e478;
    let _e479 = safeColor82_;
    param_183 = _e479;
    let _e480 = safeColor90_;
    param_184 = _e480;
    let _e481 = (*exponent_3);
    param_185 = _e481;
    let _e482 = (*thinfilm_thickness);
    param_186 = _e482;
    let _e483 = (*thinfilm_ior);
    param_187 = _e483;
    let _e484 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_182), (&param_183), (&param_184), (&param_185), (&param_186), (&param_187));
    fd_8 = _e484;
    let _e485 = (*roughness_8);
    safeAlpha = clamp(_e485, vec2(0.00000001f), vec2(1f));
    let _e489 = safeAlpha;
    param_188 = _e489;
    let _e490 = mx_average_alpha_u0028_vf2_u003b((&param_188));
    avgAlpha_1 = _e490;
    let _e492 = (*closureData_14).closureType;
    if (_e492 == 1i) {
        let _e494 = (*X_2);
        let _e495 = (*X_2);
        let _e496 = (*N_11);
        let _e498 = (*N_11);
        (*X_2) = normalize((_e494 - (_e498 * dot(_e495, _e496))));
        let _e502 = (*N_11);
        let _e503 = (*X_2);
        Y_1 = cross(_e502, _e503);
        let _e505 = L_6;
        let _e506 = V_8;
        H_4 = normalize((_e505 + _e506));
        let _e509 = (*N_11);
        let _e510 = L_6;
        NdotL_7 = clamp(dot(_e509, _e510), 0.00000001f, 1f);
        let _e513 = V_8;
        let _e514 = H_4;
        VdotH_1 = clamp(dot(_e513, _e514), 0.00000001f, 1f);
        let _e517 = H_4;
        let _e518 = (*X_2);
        let _e520 = H_4;
        let _e521 = Y_1;
        let _e523 = H_4;
        let _e524 = (*N_11);
        Ht = vec3<f32>(dot(_e517, _e518), dot(_e520, _e521), dot(_e523, _e524));
        let _e527 = VdotH_1;
        param_189 = _e527;
        let _e528 = fd_8;
        param_190 = _e528;
        let _e529 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_189), (&param_190));
        F_1 = _e529;
        let _e530 = Ht;
        param_191 = _e530;
        let _e531 = safeAlpha;
        param_192 = _e531;
        let _e532 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_191), (&param_192));
        D = _e532;
        let _e533 = NdotL_7;
        param_193 = _e533;
        let _e534 = NdotV_13;
        param_194 = _e534;
        let _e535 = avgAlpha_1;
        param_195 = _e535;
        let _e536 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_193), (&param_194), (&param_195));
        G_2 = _e536;
        let _e537 = NdotV_13;
        param_196 = _e537;
        let _e538 = avgAlpha_1;
        param_197 = _e538;
        let _e539 = fd_8;
        param_198 = _e539;
        let _e540 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_196), (&param_197), (&param_198));
        comp = _e540;
        let _e541 = NdotV_13;
        param_199 = _e541;
        let _e542 = avgAlpha_1;
        param_200 = _e542;
        let _e543 = safeColor0_;
        param_201 = _e543;
        let _e544 = safeColor90_;
        param_202 = _e544;
        let _e545 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_199), (&param_200), (&param_201), (&param_202));
        let _e546 = comp;
        dirAlbedo_2 = (_e545 * _e546);
        let _e548 = dirAlbedo_2;
        avgDirAlbedo = dot(_e548, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e550 = avgDirAlbedo;
        let _e551 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e550 * _e551)));
        let _e556 = D;
        let _e557 = F_1;
        let _e559 = G_2;
        let _e561 = comp;
        let _e564 = (*closureData_14).occlusion;
        let _e566 = (*weight_4);
        let _e568 = NdotV_13;
        (*bsdf_3).response = ((((((_e557 * _e556) * _e559) * _e561) * _e564) * _e566) / vec3((4f * _e568)));
    } else {
        let _e574 = (*closureData_14).closureType;
        if (_e574 == 2i) {
            let _e576 = NdotV_13;
            param_203 = _e576;
            let _e577 = avgAlpha_1;
            param_204 = _e577;
            let _e578 = fd_8;
            param_205 = _e578;
            let _e579 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_203), (&param_204), (&param_205));
            comp_1 = _e579;
            let _e580 = NdotV_13;
            param_206 = _e580;
            let _e581 = avgAlpha_1;
            param_207 = _e581;
            let _e582 = safeColor0_;
            param_208 = _e582;
            let _e583 = safeColor90_;
            param_209 = _e583;
            let _e584 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_206), (&param_207), (&param_208), (&param_209));
            let _e585 = comp_1;
            dirAlbedo_3 = (_e584 * _e585);
            let _e587 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e587, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e589 = avgDirAlbedo_1;
            let _e590 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e589 * _e590)));
            let _e595 = (*scatter_mode);
            if (_e595 != 0i) {
                let _e597 = safeColor0_;
                avgF0_ = dot(_e597, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e599 = avgF0_;
                param_210 = _e599;
                let _e600 = mx_f0_to_ior_u0028_f1_u003b((&param_210));
                fd_8.ior = vec3(_e600);
                let _e603 = (*N_11);
                param_211 = _e603;
                let _e604 = V_8;
                param_212 = _e604;
                let _e605 = (*X_2);
                param_213 = _e605;
                let _e606 = safeAlpha;
                param_214 = _e606;
                let _e607 = (*distribution_2);
                param_215 = _e607;
                let _e608 = fd_8;
                param_216 = _e608;
                param_217 = vec3<f32>(1f, 1f, 1f);
                let _e609 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_211), (&param_212), (&param_213), (&param_214), (&param_215), (&param_216), (&param_217));
                let _e610 = (*weight_4);
                (*bsdf_3).response = (_e609 * _e610);
            }
        } else {
            let _e614 = (*closureData_14).closureType;
            if (_e614 == 3i) {
                let _e616 = NdotV_13;
                param_218 = _e616;
                let _e617 = avgAlpha_1;
                param_219 = _e617;
                let _e618 = fd_8;
                param_220 = _e618;
                let _e619 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_218), (&param_219), (&param_220));
                comp_2 = _e619;
                let _e620 = NdotV_13;
                param_221 = _e620;
                let _e621 = avgAlpha_1;
                param_222 = _e621;
                let _e622 = safeColor0_;
                param_223 = _e622;
                let _e623 = safeColor90_;
                param_224 = _e623;
                let _e624 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_221), (&param_222), (&param_223), (&param_224));
                let _e625 = comp_2;
                dirAlbedo_4 = (_e624 * _e625);
                let _e627 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e627, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e629 = avgDirAlbedo_2;
                let _e630 = (*weight_4);
                (*bsdf_3).throughput = vec3((1f - (_e629 * _e630)));
                let _e635 = (*N_11);
                param_225 = _e635;
                let _e636 = V_8;
                param_226 = _e636;
                let _e637 = (*X_2);
                param_227 = _e637;
                let _e638 = safeAlpha;
                param_228 = _e638;
                let _e639 = (*distribution_2);
                param_229 = _e639;
                let _e640 = fd_8;
                param_230 = _e640;
                let _e641 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_225), (&param_226), (&param_227), (&param_228), (&param_229), (&param_230));
                Li_4 = _e641;
                let _e642 = Li_4;
                let _e643 = comp_2;
                let _e645 = (*weight_4);
                (*bsdf_3).response = ((_e642 * _e643) * _e645);
            }
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_231: f32;

    let _e348 = (*ior_3);
    let _e350 = (*ior_3);
    param_231 = ((_e348 - 1f) / (_e350 + 1f));
    let _e353 = mx_square_u0028_f1_u003b((&param_231));
    return _e353;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e351 = (*tf_thickness_1);
    fd_9.airy = (_e351 > 0f);
    let _e354 = (*ior_4);
    fd_9.ior = vec3(_e354);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e362 = (*tf_thickness_1);
    fd_9.tf_thickness = _e362;
    let _e364 = (*tf_ior_1);
    fd_9.tf_ior = _e364;
    fd_9.refraction = false;
    let _e367 = fd_9;
    return _e367;
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
    var phi_4395_: bool;

    let _e430 = (*weight_5);
    if (_e430 < 0.00000001f) {
        return;
    }
    let _e433 = (*closureData_15).closureType;
    let _e435 = (*scatter_mode_1);
    if ((_e433 != 2i) && (_e435 == 1i)) {
        return;
    }
    let _e439 = (*closureData_15).V;
    V_9 = _e439;
    let _e441 = (*closureData_15).L;
    L_7 = _e441;
    let _e442 = (*retroreflective_1);
    phi_4395_ = _e442;
    if _e442 {
        let _e444 = (*closureData_15).closureType;
        phi_4395_ = (_e444 != 2i);
    }
    let _e447 = phi_4395_;
    if _e447 {
        let _e448 = V_9;
        let _e450 = (*N_12);
        V_9 = reflect(-(_e448), _e450);
    }
    let _e452 = (*N_12);
    param_232 = _e452;
    let _e453 = V_9;
    param_233 = _e453;
    let _e454 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_232), (&param_233));
    (*N_12) = _e454;
    let _e455 = (*N_12);
    let _e456 = V_9;
    NdotV_14 = clamp(dot(_e455, _e456), 0.00000001f, 1f);
    let _e459 = (*ior_5);
    param_234 = _e459;
    let _e460 = (*thinfilm_thickness_1);
    param_235 = _e460;
    let _e461 = (*thinfilm_ior_1);
    param_236 = _e461;
    let _e462 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_234), (&param_235), (&param_236));
    fd_10 = _e462;
    let _e463 = (*ior_5);
    param_237 = _e463;
    let _e464 = mx_ior_to_f0_u0028_f1_u003b((&param_237));
    F0_8 = _e464;
    let _e465 = (*roughness_9);
    safeAlpha_1 = clamp(_e465, vec2(0.00000001f), vec2(1f));
    let _e469 = safeAlpha_1;
    param_238 = _e469;
    let _e470 = mx_average_alpha_u0028_vf2_u003b((&param_238));
    avgAlpha_2 = _e470;
    let _e471 = (*tint_2);
    safeTint = max(_e471, vec3(0f));
    let _e475 = (*closureData_15).closureType;
    if (_e475 == 1i) {
        let _e477 = (*X_3);
        let _e478 = (*X_3);
        let _e479 = (*N_12);
        let _e481 = (*N_12);
        (*X_3) = normalize((_e477 - (_e481 * dot(_e478, _e479))));
        let _e485 = (*N_12);
        let _e486 = (*X_3);
        Y_2 = cross(_e485, _e486);
        let _e488 = L_7;
        let _e489 = V_9;
        H_5 = normalize((_e488 + _e489));
        let _e492 = (*N_12);
        let _e493 = L_7;
        NdotL_8 = clamp(dot(_e492, _e493), 0.00000001f, 1f);
        let _e496 = V_9;
        let _e497 = H_5;
        VdotH_2 = clamp(dot(_e496, _e497), 0.00000001f, 1f);
        let _e500 = H_5;
        let _e501 = (*X_3);
        let _e503 = H_5;
        let _e504 = Y_2;
        let _e506 = H_5;
        let _e507 = (*N_12);
        Ht_1 = vec3<f32>(dot(_e500, _e501), dot(_e503, _e504), dot(_e506, _e507));
        let _e510 = VdotH_2;
        param_239 = _e510;
        let _e511 = fd_10;
        param_240 = _e511;
        let _e512 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_239), (&param_240));
        F_2 = _e512;
        let _e513 = Ht_1;
        param_241 = _e513;
        let _e514 = safeAlpha_1;
        param_242 = _e514;
        let _e515 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_241), (&param_242));
        D_1 = _e515;
        let _e516 = NdotL_8;
        param_243 = _e516;
        let _e517 = NdotV_14;
        param_244 = _e517;
        let _e518 = avgAlpha_2;
        param_245 = _e518;
        let _e519 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_243), (&param_244), (&param_245));
        G_3 = _e519;
        let _e520 = NdotV_14;
        param_246 = _e520;
        let _e521 = avgAlpha_2;
        param_247 = _e521;
        let _e522 = fd_10;
        param_248 = _e522;
        let _e523 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_246), (&param_247), (&param_248));
        comp_3 = _e523;
        let _e524 = NdotV_14;
        param_249 = _e524;
        let _e525 = avgAlpha_2;
        param_250 = _e525;
        let _e526 = F0_8;
        param_251 = _e526;
        param_252 = 1f;
        let _e527 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_249), (&param_250), (&param_251), (&param_252));
        let _e528 = comp_3;
        dirAlbedo_5 = (_e528 * _e527);
        let _e530 = dirAlbedo_5;
        let _e531 = (*weight_5);
        (*bsdf_4).throughput = (vec3(1f) - (_e530 * _e531));
        let _e536 = D_1;
        let _e537 = F_2;
        let _e539 = G_3;
        let _e541 = comp_3;
        let _e543 = safeTint;
        let _e546 = (*closureData_15).occlusion;
        let _e548 = (*weight_5);
        let _e550 = NdotV_14;
        (*bsdf_4).response = (((((((_e537 * _e536) * _e539) * _e541) * _e543) * _e546) * _e548) / vec3((4f * _e550)));
    } else {
        let _e556 = (*closureData_15).closureType;
        if (_e556 == 2i) {
            let _e558 = NdotV_14;
            param_253 = _e558;
            let _e559 = avgAlpha_2;
            param_254 = _e559;
            let _e560 = fd_10;
            param_255 = _e560;
            let _e561 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254), (&param_255));
            comp_4 = _e561;
            let _e562 = NdotV_14;
            param_256 = _e562;
            let _e563 = avgAlpha_2;
            param_257 = _e563;
            let _e564 = F0_8;
            param_258 = _e564;
            param_259 = 1f;
            let _e565 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_256), (&param_257), (&param_258), (&param_259));
            let _e566 = comp_4;
            dirAlbedo_6 = (_e566 * _e565);
            let _e568 = dirAlbedo_6;
            let _e569 = (*weight_5);
            (*bsdf_4).throughput = (vec3(1f) - (_e568 * _e569));
            let _e574 = (*scatter_mode_1);
            if (_e574 != 0i) {
                let _e576 = (*N_12);
                param_260 = _e576;
                let _e577 = V_9;
                param_261 = _e577;
                let _e578 = (*X_3);
                param_262 = _e578;
                let _e579 = safeAlpha_1;
                param_263 = _e579;
                let _e580 = (*distribution_3);
                param_264 = _e580;
                let _e581 = fd_10;
                param_265 = _e581;
                let _e582 = safeTint;
                param_266 = _e582;
                let _e583 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_260), (&param_261), (&param_262), (&param_263), (&param_264), (&param_265), (&param_266));
                let _e584 = (*weight_5);
                (*bsdf_4).response = (_e583 * _e584);
            }
        } else {
            let _e588 = (*closureData_15).closureType;
            if (_e588 == 3i) {
                let _e590 = NdotV_14;
                param_267 = _e590;
                let _e591 = avgAlpha_2;
                param_268 = _e591;
                let _e592 = fd_10;
                param_269 = _e592;
                let _e593 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
                comp_5 = _e593;
                let _e594 = NdotV_14;
                param_270 = _e594;
                let _e595 = avgAlpha_2;
                param_271 = _e595;
                let _e596 = F0_8;
                param_272 = _e596;
                param_273 = 1f;
                let _e597 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
                let _e598 = comp_5;
                dirAlbedo_7 = (_e598 * _e597);
                let _e600 = dirAlbedo_7;
                let _e601 = (*weight_5);
                (*bsdf_4).throughput = (vec3(1f) - (_e600 * _e601));
                let _e606 = (*N_12);
                param_274 = _e606;
                let _e607 = V_9;
                param_275 = _e607;
                let _e608 = (*X_3);
                param_276 = _e608;
                let _e609 = safeAlpha_1;
                param_277 = _e609;
                let _e610 = (*distribution_3);
                param_278 = _e610;
                let _e611 = fd_10;
                param_279 = _e611;
                let _e612 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279));
                Li_5 = _e612;
                let _e613 = Li_5;
                let _e614 = safeTint;
                let _e616 = comp_5;
                let _e618 = (*weight_5);
                (*bsdf_4).response = (((_e613 * _e614) * _e616) * _e618);
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

    let _e352 = (*y_2);
    let _e353 = (*y_2);
    let _e357 = (*y_2);
    let _e358 = (*y_2);
    s_3 = ((_e352 * (0.0206607f + (1.58491f * _e353))) / (0.0379424f + (_e357 * (1.32227f + _e358))));
    let _e363 = (*y_2);
    let _e364 = (*y_2);
    let _e365 = (*y_2);
    let _e366 = (*y_2);
    let _e368 = (*y_2);
    let _e376 = (*y_2);
    m_4 = ((_e363 * (-0.193854f + (_e364 * (-1.14885f + (_e365 * (1.7932f - ((0.95943f * _e366) * _e368))))))) / (0.046391f + _e376));
    let _e379 = (*y_2);
    let _e380 = (*y_2);
    let _e383 = (*y_2);
    let _e387 = (*y_2);
    let _e388 = (*y_2);
    o = ((_e379 * (0.000654023f + ((-0.0207818f + (0.119681f * _e380)) * _e383))) / (1.26264f + (_e387 * (-1.92021f + _e388))));
    let _e393 = (*x_8);
    let _e394 = m_4;
    let _e396 = s_3;
    param_280 = ((_e393 - _e394) / _e396);
    let _e398 = mx_square_u0028_f1_u003b((&param_280));
    let _e401 = s_3;
    let _e404 = o;
    return ((exp((-0.5f * _e398)) / (_e401 * 2.5066283f)) + _e404);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_12: ptr<function, f32>) -> f32 {
    let _e347 = (*cosTheta_12);
    return (max(_e347, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_9: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e348 = (*x_9);
    let _e351 = (*y_3);
    let _e354 = (*y_3);
    let _e356 = (*y_3);
    let _e358 = (*y_3);
    let _e360 = (*x_9);
    let _e363 = (*x_9);
    let _e365 = (*y_3);
    let _e368 = (*y_3);
    let _e370 = (*y_3);
    return (((((sqrt((1f - _e348)) * (_e351 - 1f)) * _e354) * _e356) * _e358) / (((0.0000254053f + (1.71228f * _e360)) - ((1.71506f * _e363) * _e365)) + ((1.34174f * _e368) * _e370)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_10: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e348 = (*x_10);
    let _e350 = (*y_4);
    let _e353 = (*y_4);
    let _e355 = (*x_10);
    let _e357 = (*x_10);
    let _e360 = (*x_10);
    let _e362 = (*y_4);
    return ((((2.58126f * _e348) + (0.813703f * _e350)) * _e353) / ((1f + ((0.310327f * _e355) * _e357)) + ((2.60994f * _e360) * _e362)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_13: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_4: vec3<f32>;
    var Y_3: vec3<f32>;

    let _e353 = (*N_13)[2u];
    sign_ = select(1f, -1f, (_e353 < 0f));
    let _e356 = sign_;
    let _e358 = (*N_13)[2u];
    a_3 = (-1f / (_e356 + _e358));
    let _e362 = (*N_13)[0u];
    let _e364 = (*N_13)[1u];
    let _e366 = a_3;
    b = ((_e362 * _e364) * _e366);
    let _e368 = sign_;
    let _e370 = (*N_13)[0u];
    let _e373 = (*N_13)[0u];
    let _e375 = a_3;
    let _e378 = sign_;
    let _e379 = b;
    let _e381 = sign_;
    let _e384 = (*N_13)[0u];
    X_4 = vec3<f32>((1f + (((_e368 * _e370) * _e373) * _e375)), (_e378 * _e379), (-(_e381) * _e384));
    let _e387 = b;
    let _e388 = sign_;
    let _e390 = (*N_13)[1u];
    let _e392 = (*N_13)[1u];
    let _e394 = a_3;
    let _e398 = (*N_13)[1u];
    Y_3 = vec3<f32>(_e387, (_e388 + ((_e390 * _e392) * _e394)), -(_e398));
    let _e401 = X_4;
    let _e402 = Y_3;
    let _e403 = (*N_13);
    return mat3x3<f32>(vec3<f32>(_e401.x, _e401.y, _e401.z), vec3<f32>(_e402.x, _e402.y, _e402.z), vec3<f32>(_e403.x, _e403.y, _e403.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_10: ptr<function, vec3<f32>>, N_14: ptr<function, vec3<f32>>, NdotV_15: ptr<function, f32>) -> mat3x3<f32> {
    var X_5: vec3<f32>;
    var lenSqr: f32;
    var Y_4: vec3<f32>;
    var param_281: vec3<f32>;

    let _e353 = (*V_10);
    let _e354 = (*N_14);
    let _e355 = (*NdotV_15);
    X_5 = (_e353 - (_e354 * _e355));
    let _e358 = X_5;
    let _e359 = X_5;
    lenSqr = dot(_e358, _e359);
    let _e361 = lenSqr;
    if (_e361 > 0f) {
        let _e363 = lenSqr;
        let _e365 = X_5;
        X_5 = (_e365 * inverseSqrt(_e363));
        let _e367 = (*N_14);
        let _e368 = X_5;
        Y_4 = cross(_e367, _e368);
        let _e370 = X_5;
        let _e371 = Y_4;
        let _e372 = (*N_14);
        return mat3x3<f32>(vec3<f32>(_e370.x, _e370.y, _e370.z), vec3<f32>(_e371.x, _e371.y, _e371.z), vec3<f32>(_e372.x, _e372.y, _e372.z));
    }
    let _e386 = (*N_14);
    param_281 = _e386;
    let _e387 = mx_orthonormal_basis_u0028_vf3_u003b((&param_281));
    return _e387;
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

    let _e368 = (*V_11);
    param_282 = _e368;
    let _e369 = (*N_15);
    param_283 = _e369;
    let _e370 = (*NdotV_16);
    param_284 = _e370;
    let _e371 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_282), (&param_283), (&param_284));
    toLTC = transpose(_e371);
    let _e373 = toLTC;
    param_285 = _e373;
    let _e374 = (*L_8);
    param_286 = _e374;
    let _e375 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_285), (&param_286));
    w = _e375;
    let _e376 = (*NdotV_16);
    param_287 = _e376;
    let _e377 = (*roughness_10);
    param_288 = _e377;
    let _e378 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_287), (&param_288));
    aInv = _e378;
    let _e379 = (*NdotV_16);
    param_289 = _e379;
    let _e380 = (*roughness_10);
    param_290 = _e380;
    let _e381 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_289), (&param_290));
    bInv = _e381;
    let _e382 = aInv;
    let _e384 = w[0u];
    let _e386 = bInv;
    let _e388 = w[2u];
    let _e391 = aInv;
    let _e393 = w[1u];
    let _e396 = w[2u];
    wo = vec3<f32>(((_e382 * _e384) + (_e386 * _e388)), (_e391 * _e393), _e396);
    let _e398 = wo;
    let _e399 = wo;
    lenSqr_1 = dot(_e398, _e399);
    let _e402 = wo[2u];
    param_291 = _e402;
    let _e403 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_291));
    let _e404 = aInv;
    let _e405 = lenSqr_1;
    param_292 = (_e404 / _e405);
    let _e407 = mx_square_u0028_f1_u003b((&param_292));
    return (_e403 * _e407);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_293: f32;
    var param_294: f32;

    let _e351 = (*NdotV_17);
    let _e354 = (*roughness_11);
    let _e357 = (*NdotV_17);
    let _e359 = (*roughness_11);
    let _e362 = (*NdotV_17);
    param_293 = _e362;
    let _e363 = mx_square_u0028_f1_u003b((&param_293));
    let _e366 = (*roughness_11);
    param_294 = _e366;
    let _e367 = mx_square_u0028_f1_u003b((&param_294));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e351)) + (vec2<f32>(799.08826f, 442.7821f) * _e354)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e357) * _e359)) + (vec2<f32>(60.28956f, 121.81241f) * _e363)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e367));
    let _e371 = r_2[0u];
    let _e373 = r_2[1u];
    return (_e371 / _e373);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_18: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var dirAlbedo_8: f32;
    var param_295: f32;
    var param_296: f32;

    let _e351 = (*NdotV_18);
    param_295 = _e351;
    let _e352 = (*roughness_12);
    param_296 = _e352;
    let _e353 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_295), (&param_296));
    dirAlbedo_8 = _e353;
    let _e354 = dirAlbedo_8;
    return clamp(_e354, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e351 = (*roughness_13);
    invRoughness = (1f / max(_e351, 0.005f));
    let _e354 = (*NdotH);
    let _e355 = (*NdotH);
    cos2_ = (_e354 * _e355);
    let _e357 = cos2_;
    sin2_ = (1f - _e357);
    let _e359 = invRoughness;
    let _e361 = sin2_;
    let _e362 = invRoughness;
    return (((2f + _e359) * pow(_e361, (_e362 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_9: ptr<function, f32>, NdotV_19: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_14: ptr<function, f32>) -> f32 {
    var D_2: f32;
    var param_297: f32;
    var param_298: f32;
    var F_3: f32;
    var G_4: f32;

    let _e355 = (*NdotH_1);
    param_297 = _e355;
    let _e356 = (*roughness_14);
    param_298 = _e356;
    let _e357 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_297), (&param_298));
    D_2 = _e357;
    F_3 = 1f;
    G_4 = 1f;
    let _e358 = D_2;
    let _e359 = F_3;
    let _e361 = G_4;
    let _e363 = (*NdotL_9);
    let _e364 = (*NdotV_19);
    let _e366 = (*NdotL_9);
    let _e367 = (*NdotV_19);
    return (((_e358 * _e359) * _e361) / (4f * ((_e363 + _e364) - (_e366 * _e367))));
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

    let _e384 = (*weight_6);
    if (_e384 < 0.00000001f) {
        return;
    }
    let _e387 = (*closureData_16).V;
    V_12 = _e387;
    let _e389 = (*closureData_16).L;
    L_9 = _e389;
    let _e390 = (*N_16);
    param_299 = _e390;
    let _e391 = V_12;
    param_300 = _e391;
    let _e392 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_299), (&param_300));
    (*N_16) = _e392;
    let _e393 = (*N_16);
    let _e394 = V_12;
    NdotV_20 = clamp(dot(_e393, _e394), 0.00000001f, 1f);
    let _e398 = (*closureData_16).closureType;
    if (_e398 == 1i) {
        let _e400 = (*mode);
        if (_e400 == 0i) {
            let _e402 = L_9;
            let _e403 = V_12;
            H_6 = normalize((_e402 + _e403));
            let _e406 = (*N_16);
            let _e407 = L_9;
            NdotL_10 = clamp(dot(_e406, _e407), 0.00000001f, 1f);
            let _e410 = (*N_16);
            let _e411 = H_6;
            NdotH_2 = clamp(dot(_e410, _e411), 0.00000001f, 1f);
            let _e414 = (*color_6);
            let _e415 = NdotL_10;
            param_301 = _e415;
            let _e416 = NdotV_20;
            param_302 = _e416;
            let _e417 = NdotH_2;
            param_303 = _e417;
            let _e418 = (*roughness_15);
            param_304 = _e418;
            let _e419 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_301), (&param_302), (&param_303), (&param_304));
            fr = (_e414 * _e419);
            let _e421 = NdotV_20;
            param_305 = _e421;
            let _e422 = (*roughness_15);
            param_306 = _e422;
            let _e423 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_305), (&param_306));
            dirAlbedo_9 = _e423;
            let _e424 = fr;
            let _e425 = NdotL_10;
            let _e428 = (*closureData_16).occlusion;
            let _e430 = (*weight_6);
            (*bsdf_5).response = (((_e424 * _e425) * _e428) * _e430);
        } else {
            let _e433 = (*roughness_15);
            (*roughness_15) = clamp(_e433, 0.01f, 1f);
            let _e435 = (*color_6);
            let _e436 = L_9;
            param_307 = _e436;
            let _e437 = V_12;
            param_308 = _e437;
            let _e438 = (*N_16);
            param_309 = _e438;
            let _e439 = NdotV_20;
            param_310 = _e439;
            let _e440 = (*roughness_15);
            param_311 = _e440;
            let _e441 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_307), (&param_308), (&param_309), (&param_310), (&param_311));
            fr_1 = (_e435 * _e441);
            let _e443 = NdotV_20;
            param_312 = _e443;
            let _e444 = (*roughness_15);
            param_313 = _e444;
            let _e445 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_312), (&param_313));
            dirAlbedo_9 = _e445;
            let _e446 = dirAlbedo_9;
            let _e447 = fr_1;
            let _e450 = (*closureData_16).occlusion;
            let _e452 = (*weight_6);
            (*bsdf_5).response = (((_e447 * _e446) * _e450) * _e452);
        }
        let _e455 = dirAlbedo_9;
        let _e456 = (*weight_6);
        (*bsdf_5).throughput = vec3((1f - (_e455 * _e456)));
    } else {
        let _e462 = (*closureData_16).closureType;
        if (_e462 == 3i) {
            let _e464 = (*mode);
            if (_e464 == 0i) {
                let _e466 = NdotV_20;
                param_314 = _e466;
                let _e467 = (*roughness_15);
                param_315 = _e467;
                let _e468 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_314), (&param_315));
                dirAlbedo_10 = _e468;
            } else {
                let _e469 = (*roughness_15);
                (*roughness_15) = clamp(_e469, 0.01f, 1f);
                let _e471 = NdotV_20;
                param_316 = _e471;
                let _e472 = (*roughness_15);
                param_317 = _e472;
                let _e473 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_316), (&param_317));
                dirAlbedo_10 = _e473;
            }
            let _e474 = (*N_16);
            param_318 = _e474;
            let _e475 = mx_environment_irradiance_u0028_vf3_u003b((&param_318));
            Li_6 = _e475;
            let _e476 = Li_6;
            let _e477 = (*color_6);
            let _e479 = dirAlbedo_10;
            let _e481 = (*weight_6);
            (*bsdf_5).response = (((_e476 * _e477) * _e479) * _e481);
            let _e484 = dirAlbedo_10;
            let _e485 = (*weight_6);
            (*bsdf_5).throughput = vec3((1f - (_e484 * _e485)));
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e352 = (*closureType);
    let _e353 = (*L_10);
    let _e354 = (*V_13);
    let _e355 = (*N_17);
    let _e356 = (*P_2);
    let _e357 = (*occlusion_1);
    return ClosureData(_e352, _e353, _e354, _e355, _e356, _e357);
}

fn NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_4: ptr<function, vec3<f32>>, outx: ptr<function, f32>, outy: ptr<function, f32>, outz: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e354 = (*in1_4)[0u];
    N_extract_0_out = _e354;
    let _e356 = (*in1_4)[1u];
    N_extract_1_out = _e356;
    let _e358 = (*in1_4)[2u];
    N_extract_2_out = _e358;
    let _e359 = N_extract_0_out;
    (*outx) = _e359;
    let _e360 = N_extract_1_out;
    (*outy) = _e360;
    let _e361 = N_extract_2_out;
    (*outz) = _e361;
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
    let _e357 = (*in1_5);
    param_319 = _e357;
    NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322));
    let _e358 = param_320;
    N_separate_outx = _e358;
    let _e359 = param_321;
    N_separate_outy = _e359;
    let _e360 = param_322;
    N_separate_outz = _e360;
    let _e361 = N_separate_outx;
    let _e362 = N_separate_outy;
    N_min_01_out = min(_e361, _e362);
    let _e364 = N_min_01_out;
    let _e365 = N_separate_outz;
    N_min_out = min(_e364, _e365);
    let _e367 = N_min_out;
    (*out1_) = _e367;
    return;
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_6: ptr<function, f32>, out1_1: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e349 = (*in1_6);
    combine_out = vec3(_e349);
    let _e351 = combine_out;
    (*out1_1) = _e351;
    return;
}

fn NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b(in1_7: ptr<function, f32>, out1_2: ptr<function, vec3<f32>>) {
    var combine_out_1: vec3<f32>;

    let _e349 = (*in1_7);
    combine_out_1 = vec3(_e349);
    let _e351 = combine_out_1;
    (*out1_2) = _e351;
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_8: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out_1: f32;
    var N_extract_1_out_1: f32;
    var N_extract_2_out_1: f32;

    let _e354 = (*in1_8)[0u];
    N_extract_0_out_1 = _e354;
    let _e356 = (*in1_8)[1u];
    N_extract_1_out_1 = _e356;
    let _e358 = (*in1_8)[2u];
    N_extract_2_out_1 = _e358;
    let _e359 = N_extract_0_out_1;
    (*outr) = _e359;
    let _e360 = N_extract_1_out_1;
    (*outg) = _e360;
    let _e361 = N_extract_2_out_1;
    (*outb) = _e361;
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
    let _e356 = (*in1_9);
    param_323 = _e356;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_323), (&param_324), (&param_325), (&param_326));
    let _e357 = param_324;
    separate_outr = _e357;
    let _e358 = param_325;
    separate_outg = _e358;
    let _e359 = param_326;
    separate_outb = _e359;
    let _e360 = separate_outr;
    let _e361 = separate_outg;
    let _e362 = separate_outb;
    combine_out_2 = vec3<f32>(_e360, _e361, _e362);
    let _e364 = combine_out_2;
    (*out1_3) = _e364;
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

    let _e358 = (*roughness_16);
    let _e359 = (*roughness_16);
    rough_sq_out = (_e358 * _e359);
    let _e361 = (*anisotropy_2);
    aniso_invert_out = (1f - _e361);
    let _e363 = aniso_invert_out;
    let _e364 = aniso_invert_out;
    aniso_invert_sq_out = (_e363 * _e364);
    let _e366 = aniso_invert_sq_out;
    denom_out = (_e366 + 1f);
    let _e368 = denom_out;
    fraction_out = (2f / _e368);
    let _e370 = fraction_out;
    sqrt_out = sqrt(_e370);
    let _e372 = rough_sq_out;
    let _e373 = sqrt_out;
    alpha_x_out = (_e372 * _e373);
    let _e375 = aniso_invert_out;
    let _e376 = alpha_x_out;
    alpha_y_out = (_e375 * _e376);
    let _e378 = alpha_x_out;
    let _e379 = alpha_y_out;
    result_out = vec2<f32>(_e378, _e379);
    let _e381 = result_out;
    (*out1_4) = _e381;
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
    let _e771 = (*coat_roughness);
    param_327 = _e771;
    let _e772 = (*coat_roughness_anisotropy);
    param_328 = _e772;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_327), (&param_328), (&param_329));
    let _e773 = param_329;
    coat_roughness_vector_out = _e773;
    let _e774 = (*specular_weight);
    let _e775 = (*thin_film_weight);
    metal_bsdf_tf_mix_fg_weight_out = (_e774 * _e775);
    let _e777 = (*base_color);
    let _e778 = (*base_weight);
    metal_reflectivity_out = (_e777 * _e778);
    let _e780 = (*coat_roughness);
    coat_roughness_to_power_4_out = pow(_e780, 4f);
    let _e782 = (*specular_roughness);
    specular_roughness_to_power_4_out = pow(_e782, 4f);
    let _e784 = (*thin_film_thickness);
    thin_film_thickness_nm_out = (_e784 * 1000f);
    let _e786 = (*thin_film_weight);
    metal_bsdf_tf_mix_mix_inv_out = (1f - _e786);
    let _e788 = (*thin_film_weight);
    dielectric_reflection_tf_mix_fg_weight_out = (1f * _e788);
    let _e790 = (*specular_ior);
    let _e791 = (*coat_ior);
    specular_to_coat_ior_ratio_out = (_e790 / _e791);
    let _e793 = (*coat_ior);
    let _e794 = (*specular_ior);
    coat_to_specular_ior_ratio_out = (_e793 / _e794);
    let _e796 = (*thin_film_weight);
    dielectric_reflection_tf_mix_mix_inv_out = (1f - _e796);
    let _e798 = (*transmission_depth);
    let _e800 = (*transmission_color);
    if_transmission_tint_out = select(_e800, vec3<f32>(1f, 1f, 1f), (_e798 > 0f));
    transmission_color_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e802 = (*transmission_color);
    param_330 = _e802;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_330), (&param_331));
    let _e803 = param_331;
    transmission_color_vector_out = _e803;
    transmission_depth_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e804 = (*transmission_depth);
    param_332 = _e804;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_332), (&param_333));
    let _e805 = param_333;
    transmission_depth_vector_out = _e805;
    transmission_scatter_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e806 = (*transmission_scatter);
    param_334 = _e806;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_334), (&param_335));
    let _e807 = param_335;
    transmission_scatter_vector_out = _e807;
    let _e808 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e808, vec3(0f));
    let _e811 = (*subsurface_scatter_anisotropy);
    one_minus_subsurface_scatter_anisotropy_out = (1f - _e811);
    let _e813 = (*subsurface_scatter_anisotropy);
    one_plus_subsurface_scatter_anisotropy_out = (1f + _e813);
    let _e815 = (*geometry_thin_walled);
    subsurface_selector_out = select(0f, 1f, _e815);
    let _e817 = (*subsurface_radius_scale);
    let _e818 = (*subsurface_radius);
    subsurface_radius_scaled_out = (_e817 * _e818);
    let _e820 = (*subsurface_weight);
    opaque_base_mix_inv_out = (1f - _e820);
    let _e822 = (*base_color);
    base_color_nonnegative_out = max(_e822, vec3(0f));
    let _e825 = (*transmission_weight);
    dielectric_substrate_mix_inv_out = (1f - _e825);
    let _e827 = (*base_metalness);
    base_substrate_mix_inv_out = (1f - _e827);
    let _e829 = (*coat_ior);
    coat_ior_minus_one_out = (_e829 - 1f);
    let _e831 = (*coat_ior);
    coat_ior_plus_one_out = (1f + _e831);
    let _e833 = (*coat_ior);
    let _e834 = (*coat_ior);
    coat_ior_sqr_out = (_e833 * _e834);
    let _e836 = (*base_color);
    let _e837 = (*specular_weight);
    Emetal_out = (_e836 * _e837);
    let _e839 = (*base_color);
    let _e840 = (*subsurface_color);
    let _e841 = (*subsurface_weight);
    Edielectric_out = mix(_e839, _e840, vec3(_e841));
    let _e844 = (*coat_weight);
    let _e845 = (*coat_darkening);
    coat_weight_times_coat_darkening_out = (_e844 * _e845);
    let _e847 = (*coat_color);
    let _e848 = (*coat_weight);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e847, vec3(_e848));
    let _e851 = (*emission_color);
    let _e852 = (*emission_luminance);
    emission_weight_out = (_e851 * _e852);
    let _e854 = coat_roughness_to_power_4_out;
    two_times_coat_roughness_to_power_4_out = (_e854 * 2f);
    let _e856 = (*specular_weight);
    let _e857 = metal_bsdf_tf_mix_mix_inv_out;
    metal_bsdf_tf_mix_bg_weight_out = (_e856 * _e857);
    let _e859 = specular_to_coat_ior_ratio_out;
    let _e861 = specular_to_coat_ior_ratio_out;
    let _e862 = coat_to_specular_ior_ratio_out;
    specular_to_coat_ior_ratio_tir_fix_out = select(_e862, _e861, (_e859 > 1f));
    let _e864 = dielectric_reflection_tf_mix_mix_inv_out;
    dielectric_reflection_tf_mix_bg_weight_out = (1f * _e864);
    let _e866 = transmission_color_vector_out;
    transmission_color_ln_out = log(_e866);
    let _e868 = transmission_scatter_vector_out;
    let _e869 = transmission_depth_vector_out;
    scattering_coeff_out = (_e868 / _e869);
    let _e871 = (*subsurface_color);
    let _e872 = one_minus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_brdf_factor_out = (_e871 * _e872);
    let _e874 = (*subsurface_color);
    let _e875 = one_plus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_btdf_factor_out = (_e874 * _e875);
    let _e877 = subsurface_selector_out;
    selected_subsurface_mix_inv_out = (1f - _e877);
    let _e879 = (*base_weight);
    let _e880 = opaque_base_mix_inv_out;
    opaque_base_bg_weight_out = (_e879 * _e880);
    let _e882 = coat_ior_minus_one_out;
    let _e883 = coat_ior_plus_one_out;
    coat_ior_to_F0_sqrt_out = (_e882 / _e883);
    let _e885 = Edielectric_out;
    let _e886 = Emetal_out;
    let _e887 = (*base_metalness);
    Ebase_out = mix(_e885, _e886, vec3(_e887));
    let _e890 = two_times_coat_roughness_to_power_4_out;
    let _e891 = specular_roughness_to_power_4_out;
    add_coat_and_spec_roughnesses_to_power_4_out = (_e890 + _e891);
    let _e893 = (*specular_ior);
    let _e894 = specular_to_coat_ior_ratio_tir_fix_out;
    let _e895 = (*coat_weight);
    eta_s_out = mix(_e893, _e894, _e895);
    let _e897 = transmission_color_ln_out;
    extinction_coeff_denom_out = (_e897 * -1f);
    let _e899 = (*transmission_depth);
    let _e901 = scattering_coeff_out;
    if_volume_scattering_out = select(vec3<f32>(0f, 0f, 0f), _e901, (_e899 > 0f));
    let _e903 = selected_subsurface_mix_inv_out;
    selected_subsurface_bg_weight_out = (1f * _e903);
    let _e905 = coat_ior_to_F0_sqrt_out;
    let _e906 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e905 * _e906);
    let _e908 = add_coat_and_spec_roughnesses_to_power_4_out;
    min_1_add_coat_and_spec_roughnesses_to_power_4_out = min(1f, _e908);
    let _e910 = eta_s_out;
    eta_s_minus_one_out = (_e910 - 1f);
    let _e912 = eta_s_out;
    eta_s_plus_one_out = (_e912 + 1f);
    let _e914 = extinction_coeff_denom_out;
    let _e915 = transmission_depth_vector_out;
    extinction_coeff_out = (_e914 / _e915);
    let _e917 = coat_ior_to_F0_out;
    one_minus_coat_F0_out = (1f - _e917);
    let _e919 = min_1_add_coat_and_spec_roughnesses_to_power_4_out;
    coat_affected_specular_roughness_out = pow(_e919, 0.25f);
    let _e921 = eta_s_minus_one_out;
    sign_eta_s_minus_one_out = sign(_e921);
    let _e923 = eta_s_minus_one_out;
    let _e924 = eta_s_plus_one_out;
    specular_F0_sqrt_out = (_e923 / _e924);
    let _e926 = extinction_coeff_out;
    let _e927 = scattering_coeff_out;
    absorption_coeff_out = (_e926 - _e927);
    let _e929 = one_minus_coat_F0_out;
    let _e930 = coat_ior_sqr_out;
    one_minus_coat_F0_over_eta2_out = (_e929 / _e930);
    one_minus_coat_F0_color_out = vec3<f32>(0f, 0f, 0f);
    let _e932 = one_minus_coat_F0_out;
    param_336 = _e932;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_336), (&param_337));
    let _e933 = param_337;
    one_minus_coat_F0_color_out = _e933;
    let _e934 = (*specular_roughness);
    let _e935 = coat_affected_specular_roughness_out;
    let _e936 = (*coat_weight);
    effective_specular_roughness_out = mix(_e934, _e935, _e936);
    let _e938 = specular_F0_sqrt_out;
    let _e939 = specular_F0_sqrt_out;
    specular_F0_out = (_e938 * _e939);
    absorption_coeff_min_out = 0f;
    let _e941 = absorption_coeff_out;
    param_338 = _e941;
    NG_mincomponent_vector3_u0028_vf3_u003b_f1_u003b((&param_338), (&param_339));
    let _e942 = param_339;
    absorption_coeff_min_out = _e942;
    let _e943 = one_minus_coat_F0_over_eta2_out;
    Kcoat_out = (1f - _e943);
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e945 = effective_specular_roughness_out;
    param_340 = _e945;
    let _e946 = (*specular_roughness_anisotropy);
    param_341 = _e946;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_340), (&param_341), (&param_342));
    let _e947 = param_342;
    main_roughness_out = _e947;
    let _e948 = (*specular_weight);
    let _e949 = specular_F0_out;
    scaled_specular_F0_out = (_e948 * _e949);
    absorption_coeff_min_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e951 = absorption_coeff_min_out;
    param_343 = _e951;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_343), (&param_344));
    let _e952 = param_344;
    absorption_coeff_min_vector_out = _e952;
    let _e953 = Kcoat_out;
    one_minus_Kcoat_out = (1f - _e953);
    let _e955 = Ebase_out;
    let _e956 = Kcoat_out;
    Ebase_Kcoat_out = (_e955 * _e956);
    let _e958 = scaled_specular_F0_out;
    scaled_specular_F0_clamped_out = clamp(_e958, 0f, 0.99999f);
    let _e960 = absorption_coeff_out;
    let _e961 = absorption_coeff_min_vector_out;
    absorption_coeff_shifted_out = (_e960 - _e961);
    one_minus_Kcoat_color_out = vec3<f32>(0f, 0f, 0f);
    let _e963 = one_minus_Kcoat_out;
    param_345 = _e963;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_345), (&param_346));
    let _e964 = param_346;
    one_minus_Kcoat_color_out = _e964;
    let _e965 = Ebase_Kcoat_out;
    one_minus_Ebase_Kcoat_out = (vec3<f32>(1f, 1f, 1f) - _e965);
    let _e967 = scaled_specular_F0_clamped_out;
    sqrt_scaled_specular_F0_out = sqrt(_e967);
    let _e969 = absorption_coeff_min_out;
    let _e971 = absorption_coeff_shifted_out;
    let _e972 = absorption_coeff_out;
    if_absorption_coeff_shifted_out = select(_e972, _e971, (0f > _e969));
    let _e974 = one_minus_Kcoat_color_out;
    let _e975 = one_minus_Ebase_Kcoat_out;
    base_darkening_out = (_e974 / _e975);
    let _e977 = sign_eta_s_minus_one_out;
    let _e978 = sqrt_scaled_specular_F0_out;
    modulated_eta_s_epsilon_out = (_e977 * _e978);
    let _e980 = (*transmission_depth);
    let _e982 = if_absorption_coeff_shifted_out;
    if_volume_absorption_out = select(vec3<f32>(0f, 0f, 0f), _e982, (_e980 > 0f));
    let _e984 = base_darkening_out;
    let _e985 = coat_weight_times_coat_darkening_out;
    modulated_base_darkening_out = mix(vec3<f32>(1f, 1f, 1f), _e984, vec3(_e985));
    let _e988 = modulated_eta_s_epsilon_out;
    one_plus_modulated_eta_s_epsilon_out = (1f + _e988);
    let _e990 = modulated_eta_s_epsilon_out;
    one_minus_modulated_eta_s_epsilon_out = (1f - _e990);
    let _e992 = one_plus_modulated_eta_s_epsilon_out;
    let _e993 = one_minus_modulated_eta_s_epsilon_out;
    modulated_eta_s_out = (_e992 / _e993);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e995 = g_ptN;
    N_18 = _e995;
    let _e996 = g_ptV;
    V_14 = _e996;
    let _e997 = g_ptL;
    L_11 = _e997;
    let _e998 = g_ptP;
    P_3 = _e998;
    let _e999 = g_ptOcclusion;
    occlusion_2 = _e999;
    let _e1000 = g_ptClosureType;
    param_347 = _e1000;
    let _e1001 = L_11;
    param_348 = _e1001;
    let _e1002 = V_14;
    param_349 = _e1002;
    let _e1003 = N_18;
    param_350 = _e1003;
    let _e1004 = P_3;
    param_351 = _e1004;
    let _e1005 = occlusion_2;
    param_352 = _e1005;
    let _e1006 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_347), (&param_348), (&param_349), (&param_350), (&param_351), (&param_352));
    closureData_17 = _e1006;
    fuzz_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1007 = closureData_17;
    param_353 = _e1007;
    let _e1008 = (*fuzz_weight);
    param_354 = _e1008;
    let _e1009 = (*fuzz_color);
    param_355 = _e1009;
    let _e1010 = (*fuzz_roughness);
    param_356 = _e1010;
    let _e1011 = (*geometry_normal);
    param_357 = _e1011;
    param_358 = 1i;
    let _e1012 = fuzz_bsdf_out;
    param_359 = _e1012;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359));
    let _e1013 = param_359;
    fuzz_bsdf_out = _e1013;
    coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1014 = closureData_17;
    param_360 = _e1014;
    let _e1015 = (*coat_weight);
    param_361 = _e1015;
    param_362 = vec3<f32>(1f, 1f, 1f);
    let _e1016 = (*coat_ior);
    param_363 = _e1016;
    let _e1017 = coat_roughness_vector_out;
    param_364 = _e1017;
    param_365 = false;
    param_366 = 0f;
    param_367 = 1.5f;
    let _e1018 = (*geometry_coat_normal);
    param_368 = _e1018;
    let _e1019 = (*geometry_coat_tangent);
    param_369 = _e1019;
    param_370 = 0i;
    param_371 = 0i;
    let _e1020 = coat_bsdf_out;
    param_372 = _e1020;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372));
    let _e1021 = param_372;
    coat_bsdf_out = _e1021;
    metal_bsdf_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1022 = closureData_17;
    param_373 = _e1022;
    let _e1023 = metal_bsdf_tf_mix_fg_weight_out;
    param_374 = _e1023;
    let _e1024 = metal_reflectivity_out;
    param_375 = _e1024;
    let _e1025 = (*specular_color);
    param_376 = _e1025;
    param_377 = vec3<f32>(1f, 1f, 1f);
    param_378 = 5f;
    let _e1026 = main_roughness_out;
    param_379 = _e1026;
    param_380 = false;
    let _e1027 = thin_film_thickness_nm_out;
    param_381 = _e1027;
    let _e1028 = (*thin_film_ior);
    param_382 = _e1028;
    let _e1029 = (*geometry_normal);
    param_383 = _e1029;
    let _e1030 = (*geometry_tangent);
    param_384 = _e1030;
    param_385 = 0i;
    param_386 = 0i;
    let _e1031 = metal_bsdf_tf_out;
    param_387 = _e1031;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_373), (&param_374), (&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387));
    let _e1032 = param_387;
    metal_bsdf_tf_out = _e1032;
    metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1033 = closureData_17;
    param_388 = _e1033;
    let _e1034 = metal_bsdf_tf_mix_bg_weight_out;
    param_389 = _e1034;
    let _e1035 = metal_reflectivity_out;
    param_390 = _e1035;
    let _e1036 = (*specular_color);
    param_391 = _e1036;
    param_392 = vec3<f32>(1f, 1f, 1f);
    param_393 = 5f;
    let _e1037 = main_roughness_out;
    param_394 = _e1037;
    param_395 = false;
    param_396 = 0f;
    param_397 = 1.5f;
    let _e1038 = (*geometry_normal);
    param_398 = _e1038;
    let _e1039 = (*geometry_tangent);
    param_399 = _e1039;
    param_400 = 0i;
    param_401 = 0i;
    let _e1040 = metal_bsdf_out;
    param_402 = _e1040;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402));
    let _e1041 = param_402;
    metal_bsdf_out = _e1041;
    metal_bsdf_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1042 = closureData_17;
    param_403 = _e1042;
    let _e1043 = metal_bsdf_tf_out;
    param_404 = _e1043;
    let _e1044 = metal_bsdf_out;
    param_405 = _e1044;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_403), (&param_404), (&param_405), (&param_406));
    let _e1045 = param_406;
    metal_bsdf_tf_mix_add_out = _e1045;
    base_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1046 = closureData_17;
    param_407 = _e1046;
    let _e1047 = metal_bsdf_tf_mix_add_out;
    param_408 = _e1047;
    let _e1048 = (*base_metalness);
    param_409 = _e1048;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_407), (&param_408), (&param_409), (&param_410));
    let _e1049 = param_410;
    base_substrate_fg_mul_out = _e1049;
    dielectric_reflection_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1050 = closureData_17;
    param_411 = _e1050;
    let _e1051 = dielectric_reflection_tf_mix_fg_weight_out;
    param_412 = _e1051;
    let _e1052 = (*specular_color);
    param_413 = _e1052;
    let _e1053 = modulated_eta_s_out;
    param_414 = _e1053;
    let _e1054 = main_roughness_out;
    param_415 = _e1054;
    param_416 = false;
    let _e1055 = thin_film_thickness_nm_out;
    param_417 = _e1055;
    let _e1056 = (*thin_film_ior);
    param_418 = _e1056;
    let _e1057 = (*geometry_normal);
    param_419 = _e1057;
    let _e1058 = (*geometry_tangent);
    param_420 = _e1058;
    param_421 = 0i;
    param_422 = 0i;
    let _e1059 = dielectric_reflection_tf_out;
    param_423 = _e1059;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420), (&param_421), (&param_422), (&param_423));
    let _e1060 = param_423;
    dielectric_reflection_tf_out = _e1060;
    dielectric_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1061 = closureData_17;
    param_424 = _e1061;
    let _e1062 = dielectric_reflection_tf_mix_bg_weight_out;
    param_425 = _e1062;
    let _e1063 = (*specular_color);
    param_426 = _e1063;
    let _e1064 = modulated_eta_s_out;
    param_427 = _e1064;
    let _e1065 = main_roughness_out;
    param_428 = _e1065;
    param_429 = false;
    param_430 = 0f;
    param_431 = 1.5f;
    let _e1066 = (*geometry_normal);
    param_432 = _e1066;
    let _e1067 = (*geometry_tangent);
    param_433 = _e1067;
    param_434 = 0i;
    param_435 = 0i;
    let _e1068 = dielectric_reflection_out;
    param_436 = _e1068;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_424), (&param_425), (&param_426), (&param_427), (&param_428), (&param_429), (&param_430), (&param_431), (&param_432), (&param_433), (&param_434), (&param_435), (&param_436));
    let _e1069 = param_436;
    dielectric_reflection_out = _e1069;
    dielectric_reflection_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1070 = closureData_17;
    param_437 = _e1070;
    let _e1071 = dielectric_reflection_tf_out;
    param_438 = _e1071;
    let _e1072 = dielectric_reflection_out;
    param_439 = _e1072;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_437), (&param_438), (&param_439), (&param_440));
    let _e1073 = param_440;
    dielectric_reflection_tf_mix_add_out = _e1073;
    dielectric_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1074 = closureData_17;
    param_441 = _e1074;
    param_442 = 1f;
    let _e1075 = if_transmission_tint_out;
    param_443 = _e1075;
    let _e1076 = modulated_eta_s_out;
    param_444 = _e1076;
    let _e1077 = main_roughness_out;
    param_445 = _e1077;
    param_446 = false;
    param_447 = 0f;
    param_448 = 1.5f;
    let _e1078 = (*geometry_normal);
    param_449 = _e1078;
    let _e1079 = (*geometry_tangent);
    param_450 = _e1079;
    param_451 = 0i;
    param_452 = 1i;
    let _e1080 = dielectric_transmission_out;
    param_453 = _e1080;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_441), (&param_442), (&param_443), (&param_444), (&param_445), (&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451), (&param_452), (&param_453));
    let _e1081 = param_453;
    dielectric_transmission_out = _e1081;
    dielectric_volume_out = VDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1082 = closureData_17;
    param_454 = _e1082;
    let _e1083 = if_volume_absorption_out;
    param_455 = _e1083;
    let _e1084 = if_volume_scattering_out;
    param_456 = _e1084;
    let _e1085 = (*transmission_scatter_anisotropy);
    param_457 = _e1085;
    let _e1086 = dielectric_volume_out;
    param_458 = _e1086;
    mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b((&param_454), (&param_455), (&param_456), (&param_457), (&param_458));
    let _e1087 = param_458;
    dielectric_volume_out = _e1087;
    dielectric_volume_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1088 = closureData_17;
    param_459 = _e1088;
    let _e1089 = dielectric_transmission_out;
    param_460 = _e1089;
    let _e1090 = dielectric_volume_out;
    param_461 = _e1090;
    mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_459), (&param_460), (&param_461), (&param_462));
    let _e1091 = param_462;
    dielectric_volume_transmission_out = _e1091;
    dielectric_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1092 = closureData_17;
    param_463 = _e1092;
    let _e1093 = dielectric_volume_transmission_out;
    param_464 = _e1093;
    let _e1094 = (*transmission_weight);
    param_465 = _e1094;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_463), (&param_464), (&param_465), (&param_466));
    let _e1095 = param_466;
    dielectric_substrate_fg_mul_out = _e1095;
    subsurface_thin_walled_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1096 = closureData_17;
    param_467 = _e1096;
    param_468 = 1f;
    let _e1097 = subsurface_color_nonnegative_out;
    param_469 = _e1097;
    let _e1098 = (*base_diffuse_roughness);
    param_470 = _e1098;
    let _e1099 = (*geometry_normal);
    param_471 = _e1099;
    param_472 = false;
    let _e1100 = subsurface_thin_walled_reflection_bsdf_out;
    param_473 = _e1100;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473));
    let _e1101 = param_473;
    subsurface_thin_walled_reflection_bsdf_out = _e1101;
    subsurface_thin_walled_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1102 = closureData_17;
    param_474 = _e1102;
    let _e1103 = subsurface_thin_walled_reflection_bsdf_out;
    param_475 = _e1103;
    let _e1104 = subsurface_thin_walled_brdf_factor_out;
    param_476 = _e1104;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_474), (&param_475), (&param_476), (&param_477));
    let _e1105 = param_477;
    subsurface_thin_walled_reflection_out = _e1105;
    subsurface_thin_walled_transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1106 = closureData_17;
    param_478 = _e1106;
    param_479 = 1f;
    let _e1107 = subsurface_color_nonnegative_out;
    param_480 = _e1107;
    let _e1108 = (*geometry_normal);
    param_481 = _e1108;
    let _e1109 = subsurface_thin_walled_transmission_bsdf_out;
    param_482 = _e1109;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_478), (&param_479), (&param_480), (&param_481), (&param_482));
    let _e1110 = param_482;
    subsurface_thin_walled_transmission_bsdf_out = _e1110;
    subsurface_thin_walled_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1111 = closureData_17;
    param_483 = _e1111;
    let _e1112 = subsurface_thin_walled_transmission_bsdf_out;
    param_484 = _e1112;
    let _e1113 = subsurface_thin_walled_btdf_factor_out;
    param_485 = _e1113;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_483), (&param_484), (&param_485), (&param_486));
    let _e1114 = param_486;
    subsurface_thin_walled_transmission_out = _e1114;
    subsurface_thin_walled_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1115 = closureData_17;
    param_487 = _e1115;
    let _e1116 = subsurface_thin_walled_reflection_out;
    param_488 = _e1116;
    let _e1117 = subsurface_thin_walled_transmission_out;
    param_489 = _e1117;
    param_490 = 0.5f;
    mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_487), (&param_488), (&param_489), (&param_490), (&param_491));
    let _e1118 = param_491;
    subsurface_thin_walled_out = _e1118;
    selected_subsurface_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1119 = closureData_17;
    param_492 = _e1119;
    let _e1120 = subsurface_thin_walled_out;
    param_493 = _e1120;
    let _e1121 = subsurface_selector_out;
    param_494 = _e1121;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_492), (&param_493), (&param_494), (&param_495));
    let _e1122 = param_495;
    selected_subsurface_fg_mul_out = _e1122;
    subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1123 = closureData_17;
    param_496 = _e1123;
    let _e1124 = selected_subsurface_bg_weight_out;
    param_497 = _e1124;
    let _e1125 = subsurface_color_nonnegative_out;
    param_498 = _e1125;
    let _e1126 = subsurface_radius_scaled_out;
    param_499 = _e1126;
    let _e1127 = (*subsurface_scatter_anisotropy);
    param_500 = _e1127;
    let _e1128 = (*geometry_normal);
    param_501 = _e1128;
    let _e1129 = subsurface_bsdf_out;
    param_502 = _e1129;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502));
    let _e1130 = param_502;
    subsurface_bsdf_out = _e1130;
    selected_subsurface_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1131 = closureData_17;
    param_503 = _e1131;
    let _e1132 = selected_subsurface_fg_mul_out;
    param_504 = _e1132;
    let _e1133 = subsurface_bsdf_out;
    param_505 = _e1133;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_503), (&param_504), (&param_505), (&param_506));
    let _e1134 = param_506;
    selected_subsurface_add_out = _e1134;
    opaque_base_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1135 = closureData_17;
    param_507 = _e1135;
    let _e1136 = selected_subsurface_add_out;
    param_508 = _e1136;
    let _e1137 = (*subsurface_weight);
    param_509 = _e1137;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_507), (&param_508), (&param_509), (&param_510));
    let _e1138 = param_510;
    opaque_base_fg_mul_out = _e1138;
    diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1139 = closureData_17;
    param_511 = _e1139;
    let _e1140 = opaque_base_bg_weight_out;
    param_512 = _e1140;
    let _e1141 = base_color_nonnegative_out;
    param_513 = _e1141;
    let _e1142 = (*base_diffuse_roughness);
    param_514 = _e1142;
    let _e1143 = (*geometry_normal);
    param_515 = _e1143;
    param_516 = true;
    let _e1144 = diffuse_bsdf_out;
    param_517 = _e1144;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_511), (&param_512), (&param_513), (&param_514), (&param_515), (&param_516), (&param_517));
    let _e1145 = param_517;
    diffuse_bsdf_out = _e1145;
    opaque_base_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1146 = closureData_17;
    param_518 = _e1146;
    let _e1147 = opaque_base_fg_mul_out;
    param_519 = _e1147;
    let _e1148 = diffuse_bsdf_out;
    param_520 = _e1148;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_518), (&param_519), (&param_520), (&param_521));
    let _e1149 = param_521;
    opaque_base_add_out = _e1149;
    dielectric_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1150 = closureData_17;
    param_522 = _e1150;
    let _e1151 = opaque_base_add_out;
    param_523 = _e1151;
    let _e1152 = dielectric_substrate_mix_inv_out;
    param_524 = _e1152;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_522), (&param_523), (&param_524), (&param_525));
    let _e1153 = param_525;
    dielectric_substrate_bg_mul_out = _e1153;
    dielectric_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1154 = closureData_17;
    param_526 = _e1154;
    let _e1155 = dielectric_substrate_fg_mul_out;
    param_527 = _e1155;
    let _e1156 = dielectric_substrate_bg_mul_out;
    param_528 = _e1156;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_526), (&param_527), (&param_528), (&param_529));
    let _e1157 = param_529;
    dielectric_substrate_add_out = _e1157;
    dielectric_base_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1158 = closureData_17;
    param_530 = _e1158;
    let _e1159 = dielectric_reflection_tf_mix_add_out;
    param_531 = _e1159;
    let _e1160 = dielectric_substrate_add_out;
    param_532 = _e1160;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_530), (&param_531), (&param_532), (&param_533));
    let _e1161 = param_533;
    dielectric_base_out = _e1161;
    base_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1162 = closureData_17;
    param_534 = _e1162;
    let _e1163 = dielectric_base_out;
    param_535 = _e1163;
    let _e1164 = base_substrate_mix_inv_out;
    param_536 = _e1164;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_534), (&param_535), (&param_536), (&param_537));
    let _e1165 = param_537;
    base_substrate_bg_mul_out = _e1165;
    base_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1166 = closureData_17;
    param_538 = _e1166;
    let _e1167 = base_substrate_fg_mul_out;
    param_539 = _e1167;
    let _e1168 = base_substrate_bg_mul_out;
    param_540 = _e1168;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_538), (&param_539), (&param_540), (&param_541));
    let _e1169 = param_541;
    base_substrate_add_out = _e1169;
    darkened_base_substrate_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1170 = closureData_17;
    param_542 = _e1170;
    let _e1171 = base_substrate_add_out;
    param_543 = _e1171;
    let _e1172 = modulated_base_darkening_out;
    param_544 = _e1172;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_542), (&param_543), (&param_544), (&param_545));
    let _e1173 = param_545;
    darkened_base_substrate_out = _e1173;
    coat_substrate_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1174 = closureData_17;
    param_546 = _e1174;
    let _e1175 = darkened_base_substrate_out;
    param_547 = _e1175;
    let _e1176 = coat_attenuation_out;
    param_548 = _e1176;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_546), (&param_547), (&param_548), (&param_549));
    let _e1177 = param_549;
    coat_substrate_attenuated_out = _e1177;
    coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1178 = closureData_17;
    param_550 = _e1178;
    let _e1179 = coat_bsdf_out;
    param_551 = _e1179;
    let _e1180 = coat_substrate_attenuated_out;
    param_552 = _e1180;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_550), (&param_551), (&param_552), (&param_553));
    let _e1181 = param_553;
    coat_layer_out = _e1181;
    fuzz_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1182 = closureData_17;
    param_554 = _e1182;
    let _e1183 = fuzz_bsdf_out;
    param_555 = _e1183;
    let _e1184 = coat_layer_out;
    param_556 = _e1184;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_554), (&param_555), (&param_556), (&param_557));
    let _e1185 = param_557;
    fuzz_layer_out = _e1185;
    let _e1187 = fuzz_layer_out.response;
    let _e1189 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1189 + _e1187);
    let _e1192 = g_ptEmitEmission;
    if (_e1192 != 0i) {
        param_558 = 4i;
        let _e1194 = L_11;
        param_559 = _e1194;
        let _e1195 = V_14;
        param_560 = _e1195;
        let _e1196 = N_18;
        param_561 = _e1196;
        let _e1197 = P_3;
        param_562 = _e1197;
        let _e1198 = occlusion_2;
        param_563 = _e1198;
        let _e1199 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_558), (&param_559), (&param_560), (&param_561), (&param_562), (&param_563));
        closureData_18 = _e1199;
        uncoated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1200 = closureData_18;
        param_564 = _e1200;
        let _e1201 = emission_weight_out;
        param_565 = _e1201;
        mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_564), (&param_565), (&param_566));
        let _e1202 = param_566;
        uncoated_emission_edf_out = _e1202;
        coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1203 = closureData_18;
        param_567 = _e1203;
        let _e1204 = uncoated_emission_edf_out;
        param_568 = _e1204;
        let _e1205 = (*coat_color);
        param_569 = _e1205;
        mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_567), (&param_568), (&param_569), (&param_570));
        let _e1206 = param_570;
        coat_tinted_emission_edf_out = _e1206;
        coated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1207 = closureData_18;
        param_571 = _e1207;
        let _e1208 = one_minus_coat_F0_color_out;
        param_572 = _e1208;
        param_573 = vec3<f32>(0f, 0f, 0f);
        param_574 = 5f;
        let _e1209 = coat_tinted_emission_edf_out;
        param_575 = _e1209;
        mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_571), (&param_572), (&param_573), (&param_574), (&param_575), (&param_576));
        let _e1210 = param_576;
        coated_emission_edf_out = _e1210;
        emission_edf_out = vec3<f32>(0f, 0f, 0f);
        let _e1211 = closureData_18;
        param_577 = _e1211;
        let _e1212 = coated_emission_edf_out;
        param_578 = _e1212;
        let _e1213 = uncoated_emission_edf_out;
        param_579 = _e1213;
        let _e1214 = (*coat_weight);
        param_580 = _e1214;
        mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_577), (&param_578), (&param_579), (&param_580), (&param_581));
        let _e1215 = param_581;
        emission_edf_out = _e1215;
        let _e1216 = emission_edf_out;
        let _e1217 = g_ptEmission;
        g_ptEmission = (_e1217 + _e1216);
        let _e1219 = emission_edf_out;
        let _e1221 = shader_constructor_out.color;
        shader_constructor_out.color = (_e1221 + _e1219);
    }
    let _e1224 = shader_constructor_out;
    (*out1_5) = _e1224;
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

    let _e391 = g_ptN;
    normalWorld = _e391;
    let _e392 = g_ptTangent;
    tangentWorld = _e392;
    let _e393 = normalWorld;
    geomprop_Nworld_out = normalize(_e393);
    let _e395 = tangentWorld;
    geomprop_Tworld_out = normalize(_e395);
    open_pbr_surface_surfaceshader_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e397 = base_weight_1;
    param_582 = _e397;
    let _e398 = base_color_1;
    param_583 = _e398;
    let _e399 = base_diffuse_roughness_1;
    param_584 = _e399;
    let _e400 = base_metalness_1;
    param_585 = _e400;
    let _e401 = specular_weight_1;
    param_586 = _e401;
    let _e402 = specular_color_1;
    param_587 = _e402;
    let _e403 = specular_roughness_1;
    param_588 = _e403;
    let _e404 = specular_ior_1;
    param_589 = _e404;
    let _e405 = specular_roughness_anisotropy_1;
    param_590 = _e405;
    let _e406 = transmission_weight_1;
    param_591 = _e406;
    let _e407 = transmission_color_1;
    param_592 = _e407;
    let _e408 = transmission_depth_1;
    param_593 = _e408;
    let _e409 = transmission_scatter_1;
    param_594 = _e409;
    let _e410 = transmission_scatter_anisotropy_1;
    param_595 = _e410;
    let _e411 = transmission_dispersion_scale_1;
    param_596 = _e411;
    let _e412 = transmission_dispersion_abbe_number_1;
    param_597 = _e412;
    let _e413 = subsurface_weight_1;
    param_598 = _e413;
    let _e414 = subsurface_color_1;
    param_599 = _e414;
    let _e415 = subsurface_radius_1;
    param_600 = _e415;
    let _e416 = subsurface_radius_scale_1;
    param_601 = _e416;
    let _e417 = subsurface_scatter_anisotropy_1;
    param_602 = _e417;
    let _e418 = fuzz_weight_1;
    param_603 = _e418;
    let _e419 = fuzz_color_1;
    param_604 = _e419;
    let _e420 = fuzz_roughness_1;
    param_605 = _e420;
    let _e421 = coat_weight_1;
    param_606 = _e421;
    let _e422 = coat_color_1;
    param_607 = _e422;
    let _e423 = coat_roughness_1;
    param_608 = _e423;
    let _e424 = coat_roughness_anisotropy_1;
    param_609 = _e424;
    let _e425 = coat_ior_1;
    param_610 = _e425;
    let _e426 = coat_darkening_1;
    param_611 = _e426;
    let _e427 = thin_film_weight_1;
    param_612 = _e427;
    let _e428 = thin_film_thickness_1;
    param_613 = _e428;
    let _e429 = thin_film_ior_1;
    param_614 = _e429;
    let _e430 = emission_luminance_1;
    param_615 = _e430;
    let _e431 = emission_color_1;
    param_616 = _e431;
    let _e432 = geometry_opacity_1;
    param_617 = _e432;
    let _e433 = geometry_thin_walled_1;
    param_618 = _e433;
    let _e434 = geomprop_Nworld_out;
    param_619 = _e434;
    let _e435 = geomprop_Nworld_out;
    param_620 = _e435;
    let _e436 = geomprop_Tworld_out;
    param_621 = _e436;
    let _e437 = geomprop_Tworld_out;
    param_622 = _e437;
    NG_open_pbr_surface_surfaceshader_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_b1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_582), (&param_583), (&param_584), (&param_585), (&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591), (&param_592), (&param_593), (&param_594), (&param_595), (&param_596), (&param_597), (&param_598), (&param_599), (&param_600), (&param_601), (&param_602), (&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615), (&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621), (&param_622), (&param_623));
    let _e438 = param_623;
    open_pbr_surface_surfaceshader_out = _e438;
    let _e439 = open_pbr_surface_surfaceshader_out;
    return _e439;
}

fn localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vLocal: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e349 = (*basis_2).tW;
    let _e351 = (*vLocal)[0u];
    let _e354 = (*basis_2).bW;
    let _e356 = (*vLocal)[1u];
    let _e360 = (*basis_2).nW;
    let _e362 = (*vLocal)[2u];
    return (((_e349 * _e351) + (_e354 * _e356)) + (_e360 * _e362));
}

fn mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b(pW_3: ptr<function, vec3<f32>>, basis_3: ptr<function, Basis>, winputL_2: ptr<function, vec3<f32>>, woutputL_2: ptr<function, vec3<f32>>, pdf_woutputL_2: ptr<function, f32>) -> vec3<f32> {
    var param_624: vec3<f32>;
    var param_625: Basis;
    var param_626: vec3<f32>;
    var param_627: Basis;

    let _e355 = (*pW_3);
    g_ptP = _e355;
    let _e357 = (*basis_3).nW;
    g_ptN = _e357;
    let _e359 = (*basis_3).tW;
    g_ptTangent = _e359;
    let _e361 = (*basis_3).bW;
    g_ptBitangent = _e361;
    let _e362 = (*winputL_2);
    param_624 = _e362;
    let _e363 = (*basis_3);
    param_625 = _e363;
    let _e364 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_624), (&param_625));
    g_ptV = _e364;
    let _e365 = (*woutputL_2);
    param_626 = _e365;
    let _e366 = (*basis_3);
    param_627 = _e366;
    let _e367 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_626), (&param_627));
    g_ptL = _e367;
    g_ptOcclusion = 1f;
    g_ptEmitEmission = 0i;
    g_ptClosureType = 1i;
    let _e369 = (*woutputL_2)[2u];
    (*pdf_woutputL_2) = (max(_e369, 0f) / 3.1415927f);
    let _e372 = mtlxHostEvalSurface_u0028_();
    return _e372.color;
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

    let _e367 = (*surfaceshader_1);
    if (_e367 == 1i) {
        let _e369 = (*pW_4);
        param_628 = _e369;
        let _e370 = (*basis_4);
        param_629 = _e370;
        let _e371 = (*winputL_3);
        param_630 = _e371;
        let _e372 = (*woutputL_3);
        param_631 = _e372;
        let _e373 = (*pdf_woutputL_3);
        param_632 = _e373;
        let _e374 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_628), (&param_629), (&param_630), (&param_631), (&param_632));
        let _e375 = param_632;
        (*pdf_woutputL_3) = _e375;
        return _e374;
    } else {
        let _e376 = (*surfaceshader_1);
        if (_e376 == 2i) {
            let _e378 = (*pW_4);
            param_633 = _e378;
            let _e379 = (*basis_4);
            param_634 = _e379;
            let _e380 = (*winputL_3);
            param_635 = _e380;
            let _e381 = (*woutputL_3);
            param_636 = _e381;
            let _e382 = (*pdf_woutputL_3);
            param_637 = _e382;
            let _e383 = ground_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_633), (&param_634), (&param_635), (&param_636), (&param_637));
            let _e384 = param_637;
            (*pdf_woutputL_3) = _e384;
            return _e383;
        } else {
            let _e385 = (*pW_4);
            param_638 = _e385;
            let _e386 = (*basis_4);
            param_639 = _e386;
            let _e387 = (*winputL_3);
            param_640 = _e387;
            let _e388 = (*woutputL_3);
            param_641 = _e388;
            let _e389 = (*pdf_woutputL_3);
            param_642 = _e389;
            let _e390 = neutral_brdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_638), (&param_639), (&param_640), (&param_641), (&param_642));
            let _e391 = param_642;
            (*pdf_woutputL_3) = _e391;
            return _e390;
        }
    }
}

fn mtlx_openpbr_is_thinwalled_u0028_() -> bool {
    let _e346 = geometry_thin_walled_1;
    return _e346;
}

fn mtlx_openpbr_is_opaque_u0028_() -> bool {
    let _e346 = g_ptOpacity;
    return (_e346 >= 0.999999f);
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e348 = (*N_19);
    l = length(_e348);
    let _e350 = (*N_19);
    let _e351 = l;
    return (_e350 / vec3(max(_e351, 0.0000000001f)));
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_643: vec3<f32>;

    let _e350 = (*N_20)[2u];
    let _e353 = (*N_20)[0u];
    if (abs(_e350) < abs(_e353)) {
        let _e357 = (*N_20)[2u];
        let _e359 = (*N_20)[0u];
        T = vec3<f32>(_e357, 0f, -(_e359));
    } else {
        let _e363 = (*N_20)[2u];
        let _e365 = (*N_20)[1u];
        T = vec3<f32>(0f, _e363, -(_e365));
    }
    let _e368 = T;
    param_643 = _e368;
    let _e369 = safe_normalize_u0028_vf3_u003b((&param_643));
    T = _e369;
    let _e370 = T;
    return _e370;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e350 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e350).x;
    let _e353 = (*index);
    let _e354 = width;
    let _e362 = (*index);
    let _e363 = width;
    let _e366 = textureLoad(texture, vec2<i32>((_e353 - (i32(floor((f32(_e353) / f32(_e354)))) * _e354)), (_e362 / _e363)), 0i);
    return _e366;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_644: i32;
    var param_645: i32;
    var param_646: i32;

    let _e354 = (*barycoord)[0u];
    let _e356 = (*faceIndices)[0u];
    param_644 = bitcast<i32>(_e356);
    let _e358 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_644));
    let _e361 = (*barycoord)[1u];
    let _e363 = (*faceIndices)[1u];
    param_645 = bitcast<i32>(_e363);
    let _e365 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_645));
    let _e369 = (*barycoord)[2u];
    let _e371 = (*faceIndices)[2u];
    param_646 = bitcast<i32>(_e371);
    let _e373 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_646));
    return (((_e358 * _e354) + (_e365 * _e361)) + (_e373 * _e369));
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

    let _e358 = (*direction);
    inverseDirection = (vec3(1f) / _e358);
    let _e361 = (*minimum);
    let _e362 = (*origin);
    let _e364 = inverseDirection;
    t0_2 = ((_e361 - _e362) * _e364);
    let _e366 = (*maximum);
    let _e367 = (*origin);
    let _e369 = inverseDirection;
    t1_2 = ((_e366 - _e367) * _e369);
    let _e371 = t0_2;
    let _e372 = t1_2;
    entry = min(_e371, _e372);
    let _e374 = t0_2;
    let _e375 = t1_2;
    exit = max(_e374, _e375);
    let _e378 = entry[0u];
    let _e380 = entry[1u];
    let _e382 = entry[2u];
    nearDistance = max(_e378, max(_e380, _e382));
    let _e386 = exit[0u];
    let _e388 = exit[1u];
    let _e390 = exit[2u];
    farDistance = min(_e386, min(_e388, _e390));
    let _e393 = farDistance;
    let _e394 = nearDistance;
    if (_e393 >= max(_e394, 0f)) {
        let _e397 = nearDistance;
        local_10 = max(_e397, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e399 = local_10;
    return _e399;
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
    var phi_1438_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e399 = (*maxDistance);
    closest = _e399;
    found = false;
    loop {
        let _e400 = pointer;
        let _e402 = pointer;
        if ((_e400 >= 0i) && (_e402 < 64i)) {
            let _e405 = pointer;
            pointer = (_e405 - 1i);
            let _e408 = stack[_e405];
            nodeIndex = _e408;
            let _e409 = nodeIndex;
            param_647 = (_e409 * 3i);
            let _e411 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_647));
            minimum_1 = _e411;
            let _e412 = nodeIndex;
            param_648 = ((_e412 * 3i) + 1i);
            let _e415 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_648));
            maximum_1 = _e415;
            let _e416 = nodeIndex;
            param_649 = ((_e416 * 3i) + 2i);
            let _e419 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_649));
            metadata = _e419;
            let _e420 = minimum_1;
            param_650 = _e420.xyz;
            let _e422 = maximum_1;
            param_651 = _e422.xyz;
            let _e424 = (*rayOrigin);
            param_652 = _e424;
            let _e425 = (*rayDirection);
            param_653 = _e425;
            let _e426 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_650), (&param_651), (&param_652), (&param_653));
            let _e427 = closest;
            if (_e426 > _e427) {
                continue;
            }
            let _e430 = metadata[2u];
            if (_e430 > 0.5f) {
                let _e433 = metadata[0u];
                offset = i32((_e433 + 0.5f));
                let _e437 = metadata[1u];
                count = i32((_e437 + 0.5f));
                triangle = 0i;
                loop {
                    let _e440 = triangle;
                    let _e441 = count;
                    if (_e440 < _e441) {
                        let _e443 = offset;
                        let _e444 = triangle;
                        param_654 = (_e443 + _e444);
                        let _e446 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_654));
                        vertexIndices = vec3<u32>((_e446.xyz + vec3(0.5f)));
                        let _e452 = vertexIndices[0u];
                        param_655 = bitcast<i32>(_e452);
                        let _e454 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_655));
                        p0_ = _e454.xyz;
                        let _e457 = vertexIndices[1u];
                        param_656 = bitcast<i32>(_e457);
                        let _e459 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_656));
                        p1_ = _e459.xyz;
                        let _e462 = vertexIndices[2u];
                        param_657 = bitcast<i32>(_e462);
                        let _e464 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_657));
                        p2_ = _e464.xyz;
                        let _e466 = p1_;
                        let _e467 = p0_;
                        edge0_ = (_e466 - _e467);
                        let _e469 = p2_;
                        let _e470 = p0_;
                        edge1_ = (_e469 - _e470);
                        let _e472 = (*rayDirection);
                        let _e473 = edge1_;
                        pvec = cross(_e472, _e473);
                        let _e475 = edge0_;
                        let _e476 = pvec;
                        determinant_ = dot(_e475, _e476);
                        let _e478 = determinant_;
                        if (abs(_e478) < 0.00000001f) {
                            continue;
                        }
                        let _e481 = determinant_;
                        inverseDeterminant = (1f / _e481);
                        let _e483 = (*rayOrigin);
                        let _e484 = p0_;
                        tvec = (_e483 - _e484);
                        let _e486 = tvec;
                        let _e487 = pvec;
                        let _e489 = inverseDeterminant;
                        u = (dot(_e486, _e487) * _e489);
                        let _e491 = tvec;
                        let _e492 = edge0_;
                        qvec = cross(_e491, _e492);
                        let _e494 = (*rayDirection);
                        let _e495 = qvec;
                        let _e497 = inverseDeterminant;
                        v_3 = (dot(_e494, _e495) * _e497);
                        let _e499 = edge1_;
                        let _e500 = qvec;
                        let _e502 = inverseDeterminant;
                        distance_ = (dot(_e499, _e500) * _e502);
                        let _e504 = u;
                        let _e506 = v_3;
                        let _e508 = ((_e504 >= 0f) && (_e506 >= 0f));
                        phi_1438_ = _e508;
                        if _e508 {
                            let _e509 = u;
                            let _e510 = v_3;
                            phi_1438_ = ((_e509 + _e510) <= 1f);
                        }
                        let _e514 = phi_1438_;
                        let _e515 = distance_;
                        let _e518 = distance_;
                        let _e519 = closest;
                        if ((_e514 && (_e515 > 0f)) && (_e518 < _e519)) {
                            let _e522 = distance_;
                            closest = _e522;
                            let _e523 = distance_;
                            (*dist_2) = _e523;
                            let _e524 = u;
                            let _e526 = v_3;
                            let _e528 = u;
                            let _e529 = v_3;
                            (*barycoord_1) = vec3<f32>(((1f - _e524) - _e526), _e528, _e529);
                            let _e531 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e531.x, _e531.y, _e531.z, 0u);
                            let _e536 = edge0_;
                            let _e537 = edge1_;
                            (*faceNormal) = normalize(cross(_e536, _e537));
                            let _e540 = determinant_;
                            (*side) = select(1f, -1f, (_e540 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e543 = triangle;
                        triangle = (_e543 + 1i);
                    }
                }
            } else {
                let _e546 = metadata[0u];
                left = i32((_e546 + 0.5f));
                let _e550 = metadata[1u];
                right = i32((_e550 + 0.5f));
                let _e553 = pointer;
                if ((_e553 + 2i) >= 64i) {
                    continue;
                }
                let _e556 = pointer;
                let _e557 = (_e556 + 1i);
                pointer = _e557;
                let _e558 = right;
                stack[_e557] = _e558;
                let _e560 = pointer;
                let _e561 = (_e560 + 1i);
                pointer = _e561;
                let _e562 = left;
                stack[_e561] = _e562;
            }
            continue;
        } else {
            break;
        }
    }
    let _e564 = found;
    return _e564;
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

    let _e368 = (*rayOrigin_1);
    param_658 = _e368;
    let _e369 = (*rayDirection_1);
    param_659 = _e369;
    let _e370 = (*maxDistance_1);
    param_660 = _e370;
    let _e371 = (*faceIndices_2);
    param_661 = _e371;
    let _e372 = (*faceNormal_1);
    param_662 = _e372;
    let _e373 = (*barycoord_2);
    param_663 = _e373;
    let _e374 = (*side_1);
    param_664 = _e374;
    let _e375 = (*dist_3);
    param_665 = _e375;
    let _e376 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_658), (&param_659), (&param_660), (&param_661), (&param_662), (&param_663), (&param_664), (&param_665));
    let _e377 = param_661;
    (*faceIndices_2) = _e377;
    let _e378 = param_662;
    (*faceNormal_1) = _e378;
    let _e379 = param_663;
    (*barycoord_2) = _e379;
    let _e380 = param_664;
    (*side_1) = _e380;
    let _e381 = param_665;
    (*dist_3) = _e381;
    return _e376;
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
    var phi_7834_: bool;
    var phi_7856_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e388 = (*rayOrigin_2);
    param_666 = _e388;
    let _e389 = (*rayDir);
    param_667 = _e389;
    let _e390 = (*maxDistance_2);
    param_668 = _e390;
    let _e391 = faceIndices_surface;
    param_669 = _e391;
    let _e392 = faceNormal_surface;
    param_670 = _e392;
    let _e393 = barycoord_surface;
    param_671 = _e393;
    let _e394 = side_surface;
    param_672 = _e394;
    let _e395 = dist_surface;
    param_673 = _e395;
    let _e396 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_666), (&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672), (&param_673));
    let _e397 = param_669;
    faceIndices_surface = _e397;
    let _e398 = param_670;
    faceNormal_surface = _e398;
    let _e399 = param_671;
    barycoord_surface = _e399;
    let _e400 = param_672;
    side_surface = _e400;
    let _e401 = param_673;
    dist_surface = _e401;
    hit_surface = _e396;
    dist_closest = 100000000000000000000f;
    let _e402 = hit_surface;
    if _e402 {
        let _e403 = dist_closest;
        let _e404 = dist_surface;
        dist_closest = min(_e403, _e404);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e407 = (*rayDir)[1u];
    if (abs(_e407) > 0.0000000001f) {
        let _e411 = (*rayOrigin_2)[1u];
        let _e414 = (*rayDir)[1u];
        t = ((0.01f - _e411) / _e414);
        let _e416 = t;
        let _e417 = (_e416 > 0f);
        phi_7834_ = _e417;
        if _e417 {
            let _e418 = t;
            let _e419 = dist_closest;
            let _e420 = (*maxDistance_2);
            phi_7834_ = (_e418 < min(_e419, _e420));
        }
        let _e424 = phi_7834_;
        if _e424 {
            let _e425 = t;
            dist_ground = _e425;
            hit_ground = true;
        }
    }
    let _e426 = hit_surface;
    let _e427 = hit_ground;
    hit = (_e426 || _e427);
    let _e429 = hit;
    if !(_e429) {
        return false;
    }
    let _e431 = hit_surface;
    phi_7856_ = _e431;
    if _e431 {
        let _e432 = hit_ground;
        let _e434 = dist_surface;
        let _e435 = dist_ground;
        phi_7856_ = (!(_e432) || (_e434 <= _e435));
    }
    let _e439 = phi_7856_;
    if _e439 {
        let _e440 = (*rayOrigin_2);
        let _e441 = dist_surface;
        let _e442 = (*rayDir);
        (*P_4) = (_e440 + (_e442 * _e441));
        let _e445 = barycoord_surface;
        (*baryCoord) = _e445;
        let _e446 = faceNormal_surface;
        param_674 = _e446;
        let _e447 = safe_normalize_u0028_vf3_u003b((&param_674));
        (*Ng) = _e447;
        let _e448 = barycoord_surface;
        param_675 = _e448;
        let _e449 = faceIndices_surface;
        param_676 = _e449.xyz;
        let _e451 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_675), (&param_676));
        gN = _e451;
        let _e452 = barycoord_surface;
        param_677 = _e452;
        let _e453 = faceIndices_surface;
        param_678 = _e453.xyz;
        let _e455 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_677), (&param_678));
        gT = _e455;
        let _e457 = unnamed.has_normals_surface;
        if (_e457 != 0u) {
            let _e459 = gN;
            local_11 = _e459.xyz;
        } else {
            let _e461 = (*Ng);
            local_11 = _e461;
        }
        let _e462 = local_11;
        (*Ns) = _e462;
        let _e464 = unnamed.has_uvs_surface;
        if (_e464 != 0u) {
            let _e467 = gN[3u];
            let _e469 = gT[3u];
            local_12 = vec2<f32>(_e467, _e469);
        } else {
            let _e471 = barycoord_surface;
            local_12 = _e471.xy;
        }
        let _e473 = local_12;
        (*texCoord) = _e473;
        let _e475 = unnamed.has_tangents_surface;
        if (_e475 != 0u) {
            let _e477 = gT;
            local_13 = _e477.xyz;
        } else {
            let _e479 = (*Ns);
            param_679 = _e479;
            let _e480 = normalToTangent_u0028_vf3_u003b((&param_679));
            local_13 = _e480;
        }
        let _e481 = local_13;
        (*Ts) = _e481;
        let _e482 = barycoord_surface;
        param_680 = _e482;
        let _e483 = faceIndices_surface;
        param_681 = _e483.xyz;
        let _e485 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_680), (&param_681));
        (*surfaceshader_2) = select(1i, 0i, (_e485.x > 0.5f));
    } else {
        let _e489 = hit_ground;
        if _e489 {
            let _e490 = (*rayOrigin_2);
            let _e491 = dist_ground;
            let _e492 = (*rayDir);
            (*P_4) = (_e490 + (_e492 * _e491));
            (*surfaceshader_2) = 2i;
            (*baryCoord) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e495 = (*Ng);
            (*Ns) = _e495;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            let _e497 = (*P_4)[0u];
            let _e499 = (*P_4)[2u];
            (*texCoord) = (((vec2<f32>(_e497, -(_e499)) / vec2(200f)) * 2f) + vec2(0.5f));
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
    var phi_8000_: bool;
    var phi_8004_: bool;

    let _e367 = (*rayOrigin_3);
    param_682 = _e367;
    let _e368 = (*rayDir_1);
    param_683 = _e368;
    let _e369 = (*maxDistance_3);
    param_684 = _e369;
    let _e370 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687), (&param_688), (&param_689), (&param_690), (&param_691));
    let _e371 = param_685;
    pW_5 = _e371;
    let _e372 = param_686;
    nsW = _e372;
    let _e373 = param_687;
    ngW = _e373;
    let _e374 = param_688;
    TsW = _e374;
    let _e375 = param_689;
    baryCoord_1 = _e375;
    let _e376 = param_690;
    texCoord_1 = _e376;
    let _e377 = param_691;
    surfaceshader_3 = _e377;
    hit_1 = _e370;
    let _e378 = hit_1;
    let _e379 = surfaceshader_3;
    let _e381 = (_e378 && (_e379 == 1i));
    phi_8000_ = _e381;
    if _e381 {
        let _e382 = mtlx_openpbr_is_opaque_u0028_();
        phi_8000_ = !(_e382);
    }
    let _e385 = phi_8000_;
    phi_8004_ = _e385;
    if _e385 {
        let _e386 = mtlx_openpbr_is_thinwalled_u0028_();
        phi_8004_ = _e386;
    }
    let _e388 = phi_8004_;
    if _e388 {
        return 1f;
    }
    let _e389 = hit_1;
    return select(1f, 0f, _e389);
}

fn maxComponent_u0028_vf3_u003b(v_4: ptr<function, vec3<f32>>) -> f32 {
    let _e348 = (*v_4)[0u];
    let _e350 = (*v_4)[1u];
    let _e352 = (*v_4)[2u];
    return max(_e348, max(_e350, _e352));
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_5: ptr<function, Basis>) -> vec3<f32> {
    let _e348 = (*vWorld);
    let _e350 = (*basis_5).tW;
    let _e352 = (*vWorld);
    let _e354 = (*basis_5).bW;
    let _e356 = (*vWorld);
    let _e358 = (*basis_5).nW;
    return vec3<f32>(dot(_e348, _e350), dot(_e352, _e354), dot(_e356, _e358));
}

fn pcg_u0028_u1_u003b(v_5: ptr<function, u32>) -> u32 {
    var state: u32;
    var word: u32;

    let _e349 = (*v_5);
    state = ((_e349 * 747796405u) + 2891336453u);
    let _e352 = state;
    let _e353 = state;
    let _e359 = state;
    word = (((_e352 >> bitcast<u32>(((_e353 >> bitcast<u32>(28u)) + 4u))) ^ _e359) * 277803737u);
    let _e362 = word;
    let _e365 = word;
    return ((_e362 >> bitcast<u32>(22u)) ^ _e365);
}

fn rand_u0028_u1_u003b(seed: ptr<function, u32>) -> f32 {
    var param_692: u32;

    let _e348 = (*seed);
    param_692 = _e348;
    let _e349 = pcg_u0028_u1_u003b((&param_692));
    (*seed) = _e349;
    let _e350 = (*seed);
    return (f32((_e350 - 1u)) * 0.00000000023283064f);
}

fn GetMtlxLight_u0028_i1_u003b(i_4: ptr<function, i32>) -> MtlxLight {
    var t0_3: vec4<f32>;
    var t1_3: vec4<f32>;
    var t2_2: vec4<f32>;
    var t3_2: vec4<f32>;
    var t4_2: vec4<f32>;
    var t5_: vec4<f32>;
    var l_1: MtlxLight;

    let _e354 = (*i_4);
    let _e356 = textureLoad(mtlxLightsTex_texture, vec2<i32>(0i, _e354), 0i);
    t0_3 = _e356;
    let _e357 = (*i_4);
    let _e359 = textureLoad(mtlxLightsTex_texture, vec2<i32>(1i, _e357), 0i);
    t1_3 = _e359;
    let _e360 = (*i_4);
    let _e362 = textureLoad(mtlxLightsTex_texture, vec2<i32>(2i, _e360), 0i);
    t2_2 = _e362;
    let _e363 = (*i_4);
    let _e365 = textureLoad(mtlxLightsTex_texture, vec2<i32>(3i, _e363), 0i);
    t3_2 = _e365;
    let _e366 = (*i_4);
    let _e368 = textureLoad(mtlxLightsTex_texture, vec2<i32>(4i, _e366), 0i);
    t4_2 = _e368;
    let _e369 = (*i_4);
    let _e371 = textureLoad(mtlxLightsTex_texture, vec2<i32>(5i, _e369), 0i);
    t5_ = _e371;
    let _e372 = t0_3;
    l_1.position = _e372.xyz;
    let _e376 = t0_3[3u];
    l_1.decayRate = _e376;
    let _e378 = t1_3;
    l_1.direction = _e378.xyz;
    let _e382 = t1_3[3u];
    l_1.type_ = i32((_e382 + 0.5f));
    let _e386 = t2_2;
    l_1.color = _e386.xyz;
    let _e390 = t2_2[3u];
    l_1.intensity = _e390;
    let _e393 = t3_2[0u];
    l_1.innerCone = _e393;
    let _e396 = t3_2[1u];
    l_1.outerCone = _e396;
    let _e398 = t4_2;
    l_1.u = _e398.xyz;
    let _e401 = t5_;
    l_1.v = _e401.xyz;
    let _e404 = l_1;
    return _e404;
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

    let _e381 = (*index_1);
    param_693 = _e381;
    let _e382 = GetMtlxLight_u0028_i1_u003b((&param_693));
    l_2 = _e382;
    let _e384 = l_2.color;
    let _e386 = l_2.intensity;
    intensity = (_e384 * _e386);
    (*maxDistance_4) = 100000000000000000000f;
    let _e389 = l_2.type_;
    if (_e389 == 1i) {
        let _e392 = l_2.direction;
        param_694 = -(_e392);
        let _e394 = safe_normalize_u0028_vf3_u003b((&param_694));
        (*woutputW) = _e394;
    } else {
        let _e396 = l_2.type_;
        if (_e396 == 3i) {
            let _e398 = (*rndSeed);
            param_695 = _e398;
            let _e399 = rand_u0028_u1_u003b((&param_695));
            let _e400 = param_695;
            (*rndSeed) = _e400;
            let _e401 = (*rndSeed);
            param_696 = _e401;
            let _e402 = rand_u0028_u1_u003b((&param_696));
            let _e403 = param_696;
            (*rndSeed) = _e403;
            xi = vec2<f32>(_e399, _e402);
            let _e406 = l_2.position;
            let _e408 = xi[0u];
            let _e410 = l_2.u;
            let _e414 = xi[1u];
            let _e416 = l_2.v;
            pointOnLight = ((_e406 + (_e410 * _e408)) + (_e416 * _e414));
            let _e420 = l_2.u;
            let _e422 = l_2.v;
            param_697 = cross(_e420, _e422);
            let _e424 = safe_normalize_u0028_vf3_u003b((&param_697));
            lightNormal = _e424;
            let _e426 = l_2.u;
            let _e428 = l_2.v;
            area = length(cross(_e426, _e428));
            let _e431 = pointOnLight;
            let _e432 = (*pW_6);
            toLight = (_e431 - _e432);
            let _e434 = toLight;
            let _e435 = toLight;
            distSq = max(dot(_e434, _e435), 0.0000000001f);
            let _e438 = distSq;
            distanceToLight = sqrt(_e438);
            let _e440 = toLight;
            let _e441 = distanceToLight;
            (*woutputW) = (_e440 / vec3(_e441));
            let _e444 = distanceToLight;
            (*maxDistance_4) = max(0f, (_e444 - 0.0002f));
            let _e447 = lightNormal;
            let _e448 = (*woutputW);
            cosLight = max(dot(_e447, -(_e448)), 0f);
            let _e452 = cosLight;
            let _e454 = area;
            if ((_e452 <= 0f) || (_e454 <= 0f)) {
                let _e457 = (*woutputW);
                param_698 = _e457;
                let _e458 = (*basis_6);
                param_699 = _e458;
                let _e459 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_698), (&param_699));
                (*woutputL_4) = _e459;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e460 = cosLight;
            let _e461 = area;
            let _e463 = distSq;
            let _e465 = intensity;
            intensity = (_e465 * ((_e460 * _e461) / _e463));
            let _e467 = (*woutputW);
            param_700 = _e467;
            let _e468 = (*basis_6);
            param_701 = _e468;
            let _e469 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_700), (&param_701));
            (*woutputL_4) = _e469;
            let _e470 = intensity;
            return _e470;
        } else {
            let _e472 = l_2.position;
            let _e473 = (*pW_6);
            toLight_1 = (_e472 - _e473);
            let _e475 = toLight_1;
            distanceToLight_1 = max(length(_e475), 0.0000000001f);
            let _e478 = toLight_1;
            let _e479 = distanceToLight_1;
            (*woutputW) = (_e478 / vec3(_e479));
            let _e482 = distanceToLight_1;
            (*maxDistance_4) = max(0f, (_e482 - 0.0002f));
            let _e485 = distanceToLight_1;
            let _e488 = l_2.decayRate;
            attenuation = pow((_e485 + 1f), (_e488 + 0.0000000001f));
            let _e491 = attenuation;
            let _e493 = intensity;
            intensity = (_e493 / vec3(max(_e491, 0.0000000001f)));
            let _e497 = l_2.type_;
            if (_e497 == 2i) {
                let _e499 = (*woutputW);
                let _e501 = l_2.direction;
                param_702 = _e501;
                let _e502 = safe_normalize_u0028_vf3_u003b((&param_702));
                cosDir = dot(_e499, -(_e502));
                let _e506 = l_2.innerCone;
                let _e508 = l_2.outerCone;
                low = min(_e506, _e508);
                let _e511 = l_2.innerCone;
                high = _e511;
                let _e512 = low;
                let _e513 = high;
                let _e514 = cosDir;
                let _e516 = intensity;
                intensity = (_e516 * smoothstep(_e512, _e513, _e514));
            }
        }
    }
    let _e518 = (*woutputW);
    param_703 = _e518;
    let _e519 = (*basis_6);
    param_704 = _e519;
    let _e520 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_703), (&param_704));
    (*woutputL_4) = _e520;
    let _e521 = intensity;
    return _e521;
}

fn mtlxLightTotalPower_u0028_i1_u003b(index_2: ptr<function, i32>) -> f32 {
    var l_3: MtlxLight;
    var param_705: i32;
    var power: f32;

    let _e350 = (*index_2);
    param_705 = _e350;
    let _e351 = GetMtlxLight_u0028_i1_u003b((&param_705));
    l_3 = _e351;
    let _e353 = l_3.color;
    let _e355 = l_3.intensity;
    power = length((_e353 * _e355));
    let _e359 = l_3.type_;
    if (_e359 == 3i) {
        let _e362 = l_3.u;
        let _e364 = l_3.v;
        let _e367 = power;
        power = (_e367 * length(cross(_e362, _e364)));
    }
    let _e369 = power;
    return _e369;
}

fn sunPdf_u0028_vf3_u003b_vf3_u003b(woutputL_5: ptr<function, vec3<f32>>, woutputW_1: ptr<function, vec3<f32>>) -> f32 {
    var theta_max: f32;
    var solid_angle: f32;

    let _e351 = unnamed.sunAngularSize;
    theta_max = ((_e351 * 3.1415927f) / 180f);
    let _e354 = (*woutputW_1);
    let _e356 = unnamed.sunDir;
    let _e358 = theta_max;
    if (dot(_e354, _e356) < cos(_e358)) {
        return 0f;
    }
    let _e361 = theta_max;
    solid_angle = (6.2831855f * (1f - cos(_e361)));
    let _e365 = solid_angle;
    return (1f / _e365);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max_1: f32;

    let _e349 = unnamed.sunAngularSize;
    theta_max_1 = ((_e349 * 3.1415927f) / 180f);
    let _e352 = (*woutputW_2);
    let _e354 = unnamed.sunDir;
    let _e356 = theta_max_1;
    if (dot(_e352, _e354) < cos(_e356)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e360 = unnamed.sunPower;
    let _e362 = unnamed.sunColor;
    return (_e362 * _e360);
}

fn envMapLuminance_u0028_vf3_u003b(c_3: ptr<function, vec3<f32>>) -> f32 {
    let _e347 = (*c_3);
    return dot(_e347, vec3<f32>(0.212671f, 0.71516f, 0.072169f));
}

fn envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b(uv_3: ptr<function, vec2<f32>>, color_7: ptr<function, vec3<f32>>) -> f32 {
    var theta_1: f32;
    var s_4: f32;
    var pdf_2: f32;
    var param_706: vec3<f32>;

    let _e353 = (*uv_3)[1u];
    theta_1 = (_e353 * 3.1415927f);
    let _e355 = theta_1;
    s_4 = sin(_e355);
    let _e357 = s_4;
    if (_e357 <= 0f) {
        return 0f;
    }
    let _e359 = (*color_7);
    param_706 = _e359;
    let _e360 = envMapLuminance_u0028_vf3_u003b((&param_706));
    let _e362 = unnamed.envMapTotalSum;
    pdf_2 = (_e360 / max(_e362, 0.0000000001f));
    let _e365 = pdf_2;
    let _e368 = unnamed.envMapRes[0u];
    let _e372 = unnamed.envMapRes[1u];
    let _e374 = s_4;
    return (((_e365 * _e368) * _e372) / (19.739208f * _e374));
}

fn envMapUvToDir_u0028_vf2_u003b(uv_4: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi_1: f32;
    var theta_2: f32;
    var s_5: f32;

    let _e351 = (*uv_4)[0u];
    phi_1 = (_e351 * 6.2831855f);
    let _e354 = (*uv_4)[1u];
    theta_2 = (_e354 * 3.1415927f);
    let _e356 = theta_2;
    s_5 = sin(_e356);
    let _e358 = s_5;
    let _e360 = phi_1;
    let _e363 = theta_2;
    let _e365 = s_5;
    let _e367 = phi_1;
    return vec3<f32>((-(_e358) * cos(_e360)), cos(_e363), (-(_e365) * sin(_e367)));
}

fn envMapBinarySearch_u0028_f1_u003b(value: ptr<function, f32>) -> vec2<f32> {
    var res: vec2<i32>;
    var lower: i32;
    var upper: i32;
    var mid: i32;
    var y_5: i32;
    var mid_1: i32;
    var x_11: i32;

    let _e355 = unnamed.envMapRes;
    res = vec2<i32>(_e355);
    lower = 0i;
    let _e358 = res[1u];
    upper = (_e358 - 1i);
    loop {
        let _e360 = lower;
        let _e361 = upper;
        if (_e360 < _e361) {
            let _e363 = lower;
            let _e364 = upper;
            mid = ((_e363 + _e364) >> bitcast<u32>(1i));
            let _e368 = (*value);
            let _e370 = res[0u];
            let _e372 = mid;
            let _e374 = textureLoad(envMapCDFTex_texture, vec2<i32>((_e370 - 1i), _e372), 0i);
            if (_e368 < _e374.x) {
                let _e377 = mid;
                upper = _e377;
            } else {
                let _e378 = mid;
                lower = (_e378 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e380 = lower;
    let _e382 = res[1u];
    y_5 = clamp(_e380, 0i, (_e382 - 1i));
    lower = 0i;
    let _e386 = res[0u];
    upper = (_e386 - 1i);
    loop {
        let _e388 = lower;
        let _e389 = upper;
        if (_e388 < _e389) {
            let _e391 = lower;
            let _e392 = upper;
            mid_1 = ((_e391 + _e392) >> bitcast<u32>(1i));
            let _e396 = (*value);
            let _e397 = mid_1;
            let _e398 = y_5;
            let _e400 = textureLoad(envMapCDFTex_texture, vec2<i32>(_e397, _e398), 0i);
            if (_e396 < _e400.x) {
                let _e403 = mid_1;
                upper = _e403;
            } else {
                let _e404 = mid_1;
                lower = (_e404 + 1i);
            }
            continue;
        } else {
            break;
        }
    }
    let _e406 = lower;
    let _e408 = res[0u];
    x_11 = clamp(_e406, 0i, (_e408 - 1i));
    let _e411 = x_11;
    let _e413 = y_5;
    let _e417 = unnamed.envMapRes;
    return (vec2<f32>(f32(_e411), f32(_e413)) / _e417);
}

fn skyRadiance_u0028_vf3_u003b(woutputW_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e349 = (*woutputW_3)[0u];
    let _e350 = (*woutputW_3);
    let _e351 = _e350.yz;
    let _e355 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e349, _e351.x, _e351.y), 0f);
    env = _e355;
    let _e356 = env;
    let _e359 = unnamed.skyPower;
    let _e362 = unnamed.skyColor;
    return ((_e356.xyz * _e359) * _e362);
}

fn sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b(rndSeed_1: ptr<function, u32>, pdf_3: ptr<function, f32>) -> vec3<f32> {
    var r_3: f32;
    var param_707: u32;
    var theta_3: f32;
    var param_708: u32;
    var x_12: f32;
    var y_6: f32;
    var z_1: f32;

    let _e355 = (*rndSeed_1);
    param_707 = _e355;
    let _e356 = rand_u0028_u1_u003b((&param_707));
    let _e357 = param_707;
    (*rndSeed_1) = _e357;
    r_3 = sqrt(_e356);
    let _e359 = (*rndSeed_1);
    param_708 = _e359;
    let _e360 = rand_u0028_u1_u003b((&param_708));
    let _e361 = param_708;
    (*rndSeed_1) = _e361;
    theta_3 = (6.2831855f * _e360);
    let _e363 = r_3;
    let _e364 = theta_3;
    x_12 = (_e363 * cos(_e364));
    let _e367 = r_3;
    let _e368 = theta_3;
    y_6 = (_e367 * sin(_e368));
    let _e371 = x_12;
    let _e372 = x_12;
    let _e375 = y_6;
    let _e376 = y_6;
    z_1 = sqrt(max(0f, ((1f - (_e371 * _e372)) - (_e375 * _e376))));
    let _e381 = z_1;
    (*pdf_3) = max(0.000001f, (abs(_e381) / 3.1415927f));
    let _e385 = x_12;
    let _e386 = y_6;
    let _e387 = z_1;
    return vec3<f32>(_e385, _e386, _e387);
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

    let _e367 = unnamed.has_env_cdf;
    if !((_e367 != 0u)) {
        let _e370 = (*rndSeed_2);
        param_709 = _e370;
        let _e371 = (*pdfDir);
        param_710 = _e371;
        let _e372 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_709), (&param_710));
        let _e373 = param_709;
        (*rndSeed_2) = _e373;
        let _e374 = param_710;
        (*pdfDir) = _e374;
        (*woutputL_6) = _e372;
        let _e375 = (*woutputL_6);
        param_711 = _e375;
        let _e376 = (*basis_7);
        param_712 = _e376;
        let _e377 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_711), (&param_712));
        (*woutputW_4) = _e377;
        let _e378 = (*woutputW_4);
        param_713 = _e378;
        let _e379 = skyRadiance_u0028_vf3_u003b((&param_713));
        return _e379;
    }
    let _e380 = (*rndSeed_2);
    param_714 = _e380;
    let _e381 = rand_u0028_u1_u003b((&param_714));
    let _e382 = param_714;
    (*rndSeed_2) = _e382;
    let _e384 = unnamed.envMapTotalSum;
    param_715 = (_e381 * max(_e384, 0.0000000001f));
    let _e387 = envMapBinarySearch_u0028_f1_u003b((&param_715));
    uv_5 = _e387;
    let _e388 = uv_5;
    param_716 = _e388;
    let _e389 = envMapUvToDir_u0028_vf2_u003b((&param_716));
    param_717 = _e389;
    let _e390 = safe_normalize_u0028_vf3_u003b((&param_717));
    (*woutputW_4) = _e390;
    let _e391 = (*woutputW_4);
    param_718 = _e391;
    let _e392 = (*basis_7);
    param_719 = _e392;
    let _e393 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_718), (&param_719));
    (*woutputL_6) = _e393;
    let _e394 = uv_5;
    let _e395 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e394, 0f);
    color_8 = _e395.xyz;
    let _e397 = uv_5;
    param_720 = _e397;
    let _e398 = color_8;
    param_721 = _e398;
    let _e399 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_720), (&param_721));
    (*pdfDir) = _e399;
    let _e401 = unnamed.skyPower;
    let _e403 = unnamed.skyColor;
    let _e405 = color_8;
    return ((_e403 * _e401) * _e405);
}

fn envMapDirToUv_u0028_vf3_u003b(d: ptr<function, vec3<f32>>) -> vec2<f32> {
    var theta_4: f32;

    let _e349 = (*d)[1u];
    theta_4 = acos(clamp(_e349, -1f, 1f));
    let _e353 = (*d)[2u];
    let _e355 = (*d)[0u];
    let _e359 = theta_4;
    return vec2<f32>(((3.1415927f + atan2(_e353, _e355)) * 0.15915494f), (_e359 * 0.31830987f));
}

fn skyPdf_u0028_vf3_u003b_vf3_u003b(woutputL_7: ptr<function, vec3<f32>>, woutputW_5: ptr<function, vec3<f32>>) -> f32 {
    var param_722: vec3<f32>;
    var uv_6: vec2<f32>;
    var param_723: vec3<f32>;
    var param_724: vec3<f32>;
    var color_9: vec3<f32>;
    var param_725: vec2<f32>;
    var param_726: vec3<f32>;

    let _e356 = unnamed.has_env_cdf;
    if !((_e356 != 0u)) {
        let _e359 = (*woutputL_7);
        param_722 = _e359;
        let _e360 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_722));
        return _e360;
    }
    let _e361 = (*woutputW_5);
    param_723 = _e361;
    let _e362 = safe_normalize_u0028_vf3_u003b((&param_723));
    param_724 = _e362;
    let _e363 = envMapDirToUv_u0028_vf3_u003b((&param_724));
    uv_6 = _e363;
    let _e364 = uv_6;
    let _e365 = textureSampleLevel(envMapEquirect_texture, envMapEquirect_sampler, _e364, 0f);
    color_9 = _e365.xyz;
    let _e367 = uv_6;
    param_725 = _e367;
    let _e368 = color_9;
    param_726 = _e368;
    let _e369 = envMapPdfFromUv_u0028_vf2_u003b_vf3_u003b((&param_725), (&param_726));
    return _e369;
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

    let _e369 = unnamed.sunAngularSize;
    theta_max_2 = ((_e369 * 3.1415927f) / 180f);
    let _e372 = theta_max_2;
    let _e373 = (*rndSeed_3);
    param_727 = _e373;
    let _e374 = rand_u0028_u1_u003b((&param_727));
    let _e375 = param_727;
    (*rndSeed_3) = _e375;
    theta_5 = (_e372 * sqrt(_e374));
    let _e378 = theta_5;
    costheta = cos(_e378);
    let _e380 = costheta;
    let _e381 = costheta;
    sintheta = sqrt(max(0f, (1f - (_e380 * _e381))));
    let _e386 = (*rndSeed_3);
    param_728 = _e386;
    let _e387 = rand_u0028_u1_u003b((&param_728));
    let _e388 = param_728;
    (*rndSeed_3) = _e388;
    phi_2 = (6.2831855f * _e387);
    let _e390 = phi_2;
    cosphi = cos(_e390);
    let _e392 = phi_2;
    sinphi = sin(_e392);
    let _e394 = sintheta;
    let _e395 = cosphi;
    x_13 = (_e394 * _e395);
    let _e397 = sintheta;
    let _e398 = sinphi;
    y_7 = (_e397 * _e398);
    let _e400 = costheta;
    z_2 = _e400;
    let _e401 = theta_max_2;
    solid_angle_1 = (6.2831855f * (1f - cos(_e401)));
    let _e405 = solid_angle_1;
    (*pdfDir_1) = (1f / _e405);
    let _e407 = x_13;
    let _e408 = y_7;
    let _e409 = z_2;
    param_729 = vec3<f32>(_e407, _e408, _e409);
    let _e411 = sunBasis;
    param_730 = _e411;
    let _e412 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_729), (&param_730));
    (*woutputW_6) = _e412;
    let _e413 = (*woutputW_6);
    param_731 = _e413;
    let _e414 = (*basis_8);
    param_732 = _e414;
    let _e415 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_731), (&param_732));
    (*woutputL_8) = _e415;
    let _e417 = unnamed.sunPower;
    let _e419 = unnamed.sunColor;
    let _e421 = solid_angle_1;
    return ((_e419 * _e417) / vec3(_e421));
}

fn skyTotalPower_u0028_() -> f32 {
    let _e347 = unnamed.skyPower;
    let _e349 = unnamed.skyColor;
    return (length((_e349 * _e347)) * 6.2831855f);
}

fn sunTotalPower_u0028_() -> f32 {
    let _e347 = unnamed.sunPower;
    let _e349 = unnamed.sunColor;
    return length((_e349 * _e347));
}

fn mtlxLightsTotalPower_u0028_() -> f32 {
    var power_1: f32;
    var i_5: i32;
    var param_733: i32;

    power_1 = 0f;
    i_5 = 0i;
    loop {
        let _e349 = i_5;
        if (_e349 < 1i) {
            let _e351 = i_5;
            let _e353 = unnamed.mtlxLightCount;
            if (_e351 >= _e353) {
                break;
            }
            let _e355 = i_5;
            param_733 = _e355;
            let _e356 = mtlxLightTotalPower_u0028_i1_u003b((&param_733));
            let _e357 = power_1;
            power_1 = (_e357 + _e356);
            continue;
        } else {
            break;
        }
        continuing {
            let _e359 = i_5;
            i_5 = (_e359 + 1i);
        }
    }
    let _e361 = power_1;
    return _e361;
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
    var phi_9052_: bool;

    let _e413 = mtlxLightsTotalPower_u0028_();
    w_mtlx = _e413;
    let _e415 = unnamed.mtlxDisableSun;
    let _e416 = (_e415 != 0u);
    phi_9052_ = _e416;
    if !(_e416) {
        let _e419 = unnamed.mtlxLightCount;
        phi_9052_ = (_e419 > 0i);
    }
    let _e422 = phi_9052_;
    if _e422 {
        local_14 = 0f;
    } else {
        let _e423 = sunTotalPower_u0028_();
        local_14 = _e423;
    }
    let _e424 = local_14;
    w_sun = _e424;
    let _e425 = skyTotalPower_u0028_();
    w_sky = _e425;
    let _e426 = w_sun;
    let _e427 = w_sky;
    let _e429 = w_mtlx;
    w_total = max(0.0000000001f, ((_e426 + _e427) + _e429));
    let _e432 = w_sun;
    let _e433 = w_total;
    P_sun = (_e432 / _e433);
    let _e435 = w_sky;
    let _e436 = w_total;
    P_sky = (_e435 / _e436);
    let _e438 = w_mtlx;
    let _e439 = w_total;
    P_mtlx = (_e438 / _e439);
    let _e441 = (*rndSeed_4);
    param_734 = _e441;
    let _e442 = rand_u0028_u1_u003b((&param_734));
    let _e443 = param_734;
    (*rndSeed_4) = _e443;
    r_4 = _e442;
    maxDistance_5 = 100000000000000000000f;
    let _e444 = r_4;
    let _e445 = P_sun;
    if (_e444 < _e445) {
        let _e447 = (*basis_9);
        param_735 = _e447;
        let _e448 = (*shadowL);
        param_736 = _e448;
        let _e449 = (*shadowW);
        param_737 = _e449;
        let _e450 = pdf_sun;
        param_738 = _e450;
        let _e451 = (*rndSeed_4);
        param_739 = _e451;
        let _e452 = sunSample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_735), (&param_736), (&param_737), (&param_738), (&param_739));
        let _e453 = param_736;
        (*shadowL) = _e453;
        let _e454 = param_737;
        (*shadowW) = _e454;
        let _e455 = param_738;
        pdf_sun = _e455;
        let _e456 = param_739;
        (*rndSeed_4) = _e456;
        Li_7 = _e452;
        let _e457 = (*shadowW);
        param_740 = _e457;
        let _e458 = skyRadiance_u0028_vf3_u003b((&param_740));
        let _e459 = Li_7;
        Li_7 = (_e459 + _e458);
        let _e461 = (*shadowL);
        param_741 = _e461;
        let _e462 = (*shadowW);
        param_742 = _e462;
        let _e463 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_741), (&param_742));
        pdf_sky = _e463;
    } else {
        let _e464 = r_4;
        let _e465 = P_sun;
        let _e466 = P_sky;
        if (_e464 < (_e465 + _e466)) {
            let _e469 = (*basis_9);
            param_743 = _e469;
            let _e470 = (*rndSeed_4);
            param_747 = _e470;
            let _e471 = skySample_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_743), (&param_744), (&param_745), (&param_746), (&param_747));
            let _e472 = param_744;
            (*shadowL) = _e472;
            let _e473 = param_745;
            (*shadowW) = _e473;
            let _e474 = param_746;
            pdf_sky = _e474;
            let _e475 = param_747;
            (*rndSeed_4) = _e475;
            Li_7 = _e471;
            let _e476 = w_sun;
            if (_e476 > 0f) {
                let _e478 = (*shadowW);
                param_748 = _e478;
                let _e479 = sunRadiance_u0028_vf3_u003b((&param_748));
                let _e480 = Li_7;
                Li_7 = (_e480 + _e479);
            }
            let _e482 = (*shadowL);
            param_749 = _e482;
            let _e483 = (*shadowW);
            param_750 = _e483;
            let _e484 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_749), (&param_750));
            pdf_sun = _e484;
        } else {
            let _e485 = (*rndSeed_4);
            param_751 = _e485;
            let _e486 = rand_u0028_u1_u003b((&param_751));
            let _e487 = param_751;
            (*rndSeed_4) = _e487;
            let _e488 = w_mtlx;
            target_ = (_e486 * max(_e488, 0.0000000001f));
            accum = 0f;
            selected = 0i;
            i_6 = 0i;
            loop {
                let _e491 = i_6;
                if (_e491 < 1i) {
                    let _e493 = i_6;
                    let _e495 = unnamed.mtlxLightCount;
                    if (_e493 >= _e495) {
                        break;
                    }
                    let _e497 = i_6;
                    param_752 = _e497;
                    let _e498 = mtlxLightTotalPower_u0028_i1_u003b((&param_752));
                    let _e499 = accum;
                    accum = (_e499 + _e498);
                    let _e501 = target_;
                    let _e502 = accum;
                    if (_e501 <= _e502) {
                        let _e504 = i_6;
                        selected = _e504;
                        break;
                    }
                    continue;
                } else {
                    break;
                }
                continuing {
                    let _e505 = i_6;
                    i_6 = (_e505 + 1i);
                }
            }
            let _e507 = selected;
            param_753 = _e507;
            let _e508 = mtlxLightTotalPower_u0028_i1_u003b((&param_753));
            selectedPower = max(_e508, 0.0000000001f);
            let _e510 = selected;
            param_754 = _e510;
            let _e511 = (*pW_7);
            param_755 = _e511;
            let _e512 = (*basis_9);
            param_756 = _e512;
            let _e513 = (*rndSeed_4);
            param_760 = _e513;
            let _e514 = mtlxLightSample_u0028_i1_u003b_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760));
            let _e515 = param_757;
            (*shadowL) = _e515;
            let _e516 = param_758;
            (*shadowW) = _e516;
            let _e517 = param_759;
            maxDistance_5 = _e517;
            let _e518 = param_760;
            (*rndSeed_4) = _e518;
            Li_7 = _e514;
            let _e519 = (*shadowL);
            param_761 = _e519;
            let _e520 = (*shadowW);
            param_762 = _e520;
            let _e521 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_761), (&param_762));
            pdf_sun = _e521;
            let _e522 = (*shadowL);
            param_763 = _e522;
            let _e523 = (*shadowW);
            param_764 = _e523;
            let _e524 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_763), (&param_764));
            pdf_sky = _e524;
            let _e525 = P_mtlx;
            let _e526 = selectedPower;
            let _e528 = w_mtlx;
            (*lightPdf) = ((_e525 * _e526) / max(_e528, 0.0000000001f));
            let _e532 = (*shadowL)[2u];
            if (_e532 < 0f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e534 = Li_7;
            param_765 = _e534;
            let _e535 = maxComponent_u0028_vf3_u003b((&param_765));
            if (_e535 < 0.000000000001f) {
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e537 = (*pW_7);
            let _e539 = (*basis_9).nW;
            let _e540 = (*shadowW);
            let _e542 = (*basis_9).nW;
            shadowOrigin = (_e537 + ((_e539 * sign(dot(_e540, _e542))) * 0.0001f));
            let _e548 = shadowOrigin;
            param_766 = _e548;
            let _e549 = (*shadowW);
            param_767 = _e549;
            let _e550 = maxDistance_5;
            param_768 = _e550;
            let _e551 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_766), (&param_767), (&param_768));
            visibility = _e551;
            let _e552 = visibility;
            let _e553 = Li_7;
            return (_e553 * _e552);
        }
    }
    let _e555 = P_sun;
    let _e556 = pdf_sun;
    let _e558 = P_sky;
    let _e559 = pdf_sky;
    (*lightPdf) = ((_e555 * _e556) + (_e558 * _e559));
    let _e563 = (*shadowL)[2u];
    if (_e563 < 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e565 = Li_7;
    param_769 = _e565;
    let _e566 = maxComponent_u0028_vf3_u003b((&param_769));
    if (_e566 < 0.000000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e568 = (*pW_7);
    let _e570 = (*basis_9).nW;
    let _e571 = (*shadowW);
    let _e573 = (*basis_9).nW;
    shadowOrigin_1 = (_e568 + ((_e570 * sign(dot(_e571, _e573))) * 0.0001f));
    let _e579 = shadowOrigin_1;
    param_770 = _e579;
    let _e580 = (*shadowW);
    param_771 = _e580;
    param_772 = 100000000000000000000f;
    let _e581 = TraceShadow_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_770), (&param_771), (&param_772));
    visibility_1 = _e581;
    let _e582 = visibility_1;
    let _e583 = Li_7;
    return (_e583 * _e582);
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_8: ptr<function, vec3<f32>>, basis_10: ptr<function, Basis>, winputL_4: ptr<function, vec3<f32>>, rndSeed_5: ptr<function, u32>) {
    var param_773: vec3<f32>;
    var param_774: Basis;

    let _e352 = (*pW_8);
    g_ptP = _e352;
    let _e354 = (*basis_10).nW;
    g_ptN = _e354;
    let _e356 = (*basis_10).tW;
    g_ptTangent = _e356;
    let _e358 = (*basis_10).bW;
    g_ptBitangent = _e358;
    let _e360 = (*basis_10).texCoord;
    g_ptTexcoord = _e360;
    let _e361 = (*winputL_4);
    param_773 = _e361;
    let _e362 = (*basis_10);
    param_774 = _e362;
    let _e363 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_773), (&param_774));
    g_ptV = _e363;
    let _e365 = (*basis_10).nW;
    g_ptL = _e365;
    g_ptOcclusion = 1f;
    g_ptClosureType = 4i;
    g_ptEmitEmission = 1i;
    let _e366 = geometry_opacity_1;
    g_ptOpacity = clamp(_e366, 0f, 1f);
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    let _e368 = mtlxHostEvalSurface_u0028_();
    let _e369 = (*rndSeed_5);
    (*rndSeed_5) = (_e369 + 0u);
    return;
}

fn mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(pW_9: ptr<function, vec3<f32>>, basis_11: ptr<function, Basis>) -> vec3<f32> {
    var emissionSeed: u32;
    var param_775: vec3<f32>;
    var param_776: Basis;
    var param_777: vec3<f32>;
    var param_778: u32;

    emissionSeed = 0u;
    let _e353 = (*pW_9);
    param_775 = _e353;
    let _e354 = (*basis_11);
    param_776 = _e354;
    param_777 = vec3<f32>(0f, 0f, 1f);
    let _e355 = emissionSeed;
    param_778 = _e355;
    mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_775), (&param_776), (&param_777), (&param_778));
    let _e356 = param_778;
    emissionSeed = _e356;
    let _e357 = g_ptEmission;
    return max(_e357, vec3<f32>(0f, 0f, 0f));
}

fn evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b(pW_10: ptr<function, vec3<f32>>, basis_12: ptr<function, Basis>, winputL_5: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_779: vec3<f32>;
    var param_780: Basis;

    let _e351 = (*pW_10);
    param_779 = _e351;
    let _e352 = (*basis_12);
    param_780 = _e352;
    let _e353 = mtlx_openpbr_emission_at_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_779), (&param_780));
    return _e353;
}

fn neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_11: ptr<function, vec3<f32>>, basis_13: ptr<function, Basis>, winputL_6: ptr<function, vec3<f32>>, rndSeed_6: ptr<function, u32>, woutputL_9: ptr<function, vec3<f32>>, pdf_woutputL_4: ptr<function, f32>) -> vec3<f32> {
    var param_781: u32;
    var param_782: f32;
    var param_783: vec3<f32>;
    var phi_8073_: bool;

    let _e356 = (*winputL_6)[2u];
    if (_e356 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e358 = (*rndSeed_6);
    param_781 = _e358;
    let _e359 = (*pdf_woutputL_4);
    param_782 = _e359;
    let _e360 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_781), (&param_782));
    let _e361 = param_781;
    (*rndSeed_6) = _e361;
    let _e362 = param_782;
    (*pdf_woutputL_4) = _e362;
    (*woutputL_9) = _e360;
    let _e364 = unnamed.wireframe;
    let _e365 = (_e364 != 0u);
    phi_8073_ = _e365;
    if _e365 {
        let _e367 = (*basis_13).baryCoord;
        param_783 = _e367;
        let _e368 = minComponent_u0028_vf3_u003b((&param_783));
        phi_8073_ = (_e368 < 0.003f);
    }
    let _e371 = phi_8073_;
    if _e371 {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e373 = unnamed.neutral_color;
    return (_e373 / vec3(3.1415927f));
}

fn ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b(pW_12: ptr<function, vec3<f32>>, basis_14: ptr<function, Basis>, winputL_7: ptr<function, vec3<f32>>, rndSeed_7: ptr<function, u32>, woutputL_10: ptr<function, vec3<f32>>, pdf_woutputL_5: ptr<function, f32>) -> vec3<f32> {
    var param_784: u32;
    var param_785: f32;
    var param_786: vec3<f32>;

    let _e356 = (*winputL_7)[2u];
    if (_e356 < 0.0000000001f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e358 = (*rndSeed_7);
    param_784 = _e358;
    let _e359 = (*pdf_woutputL_5);
    param_785 = _e359;
    let _e360 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_784), (&param_785));
    let _e361 = param_784;
    (*rndSeed_7) = _e361;
    let _e362 = param_785;
    (*pdf_woutputL_5) = _e362;
    (*woutputL_10) = _e360;
    let _e363 = (*pW_12);
    param_786 = _e363;
    let _e364 = ground_albedo_u0028_vf3_u003b((&param_786));
    return (_e364 / vec3(3.1415927f));
}

fn ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b(w_1: ptr<function, vec3<f32>>, alpha_x: ptr<function, f32>, alpha_y: ptr<function, f32>) -> f32 {
    let _e350 = (*w_1)[2u];
    if (abs(_e350) < 0.00000011920929f) {
        return 0f;
    }
    let _e353 = (*alpha_x);
    let _e355 = (*w_1)[0u];
    let _e357 = (*alpha_x);
    let _e359 = (*w_1)[0u];
    let _e362 = (*alpha_y);
    let _e364 = (*w_1)[1u];
    let _e366 = (*alpha_y);
    let _e368 = (*w_1)[1u];
    let _e373 = (*w_1)[2u];
    let _e375 = (*w_1)[2u];
    return ((-1f + sqrt((1f + ((((_e353 * _e355) * (_e357 * _e359)) + ((_e362 * _e364) * (_e366 * _e368))) / (_e373 * _e375))))) / 2f);
}

fn ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(woL: ptr<function, vec3<f32>>, wiL_1: ptr<function, vec3<f32>>, alpha_x_1: ptr<function, f32>, alpha_y_1: ptr<function, f32>) -> f32 {
    var param_787: vec3<f32>;
    var param_788: f32;
    var param_789: f32;
    var param_790: vec3<f32>;
    var param_791: f32;
    var param_792: f32;

    let _e356 = (*woL);
    param_787 = _e356;
    let _e357 = (*alpha_x_1);
    param_788 = _e357;
    let _e358 = (*alpha_y_1);
    param_789 = _e358;
    let _e359 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_787), (&param_788), (&param_789));
    let _e361 = (*wiL_1);
    param_790 = _e361;
    let _e362 = (*alpha_x_1);
    param_791 = _e362;
    let _e363 = (*alpha_y_1);
    param_792 = _e363;
    let _e364 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_790), (&param_791), (&param_792));
    return (1f / ((1f + _e359) + _e364));
}

fn ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b(m_5: ptr<function, vec3<f32>>, alpha_x_2: ptr<function, f32>, alpha_y_2: ptr<function, f32>) -> f32 {
    var ax: f32;
    var ay: f32;
    var Ddenom: f32;

    let _e352 = (*alpha_x_2);
    ax = max(_e352, 0.0000000001f);
    let _e354 = (*alpha_y_2);
    ay = max(_e354, 0.0000000001f);
    let _e356 = ax;
    let _e358 = ay;
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
    let _e386 = (*m_5)[0u];
    let _e387 = ax;
    let _e390 = (*m_5)[0u];
    let _e391 = ax;
    let _e395 = (*m_5)[1u];
    let _e396 = ay;
    let _e399 = (*m_5)[1u];
    let _e400 = ay;
    let _e405 = (*m_5)[2u];
    let _e407 = (*m_5)[2u];
    Ddenom = (((3.1415927f * _e356) * _e358) * (((((_e361 / _e362) * (_e365 / _e366)) + ((_e370 / _e371) * (_e374 / _e375))) + (_e380 * _e382)) * ((((_e386 / _e387) * (_e390 / _e391)) + ((_e395 / _e396) * (_e399 / _e400))) + (_e405 * _e407))));
    let _e412 = Ddenom;
    return (1f / max(_e412, 0.0000000001f));
}

fn ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b(w_2: ptr<function, vec3<f32>>, alpha_x_3: ptr<function, f32>, alpha_y_3: ptr<function, f32>) -> f32 {
    var param_793: vec3<f32>;
    var param_794: f32;
    var param_795: f32;

    let _e352 = (*w_2);
    param_793 = _e352;
    let _e353 = (*alpha_x_3);
    param_794 = _e353;
    let _e354 = (*alpha_y_3);
    param_795 = _e354;
    let _e355 = ggx_lambda_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_793), (&param_794), (&param_795));
    return (1f / (1f + _e355));
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

    let _e362 = (*rndSeed_8);
    param_796 = _e362;
    let _e363 = rand_u0028_u1_u003b((&param_796));
    let _e364 = param_796;
    (*rndSeed_8) = _e364;
    let _e365 = (*rndSeed_8);
    param_797 = _e365;
    let _e366 = rand_u0028_u1_u003b((&param_797));
    let _e367 = param_797;
    (*rndSeed_8) = _e367;
    Xi_2 = vec2<f32>(_e363, _e366);
    let _e369 = (*wiL_2);
    V_15 = _e369;
    let _e370 = (*alpha_x_4);
    let _e371 = (*alpha_y_4);
    alpha_12 = vec2<f32>(_e370, _e371);
    let _e373 = V_15;
    let _e375 = alpha_12;
    let _e376 = (_e373.xy * _e375);
    let _e378 = V_15[2u];
    V_15 = normalize(vec3<f32>(_e376.x, _e376.y, _e378));
    let _e384 = Xi_2[0u];
    phi_3 = (6.2831855f * _e384);
    let _e387 = Xi_2[1u];
    let _e390 = V_15[2u];
    let _e394 = V_15[2u];
    z_3 = (((1f - _e387) * (1f + _e390)) - _e394);
    let _e396 = z_3;
    let _e397 = z_3;
    sinTheta_1 = sqrt(clamp((1f - (_e396 * _e397)), 0f, 1f));
    let _e402 = sinTheta_1;
    let _e403 = phi_3;
    x_14 = (_e402 * cos(_e403));
    let _e406 = sinTheta_1;
    let _e407 = phi_3;
    y_8 = (_e406 * sin(_e407));
    let _e410 = x_14;
    let _e411 = y_8;
    let _e412 = z_3;
    c_4 = vec3<f32>(_e410, _e411, _e412);
    let _e414 = c_4;
    let _e415 = V_15;
    H_7 = (_e414 + _e415);
    let _e417 = H_7;
    let _e419 = alpha_12;
    let _e420 = (_e417.xy * _e419);
    let _e422 = H_7[2u];
    H_7 = normalize(vec3<f32>(_e420.x, _e420.y, _e422));
    let _e427 = H_7;
    return _e427;
}

fn FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b(mui: ptr<function, f32>, eta_ti: ptr<function, f32>) -> f32 {
    var c_5: f32;
    var mut2_: f32;
    var g_1: f32;

    let _e351 = (*mui);
    c_5 = _e351;
    let _e352 = (*eta_ti);
    let _e353 = (*eta_ti);
    let _e355 = c_5;
    let _e356 = c_5;
    mut2_ = (((_e352 * _e353) + (_e355 * _e356)) - 1f);
    let _e360 = mut2_;
    if (_e360 <= 0f) {
        return 1f;
    }
    let _e362 = mut2_;
    g_1 = sqrt(_e362);
    let _e364 = g_1;
    let _e365 = c_5;
    let _e367 = g_1;
    let _e368 = c_5;
    let _e371 = g_1;
    let _e372 = c_5;
    let _e374 = g_1;
    let _e375 = c_5;
    let _e380 = g_1;
    let _e381 = c_5;
    let _e383 = c_5;
    let _e386 = g_1;
    let _e387 = c_5;
    let _e389 = c_5;
    let _e393 = g_1;
    let _e394 = c_5;
    let _e396 = c_5;
    let _e399 = g_1;
    let _e400 = c_5;
    let _e402 = c_5;
    return ((0.5f * (((_e364 - _e365) / (_e367 + _e368)) * ((_e371 - _e372) / (_e374 + _e375)))) * (1f + (((((_e380 + _e381) * _e383) - 1f) / (((_e386 - _e387) * _e389) + 1f)) * ((((_e393 + _e394) * _e396) - 1f) / (((_e399 - _e400) * _e402) + 1f)))));
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
    var phi_7267_: bool;
    var phi_7407_: bool;

    (*internal_medium).extinction = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).albedo = vec3<f32>(0f, 0f, 0f);
    (*internal_medium).anisotropy = 0f;
    let _e500 = base_metalness_1;
    m_metal = clamp(_e500, 0f, 1f);
    let _e502 = specular_roughness_1;
    m_rough = clamp(_e502, 0f, 1f);
    let _e504 = specular_roughness_anisotropy_1;
    m_aniso = clamp(_e504, 0f, 0.99f);
    let _e506 = base_color_1;
    let _e507 = base_weight_1;
    m_base = (_e506 * _e507);
    let _e509 = specular_color_1;
    m_specC = _e509;
    let _e510 = specular_weight_1;
    m_specW = _e510;
    let _e511 = specular_ior_1;
    m_ior = max(_e511, 1.001f);
    let _e513 = coat_weight_1;
    m_coatW = clamp(_e513, 0f, 1f);
    let _e515 = coat_roughness_1;
    m_coatRough = clamp(_e515, 0f, 1f);
    let _e517 = coat_roughness_anisotropy_1;
    m_coatAniso = clamp(_e517, 0f, 0.99f);
    let _e519 = coat_ior_1;
    m_coatIor = max(_e519, 1.001f);
    let _e521 = (*winputL_8);
    V_16 = _e521;
    let _e523 = V_16[2u];
    if (_e523 < 0f) {
        let _e525 = V_16;
        V_16 = -(_e525);
    }
    let _e528 = V_16[2u];
    NdotV_21 = max(_e528, 0.0001f);
    let _e530 = m_rough;
    let _e531 = m_rough;
    alpha_13 = clamp((_e530 * _e531), 0.0001f, 1f);
    let _e534 = m_aniso;
    anisoAspect = max(0.0001f, (1f - _e534));
    let _e537 = alpha_13;
    let _e538 = anisoAspect;
    let _e539 = anisoAspect;
    let _e545 = alpha_13;
    let _e546 = anisoAspect;
    let _e548 = anisoAspect;
    let _e549 = anisoAspect;
    sampleAlpha = clamp(vec2<f32>((_e537 * sqrt((2f / ((_e538 * _e539) + 1f)))), ((_e545 * _e546) * sqrt((2f / ((_e548 * _e549) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e557 = m_coatRough;
    let _e558 = m_coatRough;
    coatAlpha = clamp((_e557 * _e558), 0.0001f, 1f);
    let _e561 = m_coatAniso;
    coatAnisoAspect = max(0.0001f, (1f - _e561));
    let _e564 = coatAlpha;
    let _e565 = coatAnisoAspect;
    let _e566 = coatAnisoAspect;
    let _e572 = coatAlpha;
    let _e573 = coatAnisoAspect;
    let _e575 = coatAnisoAspect;
    let _e576 = coatAnisoAspect;
    coatSampleAlpha = clamp(vec2<f32>((_e564 * sqrt((2f / ((_e565 * _e566) + 1f)))), ((_e572 * _e573) * sqrt((2f / ((_e575 * _e576) + 1f))))), vec2<f32>(0.0001f, 0.0001f), vec2<f32>(1f, 1f));
    let _e584 = m_ior;
    let _e586 = m_ior;
    F0d = pow(((_e584 - 1f) / (_e586 + 1f)), 2f);
    let _e590 = F0d;
    let _e592 = m_specC;
    let _e595 = m_specW;
    let _e597 = m_base;
    let _e598 = m_metal;
    F0_9 = mix(((vec3(_e590) * max(_e592, vec3<f32>(0f, 0f, 0f))) * _e595), _e597, vec3(_e598));
    let _e602 = F0_9[0u];
    let _e604 = F0_9[1u];
    let _e606 = F0_9[2u];
    F0lum = max(_e602, max(_e604, _e606));
    let _e609 = F0lum;
    let _e610 = F0lum;
    let _e612 = NdotV_21;
    Fv = (_e609 + ((1f - _e610) * pow((1f - _e612), 5f)));
    let _e617 = NdotV_21;
    param_798 = _e617;
    let _e618 = m_coatIor;
    param_799 = _e618;
    let _e619 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_798), (&param_799));
    coatFv = _e619;
    let _e620 = m_coatW;
    let _e621 = coatFv;
    pCoat = clamp((_e620 * _e621), 0f, 0.75f);
    let _e624 = (*rndSeed_9);
    param_800 = _e624;
    let _e625 = rand_u0028_u1_u003b((&param_800));
    let _e626 = param_800;
    (*rndSeed_9) = _e626;
    xiLobe = _e625;
    pTrans = 0f;
    let _e627 = transmission_weight_1;
    m_transW = clamp(_e627, 0f, 1f);
    let _e629 = transmission_color_1;
    m_transC = _e629;
    let _e630 = transmission_depth_1;
    m_transD = _e630;
    let _e631 = m_transW;
    let _e632 = Fv;
    pTrans = clamp((_e631 * (1f - _e632)), 0f, 0.95f);
    let _e636 = xiLobe;
    let _e637 = pCoat;
    if (_e636 < _e637) {
        let _e639 = V_16;
        param_801 = _e639;
        let _e641 = coatSampleAlpha[0u];
        param_802 = _e641;
        let _e643 = coatSampleAlpha[1u];
        param_803 = _e643;
        let _e644 = (*rndSeed_9);
        param_804 = _e644;
        let _e645 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_801), (&param_802), (&param_803), (&param_804));
        let _e646 = param_804;
        (*rndSeed_9) = _e646;
        Hc = _e645;
        let _e647 = V_16;
        let _e649 = Hc;
        (*woutputL_11) = reflect(-(_e647), _e649);
        let _e652 = (*woutputL_11)[2u];
        if (_e652 <= 0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e654 = V_16;
        param_805 = _e654;
        let _e656 = coatSampleAlpha[0u];
        param_806 = _e656;
        let _e658 = coatSampleAlpha[1u];
        param_807 = _e658;
        let _e659 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_805), (&param_806), (&param_807));
        let _e660 = V_16;
        let _e661 = (*woutputL_11);
        param_808 = normalize((_e660 + _e661));
        let _e665 = coatSampleAlpha[0u];
        param_809 = _e665;
        let _e667 = coatSampleAlpha[1u];
        param_810 = _e667;
        let _e668 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_808), (&param_809), (&param_810));
        let _e670 = NdotV_21;
        pdfCoat = ((_e659 * _e668) / (4f * _e670));
        let _e673 = V_16;
        param_811 = _e673;
        let _e675 = sampleAlpha[0u];
        param_812 = _e675;
        let _e677 = sampleAlpha[1u];
        param_813 = _e677;
        let _e678 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_811), (&param_812), (&param_813));
        let _e679 = V_16;
        let _e680 = (*woutputL_11);
        param_814 = normalize((_e679 + _e680));
        let _e684 = sampleAlpha[0u];
        param_815 = _e684;
        let _e686 = sampleAlpha[1u];
        param_816 = _e686;
        let _e687 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_814), (&param_815), (&param_816));
        let _e689 = NdotV_21;
        pdfBaseSpec = ((_e678 * _e687) / (4f * _e689));
        let _e692 = (*woutputL_11);
        param_817 = _e692;
        let _e693 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_817));
        pdfBaseDiff = _e693;
        let _e694 = m_metal;
        let _e696 = m_base;
        diffLumCoat = ((1f - _e694) * dot(_e696, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
        let _e699 = Fv;
        let _e700 = Fv;
        let _e701 = Fv;
        let _e703 = diffLumCoat;
        pSpecCoat = clamp((_e699 / ((_e700 + ((1f - _e701) * _e703)) + 0.001f)), 0.05f, 0.95f);
        let _e709 = pCoat;
        let _e710 = pdfCoat;
        let _e712 = pCoat;
        let _e714 = pTrans;
        let _e717 = pSpecCoat;
        let _e718 = pdfBaseSpec;
        let _e720 = pSpecCoat;
        let _e722 = pdfBaseDiff;
        (*pdf_woutputL_6) = max(((_e709 * _e710) + (((1f - _e712) * (1f - _e714)) * ((_e717 * _e718) + ((1f - _e720) * _e722)))), 0.000001f);
        let _e728 = (*pW_13);
        param_818 = _e728;
        let _e729 = (*basis_15);
        param_819 = _e729;
        let _e730 = (*winputL_8);
        param_820 = _e730;
        let _e731 = (*woutputL_11);
        param_821 = _e731;
        let _e732 = ignorePdfCoat;
        param_822 = _e732;
        let _e733 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_818), (&param_819), (&param_820), (&param_821), (&param_822));
        let _e734 = param_822;
        ignorePdfCoat = _e734;
        return _e733;
    }
    let _e735 = xiLobe;
    let _e736 = pCoat;
    let _e737 = pCoat;
    let _e739 = pTrans;
    if (_e735 < (_e736 + ((1f - _e737) * _e739))) {
        let _e744 = (*winputL_8)[2u];
        externalTransmission = (_e744 > 0f);
        let _e746 = externalTransmission;
        if _e746 {
            let _e747 = m_ior;
            local_15 = (1f / _e747);
        } else {
            let _e749 = m_ior;
            local_15 = _e749;
        }
        let _e750 = local_15;
        etaRatio = _e750;
        let _e751 = alpha_13;
        if (_e751 <= 0.001f) {
            let _e753 = externalTransmission;
            Hdelta = vec3<f32>(0f, 0f, select(-1f, 1f, _e753));
            let _e756 = Hdelta;
            let _e757 = (*winputL_8);
            HdotWiDelta = dot(_e756, _e757);
            let _e759 = etaRatio;
            let _e760 = etaRatio;
            let _e762 = HdotWiDelta;
            let _e763 = HdotWiDelta;
            discrDelta = (1f - ((_e759 * _e760) * (1f - (_e762 * _e763))));
            let _e768 = discrDelta;
            if (_e768 < 0f) {
                let _e770 = (*winputL_8);
                let _e772 = (*winputL_8);
                let _e773 = Hdelta;
                let _e776 = Hdelta;
                (*woutputL_11) = (-(_e770) + (_e776 * (2f * dot(_e772, _e773))));
                let _e779 = pCoat;
                let _e781 = pTrans;
                (*pdf_woutputL_6) = max(((1f - _e779) * _e781), 0.000001f);
                let _e784 = m_transW;
                let _e785 = (*pdf_woutputL_6);
                let _e788 = (*woutputL_11)[2u];
                return vec3(((_e784 * _e785) / max(abs(_e788), 0.0000000001f)));
            }
            let _e793 = etaRatio;
            let _e794 = (*winputL_8);
            let _e796 = Hdelta;
            let _e797 = HdotWiDelta;
            let _e800 = etaRatio;
            let _e801 = HdotWiDelta;
            let _e804 = discrDelta;
            beamIncidentDelta = ((_e794 * _e793) - ((_e796 * sign(_e797)) * ((_e800 * abs(_e801)) - sqrt(_e804))));
            let _e809 = beamIncidentDelta;
            (*woutputL_11) = -(normalize(_e809));
            let _e813 = (*winputL_8)[2u];
            let _e815 = (*woutputL_11)[2u];
            if ((_e813 * _e815) >= -0.0001f) {
                (*pdf_woutputL_6) = 0f;
                return vec3<f32>(0f, 0f, 0f);
            }
            let _e818 = m_transD;
            let _e819 = (_e818 > 0f);
            phi_7267_ = _e819;
            if _e819 {
                let _e820 = mtlx_openpbr_is_thinwalled_u0028_();
                phi_7267_ = !(_e820);
            }
            let _e823 = phi_7267_;
            if _e823 {
                let _e824 = m_transC;
                let _e828 = m_transD;
                (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e824))) / vec3(_e828));
                let _e832 = transmission_scatter_1;
                (*internal_medium).albedo = clamp(_e832, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
                let _e835 = transmission_scatter_anisotropy_1;
                (*internal_medium).anisotropy = clamp(_e835, -0.99f, 0.99f);
            }
            let _e838 = HdotWiDelta;
            let _e840 = etaRatio;
            param_823 = abs(_e838);
            param_824 = (1f / _e840);
            let _e842 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_823), (&param_824));
            Tdelta = clamp((1f - _e842), 0f, 1f);
            let _e845 = m_transD;
            let _e847 = m_transC;
            tintDelta = select(vec3<f32>(1f, 1f, 1f), _e847, (_e845 == 0f));
            let _e849 = pCoat;
            let _e851 = pTrans;
            (*pdf_woutputL_6) = max(((1f - _e849) * _e851), 0.000001f);
            let _e854 = m_transW;
            let _e855 = tintDelta;
            let _e857 = Tdelta;
            let _e859 = (*pdf_woutputL_6);
            let _e862 = (*woutputL_11)[2u];
            return ((((_e855 * _e854) * _e857) * _e859) / vec3(max(abs(_e862), 0.0000000001f)));
        }
        let _e867 = (*winputL_8);
        Vsample = _e867;
        let _e869 = Vsample[2u];
        if (_e869 < 0f) {
            let _e872 = Vsample[2u];
            Vsample[2u] = (_e872 * -1f);
        }
        let _e875 = Vsample;
        param_825 = _e875;
        let _e877 = sampleAlpha[0u];
        param_826 = _e877;
        let _e879 = sampleAlpha[1u];
        param_827 = _e879;
        let _e880 = (*rndSeed_9);
        param_828 = _e880;
        let _e881 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_825), (&param_826), (&param_827), (&param_828));
        let _e882 = param_828;
        (*rndSeed_9) = _e882;
        Ht_2 = _e881;
        let _e884 = (*winputL_8)[2u];
        if (_e884 < 0f) {
            let _e887 = Ht_2[2u];
            Ht_2[2u] = (_e887 * -1f);
        }
        let _e890 = Ht_2;
        let _e891 = (*winputL_8);
        HdotWi = dot(_e890, _e891);
        let _e893 = etaRatio;
        let _e894 = etaRatio;
        let _e896 = HdotWi;
        let _e897 = HdotWi;
        discr = (1f - ((_e893 * _e894) * (1f - (_e896 * _e897))));
        let _e902 = discr;
        if (_e902 < 0f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e904 = etaRatio;
        let _e905 = (*winputL_8);
        let _e907 = Ht_2;
        let _e908 = HdotWi;
        let _e911 = etaRatio;
        let _e912 = HdotWi;
        let _e915 = discr;
        beamIncident = ((_e905 * _e904) - ((_e907 * sign(_e908)) * ((_e911 * abs(_e912)) - sqrt(_e915))));
        let _e920 = beamIncident;
        (*woutputL_11) = -(normalize(_e920));
        let _e924 = (*winputL_8)[2u];
        let _e926 = (*woutputL_11)[2u];
        if ((_e924 * _e926) >= -0.0001f) {
            (*pdf_woutputL_6) = 0f;
            return vec3<f32>(0f, 0f, 0f);
        }
        let _e929 = m_transD;
        let _e930 = (_e929 > 0f);
        phi_7407_ = _e930;
        if _e930 {
            let _e931 = mtlx_openpbr_is_thinwalled_u0028_();
            phi_7407_ = !(_e931);
        }
        let _e934 = phi_7407_;
        if _e934 {
            let _e935 = m_transC;
            let _e939 = m_transD;
            (*internal_medium).extinction = (-(log(max(vec3<f32>(0.000001f, 0.000001f, 0.000001f), _e935))) / vec3(_e939));
            let _e943 = transmission_scatter_1;
            (*internal_medium).albedo = clamp(_e943, vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e946 = transmission_scatter_anisotropy_1;
            (*internal_medium).anisotropy = clamp(_e946, -0.99f, 0.99f);
        }
        let _e949 = V_16;
        let _e950 = m_ior;
        let _e951 = (*woutputL_11);
        Hr = normalize(-((_e949 + (_e951 * _e950))));
        let _e957 = Hr[2u];
        if (_e957 < 0f) {
            let _e959 = Hr;
            Hr = -(_e959);
        }
        let _e961 = (*winputL_8);
        let _e962 = Ht_2;
        VoH = abs(dot(_e961, _e962));
        let _e965 = (*woutputL_11);
        let _e966 = Ht_2;
        LoH = abs(dot(_e965, _e966));
        let _e969 = LoH;
        let _e970 = etaRatio;
        let _e971 = VoH;
        denomT = (_e969 + (_e970 * _e971));
        let _e974 = etaRatio;
        let _e975 = etaRatio;
        let _e977 = VoH;
        let _e979 = denomT;
        let _e980 = denomT;
        jacT = (((_e974 * _e975) * _e977) / max((_e979 * _e980), 0.00000001f));
        let _e984 = Vsample;
        param_829 = _e984;
        let _e986 = sampleAlpha[0u];
        param_830 = _e986;
        let _e988 = sampleAlpha[1u];
        param_831 = _e988;
        let _e989 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_829), (&param_830), (&param_831));
        let _e990 = VoH;
        let _e993 = Ht_2[2u];
        if (abs(_e993) > 0f) {
            let _e997 = Ht_2[0u];
            let _e999 = Ht_2[1u];
            let _e1001 = Ht_2[2u];
            local_16 = vec3<f32>(_e997, _e999, abs(_e1001));
        } else {
            let _e1004 = Ht_2;
            local_16 = _e1004;
        }
        let _e1005 = local_16;
        param_832 = _e1005;
        let _e1007 = sampleAlpha[0u];
        param_833 = _e1007;
        let _e1009 = sampleAlpha[1u];
        param_834 = _e1009;
        let _e1010 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_832), (&param_833), (&param_834));
        let _e1013 = (*winputL_8)[2u];
        DvT = (((_e989 * _e990) * _e1010) / max(abs(_e1013), 0.0001f));
        let _e1017 = pCoat;
        let _e1019 = pTrans;
        let _e1021 = DvT;
        let _e1023 = jacT;
        (*pdf_woutputL_6) = max(((((1f - _e1017) * _e1019) * _e1021) * _e1023), 0.000001f);
        let _e1027 = Ht_2[2u];
        if (abs(_e1027) > 0f) {
            let _e1031 = Ht_2[0u];
            let _e1033 = Ht_2[1u];
            let _e1035 = Ht_2[2u];
            local_17 = vec3<f32>(_e1031, _e1033, abs(_e1035));
        } else {
            let _e1038 = Ht_2;
            local_17 = _e1038;
        }
        let _e1039 = local_17;
        param_835 = _e1039;
        let _e1041 = sampleAlpha[0u];
        param_836 = _e1041;
        let _e1043 = sampleAlpha[1u];
        param_837 = _e1043;
        let _e1044 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_835), (&param_836), (&param_837));
        D_3 = _e1044;
        let _e1045 = (*winputL_8);
        param_838 = _e1045;
        let _e1046 = (*woutputL_11);
        param_839 = _e1046;
        let _e1048 = sampleAlpha[0u];
        param_840 = _e1048;
        let _e1050 = sampleAlpha[1u];
        param_841 = _e1050;
        let _e1051 = ggx_G2_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_838), (&param_839), (&param_840), (&param_841));
        G2_ = _e1051;
        let _e1052 = etaRatio;
        etaRefl = (1f / _e1052);
        let _e1054 = VoH;
        param_842 = _e1054;
        let _e1055 = etaRefl;
        param_843 = _e1055;
        let _e1056 = FresnelDielectricReflectance_u0028_f1_u003b_f1_u003b((&param_842), (&param_843));
        T_1 = clamp((1f - _e1056), 0f, 1f);
        let _e1059 = m_transD;
        let _e1061 = m_transC;
        tint_3 = select(vec3<f32>(1f, 1f, 1f), _e1061, (_e1059 == 0f));
        let _e1063 = m_transW;
        let _e1064 = tint_3;
        let _e1066 = T_1;
        let _e1068 = VoH;
        let _e1070 = jacT;
        let _e1072 = D_3;
        let _e1074 = G2_;
        let _e1077 = (*woutputL_11)[2u];
        let _e1080 = (*winputL_8)[2u];
        return (((((((_e1064 * _e1063) * _e1066) * _e1068) * _e1070) * _e1072) * _e1074) / vec3(max((abs(_e1077) * abs(_e1080)), 0.0000000001f)));
    }
    let _e1086 = m_metal;
    let _e1088 = m_base;
    diffLum = ((1f - _e1086) * dot(_e1088, vec3<f32>(0.2126f, 0.7152f, 0.0722f)));
    let _e1091 = Fv;
    let _e1092 = Fv;
    let _e1093 = Fv;
    let _e1095 = diffLum;
    pSpec = clamp((_e1091 / ((_e1092 + ((1f - _e1093) * _e1095)) + 0.001f)), 0.05f, 0.95f);
    let _e1101 = (*rndSeed_9);
    param_844 = _e1101;
    let _e1102 = rand_u0028_u1_u003b((&param_844));
    let _e1103 = param_844;
    (*rndSeed_9) = _e1103;
    let _e1104 = pSpec;
    if (_e1102 < _e1104) {
        let _e1106 = V_16;
        param_845 = _e1106;
        let _e1108 = sampleAlpha[0u];
        param_846 = _e1108;
        let _e1110 = sampleAlpha[1u];
        param_847 = _e1110;
        let _e1111 = (*rndSeed_9);
        param_848 = _e1111;
        let _e1112 = ggx_ndf_sample_u0028_vf3_u003b_f1_u003b_f1_u003b_u1_u003b((&param_845), (&param_846), (&param_847), (&param_848));
        let _e1113 = param_848;
        (*rndSeed_9) = _e1113;
        H_8 = _e1112;
        let _e1114 = V_16;
        let _e1116 = H_8;
        (*woutputL_11) = reflect(-(_e1114), _e1116);
    } else {
        let _e1118 = (*rndSeed_9);
        param_849 = _e1118;
        let _e1119 = pdfTmp;
        param_850 = _e1119;
        let _e1120 = sampleHemisphereCosineWeighted_u0028_u1_u003b_f1_u003b((&param_849), (&param_850));
        let _e1121 = param_849;
        (*rndSeed_9) = _e1121;
        let _e1122 = param_850;
        pdfTmp = _e1122;
        (*woutputL_11) = _e1120;
    }
    let _e1124 = (*woutputL_11)[2u];
    if (_e1124 <= 0.0001f) {
        (*pdf_woutputL_6) = 0f;
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e1126 = V_16;
    let _e1127 = (*woutputL_11);
    Hh = normalize((_e1126 + _e1127));
    let _e1130 = V_16;
    param_851 = _e1130;
    let _e1132 = sampleAlpha[0u];
    param_852 = _e1132;
    let _e1134 = sampleAlpha[1u];
    param_853 = _e1134;
    let _e1135 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_851), (&param_852), (&param_853));
    let _e1136 = Hh;
    param_854 = _e1136;
    let _e1138 = sampleAlpha[0u];
    param_855 = _e1138;
    let _e1140 = sampleAlpha[1u];
    param_856 = _e1140;
    let _e1141 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_854), (&param_855), (&param_856));
    let _e1143 = NdotV_21;
    pdfSpec = ((_e1135 * _e1141) / (4f * _e1143));
    let _e1146 = (*woutputL_11);
    param_857 = _e1146;
    let _e1147 = pdfHemisphereCosineWeighted_u0028_vf3_u003b((&param_857));
    pdfDiff = _e1147;
    let _e1148 = V_16;
    param_858 = _e1148;
    let _e1150 = coatSampleAlpha[0u];
    param_859 = _e1150;
    let _e1152 = coatSampleAlpha[1u];
    param_860 = _e1152;
    let _e1153 = ggx_G1_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_858), (&param_859), (&param_860));
    let _e1154 = Hh;
    param_861 = _e1154;
    let _e1156 = coatSampleAlpha[0u];
    param_862 = _e1156;
    let _e1158 = coatSampleAlpha[1u];
    param_863 = _e1158;
    let _e1159 = ggx_ndf_eval_u0028_vf3_u003b_f1_u003b_f1_u003b((&param_861), (&param_862), (&param_863));
    let _e1161 = NdotV_21;
    pdfCoat_1 = ((_e1153 * _e1159) / (4f * _e1161));
    let _e1164 = pCoat;
    let _e1165 = pdfCoat_1;
    let _e1167 = pCoat;
    let _e1169 = pTrans;
    let _e1172 = pSpec;
    let _e1173 = pdfSpec;
    let _e1175 = pSpec;
    let _e1177 = pdfDiff;
    (*pdf_woutputL_6) = max(((_e1164 * _e1165) + (((1f - _e1167) * (1f - _e1169)) * ((_e1172 * _e1173) + ((1f - _e1175) * _e1177)))), 0.000001f);
    let _e1183 = (*pW_13);
    param_864 = _e1183;
    let _e1184 = (*basis_15);
    param_865 = _e1184;
    let _e1185 = (*winputL_8);
    param_866 = _e1185;
    let _e1186 = (*woutputL_11);
    param_867 = _e1186;
    let _e1187 = ignorePdf;
    param_868 = _e1187;
    let _e1188 = mtlx_openpbr_bsdf_evaluate_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_864), (&param_865), (&param_866), (&param_867), (&param_868));
    let _e1189 = param_868;
    ignorePdf = _e1189;
    return _e1188;
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

    let _e373 = (*surfaceshader_4);
    if (_e373 == 1i) {
        let _e375 = (*pW_14);
        param_869 = _e375;
        let _e376 = (*basis_16);
        param_870 = _e376;
        let _e377 = (*winputL_9);
        param_871 = _e377;
        let _e378 = (*rndSeed_10);
        param_872 = _e378;
        let _e379 = mtlx_openpbr_bsdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_869), (&param_870), (&param_871), (&param_872), (&param_873), (&param_874), (&param_875));
        let _e380 = param_872;
        (*rndSeed_10) = _e380;
        let _e381 = param_873;
        (*woutputL_12) = _e381;
        let _e382 = param_874;
        (*pdf_woutputL_7) = _e382;
        let _e383 = param_875;
        (*internal_medium_1) = _e383;
        return _e379;
    } else {
        let _e384 = (*surfaceshader_4);
        if (_e384 == 2i) {
            let _e386 = (*pW_14);
            param_876 = _e386;
            let _e387 = (*basis_16);
            param_877 = _e387;
            let _e388 = (*winputL_9);
            param_878 = _e388;
            let _e389 = (*rndSeed_10);
            param_879 = _e389;
            let _e390 = ground_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_876), (&param_877), (&param_878), (&param_879), (&param_880), (&param_881));
            let _e391 = param_879;
            (*rndSeed_10) = _e391;
            let _e392 = param_880;
            (*woutputL_12) = _e392;
            let _e393 = param_881;
            (*pdf_woutputL_7) = _e393;
            return _e390;
        } else {
            let _e394 = (*pW_14);
            param_882 = _e394;
            let _e395 = (*basis_16);
            param_883 = _e395;
            let _e396 = (*winputL_9);
            param_884 = _e396;
            let _e397 = (*rndSeed_10);
            param_885 = _e397;
            let _e398 = neutral_brdf_sample_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_vf3_u003b_f1_u003b((&param_882), (&param_883), (&param_884), (&param_885), (&param_886), (&param_887));
            let _e399 = param_885;
            (*rndSeed_10) = _e399;
            let _e400 = param_886;
            (*woutputL_12) = _e400;
            let _e401 = param_887;
            (*pdf_woutputL_7) = _e401;
            return _e398;
        }
    }
}

fn mtlx_openpbr_thin_film_ior_u0028_() -> f32 {
    let _e346 = thin_film_ior_1;
    return max(_e346, 1f);
}

fn mtlx_openpbr_thin_film_thickness_nm_u0028_() -> f32 {
    let _e346 = thin_film_thickness_1;
    return max((1000f * _e346), 0f);
}

fn mtlx_openpbr_specular_ior_u0028_() -> f32 {
    let _e346 = specular_ior_1;
    return max(_e346, 1.001f);
}

fn mtlx_openpbr_specular_roughness_u0028_() -> f32 {
    let _e346 = specular_roughness_1;
    return clamp(_e346, 0f, 1f);
}

fn mtlx_openpbr_thin_film_weight_u0028_() -> f32 {
    let _e346 = thin_film_weight_1;
    return clamp(_e346, 0f, 1f);
}

fn mtlx_openpbr_transmission_weight_u0028_() -> f32 {
    let _e346 = transmission_weight_1;
    return clamp(_e346, 0f, 1f);
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

    let _e363 = mtlx_openpbr_is_thinwalled_u0028_();
    if !(_e363) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e365 = mtlx_openpbr_transmission_weight_u0028_();
    if (_e365 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e367 = mtlx_openpbr_thin_film_weight_u0028_();
    if (_e367 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e369 = mtlx_openpbr_specular_roughness_u0028_();
    if (_e369 > 0.02f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e372 = (*winputL_10)[2u];
    cosI = clamp(abs(_e372), 0.0001f, 1f);
    let _e375 = mtlx_openpbr_specular_ior_u0028_();
    let _e377 = mtlx_openpbr_thin_film_thickness_nm_u0028_();
    let _e378 = mtlx_openpbr_thin_film_ior_u0028_();
    param_888 = max(_e375, 1.001f);
    param_889 = _e377;
    param_890 = _e378;
    let _e379 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_888), (&param_889), (&param_890));
    fd_11 = _e379;
    let _e380 = mtlx_openpbr_thin_film_weight_u0028_();
    let _e381 = cosI;
    param_891 = _e381;
    let _e382 = fd_11;
    param_892 = _e382;
    let _e383 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_891), (&param_892));
    F_4 = (_e383 * _e380);
    let _e385 = (*winputL_10);
    reflectedL = reflect(-(_e385), vec3<f32>(0f, 0f, 1f));
    let _e389 = reflectedL[2u];
    if (_e389 <= 0f) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e391 = reflectedL;
    param_893 = _e391;
    let _e392 = (*basis_17);
    param_894 = _e392;
    let _e393 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_893), (&param_894));
    reflectedW = _e393;
    let _e394 = reflectedW;
    param_895 = _e394;
    let _e395 = sunRadiance_u0028_vf3_u003b((&param_895));
    let _e396 = reflectedW;
    param_896 = _e396;
    let _e397 = skyRadiance_u0028_vf3_u003b((&param_896));
    envRadiance = (_e395 + _e397);
    let _e399 = envRadiance;
    let _e401 = unnamed.skyPower;
    let _e404 = unnamed.skyColor;
    envRadiance = max(_e399, (_e404 * (0.25f * _e401)));
    let _e407 = F_4;
    let _e408 = envRadiance;
    return (_e407 * _e408);
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, baryCoord_2: ptr<function, vec3<f32>>, texCoord_2: ptr<function, vec2<f32>>) -> Basis {
    var basis_18: Basis;
    var param_897: vec3<f32>;
    var param_898: vec3<f32>;

    let _e353 = (*nW);
    param_897 = _e353;
    let _e354 = safe_normalize_u0028_vf3_u003b((&param_897));
    basis_18.nW = _e354;
    let _e356 = (*tW);
    param_898 = _e356;
    let _e357 = safe_normalize_u0028_vf3_u003b((&param_898));
    basis_18.tW = _e357;
    let _e360 = basis_18.nW;
    let _e362 = basis_18.tW;
    basis_18.bW = cross(_e360, _e362);
    let _e365 = (*baryCoord_2);
    basis_18.baryCoord = _e365;
    let _e367 = (*texCoord_2);
    basis_18.texCoord = _e367;
    let _e369 = basis_18;
    return _e369;
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
    var phi_9340_: bool;

    let _e364 = (*shadowW_1);
    param_899 = _e364;
    let _e365 = (*basis_19);
    param_900 = _e365;
    let _e366 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_899), (&param_900));
    shadowL_1 = _e366;
    let _e367 = shadowL_1;
    param_901 = _e367;
    let _e368 = (*shadowW_1);
    param_902 = _e368;
    let _e369 = skyPdf_u0028_vf3_u003b_vf3_u003b((&param_901), (&param_902));
    pdf_sky_1 = _e369;
    let _e370 = shadowL_1;
    param_903 = _e370;
    let _e371 = (*shadowW_1);
    param_904 = _e371;
    let _e372 = sunPdf_u0028_vf3_u003b_vf3_u003b((&param_903), (&param_904));
    pdf_sun_1 = _e372;
    let _e374 = unnamed.mtlxDisableSun;
    let _e375 = (_e374 != 0u);
    phi_9340_ = _e375;
    if !(_e375) {
        let _e378 = unnamed.mtlxLightCount;
        phi_9340_ = (_e378 > 0i);
    }
    let _e381 = phi_9340_;
    if _e381 {
        local_18 = 0f;
    } else {
        let _e382 = sunTotalPower_u0028_();
        local_18 = _e382;
    }
    let _e383 = local_18;
    w_sun_1 = _e383;
    let _e384 = skyTotalPower_u0028_();
    w_sky_1 = _e384;
    let _e385 = w_sun_1;
    let _e386 = w_sky_1;
    w_total_1 = max(0.0000000001f, (_e385 + _e386));
    let _e389 = w_sun_1;
    let _e390 = w_total_1;
    P_sun_1 = (_e389 / _e390);
    let _e392 = w_sky_1;
    let _e393 = w_total_1;
    P_sky_1 = (_e392 / _e393);
    let _e395 = P_sun_1;
    let _e396 = pdf_sun_1;
    let _e398 = P_sky_1;
    let _e399 = pdf_sky_1;
    lightPdf_1 = ((_e395 * _e396) + (_e398 * _e399));
    let _e402 = lightPdf_1;
    return _e402;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_20: Basis;
    var param_905: vec3<f32>;
    var param_906: vec3<f32>;

    let _e350 = (*nW_1);
    param_905 = _e350;
    let _e351 = safe_normalize_u0028_vf3_u003b((&param_905));
    basis_20.nW = _e351;
    let _e353 = (*nW_1);
    param_906 = _e353;
    let _e354 = normalToTangent_u0028_vf3_u003b((&param_906));
    basis_20.tW = _e354;
    let _e357 = basis_20.nW;
    let _e359 = basis_20.tW;
    basis_20.bW = cross(_e357, _e359);
    basis_20.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_20.texCoord = vec2<f32>(0f, 0f);
    let _e364 = basis_20;
    return _e364;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_4: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e356 = (*cameraWorld);
    lookDirection = (_e356 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e358 = (*inverseProjection);
    nearVector = (_e358 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e361 = nearVector[2u];
    let _e363 = nearVector[3u];
    nearDistance_1 = abs((_e361 / _e363));
    let _e366 = (*cameraWorld);
    origin_1 = (_e366 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e368 = (*inverseProjection);
    let _e369 = (*coordinate);
    direction_1 = (_e368 * vec4<f32>(_e369.x, _e369.y, 0.5f, 1f));
    let _e375 = direction_1[3u];
    let _e376 = direction_1;
    direction_1 = (_e376 / vec4(_e375));
    let _e379 = (*cameraWorld);
    let _e380 = direction_1;
    let _e382 = origin_1;
    direction_1 = ((_e379 * _e380) - _e382);
    let _e384 = direction_1;
    let _e386 = nearDistance_1;
    let _e388 = direction_1;
    let _e389 = lookDirection;
    let _e393 = origin_1;
    let _e395 = (_e393.xyz + ((_e384.xyz * _e386) / vec3(dot(_e388, _e389))));
    origin_1[0u] = _e395.x;
    origin_1[1u] = _e395.y;
    origin_1[2u] = _e395.z;
    let _e402 = origin_1;
    (*rayOrigin_4) = _e402.xyz;
    let _e404 = direction_1;
    (*rayDirection_2) = _e404.xyz;
    return;
}

fn sample_triangle_filter_u0028_f1_u003b(xi_1: ptr<function, f32>) -> f32 {
    var local_19: f32;

    let _e348 = (*xi_1);
    if (_e348 < 0.5f) {
        let _e350 = (*xi_1);
        local_19 = (sqrt((2f * _e350)) - 1f);
    } else {
        let _e354 = (*xi_1);
        local_19 = (1f - sqrt((2f - (2f * _e354))));
    }
    let _e359 = local_19;
    return _e359;
}

fn xorshift_u0028_u1_u003b(seed_1: ptr<function, u32>) {
    let _e347 = (*seed_1);
    let _e350 = (*seed_1);
    (*seed_1) = (_e350 ^ (_e347 << bitcast<u32>(13u)));
    let _e352 = (*seed_1);
    let _e355 = (*seed_1);
    (*seed_1) = (_e355 ^ (_e352 >> bitcast<u32>(17u)));
    let _e357 = (*seed_1);
    let _e360 = (*seed_1);
    (*seed_1) = (_e360 ^ (_e357 << bitcast<u32>(5u)));
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
    var phi_9674_: bool;
    var phi_9686_: bool;
    var phi_9687_: bool;
    var phi_9720_: bool;
    var phi_9727_: bool;
    var phi_9858_: bool;
    var phi_9949_: bool;

    g_ptOcclusion = 1f;
    g_ptEmitEmission = 1i;
    g_ptOpacity = 1f;
    g_ptEmission = vec3<f32>(0f, 0f, 0f);
    base_weight_1 = 1f;
    base_color_1 = vec3<f32>(0.8f, 0.75f, 0.7f);
    base_diffuse_roughness_1 = 0f;
    base_metalness_1 = 0f;
    specular_weight_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    specular_roughness_1 = 0.35f;
    specular_ior_1 = 1.5f;
    specular_roughness_anisotropy_1 = 0f;
    transmission_weight_1 = 0f;
    transmission_color_1 = vec3<f32>(1f, 1f, 1f);
    transmission_depth_1 = 0f;
    transmission_scatter_1 = vec3<f32>(0f, 0f, 0f);
    transmission_scatter_anisotropy_1 = 0f;
    transmission_dispersion_scale_1 = 0f;
    transmission_dispersion_abbe_number_1 = 20f;
    subsurface_weight_1 = 1f;
    subsurface_color_1 = vec3<f32>(0.8f, 0.75f, 0.7f);
    subsurface_radius_1 = 1f;
    subsurface_radius_scale_1 = vec3<f32>(0.3f, 0.5f, 0.3f);
    subsurface_scatter_anisotropy_1 = 0f;
    fuzz_weight_1 = 0f;
    fuzz_color_1 = vec3<f32>(1f, 1f, 1f);
    fuzz_roughness_1 = 0.5f;
    coat_weight_1 = 1f;
    coat_color_1 = vec3<f32>(1f, 1f, 1f);
    coat_roughness_1 = 0.15f;
    coat_roughness_anisotropy_1 = 0f;
    coat_ior_1 = 1.68f;
    coat_darkening_1 = 1f;
    thin_film_weight_1 = 1f;
    thin_film_thickness_1 = 0.42f;
    thin_film_ior_1 = 2f;
    emission_luminance_1 = 0f;
    emission_color_1 = vec3<f32>(1f, 1f, 1f);
    geometry_opacity_1 = 1f;
    geometry_thin_walled_1 = false;
    let _e487 = gl_FragCoord_1;
    frag = _e487.xy;
    let _e490 = frag[0u];
    let _e492 = frag[1u];
    let _e495 = unnamed.resolution[0u];
    rndSeed_11 = u32((_e490 + (_e492 * _e495)));
    let _e499 = rndSeed_11;
    param_907 = _e499;
    xorshift_u0028_u1_u003b((&param_907));
    let _e500 = param_907;
    rndSeed_11 = _e500;
    let _e502 = unnamed.samples;
    let _e504 = rndSeed_11;
    rndSeed_11 = (_e504 ^ u32(_e502));
    let _e506 = rndSeed_11;
    param_908 = _e506;
    let _e507 = rand_u0028_u1_u003b((&param_908));
    let _e508 = param_908;
    rndSeed_11 = _e508;
    param_909 = _e507;
    let _e509 = sample_triangle_filter_u0028_f1_u003b((&param_909));
    jx = (0.5f * _e509);
    let _e511 = rndSeed_11;
    param_910 = _e511;
    let _e512 = rand_u0028_u1_u003b((&param_910));
    let _e513 = param_910;
    rndSeed_11 = _e513;
    param_911 = _e512;
    let _e514 = sample_triangle_filter_u0028_f1_u003b((&param_911));
    jy = (0.5f * _e514);
    let _e516 = frag;
    let _e517 = jx;
    let _e518 = jy;
    pixel = (_e516 + vec2<f32>(_e517, _e518));
    let _e521 = pixel;
    let _e523 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e521 / _e523) * 2f));
    let _e529 = unnamed.invModelMatrix;
    let _e531 = unnamed.cameraWorldMatrix;
    let _e533 = ndc;
    param_912 = _e533;
    param_913 = (_e529 * _e531);
    let _e535 = unnamed.invProjectionMatrix;
    param_914 = _e535;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_912), (&param_913), (&param_914), (&param_915), (&param_916));
    let _e536 = param_915;
    pW_15 = _e536;
    let _e537 = param_916;
    dW = _e537;
    let _e538 = dW;
    dW = normalize(_e538);
    let _e541 = unnamed.sunDir;
    param_917 = _e541;
    let _e542 = makeBasis_u0028_vf3_u003b((&param_917));
    sunBasis = _e542;
    L_12 = vec3<f32>(0f, 0f, 0f);
    throughput = vec3<f32>(1f, 1f, 1f);
    bsdfPdf_continuation = 1f;
    in_dielectric = false;
    vertex = 0i;
    loop {
        let _e543 = vertex;
        let _e545 = unnamed.bounces;
        if (_e543 <= _e545) {
            inside_volume = false;
            inside_scattering_volume = false;
            let _e547 = inside_scattering_volume;
            if !(_e547) {
                let _e549 = pW_15;
                param_918 = _e549;
                let _e550 = dW;
                param_919 = _e550;
                param_920 = 100000000000000000000f;
                let _e551 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_918), (&param_919), (&param_920), (&param_921), (&param_922), (&param_923), (&param_924), (&param_925), (&param_926), (&param_927));
                let _e552 = param_921;
                pW_next = _e552;
                let _e553 = param_922;
                NsW_next = _e553;
                let _e554 = param_923;
                NgW_next = _e554;
                let _e555 = param_924;
                TsW_next = _e555;
                let _e556 = param_925;
                baryCoord_next = _e556;
                let _e557 = param_926;
                texCoord_next = _e557;
                let _e558 = param_927;
                material_next = _e558;
                surface_hit = _e551;
            }
            let _e559 = surface_hit;
            if !(_e559) {
                misWeightLight = 1f;
                let _e561 = vertex;
                let _e563 = inside_scattering_volume;
                if ((_e561 > 0i) && !(_e563)) {
                    let _e566 = dW;
                    param_928 = _e566;
                    let _e567 = basis_21;
                    param_929 = _e567;
                    let _e568 = LiPDF_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_928), (&param_929));
                    lightPdf_2 = _e568;
                    let _e569 = bsdfPdf_continuation;
                    let _e570 = lightPdf_2;
                    let _e571 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e569, _e570);
                    misWeightLight = _e571;
                }
                let _e572 = throughput;
                let _e573 = misWeightLight;
                let _e575 = dW;
                param_930 = _e575;
                let _e576 = sunRadiance_u0028_vf3_u003b((&param_930));
                let _e577 = dW;
                param_931 = _e577;
                let _e578 = skyRadiance_u0028_vf3_u003b((&param_931));
                Lenv = ((_e572 * _e573) * (_e576 + _e578));
                let _e581 = Lenv;
                param_932 = _e581;
                let _e582 = maxComponent_u0028_vf3_u003b((&param_932));
                maxLenv = _e582;
                let _e583 = maxLenv;
                let _e585 = unnamed.firefly_clamp;
                if (_e583 > _e585) {
                    let _e588 = unnamed.firefly_clamp;
                    let _e589 = maxLenv;
                    let _e591 = Lenv;
                    Lenv = (_e591 * (_e588 / _e589));
                }
                let _e593 = Lenv;
                let _e594 = L_12;
                L_12 = (_e594 + _e593);
                break;
            }
            let _e596 = vertex;
            let _e598 = unnamed.bounces;
            if (_e596 == _e598) {
                break;
            }
            let _e600 = pW_next;
            pW_15 = _e600;
            let _e601 = NsW_next;
            NsW = _e601;
            let _e602 = NgW_next;
            NgW = _e602;
            let _e603 = TsW_next;
            TsW_1 = _e603;
            let _e604 = baryCoord_next;
            baryCoord_3 = _e604;
            let _e605 = texCoord_next;
            texCoord_3 = _e605;
            let _e606 = material_next;
            surfaceshader_5 = _e606;
            let _e607 = surfaceshader_5;
            if (_e607 == 1i) {
                let _e609 = in_dielectric;
                phi_9674_ = _e609;
                if _e609 {
                    let _e610 = NsW;
                    let _e611 = dW;
                    phi_9674_ = (dot(_e610, _e611) < 0f);
                }
                let _e615 = phi_9674_;
                phi_9687_ = _e615;
                if !(_e615) {
                    let _e617 = in_dielectric;
                    let _e618 = !(_e617);
                    phi_9686_ = _e618;
                    if _e618 {
                        let _e619 = NsW;
                        let _e620 = dW;
                        phi_9686_ = (dot(_e619, _e620) > 0f);
                    }
                    let _e624 = phi_9686_;
                    phi_9687_ = _e624;
                }
                let _e626 = phi_9687_;
                if _e626 {
                    let _e627 = NsW;
                    NsW = (_e627 * -1f);
                }
            } else {
                let _e629 = NsW;
                let _e630 = dW;
                if (dot(_e629, _e630) > 0f) {
                    let _e633 = NsW;
                    NsW = (_e633 * -1f);
                }
            }
            let _e635 = NgW;
            let _e636 = NsW;
            if (dot(_e635, _e636) < 0f) {
                let _e639 = NgW;
                NgW = (_e639 * -1f);
            }
            let _e642 = unnamed.smooth_normals;
            if (_e642 != 0u) {
                let _e644 = surfaceshader_5;
                let _e645 = (_e644 == 1i);
                phi_9720_ = _e645;
                if _e645 {
                    let _e646 = mtlx_openpbr_is_opaque_u0028_();
                    phi_9720_ = _e646;
                }
                let _e648 = phi_9720_;
                phi_9727_ = _e648;
                if _e648 {
                    let _e649 = NsW;
                    let _e650 = dW;
                    phi_9727_ = (dot(_e649, _e650) > 0f);
                }
                let _e654 = phi_9727_;
                if _e654 {
                    let _e655 = NgW;
                    let _e657 = NgW;
                    let _e658 = NsW;
                    let _e661 = NsW;
                    NsW = (((_e655 * 2f) * dot(_e657, _e658)) - _e661);
                }
                let _e663 = NsW;
                param_933 = _e663;
                let _e664 = TsW_next;
                param_934 = _e664;
                let _e665 = baryCoord_3;
                param_935 = _e665;
                let _e666 = texCoord_3;
                param_936 = _e666;
                let _e667 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_933), (&param_934), (&param_935), (&param_936));
                basis_21 = _e667;
            } else {
                let _e668 = NgW;
                param_937 = _e668;
                let _e669 = TsW_next;
                param_938 = _e669;
                let _e670 = baryCoord_3;
                param_939 = _e670;
                let _e671 = texCoord_3;
                param_940 = _e671;
                let _e672 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_937), (&param_938), (&param_939), (&param_940));
                basis_21 = _e672;
            }
            let _e673 = dW;
            winputW = -(_e673);
            let _e675 = winputW;
            param_941 = _e675;
            let _e676 = basis_21;
            param_942 = _e676;
            let _e677 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_941), (&param_942));
            winputL_11 = _e677;
            let _e679 = winputL_11[2u];
            if (abs(_e679) < 0.001f) {
                break;
            }
            thin_walled = false;
            let _e682 = surfaceshader_5;
            if (_e682 == 1i) {
                let _e684 = pW_15;
                param_943 = _e684;
                let _e685 = basis_21;
                param_944 = _e685;
                let _e686 = winputL_11;
                param_945 = _e686;
                let _e687 = rndSeed_11;
                param_946 = _e687;
                mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_943), (&param_944), (&param_945), (&param_946));
                let _e688 = param_946;
                rndSeed_11 = _e688;
                let _e689 = mtlx_openpbr_is_thinwalled_u0028_();
                thin_walled = _e689;
            }
            let _e690 = surfaceshader_5;
            if (_e690 == 1i) {
                let _e692 = throughput;
                let _e693 = basis_21;
                param_947 = _e693;
                let _e694 = winputL_11;
                param_948 = _e694;
                let _e695 = evaluateThinFilmEnvironmentReflection_u0028_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_947), (&param_948));
                Ltf = (_e692 * _e695);
                let _e697 = Ltf;
                param_949 = _e697;
                let _e698 = maxComponent_u0028_vf3_u003b((&param_949));
                maxLtf = _e698;
                let _e699 = maxLtf;
                let _e701 = unnamed.firefly_clamp;
                if (_e699 > _e701) {
                    let _e704 = unnamed.firefly_clamp;
                    let _e705 = maxLtf;
                    let _e707 = Ltf;
                    Ltf = (_e707 * (_e704 / _e705));
                }
                let _e709 = Ltf;
                let _e710 = L_12;
                L_12 = (_e710 + _e709);
            }
            let _e712 = pW_15;
            param_950 = _e712;
            let _e713 = basis_21;
            param_951 = _e713;
            let _e714 = winputL_11;
            param_952 = _e714;
            let _e715 = rndSeed_11;
            param_953 = _e715;
            let _e716 = surfaceshader_5;
            param_954 = _e716;
            let _e717 = sampleBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b_i1_u003b_vf3_u003b_f1_u003b_struct_u002d_Volume_u002d_vf3_u002d_vf3_u002d_f11_u003b((&param_950), (&param_951), (&param_952), (&param_953), (&param_954), (&param_955), (&param_956), (&param_957));
            let _e718 = param_953;
            rndSeed_11 = _e718;
            let _e719 = param_955;
            woutputL_13 = _e719;
            let _e720 = param_956;
            bsdfPdf_continuation = _e720;
            let _e721 = param_957;
            internal_medium_2 = _e721;
            f_2 = _e717;
            let _e722 = woutputL_13;
            param_958 = _e722;
            let _e723 = basis_21;
            param_959 = _e723;
            let _e724 = localToWorld_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_958), (&param_959));
            woutputW_7 = _e724;
            let _e725 = surfaceshader_5;
            let _e726 = (_e725 == 1i);
            phi_9858_ = _e726;
            if _e726 {
                let _e728 = winputL_11[2u];
                let _e730 = woutputL_13[2u];
                phi_9858_ = ((_e728 * _e730) < 0f);
            }
            let _e734 = phi_9858_;
            transmitted_sample = _e734;
            let _e735 = surfaceshader_5;
            let _e737 = transmitted_sample;
            if ((_e735 == 1i) && !(_e737)) {
                local_20 = 1f;
            } else {
                let _e740 = woutputW_7;
                let _e742 = basis_21.nW;
                local_20 = abs(dot(_e740, _e742));
            }
            let _e745 = local_20;
            cos_out = _e745;
            let _e746 = f_2;
            let _e747 = bsdfPdf_continuation;
            let _e751 = cos_out;
            surface_throughput = ((_e746 / vec3(max(0.000001f, _e747))) * _e751);
            let _e753 = surface_throughput;
            param_960 = _e753;
            let _e754 = maxComponent_u0028_vf3_u003b((&param_960));
            maxComp = _e754;
            let _e755 = maxComp;
            let _e757 = unnamed.firefly_clamp;
            if (_e755 > _e757) {
                let _e760 = unnamed.firefly_clamp;
                let _e761 = maxComp;
                let _e763 = surface_throughput;
                surface_throughput = (_e763 * (_e760 / _e761));
            }
            let _e765 = woutputW_7;
            dW = _e765;
            let _e766 = surfaceshader_5;
            if (_e766 == 1i) {
                let _e768 = throughput;
                let _e769 = pW_15;
                param_961 = _e769;
                let _e770 = basis_21;
                param_962 = _e770;
                let _e771 = winputL_11;
                param_963 = _e771;
                let _e772 = evaluateEdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b((&param_961), (&param_962), (&param_963));
                Le = (_e768 * _e772);
                let _e774 = Le;
                param_964 = _e774;
                let _e775 = maxComponent_u0028_vf3_u003b((&param_964));
                maxLe = _e775;
                let _e776 = maxLe;
                let _e778 = unnamed.firefly_clamp;
                if (_e776 > _e778) {
                    let _e781 = unnamed.firefly_clamp;
                    let _e782 = maxLe;
                    let _e784 = Le;
                    Le = (_e784 * (_e781 / _e782));
                }
                let _e786 = Le;
                let _e787 = L_12;
                L_12 = (_e787 + _e786);
            }
            let _e789 = thin_walled;
            let _e791 = surfaceshader_5;
            let _e793 = (!(_e789) && (_e791 == 1i));
            phi_9949_ = _e793;
            if _e793 {
                let _e794 = winputW;
                let _e795 = NgW;
                let _e797 = dW;
                let _e798 = NgW;
                phi_9949_ = ((dot(_e794, _e795) * dot(_e797, _e798)) < 0f);
            }
            let _e803 = phi_9949_;
            transmitted = _e803;
            let _e804 = transmitted;
            if _e804 {
                let _e805 = in_dielectric;
                in_dielectric = !(_e805);
            }
            let _e807 = in_dielectric;
            let _e809 = transmitted;
            if (!(_e807) && !(_e809)) {
                let _e812 = pW_15;
                param_965 = _e812;
                let _e813 = basis_21;
                param_966 = _e813;
                let _e814 = rndSeed_11;
                param_970 = _e814;
                let _e815 = LiDirect_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_f1_u003b_u1_u003b((&param_965), (&param_966), (&param_967), (&param_968), (&param_969), (&param_970));
                let _e816 = param_967;
                shadowL_2 = _e816;
                let _e817 = param_968;
                shadowW_2 = _e817;
                let _e818 = param_969;
                lightPdf_3 = _e818;
                let _e819 = param_970;
                rndSeed_11 = _e819;
                Li_8 = _e815;
                let _e820 = Li_8;
                param_971 = _e820;
                let _e821 = maxComponent_u0028_vf3_u003b((&param_971));
                if (_e821 > 0.000000000001f) {
                    bsdfPdf_shadow = 0.000001f;
                    let _e823 = pW_15;
                    param_972 = _e823;
                    let _e824 = basis_21;
                    param_973 = _e824;
                    let _e825 = winputL_11;
                    param_974 = _e825;
                    let _e826 = shadowL_2;
                    param_975 = _e826;
                    let _e827 = surfaceshader_5;
                    param_976 = _e827;
                    let _e828 = bsdfPdf_shadow;
                    param_977 = _e828;
                    let _e829 = evaluateBsdf_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b_i1_u003b_f1_u003b((&param_972), (&param_973), (&param_974), (&param_975), (&param_976), (&param_977));
                    let _e830 = param_977;
                    bsdfPdf_shadow = _e830;
                    fshadow = _e829;
                    let _e831 = lightPdf_3;
                    let _e832 = bsdfPdf_shadow;
                    let _e833 = powerHeuristic_u0028_f1_u003b_f1_u003b(_e831, _e832);
                    misWeightLight_1 = _e833;
                    let _e834 = surfaceshader_5;
                    if (_e834 == 1i) {
                        local_21 = 1f;
                    } else {
                        let _e836 = shadowW_2;
                        let _e838 = basis_21.nW;
                        local_21 = abs(dot(_e836, _e838));
                    }
                    let _e841 = local_21;
                    cos_shadow = _e841;
                    let _e842 = misWeightLight_1;
                    let _e843 = fshadow;
                    let _e845 = cos_shadow;
                    let _e847 = Li_8;
                    let _e849 = lightPdf_3;
                    Ld = ((((_e843 * _e842) * _e845) * _e847) / vec3(max(0.000001f, _e849)));
                    let _e853 = throughput;
                    let _e854 = Ld;
                    Lcontrib = (_e853 * _e854);
                    let _e856 = Lcontrib;
                    param_978 = _e856;
                    let _e857 = maxComponent_u0028_vf3_u003b((&param_978));
                    maxLcontrib = _e857;
                    let _e858 = maxLcontrib;
                    let _e860 = unnamed.firefly_clamp;
                    if (_e858 > _e860) {
                        let _e863 = unnamed.firefly_clamp;
                        let _e864 = maxLcontrib;
                        let _e866 = Lcontrib;
                        Lcontrib = (_e866 * (_e863 / _e864));
                    }
                    let _e868 = Lcontrib;
                    let _e869 = L_12;
                    L_12 = (_e869 + _e868);
                }
            }
            let _e871 = NgW;
            let _e872 = dW;
            let _e873 = NgW;
            let _e878 = pW_15;
            pW_15 = (_e878 + ((_e871 * sign(dot(_e872, _e873))) * 0.0001f));
            let _e880 = surface_throughput;
            let _e881 = throughput;
            throughput = (_e881 * _e880);
            let _e883 = throughput;
            param_979 = _e883;
            let _e884 = maxComponent_u0028_vf3_u003b((&param_979));
            maxTP = _e884;
            let _e885 = maxTP;
            let _e887 = unnamed.firefly_clamp;
            if (_e885 > _e887) {
                let _e890 = unnamed.firefly_clamp;
                let _e891 = maxTP;
                let _e893 = throughput;
                throughput = (_e893 * (_e890 / _e891));
            }
            let _e895 = throughput;
            param_980 = _e895;
            let _e896 = maxComponent_u0028_vf3_u003b((&param_980));
            let _e898 = vertex;
            if ((_e896 < 1f) && (_e898 > 1i)) {
                let _e901 = throughput;
                param_981 = _e901;
                let _e902 = maxComponent_u0028_vf3_u003b((&param_981));
                q = max(0f, (1f - _e902));
                let _e905 = rndSeed_11;
                param_982 = _e905;
                let _e906 = rand_u0028_u1_u003b((&param_982));
                let _e907 = param_982;
                rndSeed_11 = _e907;
                let _e908 = q;
                if (_e906 < _e908) {
                    break;
                }
                let _e910 = q;
                let _e912 = throughput;
                throughput = (_e912 / vec3((1f - _e910)));
            }
            continue;
        } else {
            break;
        }
        continuing {
            let _e915 = vertex;
            vertex = (_e915 + 1i);
        }
    }
    let _e917 = L_12;
    mtlxFragmentColor[0u] = _e917.x;
    mtlxFragmentColor[1u] = _e917.y;
    mtlxFragmentColor[2u] = _e917.z;
    let _e925 = unnamed.accumulation_weight;
    mtlxFragmentColor[3u] = _e925;
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
