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

    let _e285 = (*pW)[0u];
    let _e287 = (*pW)[2u];
    uv = (((vec2<f32>(_e285, -(_e287)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e295 = uv;
    let _e296 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e295, 0.0);
    return _e296.xyz;
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e287 = (*bg);
    let _e288 = (*fg);
    let _e289 = (*mixValue);
    (*result) = mix(_e287, _e288, vec3(_e289));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e287 = (*cosTheta);
    x = clamp((1f - _e287), 0f, 1f);
    let _e290 = (*F0_);
    let _e291 = (*F90_);
    let _e292 = x;
    let _e293 = (*exponent);
    return mix(_e290, _e291, vec3(pow(_e292, _e293)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e285 = (*N);
    let _e286 = (*V);
    if (dot(_e285, _e286) < 0f) {
        let _e289 = (*N);
        local = -(_e289);
    } else {
        let _e291 = (*N);
        local = _e291;
    }
    let _e292 = local;
    return _e292;
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

    let _e298 = (*closureData_1).closureType;
    if (_e298 == 4i) {
        let _e301 = (*closureData_1).N;
        param = _e301;
        let _e303 = (*closureData_1).V;
        param_1 = _e303;
        let _e304 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param), (&param_1));
        N_1 = _e304;
        let _e305 = N_1;
        let _e307 = (*closureData_1).V;
        NdotV = clamp(dot(_e305, _e307), 0.00000001f, 1f);
        let _e310 = NdotV;
        param_2 = _e310;
        let _e311 = (*color0_);
        param_3 = _e311;
        let _e312 = (*color90_);
        param_4 = _e312;
        let _e313 = (*exponent_1);
        param_5 = _e313;
        let _e314 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_2), (&param_3), (&param_4), (&param_5));
        f = _e314;
        let _e315 = (*base);
        let _e316 = f;
        (*result_1) = (_e315 * _e316);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e286 = (*in1_);
    let _e287 = (*in2_);
    (*result_2) = (_e286 * _e287);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e286 = (*closureData_3).closureType;
    if (_e286 == 4i) {
        let _e288 = (*color);
        (*result_3) = _e288;
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_4: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e287 = (*in2_1);
    tint = clamp(_e287, vec3(0f), vec3(1f));
    let _e292 = (*in1_1).response;
    let _e293 = tint;
    (*result_4).response = (_e292 * _e293);
    let _e297 = (*in1_1).throughput;
    (*result_4).throughput = _e297;
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_5: ptr<function, BSDF>) {
    let _e287 = (*top).response;
    let _e289 = (*base_1).response;
    let _e291 = (*top).throughput;
    (*result_5).response = (_e287 + (_e289 * _e291));
    let _e296 = (*top).throughput;
    let _e298 = (*base_1).throughput;
    (*result_5).throughput = (_e296 * _e298);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e286 = (*dir)[1u];
    latitude = ((-(asin(_e286)) * 0.31830987f) + 0.5f);
    let _e292 = (*dir)[0u];
    let _e294 = (*dir)[2u];
    longitude = (((atan2(_e292, -(_e294)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e300 = longitude;
    let _e301 = latitude;
    return vec2<f32>(_e300, _e301);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e284 = (*m);
    let _e285 = (*v);
    return (_e284 * _e285);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_6: mat4x4<f32>;
    var param_7: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_8: vec3<f32>;

    let _e290 = (*dir_1);
    let _e295 = (*transform);
    param_6 = _e295;
    param_7 = vec4<f32>(_e290.x, _e290.y, _e290.z, 0f);
    let _e296 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_6), (&param_7));
    envDir = normalize(_e296.xyz);
    let _e299 = envDir;
    param_8 = _e299;
    let _e300 = mx_latlong_projection_u0028_vf3_u003b((&param_8));
    uv_1 = _e300;
    let _e301 = uv_1;
    let _e302 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e301, 0.0);
    return _e302.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e285 = a;
    c = cos(_e285);
    let _e287 = a;
    s = sin(_e287);
    let _e289 = c;
    let _e290 = s;
    let _e292 = s;
    let _e293 = c;
    return mat4x4<f32>(vec4<f32>(_e289, 0f, -(_e290), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e292, 0f, _e293, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_9: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: f32;

    let _e287 = mtlxEnvMatrix_u0028_();
    let _e288 = (*N_2);
    param_9 = _e288;
    param_10 = _e287;
    param_11 = 0f;
    let _e289 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_9), (&param_10), (&param_11));
    Li = _e289;
    let _e290 = Li;
    let _e292 = unnamed.skyPower;
    return (_e290 * _e292);
}

fn mx_square_u0028_f1_u003b(x_1: ptr<function, f32>) -> f32 {
    let _e283 = (*x_1);
    let _e284 = (*x_1);
    return (_e283 * _e284);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_12: f32;

    let _e286 = (*roughness);
    let _e289 = (*NdotV_1);
    let _e291 = (*roughness);
    let _e294 = (*roughness);
    param_12 = _e294;
    let _e295 = mx_square_u0028_f1_u003b((&param_12));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e286)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e289) * _e291)) + (vec2<f32>(1.4385f, 2.0315f) * _e295));
    let _e299 = r[0u];
    let _e301 = r[1u];
    return (_e299 / _e301);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_13: f32;
    var param_14: f32;

    let _e287 = (*NdotV_2);
    param_13 = _e287;
    let _e288 = (*roughness_1);
    param_14 = _e288;
    let _e289 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_13), (&param_14));
    dirAlbedo = _e289;
    let _e290 = dirAlbedo;
    return clamp(_e290, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e283 = (*x_2);
    let _e284 = (*x_2);
    return (_e283 * _e284);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e284 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e284)));
    let _e288 = A;
    let _e289 = (*roughness_2);
    return (_e288 * (1f + (0.07248821f * _e289)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_15: f32;
    var G: f32;

    let _e289 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e289)));
    let _e293 = (*roughness_3);
    let _e294 = A_1;
    B = (_e293 * _e294);
    let _e296 = (*cosTheta_1);
    param_15 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_15));
    Si = sqrt(max(0f, (1f - _e297)));
    let _e301 = Si;
    let _e302 = (*cosTheta_1);
    let _e305 = Si;
    let _e306 = (*cosTheta_1);
    let _e310 = Si;
    let _e311 = (*cosTheta_1);
    let _e313 = Si;
    let _e314 = Si;
    let _e316 = Si;
    let _e320 = Si;
    G = ((_e301 * (acos(clamp(_e302, -1f, 1f)) - (_e305 * _e306))) + ((2f * (((_e310 / _e311) * (1f - ((_e313 * _e314) * _e316))) - _e320)) / 3f));
    let _e325 = A_1;
    let _e326 = B;
    let _e327 = G;
    return (_e325 + ((_e326 * _e327) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_16: f32;
    var param_17: f32;
    var avgAlbedo: f32;
    var param_18: f32;
    var colorMultiScatter: vec3<f32>;
    var param_19: vec3<f32>;

    let _e292 = (*cosTheta_2);
    param_16 = _e292;
    let _e293 = (*roughness_4);
    param_17 = _e293;
    let _e294 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_16), (&param_17));
    dirAlbedo_1 = _e294;
    let _e295 = (*roughness_4);
    param_18 = _e295;
    let _e296 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_18));
    avgAlbedo = _e296;
    let _e297 = (*color_1);
    param_19 = _e297;
    let _e298 = mx_square_u0028_vf3_u003b((&param_19));
    let _e299 = avgAlbedo;
    let _e301 = (*color_1);
    let _e302 = avgAlbedo;
    colorMultiScatter = ((_e298 * _e299) / (vec3<f32>(1f, 1f, 1f) - (_e301 * max(0f, (1f - _e302)))));
    let _e308 = colorMultiScatter;
    let _e309 = (*color_1);
    let _e310 = dirAlbedo_1;
    return mix(_e308, _e309, vec3(_e310));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_20: f32;
    var A_2: f32;
    var B_1: f32;

    let _e293 = (*LdotV);
    let _e294 = (*NdotL);
    let _e295 = (*NdotV_3);
    s_1 = (_e293 - (_e294 * _e295));
    let _e298 = s_1;
    if (_e298 > 0f) {
        let _e300 = s_1;
        let _e301 = (*NdotL);
        let _e302 = (*NdotV_3);
        local_1 = (_e300 / max(_e301, _e302));
    } else {
        local_1 = 0f;
    }
    let _e305 = local_1;
    stinv = _e305;
    let _e306 = (*roughness_5);
    param_20 = _e306;
    let _e307 = mx_square_u0028_f1_u003b((&param_20));
    sigma2_ = _e307;
    let _e308 = sigma2_;
    let _e309 = sigma2_;
    A_2 = (1f - (0.5f * (_e308 / (_e309 + 0.33f))));
    let _e314 = sigma2_;
    let _e316 = sigma2_;
    B_1 = ((0.45f * _e314) / (_e316 + 0.09f));
    let _e319 = A_2;
    let _e320 = B_1;
    let _e321 = stinv;
    return (_e319 + (_e320 * _e321));
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

    let _e303 = (*LdotV_1);
    let _e304 = (*NdotL_1);
    let _e305 = (*NdotV_4);
    s_2 = (_e303 - (_e304 * _e305));
    let _e308 = s_2;
    if (_e308 > 0f) {
        let _e310 = s_2;
        let _e311 = (*NdotL_1);
        let _e312 = (*NdotV_4);
        local_2 = (_e310 / max(_e311, _e312));
    } else {
        let _e315 = s_2;
        local_2 = _e315;
    }
    let _e316 = local_2;
    stinv_1 = _e316;
    let _e317 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e317)));
    let _e321 = (*color_2);
    let _e322 = A_3;
    let _e324 = (*roughness_6);
    let _e325 = stinv_1;
    lobeSingleScatter = ((_e321 * _e322) * (1f + (_e324 * _e325)));
    let _e329 = (*NdotV_4);
    param_21 = _e329;
    let _e330 = (*roughness_6);
    param_22 = _e330;
    let _e331 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_21), (&param_22));
    dirAlbedoV = _e331;
    let _e332 = (*NdotL_1);
    param_23 = _e332;
    let _e333 = (*roughness_6);
    param_24 = _e333;
    let _e334 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_23), (&param_24));
    dirAlbedoL = _e334;
    let _e335 = (*roughness_6);
    param_25 = _e335;
    let _e336 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_25));
    avgAlbedo_1 = _e336;
    let _e337 = (*color_2);
    param_26 = _e337;
    let _e338 = mx_square_u0028_vf3_u003b((&param_26));
    let _e339 = avgAlbedo_1;
    let _e341 = (*color_2);
    let _e342 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e338 * _e339) / (vec3<f32>(1f, 1f, 1f) - (_e341 * max(0f, (1f - _e342)))));
    let _e348 = colorMultiScatter_1;
    let _e349 = dirAlbedoV;
    let _e353 = dirAlbedoL;
    let _e357 = avgAlbedo_1;
    lobeMultiScatter = (((_e348 * max(0.00000001f, (1f - _e349))) * max(0.00000001f, (1f - _e353))) / vec3(max(0.00000001f, (1f - _e357))));
    let _e362 = lobeSingleScatter;
    let _e363 = lobeMultiScatter;
    return (_e362 + _e363);
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
    let _e317 = (*weight);
    if (_e317 < 0.00000001f) {
        return;
    }
    let _e320 = (*closureData_6).V;
    V_1 = _e320;
    let _e322 = (*closureData_6).L;
    L = _e322;
    let _e323 = (*N_3);
    param_27 = _e323;
    let _e324 = V_1;
    param_28 = _e324;
    let _e325 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_27), (&param_28));
    (*N_3) = _e325;
    let _e326 = (*N_3);
    let _e327 = V_1;
    NdotV_5 = clamp(dot(_e326, _e327), 0.00000001f, 1f);
    let _e331 = (*closureData_6).closureType;
    if (_e331 == 1i) {
        let _e333 = (*N_3);
        let _e334 = L;
        NdotL_2 = clamp(dot(_e333, _e334), 0.00000001f, 1f);
        let _e337 = L;
        let _e338 = V_1;
        LdotV_2 = clamp(dot(_e337, _e338), 0.00000001f, 1f);
        let _e341 = (*energy_compensation);
        if _e341 {
            let _e342 = NdotV_5;
            param_29 = _e342;
            let _e343 = NdotL_2;
            param_30 = _e343;
            let _e344 = LdotV_2;
            param_31 = _e344;
            let _e345 = (*roughness_7);
            param_32 = _e345;
            let _e346 = (*color_3);
            param_33 = _e346;
            let _e347 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_29), (&param_30), (&param_31), (&param_32), (&param_33));
            local_3 = _e347;
        } else {
            let _e348 = NdotV_5;
            param_34 = _e348;
            let _e349 = NdotL_2;
            param_35 = _e349;
            let _e350 = LdotV_2;
            param_36 = _e350;
            let _e351 = (*roughness_7);
            param_37 = _e351;
            let _e352 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_34), (&param_35), (&param_36), (&param_37));
            let _e353 = (*color_3);
            local_3 = (_e353 * _e352);
        }
        let _e355 = local_3;
        diffuse = _e355;
        let _e356 = diffuse;
        let _e358 = (*closureData_6).occlusion;
        let _e360 = (*weight);
        let _e362 = NdotL_2;
        (*bsdf).response = ((((_e356 * _e358) * _e360) * _e362) * 0.31830987f);
    } else {
        let _e367 = (*closureData_6).closureType;
        if (_e367 == 3i) {
            let _e369 = (*energy_compensation);
            if _e369 {
                let _e370 = NdotV_5;
                param_38 = _e370;
                let _e371 = (*roughness_7);
                param_39 = _e371;
                let _e372 = (*color_3);
                param_40 = _e372;
                let _e373 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_38), (&param_39), (&param_40));
                local_4 = _e373;
            } else {
                let _e374 = NdotV_5;
                param_41 = _e374;
                let _e375 = (*roughness_7);
                param_42 = _e375;
                let _e376 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_41), (&param_42));
                let _e377 = (*color_3);
                local_4 = (_e377 * _e376);
            }
            let _e379 = local_4;
            diffuse_1 = _e379;
            let _e380 = (*N_3);
            param_43 = _e380;
            let _e381 = mx_environment_irradiance_u0028_vf3_u003b((&param_43));
            Li_1 = _e381;
            let _e382 = Li_1;
            let _e383 = diffuse_1;
            let _e385 = (*weight);
            (*bsdf).response = ((_e382 * _e383) * _e385);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_6: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e287 = (*in2_2);
    weight_1 = clamp(_e287, 0f, 1f);
    let _e290 = (*in1_2).response;
    let _e291 = weight_1;
    (*result_6).response = (_e290 * _e291);
    let _e295 = (*in1_2).throughput;
    (*result_6).throughput = _e295;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_7: ptr<function, BSDF>) {
    let _e287 = (*in1_3).response;
    let _e289 = (*in2_3).response;
    (*result_7).response = (_e287 + _e289);
    let _e293 = (*in1_3).throughput;
    let _e295 = (*in2_3).throughput;
    (*result_7).throughput = max(((_e293 + _e295) - vec3(1f)), vec3(0f));
    return;
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e287 = (*shape);
    let _e289 = (*dist);
    num1_ = exp((-(_e287) * _e289));
    let _e292 = (*shape);
    let _e294 = (*dist);
    num2_ = exp(((-(_e292) * _e294) / vec3(3f)));
    let _e299 = (*dist);
    denom = max(_e299, 0.00000001f);
    let _e301 = num1_;
    let _e302 = num2_;
    let _e304 = denom;
    return ((_e301 + _e302) / vec3(_e304));
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

    let _e296 = (*N_4);
    let _e297 = (*L_1);
    theta = acos(dot(_e296, _e297));
    let _e300 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e300, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e304 = i;
        if (_e304 < 32i) {
            let _e306 = i;
            x_3 = (-3.1415927f + ((f32(_e306) + 0.5f) * 0.19634955f));
            let _e311 = (*radius);
            let _e312 = x_3;
            dist_1 = (_e311 * abs((2f * sin((_e312 * 0.5f)))));
            let _e318 = dist_1;
            param_44 = _e318;
            let _e319 = shape_1;
            param_45 = _e319;
            let _e320 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_44), (&param_45));
            R = _e320;
            let _e321 = R;
            let _e322 = theta;
            let _e323 = x_3;
            let _e328 = sumD;
            sumD = (_e328 + (_e321 * max(cos((_e322 + _e323)), 0f)));
            let _e330 = R;
            let _e331 = sumR;
            sumR = (_e331 + _e330);
            continue;
        } else {
            break;
        }
        continuing {
            let _e333 = i;
            i = (_e333 + 1i);
        }
    }
    let _e335 = sumD;
    let _e336 = sumR;
    return (_e335 / _e336);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, L_2: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_46: vec3<f32>;
    var param_47: vec3<f32>;
    var param_48: f32;
    var param_49: vec3<f32>;

    let _e293 = (*N_5);
    let _e294 = fwidth(_e293);
    let _e296 = (*P);
    let _e297 = fwidth(_e296);
    curvature = (length(_e294) / length(_e297));
    let _e300 = curvature;
    radius_1 = (1f / max(_e300, 0.01f));
    let _e303 = (*albedo);
    let _e304 = (*N_5);
    param_46 = _e304;
    let _e305 = (*L_2);
    param_47 = _e305;
    let _e306 = radius_1;
    param_48 = _e306;
    let _e307 = (*mfp_1);
    param_49 = _e307;
    let _e308 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_46), (&param_47), (&param_48), (&param_49));
    return ((_e303 * _e308) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
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
    let _e306 = (*weight_2);
    if (_e306 < 0.00000001f) {
        return;
    }
    let _e309 = (*closureData_9).V;
    V_2 = _e309;
    let _e311 = (*closureData_9).L;
    L_3 = _e311;
    let _e313 = (*closureData_9).P;
    P_1 = _e313;
    let _e315 = (*closureData_9).occlusion;
    occlusion = _e315;
    let _e316 = (*N_6);
    param_50 = _e316;
    let _e317 = V_2;
    param_51 = _e317;
    let _e318 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_50), (&param_51));
    (*N_6) = _e318;
    let _e320 = (*closureData_9).closureType;
    if (_e320 == 1i) {
        let _e322 = (*N_6);
        param_52 = _e322;
        let _e323 = L_3;
        param_53 = _e323;
        let _e324 = P_1;
        param_54 = _e324;
        let _e325 = (*color_4);
        param_55 = _e325;
        let _e326 = (*radius_2);
        param_56 = _e326;
        let _e327 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_52), (&param_53), (&param_54), (&param_55), (&param_56));
        sss = _e327;
        let _e328 = (*N_6);
        let _e329 = L_3;
        NdotL_3 = clamp(dot(_e328, _e329), 0.00000001f, 1f);
        let _e332 = NdotL_3;
        let _e333 = occlusion;
        visibleOcclusion = (1f - (_e332 * (1f - _e333)));
        let _e337 = sss;
        let _e338 = visibleOcclusion;
        let _e340 = (*weight_2);
        (*bsdf_1).response = ((_e337 * _e338) * _e340);
    } else {
        let _e344 = (*closureData_9).closureType;
        if (_e344 == 3i) {
            let _e346 = (*N_6);
            param_57 = _e346;
            let _e347 = mx_environment_irradiance_u0028_vf3_u003b((&param_57));
            Li_2 = _e347;
            let _e348 = Li_2;
            let _e349 = (*color_4);
            let _e351 = (*weight_2);
            (*bsdf_1).response = ((_e348 * _e349) * _e351);
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
    let _e293 = (*weight_3);
    if (_e293 < 0.00000001f) {
        return;
    }
    let _e296 = (*closureData_10).V;
    V_3 = _e296;
    let _e298 = (*closureData_10).L;
    L_4 = _e298;
    let _e299 = (*N_7);
    (*N_7) = -(_e299);
    let _e302 = (*closureData_10).closureType;
    if (_e302 == 1i) {
        let _e304 = (*N_7);
        let _e305 = L_4;
        NdotL_4 = clamp(dot(_e304, _e305), 0f, 1f);
        let _e308 = (*color_5);
        let _e309 = (*weight_3);
        let _e311 = NdotL_4;
        (*bsdf_2).response = (((_e308 * _e309) * _e311) * 0.31830987f);
    } else {
        let _e316 = (*closureData_10).closureType;
        if (_e316 == 3i) {
            let _e318 = (*N_7);
            param_58 = _e318;
            let _e319 = mx_environment_irradiance_u0028_vf3_u003b((&param_58));
            Li_3 = _e319;
            let _e320 = Li_3;
            let _e321 = (*color_5);
            let _e323 = (*weight_3);
            (*bsdf_2).response = ((_e320 * _e321) * _e323);
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_4: ptr<function, f32>, y: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_1: f32;
    var o: f32;
    var param_59: f32;

    let _e288 = (*y);
    let _e289 = (*y);
    let _e293 = (*y);
    let _e294 = (*y);
    s_3 = ((_e288 * (0.0206607f + (1.58491f * _e289))) / (0.0379424f + (_e293 * (1.32227f + _e294))));
    let _e299 = (*y);
    let _e300 = (*y);
    let _e301 = (*y);
    let _e302 = (*y);
    let _e304 = (*y);
    let _e312 = (*y);
    m_1 = ((_e299 * (-0.193854f + (_e300 * (-1.14885f + (_e301 * (1.7932f - ((0.95943f * _e302) * _e304))))))) / (0.046391f + _e312));
    let _e315 = (*y);
    let _e316 = (*y);
    let _e319 = (*y);
    let _e323 = (*y);
    let _e324 = (*y);
    o = ((_e315 * (0.000654023f + ((-0.0207818f + (0.119681f * _e316)) * _e319))) / (1.26264f + (_e323 * (-1.92021f + _e324))));
    let _e329 = (*x_4);
    let _e330 = m_1;
    let _e332 = s_3;
    param_59 = ((_e329 - _e330) / _e332);
    let _e334 = mx_square_u0028_f1_u003b((&param_59));
    let _e337 = s_3;
    let _e340 = o;
    return ((exp((-0.5f * _e334)) / (_e337 * 2.5066283f)) + _e340);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_3: ptr<function, f32>) -> f32 {
    let _e283 = (*cosTheta_3);
    return (max(_e283, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_5: ptr<function, f32>, y_1: ptr<function, f32>) -> f32 {
    let _e284 = (*x_5);
    let _e287 = (*y_1);
    let _e290 = (*y_1);
    let _e292 = (*y_1);
    let _e294 = (*y_1);
    let _e296 = (*x_5);
    let _e299 = (*x_5);
    let _e301 = (*y_1);
    let _e304 = (*y_1);
    let _e306 = (*y_1);
    return (((((sqrt((1f - _e284)) * (_e287 - 1f)) * _e290) * _e292) * _e294) / (((0.0000254053f + (1.71228f * _e296)) - ((1.71506f * _e299) * _e301)) + ((1.34174f * _e304) * _e306)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    let _e284 = (*x_6);
    let _e286 = (*y_2);
    let _e289 = (*y_2);
    let _e291 = (*x_6);
    let _e293 = (*x_6);
    let _e296 = (*x_6);
    let _e298 = (*y_2);
    return ((((2.58126f * _e284) + (0.813703f * _e286)) * _e289) / ((1f + ((0.310327f * _e291) * _e293)) + ((2.60994f * _e296) * _e298)));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_2: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e284 = (*m_2);
    let _e285 = (*v_1);
    return (_e284 * _e285);
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_8: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_1: f32;
    var b: f32;
    var X: vec3<f32>;
    var Y: vec3<f32>;

    let _e289 = (*N_8)[2u];
    sign_ = select(1f, -1f, (_e289 < 0f));
    let _e292 = sign_;
    let _e294 = (*N_8)[2u];
    a_1 = (-1f / (_e292 + _e294));
    let _e298 = (*N_8)[0u];
    let _e300 = (*N_8)[1u];
    let _e302 = a_1;
    b = ((_e298 * _e300) * _e302);
    let _e304 = sign_;
    let _e306 = (*N_8)[0u];
    let _e309 = (*N_8)[0u];
    let _e311 = a_1;
    let _e314 = sign_;
    let _e315 = b;
    let _e317 = sign_;
    let _e320 = (*N_8)[0u];
    X = vec3<f32>((1f + (((_e304 * _e306) * _e309) * _e311)), (_e314 * _e315), (-(_e317) * _e320));
    let _e323 = b;
    let _e324 = sign_;
    let _e326 = (*N_8)[1u];
    let _e328 = (*N_8)[1u];
    let _e330 = a_1;
    let _e334 = (*N_8)[1u];
    Y = vec3<f32>(_e323, (_e324 + ((_e326 * _e328) * _e330)), -(_e334));
    let _e337 = X;
    let _e338 = Y;
    let _e339 = (*N_8);
    return mat3x3<f32>(vec3<f32>(_e337.x, _e337.y, _e337.z), vec3<f32>(_e338.x, _e338.y, _e338.z), vec3<f32>(_e339.x, _e339.y, _e339.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_4: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_6: ptr<function, f32>) -> mat3x3<f32> {
    var X_1: vec3<f32>;
    var lenSqr: f32;
    var Y_1: vec3<f32>;
    var param_60: vec3<f32>;

    let _e289 = (*V_4);
    let _e290 = (*N_9);
    let _e291 = (*NdotV_6);
    X_1 = (_e289 - (_e290 * _e291));
    let _e294 = X_1;
    let _e295 = X_1;
    lenSqr = dot(_e294, _e295);
    let _e297 = lenSqr;
    if (_e297 > 0f) {
        let _e299 = lenSqr;
        let _e301 = X_1;
        X_1 = (_e301 * inverseSqrt(_e299));
        let _e303 = (*N_9);
        let _e304 = X_1;
        Y_1 = cross(_e303, _e304);
        let _e306 = X_1;
        let _e307 = Y_1;
        let _e308 = (*N_9);
        return mat3x3<f32>(vec3<f32>(_e306.x, _e306.y, _e306.z), vec3<f32>(_e307.x, _e307.y, _e307.z), vec3<f32>(_e308.x, _e308.y, _e308.z));
    }
    let _e322 = (*N_9);
    param_60 = _e322;
    let _e323 = mx_orthonormal_basis_u0028_vf3_u003b((&param_60));
    return _e323;
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

    let _e304 = (*V_5);
    param_61 = _e304;
    let _e305 = (*N_10);
    param_62 = _e305;
    let _e306 = (*NdotV_7);
    param_63 = _e306;
    let _e307 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_61), (&param_62), (&param_63));
    toLTC = transpose(_e307);
    let _e309 = toLTC;
    param_64 = _e309;
    let _e310 = (*L_5);
    param_65 = _e310;
    let _e311 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_64), (&param_65));
    w = _e311;
    let _e312 = (*NdotV_7);
    param_66 = _e312;
    let _e313 = (*roughness_8);
    param_67 = _e313;
    let _e314 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_66), (&param_67));
    aInv = _e314;
    let _e315 = (*NdotV_7);
    param_68 = _e315;
    let _e316 = (*roughness_8);
    param_69 = _e316;
    let _e317 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_68), (&param_69));
    bInv = _e317;
    let _e318 = aInv;
    let _e320 = w[0u];
    let _e322 = bInv;
    let _e324 = w[2u];
    let _e327 = aInv;
    let _e329 = w[1u];
    let _e332 = w[2u];
    wo = vec3<f32>(((_e318 * _e320) + (_e322 * _e324)), (_e327 * _e329), _e332);
    let _e334 = wo;
    let _e335 = wo;
    lenSqr_1 = dot(_e334, _e335);
    let _e338 = wo[2u];
    param_70 = _e338;
    let _e339 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_70));
    let _e340 = aInv;
    let _e341 = lenSqr_1;
    param_71 = (_e340 / _e341);
    let _e343 = mx_square_u0028_f1_u003b((&param_71));
    return (_e339 * _e343);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_8: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var r_1: vec2<f32>;
    var param_72: f32;
    var param_73: f32;

    let _e287 = (*NdotV_8);
    let _e290 = (*roughness_9);
    let _e293 = (*NdotV_8);
    let _e295 = (*roughness_9);
    let _e298 = (*NdotV_8);
    param_72 = _e298;
    let _e299 = mx_square_u0028_f1_u003b((&param_72));
    let _e302 = (*roughness_9);
    param_73 = _e302;
    let _e303 = mx_square_u0028_f1_u003b((&param_73));
    r_1 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e287)) + (vec2<f32>(799.08826f, 442.7821f) * _e290)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e293) * _e295)) + (vec2<f32>(60.28956f, 121.81241f) * _e299)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e303));
    let _e307 = r_1[0u];
    let _e309 = r_1[1u];
    return (_e307 / _e309);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_9: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var dirAlbedo_2: f32;
    var param_74: f32;
    var param_75: f32;

    let _e287 = (*NdotV_9);
    param_74 = _e287;
    let _e288 = (*roughness_10);
    param_75 = _e288;
    let _e289 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_74), (&param_75));
    dirAlbedo_2 = _e289;
    let _e290 = dirAlbedo_2;
    return clamp(_e290, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e287 = (*roughness_11);
    invRoughness = (1f / max(_e287, 0.005f));
    let _e290 = (*NdotH);
    let _e291 = (*NdotH);
    cos2_ = (_e290 * _e291);
    let _e293 = cos2_;
    sin2_ = (1f - _e293);
    let _e295 = invRoughness;
    let _e297 = sin2_;
    let _e298 = invRoughness;
    return (((2f + _e295) * pow(_e297, (_e298 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_10: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var D: f32;
    var param_76: f32;
    var param_77: f32;
    var F: f32;
    var G_1: f32;

    let _e291 = (*NdotH_1);
    param_76 = _e291;
    let _e292 = (*roughness_12);
    param_77 = _e292;
    let _e293 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_76), (&param_77));
    D = _e293;
    F = 1f;
    G_1 = 1f;
    let _e294 = D;
    let _e295 = F;
    let _e297 = G_1;
    let _e299 = (*NdotL_5);
    let _e300 = (*NdotV_10);
    let _e302 = (*NdotL_5);
    let _e303 = (*NdotV_10);
    return (((_e294 * _e295) * _e297) / (4f * ((_e299 + _e300) - (_e302 * _e303))));
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

    let _e320 = (*weight_4);
    if (_e320 < 0.00000001f) {
        return;
    }
    let _e323 = (*closureData_11).V;
    V_6 = _e323;
    let _e325 = (*closureData_11).L;
    L_6 = _e325;
    let _e326 = (*N_11);
    param_78 = _e326;
    let _e327 = V_6;
    param_79 = _e327;
    let _e328 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_78), (&param_79));
    (*N_11) = _e328;
    let _e329 = (*N_11);
    let _e330 = V_6;
    NdotV_11 = clamp(dot(_e329, _e330), 0.00000001f, 1f);
    let _e334 = (*closureData_11).closureType;
    if (_e334 == 1i) {
        let _e336 = (*mode);
        if (_e336 == 0i) {
            let _e338 = L_6;
            let _e339 = V_6;
            H = normalize((_e338 + _e339));
            let _e342 = (*N_11);
            let _e343 = L_6;
            NdotL_6 = clamp(dot(_e342, _e343), 0.00000001f, 1f);
            let _e346 = (*N_11);
            let _e347 = H;
            NdotH_2 = clamp(dot(_e346, _e347), 0.00000001f, 1f);
            let _e350 = (*color_6);
            let _e351 = NdotL_6;
            param_80 = _e351;
            let _e352 = NdotV_11;
            param_81 = _e352;
            let _e353 = NdotH_2;
            param_82 = _e353;
            let _e354 = (*roughness_13);
            param_83 = _e354;
            let _e355 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_80), (&param_81), (&param_82), (&param_83));
            fr = (_e350 * _e355);
            let _e357 = NdotV_11;
            param_84 = _e357;
            let _e358 = (*roughness_13);
            param_85 = _e358;
            let _e359 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
            dirAlbedo_3 = _e359;
            let _e360 = fr;
            let _e361 = NdotL_6;
            let _e364 = (*closureData_11).occlusion;
            let _e366 = (*weight_4);
            (*bsdf_3).response = (((_e360 * _e361) * _e364) * _e366);
        } else {
            let _e369 = (*roughness_13);
            (*roughness_13) = clamp(_e369, 0.01f, 1f);
            let _e371 = (*color_6);
            let _e372 = L_6;
            param_86 = _e372;
            let _e373 = V_6;
            param_87 = _e373;
            let _e374 = (*N_11);
            param_88 = _e374;
            let _e375 = NdotV_11;
            param_89 = _e375;
            let _e376 = (*roughness_13);
            param_90 = _e376;
            let _e377 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_86), (&param_87), (&param_88), (&param_89), (&param_90));
            fr_1 = (_e371 * _e377);
            let _e379 = NdotV_11;
            param_91 = _e379;
            let _e380 = (*roughness_13);
            param_92 = _e380;
            let _e381 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_91), (&param_92));
            dirAlbedo_3 = _e381;
            let _e382 = dirAlbedo_3;
            let _e383 = fr_1;
            let _e386 = (*closureData_11).occlusion;
            let _e388 = (*weight_4);
            (*bsdf_3).response = (((_e383 * _e382) * _e386) * _e388);
        }
        let _e391 = dirAlbedo_3;
        let _e392 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e391 * _e392)));
    } else {
        let _e398 = (*closureData_11).closureType;
        if (_e398 == 3i) {
            let _e400 = (*mode);
            if (_e400 == 0i) {
                let _e402 = NdotV_11;
                param_93 = _e402;
                let _e403 = (*roughness_13);
                param_94 = _e403;
                let _e404 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_93), (&param_94));
                dirAlbedo_4 = _e404;
            } else {
                let _e405 = (*roughness_13);
                (*roughness_13) = clamp(_e405, 0.01f, 1f);
                let _e407 = NdotV_11;
                param_95 = _e407;
                let _e408 = (*roughness_13);
                param_96 = _e408;
                let _e409 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_95), (&param_96));
                dirAlbedo_4 = _e409;
            }
            let _e410 = (*N_11);
            param_97 = _e410;
            let _e411 = mx_environment_irradiance_u0028_vf3_u003b((&param_97));
            Li_4 = _e411;
            let _e412 = Li_4;
            let _e413 = (*color_6);
            let _e415 = dirAlbedo_4;
            let _e417 = (*weight_4);
            (*bsdf_3).response = (((_e412 * _e413) * _e415) * _e417);
            let _e420 = dirAlbedo_4;
            let _e421 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e420 * _e421)));
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

    let _e291 = (*alpha);
    param_98 = _e291;
    let _e292 = mx_square_u0028_f1_u003b((&param_98));
    alpha2_ = _e292;
    let _e293 = alpha2_;
    let _e294 = alpha2_;
    let _e296 = (*NdotL_7);
    param_99 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_99));
    lambdaL = sqrt((_e293 + ((1f - _e294) * _e297)));
    let _e301 = alpha2_;
    let _e302 = alpha2_;
    let _e304 = (*NdotV_12);
    param_100 = _e304;
    let _e305 = mx_square_u0028_f1_u003b((&param_100));
    lambdaV = sqrt((_e301 + ((1f - _e302) * _e305)));
    let _e309 = (*NdotL_7);
    let _e311 = (*NdotV_12);
    let _e313 = lambdaL;
    let _e314 = (*NdotV_12);
    let _e316 = lambdaV;
    let _e317 = (*NdotL_7);
    return (((2f * _e309) * _e311) / ((_e313 * _e314) + (_e316 * _e317)));
}

