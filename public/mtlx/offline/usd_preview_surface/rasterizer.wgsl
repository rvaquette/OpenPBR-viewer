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

struct lightshader {
    intensity: vec3<f32>,
    direction: vec3<f32>,
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
    mtlxLightCount: i32,
    u_lightData: array<i32, 1>,
}

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
var<private> thin_walled_1: bool;
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
@group(0) @binding(15) 
var<uniform> unnamed: MtlxMaterialUniforms;
@group(0) @binding(34) 
var ground_texture_texture: texture_2d<f32>;
@group(0) @binding(35) 
var ground_texture_sampler: sampler;
@group(0) @binding(16) 
var envMap_texture: texture_cube<f32>;
@group(0) @binding(17) 
var envMap_sampler: sampler;
@group(0) @binding(18) 
var envMapLatLong_texture: texture_2d<f32>;
@group(0) @binding(19) 
var envMapLatLong_sampler: sampler;
@group(0) @binding(20) 
var envMapIrradiance_texture: texture_2d<f32>;
@group(0) @binding(21) 
var envMapIrradiance_sampler: sampler;
var<private> normalWorld: vec3<f32>;
var<private> positionWorld: vec3<f32>;
var<private> tangentWorld: vec3<f32>;
var<private> mtlxRasterOut_2: vec4<f32>;
var<private> gl_FragCoord_1: vec4<f32>;
var<private> sunBasis: Basis;
var<private> mtlxFragmentColor: vec4<f32>;
var<private> vUv_1: vec2<f32>;

fn ground_albedo_u0028_vf3_u003b(pW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var uv: vec2<f32>;

    let _e282 = (*pW)[0u];
    let _e284 = (*pW)[2u];
    uv = (((vec2<f32>(_e282, -(_e284)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e292 = uv;
    let _e293 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e292, 0.0);
    return _e293.xyz;
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e284 = (*bg);
    let _e285 = (*fg);
    let _e286 = (*mixValue);
    (*result) = mix(_e284, _e285, vec3(_e286));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e284 = (*cosTheta);
    x = clamp((1f - _e284), 0f, 1f);
    let _e287 = (*F0_);
    let _e288 = (*F90_);
    let _e289 = x;
    let _e290 = (*exponent);
    return mix(_e287, _e288, vec3(pow(_e289, _e290)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e282 = (*N);
    let _e283 = (*V);
    if (dot(_e282, _e283) < 0f) {
        let _e286 = (*N);
        local = -(_e286);
    } else {
        let _e288 = (*N);
        local = _e288;
    }
    let _e289 = local;
    return _e289;
}

fn mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(closureData_1: ptr<function, ClosureData>, color0_: ptr<function, vec3<f32>>, color90_: ptr<function, vec3<f32>>, exponent_1: ptr<function, f32>, base: ptr<function, vec3<f32>>, result_1: ptr<function, vec3<f32>>) {
    var N_1: vec3<f32>;
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var NdotV: f32;
    var f: vec3<f32>;
    var param_2: f32;
    var param_3: vec3<f32>;
    var param_4: vec3<f32>;
    var param_5: f32;

    let _e295 = (*closureData_1).closureType;
    if (_e295 == 4i) {
        let _e298 = (*closureData_1).N;
        param = _e298;
        let _e300 = (*closureData_1).V;
        param_1 = _e300;
        let _e301 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param), (&param_1));
        N_1 = _e301;
        let _e302 = N_1;
        let _e304 = (*closureData_1).V;
        NdotV = clamp(dot(_e302, _e304), 0.00000001f, 1f);
        let _e307 = NdotV;
        param_2 = _e307;
        let _e308 = (*color0_);
        param_3 = _e308;
        let _e309 = (*color90_);
        param_4 = _e309;
        let _e310 = (*exponent_1);
        param_5 = _e310;
        let _e311 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_2), (&param_3), (&param_4), (&param_5));
        f = _e311;
        let _e312 = (*base);
        let _e313 = f;
        (*result_1) = (_e312 * _e313);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e283 = (*in1_);
    let _e284 = (*in2_);
    (*result_2) = (_e283 * _e284);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e283 = (*closureData_3).closureType;
    if (_e283 == 4i) {
        let _e285 = (*color);
        (*result_3) = _e285;
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_4: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e284 = (*in2_1);
    tint = clamp(_e284, vec3(0f), vec3(1f));
    let _e289 = (*in1_1).response;
    let _e290 = tint;
    (*result_4).response = (_e289 * _e290);
    let _e294 = (*in1_1).throughput;
    (*result_4).throughput = _e294;
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_5: ptr<function, BSDF>) {
    let _e284 = (*top).response;
    let _e286 = (*base_1).response;
    let _e288 = (*top).throughput;
    (*result_5).response = (_e284 + (_e286 * _e288));
    let _e293 = (*top).throughput;
    let _e295 = (*base_1).throughput;
    (*result_5).throughput = (_e293 * _e295);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e283 = (*dir)[1u];
    latitude = ((-(asin(_e283)) * 0.31830987f) + 0.5f);
    let _e289 = (*dir)[0u];
    let _e291 = (*dir)[2u];
    longitude = (((atan2(_e289, -(_e291)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e297 = longitude;
    let _e298 = latitude;
    return vec2<f32>(_e297, _e298);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e281 = (*m);
    let _e282 = (*v);
    return (_e281 * _e282);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_6: mat4x4<f32>;
    var param_7: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_8: vec3<f32>;

    let _e287 = (*dir_1);
    let _e292 = (*transform);
    param_6 = _e292;
    param_7 = vec4<f32>(_e287.x, _e287.y, _e287.z, 0f);
    let _e293 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_6), (&param_7));
    envDir = normalize(_e293.xyz);
    let _e296 = envDir;
    param_8 = _e296;
    let _e297 = mx_latlong_projection_u0028_vf3_u003b((&param_8));
    uv_1 = _e297;
    let _e298 = uv_1;
    let _e299 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e298, 0.0);
    return _e299.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e282 = a;
    c = cos(_e282);
    let _e284 = a;
    s = sin(_e284);
    let _e286 = c;
    let _e287 = s;
    let _e289 = s;
    let _e290 = c;
    return mat4x4<f32>(vec4<f32>(_e286, 0f, -(_e287), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e289, 0f, _e290, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_9: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: f32;

    let _e284 = mtlxEnvMatrix_u0028_();
    let _e285 = (*N_2);
    param_9 = _e285;
    param_10 = _e284;
    param_11 = 0f;
    let _e286 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_9), (&param_10), (&param_11));
    Li = _e286;
    let _e287 = Li;
    let _e289 = unnamed.skyPower;
    return (_e287 * _e289);
}

fn mx_square_u0028_f1_u003b(x_1: ptr<function, f32>) -> f32 {
    let _e280 = (*x_1);
    let _e281 = (*x_1);
    return (_e280 * _e281);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_12: f32;

    let _e283 = (*roughness);
    let _e286 = (*NdotV_1);
    let _e288 = (*roughness);
    let _e291 = (*roughness);
    param_12 = _e291;
    let _e292 = mx_square_u0028_f1_u003b((&param_12));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e283)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e286) * _e288)) + (vec2<f32>(1.4385f, 2.0315f) * _e292));
    let _e296 = r[0u];
    let _e298 = r[1u];
    return (_e296 / _e298);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_13: f32;
    var param_14: f32;

    let _e284 = (*NdotV_2);
    param_13 = _e284;
    let _e285 = (*roughness_1);
    param_14 = _e285;
    let _e286 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_13), (&param_14));
    dirAlbedo = _e286;
    let _e287 = dirAlbedo;
    return clamp(_e287, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e280 = (*x_2);
    let _e281 = (*x_2);
    return (_e280 * _e281);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e281 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e281)));
    let _e285 = A;
    let _e286 = (*roughness_2);
    return (_e285 * (1f + (0.07248821f * _e286)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_15: f32;
    var G: f32;

    let _e286 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e286)));
    let _e290 = (*roughness_3);
    let _e291 = A_1;
    B = (_e290 * _e291);
    let _e293 = (*cosTheta_1);
    param_15 = _e293;
    let _e294 = mx_square_u0028_f1_u003b((&param_15));
    Si = sqrt(max(0f, (1f - _e294)));
    let _e298 = Si;
    let _e299 = (*cosTheta_1);
    let _e302 = Si;
    let _e303 = (*cosTheta_1);
    let _e307 = Si;
    let _e308 = (*cosTheta_1);
    let _e310 = Si;
    let _e311 = Si;
    let _e313 = Si;
    let _e317 = Si;
    G = ((_e298 * (acos(clamp(_e299, -1f, 1f)) - (_e302 * _e303))) + ((2f * (((_e307 / _e308) * (1f - ((_e310 * _e311) * _e313))) - _e317)) / 3f));
    let _e322 = A_1;
    let _e323 = B;
    let _e324 = G;
    return (_e322 + ((_e323 * _e324) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_16: f32;
    var param_17: f32;
    var avgAlbedo: f32;
    var param_18: f32;
    var colorMultiScatter: vec3<f32>;
    var param_19: vec3<f32>;

    let _e289 = (*cosTheta_2);
    param_16 = _e289;
    let _e290 = (*roughness_4);
    param_17 = _e290;
    let _e291 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_16), (&param_17));
    dirAlbedo_1 = _e291;
    let _e292 = (*roughness_4);
    param_18 = _e292;
    let _e293 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_18));
    avgAlbedo = _e293;
    let _e294 = (*color_1);
    param_19 = _e294;
    let _e295 = mx_square_u0028_vf3_u003b((&param_19));
    let _e296 = avgAlbedo;
    let _e298 = (*color_1);
    let _e299 = avgAlbedo;
    colorMultiScatter = ((_e295 * _e296) / (vec3<f32>(1f, 1f, 1f) - (_e298 * max(0f, (1f - _e299)))));
    let _e305 = colorMultiScatter;
    let _e306 = (*color_1);
    let _e307 = dirAlbedo_1;
    return mix(_e305, _e306, vec3(_e307));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_20: f32;
    var A_2: f32;
    var B_1: f32;

    let _e290 = (*LdotV);
    let _e291 = (*NdotL);
    let _e292 = (*NdotV_3);
    s_1 = (_e290 - (_e291 * _e292));
    let _e295 = s_1;
    if (_e295 > 0f) {
        let _e297 = s_1;
        let _e298 = (*NdotL);
        let _e299 = (*NdotV_3);
        local_1 = (_e297 / max(_e298, _e299));
    } else {
        local_1 = 0f;
    }
    let _e302 = local_1;
    stinv = _e302;
    let _e303 = (*roughness_5);
    param_20 = _e303;
    let _e304 = mx_square_u0028_f1_u003b((&param_20));
    sigma2_ = _e304;
    let _e305 = sigma2_;
    let _e306 = sigma2_;
    A_2 = (1f - (0.5f * (_e305 / (_e306 + 0.33f))));
    let _e311 = sigma2_;
    let _e313 = sigma2_;
    B_1 = ((0.45f * _e311) / (_e313 + 0.09f));
    let _e316 = A_2;
    let _e317 = B_1;
    let _e318 = stinv;
    return (_e316 + (_e317 * _e318));
}

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_4: ptr<function, f32>, NdotL_1: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_2: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_21: f32;
    var param_22: f32;
    var dirAlbedoL: f32;
    var param_23: f32;
    var param_24: f32;
    var avgAlbedo_1: f32;
    var param_25: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_26: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e300 = (*LdotV_1);
    let _e301 = (*NdotL_1);
    let _e302 = (*NdotV_4);
    s_2 = (_e300 - (_e301 * _e302));
    let _e305 = s_2;
    if (_e305 > 0f) {
        let _e307 = s_2;
        let _e308 = (*NdotL_1);
        let _e309 = (*NdotV_4);
        local_2 = (_e307 / max(_e308, _e309));
    } else {
        let _e312 = s_2;
        local_2 = _e312;
    }
    let _e313 = local_2;
    stinv_1 = _e313;
    let _e314 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e314)));
    let _e318 = (*color_2);
    let _e319 = A_3;
    let _e321 = (*roughness_6);
    let _e322 = stinv_1;
    lobeSingleScatter = ((_e318 * _e319) * (1f + (_e321 * _e322)));
    let _e326 = (*NdotV_4);
    param_21 = _e326;
    let _e327 = (*roughness_6);
    param_22 = _e327;
    let _e328 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_21), (&param_22));
    dirAlbedoV = _e328;
    let _e329 = (*NdotL_1);
    param_23 = _e329;
    let _e330 = (*roughness_6);
    param_24 = _e330;
    let _e331 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_23), (&param_24));
    dirAlbedoL = _e331;
    let _e332 = (*roughness_6);
    param_25 = _e332;
    let _e333 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_25));
    avgAlbedo_1 = _e333;
    let _e334 = (*color_2);
    param_26 = _e334;
    let _e335 = mx_square_u0028_vf3_u003b((&param_26));
    let _e336 = avgAlbedo_1;
    let _e338 = (*color_2);
    let _e339 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e335 * _e336) / (vec3<f32>(1f, 1f, 1f) - (_e338 * max(0f, (1f - _e339)))));
    let _e345 = colorMultiScatter_1;
    let _e346 = dirAlbedoV;
    let _e350 = dirAlbedoL;
    let _e354 = avgAlbedo_1;
    lobeMultiScatter = (((_e345 * max(0.00000001f, (1f - _e346))) * max(0.00000001f, (1f - _e350))) / vec3(max(0.00000001f, (1f - _e354))));
    let _e359 = lobeSingleScatter;
    let _e360 = lobeMultiScatter;
    return (_e359 + _e360);
}

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, weight: ptr<function, f32>, color_3: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_3: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L: vec3<f32>;
    var param_27: vec3<f32>;
    var param_28: vec3<f32>;
    var NdotV_5: f32;
    var NdotL_2: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_29: f32;
    var param_30: f32;
    var param_31: f32;
    var param_32: f32;
    var param_33: vec3<f32>;
    var param_34: f32;
    var param_35: f32;
    var param_36: f32;
    var param_37: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_38: f32;
    var param_39: f32;
    var param_40: vec3<f32>;
    var param_41: f32;
    var param_42: f32;
    var Li_1: vec3<f32>;
    var param_43: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e314 = (*weight);
    if (_e314 < 0.00000001f) {
        return;
    }
    let _e317 = (*closureData_6).V;
    V_1 = _e317;
    let _e319 = (*closureData_6).L;
    L = _e319;
    let _e320 = (*N_3);
    param_27 = _e320;
    let _e321 = V_1;
    param_28 = _e321;
    let _e322 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_27), (&param_28));
    (*N_3) = _e322;
    let _e323 = (*N_3);
    let _e324 = V_1;
    NdotV_5 = clamp(dot(_e323, _e324), 0.00000001f, 1f);
    let _e328 = (*closureData_6).closureType;
    if (_e328 == 1i) {
        let _e330 = (*N_3);
        let _e331 = L;
        NdotL_2 = clamp(dot(_e330, _e331), 0.00000001f, 1f);
        let _e334 = L;
        let _e335 = V_1;
        LdotV_2 = clamp(dot(_e334, _e335), 0.00000001f, 1f);
        let _e338 = (*energy_compensation);
        if _e338 {
            let _e339 = NdotV_5;
            param_29 = _e339;
            let _e340 = NdotL_2;
            param_30 = _e340;
            let _e341 = LdotV_2;
            param_31 = _e341;
            let _e342 = (*roughness_7);
            param_32 = _e342;
            let _e343 = (*color_3);
            param_33 = _e343;
            let _e344 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_29), (&param_30), (&param_31), (&param_32), (&param_33));
            local_3 = _e344;
        } else {
            let _e345 = NdotV_5;
            param_34 = _e345;
            let _e346 = NdotL_2;
            param_35 = _e346;
            let _e347 = LdotV_2;
            param_36 = _e347;
            let _e348 = (*roughness_7);
            param_37 = _e348;
            let _e349 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_34), (&param_35), (&param_36), (&param_37));
            let _e350 = (*color_3);
            local_3 = (_e350 * _e349);
        }
        let _e352 = local_3;
        diffuse = _e352;
        let _e353 = diffuse;
        let _e355 = (*closureData_6).occlusion;
        let _e357 = (*weight);
        let _e359 = NdotL_2;
        (*bsdf).response = ((((_e353 * _e355) * _e357) * _e359) * 0.31830987f);
    } else {
        let _e364 = (*closureData_6).closureType;
        if (_e364 == 3i) {
            let _e366 = (*energy_compensation);
            if _e366 {
                let _e367 = NdotV_5;
                param_38 = _e367;
                let _e368 = (*roughness_7);
                param_39 = _e368;
                let _e369 = (*color_3);
                param_40 = _e369;
                let _e370 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_38), (&param_39), (&param_40));
                local_4 = _e370;
            } else {
                let _e371 = NdotV_5;
                param_41 = _e371;
                let _e372 = (*roughness_7);
                param_42 = _e372;
                let _e373 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_41), (&param_42));
                let _e374 = (*color_3);
                local_4 = (_e374 * _e373);
            }
            let _e376 = local_4;
            diffuse_1 = _e376;
            let _e377 = (*N_3);
            param_43 = _e377;
            let _e378 = mx_environment_irradiance_u0028_vf3_u003b((&param_43));
            Li_1 = _e378;
            let _e379 = Li_1;
            let _e380 = diffuse_1;
            let _e382 = (*weight);
            (*bsdf).response = ((_e379 * _e380) * _e382);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_6: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e284 = (*in2_2);
    weight_1 = clamp(_e284, 0f, 1f);
    let _e287 = (*in1_2).response;
    let _e288 = weight_1;
    (*result_6).response = (_e287 * _e288);
    let _e292 = (*in1_2).throughput;
    (*result_6).throughput = _e292;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_7: ptr<function, BSDF>) {
    let _e284 = (*in1_3).response;
    let _e286 = (*in2_3).response;
    (*result_7).response = (_e284 + _e286);
    let _e290 = (*in1_3).throughput;
    let _e292 = (*in2_3).throughput;
    (*result_7).throughput = max(((_e290 + _e292) - vec3(1f)), vec3(0f));
    return;
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e284 = (*shape);
    let _e286 = (*dist);
    num1_ = exp((-(_e284) * _e286));
    let _e289 = (*shape);
    let _e291 = (*dist);
    num2_ = exp(((-(_e289) * _e291) / vec3(3f)));
    let _e296 = (*dist);
    denom = max(_e296, 0.00000001f);
    let _e298 = num1_;
    let _e299 = num2_;
    let _e301 = denom;
    return ((_e298 + _e299) / vec3(_e301));
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
    var param_44: f32;
    var param_45: vec3<f32>;

    let _e293 = (*N_4);
    let _e294 = (*L_1);
    theta = acos(dot(_e293, _e294));
    let _e297 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e297, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e301 = i;
        if (_e301 < 32i) {
            let _e303 = i;
            x_3 = (-3.1415927f + ((f32(_e303) + 0.5f) * 0.19634955f));
            let _e308 = (*radius);
            let _e309 = x_3;
            dist_1 = (_e308 * abs((2f * sin((_e309 * 0.5f)))));
            let _e315 = dist_1;
            param_44 = _e315;
            let _e316 = shape_1;
            param_45 = _e316;
            let _e317 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_44), (&param_45));
            R = _e317;
            let _e318 = R;
            let _e319 = theta;
            let _e320 = x_3;
            let _e325 = sumD;
            sumD = (_e325 + (_e318 * max(cos((_e319 + _e320)), 0f)));
            let _e327 = R;
            let _e328 = sumR;
            sumR = (_e328 + _e327);
            continue;
        } else {
            break;
        }
        continuing {
            let _e330 = i;
            i = (_e330 + 1i);
        }
    }
    let _e332 = sumD;
    let _e333 = sumR;
    return (_e332 / _e333);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, L_2: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_46: vec3<f32>;
    var param_47: vec3<f32>;
    var param_48: f32;
    var param_49: vec3<f32>;

    let _e290 = (*N_5);
    let _e291 = fwidth(_e290);
    let _e293 = (*P);
    let _e294 = fwidth(_e293);
    curvature = (length(_e291) / length(_e294));
    let _e297 = curvature;
    radius_1 = (1f / max(_e297, 0.01f));
    let _e300 = (*albedo);
    let _e301 = (*N_5);
    param_46 = _e301;
    let _e302 = (*L_2);
    param_47 = _e302;
    let _e303 = radius_1;
    param_48 = _e303;
    let _e304 = (*mfp_1);
    param_49 = _e304;
    let _e305 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_46), (&param_47), (&param_48), (&param_49));
    return ((_e300 * _e305) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
}

fn mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_9: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color_4: ptr<function, vec3<f32>>, radius_2: ptr<function, vec3<f32>>, anisotropy: ptr<function, f32>, N_6: ptr<function, vec3<f32>>, bsdf_1: ptr<function, BSDF>) {
    var V_2: vec3<f32>;
    var L_3: vec3<f32>;
    var P_1: vec3<f32>;
    var occlusion: f32;
    var param_50: vec3<f32>;
    var param_51: vec3<f32>;
    var sss: vec3<f32>;
    var param_52: vec3<f32>;
    var param_53: vec3<f32>;
    var param_54: vec3<f32>;
    var param_55: vec3<f32>;
    var param_56: vec3<f32>;
    var NdotL_3: f32;
    var visibleOcclusion: f32;
    var Li_2: vec3<f32>;
    var param_57: vec3<f32>;

    (*bsdf_1).throughput = vec3<f32>(0f, 0f, 0f);
    let _e303 = (*weight_2);
    if (_e303 < 0.00000001f) {
        return;
    }
    let _e306 = (*closureData_9).V;
    V_2 = _e306;
    let _e308 = (*closureData_9).L;
    L_3 = _e308;
    let _e310 = (*closureData_9).P;
    P_1 = _e310;
    let _e312 = (*closureData_9).occlusion;
    occlusion = _e312;
    let _e313 = (*N_6);
    param_50 = _e313;
    let _e314 = V_2;
    param_51 = _e314;
    let _e315 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_50), (&param_51));
    (*N_6) = _e315;
    let _e317 = (*closureData_9).closureType;
    if (_e317 == 1i) {
        let _e319 = (*N_6);
        param_52 = _e319;
        let _e320 = L_3;
        param_53 = _e320;
        let _e321 = P_1;
        param_54 = _e321;
        let _e322 = (*color_4);
        param_55 = _e322;
        let _e323 = (*radius_2);
        param_56 = _e323;
        let _e324 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_52), (&param_53), (&param_54), (&param_55), (&param_56));
        sss = _e324;
        let _e325 = (*N_6);
        let _e326 = L_3;
        NdotL_3 = clamp(dot(_e325, _e326), 0.00000001f, 1f);
        let _e329 = NdotL_3;
        let _e330 = occlusion;
        visibleOcclusion = (1f - (_e329 * (1f - _e330)));
        let _e334 = sss;
        let _e335 = visibleOcclusion;
        let _e337 = (*weight_2);
        (*bsdf_1).response = ((_e334 * _e335) * _e337);
    } else {
        let _e341 = (*closureData_9).closureType;
        if (_e341 == 3i) {
            let _e343 = (*N_6);
            param_57 = _e343;
            let _e344 = mx_environment_irradiance_u0028_vf3_u003b((&param_57));
            Li_2 = _e344;
            let _e345 = Li_2;
            let _e346 = (*color_4);
            let _e348 = (*weight_2);
            (*bsdf_1).response = ((_e345 * _e346) * _e348);
        }
    }
    return;
}

