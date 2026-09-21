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

    let _e269 = (*pW)[0u];
    let _e271 = (*pW)[2u];
    uv = (((vec2<f32>(_e269, -(_e271)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e279 = uv;
    let _e280 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e279, 0.0);
    return _e280.xyz;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result: ptr<function, vec3<f32>>) {
    let _e270 = (*closureData).closureType;
    if (_e270 == 4i) {
        let _e272 = (*color);
        (*result) = _e272;
    }
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_1: ptr<function, ClosureData>, top: ptr<function, BSDF>, base: ptr<function, BSDF>, result_1: ptr<function, BSDF>) {
    let _e271 = (*top).response;
    let _e273 = (*base).response;
    let _e275 = (*top).throughput;
    (*result_1).response = (_e271 + (_e273 * _e275));
    let _e280 = (*top).throughput;
    let _e282 = (*base).throughput;
    (*result_1).throughput = (_e280 * _e282);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e270 = (*dir)[1u];
    latitude = ((-(asin(_e270)) * 0.31830987f) + 0.5f);
    let _e276 = (*dir)[0u];
    let _e278 = (*dir)[2u];
    longitude = (((atan2(_e276, -(_e278)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e284 = longitude;
    let _e285 = latitude;
    return vec2<f32>(_e284, _e285);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e268 = (*m);
    let _e269 = (*v);
    return (_e268 * _e269);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param: mat4x4<f32>;
    var param_1: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_2: vec3<f32>;

    let _e274 = (*dir_1);
    let _e279 = (*transform);
    param = _e279;
    param_1 = vec4<f32>(_e274.x, _e274.y, _e274.z, 0f);
    let _e280 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param), (&param_1));
    envDir = normalize(_e280.xyz);
    let _e283 = envDir;
    param_2 = _e283;
    let _e284 = mx_latlong_projection_u0028_vf3_u003b((&param_2));
    uv_1 = _e284;
    let _e285 = uv_1;
    let _e286 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e285, 0.0);
    return _e286.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e269 = a;
    c = cos(_e269);
    let _e271 = a;
    s = sin(_e271);
    let _e273 = c;
    let _e274 = s;
    let _e276 = s;
    let _e277 = c;
    return mat4x4<f32>(vec4<f32>(_e273, 0f, -(_e274), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e276, 0f, _e277, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_3: vec3<f32>;
    var param_4: mat4x4<f32>;
    var param_5: f32;

    let _e271 = mtlxEnvMatrix_u0028_();
    let _e272 = (*N);
    param_3 = _e272;
    param_4 = _e271;
    param_5 = 0f;
    let _e273 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_3), (&param_4), (&param_5));
    Li = _e273;
    let _e274 = Li;
    let _e276 = unnamed.skyPower;
    return (_e274 * _e276);
}

fn mx_square_u0028_f1_u003b(x: ptr<function, f32>) -> f32 {
    let _e267 = (*x);
    let _e268 = (*x);
    return (_e267 * _e268);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_6: f32;

    let _e270 = (*roughness);
    let _e273 = (*NdotV);
    let _e275 = (*roughness);
    let _e278 = (*roughness);
    param_6 = _e278;
    let _e279 = mx_square_u0028_f1_u003b((&param_6));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e270)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e273) * _e275)) + (vec2<f32>(1.4385f, 2.0315f) * _e279));
    let _e283 = r[0u];
    let _e285 = r[1u];
    return (_e283 / _e285);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_7: f32;
    var param_8: f32;

    let _e271 = (*NdotV_1);
    param_7 = _e271;
    let _e272 = (*roughness_1);
    param_8 = _e272;
    let _e273 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_7), (&param_8));
    dirAlbedo = _e273;
    let _e274 = dirAlbedo;
    return clamp(_e274, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e267 = (*x_1);
    let _e268 = (*x_1);
    return (_e267 * _e268);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e268 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e268)));
    let _e272 = A;
    let _e273 = (*roughness_2);
    return (_e272 * (1f + (0.07248821f * _e273)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_9: f32;
    var G: f32;

    let _e273 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e273)));
    let _e277 = (*roughness_3);
    let _e278 = A_1;
    B = (_e277 * _e278);
    let _e280 = (*cosTheta);
    param_9 = _e280;
    let _e281 = mx_square_u0028_f1_u003b((&param_9));
    Si = sqrt(max(0f, (1f - _e281)));
    let _e285 = Si;
    let _e286 = (*cosTheta);
    let _e289 = Si;
    let _e290 = (*cosTheta);
    let _e294 = Si;
    let _e295 = (*cosTheta);
    let _e297 = Si;
    let _e298 = Si;
    let _e300 = Si;
    let _e304 = Si;
    G = ((_e285 * (acos(clamp(_e286, -1f, 1f)) - (_e289 * _e290))) + ((2f * (((_e294 / _e295) * (1f - ((_e297 * _e298) * _e300))) - _e304)) / 3f));
    let _e309 = A_1;
    let _e310 = B;
    let _e311 = G;
    return (_e309 + ((_e310 * _e311) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_1: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_10: f32;
    var param_11: f32;
    var avgAlbedo: f32;
    var param_12: f32;
    var colorMultiScatter: vec3<f32>;
    var param_13: vec3<f32>;

    let _e276 = (*cosTheta_1);
    param_10 = _e276;
    let _e277 = (*roughness_4);
    param_11 = _e277;
    let _e278 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_10), (&param_11));
    dirAlbedo_1 = _e278;
    let _e279 = (*roughness_4);
    param_12 = _e279;
    let _e280 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_12));
    avgAlbedo = _e280;
    let _e281 = (*color_1);
    param_13 = _e281;
    let _e282 = mx_square_u0028_vf3_u003b((&param_13));
    let _e283 = avgAlbedo;
    let _e285 = (*color_1);
    let _e286 = avgAlbedo;
    colorMultiScatter = ((_e282 * _e283) / (vec3<f32>(1f, 1f, 1f) - (_e285 * max(0f, (1f - _e286)))));
    let _e292 = colorMultiScatter;
    let _e293 = (*color_1);
    let _e294 = dirAlbedo_1;
    return mix(_e292, _e293, vec3(_e294));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local: f32;
    var sigma2_: f32;
    var param_14: f32;
    var A_2: f32;
    var B_1: f32;

    let _e277 = (*LdotV);
    let _e278 = (*NdotL);
    let _e279 = (*NdotV_2);
    s_1 = (_e277 - (_e278 * _e279));
    let _e282 = s_1;
    if (_e282 > 0f) {
        let _e284 = s_1;
        let _e285 = (*NdotL);
        let _e286 = (*NdotV_2);
        local = (_e284 / max(_e285, _e286));
    } else {
        local = 0f;
    }
    let _e289 = local;
    stinv = _e289;
    let _e290 = (*roughness_5);
    param_14 = _e290;
    let _e291 = mx_square_u0028_f1_u003b((&param_14));
    sigma2_ = _e291;
    let _e292 = sigma2_;
    let _e293 = sigma2_;
    A_2 = (1f - (0.5f * (_e292 / (_e293 + 0.33f))));
    let _e298 = sigma2_;
    let _e300 = sigma2_;
    B_1 = ((0.45f * _e298) / (_e300 + 0.09f));
    let _e303 = A_2;
    let _e304 = B_1;
    let _e305 = stinv;
    return (_e303 + (_e304 * _e305));
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

    let _e287 = (*LdotV_1);
    let _e288 = (*NdotL_1);
    let _e289 = (*NdotV_3);
    s_2 = (_e287 - (_e288 * _e289));
    let _e292 = s_2;
    if (_e292 > 0f) {
        let _e294 = s_2;
        let _e295 = (*NdotL_1);
        let _e296 = (*NdotV_3);
        local_1 = (_e294 / max(_e295, _e296));
    } else {
        let _e299 = s_2;
        local_1 = _e299;
    }
    let _e300 = local_1;
    stinv_1 = _e300;
    let _e301 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e301)));
    let _e305 = (*color_2);
    let _e306 = A_3;
    let _e308 = (*roughness_6);
    let _e309 = stinv_1;
    lobeSingleScatter = ((_e305 * _e306) * (1f + (_e308 * _e309)));
    let _e313 = (*NdotV_3);
    param_15 = _e313;
    let _e314 = (*roughness_6);
    param_16 = _e314;
    let _e315 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_15), (&param_16));
    dirAlbedoV = _e315;
    let _e316 = (*NdotL_1);
    param_17 = _e316;
    let _e317 = (*roughness_6);
    param_18 = _e317;
    let _e318 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_17), (&param_18));
    dirAlbedoL = _e318;
    let _e319 = (*roughness_6);
    param_19 = _e319;
    let _e320 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_19));
    avgAlbedo_1 = _e320;
    let _e321 = (*color_2);
    param_20 = _e321;
    let _e322 = mx_square_u0028_vf3_u003b((&param_20));
    let _e323 = avgAlbedo_1;
    let _e325 = (*color_2);
    let _e326 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e322 * _e323) / (vec3<f32>(1f, 1f, 1f) - (_e325 * max(0f, (1f - _e326)))));
    let _e332 = colorMultiScatter_1;
    let _e333 = dirAlbedoV;
    let _e337 = dirAlbedoL;
    let _e341 = avgAlbedo_1;
    lobeMultiScatter = (((_e332 * max(0.00000001f, (1f - _e333))) * max(0.00000001f, (1f - _e337))) / vec3(max(0.00000001f, (1f - _e341))));
    let _e346 = lobeSingleScatter;
    let _e347 = lobeMultiScatter;
    return (_e346 + _e347);
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N_1: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local_2: vec3<f32>;

    let _e269 = (*N_1);
    let _e270 = (*V);
    if (dot(_e269, _e270) < 0f) {
        let _e273 = (*N_1);
        local_2 = -(_e273);
    } else {
        let _e275 = (*N_1);
        local_2 = _e275;
    }
    let _e276 = local_2;
    return _e276;
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
    let _e301 = (*weight);
    if (_e301 < 0.00000001f) {
        return;
    }
    let _e304 = (*closureData_2).V;
    V_1 = _e304;
    let _e306 = (*closureData_2).L;
    L = _e306;
    let _e307 = (*N_2);
    param_21 = _e307;
    let _e308 = V_1;
    param_22 = _e308;
    let _e309 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_21), (&param_22));
    (*N_2) = _e309;
    let _e310 = (*N_2);
    let _e311 = V_1;
    NdotV_4 = clamp(dot(_e310, _e311), 0.00000001f, 1f);
    let _e315 = (*closureData_2).closureType;
    if (_e315 == 1i) {
        let _e317 = (*N_2);
        let _e318 = L;
        NdotL_2 = clamp(dot(_e317, _e318), 0.00000001f, 1f);
        let _e321 = L;
        let _e322 = V_1;
        LdotV_2 = clamp(dot(_e321, _e322), 0.00000001f, 1f);
        let _e325 = (*energy_compensation);
        if _e325 {
            let _e326 = NdotV_4;
            param_23 = _e326;
            let _e327 = NdotL_2;
            param_24 = _e327;
            let _e328 = LdotV_2;
            param_25 = _e328;
            let _e329 = (*roughness_7);
            param_26 = _e329;
            let _e330 = (*color_3);
            param_27 = _e330;
            let _e331 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_23), (&param_24), (&param_25), (&param_26), (&param_27));
            local_3 = _e331;
        } else {
            let _e332 = NdotV_4;
            param_28 = _e332;
            let _e333 = NdotL_2;
            param_29 = _e333;
            let _e334 = LdotV_2;
            param_30 = _e334;
            let _e335 = (*roughness_7);
            param_31 = _e335;
            let _e336 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_28), (&param_29), (&param_30), (&param_31));
            let _e337 = (*color_3);
            local_3 = (_e337 * _e336);
        }
        let _e339 = local_3;
        diffuse = _e339;
        let _e340 = diffuse;
        let _e342 = (*closureData_2).occlusion;
        let _e344 = (*weight);
        let _e346 = NdotL_2;
        (*bsdf).response = ((((_e340 * _e342) * _e344) * _e346) * 0.31830987f);
    } else {
        let _e351 = (*closureData_2).closureType;
        if (_e351 == 3i) {
            let _e353 = (*energy_compensation);
            if _e353 {
                let _e354 = NdotV_4;
                param_32 = _e354;
                let _e355 = (*roughness_7);
                param_33 = _e355;
                let _e356 = (*color_3);
                param_34 = _e356;
                let _e357 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_32), (&param_33), (&param_34));
                local_4 = _e357;
            } else {
                let _e358 = NdotV_4;
                param_35 = _e358;
                let _e359 = (*roughness_7);
                param_36 = _e359;
                let _e360 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_35), (&param_36));
                let _e361 = (*color_3);
                local_4 = (_e361 * _e360);
            }
            let _e363 = local_4;
            diffuse_1 = _e363;
            let _e364 = (*N_2);
            param_37 = _e364;
            let _e365 = mx_environment_irradiance_u0028_vf3_u003b((&param_37));
            Li_1 = _e365;
            let _e366 = Li_1;
            let _e367 = diffuse_1;
            let _e369 = (*weight);
            (*bsdf).response = ((_e366 * _e367) * _e369);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_3: ptr<function, ClosureData>, in1_: ptr<function, BSDF>, in2_: ptr<function, f32>, result_2: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e271 = (*in2_);
    weight_1 = clamp(_e271, 0f, 1f);
    let _e274 = (*in1_).response;
    let _e275 = weight_1;
    (*result_2).response = (_e274 * _e275);
    let _e279 = (*in1_).throughput;
    (*result_2).throughput = _e279;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, BSDF>, result_3: ptr<function, BSDF>) {
    let _e271 = (*in1_1).response;
    let _e273 = (*in2_1).response;
    (*result_3).response = (_e271 + _e273);
    let _e277 = (*in1_1).throughput;
    let _e279 = (*in2_1).throughput;
    (*result_3).throughput = max(((_e277 + _e279) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_3: ptr<function, f32>, NdotV_5: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_38: f32;
    var lambdaL: f32;
    var param_39: f32;
    var lambdaV: f32;
    var param_40: f32;

    let _e275 = (*alpha);
    param_38 = _e275;
    let _e276 = mx_square_u0028_f1_u003b((&param_38));
    alpha2_ = _e276;
    let _e277 = alpha2_;
    let _e278 = alpha2_;
    let _e280 = (*NdotL_3);
    param_39 = _e280;
    let _e281 = mx_square_u0028_f1_u003b((&param_39));
    lambdaL = sqrt((_e277 + ((1f - _e278) * _e281)));
    let _e285 = alpha2_;
    let _e286 = alpha2_;
    let _e288 = (*NdotV_5);
    param_40 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_40));
    lambdaV = sqrt((_e285 + ((1f - _e286) * _e289)));
    let _e293 = (*NdotL_3);
    let _e295 = (*NdotV_5);
    let _e297 = lambdaL;
    let _e298 = (*NdotV_5);
    let _e300 = lambdaV;
    let _e301 = (*NdotL_3);
    return (((2f * _e293) * _e295) / ((_e297 * _e298) + (_e300 * _e301)));
}