fn mx_pow6_u0028_f1_u003b(x_7: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_101: f32;
    var param_102: f32;

    let _e286 = (*x_7);
    param_101 = _e286;
    let _e287 = mx_square_u0028_f1_u003b((&param_101));
    x2_ = _e287;
    let _e288 = x2_;
    param_102 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_102));
    let _e290 = x2_;
    return (_e289 * _e290);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_4: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_8: f32;
    var a_2: vec3<f32>;
    var param_103: f32;

    let _e287 = (*cosTheta_4);
    x_8 = clamp(_e287, 0f, 1f);
    let _e290 = (*fd).F0_;
    let _e292 = (*fd).F90_;
    let _e294 = (*fd).exponent;
    let _e299 = (*fd).F82_;
    a_2 = ((mix(_e290, _e292, vec3(pow(0.85714287f, _e294))) * (vec3<f32>(1f, 1f, 1f) - _e299)) * 17.651384f);
    let _e304 = (*fd).F0_;
    let _e306 = (*fd).F90_;
    let _e307 = x_8;
    let _e310 = (*fd).exponent;
    let _e314 = a_2;
    let _e315 = x_8;
    let _e317 = x_8;
    param_103 = (1f - _e317);
    let _e319 = mx_pow6_u0028_f1_u003b((&param_103));
    return (mix(_e304, _e306, vec3(pow((1f - _e307), _e310))) - ((_e314 * _e315) * _e319));
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

    let _e299 = (*cosTheta_5);
    param_104 = clamp(_e299, 0f, 1f);
    let _e301 = mx_square_u0028_f1_u003b((&param_104));
    cosTheta2_ = _e301;
    let _e302 = cosTheta2_;
    sinTheta2_ = (1f - _e302);
    let _e304 = (*n);
    let _e305 = (*n);
    n2_ = (_e304 * _e305);
    let _e307 = (*k);
    let _e308 = (*k);
    k2_ = (_e307 * _e308);
    let _e310 = n2_;
    let _e311 = k2_;
    let _e313 = sinTheta2_;
    t0_ = ((_e310 - _e311) - vec3(_e313));
    let _e316 = t0_;
    let _e317 = t0_;
    let _e319 = n2_;
    let _e321 = k2_;
    a2plusb2_ = sqrt(((_e316 * _e317) + ((_e319 * 4f) * _e321)));
    let _e325 = a2plusb2_;
    let _e326 = cosTheta2_;
    t1_ = (_e325 + vec3(_e326));
    let _e329 = a2plusb2_;
    let _e330 = t0_;
    a_3 = sqrt(max(((_e329 + _e330) * 0.5f), vec3(0f)));
    let _e336 = a_3;
    let _e338 = (*cosTheta_5);
    t2_ = ((_e336 * 2f) * _e338);
    let _e340 = t1_;
    let _e341 = t2_;
    let _e343 = t1_;
    let _e344 = t2_;
    (*Rs) = ((_e340 - _e341) / (_e343 + _e344));
    let _e347 = cosTheta2_;
    let _e348 = a2plusb2_;
    let _e350 = sinTheta2_;
    let _e351 = sinTheta2_;
    t3_ = ((_e348 * _e347) + vec3((_e350 * _e351)));
    let _e355 = t2_;
    let _e356 = sinTheta2_;
    t4_ = (_e355 * _e356);
    let _e358 = (*Rs);
    let _e359 = t3_;
    let _e360 = t4_;
    let _e363 = t3_;
    let _e364 = t4_;
    (*Rp) = ((_e358 * (_e359 - _e360)) / (_e363 + _e364));
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

    let _e292 = (*cosTheta_6);
    param_105 = _e292;
    let _e293 = (*n_1);
    param_106 = _e293;
    let _e294 = (*k_1);
    param_107 = _e294;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_105), (&param_106), (&param_107), (&param_108), (&param_109));
    let _e295 = param_108;
    Rp_1 = _e295;
    let _e296 = param_109;
    Rs_1 = _e296;
    let _e297 = Rp_1;
    let _e298 = Rs_1;
    return ((_e297 + _e298) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_110: f32;
    var param_111: f32;

    let _e289 = (*cosTheta_7);
    c_1 = _e289;
    let _e290 = (*ior);
    let _e291 = (*ior);
    let _e293 = c_1;
    let _e294 = c_1;
    g2_ = (((_e290 * _e291) + (_e293 * _e294)) - 1f);
    let _e298 = g2_;
    if (_e298 < 0f) {
        return 1f;
    }
    let _e300 = g2_;
    g = sqrt(_e300);
    let _e302 = g;
    let _e303 = c_1;
    let _e305 = g;
    let _e306 = c_1;
    param_110 = ((_e302 - _e303) / (_e305 + _e306));
    let _e309 = mx_square_u0028_f1_u003b((&param_110));
    let _e311 = g;
    let _e312 = c_1;
    let _e314 = c_1;
    let _e317 = g;
    let _e318 = c_1;
    let _e320 = c_1;
    param_111 = ((((_e311 + _e312) * _e314) - 1f) / (((_e317 - _e318) * _e320) + 1f));
    let _e324 = mx_square_u0028_f1_u003b((&param_111));
    return ((0.5f * _e309) * (1f + _e324));
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e289 = (*opd);
    phase = (6.2831855f * _e289);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e291 = val;
    let _e292 = var_;
    let _e296 = pos;
    let _e297 = phase;
    let _e299 = (*shift);
    let _e303 = var_;
    let _e305 = phase;
    let _e307 = phase;
    xyz = (((_e291 * sqrt((_e292 * 6.2831855f))) * cos(((_e296 * _e297) + _e299))) * exp(((-(_e303) * _e305) * _e307)));
    let _e311 = phase;
    let _e314 = (*shift)[0u];
    let _e318 = phase;
    let _e320 = phase;
    let _e325 = xyz[0u];
    xyz[0u] = (_e325 + ((0.00000001644083f * cos(((2239900f * _e311) + _e314))) * exp(((-4528200000f * _e318) * _e320))));
    let _e328 = xyz;
    return (_e328 / vec3(0.00000010685f));
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

    let _e297 = (*kappa2_);
    let _e298 = (*eta2_);
    k2_1 = (_e297 / _e298);
    let _e300 = (*cosTheta_8);
    let _e301 = (*cosTheta_8);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e300 * _e301)));
    let _e305 = (*eta2_);
    let _e306 = (*eta2_);
    let _e308 = k2_1;
    let _e309 = k2_1;
    let _e313 = (*eta1_);
    let _e314 = (*eta1_);
    let _e316 = sinThetaSqr;
    A_4 = (((_e305 * _e306) * (vec3<f32>(1f, 1f, 1f) - (_e308 * _e309))) - (_e316 * (_e313 * _e314)));
    let _e319 = A_4;
    let _e320 = A_4;
    let _e322 = (*eta2_);
    let _e324 = (*eta2_);
    let _e326 = k2_1;
    param_112 = (((_e322 * 2f) * _e324) * _e326);
    let _e328 = mx_square_u0028_vf3_u003b((&param_112));
    B_2 = sqrt(((_e319 * _e320) + _e328));
    let _e331 = A_4;
    let _e332 = B_2;
    U = sqrt(((_e331 + _e332) / vec3(2f)));
    let _e337 = B_2;
    let _e338 = A_4;
    V_7 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e337 - _e338) / vec3(2f))));
    let _e344 = (*eta1_);
    let _e346 = V_7;
    let _e348 = (*cosTheta_8);
    let _e350 = U;
    let _e351 = U;
    let _e353 = V_7;
    let _e354 = V_7;
    let _e357 = (*eta1_);
    let _e358 = (*cosTheta_8);
    param_113 = (_e357 * _e358);
    let _e360 = mx_square_u0028_f1_u003b((&param_113));
    (*phiS) = atan2(((_e346 * (2f * _e344)) * _e348), (((_e350 * _e351) + (_e353 * _e354)) - vec3(_e360)));
    let _e364 = (*eta1_);
    let _e366 = (*eta2_);
    let _e368 = (*eta2_);
    let _e370 = (*cosTheta_8);
    let _e372 = k2_1;
    let _e374 = U;
    let _e376 = k2_1;
    let _e377 = k2_1;
    let _e380 = V_7;
    let _e384 = (*eta2_);
    let _e385 = (*eta2_);
    let _e387 = k2_1;
    let _e388 = k2_1;
    let _e392 = (*cosTheta_8);
    param_114 = (((_e384 * _e385) * (vec3<f32>(1f, 1f, 1f) + (_e387 * _e388))) * _e392);
    let _e394 = mx_square_u0028_vf3_u003b((&param_114));
    let _e395 = (*eta1_);
    let _e396 = (*eta1_);
    let _e398 = U;
    let _e399 = U;
    let _e401 = V_7;
    let _e402 = V_7;
    (*phiP) = atan2(((((_e366 * (2f * _e364)) * _e368) * _e370) * (((_e372 * 2f) * _e374) - ((vec3<f32>(1f, 1f, 1f) - (_e376 * _e377)) * _e380))), (_e394 - (((_e398 * _e399) + (_e401 * _e402)) * (_e395 * _e396))));
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

    let _e294 = (*cosTheta_9);
    param_115 = clamp(_e294, 0f, 1f);
    let _e296 = mx_square_u0028_f1_u003b((&param_115));
    cosTheta2_1 = _e296;
    let _e297 = cosTheta2_1;
    sinTheta2_1 = (1f - _e297);
    let _e299 = (*ior_1);
    let _e300 = (*ior_1);
    let _e302 = sinTheta2_1;
    t0_1 = max(((_e299 * _e300) - _e302), 0f);
    let _e305 = t0_1;
    let _e306 = cosTheta2_1;
    t1_1 = (_e305 + _e306);
    let _e308 = t0_1;
    let _e311 = (*cosTheta_9);
    t2_1 = ((2f * sqrt(_e308)) * _e311);
    let _e313 = t1_1;
    let _e314 = t2_1;
    let _e316 = t1_1;
    let _e317 = t2_1;
    Rs_2 = ((_e313 - _e314) / (_e316 + _e317));
    let _e320 = cosTheta2_1;
    let _e321 = t0_1;
    let _e323 = sinTheta2_1;
    let _e324 = sinTheta2_1;
    t3_1 = ((_e320 * _e321) + (_e323 * _e324));
    let _e327 = t2_1;
    let _e328 = sinTheta2_1;
    t4_1 = (_e327 * _e328);
    let _e330 = Rs_2;
    let _e331 = t3_1;
    let _e332 = t4_1;
    let _e335 = t3_1;
    let _e336 = t4_1;
    Rp_2 = ((_e330 * (_e331 - _e332)) / (_e335 + _e336));
    let _e339 = Rp_2;
    let _e340 = Rs_2;
    return vec2<f32>(_e339, _e340);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e284 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e284, vec3(0.01f), vec3(0.99f)));
    let _e289 = sqrtF0_;
    let _e291 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e289) / (vec3<f32>(1f, 1f, 1f) - _e291));
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
    let _e338 = (*fd_1).tf_ior;
    let _e339 = eta1_1;
    eta2_1 = max(_e338, _e339);
    let _e342 = (*fd_1).model;
    if (_e342 == 2i) {
        let _e345 = (*fd_1).F0_;
        param_116 = _e345;
        let _e346 = mx_f0_to_ior_u0028_vf3_u003b((&param_116));
        local_5 = _e346;
    } else {
        let _e348 = (*fd_1).ior;
        local_5 = _e348;
    }
    let _e349 = local_5;
    eta3_ = _e349;
    let _e351 = (*fd_1).model;
    if (_e351 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e354 = (*fd_1).extinction;
        local_6 = _e354;
    }
    let _e355 = local_6;
    kappa3_ = _e355;
    let _e356 = (*cosTheta_10);
    param_117 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_117));
    let _e359 = eta1_1;
    let _e360 = eta2_1;
    param_118 = (_e359 / _e360);
    let _e362 = mx_square_u0028_f1_u003b((&param_118));
    cosThetaT = sqrt((1f - ((1f - _e357) * _e362)));
    let _e366 = eta2_1;
    let _e367 = eta1_1;
    let _e369 = (*cosTheta_10);
    param_119 = _e369;
    param_120 = (_e366 / _e367);
    let _e370 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_119), (&param_120));
    R12_ = _e370;
    let _e371 = cosThetaT;
    if (_e371 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e373 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e373);
    let _e376 = (*fd_1).model;
    if (_e376 == 2i) {
        let _e378 = cosThetaT;
        param_121 = _e378;
        let _e379 = (*fd_1);
        param_122 = _e379;
        let _e380 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_121), (&param_122));
        f_1 = _e380;
        let _e381 = f_1;
        R23p = (_e381 * 0.5f);
        let _e383 = f_1;
        R23s = (_e383 * 0.5f);
    } else {
        let _e385 = eta3_;
        let _e386 = eta2_1;
        let _e389 = kappa3_;
        let _e390 = eta2_1;
        let _e393 = cosThetaT;
        param_123 = _e393;
        param_124 = (_e385 / vec3(_e386));
        param_125 = (_e389 / vec3(_e390));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_123), (&param_124), (&param_125), (&param_126), (&param_127));
        let _e394 = param_126;
        R23p = _e394;
        let _e395 = param_127;
        R23s = _e395;
    }
    let _e396 = eta2_1;
    let _e397 = eta1_1;
    cosB = cos(atan((_e396 / _e397)));
    let _e401 = (*cosTheta_10);
    let _e402 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e401 < _e402)), 3.1415927f);
    let _e407 = (*fd_1).model;
    if (_e407 == 2i) {
        let _e410 = eta3_[0u];
        let _e411 = eta2_1;
        let _e415 = eta3_[1u];
        let _e416 = eta2_1;
        let _e420 = eta3_[2u];
        let _e421 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e410 < _e411)), select(0f, 3.1415927f, (_e415 < _e416)), select(0f, 3.1415927f, (_e420 < _e421)));
        let _e425 = phi23p;
        phi23s = _e425;
    } else {
        let _e426 = cosThetaT;
        param_128 = _e426;
        let _e427 = eta2_1;
        param_129 = _e427;
        let _e428 = eta3_;
        param_130 = _e428;
        let _e429 = kappa3_;
        param_131 = _e429;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_128), (&param_129), (&param_130), (&param_131), (&param_132), (&param_133));
        let _e430 = param_132;
        phi23p = _e430;
        let _e431 = param_133;
        phi23s = _e431;
    }
    let _e433 = R12_[0u];
    let _e434 = R23p;
    r123p = max(sqrt((_e434 * _e433)), vec3(0f));
    let _e440 = R12_[1u];
    let _e441 = R23s;
    r123s = max(sqrt((_e441 * _e440)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e447 = (*fd_1).tf_thickness;
    distMeters = (_e447 * 0.000000001f);
    let _e449 = eta2_1;
    let _e451 = cosThetaT;
    let _e453 = distMeters;
    opd_1 = (((2f * _e449) * _e451) * _e453);
    let _e456 = T121_[0u];
    param_134 = _e456;
    let _e457 = mx_square_u0028_f1_u003b((&param_134));
    let _e458 = R23p;
    let _e461 = R12_[0u];
    let _e462 = R23p;
    Rs_3 = ((_e458 * _e457) / (vec3<f32>(1f, 1f, 1f) - (_e462 * _e461)));
    let _e467 = R12_[0u];
    let _e468 = Rs_3;
    let _e471 = I;
    I = (_e471 + (vec3(_e467) + _e468));
    let _e473 = Rs_3;
    let _e475 = T121_[0u];
    Cm = (_e473 - vec3(_e475));
    m_3 = 1i;
    loop {
        let _e478 = m_3;
        if (_e478 <= 2i) {
            let _e480 = r123p;
            let _e481 = Cm;
            Cm = (_e481 * _e480);
            let _e483 = m_3;
            let _e485 = opd_1;
            let _e487 = m_3;
            let _e489 = phi23p;
            let _e491 = phi21_[0u];
            param_135 = (f32(_e483) * _e485);
            param_136 = ((_e489 + vec3(_e491)) * f32(_e487));
            let _e495 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_135), (&param_136));
            Sm = (_e495 * 2f);
            let _e497 = Cm;
            let _e498 = Sm;
            let _e500 = I;
            I = (_e500 + (_e497 * _e498));
            continue;
        } else {
            break;
        }
        continuing {
            let _e502 = m_3;
            m_3 = (_e502 + 1i);
        }
    }
    let _e505 = T121_[1u];
    param_137 = _e505;
    let _e506 = mx_square_u0028_f1_u003b((&param_137));
    let _e507 = R23s;
    let _e510 = R12_[1u];
    let _e511 = R23s;
    Rp_3 = ((_e507 * _e506) / (vec3<f32>(1f, 1f, 1f) - (_e511 * _e510)));
    let _e516 = R12_[1u];
    let _e517 = Rp_3;
    let _e520 = I;
    I = (_e520 + (vec3(_e516) + _e517));
    let _e522 = Rp_3;
    let _e524 = T121_[1u];
    Cm = (_e522 - vec3(_e524));
    m_4 = 1i;
    loop {
        let _e527 = m_4;
        if (_e527 <= 2i) {
            let _e529 = r123s;
            let _e530 = Cm;
            Cm = (_e530 * _e529);
            let _e532 = m_4;
            let _e534 = opd_1;
            let _e536 = m_4;
            let _e538 = phi23s;
            let _e540 = phi21_[1u];
            param_138 = (f32(_e532) * _e534);
            param_139 = ((_e538 + vec3(_e540)) * f32(_e536));
            let _e544 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_138), (&param_139));
            Sm = (_e544 * 2f);
            let _e546 = Cm;
            let _e547 = Sm;
            let _e549 = I;
            I = (_e549 + (_e546 * _e547));
            continue;
        } else {
            break;
        }
        continuing {
            let _e551 = m_4;
            m_4 = (_e551 + 1i);
        }
    }
    let _e553 = I;
    I = (_e553 * 0.5f);
    param_140 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e555 = I;
    param_141 = _e555;
    let _e556 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_140), (&param_141));
    I = clamp(_e556, vec3(0f), vec3(1f));
    let _e560 = I;
    return _e560;
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

    let _e294 = (*fd_2).airy;
    if _e294 {
        let _e295 = (*cosTheta_11);
        param_142 = _e295;
        let _e296 = (*fd_2);
        param_143 = _e296;
        let _e297 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_142), (&param_143));
        return _e297;
    } else {
        let _e299 = (*fd_2).model;
        if (_e299 == 0i) {
            let _e301 = (*cosTheta_11);
            param_144 = _e301;
            let _e304 = (*fd_2).ior[0u];
            param_145 = _e304;
            let _e305 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_144), (&param_145));
            return vec3(_e305);
        } else {
            let _e308 = (*fd_2).model;
            if (_e308 == 1i) {
                let _e310 = (*cosTheta_11);
                param_146 = _e310;
                let _e312 = (*fd_2).ior;
                param_147 = _e312;
                let _e314 = (*fd_2).extinction;
                param_148 = _e314;
                let _e315 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_146), (&param_147), (&param_148));
                return _e315;
            } else {
                let _e316 = (*cosTheta_11);
                param_149 = _e316;
                let _e317 = (*fd_2);
                param_150 = _e317;
                let _e318 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_149), (&param_150));
                return _e318;
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

    let _e290 = (*dir_2);
    let _e295 = (*transform_1);
    param_151 = _e295;
    param_152 = vec4<f32>(_e290.x, _e290.y, _e290.z, 0f);
    let _e296 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_151), (&param_152));
    envDir_1 = normalize(_e296.xyz);
    let _e299 = envDir_1;
    param_153 = _e299;
    let _e300 = mx_latlong_projection_u0028_vf3_u003b((&param_153));
    uv_2 = _e300;
    let _e301 = uv_2;
    let _e302 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e301, 0.0);
    return _e302.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_154: f32;

    let _e289 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e289 - 1.5f);
    let _e292 = (*dir_3)[1u];
    param_154 = _e292;
    let _e293 = mx_square_u0028_f1_u003b((&param_154));
    distortion = sqrt((1f - _e293));
    let _e296 = effectiveMaxMipLevel;
    let _e297 = (*envSamples);
    let _e299 = (*pdf);
    let _e301 = distortion;
    return max((_e296 - (0.5f * log2(((f32(_e297) * _e299) * _e301)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H_1: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_155: f32;
    var param_156: f32;

    let _e288 = (*H_1);
    let _e290 = (*alpha_1);
    He = (_e288.xy / _e290);
    let _e292 = He;
    let _e293 = He;
    let _e296 = (*H_1)[2u];
    param_155 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_155));
    denom_1 = (dot(_e292, _e293) + _e297);
    let _e300 = (*alpha_1)[0u];
    let _e303 = (*alpha_1)[1u];
    let _e305 = denom_1;
    param_156 = _e305;
    let _e306 = mx_square_u0028_f1_u003b((&param_156));
    return (1f / (((3.1415927f * _e300) * _e303) * _e306));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_2: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_13: ptr<function, f32>) -> f32 {
    var param_157: vec3<f32>;
    var param_158: vec2<f32>;

    let _e288 = (*H_2);
    param_157 = _e288;
    let _e289 = (*alpha_2);
    param_158 = _e289;
    let _e290 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_157), (&param_158));
    let _e291 = (*G1V);
    let _e293 = (*NdotV_13);
    return ((_e290 * _e291) / (4f * _e293));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e286 = (*R_1);
    let _e287 = (*N_12);
    let _e288 = (*ior_2);
    (*R_1) = refract(_e286, _e287, (1f / _e288));
    let _e291 = (*R_1);
    let _e292 = (*R_1);
    let _e293 = (*N_12);
    let _e296 = (*N_12);
    N1_ = normalize(((_e291 * dot(_e292, _e293)) - (_e296 * 0.5f)));
    let _e300 = (*R_1);
    let _e301 = N1_;
    let _e302 = (*ior_2);
    return refract(_e300, _e301, _e302);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_8: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_9: f32;
    var y_3: f32;
    var c_2: vec3<f32>;
    var H_3: vec3<f32>;

    let _e292 = (*V_8);
    let _e294 = (*alpha_3);
    let _e295 = (_e292.xy * _e294);
    let _e297 = (*V_8)[2u];
    (*V_8) = normalize(vec3<f32>(_e295.x, _e295.y, _e297));
    let _e303 = (*Xi)[0u];
    phi = (6.2831855f * _e303);
    let _e306 = (*Xi)[1u];
    let _e309 = (*V_8)[2u];
    let _e313 = (*V_8)[2u];
    z = (((1f - _e306) * (1f + _e309)) - _e313);
    let _e315 = z;
    let _e316 = z;
    sinTheta = sqrt(clamp((1f - (_e315 * _e316)), 0f, 1f));
    let _e321 = sinTheta;
    let _e322 = phi;
    x_9 = (_e321 * cos(_e322));
    let _e325 = sinTheta;
    let _e326 = phi;
    y_3 = (_e325 * sin(_e326));
    let _e329 = x_9;
    let _e330 = y_3;
    let _e331 = z;
    c_2 = vec3<f32>(_e329, _e330, _e331);
    let _e333 = c_2;
    let _e334 = (*V_8);
    H_3 = (_e333 + _e334);
    let _e336 = H_3;
    let _e338 = (*alpha_3);
    let _e339 = (_e336.xy * _e338);
    let _e341 = H_3[2u];
    H_3 = normalize(vec3<f32>(_e339.x, _e339.y, max(_e341, 0f)));
    let _e347 = H_3;
    return _e347;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e283 = (*i_1);
    return fract(((f32(_e283) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_159: i32;

    let _e285 = (*i_2);
    let _e288 = (*numSamples);
    let _e291 = (*i_2);
    param_159 = _e291;
    let _e292 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_159));
    return vec2<f32>(((f32(_e285) + 0.5f) / f32(_e288)), _e292);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_12: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_160: f32;
    var tanTheta2_: f32;
    var param_161: f32;

    let _e288 = (*cosTheta_12);
    param_160 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_160));
    cosTheta2_2 = _e289;
    let _e290 = cosTheta2_2;
    let _e292 = cosTheta2_2;
    tanTheta2_ = ((1f - _e290) / _e292);
    let _e294 = (*alpha_4);
    param_161 = _e294;
    let _e295 = mx_square_u0028_f1_u003b((&param_161));
    let _e296 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e295 * _e296)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e284 = (*alpha_5)[0u];
    let _e286 = (*alpha_5)[1u];
    return sqrt((_e284 * _e286));
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

    let _e339 = (*X_2);
    let _e340 = (*X_2);
    let _e341 = (*N_13);
    let _e343 = (*N_13);
    (*X_2) = normalize((_e339 - (_e343 * dot(_e340, _e341))));
    let _e347 = (*N_13);
    let _e348 = (*X_2);
    Y_2 = cross(_e347, _e348);
    let _e350 = (*X_2);
    let _e351 = Y_2;
    let _e352 = (*N_13);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e350.x, _e350.y, _e350.z), vec3<f32>(_e351.x, _e351.y, _e351.z), vec3<f32>(_e352.x, _e352.y, _e352.z));
    let _e366 = (*V_9);
    let _e367 = (*X_2);
    let _e369 = (*V_9);
    let _e370 = Y_2;
    let _e372 = (*V_9);
    let _e373 = (*N_13);
    (*V_9) = vec3<f32>(dot(_e366, _e367), dot(_e369, _e370), dot(_e372, _e373));
    let _e377 = (*V_9)[2u];
    NdotV_14 = clamp(_e377, 0.00000001f, 1f);
    let _e379 = (*alpha_6);
    param_162 = _e379;
    let _e380 = mx_average_alpha_u0028_vf2_u003b((&param_162));
    avgAlpha = _e380;
    let _e381 = NdotV_14;
    param_163 = _e381;
    let _e382 = avgAlpha;
    param_164 = _e382;
    let _e383 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_163), (&param_164));
    G1V_1 = _e383;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e384 = i_3;
        let _e385 = envRadianceSamples;
        if (_e384 < _e385) {
            let _e387 = i_3;
            param_165 = _e387;
            let _e388 = envRadianceSamples;
            param_166 = _e388;
            let _e389 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_165), (&param_166));
            Xi_1 = _e389;
            let _e390 = Xi_1;
            param_167 = _e390;
            let _e391 = (*V_9);
            param_168 = _e391;
            let _e392 = (*alpha_6);
            param_169 = _e392;
            let _e393 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_167), (&param_168), (&param_169));
            H_4 = _e393;
            let _e395 = (*fd_3).refraction;
            if _e395 {
                let _e396 = (*V_9);
                param_170 = -(_e396);
                let _e398 = H_4;
                param_171 = _e398;
                let _e401 = (*fd_3).ior[0u];
                param_172 = _e401;
                let _e402 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_170), (&param_171), (&param_172));
                local_7 = _e402;
            } else {
                let _e403 = (*V_9);
                let _e404 = H_4;
                local_7 = -(reflect(_e403, _e404));
            }
            let _e407 = local_7;
            L_7 = _e407;
            let _e409 = L_7[2u];
            NdotL_8 = clamp(_e409, 0.00000001f, 1f);
            let _e411 = (*V_9);
            let _e412 = H_4;
            VdotH = clamp(dot(_e411, _e412), 0.00000001f, 1f);
            let _e415 = tangentToWorld;
            param_173 = _e415;
            let _e416 = L_7;
            param_174 = _e416;
            let _e417 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_173), (&param_174));
            Lw = _e417;
            let _e418 = H_4;
            param_175 = _e418;
            let _e419 = (*alpha_6);
            param_176 = _e419;
            let _e420 = G1V_1;
            param_177 = _e420;
            let _e421 = NdotV_14;
            param_178 = _e421;
            let _e422 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_175), (&param_176), (&param_177), (&param_178));
            pdf_1 = _e422;
            let _e423 = Lw;
            param_179 = _e423;
            let _e424 = pdf_1;
            param_180 = _e424;
            param_181 = 0f;
            let _e425 = envRadianceSamples;
            param_182 = _e425;
            let _e426 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_179), (&param_180), (&param_181), (&param_182));
            lod_2 = _e426;
            let _e427 = mtlxEnvMatrix_u0028_();
            let _e428 = Lw;
            param_183 = _e428;
            param_184 = _e427;
            let _e429 = lod_2;
            param_185 = _e429;
            let _e430 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_183), (&param_184), (&param_185));
            sampleColor = _e430;
            let _e431 = VdotH;
            param_186 = _e431;
            let _e432 = (*fd_3);
            param_187 = _e432;
            let _e433 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_186), (&param_187));
            F_1 = _e433;
            let _e434 = NdotL_8;
            param_188 = _e434;
            let _e435 = NdotV_14;
            param_189 = _e435;
            let _e436 = avgAlpha;
            param_190 = _e436;
            let _e437 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_188), (&param_189), (&param_190));
            G_2 = _e437;
            let _e439 = (*fd_3).refraction;
            if _e439 {
                let _e440 = F_1;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e440);
            } else {
                let _e442 = F_1;
                let _e443 = G_2;
                local_8 = (_e442 * _e443);
            }
            let _e445 = local_8;
            FG = _e445;
            let _e446 = sampleColor;
            let _e447 = FG;
            let _e449 = radiance;
            radiance = (_e449 + (_e446 * _e447));
            continue;
        } else {
            break;
        }
        continuing {
            let _e451 = i_3;
            i_3 = (_e451 + 1i);
        }
    }
    let _e453 = G1V_1;
    let _e454 = envRadianceSamples;
    let _e457 = radiance;
    radiance = (_e457 / vec3((_e453 * f32(_e454))));
    let _e460 = radiance;
    let _e463 = unnamed.skyPower;
    return (select(_e460, vec3<f32>(0f, 0f, 0f), false) * _e463);
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

    let _e294 = (*NdotV_15);
    x_10 = _e294;
    let _e295 = (*alpha_7);
    y_4 = _e295;
    let _e296 = x_10;
    param_191 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_191));
    x2_1 = _e297;
    let _e298 = y_4;
    param_192 = _e298;
    let _e299 = mx_square_u0028_f1_u003b((&param_192));
    y2_ = _e299;
    let _e300 = x_10;
    let _e303 = y_4;
    let _e306 = x_10;
    let _e308 = y_4;
    let _e311 = x2_1;
    let _e314 = y2_;
    let _e317 = x2_1;
    let _e319 = y_4;
    let _e322 = x_10;
    let _e324 = y2_;
    let _e327 = x2_1;
    let _e329 = y2_;
    r_2 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e300)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e303)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e306) * _e308)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e311)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e314)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e317) * _e319)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e322) * _e324)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e327) * _e329));
    let _e332 = r_2;
    let _e334 = r_2;
    AB = clamp((_e332.xy / _e334.zw), vec2(0f), vec2(1f));
    let _e340 = (*F0_2);
    let _e342 = AB[0u];
    let _e344 = (*F90_1);
    let _e346 = AB[1u];
    return ((_e340 * _e342) + (_e344 * _e346));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_16: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_193: f32;
    var param_194: f32;
    var param_195: vec3<f32>;
    var param_196: vec3<f32>;

    let _e290 = (*NdotV_16);
    param_193 = _e290;
    let _e291 = (*alpha_8);
    param_194 = _e291;
    let _e292 = (*F0_3);
    param_195 = _e292;
    let _e293 = (*F90_2);
    param_196 = _e293;
    let _e294 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_193), (&param_194), (&param_195), (&param_196));
    return _e294;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_197: f32;
    var param_198: f32;
    var param_199: vec3<f32>;
    var param_200: vec3<f32>;

    let _e290 = (*F0_4);
    let _e292 = (*F90_3);
    let _e294 = (*NdotV_17);
    param_197 = _e294;
    let _e295 = (*alpha_9);
    param_198 = _e295;
    param_199 = vec3(_e290);
    param_200 = vec3(_e292);
    let _e296 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_197), (&param_198), (&param_199), (&param_200));
    return _e296.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_4: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_201: f32;
    var param_202: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_2969_: bool;

    param_201 = 1f;
    let _e288 = (*fd_4);
    param_202 = _e288;
    let _e289 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_201), (&param_202));
    F0_5 = _e289;
    let _e291 = (*fd_4).model;
    let _e292 = (_e291 == 2i);
    phi_2969_ = _e292;
    if _e292 {
        let _e294 = (*fd_4).airy;
        phi_2969_ = !(_e294);
    }
    let _e297 = phi_2969_;
    if _e297 {
        let _e299 = (*fd_4).F90_;
        local_9 = _e299;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e300 = local_9;
    F90_4 = _e300;
    let _e301 = F0_5;
    let _e302 = F90_4;
    let _e303 = F0_5;
    return (_e301 + ((_e302 - _e303) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_18: ptr<function, f32>, alpha_10: ptr<function, f32>, fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_203: FresnelData;
    var Ess: f32;
    var param_204: f32;
    var param_205: f32;
    var param_206: f32;
    var param_207: f32;

    let _e292 = (*fd_5);
    param_203 = _e292;
    let _e293 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_203));
    Fss = _e293;
    let _e294 = (*NdotV_18);
    param_204 = _e294;
    let _e295 = (*alpha_10);
    param_205 = _e295;
    param_206 = 1f;
    param_207 = 1f;
    let _e296 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_204), (&param_205), (&param_206), (&param_207));
    Ess = _e296;
    let _e297 = Fss;
    let _e298 = Ess;
    let _e301 = Ess;
    return (vec3(1f) + ((_e297 * (1f - _e298)) / vec3(_e301)));
}