fn mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_10: ptr<function, ClosureData>, weight_3: ptr<function, f32>, color_5: ptr<function, vec3<f32>>, N_7: ptr<function, vec3<f32>>, bsdf_2: ptr<function, BSDF>) {
    var V_3: vec3<f32>;
    var L_4: vec3<f32>;
    var NdotL_4: f32;
    var Li_3: vec3<f32>;
    var param_58: vec3<f32>;

    (*bsdf_2).throughput = vec3<f32>(0f, 0f, 0f);
    let _e290 = (*weight_3);
    if (_e290 < 0.00000001f) {
        return;
    }
    let _e293 = (*closureData_10).V;
    V_3 = _e293;
    let _e295 = (*closureData_10).L;
    L_4 = _e295;
    let _e296 = (*N_7);
    (*N_7) = -(_e296);
    let _e299 = (*closureData_10).closureType;
    if (_e299 == 1i) {
        let _e301 = (*N_7);
        let _e302 = L_4;
        NdotL_4 = clamp(dot(_e301, _e302), 0f, 1f);
        let _e305 = (*color_5);
        let _e306 = (*weight_3);
        let _e308 = NdotL_4;
        (*bsdf_2).response = (((_e305 * _e306) * _e308) * 0.31830987f);
    } else {
        let _e313 = (*closureData_10).closureType;
        if (_e313 == 3i) {
            let _e315 = (*N_7);
            param_58 = _e315;
            let _e316 = mx_environment_irradiance_u0028_vf3_u003b((&param_58));
            Li_3 = _e316;
            let _e317 = Li_3;
            let _e318 = (*color_5);
            let _e320 = (*weight_3);
            (*bsdf_2).response = ((_e317 * _e318) * _e320);
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_4: ptr<function, f32>, y: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_1: f32;
    var o: f32;
    var param_59: f32;

    let _e285 = (*y);
    let _e286 = (*y);
    let _e290 = (*y);
    let _e291 = (*y);
    s_3 = ((_e285 * (0.0206607f + (1.58491f * _e286))) / (0.0379424f + (_e290 * (1.32227f + _e291))));
    let _e296 = (*y);
    let _e297 = (*y);
    let _e298 = (*y);
    let _e299 = (*y);
    let _e301 = (*y);
    let _e309 = (*y);
    m_1 = ((_e296 * (-0.193854f + (_e297 * (-1.14885f + (_e298 * (1.7932f - ((0.95943f * _e299) * _e301))))))) / (0.046391f + _e309));
    let _e312 = (*y);
    let _e313 = (*y);
    let _e316 = (*y);
    let _e320 = (*y);
    let _e321 = (*y);
    o = ((_e312 * (0.000654023f + ((-0.0207818f + (0.119681f * _e313)) * _e316))) / (1.26264f + (_e320 * (-1.92021f + _e321))));
    let _e326 = (*x_4);
    let _e327 = m_1;
    let _e329 = s_3;
    param_59 = ((_e326 - _e327) / _e329);
    let _e331 = mx_square_u0028_f1_u003b((&param_59));
    let _e334 = s_3;
    let _e337 = o;
    return ((exp((-0.5f * _e331)) / (_e334 * 2.5066283f)) + _e337);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_3: ptr<function, f32>) -> f32 {
    let _e280 = (*cosTheta_3);
    return (max(_e280, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_5: ptr<function, f32>, y_1: ptr<function, f32>) -> f32 {
    let _e281 = (*x_5);
    let _e284 = (*y_1);
    let _e287 = (*y_1);
    let _e289 = (*y_1);
    let _e291 = (*y_1);
    let _e293 = (*x_5);
    let _e296 = (*x_5);
    let _e298 = (*y_1);
    let _e301 = (*y_1);
    let _e303 = (*y_1);
    return (((((sqrt((1f - _e281)) * (_e284 - 1f)) * _e287) * _e289) * _e291) / (((0.0000254053f + (1.71228f * _e293)) - ((1.71506f * _e296) * _e298)) + ((1.34174f * _e301) * _e303)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    let _e281 = (*x_6);
    let _e283 = (*y_2);
    let _e286 = (*y_2);
    let _e288 = (*x_6);
    let _e290 = (*x_6);
    let _e293 = (*x_6);
    let _e295 = (*y_2);
    return ((((2.58126f * _e281) + (0.813703f * _e283)) * _e286) / ((1f + ((0.310327f * _e288) * _e290)) + ((2.60994f * _e293) * _e295)));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_2: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e281 = (*m_2);
    let _e282 = (*v_1);
    return (_e281 * _e282);
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_8: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_1: f32;
    var b: f32;
    var X: vec3<f32>;
    var Y: vec3<f32>;

    let _e286 = (*N_8)[2u];
    sign_ = select(1f, -1f, (_e286 < 0f));
    let _e289 = sign_;
    let _e291 = (*N_8)[2u];
    a_1 = (-1f / (_e289 + _e291));
    let _e295 = (*N_8)[0u];
    let _e297 = (*N_8)[1u];
    let _e299 = a_1;
    b = ((_e295 * _e297) * _e299);
    let _e301 = sign_;
    let _e303 = (*N_8)[0u];
    let _e306 = (*N_8)[0u];
    let _e308 = a_1;
    let _e311 = sign_;
    let _e312 = b;
    let _e314 = sign_;
    let _e317 = (*N_8)[0u];
    X = vec3<f32>((1f + (((_e301 * _e303) * _e306) * _e308)), (_e311 * _e312), (-(_e314) * _e317));
    let _e320 = b;
    let _e321 = sign_;
    let _e323 = (*N_8)[1u];
    let _e325 = (*N_8)[1u];
    let _e327 = a_1;
    let _e331 = (*N_8)[1u];
    Y = vec3<f32>(_e320, (_e321 + ((_e323 * _e325) * _e327)), -(_e331));
    let _e334 = X;
    let _e335 = Y;
    let _e336 = (*N_8);
    return mat3x3<f32>(vec3<f32>(_e334.x, _e334.y, _e334.z), vec3<f32>(_e335.x, _e335.y, _e335.z), vec3<f32>(_e336.x, _e336.y, _e336.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_4: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_6: ptr<function, f32>) -> mat3x3<f32> {
    var X_1: vec3<f32>;
    var lenSqr: f32;
    var Y_1: vec3<f32>;
    var param_60: vec3<f32>;

    let _e286 = (*V_4);
    let _e287 = (*N_9);
    let _e288 = (*NdotV_6);
    X_1 = (_e286 - (_e287 * _e288));
    let _e291 = X_1;
    let _e292 = X_1;
    lenSqr = dot(_e291, _e292);
    let _e294 = lenSqr;
    if (_e294 > 0f) {
        let _e296 = lenSqr;
        let _e298 = X_1;
        X_1 = (_e298 * inverseSqrt(_e296));
        let _e300 = (*N_9);
        let _e301 = X_1;
        Y_1 = cross(_e300, _e301);
        let _e303 = X_1;
        let _e304 = Y_1;
        let _e305 = (*N_9);
        return mat3x3<f32>(vec3<f32>(_e303.x, _e303.y, _e303.z), vec3<f32>(_e304.x, _e304.y, _e304.z), vec3<f32>(_e305.x, _e305.y, _e305.z));
    }
    let _e319 = (*N_9);
    param_60 = _e319;
    let _e320 = mx_orthonormal_basis_u0028_vf3_u003b((&param_60));
    return _e320;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_5: ptr<function, vec3<f32>>, V_5: ptr<function, vec3<f32>>, N_10: ptr<function, vec3<f32>>, NdotV_7: ptr<function, f32>, roughness_8: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_61: vec3<f32>;
    var param_62: vec3<f32>;
    var param_63: f32;
    var w: vec3<f32>;
    var param_64: mat3x3<f32>;
    var param_65: vec3<f32>;
    var aInv: f32;
    var param_66: f32;
    var param_67: f32;
    var bInv: f32;
    var param_68: f32;
    var param_69: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_70: f32;
    var param_71: f32;

    let _e301 = (*V_5);
    param_61 = _e301;
    let _e302 = (*N_10);
    param_62 = _e302;
    let _e303 = (*NdotV_7);
    param_63 = _e303;
    let _e304 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_61), (&param_62), (&param_63));
    toLTC = transpose(_e304);
    let _e306 = toLTC;
    param_64 = _e306;
    let _e307 = (*L_5);
    param_65 = _e307;
    let _e308 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_64), (&param_65));
    w = _e308;
    let _e309 = (*NdotV_7);
    param_66 = _e309;
    let _e310 = (*roughness_8);
    param_67 = _e310;
    let _e311 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_66), (&param_67));
    aInv = _e311;
    let _e312 = (*NdotV_7);
    param_68 = _e312;
    let _e313 = (*roughness_8);
    param_69 = _e313;
    let _e314 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_68), (&param_69));
    bInv = _e314;
    let _e315 = aInv;
    let _e317 = w[0u];
    let _e319 = bInv;
    let _e321 = w[2u];
    let _e324 = aInv;
    let _e326 = w[1u];
    let _e329 = w[2u];
    wo = vec3<f32>(((_e315 * _e317) + (_e319 * _e321)), (_e324 * _e326), _e329);
    let _e331 = wo;
    let _e332 = wo;
    lenSqr_1 = dot(_e331, _e332);
    let _e335 = wo[2u];
    param_70 = _e335;
    let _e336 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_70));
    let _e337 = aInv;
    let _e338 = lenSqr_1;
    param_71 = (_e337 / _e338);
    let _e340 = mx_square_u0028_f1_u003b((&param_71));
    return (_e336 * _e340);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_8: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var r_1: vec2<f32>;
    var param_72: f32;
    var param_73: f32;

    let _e284 = (*NdotV_8);
    let _e287 = (*roughness_9);
    let _e290 = (*NdotV_8);
    let _e292 = (*roughness_9);
    let _e295 = (*NdotV_8);
    param_72 = _e295;
    let _e296 = mx_square_u0028_f1_u003b((&param_72));
    let _e299 = (*roughness_9);
    param_73 = _e299;
    let _e300 = mx_square_u0028_f1_u003b((&param_73));
    r_1 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e284)) + (vec2<f32>(799.08826f, 442.7821f) * _e287)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e290) * _e292)) + (vec2<f32>(60.28956f, 121.81241f) * _e296)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e300));
    let _e304 = r_1[0u];
    let _e306 = r_1[1u];
    return (_e304 / _e306);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_9: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var dirAlbedo_2: f32;
    var param_74: f32;
    var param_75: f32;

    let _e284 = (*NdotV_9);
    param_74 = _e284;
    let _e285 = (*roughness_10);
    param_75 = _e285;
    let _e286 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_74), (&param_75));
    dirAlbedo_2 = _e286;
    let _e287 = dirAlbedo_2;
    return clamp(_e287, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e284 = (*roughness_11);
    invRoughness = (1f / max(_e284, 0.005f));
    let _e287 = (*NdotH);
    let _e288 = (*NdotH);
    cos2_ = (_e287 * _e288);
    let _e290 = cos2_;
    sin2_ = (1f - _e290);
    let _e292 = invRoughness;
    let _e294 = sin2_;
    let _e295 = invRoughness;
    return (((2f + _e292) * pow(_e294, (_e295 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_10: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var D: f32;
    var param_76: f32;
    var param_77: f32;
    var F: f32;
    var G_1: f32;

    let _e288 = (*NdotH_1);
    param_76 = _e288;
    let _e289 = (*roughness_12);
    param_77 = _e289;
    let _e290 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_76), (&param_77));
    D = _e290;
    F = 1f;
    G_1 = 1f;
    let _e291 = D;
    let _e292 = F;
    let _e294 = G_1;
    let _e296 = (*NdotL_5);
    let _e297 = (*NdotV_10);
    let _e299 = (*NdotL_5);
    let _e300 = (*NdotV_10);
    return (((_e291 * _e292) * _e294) / (4f * ((_e296 + _e297) - (_e299 * _e300))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_11: ptr<function, ClosureData>, weight_4: ptr<function, f32>, color_6: ptr<function, vec3<f32>>, roughness_13: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_6: vec3<f32>;
    var L_6: vec3<f32>;
    var param_78: vec3<f32>;
    var param_79: vec3<f32>;
    var NdotV_11: f32;
    var H: vec3<f32>;
    var NdotL_6: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_80: f32;
    var param_81: f32;
    var param_82: f32;
    var param_83: f32;
    var dirAlbedo_3: f32;
    var param_84: f32;
    var param_85: f32;
    var fr_1: vec3<f32>;
    var param_86: vec3<f32>;
    var param_87: vec3<f32>;
    var param_88: vec3<f32>;
    var param_89: f32;
    var param_90: f32;
    var param_91: f32;
    var param_92: f32;
    var dirAlbedo_4: f32;
    var param_93: f32;
    var param_94: f32;
    var param_95: f32;
    var param_96: f32;
    var Li_4: vec3<f32>;
    var param_97: vec3<f32>;

    let _e317 = (*weight_4);
    if (_e317 < 0.00000001f) {
        return;
    }
    let _e320 = (*closureData_11).V;
    V_6 = _e320;
    let _e322 = (*closureData_11).L;
    L_6 = _e322;
    let _e323 = (*N_11);
    param_78 = _e323;
    let _e324 = V_6;
    param_79 = _e324;
    let _e325 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_78), (&param_79));
    (*N_11) = _e325;
    let _e326 = (*N_11);
    let _e327 = V_6;
    NdotV_11 = clamp(dot(_e326, _e327), 0.00000001f, 1f);
    let _e331 = (*closureData_11).closureType;
    if (_e331 == 1i) {
        let _e333 = (*mode);
        if (_e333 == 0i) {
            let _e335 = L_6;
            let _e336 = V_6;
            H = normalize((_e335 + _e336));
            let _e339 = (*N_11);
            let _e340 = L_6;
            NdotL_6 = clamp(dot(_e339, _e340), 0.00000001f, 1f);
            let _e343 = (*N_11);
            let _e344 = H;
            NdotH_2 = clamp(dot(_e343, _e344), 0.00000001f, 1f);
            let _e347 = (*color_6);
            let _e348 = NdotL_6;
            param_80 = _e348;
            let _e349 = NdotV_11;
            param_81 = _e349;
            let _e350 = NdotH_2;
            param_82 = _e350;
            let _e351 = (*roughness_13);
            param_83 = _e351;
            let _e352 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_80), (&param_81), (&param_82), (&param_83));
            fr = (_e347 * _e352);
            let _e354 = NdotV_11;
            param_84 = _e354;
            let _e355 = (*roughness_13);
            param_85 = _e355;
            let _e356 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
            dirAlbedo_3 = _e356;
            let _e357 = fr;
            let _e358 = NdotL_6;
            let _e361 = (*closureData_11).occlusion;
            let _e363 = (*weight_4);
            (*bsdf_3).response = (((_e357 * _e358) * _e361) * _e363);
        } else {
            let _e366 = (*roughness_13);
            (*roughness_13) = clamp(_e366, 0.01f, 1f);
            let _e368 = (*color_6);
            let _e369 = L_6;
            param_86 = _e369;
            let _e370 = V_6;
            param_87 = _e370;
            let _e371 = (*N_11);
            param_88 = _e371;
            let _e372 = NdotV_11;
            param_89 = _e372;
            let _e373 = (*roughness_13);
            param_90 = _e373;
            let _e374 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_86), (&param_87), (&param_88), (&param_89), (&param_90));
            fr_1 = (_e368 * _e374);
            let _e376 = NdotV_11;
            param_91 = _e376;
            let _e377 = (*roughness_13);
            param_92 = _e377;
            let _e378 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_91), (&param_92));
            dirAlbedo_3 = _e378;
            let _e379 = dirAlbedo_3;
            let _e380 = fr_1;
            let _e383 = (*closureData_11).occlusion;
            let _e385 = (*weight_4);
            (*bsdf_3).response = (((_e380 * _e379) * _e383) * _e385);
        }
        let _e388 = dirAlbedo_3;
        let _e389 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e388 * _e389)));
    } else {
        let _e395 = (*closureData_11).closureType;
        if (_e395 == 3i) {
            let _e397 = (*mode);
            if (_e397 == 0i) {
                let _e399 = NdotV_11;
                param_93 = _e399;
                let _e400 = (*roughness_13);
                param_94 = _e400;
                let _e401 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_93), (&param_94));
                dirAlbedo_4 = _e401;
            } else {
                let _e402 = (*roughness_13);
                (*roughness_13) = clamp(_e402, 0.01f, 1f);
                let _e404 = NdotV_11;
                param_95 = _e404;
                let _e405 = (*roughness_13);
                param_96 = _e405;
                let _e406 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_95), (&param_96));
                dirAlbedo_4 = _e406;
            }
            let _e407 = (*N_11);
            param_97 = _e407;
            let _e408 = mx_environment_irradiance_u0028_vf3_u003b((&param_97));
            Li_4 = _e408;
            let _e409 = Li_4;
            let _e410 = (*color_6);
            let _e412 = dirAlbedo_4;
            let _e414 = (*weight_4);
            (*bsdf_3).response = (((_e409 * _e410) * _e412) * _e414);
            let _e417 = dirAlbedo_4;
            let _e418 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e417 * _e418)));
        }
    }
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_7: ptr<function, f32>, NdotV_12: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_98: f32;
    var lambdaL: f32;
    var param_99: f32;
    var lambdaV: f32;
    var param_100: f32;

    let _e288 = (*alpha);
    param_98 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_98));
    alpha2_ = _e289;
    let _e290 = alpha2_;
    let _e291 = alpha2_;
    let _e293 = (*NdotL_7);
    param_99 = _e293;
    let _e294 = mx_square_u0028_f1_u003b((&param_99));
    lambdaL = sqrt((_e290 + ((1f - _e291) * _e294)));
    let _e298 = alpha2_;
    let _e299 = alpha2_;
    let _e301 = (*NdotV_12);
    param_100 = _e301;
    let _e302 = mx_square_u0028_f1_u003b((&param_100));
    lambdaV = sqrt((_e298 + ((1f - _e299) * _e302)));
    let _e306 = (*NdotL_7);
    let _e308 = (*NdotV_12);
    let _e310 = lambdaL;
    let _e311 = (*NdotV_12);
    let _e313 = lambdaV;
    let _e314 = (*NdotL_7);
    return (((2f * _e306) * _e308) / ((_e310 * _e311) + (_e313 * _e314)));
}