fn mx_pow6_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_41: f32;
    var param_42: f32;

    let _e270 = (*x_2);
    param_41 = _e270;
    let _e271 = mx_square_u0028_f1_u003b((&param_41));
    x2_ = _e271;
    let _e272 = x2_;
    param_42 = _e272;
    let _e273 = mx_square_u0028_f1_u003b((&param_42));
    let _e274 = x2_;
    return (_e273 * _e274);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_2: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_3: f32;
    var a_1: vec3<f32>;
    var param_43: f32;

    let _e271 = (*cosTheta_2);
    x_3 = clamp(_e271, 0f, 1f);
    let _e274 = (*fd).F0_;
    let _e276 = (*fd).F90_;
    let _e278 = (*fd).exponent;
    let _e283 = (*fd).F82_;
    a_1 = ((mix(_e274, _e276, vec3(pow(0.85714287f, _e278))) * (vec3<f32>(1f, 1f, 1f) - _e283)) * 17.651384f);
    let _e288 = (*fd).F0_;
    let _e290 = (*fd).F90_;
    let _e291 = x_3;
    let _e294 = (*fd).exponent;
    let _e298 = a_1;
    let _e299 = x_3;
    let _e301 = x_3;
    param_43 = (1f - _e301);
    let _e303 = mx_pow6_u0028_f1_u003b((&param_43));
    return (mix(_e288, _e290, vec3(pow((1f - _e291), _e294))) - ((_e298 * _e299) * _e303));
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

    let _e283 = (*cosTheta_3);
    param_44 = clamp(_e283, 0f, 1f);
    let _e285 = mx_square_u0028_f1_u003b((&param_44));
    cosTheta2_ = _e285;
    let _e286 = cosTheta2_;
    sinTheta2_ = (1f - _e286);
    let _e288 = (*n);
    let _e289 = (*n);
    n2_ = (_e288 * _e289);
    let _e291 = (*k);
    let _e292 = (*k);
    k2_ = (_e291 * _e292);
    let _e294 = n2_;
    let _e295 = k2_;
    let _e297 = sinTheta2_;
    t0_ = ((_e294 - _e295) - vec3(_e297));
    let _e300 = t0_;
    let _e301 = t0_;
    let _e303 = n2_;
    let _e305 = k2_;
    a2plusb2_ = sqrt(((_e300 * _e301) + ((_e303 * 4f) * _e305)));
    let _e309 = a2plusb2_;
    let _e310 = cosTheta2_;
    t1_ = (_e309 + vec3(_e310));
    let _e313 = a2plusb2_;
    let _e314 = t0_;
    a_2 = sqrt(max(((_e313 + _e314) * 0.5f), vec3(0f)));
    let _e320 = a_2;
    let _e322 = (*cosTheta_3);
    t2_ = ((_e320 * 2f) * _e322);
    let _e324 = t1_;
    let _e325 = t2_;
    let _e327 = t1_;
    let _e328 = t2_;
    (*Rs) = ((_e324 - _e325) / (_e327 + _e328));
    let _e331 = cosTheta2_;
    let _e332 = a2plusb2_;
    let _e334 = sinTheta2_;
    let _e335 = sinTheta2_;
    t3_ = ((_e332 * _e331) + vec3((_e334 * _e335)));
    let _e339 = t2_;
    let _e340 = sinTheta2_;
    t4_ = (_e339 * _e340);
    let _e342 = (*Rs);
    let _e343 = t3_;
    let _e344 = t4_;
    let _e347 = t3_;
    let _e348 = t4_;
    (*Rp) = ((_e342 * (_e343 - _e344)) / (_e347 + _e348));
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

    let _e276 = (*cosTheta_4);
    param_45 = _e276;
    let _e277 = (*n_1);
    param_46 = _e277;
    let _e278 = (*k_1);
    param_47 = _e278;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_45), (&param_46), (&param_47), (&param_48), (&param_49));
    let _e279 = param_48;
    Rp_1 = _e279;
    let _e280 = param_49;
    Rs_1 = _e280;
    let _e281 = Rp_1;
    let _e282 = Rs_1;
    return ((_e281 + _e282) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_5: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_50: f32;
    var param_51: f32;

    let _e273 = (*cosTheta_5);
    c_1 = _e273;
    let _e274 = (*ior);
    let _e275 = (*ior);
    let _e277 = c_1;
    let _e278 = c_1;
    g2_ = (((_e274 * _e275) + (_e277 * _e278)) - 1f);
    let _e282 = g2_;
    if (_e282 < 0f) {
        return 1f;
    }
    let _e284 = g2_;
    g = sqrt(_e284);
    let _e286 = g;
    let _e287 = c_1;
    let _e289 = g;
    let _e290 = c_1;
    param_50 = ((_e286 - _e287) / (_e289 + _e290));
    let _e293 = mx_square_u0028_f1_u003b((&param_50));
    let _e295 = g;
    let _e296 = c_1;
    let _e298 = c_1;
    let _e301 = g;
    let _e302 = c_1;
    let _e304 = c_1;
    param_51 = ((((_e295 + _e296) * _e298) - 1f) / (((_e301 - _e302) * _e304) + 1f));
    let _e308 = mx_square_u0028_f1_u003b((&param_51));
    return ((0.5f * _e293) * (1f + _e308));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e268 = (*m_1);
    let _e269 = (*v_1);
    return (_e268 * _e269);
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e273 = (*opd);
    phase = (6.2831855f * _e273);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e275 = val;
    let _e276 = var_;
    let _e280 = pos;
    let _e281 = phase;
    let _e283 = (*shift);
    let _e287 = var_;
    let _e289 = phase;
    let _e291 = phase;
    xyz = (((_e275 * sqrt((_e276 * 6.2831855f))) * cos(((_e280 * _e281) + _e283))) * exp(((-(_e287) * _e289) * _e291)));
    let _e295 = phase;
    let _e298 = (*shift)[0u];
    let _e302 = phase;
    let _e304 = phase;
    let _e309 = xyz[0u];
    xyz[0u] = (_e309 + ((0.00000001644083f * cos(((2239900f * _e295) + _e298))) * exp(((-4528200000f * _e302) * _e304))));
    let _e312 = xyz;
    return (_e312 / vec3(0.00000010685f));
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

    let _e281 = (*kappa2_);
    let _e282 = (*eta2_);
    k2_1 = (_e281 / _e282);
    let _e284 = (*cosTheta_6);
    let _e285 = (*cosTheta_6);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e284 * _e285)));
    let _e289 = (*eta2_);
    let _e290 = (*eta2_);
    let _e292 = k2_1;
    let _e293 = k2_1;
    let _e297 = (*eta1_);
    let _e298 = (*eta1_);
    let _e300 = sinThetaSqr;
    A_4 = (((_e289 * _e290) * (vec3<f32>(1f, 1f, 1f) - (_e292 * _e293))) - (_e300 * (_e297 * _e298)));
    let _e303 = A_4;
    let _e304 = A_4;
    let _e306 = (*eta2_);
    let _e308 = (*eta2_);
    let _e310 = k2_1;
    param_52 = (((_e306 * 2f) * _e308) * _e310);
    let _e312 = mx_square_u0028_vf3_u003b((&param_52));
    B_2 = sqrt(((_e303 * _e304) + _e312));
    let _e315 = A_4;
    let _e316 = B_2;
    U = sqrt(((_e315 + _e316) / vec3(2f)));
    let _e321 = B_2;
    let _e322 = A_4;
    V_2 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e321 - _e322) / vec3(2f))));
    let _e328 = (*eta1_);
    let _e330 = V_2;
    let _e332 = (*cosTheta_6);
    let _e334 = U;
    let _e335 = U;
    let _e337 = V_2;
    let _e338 = V_2;
    let _e341 = (*eta1_);
    let _e342 = (*cosTheta_6);
    param_53 = (_e341 * _e342);
    let _e344 = mx_square_u0028_f1_u003b((&param_53));
    (*phiS) = atan2(((_e330 * (2f * _e328)) * _e332), (((_e334 * _e335) + (_e337 * _e338)) - vec3(_e344)));
    let _e348 = (*eta1_);
    let _e350 = (*eta2_);
    let _e352 = (*eta2_);
    let _e354 = (*cosTheta_6);
    let _e356 = k2_1;
    let _e358 = U;
    let _e360 = k2_1;
    let _e361 = k2_1;
    let _e364 = V_2;
    let _e368 = (*eta2_);
    let _e369 = (*eta2_);
    let _e371 = k2_1;
    let _e372 = k2_1;
    let _e376 = (*cosTheta_6);
    param_54 = (((_e368 * _e369) * (vec3<f32>(1f, 1f, 1f) + (_e371 * _e372))) * _e376);
    let _e378 = mx_square_u0028_vf3_u003b((&param_54));
    let _e379 = (*eta1_);
    let _e380 = (*eta1_);
    let _e382 = U;
    let _e383 = U;
    let _e385 = V_2;
    let _e386 = V_2;
    (*phiP) = atan2(((((_e350 * (2f * _e348)) * _e352) * _e354) * (((_e356 * 2f) * _e358) - ((vec3<f32>(1f, 1f, 1f) - (_e360 * _e361)) * _e364))), (_e378 - (((_e382 * _e383) + (_e385 * _e386)) * (_e379 * _e380))));
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

    let _e278 = (*cosTheta_7);
    param_55 = clamp(_e278, 0f, 1f);
    let _e280 = mx_square_u0028_f1_u003b((&param_55));
    cosTheta2_1 = _e280;
    let _e281 = cosTheta2_1;
    sinTheta2_1 = (1f - _e281);
    let _e283 = (*ior_1);
    let _e284 = (*ior_1);
    let _e286 = sinTheta2_1;
    t0_1 = max(((_e283 * _e284) - _e286), 0f);
    let _e289 = t0_1;
    let _e290 = cosTheta2_1;
    t1_1 = (_e289 + _e290);
    let _e292 = t0_1;
    let _e295 = (*cosTheta_7);
    t2_1 = ((2f * sqrt(_e292)) * _e295);
    let _e297 = t1_1;
    let _e298 = t2_1;
    let _e300 = t1_1;
    let _e301 = t2_1;
    Rs_2 = ((_e297 - _e298) / (_e300 + _e301));
    let _e304 = cosTheta2_1;
    let _e305 = t0_1;
    let _e307 = sinTheta2_1;
    let _e308 = sinTheta2_1;
    t3_1 = ((_e304 * _e305) + (_e307 * _e308));
    let _e311 = t2_1;
    let _e312 = sinTheta2_1;
    t4_1 = (_e311 * _e312);
    let _e314 = Rs_2;
    let _e315 = t3_1;
    let _e316 = t4_1;
    let _e319 = t3_1;
    let _e320 = t4_1;
    Rp_2 = ((_e314 * (_e315 - _e316)) / (_e319 + _e320));
    let _e323 = Rp_2;
    let _e324 = Rs_2;
    return vec2<f32>(_e323, _e324);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e268 = (*F0_);
    sqrtF0_ = sqrt(clamp(_e268, vec3(0.01f), vec3(0.99f)));
    let _e273 = sqrtF0_;
    let _e275 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e273) / (vec3<f32>(1f, 1f, 1f) - _e275));
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
    let _e322 = (*fd_1).tf_ior;
    let _e323 = eta1_1;
    eta2_1 = max(_e322, _e323);
    let _e326 = (*fd_1).model;
    if (_e326 == 2i) {
        let _e329 = (*fd_1).F0_;
        param_56 = _e329;
        let _e330 = mx_f0_to_ior_u0028_vf3_u003b((&param_56));
        local_5 = _e330;
    } else {
        let _e332 = (*fd_1).ior;
        local_5 = _e332;
    }
    let _e333 = local_5;
    eta3_ = _e333;
    let _e335 = (*fd_1).model;
    if (_e335 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e338 = (*fd_1).extinction;
        local_6 = _e338;
    }
    let _e339 = local_6;
    kappa3_ = _e339;
    let _e340 = (*cosTheta_8);
    param_57 = _e340;
    let _e341 = mx_square_u0028_f1_u003b((&param_57));
    let _e343 = eta1_1;
    let _e344 = eta2_1;
    param_58 = (_e343 / _e344);
    let _e346 = mx_square_u0028_f1_u003b((&param_58));
    cosThetaT = sqrt((1f - ((1f - _e341) * _e346)));
    let _e350 = eta2_1;
    let _e351 = eta1_1;
    let _e353 = (*cosTheta_8);
    param_59 = _e353;
    param_60 = (_e350 / _e351);
    let _e354 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_59), (&param_60));
    R12_ = _e354;
    let _e355 = cosThetaT;
    if (_e355 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e357 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e357);
    let _e360 = (*fd_1).model;
    if (_e360 == 2i) {
        let _e362 = cosThetaT;
        param_61 = _e362;
        let _e363 = (*fd_1);
        param_62 = _e363;
        let _e364 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_61), (&param_62));
        f = _e364;
        let _e365 = f;
        R23p = (_e365 * 0.5f);
        let _e367 = f;
        R23s = (_e367 * 0.5f);
    } else {
        let _e369 = eta3_;
        let _e370 = eta2_1;
        let _e373 = kappa3_;
        let _e374 = eta2_1;
        let _e377 = cosThetaT;
        param_63 = _e377;
        param_64 = (_e369 / vec3(_e370));
        param_65 = (_e373 / vec3(_e374));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_63), (&param_64), (&param_65), (&param_66), (&param_67));
        let _e378 = param_66;
        R23p = _e378;
        let _e379 = param_67;
        R23s = _e379;
    }
    let _e380 = eta2_1;
    let _e381 = eta1_1;
    cosB = cos(atan((_e380 / _e381)));
    let _e385 = (*cosTheta_8);
    let _e386 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e385 < _e386)), 3.1415927f);
    let _e391 = (*fd_1).model;
    if (_e391 == 2i) {
        let _e394 = eta3_[0u];
        let _e395 = eta2_1;
        let _e399 = eta3_[1u];
        let _e400 = eta2_1;
        let _e404 = eta3_[2u];
        let _e405 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e394 < _e395)), select(0f, 3.1415927f, (_e399 < _e400)), select(0f, 3.1415927f, (_e404 < _e405)));
        let _e409 = phi23p;
        phi23s = _e409;
    } else {
        let _e410 = cosThetaT;
        param_68 = _e410;
        let _e411 = eta2_1;
        param_69 = _e411;
        let _e412 = eta3_;
        param_70 = _e412;
        let _e413 = kappa3_;
        param_71 = _e413;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_68), (&param_69), (&param_70), (&param_71), (&param_72), (&param_73));
        let _e414 = param_72;
        phi23p = _e414;
        let _e415 = param_73;
        phi23s = _e415;
    }
    let _e417 = R12_[0u];
    let _e418 = R23p;
    r123p = max(sqrt((_e418 * _e417)), vec3(0f));
    let _e424 = R12_[1u];
    let _e425 = R23s;
    r123s = max(sqrt((_e425 * _e424)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e431 = (*fd_1).tf_thickness;
    distMeters = (_e431 * 0.000000001f);
    let _e433 = eta2_1;
    let _e435 = cosThetaT;
    let _e437 = distMeters;
    opd_1 = (((2f * _e433) * _e435) * _e437);
    let _e440 = T121_[0u];
    param_74 = _e440;
    let _e441 = mx_square_u0028_f1_u003b((&param_74));
    let _e442 = R23p;
    let _e445 = R12_[0u];
    let _e446 = R23p;
    Rs_3 = ((_e442 * _e441) / (vec3<f32>(1f, 1f, 1f) - (_e446 * _e445)));
    let _e451 = R12_[0u];
    let _e452 = Rs_3;
    let _e455 = I;
    I = (_e455 + (vec3(_e451) + _e452));
    let _e457 = Rs_3;
    let _e459 = T121_[0u];
    Cm = (_e457 - vec3(_e459));
    m_2 = 1i;
    loop {
        let _e462 = m_2;
        if (_e462 <= 2i) {
            let _e464 = r123p;
            let _e465 = Cm;
            Cm = (_e465 * _e464);
            let _e467 = m_2;
            let _e469 = opd_1;
            let _e471 = m_2;
            let _e473 = phi23p;
            let _e475 = phi21_[0u];
            param_75 = (f32(_e467) * _e469);
            param_76 = ((_e473 + vec3(_e475)) * f32(_e471));
            let _e479 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_75), (&param_76));
            Sm = (_e479 * 2f);
            let _e481 = Cm;
            let _e482 = Sm;
            let _e484 = I;
            I = (_e484 + (_e481 * _e482));
            continue;
        } else {
            break;
        }
        continuing {
            let _e486 = m_2;
            m_2 = (_e486 + 1i);
        }
    }
    let _e489 = T121_[1u];
    param_77 = _e489;
    let _e490 = mx_square_u0028_f1_u003b((&param_77));
    let _e491 = R23s;
    let _e494 = R12_[1u];
    let _e495 = R23s;
    Rp_3 = ((_e491 * _e490) / (vec3<f32>(1f, 1f, 1f) - (_e495 * _e494)));
    let _e500 = R12_[1u];
    let _e501 = Rp_3;
    let _e504 = I;
    I = (_e504 + (vec3(_e500) + _e501));
    let _e506 = Rp_3;
    let _e508 = T121_[1u];
    Cm = (_e506 - vec3(_e508));
    m_3 = 1i;
    loop {
        let _e511 = m_3;
        if (_e511 <= 2i) {
            let _e513 = r123s;
            let _e514 = Cm;
            Cm = (_e514 * _e513);
            let _e516 = m_3;
            let _e518 = opd_1;
            let _e520 = m_3;
            let _e522 = phi23s;
            let _e524 = phi21_[1u];
            param_78 = (f32(_e516) * _e518);
            param_79 = ((_e522 + vec3(_e524)) * f32(_e520));
            let _e528 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_78), (&param_79));
            Sm = (_e528 * 2f);
            let _e530 = Cm;
            let _e531 = Sm;
            let _e533 = I;
            I = (_e533 + (_e530 * _e531));
            continue;
        } else {
            break;
        }
        continuing {
            let _e535 = m_3;
            m_3 = (_e535 + 1i);
        }
    }
    let _e537 = I;
    I = (_e537 * 0.5f);
    param_80 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e539 = I;
    param_81 = _e539;
    let _e540 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_80), (&param_81));
    I = clamp(_e540, vec3(0f), vec3(1f));
    let _e544 = I;
    return _e544;
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

    let _e278 = (*fd_2).airy;
    if _e278 {
        let _e279 = (*cosTheta_9);
        param_82 = _e279;
        let _e280 = (*fd_2);
        param_83 = _e280;
        let _e281 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_82), (&param_83));
        return _e281;
    } else {
        let _e283 = (*fd_2).model;
        if (_e283 == 0i) {
            let _e285 = (*cosTheta_9);
            param_84 = _e285;
            let _e288 = (*fd_2).ior[0u];
            param_85 = _e288;
            let _e289 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
            return vec3(_e289);
        } else {
            let _e292 = (*fd_2).model;
            if (_e292 == 1i) {
                let _e294 = (*cosTheta_9);
                param_86 = _e294;
                let _e296 = (*fd_2).ior;
                param_87 = _e296;
                let _e298 = (*fd_2).extinction;
                param_88 = _e298;
                let _e299 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_86), (&param_87), (&param_88));
                return _e299;
            } else {
                let _e300 = (*cosTheta_9);
                param_89 = _e300;
                let _e301 = (*fd_2);
                param_90 = _e301;
                let _e302 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_89), (&param_90));
                return _e302;
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

    let _e274 = (*dir_2);
    let _e279 = (*transform_1);
    param_91 = _e279;
    param_92 = vec4<f32>(_e274.x, _e274.y, _e274.z, 0f);
    let _e280 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_91), (&param_92));
    envDir_1 = normalize(_e280.xyz);
    let _e283 = envDir_1;
    param_93 = _e283;
    let _e284 = mx_latlong_projection_u0028_vf3_u003b((&param_93));
    uv_2 = _e284;
    let _e285 = uv_2;
    let _e286 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e285, 0.0);
    return _e286.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_94: f32;

    let _e273 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e273 - 1.5f);
    let _e276 = (*dir_3)[1u];
    param_94 = _e276;
    let _e277 = mx_square_u0028_f1_u003b((&param_94));
    distortion = sqrt((1f - _e277));
    let _e280 = effectiveMaxMipLevel;
    let _e281 = (*envSamples);
    let _e283 = (*pdf);
    let _e285 = distortion;
    return max((_e280 - (0.5f * log2(((f32(_e281) * _e283) * _e285)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom: f32;
    var param_95: f32;
    var param_96: f32;

    let _e272 = (*H);
    let _e274 = (*alpha_1);
    He = (_e272.xy / _e274);
    let _e276 = He;
    let _e277 = He;
    let _e280 = (*H)[2u];
    param_95 = _e280;
    let _e281 = mx_square_u0028_f1_u003b((&param_95));
    denom = (dot(_e276, _e277) + _e281);
    let _e284 = (*alpha_1)[0u];
    let _e287 = (*alpha_1)[1u];
    let _e289 = denom;
    param_96 = _e289;
    let _e290 = mx_square_u0028_f1_u003b((&param_96));
    return (1f / (((3.1415927f * _e284) * _e287) * _e290));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_6: ptr<function, f32>) -> f32 {
    var param_97: vec3<f32>;
    var param_98: vec2<f32>;

    let _e272 = (*H_1);
    param_97 = _e272;
    let _e273 = (*alpha_2);
    param_98 = _e273;
    let _e274 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_97), (&param_98));
    let _e275 = (*G1V);
    let _e277 = (*NdotV_6);
    return ((_e274 * _e275) / (4f * _e277));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R: ptr<function, vec3<f32>>, N_3: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e270 = (*R);
    let _e271 = (*N_3);
    let _e272 = (*ior_2);
    (*R) = refract(_e270, _e271, (1f / _e272));
    let _e275 = (*R);
    let _e276 = (*R);
    let _e277 = (*N_3);
    let _e280 = (*N_3);
    N1_ = normalize(((_e275 * dot(_e276, _e277)) - (_e280 * 0.5f)));
    let _e284 = (*R);
    let _e285 = N1_;
    let _e286 = (*ior_2);
    return refract(_e284, _e285, _e286);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_3: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_4: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e276 = (*V_3);
    let _e278 = (*alpha_3);
    let _e279 = (_e276.xy * _e278);
    let _e281 = (*V_3)[2u];
    (*V_3) = normalize(vec3<f32>(_e279.x, _e279.y, _e281));
    let _e287 = (*Xi)[0u];
    phi = (6.2831855f * _e287);
    let _e290 = (*Xi)[1u];
    let _e293 = (*V_3)[2u];
    let _e297 = (*V_3)[2u];
    z = (((1f - _e290) * (1f + _e293)) - _e297);
    let _e299 = z;
    let _e300 = z;
    sinTheta = sqrt(clamp((1f - (_e299 * _e300)), 0f, 1f));
    let _e305 = sinTheta;
    let _e306 = phi;
    x_4 = (_e305 * cos(_e306));
    let _e309 = sinTheta;
    let _e310 = phi;
    y = (_e309 * sin(_e310));
    let _e313 = x_4;
    let _e314 = y;
    let _e315 = z;
    c_2 = vec3<f32>(_e313, _e314, _e315);
    let _e317 = c_2;
    let _e318 = (*V_3);
    H_2 = (_e317 + _e318);
    let _e320 = H_2;
    let _e322 = (*alpha_3);
    let _e323 = (_e320.xy * _e322);
    let _e325 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e323.x, _e323.y, max(_e325, 0f)));
    let _e331 = H_2;
    return _e331;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i: ptr<function, i32>) -> f32 {
    let _e267 = (*i);
    return fract(((f32(_e267) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_1: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_99: i32;

    let _e269 = (*i_1);
    let _e272 = (*numSamples);
    let _e275 = (*i_1);
    param_99 = _e275;
    let _e276 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_99));
    return vec2<f32>(((f32(_e269) + 0.5f) / f32(_e272)), _e276);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_10: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_100: f32;
    var tanTheta2_: f32;
    var param_101: f32;

    let _e272 = (*cosTheta_10);
    param_100 = _e272;
    let _e273 = mx_square_u0028_f1_u003b((&param_100));
    cosTheta2_2 = _e273;
    let _e274 = cosTheta2_2;
    let _e276 = cosTheta2_2;
    tanTheta2_ = ((1f - _e274) / _e276);
    let _e278 = (*alpha_4);
    param_101 = _e278;
    let _e279 = mx_square_u0028_f1_u003b((&param_101));
    let _e280 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e279 * _e280)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e268 = (*alpha_5)[0u];
    let _e270 = (*alpha_5)[1u];
    return sqrt((_e268 * _e270));
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

    let _e323 = (*X);
    let _e324 = (*X);
    let _e325 = (*N_4);
    let _e327 = (*N_4);
    (*X) = normalize((_e323 - (_e327 * dot(_e324, _e325))));
    let _e331 = (*N_4);
    let _e332 = (*X);
    Y = cross(_e331, _e332);
    let _e334 = (*X);
    let _e335 = Y;
    let _e336 = (*N_4);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e334.x, _e334.y, _e334.z), vec3<f32>(_e335.x, _e335.y, _e335.z), vec3<f32>(_e336.x, _e336.y, _e336.z));
    let _e350 = (*V_4);
    let _e351 = (*X);
    let _e353 = (*V_4);
    let _e354 = Y;
    let _e356 = (*V_4);
    let _e357 = (*N_4);
    (*V_4) = vec3<f32>(dot(_e350, _e351), dot(_e353, _e354), dot(_e356, _e357));
    let _e361 = (*V_4)[2u];
    NdotV_7 = clamp(_e361, 0.00000001f, 1f);
    let _e363 = (*alpha_6);
    param_102 = _e363;
    let _e364 = mx_average_alpha_u0028_vf2_u003b((&param_102));
    avgAlpha = _e364;
    let _e365 = NdotV_7;
    param_103 = _e365;
    let _e366 = avgAlpha;
    param_104 = _e366;
    let _e367 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_103), (&param_104));
    G1V_1 = _e367;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_2 = 0i;
    loop {
        let _e368 = i_2;
        let _e369 = envRadianceSamples;
        if (_e368 < _e369) {
            let _e371 = i_2;
            param_105 = _e371;
            let _e372 = envRadianceSamples;
            param_106 = _e372;
            let _e373 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_105), (&param_106));
            Xi_1 = _e373;
            let _e374 = Xi_1;
            param_107 = _e374;
            let _e375 = (*V_4);
            param_108 = _e375;
            let _e376 = (*alpha_6);
            param_109 = _e376;
            let _e377 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_107), (&param_108), (&param_109));
            H_3 = _e377;
            let _e379 = (*fd_3).refraction;
            if _e379 {
                let _e380 = (*V_4);
                param_110 = -(_e380);
                let _e382 = H_3;
                param_111 = _e382;
                let _e385 = (*fd_3).ior[0u];
                param_112 = _e385;
                let _e386 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_110), (&param_111), (&param_112));
                local_7 = _e386;
            } else {
                let _e387 = (*V_4);
                let _e388 = H_3;
                local_7 = -(reflect(_e387, _e388));
            }
            let _e391 = local_7;
            L_1 = _e391;
            let _e393 = L_1[2u];
            NdotL_4 = clamp(_e393, 0.00000001f, 1f);
            let _e395 = (*V_4);
            let _e396 = H_3;
            VdotH = clamp(dot(_e395, _e396), 0.00000001f, 1f);
            let _e399 = tangentToWorld;
            param_113 = _e399;
            let _e400 = L_1;
            param_114 = _e400;
            let _e401 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_113), (&param_114));
            Lw = _e401;
            let _e402 = H_3;
            param_115 = _e402;
            let _e403 = (*alpha_6);
            param_116 = _e403;
            let _e404 = G1V_1;
            param_117 = _e404;
            let _e405 = NdotV_7;
            param_118 = _e405;
            let _e406 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_115), (&param_116), (&param_117), (&param_118));
            pdf_1 = _e406;
            let _e407 = Lw;
            param_119 = _e407;
            let _e408 = pdf_1;
            param_120 = _e408;
            param_121 = 0f;
            let _e409 = envRadianceSamples;
            param_122 = _e409;
            let _e410 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_119), (&param_120), (&param_121), (&param_122));
            lod_2 = _e410;
            let _e411 = mtlxEnvMatrix_u0028_();
            let _e412 = Lw;
            param_123 = _e412;
            param_124 = _e411;
            let _e413 = lod_2;
            param_125 = _e413;
            let _e414 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_123), (&param_124), (&param_125));
            sampleColor = _e414;
            let _e415 = VdotH;
            param_126 = _e415;
            let _e416 = (*fd_3);
            param_127 = _e416;
            let _e417 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_126), (&param_127));
            F = _e417;
            let _e418 = NdotL_4;
            param_128 = _e418;
            let _e419 = NdotV_7;
            param_129 = _e419;
            let _e420 = avgAlpha;
            param_130 = _e420;
            let _e421 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_128), (&param_129), (&param_130));
            G_1 = _e421;
            let _e423 = (*fd_3).refraction;
            if _e423 {
                let _e424 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e424);
            } else {
                let _e426 = F;
                let _e427 = G_1;
                local_8 = (_e426 * _e427);
            }
            let _e429 = local_8;
            FG = _e429;
            let _e430 = sampleColor;
            let _e431 = FG;
            let _e433 = radiance;
            radiance = (_e433 + (_e430 * _e431));
            continue;
        } else {
            break;
        }
        continuing {
            let _e435 = i_2;
            i_2 = (_e435 + 1i);
        }
    }
    let _e437 = G1V_1;
    let _e438 = envRadianceSamples;
    let _e441 = radiance;
    radiance = (_e441 / vec3((_e437 * f32(_e438))));
    let _e444 = radiance;
    let _e447 = unnamed.skyPower;
    return (select(_e444, vec3<f32>(0f, 0f, 0f), false) * _e447);
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
        let _e281 = (*tint);
        param_131 = _e281;
        let _e282 = mx_square_u0028_vf3_u003b((&param_131));
        (*tint) = _e282;
    }
    let _e283 = (*N_5);
    param_132 = _e283;
    let _e284 = (*V_5);
    param_133 = _e284;
    let _e285 = (*X_1);
    param_134 = _e285;
    let _e286 = (*alpha_7);
    param_135 = _e286;
    let _e287 = (*distribution_1);
    param_136 = _e287;
    let _e288 = (*fd_4);
    param_137 = _e288;
    let _e289 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_132), (&param_133), (&param_134), (&param_135), (&param_136), (&param_137));
    let _e290 = (*tint);
    return (_e289 * _e290);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_1: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e268 = (*F0_1);
    sqrtF0_1 = sqrt(clamp(_e268, 0.01f, 0.99f));
    let _e271 = sqrtF0_1;
    let _e273 = sqrtF0_1;
    return ((1f + _e271) / (1f - _e273));
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

    let _e278 = (*NdotV_8);
    x_5 = _e278;
    let _e279 = (*alpha_8);
    y_1 = _e279;
    let _e280 = x_5;
    param_138 = _e280;
    let _e281 = mx_square_u0028_f1_u003b((&param_138));
    x2_1 = _e281;
    let _e282 = y_1;
    param_139 = _e282;
    let _e283 = mx_square_u0028_f1_u003b((&param_139));
    y2_ = _e283;
    let _e284 = x_5;
    let _e287 = y_1;
    let _e290 = x_5;
    let _e292 = y_1;
    let _e295 = x2_1;
    let _e298 = y2_;
    let _e301 = x2_1;
    let _e303 = y_1;
    let _e306 = x_5;
    let _e308 = y2_;
    let _e311 = x2_1;
    let _e313 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e284)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e287)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e290) * _e292)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e295)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e298)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e301) * _e303)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e306) * _e308)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e311) * _e313));
    let _e316 = r_1;
    let _e318 = r_1;
    AB = clamp((_e316.xy / _e318.zw), vec2(0f), vec2(1f));
    let _e324 = (*F0_2);
    let _e326 = AB[0u];
    let _e328 = (*F90_);
    let _e330 = AB[1u];
    return ((_e324 * _e326) + (_e328 * _e330));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_140: f32;
    var param_141: f32;
    var param_142: vec3<f32>;
    var param_143: vec3<f32>;

    let _e274 = (*NdotV_9);
    param_140 = _e274;
    let _e275 = (*alpha_9);
    param_141 = _e275;
    let _e276 = (*F0_3);
    param_142 = _e276;
    let _e277 = (*F90_1);
    param_143 = _e277;
    let _e278 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_140), (&param_141), (&param_142), (&param_143));
    return _e278;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_10: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_4: ptr<function, f32>, F90_2: ptr<function, f32>) -> f32 {
    var param_144: f32;
    var param_145: f32;
    var param_146: vec3<f32>;
    var param_147: vec3<f32>;

    let _e274 = (*F0_4);
    let _e276 = (*F90_2);
    let _e278 = (*NdotV_10);
    param_144 = _e278;
    let _e279 = (*alpha_10);
    param_145 = _e279;
    param_146 = vec3(_e274);
    param_147 = vec3(_e276);
    let _e280 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_144), (&param_145), (&param_146), (&param_147));
    return _e280.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_148: f32;
    var param_149: FresnelData;
    var F90_3: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_2872_: bool;

    param_148 = 1f;
    let _e272 = (*fd_5);
    param_149 = _e272;
    let _e273 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_148), (&param_149));
    F0_5 = _e273;
    let _e275 = (*fd_5).model;
    let _e276 = (_e275 == 2i);
    phi_2872_ = _e276;
    if _e276 {
        let _e278 = (*fd_5).airy;
        phi_2872_ = !(_e278);
    }
    let _e281 = phi_2872_;
    if _e281 {
        let _e283 = (*fd_5).F90_;
        local_9 = _e283;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e284 = local_9;
    F90_3 = _e284;
    let _e285 = F0_5;
    let _e286 = F90_3;
    let _e287 = F0_5;
    return (_e285 + ((_e286 - _e287) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_11: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_150: FresnelData;
    var Ess: f32;
    var param_151: f32;
    var param_152: f32;
    var param_153: f32;
    var param_154: f32;

    let _e276 = (*fd_6);
    param_150 = _e276;
    let _e277 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_150));
    Fss = _e277;
    let _e278 = (*NdotV_11);
    param_151 = _e278;
    let _e279 = (*alpha_11);
    param_152 = _e279;
    param_153 = 1f;
    param_154 = 1f;
    let _e280 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_151), (&param_152), (&param_153), (&param_154));
    Ess = _e280;
    let _e281 = Fss;
    let _e282 = Ess;
    let _e285 = Ess;
    return (vec3(1f) + ((_e281 * (1f - _e282)) / vec3(_e285)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_6: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_4: ptr<function, vec3<f32>>, exponent: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e274 = (*tf_thickness);
    fd_7.airy = (_e274 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e279 = (*F0_6);
    fd_7.F0_ = _e279;
    let _e281 = (*F82_);
    fd_7.F82_ = _e281;
    let _e283 = (*F90_4);
    fd_7.F90_ = _e283;
    let _e285 = (*exponent);
    fd_7.exponent = _e285;
    let _e287 = (*tf_thickness);
    fd_7.tf_thickness = _e287;
    let _e289 = (*tf_ior);
    fd_7.tf_ior = _e289;
    fd_7.refraction = false;
    let _e292 = fd_7;
    return _e292;
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
    var phi_4544_: bool;

    let _e360 = (*weight_2);
    if (_e360 < 0.00000001f) {
        return;
    }
    let _e363 = (*closureData_5).closureType;
    let _e365 = (*scatter_mode);
    if ((_e363 != 2i) && (_e365 == 1i)) {
        return;
    }
    let _e369 = (*closureData_5).V;
    V_6 = _e369;
    let _e371 = (*closureData_5).L;
    L_2 = _e371;
    let _e372 = (*retroreflective);
    phi_4544_ = _e372;
    if _e372 {
        let _e374 = (*closureData_5).closureType;
        phi_4544_ = (_e374 != 2i);
    }
    let _e377 = phi_4544_;
    if _e377 {
        let _e378 = V_6;
        let _e380 = (*N_6);
        V_6 = reflect(-(_e378), _e380);
    }
    let _e382 = (*N_6);
    param_155 = _e382;
    let _e383 = V_6;
    param_156 = _e383;
    let _e384 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_155), (&param_156));
    (*N_6) = _e384;
    let _e385 = (*N_6);
    let _e386 = V_6;
    NdotV_12 = clamp(dot(_e385, _e386), 0.00000001f, 1f);
    let _e389 = (*color0_);
    safeColor0_ = max(_e389, vec3(0f));
    let _e392 = (*color82_);
    safeColor82_ = max(_e392, vec3(0f));
    let _e395 = (*color90_);
    safeColor90_ = max(_e395, vec3(0f));
    let _e398 = safeColor0_;
    param_157 = _e398;
    let _e399 = safeColor82_;
    param_158 = _e399;
    let _e400 = safeColor90_;
    param_159 = _e400;
    let _e401 = (*exponent_1);
    param_160 = _e401;
    let _e402 = (*thinfilm_thickness);
    param_161 = _e402;
    let _e403 = (*thinfilm_ior);
    param_162 = _e403;
    let _e404 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_157), (&param_158), (&param_159), (&param_160), (&param_161), (&param_162));
    fd_8 = _e404;
    let _e405 = (*roughness_8);
    safeAlpha = clamp(_e405, vec2(0.00000001f), vec2(1f));
    let _e409 = safeAlpha;
    param_163 = _e409;
    let _e410 = mx_average_alpha_u0028_vf2_u003b((&param_163));
    avgAlpha_1 = _e410;
    let _e412 = (*closureData_5).closureType;
    if (_e412 == 1i) {
        let _e414 = (*X_2);
        let _e415 = (*X_2);
        let _e416 = (*N_6);
        let _e418 = (*N_6);
        (*X_2) = normalize((_e414 - (_e418 * dot(_e415, _e416))));
        let _e422 = (*N_6);
        let _e423 = (*X_2);
        Y_1 = cross(_e422, _e423);
        let _e425 = L_2;
        let _e426 = V_6;
        H_4 = normalize((_e425 + _e426));
        let _e429 = (*N_6);
        let _e430 = L_2;
        NdotL_5 = clamp(dot(_e429, _e430), 0.00000001f, 1f);
        let _e433 = V_6;
        let _e434 = H_4;
        VdotH_1 = clamp(dot(_e433, _e434), 0.00000001f, 1f);
        let _e437 = H_4;
        let _e438 = (*X_2);
        let _e440 = H_4;
        let _e441 = Y_1;
        let _e443 = H_4;
        let _e444 = (*N_6);
        Ht = vec3<f32>(dot(_e437, _e438), dot(_e440, _e441), dot(_e443, _e444));
        let _e447 = VdotH_1;
        param_164 = _e447;
        let _e448 = fd_8;
        param_165 = _e448;
        let _e449 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_164), (&param_165));
        F_1 = _e449;
        let _e450 = Ht;
        param_166 = _e450;
        let _e451 = safeAlpha;
        param_167 = _e451;
        let _e452 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_166), (&param_167));
        D = _e452;
        let _e453 = NdotL_5;
        param_168 = _e453;
        let _e454 = NdotV_12;
        param_169 = _e454;
        let _e455 = avgAlpha_1;
        param_170 = _e455;
        let _e456 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_168), (&param_169), (&param_170));
        G_2 = _e456;
        let _e457 = NdotV_12;
        param_171 = _e457;
        let _e458 = avgAlpha_1;
        param_172 = _e458;
        let _e459 = fd_8;
        param_173 = _e459;
        let _e460 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_171), (&param_172), (&param_173));
        comp = _e460;
        let _e461 = NdotV_12;
        param_174 = _e461;
        let _e462 = avgAlpha_1;
        param_175 = _e462;
        let _e463 = safeColor0_;
        param_176 = _e463;
        let _e464 = safeColor90_;
        param_177 = _e464;
        let _e465 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_174), (&param_175), (&param_176), (&param_177));
        let _e466 = comp;
        dirAlbedo_2 = (_e465 * _e466);
        let _e468 = dirAlbedo_2;
        avgDirAlbedo = dot(_e468, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e470 = avgDirAlbedo;
        let _e471 = (*weight_2);
        (*bsdf_1).throughput = vec3((1f - (_e470 * _e471)));
        let _e476 = D;
        let _e477 = F_1;
        let _e479 = G_2;
        let _e481 = comp;
        let _e484 = (*closureData_5).occlusion;
        let _e486 = (*weight_2);
        let _e488 = NdotV_12;
        (*bsdf_1).response = ((((((_e477 * _e476) * _e479) * _e481) * _e484) * _e486) / vec3((4f * _e488)));
    } else {
        let _e494 = (*closureData_5).closureType;
        if (_e494 == 2i) {
            let _e496 = NdotV_12;
            param_178 = _e496;
            let _e497 = avgAlpha_1;
            param_179 = _e497;
            let _e498 = fd_8;
            param_180 = _e498;
            let _e499 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_178), (&param_179), (&param_180));
            comp_1 = _e499;
            let _e500 = NdotV_12;
            param_181 = _e500;
            let _e501 = avgAlpha_1;
            param_182 = _e501;
            let _e502 = safeColor0_;
            param_183 = _e502;
            let _e503 = safeColor90_;
            param_184 = _e503;
            let _e504 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_181), (&param_182), (&param_183), (&param_184));
            let _e505 = comp_1;
            dirAlbedo_3 = (_e504 * _e505);
            let _e507 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e507, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e509 = avgDirAlbedo_1;
            let _e510 = (*weight_2);
            (*bsdf_1).throughput = vec3((1f - (_e509 * _e510)));
            let _e515 = (*scatter_mode);
            if (_e515 != 0i) {
                let _e517 = safeColor0_;
                avgF0_ = dot(_e517, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e519 = avgF0_;
                param_185 = _e519;
                let _e520 = mx_f0_to_ior_u0028_f1_u003b((&param_185));
                fd_8.ior = vec3(_e520);
                let _e523 = (*N_6);
                param_186 = _e523;
                let _e524 = V_6;
                param_187 = _e524;
                let _e525 = (*X_2);
                param_188 = _e525;
                let _e526 = safeAlpha;
                param_189 = _e526;
                let _e527 = (*distribution_2);
                param_190 = _e527;
                let _e528 = fd_8;
                param_191 = _e528;
                param_192 = vec3<f32>(1f, 1f, 1f);
                let _e529 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_186), (&param_187), (&param_188), (&param_189), (&param_190), (&param_191), (&param_192));
                let _e530 = (*weight_2);
                (*bsdf_1).response = (_e529 * _e530);
            }
        } else {
            let _e534 = (*closureData_5).closureType;
            if (_e534 == 3i) {
                let _e536 = NdotV_12;
                param_193 = _e536;
                let _e537 = avgAlpha_1;
                param_194 = _e537;
                let _e538 = fd_8;
                param_195 = _e538;
                let _e539 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_193), (&param_194), (&param_195));
                comp_2 = _e539;
                let _e540 = NdotV_12;
                param_196 = _e540;
                let _e541 = avgAlpha_1;
                param_197 = _e541;
                let _e542 = safeColor0_;
                param_198 = _e542;
                let _e543 = safeColor90_;
                param_199 = _e543;
                let _e544 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_196), (&param_197), (&param_198), (&param_199));
                let _e545 = comp_2;
                dirAlbedo_4 = (_e544 * _e545);
                let _e547 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e547, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e549 = avgDirAlbedo_2;
                let _e550 = (*weight_2);
                (*bsdf_1).throughput = vec3((1f - (_e549 * _e550)));
                let _e555 = (*N_6);
                param_200 = _e555;
                let _e556 = V_6;
                param_201 = _e556;
                let _e557 = (*X_2);
                param_202 = _e557;
                let _e558 = safeAlpha;
                param_203 = _e558;
                let _e559 = (*distribution_2);
                param_204 = _e559;
                let _e560 = fd_8;
                param_205 = _e560;
                let _e561 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_200), (&param_201), (&param_202), (&param_203), (&param_204), (&param_205));
                Li_2 = _e561;
                let _e562 = Li_2;
                let _e563 = comp_2;
                let _e565 = (*weight_2);
                (*bsdf_1).response = ((_e562 * _e563) * _e565);
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

    let _e272 = (*y_2);
    let _e273 = (*y_2);
    let _e277 = (*y_2);
    let _e278 = (*y_2);
    s_3 = ((_e272 * (0.0206607f + (1.58491f * _e273))) / (0.0379424f + (_e277 * (1.32227f + _e278))));
    let _e283 = (*y_2);
    let _e284 = (*y_2);
    let _e285 = (*y_2);
    let _e286 = (*y_2);
    let _e288 = (*y_2);
    let _e296 = (*y_2);
    m_4 = ((_e283 * (-0.193854f + (_e284 * (-1.14885f + (_e285 * (1.7932f - ((0.95943f * _e286) * _e288))))))) / (0.046391f + _e296));
    let _e299 = (*y_2);
    let _e300 = (*y_2);
    let _e303 = (*y_2);
    let _e307 = (*y_2);
    let _e308 = (*y_2);
    o = ((_e299 * (0.000654023f + ((-0.0207818f + (0.119681f * _e300)) * _e303))) / (1.26264f + (_e307 * (-1.92021f + _e308))));
    let _e313 = (*x_6);
    let _e314 = m_4;
    let _e316 = s_3;
    param_206 = ((_e313 - _e314) / _e316);
    let _e318 = mx_square_u0028_f1_u003b((&param_206));
    let _e321 = s_3;
    let _e324 = o;
    return ((exp((-0.5f * _e318)) / (_e321 * 2.5066283f)) + _e324);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_11: ptr<function, f32>) -> f32 {
    let _e267 = (*cosTheta_11);
    return (max(_e267, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_7: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e268 = (*x_7);
    let _e271 = (*y_3);
    let _e274 = (*y_3);
    let _e276 = (*y_3);
    let _e278 = (*y_3);
    let _e280 = (*x_7);
    let _e283 = (*x_7);
    let _e285 = (*y_3);
    let _e288 = (*y_3);
    let _e290 = (*y_3);
    return (((((sqrt((1f - _e268)) * (_e271 - 1f)) * _e274) * _e276) * _e278) / (((0.0000254053f + (1.71228f * _e280)) - ((1.71506f * _e283) * _e285)) + ((1.34174f * _e288) * _e290)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e268 = (*x_8);
    let _e270 = (*y_4);
    let _e273 = (*y_4);
    let _e275 = (*x_8);
    let _e277 = (*x_8);
    let _e280 = (*x_8);
    let _e282 = (*y_4);
    return ((((2.58126f * _e268) + (0.813703f * _e270)) * _e273) / ((1f + ((0.310327f * _e275) * _e277)) + ((2.60994f * _e280) * _e282)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_7: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_3: vec3<f32>;
    var Y_2: vec3<f32>;

    let _e273 = (*N_7)[2u];
    sign_ = select(1f, -1f, (_e273 < 0f));
    let _e276 = sign_;
    let _e278 = (*N_7)[2u];
    a_3 = (-1f / (_e276 + _e278));
    let _e282 = (*N_7)[0u];
    let _e284 = (*N_7)[1u];
    let _e286 = a_3;
    b = ((_e282 * _e284) * _e286);
    let _e288 = sign_;
    let _e290 = (*N_7)[0u];
    let _e293 = (*N_7)[0u];
    let _e295 = a_3;
    let _e298 = sign_;
    let _e299 = b;
    let _e301 = sign_;
    let _e304 = (*N_7)[0u];
    X_3 = vec3<f32>((1f + (((_e288 * _e290) * _e293) * _e295)), (_e298 * _e299), (-(_e301) * _e304));
    let _e307 = b;
    let _e308 = sign_;
    let _e310 = (*N_7)[1u];
    let _e312 = (*N_7)[1u];
    let _e314 = a_3;
    let _e318 = (*N_7)[1u];
    Y_2 = vec3<f32>(_e307, (_e308 + ((_e310 * _e312) * _e314)), -(_e318));
    let _e321 = X_3;
    let _e322 = Y_2;
    let _e323 = (*N_7);
    return mat3x3<f32>(vec3<f32>(_e321.x, _e321.y, _e321.z), vec3<f32>(_e322.x, _e322.y, _e322.z), vec3<f32>(_e323.x, _e323.y, _e323.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_7: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, NdotV_13: ptr<function, f32>) -> mat3x3<f32> {
    var X_4: vec3<f32>;
    var lenSqr: f32;
    var Y_3: vec3<f32>;
    var param_207: vec3<f32>;

    let _e273 = (*V_7);
    let _e274 = (*N_8);
    let _e275 = (*NdotV_13);
    X_4 = (_e273 - (_e274 * _e275));
    let _e278 = X_4;
    let _e279 = X_4;
    lenSqr = dot(_e278, _e279);
    let _e281 = lenSqr;
    if (_e281 > 0f) {
        let _e283 = lenSqr;
        let _e285 = X_4;
        X_4 = (_e285 * inverseSqrt(_e283));
        let _e287 = (*N_8);
        let _e288 = X_4;
        Y_3 = cross(_e287, _e288);
        let _e290 = X_4;
        let _e291 = Y_3;
        let _e292 = (*N_8);
        return mat3x3<f32>(vec3<f32>(_e290.x, _e290.y, _e290.z), vec3<f32>(_e291.x, _e291.y, _e291.z), vec3<f32>(_e292.x, _e292.y, _e292.z));
    }
    let _e306 = (*N_8);
    param_207 = _e306;
    let _e307 = mx_orthonormal_basis_u0028_vf3_u003b((&param_207));
    return _e307;
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

    let _e288 = (*V_8);
    param_208 = _e288;
    let _e289 = (*N_9);
    param_209 = _e289;
    let _e290 = (*NdotV_14);
    param_210 = _e290;
    let _e291 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_208), (&param_209), (&param_210));
    toLTC = transpose(_e291);
    let _e293 = toLTC;
    param_211 = _e293;
    let _e294 = (*L_3);
    param_212 = _e294;
    let _e295 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_211), (&param_212));
    w = _e295;
    let _e296 = (*NdotV_14);
    param_213 = _e296;
    let _e297 = (*roughness_9);
    param_214 = _e297;
    let _e298 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_213), (&param_214));
    aInv = _e298;
    let _e299 = (*NdotV_14);
    param_215 = _e299;
    let _e300 = (*roughness_9);
    param_216 = _e300;
    let _e301 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_215), (&param_216));
    bInv = _e301;
    let _e302 = aInv;
    let _e304 = w[0u];
    let _e306 = bInv;
    let _e308 = w[2u];
    let _e311 = aInv;
    let _e313 = w[1u];
    let _e316 = w[2u];
    wo = vec3<f32>(((_e302 * _e304) + (_e306 * _e308)), (_e311 * _e313), _e316);
    let _e318 = wo;
    let _e319 = wo;
    lenSqr_1 = dot(_e318, _e319);
    let _e322 = wo[2u];
    param_217 = _e322;
    let _e323 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_217));
    let _e324 = aInv;
    let _e325 = lenSqr_1;
    param_218 = (_e324 / _e325);
    let _e327 = mx_square_u0028_f1_u003b((&param_218));
    return (_e323 * _e327);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_15: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_219: f32;
    var param_220: f32;

    let _e271 = (*NdotV_15);
    let _e274 = (*roughness_10);
    let _e277 = (*NdotV_15);
    let _e279 = (*roughness_10);
    let _e282 = (*NdotV_15);
    param_219 = _e282;
    let _e283 = mx_square_u0028_f1_u003b((&param_219));
    let _e286 = (*roughness_10);
    param_220 = _e286;
    let _e287 = mx_square_u0028_f1_u003b((&param_220));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e271)) + (vec2<f32>(799.08826f, 442.7821f) * _e274)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e277) * _e279)) + (vec2<f32>(60.28956f, 121.81241f) * _e283)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e287));
    let _e291 = r_2[0u];
    let _e293 = r_2[1u];
    return (_e291 / _e293);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_16: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var dirAlbedo_5: f32;
    var param_221: f32;
    var param_222: f32;

    let _e271 = (*NdotV_16);
    param_221 = _e271;
    let _e272 = (*roughness_11);
    param_222 = _e272;
    let _e273 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_221), (&param_222));
    dirAlbedo_5 = _e273;
    let _e274 = dirAlbedo_5;
    return clamp(_e274, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e271 = (*roughness_12);
    invRoughness = (1f / max(_e271, 0.005f));
    let _e274 = (*NdotH);
    let _e275 = (*NdotH);
    cos2_ = (_e274 * _e275);
    let _e277 = cos2_;
    sin2_ = (1f - _e277);
    let _e279 = invRoughness;
    let _e281 = sin2_;
    let _e282 = invRoughness;
    return (((2f + _e279) * pow(_e281, (_e282 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_6: ptr<function, f32>, NdotV_17: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var D_1: f32;
    var param_223: f32;
    var param_224: f32;
    var F_2: f32;
    var G_3: f32;

    let _e275 = (*NdotH_1);
    param_223 = _e275;
    let _e276 = (*roughness_13);
    param_224 = _e276;
    let _e277 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_223), (&param_224));
    D_1 = _e277;
    F_2 = 1f;
    G_3 = 1f;
    let _e278 = D_1;
    let _e279 = F_2;
    let _e281 = G_3;
    let _e283 = (*NdotL_6);
    let _e284 = (*NdotV_17);
    let _e286 = (*NdotL_6);
    let _e287 = (*NdotV_17);
    return (((_e278 * _e279) * _e281) / (4f * ((_e283 + _e284) - (_e286 * _e287))));
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

    let _e304 = (*weight_3);
    if (_e304 < 0.00000001f) {
        return;
    }
    let _e307 = (*closureData_6).V;
    V_9 = _e307;
    let _e309 = (*closureData_6).L;
    L_4 = _e309;
    let _e310 = (*N_10);
    param_225 = _e310;
    let _e311 = V_9;
    param_226 = _e311;
    let _e312 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_225), (&param_226));
    (*N_10) = _e312;
    let _e313 = (*N_10);
    let _e314 = V_9;
    NdotV_18 = clamp(dot(_e313, _e314), 0.00000001f, 1f);
    let _e318 = (*closureData_6).closureType;
    if (_e318 == 1i) {
        let _e320 = (*mode);
        if (_e320 == 0i) {
            let _e322 = L_4;
            let _e323 = V_9;
            H_5 = normalize((_e322 + _e323));
            let _e326 = (*N_10);
            let _e327 = L_4;
            NdotL_7 = clamp(dot(_e326, _e327), 0.00000001f, 1f);
            let _e330 = (*N_10);
            let _e331 = H_5;
            NdotH_2 = clamp(dot(_e330, _e331), 0.00000001f, 1f);
            let _e334 = (*color_4);
            let _e335 = NdotL_7;
            param_227 = _e335;
            let _e336 = NdotV_18;
            param_228 = _e336;
            let _e337 = NdotH_2;
            param_229 = _e337;
            let _e338 = (*roughness_14);
            param_230 = _e338;
            let _e339 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_227), (&param_228), (&param_229), (&param_230));
            fr = (_e334 * _e339);
            let _e341 = NdotV_18;
            param_231 = _e341;
            let _e342 = (*roughness_14);
            param_232 = _e342;
            let _e343 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_231), (&param_232));
            dirAlbedo_6 = _e343;
            let _e344 = fr;
            let _e345 = NdotL_7;
            let _e348 = (*closureData_6).occlusion;
            let _e350 = (*weight_3);
            (*bsdf_2).response = (((_e344 * _e345) * _e348) * _e350);
        } else {
            let _e353 = (*roughness_14);
            (*roughness_14) = clamp(_e353, 0.01f, 1f);
            let _e355 = (*color_4);
            let _e356 = L_4;
            param_233 = _e356;
            let _e357 = V_9;
            param_234 = _e357;
            let _e358 = (*N_10);
            param_235 = _e358;
            let _e359 = NdotV_18;
            param_236 = _e359;
            let _e360 = (*roughness_14);
            param_237 = _e360;
            let _e361 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_233), (&param_234), (&param_235), (&param_236), (&param_237));
            fr_1 = (_e355 * _e361);
            let _e363 = NdotV_18;
            param_238 = _e363;
            let _e364 = (*roughness_14);
            param_239 = _e364;
            let _e365 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_238), (&param_239));
            dirAlbedo_6 = _e365;
            let _e366 = dirAlbedo_6;
            let _e367 = fr_1;
            let _e370 = (*closureData_6).occlusion;
            let _e372 = (*weight_3);
            (*bsdf_2).response = (((_e367 * _e366) * _e370) * _e372);
        }
        let _e375 = dirAlbedo_6;
        let _e376 = (*weight_3);
        (*bsdf_2).throughput = vec3((1f - (_e375 * _e376)));
    } else {
        let _e382 = (*closureData_6).closureType;
        if (_e382 == 3i) {
            let _e384 = (*mode);
            if (_e384 == 0i) {
                let _e386 = NdotV_18;
                param_240 = _e386;
                let _e387 = (*roughness_14);
                param_241 = _e387;
                let _e388 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_240), (&param_241));
                dirAlbedo_7 = _e388;
            } else {
                let _e389 = (*roughness_14);
                (*roughness_14) = clamp(_e389, 0.01f, 1f);
                let _e391 = NdotV_18;
                param_242 = _e391;
                let _e392 = (*roughness_14);
                param_243 = _e392;
                let _e393 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_242), (&param_243));
                dirAlbedo_7 = _e393;
            }
            let _e394 = (*N_10);
            param_244 = _e394;
            let _e395 = mx_environment_irradiance_u0028_vf3_u003b((&param_244));
            Li_3 = _e395;
            let _e396 = Li_3;
            let _e397 = (*color_4);
            let _e399 = dirAlbedo_7;
            let _e401 = (*weight_3);
            (*bsdf_2).response = (((_e396 * _e397) * _e399) * _e401);
            let _e404 = dirAlbedo_7;
            let _e405 = (*weight_3);
            (*bsdf_2).throughput = vec3((1f - (_e404 * _e405)));
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_245: f32;

    let _e268 = (*ior_3);
    let _e270 = (*ior_3);
    param_245 = ((_e268 - 1f) / (_e270 + 1f));
    let _e273 = mx_square_u0028_f1_u003b((&param_245));
    return _e273;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e271 = (*tf_thickness_1);
    fd_9.airy = (_e271 > 0f);
    let _e274 = (*ior_4);
    fd_9.ior = vec3(_e274);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e282 = (*tf_thickness_1);
    fd_9.tf_thickness = _e282;
    let _e284 = (*tf_ior_1);
    fd_9.tf_ior = _e284;
    fd_9.refraction = false;
    let _e287 = fd_9;
    return _e287;
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
    var phi_3361_: bool;

    let _e350 = (*weight_4);
    if (_e350 < 0.00000001f) {
        return;
    }
    let _e353 = (*closureData_7).closureType;
    let _e355 = (*scatter_mode_1);
    if ((_e353 != 2i) && (_e355 == 1i)) {
        return;
    }
    let _e359 = (*closureData_7).V;
    V_10 = _e359;
    let _e361 = (*closureData_7).L;
    L_5 = _e361;
    let _e362 = (*retroreflective_1);
    phi_3361_ = _e362;
    if _e362 {
        let _e364 = (*closureData_7).closureType;
        phi_3361_ = (_e364 != 2i);
    }
    let _e367 = phi_3361_;
    if _e367 {
        let _e368 = V_10;
        let _e370 = (*N_11);
        V_10 = reflect(-(_e368), _e370);
    }
    let _e372 = (*N_11);
    param_246 = _e372;
    let _e373 = V_10;
    param_247 = _e373;
    let _e374 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_246), (&param_247));
    (*N_11) = _e374;
    let _e375 = (*N_11);
    let _e376 = V_10;
    NdotV_19 = clamp(dot(_e375, _e376), 0.00000001f, 1f);
    let _e379 = (*ior_5);
    param_248 = _e379;
    let _e380 = (*thinfilm_thickness_1);
    param_249 = _e380;
    let _e381 = (*thinfilm_ior_1);
    param_250 = _e381;
    let _e382 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_248), (&param_249), (&param_250));
    fd_10 = _e382;
    let _e383 = (*ior_5);
    param_251 = _e383;
    let _e384 = mx_ior_to_f0_u0028_f1_u003b((&param_251));
    F0_7 = _e384;
    let _e385 = (*roughness_15);
    safeAlpha_1 = clamp(_e385, vec2(0.00000001f), vec2(1f));
    let _e389 = safeAlpha_1;
    param_252 = _e389;
    let _e390 = mx_average_alpha_u0028_vf2_u003b((&param_252));
    avgAlpha_2 = _e390;
    let _e391 = (*tint_1);
    safeTint = max(_e391, vec3(0f));
    let _e395 = (*closureData_7).closureType;
    if (_e395 == 1i) {
        let _e397 = (*X_5);
        let _e398 = (*X_5);
        let _e399 = (*N_11);
        let _e401 = (*N_11);
        (*X_5) = normalize((_e397 - (_e401 * dot(_e398, _e399))));
        let _e405 = (*N_11);
        let _e406 = (*X_5);
        Y_4 = cross(_e405, _e406);
        let _e408 = L_5;
        let _e409 = V_10;
        H_6 = normalize((_e408 + _e409));
        let _e412 = (*N_11);
        let _e413 = L_5;
        NdotL_8 = clamp(dot(_e412, _e413), 0.00000001f, 1f);
        let _e416 = V_10;
        let _e417 = H_6;
        VdotH_2 = clamp(dot(_e416, _e417), 0.00000001f, 1f);
        let _e420 = H_6;
        let _e421 = (*X_5);
        let _e423 = H_6;
        let _e424 = Y_4;
        let _e426 = H_6;
        let _e427 = (*N_11);
        Ht_1 = vec3<f32>(dot(_e420, _e421), dot(_e423, _e424), dot(_e426, _e427));
        let _e430 = VdotH_2;
        param_253 = _e430;
        let _e431 = fd_10;
        param_254 = _e431;
        let _e432 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_253), (&param_254));
        F_3 = _e432;
        let _e433 = Ht_1;
        param_255 = _e433;
        let _e434 = safeAlpha_1;
        param_256 = _e434;
        let _e435 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_255), (&param_256));
        D_2 = _e435;
        let _e436 = NdotL_8;
        param_257 = _e436;
        let _e437 = NdotV_19;
        param_258 = _e437;
        let _e438 = avgAlpha_2;
        param_259 = _e438;
        let _e439 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_257), (&param_258), (&param_259));
        G_4 = _e439;
        let _e440 = NdotV_19;
        param_260 = _e440;
        let _e441 = avgAlpha_2;
        param_261 = _e441;
        let _e442 = fd_10;
        param_262 = _e442;
        let _e443 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_260), (&param_261), (&param_262));
        comp_3 = _e443;
        let _e444 = NdotV_19;
        param_263 = _e444;
        let _e445 = avgAlpha_2;
        param_264 = _e445;
        let _e446 = F0_7;
        param_265 = _e446;
        param_266 = 1f;
        let _e447 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_263), (&param_264), (&param_265), (&param_266));
        let _e448 = comp_3;
        dirAlbedo_8 = (_e448 * _e447);
        let _e450 = dirAlbedo_8;
        let _e451 = (*weight_4);
        (*bsdf_3).throughput = (vec3(1f) - (_e450 * _e451));
        let _e456 = D_2;
        let _e457 = F_3;
        let _e459 = G_4;
        let _e461 = comp_3;
        let _e463 = safeTint;
        let _e466 = (*closureData_7).occlusion;
        let _e468 = (*weight_4);
        let _e470 = NdotV_19;
        (*bsdf_3).response = (((((((_e457 * _e456) * _e459) * _e461) * _e463) * _e466) * _e468) / vec3((4f * _e470)));
    } else {
        let _e476 = (*closureData_7).closureType;
        if (_e476 == 2i) {
            let _e478 = NdotV_19;
            param_267 = _e478;
            let _e479 = avgAlpha_2;
            param_268 = _e479;
            let _e480 = fd_10;
            param_269 = _e480;
            let _e481 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_267), (&param_268), (&param_269));
            comp_4 = _e481;
            let _e482 = NdotV_19;
            param_270 = _e482;
            let _e483 = avgAlpha_2;
            param_271 = _e483;
            let _e484 = F0_7;
            param_272 = _e484;
            param_273 = 1f;
            let _e485 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_270), (&param_271), (&param_272), (&param_273));
            let _e486 = comp_4;
            dirAlbedo_9 = (_e486 * _e485);
            let _e488 = dirAlbedo_9;
            let _e489 = (*weight_4);
            (*bsdf_3).throughput = (vec3(1f) - (_e488 * _e489));
            let _e494 = (*scatter_mode_1);
            if (_e494 != 0i) {
                let _e496 = (*N_11);
                param_274 = _e496;
                let _e497 = V_10;
                param_275 = _e497;
                let _e498 = (*X_5);
                param_276 = _e498;
                let _e499 = safeAlpha_1;
                param_277 = _e499;
                let _e500 = (*distribution_3);
                param_278 = _e500;
                let _e501 = fd_10;
                param_279 = _e501;
                let _e502 = safeTint;
                param_280 = _e502;
                let _e503 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_274), (&param_275), (&param_276), (&param_277), (&param_278), (&param_279), (&param_280));
                let _e504 = (*weight_4);
                (*bsdf_3).response = (_e503 * _e504);
            }
        } else {
            let _e508 = (*closureData_7).closureType;
            if (_e508 == 3i) {
                let _e510 = NdotV_19;
                param_281 = _e510;
                let _e511 = avgAlpha_2;
                param_282 = _e511;
                let _e512 = fd_10;
                param_283 = _e512;
                let _e513 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_281), (&param_282), (&param_283));
                comp_5 = _e513;
                let _e514 = NdotV_19;
                param_284 = _e514;
                let _e515 = avgAlpha_2;
                param_285 = _e515;
                let _e516 = F0_7;
                param_286 = _e516;
                param_287 = 1f;
                let _e517 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_284), (&param_285), (&param_286), (&param_287));
                let _e518 = comp_5;
                dirAlbedo_10 = (_e518 * _e517);
                let _e520 = dirAlbedo_10;
                let _e521 = (*weight_4);
                (*bsdf_3).throughput = (vec3(1f) - (_e520 * _e521));
                let _e526 = (*N_11);
                param_288 = _e526;
                let _e527 = V_10;
                param_289 = _e527;
                let _e528 = (*X_5);
                param_290 = _e528;
                let _e529 = safeAlpha_1;
                param_291 = _e529;
                let _e530 = (*distribution_3);
                param_292 = _e530;
                let _e531 = fd_10;
                param_293 = _e531;
                let _e532 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_288), (&param_289), (&param_290), (&param_291), (&param_292), (&param_293));
                Li_4 = _e532;
                let _e533 = Li_4;
                let _e534 = safeTint;
                let _e536 = comp_5;
                let _e538 = (*weight_4);
                (*bsdf_3).response = (((_e533 * _e534) * _e536) * _e538);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_6: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, occlusion: ptr<function, f32>) -> ClosureData {
    let _e272 = (*closureType);
    let _e273 = (*L_6);
    let _e274 = (*V_11);
    let _e275 = (*N_12);
    let _e276 = (*P);
    let _e277 = (*occlusion);
    return ClosureData(_e272, _e273, _e274, _e275, _e276, _e277);
}

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_4: ptr<function, lightshader>) {
    (*result_4).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_4).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e267 = unnamed.mtlxLightCount;
    return min(_e267, 1i);
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_5: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e274 = (*axis);
    (*axis) = normalize(_e274);
    let _e276 = (*amount);
    rotationRadians = radians(_e276);
    let _e278 = rotationRadians;
    s_4 = sin(_e278);
    let _e280 = rotationRadians;
    c_3 = cos(_e280);
    let _e282 = c_3;
    oc = (1f - _e282);
    let _e284 = (*_in);
    let _e285 = c_3;
    let _e287 = (*_in);
    let _e288 = (*axis);
    let _e290 = s_4;
    let _e293 = (*axis);
    let _e294 = (*axis);
    let _e295 = (*_in);
    let _e298 = oc;
    (*result_5) = (((_e284 * _e285) + (cross(_e287, _e288) * _e290)) + ((_e293 * dot(_e294, _e295)) * _e298));
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_2: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e274 = (*in1_2)[0u];
    N_extract_0_out = _e274;
    let _e276 = (*in1_2)[1u];
    N_extract_1_out = _e276;
    let _e278 = (*in1_2)[2u];
    N_extract_2_out = _e278;
    let _e279 = N_extract_0_out;
    (*outr) = _e279;
    let _e280 = N_extract_1_out;
    (*outg) = _e280;
    let _e281 = N_extract_2_out;
    (*outb) = _e281;
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
    let _e277 = (*in1_3);
    param_294 = _e277;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_294), (&param_295), (&param_296), (&param_297));
    let _e278 = param_295;
    N_separate_outr = _e278;
    let _e279 = param_296;
    N_separate_outg = _e279;
    let _e280 = param_297;
    N_separate_outb = _e280;
    let _e281 = N_separate_outr;
    let _e282 = N_separate_outg;
    N_max_01_out = max(_e281, _e282);
    let _e284 = N_max_01_out;
    let _e285 = N_separate_outb;
    N_max_out = max(_e284, _e285);
    let _e287 = N_max_out;
    (*mtlxRasterOut) = _e287;
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy: ptr<function, f32>, result_6: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e271 = (*roughness_16);
    let _e272 = (*roughness_16);
    roughness_sqr = clamp((_e271 * _e272), 0.00000001f, 1f);
    let _e275 = (*anisotropy);
    if (_e275 > 0f) {
        let _e277 = (*anisotropy);
        aspect = sqrt((1f - clamp(_e277, 0f, 0.98f)));
        let _e281 = roughness_sqr;
        let _e282 = aspect;
        (*result_6)[0u] = min((_e281 / _e282), 1f);
        let _e286 = roughness_sqr;
        let _e287 = aspect;
        (*result_6)[1u] = (_e286 * _e287);
    } else {
        let _e290 = roughness_sqr;
        (*result_6)[0u] = _e290;
        let _e292 = roughness_sqr;
        (*result_6)[1u] = _e292;
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
    let _e846 = (*clearcoat_roughness);
    param_298 = _e846;
    param_299 = 0f;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_298), (&param_299), (&param_300));
    let _e847 = param_300;
    clearcoat_roughness_uv_out = _e847;
    sheen_intensity_out = 0f;
    let _e848 = (*sheen_color);
    param_301 = _e848;
    NG_maxcomponent_color3_u0028_vf3_u003b_f1_u003b((&param_301), (&param_302));
    let _e849 = param_302;
    sheen_intensity_out = _e849;
    let _e850 = (*sheen_roughness);
    let _e851 = (*sheen_roughness);
    sheen_roughness_sq_out = (_e850 * _e851);
    let _e853 = (*iridescence);
    mix_iridescent_metal_bsdf_fg_weight_out = (1f * _e853);
    let _e855 = (*roughness_17);
    let _e856 = (*roughness_17);
    alpha_roughness_out = (_e855 * _e856);
    let _e858 = (*anisotropy_strength);
    let _e859 = (*anisotropy_strength);
    strength_2_out = (_e858 * _e859);
    let _e861 = (*anisotropy_rotation);
    abs_anisotropy_rotation_out = abs(_e861);
    let _e863 = (*anisotropy_rotation);
    rad_2_deg_out = (_e863 * -57.29578f);
    let _e865 = (*iridescence);
    mix_iridescent_metal_bsdf_mix_inv_out = (1f - _e865);
    let _e867 = (*iridescence);
    mix_iridescent_dielectric_reflection_fg_weight_out = (1f * _e867);
    let _e869 = (*ior_6);
    one_minus_ior_out = (1f - _e869);
    let _e871 = (*ior_6);
    one_plus_ior_out = (1f + _e871);
    let _e873 = (*specular);
    dielectric_f90_out = (vec3<f32>(1f, 1f, 1f) * _e873);
    let _e875 = (*iridescence);
    mix_iridescent_dielectric_reflection_mix_inv_out = (1f - _e875);
    let _e877 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e877);
    let _e879 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e879);
    let _e881 = (*metallic);
    base_mix_mix_inv_out = (1f - _e881);
    let _e883 = (*emissive);
    let _e884 = (*emissive_strength);
    emission_color_out = (_e883 * _e884);
    let _e886 = (*alpha_12);
    let _e887 = (*alpha_cutoff);
    opacity_mask_cutoff_out = select(0f, 1f, (_e886 >= _e887));
    let _e890 = (*sheen_color);
    let _e891 = sheen_intensity_out;
    sheen_color_normalized_out = (_e890 / vec3(_e891));
    let _e894 = alpha_roughness_out;
    clamped_ab_out = clamp(_e894, 0.00001f, 1f);
    let _e896 = alpha_roughness_out;
    let _e897 = strength_2_out;
    at_out = mix(_e896, 1f, _e897);
    rotate_tangent_out = vec3<f32>(0f, 0f, 0f);
    let _e899 = (*tangent);
    param_303 = _e899;
    let _e900 = rad_2_deg_out;
    param_304 = _e900;
    let _e901 = (*normal);
    param_305 = _e901;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_303), (&param_304), (&param_305), (&param_306));
    let _e902 = param_306;
    rotate_tangent_out = _e902;
    let _e903 = mix_iridescent_metal_bsdf_mix_inv_out;
    mix_iridescent_metal_bsdf_bg_weight_out = (1f * _e903);
    let _e905 = one_minus_ior_out;
    let _e906 = one_plus_ior_out;
    ior_div_out = (_e905 / _e906);
    let _e908 = mix_iridescent_dielectric_reflection_mix_inv_out;
    mix_iridescent_dielectric_reflection_bg_weight_out = (1f * _e908);
    let _e910 = transmission_mix_mix_inv_out;
    transmission_mix_bg_weight_out = (1f * _e910);
    let _e912 = (*alpha_mode);
    let _e914 = opacity_mask_cutoff_out;
    let _e915 = (*alpha_12);
    opacity_mask_out = select(_e915, _e914, (_e912 == 1i));
    let _e917 = at_out;
    clamped_at_out = clamp(_e917, 0.00001f, 1f);
    let _e919 = rotate_tangent_out;
    normalize_tangent_out = normalize(_e919);
    let _e921 = ior_div_out;
    let _e922 = ior_div_out;
    dielectric_f0_from_ior_out = (_e921 * _e922);
    let _e924 = (*alpha_mode);
    let _e926 = opacity_mask_out;
    opacity_out = select(_e926, 1f, (_e924 == 0i));
    let _e928 = clamped_at_out;
    let _e929 = clamped_ab_out;
    roughness_uv_out = vec2<f32>(_e928, _e929);
    let _e931 = abs_anisotropy_rotation_out;
    let _e933 = normalize_tangent_out;
    let _e934 = (*tangent);
    selected_tangent_out = select(_e934, _e933, (_e931 > 0f));
    let _e936 = (*specular_color);
    let _e937 = dielectric_f0_from_ior_out;
    dielectric_f0_from_ior_specular_color_out = (_e936 * _e937);
    let _e939 = dielectric_f0_from_ior_specular_color_out;
    clamped_dielectric_f0_from_ior_specular_color_out = min(_e939, vec3(1f));
    let _e942 = clamped_dielectric_f0_from_ior_specular_color_out;
    let _e943 = (*specular);
    dielectric_f0_out = (_e942 * _e943);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e945 = normalWorld;
    N_13 = normalize(_e945);
    let _e949 = unnamed.cameraWorldMatrix[3];
    let _e951 = positionWorld;
    V_12 = normalize((_e949.xyz - _e951));
    let _e954 = positionWorld;
    P_1 = _e954;
    L_7 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e955 = opacity_out;
    surfaceOpacity = _e955;
    let _e956 = numActiveLightSources_u0028_();
    numLights = _e956;
    activeLightIndex = 0i;
    loop {
        let _e957 = activeLightIndex;
        let _e958 = numLights;
        if (_e957 < _e958) {
            let _e960 = activeLightIndex;
            let _e963 = unnamed.u_lightData[_e960];
            param_307 = _e963;
            let _e964 = positionWorld;
            param_308 = _e964;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_307), (&param_308), (&param_309));
            let _e965 = param_309;
            lightShader = _e965;
            let _e967 = lightShader.direction;
            L_7 = _e967;
            param_310 = 1i;
            let _e968 = L_7;
            param_311 = _e968;
            let _e969 = V_12;
            param_312 = _e969;
            let _e970 = N_13;
            param_313 = _e970;
            let _e971 = P_1;
            param_314 = _e971;
            let _e972 = occlusion_2;
            param_315 = _e972;
            let _e973 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_310), (&param_311), (&param_312), (&param_313), (&param_314), (&param_315));
            closureData_8 = _e973;
            clearcoat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e974 = closureData_8;
            param_316 = _e974;
            let _e975 = (*clearcoat);
            param_317 = _e975;
            param_318 = vec3<f32>(1f, 1f, 1f);
            param_319 = 1.5f;
            let _e976 = clearcoat_roughness_uv_out;
            param_320 = _e976;
            param_321 = false;
            param_322 = 0f;
            param_323 = 1.5f;
            let _e977 = (*clearcoat_normal);
            param_324 = _e977;
            let _e978 = (*tangent);
            param_325 = _e978;
            param_326 = 0i;
            param_327 = 0i;
            let _e979 = clearcoat_bsdf_out;
            param_328 = _e979;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_316), (&param_317), (&param_318), (&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324), (&param_325), (&param_326), (&param_327), (&param_328));
            let _e980 = param_328;
            clearcoat_bsdf_out = _e980;
            sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e981 = closureData_8;
            param_329 = _e981;
            let _e982 = sheen_intensity_out;
            param_330 = _e982;
            let _e983 = sheen_color_normalized_out;
            param_331 = _e983;
            let _e984 = sheen_roughness_sq_out;
            param_332 = _e984;
            let _e985 = (*normal);
            param_333 = _e985;
            param_334 = 0i;
            let _e986 = sheen_bsdf_out;
            param_335 = _e986;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335));
            let _e987 = param_335;
            sheen_bsdf_out = _e987;
            tf_metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e988 = closureData_8;
            param_336 = _e988;
            let _e989 = mix_iridescent_metal_bsdf_fg_weight_out;
            param_337 = _e989;
            let _e990 = (*base_color);
            param_338 = _e990;
            param_339 = vec3<f32>(1f, 1f, 1f);
            param_340 = vec3<f32>(1f, 1f, 1f);
            param_341 = 5f;
            let _e991 = roughness_uv_out;
            param_342 = _e991;
            param_343 = false;
            let _e992 = (*iridescence_thickness);
            param_344 = _e992;
            let _e993 = (*iridescence_ior);
            param_345 = _e993;
            let _e994 = (*normal);
            param_346 = _e994;
            let _e995 = selected_tangent_out;
            param_347 = _e995;
            param_348 = 0i;
            param_349 = 0i;
            let _e996 = tf_metal_bsdf_out;
            param_350 = _e996;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_336), (&param_337), (&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349), (&param_350));
            let _e997 = param_350;
            tf_metal_bsdf_out = _e997;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e998 = closureData_8;
            param_351 = _e998;
            let _e999 = mix_iridescent_metal_bsdf_bg_weight_out;
            param_352 = _e999;
            let _e1000 = (*base_color);
            param_353 = _e1000;
            param_354 = vec3<f32>(1f, 1f, 1f);
            param_355 = vec3<f32>(1f, 1f, 1f);
            param_356 = 5f;
            let _e1001 = roughness_uv_out;
            param_357 = _e1001;
            param_358 = false;
            param_359 = 0f;
            param_360 = 1.5f;
            let _e1002 = (*normal);
            param_361 = _e1002;
            let _e1003 = selected_tangent_out;
            param_362 = _e1003;
            param_363 = 0i;
            param_364 = 0i;
            let _e1004 = metal_bsdf_out;
            param_365 = _e1004;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365));
            let _e1005 = param_365;
            metal_bsdf_out = _e1005;
            mix_iridescent_metal_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1006 = closureData_8;
            param_366 = _e1006;
            let _e1007 = tf_metal_bsdf_out;
            param_367 = _e1007;
            let _e1008 = metal_bsdf_out;
            param_368 = _e1008;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_366), (&param_367), (&param_368), (&param_369));
            let _e1009 = param_369;
            mix_iridescent_metal_bsdf_add_out = _e1009;
            base_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1010 = closureData_8;
            param_370 = _e1010;
            let _e1011 = mix_iridescent_metal_bsdf_add_out;
            param_371 = _e1011;
            let _e1012 = (*metallic);
            param_372 = _e1012;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_370), (&param_371), (&param_372), (&param_373));
            let _e1013 = param_373;
            base_mix_fg_mul_out = _e1013;
            tf_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1014 = closureData_8;
            param_374 = _e1014;
            let _e1015 = mix_iridescent_dielectric_reflection_fg_weight_out;
            param_375 = _e1015;
            let _e1016 = dielectric_f0_out;
            param_376 = _e1016;
            param_377 = vec3<f32>(1f, 1f, 1f);
            let _e1017 = dielectric_f90_out;
            param_378 = _e1017;
            param_379 = 5f;
            let _e1018 = roughness_uv_out;
            param_380 = _e1018;
            param_381 = false;
            let _e1019 = (*iridescence_thickness);
            param_382 = _e1019;
            let _e1020 = (*iridescence_ior);
            param_383 = _e1020;
            let _e1021 = (*normal);
            param_384 = _e1021;
            let _e1022 = selected_tangent_out;
            param_385 = _e1022;
            param_386 = 0i;
            param_387 = 0i;
            let _e1023 = tf_reflection_bsdf_out;
            param_388 = _e1023;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_374), (&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386), (&param_387), (&param_388));
            let _e1024 = param_388;
            tf_reflection_bsdf_out = _e1024;
            reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1025 = closureData_8;
            param_389 = _e1025;
            let _e1026 = mix_iridescent_dielectric_reflection_bg_weight_out;
            param_390 = _e1026;
            let _e1027 = dielectric_f0_out;
            param_391 = _e1027;
            param_392 = vec3<f32>(1f, 1f, 1f);
            let _e1028 = dielectric_f90_out;
            param_393 = _e1028;
            param_394 = 5f;
            let _e1029 = roughness_uv_out;
            param_395 = _e1029;
            param_396 = false;
            param_397 = 0f;
            param_398 = 1.5f;
            let _e1030 = (*normal);
            param_399 = _e1030;
            let _e1031 = selected_tangent_out;
            param_400 = _e1031;
            param_401 = 0i;
            param_402 = 0i;
            let _e1032 = reflection_bsdf_out;
            param_403 = _e1032;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401), (&param_402), (&param_403));
            let _e1033 = param_403;
            reflection_bsdf_out = _e1033;
            mix_iridescent_dielectric_reflection_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1034 = closureData_8;
            param_404 = _e1034;
            let _e1035 = tf_reflection_bsdf_out;
            param_405 = _e1035;
            let _e1036 = reflection_bsdf_out;
            param_406 = _e1036;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_404), (&param_405), (&param_406), (&param_407));
            let _e1037 = param_407;
            mix_iridescent_dielectric_reflection_add_out = _e1037;
            transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1038 = closureData_8;
            param_408 = _e1038;
            let _e1039 = transmission_mix_fg_weight_out;
            param_409 = _e1039;
            let _e1040 = (*base_color);
            param_410 = _e1040;
            let _e1041 = (*ior_6);
            param_411 = _e1041;
            let _e1042 = roughness_uv_out;
            param_412 = _e1042;
            param_413 = false;
            param_414 = 0f;
            param_415 = 1.5f;
            let _e1043 = (*normal);
            param_416 = _e1043;
            let _e1044 = selected_tangent_out;
            param_417 = _e1044;
            param_418 = 0i;
            param_419 = 1i;
            let _e1045 = transmission_bsdf_out;
            param_420 = _e1045;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_408), (&param_409), (&param_410), (&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420));
            let _e1046 = param_420;
            transmission_bsdf_out = _e1046;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1047 = closureData_8;
            param_421 = _e1047;
            let _e1048 = transmission_mix_bg_weight_out;
            param_422 = _e1048;
            let _e1049 = (*base_color);
            param_423 = _e1049;
            param_424 = 0f;
            let _e1050 = (*normal);
            param_425 = _e1050;
            param_426 = false;
            let _e1051 = diffuse_bsdf_out;
            param_427 = _e1051;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_421), (&param_422), (&param_423), (&param_424), (&param_425), (&param_426), (&param_427));
            let _e1052 = param_427;
            diffuse_bsdf_out = _e1052;
            transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1053 = closureData_8;
            param_428 = _e1053;
            let _e1054 = transmission_bsdf_out;
            param_429 = _e1054;
            let _e1055 = diffuse_bsdf_out;
            param_430 = _e1055;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_428), (&param_429), (&param_430), (&param_431));
            let _e1056 = param_431;
            transmission_mix_add_out = _e1056;
            iridescent_dielectric_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1057 = closureData_8;
            param_432 = _e1057;
            let _e1058 = mix_iridescent_dielectric_reflection_add_out;
            param_433 = _e1058;
            let _e1059 = transmission_mix_add_out;
            param_434 = _e1059;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_432), (&param_433), (&param_434), (&param_435));
            let _e1060 = param_435;
            iridescent_dielectric_bsdf_out = _e1060;
            base_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1061 = closureData_8;
            param_436 = _e1061;
            let _e1062 = iridescent_dielectric_bsdf_out;
            param_437 = _e1062;
            let _e1063 = base_mix_mix_inv_out;
            param_438 = _e1063;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_436), (&param_437), (&param_438), (&param_439));
            let _e1064 = param_439;
            base_mix_bg_mul_out = _e1064;
            base_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1065 = closureData_8;
            param_440 = _e1065;
            let _e1066 = base_mix_fg_mul_out;
            param_441 = _e1066;
            let _e1067 = base_mix_bg_mul_out;
            param_442 = _e1067;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_440), (&param_441), (&param_442), (&param_443));
            let _e1068 = param_443;
            base_mix_add_out = _e1068;
            sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1069 = closureData_8;
            param_444 = _e1069;
            let _e1070 = sheen_bsdf_out;
            param_445 = _e1070;
            let _e1071 = base_mix_add_out;
            param_446 = _e1071;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_444), (&param_445), (&param_446), (&param_447));
            let _e1072 = param_447;
            sheen_layer_out = _e1072;
            clearcoat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1073 = closureData_8;
            param_448 = _e1073;
            let _e1074 = clearcoat_bsdf_out;
            param_449 = _e1074;
            let _e1075 = sheen_layer_out;
            param_450 = _e1075;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_448), (&param_449), (&param_450), (&param_451));
            let _e1076 = param_451;
            clearcoat_layer_out = _e1076;
            let _e1078 = lightShader.intensity;
            let _e1080 = clearcoat_layer_out.response;
            let _e1083 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1083 + (_e1078 * _e1080));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1086 = activeLightIndex;
            activeLightIndex = (_e1086 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_452 = 3i;
    let _e1088 = L_7;
    param_453 = _e1088;
    let _e1089 = V_12;
    param_454 = _e1089;
    let _e1090 = N_13;
    param_455 = _e1090;
    let _e1091 = P_1;
    param_456 = _e1091;
    let _e1092 = occlusion_2;
    param_457 = _e1092;
    let _e1093 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_452), (&param_453), (&param_454), (&param_455), (&param_456), (&param_457));
    closureData_9 = _e1093;
    clearcoat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1094 = closureData_9;
    param_458 = _e1094;
    let _e1095 = (*clearcoat);
    param_459 = _e1095;
    param_460 = vec3<f32>(1f, 1f, 1f);
    param_461 = 1.5f;
    let _e1096 = clearcoat_roughness_uv_out;
    param_462 = _e1096;
    param_463 = false;
    param_464 = 0f;
    param_465 = 1.5f;
    let _e1097 = (*clearcoat_normal);
    param_466 = _e1097;
    let _e1098 = (*tangent);
    param_467 = _e1098;
    param_468 = 0i;
    param_469 = 0i;
    let _e1099 = clearcoat_bsdf_out_1;
    param_470 = _e1099;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_458), (&param_459), (&param_460), (&param_461), (&param_462), (&param_463), (&param_464), (&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470));
    let _e1100 = param_470;
    clearcoat_bsdf_out_1 = _e1100;
    sheen_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1101 = closureData_9;
    param_471 = _e1101;
    let _e1102 = sheen_intensity_out;
    param_472 = _e1102;
    let _e1103 = sheen_color_normalized_out;
    param_473 = _e1103;
    let _e1104 = sheen_roughness_sq_out;
    param_474 = _e1104;
    let _e1105 = (*normal);
    param_475 = _e1105;
    param_476 = 0i;
    let _e1106 = sheen_bsdf_out_1;
    param_477 = _e1106;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476), (&param_477));
    let _e1107 = param_477;
    sheen_bsdf_out_1 = _e1107;
    tf_metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1108 = closureData_9;
    param_478 = _e1108;
    let _e1109 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_479 = _e1109;
    let _e1110 = (*base_color);
    param_480 = _e1110;
    param_481 = vec3<f32>(1f, 1f, 1f);
    param_482 = vec3<f32>(1f, 1f, 1f);
    param_483 = 5f;
    let _e1111 = roughness_uv_out;
    param_484 = _e1111;
    param_485 = false;
    let _e1112 = (*iridescence_thickness);
    param_486 = _e1112;
    let _e1113 = (*iridescence_ior);
    param_487 = _e1113;
    let _e1114 = (*normal);
    param_488 = _e1114;
    let _e1115 = selected_tangent_out;
    param_489 = _e1115;
    param_490 = 0i;
    param_491 = 0i;
    let _e1116 = tf_metal_bsdf_out_1;
    param_492 = _e1116;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489), (&param_490), (&param_491), (&param_492));
    let _e1117 = param_492;
    tf_metal_bsdf_out_1 = _e1117;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1118 = closureData_9;
    param_493 = _e1118;
    let _e1119 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_494 = _e1119;
    let _e1120 = (*base_color);
    param_495 = _e1120;
    param_496 = vec3<f32>(1f, 1f, 1f);
    param_497 = vec3<f32>(1f, 1f, 1f);
    param_498 = 5f;
    let _e1121 = roughness_uv_out;
    param_499 = _e1121;
    param_500 = false;
    param_501 = 0f;
    param_502 = 1.5f;
    let _e1122 = (*normal);
    param_503 = _e1122;
    let _e1123 = selected_tangent_out;
    param_504 = _e1123;
    param_505 = 0i;
    param_506 = 0i;
    let _e1124 = metal_bsdf_out_1;
    param_507 = _e1124;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502), (&param_503), (&param_504), (&param_505), (&param_506), (&param_507));
    let _e1125 = param_507;
    metal_bsdf_out_1 = _e1125;
    mix_iridescent_metal_bsdf_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1126 = closureData_9;
    param_508 = _e1126;
    let _e1127 = tf_metal_bsdf_out_1;
    param_509 = _e1127;
    let _e1128 = metal_bsdf_out_1;
    param_510 = _e1128;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_508), (&param_509), (&param_510), (&param_511));
    let _e1129 = param_511;
    mix_iridescent_metal_bsdf_add_out_1 = _e1129;
    base_mix_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1130 = closureData_9;
    param_512 = _e1130;
    let _e1131 = mix_iridescent_metal_bsdf_add_out_1;
    param_513 = _e1131;
    let _e1132 = (*metallic);
    param_514 = _e1132;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_512), (&param_513), (&param_514), (&param_515));
    let _e1133 = param_515;
    base_mix_fg_mul_out_1 = _e1133;
    tf_reflection_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1134 = closureData_9;
    param_516 = _e1134;
    let _e1135 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_517 = _e1135;
    let _e1136 = dielectric_f0_out;
    param_518 = _e1136;
    param_519 = vec3<f32>(1f, 1f, 1f);
    let _e1137 = dielectric_f90_out;
    param_520 = _e1137;
    param_521 = 5f;
    let _e1138 = roughness_uv_out;
    param_522 = _e1138;
    param_523 = false;
    let _e1139 = (*iridescence_thickness);
    param_524 = _e1139;
    let _e1140 = (*iridescence_ior);
    param_525 = _e1140;
    let _e1141 = (*normal);
    param_526 = _e1141;
    let _e1142 = selected_tangent_out;
    param_527 = _e1142;
    param_528 = 0i;
    param_529 = 0i;
    let _e1143 = tf_reflection_bsdf_out_1;
    param_530 = _e1143;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_516), (&param_517), (&param_518), (&param_519), (&param_520), (&param_521), (&param_522), (&param_523), (&param_524), (&param_525), (&param_526), (&param_527), (&param_528), (&param_529), (&param_530));
    let _e1144 = param_530;
    tf_reflection_bsdf_out_1 = _e1144;
    reflection_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1145 = closureData_9;
    param_531 = _e1145;
    let _e1146 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_532 = _e1146;
    let _e1147 = dielectric_f0_out;
    param_533 = _e1147;
    param_534 = vec3<f32>(1f, 1f, 1f);
    let _e1148 = dielectric_f90_out;
    param_535 = _e1148;
    param_536 = 5f;
    let _e1149 = roughness_uv_out;
    param_537 = _e1149;
    param_538 = false;
    param_539 = 0f;
    param_540 = 1.5f;
    let _e1150 = (*normal);
    param_541 = _e1150;
    let _e1151 = selected_tangent_out;
    param_542 = _e1151;
    param_543 = 0i;
    param_544 = 0i;
    let _e1152 = reflection_bsdf_out_1;
    param_545 = _e1152;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_531), (&param_532), (&param_533), (&param_534), (&param_535), (&param_536), (&param_537), (&param_538), (&param_539), (&param_540), (&param_541), (&param_542), (&param_543), (&param_544), (&param_545));
    let _e1153 = param_545;
    reflection_bsdf_out_1 = _e1153;
    mix_iridescent_dielectric_reflection_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1154 = closureData_9;
    param_546 = _e1154;
    let _e1155 = tf_reflection_bsdf_out_1;
    param_547 = _e1155;
    let _e1156 = reflection_bsdf_out_1;
    param_548 = _e1156;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_546), (&param_547), (&param_548), (&param_549));
    let _e1157 = param_549;
    mix_iridescent_dielectric_reflection_add_out_1 = _e1157;
    transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1158 = closureData_9;
    param_550 = _e1158;
    let _e1159 = transmission_mix_fg_weight_out;
    param_551 = _e1159;
    let _e1160 = (*base_color);
    param_552 = _e1160;
    let _e1161 = (*ior_6);
    param_553 = _e1161;
    let _e1162 = roughness_uv_out;
    param_554 = _e1162;
    param_555 = false;
    param_556 = 0f;
    param_557 = 1.5f;
    let _e1163 = (*normal);
    param_558 = _e1163;
    let _e1164 = selected_tangent_out;
    param_559 = _e1164;
    param_560 = 0i;
    param_561 = 1i;
    let _e1165 = transmission_bsdf_out_1;
    param_562 = _e1165;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_550), (&param_551), (&param_552), (&param_553), (&param_554), (&param_555), (&param_556), (&param_557), (&param_558), (&param_559), (&param_560), (&param_561), (&param_562));
    let _e1166 = param_562;
    transmission_bsdf_out_1 = _e1166;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1167 = closureData_9;
    param_563 = _e1167;
    let _e1168 = transmission_mix_bg_weight_out;
    param_564 = _e1168;
    let _e1169 = (*base_color);
    param_565 = _e1169;
    param_566 = 0f;
    let _e1170 = (*normal);
    param_567 = _e1170;
    param_568 = false;
    let _e1171 = diffuse_bsdf_out_1;
    param_569 = _e1171;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_563), (&param_564), (&param_565), (&param_566), (&param_567), (&param_568), (&param_569));
    let _e1172 = param_569;
    diffuse_bsdf_out_1 = _e1172;
    transmission_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1173 = closureData_9;
    param_570 = _e1173;
    let _e1174 = transmission_bsdf_out_1;
    param_571 = _e1174;
    let _e1175 = diffuse_bsdf_out_1;
    param_572 = _e1175;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_570), (&param_571), (&param_572), (&param_573));
    let _e1176 = param_573;
    transmission_mix_add_out_1 = _e1176;
    iridescent_dielectric_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1177 = closureData_9;
    param_574 = _e1177;
    let _e1178 = mix_iridescent_dielectric_reflection_add_out_1;
    param_575 = _e1178;
    let _e1179 = transmission_mix_add_out_1;
    param_576 = _e1179;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_574), (&param_575), (&param_576), (&param_577));
    let _e1180 = param_577;
    iridescent_dielectric_bsdf_out_1 = _e1180;
    base_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1181 = closureData_9;
    param_578 = _e1181;
    let _e1182 = iridescent_dielectric_bsdf_out_1;
    param_579 = _e1182;
    let _e1183 = base_mix_mix_inv_out;
    param_580 = _e1183;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_578), (&param_579), (&param_580), (&param_581));
    let _e1184 = param_581;
    base_mix_bg_mul_out_1 = _e1184;
    base_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1185 = closureData_9;
    param_582 = _e1185;
    let _e1186 = base_mix_fg_mul_out_1;
    param_583 = _e1186;
    let _e1187 = base_mix_bg_mul_out_1;
    param_584 = _e1187;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_582), (&param_583), (&param_584), (&param_585));
    let _e1188 = param_585;
    base_mix_add_out_1 = _e1188;
    sheen_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1189 = closureData_9;
    param_586 = _e1189;
    let _e1190 = sheen_bsdf_out_1;
    param_587 = _e1190;
    let _e1191 = base_mix_add_out_1;
    param_588 = _e1191;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_586), (&param_587), (&param_588), (&param_589));
    let _e1192 = param_589;
    sheen_layer_out_1 = _e1192;
    clearcoat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1193 = closureData_9;
    param_590 = _e1193;
    let _e1194 = clearcoat_bsdf_out_1;
    param_591 = _e1194;
    let _e1195 = sheen_layer_out_1;
    param_592 = _e1195;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_590), (&param_591), (&param_592), (&param_593));
    let _e1196 = param_593;
    clearcoat_layer_out_1 = _e1196;
    let _e1197 = occlusion_2;
    let _e1199 = clearcoat_layer_out_1.response;
    let _e1202 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1202 + (_e1199 * _e1197));
    param_594 = 4i;
    let _e1205 = L_7;
    param_595 = _e1205;
    let _e1206 = V_12;
    param_596 = _e1206;
    let _e1207 = N_13;
    param_597 = _e1207;
    let _e1208 = P_1;
    param_598 = _e1208;
    let _e1209 = occlusion_2;
    param_599 = _e1209;
    let _e1210 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_594), (&param_595), (&param_596), (&param_597), (&param_598), (&param_599));
    closureData_10 = _e1210;
    emission_out = vec3<f32>(0f, 0f, 0f);
    let _e1211 = closureData_10;
    param_600 = _e1211;
    let _e1212 = emission_color_out;
    param_601 = _e1212;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_600), (&param_601), (&param_602));
    let _e1213 = param_602;
    emission_out = _e1213;
    let _e1214 = emission_out;
    let _e1216 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1216 + _e1214);
    param_603 = 2i;
    let _e1219 = L_7;
    param_604 = _e1219;
    let _e1220 = V_12;
    param_605 = _e1220;
    let _e1221 = N_13;
    param_606 = _e1221;
    let _e1222 = P_1;
    param_607 = _e1222;
    let _e1223 = occlusion_2;
    param_608 = _e1223;
    let _e1224 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608));
    closureData_11 = _e1224;
    clearcoat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1225 = closureData_11;
    param_609 = _e1225;
    let _e1226 = (*clearcoat);
    param_610 = _e1226;
    param_611 = vec3<f32>(1f, 1f, 1f);
    param_612 = 1.5f;
    let _e1227 = clearcoat_roughness_uv_out;
    param_613 = _e1227;
    param_614 = false;
    param_615 = 0f;
    param_616 = 1.5f;
    let _e1228 = (*clearcoat_normal);
    param_617 = _e1228;
    let _e1229 = (*tangent);
    param_618 = _e1229;
    param_619 = 0i;
    param_620 = 0i;
    let _e1230 = clearcoat_bsdf_out_2;
    param_621 = _e1230;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615), (&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621));
    let _e1231 = param_621;
    clearcoat_bsdf_out_2 = _e1231;
    sheen_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1232 = closureData_11;
    param_622 = _e1232;
    let _e1233 = sheen_intensity_out;
    param_623 = _e1233;
    let _e1234 = sheen_color_normalized_out;
    param_624 = _e1234;
    let _e1235 = sheen_roughness_sq_out;
    param_625 = _e1235;
    let _e1236 = (*normal);
    param_626 = _e1236;
    param_627 = 0i;
    let _e1237 = sheen_bsdf_out_2;
    param_628 = _e1237;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627), (&param_628));
    let _e1238 = param_628;
    sheen_bsdf_out_2 = _e1238;
    tf_metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1239 = closureData_11;
    param_629 = _e1239;
    let _e1240 = mix_iridescent_metal_bsdf_fg_weight_out;
    param_630 = _e1240;
    let _e1241 = (*base_color);
    param_631 = _e1241;
    param_632 = vec3<f32>(1f, 1f, 1f);
    param_633 = vec3<f32>(1f, 1f, 1f);
    param_634 = 5f;
    let _e1242 = roughness_uv_out;
    param_635 = _e1242;
    param_636 = false;
    let _e1243 = (*iridescence_thickness);
    param_637 = _e1243;
    let _e1244 = (*iridescence_ior);
    param_638 = _e1244;
    let _e1245 = (*normal);
    param_639 = _e1245;
    let _e1246 = selected_tangent_out;
    param_640 = _e1246;
    param_641 = 0i;
    param_642 = 0i;
    let _e1247 = tf_metal_bsdf_out_2;
    param_643 = _e1247;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_629), (&param_630), (&param_631), (&param_632), (&param_633), (&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640), (&param_641), (&param_642), (&param_643));
    let _e1248 = param_643;
    tf_metal_bsdf_out_2 = _e1248;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1249 = closureData_11;
    param_644 = _e1249;
    let _e1250 = mix_iridescent_metal_bsdf_bg_weight_out;
    param_645 = _e1250;
    let _e1251 = (*base_color);
    param_646 = _e1251;
    param_647 = vec3<f32>(1f, 1f, 1f);
    param_648 = vec3<f32>(1f, 1f, 1f);
    param_649 = 5f;
    let _e1252 = roughness_uv_out;
    param_650 = _e1252;
    param_651 = false;
    param_652 = 0f;
    param_653 = 1.5f;
    let _e1253 = (*normal);
    param_654 = _e1253;
    let _e1254 = selected_tangent_out;
    param_655 = _e1254;
    param_656 = 0i;
    param_657 = 0i;
    let _e1255 = metal_bsdf_out_2;
    param_658 = _e1255;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650), (&param_651), (&param_652), (&param_653), (&param_654), (&param_655), (&param_656), (&param_657), (&param_658));
    let _e1256 = param_658;
    metal_bsdf_out_2 = _e1256;
    mix_iridescent_metal_bsdf_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1257 = closureData_11;
    param_659 = _e1257;
    let _e1258 = tf_metal_bsdf_out_2;
    param_660 = _e1258;
    let _e1259 = metal_bsdf_out_2;
    param_661 = _e1259;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_659), (&param_660), (&param_661), (&param_662));
    let _e1260 = param_662;
    mix_iridescent_metal_bsdf_add_out_2 = _e1260;
    base_mix_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1261 = closureData_11;
    param_663 = _e1261;
    let _e1262 = mix_iridescent_metal_bsdf_add_out_2;
    param_664 = _e1262;
    let _e1263 = (*metallic);
    param_665 = _e1263;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_663), (&param_664), (&param_665), (&param_666));
    let _e1264 = param_666;
    base_mix_fg_mul_out_2 = _e1264;
    tf_reflection_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1265 = closureData_11;
    param_667 = _e1265;
    let _e1266 = mix_iridescent_dielectric_reflection_fg_weight_out;
    param_668 = _e1266;
    let _e1267 = dielectric_f0_out;
    param_669 = _e1267;
    param_670 = vec3<f32>(1f, 1f, 1f);
    let _e1268 = dielectric_f90_out;
    param_671 = _e1268;
    param_672 = 5f;
    let _e1269 = roughness_uv_out;
    param_673 = _e1269;
    param_674 = false;
    let _e1270 = (*iridescence_thickness);
    param_675 = _e1270;
    let _e1271 = (*iridescence_ior);
    param_676 = _e1271;
    let _e1272 = (*normal);
    param_677 = _e1272;
    let _e1273 = selected_tangent_out;
    param_678 = _e1273;
    param_679 = 0i;
    param_680 = 0i;
    let _e1274 = tf_reflection_bsdf_out_2;
    param_681 = _e1274;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672), (&param_673), (&param_674), (&param_675), (&param_676), (&param_677), (&param_678), (&param_679), (&param_680), (&param_681));
    let _e1275 = param_681;
    tf_reflection_bsdf_out_2 = _e1275;
    reflection_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1276 = closureData_11;
    param_682 = _e1276;
    let _e1277 = mix_iridescent_dielectric_reflection_bg_weight_out;
    param_683 = _e1277;
    let _e1278 = dielectric_f0_out;
    param_684 = _e1278;
    param_685 = vec3<f32>(1f, 1f, 1f);
    let _e1279 = dielectric_f90_out;
    param_686 = _e1279;
    param_687 = 5f;
    let _e1280 = roughness_uv_out;
    param_688 = _e1280;
    param_689 = false;
    param_690 = 0f;
    param_691 = 1.5f;
    let _e1281 = (*normal);
    param_692 = _e1281;
    let _e1282 = selected_tangent_out;
    param_693 = _e1282;
    param_694 = 0i;
    param_695 = 0i;
    let _e1283 = reflection_bsdf_out_2;
    param_696 = _e1283;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687), (&param_688), (&param_689), (&param_690), (&param_691), (&param_692), (&param_693), (&param_694), (&param_695), (&param_696));
    let _e1284 = param_696;
    reflection_bsdf_out_2 = _e1284;
    mix_iridescent_dielectric_reflection_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1285 = closureData_11;
    param_697 = _e1285;
    let _e1286 = tf_reflection_bsdf_out_2;
    param_698 = _e1286;
    let _e1287 = reflection_bsdf_out_2;
    param_699 = _e1287;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_697), (&param_698), (&param_699), (&param_700));
    let _e1288 = param_700;
    mix_iridescent_dielectric_reflection_add_out_2 = _e1288;
    transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1289 = closureData_11;
    param_701 = _e1289;
    let _e1290 = transmission_mix_fg_weight_out;
    param_702 = _e1290;
    let _e1291 = (*base_color);
    param_703 = _e1291;
    let _e1292 = (*ior_6);
    param_704 = _e1292;
    let _e1293 = roughness_uv_out;
    param_705 = _e1293;
    param_706 = false;
    param_707 = 0f;
    param_708 = 1.5f;
    let _e1294 = (*normal);
    param_709 = _e1294;
    let _e1295 = selected_tangent_out;
    param_710 = _e1295;
    param_711 = 0i;
    param_712 = 1i;
    let _e1296 = transmission_bsdf_out_2;
    param_713 = _e1296;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_701), (&param_702), (&param_703), (&param_704), (&param_705), (&param_706), (&param_707), (&param_708), (&param_709), (&param_710), (&param_711), (&param_712), (&param_713));
    let _e1297 = param_713;
    transmission_bsdf_out_2 = _e1297;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1298 = closureData_11;
    param_714 = _e1298;
    let _e1299 = transmission_mix_bg_weight_out;
    param_715 = _e1299;
    let _e1300 = (*base_color);
    param_716 = _e1300;
    param_717 = 0f;
    let _e1301 = (*normal);
    param_718 = _e1301;
    param_719 = false;
    let _e1302 = diffuse_bsdf_out_2;
    param_720 = _e1302;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_714), (&param_715), (&param_716), (&param_717), (&param_718), (&param_719), (&param_720));
    let _e1303 = param_720;
    diffuse_bsdf_out_2 = _e1303;
    transmission_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1304 = closureData_11;
    param_721 = _e1304;
    let _e1305 = transmission_bsdf_out_2;
    param_722 = _e1305;
    let _e1306 = diffuse_bsdf_out_2;
    param_723 = _e1306;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_721), (&param_722), (&param_723), (&param_724));
    let _e1307 = param_724;
    transmission_mix_add_out_2 = _e1307;
    iridescent_dielectric_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1308 = closureData_11;
    param_725 = _e1308;
    let _e1309 = mix_iridescent_dielectric_reflection_add_out_2;
    param_726 = _e1309;
    let _e1310 = transmission_mix_add_out_2;
    param_727 = _e1310;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_725), (&param_726), (&param_727), (&param_728));
    let _e1311 = param_728;
    iridescent_dielectric_bsdf_out_2 = _e1311;
    base_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1312 = closureData_11;
    param_729 = _e1312;
    let _e1313 = iridescent_dielectric_bsdf_out_2;
    param_730 = _e1313;
    let _e1314 = base_mix_mix_inv_out;
    param_731 = _e1314;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_729), (&param_730), (&param_731), (&param_732));
    let _e1315 = param_732;
    base_mix_bg_mul_out_2 = _e1315;
    base_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1316 = closureData_11;
    param_733 = _e1316;
    let _e1317 = base_mix_fg_mul_out_2;
    param_734 = _e1317;
    let _e1318 = base_mix_bg_mul_out_2;
    param_735 = _e1318;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_733), (&param_734), (&param_735), (&param_736));
    let _e1319 = param_736;
    base_mix_add_out_2 = _e1319;
    sheen_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1320 = closureData_11;
    param_737 = _e1320;
    let _e1321 = sheen_bsdf_out_2;
    param_738 = _e1321;
    let _e1322 = base_mix_add_out_2;
    param_739 = _e1322;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_737), (&param_738), (&param_739), (&param_740));
    let _e1323 = param_740;
    sheen_layer_out_2 = _e1323;
    clearcoat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1324 = closureData_11;
    param_741 = _e1324;
    let _e1325 = clearcoat_bsdf_out_2;
    param_742 = _e1325;
    let _e1326 = sheen_layer_out_2;
    param_743 = _e1326;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_741), (&param_742), (&param_743), (&param_744));
    let _e1327 = param_744;
    clearcoat_layer_out_2 = _e1327;
    let _e1329 = clearcoat_layer_out_2.response;
    let _e1331 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1331 + _e1329);
    let _e1334 = surfaceOpacity;
    let _e1336 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1336 * _e1334);
    let _e1340 = shader_constructor_out.transparency;
    let _e1341 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e1340, vec3(_e1341));
    let _e1345 = shader_constructor_out;
    (*mtlxRasterOut_1) = _e1345;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_carpaint_out: surfaceshader;
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

    let _e299 = normalWorld;
    geomprop_Nworld_out = normalize(_e299);
    let _e301 = tangentWorld;
    geomprop_Tworld_out = normalize(_e301);
    SR_carpaint_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e303 = base_color_1;
    param_745 = _e303;
    let _e304 = metallic_1;
    param_746 = _e304;
    let _e305 = roughness_18;
    param_747 = _e305;
    let _e306 = geomprop_Nworld_out;
    param_748 = _e306;
    let _e307 = geomprop_Tworld_out;
    param_749 = _e307;
    let _e308 = occlusion_3;
    param_750 = _e308;
    let _e309 = transmission_1;
    param_751 = _e309;
    let _e310 = specular_1;
    param_752 = _e310;
    let _e311 = specular_color_1;
    param_753 = _e311;
    let _e312 = ior_7;
    param_754 = _e312;
    let _e313 = alpha_13;
    param_755 = _e313;
    let _e314 = alpha_mode_1;
    param_756 = _e314;
    let _e315 = alpha_cutoff_1;
    param_757 = _e315;
    let _e316 = iridescence_1;
    param_758 = _e316;
    let _e317 = iridescence_ior_1;
    param_759 = _e317;
    let _e318 = iridescence_thickness_1;
    param_760 = _e318;
    let _e319 = sheen_color_1;
    param_761 = _e319;
    let _e320 = sheen_roughness_1;
    param_762 = _e320;
    let _e321 = clearcoat_1;
    param_763 = _e321;
    let _e322 = clearcoat_roughness_1;
    param_764 = _e322;
    let _e323 = geomprop_Nworld_out;
    param_765 = _e323;
    let _e324 = emissive_1;
    param_766 = _e324;
    let _e325 = emissive_strength_1;
    param_767 = _e325;
    let _e326 = thickness_1;
    param_768 = _e326;
    let _e327 = attenuation_distance_1;
    param_769 = _e327;
    let _e328 = attenuation_color_1;
    param_770 = _e328;
    let _e329 = anisotropy_strength_1;
    param_771 = _e329;
    let _e330 = anisotropy_rotation_1;
    param_772 = _e330;
    let _e331 = dispersion_1;
    param_773 = _e331;
    IMPL_gltf_pbr_surfaceshader_u0028_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_i1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_745), (&param_746), (&param_747), (&param_748), (&param_749), (&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765), (&param_766), (&param_767), (&param_768), (&param_769), (&param_770), (&param_771), (&param_772), (&param_773), (&param_774));
    let _e332 = param_774;
    SR_carpaint_out = _e332;
    let _e334 = SR_carpaint_out.color;
    mtlxRasterOut_2 = vec4<f32>(_e334.x, _e334.y, _e334.z, 1f);
    let _e339 = mtlxRasterOut_2;
    return _e339;
}