fn mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(ior_3: ptr<function, vec3<f32>>, extinction: ptr<function, vec3<f32>>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_6: FresnelData;

    fd_6.model = 1i;
    let _e288 = (*tf_thickness);
    fd_6.airy = (_e288 > 0f);
    let _e291 = (*ior_3);
    fd_6.ior = _e291;
    let _e293 = (*extinction);
    fd_6.extinction = _e293;
    fd_6.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_6.exponent = 0f;
    let _e299 = (*tf_thickness);
    fd_6.tf_thickness = _e299;
    let _e301 = (*tf_ior);
    fd_6.tf_ior = _e301;
    fd_6.refraction = false;
    let _e304 = fd_6;
    return _e304;
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
    let _e339 = (*weight_5);
    if (_e339 < 0.00000001f) {
        return;
    }
    let _e342 = (*closureData_12).V;
    V_10 = _e342;
    let _e344 = (*closureData_12).L;
    L_8 = _e344;
    let _e345 = (*retroreflective);
    if _e345 {
        let _e346 = V_10;
        let _e348 = (*N_14);
        local_10 = reflect(-(_e346), _e348);
    } else {
        let _e350 = V_10;
        local_10 = _e350;
    }
    let _e351 = local_10;
    V_10 = _e351;
    let _e352 = (*N_14);
    param_208 = _e352;
    let _e353 = V_10;
    param_209 = _e353;
    let _e354 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_208), (&param_209));
    (*N_14) = _e354;
    let _e355 = (*N_14);
    let _e356 = V_10;
    NdotV_19 = clamp(dot(_e355, _e356), 0.00000001f, 1f);
    let _e359 = (*ior_n);
    param_210 = _e359;
    let _e360 = (*ior_k);
    param_211 = _e360;
    let _e361 = (*thinfilm_thickness);
    param_212 = _e361;
    let _e362 = (*thinfilm_ior);
    param_213 = _e362;
    let _e363 = mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_210), (&param_211), (&param_212), (&param_213));
    fd_7 = _e363;
    let _e364 = (*roughness_14);
    safeAlpha = clamp(_e364, vec2(0.00000001f), vec2(1f));
    let _e368 = safeAlpha;
    param_214 = _e368;
    let _e369 = mx_average_alpha_u0028_vf2_u003b((&param_214));
    avgAlpha_1 = _e369;
    let _e371 = (*closureData_12).closureType;
    if (_e371 == 1i) {
        let _e373 = (*X_3);
        let _e374 = (*X_3);
        let _e375 = (*N_14);
        let _e377 = (*N_14);
        (*X_3) = normalize((_e373 - (_e377 * dot(_e374, _e375))));
        let _e381 = (*N_14);
        let _e382 = (*X_3);
        Y_3 = cross(_e381, _e382);
        let _e384 = L_8;
        let _e385 = V_10;
        H_5 = normalize((_e384 + _e385));
        let _e388 = (*N_14);
        let _e389 = L_8;
        NdotL_9 = clamp(dot(_e388, _e389), 0.00000001f, 1f);
        let _e392 = V_10;
        let _e393 = H_5;
        VdotH_1 = clamp(dot(_e392, _e393), 0.00000001f, 1f);
        let _e396 = H_5;
        let _e397 = (*X_3);
        let _e399 = H_5;
        let _e400 = Y_3;
        let _e402 = H_5;
        let _e403 = (*N_14);
        Ht = vec3<f32>(dot(_e396, _e397), dot(_e399, _e400), dot(_e402, _e403));
        let _e406 = VdotH_1;
        param_215 = _e406;
        let _e407 = fd_7;
        param_216 = _e407;
        let _e408 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_215), (&param_216));
        F_2 = _e408;
        let _e409 = Ht;
        param_217 = _e409;
        let _e410 = safeAlpha;
        param_218 = _e410;
        let _e411 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_217), (&param_218));
        D_1 = _e411;
        let _e412 = NdotL_9;
        param_219 = _e412;
        let _e413 = NdotV_19;
        param_220 = _e413;
        let _e414 = avgAlpha_1;
        param_221 = _e414;
        let _e415 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_219), (&param_220), (&param_221));
        G_3 = _e415;
        let _e416 = NdotV_19;
        param_222 = _e416;
        let _e417 = avgAlpha_1;
        param_223 = _e417;
        let _e418 = fd_7;
        param_224 = _e418;
        let _e419 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_222), (&param_223), (&param_224));
        comp = _e419;
        let _e420 = D_1;
        let _e421 = F_2;
        let _e423 = G_3;
        let _e425 = comp;
        let _e428 = (*closureData_12).occlusion;
        let _e430 = (*weight_5);
        let _e432 = NdotV_19;
        (*bsdf_4).response = ((((((_e421 * _e420) * _e423) * _e425) * _e428) * _e430) / vec3((4f * _e432)));
    } else {
        let _e438 = (*closureData_12).closureType;
        if (_e438 == 3i) {
            let _e440 = NdotV_19;
            param_225 = _e440;
            let _e441 = avgAlpha_1;
            param_226 = _e441;
            let _e442 = fd_7;
            param_227 = _e442;
            let _e443 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_225), (&param_226), (&param_227));
            comp_1 = _e443;
            let _e444 = (*N_14);
            param_228 = _e444;
            let _e445 = V_10;
            param_229 = _e445;
            let _e446 = (*X_3);
            param_230 = _e446;
            let _e447 = safeAlpha;
            param_231 = _e447;
            let _e448 = (*distribution_1);
            param_232 = _e448;
            let _e449 = fd_7;
            param_233 = _e449;
            let _e450 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_228), (&param_229), (&param_230), (&param_231), (&param_232), (&param_233));
            Li_5 = _e450;
            let _e451 = Li_5;
            let _e452 = comp_1;
            let _e454 = (*weight_5);
            (*bsdf_4).response = ((_e451 * _e452) * _e454);
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
        let _e297 = (*tint_1);
        param_234 = _e297;
        let _e298 = mx_square_u0028_vf3_u003b((&param_234));
        (*tint_1) = _e298;
    }
    let _e299 = (*N_15);
    param_235 = _e299;
    let _e300 = (*V_11);
    param_236 = _e300;
    let _e301 = (*X_4);
    param_237 = _e301;
    let _e302 = (*alpha_11);
    param_238 = _e302;
    let _e303 = (*distribution_2);
    param_239 = _e303;
    let _e304 = (*fd_8);
    param_240 = _e304;
    let _e305 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_235), (&param_236), (&param_237), (&param_238), (&param_239), (&param_240));
    let _e306 = (*tint_1);
    return (_e305 * _e306);
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_4: ptr<function, f32>) -> f32 {
    var param_241: f32;

    let _e284 = (*ior_4);
    let _e286 = (*ior_4);
    param_241 = ((_e284 - 1f) / (_e286 + 1f));
    let _e289 = mx_square_u0028_f1_u003b((&param_241));
    return _e289;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_5: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e287 = (*tf_thickness_1);
    fd_9.airy = (_e287 > 0f);
    let _e290 = (*ior_5);
    fd_9.ior = vec3(_e290);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e298 = (*tf_thickness_1);
    fd_9.tf_thickness = _e298;
    let _e300 = (*tf_ior_1);
    fd_9.tf_ior = _e300;
    fd_9.refraction = false;
    let _e303 = fd_9;
    return _e303;
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
    var phi_4013_: bool;

    let _e366 = (*weight_6);
    if (_e366 < 0.00000001f) {
        return;
    }
    let _e369 = (*closureData_13).closureType;
    let _e371 = (*scatter_mode);
    if ((_e369 != 2i) && (_e371 == 1i)) {
        return;
    }
    let _e375 = (*closureData_13).V;
    V_12 = _e375;
    let _e377 = (*closureData_13).L;
    L_9 = _e377;
    let _e378 = (*retroreflective_1);
    phi_4013_ = _e378;
    if _e378 {
        let _e380 = (*closureData_13).closureType;
        phi_4013_ = (_e380 != 2i);
    }
    let _e383 = phi_4013_;
    if _e383 {
        let _e384 = V_12;
        let _e386 = (*N_16);
        V_12 = reflect(-(_e384), _e386);
    }
    let _e388 = (*N_16);
    param_242 = _e388;
    let _e389 = V_12;
    param_243 = _e389;
    let _e390 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_242), (&param_243));
    (*N_16) = _e390;
    let _e391 = (*N_16);
    let _e392 = V_12;
    NdotV_20 = clamp(dot(_e391, _e392), 0.00000001f, 1f);
    let _e395 = (*ior_6);
    param_244 = _e395;
    let _e396 = (*thinfilm_thickness_1);
    param_245 = _e396;
    let _e397 = (*thinfilm_ior_1);
    param_246 = _e397;
    let _e398 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_244), (&param_245), (&param_246));
    fd_10 = _e398;
    let _e399 = (*ior_6);
    param_247 = _e399;
    let _e400 = mx_ior_to_f0_u0028_f1_u003b((&param_247));
    F0_6 = _e400;
    let _e401 = (*roughness_15);
    safeAlpha_1 = clamp(_e401, vec2(0.00000001f), vec2(1f));
    let _e405 = safeAlpha_1;
    param_248 = _e405;
    let _e406 = mx_average_alpha_u0028_vf2_u003b((&param_248));
    avgAlpha_2 = _e406;
    let _e407 = (*tint_2);
    safeTint = max(_e407, vec3(0f));
    let _e411 = (*closureData_13).closureType;
    if (_e411 == 1i) {
        let _e413 = (*X_5);
        let _e414 = (*X_5);
        let _e415 = (*N_16);
        let _e417 = (*N_16);
        (*X_5) = normalize((_e413 - (_e417 * dot(_e414, _e415))));
        let _e421 = (*N_16);
        let _e422 = (*X_5);
        Y_4 = cross(_e421, _e422);
        let _e424 = L_9;
        let _e425 = V_12;
        H_6 = normalize((_e424 + _e425));
        let _e428 = (*N_16);
        let _e429 = L_9;
        NdotL_10 = clamp(dot(_e428, _e429), 0.00000001f, 1f);
        let _e432 = V_12;
        let _e433 = H_6;
        VdotH_2 = clamp(dot(_e432, _e433), 0.00000001f, 1f);
        let _e436 = H_6;
        let _e437 = (*X_5);
        let _e439 = H_6;
        let _e440 = Y_4;
        let _e442 = H_6;
        let _e443 = (*N_16);
        Ht_1 = vec3<f32>(dot(_e436, _e437), dot(_e439, _e440), dot(_e442, _e443));
        let _e446 = VdotH_2;
        param_249 = _e446;
        let _e447 = fd_10;
        param_250 = _e447;
        let _e448 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_249), (&param_250));
        F_3 = _e448;
        let _e449 = Ht_1;
        param_251 = _e449;
        let _e450 = safeAlpha_1;
        param_252 = _e450;
        let _e451 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_251), (&param_252));
        D_2 = _e451;
        let _e452 = NdotL_10;
        param_253 = _e452;
        let _e453 = NdotV_20;
        param_254 = _e453;
        let _e454 = avgAlpha_2;
        param_255 = _e454;
        let _e455 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_253), (&param_254), (&param_255));
        G_4 = _e455;
        let _e456 = NdotV_20;
        param_256 = _e456;
        let _e457 = avgAlpha_2;
        param_257 = _e457;
        let _e458 = fd_10;
        param_258 = _e458;
        let _e459 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_256), (&param_257), (&param_258));
        comp_2 = _e459;
        let _e460 = NdotV_20;
        param_259 = _e460;
        let _e461 = avgAlpha_2;
        param_260 = _e461;
        let _e462 = F0_6;
        param_261 = _e462;
        param_262 = 1f;
        let _e463 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_259), (&param_260), (&param_261), (&param_262));
        let _e464 = comp_2;
        dirAlbedo_5 = (_e464 * _e463);
        let _e466 = dirAlbedo_5;
        let _e467 = (*weight_6);
        (*bsdf_5).throughput = (vec3(1f) - (_e466 * _e467));
        let _e472 = D_2;
        let _e473 = F_3;
        let _e475 = G_4;
        let _e477 = comp_2;
        let _e479 = safeTint;
        let _e482 = (*closureData_13).occlusion;
        let _e484 = (*weight_6);
        let _e486 = NdotV_20;
        (*bsdf_5).response = (((((((_e473 * _e472) * _e475) * _e477) * _e479) * _e482) * _e484) / vec3((4f * _e486)));
    } else {
        let _e492 = (*closureData_13).closureType;
        if (_e492 == 2i) {
            let _e494 = NdotV_20;
            param_263 = _e494;
            let _e495 = avgAlpha_2;
            param_264 = _e495;
            let _e496 = fd_10;
            param_265 = _e496;
            let _e497 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_263), (&param_264), (&param_265));
            comp_3 = _e497;
            let _e498 = NdotV_20;
            param_266 = _e498;
            let _e499 = avgAlpha_2;
            param_267 = _e499;
            let _e500 = F0_6;
            param_268 = _e500;
            param_269 = 1f;
            let _e501 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_266), (&param_267), (&param_268), (&param_269));
            let _e502 = comp_3;
            dirAlbedo_6 = (_e502 * _e501);
            let _e504 = dirAlbedo_6;
            let _e505 = (*weight_6);
            (*bsdf_5).throughput = (vec3(1f) - (_e504 * _e505));
            let _e510 = (*scatter_mode);
            if (_e510 != 0i) {
                let _e512 = (*N_16);
                param_270 = _e512;
                let _e513 = V_12;
                param_271 = _e513;
                let _e514 = (*X_5);
                param_272 = _e514;
                let _e515 = safeAlpha_1;
                param_273 = _e515;
                let _e516 = (*distribution_3);
                param_274 = _e516;
                let _e517 = fd_10;
                param_275 = _e517;
                let _e518 = safeTint;
                param_276 = _e518;
                let _e519 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_270), (&param_271), (&param_272), (&param_273), (&param_274), (&param_275), (&param_276));
                let _e520 = (*weight_6);
                (*bsdf_5).response = (_e519 * _e520);
            }
        } else {
            let _e524 = (*closureData_13).closureType;
            if (_e524 == 3i) {
                let _e526 = NdotV_20;
                param_277 = _e526;
                let _e527 = avgAlpha_2;
                param_278 = _e527;
                let _e528 = fd_10;
                param_279 = _e528;
                let _e529 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_277), (&param_278), (&param_279));
                comp_4 = _e529;
                let _e530 = NdotV_20;
                param_280 = _e530;
                let _e531 = avgAlpha_2;
                param_281 = _e531;
                let _e532 = F0_6;
                param_282 = _e532;
                param_283 = 1f;
                let _e533 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_280), (&param_281), (&param_282), (&param_283));
                let _e534 = comp_4;
                dirAlbedo_7 = (_e534 * _e533);
                let _e536 = dirAlbedo_7;
                let _e537 = (*weight_6);
                (*bsdf_5).throughput = (vec3(1f) - (_e536 * _e537));
                let _e542 = (*N_16);
                param_284 = _e542;
                let _e543 = V_12;
                param_285 = _e543;
                let _e544 = (*X_5);
                param_286 = _e544;
                let _e545 = safeAlpha_1;
                param_287 = _e545;
                let _e546 = (*distribution_3);
                param_288 = _e546;
                let _e547 = fd_10;
                param_289 = _e547;
                let _e548 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_284), (&param_285), (&param_286), (&param_287), (&param_288), (&param_289));
                Li_6 = _e548;
                let _e549 = Li_6;
                let _e550 = safeTint;
                let _e552 = comp_4;
                let _e554 = (*weight_6);
                (*bsdf_5).response = (((_e549 * _e550) * _e552) * _e554);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e288 = (*closureType);
    let _e289 = (*L_10);
    let _e290 = (*V_13);
    let _e291 = (*N_17);
    let _e292 = (*P_2);
    let _e293 = (*occlusion_1);
    return ClosureData(_e288, _e289, _e290, _e291, _e292, _e293);
}

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_8: ptr<function, lightshader>) {
    (*result_8).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_8).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e283 = unnamed.mtlxLightCount;
    return min(_e283, 1i);
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_4: ptr<function, f32>, mtlxRasterOut: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e285 = (*in1_4);
    combine_out = vec3(_e285);
    let _e287 = combine_out;
    (*mtlxRasterOut) = _e287;
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

    let _e293 = (*reflectivity);
    r_3 = clamp(_e293, vec3(0f), vec3(0.99f));
    let _e297 = r_3;
    r_sqrt = sqrt(_e297);
    let _e299 = r_3;
    let _e302 = r_3;
    n_min = ((vec3(1f) - _e299) / (vec3(1f) + _e302));
    let _e306 = r_sqrt;
    let _e309 = r_sqrt;
    n_max = ((vec3(1f) + _e306) / (vec3(1f) - _e309));
    let _e313 = n_max;
    let _e314 = n_min;
    let _e315 = (*edge_color);
    (*ior_7) = mix(_e313, _e314, _e315);
    let _e317 = (*ior_7);
    np1_ = (_e317 + vec3(1f));
    let _e320 = (*ior_7);
    nm1_ = (_e320 - vec3(1f));
    let _e323 = np1_;
    let _e324 = np1_;
    let _e326 = r_3;
    let _e328 = nm1_;
    let _e329 = nm1_;
    let _e332 = r_3;
    k2_2 = ((((_e323 * _e324) * _e326) - (_e328 * _e329)) / (vec3(1f) - _e332));
    let _e336 = k2_2;
    k2_2 = max(_e336, vec3(0f));
    let _e339 = k2_2;
    (*extinction_1) = sqrt(_e339);
    return;
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_9: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e290 = (*axis);
    (*axis) = normalize(_e290);
    let _e292 = (*amount);
    rotationRadians = radians(_e292);
    let _e294 = rotationRadians;
    s_4 = sin(_e294);
    let _e296 = rotationRadians;
    c_3 = cos(_e296);
    let _e298 = c_3;
    oc = (1f - _e298);
    let _e300 = (*_in);
    let _e301 = c_3;
    let _e303 = (*_in);
    let _e304 = (*axis);
    let _e306 = s_4;
    let _e309 = (*axis);
    let _e310 = (*axis);
    let _e311 = (*_in);
    let _e314 = oc;
    (*result_9) = (((_e300 * _e301) + (cross(_e303, _e304) * _e306)) + ((_e309 * dot(_e310, _e311)) * _e314));
    return;
}

