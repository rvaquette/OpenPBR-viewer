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

var<private> base_color_1: vec3<f32>;
var<private> metallic_1: f32;
var<private> roughness_18: f32;
var<private> occlusion_3: f32;
var<private> transmission_1: f32;
var<private> specular_1: f32;
var<private> specular_color_1: vec3<f32>;
var<private> ior_7: f32;
var<private> alpha_13: f32;
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

    let _e265 = (*pW)[0u];
    let _e267 = (*pW)[2u];
    uv = (((vec2<f32>(_e265, -(_e267)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e275 = uv;
    let _e276 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e275, 0.0);
    return _e276.xyz;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result: ptr<function, vec3<f32>>) {
    let _e266 = (*closureData).closureType;
    if (_e266 == 4i) {
        let _e268 = (*color);
        (*result) = _e268;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_1: ptr<function, ClosureData>, top: ptr<function, BSDF>, base: ptr<function, BSDF>, result_1: ptr<function, BSDF>) {
    let _e267 = (*top).response;
    let _e269 = (*base).response;
    let _e271 = (*top).throughput;
    (*result_1).response = (_e267 + (_e269 * _e271));
    let _e276 = (*top).throughput;
    let _e278 = (*base).throughput;
    (*result_1).throughput = (_e276 * _e278);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e266 = (*dir)[1u];
    latitude = ((-(asin(_e266)) * 0.31830987f) + 0.5f);
    let _e272 = (*dir)[0u];
    let _e274 = (*dir)[2u];
    longitude = (((atan2(_e272, -(_e274)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e280 = longitude;
    let _e281 = latitude;
    return vec2<f32>(_e280, _e281);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e264 = (*m);
    let _e265 = (*v);
    return (_e264 * _e265);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param: mat4x4<f32>;
    var param_1: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_2: vec3<f32>;

    let _e270 = (*dir_1);
    let _e275 = (*transform);
    param = _e275;
    param_1 = vec4<f32>(_e270.x, _e270.y, _e270.z, 0f);
    let _e276 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param), (&param_1));
    envDir = normalize(_e276.xyz);
    let _e279 = envDir;
    param_2 = _e279;
    let _e280 = mx_latlong_projection_u0028_vf3_u003b((&param_2));
    uv_1 = _e280;
    let _e281 = uv_1;
    let _e282 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e281, 0.0);
    return _e282.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e265 = a;
    c = cos(_e265);
    let _e267 = a;
    s = sin(_e267);
    let _e269 = c;
    let _e270 = s;
    let _e272 = s;
    let _e273 = c;
    return mat4x4<f32>(vec4<f32>(_e269, 0f, -(_e270), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e272, 0f, _e273, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_3: vec3<f32>;
    var param_4: mat4x4<f32>;
    var param_5: f32;

    let _e267 = mtlxEnvMatrix_u0028_();
    let _e268 = (*N);
    param_3 = _e268;
    param_4 = _e267;
    param_5 = 0f;
    let _e269 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_3), (&param_4), (&param_5));
    Li = _e269;
    let _e270 = Li;
    let _e272 = unnamed.skyPower;
    return (_e270 * _e272);
}

fn mx_square_u0028_f1_u003b(x: ptr<function, f32>) -> f32 {
    let _e263 = (*x);
    let _e264 = (*x);
    return (_e263 * _e264);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_6: f32;

    let _e266 = (*roughness);
    let _e269 = (*NdotV);
    let _e271 = (*roughness);
    let _e274 = (*roughness);
    param_6 = _e274;
    let _e275 = mx_square_u0028_f1_u003b((&param_6));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e266)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e269) * _e271)) + (vec2<f32>(1.4385f, 2.0315f) * _e275));
    let _e279 = r[0u];
    let _e281 = r[1u];
    return (_e279 / _e281);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_7: f32;
    var param_8: f32;

    let _e267 = (*NdotV_1);
    param_7 = _e267;
    let _e268 = (*roughness_1);
    param_8 = _e268;
    let _e269 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_7), (&param_8));
    dirAlbedo = _e269;
    let _e270 = dirAlbedo;
    return clamp(_e270, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e263 = (*x_1);
    let _e264 = (*x_1);
    return (_e263 * _e264);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e264 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e264)));
    let _e268 = A;
    let _e269 = (*roughness_2);
    return (_e268 * (1f + (0.07248821f * _e269)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_9: f32;
    var G: f32;

    let _e269 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e269)));
    let _e273 = (*roughness_3);
    let _e274 = A_1;
    B = (_e273 * _e274);
    let _e276 = (*cosTheta);
    param_9 = _e276;
    let _e277 = mx_square_u0028_f1_u003b((&param_9));
    Si = sqrt(max(0f, (1f - _e277)));
    let _e281 = Si;
    let _e282 = (*cosTheta);
    let _e285 = Si;
    let _e286 = (*cosTheta);
    let _e290 = Si;
    let _e291 = (*cosTheta);
    let _e293 = Si;
    let _e294 = Si;
    let _e296 = Si;
    let _e300 = Si;
    G = ((_e281 * (acos(clamp(_e282, -1f, 1f)) - (_e285 * _e286))) + ((2f * (((_e290 / _e291) * (1f - ((_e293 * _e294) * _e296))) - _e300)) / 3f));
    let _e305 = A_1;
    let _e306 = B;
    let _e307 = G;
    return (_e305 + ((_e306 * _e307) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_1: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_10: f32;
    var param_11: f32;
    var avgAlbedo: f32;
    var param_12: f32;
    var colorMultiScatter: vec3<f32>;
    var param_13: vec3<f32>;

    let _e272 = (*cosTheta_1);
    param_10 = _e272;
    let _e273 = (*roughness_4);
    param_11 = _e273;
    let _e274 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_10), (&param_11));
    dirAlbedo_1 = _e274;
    let _e275 = (*roughness_4);
    param_12 = _e275;
    let _e276 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_12));
    avgAlbedo = _e276;
    let _e277 = (*color_1);
    param_13 = _e277;
    let _e278 = mx_square_u0028_vf3_u003b((&param_13));
    let _e279 = avgAlbedo;
    let _e281 = (*color_1);
    let _e282 = avgAlbedo;
    colorMultiScatter = ((_e278 * _e279) / (vec3<f32>(1f, 1f, 1f) - (_e281 * max(0f, (1f - _e282)))));
    let _e288 = colorMultiScatter;
    let _e289 = (*color_1);
    let _e290 = dirAlbedo_1;
    return mix(_e288, _e289, vec3(_e290));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local: f32;
    var sigma2_: f32;
    var param_14: f32;
    var A_2: f32;
    var B_1: f32;

    let _e273 = (*LdotV);
    let _e274 = (*NdotL);
    let _e275 = (*NdotV_2);
    s_1 = (_e273 - (_e274 * _e275));
    let _e278 = s_1;
    if (_e278 > 0f) {
        let _e280 = s_1;
        let _e281 = (*NdotL);
        let _e282 = (*NdotV_2);
        local = (_e280 / max(_e281, _e282));
    } else {
        local = 0f;
    }
    let _e285 = local;
    stinv = _e285;
    let _e286 = (*roughness_5);
    param_14 = _e286;
    let _e287 = mx_square_u0028_f1_u003b((&param_14));
    sigma2_ = _e287;
    let _e288 = sigma2_;
    let _e289 = sigma2_;
    A_2 = (1f - (0.5f * (_e288 / (_e289 + 0.33f))));
    let _e294 = sigma2_;
    let _e296 = sigma2_;
    B_1 = ((0.45f * _e294) / (_e296 + 0.09f));
    let _e299 = A_2;
    let _e300 = B_1;
    let _e301 = stinv;
    return (_e299 + (_e300 * _e301));
}

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_3: ptr<function, f32>, NdotL_1: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_1: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_15: f32;
    var param_16: f32;
    var dirAlbedoL: f32;
    var param_17: f32;
    var param_18: f32;
    var avgAlbedo_1: f32;
    var param_19: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_20: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e283 = (*LdotV_1);
    let _e284 = (*NdotL_1);
    let _e285 = (*NdotV_3);
    s_2 = (_e283 - (_e284 * _e285));
    let _e288 = s_2;
    if (_e288 > 0f) {
        let _e290 = s_2;
        let _e291 = (*NdotL_1);
        let _e292 = (*NdotV_3);
        local_1 = (_e290 / max(_e291, _e292));
    } else {
        let _e295 = s_2;
        local_1 = _e295;
    }
    let _e296 = local_1;
    stinv_1 = _e296;
    let _e297 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e297)));
    let _e301 = (*color_2);
    let _e302 = A_3;
    let _e304 = (*roughness_6);
    let _e305 = stinv_1;
    lobeSingleScatter = ((_e301 * _e302) * (1f + (_e304 * _e305)));
    let _e309 = (*NdotV_3);
    param_15 = _e309;
    let _e310 = (*roughness_6);
    param_16 = _e310;
    let _e311 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_15), (&param_16));
    dirAlbedoV = _e311;
    let _e312 = (*NdotL_1);
    param_17 = _e312;
    let _e313 = (*roughness_6);
    param_18 = _e313;
    let _e314 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_17), (&param_18));
    dirAlbedoL = _e314;
    let _e315 = (*roughness_6);
    param_19 = _e315;
    let _e316 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_19));
    avgAlbedo_1 = _e316;
    let _e317 = (*color_2);
    param_20 = _e317;
    let _e318 = mx_square_u0028_vf3_u003b((&param_20));
    let _e319 = avgAlbedo_1;
    let _e321 = (*color_2);
    let _e322 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e318 * _e319) / (vec3<f32>(1f, 1f, 1f) - (_e321 * max(0f, (1f - _e322)))));
    let _e328 = colorMultiScatter_1;
    let _e329 = dirAlbedoV;
    let _e333 = dirAlbedoL;
    let _e337 = avgAlbedo_1;
    lobeMultiScatter = (((_e328 * max(0.00000001f, (1f - _e329))) * max(0.00000001f, (1f - _e333))) / vec3(max(0.00000001f, (1f - _e337))));
    let _e342 = lobeSingleScatter;
    let _e343 = lobeMultiScatter;
    return (_e342 + _e343);
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N_1: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local_2: vec3<f32>;

    let _e265 = (*N_1);
    let _e266 = (*V);
    if (dot(_e265, _e266) < 0f) {
        let _e269 = (*N_1);
        local_2 = -(_e269);
    } else {
        let _e271 = (*N_1);
        local_2 = _e271;
    }
    let _e272 = local_2;
    return _e272;
}

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_2: ptr<function, ClosureData>, weight: ptr<function, f32>, color_3: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_2: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L: vec3<f32>;
    var param_21: vec3<f32>;
    var param_22: vec3<f32>;
    var NdotV_4: f32;
    var NdotL_2: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_23: f32;
    var param_24: f32;
    var param_25: f32;
    var param_26: f32;
    var param_27: vec3<f32>;
    var param_28: f32;
    var param_29: f32;
    var param_30: f32;
    var param_31: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_32: f32;
    var param_33: f32;
    var param_34: vec3<f32>;
    var param_35: f32;
    var param_36: f32;
    var Li_1: vec3<f32>;
    var param_37: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e297 = (*weight);
    if (_e297 < 0.00000001f) {
        return;
    }
    let _e300 = (*closureData_2).V;
    V_1 = _e300;
    let _e302 = (*closureData_2).L;
    L = _e302;
    let _e303 = (*N_2);
    param_21 = _e303;
    let _e304 = V_1;
    param_22 = _e304;
    let _e305 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_21), (&param_22));
    (*N_2) = _e305;
    let _e306 = (*N_2);
    let _e307 = V_1;
    NdotV_4 = clamp(dot(_e306, _e307), 0.00000001f, 1f);
    let _e311 = (*closureData_2).closureType;
    if (_e311 == 1i) {
        let _e313 = (*N_2);
        let _e314 = L;
        NdotL_2 = clamp(dot(_e313, _e314), 0.00000001f, 1f);
        let _e317 = L;
        let _e318 = V_1;
        LdotV_2 = clamp(dot(_e317, _e318), 0.00000001f, 1f);
        let _e321 = (*energy_compensation);
        if _e321 {
            let _e322 = NdotV_4;
            param_23 = _e322;
            let _e323 = NdotL_2;
            param_24 = _e323;
            let _e324 = LdotV_2;
            param_25 = _e324;
            let _e325 = (*roughness_7);
            param_26 = _e325;
            let _e326 = (*color_3);
            param_27 = _e326;
            let _e327 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_23), (&param_24), (&param_25), (&param_26), (&param_27));
            local_3 = _e327;
        } else {
            let _e328 = NdotV_4;
            param_28 = _e328;
            let _e329 = NdotL_2;
            param_29 = _e329;
            let _e330 = LdotV_2;
            param_30 = _e330;
            let _e331 = (*roughness_7);
            param_31 = _e331;
            let _e332 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_28), (&param_29), (&param_30), (&param_31));
            let _e333 = (*color_3);
            local_3 = (_e333 * _e332);
        }
        let _e335 = local_3;
        diffuse = _e335;
        let _e336 = diffuse;
        let _e338 = (*closureData_2).occlusion;
        let _e340 = (*weight);
        let _e342 = NdotL_2;
        (*bsdf).response = ((((_e336 * _e338) * _e340) * _e342) * 0.31830987f);
    } else {
        let _e347 = (*closureData_2).closureType;
        if (_e347 == 3i) {
            let _e349 = (*energy_compensation);
            if _e349 {
                let _e350 = NdotV_4;
                param_32 = _e350;
                let _e351 = (*roughness_7);
                param_33 = _e351;
                let _e352 = (*color_3);
                param_34 = _e352;
                let _e353 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_32), (&param_33), (&param_34));
                local_4 = _e353;
            } else {
                let _e354 = NdotV_4;
                param_35 = _e354;
                let _e355 = (*roughness_7);
                param_36 = _e355;
                let _e356 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_35), (&param_36));
                let _e357 = (*color_3);
                local_4 = (_e357 * _e356);
            }
            let _e359 = local_4;
            diffuse_1 = _e359;
            let _e360 = (*N_2);
            param_37 = _e360;
            let _e361 = mx_environment_irradiance_u0028_vf3_u003b((&param_37));
            Li_1 = _e361;
            let _e362 = Li_1;
            let _e363 = diffuse_1;
            let _e365 = (*weight);
            (*bsdf).response = ((_e362 * _e363) * _e365);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_3: ptr<function, ClosureData>, in1_: ptr<function, BSDF>, in2_: ptr<function, f32>, result_2: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e267 = (*in2_);
    weight_1 = clamp(_e267, 0f, 1f);
    let _e270 = (*in1_).response;
    let _e271 = weight_1;
    (*result_2).response = (_e270 * _e271);
    let _e275 = (*in1_).throughput;
    (*result_2).throughput = _e275;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, BSDF>, result_3: ptr<function, BSDF>) {
    let _e267 = (*in1_1).response;
    let _e269 = (*in2_1).response;
    (*result_3).response = (_e267 + _e269);
    let _e273 = (*in1_1).throughput;
    let _e275 = (*in2_1).throughput;
    (*result_3).throughput = max(((_e273 + _e275) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_3: ptr<function, f32>, NdotV_5: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_38: f32;
    var lambdaL: f32;
    var param_39: f32;
    var lambdaV: f32;
    var param_40: f32;

    let _e271 = (*alpha);
    param_38 = _e271;
    let _e272 = mx_square_u0028_f1_u003b((&param_38));
    alpha2_ = _e272;
    let _e273 = alpha2_;
    let _e274 = alpha2_;
    let _e276 = (*NdotL_3);
    param_39 = _e276;
    let _e277 = mx_square_u0028_f1_u003b((&param_39));
    lambdaL = sqrt((_e273 + ((1f - _e274) * _e277)));
    let _e281 = alpha2_;
    let _e282 = alpha2_;
    let _e284 = (*NdotV_5);
    param_40 = _e284;
    let _e285 = mx_square_u0028_f1_u003b((&param_40));
    lambdaV = sqrt((_e281 + ((1f - _e282) * _e285)));
    let _e289 = (*NdotL_3);
    let _e291 = (*NdotV_5);
    let _e293 = lambdaL;
    let _e294 = (*NdotV_5);
    let _e296 = lambdaV;
    let _e297 = (*NdotL_3);
    return (((2f * _e289) * _e291) / ((_e293 * _e294) + (_e296 * _e297)));
}

fn mx_pow6_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_41: f32;
    var param_42: f32;

    let _e266 = (*x_2);
    param_41 = _e266;
    let _e267 = mx_square_u0028_f1_u003b((&param_41));
    x2_ = _e267;
    let _e268 = x2_;
    param_42 = _e268;
    let _e269 = mx_square_u0028_f1_u003b((&param_42));
    let _e270 = x2_;
    return (_e269 * _e270);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_2: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_3: f32;
    var a_1: vec3<f32>;
    var param_43: f32;

    let _e267 = (*cosTheta_2);
    x_3 = clamp(_e267, 0f, 1f);
    let _e270 = (*fd).F0_;
    let _e272 = (*fd).F90_;
    let _e274 = (*fd).exponent;
    let _e279 = (*fd).F82_;
    a_1 = ((mix(_e270, _e272, vec3(pow(0.85714287f, _e274))) * (vec3<f32>(1f, 1f, 1f) - _e279)) * 17.651384f);
    let _e284 = (*fd).F0_;
    let _e286 = (*fd).F90_;
    let _e287 = x_3;
    let _e290 = (*fd).exponent;
    let _e294 = a_1;
    let _e295 = x_3;
    let _e297 = x_3;
    param_43 = (1f - _e297);
    let _e299 = mx_pow6_u0028_f1_u003b((&param_43));
    return (mix(_e284, _e286, vec3(pow((1f - _e287), _e290))) - ((_e294 * _e295) * _e299));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_3: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_44: f32;
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

    let _e279 = (*cosTheta_3);
    param_44 = clamp(_e279, 0f, 1f);
    let _e281 = mx_square_u0028_f1_u003b((&param_44));
    cosTheta2_ = _e281;
    let _e282 = cosTheta2_;
    sinTheta2_ = (1f - _e282);
    let _e284 = (*n);
    let _e285 = (*n);
    n2_ = (_e284 * _e285);
    let _e287 = (*k);
    let _e288 = (*k);
    k2_ = (_e287 * _e288);
    let _e290 = n2_;
    let _e291 = k2_;
    let _e293 = sinTheta2_;
    t0_ = ((_e290 - _e291) - vec3(_e293));
    let _e296 = t0_;
    let _e297 = t0_;
    let _e299 = n2_;
    let _e301 = k2_;
    a2plusb2_ = sqrt(((_e296 * _e297) + ((_e299 * 4f) * _e301)));
    let _e305 = a2plusb2_;
    let _e306 = cosTheta2_;
    t1_ = (_e305 + vec3(_e306));
    let _e309 = a2plusb2_;
    let _e310 = t0_;
    a_2 = sqrt(max(((_e309 + _e310) * 0.5f), vec3(0f)));
    let _e316 = a_2;
    let _e318 = (*cosTheta_3);
    t2_ = ((_e316 * 2f) * _e318);
    let _e320 = t1_;
    let _e321 = t2_;
    let _e323 = t1_;
    let _e324 = t2_;
    (*Rs) = ((_e320 - _e321) / (_e323 + _e324));
    let _e327 = cosTheta2_;
    let _e328 = a2plusb2_;
    let _e330 = sinTheta2_;
    let _e331 = sinTheta2_;
    t3_ = ((_e328 * _e327) + vec3((_e330 * _e331)));
    let _e335 = t2_;
    let _e336 = sinTheta2_;
    t4_ = (_e335 * _e336);
    let _e338 = (*Rs);
    let _e339 = t3_;
    let _e340 = t4_;
    let _e343 = t3_;
    let _e344 = t4_;
    (*Rp) = ((_e338 * (_e339 - _e340)) / (_e343 + _e344));
    return;
}

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_4: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_45: f32;
    var param_46: vec3<f32>;
    var param_47: vec3<f32>;
    var param_48: vec3<f32>;
    var param_49: vec3<f32>;

    let _e272 = (*cosTheta_4);
    param_45 = _e272;
    let _e273 = (*n_1);
    param_46 = _e273;
    let _e274 = (*k_1);
    param_47 = _e274;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_45), (&param_46), (&param_47), (&param_48), (&param_49));
    let _e275 = param_48;
    Rp_1 = _e275;
    let _e276 = param_49;
    Rs_1 = _e276;
    let _e277 = Rp_1;
    let _e278 = Rs_1;
    return ((_e277 + _e278) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_5: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_50: f32;
    var param_51: f32;

    let _e269 = (*cosTheta_5);
    c_1 = _e269;
    let _e270 = (*ior);
    let _e271 = (*ior);
    let _e273 = c_1;
    let _e274 = c_1;
    g2_ = (((_e270 * _e271) + (_e273 * _e274)) - 1f);
    let _e278 = g2_;
    if (_e278 < 0f) {
        return 1f;
    }
    let _e280 = g2_;
    g = sqrt(_e280);
    let _e282 = g;
    let _e283 = c_1;
    let _e285 = g;
    let _e286 = c_1;
    param_50 = ((_e282 - _e283) / (_e285 + _e286));
    let _e289 = mx_square_u0028_f1_u003b((&param_50));
    let _e291 = g;
    let _e292 = c_1;
    let _e294 = c_1;
    let _e297 = g;
    let _e298 = c_1;
    let _e300 = c_1;
    param_51 = ((((_e291 + _e292) * _e294) - 1f) / (((_e297 - _e298) * _e300) + 1f));
    let _e304 = mx_square_u0028_f1_u003b((&param_51));
    return ((0.5f * _e289) * (1f + _e304));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e264 = (*m_1);
    let _e265 = (*v_1);
    return (_e264 * _e265);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e269 = (*opd);
    phase = (6.2831855f * _e269);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e271 = val;
    let _e272 = var_;
    let _e276 = pos;
    let _e277 = phase;
    let _e279 = (*shift);
    let _e283 = var_;
    let _e285 = phase;
    let _e287 = phase;
    xyz = (((_e271 * sqrt((_e272 * 6.2831855f))) * cos(((_e276 * _e277) + _e279))) * exp(((-(_e283) * _e285) * _e287)));
    let _e291 = phase;
    let _e294 = (*shift)[0u];
    let _e298 = phase;
    let _e300 = phase;
    let _e305 = xyz[0u];
    xyz[0u] = (_e305 + ((0.00000001644083f * cos(((2239900f * _e291) + _e294))) * exp(((-4528200000f * _e298) * _e300))));
    let _e308 = xyz;
    return (_e308 / vec3(0.00000010685f));
}

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_6: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_52: vec3<f32>;
    var U: vec3<f32>;
    var V_2: vec3<f32>;
    var param_53: f32;
    var param_54: vec3<f32>;

    let _e277 = (*kappa2_);
    let _e278 = (*eta2_);
    k2_1 = (_e277 / _e278);
    let _e280 = (*cosTheta_6);
    let _e281 = (*cosTheta_6);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e280 * _e281)));
    let _e285 = (*eta2_);
    let _e286 = (*eta2_);
    let _e288 = k2_1;
    let _e289 = k2_1;
    let _e293 = (*eta1_);
    let _e294 = (*eta1_);
    let _e296 = sinThetaSqr;
    A_4 = (((_e285 * _e286) * (vec3<f32>(1f, 1f, 1f) - (_e288 * _e289))) - (_e296 * (_e293 * _e294)));
    let _e299 = A_4;
    let _e300 = A_4;
    let _e302 = (*eta2_);
    let _e304 = (*eta2_);
    let _e306 = k2_1;
    param_52 = (((_e302 * 2f) * _e304) * _e306);
    let _e308 = mx_square_u0028_vf3_u003b((&param_52));
    B_2 = sqrt(((_e299 * _e300) + _e308));
    let _e311 = A_4;
    let _e312 = B_2;
    U = sqrt(((_e311 + _e312) / vec3(2f)));
    let _e317 = B_2;
    let _e318 = A_4;
    V_2 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e317 - _e318) / vec3(2f))));
    let _e324 = (*eta1_);
    let _e326 = V_2;
    let _e328 = (*cosTheta_6);
    let _e330 = U;
    let _e331 = U;
    let _e333 = V_2;
    let _e334 = V_2;
    let _e337 = (*eta1_);
    let _e338 = (*cosTheta_6);
    param_53 = (_e337 * _e338);
    let _e340 = mx_square_u0028_f1_u003b((&param_53));
    (*phiS) = atan2(((_e326 * (2f * _e324)) * _e328), (((_e330 * _e331) + (_e333 * _e334)) - vec3(_e340)));
    let _e344 = (*eta1_);
    let _e346 = (*eta2_);
    let _e348 = (*eta2_);
    let _e350 = (*cosTheta_6);
    let _e352 = k2_1;
    let _e354 = U;
    let _e356 = k2_1;
    let _e357 = k2_1;
    let _e360 = V_2;
    let _e364 = (*eta2_);
    let _e365 = (*eta2_);
    let _e367 = k2_1;
    let _e368 = k2_1;
    let _e372 = (*cosTheta_6);
    param_54 = (((_e364 * _e365) * (vec3<f32>(1f, 1f, 1f) + (_e367 * _e368))) * _e372);
    let _e374 = mx_square_u0028_vf3_u003b((&param_54));
    let _e375 = (*eta1_);
    let _e376 = (*eta1_);
    let _e378 = U;
    let _e379 = U;
    let _e381 = V_2;
    let _e382 = V_2;
    (*phiP) = atan2(((((_e346 * (2f * _e344)) * _e348) * _e350) * (((_e352 * 2f) * _e354) - ((vec3<f32>(1f, 1f, 1f) - (_e356 * _e357)) * _e360))), (_e374 - (((_e378 * _e379) + (_e381 * _e382)) * (_e375 * _e376))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_55: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e274 = (*cosTheta_7);
    param_55 = clamp(_e274, 0f, 1f);
    let _e276 = mx_square_u0028_f1_u003b((&param_55));
    cosTheta2_1 = _e276;
    let _e277 = cosTheta2_1;
    sinTheta2_1 = (1f - _e277);
    let _e279 = (*ior_1);
    let _e280 = (*ior_1);
    let _e282 = sinTheta2_1;
    t0_1 = max(((_e279 * _e280) - _e282), 0f);
    let _e285 = t0_1;
    let _e286 = cosTheta2_1;
    t1_1 = (_e285 + _e286);
    let _e288 = t0_1;
    let _e291 = (*cosTheta_7);
    t2_1 = ((2f * sqrt(_e288)) * _e291);
    let _e293 = t1_1;
    let _e294 = t2_1;
    let _e296 = t1_1;
    let _e297 = t2_1;
    Rs_2 = ((_e293 - _e294) / (_e296 + _e297));
    let _e300 = cosTheta2_1;
    let _e301 = t0_1;
    let _e303 = sinTheta2_1;
    let _e304 = sinTheta2_1;
    t3_1 = ((_e300 * _e301) + (_e303 * _e304));
    let _e307 = t2_1;
    let _e308 = sinTheta2_1;
    t4_1 = (_e307 * _e308);
    let _e310 = Rs_2;
    let _e311 = t3_1;
    let _e312 = t4_1;
    let _e315 = t3_1;
    let _e316 = t4_1;
    Rp_2 = ((_e310 * (_e311 - _e312)) / (_e315 + _e316));
    let _e319 = Rp_2;
    let _e320 = Rs_2;
    return vec2<f32>(_e319, _e320);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e264 = (*F0_);
    sqrtF0_ = sqrt(clamp(_e264, vec3(0.01f), vec3(0.99f)));
    let _e269 = sqrtF0_;
    let _e271 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e269) / (vec3<f32>(1f, 1f, 1f) - _e271));
}

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_8: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_56: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_57: f32;
    var param_58: f32;
    var R12_: vec2<f32>;
    var param_59: f32;
    var param_60: f32;
    var T121_: vec2<f32>;
    var f: vec3<f32>;
    var param_61: f32;
    var param_62: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_63: f32;
    var param_64: vec3<f32>;
    var param_65: vec3<f32>;
    var param_66: vec3<f32>;
    var param_67: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_68: f32;
    var param_69: f32;
    var param_70: vec3<f32>;
    var param_71: vec3<f32>;
    var param_72: vec3<f32>;
    var param_73: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_74: f32;
    var Cm: vec3<f32>;
    var m_2: i32;
    var Sm: vec3<f32>;
    var param_75: f32;
    var param_76: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_77: f32;
    var m_3: i32;
    var param_78: f32;
    var param_79: vec3<f32>;
    var param_80: mat3x3<f32>;
    var param_81: vec3<f32>;

    eta1_1 = 1f;
    let _e318 = (*fd_1).tf_ior;
    let _e319 = eta1_1;
    eta2_1 = max(_e318, _e319);
    let _e322 = (*fd_1).model;
    if (_e322 == 2i) {
        let _e325 = (*fd_1).F0_;
        param_56 = _e325;
        let _e326 = mx_f0_to_ior_u0028_vf3_u003b((&param_56));
        local_5 = _e326;
    } else {
        let _e328 = (*fd_1).ior;
        local_5 = _e328;
    }
    let _e329 = local_5;
    eta3_ = _e329;
    let _e331 = (*fd_1).model;
    if (_e331 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e334 = (*fd_1).extinction;
        local_6 = _e334;
    }
    let _e335 = local_6;
    kappa3_ = _e335;
    let _e336 = (*cosTheta_8);
    param_57 = _e336;
    let _e337 = mx_square_u0028_f1_u003b((&param_57));
    let _e339 = eta1_1;
    let _e340 = eta2_1;
    param_58 = (_e339 / _e340);
    let _e342 = mx_square_u0028_f1_u003b((&param_58));
    cosThetaT = sqrt((1f - ((1f - _e337) * _e342)));
    let _e346 = eta2_1;
    let _e347 = eta1_1;
    let _e349 = (*cosTheta_8);
    param_59 = _e349;
    param_60 = (_e346 / _e347);
    let _e350 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_59), (&param_60));
    R12_ = _e350;
    let _e351 = cosThetaT;
    if (_e351 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e353 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e353);
    let _e356 = (*fd_1).model;
    if (_e356 == 2i) {
        let _e358 = cosThetaT;
        param_61 = _e358;
        let _e359 = (*fd_1);
        param_62 = _e359;
        let _e360 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_61), (&param_62));
        f = _e360;
        let _e361 = f;
        R23p = (_e361 * 0.5f);
        let _e363 = f;
        R23s = (_e363 * 0.5f);
    } else {
        let _e365 = eta3_;
        let _e366 = eta2_1;
        let _e369 = kappa3_;
        let _e370 = eta2_1;
        let _e373 = cosThetaT;
        param_63 = _e373;
        param_64 = (_e365 / vec3(_e366));
        param_65 = (_e369 / vec3(_e370));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_63), (&param_64), (&param_65), (&param_66), (&param_67));
        let _e374 = param_66;
        R23p = _e374;
        let _e375 = param_67;
        R23s = _e375;
    }
    let _e376 = eta2_1;
    let _e377 = eta1_1;
    cosB = cos(atan((_e376 / _e377)));
    let _e381 = (*cosTheta_8);
    let _e382 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e381 < _e382)), 3.1415927f);
    let _e387 = (*fd_1).model;
    if (_e387 == 2i) {
        let _e390 = eta3_[0u];
        let _e391 = eta2_1;
        let _e395 = eta3_[1u];
        let _e396 = eta2_1;
        let _e400 = eta3_[2u];
        let _e401 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e390 < _e391)), select(0f, 3.1415927f, (_e395 < _e396)), select(0f, 3.1415927f, (_e400 < _e401)));
        let _e405 = phi23p;
        phi23s = _e405;
    } else {
        let _e406 = cosThetaT;
        param_68 = _e406;
        let _e407 = eta2_1;
        param_69 = _e407;
        let _e408 = eta3_;
        param_70 = _e408;
        let _e409 = kappa3_;
        param_71 = _e409;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_68), (&param_69), (&param_70), (&param_71), (&param_72), (&param_73));
        let _e410 = param_72;
        phi23p = _e410;
        let _e411 = param_73;
        phi23s = _e411;
    }
    let _e413 = R12_[0u];
    let _e414 = R23p;
    r123p = max(sqrt((_e414 * _e413)), vec3(0f));
    let _e420 = R12_[1u];
    let _e421 = R23s;
    r123s = max(sqrt((_e421 * _e420)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e427 = (*fd_1).tf_thickness;
    distMeters = (_e427 * 0.000000001f);
    let _e429 = eta2_1;
    let _e431 = cosThetaT;
    let _e433 = distMeters;
    opd_1 = (((2f * _e429) * _e431) * _e433);
    let _e436 = T121_[0u];
    param_74 = _e436;
    let _e437 = mx_square_u0028_f1_u003b((&param_74));
    let _e438 = R23p;
    let _e441 = R12_[0u];
    let _e442 = R23p;
    Rs_3 = ((_e438 * _e437) / (vec3<f32>(1f, 1f, 1f) - (_e442 * _e441)));
    let _e447 = R12_[0u];
    let _e448 = Rs_3;
    let _e451 = I;
    I = (_e451 + (vec3(_e447) + _e448));
    let _e453 = Rs_3;
    let _e455 = T121_[0u];
    Cm = (_e453 - vec3(_e455));
    m_2 = 1i;
    loop {
        let _e458 = m_2;
        if (_e458 <= 2i) {
            let _e460 = r123p;
            let _e461 = Cm;
            Cm = (_e461 * _e460);
            let _e463 = m_2;
            let _e465 = opd_1;
            let _e467 = m_2;
            let _e469 = phi23p;
            let _e471 = phi21_[0u];
            param_75 = (f32(_e463) * _e465);
            param_76 = ((_e469 + vec3(_e471)) * f32(_e467));
            let _e475 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_75), (&param_76));
            Sm = (_e475 * 2f);
            let _e477 = Cm;
            let _e478 = Sm;
            let _e480 = I;
            I = (_e480 + (_e477 * _e478));
            continue;
        } else {
            break;
        }
        continuing {
            let _e482 = m_2;
            m_2 = (_e482 + 1i);
        }
    }
    let _e485 = T121_[1u];
    param_77 = _e485;
    let _e486 = mx_square_u0028_f1_u003b((&param_77));
    let _e487 = R23s;
    let _e490 = R12_[1u];
    let _e491 = R23s;
    Rp_3 = ((_e487 * _e486) / (vec3<f32>(1f, 1f, 1f) - (_e491 * _e490)));
    let _e496 = R12_[1u];
    let _e497 = Rp_3;
    let _e500 = I;
    I = (_e500 + (vec3(_e496) + _e497));
    let _e502 = Rp_3;
    let _e504 = T121_[1u];
    Cm = (_e502 - vec3(_e504));
    m_3 = 1i;
    loop {
        let _e507 = m_3;
        if (_e507 <= 2i) {
            let _e509 = r123s;
            let _e510 = Cm;
            Cm = (_e510 * _e509);
            let _e512 = m_3;
            let _e514 = opd_1;
            let _e516 = m_3;
            let _e518 = phi23s;
            let _e520 = phi21_[1u];
            param_78 = (f32(_e512) * _e514);
            param_79 = ((_e518 + vec3(_e520)) * f32(_e516));
            let _e524 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_78), (&param_79));
            Sm = (_e524 * 2f);
            let _e526 = Cm;
            let _e527 = Sm;
            let _e529 = I;
            I = (_e529 + (_e526 * _e527));
            continue;
        } else {
            break;
        }
        continuing {
            let _e531 = m_3;
            m_3 = (_e531 + 1i);
        }
    }
    let _e533 = I;
    I = (_e533 * 0.5f);
    param_80 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e535 = I;
    param_81 = _e535;
    let _e536 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_80), (&param_81));
    I = clamp(_e536, vec3(0f), vec3(1f));
    let _e540 = I;
    return _e540;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_9: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_82: f32;
    var param_83: FresnelData;
    var param_84: f32;
    var param_85: f32;
    var param_86: f32;
    var param_87: vec3<f32>;
    var param_88: vec3<f32>;
    var param_89: f32;
    var param_90: FresnelData;

    let _e274 = (*fd_2).airy;
    if _e274 {
        let _e275 = (*cosTheta_9);
        param_82 = _e275;
        let _e276 = (*fd_2);
        param_83 = _e276;
        let _e277 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_82), (&param_83));
        return _e277;
    } else {
        let _e279 = (*fd_2).model;
        if (_e279 == 0i) {
            let _e281 = (*cosTheta_9);
            param_84 = _e281;
            let _e284 = (*fd_2).ior[0u];
            param_85 = _e284;
            let _e285 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
            return vec3(_e285);
        } else {
            let _e288 = (*fd_2).model;
            if (_e288 == 1i) {
                let _e290 = (*cosTheta_9);
                param_86 = _e290;
                let _e292 = (*fd_2).ior;
                param_87 = _e292;
                let _e294 = (*fd_2).extinction;
                param_88 = _e294;
                let _e295 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_86), (&param_87), (&param_88));
                return _e295;
            } else {
                let _e296 = (*cosTheta_9);
                param_89 = _e296;
                let _e297 = (*fd_2);
                param_90 = _e297;
                let _e298 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_89), (&param_90));
                return _e298;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_91: mat4x4<f32>;
    var param_92: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_93: vec3<f32>;

    let _e270 = (*dir_2);
    let _e275 = (*transform_1);
    param_91 = _e275;
    param_92 = vec4<f32>(_e270.x, _e270.y, _e270.z, 0f);
    let _e276 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_91), (&param_92));
    envDir_1 = normalize(_e276.xyz);
    let _e279 = envDir_1;
    param_93 = _e279;
    let _e280 = mx_latlong_projection_u0028_vf3_u003b((&param_93));
    uv_2 = _e280;
    let _e281 = uv_2;
    let _e282 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e281, 0.0);
    return _e282.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_94: f32;

    let _e269 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e269 - 1.5f);
    let _e272 = (*dir_3)[1u];
    param_94 = _e272;
    let _e273 = mx_square_u0028_f1_u003b((&param_94));
    distortion = sqrt((1f - _e273));
    let _e276 = effectiveMaxMipLevel;
    let _e277 = (*envSamples);
    let _e279 = (*pdf);
    let _e281 = distortion;
    return max((_e276 - (0.5f * log2(((f32(_e277) * _e279) * _e281)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom: f32;
    var param_95: f32;
    var param_96: f32;

    let _e268 = (*H);
    let _e270 = (*alpha_1);
    He = (_e268.xy / _e270);
    let _e272 = He;
    let _e273 = He;
    let _e276 = (*H)[2u];
    param_95 = _e276;
    let _e277 = mx_square_u0028_f1_u003b((&param_95));
    denom = (dot(_e272, _e273) + _e277);
    let _e280 = (*alpha_1)[0u];
    let _e283 = (*alpha_1)[1u];
    let _e285 = denom;
    param_96 = _e285;
    let _e286 = mx_square_u0028_f1_u003b((&param_96));
    return (1f / (((3.1415927f * _e280) * _e283) * _e286));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_6: ptr<function, f32>) -> f32 {
    var param_97: vec3<f32>;
    var param_98: vec2<f32>;

    let _e268 = (*H_1);
    param_97 = _e268;
    let _e269 = (*alpha_2);
    param_98 = _e269;
    let _e270 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_97), (&param_98));
    let _e271 = (*G1V);
    let _e273 = (*NdotV_6);
    return ((_e270 * _e271) / (4f * _e273));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R: ptr<function, vec3<f32>>, N_3: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e266 = (*R);
    let _e267 = (*N_3);
    let _e268 = (*ior_2);
    (*R) = refract(_e266, _e267, (1f / _e268));
    let _e271 = (*R);
    let _e272 = (*R);
    let _e273 = (*N_3);
    let _e276 = (*N_3);
    N1_ = normalize(((_e271 * dot(_e272, _e273)) - (_e276 * 0.5f)));
    let _e280 = (*R);
    let _e281 = N1_;
    let _e282 = (*ior_2);
    return refract(_e280, _e281, _e282);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_3: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_4: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e272 = (*V_3);
    let _e274 = (*alpha_3);
    let _e275 = (_e272.xy * _e274);
    let _e277 = (*V_3)[2u];
    (*V_3) = normalize(vec3<f32>(_e275.x, _e275.y, _e277));
    let _e283 = (*Xi)[0u];
    phi = (6.2831855f * _e283);
    let _e286 = (*Xi)[1u];
    let _e289 = (*V_3)[2u];
    let _e293 = (*V_3)[2u];
    z = (((1f - _e286) * (1f + _e289)) - _e293);
    let _e295 = z;
    let _e296 = z;
    sinTheta = sqrt(clamp((1f - (_e295 * _e296)), 0f, 1f));
    let _e301 = sinTheta;
    let _e302 = phi;
    x_4 = (_e301 * cos(_e302));
    let _e305 = sinTheta;
    let _e306 = phi;
    y = (_e305 * sin(_e306));
    let _e309 = x_4;
    let _e310 = y;
    let _e311 = z;
    c_2 = vec3<f32>(_e309, _e310, _e311);
    let _e313 = c_2;
    let _e314 = (*V_3);
    H_2 = (_e313 + _e314);
    let _e316 = H_2;
    let _e318 = (*alpha_3);
    let _e319 = (_e316.xy * _e318);
    let _e321 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e319.x, _e319.y, max(_e321, 0f)));
    let _e327 = H_2;
    return _e327;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i: ptr<function, i32>) -> f32 {
    let _e263 = (*i);
    return fract(((f32(_e263) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_1: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_99: i32;

    let _e265 = (*i_1);
    let _e268 = (*numSamples);
    let _e271 = (*i_1);
    param_99 = _e271;
    let _e272 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_99));
    return vec2<f32>(((f32(_e265) + 0.5f) / f32(_e268)), _e272);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_10: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_100: f32;
    var tanTheta2_: f32;
    var param_101: f32;

    let _e268 = (*cosTheta_10);
    param_100 = _e268;
    let _e269 = mx_square_u0028_f1_u003b((&param_100));
    cosTheta2_2 = _e269;
    let _e270 = cosTheta2_2;
    let _e272 = cosTheta2_2;
    tanTheta2_ = ((1f - _e270) / _e272);
    let _e274 = (*alpha_4);
    param_101 = _e274;
    let _e275 = mx_square_u0028_f1_u003b((&param_101));
    let _e276 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e275 * _e276)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e264 = (*alpha_5)[0u];
    let _e266 = (*alpha_5)[1u];
    return sqrt((_e264 * _e266));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_4: ptr<function, vec3<f32>>, V_4: ptr<function, vec3<f32>>, X: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_7: f32;
    var avgAlpha: f32;
    var param_102: vec2<f32>;
    var G1V_1: f32;
    var param_103: f32;
    var param_104: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_2: i32;
    var Xi_1: vec2<f32>;
    var param_105: i32;
    var param_106: i32;
    var H_3: vec3<f32>;
    var param_107: vec2<f32>;
    var param_108: vec3<f32>;
    var param_109: vec2<f32>;
    var L_1: vec3<f32>;
    var local_7: vec3<f32>;
    var param_110: vec3<f32>;
    var param_111: vec3<f32>;
    var param_112: f32;
    var NdotL_4: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_113: mat3x3<f32>;
    var param_114: vec3<f32>;
    var pdf_1: f32;
    var param_115: vec3<f32>;
    var param_116: vec2<f32>;
    var param_117: f32;
    var param_118: f32;
    var lod_2: f32;
    var param_119: vec3<f32>;
    var param_120: f32;
    var param_121: f32;
    var param_122: i32;
    var sampleColor: vec3<f32>;
    var param_123: vec3<f32>;
    var param_124: mat4x4<f32>;
    var param_125: f32;
    var F: vec3<f32>;
    var param_126: f32;
    var param_127: FresnelData;
    var G_1: f32;
    var param_128: f32;
    var param_129: f32;
    var param_130: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e319 = (*X);
    let _e320 = (*X);
    let _e321 = (*N_4);
    let _e323 = (*N_4);
    (*X) = normalize((_e319 - (_e323 * dot(_e320, _e321))));
    let _e327 = (*N_4);
    let _e328 = (*X);
    Y = cross(_e327, _e328);
    let _e330 = (*X);
    let _e331 = Y;
    let _e332 = (*N_4);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e330.x, _e330.y, _e330.z), vec3<f32>(_e331.x, _e331.y, _e331.z), vec3<f32>(_e332.x, _e332.y, _e332.z));
    let _e346 = (*V_4);
    let _e347 = (*X);
    let _e349 = (*V_4);
    let _e350 = Y;
    let _e352 = (*V_4);
    let _e353 = (*N_4);
    (*V_4) = vec3<f32>(dot(_e346, _e347), dot(_e349, _e350), dot(_e352, _e353));
    let _e357 = (*V_4)[2u];
    NdotV_7 = clamp(_e357, 0.00000001f, 1f);
    let _e359 = (*alpha_6);
    param_102 = _e359;
    let _e360 = mx_average_alpha_u0028_vf2_u003b((&param_102));
    avgAlpha = _e360;
    let _e361 = NdotV_7;
    param_103 = _e361;
    let _e362 = avgAlpha;
    param_104 = _e362;
    let _e363 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_103), (&param_104));
    G1V_1 = _e363;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_2 = 0i;
    loop {
        let _e364 = i_2;
        let _e365 = envRadianceSamples;
        if (_e364 < _e365) {
            let _e367 = i_2;
            param_105 = _e367;
            let _e368 = envRadianceSamples;
            param_106 = _e368;
            let _e369 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_105), (&param_106));
            Xi_1 = _e369;
            let _e370 = Xi_1;
            param_107 = _e370;
            let _e371 = (*V_4);
            param_108 = _e371;
            let _e372 = (*alpha_6);
            param_109 = _e372;
            let _e373 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_107), (&param_108), (&param_109));
            H_3 = _e373;
            let _e375 = (*fd_3).refraction;
            if _e375 {
                let _e376 = (*V_4);
                param_110 = -(_e376);
                let _e378 = H_3;
                param_111 = _e378;
                let _e381 = (*fd_3).ior[0u];
                param_112 = _e381;
                let _e382 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_110), (&param_111), (&param_112));
                local_7 = _e382;
            } else {
                let _e383 = (*V_4);
                let _e384 = H_3;
                local_7 = -(reflect(_e383, _e384));
            }
            let _e387 = local_7;
            L_1 = _e387;
            let _e389 = L_1[2u];
            NdotL_4 = clamp(_e389, 0.00000001f, 1f);
            let _e391 = (*V_4);
            let _e392 = H_3;
            VdotH = clamp(dot(_e391, _e392), 0.00000001f, 1f);
            let _e395 = tangentToWorld;
            param_113 = _e395;
            let _e396 = L_1;
            param_114 = _e396;
            let _e397 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_113), (&param_114));
            Lw = _e397;
            let _e398 = H_3;
            param_115 = _e398;
            let _e399 = (*alpha_6);
            param_116 = _e399;
            let _e400 = G1V_1;
            param_117 = _e400;
            let _e401 = NdotV_7;
            param_118 = _e401;
            let _e402 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_115), (&param_116), (&param_117), (&param_118));
            pdf_1 = _e402;
            let _e403 = Lw;
            param_119 = _e403;
            let _e404 = pdf_1;
            param_120 = _e404;
            param_121 = 0f;
            let _e405 = envRadianceSamples;
            param_122 = _e405;
            let _e406 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_119), (&param_120), (&param_121), (&param_122));
            lod_2 = _e406;
            let _e407 = mtlxEnvMatrix_u0028_();
            let _e408 = Lw;
            param_123 = _e408;
            param_124 = _e407;
            let _e409 = lod_2;
            param_125 = _e409;
            let _e410 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_123), (&param_124), (&param_125));
            sampleColor = _e410;
            let _e411 = VdotH;
            param_126 = _e411;
            let _e412 = (*fd_3);
            param_127 = _e412;
            let _e413 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_126), (&param_127));
            F = _e413;
            let _e414 = NdotL_4;
            param_128 = _e414;
            let _e415 = NdotV_7;
            param_129 = _e415;
            let _e416 = avgAlpha;
            param_130 = _e416;
            let _e417 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_128), (&param_129), (&param_130));
            G_1 = _e417;
            let _e419 = (*fd_3).refraction;
            if _e419 {
                let _e420 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e420);
            } else {
                let _e422 = F;
                let _e423 = G_1;
                local_8 = (_e422 * _e423);
            }
            let _e425 = local_8;
            FG = _e425;
            let _e426 = sampleColor;
            let _e427 = FG;
            let _e429 = radiance;
            radiance = (_e429 + (_e426 * _e427));
            continue;
        } else {
            break;
        }
        continuing {
            let _e431 = i_2;
            i_2 = (_e431 + 1i);
        }
    }
    let _e433 = G1V_1;
    let _e434 = envRadianceSamples;
    let _e437 = radiance;
    radiance = (_e437 / vec3((_e433 * f32(_e434))));
    let _e440 = radiance;
    let _e443 = unnamed.skyPower;
    return (select(_e440, vec3<f32>(0f, 0f, 0f), false) * _e443);
}

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, V_5: ptr<function, vec3<f32>>, X_1: ptr<function, vec3<f32>>, alpha_7: ptr<function, vec2<f32>>, distribution_1: ptr<function, i32>, fd_4: ptr<function, FresnelData>, tint: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_131: vec3<f32>;
    var param_132: vec3<f32>;
    var param_133: vec3<f32>;
    var param_134: vec3<f32>;
    var param_135: vec2<f32>;
    var param_136: i32;
    var param_137: FresnelData;

    (*fd_4).refraction = true;
    if false {
        let _e277 = (*tint);
        param_131 = _e277;
        let _e278 = mx_square_u0028_vf3_u003b((&param_131));
        (*tint) = _e278;
    }
    let _e279 = (*N_5);
    param_132 = _e279;
    let _e280 = (*V_5);
    param_133 = _e280;
    let _e281 = (*X_1);
    param_134 = _e281;
    let _e282 = (*alpha_7);
    param_135 = _e282;
    let _e283 = (*distribution_1);
    param_136 = _e283;
    let _e284 = (*fd_4);
    param_137 = _e284;
    let _e285 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_132), (&param_133), (&param_134), (&param_135), (&param_136), (&param_137));
    let _e286 = (*tint);
    return (_e285 * _e286);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_1: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e264 = (*F0_1);
    sqrtF0_1 = sqrt(clamp(_e264, 0.01f, 0.99f));
    let _e267 = sqrtF0_1;
    let _e269 = sqrtF0_1;
    return ((1f + _e267) / (1f - _e269));
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_8: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_2: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_5: f32;
    var y_1: f32;
    var x2_1: f32;
    var param_138: f32;
    var y2_: f32;
    var param_139: f32;
    var r_1: vec4<f32>;
    var AB: vec2<f32>;

    let _e274 = (*NdotV_8);
    x_5 = _e274;
    let _e275 = (*alpha_8);
    y_1 = _e275;
    let _e276 = x_5;
    param_138 = _e276;
    let _e277 = mx_square_u0028_f1_u003b((&param_138));
    x2_1 = _e277;
    let _e278 = y_1;
    param_139 = _e278;
    let _e279 = mx_square_u0028_f1_u003b((&param_139));
    y2_ = _e279;
    let _e280 = x_5;
    let _e283 = y_1;
    let _e286 = x_5;
    let _e288 = y_1;
    let _e291 = x2_1;
    let _e294 = y2_;
    let _e297 = x2_1;
    let _e299 = y_1;
    let _e302 = x_5;
    let _e304 = y2_;
    let _e307 = x2_1;
    let _e309 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e280)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e283)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e286) * _e288)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e291)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e294)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e297) * _e299)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e302) * _e304)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e307) * _e309));
    let _e312 = r_1;
    let _e314 = r_1;
    AB = clamp((_e312.xy / _e314.zw), vec2(0f), vec2(1f));
    let _e320 = (*F0_2);
    let _e322 = AB[0u];
    let _e324 = (*F90_);
    let _e326 = AB[1u];
    return ((_e320 * _e322) + (_e324 * _e326));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_140: f32;
    var param_141: f32;
    var param_142: vec3<f32>;
    var param_143: vec3<f32>;

    let _e270 = (*NdotV_9);
    param_140 = _e270;
    let _e271 = (*alpha_9);
    param_141 = _e271;
    let _e272 = (*F0_3);
    param_142 = _e272;
    let _e273 = (*F90_1);
    param_143 = _e273;
    let _e274 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_140), (&param_141), (&param_142), (&param_143));
    return _e274;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_10: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_4: ptr<function, f32>, F90_2: ptr<function, f32>) -> f32 {
    var param_144: f32;
    var param_145: f32;
    var param_146: vec3<f32>;
    var param_147: vec3<f32>;

    let _e270 = (*F0_4);
    let _e272 = (*F90_2);
    let _e274 = (*NdotV_10);
    param_144 = _e274;
    let _e275 = (*alpha_10);
    param_145 = _e275;
    param_146 = vec3(_e270);
    param_147 = vec3(_e272);
    let _e276 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_144), (&param_145), (&param_146), (&param_147));
    return _e276.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_148: f32;
    var param_149: FresnelData;
    var F90_3: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_2867_: bool;

    param_148 = 1f;
    let _e268 = (*fd_5);
    param_149 = _e268;
    let _e269 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_148), (&param_149));
    F0_5 = _e269;
    let _e271 = (*fd_5).model;
    let _e272 = (_e271 == 2i);
    phi_2867_ = _e272;
    if _e272 {
        let _e274 = (*fd_5).airy;
        phi_2867_ = !(_e274);
    }
    let _e277 = phi_2867_;
    if _e277 {
        let _e279 = (*fd_5).F90_;
        local_9 = _e279;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e280 = local_9;
    F90_3 = _e280;
    let _e281 = F0_5;
    let _e282 = F90_3;
    let _e283 = F0_5;
    return (_e281 + ((_e282 - _e283) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_11: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_150: FresnelData;
    var Ess: f32;
    var param_151: f32;
    var param_152: f32;
    var param_153: f32;
    var param_154: f32;

    let _e272 = (*fd_6);
    param_150 = _e272;
    let _e273 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_150));
    Fss = _e273;
    let _e274 = (*NdotV_11);
    param_151 = _e274;
    let _e275 = (*alpha_11);
    param_152 = _e275;
    param_153 = 1f;
    param_154 = 1f;
    let _e276 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_151), (&param_152), (&param_153), (&param_154));
    Ess = _e276;
    let _e277 = Fss;
    let _e278 = Ess;
    let _e281 = Ess;
    return (vec3(1f) + ((_e277 * (1f - _e278)) / vec3(_e281)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_6: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_4: ptr<function, vec3<f32>>, exponent: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e270 = (*tf_thickness);
    fd_7.airy = (_e270 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e275 = (*F0_6);
    fd_7.F0_ = _e275;
    let _e277 = (*F82_);
    fd_7.F82_ = _e277;
    let _e279 = (*F90_4);
    fd_7.F90_ = _e279;
    let _e281 = (*exponent);
    fd_7.exponent = _e281;
    let _e283 = (*tf_thickness);
    fd_7.tf_thickness = _e283;
    let _e285 = (*tf_ior);
    fd_7.tf_ior = _e285;
    fd_7.refraction = false;
    let _e288 = fd_7;
    return _e288;
}

fn mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color0_: ptr<function, vec3<f32>>, color82_: ptr<function, vec3<f32>>, color90_: ptr<function, vec3<f32>>, exponent_1: ptr<function, f32>, roughness_8: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_6: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, distribution_2: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_1: ptr<function, BSDF>) {
    var V_6: vec3<f32>;
    var L_2: vec3<f32>;
    var param_155: vec3<f32>;
    var param_156: vec3<f32>;
    var NdotV_12: f32;
    var safeColor0_: vec3<f32>;
    var safeColor82_: vec3<f32>;
    var safeColor90_: vec3<f32>;
    var fd_8: FresnelData;
    var param_157: vec3<f32>;
    var param_158: vec3<f32>;
    var param_159: vec3<f32>;
    var param_160: f32;
    var param_161: f32;
    var param_162: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_163: vec2<f32>;
    var Y_1: vec3<f32>;
    var H_4: vec3<f32>;
    var NdotL_5: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_1: vec3<f32>;
    var param_164: f32;
    var param_165: FresnelData;
    var D: f32;
    var param_166: vec3<f32>;
    var param_167: vec2<f32>;
    var G_2: f32;
    var param_168: f32;
    var param_169: f32;
    var param_170: f32;
    var comp: vec3<f32>;
    var param_171: f32;
    var param_172: f32;
    var param_173: FresnelData;
    var dirAlbedo_2: vec3<f32>;
    var param_174: f32;
    var param_175: f32;
    var param_176: vec3<f32>;
    var param_177: vec3<f32>;
    var avgDirAlbedo: f32;
    var comp_1: vec3<f32>;
    var param_178: f32;
    var param_179: f32;
    var param_180: FresnelData;
    var dirAlbedo_3: vec3<f32>;
    var param_181: f32;
    var param_182: f32;
    var param_183: vec3<f32>;
    var param_184: vec3<f32>;
    var avgDirAlbedo_1: f32;
    var avgF0_: f32;
    var param_185: f32;
    var param_186: vec3<f32>;
    var param_187: vec3<f32>;
    var param_188: vec3<f32>;
    var param_189: vec2<f32>;
    var param_190: i32;
    var param_191: FresnelData;
    var param_192: vec3<f32>;
    var comp_2: vec3<f32>;
    var param_193: f32;
    var param_194: f32;
    var param_195: FresnelData;
    var dirAlbedo_4: vec3<f32>;
    var param_196: f32;
    var param_197: f32;
    var param_198: vec3<f32>;
    var param_199: vec3<f32>;
    var avgDirAlbedo_2: f32;
    var Li_2: vec3<f32>;
    var param_200: vec3<f32>;
    var param_201: vec3<f32>;
    var param_202: vec3<f32>;
    var param_203: vec2<f32>;
    var param_204: i32;
    var param_205: FresnelData;
    var phi_4540_: bool;

    let _e356 = (*weight_2);
    if (_e356 < 0.00000001f) {
        return;
    }
    let _e359 = (*closureData_5).closureType;
    let _e361 = (*scatter_mode);
    if ((_e359 != 2i) && (_e361 == 1i)) {
        return;
    }
    let _e365 = (*closureData_5).V;
    V_6 = _e365;
    let _e367 = (*closureData_5).L;
    L_2 = _e367;
    let _e368 = (*retroreflective);
    phi_4540_ = _e368;
    if _e368 {
        let _e370 = (*closureData_5).closureType;
        phi_4540_ = (_e370 != 2i);
    }
    let _e373 = phi_4540_;
    if _e373 {
        let _e374 = V_6;
        let _e376 = (*N_6);
        V_6 = reflect(-(_e374), _e376);
    }
    let _e378 = (*N_6);
    param_155 = _e378;
    let _e379 = V_6;
    param_156 = _e379;
    let _e380 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_155), (&param_156));
    (*N_6) = _e380;
    let _e381 = (*N_6);
    let _e382 = V_6;
    NdotV_12 = clamp(dot(_e381, _e382), 0.00000001f, 1f);
    let _e385 = (*color0_);
    safeColor0_ = max(_e385, vec3(0f));
    let _e388 = (*color82_);
    safeColor82_ = max(_e388, vec3(0f));
    let _e391 = (*color90_);
    safeColor90_ = max(_e391, vec3(0f));
    let _e394 = safeColor0_;
    param_157 = _e394;
    let _e395 = safeColor82_;
    param_158 = _e395;
    let _e396 = safeColor90_;
    param_159 = _e396;
    let _e397 = (*exponent_1);
    param_160 = _e397;
    let _e398 = (*thinfilm_thickness);
    param_161 = _e398;
    let _e399 = (*thinfilm_ior);
    param_162 = _e399;
    let _e400 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_157), (&param_158), (&param_159), (&param_160), (&param_161), (&param_162));
    fd_8 = _e400;
    let _e401 = (*roughness_8);
    safeAlpha = clamp(_e401, vec2(0.00000001f), vec2(1f));
    let _e405 = safeAlpha;
    param_163 = _e405;
    let _e406 = mx_average_alpha_u0028_vf2_u003b((&param_163));
    avgAlpha_1 = _e406;
    let _e408 = (*closureData_5).closureType;
    if (_e408 == 1i) {
        let _e410 = (*X_2);
        let _e411 = (*X_2);
        let _e412 = (*N_6);
        let _e414 = (*N_6);
        (*X_2) = normalize((_e410 - (_e414 * dot(_e411, _e412))));
        let _e418 = (*N_6);
        let _e419 = (*X_2);
        Y_1 = cross(_e418, _e419);
        let _e421 = L_2;
        let _e422 = V_6;
        H_4 = normalize((_e421 + _e422));
        let _e425 = (*N_6);
        let _e426 = L_2;
        NdotL_5 = clamp(dot(_e425, _e426), 0.00000001f, 1f);
        let _e429 = V_6;
        let _e430 = H_4;
        VdotH_1 = clamp(dot(_e429, _e430), 0.00000001f, 1f);
        let _e433 = H_4;
        let _e434 = (*X_2);
        let _e436 = H_4;
        let _e437 = Y_1;
        let _e439 = H_4;
        let _e440 = (*N_6);
        Ht = vec3<f32>(dot(_e433, _e434), dot(_e436, _e437), dot(_e439, _e440));
        let _e443 = VdotH_1;
        param_164 = _e443;
        let _e444 = fd_8;
        param_165 = _e444;
        let _e445 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_164), (&param_165));
        F_1 = _e445;
        let _e446 = Ht;
        param_166 = _e446;
        let _e447 = safeAlpha;
        param_167 = _e447;
        let _e448 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_166), (&param_167));
        D = _e448;
        let _e449 = NdotL_5;
        param_168 = _e449;
        let _e450 = NdotV_12;
        param_169 = _e450;
        let _e451 = avgAlpha_1;
        param_170 = _e451;
        let _e452 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_168), (&param_169), (&param_170));
        G_2 = _e452;
        let _e453 = NdotV_12;
        param_171 = _e453;
        let _e454 = avgAlpha_1;
        param_172 = _e454;
        let _e455 = fd_8;
        param_173 = _e455;
        let _e456 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_171), (&param_172), (&param_173));
        comp = _e456;
        let _e457 = NdotV_12;
        param_174 = _e457;
        let _e458 = avgAlpha_1;
        param_175 = _e458;
        let _e459 = safeColor0_;
        param_176 = _e459;
        let _e460 = safeColor90_;
        param_177 = _e460;
        let _e461 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_174), (&param_175), (&param_176), (&param_177));
        let _e462 = comp;
        dirAlbedo_2 = (_e461 * _e462);
        let _e464 = dirAlbedo_2;
        avgDirAlbedo = dot(_e464, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e466 = avgDirAlbedo;
        let _e467 = (*weight_2);
        (*bsdf_1).throughput = vec3((1f - (_e466 * _e467)));
        let _e472 = D;
        let _e473 = F_1;
        let _e475 = G_2;
        let _e477 = comp;
        let _e480 = (*closureData_5).occlusion;
        let _e482 = (*weight_2);
        let _e484 = NdotV_12;
        (*bsdf_1).response = ((((((_e473 * _e472) * _e475) * _e477) * _e480) * _e482) / vec3((4f * _e484)));
    } else {
        let _e490 = (*closureData_5).closureType;
        if (_e490 == 2i) {
            let _e492 = NdotV_12;
            param_178 = _e492;
            let _e493 = avgAlpha_1;
            param_179 = _e493;
            let _e494 = fd_8;
            param_180 = _e494;
            let _e495 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_178), (&param_179), (&param_180));
            comp_1 = _e495;
            let _e496 = NdotV_12;
            param_181 = _e496;
            let _e497 = avgAlpha_1;
            param_182 = _e497;
            let _e498 = safeColor0_;
            param_183 = _e498;
            let _e499 = safeColor90_;
            param_184 = _e499;
            let _e500 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_181), (&param_182), (&param_183), (&param_184));
            let _e501 = comp_1;
            dirAlbedo_3 = (_e500 * _e501);
            let _e503 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e503, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e505 = avgDirAlbedo_1;
            let _e506 = (*weight_2);
            (*bsdf_1).throughput = vec3((1f - (_e505 * _e506)));
            let _e511 = (*scatter_mode);
            if (_e511 != 0i) {
                let _e513 = safeColor0_;
                avgF0_ = dot(_e513, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e515 = avgF0_;
                param_185 = _e515;
                let _e516 = mx_f0_to_ior_u0028_f1_u003b((&param_185));
                fd_8.ior = vec3(_e516);
                let _e519 = (*N_6);
                param_186 = _e519;
                let _e520 = V_6;
                param_187 = _e520;
                let _e521 = (*X_2);
                param_188 = _e521;
                let _e522 = safeAlpha;
                param_189 = _e522;
                let _e523 = (*distribution_2);
                param_190 = _e523;
                let _e524 = fd_8;
                param_191 = _e524;
                param_192 = vec3<f32>(1f, 1f, 1f);
                let _e525 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_186), (&param_187), (&param_188), (&param_189), (&param_190), (&param_191), (&param_192));
                let _e526 = (*weight_2);
                (*bsdf_1).response = (_e525 * _e526);
            }
        } else {
            let _e530 = (*closureData_5).closureType;
            if (_e530 == 3i) {
                let _e532 = NdotV_12;
                param_193 = _e532;
                let _e533 = avgAlpha_1;
                param_194 = _e533;
                let _e534 = fd_8;
                param_195 = _e534;
                let _e535 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_193), (&param_194), (&param_195));
                comp_2 = _e535;
                let _e536 = NdotV_12;
                param_196 = _e536;
                let _e537 = avgAlpha_1;
                param_197 = _e537;
                let _e538 = safeColor0_;
                param_198 = _e538;
                let _e539 = safeColor90_;
                param_199 = _e539;
                let _e540 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_196), (&param_197), (&param_198), (&param_199));
                let _e541 = comp_2;
                dirAlbedo_4 = (_e540 * _e541);
                let _e543 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e543, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e545 = avgDirAlbedo_2;
                let _e546 = (*weight_2);
                (*bsdf_1).throughput = vec3((1f - (_e545 * _e546)));
                let _e551 = (*N_6);
                param_200 = _e551;
                let _e552 = V_6;
                param_201 = _e552;
                let _e553 = (*X_2);
                param_202 = _e553;
                let _e554 = safeAlpha;
                param_203 = _e554;
                let _e555 = (*distribution_2);
                param_204 = _e555;
                let _e556 = fd_8;
                param_205 = _e556;
                let _e557 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_200), (&param_201), (&param_202), (&param_203), (&param_204), (&param_205));
                Li_2 = _e557;
                let _e558 = Li_2;
                let _e559 = comp_2;
                let _e561 = (*weight_2);
                (*bsdf_1).response = ((_e558 * _e559) * _e561);
            }
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_4: f32;
    var o: f32;
    var param_206: f32;

    let _e268 = (*y_2);
    let _e269 = (*y_2);
    let _e273 = (*y_2);
    let _e274 = (*y_2);
    s_3 = ((_e268 * (0.0206607f + (1.58491f * _e269))) / (0.0379424f + (_e273 * (1.32227f + _e274))));
    let _e279 = (*y_2);
    let _e280 = (*y_2);
    let _e281 = (*y_2);
    let _e282 = (*y_2);
    let _e284 = (*y_2);
    let _e292 = (*y_2);
    m_4 = ((_e279 * (-0.193854f + (_e280 * (-1.14885f + (_e281 * (1.7932f - ((0.95943f * _e282) * _e284))))))) / (0.046391f + _e292));
    let _e295 = (*y_2);
    let _e296 = (*y_2);
    let _e299 = (*y_2);
    let _e303 = (*y_2);
    let _e304 = (*y_2);
    o = ((_e295 * (0.000654023f + ((-0.0207818f + (0.119681f * _e296)) * _e299))) / (1.26264f + (_e303 * (-1.92021f + _e304))));
    let _e309 = (*x_6);
    let _e310 = m_4;
    let _e312 = s_3;
    param_206 = ((_e309 - _e310) / _e312);
    let _e314 = mx_square_u0028_f1_u003b((&param_206));
    let _e317 = s_3;
    let _e320 = o;
    return ((exp((-0.5f * _e314)) / (_e317 * 2.5066283f)) + _e320);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_11: ptr<function, f32>) -> f32 {
    let _e263 = (*cosTheta_11);
    return (max(_e263, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_7: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e264 = (*x_7);
    let _e267 = (*y_3);
    let _e270 = (*y_3);
    let _e272 = (*y_3);
    let _e274 = (*y_3);
    let _e276 = (*x_7);
    let _e279 = (*x_7);
    let _e281 = (*y_3);
    let _e284 = (*y_3);
    let _e286 = (*y_3);
    return (((((sqrt((1f - _e264)) * (_e267 - 1f)) * _e270) * _e272) * _e274) / (((0.0000254053f + (1.71228f * _e276)) - ((1.71506f * _e279) * _e281)) + ((1.34174f * _e284) * _e286)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e264 = (*x_8);
    let _e266 = (*y_4);
    let _e269 = (*y_4);
    let _e271 = (*x_8);
    let _e273 = (*x_8);
    let _e276 = (*x_8);
    let _e278 = (*y_4);
    return ((((2.58126f * _e264) + (0.813703f * _e266)) * _e269) / ((1f + ((0.310327f * _e271) * _e273)) + ((2.60994f * _e276) * _e278)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_7: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_3: vec3<f32>;
    var Y_2: vec3<f32>;

    let _e269 = (*N_7)[2u];
    sign_ = select(1f, -1f, (_e269 < 0f));
    let _e272 = sign_;
    let _e274 = (*N_7)[2u];
    a_3 = (-1f / (_e272 + _e274));
    let _e278 = (*N_7)[0u];
    let _e280 = (*N_7)[1u];
    let _e282 = a_3;
    b = ((_e278 * _e280) * _e282);
    let _e284 = sign_;
    let _e286 = (*N_7)[0u];
    let _e289 = (*N_7)[0u];
    let _e291 = a_3;
    let _e294 = sign_;
    let _e295 = b;
    let _e297 = sign_;
    let _e300 = (*N_7)[0u];
    X_3 = vec3<f32>((1f + (((_e284 * _e286) * _e289) * _e291)), (_e294 * _e295), (-(_e297) * _e300));
    let _e303 = b;
    let _e304 = sign_;
    let _e306 = (*N_7)[1u];
    let _e308 = (*N_7)[1u];
    let _e310 = a_3;
    let _e314 = (*N_7)[1u];
    Y_2 = vec3<f32>(_e303, (_e304 + ((_e306 * _e308) * _e310)), -(_e314));
    let _e317 = X_3;
    let _e318 = Y_2;
    let _e319 = (*N_7);
    return mat3x3<f32>(vec3<f32>(_e317.x, _e317.y, _e317.z), vec3<f32>(_e318.x, _e318.y, _e318.z), vec3<f32>(_e319.x, _e319.y, _e319.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_7: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, NdotV_13: ptr<function, f32>) -> mat3x3<f32> {
    var X_4: vec3<f32>;
    var lenSqr: f32;
    var Y_3: vec3<f32>;
    var param_207: vec3<f32>;

    let _e269 = (*V_7);
    let _e270 = (*N_8);
    let _e271 = (*NdotV_13);
    X_4 = (_e269 - (_e270 * _e271));
    let _e274 = X_4;
    let _e275 = X_4;
    lenSqr = dot(_e274, _e275);
    let _e277 = lenSqr;
    if (_e277 > 0f) {
        let _e279 = lenSqr;
        let _e281 = X_4;
        X_4 = (_e281 * inverseSqrt(_e279));
        let _e283 = (*N_8);
        let _e284 = X_4;
        Y_3 = cross(_e283, _e284);
        let _e286 = X_4;
        let _e287 = Y_3;
        let _e288 = (*N_8);
        return mat3x3<f32>(vec3<f32>(_e286.x, _e286.y, _e286.z), vec3<f32>(_e287.x, _e287.y, _e287.z), vec3<f32>(_e288.x, _e288.y, _e288.z));
    }
    let _e302 = (*N_8);
    param_207 = _e302;
    let _e303 = mx_orthonormal_basis_u0028_vf3_u003b((&param_207));
    return _e303;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_3: ptr<function, vec3<f32>>, V_8: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_14: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_208: vec3<f32>;
    var param_209: vec3<f32>;
    var param_210: f32;
    var w: vec3<f32>;
    var param_211: mat3x3<f32>;
    var param_212: vec3<f32>;
    var aInv: f32;
    var param_213: f32;
    var param_214: f32;
    var bInv: f32;
    var param_215: f32;
    var param_216: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_217: f32;
    var param_218: f32;

    let _e284 = (*V_8);
    param_208 = _e284;
    let _e285 = (*N_9);
    param_209 = _e285;
    let _e286 = (*NdotV_14);
    param_210 = _e286;
    let _e287 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_208), (&param_209), (&param_210));
    toLTC = transpose(_e287);
    let _e289 = toLTC;
    param_211 = _e289;
    let _e290 = (*L_3);
    param_212 = _e290;
    let _e291 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_211), (&param_212));
    w = _e291;
    let _e292 = (*NdotV_14);
    param_213 = _e292;
    let _e293 = (*roughness_9);
    param_214 = _e293;
    let _e294 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_213), (&param_214));
    aInv = _e294;
    let _e295 = (*NdotV_14);
    param_215 = _e295;
    let _e296 = (*roughness_9);
    param_216 = _e296;
    let _e297 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_215), (&param_216));
    bInv = _e297;
    let _e298 = aInv;
    let _e300 = w[0u];
    let _e302 = bInv;
    let _e304 = w[2u];
    let _e307 = aInv;
    let _e309 = w[1u];
    let _e312 = w[2u];
    wo = vec3<f32>(((_e298 * _e300) + (_e302 * _e304)), (_e307 * _e309), _e312);
    let _e314 = wo;
    let _e315 = wo;
    lenSqr_1 = dot(_e314, _e315);
    let _e318 = wo[2u];
    param_217 = _e318;
    let _e319 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_217));
    let _e320 = aInv;
    let _e321 = lenSqr_1;
    param_218 = (_e320 / _e321);
    let _e323 = mx_square_u0028_f1_u003b((&param_218));
    return (_e319 * _e323);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_15: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_219: f32;
    var param_220: f32;

    let _e267 = (*NdotV_15);
    let _e270 = (*roughness_10);
    let _e273 = (*NdotV_15);
    let _e275 = (*roughness_10);
    let _e278 = (*NdotV_15);
    param_219 = _e278;
    let _e279 = mx_square_u0028_f1_u003b((&param_219));
    let _e282 = (*roughness_10);
    param_220 = _e282;
    let _e283 = mx_square_u0028_f1_u003b((&param_220));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e267)) + (vec2<f32>(799.08826f, 442.7821f) * _e270)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e273) * _e275)) + (vec2<f32>(60.28956f, 121.81241f) * _e279)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e283));
    let _e287 = r_2[0u];
    let _e289 = r_2[1u];
    return (_e287 / _e289);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_16: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var dirAlbedo_5: f32;
    var param_221: f32;
    var param_222: f32;

    let _e267 = (*NdotV_16);
    param_221 = _e267;
    let _e268 = (*roughness_11);
    param_222 = _e268;
    let _e269 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_221), (&param_222));
    dirAlbedo_5 = _e269;
    let _e270 = dirAlbedo_5;
    return clamp(_e270, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e267 = (*roughness_12);
    invRoughness = (1f / max(_e267, 0.005f));
    let _e270 = (*NdotH);
    let _e271 = (*NdotH);
    cos2_ = (_e270 * _e271);
    let _e273 = cos2_;
    sin2_ = (1f - _e273);
    let _e275 = invRoughness;
    let _e277 = sin2_;
    let _e278 = invRoughness;
    return (((2f + _e275) * pow(_e277, (_e278 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_6: ptr<function, f32>, NdotV_17: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var D_1: f32;
    var param_223: f32;
    var param_224: f32;
    var F_2: f32;
    var G_3: f32;

    let _e271 = (*NdotH_1);
    param_223 = _e271;
    let _e272 = (*roughness_13);
    param_224 = _e272;
    let _e273 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_223), (&param_224));
    D_1 = _e273;
    F_2 = 1f;
    G_3 = 1f;
    let _e274 = D_1;
    let _e275 = F_2;
    let _e277 = G_3;
    let _e279 = (*NdotL_6);
    let _e280 = (*NdotV_17);
    let _e282 = (*NdotL_6);
    let _e283 = (*NdotV_17);
    return (((_e274 * _e275) * _e277) / (4f * ((_e279 + _e280) - (_e282 * _e283))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, weight_3: ptr<function, f32>, color_4: ptr<function, vec3<f32>>, roughness_14: ptr<function, f32>, N_10: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_2: ptr<function, BSDF>) {
    var V_9: vec3<f32>;
    var L_4: vec3<f32>;
    var param_225: vec3<f32>;
    var param_226: vec3<f32>;
    var NdotV_18: f32;
    var H_5: vec3<f32>;
    var NdotL_7: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_227: f32;
    var param_228: f32;
    var param_229: f32;
    var param_230: f32;
    var dirAlbedo_6: f32;
    var param_231: f32;
    var param_232: f32;
    var fr_1: vec3<f32>;
    var param_233: vec3<f32>;
    var param_234: vec3<f32>;
    var param_235: vec3<f32>;
    var param_236: f32;
    var param_237: f32;
    var param_238: f32;
    var param_239: f32;
    var dirAlbedo_7: f32;
    var param_240: f32;
    var param_241: f32;
    var param_242: f32;
    var param_243: f32;
    var Li_3: vec3<f32>;
    var param_244: vec3<f32>;

    let _e300 = (*weight_3);
    if (_e300 < 0.00000001f) {
        return;
    }
    let _e303 = (*closureData_6).V;
    V_9 = _e303;
    let _e305 = (*closureData_6).L;
    L_4 = _e305;
    let _e306 = (*N_10);
    param_225 = _e306;
    let _e307 = V_9;
    param_226 = _e307;
    let _e308 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_225), (&param_226));
    (*N_10) = _e308;
    let _e309 = (*N_10);
    let _e310 = V_9;
    NdotV_18 = clamp(dot(_e309, _e310), 0.00000001f, 1f);
    let _e314 = (*closureData_6).closureType;
    if (_e314 == 1i) {
        let _e316 = (*mode);
        if (_e316 == 0i) {
            let _e318 = L_4;
            let _e319 = V_9;
            H_5 = normalize((_e318 + _e319));
            let _e322 = (*N_10);
            let _e323 = L_4;
            NdotL_7 = clamp(dot(_e322, _e323), 0.00000001f, 1f);
            let _e326 = (*N_10);
            let _e327 = H_5;
            NdotH_2 = clamp(dot(_e326, _e327), 0.00000001f, 1f);
            let _e330 = (*color_4);
            let _e331 = NdotL_7;
            param_227 = _e331;
            let _e332 = NdotV_18;
            param_228 = _e332;
            let _e333 = NdotH_2;
            param_229 = _e333;
            let _e334 = (*roughness_14);
            param_230 = _e334;
            let _e335 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_227), (&param_228), (&param_229), (&param_230));
            fr = (_e330 * _e335);
            let _e337 = NdotV_18;
            param_231 = _e337;
            let _e338 = (*roughness_14);
            param_232 = _e338;
            let _e339 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_231), (&param_232));
            dirAlbedo_6 = _e339;
            let _e340 = fr;
            let _e341 = NdotL_7;
            let _e344 = (*closureData_6).occlusion;
            let _e346 = (*weight_3);
            (*bsdf_2).response = (((_e340 * _e341) * _e344) * _e346);
        } else {
            let _e349 = (*roughness_14);
            (*roughness_14) = clamp(_e349, 0.01f, 1f);
            let _e351 = (*color_4);
            let _e352 = L_4;
            param_233 = _e352;
            let _e353 = V_9;
            param_234 = _e353;
            let _e354 = (*N_10);
            param_235 = _e354;
            let _e355 = NdotV_18;
            param_236 = _e355;
            let _e356 = (*roughness_14);
            param_237 = _e356;
            let _e357 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_233), (&param_234), (&param_235), (&param_236), (&param_237));
            fr_1 = (_e351 * _e357);
            let _e359 = NdotV_18;
            param_238 = _e359;
            let _e360 = (*roughness_14);
            param_239 = _e360;
            let _e361 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_238), (&param_239));
            dirAlbedo_6 = _e361;
            let _e362 = dirAlbedo_6;
            let _e363 = fr_1;
            let _e366 = (*closureData_6).occlusion;
            let _e368 = (*weight_3);
            (*bsdf_2).response = (((_e363 * _e362) * _e366) * _e368);
        }
        let _e371 = dirAlbedo_6;
        let _e372 = (*weight_3);
        (*bsdf_2).throughput = vec3((1f - (_e371 * _e372)));
    } else {
        let _e378 = (*closureData_6).closureType;
        if (_e378 == 3i) {
            let _e380 = (*mode);
            if (_e380 == 0i) {
                let _e382 = NdotV_18;
                param_240 = _e382;
                let _e383 = (*roughness_14);
                param_241 = _e383;
                let _e384 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_240), (&param_241));
                dirAlbedo_7 = _e384;
            } else {
                let _e385 = (*roughness_14);
                (*roughness_14) = clamp(_e385, 0.01f, 1f);
                let _e387 = NdotV_18;
                param_242 = _e387;
                let _e388 = (*roughness_14);
                param_243 = _e388;
                let _e389 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_242), (&param_243));
                dirAlbedo_7 = _e389;
            }
            let _e390 = (*N_10);
            param_244 = _e390;
            let _e391 = mx_environment_irradiance_u0028_vf3_u003b((&param_244));
            Li_3 = _e391;
            let _e392 = Li_3;
            let _e393 = (*color_4);
            let _e395 = dirAlbedo_7;
            let _e397 = (*weight_3);
            (*bsdf_2).response = (((_e392 * _e393) * _e395) * _e397);
            let _e400 = dirAlbedo_7;
            let _e401 = (*weight_3);
            (*bsdf_2).throughput = vec3((1f - (_e400 * _e401)));
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_245: f32;

    let _e264 = (*ior_3);
    let _e266 = (*ior_3);
    param_245 = ((_e264 - 1f) / (_e266 + 1f));
    let _e269 = mx_square_u0028_f1_u003b((&param_245));
    return _e269;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e267 = (*tf_thickness_1);
    fd_9.airy = (_e267 > 0f);
    let _e270 = (*ior_4);
    fd_9.ior = vec3(_e270);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e278 = (*tf_thickness_1);
    fd_9.tf_thickness = _e278;
    let _e280 = (*tf_ior_1);
    fd_9.tf_ior = _e280;
    fd_9.refraction = false;
    let _e283 = fd_9;
    return _e283;
}

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, weight_4: ptr<function, f32>, tint_1: ptr<function, vec3<f32>>, ior_5: ptr<function, f32>, roughness_15: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, X_5: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode_1: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_10: vec3<f32>;
    var L_5: vec3<f32>;
    var param_246: vec3<f32>;
    var param_247: vec3<f32>;
    var NdotV_19: f32;
    var fd_10: FresnelData;
    var param_248: f32;
    var param_249: f32;
    var param_250: f32;
    var F0_7: f32;
    var param_251: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_252: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_4: vec3<f32>;
    var H_6: vec3<f32>;
    var NdotL_8: f32;
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
    var comp_3: vec3<f32>;
    var param_260: f32;
    var param_261: f32;
    var param_262: FresnelData;
    var dirAlbedo_8: vec3<f32>;
    var param_263: f32;
    var param_264: f32;
    var param_265: f32;
    var param_266: f32;
    var comp_4: vec3<f32>;
    var param_267: f32;
    var param_268: f32;
    var param_269: FresnelData;
    var dirAlbedo_9: vec3<f32>;
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
    var comp_5: vec3<f32>;
    var param_281: f32;
    var param_282: f32;
    var param_283: FresnelData;
    var dirAlbedo_10: vec3<f32>;
    var param_284: f32;
    var param_285: f32;
    var param_286: f32;
    var param_287: f32;
    var Li_4: vec3<f32>;
    var param_288: vec3<f32>;
    var param_289: vec3<f32>;
    var param_290: vec3<f32>;
    var param_291: vec2<f32>;
    var param_292: i32;
    var param_293: FresnelData;
    var phi_3357_: bool;

    let _e346 = (*weight_4);
    if (_e346 < 0.00000001f) {
        return;
    }
    let _e349 = (*closureData_7).closureType;
    let _e351 = (*scatter_mode_1);
    if ((_e349 != 2i) && (_e351 == 1i)) {
        return;
    }
    let _e355 = (*closureData_7).V;
    V_10 = _e355;
    let _e357 = (*closureData_7).L;
    L_5 = _e357;
    let _e358 = (*retroreflective_1);
    phi_3357_ = _e358;
    if _e358 {
        let _e360 = (*closureData_7).closureType;
        phi_3357_ = (_e360 != 2i);
    }
    let _e363 = phi_3357_;
    if _e363 {
        let _e364 = V_10;
        let _e366 = (*N_11);
        V_10 = reflect(-(_e364), _e366);
    }
    let _e368 = (*N_11);
    param_246 = _e368;
    let _e369 = V_10;
    param_247 = _e369;
    let _e370 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_246), (&param_247));
    (*N_11) = _e370;
    let _e371 = (*N_11);
    let _e372 = V_10;
    NdotV_19 = clamp(dot(_e371, _e372), 0.00000001f, 1f);
    let _e375 = (*ior_5);
    param_248 = _e375;
    let _e376 = (*thinfilm_thickness_1);
    param_249 = _e376;
    let _e377 = (*thinfilm_ior_1);
    param_250 = _e377;
    let _e378 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_248), (&param_249), (&param_250));
    fd_10 = _e378;
    let _e379 = (*ior_5);
    param_251 = _e379;
    let _e380 = mx_ior_to_f0_u0028_f1_u003b((&param_251));
    F0_7 = _e380;
    let _e381 = (*roughness_15);
    safeAlpha_1 = clamp(_e381, vec2(0.00000001f), vec2(1f));
    let _e385 = safeAlpha_1;
    param_252 = _e385;
    let _e386 = mx_average_alpha_u0028_vf2_u003b((&param_252));
    avgAlpha_2 = _e386;
    let _e387 = (*tint_1);
    safeTint = max(_e387, vec3(0f));
    let _e391 = (*closureData_7).closureType;
    if (_e391 == 1i) {
        let _e393 = (*X_5);
        let _e394 = (*X_5);
        let _e395 = (*N_11);
        let _e397 = (*N_11);
        (*X_5) = normalize((_e393 - (_e397 * dot(_e394, _e395))));
        let _e401 = (*N_11);
        let _e402 = (*X_5);
        Y_4 = cross(_e401, _e402);
        let _e404 = L_5;
        let _e405 = V_10;
        H_6 = normalize((_e404 + _e405));
        let _e408 = (*N_11);
        let _e409 = L_5;
        NdotL_8 = clamp(dot(_e408, _e409), 0.00000001f, 1f);
        let _e412 = V_10;
        let _e413 = H_6;
        VdotH_2 = clamp(dot(_e412, _e413), 0.00000001f, 1f);
        let _e416 = H_6;
        let _e417 = (*X_5);
        let _e419 = H_6;
        let _e420 = Y_4;
        let _e422 = H_6;
        let _e423 = (*N_11);
        Ht_1 = vec3<f32>(dot(_e416, _e417), dot(_e419, _e420), dot(_e422, _e423));
        let _e426 = VdotH_2;
        param_253 = _e426;
        let _e427 = fd_10;
        param_254 = _e427;
        let _e428 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254));
        F_3 = _e428;
        let _e429 = Ht_1;
        param_255 = _e429;
        let _e430 = safeAlpha_1;
        param_256 = _e430;
        let _e431 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_255), (&param_256));
        D_2 = _e431;
        let _e432 = NdotL_8;
        param_257 = _e432;
        let _e433 = NdotV_19;
        param_258 = _e433;
        let _e434 = avgAlpha_2;
        param_259 = _e434;
        let _e435 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_257), (&param_258), (&param_259));
        G_4 = _e435;
        let _e436 = NdotV_19;
        param_260 = _e436;
        let _e437 = avgAlpha_2;
        param_261 = _e437;
        let _e438 = fd_10;
        param_262 = _e438;
        let _e439 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_260), (&param_261), (&param_262));
        comp_3 = _e439;
        let _e440 = NdotV_19;
        param_263 = _e440;
        let _e441 = avgAlpha_2;
        param_264 = _e441;
        let _e442 = F0_7;
        param_265 = _e442;
        param_266 = 1f;
        let _e443 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_263), (&param_264), (&param_265), (&param_266));
        let _e444 = comp_3;
        dirAlbedo_8 = (_e444 * _e443);
        let _e446 = dirAlbedo_8;
        let _e447 = (*weight_4);
        (*bsdf_3).throughput = (vec3(1f) - (_e446 * _e447));
        let _e452 = D_2;
        let _e453 = F_3;
        let _e455 = G_4;
        let _e457 = comp_3;
        let _e459 = safeTint;
        let _e462 = (*closureData_7).occlusion;
        let _e464 = (*weight_4);
        let _e466 = NdotV_19;
        (*bsdf_3).response = (((((((_e453 * _e452) * _e455) * _e457) * _e459) * _e462) * _e464) / vec3((4f * _e466)));
    } else {
        let _e472 = (*closureData_7).closureType;
        if (_e472 == 2i) {
            let _e474 = NdotV_19;
            param_267 = _e474;
            let _e475 = avgAlpha_2;
            param_268 = _e475;
            let _e476 = fd_10;
            param_269 = _e476;
            let _e477 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
            comp_4 = _e477;
            let _e478 = NdotV_19;
            param_270 = _e478;
            let _e479 = avgAlpha_2;
            param_271 = _e479;
            let _e480 = F0_7;
            param_272 = _e480;
            param_273 = 1f;
            let _e481 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
            let _e482 = comp_4;
            dirAlbedo_9 = (_e482 * _e481);
            let _e484 = dirAlbedo_9;
            let _e485 = (*weight_4);
            (*bsdf_3).throughput = (vec3(1f) - (_e484 * _e485));
            let _e490 = (*scatter_mode_1);
            if (_e490 != 0i) {
                let _e492 = (*N_11);
                param_274 = _e492;
                let _e493 = V_10;
                param_275 = _e493;
                let _e494 = (*X_5);
                param_276 = _e494;
                let _e495 = safeAlpha_1;
                param_277 = _e495;
                let _e496 = (*distribution_3);
                param_278 = _e496;
                let _e497 = fd_10;
                param_279 = _e497;
                let _e498 = safeTint;
                param_280 = _e498;
                let _e499 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279), (&param_280));
                let _e500 = (*weight_4);
                (*bsdf_3).response = (_e499 * _e500);
            }
        } else {
            let _e504 = (*closureData_7).closureType;
            if (_e504 == 3i) {
                let _e506 = NdotV_19;
                param_281 = _e506;
                let _e507 = avgAlpha_2;
                param_282 = _e507;
                let _e508 = fd_10;
                param_283 = _e508;
                let _e509 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_281), (&param_282), (&param_283));
                comp_5 = _e509;
                let _e510 = NdotV_19;
                param_284 = _e510;
                let _e511 = avgAlpha_2;
                param_285 = _e511;
                let _e512 = F0_7;
                param_286 = _e512;
                param_287 = 1f;
                let _e513 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_284), (&param_285), (&param_286), (&param_287));
                let _e514 = comp_5;
                dirAlbedo_10 = (_e514 * _e513);
                let _e516 = dirAlbedo_10;
                let _e517 = (*weight_4);
                (*bsdf_3).throughput = (vec3(1f) - (_e516 * _e517));
                let _e522 = (*N_11);
                param_288 = _e522;
                let _e523 = V_10;
                param_289 = _e523;
                let _e524 = (*X_5);
                param_290 = _e524;
                let _e525 = safeAlpha_1;
                param_291 = _e525;
                let _e526 = (*distribution_3);
                param_292 = _e526;
                let _e527 = fd_10;
                param_293 = _e527;
                let _e528 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_288), (&param_289), (&param_290), (&param_291), (&param_292), (&param_293));
                Li_4 = _e528;
                let _e529 = Li_4;
                let _e530 = safeTint;
                let _e532 = comp_5;
                let _e534 = (*weight_4);
                (*bsdf_3).response = (((_e529 * _e530) * _e532) * _e534);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_6: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, occlusion: ptr<function, f32>) -> ClosureData {
    let _e268 = (*closureType);
    let _e269 = (*L_6);
    let _e270 = (*V_11);
    let _e271 = (*N_12);
    let _e272 = (*P);
    let _e273 = (*occlusion);
    return ClosureData(_e268, _e269, _e270, _e271, _e272, _e273);
}

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_4: ptr<function, lightshader>) {
    (*result_4).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_4).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e263 = unnamed.mtlxLightCount;
    return min(_e263, 1i);
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_5: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e270 = (*axis);
    (*axis) = normalize(_e270);
    let _e272 = (*amount);
    rotationRadians = radians(_e272);
    let _e274 = rotationRadians;
    s_4 = sin(_e274);
    let _e276 = rotationRadians;
    c_3 = cos(_e276);
    let _e278 = c_3;
    oc = (1f - _e278);
    let _e280 = (*_in);
    let _e281 = c_3;
    let _e283 = (*_in);
    let _e284 = (*axis);
    let _e286 = s_4;
    let _e289 = (*axis);
    let _e290 = (*axis);
    let _e291 = (*_in);
    let _e294 = oc;
    (*result_5) = (((_e280 * _e281) + (cross(_e283, _e284) * _e286)) + ((_e289 * dot(_e290, _e291)) * _e294));
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_2: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e270 = (*in1_2)[0u];
    N_extract_0_out = _e270;
    let _e272 = (*in1_2)[1u];
    N_extract_1_out = _e272;
    let _e274 = (*in1_2)[2u];
    N_extract_2_out = _e274;
    let _e275 = N_extract_0_out;
    (*outr) = _e275;
    let _e276 = N_extract_1_out;
    (*outg) = _e276;
    let _e277 = N_extract_2_out;
    (*outb) = _e277;
    return;
}