fn mx_pow6_u0028_f1_u003b(x_7: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_101: f32;
    var param_102: f32;

    let _e283 = (*x_7);
    param_101 = _e283;
    let _e284 = mx_square_u0028_f1_u003b((&param_101));
    x2_ = _e284;
    let _e285 = x2_;
    param_102 = _e285;
    let _e286 = mx_square_u0028_f1_u003b((&param_102));
    let _e287 = x2_;
    return (_e286 * _e287);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_4: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_8: f32;
    var a_2: vec3<f32>;
    var param_103: f32;

    let _e284 = (*cosTheta_4);
    x_8 = clamp(_e284, 0f, 1f);
    let _e287 = (*fd).F0_;
    let _e289 = (*fd).F90_;
    let _e291 = (*fd).exponent;
    let _e296 = (*fd).F82_;
    a_2 = ((mix(_e287, _e289, vec3(pow(0.85714287f, _e291))) * (vec3<f32>(1f, 1f, 1f) - _e296)) * 17.651384f);
    let _e301 = (*fd).F0_;
    let _e303 = (*fd).F90_;
    let _e304 = x_8;
    let _e307 = (*fd).exponent;
    let _e311 = a_2;
    let _e312 = x_8;
    let _e314 = x_8;
    param_103 = (1f - _e314);
    let _e316 = mx_pow6_u0028_f1_u003b((&param_103));
    return (mix(_e301, _e303, vec3(pow((1f - _e304), _e307))) - ((_e311 * _e312) * _e316));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_5: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_104: f32;
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

    let _e296 = (*cosTheta_5);
    param_104 = clamp(_e296, 0f, 1f);
    let _e298 = mx_square_u0028_f1_u003b((&param_104));
    cosTheta2_ = _e298;
    let _e299 = cosTheta2_;
    sinTheta2_ = (1f - _e299);
    let _e301 = (*n);
    let _e302 = (*n);
    n2_ = (_e301 * _e302);
    let _e304 = (*k);
    let _e305 = (*k);
    k2_ = (_e304 * _e305);
    let _e307 = n2_;
    let _e308 = k2_;
    let _e310 = sinTheta2_;
    t0_ = ((_e307 - _e308) - vec3(_e310));
    let _e313 = t0_;
    let _e314 = t0_;
    let _e316 = n2_;
    let _e318 = k2_;
    a2plusb2_ = sqrt(((_e313 * _e314) + ((_e316 * 4f) * _e318)));
    let _e322 = a2plusb2_;
    let _e323 = cosTheta2_;
    t1_ = (_e322 + vec3(_e323));
    let _e326 = a2plusb2_;
    let _e327 = t0_;
    a_3 = sqrt(max(((_e326 + _e327) * 0.5f), vec3(0f)));
    let _e333 = a_3;
    let _e335 = (*cosTheta_5);
    t2_ = ((_e333 * 2f) * _e335);
    let _e337 = t1_;
    let _e338 = t2_;
    let _e340 = t1_;
    let _e341 = t2_;
    (*Rs) = ((_e337 - _e338) / (_e340 + _e341));
    let _e344 = cosTheta2_;
    let _e345 = a2plusb2_;
    let _e347 = sinTheta2_;
    let _e348 = sinTheta2_;
    t3_ = ((_e345 * _e344) + vec3((_e347 * _e348)));
    let _e352 = t2_;
    let _e353 = sinTheta2_;
    t4_ = (_e352 * _e353);
    let _e355 = (*Rs);
    let _e356 = t3_;
    let _e357 = t4_;
    let _e360 = t3_;
    let _e361 = t4_;
    (*Rp) = ((_e355 * (_e356 - _e357)) / (_e360 + _e361));
    return;
}

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_6: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_105: f32;
    var param_106: vec3<f32>;
    var param_107: vec3<f32>;
    var param_108: vec3<f32>;
    var param_109: vec3<f32>;

    let _e289 = (*cosTheta_6);
    param_105 = _e289;
    let _e290 = (*n_1);
    param_106 = _e290;
    let _e291 = (*k_1);
    param_107 = _e291;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_105), (&param_106), (&param_107), (&param_108), (&param_109));
    let _e292 = param_108;
    Rp_1 = _e292;
    let _e293 = param_109;
    Rs_1 = _e293;
    let _e294 = Rp_1;
    let _e295 = Rs_1;
    return ((_e294 + _e295) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_110: f32;
    var param_111: f32;

    let _e286 = (*cosTheta_7);
    c_1 = _e286;
    let _e287 = (*ior);
    let _e288 = (*ior);
    let _e290 = c_1;
    let _e291 = c_1;
    g2_ = (((_e287 * _e288) + (_e290 * _e291)) - 1f);
    let _e295 = g2_;
    if (_e295 < 0f) {
        return 1f;
    }
    let _e297 = g2_;
    g = sqrt(_e297);
    let _e299 = g;
    let _e300 = c_1;
    let _e302 = g;
    let _e303 = c_1;
    param_110 = ((_e299 - _e300) / (_e302 + _e303));
    let _e306 = mx_square_u0028_f1_u003b((&param_110));
    let _e308 = g;
    let _e309 = c_1;
    let _e311 = c_1;
    let _e314 = g;
    let _e315 = c_1;
    let _e317 = c_1;
    param_111 = ((((_e308 + _e309) * _e311) - 1f) / (((_e314 - _e315) * _e317) + 1f));
    let _e321 = mx_square_u0028_f1_u003b((&param_111));
    return ((0.5f * _e306) * (1f + _e321));
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e286 = (*opd);
    phase = (6.2831855f * _e286);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e288 = val;
    let _e289 = var_;
    let _e293 = pos;
    let _e294 = phase;
    let _e296 = (*shift);
    let _e300 = var_;
    let _e302 = phase;
    let _e304 = phase;
    xyz = (((_e288 * sqrt((_e289 * 6.2831855f))) * cos(((_e293 * _e294) + _e296))) * exp(((-(_e300) * _e302) * _e304)));
    let _e308 = phase;
    let _e311 = (*shift)[0u];
    let _e315 = phase;
    let _e317 = phase;
    let _e322 = xyz[0u];
    xyz[0u] = (_e322 + ((0.00000001644083f * cos(((2239900f * _e308) + _e311))) * exp(((-4528200000f * _e315) * _e317))));
    let _e325 = xyz;
    return (_e325 / vec3(0.00000010685f));
}

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_8: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_112: vec3<f32>;
    var U: vec3<f32>;
    var V_7: vec3<f32>;
    var param_113: f32;
    var param_114: vec3<f32>;

    let _e294 = (*kappa2_);
    let _e295 = (*eta2_);
    k2_1 = (_e294 / _e295);
    let _e297 = (*cosTheta_8);
    let _e298 = (*cosTheta_8);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e297 * _e298)));
    let _e302 = (*eta2_);
    let _e303 = (*eta2_);
    let _e305 = k2_1;
    let _e306 = k2_1;
    let _e310 = (*eta1_);
    let _e311 = (*eta1_);
    let _e313 = sinThetaSqr;
    A_4 = (((_e302 * _e303) * (vec3<f32>(1f, 1f, 1f) - (_e305 * _e306))) - (_e313 * (_e310 * _e311)));
    let _e316 = A_4;
    let _e317 = A_4;
    let _e319 = (*eta2_);
    let _e321 = (*eta2_);
    let _e323 = k2_1;
    param_112 = (((_e319 * 2f) * _e321) * _e323);
    let _e325 = mx_square_u0028_vf3_u003b((&param_112));
    B_2 = sqrt(((_e316 * _e317) + _e325));
    let _e328 = A_4;
    let _e329 = B_2;
    U = sqrt(((_e328 + _e329) / vec3(2f)));
    let _e334 = B_2;
    let _e335 = A_4;
    V_7 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e334 - _e335) / vec3(2f))));
    let _e341 = (*eta1_);
    let _e343 = V_7;
    let _e345 = (*cosTheta_8);
    let _e347 = U;
    let _e348 = U;
    let _e350 = V_7;
    let _e351 = V_7;
    let _e354 = (*eta1_);
    let _e355 = (*cosTheta_8);
    param_113 = (_e354 * _e355);
    let _e357 = mx_square_u0028_f1_u003b((&param_113));
    (*phiS) = atan2(((_e343 * (2f * _e341)) * _e345), (((_e347 * _e348) + (_e350 * _e351)) - vec3(_e357)));
    let _e361 = (*eta1_);
    let _e363 = (*eta2_);
    let _e365 = (*eta2_);
    let _e367 = (*cosTheta_8);
    let _e369 = k2_1;
    let _e371 = U;
    let _e373 = k2_1;
    let _e374 = k2_1;
    let _e377 = V_7;
    let _e381 = (*eta2_);
    let _e382 = (*eta2_);
    let _e384 = k2_1;
    let _e385 = k2_1;
    let _e389 = (*cosTheta_8);
    param_114 = (((_e381 * _e382) * (vec3<f32>(1f, 1f, 1f) + (_e384 * _e385))) * _e389);
    let _e391 = mx_square_u0028_vf3_u003b((&param_114));
    let _e392 = (*eta1_);
    let _e393 = (*eta1_);
    let _e395 = U;
    let _e396 = U;
    let _e398 = V_7;
    let _e399 = V_7;
    (*phiP) = atan2(((((_e363 * (2f * _e361)) * _e365) * _e367) * (((_e369 * 2f) * _e371) - ((vec3<f32>(1f, 1f, 1f) - (_e373 * _e374)) * _e377))), (_e391 - (((_e395 * _e396) + (_e398 * _e399)) * (_e392 * _e393))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_9: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_115: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e291 = (*cosTheta_9);
    param_115 = clamp(_e291, 0f, 1f);
    let _e293 = mx_square_u0028_f1_u003b((&param_115));
    cosTheta2_1 = _e293;
    let _e294 = cosTheta2_1;
    sinTheta2_1 = (1f - _e294);
    let _e296 = (*ior_1);
    let _e297 = (*ior_1);
    let _e299 = sinTheta2_1;
    t0_1 = max(((_e296 * _e297) - _e299), 0f);
    let _e302 = t0_1;
    let _e303 = cosTheta2_1;
    t1_1 = (_e302 + _e303);
    let _e305 = t0_1;
    let _e308 = (*cosTheta_9);
    t2_1 = ((2f * sqrt(_e305)) * _e308);
    let _e310 = t1_1;
    let _e311 = t2_1;
    let _e313 = t1_1;
    let _e314 = t2_1;
    Rs_2 = ((_e310 - _e311) / (_e313 + _e314));
    let _e317 = cosTheta2_1;
    let _e318 = t0_1;
    let _e320 = sinTheta2_1;
    let _e321 = sinTheta2_1;
    t3_1 = ((_e317 * _e318) + (_e320 * _e321));
    let _e324 = t2_1;
    let _e325 = sinTheta2_1;
    t4_1 = (_e324 * _e325);
    let _e327 = Rs_2;
    let _e328 = t3_1;
    let _e329 = t4_1;
    let _e332 = t3_1;
    let _e333 = t4_1;
    Rp_2 = ((_e327 * (_e328 - _e329)) / (_e332 + _e333));
    let _e336 = Rp_2;
    let _e337 = Rs_2;
    return vec2<f32>(_e336, _e337);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e281 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e281, vec3(0.01f), vec3(0.99f)));
    let _e286 = sqrtF0_;
    let _e288 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e286) / (vec3<f32>(1f, 1f, 1f) - _e288));
}

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_10: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_116: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_117: f32;
    var param_118: f32;
    var R12_: vec2<f32>;
    var param_119: f32;
    var param_120: f32;
    var T121_: vec2<f32>;
    var f_1: vec3<f32>;
    var param_121: f32;
    var param_122: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_123: f32;
    var param_124: vec3<f32>;
    var param_125: vec3<f32>;
    var param_126: vec3<f32>;
    var param_127: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_128: f32;
    var param_129: f32;
    var param_130: vec3<f32>;
    var param_131: vec3<f32>;
    var param_132: vec3<f32>;
    var param_133: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_134: f32;
    var Cm: vec3<f32>;
    var m_3: i32;
    var Sm: vec3<f32>;
    var param_135: f32;
    var param_136: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_137: f32;
    var m_4: i32;
    var param_138: f32;
    var param_139: vec3<f32>;
    var param_140: mat3x3<f32>;
    var param_141: vec3<f32>;

    eta1_1 = 1f;
    let _e335 = (*fd_1).tf_ior;
    let _e336 = eta1_1;
    eta2_1 = max(_e335, _e336);
    let _e339 = (*fd_1).model;
    if (_e339 == 2i) {
        let _e342 = (*fd_1).F0_;
        param_116 = _e342;
        let _e343 = mx_f0_to_ior_u0028_vf3_u003b((&param_116));
        local_5 = _e343;
    } else {
        let _e345 = (*fd_1).ior;
        local_5 = _e345;
    }
    let _e346 = local_5;
    eta3_ = _e346;
    let _e348 = (*fd_1).model;
    if (_e348 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e351 = (*fd_1).extinction;
        local_6 = _e351;
    }
    let _e352 = local_6;
    kappa3_ = _e352;
    let _e353 = (*cosTheta_10);
    param_117 = _e353;
    let _e354 = mx_square_u0028_f1_u003b((&param_117));
    let _e356 = eta1_1;
    let _e357 = eta2_1;
    param_118 = (_e356 / _e357);
    let _e359 = mx_square_u0028_f1_u003b((&param_118));
    cosThetaT = sqrt((1f - ((1f - _e354) * _e359)));
    let _e363 = eta2_1;
    let _e364 = eta1_1;
    let _e366 = (*cosTheta_10);
    param_119 = _e366;
    param_120 = (_e363 / _e364);
    let _e367 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_119), (&param_120));
    R12_ = _e367;
    let _e368 = cosThetaT;
    if (_e368 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e370 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e370);
    let _e373 = (*fd_1).model;
    if (_e373 == 2i) {
        let _e375 = cosThetaT;
        param_121 = _e375;
        let _e376 = (*fd_1);
        param_122 = _e376;
        let _e377 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_121), (&param_122));
        f_1 = _e377;
        let _e378 = f_1;
        R23p = (_e378 * 0.5f);
        let _e380 = f_1;
        R23s = (_e380 * 0.5f);
    } else {
        let _e382 = eta3_;
        let _e383 = eta2_1;
        let _e386 = kappa3_;
        let _e387 = eta2_1;
        let _e390 = cosThetaT;
        param_123 = _e390;
        param_124 = (_e382 / vec3(_e383));
        param_125 = (_e386 / vec3(_e387));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_123), (&param_124), (&param_125), (&param_126), (&param_127));
        let _e391 = param_126;
        R23p = _e391;
        let _e392 = param_127;
        R23s = _e392;
    }
    let _e393 = eta2_1;
    let _e394 = eta1_1;
    cosB = cos(atan((_e393 / _e394)));
    let _e398 = (*cosTheta_10);
    let _e399 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e398 < _e399)), 3.1415927f);
    let _e404 = (*fd_1).model;
    if (_e404 == 2i) {
        let _e407 = eta3_[0u];
        let _e408 = eta2_1;
        let _e412 = eta3_[1u];
        let _e413 = eta2_1;
        let _e417 = eta3_[2u];
        let _e418 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e407 < _e408)), select(0f, 3.1415927f, (_e412 < _e413)), select(0f, 3.1415927f, (_e417 < _e418)));
        let _e422 = phi23p;
        phi23s = _e422;
    } else {
        let _e423 = cosThetaT;
        param_128 = _e423;
        let _e424 = eta2_1;
        param_129 = _e424;
        let _e425 = eta3_;
        param_130 = _e425;
        let _e426 = kappa3_;
        param_131 = _e426;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_128), (&param_129), (&param_130), (&param_131), (&param_132), (&param_133));
        let _e427 = param_132;
        phi23p = _e427;
        let _e428 = param_133;
        phi23s = _e428;
    }
    let _e430 = R12_[0u];
    let _e431 = R23p;
    r123p = max(sqrt((_e431 * _e430)), vec3(0f));
    let _e437 = R12_[1u];
    let _e438 = R23s;
    r123s = max(sqrt((_e438 * _e437)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e444 = (*fd_1).tf_thickness;
    distMeters = (_e444 * 0.000000001f);
    let _e446 = eta2_1;
    let _e448 = cosThetaT;
    let _e450 = distMeters;
    opd_1 = (((2f * _e446) * _e448) * _e450);
    let _e453 = T121_[0u];
    param_134 = _e453;
    let _e454 = mx_square_u0028_f1_u003b((&param_134));
    let _e455 = R23p;
    let _e458 = R12_[0u];
    let _e459 = R23p;
    Rs_3 = ((_e455 * _e454) / (vec3<f32>(1f, 1f, 1f) - (_e459 * _e458)));
    let _e464 = R12_[0u];
    let _e465 = Rs_3;
    let _e468 = I;
    I = (_e468 + (vec3(_e464) + _e465));
    let _e470 = Rs_3;
    let _e472 = T121_[0u];
    Cm = (_e470 - vec3(_e472));
    m_3 = 1i;
    loop {
        let _e475 = m_3;
        if (_e475 <= 2i) {
            let _e477 = r123p;
            let _e478 = Cm;
            Cm = (_e478 * _e477);
            let _e480 = m_3;
            let _e482 = opd_1;
            let _e484 = m_3;
            let _e486 = phi23p;
            let _e488 = phi21_[0u];
            param_135 = (f32(_e480) * _e482);
            param_136 = ((_e486 + vec3(_e488)) * f32(_e484));
            let _e492 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_135), (&param_136));
            Sm = (_e492 * 2f);
            let _e494 = Cm;
            let _e495 = Sm;
            let _e497 = I;
            I = (_e497 + (_e494 * _e495));
            continue;
        } else {
            break;
        }
        continuing {
            let _e499 = m_3;
            m_3 = (_e499 + 1i);
        }
    }
    let _e502 = T121_[1u];
    param_137 = _e502;
    let _e503 = mx_square_u0028_f1_u003b((&param_137));
    let _e504 = R23s;
    let _e507 = R12_[1u];
    let _e508 = R23s;
    Rp_3 = ((_e504 * _e503) / (vec3<f32>(1f, 1f, 1f) - (_e508 * _e507)));
    let _e513 = R12_[1u];
    let _e514 = Rp_3;
    let _e517 = I;
    I = (_e517 + (vec3(_e513) + _e514));
    let _e519 = Rp_3;
    let _e521 = T121_[1u];
    Cm = (_e519 - vec3(_e521));
    m_4 = 1i;
    loop {
        let _e524 = m_4;
        if (_e524 <= 2i) {
            let _e526 = r123s;
            let _e527 = Cm;
            Cm = (_e527 * _e526);
            let _e529 = m_4;
            let _e531 = opd_1;
            let _e533 = m_4;
            let _e535 = phi23s;
            let _e537 = phi21_[1u];
            param_138 = (f32(_e529) * _e531);
            param_139 = ((_e535 + vec3(_e537)) * f32(_e533));
            let _e541 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_138), (&param_139));
            Sm = (_e541 * 2f);
            let _e543 = Cm;
            let _e544 = Sm;
            let _e546 = I;
            I = (_e546 + (_e543 * _e544));
            continue;
        } else {
            break;
        }
        continuing {
            let _e548 = m_4;
            m_4 = (_e548 + 1i);
        }
    }
    let _e550 = I;
    I = (_e550 * 0.5f);
    param_140 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e552 = I;
    param_141 = _e552;
    let _e553 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_140), (&param_141));
    I = clamp(_e553, vec3(0f), vec3(1f));
    let _e557 = I;
    return _e557;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_11: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_142: f32;
    var param_143: FresnelData;
    var param_144: f32;
    var param_145: f32;
    var param_146: f32;
    var param_147: vec3<f32>;
    var param_148: vec3<f32>;
    var param_149: f32;
    var param_150: FresnelData;

    let _e291 = (*fd_2).airy;
    if _e291 {
        let _e292 = (*cosTheta_11);
        param_142 = _e292;
        let _e293 = (*fd_2);
        param_143 = _e293;
        let _e294 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_142), (&param_143));
        return _e294;
    } else {
        let _e296 = (*fd_2).model;
        if (_e296 == 0i) {
            let _e298 = (*cosTheta_11);
            param_144 = _e298;
            let _e301 = (*fd_2).ior[0u];
            param_145 = _e301;
            let _e302 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_144), (&param_145));
            return vec3(_e302);
        } else {
            let _e305 = (*fd_2).model;
            if (_e305 == 1i) {
                let _e307 = (*cosTheta_11);
                param_146 = _e307;
                let _e309 = (*fd_2).ior;
                param_147 = _e309;
                let _e311 = (*fd_2).extinction;
                param_148 = _e311;
                let _e312 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_146), (&param_147), (&param_148));
                return _e312;
            } else {
                let _e313 = (*cosTheta_11);
                param_149 = _e313;
                let _e314 = (*fd_2);
                param_150 = _e314;
                let _e315 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_149), (&param_150));
                return _e315;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_151: mat4x4<f32>;
    var param_152: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_153: vec3<f32>;

    let _e287 = (*dir_2);
    let _e292 = (*transform_1);
    param_151 = _e292;
    param_152 = vec4<f32>(_e287.x, _e287.y, _e287.z, 0f);
    let _e293 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_151), (&param_152));
    envDir_1 = normalize(_e293.xyz);
    let _e296 = envDir_1;
    param_153 = _e296;
    let _e297 = mx_latlong_projection_u0028_vf3_u003b((&param_153));
    uv_2 = _e297;
    let _e298 = uv_2;
    let _e299 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e298, 0.0);
    return _e299.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_154: f32;

    let _e286 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e286 - 1.5f);
    let _e289 = (*dir_3)[1u];
    param_154 = _e289;
    let _e290 = mx_square_u0028_f1_u003b((&param_154));
    distortion = sqrt((1f - _e290));
    let _e293 = effectiveMaxMipLevel;
    let _e294 = (*envSamples);
    let _e296 = (*pdf);
    let _e298 = distortion;
    return max((_e293 - (0.5f * log2(((f32(_e294) * _e296) * _e298)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H_1: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_155: f32;
    var param_156: f32;

    let _e285 = (*H_1);
    let _e287 = (*alpha_1);
    He = (_e285.xy / _e287);
    let _e289 = He;
    let _e290 = He;
    let _e293 = (*H_1)[2u];
    param_155 = _e293;
    let _e294 = mx_square_u0028_f1_u003b((&param_155));
    denom_1 = (dot(_e289, _e290) + _e294);
    let _e297 = (*alpha_1)[0u];
    let _e300 = (*alpha_1)[1u];
    let _e302 = denom_1;
    param_156 = _e302;
    let _e303 = mx_square_u0028_f1_u003b((&param_156));
    return (1f / (((3.1415927f * _e297) * _e300) * _e303));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_2: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_13: ptr<function, f32>) -> f32 {
    var param_157: vec3<f32>;
    var param_158: vec2<f32>;

    let _e285 = (*H_2);
    param_157 = _e285;
    let _e286 = (*alpha_2);
    param_158 = _e286;
    let _e287 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_157), (&param_158));
    let _e288 = (*G1V);
    let _e290 = (*NdotV_13);
    return ((_e287 * _e288) / (4f * _e290));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e283 = (*R_1);
    let _e284 = (*N_12);
    let _e285 = (*ior_2);
    (*R_1) = refract(_e283, _e284, (1f / _e285));
    let _e288 = (*R_1);
    let _e289 = (*R_1);
    let _e290 = (*N_12);
    let _e293 = (*N_12);
    N1_ = normalize(((_e288 * dot(_e289, _e290)) - (_e293 * 0.5f)));
    let _e297 = (*R_1);
    let _e298 = N1_;
    let _e299 = (*ior_2);
    return refract(_e297, _e298, _e299);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_8: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_9: f32;
    var y_3: f32;
    var c_2: vec3<f32>;
    var H_3: vec3<f32>;

    let _e289 = (*V_8);
    let _e291 = (*alpha_3);
    let _e292 = (_e289.xy * _e291);
    let _e294 = (*V_8)[2u];
    (*V_8) = normalize(vec3<f32>(_e292.x, _e292.y, _e294));
    let _e300 = (*Xi)[0u];
    phi = (6.2831855f * _e300);
    let _e303 = (*Xi)[1u];
    let _e306 = (*V_8)[2u];
    let _e310 = (*V_8)[2u];
    z = (((1f - _e303) * (1f + _e306)) - _e310);
    let _e312 = z;
    let _e313 = z;
    sinTheta = sqrt(clamp((1f - (_e312 * _e313)), 0f, 1f));
    let _e318 = sinTheta;
    let _e319 = phi;
    x_9 = (_e318 * cos(_e319));
    let _e322 = sinTheta;
    let _e323 = phi;
    y_3 = (_e322 * sin(_e323));
    let _e326 = x_9;
    let _e327 = y_3;
    let _e328 = z;
    c_2 = vec3<f32>(_e326, _e327, _e328);
    let _e330 = c_2;
    let _e331 = (*V_8);
    H_3 = (_e330 + _e331);
    let _e333 = H_3;
    let _e335 = (*alpha_3);
    let _e336 = (_e333.xy * _e335);
    let _e338 = H_3[2u];
    H_3 = normalize(vec3<f32>(_e336.x, _e336.y, max(_e338, 0f)));
    let _e344 = H_3;
    return _e344;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e280 = (*i_1);
    return fract(((f32(_e280) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_159: i32;

    let _e282 = (*i_2);
    let _e285 = (*numSamples);
    let _e288 = (*i_2);
    param_159 = _e288;
    let _e289 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_159));
    return vec2<f32>(((f32(_e282) + 0.5f) / f32(_e285)), _e289);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_12: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_160: f32;
    var tanTheta2_: f32;
    var param_161: f32;

    let _e285 = (*cosTheta_12);
    param_160 = _e285;
    let _e286 = mx_square_u0028_f1_u003b((&param_160));
    cosTheta2_2 = _e286;
    let _e287 = cosTheta2_2;
    let _e289 = cosTheta2_2;
    tanTheta2_ = ((1f - _e287) / _e289);
    let _e291 = (*alpha_4);
    param_161 = _e291;
    let _e292 = mx_square_u0028_f1_u003b((&param_161));
    let _e293 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e292 * _e293)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e281 = (*alpha_5)[0u];
    let _e283 = (*alpha_5)[1u];
    return sqrt((_e281 * _e283));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_13: ptr<function, vec3<f32>>, V_9: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y_2: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_14: f32;
    var avgAlpha: f32;
    var param_162: vec2<f32>;
    var G1V_1: f32;
    var param_163: f32;
    var param_164: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_3: i32;
    var Xi_1: vec2<f32>;
    var param_165: i32;
    var param_166: i32;
    var H_4: vec3<f32>;
    var param_167: vec2<f32>;
    var param_168: vec3<f32>;
    var param_169: vec2<f32>;
    var L_7: vec3<f32>;
    var local_7: vec3<f32>;
    var param_170: vec3<f32>;
    var param_171: vec3<f32>;
    var param_172: f32;
    var NdotL_8: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_173: mat3x3<f32>;
    var param_174: vec3<f32>;
    var pdf_1: f32;
    var param_175: vec3<f32>;
    var param_176: vec2<f32>;
    var param_177: f32;
    var param_178: f32;
    var lod_2: f32;
    var param_179: vec3<f32>;
    var param_180: f32;
    var param_181: f32;
    var param_182: i32;
    var sampleColor: vec3<f32>;
    var param_183: vec3<f32>;
    var param_184: mat4x4<f32>;
    var param_185: f32;
    var F_1: vec3<f32>;
    var param_186: f32;
    var param_187: FresnelData;
    var G_2: f32;
    var param_188: f32;
    var param_189: f32;
    var param_190: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e336 = (*X_2);
    let _e337 = (*X_2);
    let _e338 = (*N_13);
    let _e340 = (*N_13);
    (*X_2) = normalize((_e336 - (_e340 * dot(_e337, _e338))));
    let _e344 = (*N_13);
    let _e345 = (*X_2);
    Y_2 = cross(_e344, _e345);
    let _e347 = (*X_2);
    let _e348 = Y_2;
    let _e349 = (*N_13);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e347.x, _e347.y, _e347.z), vec3<f32>(_e348.x, _e348.y, _e348.z), vec3<f32>(_e349.x, _e349.y, _e349.z));
    let _e363 = (*V_9);
    let _e364 = (*X_2);
    let _e366 = (*V_9);
    let _e367 = Y_2;
    let _e369 = (*V_9);
    let _e370 = (*N_13);
    (*V_9) = vec3<f32>(dot(_e363, _e364), dot(_e366, _e367), dot(_e369, _e370));
    let _e374 = (*V_9)[2u];
    NdotV_14 = clamp(_e374, 0.00000001f, 1f);
    let _e376 = (*alpha_6);
    param_162 = _e376;
    let _e377 = mx_average_alpha_u0028_vf2_u003b((&param_162));
    avgAlpha = _e377;
    let _e378 = NdotV_14;
    param_163 = _e378;
    let _e379 = avgAlpha;
    param_164 = _e379;
    let _e380 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_163), (&param_164));
    G1V_1 = _e380;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e381 = i_3;
        let _e382 = envRadianceSamples;
        if (_e381 < _e382) {
            let _e384 = i_3;
            param_165 = _e384;
            let _e385 = envRadianceSamples;
            param_166 = _e385;
            let _e386 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_165), (&param_166));
            Xi_1 = _e386;
            let _e387 = Xi_1;
            param_167 = _e387;
            let _e388 = (*V_9);
            param_168 = _e388;
            let _e389 = (*alpha_6);
            param_169 = _e389;
            let _e390 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_167), (&param_168), (&param_169));
            H_4 = _e390;
            let _e392 = (*fd_3).refraction;
            if _e392 {
                let _e393 = (*V_9);
                param_170 = -(_e393);
                let _e395 = H_4;
                param_171 = _e395;
                let _e398 = (*fd_3).ior[0u];
                param_172 = _e398;
                let _e399 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_170), (&param_171), (&param_172));
                local_7 = _e399;
            } else {
                let _e400 = (*V_9);
                let _e401 = H_4;
                local_7 = -(reflect(_e400, _e401));
            }
            let _e404 = local_7;
            L_7 = _e404;
            let _e406 = L_7[2u];
            NdotL_8 = clamp(_e406, 0.00000001f, 1f);
            let _e408 = (*V_9);
            let _e409 = H_4;
            VdotH = clamp(dot(_e408, _e409), 0.00000001f, 1f);
            let _e412 = tangentToWorld;
            param_173 = _e412;
            let _e413 = L_7;
            param_174 = _e413;
            let _e414 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_173), (&param_174));
            Lw = _e414;
            let _e415 = H_4;
            param_175 = _e415;
            let _e416 = (*alpha_6);
            param_176 = _e416;
            let _e417 = G1V_1;
            param_177 = _e417;
            let _e418 = NdotV_14;
            param_178 = _e418;
            let _e419 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_175), (&param_176), (&param_177), (&param_178));
            pdf_1 = _e419;
            let _e420 = Lw;
            param_179 = _e420;
            let _e421 = pdf_1;
            param_180 = _e421;
            param_181 = 0f;
            let _e422 = envRadianceSamples;
            param_182 = _e422;
            let _e423 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_179), (&param_180), (&param_181), (&param_182));
            lod_2 = _e423;
            let _e424 = mtlxEnvMatrix_u0028_();
            let _e425 = Lw;
            param_183 = _e425;
            param_184 = _e424;
            let _e426 = lod_2;
            param_185 = _e426;
            let _e427 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_183), (&param_184), (&param_185));
            sampleColor = _e427;
            let _e428 = VdotH;
            param_186 = _e428;
            let _e429 = (*fd_3);
            param_187 = _e429;
            let _e430 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_186), (&param_187));
            F_1 = _e430;
            let _e431 = NdotL_8;
            param_188 = _e431;
            let _e432 = NdotV_14;
            param_189 = _e432;
            let _e433 = avgAlpha;
            param_190 = _e433;
            let _e434 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_188), (&param_189), (&param_190));
            G_2 = _e434;
            let _e436 = (*fd_3).refraction;
            if _e436 {
                let _e437 = F_1;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e437);
            } else {
                let _e439 = F_1;
                let _e440 = G_2;
                local_8 = (_e439 * _e440);
            }
            let _e442 = local_8;
            FG = _e442;
            let _e443 = sampleColor;
            let _e444 = FG;
            let _e446 = radiance;
            radiance = (_e446 + (_e443 * _e444));
            continue;
        } else {
            break;
        }
        continuing {
            let _e448 = i_3;
            i_3 = (_e448 + 1i);
        }
    }
    let _e450 = G1V_1;
    let _e451 = envRadianceSamples;
    let _e454 = radiance;
    radiance = (_e454 / vec3((_e450 * f32(_e451))));
    let _e457 = radiance;
    let _e460 = unnamed.skyPower;
    return (select(_e457, vec3<f32>(0f, 0f, 0f), false) * _e460);
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_15: ptr<function, f32>, alpha_7: ptr<function, f32>, F0_2: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_10: f32;
    var y_4: f32;
    var x2_1: f32;
    var param_191: f32;
    var y2_: f32;
    var param_192: f32;
    var r_2: vec4<f32>;
    var AB: vec2<f32>;

    let _e291 = (*NdotV_15);
    x_10 = _e291;
    let _e292 = (*alpha_7);
    y_4 = _e292;
    let _e293 = x_10;
    param_191 = _e293;
    let _e294 = mx_square_u0028_f1_u003b((&param_191));
    x2_1 = _e294;
    let _e295 = y_4;
    param_192 = _e295;
    let _e296 = mx_square_u0028_f1_u003b((&param_192));
    y2_ = _e296;
    let _e297 = x_10;
    let _e300 = y_4;
    let _e303 = x_10;
    let _e305 = y_4;
    let _e308 = x2_1;
    let _e311 = y2_;
    let _e314 = x2_1;
    let _e316 = y_4;
    let _e319 = x_10;
    let _e321 = y2_;
    let _e324 = x2_1;
    let _e326 = y2_;
    r_2 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e297)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e300)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e303) * _e305)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e308)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e311)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e314) * _e316)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e319) * _e321)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e324) * _e326));
    let _e329 = r_2;
    let _e331 = r_2;
    AB = clamp((_e329.xy / _e331.zw), vec2(0f), vec2(1f));
    let _e337 = (*F0_2);
    let _e339 = AB[0u];
    let _e341 = (*F90_1);
    let _e343 = AB[1u];
    return ((_e337 * _e339) + (_e341 * _e343));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_16: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_193: f32;
    var param_194: f32;
    var param_195: vec3<f32>;
    var param_196: vec3<f32>;

    let _e287 = (*NdotV_16);
    param_193 = _e287;
    let _e288 = (*alpha_8);
    param_194 = _e288;
    let _e289 = (*F0_3);
    param_195 = _e289;
    let _e290 = (*F90_2);
    param_196 = _e290;
    let _e291 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_193), (&param_194), (&param_195), (&param_196));
    return _e291;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_197: f32;
    var param_198: f32;
    var param_199: vec3<f32>;
    var param_200: vec3<f32>;

    let _e287 = (*F0_4);
    let _e289 = (*F90_3);
    let _e291 = (*NdotV_17);
    param_197 = _e291;
    let _e292 = (*alpha_9);
    param_198 = _e292;
    param_199 = vec3(_e287);
    param_200 = vec3(_e289);
    let _e293 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_197), (&param_198), (&param_199), (&param_200));
    return _e293.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_4: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_201: f32;
    var param_202: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_2967_: bool;

    param_201 = 1f;
    let _e285 = (*fd_4);
    param_202 = _e285;
    let _e286 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_201), (&param_202));
    F0_5 = _e286;
    let _e288 = (*fd_4).model;
    let _e289 = (_e288 == 2i);
    phi_2967_ = _e289;
    if _e289 {
        let _e291 = (*fd_4).airy;
        phi_2967_ = !(_e291);
    }
    let _e294 = phi_2967_;
    if _e294 {
        let _e296 = (*fd_4).F90_;
        local_9 = _e296;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e297 = local_9;
    F90_4 = _e297;
    let _e298 = F0_5;
    let _e299 = F90_4;
    let _e300 = F0_5;
    return (_e298 + ((_e299 - _e300) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_18: ptr<function, f32>, alpha_10: ptr<function, f32>, fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_203: FresnelData;
    var Ess: f32;
    var param_204: f32;
    var param_205: f32;
    var param_206: f32;
    var param_207: f32;

    let _e289 = (*fd_5);
    param_203 = _e289;
    let _e290 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_203));
    Fss = _e290;
    let _e291 = (*NdotV_18);
    param_204 = _e291;
    let _e292 = (*alpha_10);
    param_205 = _e292;
    param_206 = 1f;
    param_207 = 1f;
    let _e293 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_204), (&param_205), (&param_206), (&param_207));
    Ess = _e293;
    let _e294 = Fss;
    let _e295 = Ess;
    let _e298 = Ess;
    return (vec3(1f) + ((_e294 * (1f - _e295)) / vec3(_e298)));
}