fn mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b(_in_1: ptr<function, vec3<f32>>, lumacoeffs: ptr<function, vec3<f32>>, result_10: ptr<function, vec3<f32>>) {
    let _e285 = (*_in_1);
    let _e286 = (*lumacoeffs);
    (*result_10) = vec3(dot(_e285, _e286));
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_1: ptr<function, f32>, result_11: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e287 = (*roughness_16);
    let _e288 = (*roughness_16);
    roughness_sqr = clamp((_e287 * _e288), 0.00000001f, 1f);
    let _e291 = (*anisotropy_1);
    if (_e291 > 0f) {
        let _e293 = (*anisotropy_1);
        aspect = sqrt((1f - clamp(_e293, 0f, 0.98f)));
        let _e297 = roughness_sqr;
        let _e298 = aspect;
        (*result_11)[0u] = min((_e297 / _e298), 1f);
        let _e302 = roughness_sqr;
        let _e303 = aspect;
        (*result_11)[1u] = (_e302 * _e303);
    } else {
        let _e306 = roughness_sqr;
        (*result_11)[0u] = _e306;
        let _e308 = roughness_sqr;
        (*result_11)[1u] = _e308;
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
    let _e883 = (*coat_roughness);
    param_290 = _e883;
    let _e884 = (*coat_anisotropy);
    param_291 = _e884;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_290), (&param_291), (&param_292));
    let _e885 = param_292;
    coat_roughness_vector_out = _e885;
    let _e886 = (*coat_rotation);
    coat_tangent_rotate_degree_out = (_e886 * 360f);
    let _e888 = (*metalness);
    metalness_mix_fg_weight_out = (1f * _e888);
    let _e890 = (*base_color);
    let _e891 = (*base_2);
    metal_reflectivity_out = (_e890 * _e891);
    let _e893 = (*specular_color);
    let _e894 = (*specular);
    metal_edgecolor_out = (_e893 * _e894);
    let _e896 = (*coat_affect_roughness);
    let _e897 = (*coat);
    coat_affect_roughness_multiply1_out = (_e896 * _e897);
    let _e899 = (*specular_rotation);
    tangent_rotate_degree_out = (_e899 * 360f);
    let _e901 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e901);
    let _e903 = (*specular_roughness);
    let _e904 = (*transmission_extra_roughness);
    transmission_roughness_add_out = (_e903 + _e904);
    let _e906 = (*thin_walled);
    subsurface_selector_out = select(0f, 1f, _e906);
    let _e908 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e908, vec3(0f));
    let _e911 = (*coat);
    coat_clamped_out = clamp(_e911, 0f, 1f);
    let _e913 = (*subsurface_radius);
    let _e914 = (*subsurface_scale);
    subsurface_radius_scaled_out = (_e913 * _e914);
    let _e916 = (*subsurface);
    subsurface_mix_mix_inv_out = (1f - _e916);
    let _e918 = (*base_color);
    base_color_nonnegative_out = max(_e918, vec3(0f));
    let _e921 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e921);
    let _e923 = (*metalness);
    metalness_mix_mix_inv_out = (1f - _e923);
    let _e925 = (*coat_color);
    let _e926 = (*coat);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e925, vec3(_e926));
    let _e929 = (*coat_IOR);
    one_minus_coat_ior_out = (1f - _e929);
    let _e931 = (*coat_IOR);
    one_plus_coat_ior_out = (1f + _e931);
    let _e933 = (*emission_color);
    let _e934 = (*emission);
    emission_weight_out = (_e933 * _e934);
    opacity_luminance_out = vec3<f32>(0f, 0f, 0f);
    let _e936 = (*opacity);
    param_293 = _e936;
    param_294 = vec3<f32>(0.272229f, 0.674082f, 0.053689f);
    mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_293), (&param_294), (&param_295));
    let _e937 = param_295;
    opacity_luminance_out = _e937;
    coat_tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e938 = (*tangent);
    param_296 = _e938;
    let _e939 = coat_tangent_rotate_degree_out;
    param_297 = _e939;
    let _e940 = (*coat_normal);
    param_298 = _e940;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_296), (&param_297), (&param_298), (&param_299));
    let _e941 = param_299;
    coat_tangent_rotate_out = _e941;
    artistic_ior_ior = vec3<f32>(0f, 0f, 0f);
    artistic_ior_extinction = vec3<f32>(0f, 0f, 0f);
    let _e942 = metal_reflectivity_out;
    param_300 = _e942;
    let _e943 = metal_edgecolor_out;
    param_301 = _e943;
    mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_300), (&param_301), (&param_302), (&param_303));
    let _e944 = param_302;
    artistic_ior_ior = _e944;
    let _e945 = param_303;
    artistic_ior_extinction = _e945;
    let _e946 = coat_affect_roughness_multiply1_out;
    let _e947 = (*coat_roughness);
    coat_affect_roughness_multiply2_out = (_e946 * _e947);
    tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e949 = (*tangent);
    param_304 = _e949;
    let _e950 = tangent_rotate_degree_out;
    param_305 = _e950;
    let _e951 = (*normal);
    param_306 = _e951;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_304), (&param_305), (&param_306), (&param_307));
    let _e952 = param_307;
    tangent_rotate_out = _e952;
    let _e953 = transmission_roughness_add_out;
    transmission_roughness_clamped_out = clamp(_e953, 0f, 1f);
    let _e955 = subsurface_selector_out;
    selected_subsurface_bsdf_mix_inv_out = (1f - _e955);
    let _e957 = subsurface_selector_out;
    selected_subsurface_bsdf_fg_weight_out = (1f * _e957);
    let _e959 = coat_clamped_out;
    let _e960 = (*coat_affect_color);
    coat_gamma_multiply_out = (_e959 * _e960);
    let _e962 = (*base_2);
    let _e963 = subsurface_mix_mix_inv_out;
    subsurface_mix_bg_weight_out = (_e962 * _e963);
    let _e965 = one_minus_coat_ior_out;
    let _e966 = one_plus_coat_ior_out;
    coat_ior_to_F0_sqrt_out = (_e965 / _e966);
    let _e969 = opacity_luminance_out[0u];
    opacity_luminance_float_out = _e969;
    let _e970 = coat_tangent_rotate_out;
    coat_tangent_rotate_normalize_out = normalize(_e970);
    let _e972 = (*specular_roughness);
    let _e973 = coat_affect_roughness_multiply2_out;
    coat_affected_roughness_out = mix(_e972, 1f, _e973);
    let _e975 = tangent_rotate_out;
    tangent_rotate_normalize_out = normalize(_e975);
    let _e977 = transmission_roughness_clamped_out;
    let _e978 = coat_affect_roughness_multiply2_out;
    coat_affected_transmission_roughness_out = mix(_e977, 1f, _e978);
    let _e980 = selected_subsurface_bsdf_mix_inv_out;
    selected_subsurface_bsdf_bg_weight_out = (1f * _e980);
    let _e982 = coat_gamma_multiply_out;
    coat_gamma_out = (_e982 + 1f);
    let _e984 = coat_ior_to_F0_sqrt_out;
    let _e985 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e984 * _e985);
    let _e987 = (*coat_anisotropy);
    let _e989 = coat_tangent_rotate_normalize_out;
    let _e990 = (*tangent);
    coat_tangent_out = select(_e990, _e989, (_e987 > 0f));
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e992 = coat_affected_roughness_out;
    param_308 = _e992;
    let _e993 = (*specular_anisotropy);
    param_309 = _e993;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_308), (&param_309), (&param_310));
    let _e994 = param_310;
    main_roughness_out = _e994;
    let _e995 = (*specular_anisotropy);
    let _e997 = tangent_rotate_normalize_out;
    let _e998 = (*tangent);
    main_tangent_out = select(_e998, _e997, (_e995 > 0f));
    transmission_roughness_out = vec2<f32>(0f, 0f);
    let _e1000 = coat_affected_transmission_roughness_out;
    param_311 = _e1000;
    let _e1001 = (*specular_anisotropy);
    param_312 = _e1001;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_311), (&param_312), (&param_313));
    let _e1002 = param_313;
    transmission_roughness_out = _e1002;
    let _e1003 = subsurface_color_nonnegative_out;
    let _e1004 = coat_gamma_out;
    coat_affected_subsurface_color_out = pow(_e1003, vec3(_e1004));
    let _e1007 = base_color_nonnegative_out;
    let _e1008 = coat_gamma_out;
    coat_affected_diffuse_color_out = pow(_e1007, vec3(_e1008));
    let _e1011 = coat_ior_to_F0_out;
    one_minus_coat_ior_to_F0_out = (1f - _e1011);
    emission_color0_out = vec3<f32>(0f, 0f, 0f);
    let _e1013 = one_minus_coat_ior_to_F0_out;
    param_314 = _e1013;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_314), (&param_315));
    let _e1014 = param_315;
    emission_color0_out = _e1014;
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e1015 = normalWorld;
    N_18 = normalize(_e1015);
    let _e1019 = unnamed.cameraWorldMatrix[3];
    let _e1021 = positionWorld;
    V_14 = normalize((_e1019.xyz - _e1021));
    let _e1024 = positionWorld;
    P_3 = _e1024;
    L_11 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e1025 = opacity_luminance_float_out;
    surfaceOpacity = _e1025;
    let _e1026 = numActiveLightSources_u0028_();
    numLights = _e1026;
    activeLightIndex = 0i;
    loop {
        let _e1027 = activeLightIndex;
        let _e1028 = numLights;
        if (_e1027 < _e1028) {
            let _e1030 = activeLightIndex;
            let _e1033 = unnamed.u_lightData[_e1030];
            param_316 = _e1033;
            let _e1034 = positionWorld;
            param_317 = _e1034;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_316), (&param_317), (&param_318));
            let _e1035 = param_318;
            lightShader = _e1035;
            let _e1037 = lightShader.direction;
            L_11 = _e1037;
            param_319 = 1i;
            let _e1038 = L_11;
            param_320 = _e1038;
            let _e1039 = V_14;
            param_321 = _e1039;
            let _e1040 = N_18;
            param_322 = _e1040;
            let _e1041 = P_3;
            param_323 = _e1041;
            let _e1042 = occlusion_2;
            param_324 = _e1042;
            let _e1043 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324));
            closureData_14 = _e1043;
            coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1044 = closureData_14;
            param_325 = _e1044;
            let _e1045 = (*coat);
            param_326 = _e1045;
            param_327 = vec3<f32>(1f, 1f, 1f);
            let _e1046 = (*coat_IOR);
            param_328 = _e1046;
            let _e1047 = coat_roughness_vector_out;
            param_329 = _e1047;
            param_330 = false;
            param_331 = 0f;
            param_332 = 1.5f;
            let _e1048 = (*coat_normal);
            param_333 = _e1048;
            let _e1049 = coat_tangent_out;
            param_334 = _e1049;
            param_335 = 0i;
            param_336 = 0i;
            let _e1050 = coat_bsdf_out;
            param_337 = _e1050;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_325), (&param_326), (&param_327), (&param_328), (&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336), (&param_337));
            let _e1051 = param_337;
            coat_bsdf_out = _e1051;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1052 = closureData_14;
            param_338 = _e1052;
            let _e1053 = metalness_mix_fg_weight_out;
            param_339 = _e1053;
            let _e1054 = artistic_ior_ior;
            param_340 = _e1054;
            let _e1055 = artistic_ior_extinction;
            param_341 = _e1055;
            let _e1056 = main_roughness_out;
            param_342 = _e1056;
            param_343 = false;
            let _e1057 = (*thin_film_thickness);
            param_344 = _e1057;
            let _e1058 = (*thin_film_IOR);
            param_345 = _e1058;
            let _e1059 = (*normal);
            param_346 = _e1059;
            let _e1060 = main_tangent_out;
            param_347 = _e1060;
            param_348 = 0i;
            let _e1061 = metal_bsdf_out;
            param_349 = _e1061;
            mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349));
            let _e1062 = param_349;
            metal_bsdf_out = _e1062;
            specular_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1063 = closureData_14;
            param_350 = _e1063;
            let _e1064 = (*specular);
            param_351 = _e1064;
            let _e1065 = (*specular_color);
            param_352 = _e1065;
            let _e1066 = (*specular_IOR);
            param_353 = _e1066;
            let _e1067 = main_roughness_out;
            param_354 = _e1067;
            param_355 = false;
            let _e1068 = (*thin_film_thickness);
            param_356 = _e1068;
            let _e1069 = (*thin_film_IOR);
            param_357 = _e1069;
            let _e1070 = (*normal);
            param_358 = _e1070;
            let _e1071 = main_tangent_out;
            param_359 = _e1071;
            param_360 = 0i;
            param_361 = 0i;
            let _e1072 = specular_bsdf_out;
            param_362 = _e1072;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_350), (&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362));
            let _e1073 = param_362;
            specular_bsdf_out = _e1073;
            transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1074 = closureData_14;
            param_363 = _e1074;
            let _e1075 = transmission_mix_fg_weight_out;
            param_364 = _e1075;
            let _e1076 = (*transmission_color);
            param_365 = _e1076;
            let _e1077 = (*specular_IOR);
            param_366 = _e1077;
            let _e1078 = transmission_roughness_out;
            param_367 = _e1078;
            param_368 = false;
            param_369 = 0f;
            param_370 = 1.5f;
            let _e1079 = (*normal);
            param_371 = _e1079;
            let _e1080 = main_tangent_out;
            param_372 = _e1080;
            param_373 = 0i;
            param_374 = 1i;
            let _e1081 = transmission_bsdf_out;
            param_375 = _e1081;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372), (&param_373), (&param_374), (&param_375));
            let _e1082 = param_375;
            transmission_bsdf_out = _e1082;
            sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1083 = closureData_14;
            param_376 = _e1083;
            let _e1084 = (*sheen);
            param_377 = _e1084;
            let _e1085 = (*sheen_color);
            param_378 = _e1085;
            let _e1086 = (*sheen_roughness);
            param_379 = _e1086;
            let _e1087 = (*normal);
            param_380 = _e1087;
            param_381 = 0i;
            let _e1088 = sheen_bsdf_out;
            param_382 = _e1088;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382));
            let _e1089 = param_382;
            sheen_bsdf_out = _e1089;
            translucent_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1090 = closureData_14;
            param_383 = _e1090;
            let _e1091 = selected_subsurface_bsdf_fg_weight_out;
            param_384 = _e1091;
            let _e1092 = coat_affected_subsurface_color_out;
            param_385 = _e1092;
            let _e1093 = (*normal);
            param_386 = _e1093;
            let _e1094 = translucent_bsdf_out;
            param_387 = _e1094;
            mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_383), (&param_384), (&param_385), (&param_386), (&param_387));
            let _e1095 = param_387;
            translucent_bsdf_out = _e1095;
            subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1096 = closureData_14;
            param_388 = _e1096;
            let _e1097 = selected_subsurface_bsdf_bg_weight_out;
            param_389 = _e1097;
            let _e1098 = coat_affected_subsurface_color_out;
            param_390 = _e1098;
            let _e1099 = subsurface_radius_scaled_out;
            param_391 = _e1099;
            let _e1100 = (*subsurface_anisotropy);
            param_392 = _e1100;
            let _e1101 = (*normal);
            param_393 = _e1101;
            let _e1102 = subsurface_bsdf_out;
            param_394 = _e1102;
            mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394));
            let _e1103 = param_394;
            subsurface_bsdf_out = _e1103;
            selected_subsurface_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1104 = closureData_14;
            param_395 = _e1104;
            let _e1105 = translucent_bsdf_out;
            param_396 = _e1105;
            let _e1106 = subsurface_bsdf_out;
            param_397 = _e1106;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_395), (&param_396), (&param_397), (&param_398));
            let _e1107 = param_398;
            selected_subsurface_bsdf_add_out = _e1107;
            subsurface_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1108 = closureData_14;
            param_399 = _e1108;
            let _e1109 = selected_subsurface_bsdf_add_out;
            param_400 = _e1109;
            let _e1110 = (*subsurface);
            param_401 = _e1110;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_399), (&param_400), (&param_401), (&param_402));
            let _e1111 = param_402;
            subsurface_mix_fg_mul_out = _e1111;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1112 = closureData_14;
            param_403 = _e1112;
            let _e1113 = subsurface_mix_bg_weight_out;
            param_404 = _e1113;
            let _e1114 = coat_affected_diffuse_color_out;
            param_405 = _e1114;
            let _e1115 = (*diffuse_roughness);
            param_406 = _e1115;
            let _e1116 = (*normal);
            param_407 = _e1116;
            param_408 = false;
            let _e1117 = diffuse_bsdf_out;
            param_409 = _e1117;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_403), (&param_404), (&param_405), (&param_406), (&param_407), (&param_408), (&param_409));
            let _e1118 = param_409;
            diffuse_bsdf_out = _e1118;
            subsurface_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1119 = closureData_14;
            param_410 = _e1119;
            let _e1120 = subsurface_mix_fg_mul_out;
            param_411 = _e1120;
            let _e1121 = diffuse_bsdf_out;
            param_412 = _e1121;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_410), (&param_411), (&param_412), (&param_413));
            let _e1122 = param_413;
            subsurface_mix_add_out = _e1122;
            sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1123 = closureData_14;
            param_414 = _e1123;
            let _e1124 = sheen_bsdf_out;
            param_415 = _e1124;
            let _e1125 = subsurface_mix_add_out;
            param_416 = _e1125;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_414), (&param_415), (&param_416), (&param_417));
            let _e1126 = param_417;
            sheen_layer_out = _e1126;
            transmission_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1127 = closureData_14;
            param_418 = _e1127;
            let _e1128 = sheen_layer_out;
            param_419 = _e1128;
            let _e1129 = transmission_mix_mix_inv_out;
            param_420 = _e1129;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_418), (&param_419), (&param_420), (&param_421));
            let _e1130 = param_421;
            transmission_mix_bg_mul_out = _e1130;
            transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1131 = closureData_14;
            param_422 = _e1131;
            let _e1132 = transmission_bsdf_out;
            param_423 = _e1132;
            let _e1133 = transmission_mix_bg_mul_out;
            param_424 = _e1133;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_422), (&param_423), (&param_424), (&param_425));
            let _e1134 = param_425;
            transmission_mix_add_out = _e1134;
            specular_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1135 = closureData_14;
            param_426 = _e1135;
            let _e1136 = specular_bsdf_out;
            param_427 = _e1136;
            let _e1137 = transmission_mix_add_out;
            param_428 = _e1137;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_426), (&param_427), (&param_428), (&param_429));
            let _e1138 = param_429;
            specular_layer_out = _e1138;
            metalness_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1139 = closureData_14;
            param_430 = _e1139;
            let _e1140 = specular_layer_out;
            param_431 = _e1140;
            let _e1141 = metalness_mix_mix_inv_out;
            param_432 = _e1141;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_430), (&param_431), (&param_432), (&param_433));
            let _e1142 = param_433;
            metalness_mix_bg_mul_out = _e1142;
            metalness_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1143 = closureData_14;
            param_434 = _e1143;
            let _e1144 = metal_bsdf_out;
            param_435 = _e1144;
            let _e1145 = metalness_mix_bg_mul_out;
            param_436 = _e1145;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_434), (&param_435), (&param_436), (&param_437));
            let _e1146 = param_437;
            metalness_mix_add_out = _e1146;
            thin_film_layer_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1147 = closureData_14;
            param_438 = _e1147;
            let _e1148 = metalness_mix_add_out;
            param_439 = _e1148;
            let _e1149 = coat_attenuation_out;
            param_440 = _e1149;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_438), (&param_439), (&param_440), (&param_441));
            let _e1150 = param_441;
            thin_film_layer_attenuated_out = _e1150;
            coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1151 = closureData_14;
            param_442 = _e1151;
            let _e1152 = coat_bsdf_out;
            param_443 = _e1152;
            let _e1153 = thin_film_layer_attenuated_out;
            param_444 = _e1153;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_442), (&param_443), (&param_444), (&param_445));
            let _e1154 = param_445;
            coat_layer_out = _e1154;
            let _e1156 = lightShader.intensity;
            let _e1158 = coat_layer_out.response;
            let _e1161 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1161 + (_e1156 * _e1158));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1164 = activeLightIndex;
            activeLightIndex = (_e1164 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_446 = 3i;
    let _e1166 = L_11;
    param_447 = _e1166;
    let _e1167 = V_14;
    param_448 = _e1167;
    let _e1168 = N_18;
    param_449 = _e1168;
    let _e1169 = P_3;
    param_450 = _e1169;
    let _e1170 = occlusion_2;
    param_451 = _e1170;
    let _e1171 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451));
    closureData_15 = _e1171;
    coat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1172 = closureData_15;
    param_452 = _e1172;
    let _e1173 = (*coat);
    param_453 = _e1173;
    param_454 = vec3<f32>(1f, 1f, 1f);
    let _e1174 = (*coat_IOR);
    param_455 = _e1174;
    let _e1175 = coat_roughness_vector_out;
    param_456 = _e1175;
    param_457 = false;
    param_458 = 0f;
    param_459 = 1.5f;
    let _e1176 = (*coat_normal);
    param_460 = _e1176;
    let _e1177 = coat_tangent_out;
    param_461 = _e1177;
    param_462 = 0i;
    param_463 = 0i;
    let _e1178 = coat_bsdf_out_1;
    param_464 = _e1178;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_452), (&param_453), (&param_454), (&param_455), (&param_456), (&param_457), (&param_458), (&param_459), (&param_460), (&param_461), (&param_462), (&param_463), (&param_464));
    let _e1179 = param_464;
    coat_bsdf_out_1 = _e1179;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1180 = closureData_15;
    param_465 = _e1180;
    let _e1181 = metalness_mix_fg_weight_out;
    param_466 = _e1181;
    let _e1182 = artistic_ior_ior;
    param_467 = _e1182;
    let _e1183 = artistic_ior_extinction;
    param_468 = _e1183;
    let _e1184 = main_roughness_out;
    param_469 = _e1184;
    param_470 = false;
    let _e1185 = (*thin_film_thickness);
    param_471 = _e1185;
    let _e1186 = (*thin_film_IOR);
    param_472 = _e1186;
    let _e1187 = (*normal);
    param_473 = _e1187;
    let _e1188 = main_tangent_out;
    param_474 = _e1188;
    param_475 = 0i;
    let _e1189 = metal_bsdf_out_1;
    param_476 = _e1189;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476));
    let _e1190 = param_476;
    metal_bsdf_out_1 = _e1190;
    specular_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1191 = closureData_15;
    param_477 = _e1191;
    let _e1192 = (*specular);
    param_478 = _e1192;
    let _e1193 = (*specular_color);
    param_479 = _e1193;
    let _e1194 = (*specular_IOR);
    param_480 = _e1194;
    let _e1195 = main_roughness_out;
    param_481 = _e1195;
    param_482 = false;
    let _e1196 = (*thin_film_thickness);
    param_483 = _e1196;
    let _e1197 = (*thin_film_IOR);
    param_484 = _e1197;
    let _e1198 = (*normal);
    param_485 = _e1198;
    let _e1199 = main_tangent_out;
    param_486 = _e1199;
    param_487 = 0i;
    param_488 = 0i;
    let _e1200 = specular_bsdf_out_1;
    param_489 = _e1200;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489));
    let _e1201 = param_489;
    specular_bsdf_out_1 = _e1201;
    transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1202 = closureData_15;
    param_490 = _e1202;
    let _e1203 = transmission_mix_fg_weight_out;
    param_491 = _e1203;
    let _e1204 = (*transmission_color);
    param_492 = _e1204;
    let _e1205 = (*specular_IOR);
    param_493 = _e1205;
    let _e1206 = transmission_roughness_out;
    param_494 = _e1206;
    param_495 = false;
    param_496 = 0f;
    param_497 = 1.5f;
    let _e1207 = (*normal);
    param_498 = _e1207;
    let _e1208 = main_tangent_out;
    param_499 = _e1208;
    param_500 = 0i;
    param_501 = 1i;
    let _e1209 = transmission_bsdf_out_1;
    param_502 = _e1209;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_490), (&param_491), (&param_492), (&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502));
    let _e1210 = param_502;
    transmission_bsdf_out_1 = _e1210;
    sheen_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1211 = closureData_15;
    param_503 = _e1211;
    let _e1212 = (*sheen);
    param_504 = _e1212;
    let _e1213 = (*sheen_color);
    param_505 = _e1213;
    let _e1214 = (*sheen_roughness);
    param_506 = _e1214;
    let _e1215 = (*normal);
    param_507 = _e1215;
    param_508 = 0i;
    let _e1216 = sheen_bsdf_out_1;
    param_509 = _e1216;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_503), (&param_504), (&param_505), (&param_506), (&param_507), (&param_508), (&param_509));
    let _e1217 = param_509;
    sheen_bsdf_out_1 = _e1217;
    translucent_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1218 = closureData_15;
    param_510 = _e1218;
    let _e1219 = selected_subsurface_bsdf_fg_weight_out;
    param_511 = _e1219;
    let _e1220 = coat_affected_subsurface_color_out;
    param_512 = _e1220;
    let _e1221 = (*normal);
    param_513 = _e1221;
    let _e1222 = translucent_bsdf_out_1;
    param_514 = _e1222;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_510), (&param_511), (&param_512), (&param_513), (&param_514));
    let _e1223 = param_514;
    translucent_bsdf_out_1 = _e1223;
    subsurface_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1224 = closureData_15;
    param_515 = _e1224;
    let _e1225 = selected_subsurface_bsdf_bg_weight_out;
    param_516 = _e1225;
    let _e1226 = coat_affected_subsurface_color_out;
    param_517 = _e1226;
    let _e1227 = subsurface_radius_scaled_out;
    param_518 = _e1227;
    let _e1228 = (*subsurface_anisotropy);
    param_519 = _e1228;
    let _e1229 = (*normal);
    param_520 = _e1229;
    let _e1230 = subsurface_bsdf_out_1;
    param_521 = _e1230;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_515), (&param_516), (&param_517), (&param_518), (&param_519), (&param_520), (&param_521));
    let _e1231 = param_521;
    subsurface_bsdf_out_1 = _e1231;
    selected_subsurface_bsdf_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1232 = closureData_15;
    param_522 = _e1232;
    let _e1233 = translucent_bsdf_out_1;
    param_523 = _e1233;
    let _e1234 = subsurface_bsdf_out_1;
    param_524 = _e1234;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_522), (&param_523), (&param_524), (&param_525));
    let _e1235 = param_525;
    selected_subsurface_bsdf_add_out_1 = _e1235;
    subsurface_mix_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1236 = closureData_15;
    param_526 = _e1236;
    let _e1237 = selected_subsurface_bsdf_add_out_1;
    param_527 = _e1237;
    let _e1238 = (*subsurface);
    param_528 = _e1238;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_526), (&param_527), (&param_528), (&param_529));
    let _e1239 = param_529;
    subsurface_mix_fg_mul_out_1 = _e1239;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1240 = closureData_15;
    param_530 = _e1240;
    let _e1241 = subsurface_mix_bg_weight_out;
    param_531 = _e1241;
    let _e1242 = coat_affected_diffuse_color_out;
    param_532 = _e1242;
    let _e1243 = (*diffuse_roughness);
    param_533 = _e1243;
    let _e1244 = (*normal);
    param_534 = _e1244;
    param_535 = false;
    let _e1245 = diffuse_bsdf_out_1;
    param_536 = _e1245;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_530), (&param_531), (&param_532), (&param_533), (&param_534), (&param_535), (&param_536));
    let _e1246 = param_536;
    diffuse_bsdf_out_1 = _e1246;
    subsurface_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1247 = closureData_15;
    param_537 = _e1247;
    let _e1248 = subsurface_mix_fg_mul_out_1;
    param_538 = _e1248;
    let _e1249 = diffuse_bsdf_out_1;
    param_539 = _e1249;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_537), (&param_538), (&param_539), (&param_540));
    let _e1250 = param_540;
    subsurface_mix_add_out_1 = _e1250;
    sheen_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1251 = closureData_15;
    param_541 = _e1251;
    let _e1252 = sheen_bsdf_out_1;
    param_542 = _e1252;
    let _e1253 = subsurface_mix_add_out_1;
    param_543 = _e1253;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_541), (&param_542), (&param_543), (&param_544));
    let _e1254 = param_544;
    sheen_layer_out_1 = _e1254;
    transmission_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1255 = closureData_15;
    param_545 = _e1255;
    let _e1256 = sheen_layer_out_1;
    param_546 = _e1256;
    let _e1257 = transmission_mix_mix_inv_out;
    param_547 = _e1257;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_545), (&param_546), (&param_547), (&param_548));
    let _e1258 = param_548;
    transmission_mix_bg_mul_out_1 = _e1258;
    transmission_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1259 = closureData_15;
    param_549 = _e1259;
    let _e1260 = transmission_bsdf_out_1;
    param_550 = _e1260;
    let _e1261 = transmission_mix_bg_mul_out_1;
    param_551 = _e1261;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_549), (&param_550), (&param_551), (&param_552));
    let _e1262 = param_552;
    transmission_mix_add_out_1 = _e1262;
    specular_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1263 = closureData_15;
    param_553 = _e1263;
    let _e1264 = specular_bsdf_out_1;
    param_554 = _e1264;
    let _e1265 = transmission_mix_add_out_1;
    param_555 = _e1265;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_553), (&param_554), (&param_555), (&param_556));
    let _e1266 = param_556;
    specular_layer_out_1 = _e1266;
    metalness_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1267 = closureData_15;
    param_557 = _e1267;
    let _e1268 = specular_layer_out_1;
    param_558 = _e1268;
    let _e1269 = metalness_mix_mix_inv_out;
    param_559 = _e1269;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_557), (&param_558), (&param_559), (&param_560));
    let _e1270 = param_560;
    metalness_mix_bg_mul_out_1 = _e1270;
    metalness_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1271 = closureData_15;
    param_561 = _e1271;
    let _e1272 = metal_bsdf_out_1;
    param_562 = _e1272;
    let _e1273 = metalness_mix_bg_mul_out_1;
    param_563 = _e1273;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_561), (&param_562), (&param_563), (&param_564));
    let _e1274 = param_564;
    metalness_mix_add_out_1 = _e1274;
    thin_film_layer_attenuated_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1275 = closureData_15;
    param_565 = _e1275;
    let _e1276 = metalness_mix_add_out_1;
    param_566 = _e1276;
    let _e1277 = coat_attenuation_out;
    param_567 = _e1277;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_565), (&param_566), (&param_567), (&param_568));
    let _e1278 = param_568;
    thin_film_layer_attenuated_out_1 = _e1278;
    coat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1279 = closureData_15;
    param_569 = _e1279;
    let _e1280 = coat_bsdf_out_1;
    param_570 = _e1280;
    let _e1281 = thin_film_layer_attenuated_out_1;
    param_571 = _e1281;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_569), (&param_570), (&param_571), (&param_572));
    let _e1282 = param_572;
    coat_layer_out_1 = _e1282;
    let _e1283 = occlusion_2;
    let _e1285 = coat_layer_out_1.response;
    let _e1288 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1288 + (_e1285 * _e1283));
    param_573 = 4i;
    let _e1291 = L_11;
    param_574 = _e1291;
    let _e1292 = V_14;
    param_575 = _e1292;
    let _e1293 = N_18;
    param_576 = _e1293;
    let _e1294 = P_3;
    param_577 = _e1294;
    let _e1295 = occlusion_2;
    param_578 = _e1295;
    let _e1296 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578));
    closureData_16 = _e1296;
    emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1297 = closureData_16;
    param_579 = _e1297;
    let _e1298 = emission_weight_out;
    param_580 = _e1298;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_579), (&param_580), (&param_581));
    let _e1299 = param_581;
    emission_edf_out = _e1299;
    coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1300 = closureData_16;
    param_582 = _e1300;
    let _e1301 = emission_edf_out;
    param_583 = _e1301;
    let _e1302 = (*coat_color);
    param_584 = _e1302;
    mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_582), (&param_583), (&param_584), (&param_585));
    let _e1303 = param_585;
    coat_tinted_emission_edf_out = _e1303;
    coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1304 = closureData_16;
    param_586 = _e1304;
    let _e1305 = emission_color0_out;
    param_587 = _e1305;
    param_588 = vec3<f32>(0f, 0f, 0f);
    param_589 = 5f;
    let _e1306 = coat_tinted_emission_edf_out;
    param_590 = _e1306;
    mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591));
    let _e1307 = param_591;
    coat_emission_edf_out = _e1307;
    blended_coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1308 = closureData_16;
    param_592 = _e1308;
    let _e1309 = coat_emission_edf_out;
    param_593 = _e1309;
    let _e1310 = emission_edf_out;
    param_594 = _e1310;
    let _e1311 = (*coat);
    param_595 = _e1311;
    mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_592), (&param_593), (&param_594), (&param_595), (&param_596));
    let _e1312 = param_596;
    blended_coat_emission_edf_out = _e1312;
    let _e1313 = blended_coat_emission_edf_out;
    let _e1315 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1315 + _e1313);
    param_597 = 2i;
    let _e1318 = L_11;
    param_598 = _e1318;
    let _e1319 = V_14;
    param_599 = _e1319;
    let _e1320 = N_18;
    param_600 = _e1320;
    let _e1321 = P_3;
    param_601 = _e1321;
    let _e1322 = occlusion_2;
    param_602 = _e1322;
    let _e1323 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_597), (&param_598), (&param_599), (&param_600), (&param_601), (&param_602));
    closureData_17 = _e1323;
    coat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1324 = closureData_17;
    param_603 = _e1324;
    let _e1325 = (*coat);
    param_604 = _e1325;
    param_605 = vec3<f32>(1f, 1f, 1f);
    let _e1326 = (*coat_IOR);
    param_606 = _e1326;
    let _e1327 = coat_roughness_vector_out;
    param_607 = _e1327;
    param_608 = false;
    param_609 = 0f;
    param_610 = 1.5f;
    let _e1328 = (*coat_normal);
    param_611 = _e1328;
    let _e1329 = coat_tangent_out;
    param_612 = _e1329;
    param_613 = 0i;
    param_614 = 0i;
    let _e1330 = coat_bsdf_out_2;
    param_615 = _e1330;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615));
    let _e1331 = param_615;
    coat_bsdf_out_2 = _e1331;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1332 = closureData_17;
    param_616 = _e1332;
    let _e1333 = metalness_mix_fg_weight_out;
    param_617 = _e1333;
    let _e1334 = artistic_ior_ior;
    param_618 = _e1334;
    let _e1335 = artistic_ior_extinction;
    param_619 = _e1335;
    let _e1336 = main_roughness_out;
    param_620 = _e1336;
    param_621 = false;
    let _e1337 = (*thin_film_thickness);
    param_622 = _e1337;
    let _e1338 = (*thin_film_IOR);
    param_623 = _e1338;
    let _e1339 = (*normal);
    param_624 = _e1339;
    let _e1340 = main_tangent_out;
    param_625 = _e1340;
    param_626 = 0i;
    let _e1341 = metal_bsdf_out_2;
    param_627 = _e1341;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621), (&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627));
    let _e1342 = param_627;
    metal_bsdf_out_2 = _e1342;
    specular_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1343 = closureData_17;
    param_628 = _e1343;
    let _e1344 = (*specular);
    param_629 = _e1344;
    let _e1345 = (*specular_color);
    param_630 = _e1345;
    let _e1346 = (*specular_IOR);
    param_631 = _e1346;
    let _e1347 = main_roughness_out;
    param_632 = _e1347;
    param_633 = false;
    let _e1348 = (*thin_film_thickness);
    param_634 = _e1348;
    let _e1349 = (*thin_film_IOR);
    param_635 = _e1349;
    let _e1350 = (*normal);
    param_636 = _e1350;
    let _e1351 = main_tangent_out;
    param_637 = _e1351;
    param_638 = 0i;
    param_639 = 0i;
    let _e1352 = specular_bsdf_out_2;
    param_640 = _e1352;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_628), (&param_629), (&param_630), (&param_631), (&param_632), (&param_633), (&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640));
    let _e1353 = param_640;
    specular_bsdf_out_2 = _e1353;
    transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1354 = closureData_17;
    param_641 = _e1354;
    let _e1355 = transmission_mix_fg_weight_out;
    param_642 = _e1355;
    let _e1356 = (*transmission_color);
    param_643 = _e1356;
    let _e1357 = (*specular_IOR);
    param_644 = _e1357;
    let _e1358 = transmission_roughness_out;
    param_645 = _e1358;
    param_646 = false;
    param_647 = 0f;
    param_648 = 1.5f;
    let _e1359 = (*normal);
    param_649 = _e1359;
    let _e1360 = main_tangent_out;
    param_650 = _e1360;
    param_651 = 0i;
    param_652 = 1i;
    let _e1361 = transmission_bsdf_out_2;
    param_653 = _e1361;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_641), (&param_642), (&param_643), (&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650), (&param_651), (&param_652), (&param_653));
    let _e1362 = param_653;
    transmission_bsdf_out_2 = _e1362;
    sheen_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1363 = closureData_17;
    param_654 = _e1363;
    let _e1364 = (*sheen);
    param_655 = _e1364;
    let _e1365 = (*sheen_color);
    param_656 = _e1365;
    let _e1366 = (*sheen_roughness);
    param_657 = _e1366;
    let _e1367 = (*normal);
    param_658 = _e1367;
    param_659 = 0i;
    let _e1368 = sheen_bsdf_out_2;
    param_660 = _e1368;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_654), (&param_655), (&param_656), (&param_657), (&param_658), (&param_659), (&param_660));
    let _e1369 = param_660;
    sheen_bsdf_out_2 = _e1369;
    translucent_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1370 = closureData_17;
    param_661 = _e1370;
    let _e1371 = selected_subsurface_bsdf_fg_weight_out;
    param_662 = _e1371;
    let _e1372 = coat_affected_subsurface_color_out;
    param_663 = _e1372;
    let _e1373 = (*normal);
    param_664 = _e1373;
    let _e1374 = translucent_bsdf_out_2;
    param_665 = _e1374;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_661), (&param_662), (&param_663), (&param_664), (&param_665));
    let _e1375 = param_665;
    translucent_bsdf_out_2 = _e1375;
    subsurface_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1376 = closureData_17;
    param_666 = _e1376;
    let _e1377 = selected_subsurface_bsdf_bg_weight_out;
    param_667 = _e1377;
    let _e1378 = coat_affected_subsurface_color_out;
    param_668 = _e1378;
    let _e1379 = subsurface_radius_scaled_out;
    param_669 = _e1379;
    let _e1380 = (*subsurface_anisotropy);
    param_670 = _e1380;
    let _e1381 = (*normal);
    param_671 = _e1381;
    let _e1382 = subsurface_bsdf_out_2;
    param_672 = _e1382;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_666), (&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672));
    let _e1383 = param_672;
    subsurface_bsdf_out_2 = _e1383;
    selected_subsurface_bsdf_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1384 = closureData_17;
    param_673 = _e1384;
    let _e1385 = translucent_bsdf_out_2;
    param_674 = _e1385;
    let _e1386 = subsurface_bsdf_out_2;
    param_675 = _e1386;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_673), (&param_674), (&param_675), (&param_676));
    let _e1387 = param_676;
    selected_subsurface_bsdf_add_out_2 = _e1387;
    subsurface_mix_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1388 = closureData_17;
    param_677 = _e1388;
    let _e1389 = selected_subsurface_bsdf_add_out_2;
    param_678 = _e1389;
    let _e1390 = (*subsurface);
    param_679 = _e1390;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_677), (&param_678), (&param_679), (&param_680));
    let _e1391 = param_680;
    subsurface_mix_fg_mul_out_2 = _e1391;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1392 = closureData_17;
    param_681 = _e1392;
    let _e1393 = subsurface_mix_bg_weight_out;
    param_682 = _e1393;
    let _e1394 = coat_affected_diffuse_color_out;
    param_683 = _e1394;
    let _e1395 = (*diffuse_roughness);
    param_684 = _e1395;
    let _e1396 = (*normal);
    param_685 = _e1396;
    param_686 = false;
    let _e1397 = diffuse_bsdf_out_2;
    param_687 = _e1397;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_681), (&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687));
    let _e1398 = param_687;
    diffuse_bsdf_out_2 = _e1398;
    subsurface_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1399 = closureData_17;
    param_688 = _e1399;
    let _e1400 = subsurface_mix_fg_mul_out_2;
    param_689 = _e1400;
    let _e1401 = diffuse_bsdf_out_2;
    param_690 = _e1401;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_688), (&param_689), (&param_690), (&param_691));
    let _e1402 = param_691;
    subsurface_mix_add_out_2 = _e1402;
    sheen_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1403 = closureData_17;
    param_692 = _e1403;
    let _e1404 = sheen_bsdf_out_2;
    param_693 = _e1404;
    let _e1405 = subsurface_mix_add_out_2;
    param_694 = _e1405;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_692), (&param_693), (&param_694), (&param_695));
    let _e1406 = param_695;
    sheen_layer_out_2 = _e1406;
    transmission_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1407 = closureData_17;
    param_696 = _e1407;
    let _e1408 = sheen_layer_out_2;
    param_697 = _e1408;
    let _e1409 = transmission_mix_mix_inv_out;
    param_698 = _e1409;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_696), (&param_697), (&param_698), (&param_699));
    let _e1410 = param_699;
    transmission_mix_bg_mul_out_2 = _e1410;
    transmission_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1411 = closureData_17;
    param_700 = _e1411;
    let _e1412 = transmission_bsdf_out_2;
    param_701 = _e1412;
    let _e1413 = transmission_mix_bg_mul_out_2;
    param_702 = _e1413;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_700), (&param_701), (&param_702), (&param_703));
    let _e1414 = param_703;
    transmission_mix_add_out_2 = _e1414;
    specular_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1415 = closureData_17;
    param_704 = _e1415;
    let _e1416 = specular_bsdf_out_2;
    param_705 = _e1416;
    let _e1417 = transmission_mix_add_out_2;
    param_706 = _e1417;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_704), (&param_705), (&param_706), (&param_707));
    let _e1418 = param_707;
    specular_layer_out_2 = _e1418;
    metalness_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1419 = closureData_17;
    param_708 = _e1419;
    let _e1420 = specular_layer_out_2;
    param_709 = _e1420;
    let _e1421 = metalness_mix_mix_inv_out;
    param_710 = _e1421;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_708), (&param_709), (&param_710), (&param_711));
    let _e1422 = param_711;
    metalness_mix_bg_mul_out_2 = _e1422;
    metalness_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1423 = closureData_17;
    param_712 = _e1423;
    let _e1424 = metal_bsdf_out_2;
    param_713 = _e1424;
    let _e1425 = metalness_mix_bg_mul_out_2;
    param_714 = _e1425;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_712), (&param_713), (&param_714), (&param_715));
    let _e1426 = param_715;
    metalness_mix_add_out_2 = _e1426;
    thin_film_layer_attenuated_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1427 = closureData_17;
    param_716 = _e1427;
    let _e1428 = metalness_mix_add_out_2;
    param_717 = _e1428;
    let _e1429 = coat_attenuation_out;
    param_718 = _e1429;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_716), (&param_717), (&param_718), (&param_719));
    let _e1430 = param_719;
    thin_film_layer_attenuated_out_2 = _e1430;
    coat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1431 = closureData_17;
    param_720 = _e1431;
    let _e1432 = coat_bsdf_out_2;
    param_721 = _e1432;
    let _e1433 = thin_film_layer_attenuated_out_2;
    param_722 = _e1433;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_720), (&param_721), (&param_722), (&param_723));
    let _e1434 = param_723;
    coat_layer_out_2 = _e1434;
    let _e1436 = coat_layer_out_2.response;
    let _e1438 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1438 + _e1436);
    let _e1441 = surfaceOpacity;
    let _e1443 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1443 * _e1441);
    let _e1447 = shader_constructor_out.transparency;
    let _e1448 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e1447, vec3(_e1448));
    let _e1452 = shader_constructor_out;
    (*mtlxRasterOut_1) = _e1452;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_default_out: surfaceshader;
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

    let _e328 = normalWorld;
    geomprop_Nworld_out = normalize(_e328);
    let _e330 = tangentWorld;
    geomprop_Tworld_out = normalize(_e330);
    SR_default_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e332 = base_3;
    param_724 = _e332;
    let _e333 = base_color_1;
    param_725 = _e333;
    let _e334 = diffuse_roughness_1;
    param_726 = _e334;
    let _e335 = metalness_1;
    param_727 = _e335;
    let _e336 = specular_1;
    param_728 = _e336;
    let _e337 = specular_color_1;
    param_729 = _e337;
    let _e338 = specular_roughness_1;
    param_730 = _e338;
    let _e339 = specular_IOR_1;
    param_731 = _e339;
    let _e340 = specular_anisotropy_1;
    param_732 = _e340;
    let _e341 = specular_rotation_1;
    param_733 = _e341;
    let _e342 = transmission_1;
    param_734 = _e342;
    let _e343 = transmission_color_1;
    param_735 = _e343;
    let _e344 = transmission_depth_1;
    param_736 = _e344;
    let _e345 = transmission_scatter_1;
    param_737 = _e345;
    let _e346 = transmission_scatter_anisotropy_1;
    param_738 = _e346;
    let _e347 = transmission_dispersion_1;
    param_739 = _e347;
    let _e348 = transmission_extra_roughness_1;
    param_740 = _e348;
    let _e349 = subsurface_1;
    param_741 = _e349;
    let _e350 = subsurface_color_1;
    param_742 = _e350;
    let _e351 = subsurface_radius_1;
    param_743 = _e351;
    let _e352 = subsurface_scale_1;
    param_744 = _e352;
    let _e353 = subsurface_anisotropy_1;
    param_745 = _e353;
    let _e354 = sheen_1;
    param_746 = _e354;
    let _e355 = sheen_color_1;
    param_747 = _e355;
    let _e356 = sheen_roughness_1;
    param_748 = _e356;
    let _e357 = coat_1;
    param_749 = _e357;
    let _e358 = coat_color_1;
    param_750 = _e358;
    let _e359 = coat_roughness_1;
    param_751 = _e359;
    let _e360 = coat_anisotropy_1;
    param_752 = _e360;
    let _e361 = coat_rotation_1;
    param_753 = _e361;
    let _e362 = coat_IOR_1;
    param_754 = _e362;
    let _e363 = geomprop_Nworld_out;
    param_755 = _e363;
    let _e364 = coat_affect_color_1;
    param_756 = _e364;
    let _e365 = coat_affect_roughness_1;
    param_757 = _e365;
    let _e366 = thin_film_thickness_1;
    param_758 = _e366;
    let _e367 = thin_film_IOR_1;
    param_759 = _e367;
    let _e368 = emission_1;
    param_760 = _e368;
    let _e369 = emission_color_1;
    param_761 = _e369;
    let _e370 = opacity_1;
    param_762 = _e370;
    let _e371 = thin_walled_1;
    param_763 = _e371;
    let _e372 = geomprop_Nworld_out;
    param_764 = _e372;
    let _e373 = geomprop_Tworld_out;
    param_765 = _e373;
    NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_724), (&param_725), (&param_726), (&param_727), (&param_728), (&param_729), (&param_730), (&param_731), (&param_732), (&param_733), (&param_734), (&param_735), (&param_736), (&param_737), (&param_738), (&param_739), (&param_740), (&param_741), (&param_742), (&param_743), (&param_744), (&param_745), (&param_746), (&param_747), (&param_748), (&param_749), (&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765), (&param_766));
    let _e374 = param_766;
    SR_default_out = _e374;
    let _e376 = SR_default_out.color;
    mtlxRasterOut_2 = vec4<f32>(_e376.x, _e376.y, _e376.z, 1f);
    let _e381 = mtlxRasterOut_2;
    return _e381;
}