fn NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b(in1_3: ptr<function, vec3<f32>>, mtlxRasterOut: ptr<function, f32>) {
    var N_separate_outr: f32;
    var N_separate_outg: f32;
    var N_separate_outb: f32;
    var param_294: vec3<f32>;
    var param_295: f32;
    var param_296: f32;
    var param_297: f32;
    var N_max_01_out: f32;
    var N_max_out: f32;

    N_separate_outr = 0f;
    N_separate_outg = 0f;
    N_separate_outb = 0f;
    let _e273 = (*in1_3);
    param_294 = _e273;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_294), (&param_295), (&param_296), (&param_297));
    let _e274 = param_295;
    N_separate_outr = _e274;
    let _e275 = param_296;
    N_separate_outg = _e275;
    let _e276 = param_297;
    N_separate_outb = _e276;
    let _e277 = N_separate_outr;
    let _e278 = N_separate_outg;
    N_max_01_out = max(_e277, _e278);
    let _e280 = N_max_01_out;
    let _e281 = N_separate_outb;
    N_max_out = max(_e280, _e281);
    let _e283 = N_max_out;
    (*mtlxRasterOut) = _e283;
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy: ptr<function, f32>, result_6: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e267 = (*roughness_16);
    let _e268 = (*roughness_16);
    roughness_sqr = clamp((_e267 * _e268), 0.00000001f, 1f);
    let _e271 = (*anisotropy);
    if (_e271 > 0f) {
        let _e273 = (*anisotropy);
        aspect = sqrt((1f - clamp(_e273, 0f, 0.98f)));
        let _e277 = roughness_sqr;
        let _e278 = aspect;
        (*result_6)[0u] = min((_e277 / _e278), 1f);
        let _e282 = roughness_sqr;
        let _e283 = aspect;
        (*result_6)[1u] = (_e282 * _e283);
    } else {
        let _e286 = roughness_sqr;
        (*result_6)[0u] = _e286;
        let _e288 = roughness_sqr;
        (*result_6)[1u] = _e288;
    }
    return;
}