fn mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(ior_3: ptr<function, vec3<f32>>, extinction: ptr<function, vec3<f32>>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_6: FresnelData;

    fd_6.model = 1i;
    let _e285 = (*tf_thickness);
    fd_6.airy = (_e285 > 0f);
    let _e288 = (*ior_3);
    fd_6.ior = _e288;
    let _e290 = (*extinction);
    fd_6.extinction = _e290;
    fd_6.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_6.exponent = 0f;
    let _e296 = (*tf_thickness);
    fd_6.tf_thickness = _e296;
    let _e298 = (*tf_ior);
    fd_6.tf_ior = _e298;
    fd_6.refraction = false;
    let _e301 = fd_6;
    return _e301;
}

fn mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_12: ptr<function, ClosureData>, weight_5: ptr<function, f32>, ior_n: ptr<function, vec3<f32>>, ior_k: ptr<function, vec3<f32>>, roughness_14: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_14: ptr<function, vec3<f32>>, X_3: ptr<function, vec3<f32>>, distribution_1: ptr<function, i32>, bsdf_4: ptr<function, BSDF>) {
    var V_10: vec3<f32>;
    var L_8: vec3<f32>;
    var local_10: vec3<f32>;
    var param_208: vec3<f32>;
    var param_209: vec3<f32>;
    var NdotV_19: f32;
    var fd_7: FresnelData;
    var param_210: vec3<f32>;
    var param_211: vec3<f32>;
    var param_212: f32;
    var param_213: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_214: vec2<f32>;
    var Y_3: vec3<f32>;
    var H_5: vec3<f32>;
    var NdotL_9: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_2: vec3<f32>;
    var param_215: f32;
    var param_216: FresnelData;
    var D_1: f32;
    var param_217: vec3<f32>;
    var param_218: vec2<f32>;
    var G_3: f32;
    var param_219: f32;
    var param_220: f32;
    var param_221: f32;
    var comp: vec3<f32>;
    var param_222: f32;
    var param_223: f32;
    var param_224: FresnelData;
    var comp_1: vec3<f32>;
    var param_225: f32;
    var param_226: f32;
    var param_227: FresnelData;
    var Li_5: vec3<f32>;
    var param_228: vec3<f32>;
    var param_229: vec3<f32>;
    var param_230: vec3<f32>;
    var param_231: vec2<f32>;
    var param_232: i32;
    var param_233: FresnelData;

    (*bsdf_4).throughput = vec3<f32>(0f, 0f, 0f);
    let _e336 = (*weight_5);
    if (_e336 < 0.00000001f) {
        return;
    }
    let _e339 = (*closureData_12).V;
    V_10 = _e339;
    let _e341 = (*closureData_12).L;
    L_8 = _e341;
    let _e342 = (*retroreflective);
    if _e342 {
        let _e343 = V_10;
        let _e345 = (*N_14);
        local_10 = reflect(-(_e343), _e345);
    } else {
        let _e347 = V_10;
        local_10 = _e347;
    }
    let _e348 = local_10;
    V_10 = _e348;
    let _e349 = (*N_14);
    param_208 = _e349;
    let _e350 = V_10;
    param_209 = _e350;
    let _e351 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_208), (&param_209));
    (*N_14) = _e351;
    let _e352 = (*N_14);
    let _e353 = V_10;
    NdotV_19 = clamp(dot(_e352, _e353), 0.00000001f, 1f);
    let _e356 = (*ior_n);
    param_210 = _e356;
    let _e357 = (*ior_k);
    param_211 = _e357;
    let _e358 = (*thinfilm_thickness);
    param_212 = _e358;
    let _e359 = (*thinfilm_ior);
    param_213 = _e359;
    let _e360 = mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_210), (&param_211), (&param_212), (&param_213));
    fd_7 = _e360;
    let _e361 = (*roughness_14);
    safeAlpha = clamp(_e361, vec2(0.00000001f), vec2(1f));
    let _e365 = safeAlpha;
    param_214 = _e365;
    let _e366 = mx_average_alpha_u0028_vf2_u003b((&param_214));
    avgAlpha_1 = _e366;
    let _e368 = (*closureData_12).closureType;
    if (_e368 == 1i) {
        let _e370 = (*X_3);
        let _e371 = (*X_3);
        let _e372 = (*N_14);
        let _e374 = (*N_14);
        (*X_3) = normalize((_e370 - (_e374 * dot(_e371, _e372))));
        let _e378 = (*N_14);
        let _e379 = (*X_3);
        Y_3 = cross(_e378, _e379);
        let _e381 = L_8;
        let _e382 = V_10;
        H_5 = normalize((_e381 + _e382));
        let _e385 = (*N_14);
        let _e386 = L_8;
        NdotL_9 = clamp(dot(_e385, _e386), 0.00000001f, 1f);
        let _e389 = V_10;
        let _e390 = H_5;
        VdotH_1 = clamp(dot(_e389, _e390), 0.00000001f, 1f);
        let _e393 = H_5;
        let _e394 = (*X_3);
        let _e396 = H_5;
        let _e397 = Y_3;
        let _e399 = H_5;
        let _e400 = (*N_14);
        Ht = vec3<f32>(dot(_e393, _e394), dot(_e396, _e397), dot(_e399, _e400));
        let _e403 = VdotH_1;
        param_215 = _e403;
        let _e404 = fd_7;
        param_216 = _e404;
        let _e405 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_215), (&param_216));
        F_2 = _e405;
        let _e406 = Ht;
        param_217 = _e406;
        let _e407 = safeAlpha;
        param_218 = _e407;
        let _e408 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_217), (&param_218));
        D_1 = _e408;
        let _e409 = NdotL_9;
        param_219 = _e409;
        let _e410 = NdotV_19;
        param_220 = _e410;
        let _e411 = avgAlpha_1;
        param_221 = _e411;
        let _e412 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_219), (&param_220), (&param_221));
        G_3 = _e412;
        let _e413 = NdotV_19;
        param_222 = _e413;
        let _e414 = avgAlpha_1;
        param_223 = _e414;
        let _e415 = fd_7;
        param_224 = _e415;
        let _e416 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_222), (&param_223), (&param_224));
        comp = _e416;
        let _e417 = D_1;
        let _e418 = F_2;
        let _e420 = G_3;
        let _e422 = comp;
        let _e425 = (*closureData_12).occlusion;
        let _e427 = (*weight_5);
        let _e429 = NdotV_19;
        (*bsdf_4).response = ((((((_e418 * _e417) * _e420) * _e422) * _e425) * _e427) / vec3((4f * _e429)));
    } else {
        let _e435 = (*closureData_12).closureType;
        if (_e435 == 3i) {
            let _e437 = NdotV_19;
            param_225 = _e437;
            let _e438 = avgAlpha_1;
            param_226 = _e438;
            let _e439 = fd_7;
            param_227 = _e439;
            let _e440 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_225), (&param_226), (&param_227));
            comp_1 = _e440;
            let _e441 = (*N_14);
            param_228 = _e441;
            let _e442 = V_10;
            param_229 = _e442;
            let _e443 = (*X_3);
            param_230 = _e443;
            let _e444 = safeAlpha;
            param_231 = _e444;
            let _e445 = (*distribution_1);
            param_232 = _e445;
            let _e446 = fd_7;
            param_233 = _e446;
            let _e447 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_228), (&param_229), (&param_230), (&param_231), (&param_232), (&param_233));
            Li_5 = _e447;
            let _e448 = Li_5;
            let _e449 = comp_1;
            let _e451 = (*weight_5);
            (*bsdf_4).response = ((_e448 * _e449) * _e451);
        }
    }
    return;
}

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_15: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, X_4: ptr<function, vec3<f32>>, alpha_11: ptr<function, vec2<f32>>, distribution_2: ptr<function, i32>, fd_8: ptr<function, FresnelData>, tint_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_234: vec3<f32>;
    var param_235: vec3<f32>;
    var param_236: vec3<f32>;
    var param_237: vec3<f32>;
    var param_238: vec2<f32>;
    var param_239: i32;
    var param_240: FresnelData;

    (*fd_8).refraction = true;
    if false {
        let _e294 = (*tint_1);
        param_234 = _e294;
        let _e295 = mx_square_u0028_vf3_u003b((&param_234));
        (*tint_1) = _e295;
    }
    let _e296 = (*N_15);
    param_235 = _e296;
    let _e297 = (*V_11);
    param_236 = _e297;
    let _e298 = (*X_4);
    param_237 = _e298;
    let _e299 = (*alpha_11);
    param_238 = _e299;
    let _e300 = (*distribution_2);
    param_239 = _e300;
    let _e301 = (*fd_8);
    param_240 = _e301;
    let _e302 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_235), (&param_236), (&param_237), (&param_238), (&param_239), (&param_240));
    let _e303 = (*tint_1);
    return (_e302 * _e303);
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_4: ptr<function, f32>) -> f32 {
    var param_241: f32;

    let _e281 = (*ior_4);
    let _e283 = (*ior_4);
    param_241 = ((_e281 - 1f) / (_e283 + 1f));
    let _e286 = mx_square_u0028_f1_u003b((&param_241));
    return _e286;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_5: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e284 = (*tf_thickness_1);
    fd_9.airy = (_e284 > 0f);
    let _e287 = (*ior_5);
    fd_9.ior = vec3(_e287);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e295 = (*tf_thickness_1);
    fd_9.tf_thickness = _e295;
    let _e297 = (*tf_ior_1);
    fd_9.tf_ior = _e297;
    fd_9.refraction = false;
    let _e300 = fd_9;
    return _e300;
}

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_13: ptr<function, ClosureData>, weight_6: ptr<function, f32>, tint_2: ptr<function, vec3<f32>>, ior_6: ptr<function, f32>, roughness_15: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_16: ptr<function, vec3<f32>>, X_5: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_5: ptr<function, BSDF>) {
    var V_12: vec3<f32>;
    var L_9: vec3<f32>;
    var param_242: vec3<f32>;
    var param_243: vec3<f32>;
    var NdotV_20: f32;
    var fd_10: FresnelData;
    var param_244: f32;
    var param_245: f32;
    var param_246: f32;
    var F0_6: f32;
    var param_247: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_248: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_4: vec3<f32>;
    var H_6: vec3<f32>;
    var NdotL_10: f32;
    var VdotH_2: f32;
    var Ht_1: vec3<f32>;
    var F_3: vec3<f32>;
    var param_249: f32;
    var param_250: FresnelData;
    var D_2: f32;
    var param_251: vec3<f32>;
    var param_252: vec2<f32>;
    var G_4: f32;
    var param_253: f32;
    var param_254: f32;
    var param_255: f32;
    var comp_2: vec3<f32>;
    var param_256: f32;
    var param_257: f32;
    var param_258: FresnelData;
    var dirAlbedo_5: vec3<f32>;
    var param_259: f32;
    var param_260: f32;
    var param_261: f32;
    var param_262: f32;
    var comp_3: vec3<f32>;
    var param_263: f32;
    var param_264: f32;
    var param_265: FresnelData;
    var dirAlbedo_6: vec3<f32>;
    var param_266: f32;
    var param_267: f32;
    var param_268: f32;
    var param_269: f32;
    var param_270: vec3<f32>;
    var param_271: vec3<f32>;
    var param_272: vec3<f32>;
    var param_273: vec2<f32>;
    var param_274: i32;
    var param_275: FresnelData;
    var param_276: vec3<f32>;
    var comp_4: vec3<f32>;
    var param_277: f32;
    var param_278: f32;
    var param_279: FresnelData;
    var dirAlbedo_7: vec3<f32>;
    var param_280: f32;
    var param_281: f32;
    var param_282: f32;
    var param_283: f32;
    var Li_6: vec3<f32>;
    var param_284: vec3<f32>;
    var param_285: vec3<f32>;
    var param_286: vec3<f32>;
    var param_287: vec2<f32>;
    var param_288: i32;
    var param_289: FresnelData;
    var phi_4011_: bool;

    let _e363 = (*weight_6);
    if (_e363 < 0.00000001f) {
        return;
    }
    let _e366 = (*closureData_13).closureType;
    let _e368 = (*scatter_mode);
    if ((_e366 != 2i) && (_e368 == 1i)) {
        return;
    }
    let _e372 = (*closureData_13).V;
    V_12 = _e372;
    let _e374 = (*closureData_13).L;
    L_9 = _e374;
    let _e375 = (*retroreflective_1);
    phi_4011_ = _e375;
    if _e375 {
        let _e377 = (*closureData_13).closureType;
        phi_4011_ = (_e377 != 2i);
    }
    let _e380 = phi_4011_;
    if _e380 {
        let _e381 = V_12;
        let _e383 = (*N_16);
        V_12 = reflect(-(_e381), _e383);
    }
    let _e385 = (*N_16);
    param_242 = _e385;
    let _e386 = V_12;
    param_243 = _e386;
    let _e387 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_242), (&param_243));
    (*N_16) = _e387;
    let _e388 = (*N_16);
    let _e389 = V_12;
    NdotV_20 = clamp(dot(_e388, _e389), 0.00000001f, 1f);
    let _e392 = (*ior_6);
    param_244 = _e392;
    let _e393 = (*thinfilm_thickness_1);
    param_245 = _e393;
    let _e394 = (*thinfilm_ior_1);
    param_246 = _e394;
    let _e395 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_244), (&param_245), (&param_246));
    fd_10 = _e395;
    let _e396 = (*ior_6);
    param_247 = _e396;
    let _e397 = mx_ior_to_f0_u0028_f1_u003b((&param_247));
    F0_6 = _e397;
    let _e398 = (*roughness_15);
    safeAlpha_1 = clamp(_e398, vec2(0.00000001f), vec2(1f));
    let _e402 = safeAlpha_1;
    param_248 = _e402;
    let _e403 = mx_average_alpha_u0028_vf2_u003b((&param_248));
    avgAlpha_2 = _e403;
    let _e404 = (*tint_2);
    safeTint = max(_e404, vec3(0f));
    let _e408 = (*closureData_13).closureType;
    if (_e408 == 1i) {
        let _e410 = (*X_5);
        let _e411 = (*X_5);
        let _e412 = (*N_16);
        let _e414 = (*N_16);
        (*X_5) = normalize((_e410 - (_e414 * dot(_e411, _e412))));
        let _e418 = (*N_16);
        let _e419 = (*X_5);
        Y_4 = cross(_e418, _e419);
        let _e421 = L_9;
        let _e422 = V_12;
        H_6 = normalize((_e421 + _e422));
        let _e425 = (*N_16);
        let _e426 = L_9;
        NdotL_10 = clamp(dot(_e425, _e426), 0.00000001f, 1f);
        let _e429 = V_12;
        let _e430 = H_6;
        VdotH_2 = clamp(dot(_e429, _e430), 0.00000001f, 1f);
        let _e433 = H_6;
        let _e434 = (*X_5);
        let _e436 = H_6;
        let _e437 = Y_4;
        let _e439 = H_6;
        let _e440 = (*N_16);
        Ht_1 = vec3<f32>(dot(_e433, _e434), dot(_e436, _e437), dot(_e439, _e440));
        let _e443 = VdotH_2;
        param_249 = _e443;
        let _e444 = fd_10;
        param_250 = _e444;
        let _e445 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_249), (&param_250));
        F_3 = _e445;
        let _e446 = Ht_1;
        param_251 = _e446;
        let _e447 = safeAlpha_1;
        param_252 = _e447;
        let _e448 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_251), (&param_252));
        D_2 = _e448;
        let _e449 = NdotL_10;
        param_253 = _e449;
        let _e450 = NdotV_20;
        param_254 = _e450;
        let _e451 = avgAlpha_2;
        param_255 = _e451;
        let _e452 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_253), (&param_254), (&param_255));
        G_4 = _e452;
        let _e453 = NdotV_20;
        param_256 = _e453;
        let _e454 = avgAlpha_2;
        param_257 = _e454;
        let _e455 = fd_10;
        param_258 = _e455;
        let _e456 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_256), (&param_257), (&param_258));
        comp_2 = _e456;
        let _e457 = NdotV_20;
        param_259 = _e457;
        let _e458 = avgAlpha_2;
        param_260 = _e458;
        let _e459 = F0_6;
        param_261 = _e459;
        param_262 = 1f;
        let _e460 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_259), (&param_260), (&param_261), (&param_262));
        let _e461 = comp_2;
        dirAlbedo_5 = (_e461 * _e460);
        let _e463 = dirAlbedo_5;
        let _e464 = (*weight_6);
        (*bsdf_5).throughput = (vec3(1f) - (_e463 * _e464));
        let _e469 = D_2;
        let _e470 = F_3;
        let _e472 = G_4;
        let _e474 = comp_2;
        let _e476 = safeTint;
        let _e479 = (*closureData_13).occlusion;
        let _e481 = (*weight_6);
        let _e483 = NdotV_20;
        (*bsdf_5).response = (((((((_e470 * _e469) * _e472) * _e474) * _e476) * _e479) * _e481) / vec3((4f * _e483)));
    } else {
        let _e489 = (*closureData_13).closureType;
        if (_e489 == 2i) {
            let _e491 = NdotV_20;
            param_263 = _e491;
            let _e492 = avgAlpha_2;
            param_264 = _e492;
            let _e493 = fd_10;
            param_265 = _e493;
            let _e494 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_263), (&param_264), (&param_265));
            comp_3 = _e494;
            let _e495 = NdotV_20;
            param_266 = _e495;
            let _e496 = avgAlpha_2;
            param_267 = _e496;
            let _e497 = F0_6;
            param_268 = _e497;
            param_269 = 1f;
            let _e498 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_266), (&param_267), (&param_268), (&param_269));
            let _e499 = comp_3;
            dirAlbedo_6 = (_e499 * _e498);
            let _e501 = dirAlbedo_6;
            let _e502 = (*weight_6);
            (*bsdf_5).throughput = (vec3(1f) - (_e501 * _e502));
            let _e507 = (*scatter_mode);
            if (_e507 != 0i) {
                let _e509 = (*N_16);
                param_270 = _e509;
                let _e510 = V_12;
                param_271 = _e510;
                let _e511 = (*X_5);
                param_272 = _e511;
                let _e512 = safeAlpha_1;
                param_273 = _e512;
                let _e513 = (*distribution_3);
                param_274 = _e513;
                let _e514 = fd_10;
                param_275 = _e514;
                let _e515 = safeTint;
                param_276 = _e515;
                let _e516 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_270), (&param_271), (&param_272), (&param_273), (&param_274), (&param_275), (&param_276));
                let _e517 = (*weight_6);
                (*bsdf_5).response = (_e516 * _e517);
            }
        } else {
            let _e521 = (*closureData_13).closureType;
            if (_e521 == 3i) {
                let _e523 = NdotV_20;
                param_277 = _e523;
                let _e524 = avgAlpha_2;
                param_278 = _e524;
                let _e525 = fd_10;
                param_279 = _e525;
                let _e526 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_277), (&param_278), (&param_279));
                comp_4 = _e526;
                let _e527 = NdotV_20;
                param_280 = _e527;
                let _e528 = avgAlpha_2;
                param_281 = _e528;
                let _e529 = F0_6;
                param_282 = _e529;
                param_283 = 1f;
                let _e530 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_280), (&param_281), (&param_282), (&param_283));
                let _e531 = comp_4;
                dirAlbedo_7 = (_e531 * _e530);
                let _e533 = dirAlbedo_7;
                let _e534 = (*weight_6);
                (*bsdf_5).throughput = (vec3(1f) - (_e533 * _e534));
                let _e539 = (*N_16);
                param_284 = _e539;
                let _e540 = V_12;
                param_285 = _e540;
                let _e541 = (*X_5);
                param_286 = _e541;
                let _e542 = safeAlpha_1;
                param_287 = _e542;
                let _e543 = (*distribution_3);
                param_288 = _e543;
                let _e544 = fd_10;
                param_289 = _e544;
                let _e545 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_284), (&param_285), (&param_286), (&param_287), (&param_288), (&param_289));
                Li_6 = _e545;
                let _e546 = Li_6;
                let _e547 = safeTint;
                let _e549 = comp_4;
                let _e551 = (*weight_6);
                (*bsdf_5).response = (((_e546 * _e547) * _e549) * _e551);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e285 = (*closureType);
    let _e286 = (*L_10);
    let _e287 = (*V_13);
    let _e288 = (*N_17);
    let _e289 = (*P_2);
    let _e290 = (*occlusion_1);
    return ClosureData(_e285, _e286, _e287, _e288, _e289, _e290);
}

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_8: ptr<function, lightshader>) {
    (*result_8).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_8).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e280 = unnamed.mtlxLightCount;
    return min(_e280, 1i);
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_4: ptr<function, f32>, mtlxRasterOut: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e282 = (*in1_4);
    combine_out = vec3(_e282);
    let _e284 = combine_out;
    (*mtlxRasterOut) = _e284;
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

    let _e290 = (*reflectivity);
    r_3 = clamp(_e290, vec3(0f), vec3(0.99f));
    let _e294 = r_3;
    r_sqrt = sqrt(_e294);
    let _e296 = r_3;
    let _e299 = r_3;
    n_min = ((vec3(1f) - _e296) / (vec3(1f) + _e299));
    let _e303 = r_sqrt;
    let _e306 = r_sqrt;
    n_max = ((vec3(1f) + _e303) / (vec3(1f) - _e306));
    let _e310 = n_max;
    let _e311 = n_min;
    let _e312 = (*edge_color);
    (*ior_7) = mix(_e310, _e311, _e312);
    let _e314 = (*ior_7);
    np1_ = (_e314 + vec3(1f));
    let _e317 = (*ior_7);
    nm1_ = (_e317 - vec3(1f));
    let _e320 = np1_;
    let _e321 = np1_;
    let _e323 = r_3;
    let _e325 = nm1_;
    let _e326 = nm1_;
    let _e329 = r_3;
    k2_2 = ((((_e320 * _e321) * _e323) - (_e325 * _e326)) / (vec3(1f) - _e329));
    let _e333 = k2_2;
    k2_2 = max(_e333, vec3(0f));
    let _e336 = k2_2;
    (*extinction_1) = sqrt(_e336);
    return;
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_9: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e287 = (*axis);
    (*axis) = normalize(_e287);
    let _e289 = (*amount);
    rotationRadians = radians(_e289);
    let _e291 = rotationRadians;
    s_4 = sin(_e291);
    let _e293 = rotationRadians;
    c_3 = cos(_e293);
    let _e295 = c_3;
    oc = (1f - _e295);
    let _e297 = (*_in);
    let _e298 = c_3;
    let _e300 = (*_in);
    let _e301 = (*axis);
    let _e303 = s_4;
    let _e306 = (*axis);
    let _e307 = (*axis);
    let _e308 = (*_in);
    let _e311 = oc;
    (*result_9) = (((_e297 * _e298) + (cross(_e300, _e301) * _e303)) + ((_e306 * dot(_e307, _e308)) * _e311));
    return;
}