fn mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b(pW_1: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e270 = mtlxRasterMain_u0028_();
    return _e270.xyz;
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, rndSeed: ptr<function, u32>) {
    return;
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e268 = (*vWorld);
    let _e270 = (*basis_2).tW;
    let _e272 = (*vWorld);
    let _e274 = (*basis_2).bW;
    let _e276 = (*vWorld);
    let _e278 = (*basis_2).nW;
    return vec3<f32>(dot(_e268, _e270), dot(_e272, _e274), dot(_e276, _e278));
}

fn safe_normalize_u0028_vf3_u003b(N_14: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e268 = (*N_14);
    l = length(_e268);
    let _e270 = (*N_14);
    let _e271 = l;
    return (_e270 / vec3(max(_e271, 0.0000000001f)));
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, bW: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>) -> Basis {
    var basis_3: Basis;
    var param_775: vec3<f32>;
    var param_776: vec3<f32>;
    var param_777: vec3<f32>;

    let _e275 = (*nW);
    param_775 = _e275;
    let _e276 = safe_normalize_u0028_vf3_u003b((&param_775));
    basis_3.nW = _e276;
    let _e278 = (*tW);
    param_776 = _e278;
    let _e279 = safe_normalize_u0028_vf3_u003b((&param_776));
    basis_3.tW = _e279;
    let _e281 = (*bW);
    param_777 = _e281;
    let _e282 = safe_normalize_u0028_vf3_u003b((&param_777));
    basis_3.bW = _e282;
    let _e284 = (*baryCoord);
    basis_3.baryCoord = _e284;
    let _e286 = (*texCoord);
    basis_3.texCoord = _e286;
    let _e288 = basis_3;
    return _e288;
}