fn IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_color: ptr<function, vec3<f32>>, metallic: ptr<function, f32>, roughness_17: ptr<function, f32>, normal: ptr<function, vec3<f32>>, tangent: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>, transmission: ptr<function, f32>, specular: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, ior_6: ptr<function, f32>, alpha_12: ptr<function, f32>, alpha_mode: ptr<function, i32>, alpha_cutoff: ptr<function, f32>, iridescence: ptr<function, f32>, iridescence_ior: ptr<function, f32>, iridescence_thickness: ptr<function, f32>, sheen_color: ptr<function, vec3<f32>>, sheen_roughness: ptr<function, f32>, clearcoat: ptr<function, f32>, clearcoat_roughness: ptr<function, f32>, clearcoat_normal: ptr<function, vec3<f32>>, emissive: ptr<function, vec3<f32>>, emissive_strength: ptr<function, f32>, thickness: ptr<function, f32>, attenuation_distance: ptr<function, f32>, attenuation_color: ptr<function, vec3<f32>>, anisotropy_strength: ptr<function, f32>, anisotropy_rotation: ptr<function, f32>, dispersion: ptr<function, f32>, mtlxRasterOut_1: ptr<function, surfaceshader>) {
    var clearcoat_roughness_uv_out: vec2<f32>;
    var param_298: f32;
    var param_299: f32;
    var param_300: vec2<f32>;
    var sheen_intensity_out: f32;
    var param_301: vec3<f32>;
    var param_302: f32;
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
    var param_303: vec3<f32>;
    var param_304: f32;
    var param_305: vec3<f32>;
    var param_306: vec3<f32>;
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
    var P_1: vec3<f32>;
    var L_7: vec3<f32>;
    var occlusion_2: f32;
    var surfaceOpacity: f32;
    var numLights: i32;
    var activeLightIndex: i32;
    var lightShader: lightshader;
    var param_307: i32;
    var param_308: vec3<f32>;
    var param_309: lightshader;
    var closureData_8: ClosureData;
    var param_310: i32;
    var param_311: vec3<f32>;
    var param_312: vec3<f32>;
    var param_313: vec3<f32>;
    var param_314: vec3<f32>;
    var param_315: f32;
    var clearcoat_bsdf_out: BSDF;
    var param_316: ClosureData;
    var param_317: f32;
    var param_318: vec3<f32>;
    var param_319: f32;
    var param_320: vec2<f32>;
    var param_321: bool;
    var param_322: f32;
    var param_323: f32;
    var param_324: vec3<f32>;
    var param_325: vec3<f32>;
    var param_326: i32;
    var param_327: i32;
    var param_328: BSDF;
    var sheen_bsdf_out: BSDF;
    var param_329: ClosureData;
    var param_330: f32;
    var param_331: vec3<f32>;
    var param_332: f32;
    var param_333: vec3<f32>;
    var param_334: i32;
    var param_335: BSDF;
    var tf_metal_bsdf_out: BSDF;
    var param_336: ClosureData;
    var param_337: f32;
    var param_338: vec3<f32>;
    var param_339: vec3<f32>;
    var param_340: vec3<f32>;
    var param_341: f32;
    var param_342: vec2<f32>;
    var param_343: bool;
    var param_344: f32;
    var param_345: f32;
    var param_346: vec3<f32>;
    var param_347: vec3<f32>;
    var param_348: i32;
    var param_349: i32;
    var param_350: BSDF;
    var metal_bsdf_out: BSDF;
    var param_351: ClosureData;
    var param_352: f32;
    var param_353: vec3<f32>;
    var param_354: vec3<f32>;
    var param_355: vec3<f32>;
    var param_356: f32;
    var param_357: vec2<f32>;
    var param_358: bool;
    var param_359: f32;
    var param_360: f32;
    var param_361: vec3<f32>;
    var param_362: vec3<f32>;
    var param_363: i32;
    var param_364: i32;
    var param_365: BSDF;
    var mix_iridescent_metal_bsdf_add_out: BSDF;
    var param_366: ClosureData;
    var param_367: BSDF;
    var param_368: BSDF;
    var param_369: BSDF;
    var base_mix_fg_mul_out: BSDF;
    var param_370: ClosureData;
    var param_371: BSDF;
    var param_372: f32;
    var param_373: BSDF;
    var tf_reflection_bsdf_out: BSDF;
    var param_374: ClosureData;
    var param_375: f32;
    var param_376: vec3<f32>;
    var param_377: vec3<f32>;
    var param_378: vec3<f32>;
    var param_379: f32;
    var param_380: vec2<f32>;
    var param_381: bool;
    var param_382: f32;
    var param_383: f32;
    var param_384: vec3<f32>;
    var param_385: vec3<f32>;
    var param_386: i32;
    var param_387: i32;
    var param_388: BSDF;
    var reflection_bsdf_out: BSDF;
    var param_389: ClosureData;
    var param_390: f32;
    var param_391: vec3<f32>;
    var param_392: vec3<f32>;
    var param_393: vec3<f32>;
    var param_394: f32;
    var param_395: vec2<f32>;
    var param_396: bool;
    var param_397: f32;
    var param_398: f32;
    var param_399: vec3<f32>;
    var param_400: vec3<f32>;
    var param_401: i32;
    var param_402: i32;
    var param_403: BSDF;
    var mix_iridescent_dielectric_reflection_add_out: BSDF;
    var param_404: ClosureData;
    var param_405: BSDF;
    var param_406: BSDF;
    var param_407: BSDF;
    var transmission_bsdf_out: BSDF;
    var param_408: ClosureData;
    var param_409: f32;
    var param_410: vec3<f32>;
    var param_411: f32;
    var param_412: vec2<f32>;
    var param_413: bool;
    var param_414: f32;
    var param_415: f32;
    var param_416: vec3<f32>;
    var param_417: vec3<f32>;
    var param_418: i32;
    var param_419: i32;
    var param_420: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_421: ClosureData;
    var param_422: f32;
    var param_423: vec3<f32>;
    var param_424: f32;
    var param_425: vec3<f32>;
    var param_426: bool;
    var param_427: BSDF;
    var transmission_mix_add_out: BSDF;
    var param_428: ClosureData;
    var param_429: BSDF;
    var param_430: BSDF;
    var param_431: BSDF;
    var iridescent_dielectric_bsdf_out: BSDF;
    var param_432: ClosureData;
    var param_433: BSDF;
    var param_434: BSDF;
    var param_435: BSDF;
    var base_mix_bg_mul_out: BSDF;
    var param_436: ClosureData;
    var param_437: BSDF;
    var param_438: f32;
    var param_439: BSDF;
    var base_mix_add_out: BSDF;
    var param_440: ClosureData;
    var param_441: BSDF;
    var param_442: BSDF;
    var param_443: BSDF;
    var sheen_layer_out: BSDF;
    var param_444: ClosureData;
    var param_445: BSDF;
    var param_446: BSDF;
    var param_447: BSDF;
    var clearcoat_layer_out: BSDF;
    var param_448: ClosureData;
    var param_449: BSDF;
    var param_450: BSDF;
    var param_451: BSDF;
    var closureData_9: ClosureData;
    var param_452: i32;
    var param_453: vec3<f32>;
    var param_454: vec3<f32>;
    var param_455: vec3<f32>;
    var param_456: vec3<f32>;
    var param_457: f32;
    var clearcoat_bsdf_out_1: BSDF;
    var param_458: ClosureData;
    var param_459: f32;
    var param_460: vec3<f32>;
    var param_461: f32;
    var param_462: vec2<f32>;
    var param_463: bool;
    var param_464: f32;
    var param_465: f32;
    var param_466: vec3<f32>;
    var param_467: vec3<f32>;
    var param_468: i32;
    var param_469: i32;
    var param_470: BSDF;
    var sheen_bsdf_out_1: BSDF;
    var param_471: ClosureData;
    var param_472: f32;
    var param_473: vec3<f32>;
    var param_474: f32;
    var param_475: vec3<f32>;
    var param_476: i32;
    var param_477: BSDF;
    var tf_metal_bsdf_out_1: BSDF;
    var param_478: ClosureData;
    var param_479: f32;
    var param_480: vec3<f32>;
    var param_481: vec3<f32>;
    var param_482: vec3<f32>;
    var param_483: f32;
    var param_484: vec2<f32>;
    var param_485: bool;
    var param_486: f32;
    var param_487: f32;
    var param_488: vec3<f32>;
    var param_489: vec3<f32>;
    var param_490: i32;
    var param_491: i32;
    var param_492: BSDF;
    var metal_bsdf_out_1: BSDF;
    var param_493: ClosureData;
    var param_494: f32;
    var param_495: vec3<f32>;
    var param_496: vec3<f32>;
    var param_497: vec3<f32>;
    var param_498: f32;
    var param_499: vec2<f32>;
    var param_500: bool;
    var param_501: f32;
    var param_502: f32;
    var param_503: vec3<f32>;
    var param_504: vec3<f32>;
    var param_505: i32;
    var param_506: i32;
    var param_507: BSDF;
    var mix_iridescent_metal_bsdf_add_out_1: BSDF;
    var param_508: ClosureData;
    var param_509: BSDF;
    var param_510: BSDF;
    var param_511: BSDF;
    var base_mix_fg_mul_out_1: BSDF;
    var param_512: ClosureData;
    var param_513: BSDF;
    var param_514: f32;
    var param_515: BSDF;
    var tf_reflection_bsdf_out_1: BSDF;
    var param_516: ClosureData;
    var param_517: f32;
    var param_518: vec3<f32>;
    var param_519: vec3<f32>;
    var param_520: vec3<f32>;
    var param_521: f32;
    var param_522: vec2<f32>;
    var param_523: bool;
    var param_524: f32;
    var param_525: f32;
    var param_526: vec3<f32>;
    var param_527: vec3<f32>;
    var param_528: i32;
    var param_529: i32;
    var param_530: BSDF;
    var reflection_bsdf_out_1: BSDF;
    var param_531: ClosureData;
    var param_532: f32;
    var param_533: vec3<f32>;
    var param_534: vec3<f32>;
    var param_535: vec3<f32>;
    var param_536: f32;
    var param_537: vec2<f32>;
    var param_538: bool;
    var param_539: f32;
    var param_540: f32;
    var param_541: vec3<f32>;
    var param_542: vec3<f32>;
    var param_543: i32;
    var param_544: i32;
    var param_545: BSDF;
    var mix_iridescent_dielectric_reflection_add_out_1: BSDF;
    var param_546: ClosureData;
    var param_547: BSDF;
    var param_548: BSDF;
    var param_549: BSDF;
    var transmission_bsdf_out_1: BSDF;
    var param_550: ClosureData;
    var param_551: f32;
    var param_552: vec3<f32>;
    var param_553: f32;
    var param_554: vec2<f32>;
    var param_555: bool;
    var param_556: f32;
    var param_557: f32;
    var param_558: vec3<f32>;
    var param_559: vec3<f32>;
    var param_560: i32;
    var param_561: i32;
    var param_562: BSDF;
    var diffuse_bsdf_out_1: BSDF;
    var param_563: ClosureData;
    var param_564: f32;
    var param_565: vec3<f32>;
    var param_566: f32;
    var param_567: vec3<f32>;
    var param_568: bool;
    var param_569: BSDF;
    var transmission_mix_add_out_1: BSDF;
    var param_570: ClosureData;
    var param_571: BSDF;
    var param_572: BSDF;
    var param_573: BSDF;
    var iridescent_dielectric_bsdf_out_1: BSDF;
    var param_574: ClosureData;
    var param_575: BSDF;
    var param_576: BSDF;
    var param_577: BSDF;
    var base_mix_bg_mul_out_1: BSDF;
    var param_578: ClosureData;
    var param_579: BSDF;
    var param_580: f32;
    var param_581: BSDF;
    var base_mix_add_out_1: BSDF;
    var param_582: ClosureData;
    var param_583: BSDF;
    var param_584: BSDF;
    var param_585: BSDF;
    var sheen_layer_out_1: BSDF;
    var param_586: ClosureData;
    var param_587: BSDF;
    var param_588: BSDF;
    var param_589: BSDF;
    var clearcoat_layer_out_1: BSDF;
    var param_590: ClosureData;
    var param_591: BSDF;
    var param_592: BSDF;
    var param_593: BSDF;
    var closureData_10: ClosureData;
    var param_594: i32;
    var param_595: vec3<f32>;
    var param_596: vec3<f32>;
    var param_597: vec3<f32>;
    var param_598: vec3<f32>;
    var param_599: f32;
    var emission_out: vec3<f32>;
    var param_600: ClosureData;
    var param_601: vec3<f32>;
    var param_602: vec3<f32>;
    var closureData_11: ClosureData;
    var param_603: i32;
    var param_604: vec3<f32>;
    var param_605: vec3<f32>;
    var param_606: vec3<f32>;
    var param_607: vec3<f32>;
    var param_608: f32;
    var clearcoat_bsdf_out_2: BSDF;
    var param_609: ClosureData;
    var param_610: f32;
    var param_611: vec3<f32>;
    var param_612: f32;
    var param_613: vec2<f32>;
    var param_614: bool;
    var param_615: f32;
    var param_616: f32;
    var param_617: vec3<f32>;
    var param_618: vec3<f32>;
    var param_619: i32;
    var param_620: i32;
    var param_621: BSDF;
    var sheen_bsdf_out_2: BSDF;
    var param_622: ClosureData;
    var param_623: f32;
    var param_624: vec3<f32>;
    var param_625: f32;
    var param_626: vec3<f32>;
    var param_627: i32;
    var param_628: BSDF;
    var tf_metal_bsdf_out_2: BSDF;
    var param_629: ClosureData;
    var param_630: f32;
    var param_631: vec3<f32>;
    var param_632: vec3<f32>;
    var param_633: vec3<f32>;
    var param_634: f32;
    var param_635: vec2<f32>;
    var param_636: bool;
    var param_637: f32;
    var param_638: f32;
    var param_639: vec3<f32>;
    var param_640: vec3<f32>;
    var param_641: i32;
    var param_642: i32;
    var param_643: BSDF;
    var metal_bsdf_out_2: BSDF;
    var param_644: ClosureData;
    var param_645: f32;
    var param_646: vec3<f32>;
    var param_647: vec3<f32>;
    var param_648: vec3<f32>;
    var param_649: f32;
    var param_650: vec2<f32>;
    var param_651: bool;
    var param_652: f32;
    var param_653: f32;
    var param_654: vec3<f32>;
    var param_655: vec3<f32>;
    var param_656: i32;
    var param_657: i32;
    var param_658: BSDF;
    var mix_iridescent_metal_bsdf_add_out_2: BSDF;
    var param_659: ClosureData;
    var param_660: BSDF;
    var param_661: BSDF;
    var param_662: BSDF;
    var base_mix_fg_mul_out_2: BSDF;
    var param_663: ClosureData;
    var param_664: BSDF;
    var param_665: f32;
    var param_666: BSDF;
    var tf_reflection_bsdf_out_2: BSDF;
    var param_667: ClosureData;
    var param_668: f32;
    var param_669: vec3<f32>;
    var param_670: vec3<f32>;
    var param_671: vec3<f32>;
    var param_672: f32;
    var param_673: vec2<f32>;
    var param_674: bool;
    var param_675: f32;
    var param_676: f32;
    var param_677: vec3<f32>;
    var param_678: vec3<f32>;
    var param_679: i32;
    var param_680: i32;
    var param_681: BSDF;
    var reflection_bsdf_out_2: BSDF;
    var param_682: ClosureData;
    var param_683: f32;
    var param_684: vec3<f32>;
    var param_685: vec3<f32>;
    var param_686: vec3<f32>;
    var param_687: f32;
    var param_688: vec2<f32>;
    var param_689: bool;
    var param_690: f32;
    var param_691: f32;
    var param_692: vec3<f32>;
    var param_693: vec3<f32>;
    var param_694: i32;
    var param_695: i32;
    var param_696: BSDF;
    var mix_iridescent_dielectric_reflection_add_out_2: BSDF;
    var param_697: ClosureData;
    var param_698: BSDF;
    var param_699: BSDF;
    var param_700: BSDF;
    var transmission_bsdf_out_2: BSDF;
    var param_701: ClosureData;
    var param_702: f32;
    var param_703: vec3<f32>;
    var param_704: f32;
    var param_705: vec2<f32>;
    var param_706: bool;
    var param_707: f32;
    var param_708: f32;
    var param_709: vec3<f32>;
    var param_710: vec3<f32>;
    var param_711: i32;
    var param_712: i32;
    var param_713: BSDF;
    var diffuse_bsdf_out_2: BSDF;
    var param_714: ClosureData;
    var param_715: f32;
    var param_716: vec3<f32>;
    var param_717: f32;
    var param_718: vec3<f32>;
    var param_719: bool;
    var param_720: BSDF;
    var transmission_mix_add_out_2: BSDF;
    var param_721: ClosureData;
    var param_722: BSDF;
    var param_723: BSDF;
    var param_724: BSDF;
    var iridescent_dielectric_bsdf_out_2: BSDF;
    var param_725: ClosureData;
    var param_726: BSDF;
    var param_727: BSDF;
    var param_728: BSDF;
    var base_mix_bg_mul_out_2: BSDF;
    var param_729: ClosureData;
    var param_730: BSDF;
    var param_731: f32;
    var param_732: BSDF;
    var base_mix_add_out_2: BSDF;
    var param_733: ClosureData;
    var param_734: BSDF;
    var param_735: BSDF;
    var param_736: BSDF;
    var sheen_layer_out_2: BSDF;
    var param_737: ClosureData;
    var param_738: BSDF;
    var param_739: BSDF;
    var param_740: BSDF;
    var clearcoat_layer_out_2: BSDF;
    var param_741: ClosureData;
    var param_742: BSDF;
    var param_743: BSDF;
    var param_744: BSDF;

    clearcoat_roughness_uv_out = vec2<f32>(0f, 0f);
    let _e842 = (*clearcoat_roughness);
    param_298 = _e842;
    param_299 = 0f;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_298), (&param_299), (&param_300));
    let _e843 = param_300;
    clearcoat_roughness_uv_out = _e843;
    sheen_intensity_out = 0f;
    let _e844 = (*sheen_color);
    param_301 = _e844;
    NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b((&param_301), (&param_302));
    let _e845 = param_302;
    sheen_intensity_out = _e845;
    let _e846 = (*sheen_roughness);
    let _e847 = (*sheen_roughness);
    sheen_roughness_sq_out = (_e846 * _e847);
    let _e849 = (*iridescence);
    mix_iridescent_metal_bsdf_fg_weight_out = (1f * _e849);
    let _e851 = (*roughness_17);
    let _e852 = (*roughness_17);
    alpha_roughness_out = (_e851 * _e852);
    let _e854 = (*anisotropy_strength);
    let _e855 = (*anisotropy_strength);
    strength_2_out = (_e854 * _e855);
    let _e857 = (*anisotropy_rotation);
    abs_anisotropy_rotation_out = abs(_e857);
    let _e859 = (*anisotropy_rotation);
    rad_2_deg_out = (_e859 * -57.29578f);
    let _e861 = (*iridescence);
    mix_iridescent_metal_bsdf_mix_inv_out = (1f - _e861);
    let _e863 = (*iridescence);
    mix_iridescent_dielectric_reflection_fg_weight_out = (1f * _e863);
    let _e865 = (*ior_6);
    one_minus_ior_out = (1f - _e865);
    let _e867 = (*ior_6);
    one_plus_ior_out = (1f + _e867);
    let _e869 = (*specular);
    dielectric_f90_out = (vec3<f32>(1f, 1f, 1f) * _e869);
    let _e871 = (*iridescence);
    mix_iridescent_dielectric_reflection_mix_inv_out = (1f - _e871);
    let _e873 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e873);
    let _e875 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e875);
    let _e877 = (*metallic);
    base_mix_mix_inv_out = (1f - _e877);
    let _e879 = (*emissive);
    let _e880 = (*emissive_strength);
    emission_color_out = (_e879 * _e880);
    let _e882 = (*alpha_12);
    let _e883 = (*alpha_cutoff);
    opacity_mask_cutoff_out = select(0f, 1f, (_e882 >= _e883));
    let _e886 = (*sheen_color);
    let _e887 = sheen_intensity_out;
    sheen_color_normalized_out = (_e886 / vec3(_e887));
    let _e890 = alpha_roughness_out;
    clamped_ab_out = clamp(_e890, 0.00001f, 1f);
    let _e892 = alpha_roughness_out;
    let _e893 = strength_2_out;
    at_out = mix(_e892, 1f, _e893);
    rotate_tangent_out = vec3<f32>(0f, 0f, 0f);
    let _e895 = (*tangent);
    param_303 = _e895;
    let _e896 = rad_2_deg_out;
    param_304 = _e896;
    let _e897 = (*normal);
    param_305 = _e897;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_303), (&param_304), (&param_305), (&param_306));
    let _e898 = param_306;
    rotate_tangent_out = _e898;
    let _e899 = mix_iridescent_metal_bsdf_mix_inv_out;
    mix_iridescent_metal_bsdf_bg_weight_out = (1f * _e899);
    let _e901 = one_minus_ior_out;
    let _e902 = one_plus_ior_out;
    ior_div_out = (_e901 / _e902);
    let _e904 = mix_iridescent_dielectric_reflection_mix_inv_out;
    mix_iridescent_dielectric_reflection_bg_weight_out = (1f * _e904);
    let _e906 = transmission_mix_mix_inv_out;
    transmission_mix_bg_weight_out = (1f * _e906);
    let _e908 = (*alpha_mode);
    let _e910 = opacity_mask_cutoff_out;
    let _e911 = (*alpha_12);
    opacity_mask_out = select(_e911, _e910, (_e908 == 1i));
    let _e913 = at_out;
    clamped_at_out = clamp(_e913, 0.00001f, 1f);
    let _e915 = rotate_tangent_out;
    normalize_tangent_out = normalize(_e915);
    let _e917 = ior_div_out;
    let _e918 = ior_div_out;
    dielectric_f0_from_ior_out = (_e917 * _e918);
    let _e920 = (*alpha_mode);
    let _e922 = opacity_mask_out;
    opacity_out = select(_e922, 1f, (_e920 == 0i));
    let _e924 = clamped_at_out;
    let _e925 = clamped_ab_out;
    roughness_uv_out = vec2<f32>(_e924, _e925);
    let _e927 = abs_anisotropy_rotation_out;
    let _e929 = normalize_tangent_out;
    let _e930 = (*tangent);
    selected_tangent_out = select(_e930, _e929, (_e927 > 0f));
    let _e932 = (*specular_color);
    let _e933 = dielectric_f0_from_ior_out;
    dielectric_f0_from_ior_specular_color_out = (_e932 * _e933);
    let _e935 = dielectric_f0_from_ior_specular_color_out;
    clamped_dielectric_f0_from_ior_specular_color_out = min(_e935, vec3(1f));
    let _e938 = clamped_dielectric_f0_from_ior_specular_color_out;
    let _e939 = (*specular);
    dielectric_f0_out = (_e938 * _e939);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e941 = normalWorld;
    N_13 = normalize(_e941);
    let _e945 = unnamed.cameraWorldMatrix[3];
    let _e947 = positionWorld;
    V_12 = normalize((_e945.xyz - _e947));
    let _e950 = positionWorld;
    P_1 = _e950;
    L_7 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e951 = opacity_out;
    surfaceOpacity = _e951;
    let _e952 = numActiveLightSources_u0028_();
    numLights = _e952;
    activeLightIndex = 0i;
    loop {
        let _e953 = activeLightIndex;
        let _e954 = numLights;
        if (_e953 < _e954) {
            let _e956 = activeLightIndex;
            let _e959 = unnamed.u_lightData[_e956];
            param_307 = _e959;
            let _e960 = positionWorld;
            param_308 = _e960;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_307), (&param_308), (&param_309));
            let _e961 = param_309;
            lightShader = _e961;
            let _e963 = lightShader.direction;
            L_7 = _e963;
            param_310 = 1i;
            let _e964 = L_7;
            param_311 = _e964;
            let _e965 = V_12;
            param_312 = _e965;
            let _e966 = N_13;
            param_313 = _e966;
            let _e967 = P_1;
            param_314 = _e967;
            let _e968 = occlusion_2;
            param_315 = _e968;
            let _e969 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_310), (&param_311), (&param_312), (&param_313), (&param_314), (&param_315));
            closureData_8 = _e969;
            clearcoat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e970 = closureData_8;
            param_316 = _e970;
            let _e971 = (*clearcoat);
            param_317 = _e971;
            param_318 = vec3<f32>(1f, 1f, 1f);
            param_319 = 1.5f;
            let _e972 = clearcoat_roughness_uv_out;
            param_320 = _e972;
            param_321 = false;
            param_322 = 0f;
            param_323 = 1.5f;
            let _e973 = (*clearcoat_normal);
            param_324 = _e973;
            let _e974 = (*tangent);
            param_325 = _e974;
            param_326 = 0i;
            param_327 = 0i;
            let _e975 = clearcoat_bsdf_out;
            param_328 = _e975;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_316), (&param_317), (&param_318), (&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325), (&param_326), (&param_327), (&param_328));
            let _e976 = param_328;
            clearcoat_bsdf_out = _e976;
            sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e977 = closureData_8;
            param_329 = _e977;
            let _e978 = sheen_intensity_out;
            param_330 = _e978;
            let _e979 = sheen_color_normalized_out;
            param_331 = _e979;
            let _e980 = sheen_roughness_sq_out;
            param_332 = _e980;
            let _e981 = (*normal);
            param_333 = _e981;
            param_334 = 0i;
            let _e982 = sheen_bsdf_out;
            param_335 = _e982;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335));
            let _e983 = param_335;
            sheen_bsdf_out = _e983;
            tf_metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e984 = closureData_8;
            param_336 = _e984;
            let _e985 = mix_iridescent_metal_bsdf_fg_weight_out;
            param_337 = _e985;
            let _e986 = (*base_color);
            param_338 = _e986;
            param_339 = vec3<f32>(1f, 1f, 1f);
            param_340 = vec3<f32>(1f, 1f, 1f);
            param_341 = 5f;
            let _e987 = roughness_uv_out;
            param_342 = _e987;
            param_343 = false;
            let _e988 = (*iridescence_thickness);
            param_344 = _e988;
            let _e989 = (*iridescence_ior);
            param_345 = _e989;
            let _e990 = (*normal);
            param_346 = _e990;
            let _e991 = selected_tangent_out;
            param_347 = _e991;
            param_348 = 0i;
            param_349 = 0i;
            let _e992 = tf_metal_bsdf_out;
            param_350 = _e992;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_336), (&param_337), (&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350));
            let _e993 = param_350;
            tf_metal_bsdf_out = _e993;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e994 = closureData_8;
            param_351 = _e994;
            let _e995 = mix_iridescent_metal_bsdf_bg_weight_out;
            param_352 = _e995;
            let _e996 = (*base_color);
            param_353 = _e996;
            param_354 = vec3<f32>(1f, 1f, 1f);
            param_355 = vec3<f32>(1f, 1f, 1f);
            param_356 = 5f;
            let _e997 = roughness_uv_out;
            param_357 = _e997;
            param_358 = false;
            param_359 = 0f;
            param_360 = 1.5f;
            let _e998 = (*normal);
            param_361 = _e998;
            let _e999 = selected_tangent_out;
            param_362 = _e999;
            param_363 = 0i;
            param_364 = 0i;
            let _e1000 = metal_bsdf_out;
            param_365 = _e1000;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365));
            let _e1001 = param_365;
            metal_bsdf_out = _e1001;
            mix_iridescent_metal_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1002 = closureData_8;
            param_366 = _e1002;
            let _e1003 = tf_metal_bsdf_out;
            param_367 = _e1003;
            let _e1004 = metal_bsdf_out;
            param_368 = _e1004;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_366), (&param_367), (&param_368), (&param_369));
            let _e1005 = param_369;
            mix_iridescent_metal_bsdf_add_out = _e1005;
            base_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1006 = closureData_8;
            param_370 = _e1006;
            let _e1007 = mix_iridescent_metal_bsdf_add_out;
            param_371 = _e1007;
            let _e1008 = (*metallic);
            param_372 = _e1008;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_370), (&param_371), (&param_372), (&param_373));
            let _e1009 = param_373;
            base_mix_fg_mul_out = _e1009;
            tf_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1010 = closureData_8;
            param_374 = _e1010;
            let _e1011 = mix_iridescent_dielectric_reflection_fg_weight_out;
            param_375 = _e1011;
            let _e1012 = dielectric_f0_out;
            param_376 = _e1012;
            param_377 = vec3<f32>(1f, 1f, 1f);
            let _e1013 = dielectric_f90_out;
            param_378 = _e1013;
            param_379 = 5f;
            let _e1014 = roughness_uv_out;
            param_380 = _e1014;
            param_381 = false;
            let _e1015 = (*iridescence_thickness);
            param_382 = _e1015;
            let _e1016 = (*iridescence_ior);
            param_383 = _e1016;
            let _e1017 = (*normal);
            param_384 = _e1017;
            let _e1018 = selected_tangent_out;
            param_385 = _e1018;
            param_386 = 0i;
            param_387 = 0i;
            let _e1019 = tf_reflection_bsdf_out;
            param_388 = _e1019;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_374), (&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387), (&param_388));
            let _e1020 = param_388;
            tf_reflection_bsdf_out = _e1020;
            reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1021 = closureData_8;
            param_389 = _e1021;
            let _e1022 = mix_iridescent_dielectric_reflection_bg_weight_out;
            param_390 = _e1022;
            let _e1023 = dielectric_f0_out;
            param_391 = _e1023;
            param_392 = vec3<f32>(1f, 1f, 1f);
            let _e1024 = dielectric_f90_out;
            param_393 = _e1024;
            param_394 = 5f;
            let _e1025 = roughness_uv_out;
            param_395 = _e1025;
            param_396 = false;
            param_397 = 0f;
            param_398 = 1.5f;
            let _e1026 = (*normal);
            param_399 = _e1026;
            let _e1027 = selected_tangent_out;
            param_400 = _e1027;
            param_401 = 0i;
            param_402 = 0i;
            let _e1028 = reflection_bsdf_out;
            param_403 = _e1028;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402), (&param_403));
            let _e1029 = param_403;
            reflection_bsdf_out = _e1029;
            mix_iridescent_dielectric_reflection_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1030 = closureData_8;
            param_404 = _e1030;
            let _e1031 = tf_reflection_bsdf_out;
            param_405 = _e1031;
            let _e1032 = reflection_bsdf_out;
            param_406 = _e1032;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_404), (&param_405), (&param_406), (&param_407));
            let _e1033 = param_407;
            mix_iridescent_dielectric_reflection_add_out = _e1033;
            transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1034 = closureData_8;
            param_408 = _e1034;
            let _e1035 = transmission_mix_fg_weight_out;
            param_409 = _e1035;
            let _e1036 = (*base_color);
            param_410 = _e1036;
            let _e1037 = (*ior_6);
            param_411 = _e1037;
            let _e1038 = roughness_uv_out;
            param_412 = _e1038;
            param_413 = false;
            param_414 = 0f;
            param_415 = 1.5f;
            let _e1039 = (*normal);
            param_416 = _e1039;
            let _e1040 = selected_tangent_out;
            param_417 = _e1040;
            param_418 = 0i;
            param_419 = 1i;
            let _e1041 = transmission_bsdf_out;
            param_420 = _e1041;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_408), (&param_409), (&param_410), (&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420));
            let _e1042 = param_420;
            transmission_bsdf_out = _e1042;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1043 = closureData_8;
            param_421 = _e1043;
            let _e1044 = transmission_mix_bg_weight_out;
            param_422 = _e1044;
            let _e1045 = (*base_color);
            param_423 = _e1045;
            param_424 = 0f;
            let _e1046 = (*normal);
            param_425 = _e1046;
            param_426 = false;
            let _e1047 = diffuse_bsdf_out;
            param_427 = _e1047;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_421), (&param_422), (&param_423), (&param_424), (&param_425), (&param_426), (&param_427));
            let _e1048 = param_427;
            diffuse_bsdf_out = _e1048;
            transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1049 = closureData_8;
            param_428 = _e1049;
            let _e1050 = transmission_bsdf_out;
            param_429 = _e1050;
            let _e1051 = diffuse_bsdf_out;
            param_430 = _e1051;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_428), (&param_429), (&param_430), (&param_431));
            let _e1052 = param_431;
            transmission_mix_add_out = _e1052;
            iridescent_dielectric_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1053 = closureData_8;
            param_432 = _e1053;
            let _e1054 = mix_iridescent_dielectric_reflection_add_out;
            param_433 = _e1054;
            let _e1055 = transmission_mix_add_out;
            param_434 = _e1055;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_432), (&param_433), (&param_434), (&param_435));
            let _e1056 = param_435;
            iridescent_dielectric_bsdf_out = _e1056;
            base_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1057 = closureData_8;
            param_436 = _e1057;
            let _e1058 = iridescent_dielectric_bsdf_out;
            param_437 = _e1058;
            let _e1059 = base_mix_mix_inv_out;
            param_438 = _e1059;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_436), (&param_437), (&param_438), (&param_439));
            let _e1060 = param_439;
            base_mix_bg_mul_out = _e1060;
            base_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1061 = closureData_8;
            param_440 = _e1061;
            let _e1062 = base_mix_fg_mul_out;
            param_441 = _e1062;
            let _e1063 = base_mix_bg_mul_out;
            param_442 = _e1063;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_440), (&param_441), (&param_442), (&param_443));
            let _e1064 = param_443;
            base_mix_add_out = _e1064;
            sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1065 = closureData_8;
            param_444 = _e1065;
            let _e1066 = sheen_bsdf_out;
            param_445 = _e1066;
            let _e1067 = base_mix_add_out;
            param_446 = _e1067;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_444), (&param_445), (&param_446), (&param_447));
            let _e1068 = param_447;
            sheen_layer_out = _e1068;
            clearcoat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1069 = closureData_8;
            param_448 = _e1069;
            let _e1070 = clearcoat_bsdf_out;
            param_449 = _e1070;
            let _e1071 = sheen_layer_out;
            param_450 = _e1071;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_448), (&param_449), (&param_450), (&param_451));
            let _e1072 = param_451;
            clearcoat_layer_out = _e1072;
            let _e1074 = lightShader.intensity;
            let _e1076 = clearcoat_layer_out.response;
            let _e1079 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1079 + (_e1074 * _e1076));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1082 = activeLightIndex;
            activeLightIndex = (_e1082 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_452 = 3i;
    let _e1084 = L_7;
    param_453 = _e1084;
    let _e1085 = V_12;
    param_454 = _e1085;
    let _e1086 = N_13;
    param_455 = _e1086;
    let _e1087 = P_1;
    param_456 = _e1087;
    let _e1088 = occlusion_2;
    param_457 = _e1088;
    let _e1089 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_452), (&param_453), (&param_454), (&param_455), (&param_456), (&param_457));
    closureData_9 = _e1089;
    clearcoat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1090 = closureData_9;
    param_458 = _e1090;
    let _e1091 = (*clearcoat);
    param_459 = _e1091;
    param_460 = vec3<f32>(1f, 1f, 1f);
    param_461 = 1.5f;
    let _e1092 = clearcoat_roughness_uv_out;
    param_462 = _e1092;
    param_463 = false;
    param_464 = 0f;
    param_465 = 1.5f;
    let _e1093 = (*clearcoat_normal);
    param_466 = _e1093;
    let _e1094 = (*tangent);
    param_467 = _e1094;
    param_468 = 0i;
    param_469 = 0i;
    let _e1095 = clearcoat_bsdf_out_1;
    param_470 = _e1095;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_458), (&param_459), (&param_460), (&param_461), (&param_462), (&param_463), (&param_464), (&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470));
    let _e1096 = param_470;
    clearcoat_bsdf_out_1 = _e1096;
    sheen_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1097 = closureData_9;
    param_471 = _e1097;
    let _e1098 = sheen_intensity_out;
    param_472 = _e1098;
    let _e1099 = sheen_color_normalized_out;
    param_473 = _e1099;
    let _e1100 = sheen_roughness_sq_out;
    param_474 = _e1100;
    let _e1101 = (*normal);
    param_475 = _e1101;
    param_476 = 0i;
    let _e1102 = sheen_bsdf_out_1;
    param_477 = _e1102;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477));
    let _e1103 = param_477;
    sheen_bsdf_out_1 = _e1103;
    tf_metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1104 = closureData_9;
    param_478 = _e1104;
    let _e1105 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_479 = _e1105;
    let _e1106 = (*base_color);
    param_480 = _e1106;
    param_481 = vec3<f32>(1f, 1f, 1f);
    param_482 = vec3<f32>(1f, 1f, 1f);
    param_483 = 5f;
    let _e1107 = roughness_uv_out;
    param_484 = _e1107;
    param_485 = false;
    let _e1108 = (*iridescence_thickness);
    param_486 = _e1108;
    let _e1109 = (*iridescence_ior);
    param_487 = _e1109;
    let _e1110 = (*normal);
    param_488 = _e1110;
    let _e1111 = selected_tangent_out;
    param_489 = _e1111;
    param_490 = 0i;
    param_491 = 0i;
    let _e1112 = tf_metal_bsdf_out_1;
    param_492 = _e1112;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491), (&param_492));
    let _e1113 = param_492;
    tf_metal_bsdf_out_1 = _e1113;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1114 = closureData_9;
    param_493 = _e1114;
    let _e1115 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_494 = _e1115;
    let _e1116 = (*base_color);
    param_495 = _e1116;
    param_496 = vec3<f32>(1f, 1f, 1f);
    param_497 = vec3<f32>(1f, 1f, 1f);
    param_498 = 5f;
    let _e1117 = roughness_uv_out;
    param_499 = _e1117;
    param_500 = false;
    param_501 = 0f;
    param_502 = 1.5f;
    let _e1118 = (*normal);
    param_503 = _e1118;
    let _e1119 = selected_tangent_out;
    param_504 = _e1119;
    param_505 = 0i;
    param_506 = 0i;
    let _e1120 = metal_bsdf_out_1;
    param_507 = _e1120;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502), (&param_503), (&param_504), (&param_505), (&param_506), (&param_507));
    let _e1121 = param_507;
    metal_bsdf_out_1 = _e1121;
    mix_iridescent_metal_bsdf_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1122 = closureData_9;
    param_508 = _e1122;
    let _e1123 = tf_metal_bsdf_out_1;
    param_509 = _e1123;
    let _e1124 = metal_bsdf_out_1;
    param_510 = _e1124;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_508), (&param_509), (&param_510), (&param_511));
    let _e1125 = param_511;
    mix_iridescent_metal_bsdf_add_out_1 = _e1125;
    base_mix_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1126 = closureData_9;
    param_512 = _e1126;
    let _e1127 = mix_iridescent_metal_bsdf_add_out_1;
    param_513 = _e1127;
    let _e1128 = (*metallic);
    param_514 = _e1128;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_512), (&param_513), (&param_514), (&param_515));
    let _e1129 = param_515;
    base_mix_fg_mul_out_1 = _e1129;
    tf_reflection_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1130 = closureData_9;
    param_516 = _e1130;
    let _e1131 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_517 = _e1131;
    let _e1132 = dielectric_f0_out;
    param_518 = _e1132;
    param_519 = vec3<f32>(1f, 1f, 1f);
    let _e1133 = dielectric_f90_out;
    param_520 = _e1133;
    param_521 = 5f;
    let _e1134 = roughness_uv_out;
    param_522 = _e1134;
    param_523 = false;
    let _e1135 = (*iridescence_thickness);
    param_524 = _e1135;
    let _e1136 = (*iridescence_ior);
    param_525 = _e1136;
    let _e1137 = (*normal);
    param_526 = _e1137;
    let _e1138 = selected_tangent_out;
    param_527 = _e1138;
    param_528 = 0i;
    param_529 = 0i;
    let _e1139 = tf_reflection_bsdf_out_1;
    param_530 = _e1139;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_516), (&param_517), (&param_518), (&param_519), (&param_520), (&param_521), (&param_522), (&param_523), (&param_524), (&param_525), (&param_526), (&param_527), (&param_528), (&param_529), (&param_530));
    let _e1140 = param_530;
    tf_reflection_bsdf_out_1 = _e1140;
    reflection_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1141 = closureData_9;
    param_531 = _e1141;
    let _e1142 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_532 = _e1142;
    let _e1143 = dielectric_f0_out;
    param_533 = _e1143;
    param_534 = vec3<f32>(1f, 1f, 1f);
    let _e1144 = dielectric_f90_out;
    param_535 = _e1144;
    param_536 = 5f;
    let _e1145 = roughness_uv_out;
    param_537 = _e1145;
    param_538 = false;
    param_539 = 0f;
    param_540 = 1.5f;
    let _e1146 = (*normal);
    param_541 = _e1146;
    let _e1147 = selected_tangent_out;
    param_542 = _e1147;
    param_543 = 0i;
    param_544 = 0i;
    let _e1148 = reflection_bsdf_out_1;
    param_545 = _e1148;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_531), (&param_532), (&param_533), (&param_534), (&param_535), (&param_536), (&param_537), (&param_538), (&param_539), (&param_540), (&param_541), (&param_542), (&param_543), (&param_544), (&param_545));
    let _e1149 = param_545;
    reflection_bsdf_out_1 = _e1149;
    mix_iridescent_dielectric_reflection_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1150 = closureData_9;
    param_546 = _e1150;
    let _e1151 = tf_reflection_bsdf_out_1;
    param_547 = _e1151;
    let _e1152 = reflection_bsdf_out_1;
    param_548 = _e1152;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_546), (&param_547), (&param_548), (&param_549));
    let _e1153 = param_549;
    mix_iridescent_dielectric_reflection_add_out_1 = _e1153;
    transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1154 = closureData_9;
    param_550 = _e1154;
    let _e1155 = transmission_mix_fg_weight_out;
    param_551 = _e1155;
    let _e1156 = (*base_color);
    param_552 = _e1156;
    let _e1157 = (*ior_6);
    param_553 = _e1157;
    let _e1158 = roughness_uv_out;
    param_554 = _e1158;
    param_555 = false;
    param_556 = 0f;
    param_557 = 1.5f;
    let _e1159 = (*normal);
    param_558 = _e1159;
    let _e1160 = selected_tangent_out;
    param_559 = _e1160;
    param_560 = 0i;
    param_561 = 1i;
    let _e1161 = transmission_bsdf_out_1;
    param_562 = _e1161;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555), (&param_556), (&param_557), (&param_558), (&param_559), (&param_560), (&param_561), (&param_562));
    let _e1162 = param_562;
    transmission_bsdf_out_1 = _e1162;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1163 = closureData_9;
    param_563 = _e1163;
    let _e1164 = transmission_mix_bg_weight_out;
    param_564 = _e1164;
    let _e1165 = (*base_color);
    param_565 = _e1165;
    param_566 = 0f;
    let _e1166 = (*normal);
    param_567 = _e1166;
    param_568 = false;
    let _e1167 = diffuse_bsdf_out_1;
    param_569 = _e1167;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_563), (&param_564), (&param_565), (&param_566), (&param_567), (&param_568), (&param_569));
    let _e1168 = param_569;
    diffuse_bsdf_out_1 = _e1168;
    transmission_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1169 = closureData_9;
    param_570 = _e1169;
    let _e1170 = transmission_bsdf_out_1;
    param_571 = _e1170;
    let _e1171 = diffuse_bsdf_out_1;
    param_572 = _e1171;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_570), (&param_571), (&param_572), (&param_573));
    let _e1172 = param_573;
    transmission_mix_add_out_1 = _e1172;
    iridescent_dielectric_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1173 = closureData_9;
    param_574 = _e1173;
    let _e1174 = mix_iridescent_dielectric_reflection_add_out_1;
    param_575 = _e1174;
    let _e1175 = transmission_mix_add_out_1;
    param_576 = _e1175;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_574), (&param_575), (&param_576), (&param_577));
    let _e1176 = param_577;
    iridescent_dielectric_bsdf_out_1 = _e1176;
    base_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1177 = closureData_9;
    param_578 = _e1177;
    let _e1178 = iridescent_dielectric_bsdf_out_1;
    param_579 = _e1178;
    let _e1179 = base_mix_mix_inv_out;
    param_580 = _e1179;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_578), (&param_579), (&param_580), (&param_581));
    let _e1180 = param_581;
    base_mix_bg_mul_out_1 = _e1180;
    base_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1181 = closureData_9;
    param_582 = _e1181;
    let _e1182 = base_mix_fg_mul_out_1;
    param_583 = _e1182;
    let _e1183 = base_mix_bg_mul_out_1;
    param_584 = _e1183;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_582), (&param_583), (&param_584), (&param_585));
    let _e1184 = param_585;
    base_mix_add_out_1 = _e1184;
    sheen_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1185 = closureData_9;
    param_586 = _e1185;
    let _e1186 = sheen_bsdf_out_1;
    param_587 = _e1186;
    let _e1187 = base_mix_add_out_1;
    param_588 = _e1187;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_586), (&param_587), (&param_588), (&param_589));
    let _e1188 = param_589;
    sheen_layer_out_1 = _e1188;
    clearcoat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1189 = closureData_9;
    param_590 = _e1189;
    let _e1190 = clearcoat_bsdf_out_1;
    param_591 = _e1190;
    let _e1191 = sheen_layer_out_1;
    param_592 = _e1191;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_590), (&param_591), (&param_592), (&param_593));
    let _e1192 = param_593;
    clearcoat_layer_out_1 = _e1192;
    let _e1193 = occlusion_2;
    let _e1195 = clearcoat_layer_out_1.response;
    let _e1198 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1198 + (_e1195 * _e1193));
    param_594 = 4i;
    let _e1201 = L_7;
    param_595 = _e1201;
    let _e1202 = V_12;
    param_596 = _e1202;
    let _e1203 = N_13;
    param_597 = _e1203;
    let _e1204 = P_1;
    param_598 = _e1204;
    let _e1205 = occlusion_2;
    param_599 = _e1205;
    let _e1206 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_594), (&param_595), (&param_596), (&param_597), (&param_598), (&param_599));
    closureData_10 = _e1206;
    emission_out = vec3<f32>(0f, 0f, 0f);
    let _e1207 = closureData_10;
    param_600 = _e1207;
    let _e1208 = emission_color_out;
    param_601 = _e1208;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_600), (&param_601), (&param_602));
    let _e1209 = param_602;
    emission_out = _e1209;
    let _e1210 = emission_out;
    let _e1212 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1212 + _e1210);
    param_603 = 2i;
    let _e1215 = L_7;
    param_604 = _e1215;
    let _e1216 = V_12;
    param_605 = _e1216;
    let _e1217 = N_13;
    param_606 = _e1217;
    let _e1218 = P_1;
    param_607 = _e1218;
    let _e1219 = occlusion_2;
    param_608 = _e1219;
    let _e1220 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608));
    closureData_11 = _e1220;
    clearcoat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1221 = closureData_11;
    param_609 = _e1221;
    let _e1222 = (*clearcoat);
    param_610 = _e1222;
    param_611 = vec3<f32>(1f, 1f, 1f);
    param_612 = 1.5f;
    let _e1223 = clearcoat_roughness_uv_out;
    param_613 = _e1223;
    param_614 = false;
    param_615 = 0f;
    param_616 = 1.5f;
    let _e1224 = (*clearcoat_normal);
    param_617 = _e1224;
    let _e1225 = (*tangent);
    param_618 = _e1225;
    param_619 = 0i;
    param_620 = 0i;
    let _e1226 = clearcoat_bsdf_out_2;
    param_621 = _e1226;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615), (&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621));
    let _e1227 = param_621;
    clearcoat_bsdf_out_2 = _e1227;
    sheen_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1228 = closureData_11;
    param_622 = _e1228;
    let _e1229 = sheen_intensity_out;
    param_623 = _e1229;
    let _e1230 = sheen_color_normalized_out;
    param_624 = _e1230;
    let _e1231 = sheen_roughness_sq_out;
    param_625 = _e1231;
    let _e1232 = (*normal);
    param_626 = _e1232;
    param_627 = 0i;
    let _e1233 = sheen_bsdf_out_2;
    param_628 = _e1233;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627), (&param_628));
    let _e1234 = param_628;
    sheen_bsdf_out_2 = _e1234;
    tf_metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1235 = closureData_11;
    param_629 = _e1235;
    let _e1236 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_630 = _e1236;
    let _e1237 = (*base_color);
    param_631 = _e1237;
    param_632 = vec3<f32>(1f, 1f, 1f);
    param_633 = vec3<f32>(1f, 1f, 1f);
    param_634 = 5f;
    let _e1238 = roughness_uv_out;
    param_635 = _e1238;
    param_636 = false;
    let _e1239 = (*iridescence_thickness);
    param_637 = _e1239;
    let _e1240 = (*iridescence_ior);
    param_638 = _e1240;
    let _e1241 = (*normal);
    param_639 = _e1241;
    let _e1242 = selected_tangent_out;
    param_640 = _e1242;
    param_641 = 0i;
    param_642 = 0i;
    let _e1243 = tf_metal_bsdf_out_2;
    param_643 = _e1243;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_629), (&param_630), (&param_631), (&param_632), (&param_633), (&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640), (&param_641), (&param_642), (&param_643));
    let _e1244 = param_643;
    tf_metal_bsdf_out_2 = _e1244;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1245 = closureData_11;
    param_644 = _e1245;
    let _e1246 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_645 = _e1246;
    let _e1247 = (*base_color);
    param_646 = _e1247;
    param_647 = vec3<f32>(1f, 1f, 1f);
    param_648 = vec3<f32>(1f, 1f, 1f);
    param_649 = 5f;
    let _e1248 = roughness_uv_out;
    param_650 = _e1248;
    param_651 = false;
    param_652 = 0f;
    param_653 = 1.5f;
    let _e1249 = (*normal);
    param_654 = _e1249;
    let _e1250 = selected_tangent_out;
    param_655 = _e1250;
    param_656 = 0i;
    param_657 = 0i;
    let _e1251 = metal_bsdf_out_2;
    param_658 = _e1251;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650), (&param_651), (&param_652), (&param_653), (&param_654), (&param_655), (&param_656), (&param_657), (&param_658));
    let _e1252 = param_658;
    metal_bsdf_out_2 = _e1252;
    mix_iridescent_metal_bsdf_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1253 = closureData_11;
    param_659 = _e1253;
    let _e1254 = tf_metal_bsdf_out_2;
    param_660 = _e1254;
    let _e1255 = metal_bsdf_out_2;
    param_661 = _e1255;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_659), (&param_660), (&param_661), (&param_662));
    let _e1256 = param_662;
    mix_iridescent_metal_bsdf_add_out_2 = _e1256;
    base_mix_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1257 = closureData_11;
    param_663 = _e1257;
    let _e1258 = mix_iridescent_metal_bsdf_add_out_2;
    param_664 = _e1258;
    let _e1259 = (*metallic);
    param_665 = _e1259;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_663), (&param_664), (&param_665), (&param_666));
    let _e1260 = param_666;
    base_mix_fg_mul_out_2 = _e1260;
    tf_reflection_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1261 = closureData_11;
    param_667 = _e1261;
    let _e1262 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_668 = _e1262;
    let _e1263 = dielectric_f0_out;
    param_669 = _e1263;
    param_670 = vec3<f32>(1f, 1f, 1f);
    let _e1264 = dielectric_f90_out;
    param_671 = _e1264;
    param_672 = 5f;
    let _e1265 = roughness_uv_out;
    param_673 = _e1265;
    param_674 = false;
    let _e1266 = (*iridescence_thickness);
    param_675 = _e1266;
    let _e1267 = (*iridescence_ior);
    param_676 = _e1267;
    let _e1268 = (*normal);
    param_677 = _e1268;
    let _e1269 = selected_tangent_out;
    param_678 = _e1269;
    param_679 = 0i;
    param_680 = 0i;
    let _e1270 = tf_reflection_bsdf_out_2;
    param_681 = _e1270;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672), (&param_673), (&param_674), (&param_675), (&param_676), (&param_677), (&param_678), (&param_679), (&param_680), (&param_681));
    let _e1271 = param_681;
    tf_reflection_bsdf_out_2 = _e1271;
    reflection_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1272 = closureData_11;
    param_682 = _e1272;
    let _e1273 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_683 = _e1273;
    let _e1274 = dielectric_f0_out;
    param_684 = _e1274;
    param_685 = vec3<f32>(1f, 1f, 1f);
    let _e1275 = dielectric_f90_out;
    param_686 = _e1275;
    param_687 = 5f;
    let _e1276 = roughness_uv_out;
    param_688 = _e1276;
    param_689 = false;
    param_690 = 0f;
    param_691 = 1.5f;
    let _e1277 = (*normal);
    param_692 = _e1277;
    let _e1278 = selected_tangent_out;
    param_693 = _e1278;
    param_694 = 0i;
    param_695 = 0i;
    let _e1279 = reflection_bsdf_out_2;
    param_696 = _e1279;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687), (&param_688), (&param_689), (&param_690), (&param_691), (&param_692), (&param_693), (&param_694), (&param_695), (&param_696));
    let _e1280 = param_696;
    reflection_bsdf_out_2 = _e1280;
    mix_iridescent_dielectric_reflection_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1281 = closureData_11;
    param_697 = _e1281;
    let _e1282 = tf_reflection_bsdf_out_2;
    param_698 = _e1282;
    let _e1283 = reflection_bsdf_out_2;
    param_699 = _e1283;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_697), (&param_698), (&param_699), (&param_700));
    let _e1284 = param_700;
    mix_iridescent_dielectric_reflection_add_out_2 = _e1284;
    transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1285 = closureData_11;
    param_701 = _e1285;
    let _e1286 = transmission_mix_fg_weight_out;
    param_702 = _e1286;
    let _e1287 = (*base_color);
    param_703 = _e1287;
    let _e1288 = (*ior_6);
    param_704 = _e1288;
    let _e1289 = roughness_uv_out;
    param_705 = _e1289;
    param_706 = false;
    param_707 = 0f;
    param_708 = 1.5f;
    let _e1290 = (*normal);
    param_709 = _e1290;
    let _e1291 = selected_tangent_out;
    param_710 = _e1291;
    param_711 = 0i;
    param_712 = 1i;
    let _e1292 = transmission_bsdf_out_2;
    param_713 = _e1292;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_701), (&param_702), (&param_703), (&param_704), (&param_705), (&param_706), (&param_707), (&param_708), (&param_709), (&param_710), (&param_711), (&param_712), (&param_713));
    let _e1293 = param_713;
    transmission_bsdf_out_2 = _e1293;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1294 = closureData_11;
    param_714 = _e1294;
    let _e1295 = transmission_mix_bg_weight_out;
    param_715 = _e1295;
    let _e1296 = (*base_color);
    param_716 = _e1296;
    param_717 = 0f;
    let _e1297 = (*normal);
    param_718 = _e1297;
    param_719 = false;
    let _e1298 = diffuse_bsdf_out_2;
    param_720 = _e1298;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_714), (&param_715), (&param_716), (&param_717), (&param_718), (&param_719), (&param_720));
    let _e1299 = param_720;
    diffuse_bsdf_out_2 = _e1299;
    transmission_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1300 = closureData_11;
    param_721 = _e1300;
    let _e1301 = transmission_bsdf_out_2;
    param_722 = _e1301;
    let _e1302 = diffuse_bsdf_out_2;
    param_723 = _e1302;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_721), (&param_722), (&param_723), (&param_724));
    let _e1303 = param_724;
    transmission_mix_add_out_2 = _e1303;
    iridescent_dielectric_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1304 = closureData_11;
    param_725 = _e1304;
    let _e1305 = mix_iridescent_dielectric_reflection_add_out_2;
    param_726 = _e1305;
    let _e1306 = transmission_mix_add_out_2;
    param_727 = _e1306;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_725), (&param_726), (&param_727), (&param_728));
    let _e1307 = param_728;
    iridescent_dielectric_bsdf_out_2 = _e1307;
    base_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1308 = closureData_11;
    param_729 = _e1308;
    let _e1309 = iridescent_dielectric_bsdf_out_2;
    param_730 = _e1309;
    let _e1310 = base_mix_mix_inv_out;
    param_731 = _e1310;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_729), (&param_730), (&param_731), (&param_732));
    let _e1311 = param_732;
    base_mix_bg_mul_out_2 = _e1311;
    base_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1312 = closureData_11;
    param_733 = _e1312;
    let _e1313 = base_mix_fg_mul_out_2;
    param_734 = _e1313;
    let _e1314 = base_mix_bg_mul_out_2;
    param_735 = _e1314;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_733), (&param_734), (&param_735), (&param_736));
    let _e1315 = param_736;
    base_mix_add_out_2 = _e1315;
    sheen_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1316 = closureData_11;
    param_737 = _e1316;
    let _e1317 = sheen_bsdf_out_2;
    param_738 = _e1317;
    let _e1318 = base_mix_add_out_2;
    param_739 = _e1318;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_737), (&param_738), (&param_739), (&param_740));
    let _e1319 = param_740;
    sheen_layer_out_2 = _e1319;
    clearcoat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1320 = closureData_11;
    param_741 = _e1320;
    let _e1321 = clearcoat_bsdf_out_2;
    param_742 = _e1321;
    let _e1322 = sheen_layer_out_2;
    param_743 = _e1322;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_741), (&param_742), (&param_743), (&param_744));
    let _e1323 = param_744;
    clearcoat_layer_out_2 = _e1323;
    let _e1325 = clearcoat_layer_out_2.response;
    let _e1327 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1327 + _e1325);
    let _e1330 = surfaceOpacity;
    let _e1332 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1332 * _e1330);
    let _e1336 = shader_constructor_out.transparency;
    let _e1337 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e1336, vec3(_e1337));
    let _e1341 = shader_constructor_out;
    (*mtlxRasterOut_1) = _e1341;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_glass_out: surfaceshader;
    var param_745: vec3<f32>;
    var param_746: f32;
    var param_747: f32;
    var param_748: vec3<f32>;
    var param_749: vec3<f32>;
    var param_750: f32;
    var param_751: f32;
    var param_752: f32;
    var param_753: vec3<f32>;
    var param_754: f32;
    var param_755: f32;
    var param_756: i32;
    var param_757: f32;
    var param_758: f32;
    var param_759: f32;
    var param_760: f32;
    var param_761: vec3<f32>;
    var param_762: f32;
    var param_763: f32;
    var param_764: f32;
    var param_765: vec3<f32>;
    var param_766: vec3<f32>;
    var param_767: f32;
    var param_768: f32;
    var param_769: f32;
    var param_770: vec3<f32>;
    var param_771: f32;
    var param_772: f32;
    var param_773: f32;
    var param_774: surfaceshader;

    let _e295 = normalWorld;
    geomprop_Nworld_out = normalize(_e295);
    let _e297 = tangentWorld;
    geomprop_Tworld_out = normalize(_e297);
    SR_glass_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e299 = base_color_1;
    param_745 = _e299;
    let _e300 = metallic_1;
    param_746 = _e300;
    let _e301 = roughness_18;
    param_747 = _e301;
    let _e302 = geomprop_Nworld_out;
    param_748 = _e302;
    let _e303 = geomprop_Tworld_out;
    param_749 = _e303;
    let _e304 = occlusion_3;
    param_750 = _e304;
    let _e305 = transmission_1;
    param_751 = _e305;
    let _e306 = specular_1;
    param_752 = _e306;
    let _e307 = specular_color_1;
    param_753 = _e307;
    let _e308 = ior_7;
    param_754 = _e308;
    let _e309 = alpha_13;
    param_755 = _e309;
    let _e310 = alpha_mode_1;
    param_756 = _e310;
    let _e311 = alpha_cutoff_1;
    param_757 = _e311;
    let _e312 = iridescence_1;
    param_758 = _e312;
    let _e313 = iridescence_ior_1;
    param_759 = _e313;
    let _e314 = iridescence_thickness_1;
    param_760 = _e314;
    let _e315 = sheen_color_1;
    param_761 = _e315;
    let _e316 = sheen_roughness_1;
    param_762 = _e316;
    let _e317 = clearcoat_1;
    param_763 = _e317;
    let _e318 = clearcoat_roughness_1;
    param_764 = _e318;
    let _e319 = geomprop_Nworld_out;
    param_765 = _e319;
    let _e320 = emissive_1;
    param_766 = _e320;
    let _e321 = emissive_strength_1;
    param_767 = _e321;
    let _e322 = thickness_1;
    param_768 = _e322;
    let _e323 = attenuation_distance_1;
    param_769 = _e323;
    let _e324 = attenuation_color_1;
    param_770 = _e324;
    let _e325 = anisotropy_strength_1;
    param_771 = _e325;
    let _e326 = anisotropy_rotation_1;
    param_772 = _e326;
    let _e327 = dispersion_1;
    param_773 = _e327;
    IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_745), (&param_746), (&param_747), (&param_748), (&param_749), (&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765), (&param_766), (&param_767), (&param_768), (&param_769), (&param_770), (&param_771), (&param_772), (&param_773), (&param_774));
    let _e328 = param_774;
    SR_glass_out = _e328;
    let _e330 = SR_glass_out.color;
    mtlxRasterOut_2 = vec4<f32>(_e330.x, _e330.y, _e330.z, 1f);
    let _e335 = mtlxRasterOut_2;
    return _e335;
}