fn mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b(_in_1: ptr<function, vec3<f32>>, lumacoeffs: ptr<function, vec3<f32>>, result_10: ptr<function, vec3<f32>>) {
    let _e282 = (*_in_1);
    let _e283 = (*lumacoeffs);
    (*result_10) = vec3(dot(_e282, _e283));
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_1: ptr<function, f32>, result_11: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e284 = (*roughness_16);
    let _e285 = (*roughness_16);
    roughness_sqr = clamp((_e284 * _e285), 0.00000001f, 1f);
    let _e288 = (*anisotropy_1);
    if (_e288 > 0f) {
        let _e290 = (*anisotropy_1);
        aspect = sqrt((1f - clamp(_e290, 0f, 0.98f)));
        let _e294 = roughness_sqr;
        let _e295 = aspect;
        (*result_11)[0u] = min((_e294 / _e295), 1f);
        let _e299 = roughness_sqr;
        let _e300 = aspect;
        (*result_11)[1u] = (_e299 * _e300);
    } else {
        let _e303 = roughness_sqr;
        (*result_11)[0u] = _e303;
        let _e305 = roughness_sqr;
        (*result_11)[1u] = _e305;
    }
    return;
}

fn NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_2: ptr<function, f32>, base_color: ptr<function, vec3<f32>>, diffuse_roughness: ptr<function, f32>, metalness: ptr<function, f32>, specular: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, specular_roughness: ptr<function, f32>, specular_IOR: ptr<function, f32>, specular_anisotropy: ptr<function, f32>, specular_rotation: ptr<function, f32>, transmission: ptr<function, f32>, transmission_color: ptr<function, vec3<f32>>, transmission_depth: ptr<function, f32>, transmission_scatter: ptr<function, vec3<f32>>, transmission_scatter_anisotropy: ptr<function, f32>, transmission_dispersion: ptr<function, f32>, transmission_extra_roughness: ptr<function, f32>, subsurface: ptr<function, f32>, subsurface_color: ptr<function, vec3<f32>>, subsurface_radius: ptr<function, vec3<f32>>, subsurface_scale: ptr<function, f32>, subsurface_anisotropy: ptr<function, f32>, sheen: ptr<function, f32>, sheen_color: ptr<function, vec3<f32>>, sheen_roughness: ptr<function, f32>, coat: ptr<function, f32>, coat_color: ptr<function, vec3<f32>>, coat_roughness: ptr<function, f32>, coat_anisotropy: ptr<function, f32>, coat_rotation: ptr<function, f32>, coat_IOR: ptr<function, f32>, coat_normal: ptr<function, vec3<f32>>, coat_affect_color: ptr<function, f32>, coat_affect_roughness: ptr<function, f32>, thin_film_thickness: ptr<function, f32>, thin_film_IOR: ptr<function, f32>, emission: ptr<function, f32>, emission_color: ptr<function, vec3<f32>>, opacity: ptr<function, vec3<f32>>, thin_walled: ptr<function, bool>, normal: ptr<function, vec3<f32>>, tangent: ptr<function, vec3<f32>>, mtlxRasterOut_1: ptr<function, surfaceshader>) {
    var coat_roughness_vector_out: vec2<f32>;
    var param_290: f32;
    var param_291: f32;
    var param_292: vec2<f32>;
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
    var param_293: vec3<f32>;
    var param_294: vec3<f32>;
    var param_295: vec3<f32>;
    var coat_tangent_rotate_out: vec3<f32>;
    var param_296: vec3<f32>;
    var param_297: f32;
    var param_298: vec3<f32>;
    var param_299: vec3<f32>;
    var artistic_ior_ior: vec3<f32>;
    var artistic_ior_extinction: vec3<f32>;
    var param_300: vec3<f32>;
    var param_301: vec3<f32>;
    var param_302: vec3<f32>;
    var param_303: vec3<f32>;
    var coat_affect_roughness_multiply2_out: f32;
    var tangent_rotate_out: vec3<f32>;
    var param_304: vec3<f32>;
    var param_305: f32;
    var param_306: vec3<f32>;
    var param_307: vec3<f32>;
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
    var param_308: f32;
    var param_309: f32;
    var param_310: vec2<f32>;
    var main_tangent_out: vec3<f32>;
    var transmission_roughness_out: vec2<f32>;
    var param_311: f32;
    var param_312: f32;
    var param_313: vec2<f32>;
    var coat_affected_subsurface_color_out: vec3<f32>;
    var coat_affected_diffuse_color_out: vec3<f32>;
    var one_minus_coat_ior_to_F0_out: f32;
    var emission_color0_out: vec3<f32>;
    var param_314: f32;
    var param_315: vec3<f32>;
    var shader_constructor_out: surfaceshader;
    var N_18: vec3<f32>;
    var V_14: vec3<f32>;
    var P_3: vec3<f32>;
    var L_11: vec3<f32>;
    var occlusion_2: f32;
    var surfaceOpacity: f32;
    var numLights: i32;
    var activeLightIndex: i32;
    var lightShader: lightshader;
    var param_316: i32;
    var param_317: vec3<f32>;
    var param_318: lightshader;
    var closureData_14: ClosureData;
    var param_319: i32;
    var param_320: vec3<f32>;
    var param_321: vec3<f32>;
    var param_322: vec3<f32>;
    var param_323: vec3<f32>;
    var param_324: f32;
    var coat_bsdf_out: BSDF;
    var param_325: ClosureData;
    var param_326: f32;
    var param_327: vec3<f32>;
    var param_328: f32;
    var param_329: vec2<f32>;
    var param_330: bool;
    var param_331: f32;
    var param_332: f32;
    var param_333: vec3<f32>;
    var param_334: vec3<f32>;
    var param_335: i32;
    var param_336: i32;
    var param_337: BSDF;
    var metal_bsdf_out: BSDF;
    var param_338: ClosureData;
    var param_339: f32;
    var param_340: vec3<f32>;
    var param_341: vec3<f32>;
    var param_342: vec2<f32>;
    var param_343: bool;
    var param_344: f32;
    var param_345: f32;
    var param_346: vec3<f32>;
    var param_347: vec3<f32>;
    var param_348: i32;
    var param_349: BSDF;
    var specular_bsdf_out: BSDF;
    var param_350: ClosureData;
    var param_351: f32;
    var param_352: vec3<f32>;
    var param_353: f32;
    var param_354: vec2<f32>;
    var param_355: bool;
    var param_356: f32;
    var param_357: f32;
    var param_358: vec3<f32>;
    var param_359: vec3<f32>;
    var param_360: i32;
    var param_361: i32;
    var param_362: BSDF;
    var transmission_bsdf_out: BSDF;
    var param_363: ClosureData;
    var param_364: f32;
    var param_365: vec3<f32>;
    var param_366: f32;
    var param_367: vec2<f32>;
    var param_368: bool;
    var param_369: f32;
    var param_370: f32;
    var param_371: vec3<f32>;
    var param_372: vec3<f32>;
    var param_373: i32;
    var param_374: i32;
    var param_375: BSDF;
    var sheen_bsdf_out: BSDF;
    var param_376: ClosureData;
    var param_377: f32;
    var param_378: vec3<f32>;
    var param_379: f32;
    var param_380: vec3<f32>;
    var param_381: i32;
    var param_382: BSDF;
    var translucent_bsdf_out: BSDF;
    var param_383: ClosureData;
    var param_384: f32;
    var param_385: vec3<f32>;
    var param_386: vec3<f32>;
    var param_387: BSDF;
    var subsurface_bsdf_out: BSDF;
    var param_388: ClosureData;
    var param_389: f32;
    var param_390: vec3<f32>;
    var param_391: vec3<f32>;
    var param_392: f32;
    var param_393: vec3<f32>;
    var param_394: BSDF;
    var selected_subsurface_bsdf_add_out: BSDF;
    var param_395: ClosureData;
    var param_396: BSDF;
    var param_397: BSDF;
    var param_398: BSDF;
    var subsurface_mix_fg_mul_out: BSDF;
    var param_399: ClosureData;
    var param_400: BSDF;
    var param_401: f32;
    var param_402: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_403: ClosureData;
    var param_404: f32;
    var param_405: vec3<f32>;
    var param_406: f32;
    var param_407: vec3<f32>;
    var param_408: bool;
    var param_409: BSDF;
    var subsurface_mix_add_out: BSDF;
    var param_410: ClosureData;
    var param_411: BSDF;
    var param_412: BSDF;
    var param_413: BSDF;
    var sheen_layer_out: BSDF;
    var param_414: ClosureData;
    var param_415: BSDF;
    var param_416: BSDF;
    var param_417: BSDF;
    var transmission_mix_bg_mul_out: BSDF;
    var param_418: ClosureData;
    var param_419: BSDF;
    var param_420: f32;
    var param_421: BSDF;
    var transmission_mix_add_out: BSDF;
    var param_422: ClosureData;
    var param_423: BSDF;
    var param_424: BSDF;
    var param_425: BSDF;
    var specular_layer_out: BSDF;
    var param_426: ClosureData;
    var param_427: BSDF;
    var param_428: BSDF;
    var param_429: BSDF;
    var metalness_mix_bg_mul_out: BSDF;
    var param_430: ClosureData;
    var param_431: BSDF;
    var param_432: f32;
    var param_433: BSDF;
    var metalness_mix_add_out: BSDF;
    var param_434: ClosureData;
    var param_435: BSDF;
    var param_436: BSDF;
    var param_437: BSDF;
    var thin_film_layer_attenuated_out: BSDF;
    var param_438: ClosureData;
    var param_439: BSDF;
    var param_440: vec3<f32>;
    var param_441: BSDF;
    var coat_layer_out: BSDF;
    var param_442: ClosureData;
    var param_443: BSDF;
    var param_444: BSDF;
    var param_445: BSDF;
    var closureData_15: ClosureData;
    var param_446: i32;
    var param_447: vec3<f32>;
    var param_448: vec3<f32>;
    var param_449: vec3<f32>;
    var param_450: vec3<f32>;
    var param_451: f32;
    var coat_bsdf_out_1: BSDF;
    var param_452: ClosureData;
    var param_453: f32;
    var param_454: vec3<f32>;
    var param_455: f32;
    var param_456: vec2<f32>;
    var param_457: bool;
    var param_458: f32;
    var param_459: f32;
    var param_460: vec3<f32>;
    var param_461: vec3<f32>;
    var param_462: i32;
    var param_463: i32;
    var param_464: BSDF;
    var metal_bsdf_out_1: BSDF;
    var param_465: ClosureData;
    var param_466: f32;
    var param_467: vec3<f32>;
    var param_468: vec3<f32>;
    var param_469: vec2<f32>;
    var param_470: bool;
    var param_471: f32;
    var param_472: f32;
    var param_473: vec3<f32>;
    var param_474: vec3<f32>;
    var param_475: i32;
    var param_476: BSDF;
    var specular_bsdf_out_1: BSDF;
    var param_477: ClosureData;
    var param_478: f32;
    var param_479: vec3<f32>;
    var param_480: f32;
    var param_481: vec2<f32>;
    var param_482: bool;
    var param_483: f32;
    var param_484: f32;
    var param_485: vec3<f32>;
    var param_486: vec3<f32>;
    var param_487: i32;
    var param_488: i32;
    var param_489: BSDF;
    var transmission_bsdf_out_1: BSDF;
    var param_490: ClosureData;
    var param_491: f32;
    var param_492: vec3<f32>;
    var param_493: f32;
    var param_494: vec2<f32>;
    var param_495: bool;
    var param_496: f32;
    var param_497: f32;
    var param_498: vec3<f32>;
    var param_499: vec3<f32>;
    var param_500: i32;
    var param_501: i32;
    var param_502: BSDF;
    var sheen_bsdf_out_1: BSDF;
    var param_503: ClosureData;
    var param_504: f32;
    var param_505: vec3<f32>;
    var param_506: f32;
    var param_507: vec3<f32>;
    var param_508: i32;
    var param_509: BSDF;
    var translucent_bsdf_out_1: BSDF;
    var param_510: ClosureData;
    var param_511: f32;
    var param_512: vec3<f32>;
    var param_513: vec3<f32>;
    var param_514: BSDF;
    var subsurface_bsdf_out_1: BSDF;
    var param_515: ClosureData;
    var param_516: f32;
    var param_517: vec3<f32>;
    var param_518: vec3<f32>;
    var param_519: f32;
    var param_520: vec3<f32>;
    var param_521: BSDF;
    var selected_subsurface_bsdf_add_out_1: BSDF;
    var param_522: ClosureData;
    var param_523: BSDF;
    var param_524: BSDF;
    var param_525: BSDF;
    var subsurface_mix_fg_mul_out_1: BSDF;
    var param_526: ClosureData;
    var param_527: BSDF;
    var param_528: f32;
    var param_529: BSDF;
    var diffuse_bsdf_out_1: BSDF;
    var param_530: ClosureData;
    var param_531: f32;
    var param_532: vec3<f32>;
    var param_533: f32;
    var param_534: vec3<f32>;
    var param_535: bool;
    var param_536: BSDF;
    var subsurface_mix_add_out_1: BSDF;
    var param_537: ClosureData;
    var param_538: BSDF;
    var param_539: BSDF;
    var param_540: BSDF;
    var sheen_layer_out_1: BSDF;
    var param_541: ClosureData;
    var param_542: BSDF;
    var param_543: BSDF;
    var param_544: BSDF;
    var transmission_mix_bg_mul_out_1: BSDF;
    var param_545: ClosureData;
    var param_546: BSDF;
    var param_547: f32;
    var param_548: BSDF;
    var transmission_mix_add_out_1: BSDF;
    var param_549: ClosureData;
    var param_550: BSDF;
    var param_551: BSDF;
    var param_552: BSDF;
    var specular_layer_out_1: BSDF;
    var param_553: ClosureData;
    var param_554: BSDF;
    var param_555: BSDF;
    var param_556: BSDF;
    var metalness_mix_bg_mul_out_1: BSDF;
    var param_557: ClosureData;
    var param_558: BSDF;
    var param_559: f32;
    var param_560: BSDF;
    var metalness_mix_add_out_1: BSDF;
    var param_561: ClosureData;
    var param_562: BSDF;
    var param_563: BSDF;
    var param_564: BSDF;
    var thin_film_layer_attenuated_out_1: BSDF;
    var param_565: ClosureData;
    var param_566: BSDF;
    var param_567: vec3<f32>;
    var param_568: BSDF;
    var coat_layer_out_1: BSDF;
    var param_569: ClosureData;
    var param_570: BSDF;
    var param_571: BSDF;
    var param_572: BSDF;
    var closureData_16: ClosureData;
    var param_573: i32;
    var param_574: vec3<f32>;
    var param_575: vec3<f32>;
    var param_576: vec3<f32>;
    var param_577: vec3<f32>;
    var param_578: f32;
    var emission_edf_out: vec3<f32>;
    var param_579: ClosureData;
    var param_580: vec3<f32>;
    var param_581: vec3<f32>;
    var coat_tinted_emission_edf_out: vec3<f32>;
    var param_582: ClosureData;
    var param_583: vec3<f32>;
    var param_584: vec3<f32>;
    var param_585: vec3<f32>;
    var coat_emission_edf_out: vec3<f32>;
    var param_586: ClosureData;
    var param_587: vec3<f32>;
    var param_588: vec3<f32>;
    var param_589: f32;
    var param_590: vec3<f32>;
    var param_591: vec3<f32>;
    var blended_coat_emission_edf_out: vec3<f32>;
    var param_592: ClosureData;
    var param_593: vec3<f32>;
    var param_594: vec3<f32>;
    var param_595: f32;
    var param_596: vec3<f32>;
    var closureData_17: ClosureData;
    var param_597: i32;
    var param_598: vec3<f32>;
    var param_599: vec3<f32>;
    var param_600: vec3<f32>;
    var param_601: vec3<f32>;
    var param_602: f32;
    var coat_bsdf_out_2: BSDF;
    var param_603: ClosureData;
    var param_604: f32;
    var param_605: vec3<f32>;
    var param_606: f32;
    var param_607: vec2<f32>;
    var param_608: bool;
    var param_609: f32;
    var param_610: f32;
    var param_611: vec3<f32>;
    var param_612: vec3<f32>;
    var param_613: i32;
    var param_614: i32;
    var param_615: BSDF;
    var metal_bsdf_out_2: BSDF;
    var param_616: ClosureData;
    var param_617: f32;
    var param_618: vec3<f32>;
    var param_619: vec3<f32>;
    var param_620: vec2<f32>;
    var param_621: bool;
    var param_622: f32;
    var param_623: f32;
    var param_624: vec3<f32>;
    var param_625: vec3<f32>;
    var param_626: i32;
    var param_627: BSDF;
    var specular_bsdf_out_2: BSDF;
    var param_628: ClosureData;
    var param_629: f32;
    var param_630: vec3<f32>;
    var param_631: f32;
    var param_632: vec2<f32>;
    var param_633: bool;
    var param_634: f32;
    var param_635: f32;
    var param_636: vec3<f32>;
    var param_637: vec3<f32>;
    var param_638: i32;
    var param_639: i32;
    var param_640: BSDF;
    var transmission_bsdf_out_2: BSDF;
    var param_641: ClosureData;
    var param_642: f32;
    var param_643: vec3<f32>;
    var param_644: f32;
    var param_645: vec2<f32>;
    var param_646: bool;
    var param_647: f32;
    var param_648: f32;
    var param_649: vec3<f32>;
    var param_650: vec3<f32>;
    var param_651: i32;
    var param_652: i32;
    var param_653: BSDF;
    var sheen_bsdf_out_2: BSDF;
    var param_654: ClosureData;
    var param_655: f32;
    var param_656: vec3<f32>;
    var param_657: f32;
    var param_658: vec3<f32>;
    var param_659: i32;
    var param_660: BSDF;
    var translucent_bsdf_out_2: BSDF;
    var param_661: ClosureData;
    var param_662: f32;
    var param_663: vec3<f32>;
    var param_664: vec3<f32>;
    var param_665: BSDF;
    var subsurface_bsdf_out_2: BSDF;
    var param_666: ClosureData;
    var param_667: f32;
    var param_668: vec3<f32>;
    var param_669: vec3<f32>;
    var param_670: f32;
    var param_671: vec3<f32>;
    var param_672: BSDF;
    var selected_subsurface_bsdf_add_out_2: BSDF;
    var param_673: ClosureData;
    var param_674: BSDF;
    var param_675: BSDF;
    var param_676: BSDF;
    var subsurface_mix_fg_mul_out_2: BSDF;
    var param_677: ClosureData;
    var param_678: BSDF;
    var param_679: f32;
    var param_680: BSDF;
    var diffuse_bsdf_out_2: BSDF;
    var param_681: ClosureData;
    var param_682: f32;
    var param_683: vec3<f32>;
    var param_684: f32;
    var param_685: vec3<f32>;
    var param_686: bool;
    var param_687: BSDF;
    var subsurface_mix_add_out_2: BSDF;
    var param_688: ClosureData;
    var param_689: BSDF;
    var param_690: BSDF;
    var param_691: BSDF;
    var sheen_layer_out_2: BSDF;
    var param_692: ClosureData;
    var param_693: BSDF;
    var param_694: BSDF;
    var param_695: BSDF;
    var transmission_mix_bg_mul_out_2: BSDF;
    var param_696: ClosureData;
    var param_697: BSDF;
    var param_698: f32;
    var param_699: BSDF;
    var transmission_mix_add_out_2: BSDF;
    var param_700: ClosureData;
    var param_701: BSDF;
    var param_702: BSDF;
    var param_703: BSDF;
    var specular_layer_out_2: BSDF;
    var param_704: ClosureData;
    var param_705: BSDF;
    var param_706: BSDF;
    var param_707: BSDF;
    var metalness_mix_bg_mul_out_2: BSDF;
    var param_708: ClosureData;
    var param_709: BSDF;
    var param_710: f32;
    var param_711: BSDF;
    var metalness_mix_add_out_2: BSDF;
    var param_712: ClosureData;
    var param_713: BSDF;
    var param_714: BSDF;
    var param_715: BSDF;
    var thin_film_layer_attenuated_out_2: BSDF;
    var param_716: ClosureData;
    var param_717: BSDF;
    var param_718: vec3<f32>;
    var param_719: BSDF;
    var coat_layer_out_2: BSDF;
    var param_720: ClosureData;
    var param_721: BSDF;
    var param_722: BSDF;
    var param_723: BSDF;

    coat_roughness_vector_out = vec2<f32>(0f, 0f);
    let _e880 = (*coat_roughness);
    param_290 = _e880;
    let _e881 = (*coat_anisotropy);
    param_291 = _e881;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_290), (&param_291), (&param_292));
    let _e882 = param_292;
    coat_roughness_vector_out = _e882;
    let _e883 = (*coat_rotation);
    coat_tangent_rotate_degree_out = (_e883 * 360f);
    let _e885 = (*metalness);
    metalness_mix_fg_weight_out = (1f * _e885);
    let _e887 = (*base_color);
    let _e888 = (*base_2);
    metal_reflectivity_out = (_e887 * _e888);
    let _e890 = (*specular_color);
    let _e891 = (*specular);
    metal_edgecolor_out = (_e890 * _e891);
    let _e893 = (*coat_affect_roughness);
    let _e894 = (*coat);
    coat_affect_roughness_multiply1_out = (_e893 * _e894);
    let _e896 = (*specular_rotation);
    tangent_rotate_degree_out = (_e896 * 360f);
    let _e898 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e898);
    let _e900 = (*specular_roughness);
    let _e901 = (*transmission_extra_roughness);
    transmission_roughness_add_out = (_e900 + _e901);
    let _e903 = (*thin_walled);
    subsurface_selector_out = select(0f, 1f, _e903);
    let _e905 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e905, vec3(0f));
    let _e908 = (*coat);
    coat_clamped_out = clamp(_e908, 0f, 1f);
    let _e910 = (*subsurface_radius);
    let _e911 = (*subsurface_scale);
    subsurface_radius_scaled_out = (_e910 * _e911);
    let _e913 = (*subsurface);
    subsurface_mix_mix_inv_out = (1f - _e913);
    let _e915 = (*base_color);
    base_color_nonnegative_out = max(_e915, vec3(0f));
    let _e918 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e918);
    let _e920 = (*metalness);
    metalness_mix_mix_inv_out = (1f - _e920);
    let _e922 = (*coat_color);
    let _e923 = (*coat);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e922, vec3(_e923));
    let _e926 = (*coat_IOR);
    one_minus_coat_ior_out = (1f - _e926);
    let _e928 = (*coat_IOR);
    one_plus_coat_ior_out = (1f + _e928);
    let _e930 = (*emission_color);
    let _e931 = (*emission);
    emission_weight_out = (_e930 * _e931);
    opacity_luminance_out = vec3<f32>(0f, 0f, 0f);
    let _e933 = (*opacity);
    param_293 = _e933;
    param_294 = vec3<f32>(0.272229f, 0.674082f, 0.053689f);
    mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_293), (&param_294), (&param_295));
    let _e934 = param_295;
    opacity_luminance_out = _e934;
    coat_tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e935 = (*tangent);
    param_296 = _e935;
    let _e936 = coat_tangent_rotate_degree_out;
    param_297 = _e936;
    let _e937 = (*coat_normal);
    param_298 = _e937;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_296), (&param_297), (&param_298), (&param_299));
    let _e938 = param_299;
    coat_tangent_rotate_out = _e938;
    artistic_ior_ior = vec3<f32>(0f, 0f, 0f);
    artistic_ior_extinction = vec3<f32>(0f, 0f, 0f);
    let _e939 = metal_reflectivity_out;
    param_300 = _e939;
    let _e940 = metal_edgecolor_out;
    param_301 = _e940;
    mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_300), (&param_301), (&param_302), (&param_303));
    let _e941 = param_302;
    artistic_ior_ior = _e941;
    let _e942 = param_303;
    artistic_ior_extinction = _e942;
    let _e943 = coat_affect_roughness_multiply1_out;
    let _e944 = (*coat_roughness);
    coat_affect_roughness_multiply2_out = (_e943 * _e944);
    tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e946 = (*tangent);
    param_304 = _e946;
    let _e947 = tangent_rotate_degree_out;
    param_305 = _e947;
    let _e948 = (*normal);
    param_306 = _e948;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_304), (&param_305), (&param_306), (&param_307));
    let _e949 = param_307;
    tangent_rotate_out = _e949;
    let _e950 = transmission_roughness_add_out;
    transmission_roughness_clamped_out = clamp(_e950, 0f, 1f);
    let _e952 = subsurface_selector_out;
    selected_subsurface_bsdf_mix_inv_out = (1f - _e952);
    let _e954 = subsurface_selector_out;
    selected_subsurface_bsdf_fg_weight_out = (1f * _e954);
    let _e956 = coat_clamped_out;
    let _e957 = (*coat_affect_color);
    coat_gamma_multiply_out = (_e956 * _e957);
    let _e959 = (*base_2);
    let _e960 = subsurface_mix_mix_inv_out;
    subsurface_mix_bg_weight_out = (_e959 * _e960);
    let _e962 = one_minus_coat_ior_out;
    let _e963 = one_plus_coat_ior_out;
    coat_ior_to_F0_sqrt_out = (_e962 / _e963);
    let _e966 = opacity_luminance_out[0u];
    opacity_luminance_float_out = _e966;
    let _e967 = coat_tangent_rotate_out;
    coat_tangent_rotate_normalize_out = normalize(_e967);
    let _e969 = (*specular_roughness);
    let _e970 = coat_affect_roughness_multiply2_out;
    coat_affected_roughness_out = mix(_e969, 1f, _e970);
    let _e972 = tangent_rotate_out;
    tangent_rotate_normalize_out = normalize(_e972);
    let _e974 = transmission_roughness_clamped_out;
    let _e975 = coat_affect_roughness_multiply2_out;
    coat_affected_transmission_roughness_out = mix(_e974, 1f, _e975);
    let _e977 = selected_subsurface_bsdf_mix_inv_out;
    selected_subsurface_bsdf_bg_weight_out = (1f * _e977);
    let _e979 = coat_gamma_multiply_out;
    coat_gamma_out = (_e979 + 1f);
    let _e981 = coat_ior_to_F0_sqrt_out;
    let _e982 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e981 * _e982);
    let _e984 = (*coat_anisotropy);
    let _e986 = coat_tangent_rotate_normalize_out;
    let _e987 = (*tangent);
    coat_tangent_out = select(_e987, _e986, (_e984 > 0f));
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e989 = coat_affected_roughness_out;
    param_308 = _e989;
    let _e990 = (*specular_anisotropy);
    param_309 = _e990;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_308), (&param_309), (&param_310));
    let _e991 = param_310;
    main_roughness_out = _e991;
    let _e992 = (*specular_anisotropy);
    let _e994 = tangent_rotate_normalize_out;
    let _e995 = (*tangent);
    main_tangent_out = select(_e995, _e994, (_e992 > 0f));
    transmission_roughness_out = vec2<f32>(0f, 0f);
    let _e997 = coat_affected_transmission_roughness_out;
    param_311 = _e997;
    let _e998 = (*specular_anisotropy);
    param_312 = _e998;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_311), (&param_312), (&param_313));
    let _e999 = param_313;
    transmission_roughness_out = _e999;
    let _e1000 = subsurface_color_nonnegative_out;
    let _e1001 = coat_gamma_out;
    coat_affected_subsurface_color_out = pow(_e1000, vec3(_e1001));
    let _e1004 = base_color_nonnegative_out;
    let _e1005 = coat_gamma_out;
    coat_affected_diffuse_color_out = pow(_e1004, vec3(_e1005));
    let _e1008 = coat_ior_to_F0_out;
    one_minus_coat_ior_to_F0_out = (1f - _e1008);
    emission_color0_out = vec3<f32>(0f, 0f, 0f);
    let _e1010 = one_minus_coat_ior_to_F0_out;
    param_314 = _e1010;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_314), (&param_315));
    let _e1011 = param_315;
    emission_color0_out = _e1011;
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e1012 = normalWorld;
    N_18 = normalize(_e1012);
    let _e1016 = unnamed.cameraWorldMatrix[3];
    let _e1018 = positionWorld;
    V_14 = normalize((_e1016.xyz - _e1018));
    let _e1021 = positionWorld;
    P_3 = _e1021;
    L_11 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e1022 = opacity_luminance_float_out;
    surfaceOpacity = _e1022;
    let _e1023 = numActiveLightSources_u0028_();
    numLights = _e1023;
    activeLightIndex = 0i;
    loop {
        let _e1024 = activeLightIndex;
        let _e1025 = numLights;
        if (_e1024 < _e1025) {
            let _e1027 = activeLightIndex;
            let _e1030 = unnamed.u_lightData[_e1027];
            param_316 = _e1030;
            let _e1031 = positionWorld;
            param_317 = _e1031;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_316), (&param_317), (&param_318));
            let _e1032 = param_318;
            lightShader = _e1032;
            let _e1034 = lightShader.direction;
            L_11 = _e1034;
            param_319 = 1i;
            let _e1035 = L_11;
            param_320 = _e1035;
            let _e1036 = V_14;
            param_321 = _e1036;
            let _e1037 = N_18;
            param_322 = _e1037;
            let _e1038 = P_3;
            param_323 = _e1038;
            let _e1039 = occlusion_2;
            param_324 = _e1039;
            let _e1040 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324));
            closureData_14 = _e1040;
            coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1041 = closureData_14;
            param_325 = _e1041;
            let _e1042 = (*coat);
            param_326 = _e1042;
            param_327 = vec3<f32>(1f, 1f, 1f);
            let _e1043 = (*coat_IOR);
            param_328 = _e1043;
            let _e1044 = coat_roughness_vector_out;
            param_329 = _e1044;
            param_330 = false;
            param_331 = 0f;
            param_332 = 1.5f;
            let _e1045 = (*coat_normal);
            param_333 = _e1045;
            let _e1046 = coat_tangent_out;
            param_334 = _e1046;
            param_335 = 0i;
            param_336 = 0i;
            let _e1047 = coat_bsdf_out;
            param_337 = _e1047;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_325), (&param_326), (&param_327), (&param_328), (&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336), (&param_337));
            let _e1048 = param_337;
            coat_bsdf_out = _e1048;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1049 = closureData_14;
            param_338 = _e1049;
            let _e1050 = metalness_mix_fg_weight_out;
            param_339 = _e1050;
            let _e1051 = artistic_ior_ior;
            param_340 = _e1051;
            let _e1052 = artistic_ior_extinction;
            param_341 = _e1052;
            let _e1053 = main_roughness_out;
            param_342 = _e1053;
            param_343 = false;
            let _e1054 = (*thin_film_thickness);
            param_344 = _e1054;
            let _e1055 = (*thin_film_IOR);
            param_345 = _e1055;
            let _e1056 = (*normal);
            param_346 = _e1056;
            let _e1057 = main_tangent_out;
            param_347 = _e1057;
            param_348 = 0i;
            let _e1058 = metal_bsdf_out;
            param_349 = _e1058;
            mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349));
            let _e1059 = param_349;
            metal_bsdf_out = _e1059;
            specular_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1060 = closureData_14;
            param_350 = _e1060;
            let _e1061 = (*specular);
            param_351 = _e1061;
            let _e1062 = (*specular_color);
            param_352 = _e1062;
            let _e1063 = (*specular_IOR);
            param_353 = _e1063;
            let _e1064 = main_roughness_out;
            param_354 = _e1064;
            param_355 = false;
            let _e1065 = (*thin_film_thickness);
            param_356 = _e1065;
            let _e1066 = (*thin_film_IOR);
            param_357 = _e1066;
            let _e1067 = (*normal);
            param_358 = _e1067;
            let _e1068 = main_tangent_out;
            param_359 = _e1068;
            param_360 = 0i;
            param_361 = 0i;
            let _e1069 = specular_bsdf_out;
            param_362 = _e1069;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_350), (&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362));
            let _e1070 = param_362;
            specular_bsdf_out = _e1070;
            transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1071 = closureData_14;
            param_363 = _e1071;
            let _e1072 = transmission_mix_fg_weight_out;
            param_364 = _e1072;
            let _e1073 = (*transmission_color);
            param_365 = _e1073;
            let _e1074 = (*specular_IOR);
            param_366 = _e1074;
            let _e1075 = transmission_roughness_out;
            param_367 = _e1075;
            param_368 = false;
            param_369 = 0f;
            param_370 = 1.5f;
            let _e1076 = (*normal);
            param_371 = _e1076;
            let _e1077 = main_tangent_out;
            param_372 = _e1077;
            param_373 = 0i;
            param_374 = 1i;
            let _e1078 = transmission_bsdf_out;
            param_375 = _e1078;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372), (&param_373), (&param_374), (&param_375));
            let _e1079 = param_375;
            transmission_bsdf_out = _e1079;
            sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1080 = closureData_14;
            param_376 = _e1080;
            let _e1081 = (*sheen);
            param_377 = _e1081;
            let _e1082 = (*sheen_color);
            param_378 = _e1082;
            let _e1083 = (*sheen_roughness);
            param_379 = _e1083;
            let _e1084 = (*normal);
            param_380 = _e1084;
            param_381 = 0i;
            let _e1085 = sheen_bsdf_out;
            param_382 = _e1085;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382));
            let _e1086 = param_382;
            sheen_bsdf_out = _e1086;
            translucent_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1087 = closureData_14;
            param_383 = _e1087;
            let _e1088 = selected_subsurface_bsdf_fg_weight_out;
            param_384 = _e1088;
            let _e1089 = coat_affected_subsurface_color_out;
            param_385 = _e1089;
            let _e1090 = (*normal);
            param_386 = _e1090;
            let _e1091 = translucent_bsdf_out;
            param_387 = _e1091;
            mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_383), (&param_384), (&param_385), (&param_386), (&param_387));
            let _e1092 = param_387;
            translucent_bsdf_out = _e1092;
            subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1093 = closureData_14;
            param_388 = _e1093;
            let _e1094 = selected_subsurface_bsdf_bg_weight_out;
            param_389 = _e1094;
            let _e1095 = coat_affected_subsurface_color_out;
            param_390 = _e1095;
            let _e1096 = subsurface_radius_scaled_out;
            param_391 = _e1096;
            let _e1097 = (*subsurface_anisotropy);
            param_392 = _e1097;
            let _e1098 = (*normal);
            param_393 = _e1098;
            let _e1099 = subsurface_bsdf_out;
            param_394 = _e1099;
            mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394));
            let _e1100 = param_394;
            subsurface_bsdf_out = _e1100;
            selected_subsurface_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1101 = closureData_14;
            param_395 = _e1101;
            let _e1102 = translucent_bsdf_out;
            param_396 = _e1102;
            let _e1103 = subsurface_bsdf_out;
            param_397 = _e1103;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_395), (&param_396), (&param_397), (&param_398));
            let _e1104 = param_398;
            selected_subsurface_bsdf_add_out = _e1104;
            subsurface_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1105 = closureData_14;
            param_399 = _e1105;
            let _e1106 = selected_subsurface_bsdf_add_out;
            param_400 = _e1106;
            let _e1107 = (*subsurface);
            param_401 = _e1107;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_399), (&param_400), (&param_401), (&param_402));
            let _e1108 = param_402;
            subsurface_mix_fg_mul_out = _e1108;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1109 = closureData_14;
            param_403 = _e1109;
            let _e1110 = subsurface_mix_bg_weight_out;
            param_404 = _e1110;
            let _e1111 = coat_affected_diffuse_color_out;
            param_405 = _e1111;
            let _e1112 = (*diffuse_roughness);
            param_406 = _e1112;
            let _e1113 = (*normal);
            param_407 = _e1113;
            param_408 = false;
            let _e1114 = diffuse_bsdf_out;
            param_409 = _e1114;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_403), (&param_404), (&param_405), (&param_406), (&param_407), (&param_408), (&param_409));
            let _e1115 = param_409;
            diffuse_bsdf_out = _e1115;
            subsurface_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1116 = closureData_14;
            param_410 = _e1116;
            let _e1117 = subsurface_mix_fg_mul_out;
            param_411 = _e1117;
            let _e1118 = diffuse_bsdf_out;
            param_412 = _e1118;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_410), (&param_411), (&param_412), (&param_413));
            let _e1119 = param_413;
            subsurface_mix_add_out = _e1119;
            sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1120 = closureData_14;
            param_414 = _e1120;
            let _e1121 = sheen_bsdf_out;
            param_415 = _e1121;
            let _e1122 = subsurface_mix_add_out;
            param_416 = _e1122;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_414), (&param_415), (&param_416), (&param_417));
            let _e1123 = param_417;
            sheen_layer_out = _e1123;
            transmission_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1124 = closureData_14;
            param_418 = _e1124;
            let _e1125 = sheen_layer_out;
            param_419 = _e1125;
            let _e1126 = transmission_mix_mix_inv_out;
            param_420 = _e1126;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_418), (&param_419), (&param_420), (&param_421));
            let _e1127 = param_421;
            transmission_mix_bg_mul_out = _e1127;
            transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1128 = closureData_14;
            param_422 = _e1128;
            let _e1129 = transmission_bsdf_out;
            param_423 = _e1129;
            let _e1130 = transmission_mix_bg_mul_out;
            param_424 = _e1130;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_422), (&param_423), (&param_424), (&param_425));
            let _e1131 = param_425;
            transmission_mix_add_out = _e1131;
            specular_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1132 = closureData_14;
            param_426 = _e1132;
            let _e1133 = specular_bsdf_out;
            param_427 = _e1133;
            let _e1134 = transmission_mix_add_out;
            param_428 = _e1134;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_426), (&param_427), (&param_428), (&param_429));
            let _e1135 = param_429;
            specular_layer_out = _e1135;
            metalness_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1136 = closureData_14;
            param_430 = _e1136;
            let _e1137 = specular_layer_out;
            param_431 = _e1137;
            let _e1138 = metalness_mix_mix_inv_out;
            param_432 = _e1138;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_430), (&param_431), (&param_432), (&param_433));
            let _e1139 = param_433;
            metalness_mix_bg_mul_out = _e1139;
            metalness_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1140 = closureData_14;
            param_434 = _e1140;
            let _e1141 = metal_bsdf_out;
            param_435 = _e1141;
            let _e1142 = metalness_mix_bg_mul_out;
            param_436 = _e1142;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_434), (&param_435), (&param_436), (&param_437));
            let _e1143 = param_437;
            metalness_mix_add_out = _e1143;
            thin_film_layer_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1144 = closureData_14;
            param_438 = _e1144;
            let _e1145 = metalness_mix_add_out;
            param_439 = _e1145;
            let _e1146 = coat_attenuation_out;
            param_440 = _e1146;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_438), (&param_439), (&param_440), (&param_441));
            let _e1147 = param_441;
            thin_film_layer_attenuated_out = _e1147;
            coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1148 = closureData_14;
            param_442 = _e1148;
            let _e1149 = coat_bsdf_out;
            param_443 = _e1149;
            let _e1150 = thin_film_layer_attenuated_out;
            param_444 = _e1150;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_442), (&param_443), (&param_444), (&param_445));
            let _e1151 = param_445;
            coat_layer_out = _e1151;
            let _e1153 = lightShader.intensity;
            let _e1155 = coat_layer_out.response;
            let _e1158 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1158 + (_e1153 * _e1155));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1161 = activeLightIndex;
            activeLightIndex = (_e1161 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_446 = 3i;
    let _e1163 = L_11;
    param_447 = _e1163;
    let _e1164 = V_14;
    param_448 = _e1164;
    let _e1165 = N_18;
    param_449 = _e1165;
    let _e1166 = P_3;
    param_450 = _e1166;
    let _e1167 = occlusion_2;
    param_451 = _e1167;
    let _e1168 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451));
    closureData_15 = _e1168;
    coat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1169 = closureData_15;
    param_452 = _e1169;
    let _e1170 = (*coat);
    param_453 = _e1170;
    param_454 = vec3<f32>(1f, 1f, 1f);
    let _e1171 = (*coat_IOR);
    param_455 = _e1171;
    let _e1172 = coat_roughness_vector_out;
    param_456 = _e1172;
    param_457 = false;
    param_458 = 0f;
    param_459 = 1.5f;
    let _e1173 = (*coat_normal);
    param_460 = _e1173;
    let _e1174 = coat_tangent_out;
    param_461 = _e1174;
    param_462 = 0i;
    param_463 = 0i;
    let _e1175 = coat_bsdf_out_1;
    param_464 = _e1175;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_452), (&param_453), (&param_454), (&param_455), (&param_456), (&param_457), (&param_458), (&param_459), (&param_460), (&param_461), (&param_462), (&param_463), (&param_464));
    let _e1176 = param_464;
    coat_bsdf_out_1 = _e1176;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1177 = closureData_15;
    param_465 = _e1177;
    let _e1178 = metalness_mix_fg_weight_out;
    param_466 = _e1178;
    let _e1179 = artistic_ior_ior;
    param_467 = _e1179;
    let _e1180 = artistic_ior_extinction;
    param_468 = _e1180;
    let _e1181 = main_roughness_out;
    param_469 = _e1181;
    param_470 = false;
    let _e1182 = (*thin_film_thickness);
    param_471 = _e1182;
    let _e1183 = (*thin_film_IOR);
    param_472 = _e1183;
    let _e1184 = (*normal);
    param_473 = _e1184;
    let _e1185 = main_tangent_out;
    param_474 = _e1185;
    param_475 = 0i;
    let _e1186 = metal_bsdf_out_1;
    param_476 = _e1186;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476));
    let _e1187 = param_476;
    metal_bsdf_out_1 = _e1187;
    specular_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1188 = closureData_15;
    param_477 = _e1188;
    let _e1189 = (*specular);
    param_478 = _e1189;
    let _e1190 = (*specular_color);
    param_479 = _e1190;
    let _e1191 = (*specular_IOR);
    param_480 = _e1191;
    let _e1192 = main_roughness_out;
    param_481 = _e1192;
    param_482 = false;
    let _e1193 = (*thin_film_thickness);
    param_483 = _e1193;
    let _e1194 = (*thin_film_IOR);
    param_484 = _e1194;
    let _e1195 = (*normal);
    param_485 = _e1195;
    let _e1196 = main_tangent_out;
    param_486 = _e1196;
    param_487 = 0i;
    param_488 = 0i;
    let _e1197 = specular_bsdf_out_1;
    param_489 = _e1197;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489));
    let _e1198 = param_489;
    specular_bsdf_out_1 = _e1198;
    transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1199 = closureData_15;
    param_490 = _e1199;
    let _e1200 = transmission_mix_fg_weight_out;
    param_491 = _e1200;
    let _e1201 = (*transmission_color);
    param_492 = _e1201;
    let _e1202 = (*specular_IOR);
    param_493 = _e1202;
    let _e1203 = transmission_roughness_out;
    param_494 = _e1203;
    param_495 = false;
    param_496 = 0f;
    param_497 = 1.5f;
    let _e1204 = (*normal);
    param_498 = _e1204;
    let _e1205 = main_tangent_out;
    param_499 = _e1205;
    param_500 = 0i;
    param_501 = 1i;
    let _e1206 = transmission_bsdf_out_1;
    param_502 = _e1206;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_490), (&param_491), (&param_492), (&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502));
    let _e1207 = param_502;
    transmission_bsdf_out_1 = _e1207;
    sheen_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1208 = closureData_15;
    param_503 = _e1208;
    let _e1209 = (*sheen);
    param_504 = _e1209;
    let _e1210 = (*sheen_color);
    param_505 = _e1210;
    let _e1211 = (*sheen_roughness);
    param_506 = _e1211;
    let _e1212 = (*normal);
    param_507 = _e1212;
    param_508 = 0i;
    let _e1213 = sheen_bsdf_out_1;
    param_509 = _e1213;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_503), (&param_504), (&param_505), (&param_506), (&param_507), (&param_508), (&param_509));
    let _e1214 = param_509;
    sheen_bsdf_out_1 = _e1214;
    translucent_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1215 = closureData_15;
    param_510 = _e1215;
    let _e1216 = selected_subsurface_bsdf_fg_weight_out;
    param_511 = _e1216;
    let _e1217 = coat_affected_subsurface_color_out;
    param_512 = _e1217;
    let _e1218 = (*normal);
    param_513 = _e1218;
    let _e1219 = translucent_bsdf_out_1;
    param_514 = _e1219;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_510), (&param_511), (&param_512), (&param_513), (&param_514));
    let _e1220 = param_514;
    translucent_bsdf_out_1 = _e1220;
    subsurface_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1221 = closureData_15;
    param_515 = _e1221;
    let _e1222 = selected_subsurface_bsdf_bg_weight_out;
    param_516 = _e1222;
    let _e1223 = coat_affected_subsurface_color_out;
    param_517 = _e1223;
    let _e1224 = subsurface_radius_scaled_out;
    param_518 = _e1224;
    let _e1225 = (*subsurface_anisotropy);
    param_519 = _e1225;
    let _e1226 = (*normal);
    param_520 = _e1226;
    let _e1227 = subsurface_bsdf_out_1;
    param_521 = _e1227;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_515), (&param_516), (&param_517), (&param_518), (&param_519), (&param_520), (&param_521));
    let _e1228 = param_521;
    subsurface_bsdf_out_1 = _e1228;
    selected_subsurface_bsdf_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1229 = closureData_15;
    param_522 = _e1229;
    let _e1230 = translucent_bsdf_out_1;
    param_523 = _e1230;
    let _e1231 = subsurface_bsdf_out_1;
    param_524 = _e1231;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_522), (&param_523), (&param_524), (&param_525));
    let _e1232 = param_525;
    selected_subsurface_bsdf_add_out_1 = _e1232;
    subsurface_mix_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1233 = closureData_15;
    param_526 = _e1233;
    let _e1234 = selected_subsurface_bsdf_add_out_1;
    param_527 = _e1234;
    let _e1235 = (*subsurface);
    param_528 = _e1235;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_526), (&param_527), (&param_528), (&param_529));
    let _e1236 = param_529;
    subsurface_mix_fg_mul_out_1 = _e1236;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1237 = closureData_15;
    param_530 = _e1237;
    let _e1238 = subsurface_mix_bg_weight_out;
    param_531 = _e1238;
    let _e1239 = coat_affected_diffuse_color_out;
    param_532 = _e1239;
    let _e1240 = (*diffuse_roughness);
    param_533 = _e1240;
    let _e1241 = (*normal);
    param_534 = _e1241;
    param_535 = false;
    let _e1242 = diffuse_bsdf_out_1;
    param_536 = _e1242;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_530), (&param_531), (&param_532), (&param_533), (&param_534), (&param_535), (&param_536));
    let _e1243 = param_536;
    diffuse_bsdf_out_1 = _e1243;
    subsurface_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1244 = closureData_15;
    param_537 = _e1244;
    let _e1245 = subsurface_mix_fg_mul_out_1;
    param_538 = _e1245;
    let _e1246 = diffuse_bsdf_out_1;
    param_539 = _e1246;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_537), (&param_538), (&param_539), (&param_540));
    let _e1247 = param_540;
    subsurface_mix_add_out_1 = _e1247;
    sheen_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1248 = closureData_15;
    param_541 = _e1248;
    let _e1249 = sheen_bsdf_out_1;
    param_542 = _e1249;
    let _e1250 = subsurface_mix_add_out_1;
    param_543 = _e1250;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_541), (&param_542), (&param_543), (&param_544));
    let _e1251 = param_544;
    sheen_layer_out_1 = _e1251;
    transmission_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1252 = closureData_15;
    param_545 = _e1252;
    let _e1253 = sheen_layer_out_1;
    param_546 = _e1253;
    let _e1254 = transmission_mix_mix_inv_out;
    param_547 = _e1254;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_545), (&param_546), (&param_547), (&param_548));
    let _e1255 = param_548;
    transmission_mix_bg_mul_out_1 = _e1255;
    transmission_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1256 = closureData_15;
    param_549 = _e1256;
    let _e1257 = transmission_bsdf_out_1;
    param_550 = _e1257;
    let _e1258 = transmission_mix_bg_mul_out_1;
    param_551 = _e1258;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_549), (&param_550), (&param_551), (&param_552));
    let _e1259 = param_552;
    transmission_mix_add_out_1 = _e1259;
    specular_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1260 = closureData_15;
    param_553 = _e1260;
    let _e1261 = specular_bsdf_out_1;
    param_554 = _e1261;
    let _e1262 = transmission_mix_add_out_1;
    param_555 = _e1262;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_553), (&param_554), (&param_555), (&param_556));
    let _e1263 = param_556;
    specular_layer_out_1 = _e1263;
    metalness_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1264 = closureData_15;
    param_557 = _e1264;
    let _e1265 = specular_layer_out_1;
    param_558 = _e1265;
    let _e1266 = metalness_mix_mix_inv_out;
    param_559 = _e1266;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_557), (&param_558), (&param_559), (&param_560));
    let _e1267 = param_560;
    metalness_mix_bg_mul_out_1 = _e1267;
    metalness_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1268 = closureData_15;
    param_561 = _e1268;
    let _e1269 = metal_bsdf_out_1;
    param_562 = _e1269;
    let _e1270 = metalness_mix_bg_mul_out_1;
    param_563 = _e1270;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_561), (&param_562), (&param_563), (&param_564));
    let _e1271 = param_564;
    metalness_mix_add_out_1 = _e1271;
    thin_film_layer_attenuated_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1272 = closureData_15;
    param_565 = _e1272;
    let _e1273 = metalness_mix_add_out_1;
    param_566 = _e1273;
    let _e1274 = coat_attenuation_out;
    param_567 = _e1274;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_565), (&param_566), (&param_567), (&param_568));
    let _e1275 = param_568;
    thin_film_layer_attenuated_out_1 = _e1275;
    coat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1276 = closureData_15;
    param_569 = _e1276;
    let _e1277 = coat_bsdf_out_1;
    param_570 = _e1277;
    let _e1278 = thin_film_layer_attenuated_out_1;
    param_571 = _e1278;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_569), (&param_570), (&param_571), (&param_572));
    let _e1279 = param_572;
    coat_layer_out_1 = _e1279;
    let _e1280 = occlusion_2;
    let _e1282 = coat_layer_out_1.response;
    let _e1285 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1285 + (_e1282 * _e1280));
    param_573 = 4i;
    let _e1288 = L_11;
    param_574 = _e1288;
    let _e1289 = V_14;
    param_575 = _e1289;
    let _e1290 = N_18;
    param_576 = _e1290;
    let _e1291 = P_3;
    param_577 = _e1291;
    let _e1292 = occlusion_2;
    param_578 = _e1292;
    let _e1293 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578));
    closureData_16 = _e1293;
    emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1294 = closureData_16;
    param_579 = _e1294;
    let _e1295 = emission_weight_out;
    param_580 = _e1295;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_579), (&param_580), (&param_581));
    let _e1296 = param_581;
    emission_edf_out = _e1296;
    coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1297 = closureData_16;
    param_582 = _e1297;
    let _e1298 = emission_edf_out;
    param_583 = _e1298;
    let _e1299 = (*coat_color);
    param_584 = _e1299;
    mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_582), (&param_583), (&param_584), (&param_585));
    let _e1300 = param_585;
    coat_tinted_emission_edf_out = _e1300;
    coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1301 = closureData_16;
    param_586 = _e1301;
    let _e1302 = emission_color0_out;
    param_587 = _e1302;
    param_588 = vec3<f32>(0f, 0f, 0f);
    param_589 = 5f;
    let _e1303 = coat_tinted_emission_edf_out;
    param_590 = _e1303;
    mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591));
    let _e1304 = param_591;
    coat_emission_edf_out = _e1304;
    blended_coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1305 = closureData_16;
    param_592 = _e1305;
    let _e1306 = coat_emission_edf_out;
    param_593 = _e1306;
    let _e1307 = emission_edf_out;
    param_594 = _e1307;
    let _e1308 = (*coat);
    param_595 = _e1308;
    mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_592), (&param_593), (&param_594), (&param_595), (&param_596));
    let _e1309 = param_596;
    blended_coat_emission_edf_out = _e1309;
    let _e1310 = blended_coat_emission_edf_out;
    let _e1312 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1312 + _e1310);
    param_597 = 2i;
    let _e1315 = L_11;
    param_598 = _e1315;
    let _e1316 = V_14;
    param_599 = _e1316;
    let _e1317 = N_18;
    param_600 = _e1317;
    let _e1318 = P_3;
    param_601 = _e1318;
    let _e1319 = occlusion_2;
    param_602 = _e1319;
    let _e1320 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_597), (&param_598), (&param_599), (&param_600), (&param_601), (&param_602));
    closureData_17 = _e1320;
    coat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1321 = closureData_17;
    param_603 = _e1321;
    let _e1322 = (*coat);
    param_604 = _e1322;
    param_605 = vec3<f32>(1f, 1f, 1f);
    let _e1323 = (*coat_IOR);
    param_606 = _e1323;
    let _e1324 = coat_roughness_vector_out;
    param_607 = _e1324;
    param_608 = false;
    param_609 = 0f;
    param_610 = 1.5f;
    let _e1325 = (*coat_normal);
    param_611 = _e1325;
    let _e1326 = coat_tangent_out;
    param_612 = _e1326;
    param_613 = 0i;
    param_614 = 0i;
    let _e1327 = coat_bsdf_out_2;
    param_615 = _e1327;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615));
    let _e1328 = param_615;
    coat_bsdf_out_2 = _e1328;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1329 = closureData_17;
    param_616 = _e1329;
    let _e1330 = metalness_mix_fg_weight_out;
    param_617 = _e1330;
    let _e1331 = artistic_ior_ior;
    param_618 = _e1331;
    let _e1332 = artistic_ior_extinction;
    param_619 = _e1332;
    let _e1333 = main_roughness_out;
    param_620 = _e1333;
    param_621 = false;
    let _e1334 = (*thin_film_thickness);
    param_622 = _e1334;
    let _e1335 = (*thin_film_IOR);
    param_623 = _e1335;
    let _e1336 = (*normal);
    param_624 = _e1336;
    let _e1337 = main_tangent_out;
    param_625 = _e1337;
    param_626 = 0i;
    let _e1338 = metal_bsdf_out_2;
    param_627 = _e1338;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621), (&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627));
    let _e1339 = param_627;
    metal_bsdf_out_2 = _e1339;
    specular_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1340 = closureData_17;
    param_628 = _e1340;
    let _e1341 = (*specular);
    param_629 = _e1341;
    let _e1342 = (*specular_color);
    param_630 = _e1342;
    let _e1343 = (*specular_IOR);
    param_631 = _e1343;
    let _e1344 = main_roughness_out;
    param_632 = _e1344;
    param_633 = false;
    let _e1345 = (*thin_film_thickness);
    param_634 = _e1345;
    let _e1346 = (*thin_film_IOR);
    param_635 = _e1346;
    let _e1347 = (*normal);
    param_636 = _e1347;
    let _e1348 = main_tangent_out;
    param_637 = _e1348;
    param_638 = 0i;
    param_639 = 0i;
    let _e1349 = specular_bsdf_out_2;
    param_640 = _e1349;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_628), (&param_629), (&param_630), (&param_631), (&param_632), (&param_633), (&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640));
    let _e1350 = param_640;
    specular_bsdf_out_2 = _e1350;
    transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1351 = closureData_17;
    param_641 = _e1351;
    let _e1352 = transmission_mix_fg_weight_out;
    param_642 = _e1352;
    let _e1353 = (*transmission_color);
    param_643 = _e1353;
    let _e1354 = (*specular_IOR);
    param_644 = _e1354;
    let _e1355 = transmission_roughness_out;
    param_645 = _e1355;
    param_646 = false;
    param_647 = 0f;
    param_648 = 1.5f;
    let _e1356 = (*normal);
    param_649 = _e1356;
    let _e1357 = main_tangent_out;
    param_650 = _e1357;
    param_651 = 0i;
    param_652 = 1i;
    let _e1358 = transmission_bsdf_out_2;
    param_653 = _e1358;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_641), (&param_642), (&param_643), (&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650), (&param_651), (&param_652), (&param_653));
    let _e1359 = param_653;
    transmission_bsdf_out_2 = _e1359;
    sheen_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1360 = closureData_17;
    param_654 = _e1360;
    let _e1361 = (*sheen);
    param_655 = _e1361;
    let _e1362 = (*sheen_color);
    param_656 = _e1362;
    let _e1363 = (*sheen_roughness);
    param_657 = _e1363;
    let _e1364 = (*normal);
    param_658 = _e1364;
    param_659 = 0i;
    let _e1365 = sheen_bsdf_out_2;
    param_660 = _e1365;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_654), (&param_655), (&param_656), (&param_657), (&param_658), (&param_659), (&param_660));
    let _e1366 = param_660;
    sheen_bsdf_out_2 = _e1366;
    translucent_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1367 = closureData_17;
    param_661 = _e1367;
    let _e1368 = selected_subsurface_bsdf_fg_weight_out;
    param_662 = _e1368;
    let _e1369 = coat_affected_subsurface_color_out;
    param_663 = _e1369;
    let _e1370 = (*normal);
    param_664 = _e1370;
    let _e1371 = translucent_bsdf_out_2;
    param_665 = _e1371;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_661), (&param_662), (&param_663), (&param_664), (&param_665));
    let _e1372 = param_665;
    translucent_bsdf_out_2 = _e1372;
    subsurface_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1373 = closureData_17;
    param_666 = _e1373;
    let _e1374 = selected_subsurface_bsdf_bg_weight_out;
    param_667 = _e1374;
    let _e1375 = coat_affected_subsurface_color_out;
    param_668 = _e1375;
    let _e1376 = subsurface_radius_scaled_out;
    param_669 = _e1376;
    let _e1377 = (*subsurface_anisotropy);
    param_670 = _e1377;
    let _e1378 = (*normal);
    param_671 = _e1378;
    let _e1379 = subsurface_bsdf_out_2;
    param_672 = _e1379;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_666), (&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672));
    let _e1380 = param_672;
    subsurface_bsdf_out_2 = _e1380;
    selected_subsurface_bsdf_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1381 = closureData_17;
    param_673 = _e1381;
    let _e1382 = translucent_bsdf_out_2;
    param_674 = _e1382;
    let _e1383 = subsurface_bsdf_out_2;
    param_675 = _e1383;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_673), (&param_674), (&param_675), (&param_676));
    let _e1384 = param_676;
    selected_subsurface_bsdf_add_out_2 = _e1384;
    subsurface_mix_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1385 = closureData_17;
    param_677 = _e1385;
    let _e1386 = selected_subsurface_bsdf_add_out_2;
    param_678 = _e1386;
    let _e1387 = (*subsurface);
    param_679 = _e1387;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_677), (&param_678), (&param_679), (&param_680));
    let _e1388 = param_680;
    subsurface_mix_fg_mul_out_2 = _e1388;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1389 = closureData_17;
    param_681 = _e1389;
    let _e1390 = subsurface_mix_bg_weight_out;
    param_682 = _e1390;
    let _e1391 = coat_affected_diffuse_color_out;
    param_683 = _e1391;
    let _e1392 = (*diffuse_roughness);
    param_684 = _e1392;
    let _e1393 = (*normal);
    param_685 = _e1393;
    param_686 = false;
    let _e1394 = diffuse_bsdf_out_2;
    param_687 = _e1394;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_681), (&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687));
    let _e1395 = param_687;
    diffuse_bsdf_out_2 = _e1395;
    subsurface_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1396 = closureData_17;
    param_688 = _e1396;
    let _e1397 = subsurface_mix_fg_mul_out_2;
    param_689 = _e1397;
    let _e1398 = diffuse_bsdf_out_2;
    param_690 = _e1398;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_688), (&param_689), (&param_690), (&param_691));
    let _e1399 = param_691;
    subsurface_mix_add_out_2 = _e1399;
    sheen_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1400 = closureData_17;
    param_692 = _e1400;
    let _e1401 = sheen_bsdf_out_2;
    param_693 = _e1401;
    let _e1402 = subsurface_mix_add_out_2;
    param_694 = _e1402;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_692), (&param_693), (&param_694), (&param_695));
    let _e1403 = param_695;
    sheen_layer_out_2 = _e1403;
    transmission_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1404 = closureData_17;
    param_696 = _e1404;
    let _e1405 = sheen_layer_out_2;
    param_697 = _e1405;
    let _e1406 = transmission_mix_mix_inv_out;
    param_698 = _e1406;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_696), (&param_697), (&param_698), (&param_699));
    let _e1407 = param_699;
    transmission_mix_bg_mul_out_2 = _e1407;
    transmission_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1408 = closureData_17;
    param_700 = _e1408;
    let _e1409 = transmission_bsdf_out_2;
    param_701 = _e1409;
    let _e1410 = transmission_mix_bg_mul_out_2;
    param_702 = _e1410;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_700), (&param_701), (&param_702), (&param_703));
    let _e1411 = param_703;
    transmission_mix_add_out_2 = _e1411;
    specular_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1412 = closureData_17;
    param_704 = _e1412;
    let _e1413 = specular_bsdf_out_2;
    param_705 = _e1413;
    let _e1414 = transmission_mix_add_out_2;
    param_706 = _e1414;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_704), (&param_705), (&param_706), (&param_707));
    let _e1415 = param_707;
    specular_layer_out_2 = _e1415;
    metalness_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1416 = closureData_17;
    param_708 = _e1416;
    let _e1417 = specular_layer_out_2;
    param_709 = _e1417;
    let _e1418 = metalness_mix_mix_inv_out;
    param_710 = _e1418;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_708), (&param_709), (&param_710), (&param_711));
    let _e1419 = param_711;
    metalness_mix_bg_mul_out_2 = _e1419;
    metalness_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1420 = closureData_17;
    param_712 = _e1420;
    let _e1421 = metal_bsdf_out_2;
    param_713 = _e1421;
    let _e1422 = metalness_mix_bg_mul_out_2;
    param_714 = _e1422;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_712), (&param_713), (&param_714), (&param_715));
    let _e1423 = param_715;
    metalness_mix_add_out_2 = _e1423;
    thin_film_layer_attenuated_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1424 = closureData_17;
    param_716 = _e1424;
    let _e1425 = metalness_mix_add_out_2;
    param_717 = _e1425;
    let _e1426 = coat_attenuation_out;
    param_718 = _e1426;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_716), (&param_717), (&param_718), (&param_719));
    let _e1427 = param_719;
    thin_film_layer_attenuated_out_2 = _e1427;
    coat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1428 = closureData_17;
    param_720 = _e1428;
    let _e1429 = coat_bsdf_out_2;
    param_721 = _e1429;
    let _e1430 = thin_film_layer_attenuated_out_2;
    param_722 = _e1430;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_720), (&param_721), (&param_722), (&param_723));
    let _e1431 = param_723;
    coat_layer_out_2 = _e1431;
    let _e1433 = coat_layer_out_2.response;
    let _e1435 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1435 + _e1433);
    let _e1438 = surfaceOpacity;
    let _e1440 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1440 * _e1438);
    let _e1444 = shader_constructor_out.transparency;
    let _e1445 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e1444, vec3(_e1445));
    let _e1449 = shader_constructor_out;
    (*mtlxRasterOut_1) = _e1449;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_chrome_out: surfaceshader;
    var param_724: f32;
    var param_725: vec3<f32>;
    var param_726: f32;
    var param_727: f32;
    var param_728: f32;
    var param_729: vec3<f32>;
    var param_730: f32;
    var param_731: f32;
    var param_732: f32;
    var param_733: f32;
    var param_734: f32;
    var param_735: vec3<f32>;
    var param_736: f32;
    var param_737: vec3<f32>;
    var param_738: f32;
    var param_739: f32;
    var param_740: f32;
    var param_741: f32;
    var param_742: vec3<f32>;
    var param_743: vec3<f32>;
    var param_744: f32;
    var param_745: f32;
    var param_746: f32;
    var param_747: vec3<f32>;
    var param_748: f32;
    var param_749: f32;
    var param_750: vec3<f32>;
    var param_751: f32;
    var param_752: f32;
    var param_753: f32;
    var param_754: f32;
    var param_755: vec3<f32>;
    var param_756: f32;
    var param_757: f32;
    var param_758: f32;
    var param_759: f32;
    var param_760: f32;
    var param_761: vec3<f32>;
    var param_762: vec3<f32>;
    var param_763: bool;
    var param_764: vec3<f32>;
    var param_765: vec3<f32>;
    var param_766: surfaceshader;

    let _e325 = normalWorld;
    geomprop_Nworld_out = normalize(_e325);
    let _e327 = tangentWorld;
    geomprop_Tworld_out = normalize(_e327);
    SR_chrome_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e329 = base_3;
    param_724 = _e329;
    let _e330 = base_color_1;
    param_725 = _e330;
    let _e331 = diffuse_roughness_1;
    param_726 = _e331;
    let _e332 = metalness_1;
    param_727 = _e332;
    let _e333 = specular_1;
    param_728 = _e333;
    let _e334 = specular_color_1;
    param_729 = _e334;
    let _e335 = specular_roughness_1;
    param_730 = _e335;
    let _e336 = specular_IOR_1;
    param_731 = _e336;
    let _e337 = specular_anisotropy_1;
    param_732 = _e337;
    let _e338 = specular_rotation_1;
    param_733 = _e338;
    let _e339 = transmission_1;
    param_734 = _e339;
    let _e340 = transmission_color_1;
    param_735 = _e340;
    let _e341 = transmission_depth_1;
    param_736 = _e341;
    let _e342 = transmission_scatter_1;
    param_737 = _e342;
    let _e343 = transmission_scatter_anisotropy_1;
    param_738 = _e343;
    let _e344 = transmission_dispersion_1;
    param_739 = _e344;
    let _e345 = transmission_extra_roughness_1;
    param_740 = _e345;
    let _e346 = subsurface_1;
    param_741 = _e346;
    let _e347 = subsurface_color_1;
    param_742 = _e347;
    let _e348 = subsurface_radius_1;
    param_743 = _e348;
    let _e349 = subsurface_scale_1;
    param_744 = _e349;
    let _e350 = subsurface_anisotropy_1;
    param_745 = _e350;
    let _e351 = sheen_1;
    param_746 = _e351;
    let _e352 = sheen_color_1;
    param_747 = _e352;
    let _e353 = sheen_roughness_1;
    param_748 = _e353;
    let _e354 = coat_1;
    param_749 = _e354;
    let _e355 = coat_color_1;
    param_750 = _e355;
    let _e356 = coat_roughness_1;
    param_751 = _e356;
    let _e357 = coat_anisotropy_1;
    param_752 = _e357;
    let _e358 = coat_rotation_1;
    param_753 = _e358;
    let _e359 = coat_IOR_1;
    param_754 = _e359;
    let _e360 = geomprop_Nworld_out;
    param_755 = _e360;
    let _e361 = coat_affect_color_1;
    param_756 = _e361;
    let _e362 = coat_affect_roughness_1;
    param_757 = _e362;
    let _e363 = thin_film_thickness_1;
    param_758 = _e363;
    let _e364 = thin_film_IOR_1;
    param_759 = _e364;
    let _e365 = emission_1;
    param_760 = _e365;
    let _e366 = emission_color_1;
    param_761 = _e366;
    let _e367 = opacity_1;
    param_762 = _e367;
    let _e368 = thin_walled_1;
    param_763 = _e368;
    let _e369 = geomprop_Nworld_out;
    param_764 = _e369;
    let _e370 = geomprop_Tworld_out;
    param_765 = _e370;
    NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_724), (&param_725), (&param_726), (&param_727), (&param_728), (&param_729), (&param_730), (&param_731), (&param_732), (&param_733), (&param_734), (&param_735), (&param_736), (&param_737), (&param_738), (&param_739), (&param_740), (&param_741), (&param_742), (&param_743), (&param_744), (&param_745), (&param_746), (&param_747), (&param_748), (&param_749), (&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765), (&param_766));
    let _e371 = param_766;
    SR_chrome_out = _e371;
    let _e373 = SR_chrome_out.color;
    mtlxRasterOut_2 = vec4<f32>(_e373.x, _e373.y, _e373.z, 1f);
    let _e378 = mtlxRasterOut_2;
    return _e378;
}