fn mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b(pW_1: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e286 = mtlxRasterMain_u0028_();
    return _e286.xyz;
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, rndSeed: ptr<function, u32>) {
    return;
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e284 = (*vWorld);
    let _e286 = (*basis_2).tW;
    let _e288 = (*vWorld);
    let _e290 = (*basis_2).bW;
    let _e292 = (*vWorld);
    let _e294 = (*basis_2).nW;
    return vec3<f32>(dot(_e284, _e286), dot(_e288, _e290), dot(_e292, _e294));
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e284 = (*N_19);
    l = length(_e284);
    let _e286 = (*N_19);
    let _e287 = l;
    return (_e286 / vec3(max(_e287, 0.0000000001f)));
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, bW: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>) -> Basis {
    var basis_3: Basis;
    var param_767: vec3<f32>;
    var param_768: vec3<f32>;
    var param_769: vec3<f32>;

    let _e291 = (*nW);
    param_767 = _e291;
    let _e292 = safe_normalize_u0028_vf3_u003b((&param_767));
    basis_3.nW = _e292;
    let _e294 = (*tW);
    param_768 = _e294;
    let _e295 = safe_normalize_u0028_vf3_u003b((&param_768));
    basis_3.tW = _e295;
    let _e297 = (*bW);
    param_769 = _e297;
    let _e298 = safe_normalize_u0028_vf3_u003b((&param_769));
    basis_3.bW = _e298;
    let _e300 = (*baryCoord);
    basis_3.baryCoord = _e300;
    let _e302 = (*texCoord);
    basis_3.texCoord = _e302;
    let _e304 = basis_3;
    return _e304;
}