fn mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b(pW_1: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e266 = mtlxRasterMain_u0028_();
    return _e266.xyz;
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, rndSeed: ptr<function, u32>) {
    return;
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e264 = (*vWorld);
    let _e266 = (*basis_2).tW;
    let _e268 = (*vWorld);
    let _e270 = (*basis_2).bW;
    let _e272 = (*vWorld);
    let _e274 = (*basis_2).nW;
    return vec3<f32>(dot(_e264, _e266), dot(_e268, _e270), dot(_e272, _e274));
}

fn safe_normalize_u0028_vf3_u003b(N_14: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e264 = (*N_14);
    l = length(_e264);
    let _e266 = (*N_14);
    let _e267 = l;
    return (_e266 / vec3(max(_e267, 0.0000000001f)));
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, bW: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>) -> Basis {
    var basis_3: Basis;
    var param_775: vec3<f32>;
    var param_776: vec3<f32>;
    var param_777: vec3<f32>;

    let _e271 = (*nW);
    param_775 = _e271;
    let _e272 = safe_normalize_u0028_vf3_u003b((&param_775));
    basis_3.nW = _e272;
    let _e274 = (*tW);
    param_776 = _e274;
    let _e275 = safe_normalize_u0028_vf3_u003b((&param_776));
    basis_3.tW = _e275;
    let _e277 = (*bW);
    param_777 = _e277;
    let _e278 = safe_normalize_u0028_vf3_u003b((&param_777));
    basis_3.bW = _e278;
    let _e280 = (*baryCoord);
    basis_3.baryCoord = _e280;
    let _e282 = (*texCoord);
    basis_3.texCoord = _e282;
    let _e284 = basis_3;
    return _e284;
}