fn mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b(pW_1: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e283 = mtlxRasterMain_u0028_();
    return _e283.xyz;
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, rndSeed: ptr<function, u32>) {
    return;
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e281 = (*vWorld);
    let _e283 = (*basis_2).tW;
    let _e285 = (*vWorld);
    let _e287 = (*basis_2).bW;
    let _e289 = (*vWorld);
    let _e291 = (*basis_2).nW;
    return vec3<f32>(dot(_e281, _e283), dot(_e285, _e287), dot(_e289, _e291));
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e281 = (*N_19);
    l = length(_e281);
    let _e283 = (*N_19);
    let _e284 = l;
    return (_e283 / vec3(max(_e284, 0.0000000001f)));
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, bW: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>) -> Basis {
    var basis_3: Basis;
    var param_767: vec3<f32>;
    var param_768: vec3<f32>;
    var param_769: vec3<f32>;

    let _e288 = (*nW);
    param_767 = _e288;
    let _e289 = safe_normalize_u0028_vf3_u003b((&param_767));
    basis_3.nW = _e289;
    let _e291 = (*tW);
    param_768 = _e291;
    let _e292 = safe_normalize_u0028_vf3_u003b((&param_768));
    basis_3.tW = _e292;
    let _e294 = (*bW);
    param_769 = _e294;
    let _e295 = safe_normalize_u0028_vf3_u003b((&param_769));
    basis_3.bW = _e295;
    let _e297 = (*baryCoord);
    basis_3.baryCoord = _e297;
    let _e299 = (*texCoord);
    basis_3.texCoord = _e299;
    let _e301 = basis_3;
    return _e301;
}