fn skyRadiance_u0028_vf3_u003b(woutputW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e269 = (*woutputW)[0u];
    let _e270 = (*woutputW);
    let _e271 = _e270.yz;
    let _e275 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e269, _e271.x, _e271.y), 0f);
    env = _e275;
    let _e276 = env;
    let _e279 = unnamed.skyPower;
    let _e282 = unnamed.skyColor;
    return ((_e276.xyz * _e279) * _e282);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max: f32;

    let _e269 = unnamed.sunAngularSize;
    theta_max = ((_e269 * 3.1415927f) / 180f);
    let _e272 = (*woutputW_1);
    let _e274 = unnamed.sunDir;
    let _e276 = theta_max;
    if (dot(_e272, _e274) < cos(_e276)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e280 = unnamed.sunPower;
    let _e282 = unnamed.sunColor;
    return (_e282 * _e280);
}

fn normalToTangent_u0028_vf3_u003b(N_15: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_778: vec3<f32>;

    let _e270 = (*N_15)[2u];
    let _e273 = (*N_15)[0u];
    if (abs(_e270) < abs(_e273)) {
        let _e277 = (*N_15)[2u];
        let _e279 = (*N_15)[0u];
        T = vec3<f32>(_e277, 0f, -(_e279));
    } else {
        let _e283 = (*N_15)[2u];
        let _e285 = (*N_15)[1u];
        T = vec3<f32>(0f, _e283, -(_e285));
    }
    let _e288 = T;
    param_778 = _e288;
    let _e289 = safe_normalize_u0028_vf3_u003b((&param_778));
    T = _e289;
    let _e290 = T;
    return _e290;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e270 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e270).x;
    let _e273 = (*index);
    let _e274 = width;
    let _e282 = (*index);
    let _e283 = width;
    let _e286 = textureLoad(texture, vec2<i32>((_e273 - (i32(floor((f32(_e273) / f32(_e274)))) * _e274)), (_e282 / _e283)), 0i);
    return _e286;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_779: i32;
    var param_780: i32;
    var param_781: i32;

    let _e274 = (*barycoord)[0u];
    let _e276 = (*faceIndices)[0u];
    param_779 = bitcast<i32>(_e276);
    let _e278 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_779));
    let _e281 = (*barycoord)[1u];
    let _e283 = (*faceIndices)[1u];
    param_780 = bitcast<i32>(_e283);
    let _e285 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_780));
    let _e289 = (*barycoord)[2u];
    let _e291 = (*faceIndices)[2u];
    param_781 = bitcast<i32>(_e291);
    let _e293 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_781));
    return (((_e278 * _e274) + (_e285 * _e281)) + (_e293 * _e289));
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

    let _e278 = (*direction);
    inverseDirection = (vec3(1f) / _e278);
    let _e281 = (*minimum);
    let _e282 = (*origin);
    let _e284 = inverseDirection;
    t0_2 = ((_e281 - _e282) * _e284);
    let _e286 = (*maximum);
    let _e287 = (*origin);
    let _e289 = inverseDirection;
    t1_2 = ((_e286 - _e287) * _e289);
    let _e291 = t0_2;
    let _e292 = t1_2;
    entry = min(_e291, _e292);
    let _e294 = t0_2;
    let _e295 = t1_2;
    exit = max(_e294, _e295);
    let _e298 = entry[0u];
    let _e300 = entry[1u];
    let _e302 = entry[2u];
    nearDistance = max(_e298, max(_e300, _e302));
    let _e306 = exit[0u];
    let _e308 = exit[1u];
    let _e310 = exit[2u];
    farDistance = min(_e306, min(_e308, _e310));
    let _e313 = farDistance;
    let _e314 = nearDistance;
    if (_e313 >= max(_e314, 0f)) {
        let _e317 = nearDistance;
        local_10 = max(_e317, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e319 = local_10;
    return _e319;
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
    var phi_1048_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e319 = (*maxDistance);
    closest = _e319;
    found = false;
    loop {
        let _e320 = pointer;
        let _e322 = pointer;
        if ((_e320 >= 0i) && (_e322 < 64i)) {
            let _e325 = pointer;
            pointer = (_e325 - 1i);
            let _e328 = stack[_e325];
            nodeIndex = _e328;
            let _e329 = nodeIndex;
            param_782 = (_e329 * 3i);
            let _e331 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_782));
            minimum_1 = _e331;
            let _e332 = nodeIndex;
            param_783 = ((_e332 * 3i) + 1i);
            let _e335 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_783));
            maximum_1 = _e335;
            let _e336 = nodeIndex;
            param_784 = ((_e336 * 3i) + 2i);
            let _e339 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_784));
            metadata = _e339;
            let _e340 = minimum_1;
            param_785 = _e340.xyz;
            let _e342 = maximum_1;
            param_786 = _e342.xyz;
            let _e344 = (*rayOrigin);
            param_787 = _e344;
            let _e345 = (*rayDirection);
            param_788 = _e345;
            let _e346 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_785), (&param_786), (&param_787), (&param_788));
            let _e347 = closest;
            if (_e346 > _e347) {
                continue;
            }
            let _e350 = metadata[2u];
            if (_e350 > 0.5f) {
                let _e353 = metadata[0u];
                offset = i32((_e353 + 0.5f));
                let _e357 = metadata[1u];
                count = i32((_e357 + 0.5f));
                triangle = 0i;
                loop {
                    let _e360 = triangle;
                    let _e361 = count;
                    if (_e360 < _e361) {
                        let _e363 = offset;
                        let _e364 = triangle;
                        param_789 = (_e363 + _e364);
                        let _e366 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_789));
                        vertexIndices = vec3<u32>((_e366.xyz + vec3(0.5f)));
                        let _e372 = vertexIndices[0u];
                        param_790 = bitcast<i32>(_e372);
                        let _e374 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_790));
                        p0_ = _e374.xyz;
                        let _e377 = vertexIndices[1u];
                        param_791 = bitcast<i32>(_e377);
                        let _e379 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_791));
                        p1_ = _e379.xyz;
                        let _e382 = vertexIndices[2u];
                        param_792 = bitcast<i32>(_e382);
                        let _e384 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_792));
                        p2_ = _e384.xyz;
                        let _e386 = p1_;
                        let _e387 = p0_;
                        edge0_ = (_e386 - _e387);
                        let _e389 = p2_;
                        let _e390 = p0_;
                        edge1_ = (_e389 - _e390);
                        let _e392 = (*rayDirection);
                        let _e393 = edge1_;
                        pvec = cross(_e392, _e393);
                        let _e395 = edge0_;
                        let _e396 = pvec;
                        determinant_ = dot(_e395, _e396);
                        let _e398 = determinant_;
                        if (abs(_e398) < 0.00000001f) {
                            continue;
                        }
                        let _e401 = determinant_;
                        inverseDeterminant = (1f / _e401);
                        let _e403 = (*rayOrigin);
                        let _e404 = p0_;
                        tvec = (_e403 - _e404);
                        let _e406 = tvec;
                        let _e407 = pvec;
                        let _e409 = inverseDeterminant;
                        u = (dot(_e406, _e407) * _e409);
                        let _e411 = tvec;
                        let _e412 = edge0_;
                        qvec = cross(_e411, _e412);
                        let _e414 = (*rayDirection);
                        let _e415 = qvec;
                        let _e417 = inverseDeterminant;
                        v_2 = (dot(_e414, _e415) * _e417);
                        let _e419 = edge1_;
                        let _e420 = qvec;
                        let _e422 = inverseDeterminant;
                        distance_ = (dot(_e419, _e420) * _e422);
                        let _e424 = u;
                        let _e426 = v_2;
                        let _e428 = ((_e424 >= 0f) && (_e426 >= 0f));
                        phi_1048_ = _e428;
                        if _e428 {
                            let _e429 = u;
                            let _e430 = v_2;
                            phi_1048_ = ((_e429 + _e430) <= 1f);
                        }
                        let _e434 = phi_1048_;
                        let _e435 = distance_;
                        let _e438 = distance_;
                        let _e439 = closest;
                        if ((_e434 && (_e435 > 0f)) && (_e438 < _e439)) {
                            let _e442 = distance_;
                            closest = _e442;
                            let _e443 = distance_;
                            (*dist) = _e443;
                            let _e444 = u;
                            let _e446 = v_2;
                            let _e448 = u;
                            let _e449 = v_2;
                            (*barycoord_1) = vec3<f32>(((1f - _e444) - _e446), _e448, _e449);
                            let _e451 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e451.x, _e451.y, _e451.z, 0u);
                            let _e456 = edge0_;
                            let _e457 = edge1_;
                            (*faceNormal) = normalize(cross(_e456, _e457));
                            let _e460 = determinant_;
                            (*side) = select(1f, -1f, (_e460 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e463 = triangle;
                        triangle = (_e463 + 1i);
                    }
                }
            } else {
                let _e466 = metadata[0u];
                left = i32((_e466 + 0.5f));
                let _e470 = metadata[1u];
                right = i32((_e470 + 0.5f));
                let _e473 = pointer;
                if ((_e473 + 2i) >= 64i) {
                    continue;
                }
                let _e476 = pointer;
                let _e477 = (_e476 + 1i);
                pointer = _e477;
                let _e478 = right;
                stack[_e477] = _e478;
                let _e480 = pointer;
                let _e481 = (_e480 + 1i);
                pointer = _e481;
                let _e482 = left;
                stack[_e481] = _e482;
            }
            continue;
        } else {
            break;
        }
    }
    let _e484 = found;
    return _e484;
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

    let _e288 = (*rayOrigin_1);
    param_793 = _e288;
    let _e289 = (*rayDirection_1);
    param_794 = _e289;
    let _e290 = (*maxDistance_1);
    param_795 = _e290;
    let _e291 = (*faceIndices_2);
    param_796 = _e291;
    let _e292 = (*faceNormal_1);
    param_797 = _e292;
    let _e293 = (*barycoord_2);
    param_798 = _e293;
    let _e294 = (*side_1);
    param_799 = _e294;
    let _e295 = (*dist_1);
    param_800 = _e295;
    let _e296 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_793), (&param_794), (&param_795), (&param_796), (&param_797), (&param_798), (&param_799), (&param_800));
    let _e297 = param_796;
    (*faceIndices_2) = _e297;
    let _e298 = param_797;
    (*faceNormal_1) = _e298;
    let _e299 = param_798;
    (*barycoord_2) = _e299;
    let _e300 = param_799;
    (*side_1) = _e300;
    let _e301 = param_800;
    (*dist_1) = _e301;
    return _e296;
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
    var phi_1299_: bool;
    var phi_1321_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e312 = (*rayOrigin_2);
    param_801 = _e312;
    let _e313 = (*rayDir);
    param_802 = _e313;
    let _e314 = (*maxDistance_2);
    param_803 = _e314;
    let _e315 = faceIndices_surface;
    param_804 = _e315;
    let _e316 = faceNormal_surface;
    param_805 = _e316;
    let _e317 = barycoord_surface;
    param_806 = _e317;
    let _e318 = side_surface;
    param_807 = _e318;
    let _e319 = dist_surface;
    param_808 = _e319;
    let _e320 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_801), (&param_802), (&param_803), (&param_804), (&param_805), (&param_806), (&param_807), (&param_808));
    let _e321 = param_804;
    faceIndices_surface = _e321;
    let _e322 = param_805;
    faceNormal_surface = _e322;
    let _e323 = param_806;
    barycoord_surface = _e323;
    let _e324 = param_807;
    side_surface = _e324;
    let _e325 = param_808;
    dist_surface = _e325;
    hit_surface = _e320;
    dist_closest = 100000000000000000000f;
    let _e326 = hit_surface;
    if _e326 {
        let _e327 = dist_closest;
        let _e328 = dist_surface;
        dist_closest = min(_e327, _e328);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e331 = (*rayDir)[1u];
    if (abs(_e331) > 0.0000000001f) {
        let _e335 = (*rayOrigin_2)[1u];
        let _e338 = (*rayDir)[1u];
        t = ((0.01f - _e335) / _e338);
        let _e340 = t;
        let _e341 = (_e340 > 0f);
        phi_1299_ = _e341;
        if _e341 {
            let _e342 = t;
            let _e343 = dist_closest;
            let _e344 = (*maxDistance_2);
            phi_1299_ = (_e342 < min(_e343, _e344));
        }
        let _e348 = phi_1299_;
        if _e348 {
            let _e349 = t;
            dist_ground = _e349;
            hit_ground = true;
        }
    }
    let _e350 = hit_surface;
    let _e351 = hit_ground;
    hit = (_e350 || _e351);
    let _e353 = hit;
    if !(_e353) {
        return false;
    }
    let _e355 = hit_surface;
    phi_1321_ = _e355;
    if _e355 {
        let _e356 = hit_ground;
        let _e358 = dist_surface;
        let _e359 = dist_ground;
        phi_1321_ = (!(_e356) || (_e358 <= _e359));
    }
    let _e363 = phi_1321_;
    if _e363 {
        let _e364 = (*rayOrigin_2);
        let _e365 = dist_surface;
        let _e366 = (*rayDir);
        (*P_2) = (_e364 + (_e366 * _e365));
        let _e369 = barycoord_surface;
        (*baryCoord_1) = _e369;
        let _e370 = faceNormal_surface;
        param_809 = _e370;
        let _e371 = safe_normalize_u0028_vf3_u003b((&param_809));
        (*Ng) = _e371;
        let _e372 = barycoord_surface;
        param_810 = _e372;
        let _e373 = faceIndices_surface;
        param_811 = _e373.xyz;
        let _e375 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_810), (&param_811));
        gN = _e375;
        let _e376 = barycoord_surface;
        param_812 = _e376;
        let _e377 = faceIndices_surface;
        param_813 = _e377.xyz;
        let _e379 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_812), (&param_813));
        gT = _e379;
        let _e380 = barycoord_surface;
        param_814 = _e380;
        let _e381 = faceIndices_surface;
        param_815 = _e381.xyz;
        let _e383 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_814), (&param_815));
        gS = _e383;
        let _e385 = unnamed.has_normals_surface;
        if (_e385 != 0u) {
            let _e387 = gN;
            local_11 = _e387.xyz;
        } else {
            let _e389 = (*Ng);
            local_11 = _e389;
        }
        let _e390 = local_11;
        (*Ns) = _e390;
        let _e392 = unnamed.has_uvs_surface;
        if (_e392 != 0u) {
            let _e395 = gN[3u];
            let _e397 = gT[3u];
            local_12 = vec2<f32>(_e395, _e397);
        } else {
            let _e399 = barycoord_surface;
            local_12 = _e399.xy;
        }
        let _e401 = local_12;
        (*texCoord_1) = _e401;
        let _e403 = unnamed.has_tangents_surface;
        if (_e403 != 0u) {
            let _e405 = gT;
            local_13 = _e405.xyz;
        } else {
            let _e407 = (*Ns);
            param_816 = _e407;
            let _e408 = normalToTangent_u0028_vf3_u003b((&param_816));
            local_13 = _e408;
        }
        let _e409 = local_13;
        (*Ts) = _e409;
        let _e410 = (*Ns);
        param_817 = _e410;
        let _e411 = safe_normalize_u0028_vf3_u003b((&param_817));
        let _e412 = (*Ts);
        param_818 = _e412;
        let _e413 = safe_normalize_u0028_vf3_u003b((&param_818));
        (*Bs) = cross(_e411, _e413);
        let _e416 = gS[0u];
        (*material) = select(1i, 0i, (_e416 > 0.5f));
    } else {
        let _e419 = hit_ground;
        if _e419 {
            let _e420 = (*rayOrigin_2);
            let _e421 = dist_ground;
            let _e422 = (*rayDir);
            (*P_2) = (_e420 + (_e422 * _e421));
            (*material) = 2i;
            (*baryCoord_1) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e425 = (*Ng);
            (*Ns) = _e425;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            (*Bs) = vec3<f32>(0f, 0f, -1f);
            let _e427 = (*P_2)[0u];
            let _e429 = (*P_2)[2u];
            (*texCoord_1) = (((vec2<f32>(_e427, -(_e429)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_4: Basis;
    var param_819: vec3<f32>;
    var param_820: vec3<f32>;

    let _e270 = (*nW_1);
    param_819 = _e270;
    let _e271 = safe_normalize_u0028_vf3_u003b((&param_819));
    basis_4.nW = _e271;
    let _e273 = (*nW_1);
    param_820 = _e273;
    let _e274 = normalToTangent_u0028_vf3_u003b((&param_820));
    basis_4.tW = _e274;
    let _e277 = basis_4.nW;
    let _e279 = basis_4.tW;
    basis_4.bW = cross(_e277, _e279);
    basis_4.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_4.texCoord = vec2<f32>(0f, 0f);
    let _e284 = basis_4;
    return _e284;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_3: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e276 = (*cameraWorld);
    lookDirection = (_e276 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e278 = (*inverseProjection);
    nearVector = (_e278 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e281 = nearVector[2u];
    let _e283 = nearVector[3u];
    nearDistance_1 = abs((_e281 / _e283));
    let _e286 = (*cameraWorld);
    origin_1 = (_e286 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e288 = (*inverseProjection);
    let _e289 = (*coordinate);
    direction_1 = (_e288 * vec4<f32>(_e289.x, _e289.y, 0.5f, 1f));
    let _e295 = direction_1[3u];
    let _e296 = direction_1;
    direction_1 = (_e296 / vec4(_e295));
    let _e299 = (*cameraWorld);
    let _e300 = direction_1;
    let _e302 = origin_1;
    direction_1 = ((_e299 * _e300) - _e302);
    let _e304 = direction_1;
    let _e306 = nearDistance_1;
    let _e308 = direction_1;
    let _e309 = lookDirection;
    let _e313 = origin_1;
    let _e315 = (_e313.xyz + ((_e304.xyz * _e306) / vec3(dot(_e308, _e309))));
    origin_1[0u] = _e315.x;
    origin_1[1u] = _e315.y;
    origin_1[2u] = _e315.z;
    let _e322 = origin_1;
    (*rayOrigin_3) = _e322.xyz;
    let _e324 = direction_1;
    (*rayDirection_2) = _e324.xyz;
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

    base_color_1 = vec3<f32>(0.05189f, 0.29606f, 0.425324f);
    metallic_1 = 0f;
    roughness_18 = 0.4f;
    occlusion_3 = 1f;
    transmission_1 = 0f;
    specular_1 = 1f;
    specular_color_1 = vec3<f32>(1f, 1f, 1f);
    ior_7 = 1.5f;
    alpha_13 = 1f;
    alpha_mode_1 = 0i;
    alpha_cutoff_1 = 0.5f;
    iridescence_1 = 0f;
    iridescence_ior_1 = 1.3f;
    iridescence_thickness_1 = 100f;
    sheen_color_1 = vec3<f32>(0f, 0f, 0f);
    sheen_roughness_1 = 0f;
    clearcoat_1 = 1f;
    clearcoat_roughness_1 = 0f;
    emissive_1 = vec3<f32>(0f, 0f, 0f);
    emissive_strength_1 = 1f;
    thickness_1 = 0f;
    attenuation_distance_1 = 0f;
    attenuation_color_1 = vec3<f32>(1f, 1f, 1f);
    anisotropy_strength_1 = 0f;
    anisotropy_rotation_1 = 0f;
    dispersion_1 = 0f;
    let _e329 = gl_FragCoord_1;
    pixel = (_e329.xy + vec2<f32>(0.5f, 0.5f));
    let _e332 = pixel;
    let _e334 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e332 / _e334) * 2f));
    let _e340 = unnamed.invModelMatrix;
    let _e342 = unnamed.cameraWorldMatrix;
    let _e344 = ndc;
    param_821 = _e344;
    param_822 = (_e340 * _e342);
    let _e346 = unnamed.invProjectionMatrix;
    param_823 = _e346;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_821), (&param_822), (&param_823), (&param_824), (&param_825));
    let _e347 = param_824;
    pW_3 = _e347;
    let _e348 = param_825;
    dW = _e348;
    let _e349 = dW;
    dW = normalize(_e349);
    let _e352 = unnamed.sunDir;
    param_826 = _e352;
    let _e353 = makeBasis_u0028_vf3_u003b((&param_826));
    sunBasis = _e353;
    let _e354 = pW_3;
    param_827 = _e354;
    let _e355 = dW;
    param_828 = _e355;
    param_829 = 100000000000000000000f;
    let _e356 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_827), (&param_828), (&param_829), (&param_830), (&param_831), (&param_832), (&param_833), (&param_834), (&param_835), (&param_836), (&param_837));
    let _e357 = param_830;
    pW_hit = _e357;
    let _e358 = param_831;
    NsW = _e358;
    let _e359 = param_832;
    NgW = _e359;
    let _e360 = param_833;
    TsW = _e360;
    let _e361 = param_834;
    BsW = _e361;
    let _e362 = param_835;
    baryCoord_2 = _e362;
    let _e363 = param_836;
    texCoord_2 = _e363;
    let _e364 = param_837;
    material_1 = _e364;
    surface_hit = _e356;
    let _e365 = surface_hit;
    if !(_e365) {
        let _e367 = dW;
        param_838 = _e367;
        let _e368 = sunRadiance_u0028_vf3_u003b((&param_838));
        let _e369 = dW;
        param_839 = _e369;
        let _e370 = skyRadiance_u0028_vf3_u003b((&param_839));
        let _e371 = (_e368 + _e370);
        mtlxFragmentColor[0u] = _e371.x;
        mtlxFragmentColor[1u] = _e371.y;
        mtlxFragmentColor[2u] = _e371.z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    let _e379 = NsW;
    let _e380 = dW;
    if (dot(_e379, _e380) > 0f) {
        let _e383 = NsW;
        NsW = (_e383 * -1f);
    }
    let _e385 = NgW;
    let _e386 = NsW;
    if (dot(_e385, _e386) < 0f) {
        let _e389 = NgW;
        NgW = (_e389 * -1f);
    }
    let _e392 = unnamed.smooth_normals;
    if (_e392 != 0u) {
        let _e394 = NsW;
        param_840 = _e394;
        let _e395 = TsW;
        param_841 = _e395;
        let _e396 = BsW;
        param_842 = _e396;
        let _e397 = baryCoord_2;
        param_843 = _e397;
        let _e398 = texCoord_2;
        param_844 = _e398;
        let _e399 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_840), (&param_841), (&param_842), (&param_843), (&param_844));
        basis_5 = _e399;
    } else {
        let _e400 = NgW;
        param_845 = _e400;
        let _e401 = TsW;
        param_846 = _e401;
        let _e402 = BsW;
        param_847 = _e402;
        let _e403 = baryCoord_2;
        param_848 = _e403;
        let _e404 = texCoord_2;
        param_849 = _e404;
        let _e405 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_845), (&param_846), (&param_847), (&param_848), (&param_849));
        basis_5 = _e405;
    }
    let _e406 = dW;
    winputW = -(_e406);
    let _e408 = winputW;
    param_850 = _e408;
    let _e409 = basis_5;
    param_851 = _e409;
    let _e410 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_850), (&param_851));
    winputL_2 = _e410;
    let _e412 = winputL_2[2u];
    if (abs(_e412) < 0.001f) {
        mtlxFragmentColor[0u] = vec3<f32>(0f, 0f, 0f).x;
        mtlxFragmentColor[1u] = vec3<f32>(0f, 0f, 0f).y;
        mtlxFragmentColor[2u] = vec3<f32>(0f, 0f, 0f).z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    rndSeed_1 = 0u;
    let _e422 = material_1;
    if (_e422 == 1i) {
        let _e424 = pW_hit;
        param_852 = _e424;
        let _e425 = basis_5;
        param_853 = _e425;
        let _e426 = winputL_2;
        param_854 = _e426;
        let _e427 = rndSeed_1;
        param_855 = _e427;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_852), (&param_853), (&param_854), (&param_855));
        let _e428 = param_855;
        rndSeed_1 = _e428;
    }
    let _e429 = dW;
    let _e431 = basis_5.nW;
    viewReflectW = reflect(_e429, _e431);
    let _e433 = viewReflectW;
    param_856 = _e433;
    let _e434 = basis_5;
    param_857 = _e434;
    let _e435 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_856), (&param_857));
    viewReflectL = _e435;
    let _e437 = viewReflectL[2u];
    if (_e437 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e439 = material_1;
    if (_e439 == 1i) {
        let _e441 = pW_hit;
        param_858 = _e441;
        let _e442 = basis_5;
        param_859 = _e442;
        let _e443 = winputL_2;
        param_860 = _e443;
        let _e444 = viewReflectL;
        param_861 = _e444;
        let _e445 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_858), (&param_859), (&param_860), (&param_861));
        L_8 = _e445;
    } else {
        let _e446 = material_1;
        if (_e446 == 2i) {
            let _e448 = pW_hit;
            param_862 = _e448;
            let _e449 = ground_albedo_u0028_vf3_u003b((&param_862));
            L_8 = _e449;
        } else {
            let _e451 = unnamed.neutral_color;
            let _e453 = basis_5.nW;
            param_863 = _e453;
            let _e454 = skyRadiance_u0028_vf3_u003b((&param_863));
            L_8 = (_e451 * _e454);
        }
    }
    let _e456 = L_8;
    let _e458 = unnamed.firefly_clamp;
    let _e460 = clamp(_e456, vec3<f32>(0f, 0f, 0f), vec3(_e458));
    mtlxFragmentColor[0u] = _e460.x;
    mtlxFragmentColor[1u] = _e460.y;
    mtlxFragmentColor[2u] = _e460.z;
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