fn skyRadiance_u0028_vf3_u003b(woutputW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e265 = (*woutputW)[0u];
    let _e266 = (*woutputW);
    let _e267 = _e266.yz;
    let _e271 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e265, _e267.x, _e267.y), 0f);
    env = _e271;
    let _e272 = env;
    let _e275 = unnamed.skyPower;
    let _e278 = unnamed.skyColor;
    return ((_e272.xyz * _e275) * _e278);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max: f32;

    let _e265 = unnamed.sunAngularSize;
    theta_max = ((_e265 * 3.1415927f) / 180f);
    let _e268 = (*woutputW_1);
    let _e270 = unnamed.sunDir;
    let _e272 = theta_max;
    if (dot(_e268, _e270) < cos(_e272)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e276 = unnamed.sunPower;
    let _e278 = unnamed.sunColor;
    return (_e278 * _e276);
}

fn normalToTangent_u0028_vf3_u003b(N_15: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_778: vec3<f32>;

    let _e266 = (*N_15)[2u];
    let _e269 = (*N_15)[0u];
    if (abs(_e266) < abs(_e269)) {
        let _e273 = (*N_15)[2u];
        let _e275 = (*N_15)[0u];
        T = vec3<f32>(_e273, 0f, -(_e275));
    } else {
        let _e279 = (*N_15)[2u];
        let _e281 = (*N_15)[1u];
        T = vec3<f32>(0f, _e279, -(_e281));
    }
    let _e284 = T;
    param_778 = _e284;
    let _e285 = safe_normalize_u0028_vf3_u003b((&param_778));
    T = _e285;
    let _e286 = T;
    return _e286;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e266 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e266).x;
    let _e269 = (*index);
    let _e270 = width;
    let _e278 = (*index);
    let _e279 = width;
    let _e282 = textureLoad(texture, vec2<i32>((_e269 - (i32(floor((f32(_e269) / f32(_e270)))) * _e270)), (_e278 / _e279)), 0i);
    return _e282;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_779: i32;
    var param_780: i32;
    var param_781: i32;

    let _e270 = (*barycoord)[0u];
    let _e272 = (*faceIndices)[0u];
    param_779 = bitcast<i32>(_e272);
    let _e274 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_779));
    let _e277 = (*barycoord)[1u];
    let _e279 = (*faceIndices)[1u];
    param_780 = bitcast<i32>(_e279);
    let _e281 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_780));
    let _e285 = (*barycoord)[2u];
    let _e287 = (*faceIndices)[2u];
    param_781 = bitcast<i32>(_e287);
    let _e289 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_781));
    return (((_e274 * _e270) + (_e281 * _e277)) + (_e289 * _e285));
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

    let _e274 = (*direction);
    inverseDirection = (vec3(1f) / _e274);
    let _e277 = (*minimum);
    let _e278 = (*origin);
    let _e280 = inverseDirection;
    t0_2 = ((_e277 - _e278) * _e280);
    let _e282 = (*maximum);
    let _e283 = (*origin);
    let _e285 = inverseDirection;
    t1_2 = ((_e282 - _e283) * _e285);
    let _e287 = t0_2;
    let _e288 = t1_2;
    entry = min(_e287, _e288);
    let _e290 = t0_2;
    let _e291 = t1_2;
    exit = max(_e290, _e291);
    let _e294 = entry[0u];
    let _e296 = entry[1u];
    let _e298 = entry[2u];
    nearDistance = max(_e294, max(_e296, _e298));
    let _e302 = exit[0u];
    let _e304 = exit[1u];
    let _e306 = exit[2u];
    farDistance = min(_e302, min(_e304, _e306));
    let _e309 = farDistance;
    let _e310 = nearDistance;
    if (_e309 >= max(_e310, 0f)) {
        let _e313 = nearDistance;
        local_10 = max(_e313, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e315 = local_10;
    return _e315;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_782: i32;
    var maximum_1: vec4<f32>;
    var param_783: i32;
    var metadata: vec4<f32>;
    var param_784: i32;
    var param_785: vec3<f32>;
    var param_786: vec3<f32>;
    var param_787: vec3<f32>;
    var param_788: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_789: i32;
    var p0_: vec3<f32>;
    var param_790: i32;
    var p1_: vec3<f32>;
    var param_791: i32;
    var p2_: vec3<f32>;
    var param_792: i32;
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
    var phi_1044_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e315 = (*maxDistance);
    closest = _e315;
    found = false;
    loop {
        let _e316 = pointer;
        let _e318 = pointer;
        if ((_e316 >= 0i) && (_e318 < 64i)) {
            let _e321 = pointer;
            pointer = (_e321 - 1i);
            let _e324 = stack[_e321];
            nodeIndex = _e324;
            let _e325 = nodeIndex;
            param_782 = (_e325 * 3i);
            let _e327 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_782));
            minimum_1 = _e327;
            let _e328 = nodeIndex;
            param_783 = ((_e328 * 3i) + 1i);
            let _e331 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_783));
            maximum_1 = _e331;
            let _e332 = nodeIndex;
            param_784 = ((_e332 * 3i) + 2i);
            let _e335 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_784));
            metadata = _e335;
            let _e336 = minimum_1;
            param_785 = _e336.xyz;
            let _e338 = maximum_1;
            param_786 = _e338.xyz;
            let _e340 = (*rayOrigin);
            param_787 = _e340;
            let _e341 = (*rayDirection);
            param_788 = _e341;
            let _e342 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_785), (&param_786), (&param_787), (&param_788));
            let _e343 = closest;
            if (_e342 > _e343) {
                continue;
            }
            let _e346 = metadata[2u];
            if (_e346 > 0.5f) {
                let _e349 = metadata[0u];
                offset = i32((_e349 + 0.5f));
                let _e353 = metadata[1u];
                count = i32((_e353 + 0.5f));
                triangle = 0i;
                loop {
                    let _e356 = triangle;
                    let _e357 = count;
                    if (_e356 < _e357) {
                        let _e359 = offset;
                        let _e360 = triangle;
                        param_789 = (_e359 + _e360);
                        let _e362 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_789));
                        vertexIndices = vec3<u32>((_e362.xyz + vec3(0.5f)));
                        let _e368 = vertexIndices[0u];
                        param_790 = bitcast<i32>(_e368);
                        let _e370 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_790));
                        p0_ = _e370.xyz;
                        let _e373 = vertexIndices[1u];
                        param_791 = bitcast<i32>(_e373);
                        let _e375 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_791));
                        p1_ = _e375.xyz;
                        let _e378 = vertexIndices[2u];
                        param_792 = bitcast<i32>(_e378);
                        let _e380 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_792));
                        p2_ = _e380.xyz;
                        let _e382 = p1_;
                        let _e383 = p0_;
                        edge0_ = (_e382 - _e383);
                        let _e385 = p2_;
                        let _e386 = p0_;
                        edge1_ = (_e385 - _e386);
                        let _e388 = (*rayDirection);
                        let _e389 = edge1_;
                        pvec = cross(_e388, _e389);
                        let _e391 = edge0_;
                        let _e392 = pvec;
                        determinant_ = dot(_e391, _e392);
                        let _e394 = determinant_;
                        if (abs(_e394) < 0.00000001f) {
                            continue;
                        }
                        let _e397 = determinant_;
                        inverseDeterminant = (1f / _e397);
                        let _e399 = (*rayOrigin);
                        let _e400 = p0_;
                        tvec = (_e399 - _e400);
                        let _e402 = tvec;
                        let _e403 = pvec;
                        let _e405 = inverseDeterminant;
                        u = (dot(_e402, _e403) * _e405);
                        let _e407 = tvec;
                        let _e408 = edge0_;
                        qvec = cross(_e407, _e408);
                        let _e410 = (*rayDirection);
                        let _e411 = qvec;
                        let _e413 = inverseDeterminant;
                        v_2 = (dot(_e410, _e411) * _e413);
                        let _e415 = edge1_;
                        let _e416 = qvec;
                        let _e418 = inverseDeterminant;
                        distance_ = (dot(_e415, _e416) * _e418);
                        let _e420 = u;
                        let _e422 = v_2;
                        let _e424 = ((_e420 >= 0f) && (_e422 >= 0f));
                        phi_1044_ = _e424;
                        if _e424 {
                            let _e425 = u;
                            let _e426 = v_2;
                            phi_1044_ = ((_e425 + _e426) <= 1f);
                        }
                        let _e430 = phi_1044_;
                        let _e431 = distance_;
                        let _e434 = distance_;
                        let _e435 = closest;
                        if ((_e430 && (_e431 > 0f)) && (_e434 < _e435)) {
                            let _e438 = distance_;
                            closest = _e438;
                            let _e439 = distance_;
                            (*dist) = _e439;
                            let _e440 = u;
                            let _e442 = v_2;
                            let _e444 = u;
                            let _e445 = v_2;
                            (*barycoord_1) = vec3<f32>(((1f - _e440) - _e442), _e444, _e445);
                            let _e447 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e447.x, _e447.y, _e447.z, 0u);
                            let _e452 = edge0_;
                            let _e453 = edge1_;
                            (*faceNormal) = normalize(cross(_e452, _e453));
                            let _e456 = determinant_;
                            (*side) = select(1f, -1f, (_e456 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e459 = triangle;
                        triangle = (_e459 + 1i);
                    }
                }
            } else {
                let _e462 = metadata[0u];
                left = i32((_e462 + 0.5f));
                let _e466 = metadata[1u];
                right = i32((_e466 + 0.5f));
                let _e469 = pointer;
                if ((_e469 + 2i) >= 64i) {
                    continue;
                }
                let _e472 = pointer;
                let _e473 = (_e472 + 1i);
                pointer = _e473;
                let _e474 = right;
                stack[_e473] = _e474;
                let _e476 = pointer;
                let _e477 = (_e476 + 1i);
                pointer = _e477;
                let _e478 = left;
                stack[_e477] = _e478;
            }
            continue;
        } else {
            break;
        }
    }
    let _e480 = found;
    return _e480;
}