fn skyRadiance_u0028_vf3_u003b(woutputW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e282 = (*woutputW)[0u];
    let _e283 = (*woutputW);
    let _e284 = _e283.yz;
    let _e288 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e282, _e284.x, _e284.y), 0f);
    env = _e288;
    let _e289 = env;
    let _e292 = unnamed.skyPower;
    let _e295 = unnamed.skyColor;
    return ((_e289.xyz * _e292) * _e295);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max: f32;

    let _e282 = unnamed.sunAngularSize;
    theta_max = ((_e282 * 3.1415927f) / 180f);
    let _e285 = (*woutputW_1);
    let _e287 = unnamed.sunDir;
    let _e289 = theta_max;
    if (dot(_e285, _e287) < cos(_e289)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e293 = unnamed.sunPower;
    let _e295 = unnamed.sunColor;
    return (_e295 * _e293);
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_770: vec3<f32>;

    let _e283 = (*N_20)[2u];
    let _e286 = (*N_20)[0u];
    if (abs(_e283) < abs(_e286)) {
        let _e290 = (*N_20)[2u];
        let _e292 = (*N_20)[0u];
        T = vec3<f32>(_e290, 0f, -(_e292));
    } else {
        let _e296 = (*N_20)[2u];
        let _e298 = (*N_20)[1u];
        T = vec3<f32>(0f, _e296, -(_e298));
    }
    let _e301 = T;
    param_770 = _e301;
    let _e302 = safe_normalize_u0028_vf3_u003b((&param_770));
    T = _e302;
    let _e303 = T;
    return _e303;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e283 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e283).x;
    let _e286 = (*index);
    let _e287 = width;
    let _e295 = (*index);
    let _e296 = width;
    let _e299 = textureLoad(texture, vec2<i32>((_e286 - (i32(floor((f32(_e286) / f32(_e287)))) * _e287)), (_e295 / _e296)), 0i);
    return _e299;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_771: i32;
    var param_772: i32;
    var param_773: i32;

    let _e287 = (*barycoord)[0u];
    let _e289 = (*faceIndices)[0u];
    param_771 = bitcast<i32>(_e289);
    let _e291 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_771));
    let _e294 = (*barycoord)[1u];
    let _e296 = (*faceIndices)[1u];
    param_772 = bitcast<i32>(_e296);
    let _e298 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_772));
    let _e302 = (*barycoord)[2u];
    let _e304 = (*faceIndices)[2u];
    param_773 = bitcast<i32>(_e304);
    let _e306 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_773));
    return (((_e291 * _e287) + (_e298 * _e294)) + (_e306 * _e302));
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

    let _e291 = (*direction);
    inverseDirection = (vec3(1f) / _e291);
    let _e294 = (*minimum);
    let _e295 = (*origin);
    let _e297 = inverseDirection;
    t0_2 = ((_e294 - _e295) * _e297);
    let _e299 = (*maximum);
    let _e300 = (*origin);
    let _e302 = inverseDirection;
    t1_2 = ((_e299 - _e300) * _e302);
    let _e304 = t0_2;
    let _e305 = t1_2;
    entry = min(_e304, _e305);
    let _e307 = t0_2;
    let _e308 = t1_2;
    exit = max(_e307, _e308);
    let _e311 = entry[0u];
    let _e313 = entry[1u];
    let _e315 = entry[2u];
    nearDistance = max(_e311, max(_e313, _e315));
    let _e319 = exit[0u];
    let _e321 = exit[1u];
    let _e323 = exit[2u];
    farDistance = min(_e319, min(_e321, _e323));
    let _e326 = farDistance;
    let _e327 = nearDistance;
    if (_e326 >= max(_e327, 0f)) {
        let _e330 = nearDistance;
        local_11 = max(_e330, 0f);
    } else {
        local_11 = 100000000000000000000f;
    }
    let _e332 = local_11;
    return _e332;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist_2: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_774: i32;
    var maximum_1: vec4<f32>;
    var param_775: i32;
    var metadata: vec4<f32>;
    var param_776: i32;
    var param_777: vec3<f32>;
    var param_778: vec3<f32>;
    var param_779: vec3<f32>;
    var param_780: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_781: i32;
    var p0_: vec3<f32>;
    var param_782: i32;
    var p1_: vec3<f32>;
    var param_783: i32;
    var p2_: vec3<f32>;
    var param_784: i32;
    var edge0_: vec3<f32>;
    var edge1_: vec3<f32>;
    var pvec: vec3<f32>;
    var determinant_: f32;
    var inverseDeterminant: f32;
    var tvec: vec3<f32>;
    var u: f32;
    var qvec: vec3<f32>;
    var v_2: f32;
    var distance_: f32;
    var left: i32;
    var right: i32;
    var phi_1143_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e332 = (*maxDistance);
    closest = _e332;
    found = false;
    loop {
        let _e333 = pointer;
        let _e335 = pointer;
        if ((_e333 >= 0i) && (_e335 < 64i)) {
            let _e338 = pointer;
            pointer = (_e338 - 1i);
            let _e341 = stack[_e338];
            nodeIndex = _e341;
            let _e342 = nodeIndex;
            param_774 = (_e342 * 3i);
            let _e344 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_774));
            minimum_1 = _e344;
            let _e345 = nodeIndex;
            param_775 = ((_e345 * 3i) + 1i);
            let _e348 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_775));
            maximum_1 = _e348;
            let _e349 = nodeIndex;
            param_776 = ((_e349 * 3i) + 2i);
            let _e352 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_776));
            metadata = _e352;
            let _e353 = minimum_1;
            param_777 = _e353.xyz;
            let _e355 = maximum_1;
            param_778 = _e355.xyz;
            let _e357 = (*rayOrigin);
            param_779 = _e357;
            let _e358 = (*rayDirection);
            param_780 = _e358;
            let _e359 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_777), (&param_778), (&param_779), (&param_780));
            let _e360 = closest;
            if (_e359 > _e360) {
                continue;
            }
            let _e363 = metadata[2u];
            if (_e363 > 0.5f) {
                let _e366 = metadata[0u];
                offset = i32((_e366 + 0.5f));
                let _e370 = metadata[1u];
                count = i32((_e370 + 0.5f));
                triangle = 0i;
                loop {
                    let _e373 = triangle;
                    let _e374 = count;
                    if (_e373 < _e374) {
                        let _e376 = offset;
                        let _e377 = triangle;
                        param_781 = (_e376 + _e377);
                        let _e379 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_781));
                        vertexIndices = vec3<u32>((_e379.xyz + vec3(0.5f)));
                        let _e385 = vertexIndices[0u];
                        param_782 = bitcast<i32>(_e385);
                        let _e387 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_782));
                        p0_ = _e387.xyz;
                        let _e390 = vertexIndices[1u];
                        param_783 = bitcast<i32>(_e390);
                        let _e392 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_783));
                        p1_ = _e392.xyz;
                        let _e395 = vertexIndices[2u];
                        param_784 = bitcast<i32>(_e395);
                        let _e397 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_784));
                        p2_ = _e397.xyz;
                        let _e399 = p1_;
                        let _e400 = p0_;
                        edge0_ = (_e399 - _e400);
                        let _e402 = p2_;
                        let _e403 = p0_;
                        edge1_ = (_e402 - _e403);
                        let _e405 = (*rayDirection);
                        let _e406 = edge1_;
                        pvec = cross(_e405, _e406);
                        let _e408 = edge0_;
                        let _e409 = pvec;
                        determinant_ = dot(_e408, _e409);
                        let _e411 = determinant_;
                        if (abs(_e411) < 0.00000001f) {
                            continue;
                        }
                        let _e414 = determinant_;
                        inverseDeterminant = (1f / _e414);
                        let _e416 = (*rayOrigin);
                        let _e417 = p0_;
                        tvec = (_e416 - _e417);
                        let _e419 = tvec;
                        let _e420 = pvec;
                        let _e422 = inverseDeterminant;
                        u = (dot(_e419, _e420) * _e422);
                        let _e424 = tvec;
                        let _e425 = edge0_;
                        qvec = cross(_e424, _e425);
                        let _e427 = (*rayDirection);
                        let _e428 = qvec;
                        let _e430 = inverseDeterminant;
                        v_2 = (dot(_e427, _e428) * _e430);
                        let _e432 = edge1_;
                        let _e433 = qvec;
                        let _e435 = inverseDeterminant;
                        distance_ = (dot(_e432, _e433) * _e435);
                        let _e437 = u;
                        let _e439 = v_2;
                        let _e441 = ((_e437 >= 0f) && (_e439 >= 0f));
                        phi_1143_ = _e441;
                        if _e441 {
                            let _e442 = u;
                            let _e443 = v_2;
                            phi_1143_ = ((_e442 + _e443) <= 1f);
                        }
                        let _e447 = phi_1143_;
                        let _e448 = distance_;
                        let _e451 = distance_;
                        let _e452 = closest;
                        if ((_e447 && (_e448 > 0f)) && (_e451 < _e452)) {
                            let _e455 = distance_;
                            closest = _e455;
                            let _e456 = distance_;
                            (*dist_2) = _e456;
                            let _e457 = u;
                            let _e459 = v_2;
                            let _e461 = u;
                            let _e462 = v_2;
                            (*barycoord_1) = vec3<f32>(((1f - _e457) - _e459), _e461, _e462);
                            let _e464 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e464.x, _e464.y, _e464.z, 0u);
                            let _e469 = edge0_;
                            let _e470 = edge1_;
                            (*faceNormal) = normalize(cross(_e469, _e470));
                            let _e473 = determinant_;
                            (*side) = select(1f, -1f, (_e473 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e476 = triangle;
                        triangle = (_e476 + 1i);
                    }
                }
            } else {
                let _e479 = metadata[0u];
                left = i32((_e479 + 0.5f));
                let _e483 = metadata[1u];
                right = i32((_e483 + 0.5f));
                let _e486 = pointer;
                if ((_e486 + 2i) >= 64i) {
                    continue;
                }
                let _e489 = pointer;
                let _e490 = (_e489 + 1i);
                pointer = _e490;
                let _e491 = right;
                stack[_e490] = _e491;
                let _e493 = pointer;
                let _e494 = (_e493 + 1i);
                pointer = _e494;
                let _e495 = left;
                stack[_e494] = _e495;
            }
            continue;
        } else {
            break;
        }
    }
    let _e497 = found;
    return _e497;
}