fn skyRadiance_u0028_vf3_u003b(woutputW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e285 = (*woutputW)[0u];
    let _e286 = (*woutputW);
    let _e287 = _e286.yz;
    let _e291 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e285, _e287.x, _e287.y), 0f);
    env = _e291;
    let _e292 = env;
    let _e295 = unnamed.skyPower;
    let _e298 = unnamed.skyColor;
    return ((_e292.xyz * _e295) * _e298);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max: f32;

    let _e285 = unnamed.sunAngularSize;
    theta_max = ((_e285 * 3.1415927f) / 180f);
    let _e288 = (*woutputW_1);
    let _e290 = unnamed.sunDir;
    let _e292 = theta_max;
    if (dot(_e288, _e290) < cos(_e292)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e296 = unnamed.sunPower;
    let _e298 = unnamed.sunColor;
    return (_e298 * _e296);
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_770: vec3<f32>;

    let _e286 = (*N_20)[2u];
    let _e289 = (*N_20)[0u];
    if (abs(_e286) < abs(_e289)) {
        let _e293 = (*N_20)[2u];
        let _e295 = (*N_20)[0u];
        T = vec3<f32>(_e293, 0f, -(_e295));
    } else {
        let _e299 = (*N_20)[2u];
        let _e301 = (*N_20)[1u];
        T = vec3<f32>(0f, _e299, -(_e301));
    }
    let _e304 = T;
    param_770 = _e304;
    let _e305 = safe_normalize_u0028_vf3_u003b((&param_770));
    T = _e305;
    let _e306 = T;
    return _e306;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e286 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e286).x;
    let _e289 = (*index);
    let _e290 = width;
    let _e298 = (*index);
    let _e299 = width;
    let _e302 = textureLoad(texture, vec2<i32>((_e289 - (i32(floor((f32(_e289) / f32(_e290)))) * _e290)), (_e298 / _e299)), 0i);
    return _e302;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_771: i32;
    var param_772: i32;
    var param_773: i32;

    let _e290 = (*barycoord)[0u];
    let _e292 = (*faceIndices)[0u];
    param_771 = bitcast<i32>(_e292);
    let _e294 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_771));
    let _e297 = (*barycoord)[1u];
    let _e299 = (*faceIndices)[1u];
    param_772 = bitcast<i32>(_e299);
    let _e301 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_772));
    let _e305 = (*barycoord)[2u];
    let _e307 = (*faceIndices)[2u];
    param_773 = bitcast<i32>(_e307);
    let _e309 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_773));
    return (((_e294 * _e290) + (_e301 * _e297)) + (_e309 * _e305));
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

    let _e294 = (*direction);
    inverseDirection = (vec3(1f) / _e294);
    let _e297 = (*minimum);
    let _e298 = (*origin);
    let _e300 = inverseDirection;
    t0_2 = ((_e297 - _e298) * _e300);
    let _e302 = (*maximum);
    let _e303 = (*origin);
    let _e305 = inverseDirection;
    t1_2 = ((_e302 - _e303) * _e305);
    let _e307 = t0_2;
    let _e308 = t1_2;
    entry = min(_e307, _e308);
    let _e310 = t0_2;
    let _e311 = t1_2;
    exit = max(_e310, _e311);
    let _e314 = entry[0u];
    let _e316 = entry[1u];
    let _e318 = entry[2u];
    nearDistance = max(_e314, max(_e316, _e318));
    let _e322 = exit[0u];
    let _e324 = exit[1u];
    let _e326 = exit[2u];
    farDistance = min(_e322, min(_e324, _e326));
    let _e329 = farDistance;
    let _e330 = nearDistance;
    if (_e329 >= max(_e330, 0f)) {
        let _e333 = nearDistance;
        local_11 = max(_e333, 0f);
    } else {
        local_11 = 100000000000000000000f;
    }
    let _e335 = local_11;
    return _e335;
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
    var phi_1145_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e335 = (*maxDistance);
    closest = _e335;
    found = false;
    loop {
        let _e336 = pointer;
        let _e338 = pointer;
        if ((_e336 >= 0i) && (_e338 < 64i)) {
            let _e341 = pointer;
            pointer = (_e341 - 1i);
            let _e344 = stack[_e341];
            nodeIndex = _e344;
            let _e345 = nodeIndex;
            param_774 = (_e345 * 3i);
            let _e347 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_774));
            minimum_1 = _e347;
            let _e348 = nodeIndex;
            param_775 = ((_e348 * 3i) + 1i);
            let _e351 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_775));
            maximum_1 = _e351;
            let _e352 = nodeIndex;
            param_776 = ((_e352 * 3i) + 2i);
            let _e355 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_776));
            metadata = _e355;
            let _e356 = minimum_1;
            param_777 = _e356.xyz;
            let _e358 = maximum_1;
            param_778 = _e358.xyz;
            let _e360 = (*rayOrigin);
            param_779 = _e360;
            let _e361 = (*rayDirection);
            param_780 = _e361;
            let _e362 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_777), (&param_778), (&param_779), (&param_780));
            let _e363 = closest;
            if (_e362 > _e363) {
                continue;
            }
            let _e366 = metadata[2u];
            if (_e366 > 0.5f) {
                let _e369 = metadata[0u];
                offset = i32((_e369 + 0.5f));
                let _e373 = metadata[1u];
                count = i32((_e373 + 0.5f));
                triangle = 0i;
                loop {
                    let _e376 = triangle;
                    let _e377 = count;
                    if (_e376 < _e377) {
                        let _e379 = offset;
                        let _e380 = triangle;
                        param_781 = (_e379 + _e380);
                        let _e382 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_781));
                        vertexIndices = vec3<u32>((_e382.xyz + vec3(0.5f)));
                        let _e388 = vertexIndices[0u];
                        param_782 = bitcast<i32>(_e388);
                        let _e390 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_782));
                        p0_ = _e390.xyz;
                        let _e393 = vertexIndices[1u];
                        param_783 = bitcast<i32>(_e393);
                        let _e395 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_783));
                        p1_ = _e395.xyz;
                        let _e398 = vertexIndices[2u];
                        param_784 = bitcast<i32>(_e398);
                        let _e400 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_784));
                        p2_ = _e400.xyz;
                        let _e402 = p1_;
                        let _e403 = p0_;
                        edge0_ = (_e402 - _e403);
                        let _e405 = p2_;
                        let _e406 = p0_;
                        edge1_ = (_e405 - _e406);
                        let _e408 = (*rayDirection);
                        let _e409 = edge1_;
                        pvec = cross(_e408, _e409);
                        let _e411 = edge0_;
                        let _e412 = pvec;
                        determinant_ = dot(_e411, _e412);
                        let _e414 = determinant_;
                        if (abs(_e414) < 0.00000001f) {
                            continue;
                        }
                        let _e417 = determinant_;
                        inverseDeterminant = (1f / _e417);
                        let _e419 = (*rayOrigin);
                        let _e420 = p0_;
                        tvec = (_e419 - _e420);
                        let _e422 = tvec;
                        let _e423 = pvec;
                        let _e425 = inverseDeterminant;
                        u = (dot(_e422, _e423) * _e425);
                        let _e427 = tvec;
                        let _e428 = edge0_;
                        qvec = cross(_e427, _e428);
                        let _e430 = (*rayDirection);
                        let _e431 = qvec;
                        let _e433 = inverseDeterminant;
                        v_2 = (dot(_e430, _e431) * _e433);
                        let _e435 = edge1_;
                        let _e436 = qvec;
                        let _e438 = inverseDeterminant;
                        distance_ = (dot(_e435, _e436) * _e438);
                        let _e440 = u;
                        let _e442 = v_2;
                        let _e444 = ((_e440 >= 0f) && (_e442 >= 0f));
                        phi_1145_ = _e444;
                        if _e444 {
                            let _e445 = u;
                            let _e446 = v_2;
                            phi_1145_ = ((_e445 + _e446) <= 1f);
                        }
                        let _e450 = phi_1145_;
                        let _e451 = distance_;
                        let _e454 = distance_;
                        let _e455 = closest;
                        if ((_e450 && (_e451 > 0f)) && (_e454 < _e455)) {
                            let _e458 = distance_;
                            closest = _e458;
                            let _e459 = distance_;
                            (*dist_2) = _e459;
                            let _e460 = u;
                            let _e462 = v_2;
                            let _e464 = u;
                            let _e465 = v_2;
                            (*barycoord_1) = vec3<f32>(((1f - _e460) - _e462), _e464, _e465);
                            let _e467 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e467.x, _e467.y, _e467.z, 0u);
                            let _e472 = edge0_;
                            let _e473 = edge1_;
                            (*faceNormal) = normalize(cross(_e472, _e473));
                            let _e476 = determinant_;
                            (*side) = select(1f, -1f, (_e476 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e479 = triangle;
                        triangle = (_e479 + 1i);
                    }
                }
            } else {
                let _e482 = metadata[0u];
                left = i32((_e482 + 0.5f));
                let _e486 = metadata[1u];
                right = i32((_e486 + 0.5f));
                let _e489 = pointer;
                if ((_e489 + 2i) >= 64i) {
                    continue;
                }
                let _e492 = pointer;
                let _e493 = (_e492 + 1i);
                pointer = _e493;
                let _e494 = right;
                stack[_e493] = _e494;
                let _e496 = pointer;
                let _e497 = (_e496 + 1i);
                pointer = _e497;
                let _e498 = left;
                stack[_e497] = _e498;
            }
            continue;
        } else {
            break;
        }
    }
    let _e500 = found;
    return _e500;
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

    let _e304 = (*rayOrigin_1);
    param_785 = _e304;
    let _e305 = (*rayDirection_1);
    param_786 = _e305;
    let _e306 = (*maxDistance_1);
    param_787 = _e306;
    let _e307 = (*faceIndices_2);
    param_788 = _e307;
    let _e308 = (*faceNormal_1);
    param_789 = _e308;
    let _e309 = (*barycoord_2);
    param_790 = _e309;
    let _e310 = (*side_1);
    param_791 = _e310;
    let _e311 = (*dist_3);
    param_792 = _e311;
    let _e312 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_785), (&param_786), (&param_787), (&param_788), (&param_789), (&param_790), (&param_791), (&param_792));
    let _e313 = param_788;
    (*faceIndices_2) = _e313;
    let _e314 = param_789;
    (*faceNormal_1) = _e314;
    let _e315 = param_790;
    (*barycoord_2) = _e315;
    let _e316 = param_791;
    (*side_1) = _e316;
    let _e317 = param_792;
    (*dist_3) = _e317;
    return _e312;
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
    var phi_1396_: bool;
    var phi_1418_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e328 = (*rayOrigin_2);
    param_793 = _e328;
    let _e329 = (*rayDir);
    param_794 = _e329;
    let _e330 = (*maxDistance_2);
    param_795 = _e330;
    let _e331 = faceIndices_surface;
    param_796 = _e331;
    let _e332 = faceNormal_surface;
    param_797 = _e332;
    let _e333 = barycoord_surface;
    param_798 = _e333;
    let _e334 = side_surface;
    param_799 = _e334;
    let _e335 = dist_surface;
    param_800 = _e335;
    let _e336 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_793), (&param_794), (&param_795), (&param_796), (&param_797), (&param_798), (&param_799), (&param_800));
    let _e337 = param_796;
    faceIndices_surface = _e337;
    let _e338 = param_797;
    faceNormal_surface = _e338;
    let _e339 = param_798;
    barycoord_surface = _e339;
    let _e340 = param_799;
    side_surface = _e340;
    let _e341 = param_800;
    dist_surface = _e341;
    hit_surface = _e336;
    dist_closest = 100000000000000000000f;
    let _e342 = hit_surface;
    if _e342 {
        let _e343 = dist_closest;
        let _e344 = dist_surface;
        dist_closest = min(_e343, _e344);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e347 = (*rayDir)[1u];
    if (abs(_e347) > 0.0000000001f) {
        let _e351 = (*rayOrigin_2)[1u];
        let _e354 = (*rayDir)[1u];
        t = ((0.01f - _e351) / _e354);
        let _e356 = t;
        let _e357 = (_e356 > 0f);
        phi_1396_ = _e357;
        if _e357 {
            let _e358 = t;
            let _e359 = dist_closest;
            let _e360 = (*maxDistance_2);
            phi_1396_ = (_e358 < min(_e359, _e360));
        }
        let _e364 = phi_1396_;
        if _e364 {
            let _e365 = t;
            dist_ground = _e365;
            hit_ground = true;
        }
    }
    let _e366 = hit_surface;
    let _e367 = hit_ground;
    hit = (_e366 || _e367);
    let _e369 = hit;
    if !(_e369) {
        return false;
    }
    let _e371 = hit_surface;
    phi_1418_ = _e371;
    if _e371 {
        let _e372 = hit_ground;
        let _e374 = dist_surface;
        let _e375 = dist_ground;
        phi_1418_ = (!(_e372) || (_e374 <= _e375));
    }
    let _e379 = phi_1418_;
    if _e379 {
        let _e380 = (*rayOrigin_2);
        let _e381 = dist_surface;
        let _e382 = (*rayDir);
        (*P_4) = (_e380 + (_e382 * _e381));
        let _e385 = barycoord_surface;
        (*baryCoord_1) = _e385;
        let _e386 = faceNormal_surface;
        param_801 = _e386;
        let _e387 = safe_normalize_u0028_vf3_u003b((&param_801));
        (*Ng) = _e387;
        let _e388 = barycoord_surface;
        param_802 = _e388;
        let _e389 = faceIndices_surface;
        param_803 = _e389.xyz;
        let _e391 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_802), (&param_803));
        gN = _e391;
        let _e392 = barycoord_surface;
        param_804 = _e392;
        let _e393 = faceIndices_surface;
        param_805 = _e393.xyz;
        let _e395 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_804), (&param_805));
        gT = _e395;
        let _e396 = barycoord_surface;
        param_806 = _e396;
        let _e397 = faceIndices_surface;
        param_807 = _e397.xyz;
        let _e399 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_806), (&param_807));
        gS = _e399;
        let _e401 = unnamed.has_normals_surface;
        if (_e401 != 0u) {
            let _e403 = gN;
            local_12 = _e403.xyz;
        } else {
            let _e405 = (*Ng);
            local_12 = _e405;
        }
        let _e406 = local_12;
        (*Ns) = _e406;
        let _e408 = unnamed.has_uvs_surface;
        if (_e408 != 0u) {
            let _e411 = gN[3u];
            let _e413 = gT[3u];
            local_13 = vec2<f32>(_e411, _e413);
        } else {
            let _e415 = barycoord_surface;
            local_13 = _e415.xy;
        }
        let _e417 = local_13;
        (*texCoord_1) = _e417;
        let _e419 = unnamed.has_tangents_surface;
        if (_e419 != 0u) {
            let _e421 = gT;
            local_14 = _e421.xyz;
        } else {
            let _e423 = (*Ns);
            param_808 = _e423;
            let _e424 = normalToTangent_u0028_vf3_u003b((&param_808));
            local_14 = _e424;
        }
        let _e425 = local_14;
        (*Ts) = _e425;
        let _e426 = (*Ns);
        param_809 = _e426;
        let _e427 = safe_normalize_u0028_vf3_u003b((&param_809));
        let _e428 = (*Ts);
        param_810 = _e428;
        let _e429 = safe_normalize_u0028_vf3_u003b((&param_810));
        (*Bs) = cross(_e427, _e429);
        let _e432 = gS[0u];
        (*material) = select(1i, 0i, (_e432 > 0.5f));
    } else {
        let _e435 = hit_ground;
        if _e435 {
            let _e436 = (*rayOrigin_2);
            let _e437 = dist_ground;
            let _e438 = (*rayDir);
            (*P_4) = (_e436 + (_e438 * _e437));
            (*material) = 2i;
            (*baryCoord_1) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e441 = (*Ng);
            (*Ns) = _e441;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            (*Bs) = vec3<f32>(0f, 0f, -1f);
            let _e443 = (*P_4)[0u];
            let _e445 = (*P_4)[2u];
            (*texCoord_1) = (((vec2<f32>(_e443, -(_e445)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_4: Basis;
    var param_811: vec3<f32>;
    var param_812: vec3<f32>;

    let _e286 = (*nW_1);
    param_811 = _e286;
    let _e287 = safe_normalize_u0028_vf3_u003b((&param_811));
    basis_4.nW = _e287;
    let _e289 = (*nW_1);
    param_812 = _e289;
    let _e290 = normalToTangent_u0028_vf3_u003b((&param_812));
    basis_4.tW = _e290;
    let _e293 = basis_4.nW;
    let _e295 = basis_4.tW;
    basis_4.bW = cross(_e293, _e295);
    basis_4.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_4.texCoord = vec2<f32>(0f, 0f);
    let _e300 = basis_4;
    return _e300;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_3: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e292 = (*cameraWorld);
    lookDirection = (_e292 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e294 = (*inverseProjection);
    nearVector = (_e294 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e297 = nearVector[2u];
    let _e299 = nearVector[3u];
    nearDistance_1 = abs((_e297 / _e299));
    let _e302 = (*cameraWorld);
    origin_1 = (_e302 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e304 = (*inverseProjection);
    let _e305 = (*coordinate);
    direction_1 = (_e304 * vec4<f32>(_e305.x, _e305.y, 0.5f, 1f));
    let _e311 = direction_1[3u];
    let _e312 = direction_1;
    direction_1 = (_e312 / vec4(_e311));
    let _e315 = (*cameraWorld);
    let _e316 = direction_1;
    let _e318 = origin_1;
    direction_1 = ((_e315 * _e316) - _e318);
    let _e320 = direction_1;
    let _e322 = nearDistance_1;
    let _e324 = direction_1;
    let _e325 = lookDirection;
    let _e329 = origin_1;
    let _e331 = (_e329.xyz + ((_e320.xyz * _e322) / vec3(dot(_e324, _e325))));
    origin_1[0u] = _e331.x;
    origin_1[1u] = _e331.y;
    origin_1[2u] = _e331.z;
    let _e338 = origin_1;
    (*rayOrigin_3) = _e338.xyz;
    let _e340 = direction_1;
    (*rayDirection_2) = _e340.xyz;
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
    thin_walled_1 = false;
    let _e345 = gl_FragCoord_1;
    pixel = (_e345.xy + vec2<f32>(0.5f, 0.5f));
    let _e348 = pixel;
    let _e350 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e348 / _e350) * 2f));
    let _e356 = unnamed.invModelMatrix;
    let _e358 = unnamed.cameraWorldMatrix;
    let _e360 = ndc;
    param_813 = _e360;
    param_814 = (_e356 * _e358);
    let _e362 = unnamed.invProjectionMatrix;
    param_815 = _e362;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
    let _e363 = param_816;
    pW_3 = _e363;
    let _e364 = param_817;
    dW = _e364;
    let _e365 = dW;
    dW = normalize(_e365);
    let _e368 = unnamed.sunDir;
    param_818 = _e368;
    let _e369 = makeBasis_u0028_vf3_u003b((&param_818));
    sunBasis = _e369;
    let _e370 = pW_3;
    param_819 = _e370;
    let _e371 = dW;
    param_820 = _e371;
    param_821 = 100000000000000000000f;
    let _e372 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825), (&param_826), (&param_827), (&param_828), (&param_829));
    let _e373 = param_822;
    pW_hit = _e373;
    let _e374 = param_823;
    NsW = _e374;
    let _e375 = param_824;
    NgW = _e375;
    let _e376 = param_825;
    TsW = _e376;
    let _e377 = param_826;
    BsW = _e377;
    let _e378 = param_827;
    baryCoord_2 = _e378;
    let _e379 = param_828;
    texCoord_2 = _e379;
    let _e380 = param_829;
    material_1 = _e380;
    surface_hit = _e372;
    let _e381 = surface_hit;
    if !(_e381) {
        let _e383 = dW;
        param_830 = _e383;
        let _e384 = sunRadiance_u0028_vf3_u003b((&param_830));
        let _e385 = dW;
        param_831 = _e385;
        let _e386 = skyRadiance_u0028_vf3_u003b((&param_831));
        let _e387 = (_e384 + _e386);
        mtlxFragmentColor[0u] = _e387.x;
        mtlxFragmentColor[1u] = _e387.y;
        mtlxFragmentColor[2u] = _e387.z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    let _e395 = NsW;
    let _e396 = dW;
    if (dot(_e395, _e396) > 0f) {
        let _e399 = NsW;
        NsW = (_e399 * -1f);
    }
    let _e401 = NgW;
    let _e402 = NsW;
    if (dot(_e401, _e402) < 0f) {
        let _e405 = NgW;
        NgW = (_e405 * -1f);
    }
    let _e408 = unnamed.smooth_normals;
    if (_e408 != 0u) {
        let _e410 = NsW;
        param_832 = _e410;
        let _e411 = TsW;
        param_833 = _e411;
        let _e412 = BsW;
        param_834 = _e412;
        let _e413 = baryCoord_2;
        param_835 = _e413;
        let _e414 = texCoord_2;
        param_836 = _e414;
        let _e415 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_832), (&param_833), (&param_834), (&param_835), (&param_836));
        basis_5 = _e415;
    } else {
        let _e416 = NgW;
        param_837 = _e416;
        let _e417 = TsW;
        param_838 = _e417;
        let _e418 = BsW;
        param_839 = _e418;
        let _e419 = baryCoord_2;
        param_840 = _e419;
        let _e420 = texCoord_2;
        param_841 = _e420;
        let _e421 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_837), (&param_838), (&param_839), (&param_840), (&param_841));
        basis_5 = _e421;
    }
    let _e422 = dW;
    winputW = -(_e422);
    let _e424 = winputW;
    param_842 = _e424;
    let _e425 = basis_5;
    param_843 = _e425;
    let _e426 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_842), (&param_843));
    winputL_2 = _e426;
    let _e428 = winputL_2[2u];
    if (abs(_e428) < 0.001f) {
        mtlxFragmentColor[0u] = vec3<f32>(0f, 0f, 0f).x;
        mtlxFragmentColor[1u] = vec3<f32>(0f, 0f, 0f).y;
        mtlxFragmentColor[2u] = vec3<f32>(0f, 0f, 0f).z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    rndSeed_1 = 0u;
    let _e438 = material_1;
    if (_e438 == 1i) {
        let _e440 = pW_hit;
        param_844 = _e440;
        let _e441 = basis_5;
        param_845 = _e441;
        let _e442 = winputL_2;
        param_846 = _e442;
        let _e443 = rndSeed_1;
        param_847 = _e443;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_844), (&param_845), (&param_846), (&param_847));
        let _e444 = param_847;
        rndSeed_1 = _e444;
    }
    let _e445 = dW;
    let _e447 = basis_5.nW;
    viewReflectW = reflect(_e445, _e447);
    let _e449 = viewReflectW;
    param_848 = _e449;
    let _e450 = basis_5;
    param_849 = _e450;
    let _e451 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_848), (&param_849));
    viewReflectL = _e451;
    let _e453 = viewReflectL[2u];
    if (_e453 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e455 = material_1;
    if (_e455 == 1i) {
        let _e457 = pW_hit;
        param_850 = _e457;
        let _e458 = basis_5;
        param_851 = _e458;
        let _e459 = winputL_2;
        param_852 = _e459;
        let _e460 = viewReflectL;
        param_853 = _e460;
        let _e461 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_850), (&param_851), (&param_852), (&param_853));
        L_12 = _e461;
    } else {
        let _e462 = material_1;
        if (_e462 == 2i) {
            let _e464 = pW_hit;
            param_854 = _e464;
            let _e465 = ground_albedo_u0028_vf3_u003b((&param_854));
            L_12 = _e465;
        } else {
            let _e467 = unnamed.neutral_color;
            let _e469 = basis_5.nW;
            param_855 = _e469;
            let _e470 = skyRadiance_u0028_vf3_u003b((&param_855));
            L_12 = (_e467 * _e470);
        }
    }
    let _e472 = L_12;
    let _e474 = unnamed.firefly_clamp;
    let _e476 = clamp(_e472, vec3<f32>(0f, 0f, 0f), vec3(_e474));
    mtlxFragmentColor[0u] = _e476.x;
    mtlxFragmentColor[1u] = _e476.y;
    mtlxFragmentColor[2u] = _e476.z;
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