fn bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1: texture_2d<f32>, nodesSampler_1: sampler, indices_1: texture_2d<f32>, indicesSampler_1: sampler, positions_1: texture_2d<f32>, positionsSampler_1: sampler, rayOrigin_1: ptr<function, vec3<f32>>, rayDirection_1: ptr<function, vec3<f32>>, maxDistance_1: ptr<function, f32>, faceIndices_2: ptr<function, vec4<u32>>, faceNormal_1: ptr<function, vec3<f32>>, barycoord_2: ptr<function, vec3<f32>>, side_1: ptr<function, f32>, dist_1: ptr<function, f32>) -> bool {
    var param_793: vec3<f32>;
    var param_794: vec3<f32>;
    var param_795: f32;
    var param_796: vec4<u32>;
    var param_797: vec3<f32>;
    var param_798: vec3<f32>;
    var param_799: f32;
    var param_800: f32;

    let _e284 = (*rayOrigin_1);
    param_793 = _e284;
    let _e285 = (*rayDirection_1);
    param_794 = _e285;
    let _e286 = (*maxDistance_1);
    param_795 = _e286;
    let _e287 = (*faceIndices_2);
    param_796 = _e287;
    let _e288 = (*faceNormal_1);
    param_797 = _e288;
    let _e289 = (*barycoord_2);
    param_798 = _e289;
    let _e290 = (*side_1);
    param_799 = _e290;
    let _e291 = (*dist_1);
    param_800 = _e291;
    let _e292 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_793), (&param_794), (&param_795), (&param_796), (&param_797), (&param_798), (&param_799), (&param_800));
    let _e293 = param_796;
    (*faceIndices_2) = _e293;
    let _e294 = param_797;
    (*faceNormal_1) = _e294;
    let _e295 = param_798;
    (*barycoord_2) = _e295;
    let _e296 = param_799;
    (*side_1) = _e296;
    let _e297 = param_800;
    (*dist_1) = _e297;
    return _e292;
}