fn bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1: texture_2d<f32>, nodesSampler_1: sampler, indices_1: texture_2d<f32>, indicesSampler_1: sampler, positions_1: texture_2d<f32>, positionsSampler_1: sampler, rayOrigin_1: ptr<function, vec3<f32>>, rayDirection_1: ptr<function, vec3<f32>>, maxDistance_1: ptr<function, f32>, faceIndices_2: ptr<function, vec4<u32>>, faceNormal_1: ptr<function, vec3<f32>>, barycoord_2: ptr<function, vec3<f32>>, side_1: ptr<function, f32>, dist_3: ptr<function, f32>) -> bool {
    var param_785: vec3<f32>;
    var param_786: vec3<f32>;
    var param_787: f32;
    var param_788: vec4<u32>;
    var param_789: vec3<f32>;
    var param_790: vec3<f32>;
    var param_791: f32;
    var param_792: f32;

    let _e301 = (*rayOrigin_1);
    param_785 = _e301;
    let _e302 = (*rayDirection_1);
    param_786 = _e302;
    let _e303 = (*maxDistance_1);
    param_787 = _e303;
    let _e304 = (*faceIndices_2);
    param_788 = _e304;
    let _e305 = (*faceNormal_1);
    param_789 = _e305;
    let _e306 = (*barycoord_2);
    param_790 = _e306;
    let _e307 = (*side_1);
    param_791 = _e307;
    let _e308 = (*dist_3);
    param_792 = _e308;
    let _e309 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_785), (&param_786), (&param_787), (&param_788), (&param_789), (&param_790), (&param_791), (&param_792));
    let _e310 = param_788;
    (*faceIndices_2) = _e310;
    let _e311 = param_789;
    (*faceNormal_1) = _e311;
    let _e312 = param_790;
    (*barycoord_2) = _e312;
    let _e313 = param_791;
    (*side_1) = _e313;
    let _e314 = param_792;
    (*dist_3) = _e314;
    return _e309;
}

fn trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b(rayOrigin_2: ptr<function, vec3<f32>>, rayDir: ptr<function, vec3<f32>>, maxDistance_2: ptr<function, f32>, P_4: ptr<function, vec3<f32>>, Ns: ptr<function, vec3<f32>>, Ng: ptr<function, vec3<f32>>, Ts: ptr<function, vec3<f32>>, Bs: ptr<function, vec3<f32>>, baryCoord_1: ptr<function, vec3<f32>>, texCoord_1: ptr<function, vec2<f32>>, material: ptr<function, i32>) -> bool {
    var faceIndices_surface: vec4<u32>;
    var faceNormal_surface: vec3<f32>;
    var barycoord_surface: vec3<f32>;
    var side_surface: f32;
    var dist_surface: f32;
    var hit_surface: bool;
    var param_793: vec3<f32>;
    var param_794: vec3<f32>;
    var param_795: f32;
    var param_796: vec4<u32>;
    var param_797: vec3<f32>;
    var param_798: vec3<f32>;
    var param_799: f32;
    var param_800: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_801: vec3<f32>;
    var gN: vec4<f32>;
    var param_802: vec3<f32>;
    var param_803: vec3<u32>;
    var gT: vec4<f32>;
    var param_804: vec3<f32>;
    var param_805: vec3<u32>;
    var gS: vec4<f32>;
    var param_806: vec3<f32>;
    var param_807: vec3<u32>;
    var local_12: vec3<f32>;
    var local_13: vec2<f32>;
    var local_14: vec3<f32>;
    var param_808: vec3<f32>;
    var param_809: vec3<f32>;
    var param_810: vec3<f32>;
    var phi_1394_: bool;
    var phi_1416_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e325 = (*rayOrigin_2);
    param_793 = _e325;
    let _e326 = (*rayDir);
    param_794 = _e326;
    let _e327 = (*maxDistance_2);
    param_795 = _e327;
    let _e328 = faceIndices_surface;
    param_796 = _e328;
    let _e329 = faceNormal_surface;
    param_797 = _e329;
    let _e330 = barycoord_surface;
    param_798 = _e330;
    let _e331 = side_surface;
    param_799 = _e331;
    let _e332 = dist_surface;
    param_800 = _e332;
    let _e333 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_793), (&param_794), (&param_795), (&param_796), (&param_797), (&param_798), (&param_799), (&param_800));
    let _e334 = param_796;
    faceIndices_surface = _e334;
    let _e335 = param_797;
    faceNormal_surface = _e335;
    let _e336 = param_798;
    barycoord_surface = _e336;
    let _e337 = param_799;
    side_surface = _e337;
    let _e338 = param_800;
    dist_surface = _e338;
    hit_surface = _e333;
    dist_closest = 100000000000000000000f;
    let _e339 = hit_surface;
    if _e339 {
        let _e340 = dist_closest;
        let _e341 = dist_surface;
        dist_closest = min(_e340, _e341);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e344 = (*rayDir)[1u];
    if (abs(_e344) > 0.0000000001f) {
        let _e348 = (*rayOrigin_2)[1u];
        let _e351 = (*rayDir)[1u];
        t = ((0.01f - _e348) / _e351);
        let _e353 = t;
        let _e354 = (_e353 > 0f);
        phi_1394_ = _e354;
        if _e354 {
            let _e355 = t;
            let _e356 = dist_closest;
            let _e357 = (*maxDistance_2);
            phi_1394_ = (_e355 < min(_e356, _e357));
        }
        let _e361 = phi_1394_;
        if _e361 {
            let _e362 = t;
            dist_ground = _e362;
            hit_ground = true;
        }
    }
    let _e363 = hit_surface;
    let _e364 = hit_ground;
    hit = (_e363 || _e364);
    let _e366 = hit;
    if !(_e366) {
        return false;
    }
    let _e368 = hit_surface;
    phi_1416_ = _e368;
    if _e368 {
        let _e369 = hit_ground;
        let _e371 = dist_surface;
        let _e372 = dist_ground;
        phi_1416_ = (!(_e369) || (_e371 <= _e372));
    }
    let _e376 = phi_1416_;
    if _e376 {
        let _e377 = (*rayOrigin_2);
        let _e378 = dist_surface;
        let _e379 = (*rayDir);
        (*P_4) = (_e377 + (_e379 * _e378));
        let _e382 = barycoord_surface;
        (*baryCoord_1) = _e382;
        let _e383 = faceNormal_surface;
        param_801 = _e383;
        let _e384 = safe_normalize_u0028_vf3_u003b((&param_801));
        (*Ng) = _e384;
        let _e385 = barycoord_surface;
        param_802 = _e385;
        let _e386 = faceIndices_surface;
        param_803 = _e386.xyz;
        let _e388 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_802), (&param_803));
        gN = _e388;
        let _e389 = barycoord_surface;
        param_804 = _e389;
        let _e390 = faceIndices_surface;
        param_805 = _e390.xyz;
        let _e392 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_804), (&param_805));
        gT = _e392;
        let _e393 = barycoord_surface;
        param_806 = _e393;
        let _e394 = faceIndices_surface;
        param_807 = _e394.xyz;
        let _e396 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_806), (&param_807));
        gS = _e396;
        let _e398 = unnamed.has_normals_surface;
        if (_e398 != 0u) {
            let _e400 = gN;
            local_12 = _e400.xyz;
        } else {
            let _e402 = (*Ng);
            local_12 = _e402;
        }
        let _e403 = local_12;
        (*Ns) = _e403;
        let _e405 = unnamed.has_uvs_surface;
        if (_e405 != 0u) {
            let _e408 = gN[3u];
            let _e410 = gT[3u];
            local_13 = vec2<f32>(_e408, _e410);
        } else {
            let _e412 = barycoord_surface;
            local_13 = _e412.xy;
        }
        let _e414 = local_13;
        (*texCoord_1) = _e414;
        let _e416 = unnamed.has_tangents_surface;
        if (_e416 != 0u) {
            let _e418 = gT;
            local_14 = _e418.xyz;
        } else {
            let _e420 = (*Ns);
            param_808 = _e420;
            let _e421 = normalToTangent_u0028_vf3_u003b((&param_808));
            local_14 = _e421;
        }
        let _e422 = local_14;
        (*Ts) = _e422;
        let _e423 = (*Ns);
        param_809 = _e423;
        let _e424 = safe_normalize_u0028_vf3_u003b((&param_809));
        let _e425 = (*Ts);
        param_810 = _e425;
        let _e426 = safe_normalize_u0028_vf3_u003b((&param_810));
        (*Bs) = cross(_e424, _e426);
        let _e429 = gS[0u];
        (*material) = select(1i, 0i, (_e429 > 0.5f));
    } else {
        let _e432 = hit_ground;
        if _e432 {
            let _e433 = (*rayOrigin_2);
            let _e434 = dist_ground;
            let _e435 = (*rayDir);
            (*P_4) = (_e433 + (_e435 * _e434));
            (*material) = 2i;
            (*baryCoord_1) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e438 = (*Ng);
            (*Ns) = _e438;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            (*Bs) = vec3<f32>(0f, 0f, -1f);
            let _e440 = (*P_4)[0u];
            let _e442 = (*P_4)[2u];
            (*texCoord_1) = (((vec2<f32>(_e440, -(_e442)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_4: Basis;
    var param_811: vec3<f32>;
    var param_812: vec3<f32>;

    let _e283 = (*nW_1);
    param_811 = _e283;
    let _e284 = safe_normalize_u0028_vf3_u003b((&param_811));
    basis_4.nW = _e284;
    let _e286 = (*nW_1);
    param_812 = _e286;
    let _e287 = normalToTangent_u0028_vf3_u003b((&param_812));
    basis_4.tW = _e287;
    let _e290 = basis_4.nW;
    let _e292 = basis_4.tW;
    basis_4.bW = cross(_e290, _e292);
    basis_4.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_4.texCoord = vec2<f32>(0f, 0f);
    let _e297 = basis_4;
    return _e297;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_3: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e289 = (*cameraWorld);
    lookDirection = (_e289 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e291 = (*inverseProjection);
    nearVector = (_e291 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e294 = nearVector[2u];
    let _e296 = nearVector[3u];
    nearDistance_1 = abs((_e294 / _e296));
    let _e299 = (*cameraWorld);
    origin_1 = (_e299 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e301 = (*inverseProjection);
    let _e302 = (*coordinate);
    direction_1 = (_e301 * vec4<f32>(_e302.x, _e302.y, 0.5f, 1f));
    let _e308 = direction_1[3u];
    let _e309 = direction_1;
    direction_1 = (_e309 / vec4(_e308));
    let _e312 = (*cameraWorld);
    let _e313 = direction_1;
    let _e315 = origin_1;
    direction_1 = ((_e312 * _e313) - _e315);
    let _e317 = direction_1;
    let _e319 = nearDistance_1;
    let _e321 = direction_1;
    let _e322 = lookDirection;
    let _e326 = origin_1;
    let _e328 = (_e326.xyz + ((_e317.xyz * _e319) / vec3(dot(_e321, _e322))));
    origin_1[0u] = _e328.x;
    origin_1[1u] = _e328.y;
    origin_1[2u] = _e328.z;
    let _e335 = origin_1;
    (*rayOrigin_3) = _e335.xyz;
    let _e337 = direction_1;
    (*rayDirection_2) = _e337.xyz;
    return;
}

fn main_1() {
    var pixel: vec2<f32>;
    var ndc: vec2<f32>;
    var pW_3: vec3<f32>;
    var dW: vec3<f32>;
    var param_813: vec2<f32>;
    var param_814: mat4x4<f32>;
    var param_815: mat4x4<f32>;
    var param_816: vec3<f32>;
    var param_817: vec3<f32>;
    var param_818: vec3<f32>;
    var surface_hit: bool;
    var pW_hit: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW: vec3<f32>;
    var BsW: vec3<f32>;
    var baryCoord_2: vec3<f32>;
    var texCoord_2: vec2<f32>;
    var material_1: i32;
    var param_819: vec3<f32>;
    var param_820: vec3<f32>;
    var param_821: f32;
    var param_822: vec3<f32>;
    var param_823: vec3<f32>;
    var param_824: vec3<f32>;
    var param_825: vec3<f32>;
    var param_826: vec3<f32>;
    var param_827: vec3<f32>;
    var param_828: vec2<f32>;
    var param_829: i32;
    var param_830: vec3<f32>;
    var param_831: vec3<f32>;
    var basis_5: Basis;
    var param_832: vec3<f32>;
    var param_833: vec3<f32>;
    var param_834: vec3<f32>;
    var param_835: vec3<f32>;
    var param_836: vec2<f32>;
    var param_837: vec3<f32>;
    var param_838: vec3<f32>;
    var param_839: vec3<f32>;
    var param_840: vec3<f32>;
    var param_841: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_2: vec3<f32>;
    var param_842: vec3<f32>;
    var param_843: Basis;
    var rndSeed_1: u32;
    var param_844: vec3<f32>;
    var param_845: Basis;
    var param_846: vec3<f32>;
    var param_847: u32;
    var viewReflectW: vec3<f32>;
    var viewReflectL: vec3<f32>;
    var param_848: vec3<f32>;
    var param_849: Basis;
    var L_12: vec3<f32>;
    var param_850: vec3<f32>;
    var param_851: Basis;
    var param_852: vec3<f32>;
    var param_853: vec3<f32>;
    var param_854: vec3<f32>;
    var param_855: vec3<f32>;

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
    thin_walled_1 = false;
    let _e342 = gl_FragCoord_1;
    pixel = (_e342.xy + vec2<f32>(0.5f, 0.5f));
    let _e345 = pixel;
    let _e347 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e345 / _e347) * 2f));
    let _e353 = unnamed.invModelMatrix;
    let _e355 = unnamed.cameraWorldMatrix;
    let _e357 = ndc;
    param_813 = _e357;
    param_814 = (_e353 * _e355);
    let _e359 = unnamed.invProjectionMatrix;
    param_815 = _e359;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
    let _e360 = param_816;
    pW_3 = _e360;
    let _e361 = param_817;
    dW = _e361;
    let _e362 = dW;
    dW = normalize(_e362);
    let _e365 = unnamed.sunDir;
    param_818 = _e365;
    let _e366 = makeBasis_u0028_vf3_u003b((&param_818));
    sunBasis = _e366;
    let _e367 = pW_3;
    param_819 = _e367;
    let _e368 = dW;
    param_820 = _e368;
    param_821 = 100000000000000000000f;
    let _e369 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825), (&param_826), (&param_827), (&param_828), (&param_829));
    let _e370 = param_822;
    pW_hit = _e370;
    let _e371 = param_823;
    NsW = _e371;
    let _e372 = param_824;
    NgW = _e372;
    let _e373 = param_825;
    TsW = _e373;
    let _e374 = param_826;
    BsW = _e374;
    let _e375 = param_827;
    baryCoord_2 = _e375;
    let _e376 = param_828;
    texCoord_2 = _e376;
    let _e377 = param_829;
    material_1 = _e377;
    surface_hit = _e369;
    let _e378 = surface_hit;
    if !(_e378) {
        let _e380 = dW;
        param_830 = _e380;
        let _e381 = sunRadiance_u0028_vf3_u003b((&param_830));
        let _e382 = dW;
        param_831 = _e382;
        let _e383 = skyRadiance_u0028_vf3_u003b((&param_831));
        let _e384 = (_e381 + _e383);
        mtlxFragmentColor[0u] = _e384.x;
        mtlxFragmentColor[1u] = _e384.y;
        mtlxFragmentColor[2u] = _e384.z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    let _e392 = NsW;
    let _e393 = dW;
    if (dot(_e392, _e393) > 0f) {
        let _e396 = NsW;
        NsW = (_e396 * -1f);
    }
    let _e398 = NgW;
    let _e399 = NsW;
    if (dot(_e398, _e399) < 0f) {
        let _e402 = NgW;
        NgW = (_e402 * -1f);
    }
    let _e405 = unnamed.smooth_normals;
    if (_e405 != 0u) {
        let _e407 = NsW;
        param_832 = _e407;
        let _e408 = TsW;
        param_833 = _e408;
        let _e409 = BsW;
        param_834 = _e409;
        let _e410 = baryCoord_2;
        param_835 = _e410;
        let _e411 = texCoord_2;
        param_836 = _e411;
        let _e412 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_832), (&param_833), (&param_834), (&param_835), (&param_836));
        basis_5 = _e412;
    } else {
        let _e413 = NgW;
        param_837 = _e413;
        let _e414 = TsW;
        param_838 = _e414;
        let _e415 = BsW;
        param_839 = _e415;
        let _e416 = baryCoord_2;
        param_840 = _e416;
        let _e417 = texCoord_2;
        param_841 = _e417;
        let _e418 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_837), (&param_838), (&param_839), (&param_840), (&param_841));
        basis_5 = _e418;
    }
    let _e419 = dW;
    winputW = -(_e419);
    let _e421 = winputW;
    param_842 = _e421;
    let _e422 = basis_5;
    param_843 = _e422;
    let _e423 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_842), (&param_843));
    winputL_2 = _e423;
    let _e425 = winputL_2[2u];
    if (abs(_e425) < 0.001f) {
        mtlxFragmentColor[0u] = vec3<f32>(0f, 0f, 0f).x;
        mtlxFragmentColor[1u] = vec3<f32>(0f, 0f, 0f).y;
        mtlxFragmentColor[2u] = vec3<f32>(0f, 0f, 0f).z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    rndSeed_1 = 0u;
    let _e435 = material_1;
    if (_e435 == 1i) {
        let _e437 = pW_hit;
        param_844 = _e437;
        let _e438 = basis_5;
        param_845 = _e438;
        let _e439 = winputL_2;
        param_846 = _e439;
        let _e440 = rndSeed_1;
        param_847 = _e440;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_844), (&param_845), (&param_846), (&param_847));
        let _e441 = param_847;
        rndSeed_1 = _e441;
    }
    let _e442 = dW;
    let _e444 = basis_5.nW;
    viewReflectW = reflect(_e442, _e444);
    let _e446 = viewReflectW;
    param_848 = _e446;
    let _e447 = basis_5;
    param_849 = _e447;
    let _e448 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_848), (&param_849));
    viewReflectL = _e448;
    let _e450 = viewReflectL[2u];
    if (_e450 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e452 = material_1;
    if (_e452 == 1i) {
        let _e454 = pW_hit;
        param_850 = _e454;
        let _e455 = basis_5;
        param_851 = _e455;
        let _e456 = winputL_2;
        param_852 = _e456;
        let _e457 = viewReflectL;
        param_853 = _e457;
        let _e458 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_850), (&param_851), (&param_852), (&param_853));
        L_12 = _e458;
    } else {
        let _e459 = material_1;
        if (_e459 == 2i) {
            let _e461 = pW_hit;
            param_854 = _e461;
            let _e462 = ground_albedo_u0028_vf3_u003b((&param_854));
            L_12 = _e462;
        } else {
            let _e464 = unnamed.neutral_color;
            let _e466 = basis_5.nW;
            param_855 = _e466;
            let _e467 = skyRadiance_u0028_vf3_u003b((&param_855));
            L_12 = (_e464 * _e467);
        }
    }
    let _e469 = L_12;
    let _e471 = unnamed.firefly_clamp;
    let _e473 = clamp(_e469, vec3<f32>(0f, 0f, 0f), vec3(_e471));
    mtlxFragmentColor[0u] = _e473.x;
    mtlxFragmentColor[1u] = _e473.y;
    mtlxFragmentColor[2u] = _e473.z;
    mtlxFragmentColor[3u] = 1f;
    return;
}

@fragment 
fn main(@builtin(position) gl_FragCoord: vec4<f32>, @location(139) vUv: vec2<f32>) -> @location(0) vec4<f32> {
    gl_FragCoord_1 = gl_FragCoord;
    vUv_1 = vUv;
    main_1();
    let _e5 = mtlxFragmentColor;
    return _e5;
}