fn trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b(rayOrigin_2: ptr<function, vec3<f32>>, rayDir: ptr<function, vec3<f32>>, maxDistance_2: ptr<function, f32>, P_2: ptr<function, vec3<f32>>, Ns: ptr<function, vec3<f32>>, Ng: ptr<function, vec3<f32>>, Ts: ptr<function, vec3<f32>>, Bs: ptr<function, vec3<f32>>, baryCoord_1: ptr<function, vec3<f32>>, texCoord_1: ptr<function, vec2<f32>>, material: ptr<function, i32>) -> bool {
    var faceIndices_surface: vec4<u32>;
    var faceNormal_surface: vec3<f32>;
    var barycoord_surface: vec3<f32>;
    var side_surface: f32;
    var dist_surface: f32;
    var hit_surface: bool;
    var param_801: vec3<f32>;
    var param_802: vec3<f32>;
    var param_803: f32;
    var param_804: vec4<u32>;
    var param_805: vec3<f32>;
    var param_806: vec3<f32>;
    var param_807: f32;
    var param_808: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_809: vec3<f32>;
    var gN: vec4<f32>;
    var param_810: vec3<f32>;
    var param_811: vec3<u32>;
    var gT: vec4<f32>;
    var param_812: vec3<f32>;
    var param_813: vec3<u32>;
    var gS: vec4<f32>;
    var param_814: vec3<f32>;
    var param_815: vec3<u32>;
    var local_11: vec3<f32>;
    var local_12: vec2<f32>;
    var local_13: vec3<f32>;
    var param_816: vec3<f32>;
    var param_817: vec3<f32>;
    var param_818: vec3<f32>;
    var phi_1294_: bool;
    var phi_1316_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e308 = (*rayOrigin_2);
    param_801 = _e308;
    let _e309 = (*rayDir);
    param_802 = _e309;
    let _e310 = (*maxDistance_2);
    param_803 = _e310;
    let _e311 = faceIndices_surface;
    param_804 = _e311;
    let _e312 = faceNormal_surface;
    param_805 = _e312;
    let _e313 = barycoord_surface;
    param_806 = _e313;
    let _e314 = side_surface;
    param_807 = _e314;
    let _e315 = dist_surface;
    param_808 = _e315;
    let _e316 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_801), (&param_802), (&param_803), (&param_804), (&param_805), (&param_806), (&param_807), (&param_808));
    let _e317 = param_804;
    faceIndices_surface = _e317;
    let _e318 = param_805;
    faceNormal_surface = _e318;
    let _e319 = param_806;
    barycoord_surface = _e319;
    let _e320 = param_807;
    side_surface = _e320;
    let _e321 = param_808;
    dist_surface = _e321;
    hit_surface = _e316;
    dist_closest = 100000000000000000000f;
    let _e322 = hit_surface;
    if _e322 {
        let _e323 = dist_closest;
        let _e324 = dist_surface;
        dist_closest = min(_e323, _e324);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e327 = (*rayDir)[1u];
    if (abs(_e327) > 0.0000000001f) {
        let _e331 = (*rayOrigin_2)[1u];
        let _e334 = (*rayDir)[1u];
        t = ((0.01f - _e331) / _e334);
        let _e336 = t;
        let _e337 = (_e336 > 0f);
        phi_1294_ = _e337;
        if _e337 {
            let _e338 = t;
            let _e339 = dist_closest;
            let _e340 = (*maxDistance_2);
            phi_1294_ = (_e338 < min(_e339, _e340));
        }
        let _e344 = phi_1294_;
        if _e344 {
            let _e345 = t;
            dist_ground = _e345;
            hit_ground = true;
        }
    }
    let _e346 = hit_surface;
    let _e347 = hit_ground;
    hit = (_e346 || _e347);
    let _e349 = hit;
    if !(_e349) {
        return false;
    }
    let _e351 = hit_surface;
    phi_1316_ = _e351;
    if _e351 {
        let _e352 = hit_ground;
        let _e354 = dist_surface;
        let _e355 = dist_ground;
        phi_1316_ = (!(_e352) || (_e354 <= _e355));
    }
    let _e359 = phi_1316_;
    if _e359 {
        let _e360 = (*rayOrigin_2);
        let _e361 = dist_surface;
        let _e362 = (*rayDir);
        (*P_2) = (_e360 + (_e362 * _e361));
        let _e365 = barycoord_surface;
        (*baryCoord_1) = _e365;
        let _e366 = faceNormal_surface;
        param_809 = _e366;
        let _e367 = safe_normalize_u0028_vf3_u003b((&param_809));
        (*Ng) = _e367;
        let _e368 = barycoord_surface;
        param_810 = _e368;
        let _e369 = faceIndices_surface;
        param_811 = _e369.xyz;
        let _e371 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_810), (&param_811));
        gN = _e371;
        let _e372 = barycoord_surface;
        param_812 = _e372;
        let _e373 = faceIndices_surface;
        param_813 = _e373.xyz;
        let _e375 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_812), (&param_813));
        gT = _e375;
        let _e376 = barycoord_surface;
        param_814 = _e376;
        let _e377 = faceIndices_surface;
        param_815 = _e377.xyz;
        let _e379 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_814), (&param_815));
        gS = _e379;
        let _e381 = unnamed.has_normals_surface;
        if (_e381 != 0u) {
            let _e383 = gN;
            local_11 = _e383.xyz;
        } else {
            let _e385 = (*Ng);
            local_11 = _e385;
        }
        let _e386 = local_11;
        (*Ns) = _e386;
        let _e388 = unnamed.has_uvs_surface;
        if (_e388 != 0u) {
            let _e391 = gN[3u];
            let _e393 = gT[3u];
            local_12 = vec2<f32>(_e391, _e393);
        } else {
            let _e395 = barycoord_surface;
            local_12 = _e395.xy;
        }
        let _e397 = local_12;
        (*texCoord_1) = _e397;
        let _e399 = unnamed.has_tangents_surface;
        if (_e399 != 0u) {
            let _e401 = gT;
            local_13 = _e401.xyz;
        } else {
            let _e403 = (*Ns);
            param_816 = _e403;
            let _e404 = normalToTangent_u0028_vf3_u003b((&param_816));
            local_13 = _e404;
        }
        let _e405 = local_13;
        (*Ts) = _e405;
        let _e406 = (*Ns);
        param_817 = _e406;
        let _e407 = safe_normalize_u0028_vf3_u003b((&param_817));
        let _e408 = (*Ts);
        param_818 = _e408;
        let _e409 = safe_normalize_u0028_vf3_u003b((&param_818));
        (*Bs) = cross(_e407, _e409);
        let _e412 = gS[0u];
        (*material) = select(1i, 0i, (_e412 > 0.5f));
    } else {
        let _e415 = hit_ground;
        if _e415 {
            let _e416 = (*rayOrigin_2);
            let _e417 = dist_ground;
            let _e418 = (*rayDir);
            (*P_2) = (_e416 + (_e418 * _e417));
            (*material) = 2i;
            (*baryCoord_1) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e421 = (*Ng);
            (*Ns) = _e421;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            (*Bs) = vec3<f32>(0f, 0f, -1f);
            let _e423 = (*P_2)[0u];
            let _e425 = (*P_2)[2u];
            (*texCoord_1) = (((vec2<f32>(_e423, -(_e425)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_4: Basis;
    var param_819: vec3<f32>;
    var param_820: vec3<f32>;

    let _e266 = (*nW_1);
    param_819 = _e266;
    let _e267 = safe_normalize_u0028_vf3_u003b((&param_819));
    basis_4.nW = _e267;
    let _e269 = (*nW_1);
    param_820 = _e269;
    let _e270 = normalToTangent_u0028_vf3_u003b((&param_820));
    basis_4.tW = _e270;
    let _e273 = basis_4.nW;
    let _e275 = basis_4.tW;
    basis_4.bW = cross(_e273, _e275);
    basis_4.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_4.texCoord = vec2<f32>(0f, 0f);
    let _e280 = basis_4;
    return _e280;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_3: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e272 = (*cameraWorld);
    lookDirection = (_e272 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e274 = (*inverseProjection);
    nearVector = (_e274 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e277 = nearVector[2u];
    let _e279 = nearVector[3u];
    nearDistance_1 = abs((_e277 / _e279));
    let _e282 = (*cameraWorld);
    origin_1 = (_e282 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e284 = (*inverseProjection);
    let _e285 = (*coordinate);
    direction_1 = (_e284 * vec4<f32>(_e285.x, _e285.y, 0.5f, 1f));
    let _e291 = direction_1[3u];
    let _e292 = direction_1;
    direction_1 = (_e292 / vec4(_e291));
    let _e295 = (*cameraWorld);
    let _e296 = direction_1;
    let _e298 = origin_1;
    direction_1 = ((_e295 * _e296) - _e298);
    let _e300 = direction_1;
    let _e302 = nearDistance_1;
    let _e304 = direction_1;
    let _e305 = lookDirection;
    let _e309 = origin_1;
    let _e311 = (_e309.xyz + ((_e300.xyz * _e302) / vec3(dot(_e304, _e305))));
    origin_1[0u] = _e311.x;
    origin_1[1u] = _e311.y;
    origin_1[2u] = _e311.z;
    let _e318 = origin_1;
    (*rayOrigin_3) = _e318.xyz;
    let _e320 = direction_1;
    (*rayDirection_2) = _e320.xyz;
    return;
}

fn main_1() {
    var pixel: vec2<f32>;
    var ndc: vec2<f32>;
    var pW_3: vec3<f32>;
    var dW: vec3<f32>;
    var param_821: vec2<f32>;
    var param_822: mat4x4<f32>;
    var param_823: mat4x4<f32>;
    var param_824: vec3<f32>;
    var param_825: vec3<f32>;
    var param_826: vec3<f32>;
    var surface_hit: bool;
    var pW_hit: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW: vec3<f32>;
    var BsW: vec3<f32>;
    var baryCoord_2: vec3<f32>;
    var texCoord_2: vec2<f32>;
    var material_1: i32;
    var param_827: vec3<f32>;
    var param_828: vec3<f32>;
    var param_829: f32;
    var param_830: vec3<f32>;
    var param_831: vec3<f32>;
    var param_832: vec3<f32>;
    var param_833: vec3<f32>;
    var param_834: vec3<f32>;
    var param_835: vec3<f32>;
    var param_836: vec2<f32>;
    var param_837: i32;
    var param_838: vec3<f32>;
    var param_839: vec3<f32>;
    var basis_5: Basis;
    var param_840: vec3<f32>;
    var param_841: vec3<f32>;
    var param_842: vec3<f32>;
    var param_843: vec3<f32>;
    var param_844: vec2<f32>;
    var param_845: vec3<f32>;
    var param_846: vec3<f32>;
    var param_847: vec3<f32>;
    var param_848: vec3<f32>;
    var param_849: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_2: vec3<f32>;
    var param_850: vec3<f32>;
    var param_851: Basis;
    var rndSeed_1: u32;
    var param_852: vec3<f32>;
    var param_853: Basis;
    var param_854: vec3<f32>;
    var param_855: u32;
    var viewReflectW: vec3<f32>;
    var viewReflectL: vec3<f32>;
    var param_856: vec3<f32>;
    var param_857: Basis;
    var L_8: vec3<f32>;
    var param_858: vec3<f32>;
    var param_859: Basis;
    var param_860: vec3<f32>;
    var param_861: vec3<f32>;
    var param_862: vec3<f32>;
    var param_863: vec3<f32>;

    base_color_1 = vec3<f32>(1f, 1f, 1f);
    metallic_1 = 0f;
    roughness_18 = 0.01f;
    occlusion_3 = 1f;
    transmission_1 = 1f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    ior_7 = 1.52f;
    alpha_13 = 1f;
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
    let _e325 = gl_FragCoord_1;
    pixel = (_e325.xy + vec2<f32>(0.5f, 0.5f));
    let _e328 = pixel;
    let _e330 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e328 / _e330) * 2f));
    let _e336 = unnamed.invModelMatrix;
    let _e338 = unnamed.cameraWorldMatrix;
    let _e340 = ndc;
    param_821 = _e340;
    param_822 = (_e336 * _e338);
    let _e342 = unnamed.invProjectionMatrix;
    param_823 = _e342;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_821), (&param_822), (&param_823), (&param_824), (&param_825));
    let _e343 = param_824;
    pW_3 = _e343;
    let _e344 = param_825;
    dW = _e344;
    let _e345 = dW;
    dW = normalize(_e345);
    let _e348 = unnamed.sunDir;
    param_826 = _e348;
    let _e349 = makeBasis_u0028_vf3_u003b((&param_826));
    sunBasis = _e349;
    let _e350 = pW_3;
    param_827 = _e350;
    let _e351 = dW;
    param_828 = _e351;
    param_829 = 100000000000000000000f;
    let _e352 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_827), (&param_828), (&param_829), (&param_830), (&param_831), (&param_832), (&param_833), (&param_834), (&param_835), (&param_836), (&param_837));
    let _e353 = param_830;
    pW_hit = _e353;
    let _e354 = param_831;
    NsW = _e354;
    let _e355 = param_832;
    NgW = _e355;
    let _e356 = param_833;
    TsW = _e356;
    let _e357 = param_834;
    BsW = _e357;
    let _e358 = param_835;
    baryCoord_2 = _e358;
    let _e359 = param_836;
    texCoord_2 = _e359;
    let _e360 = param_837;
    material_1 = _e360;
    surface_hit = _e352;
    let _e361 = surface_hit;
    if !(_e361) {
        let _e363 = dW;
        param_838 = _e363;
        let _e364 = sunRadiance_u0028_vf3_u003b((&param_838));
        let _e365 = dW;
        param_839 = _e365;
        let _e366 = skyRadiance_u0028_vf3_u003b((&param_839));
        let _e367 = (_e364 + _e366);
        mtlxFragmentColor[0u] = _e367.x;
        mtlxFragmentColor[1u] = _e367.y;
        mtlxFragmentColor[2u] = _e367.z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    let _e375 = NsW;
    let _e376 = dW;
    if (dot(_e375, _e376) > 0f) {
        let _e379 = NsW;
        NsW = (_e379 * -1f);
    }
    let _e381 = NgW;
    let _e382 = NsW;
    if (dot(_e381, _e382) < 0f) {
        let _e385 = NgW;
        NgW = (_e385 * -1f);
    }
    let _e388 = unnamed.smooth_normals;
    if (_e388 != 0u) {
        let _e390 = NsW;
        param_840 = _e390;
        let _e391 = TsW;
        param_841 = _e391;
        let _e392 = BsW;
        param_842 = _e392;
        let _e393 = baryCoord_2;
        param_843 = _e393;
        let _e394 = texCoord_2;
        param_844 = _e394;
        let _e395 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844));
        basis_5 = _e395;
    } else {
        let _e396 = NgW;
        param_845 = _e396;
        let _e397 = TsW;
        param_846 = _e397;
        let _e398 = BsW;
        param_847 = _e398;
        let _e399 = baryCoord_2;
        param_848 = _e399;
        let _e400 = texCoord_2;
        param_849 = _e400;
        let _e401 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_845), (&param_846), (&param_847), (&param_848), (&param_849));
        basis_5 = _e401;
    }
    let _e402 = dW;
    winputW = -(_e402);
    let _e404 = winputW;
    param_850 = _e404;
    let _e405 = basis_5;
    param_851 = _e405;
    let _e406 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_850), (&param_851));
    winputL_2 = _e406;
    let _e408 = winputL_2[2u];
    if (abs(_e408) < 0.001f) {
        mtlxFragmentColor[0u] = vec3<f32>(0f, 0f, 0f).x;
        mtlxFragmentColor[1u] = vec3<f32>(0f, 0f, 0f).y;
        mtlxFragmentColor[2u] = vec3<f32>(0f, 0f, 0f).z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    rndSeed_1 = 0u;
    let _e418 = material_1;
    if (_e418 == 1i) {
        let _e420 = pW_hit;
        param_852 = _e420;
        let _e421 = basis_5;
        param_853 = _e421;
        let _e422 = winputL_2;
        param_854 = _e422;
        let _e423 = rndSeed_1;
        param_855 = _e423;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_852), (&param_853), (&param_854), (&param_855));
        let _e424 = param_855;
        rndSeed_1 = _e424;
    }
    let _e425 = dW;
    let _e427 = basis_5.nW;
    viewReflectW = reflect(_e425, _e427);
    let _e429 = viewReflectW;
    param_856 = _e429;
    let _e430 = basis_5;
    param_857 = _e430;
    let _e431 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_856), (&param_857));
    viewReflectL = _e431;
    let _e433 = viewReflectL[2u];
    if (_e433 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e435 = material_1;
    if (_e435 == 1i) {
        let _e437 = pW_hit;
        param_858 = _e437;
        let _e438 = basis_5;
        param_859 = _e438;
        let _e439 = winputL_2;
        param_860 = _e439;
        let _e440 = viewReflectL;
        param_861 = _e440;
        let _e441 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_858), (&param_859), (&param_860), (&param_861));
        L_8 = _e441;
    } else {
        let _e442 = material_1;
        if (_e442 == 2i) {
            let _e444 = pW_hit;
            param_862 = _e444;
            let _e445 = ground_albedo_u0028_vf3_u003b((&param_862));
            L_8 = _e445;
        } else {
            let _e447 = unnamed.neutral_color;
            let _e449 = basis_5.nW;
            param_863 = _e449;
            let _e450 = skyRadiance_u0028_vf3_u003b((&param_863));
            L_8 = (_e447 * _e450);
        }
    }
    let _e452 = L_8;
    let _e454 = unnamed.firefly_clamp;
    let _e456 = clamp(_e452, vec3<f32>(0f, 0f, 0f), vec3(_e454));
    mtlxFragmentColor[0u] = _e456.x;
    mtlxFragmentColor[1u] = _e456.y;
    mtlxFragmentColor[2u] = _e456.z;
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
