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

    let _e286 = (*pW)[0u];
    let _e288 = (*pW)[2u];
    uv = (((vec2<f32>(_e286, -(_e288)) / vec2(200f)) * 2f) + vec2(0.5f));
    let _e296 = uv;
    let _e297 = textureSampleLevel(ground_texture_texture, ground_texture_sampler, _e296, 0.0);
    return _e297.xyz;
}

fn mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(closureData: ptr<function, ClosureData>, fg: ptr<function, vec3<f32>>, bg: ptr<function, vec3<f32>>, mixValue: ptr<function, f32>, result: ptr<function, vec3<f32>>) {
    let _e288 = (*bg);
    let _e289 = (*fg);
    let _e290 = (*mixValue);
    (*result) = mix(_e288, _e289, vec3(_e290));
    return;
}

fn mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b(cosTheta: ptr<function, f32>, F0_: ptr<function, vec3<f32>>, F90_: ptr<function, vec3<f32>>, exponent: ptr<function, f32>) -> vec3<f32> {
    var x: f32;

    let _e288 = (*cosTheta);
    x = clamp((1f - _e288), 0f, 1f);
    let _e291 = (*F0_);
    let _e292 = (*F90_);
    let _e293 = x;
    let _e294 = (*exponent);
    return mix(_e291, _e292, vec3(pow(_e293, _e294)));
}

fn mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b(N: ptr<function, vec3<f32>>, V: ptr<function, vec3<f32>>) -> vec3<f32> {
    var local: vec3<f32>;

    let _e286 = (*N);
    let _e287 = (*V);
    if (dot(_e286, _e287) < 0f) {
        let _e290 = (*N);
        local = -(_e290);
    } else {
        let _e292 = (*N);
        local = _e292;
    }
    let _e293 = local;
    return _e293;
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

    let _e299 = (*closureData_1).closureType;
    if (_e299 == 4i) {
        let _e302 = (*closureData_1).N;
        param = _e302;
        let _e304 = (*closureData_1).V;
        param_1 = _e304;
        let _e305 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param), (&param_1));
        N_1 = _e305;
        let _e306 = N_1;
        let _e308 = (*closureData_1).V;
        NdotV = clamp(dot(_e306, _e308), 0.00000001f, 1f);
        let _e311 = NdotV;
        param_2 = _e311;
        let _e312 = (*color0_);
        param_3 = _e312;
        let _e313 = (*color90_);
        param_4 = _e313;
        let _e314 = (*exponent_1);
        param_5 = _e314;
        let _e315 = mx_fresnel_schlick_u0028_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_2), (&param_3), (&param_4), (&param_5));
        f = _e315;
        let _e316 = (*base);
        let _e317 = f;
        (*result_1) = (_e316 * _e317);
    }
    return;
}

fn mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b(closureData_2: ptr<function, ClosureData>, in1_: ptr<function, vec3<f32>>, in2_: ptr<function, vec3<f32>>, result_2: ptr<function, vec3<f32>>) {
    let _e287 = (*in1_);
    let _e288 = (*in2_);
    (*result_2) = (_e287 * _e288);
    return;
}

fn mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b(closureData_3: ptr<function, ClosureData>, color: ptr<function, vec3<f32>>, result_3: ptr<function, vec3<f32>>) {
    let _e287 = (*closureData_3).closureType;
    if (_e287 == 4i) {
        let _e289 = (*color);
        (*result_3) = _e289;
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_4: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e288 = (*in2_1);
    tint = clamp(_e288, vec3(0f), vec3(1f));
    let _e293 = (*in1_1).response;
    let _e294 = tint;
    (*result_4).response = (_e293 * _e294);
    let _e298 = (*in1_1).throughput;
    (*result_4).throughput = _e298;
    return;
}

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_5: ptr<function, BSDF>) {
    let _e288 = (*top).response;
    let _e290 = (*base_1).response;
    let _e292 = (*top).throughput;
    (*result_5).response = (_e288 + (_e290 * _e292));
    let _e297 = (*top).throughput;
    let _e299 = (*base_1).throughput;
    (*result_5).throughput = (_e297 * _e299);
    return;
}

fn mx_latlong_projection_u0028_vf3_u003b(dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var latitude: f32;
    var longitude: f32;

    let _e287 = (*dir)[1u];
    latitude = ((-(asin(_e287)) * 0.31830987f) + 0.5f);
    let _e293 = (*dir)[0u];
    let _e295 = (*dir)[2u];
    longitude = (((atan2(_e293, -(_e295)) * 0.31830987f) * 0.5f) + 0.5f);
    let _e301 = longitude;
    let _e302 = latitude;
    return vec2<f32>(_e301, _e302);
}

fn mx_matrix_mul_u0028_mf44_u003b_vf4_u003b(m: ptr<function, mat4x4<f32>>, v: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e285 = (*m);
    let _e286 = (*v);
    return (_e285 * _e286);
}

fn mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_1: ptr<function, vec3<f32>>, transform: ptr<function, mat4x4<f32>>, lod: ptr<function, f32>) -> vec3<f32> {
    var envDir: vec3<f32>;
    var param_6: mat4x4<f32>;
    var param_7: vec4<f32>;
    var uv_1: vec2<f32>;
    var param_8: vec3<f32>;

    let _e291 = (*dir_1);
    let _e296 = (*transform);
    param_6 = _e296;
    param_7 = vec4<f32>(_e291.x, _e291.y, _e291.z, 0f);
    let _e297 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_6), (&param_7));
    envDir = normalize(_e297.xyz);
    let _e300 = envDir;
    param_8 = _e300;
    let _e301 = mx_latlong_projection_u0028_vf3_u003b((&param_8));
    uv_1 = _e301;
    let _e302 = uv_1;
    let _e303 = textureSampleLevel(envMapIrradiance_texture, envMapIrradiance_sampler, _e302, 0.0);
    return _e303.xyz;
}

fn mtlxEnvMatrix_u0028_() -> mat4x4<f32> {
    var a: f32;
    var c: f32;
    var s: f32;

    a = 1.5707964f;
    let _e286 = a;
    c = cos(_e286);
    let _e288 = a;
    s = sin(_e288);
    let _e290 = c;
    let _e291 = s;
    let _e293 = s;
    let _e294 = c;
    return mat4x4<f32>(vec4<f32>(_e290, 0f, -(_e291), 0f), vec4<f32>(0f, -1f, 0f, 0f), vec4<f32>(_e293, 0f, _e294, 0f), vec4<f32>(0f, 0f, 0f, 1f));
}

fn mx_environment_irradiance_u0028_vf3_u003b(N_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Li: vec3<f32>;
    var param_9: vec3<f32>;
    var param_10: mat4x4<f32>;
    var param_11: f32;

    let _e288 = mtlxEnvMatrix_u0028_();
    let _e289 = (*N_2);
    param_9 = _e289;
    param_10 = _e288;
    param_11 = 0f;
    let _e290 = mx_latlong_map_lookup_irradiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_9), (&param_10), (&param_11));
    Li = _e290;
    let _e291 = Li;
    let _e293 = unnamed.skyPower;
    return (_e291 * _e293);
}

fn mx_square_u0028_f1_u003b(x_1: ptr<function, f32>) -> f32 {
    let _e284 = (*x_1);
    let _e285 = (*x_1);
    return (_e284 * _e285);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_12: f32;

    let _e287 = (*roughness);
    let _e290 = (*NdotV_1);
    let _e292 = (*roughness);
    let _e295 = (*roughness);
    param_12 = _e295;
    let _e296 = mx_square_u0028_f1_u003b((&param_12));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e287)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e290) * _e292)) + (vec2<f32>(1.4385f, 2.0315f) * _e296));
    let _e300 = r[0u];
    let _e302 = r[1u];
    return (_e300 / _e302);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_13: f32;
    var param_14: f32;

    let _e288 = (*NdotV_2);
    param_13 = _e288;
    let _e289 = (*roughness_1);
    param_14 = _e289;
    let _e290 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_13), (&param_14));
    dirAlbedo = _e290;
    let _e291 = dirAlbedo;
    return clamp(_e291, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e284 = (*x_2);
    let _e285 = (*x_2);
    return (_e284 * _e285);
}

fn mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b(roughness_2: ptr<function, f32>) -> f32 {
    var A: f32;

    let _e285 = (*roughness_2);
    A = (1f / (1f + (0.2877934f * _e285)));
    let _e289 = A;
    let _e290 = (*roughness_2);
    return (_e289 * (1f + (0.07248821f * _e290)));
}

fn mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(cosTheta_1: ptr<function, f32>, roughness_3: ptr<function, f32>) -> f32 {
    var A_1: f32;
    var B: f32;
    var Si: f32;
    var param_15: f32;
    var G: f32;

    let _e290 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e290)));
    let _e294 = (*roughness_3);
    let _e295 = A_1;
    B = (_e294 * _e295);
    let _e297 = (*cosTheta_1);
    param_15 = _e297;
    let _e298 = mx_square_u0028_f1_u003b((&param_15));
    Si = sqrt(max(0f, (1f - _e298)));
    let _e302 = Si;
    let _e303 = (*cosTheta_1);
    let _e306 = Si;
    let _e307 = (*cosTheta_1);
    let _e311 = Si;
    let _e312 = (*cosTheta_1);
    let _e314 = Si;
    let _e315 = Si;
    let _e317 = Si;
    let _e321 = Si;
    G = ((_e302 * (acos(clamp(_e303, -1f, 1f)) - (_e306 * _e307))) + ((2f * (((_e311 / _e312) * (1f - ((_e314 * _e315) * _e317))) - _e321)) / 3f));
    let _e326 = A_1;
    let _e327 = B;
    let _e328 = G;
    return (_e326 + ((_e327 * _e328) * 0.31830987f));
}

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_16: f32;
    var param_17: f32;
    var avgAlbedo: f32;
    var param_18: f32;
    var colorMultiScatter: vec3<f32>;
    var param_19: vec3<f32>;

    let _e293 = (*cosTheta_2);
    param_16 = _e293;
    let _e294 = (*roughness_4);
    param_17 = _e294;
    let _e295 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_16), (&param_17));
    dirAlbedo_1 = _e295;
    let _e296 = (*roughness_4);
    param_18 = _e296;
    let _e297 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_18));
    avgAlbedo = _e297;
    let _e298 = (*color_1);
    param_19 = _e298;
    let _e299 = mx_square_u0028_vf3_u003b((&param_19));
    let _e300 = avgAlbedo;
    let _e302 = (*color_1);
    let _e303 = avgAlbedo;
    colorMultiScatter = ((_e299 * _e300) / (vec3<f32>(1f, 1f, 1f) - (_e302 * max(0f, (1f - _e303)))));
    let _e309 = colorMultiScatter;
    let _e310 = (*color_1);
    let _e311 = dirAlbedo_1;
    return mix(_e309, _e310, vec3(_e311));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_20: f32;
    var A_2: f32;
    var B_1: f32;

    let _e294 = (*LdotV);
    let _e295 = (*NdotL);
    let _e296 = (*NdotV_3);
    s_1 = (_e294 - (_e295 * _e296));
    let _e299 = s_1;
    if (_e299 > 0f) {
        let _e301 = s_1;
        let _e302 = (*NdotL);
        let _e303 = (*NdotV_3);
        local_1 = (_e301 / max(_e302, _e303));
    } else {
        local_1 = 0f;
    }
    let _e306 = local_1;
    stinv = _e306;
    let _e307 = (*roughness_5);
    param_20 = _e307;
    let _e308 = mx_square_u0028_f1_u003b((&param_20));
    sigma2_ = _e308;
    let _e309 = sigma2_;
    let _e310 = sigma2_;
    A_2 = (1f - (0.5f * (_e309 / (_e310 + 0.33f))));
    let _e315 = sigma2_;
    let _e317 = sigma2_;
    B_1 = ((0.45f * _e315) / (_e317 + 0.09f));
    let _e320 = A_2;
    let _e321 = B_1;
    let _e322 = stinv;
    return (_e320 + (_e321 * _e322));
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

    let _e304 = (*LdotV_1);
    let _e305 = (*NdotL_1);
    let _e306 = (*NdotV_4);
    s_2 = (_e304 - (_e305 * _e306));
    let _e309 = s_2;
    if (_e309 > 0f) {
        let _e311 = s_2;
        let _e312 = (*NdotL_1);
        let _e313 = (*NdotV_4);
        local_2 = (_e311 / max(_e312, _e313));
    } else {
        let _e316 = s_2;
        local_2 = _e316;
    }
    let _e317 = local_2;
    stinv_1 = _e317;
    let _e318 = (*roughness_6);
    A_3 = (1f / (1f + (0.2877934f * _e318)));
    let _e322 = (*color_2);
    let _e323 = A_3;
    let _e325 = (*roughness_6);
    let _e326 = stinv_1;
    lobeSingleScatter = ((_e322 * _e323) * (1f + (_e325 * _e326)));
    let _e330 = (*NdotV_4);
    param_21 = _e330;
    let _e331 = (*roughness_6);
    param_22 = _e331;
    let _e332 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_21), (&param_22));
    dirAlbedoV = _e332;
    let _e333 = (*NdotL_1);
    param_23 = _e333;
    let _e334 = (*roughness_6);
    param_24 = _e334;
    let _e335 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_23), (&param_24));
    dirAlbedoL = _e335;
    let _e336 = (*roughness_6);
    param_25 = _e336;
    let _e337 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_25));
    avgAlbedo_1 = _e337;
    let _e338 = (*color_2);
    param_26 = _e338;
    let _e339 = mx_square_u0028_vf3_u003b((&param_26));
    let _e340 = avgAlbedo_1;
    let _e342 = (*color_2);
    let _e343 = avgAlbedo_1;
    colorMultiScatter_1 = ((_e339 * _e340) / (vec3<f32>(1f, 1f, 1f) - (_e342 * max(0f, (1f - _e343)))));
    let _e349 = colorMultiScatter_1;
    let _e350 = dirAlbedoV;
    let _e354 = dirAlbedoL;
    let _e358 = avgAlbedo_1;
    lobeMultiScatter = (((_e349 * max(0.00000001f, (1f - _e350))) * max(0.00000001f, (1f - _e354))) / vec3(max(0.00000001f, (1f - _e358))));
    let _e363 = lobeSingleScatter;
    let _e364 = lobeMultiScatter;
    return (_e363 + _e364);
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
    let _e318 = (*weight);
    if (_e318 < 0.00000001f) {
        return;
    }
    let _e321 = (*closureData_6).V;
    V_1 = _e321;
    let _e323 = (*closureData_6).L;
    L = _e323;
    let _e324 = (*N_3);
    param_27 = _e324;
    let _e325 = V_1;
    param_28 = _e325;
    let _e326 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_27), (&param_28));
    (*N_3) = _e326;
    let _e327 = (*N_3);
    let _e328 = V_1;
    NdotV_5 = clamp(dot(_e327, _e328), 0.00000001f, 1f);
    let _e332 = (*closureData_6).closureType;
    if (_e332 == 1i) {
        let _e334 = (*N_3);
        let _e335 = L;
        NdotL_2 = clamp(dot(_e334, _e335), 0.00000001f, 1f);
        let _e338 = L;
        let _e339 = V_1;
        LdotV_2 = clamp(dot(_e338, _e339), 0.00000001f, 1f);
        let _e342 = (*energy_compensation);
        if _e342 {
            let _e343 = NdotV_5;
            param_29 = _e343;
            let _e344 = NdotL_2;
            param_30 = _e344;
            let _e345 = LdotV_2;
            param_31 = _e345;
            let _e346 = (*roughness_7);
            param_32 = _e346;
            let _e347 = (*color_3);
            param_33 = _e347;
            let _e348 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_29), (&param_30), (&param_31), (&param_32), (&param_33));
            local_3 = _e348;
        } else {
            let _e349 = NdotV_5;
            param_34 = _e349;
            let _e350 = NdotL_2;
            param_35 = _e350;
            let _e351 = LdotV_2;
            param_36 = _e351;
            let _e352 = (*roughness_7);
            param_37 = _e352;
            let _e353 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_34), (&param_35), (&param_36), (&param_37));
            let _e354 = (*color_3);
            local_3 = (_e354 * _e353);
        }
        let _e356 = local_3;
        diffuse = _e356;
        let _e357 = diffuse;
        let _e359 = (*closureData_6).occlusion;
        let _e361 = (*weight);
        let _e363 = NdotL_2;
        (*bsdf).response = ((((_e357 * _e359) * _e361) * _e363) * 0.31830987f);
    } else {
        let _e368 = (*closureData_6).closureType;
        if (_e368 == 3i) {
            let _e370 = (*energy_compensation);
            if _e370 {
                let _e371 = NdotV_5;
                param_38 = _e371;
                let _e372 = (*roughness_7);
                param_39 = _e372;
                let _e373 = (*color_3);
                param_40 = _e373;
                let _e374 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_38), (&param_39), (&param_40));
                local_4 = _e374;
            } else {
                let _e375 = NdotV_5;
                param_41 = _e375;
                let _e376 = (*roughness_7);
                param_42 = _e376;
                let _e377 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_41), (&param_42));
                let _e378 = (*color_3);
                local_4 = (_e378 * _e377);
            }
            let _e380 = local_4;
            diffuse_1 = _e380;
            let _e381 = (*N_3);
            param_43 = _e381;
            let _e382 = mx_environment_irradiance_u0028_vf3_u003b((&param_43));
            Li_1 = _e382;
            let _e383 = Li_1;
            let _e384 = diffuse_1;
            let _e386 = (*weight);
            (*bsdf).response = ((_e383 * _e384) * _e386);
        }
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_6: ptr<function, BSDF>) {
    var weight_1: f32;

    let _e288 = (*in2_2);
    weight_1 = clamp(_e288, 0f, 1f);
    let _e291 = (*in1_2).response;
    let _e292 = weight_1;
    (*result_6).response = (_e291 * _e292);
    let _e296 = (*in1_2).throughput;
    (*result_6).throughput = _e296;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_7: ptr<function, BSDF>) {
    let _e288 = (*in1_3).response;
    let _e290 = (*in2_3).response;
    (*result_7).response = (_e288 + _e290);
    let _e294 = (*in1_3).throughput;
    let _e296 = (*in2_3).throughput;
    (*result_7).throughput = max(((_e294 + _e296) - vec3(1f)), vec3(0f));
    return;
}

fn mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b(dist: ptr<function, f32>, shape: ptr<function, vec3<f32>>) -> vec3<f32> {
    var num1_: vec3<f32>;
    var num2_: vec3<f32>;
    var denom: f32;

    let _e288 = (*shape);
    let _e290 = (*dist);
    num1_ = exp((-(_e288) * _e290));
    let _e293 = (*shape);
    let _e295 = (*dist);
    num2_ = exp(((-(_e293) * _e295) / vec3(3f)));
    let _e300 = (*dist);
    denom = max(_e300, 0.00000001f);
    let _e302 = num1_;
    let _e303 = num2_;
    let _e305 = denom;
    return ((_e302 + _e303) / vec3(_e305));
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

    let _e297 = (*N_4);
    let _e298 = (*L_1);
    theta = acos(dot(_e297, _e298));
    let _e301 = (*mfp);
    shape_1 = (vec3<f32>(1f, 1f, 1f) / max(_e301, vec3(0.1f)));
    sumD = vec3<f32>(0f, 0f, 0f);
    sumR = vec3<f32>(0f, 0f, 0f);
    i = 0i;
    loop {
        let _e305 = i;
        if (_e305 < 32i) {
            let _e307 = i;
            x_3 = (-3.1415927f + ((f32(_e307) + 0.5f) * 0.19634955f));
            let _e312 = (*radius);
            let _e313 = x_3;
            dist_1 = (_e312 * abs((2f * sin((_e313 * 0.5f)))));
            let _e319 = dist_1;
            param_44 = _e319;
            let _e320 = shape_1;
            param_45 = _e320;
            let _e321 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_44), (&param_45));
            R = _e321;
            let _e322 = R;
            let _e323 = theta;
            let _e324 = x_3;
            let _e329 = sumD;
            sumD = (_e329 + (_e322 * max(cos((_e323 + _e324)), 0f)));
            let _e331 = R;
            let _e332 = sumR;
            sumR = (_e332 + _e331);
            continue;
        } else {
            break;
        }
        continuing {
            let _e334 = i;
            i = (_e334 + 1i);
        }
    }
    let _e336 = sumD;
    let _e337 = sumR;
    return (_e336 / _e337);
}

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_5: ptr<function, vec3<f32>>, L_2: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_46: vec3<f32>;
    var param_47: vec3<f32>;
    var param_48: f32;
    var param_49: vec3<f32>;

    let _e294 = (*N_5);
    let _e295 = fwidth(_e294);
    let _e297 = (*P);
    let _e298 = fwidth(_e297);
    curvature = (length(_e295) / length(_e298));
    let _e301 = curvature;
    radius_1 = (1f / max(_e301, 0.01f));
    let _e304 = (*albedo);
    let _e305 = (*N_5);
    param_46 = _e305;
    let _e306 = (*L_2);
    param_47 = _e306;
    let _e307 = radius_1;
    param_48 = _e307;
    let _e308 = (*mfp_1);
    param_49 = _e308;
    let _e309 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_46), (&param_47), (&param_48), (&param_49));
    return ((_e304 * _e309) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
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
    let _e307 = (*weight_2);
    if (_e307 < 0.00000001f) {
        return;
    }
    let _e310 = (*closureData_9).V;
    V_2 = _e310;
    let _e312 = (*closureData_9).L;
    L_3 = _e312;
    let _e314 = (*closureData_9).P;
    P_1 = _e314;
    let _e316 = (*closureData_9).occlusion;
    occlusion = _e316;
    let _e317 = (*N_6);
    param_50 = _e317;
    let _e318 = V_2;
    param_51 = _e318;
    let _e319 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_50), (&param_51));
    (*N_6) = _e319;
    let _e321 = (*closureData_9).closureType;
    if (_e321 == 1i) {
        let _e323 = (*N_6);
        param_52 = _e323;
        let _e324 = L_3;
        param_53 = _e324;
        let _e325 = P_1;
        param_54 = _e325;
        let _e326 = (*color_4);
        param_55 = _e326;
        let _e327 = (*radius_2);
        param_56 = _e327;
        let _e328 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_52), (&param_53), (&param_54), (&param_55), (&param_56));
        sss = _e328;
        let _e329 = (*N_6);
        let _e330 = L_3;
        NdotL_3 = clamp(dot(_e329, _e330), 0.00000001f, 1f);
        let _e333 = NdotL_3;
        let _e334 = occlusion;
        visibleOcclusion = (1f - (_e333 * (1f - _e334)));
        let _e338 = sss;
        let _e339 = visibleOcclusion;
        let _e341 = (*weight_2);
        (*bsdf_1).response = ((_e338 * _e339) * _e341);
    } else {
        let _e345 = (*closureData_9).closureType;
        if (_e345 == 3i) {
            let _e347 = (*N_6);
            param_57 = _e347;
            let _e348 = mx_environment_irradiance_u0028_vf3_u003b((&param_57));
            Li_2 = _e348;
            let _e349 = Li_2;
            let _e350 = (*color_4);
            let _e352 = (*weight_2);
            (*bsdf_1).response = ((_e349 * _e350) * _e352);
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
    let _e294 = (*weight_3);
    if (_e294 < 0.00000001f) {
        return;
    }
    let _e297 = (*closureData_10).V;
    V_3 = _e297;
    let _e299 = (*closureData_10).L;
    L_4 = _e299;
    let _e300 = (*N_7);
    (*N_7) = -(_e300);
    let _e303 = (*closureData_10).closureType;
    if (_e303 == 1i) {
        let _e305 = (*N_7);
        let _e306 = L_4;
        NdotL_4 = clamp(dot(_e305, _e306), 0f, 1f);
        let _e309 = (*color_5);
        let _e310 = (*weight_3);
        let _e312 = NdotL_4;
        (*bsdf_2).response = (((_e309 * _e310) * _e312) * 0.31830987f);
    } else {
        let _e317 = (*closureData_10).closureType;
        if (_e317 == 3i) {
            let _e319 = (*N_7);
            param_58 = _e319;
            let _e320 = mx_environment_irradiance_u0028_vf3_u003b((&param_58));
            Li_3 = _e320;
            let _e321 = Li_3;
            let _e322 = (*color_5);
            let _e324 = (*weight_3);
            (*bsdf_2).response = ((_e321 * _e322) * _e324);
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_4: ptr<function, f32>, y: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_1: f32;
    var o: f32;
    var param_59: f32;

    let _e289 = (*y);
    let _e290 = (*y);
    let _e294 = (*y);
    let _e295 = (*y);
    s_3 = ((_e289 * (0.0206607f + (1.58491f * _e290))) / (0.0379424f + (_e294 * (1.32227f + _e295))));
    let _e300 = (*y);
    let _e301 = (*y);
    let _e302 = (*y);
    let _e303 = (*y);
    let _e305 = (*y);
    let _e313 = (*y);
    m_1 = ((_e300 * (-0.193854f + (_e301 * (-1.14885f + (_e302 * (1.7932f - ((0.95943f * _e303) * _e305))))))) / (0.046391f + _e313));
    let _e316 = (*y);
    let _e317 = (*y);
    let _e320 = (*y);
    let _e324 = (*y);
    let _e325 = (*y);
    o = ((_e316 * (0.000654023f + ((-0.0207818f + (0.119681f * _e317)) * _e320))) / (1.26264f + (_e324 * (-1.92021f + _e325))));
    let _e330 = (*x_4);
    let _e331 = m_1;
    let _e333 = s_3;
    param_59 = ((_e330 - _e331) / _e333);
    let _e335 = mx_square_u0028_f1_u003b((&param_59));
    let _e338 = s_3;
    let _e341 = o;
    return ((exp((-0.5f * _e335)) / (_e338 * 2.5066283f)) + _e341);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_3: ptr<function, f32>) -> f32 {
    let _e284 = (*cosTheta_3);
    return (max(_e284, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_5: ptr<function, f32>, y_1: ptr<function, f32>) -> f32 {
    let _e285 = (*x_5);
    let _e288 = (*y_1);
    let _e291 = (*y_1);
    let _e293 = (*y_1);
    let _e295 = (*y_1);
    let _e297 = (*x_5);
    let _e300 = (*x_5);
    let _e302 = (*y_1);
    let _e305 = (*y_1);
    let _e307 = (*y_1);
    return (((((sqrt((1f - _e285)) * (_e288 - 1f)) * _e291) * _e293) * _e295) / (((0.0000254053f + (1.71228f * _e297)) - ((1.71506f * _e300) * _e302)) + ((1.34174f * _e305) * _e307)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_6: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    let _e285 = (*x_6);
    let _e287 = (*y_2);
    let _e290 = (*y_2);
    let _e292 = (*x_6);
    let _e294 = (*x_6);
    let _e297 = (*x_6);
    let _e299 = (*y_2);
    return ((((2.58126f * _e285) + (0.813703f * _e287)) * _e290) / ((1f + ((0.310327f * _e292) * _e294)) + ((2.60994f * _e297) * _e299)));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_2: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e285 = (*m_2);
    let _e286 = (*v_1);
    return (_e285 * _e286);
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_8: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_1: f32;
    var b: f32;
    var X: vec3<f32>;
    var Y: vec3<f32>;

    let _e290 = (*N_8)[2u];
    sign_ = select(1f, -1f, (_e290 < 0f));
    let _e293 = sign_;
    let _e295 = (*N_8)[2u];
    a_1 = (-1f / (_e293 + _e295));
    let _e299 = (*N_8)[0u];
    let _e301 = (*N_8)[1u];
    let _e303 = a_1;
    b = ((_e299 * _e301) * _e303);
    let _e305 = sign_;
    let _e307 = (*N_8)[0u];
    let _e310 = (*N_8)[0u];
    let _e312 = a_1;
    let _e315 = sign_;
    let _e316 = b;
    let _e318 = sign_;
    let _e321 = (*N_8)[0u];
    X = vec3<f32>((1f + (((_e305 * _e307) * _e310) * _e312)), (_e315 * _e316), (-(_e318) * _e321));
    let _e324 = b;
    let _e325 = sign_;
    let _e327 = (*N_8)[1u];
    let _e329 = (*N_8)[1u];
    let _e331 = a_1;
    let _e335 = (*N_8)[1u];
    Y = vec3<f32>(_e324, (_e325 + ((_e327 * _e329) * _e331)), -(_e335));
    let _e338 = X;
    let _e339 = Y;
    let _e340 = (*N_8);
    return mat3x3<f32>(vec3<f32>(_e338.x, _e338.y, _e338.z), vec3<f32>(_e339.x, _e339.y, _e339.z), vec3<f32>(_e340.x, _e340.y, _e340.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_4: ptr<function, vec3<f32>>, N_9: ptr<function, vec3<f32>>, NdotV_6: ptr<function, f32>) -> mat3x3<f32> {
    var X_1: vec3<f32>;
    var lenSqr: f32;
    var Y_1: vec3<f32>;
    var param_60: vec3<f32>;

    let _e290 = (*V_4);
    let _e291 = (*N_9);
    let _e292 = (*NdotV_6);
    X_1 = (_e290 - (_e291 * _e292));
    let _e295 = X_1;
    let _e296 = X_1;
    lenSqr = dot(_e295, _e296);
    let _e298 = lenSqr;
    if (_e298 > 0f) {
        let _e300 = lenSqr;
        let _e302 = X_1;
        X_1 = (_e302 * inverseSqrt(_e300));
        let _e304 = (*N_9);
        let _e305 = X_1;
        Y_1 = cross(_e304, _e305);
        let _e307 = X_1;
        let _e308 = Y_1;
        let _e309 = (*N_9);
        return mat3x3<f32>(vec3<f32>(_e307.x, _e307.y, _e307.z), vec3<f32>(_e308.x, _e308.y, _e308.z), vec3<f32>(_e309.x, _e309.y, _e309.z));
    }
    let _e323 = (*N_9);
    param_60 = _e323;
    let _e324 = mx_orthonormal_basis_u0028_vf3_u003b((&param_60));
    return _e324;
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

    let _e305 = (*V_5);
    param_61 = _e305;
    let _e306 = (*N_10);
    param_62 = _e306;
    let _e307 = (*NdotV_7);
    param_63 = _e307;
    let _e308 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_61), (&param_62), (&param_63));
    toLTC = transpose(_e308);
    let _e310 = toLTC;
    param_64 = _e310;
    let _e311 = (*L_5);
    param_65 = _e311;
    let _e312 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_64), (&param_65));
    w = _e312;
    let _e313 = (*NdotV_7);
    param_66 = _e313;
    let _e314 = (*roughness_8);
    param_67 = _e314;
    let _e315 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_66), (&param_67));
    aInv = _e315;
    let _e316 = (*NdotV_7);
    param_68 = _e316;
    let _e317 = (*roughness_8);
    param_69 = _e317;
    let _e318 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_68), (&param_69));
    bInv = _e318;
    let _e319 = aInv;
    let _e321 = w[0u];
    let _e323 = bInv;
    let _e325 = w[2u];
    let _e328 = aInv;
    let _e330 = w[1u];
    let _e333 = w[2u];
    wo = vec3<f32>(((_e319 * _e321) + (_e323 * _e325)), (_e328 * _e330), _e333);
    let _e335 = wo;
    let _e336 = wo;
    lenSqr_1 = dot(_e335, _e336);
    let _e339 = wo[2u];
    param_70 = _e339;
    let _e340 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_70));
    let _e341 = aInv;
    let _e342 = lenSqr_1;
    param_71 = (_e341 / _e342);
    let _e344 = mx_square_u0028_f1_u003b((&param_71));
    return (_e340 * _e344);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_8: ptr<function, f32>, roughness_9: ptr<function, f32>) -> f32 {
    var r_1: vec2<f32>;
    var param_72: f32;
    var param_73: f32;

    let _e288 = (*NdotV_8);
    let _e291 = (*roughness_9);
    let _e294 = (*NdotV_8);
    let _e296 = (*roughness_9);
    let _e299 = (*NdotV_8);
    param_72 = _e299;
    let _e300 = mx_square_u0028_f1_u003b((&param_72));
    let _e303 = (*roughness_9);
    param_73 = _e303;
    let _e304 = mx_square_u0028_f1_u003b((&param_73));
    r_1 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e288)) + (vec2<f32>(799.08826f, 442.7821f) * _e291)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e294) * _e296)) + (vec2<f32>(60.28956f, 121.81241f) * _e300)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e304));
    let _e308 = r_1[0u];
    let _e310 = r_1[1u];
    return (_e308 / _e310);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_9: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var dirAlbedo_2: f32;
    var param_74: f32;
    var param_75: f32;

    let _e288 = (*NdotV_9);
    param_74 = _e288;
    let _e289 = (*roughness_10);
    param_75 = _e289;
    let _e290 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_74), (&param_75));
    dirAlbedo_2 = _e290;
    let _e291 = dirAlbedo_2;
    return clamp(_e291, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e288 = (*roughness_11);
    invRoughness = (1f / max(_e288, 0.005f));
    let _e291 = (*NdotH);
    let _e292 = (*NdotH);
    cos2_ = (_e291 * _e292);
    let _e294 = cos2_;
    sin2_ = (1f - _e294);
    let _e296 = invRoughness;
    let _e298 = sin2_;
    let _e299 = invRoughness;
    return (((2f + _e296) * pow(_e298, (_e299 * 0.5f))) / 6.2831855f);
}

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_10: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var D: f32;
    var param_76: f32;
    var param_77: f32;
    var F: f32;
    var G_1: f32;

    let _e292 = (*NdotH_1);
    param_76 = _e292;
    let _e293 = (*roughness_12);
    param_77 = _e293;
    let _e294 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_76), (&param_77));
    D = _e294;
    F = 1f;
    G_1 = 1f;
    let _e295 = D;
    let _e296 = F;
    let _e298 = G_1;
    let _e300 = (*NdotL_5);
    let _e301 = (*NdotV_10);
    let _e303 = (*NdotL_5);
    let _e304 = (*NdotV_10);
    return (((_e295 * _e296) * _e298) / (4f * ((_e300 + _e301) - (_e303 * _e304))));
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

    let _e321 = (*weight_4);
    if (_e321 < 0.00000001f) {
        return;
    }
    let _e324 = (*closureData_11).V;
    V_6 = _e324;
    let _e326 = (*closureData_11).L;
    L_6 = _e326;
    let _e327 = (*N_11);
    param_78 = _e327;
    let _e328 = V_6;
    param_79 = _e328;
    let _e329 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_78), (&param_79));
    (*N_11) = _e329;
    let _e330 = (*N_11);
    let _e331 = V_6;
    NdotV_11 = clamp(dot(_e330, _e331), 0.00000001f, 1f);
    let _e335 = (*closureData_11).closureType;
    if (_e335 == 1i) {
        let _e337 = (*mode);
        if (_e337 == 0i) {
            let _e339 = L_6;
            let _e340 = V_6;
            H = normalize((_e339 + _e340));
            let _e343 = (*N_11);
            let _e344 = L_6;
            NdotL_6 = clamp(dot(_e343, _e344), 0.00000001f, 1f);
            let _e347 = (*N_11);
            let _e348 = H;
            NdotH_2 = clamp(dot(_e347, _e348), 0.00000001f, 1f);
            let _e351 = (*color_6);
            let _e352 = NdotL_6;
            param_80 = _e352;
            let _e353 = NdotV_11;
            param_81 = _e353;
            let _e354 = NdotH_2;
            param_82 = _e354;
            let _e355 = (*roughness_13);
            param_83 = _e355;
            let _e356 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_80), (&param_81), (&param_82), (&param_83));
            fr = (_e351 * _e356);
            let _e358 = NdotV_11;
            param_84 = _e358;
            let _e359 = (*roughness_13);
            param_85 = _e359;
            let _e360 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_84), (&param_85));
            dirAlbedo_3 = _e360;
            let _e361 = fr;
            let _e362 = NdotL_6;
            let _e365 = (*closureData_11).occlusion;
            let _e367 = (*weight_4);
            (*bsdf_3).response = (((_e361 * _e362) * _e365) * _e367);
        } else {
            let _e370 = (*roughness_13);
            (*roughness_13) = clamp(_e370, 0.01f, 1f);
            let _e372 = (*color_6);
            let _e373 = L_6;
            param_86 = _e373;
            let _e374 = V_6;
            param_87 = _e374;
            let _e375 = (*N_11);
            param_88 = _e375;
            let _e376 = NdotV_11;
            param_89 = _e376;
            let _e377 = (*roughness_13);
            param_90 = _e377;
            let _e378 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_86), (&param_87), (&param_88), (&param_89), (&param_90));
            fr_1 = (_e372 * _e378);
            let _e380 = NdotV_11;
            param_91 = _e380;
            let _e381 = (*roughness_13);
            param_92 = _e381;
            let _e382 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_91), (&param_92));
            dirAlbedo_3 = _e382;
            let _e383 = dirAlbedo_3;
            let _e384 = fr_1;
            let _e387 = (*closureData_11).occlusion;
            let _e389 = (*weight_4);
            (*bsdf_3).response = (((_e384 * _e383) * _e387) * _e389);
        }
        let _e392 = dirAlbedo_3;
        let _e393 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e392 * _e393)));
    } else {
        let _e399 = (*closureData_11).closureType;
        if (_e399 == 3i) {
            let _e401 = (*mode);
            if (_e401 == 0i) {
                let _e403 = NdotV_11;
                param_93 = _e403;
                let _e404 = (*roughness_13);
                param_94 = _e404;
                let _e405 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_93), (&param_94));
                dirAlbedo_4 = _e405;
            } else {
                let _e406 = (*roughness_13);
                (*roughness_13) = clamp(_e406, 0.01f, 1f);
                let _e408 = NdotV_11;
                param_95 = _e408;
                let _e409 = (*roughness_13);
                param_96 = _e409;
                let _e410 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_95), (&param_96));
                dirAlbedo_4 = _e410;
            }
            let _e411 = (*N_11);
            param_97 = _e411;
            let _e412 = mx_environment_irradiance_u0028_vf3_u003b((&param_97));
            Li_4 = _e412;
            let _e413 = Li_4;
            let _e414 = (*color_6);
            let _e416 = dirAlbedo_4;
            let _e418 = (*weight_4);
            (*bsdf_3).response = (((_e413 * _e414) * _e416) * _e418);
            let _e421 = dirAlbedo_4;
            let _e422 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e421 * _e422)));
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

    let _e292 = (*alpha);
    param_98 = _e292;
    let _e293 = mx_square_u0028_f1_u003b((&param_98));
    alpha2_ = _e293;
    let _e294 = alpha2_;
    let _e295 = alpha2_;
    let _e297 = (*NdotL_7);
    param_99 = _e297;
    let _e298 = mx_square_u0028_f1_u003b((&param_99));
    lambdaL = sqrt((_e294 + ((1f - _e295) * _e298)));
    let _e302 = alpha2_;
    let _e303 = alpha2_;
    let _e305 = (*NdotV_12);
    param_100 = _e305;
    let _e306 = mx_square_u0028_f1_u003b((&param_100));
    lambdaV = sqrt((_e302 + ((1f - _e303) * _e306)));
    let _e310 = (*NdotL_7);
    let _e312 = (*NdotV_12);
    let _e314 = lambdaL;
    let _e315 = (*NdotV_12);
    let _e317 = lambdaV;
    let _e318 = (*NdotL_7);
    return (((2f * _e310) * _e312) / ((_e314 * _e315) + (_e317 * _e318)));
}

fn mx_pow6_u0028_f1_u003b(x_7: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_101: f32;
    var param_102: f32;

    let _e287 = (*x_7);
    param_101 = _e287;
    let _e288 = mx_square_u0028_f1_u003b((&param_101));
    x2_ = _e288;
    let _e289 = x2_;
    param_102 = _e289;
    let _e290 = mx_square_u0028_f1_u003b((&param_102));
    let _e291 = x2_;
    return (_e290 * _e291);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_4: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_8: f32;
    var a_2: vec3<f32>;
    var param_103: f32;

    let _e288 = (*cosTheta_4);
    x_8 = clamp(_e288, 0f, 1f);
    let _e291 = (*fd).F0_;
    let _e293 = (*fd).F90_;
    let _e295 = (*fd).exponent;
    let _e300 = (*fd).F82_;
    a_2 = ((mix(_e291, _e293, vec3(pow(0.85714287f, _e295))) * (vec3<f32>(1f, 1f, 1f) - _e300)) * 17.651384f);
    let _e305 = (*fd).F0_;
    let _e307 = (*fd).F90_;
    let _e308 = x_8;
    let _e311 = (*fd).exponent;
    let _e315 = a_2;
    let _e316 = x_8;
    let _e318 = x_8;
    param_103 = (1f - _e318);
    let _e320 = mx_pow6_u0028_f1_u003b((&param_103));
    return (mix(_e305, _e307, vec3(pow((1f - _e308), _e311))) - ((_e315 * _e316) * _e320));
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

    let _e300 = (*cosTheta_5);
    param_104 = clamp(_e300, 0f, 1f);
    let _e302 = mx_square_u0028_f1_u003b((&param_104));
    cosTheta2_ = _e302;
    let _e303 = cosTheta2_;
    sinTheta2_ = (1f - _e303);
    let _e305 = (*n);
    let _e306 = (*n);
    n2_ = (_e305 * _e306);
    let _e308 = (*k);
    let _e309 = (*k);
    k2_ = (_e308 * _e309);
    let _e311 = n2_;
    let _e312 = k2_;
    let _e314 = sinTheta2_;
    t0_ = ((_e311 - _e312) - vec3(_e314));
    let _e317 = t0_;
    let _e318 = t0_;
    let _e320 = n2_;
    let _e322 = k2_;
    a2plusb2_ = sqrt(((_e317 * _e318) + ((_e320 * 4f) * _e322)));
    let _e326 = a2plusb2_;
    let _e327 = cosTheta2_;
    t1_ = (_e326 + vec3(_e327));
    let _e330 = a2plusb2_;
    let _e331 = t0_;
    a_3 = sqrt(max(((_e330 + _e331) * 0.5f), vec3(0f)));
    let _e337 = a_3;
    let _e339 = (*cosTheta_5);
    t2_ = ((_e337 * 2f) * _e339);
    let _e341 = t1_;
    let _e342 = t2_;
    let _e344 = t1_;
    let _e345 = t2_;
    (*Rs) = ((_e341 - _e342) / (_e344 + _e345));
    let _e348 = cosTheta2_;
    let _e349 = a2plusb2_;
    let _e351 = sinTheta2_;
    let _e352 = sinTheta2_;
    t3_ = ((_e349 * _e348) + vec3((_e351 * _e352)));
    let _e356 = t2_;
    let _e357 = sinTheta2_;
    t4_ = (_e356 * _e357);
    let _e359 = (*Rs);
    let _e360 = t3_;
    let _e361 = t4_;
    let _e364 = t3_;
    let _e365 = t4_;
    (*Rp) = ((_e359 * (_e360 - _e361)) / (_e364 + _e365));
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

    let _e293 = (*cosTheta_6);
    param_105 = _e293;
    let _e294 = (*n_1);
    param_106 = _e294;
    let _e295 = (*k_1);
    param_107 = _e295;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_105), (&param_106), (&param_107), (&param_108), (&param_109));
    let _e296 = param_108;
    Rp_1 = _e296;
    let _e297 = param_109;
    Rs_1 = _e297;
    let _e298 = Rp_1;
    let _e299 = Rs_1;
    return ((_e298 + _e299) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_7: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_110: f32;
    var param_111: f32;

    let _e290 = (*cosTheta_7);
    c_1 = _e290;
    let _e291 = (*ior);
    let _e292 = (*ior);
    let _e294 = c_1;
    let _e295 = c_1;
    g2_ = (((_e291 * _e292) + (_e294 * _e295)) - 1f);
    let _e299 = g2_;
    if (_e299 < 0f) {
        return 1f;
    }
    let _e301 = g2_;
    g = sqrt(_e301);
    let _e303 = g;
    let _e304 = c_1;
    let _e306 = g;
    let _e307 = c_1;
    param_110 = ((_e303 - _e304) / (_e306 + _e307));
    let _e310 = mx_square_u0028_f1_u003b((&param_110));
    let _e312 = g;
    let _e313 = c_1;
    let _e315 = c_1;
    let _e318 = g;
    let _e319 = c_1;
    let _e321 = c_1;
    param_111 = ((((_e312 + _e313) * _e315) - 1f) / (((_e318 - _e319) * _e321) + 1f));
    let _e325 = mx_square_u0028_f1_u003b((&param_111));
    return ((0.5f * _e310) * (1f + _e325));
}

fn mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b(opd: ptr<function, f32>, shift: ptr<function, vec3<f32>>) -> vec3<f32> {
    var phase: f32;
    var val: vec3<f32>;
    var pos: vec3<f32>;
    var var_: vec3<f32>;
    var xyz: vec3<f32>;

    let _e290 = (*opd);
    phase = (6.2831855f * _e290);
    val = vec3<f32>(0.00000000000054856f, 0.00000000000044201f, 0.00000000000052481f);
    pos = vec3<f32>(1681000f, 1795300f, 2208400f);
    var_ = vec3<f32>(4327800000f, 9304600000f, 6612100000f);
    let _e292 = val;
    let _e293 = var_;
    let _e297 = pos;
    let _e298 = phase;
    let _e300 = (*shift);
    let _e304 = var_;
    let _e306 = phase;
    let _e308 = phase;
    xyz = (((_e292 * sqrt((_e293 * 6.2831855f))) * cos(((_e297 * _e298) + _e300))) * exp(((-(_e304) * _e306) * _e308)));
    let _e312 = phase;
    let _e315 = (*shift)[0u];
    let _e319 = phase;
    let _e321 = phase;
    let _e326 = xyz[0u];
    xyz[0u] = (_e326 + ((0.00000001644083f * cos(((2239900f * _e312) + _e315))) * exp(((-4528200000f * _e319) * _e321))));
    let _e329 = xyz;
    return (_e329 / vec3(0.00000010685f));
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

    let _e298 = (*kappa2_);
    let _e299 = (*eta2_);
    k2_1 = (_e298 / _e299);
    let _e301 = (*cosTheta_8);
    let _e302 = (*cosTheta_8);
    sinThetaSqr = (vec3<f32>(1f, 1f, 1f) - vec3((_e301 * _e302)));
    let _e306 = (*eta2_);
    let _e307 = (*eta2_);
    let _e309 = k2_1;
    let _e310 = k2_1;
    let _e314 = (*eta1_);
    let _e315 = (*eta1_);
    let _e317 = sinThetaSqr;
    A_4 = (((_e306 * _e307) * (vec3<f32>(1f, 1f, 1f) - (_e309 * _e310))) - (_e317 * (_e314 * _e315)));
    let _e320 = A_4;
    let _e321 = A_4;
    let _e323 = (*eta2_);
    let _e325 = (*eta2_);
    let _e327 = k2_1;
    param_112 = (((_e323 * 2f) * _e325) * _e327);
    let _e329 = mx_square_u0028_vf3_u003b((&param_112));
    B_2 = sqrt(((_e320 * _e321) + _e329));
    let _e332 = A_4;
    let _e333 = B_2;
    U = sqrt(((_e332 + _e333) / vec3(2f)));
    let _e338 = B_2;
    let _e339 = A_4;
    V_7 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e338 - _e339) / vec3(2f))));
    let _e345 = (*eta1_);
    let _e347 = V_7;
    let _e349 = (*cosTheta_8);
    let _e351 = U;
    let _e352 = U;
    let _e354 = V_7;
    let _e355 = V_7;
    let _e358 = (*eta1_);
    let _e359 = (*cosTheta_8);
    param_113 = (_e358 * _e359);
    let _e361 = mx_square_u0028_f1_u003b((&param_113));
    (*phiS) = atan2(((_e347 * (2f * _e345)) * _e349), (((_e351 * _e352) + (_e354 * _e355)) - vec3(_e361)));
    let _e365 = (*eta1_);
    let _e367 = (*eta2_);
    let _e369 = (*eta2_);
    let _e371 = (*cosTheta_8);
    let _e373 = k2_1;
    let _e375 = U;
    let _e377 = k2_1;
    let _e378 = k2_1;
    let _e381 = V_7;
    let _e385 = (*eta2_);
    let _e386 = (*eta2_);
    let _e388 = k2_1;
    let _e389 = k2_1;
    let _e393 = (*cosTheta_8);
    param_114 = (((_e385 * _e386) * (vec3<f32>(1f, 1f, 1f) + (_e388 * _e389))) * _e393);
    let _e395 = mx_square_u0028_vf3_u003b((&param_114));
    let _e396 = (*eta1_);
    let _e397 = (*eta1_);
    let _e399 = U;
    let _e400 = U;
    let _e402 = V_7;
    let _e403 = V_7;
    (*phiP) = atan2(((((_e367 * (2f * _e365)) * _e369) * _e371) * (((_e373 * 2f) * _e375) - ((vec3<f32>(1f, 1f, 1f) - (_e377 * _e378)) * _e381))), (_e395 - (((_e399 * _e400) + (_e402 * _e403)) * (_e396 * _e397))));
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

    let _e295 = (*cosTheta_9);
    param_115 = clamp(_e295, 0f, 1f);
    let _e297 = mx_square_u0028_f1_u003b((&param_115));
    cosTheta2_1 = _e297;
    let _e298 = cosTheta2_1;
    sinTheta2_1 = (1f - _e298);
    let _e300 = (*ior_1);
    let _e301 = (*ior_1);
    let _e303 = sinTheta2_1;
    t0_1 = max(((_e300 * _e301) - _e303), 0f);
    let _e306 = t0_1;
    let _e307 = cosTheta2_1;
    t1_1 = (_e306 + _e307);
    let _e309 = t0_1;
    let _e312 = (*cosTheta_9);
    t2_1 = ((2f * sqrt(_e309)) * _e312);
    let _e314 = t1_1;
    let _e315 = t2_1;
    let _e317 = t1_1;
    let _e318 = t2_1;
    Rs_2 = ((_e314 - _e315) / (_e317 + _e318));
    let _e321 = cosTheta2_1;
    let _e322 = t0_1;
    let _e324 = sinTheta2_1;
    let _e325 = sinTheta2_1;
    t3_1 = ((_e321 * _e322) + (_e324 * _e325));
    let _e328 = t2_1;
    let _e329 = sinTheta2_1;
    t4_1 = (_e328 * _e329);
    let _e331 = Rs_2;
    let _e332 = t3_1;
    let _e333 = t4_1;
    let _e336 = t3_1;
    let _e337 = t4_1;
    Rp_2 = ((_e331 * (_e332 - _e333)) / (_e336 + _e337));
    let _e340 = Rp_2;
    let _e341 = Rs_2;
    return vec2<f32>(_e340, _e341);
}

fn mx_f0_to_ior_u0028_vf3_u003b(F0_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var sqrtF0_: vec3<f32>;

    let _e285 = (*F0_1);
    sqrtF0_ = sqrt(clamp(_e285, vec3(0.01f), vec3(0.99f)));
    let _e290 = sqrtF0_;
    let _e292 = sqrtF0_;
    return ((vec3<f32>(1f, 1f, 1f) + _e290) / (vec3<f32>(1f, 1f, 1f) - _e292));
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
    let _e339 = (*fd_1).tf_ior;
    let _e340 = eta1_1;
    eta2_1 = max(_e339, _e340);
    let _e343 = (*fd_1).model;
    if (_e343 == 2i) {
        let _e346 = (*fd_1).F0_;
        param_116 = _e346;
        let _e347 = mx_f0_to_ior_u0028_vf3_u003b((&param_116));
        local_5 = _e347;
    } else {
        let _e349 = (*fd_1).ior;
        local_5 = _e349;
    }
    let _e350 = local_5;
    eta3_ = _e350;
    let _e352 = (*fd_1).model;
    if (_e352 == 2i) {
        local_6 = vec3<f32>(0f, 0f, 0f);
    } else {
        let _e355 = (*fd_1).extinction;
        local_6 = _e355;
    }
    let _e356 = local_6;
    kappa3_ = _e356;
    let _e357 = (*cosTheta_10);
    param_117 = _e357;
    let _e358 = mx_square_u0028_f1_u003b((&param_117));
    let _e360 = eta1_1;
    let _e361 = eta2_1;
    param_118 = (_e360 / _e361);
    let _e363 = mx_square_u0028_f1_u003b((&param_118));
    cosThetaT = sqrt((1f - ((1f - _e358) * _e363)));
    let _e367 = eta2_1;
    let _e368 = eta1_1;
    let _e370 = (*cosTheta_10);
    param_119 = _e370;
    param_120 = (_e367 / _e368);
    let _e371 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_119), (&param_120));
    R12_ = _e371;
    let _e372 = cosThetaT;
    if (_e372 <= 0f) {
        R12_ = vec2<f32>(1f, 1f);
    }
    let _e374 = R12_;
    T121_ = (vec2<f32>(1f, 1f) - _e374);
    let _e377 = (*fd_1).model;
    if (_e377 == 2i) {
        let _e379 = cosThetaT;
        param_121 = _e379;
        let _e380 = (*fd_1);
        param_122 = _e380;
        let _e381 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_121), (&param_122));
        f_1 = _e381;
        let _e382 = f_1;
        R23p = (_e382 * 0.5f);
        let _e384 = f_1;
        R23s = (_e384 * 0.5f);
    } else {
        let _e386 = eta3_;
        let _e387 = eta2_1;
        let _e390 = kappa3_;
        let _e391 = eta2_1;
        let _e394 = cosThetaT;
        param_123 = _e394;
        param_124 = (_e386 / vec3(_e387));
        param_125 = (_e390 / vec3(_e391));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_123), (&param_124), (&param_125), (&param_126), (&param_127));
        let _e395 = param_126;
        R23p = _e395;
        let _e396 = param_127;
        R23s = _e396;
    }
    let _e397 = eta2_1;
    let _e398 = eta1_1;
    cosB = cos(atan((_e397 / _e398)));
    let _e402 = (*cosTheta_10);
    let _e403 = cosB;
    phi21_ = vec2<f32>(select(3.1415927f, 0f, (_e402 < _e403)), 3.1415927f);
    let _e408 = (*fd_1).model;
    if (_e408 == 2i) {
        let _e411 = eta3_[0u];
        let _e412 = eta2_1;
        let _e416 = eta3_[1u];
        let _e417 = eta2_1;
        let _e421 = eta3_[2u];
        let _e422 = eta2_1;
        phi23p = vec3<f32>(select(0f, 3.1415927f, (_e411 < _e412)), select(0f, 3.1415927f, (_e416 < _e417)), select(0f, 3.1415927f, (_e421 < _e422)));
        let _e426 = phi23p;
        phi23s = _e426;
    } else {
        let _e427 = cosThetaT;
        param_128 = _e427;
        let _e428 = eta2_1;
        param_129 = _e428;
        let _e429 = eta3_;
        param_130 = _e429;
        let _e430 = kappa3_;
        param_131 = _e430;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_128), (&param_129), (&param_130), (&param_131), (&param_132), (&param_133));
        let _e431 = param_132;
        phi23p = _e431;
        let _e432 = param_133;
        phi23s = _e432;
    }
    let _e434 = R12_[0u];
    let _e435 = R23p;
    r123p = max(sqrt((_e435 * _e434)), vec3(0f));
    let _e441 = R12_[1u];
    let _e442 = R23s;
    r123s = max(sqrt((_e442 * _e441)), vec3(0f));
    I = vec3<f32>(0f, 0f, 0f);
    let _e448 = (*fd_1).tf_thickness;
    distMeters = (_e448 * 0.000000001f);
    let _e450 = eta2_1;
    let _e452 = cosThetaT;
    let _e454 = distMeters;
    opd_1 = (((2f * _e450) * _e452) * _e454);
    let _e457 = T121_[0u];
    param_134 = _e457;
    let _e458 = mx_square_u0028_f1_u003b((&param_134));
    let _e459 = R23p;
    let _e462 = R12_[0u];
    let _e463 = R23p;
    Rs_3 = ((_e459 * _e458) / (vec3<f32>(1f, 1f, 1f) - (_e463 * _e462)));
    let _e468 = R12_[0u];
    let _e469 = Rs_3;
    let _e472 = I;
    I = (_e472 + (vec3(_e468) + _e469));
    let _e474 = Rs_3;
    let _e476 = T121_[0u];
    Cm = (_e474 - vec3(_e476));
    m_3 = 1i;
    loop {
        let _e479 = m_3;
        if (_e479 <= 2i) {
            let _e481 = r123p;
            let _e482 = Cm;
            Cm = (_e482 * _e481);
            let _e484 = m_3;
            let _e486 = opd_1;
            let _e488 = m_3;
            let _e490 = phi23p;
            let _e492 = phi21_[0u];
            param_135 = (f32(_e484) * _e486);
            param_136 = ((_e490 + vec3(_e492)) * f32(_e488));
            let _e496 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_135), (&param_136));
            Sm = (_e496 * 2f);
            let _e498 = Cm;
            let _e499 = Sm;
            let _e501 = I;
            I = (_e501 + (_e498 * _e499));
            continue;
        } else {
            break;
        }
        continuing {
            let _e503 = m_3;
            m_3 = (_e503 + 1i);
        }
    }
    let _e506 = T121_[1u];
    param_137 = _e506;
    let _e507 = mx_square_u0028_f1_u003b((&param_137));
    let _e508 = R23s;
    let _e511 = R12_[1u];
    let _e512 = R23s;
    Rp_3 = ((_e508 * _e507) / (vec3<f32>(1f, 1f, 1f) - (_e512 * _e511)));
    let _e517 = R12_[1u];
    let _e518 = Rp_3;
    let _e521 = I;
    I = (_e521 + (vec3(_e517) + _e518));
    let _e523 = Rp_3;
    let _e525 = T121_[1u];
    Cm = (_e523 - vec3(_e525));
    m_4 = 1i;
    loop {
        let _e528 = m_4;
        if (_e528 <= 2i) {
            let _e530 = r123s;
            let _e531 = Cm;
            Cm = (_e531 * _e530);
            let _e533 = m_4;
            let _e535 = opd_1;
            let _e537 = m_4;
            let _e539 = phi23s;
            let _e541 = phi21_[1u];
            param_138 = (f32(_e533) * _e535);
            param_139 = ((_e539 + vec3(_e541)) * f32(_e537));
            let _e545 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_138), (&param_139));
            Sm = (_e545 * 2f);
            let _e547 = Cm;
            let _e548 = Sm;
            let _e550 = I;
            I = (_e550 + (_e547 * _e548));
            continue;
        } else {
            break;
        }
        continuing {
            let _e552 = m_4;
            m_4 = (_e552 + 1i);
        }
    }
    let _e554 = I;
    I = (_e554 * 0.5f);
    param_140 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e556 = I;
    param_141 = _e556;
    let _e557 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_140), (&param_141));
    I = clamp(_e557, vec3(0f), vec3(1f));
    let _e561 = I;
    return _e561;
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

    let _e295 = (*fd_2).airy;
    if _e295 {
        let _e296 = (*cosTheta_11);
        param_142 = _e296;
        let _e297 = (*fd_2);
        param_143 = _e297;
        let _e298 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_142), (&param_143));
        return _e298;
    } else {
        let _e300 = (*fd_2).model;
        if (_e300 == 0i) {
            let _e302 = (*cosTheta_11);
            param_144 = _e302;
            let _e305 = (*fd_2).ior[0u];
            param_145 = _e305;
            let _e306 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_144), (&param_145));
            return vec3(_e306);
        } else {
            let _e309 = (*fd_2).model;
            if (_e309 == 1i) {
                let _e311 = (*cosTheta_11);
                param_146 = _e311;
                let _e313 = (*fd_2).ior;
                param_147 = _e313;
                let _e315 = (*fd_2).extinction;
                param_148 = _e315;
                let _e316 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_146), (&param_147), (&param_148));
                return _e316;
            } else {
                let _e317 = (*cosTheta_11);
                param_149 = _e317;
                let _e318 = (*fd_2);
                param_150 = _e318;
                let _e319 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_149), (&param_150));
                return _e319;
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

    let _e291 = (*dir_2);
    let _e296 = (*transform_1);
    param_151 = _e296;
    param_152 = vec4<f32>(_e291.x, _e291.y, _e291.z, 0f);
    let _e297 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_151), (&param_152));
    envDir_1 = normalize(_e297.xyz);
    let _e300 = envDir_1;
    param_153 = _e300;
    let _e301 = mx_latlong_projection_u0028_vf3_u003b((&param_153));
    uv_2 = _e301;
    let _e302 = uv_2;
    let _e303 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e302, 0.0);
    return _e303.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_154: f32;

    let _e290 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e290 - 1.5f);
    let _e293 = (*dir_3)[1u];
    param_154 = _e293;
    let _e294 = mx_square_u0028_f1_u003b((&param_154));
    distortion = sqrt((1f - _e294));
    let _e297 = effectiveMaxMipLevel;
    let _e298 = (*envSamples);
    let _e300 = (*pdf);
    let _e302 = distortion;
    return max((_e297 - (0.5f * log2(((f32(_e298) * _e300) * _e302)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H_1: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_155: f32;
    var param_156: f32;

    let _e289 = (*H_1);
    let _e291 = (*alpha_1);
    He = (_e289.xy / _e291);
    let _e293 = He;
    let _e294 = He;
    let _e297 = (*H_1)[2u];
    param_155 = _e297;
    let _e298 = mx_square_u0028_f1_u003b((&param_155));
    denom_1 = (dot(_e293, _e294) + _e298);
    let _e301 = (*alpha_1)[0u];
    let _e304 = (*alpha_1)[1u];
    let _e306 = denom_1;
    param_156 = _e306;
    let _e307 = mx_square_u0028_f1_u003b((&param_156));
    return (1f / (((3.1415927f * _e301) * _e304) * _e307));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_2: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_13: ptr<function, f32>) -> f32 {
    var param_157: vec3<f32>;
    var param_158: vec2<f32>;

    let _e289 = (*H_2);
    param_157 = _e289;
    let _e290 = (*alpha_2);
    param_158 = _e290;
    let _e291 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_157), (&param_158));
    let _e292 = (*G1V);
    let _e294 = (*NdotV_13);
    return ((_e291 * _e292) / (4f * _e294));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_12: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e287 = (*R_1);
    let _e288 = (*N_12);
    let _e289 = (*ior_2);
    (*R_1) = refract(_e287, _e288, (1f / _e289));
    let _e292 = (*R_1);
    let _e293 = (*R_1);
    let _e294 = (*N_12);
    let _e297 = (*N_12);
    N1_ = normalize(((_e292 * dot(_e293, _e294)) - (_e297 * 0.5f)));
    let _e301 = (*R_1);
    let _e302 = N1_;
    let _e303 = (*ior_2);
    return refract(_e301, _e302, _e303);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_8: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_9: f32;
    var y_3: f32;
    var c_2: vec3<f32>;
    var H_3: vec3<f32>;

    let _e293 = (*V_8);
    let _e295 = (*alpha_3);
    let _e296 = (_e293.xy * _e295);
    let _e298 = (*V_8)[2u];
    (*V_8) = normalize(vec3<f32>(_e296.x, _e296.y, _e298));
    let _e304 = (*Xi)[0u];
    phi = (6.2831855f * _e304);
    let _e307 = (*Xi)[1u];
    let _e310 = (*V_8)[2u];
    let _e314 = (*V_8)[2u];
    z = (((1f - _e307) * (1f + _e310)) - _e314);
    let _e316 = z;
    let _e317 = z;
    sinTheta = sqrt(clamp((1f - (_e316 * _e317)), 0f, 1f));
    let _e322 = sinTheta;
    let _e323 = phi;
    x_9 = (_e322 * cos(_e323));
    let _e326 = sinTheta;
    let _e327 = phi;
    y_3 = (_e326 * sin(_e327));
    let _e330 = x_9;
    let _e331 = y_3;
    let _e332 = z;
    c_2 = vec3<f32>(_e330, _e331, _e332);
    let _e334 = c_2;
    let _e335 = (*V_8);
    H_3 = (_e334 + _e335);
    let _e337 = H_3;
    let _e339 = (*alpha_3);
    let _e340 = (_e337.xy * _e339);
    let _e342 = H_3[2u];
    H_3 = normalize(vec3<f32>(_e340.x, _e340.y, max(_e342, 0f)));
    let _e348 = H_3;
    return _e348;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e284 = (*i_1);
    return fract(((f32(_e284) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_159: i32;

    let _e286 = (*i_2);
    let _e289 = (*numSamples);
    let _e292 = (*i_2);
    param_159 = _e292;
    let _e293 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_159));
    return vec2<f32>(((f32(_e286) + 0.5f) / f32(_e289)), _e293);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_12: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_160: f32;
    var tanTheta2_: f32;
    var param_161: f32;

    let _e289 = (*cosTheta_12);
    param_160 = _e289;
    let _e290 = mx_square_u0028_f1_u003b((&param_160));
    cosTheta2_2 = _e290;
    let _e291 = cosTheta2_2;
    let _e293 = cosTheta2_2;
    tanTheta2_ = ((1f - _e291) / _e293);
    let _e295 = (*alpha_4);
    param_161 = _e295;
    let _e296 = mx_square_u0028_f1_u003b((&param_161));
    let _e297 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e296 * _e297)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e285 = (*alpha_5)[0u];
    let _e287 = (*alpha_5)[1u];
    return sqrt((_e285 * _e287));
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

    let _e340 = (*X_2);
    let _e341 = (*X_2);
    let _e342 = (*N_13);
    let _e344 = (*N_13);
    (*X_2) = normalize((_e340 - (_e344 * dot(_e341, _e342))));
    let _e348 = (*N_13);
    let _e349 = (*X_2);
    Y_2 = cross(_e348, _e349);
    let _e351 = (*X_2);
    let _e352 = Y_2;
    let _e353 = (*N_13);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e351.x, _e351.y, _e351.z), vec3<f32>(_e352.x, _e352.y, _e352.z), vec3<f32>(_e353.x, _e353.y, _e353.z));
    let _e367 = (*V_9);
    let _e368 = (*X_2);
    let _e370 = (*V_9);
    let _e371 = Y_2;
    let _e373 = (*V_9);
    let _e374 = (*N_13);
    (*V_9) = vec3<f32>(dot(_e367, _e368), dot(_e370, _e371), dot(_e373, _e374));
    let _e378 = (*V_9)[2u];
    NdotV_14 = clamp(_e378, 0.00000001f, 1f);
    let _e380 = (*alpha_6);
    param_162 = _e380;
    let _e381 = mx_average_alpha_u0028_vf2_u003b((&param_162));
    avgAlpha = _e381;
    let _e382 = NdotV_14;
    param_163 = _e382;
    let _e383 = avgAlpha;
    param_164 = _e383;
    let _e384 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_163), (&param_164));
    G1V_1 = _e384;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e385 = i_3;
        let _e386 = envRadianceSamples;
        if (_e385 < _e386) {
            let _e388 = i_3;
            param_165 = _e388;
            let _e389 = envRadianceSamples;
            param_166 = _e389;
            let _e390 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_165), (&param_166));
            Xi_1 = _e390;
            let _e391 = Xi_1;
            param_167 = _e391;
            let _e392 = (*V_9);
            param_168 = _e392;
            let _e393 = (*alpha_6);
            param_169 = _e393;
            let _e394 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_167), (&param_168), (&param_169));
            H_4 = _e394;
            let _e396 = (*fd_3).refraction;
            if _e396 {
                let _e397 = (*V_9);
                param_170 = -(_e397);
                let _e399 = H_4;
                param_171 = _e399;
                let _e402 = (*fd_3).ior[0u];
                param_172 = _e402;
                let _e403 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_170), (&param_171), (&param_172));
                local_7 = _e403;
            } else {
                let _e404 = (*V_9);
                let _e405 = H_4;
                local_7 = -(reflect(_e404, _e405));
            }
            let _e408 = local_7;
            L_7 = _e408;
            let _e410 = L_7[2u];
            NdotL_8 = clamp(_e410, 0.00000001f, 1f);
            let _e412 = (*V_9);
            let _e413 = H_4;
            VdotH = clamp(dot(_e412, _e413), 0.00000001f, 1f);
            let _e416 = tangentToWorld;
            param_173 = _e416;
            let _e417 = L_7;
            param_174 = _e417;
            let _e418 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_173), (&param_174));
            Lw = _e418;
            let _e419 = H_4;
            param_175 = _e419;
            let _e420 = (*alpha_6);
            param_176 = _e420;
            let _e421 = G1V_1;
            param_177 = _e421;
            let _e422 = NdotV_14;
            param_178 = _e422;
            let _e423 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_175), (&param_176), (&param_177), (&param_178));
            pdf_1 = _e423;
            let _e424 = Lw;
            param_179 = _e424;
            let _e425 = pdf_1;
            param_180 = _e425;
            param_181 = 0f;
            let _e426 = envRadianceSamples;
            param_182 = _e426;
            let _e427 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_179), (&param_180), (&param_181), (&param_182));
            lod_2 = _e427;
            let _e428 = mtlxEnvMatrix_u0028_();
            let _e429 = Lw;
            param_183 = _e429;
            param_184 = _e428;
            let _e430 = lod_2;
            param_185 = _e430;
            let _e431 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_183), (&param_184), (&param_185));
            sampleColor = _e431;
            let _e432 = VdotH;
            param_186 = _e432;
            let _e433 = (*fd_3);
            param_187 = _e433;
            let _e434 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_186), (&param_187));
            F_1 = _e434;
            let _e435 = NdotL_8;
            param_188 = _e435;
            let _e436 = NdotV_14;
            param_189 = _e436;
            let _e437 = avgAlpha;
            param_190 = _e437;
            let _e438 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_188), (&param_189), (&param_190));
            G_2 = _e438;
            let _e440 = (*fd_3).refraction;
            if _e440 {
                let _e441 = F_1;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e441);
            } else {
                let _e443 = F_1;
                let _e444 = G_2;
                local_8 = (_e443 * _e444);
            }
            let _e446 = local_8;
            FG = _e446;
            let _e447 = sampleColor;
            let _e448 = FG;
            let _e450 = radiance;
            radiance = (_e450 + (_e447 * _e448));
            continue;
        } else {
            break;
        }
        continuing {
            let _e452 = i_3;
            i_3 = (_e452 + 1i);
        }
    }
    let _e454 = G1V_1;
    let _e455 = envRadianceSamples;
    let _e458 = radiance;
    radiance = (_e458 / vec3((_e454 * f32(_e455))));
    let _e461 = radiance;
    let _e464 = unnamed.skyPower;
    return (select(_e461, vec3<f32>(0f, 0f, 0f), false) * _e464);
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

    let _e295 = (*NdotV_15);
    x_10 = _e295;
    let _e296 = (*alpha_7);
    y_4 = _e296;
    let _e297 = x_10;
    param_191 = _e297;
    let _e298 = mx_square_u0028_f1_u003b((&param_191));
    x2_1 = _e298;
    let _e299 = y_4;
    param_192 = _e299;
    let _e300 = mx_square_u0028_f1_u003b((&param_192));
    y2_ = _e300;
    let _e301 = x_10;
    let _e304 = y_4;
    let _e307 = x_10;
    let _e309 = y_4;
    let _e312 = x2_1;
    let _e315 = y2_;
    let _e318 = x2_1;
    let _e320 = y_4;
    let _e323 = x_10;
    let _e325 = y2_;
    let _e328 = x2_1;
    let _e330 = y2_;
    r_2 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e301)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e304)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e307) * _e309)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e312)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e315)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e318) * _e320)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e323) * _e325)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e328) * _e330));
    let _e333 = r_2;
    let _e335 = r_2;
    AB = clamp((_e333.xy / _e335.zw), vec2(0f), vec2(1f));
    let _e341 = (*F0_2);
    let _e343 = AB[0u];
    let _e345 = (*F90_1);
    let _e347 = AB[1u];
    return ((_e341 * _e343) + (_e345 * _e347));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_16: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_193: f32;
    var param_194: f32;
    var param_195: vec3<f32>;
    var param_196: vec3<f32>;

    let _e291 = (*NdotV_16);
    param_193 = _e291;
    let _e292 = (*alpha_8);
    param_194 = _e292;
    let _e293 = (*F0_3);
    param_195 = _e293;
    let _e294 = (*F90_2);
    param_196 = _e294;
    let _e295 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_193), (&param_194), (&param_195), (&param_196));
    return _e295;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_197: f32;
    var param_198: f32;
    var param_199: vec3<f32>;
    var param_200: vec3<f32>;

    let _e291 = (*F0_4);
    let _e293 = (*F90_3);
    let _e295 = (*NdotV_17);
    param_197 = _e295;
    let _e296 = (*alpha_9);
    param_198 = _e296;
    param_199 = vec3(_e291);
    param_200 = vec3(_e293);
    let _e297 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_197), (&param_198), (&param_199), (&param_200));
    return _e297.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_4: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_5: vec3<f32>;
    var param_201: f32;
    var param_202: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_2970_: bool;

    param_201 = 1f;
    let _e289 = (*fd_4);
    param_202 = _e289;
    let _e290 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_201), (&param_202));
    F0_5 = _e290;
    let _e292 = (*fd_4).model;
    let _e293 = (_e292 == 2i);
    phi_2970_ = _e293;
    if _e293 {
        let _e295 = (*fd_4).airy;
        phi_2970_ = !(_e295);
    }
    let _e298 = phi_2970_;
    if _e298 {
        let _e300 = (*fd_4).F90_;
        local_9 = _e300;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e301 = local_9;
    F90_4 = _e301;
    let _e302 = F0_5;
    let _e303 = F90_4;
    let _e304 = F0_5;
    return (_e302 + ((_e303 - _e304) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_18: ptr<function, f32>, alpha_10: ptr<function, f32>, fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_203: FresnelData;
    var Ess: f32;
    var param_204: f32;
    var param_205: f32;
    var param_206: f32;
    var param_207: f32;

    let _e293 = (*fd_5);
    param_203 = _e293;
    let _e294 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_203));
    Fss = _e294;
    let _e295 = (*NdotV_18);
    param_204 = _e295;
    let _e296 = (*alpha_10);
    param_205 = _e296;
    param_206 = 1f;
    param_207 = 1f;
    let _e297 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_204), (&param_205), (&param_206), (&param_207));
    Ess = _e297;
    let _e298 = Fss;
    let _e299 = Ess;
    let _e302 = Ess;
    return (vec3(1f) + ((_e298 * (1f - _e299)) / vec3(_e302)));
}

fn mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(ior_3: ptr<function, vec3<f32>>, extinction: ptr<function, vec3<f32>>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_6: FresnelData;

    fd_6.model = 1i;
    let _e289 = (*tf_thickness);
    fd_6.airy = (_e289 > 0f);
    let _e292 = (*ior_3);
    fd_6.ior = _e292;
    let _e294 = (*extinction);
    fd_6.extinction = _e294;
    fd_6.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_6.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_6.exponent = 0f;
    let _e300 = (*tf_thickness);
    fd_6.tf_thickness = _e300;
    let _e302 = (*tf_ior);
    fd_6.tf_ior = _e302;
    fd_6.refraction = false;
    let _e305 = fd_6;
    return _e305;
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
    let _e340 = (*weight_5);
    if (_e340 < 0.00000001f) {
        return;
    }
    let _e343 = (*closureData_12).V;
    V_10 = _e343;
    let _e345 = (*closureData_12).L;
    L_8 = _e345;
    let _e346 = (*retroreflective);
    if _e346 {
        let _e347 = V_10;
        let _e349 = (*N_14);
        local_10 = reflect(-(_e347), _e349);
    } else {
        let _e351 = V_10;
        local_10 = _e351;
    }
    let _e352 = local_10;
    V_10 = _e352;
    let _e353 = (*N_14);
    param_208 = _e353;
    let _e354 = V_10;
    param_209 = _e354;
    let _e355 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_208), (&param_209));
    (*N_14) = _e355;
    let _e356 = (*N_14);
    let _e357 = V_10;
    NdotV_19 = clamp(dot(_e356, _e357), 0.00000001f, 1f);
    let _e360 = (*ior_n);
    param_210 = _e360;
    let _e361 = (*ior_k);
    param_211 = _e361;
    let _e362 = (*thinfilm_thickness);
    param_212 = _e362;
    let _e363 = (*thinfilm_ior);
    param_213 = _e363;
    let _e364 = mx_init_fresnel_conductor_u0028_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_210), (&param_211), (&param_212), (&param_213));
    fd_7 = _e364;
    let _e365 = (*roughness_14);
    safeAlpha = clamp(_e365, vec2(0.00000001f), vec2(1f));
    let _e369 = safeAlpha;
    param_214 = _e369;
    let _e370 = mx_average_alpha_u0028_vf2_u003b((&param_214));
    avgAlpha_1 = _e370;
    let _e372 = (*closureData_12).closureType;
    if (_e372 == 1i) {
        let _e374 = (*X_3);
        let _e375 = (*X_3);
        let _e376 = (*N_14);
        let _e378 = (*N_14);
        (*X_3) = normalize((_e374 - (_e378 * dot(_e375, _e376))));
        let _e382 = (*N_14);
        let _e383 = (*X_3);
        Y_3 = cross(_e382, _e383);
        let _e385 = L_8;
        let _e386 = V_10;
        H_5 = normalize((_e385 + _e386));
        let _e389 = (*N_14);
        let _e390 = L_8;
        NdotL_9 = clamp(dot(_e389, _e390), 0.00000001f, 1f);
        let _e393 = V_10;
        let _e394 = H_5;
        VdotH_1 = clamp(dot(_e393, _e394), 0.00000001f, 1f);
        let _e397 = H_5;
        let _e398 = (*X_3);
        let _e400 = H_5;
        let _e401 = Y_3;
        let _e403 = H_5;
        let _e404 = (*N_14);
        Ht = vec3<f32>(dot(_e397, _e398), dot(_e400, _e401), dot(_e403, _e404));
        let _e407 = VdotH_1;
        param_215 = _e407;
        let _e408 = fd_7;
        param_216 = _e408;
        let _e409 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_215), (&param_216));
        F_2 = _e409;
        let _e410 = Ht;
        param_217 = _e410;
        let _e411 = safeAlpha;
        param_218 = _e411;
        let _e412 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_217), (&param_218));
        D_1 = _e412;
        let _e413 = NdotL_9;
        param_219 = _e413;
        let _e414 = NdotV_19;
        param_220 = _e414;
        let _e415 = avgAlpha_1;
        param_221 = _e415;
        let _e416 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_219), (&param_220), (&param_221));
        G_3 = _e416;
        let _e417 = NdotV_19;
        param_222 = _e417;
        let _e418 = avgAlpha_1;
        param_223 = _e418;
        let _e419 = fd_7;
        param_224 = _e419;
        let _e420 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_222), (&param_223), (&param_224));
        comp = _e420;
        let _e421 = D_1;
        let _e422 = F_2;
        let _e424 = G_3;
        let _e426 = comp;
        let _e429 = (*closureData_12).occlusion;
        let _e431 = (*weight_5);
        let _e433 = NdotV_19;
        (*bsdf_4).response = ((((((_e422 * _e421) * _e424) * _e426) * _e429) * _e431) / vec3((4f * _e433)));
    } else {
        let _e439 = (*closureData_12).closureType;
        if (_e439 == 3i) {
            let _e441 = NdotV_19;
            param_225 = _e441;
            let _e442 = avgAlpha_1;
            param_226 = _e442;
            let _e443 = fd_7;
            param_227 = _e443;
            let _e444 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_225), (&param_226), (&param_227));
            comp_1 = _e444;
            let _e445 = (*N_14);
            param_228 = _e445;
            let _e446 = V_10;
            param_229 = _e446;
            let _e447 = (*X_3);
            param_230 = _e447;
            let _e448 = safeAlpha;
            param_231 = _e448;
            let _e449 = (*distribution_1);
            param_232 = _e449;
            let _e450 = fd_7;
            param_233 = _e450;
            let _e451 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_228), (&param_229), (&param_230), (&param_231), (&param_232), (&param_233));
            Li_5 = _e451;
            let _e452 = Li_5;
            let _e453 = comp_1;
            let _e455 = (*weight_5);
            (*bsdf_4).response = ((_e452 * _e453) * _e455);
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
        let _e298 = (*tint_1);
        param_234 = _e298;
        let _e299 = mx_square_u0028_vf3_u003b((&param_234));
        (*tint_1) = _e299;
    }
    let _e300 = (*N_15);
    param_235 = _e300;
    let _e301 = (*V_11);
    param_236 = _e301;
    let _e302 = (*X_4);
    param_237 = _e302;
    let _e303 = (*alpha_11);
    param_238 = _e303;
    let _e304 = (*distribution_2);
    param_239 = _e304;
    let _e305 = (*fd_8);
    param_240 = _e305;
    let _e306 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_235), (&param_236), (&param_237), (&param_238), (&param_239), (&param_240));
    let _e307 = (*tint_1);
    return (_e306 * _e307);
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_4: ptr<function, f32>) -> f32 {
    var param_241: f32;

    let _e285 = (*ior_4);
    let _e287 = (*ior_4);
    param_241 = ((_e285 - 1f) / (_e287 + 1f));
    let _e290 = mx_square_u0028_f1_u003b((&param_241));
    return _e290;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_5: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e288 = (*tf_thickness_1);
    fd_9.airy = (_e288 > 0f);
    let _e291 = (*ior_5);
    fd_9.ior = vec3(_e291);
    fd_9.extinction = vec3<f32>(0f, 0f, 0f);
    fd_9.F0_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F82_ = vec3<f32>(0f, 0f, 0f);
    fd_9.F90_ = vec3<f32>(0f, 0f, 0f);
    fd_9.exponent = 0f;
    let _e299 = (*tf_thickness_1);
    fd_9.tf_thickness = _e299;
    let _e301 = (*tf_ior_1);
    fd_9.tf_ior = _e301;
    fd_9.refraction = false;
    let _e304 = fd_9;
    return _e304;
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
    var phi_4014_: bool;

    let _e367 = (*weight_6);
    if (_e367 < 0.00000001f) {
        return;
    }
    let _e370 = (*closureData_13).closureType;
    let _e372 = (*scatter_mode);
    if ((_e370 != 2i) && (_e372 == 1i)) {
        return;
    }
    let _e376 = (*closureData_13).V;
    V_12 = _e376;
    let _e378 = (*closureData_13).L;
    L_9 = _e378;
    let _e379 = (*retroreflective_1);
    phi_4014_ = _e379;
    if _e379 {
        let _e381 = (*closureData_13).closureType;
        phi_4014_ = (_e381 != 2i);
    }
    let _e384 = phi_4014_;
    if _e384 {
        let _e385 = V_12;
        let _e387 = (*N_16);
        V_12 = reflect(-(_e385), _e387);
    }
    let _e389 = (*N_16);
    param_242 = _e389;
    let _e390 = V_12;
    param_243 = _e390;
    let _e391 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_242), (&param_243));
    (*N_16) = _e391;
    let _e392 = (*N_16);
    let _e393 = V_12;
    NdotV_20 = clamp(dot(_e392, _e393), 0.00000001f, 1f);
    let _e396 = (*ior_6);
    param_244 = _e396;
    let _e397 = (*thinfilm_thickness_1);
    param_245 = _e397;
    let _e398 = (*thinfilm_ior_1);
    param_246 = _e398;
    let _e399 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_244), (&param_245), (&param_246));
    fd_10 = _e399;
    let _e400 = (*ior_6);
    param_247 = _e400;
    let _e401 = mx_ior_to_f0_u0028_f1_u003b((&param_247));
    F0_6 = _e401;
    let _e402 = (*roughness_15);
    safeAlpha_1 = clamp(_e402, vec2(0.00000001f), vec2(1f));
    let _e406 = safeAlpha_1;
    param_248 = _e406;
    let _e407 = mx_average_alpha_u0028_vf2_u003b((&param_248));
    avgAlpha_2 = _e407;
    let _e408 = (*tint_2);
    safeTint = max(_e408, vec3(0f));
    let _e412 = (*closureData_13).closureType;
    if (_e412 == 1i) {
        let _e414 = (*X_5);
        let _e415 = (*X_5);
        let _e416 = (*N_16);
        let _e418 = (*N_16);
        (*X_5) = normalize((_e414 - (_e418 * dot(_e415, _e416))));
        let _e422 = (*N_16);
        let _e423 = (*X_5);
        Y_4 = cross(_e422, _e423);
        let _e425 = L_9;
        let _e426 = V_12;
        H_6 = normalize((_e425 + _e426));
        let _e429 = (*N_16);
        let _e430 = L_9;
        NdotL_10 = clamp(dot(_e429, _e430), 0.00000001f, 1f);
        let _e433 = V_12;
        let _e434 = H_6;
        VdotH_2 = clamp(dot(_e433, _e434), 0.00000001f, 1f);
        let _e437 = H_6;
        let _e438 = (*X_5);
        let _e440 = H_6;
        let _e441 = Y_4;
        let _e443 = H_6;
        let _e444 = (*N_16);
        Ht_1 = vec3<f32>(dot(_e437, _e438), dot(_e440, _e441), dot(_e443, _e444));
        let _e447 = VdotH_2;
        param_249 = _e447;
        let _e448 = fd_10;
        param_250 = _e448;
        let _e449 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_249), (&param_250));
        F_3 = _e449;
        let _e450 = Ht_1;
        param_251 = _e450;
        let _e451 = safeAlpha_1;
        param_252 = _e451;
        let _e452 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_251), (&param_252));
        D_2 = _e452;
        let _e453 = NdotL_10;
        param_253 = _e453;
        let _e454 = NdotV_20;
        param_254 = _e454;
        let _e455 = avgAlpha_2;
        param_255 = _e455;
        let _e456 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_253), (&param_254), (&param_255));
        G_4 = _e456;
        let _e457 = NdotV_20;
        param_256 = _e457;
        let _e458 = avgAlpha_2;
        param_257 = _e458;
        let _e459 = fd_10;
        param_258 = _e459;
        let _e460 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_256), (&param_257), (&param_258));
        comp_2 = _e460;
        let _e461 = NdotV_20;
        param_259 = _e461;
        let _e462 = avgAlpha_2;
        param_260 = _e462;
        let _e463 = F0_6;
        param_261 = _e463;
        param_262 = 1f;
        let _e464 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_259), (&param_260), (&param_261), (&param_262));
        let _e465 = comp_2;
        dirAlbedo_5 = (_e465 * _e464);
        let _e467 = dirAlbedo_5;
        let _e468 = (*weight_6);
        (*bsdf_5).throughput = (vec3(1f) - (_e467 * _e468));
        let _e473 = D_2;
        let _e474 = F_3;
        let _e476 = G_4;
        let _e478 = comp_2;
        let _e480 = safeTint;
        let _e483 = (*closureData_13).occlusion;
        let _e485 = (*weight_6);
        let _e487 = NdotV_20;
        (*bsdf_5).response = (((((((_e474 * _e473) * _e476) * _e478) * _e480) * _e483) * _e485) / vec3((4f * _e487)));
    } else {
        let _e493 = (*closureData_13).closureType;
        if (_e493 == 2i) {
            let _e495 = NdotV_20;
            param_263 = _e495;
            let _e496 = avgAlpha_2;
            param_264 = _e496;
            let _e497 = fd_10;
            param_265 = _e497;
            let _e498 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_263), (&param_264), (&param_265));
            comp_3 = _e498;
            let _e499 = NdotV_20;
            param_266 = _e499;
            let _e500 = avgAlpha_2;
            param_267 = _e500;
            let _e501 = F0_6;
            param_268 = _e501;
            param_269 = 1f;
            let _e502 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_266), (&param_267), (&param_268), (&param_269));
            let _e503 = comp_3;
            dirAlbedo_6 = (_e503 * _e502);
            let _e505 = dirAlbedo_6;
            let _e506 = (*weight_6);
            (*bsdf_5).throughput = (vec3(1f) - (_e505 * _e506));
            let _e511 = (*scatter_mode);
            if (_e511 != 0i) {
                let _e513 = (*N_16);
                param_270 = _e513;
                let _e514 = V_12;
                param_271 = _e514;
                let _e515 = (*X_5);
                param_272 = _e515;
                let _e516 = safeAlpha_1;
                param_273 = _e516;
                let _e517 = (*distribution_3);
                param_274 = _e517;
                let _e518 = fd_10;
                param_275 = _e518;
                let _e519 = safeTint;
                param_276 = _e519;
                let _e520 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_270), (&param_271), (&param_272), (&param_273), (&param_274), (&param_275), (&param_276));
                let _e521 = (*weight_6);
                (*bsdf_5).response = (_e520 * _e521);
            }
        } else {
            let _e525 = (*closureData_13).closureType;
            if (_e525 == 3i) {
                let _e527 = NdotV_20;
                param_277 = _e527;
                let _e528 = avgAlpha_2;
                param_278 = _e528;
                let _e529 = fd_10;
                param_279 = _e529;
                let _e530 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_277), (&param_278), (&param_279));
                comp_4 = _e530;
                let _e531 = NdotV_20;
                param_280 = _e531;
                let _e532 = avgAlpha_2;
                param_281 = _e532;
                let _e533 = F0_6;
                param_282 = _e533;
                param_283 = 1f;
                let _e534 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_280), (&param_281), (&param_282), (&param_283));
                let _e535 = comp_4;
                dirAlbedo_7 = (_e535 * _e534);
                let _e537 = dirAlbedo_7;
                let _e538 = (*weight_6);
                (*bsdf_5).throughput = (vec3(1f) - (_e537 * _e538));
                let _e543 = (*N_16);
                param_284 = _e543;
                let _e544 = V_12;
                param_285 = _e544;
                let _e545 = (*X_5);
                param_286 = _e545;
                let _e546 = safeAlpha_1;
                param_287 = _e546;
                let _e547 = (*distribution_3);
                param_288 = _e547;
                let _e548 = fd_10;
                param_289 = _e548;
                let _e549 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_284), (&param_285), (&param_286), (&param_287), (&param_288), (&param_289));
                Li_6 = _e549;
                let _e550 = Li_6;
                let _e551 = safeTint;
                let _e553 = comp_4;
                let _e555 = (*weight_6);
                (*bsdf_5).response = (((_e550 * _e551) * _e553) * _e555);
            }
        }
    }
    return;
}

fn makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b(closureType: ptr<function, i32>, L_10: ptr<function, vec3<f32>>, V_13: ptr<function, vec3<f32>>, N_17: ptr<function, vec3<f32>>, P_2: ptr<function, vec3<f32>>, occlusion_1: ptr<function, f32>) -> ClosureData {
    let _e289 = (*closureType);
    let _e290 = (*L_10);
    let _e291 = (*V_13);
    let _e292 = (*N_17);
    let _e293 = (*P_2);
    let _e294 = (*occlusion_1);
    return ClosureData(_e289, _e290, _e291, _e292, _e293, _e294);
}

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_8: ptr<function, lightshader>) {
    (*result_8).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_8).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e284 = unnamed.mtlxLightCount;
    return min(_e284, 1i);
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_4: ptr<function, f32>, mtlxRasterOut: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e286 = (*in1_4);
    combine_out = vec3(_e286);
    let _e288 = combine_out;
    (*mtlxRasterOut) = _e288;
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

    let _e294 = (*reflectivity);
    r_3 = clamp(_e294, vec3(0f), vec3(0.99f));
    let _e298 = r_3;
    r_sqrt = sqrt(_e298);
    let _e300 = r_3;
    let _e303 = r_3;
    n_min = ((vec3(1f) - _e300) / (vec3(1f) + _e303));
    let _e307 = r_sqrt;
    let _e310 = r_sqrt;
    n_max = ((vec3(1f) + _e307) / (vec3(1f) - _e310));
    let _e314 = n_max;
    let _e315 = n_min;
    let _e316 = (*edge_color);
    (*ior_7) = mix(_e314, _e315, _e316);
    let _e318 = (*ior_7);
    np1_ = (_e318 + vec3(1f));
    let _e321 = (*ior_7);
    nm1_ = (_e321 - vec3(1f));
    let _e324 = np1_;
    let _e325 = np1_;
    let _e327 = r_3;
    let _e329 = nm1_;
    let _e330 = nm1_;
    let _e333 = r_3;
    k2_2 = ((((_e324 * _e325) * _e327) - (_e329 * _e330)) / (vec3(1f) - _e333));
    let _e337 = k2_2;
    k2_2 = max(_e337, vec3(0f));
    let _e340 = k2_2;
    (*extinction_1) = sqrt(_e340);
    return;
}

fn mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b(_in: ptr<function, vec3<f32>>, amount: ptr<function, f32>, axis: ptr<function, vec3<f32>>, result_9: ptr<function, vec3<f32>>) {
    var rotationRadians: f32;
    var s_4: f32;
    var c_3: f32;
    var oc: f32;

    let _e291 = (*axis);
    (*axis) = normalize(_e291);
    let _e293 = (*amount);
    rotationRadians = radians(_e293);
    let _e295 = rotationRadians;
    s_4 = sin(_e295);
    let _e297 = rotationRadians;
    c_3 = cos(_e297);
    let _e299 = c_3;
    oc = (1f - _e299);
    let _e301 = (*_in);
    let _e302 = c_3;
    let _e304 = (*_in);
    let _e305 = (*axis);
    let _e307 = s_4;
    let _e310 = (*axis);
    let _e311 = (*axis);
    let _e312 = (*_in);
    let _e315 = oc;
    (*result_9) = (((_e301 * _e302) + (cross(_e304, _e305) * _e307)) + ((_e310 * dot(_e311, _e312)) * _e315));
    return;
}

fn mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b(_in_1: ptr<function, vec3<f32>>, lumacoeffs: ptr<function, vec3<f32>>, result_10: ptr<function, vec3<f32>>) {
    let _e286 = (*_in_1);
    let _e287 = (*lumacoeffs);
    (*result_10) = vec3(dot(_e286, _e287));
    return;
}

fn mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_1: ptr<function, f32>, result_11: ptr<function, vec2<f32>>) {
    var roughness_sqr: f32;
    var aspect: f32;

    let _e288 = (*roughness_16);
    let _e289 = (*roughness_16);
    roughness_sqr = clamp((_e288 * _e289), 0.00000001f, 1f);
    let _e292 = (*anisotropy_1);
    if (_e292 > 0f) {
        let _e294 = (*anisotropy_1);
        aspect = sqrt((1f - clamp(_e294, 0f, 0.98f)));
        let _e298 = roughness_sqr;
        let _e299 = aspect;
        (*result_11)[0u] = min((_e298 / _e299), 1f);
        let _e303 = roughness_sqr;
        let _e304 = aspect;
        (*result_11)[1u] = (_e303 * _e304);
    } else {
        let _e307 = roughness_sqr;
        (*result_11)[0u] = _e307;
        let _e309 = roughness_sqr;
        (*result_11)[1u] = _e309;
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
    let _e884 = (*coat_roughness);
    param_290 = _e884;
    let _e885 = (*coat_anisotropy);
    param_291 = _e885;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_290), (&param_291), (&param_292));
    let _e886 = param_292;
    coat_roughness_vector_out = _e886;
    let _e887 = (*coat_rotation);
    coat_tangent_rotate_degree_out = (_e887 * 360f);
    let _e889 = (*metalness);
    metalness_mix_fg_weight_out = (1f * _e889);
    let _e891 = (*base_color);
    let _e892 = (*base_2);
    metal_reflectivity_out = (_e891 * _e892);
    let _e894 = (*specular_color);
    let _e895 = (*specular);
    metal_edgecolor_out = (_e894 * _e895);
    let _e897 = (*coat_affect_roughness);
    let _e898 = (*coat);
    coat_affect_roughness_multiply1_out = (_e897 * _e898);
    let _e900 = (*specular_rotation);
    tangent_rotate_degree_out = (_e900 * 360f);
    let _e902 = (*transmission);
    transmission_mix_fg_weight_out = (1f * _e902);
    let _e904 = (*specular_roughness);
    let _e905 = (*transmission_extra_roughness);
    transmission_roughness_add_out = (_e904 + _e905);
    let _e907 = (*thin_walled);
    subsurface_selector_out = select(0f, 1f, _e907);
    let _e909 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e909, vec3(0f));
    let _e912 = (*coat);
    coat_clamped_out = clamp(_e912, 0f, 1f);
    let _e914 = (*subsurface_radius);
    let _e915 = (*subsurface_scale);
    subsurface_radius_scaled_out = (_e914 * _e915);
    let _e917 = (*subsurface);
    subsurface_mix_mix_inv_out = (1f - _e917);
    let _e919 = (*base_color);
    base_color_nonnegative_out = max(_e919, vec3(0f));
    let _e922 = (*transmission);
    transmission_mix_mix_inv_out = (1f - _e922);
    let _e924 = (*metalness);
    metalness_mix_mix_inv_out = (1f - _e924);
    let _e926 = (*coat_color);
    let _e927 = (*coat);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e926, vec3(_e927));
    let _e930 = (*coat_IOR);
    one_minus_coat_ior_out = (1f - _e930);
    let _e932 = (*coat_IOR);
    one_plus_coat_ior_out = (1f + _e932);
    let _e934 = (*emission_color);
    let _e935 = (*emission);
    emission_weight_out = (_e934 * _e935);
    opacity_luminance_out = vec3<f32>(0f, 0f, 0f);
    let _e937 = (*opacity);
    param_293 = _e937;
    param_294 = vec3<f32>(0.272229f, 0.674082f, 0.053689f);
    mx_luminance_color3_u0028_vf3_u003b_vf3_u003b_vf3_u003b((&param_293), (&param_294), (&param_295));
    let _e938 = param_295;
    opacity_luminance_out = _e938;
    coat_tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e939 = (*tangent);
    param_296 = _e939;
    let _e940 = coat_tangent_rotate_degree_out;
    param_297 = _e940;
    let _e941 = (*coat_normal);
    param_298 = _e941;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_296), (&param_297), (&param_298), (&param_299));
    let _e942 = param_299;
    coat_tangent_rotate_out = _e942;
    artistic_ior_ior = vec3<f32>(0f, 0f, 0f);
    artistic_ior_extinction = vec3<f32>(0f, 0f, 0f);
    let _e943 = metal_reflectivity_out;
    param_300 = _e943;
    let _e944 = metal_edgecolor_out;
    param_301 = _e944;
    mx_artistic_ior_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_300), (&param_301), (&param_302), (&param_303));
    let _e945 = param_302;
    artistic_ior_ior = _e945;
    let _e946 = param_303;
    artistic_ior_extinction = _e946;
    let _e947 = coat_affect_roughness_multiply1_out;
    let _e948 = (*coat_roughness);
    coat_affect_roughness_multiply2_out = (_e947 * _e948);
    tangent_rotate_out = vec3<f32>(0f, 0f, 0f);
    let _e950 = (*tangent);
    param_304 = _e950;
    let _e951 = tangent_rotate_degree_out;
    param_305 = _e951;
    let _e952 = (*normal);
    param_306 = _e952;
    mx_rotate_vector3_u0028_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_304), (&param_305), (&param_306), (&param_307));
    let _e953 = param_307;
    tangent_rotate_out = _e953;
    let _e954 = transmission_roughness_add_out;
    transmission_roughness_clamped_out = clamp(_e954, 0f, 1f);
    let _e956 = subsurface_selector_out;
    selected_subsurface_bsdf_mix_inv_out = (1f - _e956);
    let _e958 = subsurface_selector_out;
    selected_subsurface_bsdf_fg_weight_out = (1f * _e958);
    let _e960 = coat_clamped_out;
    let _e961 = (*coat_affect_color);
    coat_gamma_multiply_out = (_e960 * _e961);
    let _e963 = (*base_2);
    let _e964 = subsurface_mix_mix_inv_out;
    subsurface_mix_bg_weight_out = (_e963 * _e964);
    let _e966 = one_minus_coat_ior_out;
    let _e967 = one_plus_coat_ior_out;
    coat_ior_to_F0_sqrt_out = (_e966 / _e967);
    let _e970 = opacity_luminance_out[0u];
    opacity_luminance_float_out = _e970;
    let _e971 = coat_tangent_rotate_out;
    coat_tangent_rotate_normalize_out = normalize(_e971);
    let _e973 = (*specular_roughness);
    let _e974 = coat_affect_roughness_multiply2_out;
    coat_affected_roughness_out = mix(_e973, 1f, _e974);
    let _e976 = tangent_rotate_out;
    tangent_rotate_normalize_out = normalize(_e976);
    let _e978 = transmission_roughness_clamped_out;
    let _e979 = coat_affect_roughness_multiply2_out;
    coat_affected_transmission_roughness_out = mix(_e978, 1f, _e979);
    let _e981 = selected_subsurface_bsdf_mix_inv_out;
    selected_subsurface_bsdf_bg_weight_out = (1f * _e981);
    let _e983 = coat_gamma_multiply_out;
    coat_gamma_out = (_e983 + 1f);
    let _e985 = coat_ior_to_F0_sqrt_out;
    let _e986 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e985 * _e986);
    let _e988 = (*coat_anisotropy);
    let _e990 = coat_tangent_rotate_normalize_out;
    let _e991 = (*tangent);
    coat_tangent_out = select(_e991, _e990, (_e988 > 0f));
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e993 = coat_affected_roughness_out;
    param_308 = _e993;
    let _e994 = (*specular_anisotropy);
    param_309 = _e994;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_308), (&param_309), (&param_310));
    let _e995 = param_310;
    main_roughness_out = _e995;
    let _e996 = (*specular_anisotropy);
    let _e998 = tangent_rotate_normalize_out;
    let _e999 = (*tangent);
    main_tangent_out = select(_e999, _e998, (_e996 > 0f));
    transmission_roughness_out = vec2<f32>(0f, 0f);
    let _e1001 = coat_affected_transmission_roughness_out;
    param_311 = _e1001;
    let _e1002 = (*specular_anisotropy);
    param_312 = _e1002;
    mx_roughness_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_311), (&param_312), (&param_313));
    let _e1003 = param_313;
    transmission_roughness_out = _e1003;
    let _e1004 = subsurface_color_nonnegative_out;
    let _e1005 = coat_gamma_out;
    coat_affected_subsurface_color_out = pow(_e1004, vec3(_e1005));
    let _e1008 = base_color_nonnegative_out;
    let _e1009 = coat_gamma_out;
    coat_affected_diffuse_color_out = pow(_e1008, vec3(_e1009));
    let _e1012 = coat_ior_to_F0_out;
    one_minus_coat_ior_to_F0_out = (1f - _e1012);
    emission_color0_out = vec3<f32>(0f, 0f, 0f);
    let _e1014 = one_minus_coat_ior_to_F0_out;
    param_314 = _e1014;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_314), (&param_315));
    let _e1015 = param_315;
    emission_color0_out = _e1015;
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e1016 = normalWorld;
    N_18 = normalize(_e1016);
    let _e1020 = unnamed.cameraWorldMatrix[3];
    let _e1022 = positionWorld;
    V_14 = normalize((_e1020.xyz - _e1022));
    let _e1025 = positionWorld;
    P_3 = _e1025;
    L_11 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e1026 = opacity_luminance_float_out;
    surfaceOpacity = _e1026;
    let _e1027 = numActiveLightSources_u0028_();
    numLights = _e1027;
    activeLightIndex = 0i;
    loop {
        let _e1028 = activeLightIndex;
        let _e1029 = numLights;
        if (_e1028 < _e1029) {
            let _e1031 = activeLightIndex;
            let _e1034 = unnamed.u_lightData[_e1031];
            param_316 = _e1034;
            let _e1035 = positionWorld;
            param_317 = _e1035;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_316), (&param_317), (&param_318));
            let _e1036 = param_318;
            lightShader = _e1036;
            let _e1038 = lightShader.direction;
            L_11 = _e1038;
            param_319 = 1i;
            let _e1039 = L_11;
            param_320 = _e1039;
            let _e1040 = V_14;
            param_321 = _e1040;
            let _e1041 = N_18;
            param_322 = _e1041;
            let _e1042 = P_3;
            param_323 = _e1042;
            let _e1043 = occlusion_2;
            param_324 = _e1043;
            let _e1044 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322), (&param_323), (&param_324));
            closureData_14 = _e1044;
            coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1045 = closureData_14;
            param_325 = _e1045;
            let _e1046 = (*coat);
            param_326 = _e1046;
            param_327 = vec3<f32>(1f, 1f, 1f);
            let _e1047 = (*coat_IOR);
            param_328 = _e1047;
            let _e1048 = coat_roughness_vector_out;
            param_329 = _e1048;
            param_330 = false;
            param_331 = 0f;
            param_332 = 1.5f;
            let _e1049 = (*coat_normal);
            param_333 = _e1049;
            let _e1050 = coat_tangent_out;
            param_334 = _e1050;
            param_335 = 0i;
            param_336 = 0i;
            let _e1051 = coat_bsdf_out;
            param_337 = _e1051;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_325), (&param_326), (&param_327), (&param_328), (&param_329), (&param_330), (&param_331), (&param_332), (&param_333), (&param_334), (&param_335), (&param_336), (&param_337));
            let _e1052 = param_337;
            coat_bsdf_out = _e1052;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1053 = closureData_14;
            param_338 = _e1053;
            let _e1054 = metalness_mix_fg_weight_out;
            param_339 = _e1054;
            let _e1055 = artistic_ior_ior;
            param_340 = _e1055;
            let _e1056 = artistic_ior_extinction;
            param_341 = _e1056;
            let _e1057 = main_roughness_out;
            param_342 = _e1057;
            param_343 = false;
            let _e1058 = (*thin_film_thickness);
            param_344 = _e1058;
            let _e1059 = (*thin_film_IOR);
            param_345 = _e1059;
            let _e1060 = (*normal);
            param_346 = _e1060;
            let _e1061 = main_tangent_out;
            param_347 = _e1061;
            param_348 = 0i;
            let _e1062 = metal_bsdf_out;
            param_349 = _e1062;
            mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_338), (&param_339), (&param_340), (&param_341), (&param_342), (&param_343), (&param_344), (&param_345), (&param_346), (&param_347), (&param_348), (&param_349));
            let _e1063 = param_349;
            metal_bsdf_out = _e1063;
            specular_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1064 = closureData_14;
            param_350 = _e1064;
            let _e1065 = (*specular);
            param_351 = _e1065;
            let _e1066 = (*specular_color);
            param_352 = _e1066;
            let _e1067 = (*specular_IOR);
            param_353 = _e1067;
            let _e1068 = main_roughness_out;
            param_354 = _e1068;
            param_355 = false;
            let _e1069 = (*thin_film_thickness);
            param_356 = _e1069;
            let _e1070 = (*thin_film_IOR);
            param_357 = _e1070;
            let _e1071 = (*normal);
            param_358 = _e1071;
            let _e1072 = main_tangent_out;
            param_359 = _e1072;
            param_360 = 0i;
            param_361 = 0i;
            let _e1073 = specular_bsdf_out;
            param_362 = _e1073;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_350), (&param_351), (&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358), (&param_359), (&param_360), (&param_361), (&param_362));
            let _e1074 = param_362;
            specular_bsdf_out = _e1074;
            transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1075 = closureData_14;
            param_363 = _e1075;
            let _e1076 = transmission_mix_fg_weight_out;
            param_364 = _e1076;
            let _e1077 = (*transmission_color);
            param_365 = _e1077;
            let _e1078 = (*specular_IOR);
            param_366 = _e1078;
            let _e1079 = transmission_roughness_out;
            param_367 = _e1079;
            param_368 = false;
            param_369 = 0f;
            param_370 = 1.5f;
            let _e1080 = (*normal);
            param_371 = _e1080;
            let _e1081 = main_tangent_out;
            param_372 = _e1081;
            param_373 = 0i;
            param_374 = 1i;
            let _e1082 = transmission_bsdf_out;
            param_375 = _e1082;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371), (&param_372), (&param_373), (&param_374), (&param_375));
            let _e1083 = param_375;
            transmission_bsdf_out = _e1083;
            sheen_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1084 = closureData_14;
            param_376 = _e1084;
            let _e1085 = (*sheen);
            param_377 = _e1085;
            let _e1086 = (*sheen_color);
            param_378 = _e1086;
            let _e1087 = (*sheen_roughness);
            param_379 = _e1087;
            let _e1088 = (*normal);
            param_380 = _e1088;
            param_381 = 0i;
            let _e1089 = sheen_bsdf_out;
            param_382 = _e1089;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382));
            let _e1090 = param_382;
            sheen_bsdf_out = _e1090;
            translucent_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1091 = closureData_14;
            param_383 = _e1091;
            let _e1092 = selected_subsurface_bsdf_fg_weight_out;
            param_384 = _e1092;
            let _e1093 = coat_affected_subsurface_color_out;
            param_385 = _e1093;
            let _e1094 = (*normal);
            param_386 = _e1094;
            let _e1095 = translucent_bsdf_out;
            param_387 = _e1095;
            mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_383), (&param_384), (&param_385), (&param_386), (&param_387));
            let _e1096 = param_387;
            translucent_bsdf_out = _e1096;
            subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1097 = closureData_14;
            param_388 = _e1097;
            let _e1098 = selected_subsurface_bsdf_bg_weight_out;
            param_389 = _e1098;
            let _e1099 = coat_affected_subsurface_color_out;
            param_390 = _e1099;
            let _e1100 = subsurface_radius_scaled_out;
            param_391 = _e1100;
            let _e1101 = (*subsurface_anisotropy);
            param_392 = _e1101;
            let _e1102 = (*normal);
            param_393 = _e1102;
            let _e1103 = subsurface_bsdf_out;
            param_394 = _e1103;
            mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394));
            let _e1104 = param_394;
            subsurface_bsdf_out = _e1104;
            selected_subsurface_bsdf_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1105 = closureData_14;
            param_395 = _e1105;
            let _e1106 = translucent_bsdf_out;
            param_396 = _e1106;
            let _e1107 = subsurface_bsdf_out;
            param_397 = _e1107;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_395), (&param_396), (&param_397), (&param_398));
            let _e1108 = param_398;
            selected_subsurface_bsdf_add_out = _e1108;
            subsurface_mix_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1109 = closureData_14;
            param_399 = _e1109;
            let _e1110 = selected_subsurface_bsdf_add_out;
            param_400 = _e1110;
            let _e1111 = (*subsurface);
            param_401 = _e1111;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_399), (&param_400), (&param_401), (&param_402));
            let _e1112 = param_402;
            subsurface_mix_fg_mul_out = _e1112;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1113 = closureData_14;
            param_403 = _e1113;
            let _e1114 = subsurface_mix_bg_weight_out;
            param_404 = _e1114;
            let _e1115 = coat_affected_diffuse_color_out;
            param_405 = _e1115;
            let _e1116 = (*diffuse_roughness);
            param_406 = _e1116;
            let _e1117 = (*normal);
            param_407 = _e1117;
            param_408 = false;
            let _e1118 = diffuse_bsdf_out;
            param_409 = _e1118;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_403), (&param_404), (&param_405), (&param_406), (&param_407), (&param_408), (&param_409));
            let _e1119 = param_409;
            diffuse_bsdf_out = _e1119;
            subsurface_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1120 = closureData_14;
            param_410 = _e1120;
            let _e1121 = subsurface_mix_fg_mul_out;
            param_411 = _e1121;
            let _e1122 = diffuse_bsdf_out;
            param_412 = _e1122;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_410), (&param_411), (&param_412), (&param_413));
            let _e1123 = param_413;
            subsurface_mix_add_out = _e1123;
            sheen_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1124 = closureData_14;
            param_414 = _e1124;
            let _e1125 = sheen_bsdf_out;
            param_415 = _e1125;
            let _e1126 = subsurface_mix_add_out;
            param_416 = _e1126;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_414), (&param_415), (&param_416), (&param_417));
            let _e1127 = param_417;
            sheen_layer_out = _e1127;
            transmission_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1128 = closureData_14;
            param_418 = _e1128;
            let _e1129 = sheen_layer_out;
            param_419 = _e1129;
            let _e1130 = transmission_mix_mix_inv_out;
            param_420 = _e1130;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_418), (&param_419), (&param_420), (&param_421));
            let _e1131 = param_421;
            transmission_mix_bg_mul_out = _e1131;
            transmission_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1132 = closureData_14;
            param_422 = _e1132;
            let _e1133 = transmission_bsdf_out;
            param_423 = _e1133;
            let _e1134 = transmission_mix_bg_mul_out;
            param_424 = _e1134;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_422), (&param_423), (&param_424), (&param_425));
            let _e1135 = param_425;
            transmission_mix_add_out = _e1135;
            specular_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1136 = closureData_14;
            param_426 = _e1136;
            let _e1137 = specular_bsdf_out;
            param_427 = _e1137;
            let _e1138 = transmission_mix_add_out;
            param_428 = _e1138;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_426), (&param_427), (&param_428), (&param_429));
            let _e1139 = param_429;
            specular_layer_out = _e1139;
            metalness_mix_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1140 = closureData_14;
            param_430 = _e1140;
            let _e1141 = specular_layer_out;
            param_431 = _e1141;
            let _e1142 = metalness_mix_mix_inv_out;
            param_432 = _e1142;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_430), (&param_431), (&param_432), (&param_433));
            let _e1143 = param_433;
            metalness_mix_bg_mul_out = _e1143;
            metalness_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1144 = closureData_14;
            param_434 = _e1144;
            let _e1145 = metal_bsdf_out;
            param_435 = _e1145;
            let _e1146 = metalness_mix_bg_mul_out;
            param_436 = _e1146;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_434), (&param_435), (&param_436), (&param_437));
            let _e1147 = param_437;
            metalness_mix_add_out = _e1147;
            thin_film_layer_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1148 = closureData_14;
            param_438 = _e1148;
            let _e1149 = metalness_mix_add_out;
            param_439 = _e1149;
            let _e1150 = coat_attenuation_out;
            param_440 = _e1150;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_438), (&param_439), (&param_440), (&param_441));
            let _e1151 = param_441;
            thin_film_layer_attenuated_out = _e1151;
            coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1152 = closureData_14;
            param_442 = _e1152;
            let _e1153 = coat_bsdf_out;
            param_443 = _e1153;
            let _e1154 = thin_film_layer_attenuated_out;
            param_444 = _e1154;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_442), (&param_443), (&param_444), (&param_445));
            let _e1155 = param_445;
            coat_layer_out = _e1155;
            let _e1157 = lightShader.intensity;
            let _e1159 = coat_layer_out.response;
            let _e1162 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1162 + (_e1157 * _e1159));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1165 = activeLightIndex;
            activeLightIndex = (_e1165 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_446 = 3i;
    let _e1167 = L_11;
    param_447 = _e1167;
    let _e1168 = V_14;
    param_448 = _e1168;
    let _e1169 = N_18;
    param_449 = _e1169;
    let _e1170 = P_3;
    param_450 = _e1170;
    let _e1171 = occlusion_2;
    param_451 = _e1171;
    let _e1172 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451));
    closureData_15 = _e1172;
    coat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1173 = closureData_15;
    param_452 = _e1173;
    let _e1174 = (*coat);
    param_453 = _e1174;
    param_454 = vec3<f32>(1f, 1f, 1f);
    let _e1175 = (*coat_IOR);
    param_455 = _e1175;
    let _e1176 = coat_roughness_vector_out;
    param_456 = _e1176;
    param_457 = false;
    param_458 = 0f;
    param_459 = 1.5f;
    let _e1177 = (*coat_normal);
    param_460 = _e1177;
    let _e1178 = coat_tangent_out;
    param_461 = _e1178;
    param_462 = 0i;
    param_463 = 0i;
    let _e1179 = coat_bsdf_out_1;
    param_464 = _e1179;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_452), (&param_453), (&param_454), (&param_455), (&param_456), (&param_457), (&param_458), (&param_459), (&param_460), (&param_461), (&param_462), (&param_463), (&param_464));
    let _e1180 = param_464;
    coat_bsdf_out_1 = _e1180;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1181 = closureData_15;
    param_465 = _e1181;
    let _e1182 = metalness_mix_fg_weight_out;
    param_466 = _e1182;
    let _e1183 = artistic_ior_ior;
    param_467 = _e1183;
    let _e1184 = artistic_ior_extinction;
    param_468 = _e1184;
    let _e1185 = main_roughness_out;
    param_469 = _e1185;
    param_470 = false;
    let _e1186 = (*thin_film_thickness);
    param_471 = _e1186;
    let _e1187 = (*thin_film_IOR);
    param_472 = _e1187;
    let _e1188 = (*normal);
    param_473 = _e1188;
    let _e1189 = main_tangent_out;
    param_474 = _e1189;
    param_475 = 0i;
    let _e1190 = metal_bsdf_out_1;
    param_476 = _e1190;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_465), (&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472), (&param_473), (&param_474), (&param_475), (&param_476));
    let _e1191 = param_476;
    metal_bsdf_out_1 = _e1191;
    specular_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1192 = closureData_15;
    param_477 = _e1192;
    let _e1193 = (*specular);
    param_478 = _e1193;
    let _e1194 = (*specular_color);
    param_479 = _e1194;
    let _e1195 = (*specular_IOR);
    param_480 = _e1195;
    let _e1196 = main_roughness_out;
    param_481 = _e1196;
    param_482 = false;
    let _e1197 = (*thin_film_thickness);
    param_483 = _e1197;
    let _e1198 = (*thin_film_IOR);
    param_484 = _e1198;
    let _e1199 = (*normal);
    param_485 = _e1199;
    let _e1200 = main_tangent_out;
    param_486 = _e1200;
    param_487 = 0i;
    param_488 = 0i;
    let _e1201 = specular_bsdf_out_1;
    param_489 = _e1201;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_477), (&param_478), (&param_479), (&param_480), (&param_481), (&param_482), (&param_483), (&param_484), (&param_485), (&param_486), (&param_487), (&param_488), (&param_489));
    let _e1202 = param_489;
    specular_bsdf_out_1 = _e1202;
    transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1203 = closureData_15;
    param_490 = _e1203;
    let _e1204 = transmission_mix_fg_weight_out;
    param_491 = _e1204;
    let _e1205 = (*transmission_color);
    param_492 = _e1205;
    let _e1206 = (*specular_IOR);
    param_493 = _e1206;
    let _e1207 = transmission_roughness_out;
    param_494 = _e1207;
    param_495 = false;
    param_496 = 0f;
    param_497 = 1.5f;
    let _e1208 = (*normal);
    param_498 = _e1208;
    let _e1209 = main_tangent_out;
    param_499 = _e1209;
    param_500 = 0i;
    param_501 = 1i;
    let _e1210 = transmission_bsdf_out_1;
    param_502 = _e1210;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_490), (&param_491), (&param_492), (&param_493), (&param_494), (&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501), (&param_502));
    let _e1211 = param_502;
    transmission_bsdf_out_1 = _e1211;
    sheen_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1212 = closureData_15;
    param_503 = _e1212;
    let _e1213 = (*sheen);
    param_504 = _e1213;
    let _e1214 = (*sheen_color);
    param_505 = _e1214;
    let _e1215 = (*sheen_roughness);
    param_506 = _e1215;
    let _e1216 = (*normal);
    param_507 = _e1216;
    param_508 = 0i;
    let _e1217 = sheen_bsdf_out_1;
    param_509 = _e1217;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_503), (&param_504), (&param_505), (&param_506), (&param_507), (&param_508), (&param_509));
    let _e1218 = param_509;
    sheen_bsdf_out_1 = _e1218;
    translucent_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1219 = closureData_15;
    param_510 = _e1219;
    let _e1220 = selected_subsurface_bsdf_fg_weight_out;
    param_511 = _e1220;
    let _e1221 = coat_affected_subsurface_color_out;
    param_512 = _e1221;
    let _e1222 = (*normal);
    param_513 = _e1222;
    let _e1223 = translucent_bsdf_out_1;
    param_514 = _e1223;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_510), (&param_511), (&param_512), (&param_513), (&param_514));
    let _e1224 = param_514;
    translucent_bsdf_out_1 = _e1224;
    subsurface_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1225 = closureData_15;
    param_515 = _e1225;
    let _e1226 = selected_subsurface_bsdf_bg_weight_out;
    param_516 = _e1226;
    let _e1227 = coat_affected_subsurface_color_out;
    param_517 = _e1227;
    let _e1228 = subsurface_radius_scaled_out;
    param_518 = _e1228;
    let _e1229 = (*subsurface_anisotropy);
    param_519 = _e1229;
    let _e1230 = (*normal);
    param_520 = _e1230;
    let _e1231 = subsurface_bsdf_out_1;
    param_521 = _e1231;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_515), (&param_516), (&param_517), (&param_518), (&param_519), (&param_520), (&param_521));
    let _e1232 = param_521;
    subsurface_bsdf_out_1 = _e1232;
    selected_subsurface_bsdf_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1233 = closureData_15;
    param_522 = _e1233;
    let _e1234 = translucent_bsdf_out_1;
    param_523 = _e1234;
    let _e1235 = subsurface_bsdf_out_1;
    param_524 = _e1235;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_522), (&param_523), (&param_524), (&param_525));
    let _e1236 = param_525;
    selected_subsurface_bsdf_add_out_1 = _e1236;
    subsurface_mix_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1237 = closureData_15;
    param_526 = _e1237;
    let _e1238 = selected_subsurface_bsdf_add_out_1;
    param_527 = _e1238;
    let _e1239 = (*subsurface);
    param_528 = _e1239;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_526), (&param_527), (&param_528), (&param_529));
    let _e1240 = param_529;
    subsurface_mix_fg_mul_out_1 = _e1240;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1241 = closureData_15;
    param_530 = _e1241;
    let _e1242 = subsurface_mix_bg_weight_out;
    param_531 = _e1242;
    let _e1243 = coat_affected_diffuse_color_out;
    param_532 = _e1243;
    let _e1244 = (*diffuse_roughness);
    param_533 = _e1244;
    let _e1245 = (*normal);
    param_534 = _e1245;
    param_535 = false;
    let _e1246 = diffuse_bsdf_out_1;
    param_536 = _e1246;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_530), (&param_531), (&param_532), (&param_533), (&param_534), (&param_535), (&param_536));
    let _e1247 = param_536;
    diffuse_bsdf_out_1 = _e1247;
    subsurface_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1248 = closureData_15;
    param_537 = _e1248;
    let _e1249 = subsurface_mix_fg_mul_out_1;
    param_538 = _e1249;
    let _e1250 = diffuse_bsdf_out_1;
    param_539 = _e1250;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_537), (&param_538), (&param_539), (&param_540));
    let _e1251 = param_540;
    subsurface_mix_add_out_1 = _e1251;
    sheen_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1252 = closureData_15;
    param_541 = _e1252;
    let _e1253 = sheen_bsdf_out_1;
    param_542 = _e1253;
    let _e1254 = subsurface_mix_add_out_1;
    param_543 = _e1254;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_541), (&param_542), (&param_543), (&param_544));
    let _e1255 = param_544;
    sheen_layer_out_1 = _e1255;
    transmission_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1256 = closureData_15;
    param_545 = _e1256;
    let _e1257 = sheen_layer_out_1;
    param_546 = _e1257;
    let _e1258 = transmission_mix_mix_inv_out;
    param_547 = _e1258;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_545), (&param_546), (&param_547), (&param_548));
    let _e1259 = param_548;
    transmission_mix_bg_mul_out_1 = _e1259;
    transmission_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1260 = closureData_15;
    param_549 = _e1260;
    let _e1261 = transmission_bsdf_out_1;
    param_550 = _e1261;
    let _e1262 = transmission_mix_bg_mul_out_1;
    param_551 = _e1262;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_549), (&param_550), (&param_551), (&param_552));
    let _e1263 = param_552;
    transmission_mix_add_out_1 = _e1263;
    specular_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1264 = closureData_15;
    param_553 = _e1264;
    let _e1265 = specular_bsdf_out_1;
    param_554 = _e1265;
    let _e1266 = transmission_mix_add_out_1;
    param_555 = _e1266;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_553), (&param_554), (&param_555), (&param_556));
    let _e1267 = param_556;
    specular_layer_out_1 = _e1267;
    metalness_mix_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1268 = closureData_15;
    param_557 = _e1268;
    let _e1269 = specular_layer_out_1;
    param_558 = _e1269;
    let _e1270 = metalness_mix_mix_inv_out;
    param_559 = _e1270;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_557), (&param_558), (&param_559), (&param_560));
    let _e1271 = param_560;
    metalness_mix_bg_mul_out_1 = _e1271;
    metalness_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1272 = closureData_15;
    param_561 = _e1272;
    let _e1273 = metal_bsdf_out_1;
    param_562 = _e1273;
    let _e1274 = metalness_mix_bg_mul_out_1;
    param_563 = _e1274;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_561), (&param_562), (&param_563), (&param_564));
    let _e1275 = param_564;
    metalness_mix_add_out_1 = _e1275;
    thin_film_layer_attenuated_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1276 = closureData_15;
    param_565 = _e1276;
    let _e1277 = metalness_mix_add_out_1;
    param_566 = _e1277;
    let _e1278 = coat_attenuation_out;
    param_567 = _e1278;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_565), (&param_566), (&param_567), (&param_568));
    let _e1279 = param_568;
    thin_film_layer_attenuated_out_1 = _e1279;
    coat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1280 = closureData_15;
    param_569 = _e1280;
    let _e1281 = coat_bsdf_out_1;
    param_570 = _e1281;
    let _e1282 = thin_film_layer_attenuated_out_1;
    param_571 = _e1282;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_569), (&param_570), (&param_571), (&param_572));
    let _e1283 = param_572;
    coat_layer_out_1 = _e1283;
    let _e1284 = occlusion_2;
    let _e1286 = coat_layer_out_1.response;
    let _e1289 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1289 + (_e1286 * _e1284));
    param_573 = 4i;
    let _e1292 = L_11;
    param_574 = _e1292;
    let _e1293 = V_14;
    param_575 = _e1293;
    let _e1294 = N_18;
    param_576 = _e1294;
    let _e1295 = P_3;
    param_577 = _e1295;
    let _e1296 = occlusion_2;
    param_578 = _e1296;
    let _e1297 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578));
    closureData_16 = _e1297;
    emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1298 = closureData_16;
    param_579 = _e1298;
    let _e1299 = emission_weight_out;
    param_580 = _e1299;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_579), (&param_580), (&param_581));
    let _e1300 = param_581;
    emission_edf_out = _e1300;
    coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1301 = closureData_16;
    param_582 = _e1301;
    let _e1302 = emission_edf_out;
    param_583 = _e1302;
    let _e1303 = (*coat_color);
    param_584 = _e1303;
    mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_582), (&param_583), (&param_584), (&param_585));
    let _e1304 = param_585;
    coat_tinted_emission_edf_out = _e1304;
    coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1305 = closureData_16;
    param_586 = _e1305;
    let _e1306 = emission_color0_out;
    param_587 = _e1306;
    param_588 = vec3<f32>(0f, 0f, 0f);
    param_589 = 5f;
    let _e1307 = coat_tinted_emission_edf_out;
    param_590 = _e1307;
    mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591));
    let _e1308 = param_591;
    coat_emission_edf_out = _e1308;
    blended_coat_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1309 = closureData_16;
    param_592 = _e1309;
    let _e1310 = coat_emission_edf_out;
    param_593 = _e1310;
    let _e1311 = emission_edf_out;
    param_594 = _e1311;
    let _e1312 = (*coat);
    param_595 = _e1312;
    mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_592), (&param_593), (&param_594), (&param_595), (&param_596));
    let _e1313 = param_596;
    blended_coat_emission_edf_out = _e1313;
    let _e1314 = blended_coat_emission_edf_out;
    let _e1316 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1316 + _e1314);
    param_597 = 2i;
    let _e1319 = L_11;
    param_598 = _e1319;
    let _e1320 = V_14;
    param_599 = _e1320;
    let _e1321 = N_18;
    param_600 = _e1321;
    let _e1322 = P_3;
    param_601 = _e1322;
    let _e1323 = occlusion_2;
    param_602 = _e1323;
    let _e1324 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_597), (&param_598), (&param_599), (&param_600), (&param_601), (&param_602));
    closureData_17 = _e1324;
    coat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1325 = closureData_17;
    param_603 = _e1325;
    let _e1326 = (*coat);
    param_604 = _e1326;
    param_605 = vec3<f32>(1f, 1f, 1f);
    let _e1327 = (*coat_IOR);
    param_606 = _e1327;
    let _e1328 = coat_roughness_vector_out;
    param_607 = _e1328;
    param_608 = false;
    param_609 = 0f;
    param_610 = 1.5f;
    let _e1329 = (*coat_normal);
    param_611 = _e1329;
    let _e1330 = coat_tangent_out;
    param_612 = _e1330;
    param_613 = 0i;
    param_614 = 0i;
    let _e1331 = coat_bsdf_out_2;
    param_615 = _e1331;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612), (&param_613), (&param_614), (&param_615));
    let _e1332 = param_615;
    coat_bsdf_out_2 = _e1332;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1333 = closureData_17;
    param_616 = _e1333;
    let _e1334 = metalness_mix_fg_weight_out;
    param_617 = _e1334;
    let _e1335 = artistic_ior_ior;
    param_618 = _e1335;
    let _e1336 = artistic_ior_extinction;
    param_619 = _e1336;
    let _e1337 = main_roughness_out;
    param_620 = _e1337;
    param_621 = false;
    let _e1338 = (*thin_film_thickness);
    param_622 = _e1338;
    let _e1339 = (*thin_film_IOR);
    param_623 = _e1339;
    let _e1340 = (*normal);
    param_624 = _e1340;
    let _e1341 = main_tangent_out;
    param_625 = _e1341;
    param_626 = 0i;
    let _e1342 = metal_bsdf_out_2;
    param_627 = _e1342;
    mx_conductor_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_616), (&param_617), (&param_618), (&param_619), (&param_620), (&param_621), (&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627));
    let _e1343 = param_627;
    metal_bsdf_out_2 = _e1343;
    specular_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1344 = closureData_17;
    param_628 = _e1344;
    let _e1345 = (*specular);
    param_629 = _e1345;
    let _e1346 = (*specular_color);
    param_630 = _e1346;
    let _e1347 = (*specular_IOR);
    param_631 = _e1347;
    let _e1348 = main_roughness_out;
    param_632 = _e1348;
    param_633 = false;
    let _e1349 = (*thin_film_thickness);
    param_634 = _e1349;
    let _e1350 = (*thin_film_IOR);
    param_635 = _e1350;
    let _e1351 = (*normal);
    param_636 = _e1351;
    let _e1352 = main_tangent_out;
    param_637 = _e1352;
    param_638 = 0i;
    param_639 = 0i;
    let _e1353 = specular_bsdf_out_2;
    param_640 = _e1353;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_628), (&param_629), (&param_630), (&param_631), (&param_632), (&param_633), (&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640));
    let _e1354 = param_640;
    specular_bsdf_out_2 = _e1354;
    transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1355 = closureData_17;
    param_641 = _e1355;
    let _e1356 = transmission_mix_fg_weight_out;
    param_642 = _e1356;
    let _e1357 = (*transmission_color);
    param_643 = _e1357;
    let _e1358 = (*specular_IOR);
    param_644 = _e1358;
    let _e1359 = transmission_roughness_out;
    param_645 = _e1359;
    param_646 = false;
    param_647 = 0f;
    param_648 = 1.5f;
    let _e1360 = (*normal);
    param_649 = _e1360;
    let _e1361 = main_tangent_out;
    param_650 = _e1361;
    param_651 = 0i;
    param_652 = 1i;
    let _e1362 = transmission_bsdf_out_2;
    param_653 = _e1362;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_641), (&param_642), (&param_643), (&param_644), (&param_645), (&param_646), (&param_647), (&param_648), (&param_649), (&param_650), (&param_651), (&param_652), (&param_653));
    let _e1363 = param_653;
    transmission_bsdf_out_2 = _e1363;
    sheen_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1364 = closureData_17;
    param_654 = _e1364;
    let _e1365 = (*sheen);
    param_655 = _e1365;
    let _e1366 = (*sheen_color);
    param_656 = _e1366;
    let _e1367 = (*sheen_roughness);
    param_657 = _e1367;
    let _e1368 = (*normal);
    param_658 = _e1368;
    param_659 = 0i;
    let _e1369 = sheen_bsdf_out_2;
    param_660 = _e1369;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_654), (&param_655), (&param_656), (&param_657), (&param_658), (&param_659), (&param_660));
    let _e1370 = param_660;
    sheen_bsdf_out_2 = _e1370;
    translucent_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1371 = closureData_17;
    param_661 = _e1371;
    let _e1372 = selected_subsurface_bsdf_fg_weight_out;
    param_662 = _e1372;
    let _e1373 = coat_affected_subsurface_color_out;
    param_663 = _e1373;
    let _e1374 = (*normal);
    param_664 = _e1374;
    let _e1375 = translucent_bsdf_out_2;
    param_665 = _e1375;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_661), (&param_662), (&param_663), (&param_664), (&param_665));
    let _e1376 = param_665;
    translucent_bsdf_out_2 = _e1376;
    subsurface_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1377 = closureData_17;
    param_666 = _e1377;
    let _e1378 = selected_subsurface_bsdf_bg_weight_out;
    param_667 = _e1378;
    let _e1379 = coat_affected_subsurface_color_out;
    param_668 = _e1379;
    let _e1380 = subsurface_radius_scaled_out;
    param_669 = _e1380;
    let _e1381 = (*subsurface_anisotropy);
    param_670 = _e1381;
    let _e1382 = (*normal);
    param_671 = _e1382;
    let _e1383 = subsurface_bsdf_out_2;
    param_672 = _e1383;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_666), (&param_667), (&param_668), (&param_669), (&param_670), (&param_671), (&param_672));
    let _e1384 = param_672;
    subsurface_bsdf_out_2 = _e1384;
    selected_subsurface_bsdf_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1385 = closureData_17;
    param_673 = _e1385;
    let _e1386 = translucent_bsdf_out_2;
    param_674 = _e1386;
    let _e1387 = subsurface_bsdf_out_2;
    param_675 = _e1387;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_673), (&param_674), (&param_675), (&param_676));
    let _e1388 = param_676;
    selected_subsurface_bsdf_add_out_2 = _e1388;
    subsurface_mix_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1389 = closureData_17;
    param_677 = _e1389;
    let _e1390 = selected_subsurface_bsdf_add_out_2;
    param_678 = _e1390;
    let _e1391 = (*subsurface);
    param_679 = _e1391;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_677), (&param_678), (&param_679), (&param_680));
    let _e1392 = param_680;
    subsurface_mix_fg_mul_out_2 = _e1392;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1393 = closureData_17;
    param_681 = _e1393;
    let _e1394 = subsurface_mix_bg_weight_out;
    param_682 = _e1394;
    let _e1395 = coat_affected_diffuse_color_out;
    param_683 = _e1395;
    let _e1396 = (*diffuse_roughness);
    param_684 = _e1396;
    let _e1397 = (*normal);
    param_685 = _e1397;
    param_686 = false;
    let _e1398 = diffuse_bsdf_out_2;
    param_687 = _e1398;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_681), (&param_682), (&param_683), (&param_684), (&param_685), (&param_686), (&param_687));
    let _e1399 = param_687;
    diffuse_bsdf_out_2 = _e1399;
    subsurface_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1400 = closureData_17;
    param_688 = _e1400;
    let _e1401 = subsurface_mix_fg_mul_out_2;
    param_689 = _e1401;
    let _e1402 = diffuse_bsdf_out_2;
    param_690 = _e1402;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_688), (&param_689), (&param_690), (&param_691));
    let _e1403 = param_691;
    subsurface_mix_add_out_2 = _e1403;
    sheen_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1404 = closureData_17;
    param_692 = _e1404;
    let _e1405 = sheen_bsdf_out_2;
    param_693 = _e1405;
    let _e1406 = subsurface_mix_add_out_2;
    param_694 = _e1406;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_692), (&param_693), (&param_694), (&param_695));
    let _e1407 = param_695;
    sheen_layer_out_2 = _e1407;
    transmission_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1408 = closureData_17;
    param_696 = _e1408;
    let _e1409 = sheen_layer_out_2;
    param_697 = _e1409;
    let _e1410 = transmission_mix_mix_inv_out;
    param_698 = _e1410;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_696), (&param_697), (&param_698), (&param_699));
    let _e1411 = param_699;
    transmission_mix_bg_mul_out_2 = _e1411;
    transmission_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1412 = closureData_17;
    param_700 = _e1412;
    let _e1413 = transmission_bsdf_out_2;
    param_701 = _e1413;
    let _e1414 = transmission_mix_bg_mul_out_2;
    param_702 = _e1414;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_700), (&param_701), (&param_702), (&param_703));
    let _e1415 = param_703;
    transmission_mix_add_out_2 = _e1415;
    specular_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1416 = closureData_17;
    param_704 = _e1416;
    let _e1417 = specular_bsdf_out_2;
    param_705 = _e1417;
    let _e1418 = transmission_mix_add_out_2;
    param_706 = _e1418;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_704), (&param_705), (&param_706), (&param_707));
    let _e1419 = param_707;
    specular_layer_out_2 = _e1419;
    metalness_mix_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1420 = closureData_17;
    param_708 = _e1420;
    let _e1421 = specular_layer_out_2;
    param_709 = _e1421;
    let _e1422 = metalness_mix_mix_inv_out;
    param_710 = _e1422;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_708), (&param_709), (&param_710), (&param_711));
    let _e1423 = param_711;
    metalness_mix_bg_mul_out_2 = _e1423;
    metalness_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1424 = closureData_17;
    param_712 = _e1424;
    let _e1425 = metal_bsdf_out_2;
    param_713 = _e1425;
    let _e1426 = metalness_mix_bg_mul_out_2;
    param_714 = _e1426;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_712), (&param_713), (&param_714), (&param_715));
    let _e1427 = param_715;
    metalness_mix_add_out_2 = _e1427;
    thin_film_layer_attenuated_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1428 = closureData_17;
    param_716 = _e1428;
    let _e1429 = metalness_mix_add_out_2;
    param_717 = _e1429;
    let _e1430 = coat_attenuation_out;
    param_718 = _e1430;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_716), (&param_717), (&param_718), (&param_719));
    let _e1431 = param_719;
    thin_film_layer_attenuated_out_2 = _e1431;
    coat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1432 = closureData_17;
    param_720 = _e1432;
    let _e1433 = coat_bsdf_out_2;
    param_721 = _e1433;
    let _e1434 = thin_film_layer_attenuated_out_2;
    param_722 = _e1434;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_720), (&param_721), (&param_722), (&param_723));
    let _e1435 = param_723;
    coat_layer_out_2 = _e1435;
    let _e1437 = coat_layer_out_2.response;
    let _e1439 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1439 + _e1437);
    let _e1442 = surfaceOpacity;
    let _e1444 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1444 * _e1442);
    let _e1448 = shader_constructor_out.transparency;
    let _e1449 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e1448, vec3(_e1449));
    let _e1453 = shader_constructor_out;
    (*mtlxRasterOut_1) = _e1453;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var SR_metal_brushed_out: surfaceshader;
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

    let _e329 = normalWorld;
    geomprop_Nworld_out = normalize(_e329);
    let _e331 = tangentWorld;
    geomprop_Tworld_out = normalize(_e331);
    SR_metal_brushed_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e333 = base_3;
    param_724 = _e333;
    let _e334 = base_color_1;
    param_725 = _e334;
    let _e335 = diffuse_roughness_1;
    param_726 = _e335;
    let _e336 = metalness_1;
    param_727 = _e336;
    let _e337 = specular_1;
    param_728 = _e337;
    let _e338 = specular_color_1;
    param_729 = _e338;
    let _e339 = specular_roughness_1;
    param_730 = _e339;
    let _e340 = specular_IOR_1;
    param_731 = _e340;
    let _e341 = specular_anisotropy_1;
    param_732 = _e341;
    let _e342 = specular_rotation_1;
    param_733 = _e342;
    let _e343 = transmission_1;
    param_734 = _e343;
    let _e344 = transmission_color_1;
    param_735 = _e344;
    let _e345 = transmission_depth_1;
    param_736 = _e345;
    let _e346 = transmission_scatter_1;
    param_737 = _e346;
    let _e347 = transmission_scatter_anisotropy_1;
    param_738 = _e347;
    let _e348 = transmission_dispersion_1;
    param_739 = _e348;
    let _e349 = transmission_extra_roughness_1;
    param_740 = _e349;
    let _e350 = subsurface_1;
    param_741 = _e350;
    let _e351 = subsurface_color_1;
    param_742 = _e351;
    let _e352 = subsurface_radius_1;
    param_743 = _e352;
    let _e353 = subsurface_scale_1;
    param_744 = _e353;
    let _e354 = subsurface_anisotropy_1;
    param_745 = _e354;
    let _e355 = sheen_1;
    param_746 = _e355;
    let _e356 = sheen_color_1;
    param_747 = _e356;
    let _e357 = sheen_roughness_1;
    param_748 = _e357;
    let _e358 = coat_1;
    param_749 = _e358;
    let _e359 = coat_color_1;
    param_750 = _e359;
    let _e360 = coat_roughness_1;
    param_751 = _e360;
    let _e361 = coat_anisotropy_1;
    param_752 = _e361;
    let _e362 = coat_rotation_1;
    param_753 = _e362;
    let _e363 = coat_IOR_1;
    param_754 = _e363;
    let _e364 = geomprop_Nworld_out;
    param_755 = _e364;
    let _e365 = coat_affect_color_1;
    param_756 = _e365;
    let _e366 = coat_affect_roughness_1;
    param_757 = _e366;
    let _e367 = thin_film_thickness_1;
    param_758 = _e367;
    let _e368 = thin_film_IOR_1;
    param_759 = _e368;
    let _e369 = emission_1;
    param_760 = _e369;
    let _e370 = emission_color_1;
    param_761 = _e370;
    let _e371 = opacity_1;
    param_762 = _e371;
    let _e372 = thin_walled_1;
    param_763 = _e372;
    let _e373 = geomprop_Nworld_out;
    param_764 = _e373;
    let _e374 = geomprop_Tworld_out;
    param_765 = _e374;
    NG_standard_surface_surfaceshader_100_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_b1_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_724), (&param_725), (&param_726), (&param_727), (&param_728), (&param_729), (&param_730), (&param_731), (&param_732), (&param_733), (&param_734), (&param_735), (&param_736), (&param_737), (&param_738), (&param_739), (&param_740), (&param_741), (&param_742), (&param_743), (&param_744), (&param_745), (&param_746), (&param_747), (&param_748), (&param_749), (&param_750), (&param_751), (&param_752), (&param_753), (&param_754), (&param_755), (&param_756), (&param_757), (&param_758), (&param_759), (&param_760), (&param_761), (&param_762), (&param_763), (&param_764), (&param_765), (&param_766));
    let _e375 = param_766;
    SR_metal_brushed_out = _e375;
    let _e377 = SR_metal_brushed_out.color;
    mtlxRasterOut_2 = vec4<f32>(_e377.x, _e377.y, _e377.z, 1f);
    let _e382 = mtlxRasterOut_2;
    return _e382;
}

fn mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b(pW_1: ptr<function, vec3<f32>>, basis: ptr<function, Basis>, winputL: ptr<function, vec3<f32>>, woutputL: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e287 = mtlxRasterMain_u0028_();
    return _e287.xyz;
}

fn mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b(pW_2: ptr<function, vec3<f32>>, basis_1: ptr<function, Basis>, winputL_1: ptr<function, vec3<f32>>, rndSeed: ptr<function, u32>) {
    return;
}

fn worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b(vWorld: ptr<function, vec3<f32>>, basis_2: ptr<function, Basis>) -> vec3<f32> {
    let _e285 = (*vWorld);
    let _e287 = (*basis_2).tW;
    let _e289 = (*vWorld);
    let _e291 = (*basis_2).bW;
    let _e293 = (*vWorld);
    let _e295 = (*basis_2).nW;
    return vec3<f32>(dot(_e285, _e287), dot(_e289, _e291), dot(_e293, _e295));
}

fn safe_normalize_u0028_vf3_u003b(N_19: ptr<function, vec3<f32>>) -> vec3<f32> {
    var l: f32;

    let _e285 = (*N_19);
    l = length(_e285);
    let _e287 = (*N_19);
    let _e288 = l;
    return (_e287 / vec3(max(_e288, 0.0000000001f)));
}

fn makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b(nW: ptr<function, vec3<f32>>, tW: ptr<function, vec3<f32>>, bW: ptr<function, vec3<f32>>, baryCoord: ptr<function, vec3<f32>>, texCoord: ptr<function, vec2<f32>>) -> Basis {
    var basis_3: Basis;
    var param_767: vec3<f32>;
    var param_768: vec3<f32>;
    var param_769: vec3<f32>;

    let _e292 = (*nW);
    param_767 = _e292;
    let _e293 = safe_normalize_u0028_vf3_u003b((&param_767));
    basis_3.nW = _e293;
    let _e295 = (*tW);
    param_768 = _e295;
    let _e296 = safe_normalize_u0028_vf3_u003b((&param_768));
    basis_3.tW = _e296;
    let _e298 = (*bW);
    param_769 = _e298;
    let _e299 = safe_normalize_u0028_vf3_u003b((&param_769));
    basis_3.bW = _e299;
    let _e301 = (*baryCoord);
    basis_3.baryCoord = _e301;
    let _e303 = (*texCoord);
    basis_3.texCoord = _e303;
    let _e305 = basis_3;
    return _e305;
}

fn skyRadiance_u0028_vf3_u003b(woutputW: ptr<function, vec3<f32>>) -> vec3<f32> {
    var env: vec4<f32>;

    let _e286 = (*woutputW)[0u];
    let _e287 = (*woutputW);
    let _e288 = _e287.yz;
    let _e292 = textureSampleLevel(envMap_texture, envMap_sampler, vec3<f32>(_e286, _e288.x, _e288.y), 0f);
    env = _e292;
    let _e293 = env;
    let _e296 = unnamed.skyPower;
    let _e299 = unnamed.skyColor;
    return ((_e293.xyz * _e296) * _e299);
}

fn sunRadiance_u0028_vf3_u003b(woutputW_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta_max: f32;

    let _e286 = unnamed.sunAngularSize;
    theta_max = ((_e286 * 3.1415927f) / 180f);
    let _e289 = (*woutputW_1);
    let _e291 = unnamed.sunDir;
    let _e293 = theta_max;
    if (dot(_e289, _e291) < cos(_e293)) {
        return vec3<f32>(0f, 0f, 0f);
    }
    let _e297 = unnamed.sunPower;
    let _e299 = unnamed.sunColor;
    return (_e299 * _e297);
}

fn normalToTangent_u0028_vf3_u003b(N_20: ptr<function, vec3<f32>>) -> vec3<f32> {
    var T: vec3<f32>;
    var param_770: vec3<f32>;

    let _e287 = (*N_20)[2u];
    let _e290 = (*N_20)[0u];
    if (abs(_e287) < abs(_e290)) {
        let _e294 = (*N_20)[2u];
        let _e296 = (*N_20)[0u];
        T = vec3<f32>(_e294, 0f, -(_e296));
    } else {
        let _e300 = (*N_20)[2u];
        let _e302 = (*N_20)[1u];
        T = vec3<f32>(0f, _e300, -(_e302));
    }
    let _e305 = T;
    param_770 = _e305;
    let _e306 = safe_normalize_u0028_vf3_u003b((&param_770));
    T = _e306;
    let _e307 = T;
    return _e307;
}

fn nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture: texture_2d<f32>, sampler_: sampler, index: ptr<function, i32>) -> vec4<f32> {
    var width: i32;

    let _e287 = textureDimensions(texture, 0i);
    width = vec2<i32>(_e287).x;
    let _e290 = (*index);
    let _e291 = width;
    let _e299 = (*index);
    let _e300 = width;
    let _e303 = textureLoad(texture, vec2<i32>((_e290 - (i32(floor((f32(_e290) / f32(_e291)))) * _e291)), (_e299 / _e300)), 0i);
    return _e303;
}

fn textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(texture_1: texture_2d<f32>, sampler_1: sampler, barycoord: ptr<function, vec3<f32>>, faceIndices: ptr<function, vec3<u32>>) -> vec4<f32> {
    var param_771: i32;
    var param_772: i32;
    var param_773: i32;

    let _e291 = (*barycoord)[0u];
    let _e293 = (*faceIndices)[0u];
    param_771 = bitcast<i32>(_e293);
    let _e295 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_771));
    let _e298 = (*barycoord)[1u];
    let _e300 = (*faceIndices)[1u];
    param_772 = bitcast<i32>(_e300);
    let _e302 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_772));
    let _e306 = (*barycoord)[2u];
    let _e308 = (*faceIndices)[2u];
    param_773 = bitcast<i32>(_e308);
    let _e310 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_773));
    return (((_e295 * _e291) + (_e302 * _e298)) + (_e310 * _e306));
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

    let _e295 = (*direction);
    inverseDirection = (vec3(1f) / _e295);
    let _e298 = (*minimum);
    let _e299 = (*origin);
    let _e301 = inverseDirection;
    t0_2 = ((_e298 - _e299) * _e301);
    let _e303 = (*maximum);
    let _e304 = (*origin);
    let _e306 = inverseDirection;
    t1_2 = ((_e303 - _e304) * _e306);
    let _e308 = t0_2;
    let _e309 = t1_2;
    entry = min(_e308, _e309);
    let _e311 = t0_2;
    let _e312 = t1_2;
    exit = max(_e311, _e312);
    let _e315 = entry[0u];
    let _e317 = entry[1u];
    let _e319 = entry[2u];
    nearDistance = max(_e315, max(_e317, _e319));
    let _e323 = exit[0u];
    let _e325 = exit[1u];
    let _e327 = exit[2u];
    farDistance = min(_e323, min(_e325, _e327));
    let _e330 = farDistance;
    let _e331 = nearDistance;
    if (_e330 >= max(_e331, 0f)) {
        let _e334 = nearDistance;
        local_11 = max(_e334, 0f);
    } else {
        local_11 = 100000000000000000000f;
    }
    let _e336 = local_11;
    return _e336;
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
    var phi_1146_: bool;

    pointer = 0i;
    stack[0i] = 0i;
    let _e336 = (*maxDistance);
    closest = _e336;
    found = false;
    loop {
        let _e337 = pointer;
        let _e339 = pointer;
        if ((_e337 >= 0i) && (_e339 < 64i)) {
            let _e342 = pointer;
            pointer = (_e342 - 1i);
            let _e345 = stack[_e342];
            nodeIndex = _e345;
            let _e346 = nodeIndex;
            param_774 = (_e346 * 3i);
            let _e348 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_774));
            minimum_1 = _e348;
            let _e349 = nodeIndex;
            param_775 = ((_e349 * 3i) + 1i);
            let _e352 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_775));
            maximum_1 = _e352;
            let _e353 = nodeIndex;
            param_776 = ((_e353 * 3i) + 2i);
            let _e356 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_776));
            metadata = _e356;
            let _e357 = minimum_1;
            param_777 = _e357.xyz;
            let _e359 = maximum_1;
            param_778 = _e359.xyz;
            let _e361 = (*rayOrigin);
            param_779 = _e361;
            let _e362 = (*rayDirection);
            param_780 = _e362;
            let _e363 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_777), (&param_778), (&param_779), (&param_780));
            let _e364 = closest;
            if (_e363 > _e364) {
                continue;
            }
            let _e367 = metadata[2u];
            if (_e367 > 0.5f) {
                let _e370 = metadata[0u];
                offset = i32((_e370 + 0.5f));
                let _e374 = metadata[1u];
                count = i32((_e374 + 0.5f));
                triangle = 0i;
                loop {
                    let _e377 = triangle;
                    let _e378 = count;
                    if (_e377 < _e378) {
                        let _e380 = offset;
                        let _e381 = triangle;
                        param_781 = (_e380 + _e381);
                        let _e383 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_781));
                        vertexIndices = vec3<u32>((_e383.xyz + vec3(0.5f)));
                        let _e389 = vertexIndices[0u];
                        param_782 = bitcast<i32>(_e389);
                        let _e391 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_782));
                        p0_ = _e391.xyz;
                        let _e394 = vertexIndices[1u];
                        param_783 = bitcast<i32>(_e394);
                        let _e396 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_783));
                        p1_ = _e396.xyz;
                        let _e399 = vertexIndices[2u];
                        param_784 = bitcast<i32>(_e399);
                        let _e401 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_784));
                        p2_ = _e401.xyz;
                        let _e403 = p1_;
                        let _e404 = p0_;
                        edge0_ = (_e403 - _e404);
                        let _e406 = p2_;
                        let _e407 = p0_;
                        edge1_ = (_e406 - _e407);
                        let _e409 = (*rayDirection);
                        let _e410 = edge1_;
                        pvec = cross(_e409, _e410);
                        let _e412 = edge0_;
                        let _e413 = pvec;
                        determinant_ = dot(_e412, _e413);
                        let _e415 = determinant_;
                        if (abs(_e415) < 0.00000001f) {
                            continue;
                        }
                        let _e418 = determinant_;
                        inverseDeterminant = (1f / _e418);
                        let _e420 = (*rayOrigin);
                        let _e421 = p0_;
                        tvec = (_e420 - _e421);
                        let _e423 = tvec;
                        let _e424 = pvec;
                        let _e426 = inverseDeterminant;
                        u = (dot(_e423, _e424) * _e426);
                        let _e428 = tvec;
                        let _e429 = edge0_;
                        qvec = cross(_e428, _e429);
                        let _e431 = (*rayDirection);
                        let _e432 = qvec;
                        let _e434 = inverseDeterminant;
                        v_2 = (dot(_e431, _e432) * _e434);
                        let _e436 = edge1_;
                        let _e437 = qvec;
                        let _e439 = inverseDeterminant;
                        distance_ = (dot(_e436, _e437) * _e439);
                        let _e441 = u;
                        let _e443 = v_2;
                        let _e445 = ((_e441 >= 0f) && (_e443 >= 0f));
                        phi_1146_ = _e445;
                        if _e445 {
                            let _e446 = u;
                            let _e447 = v_2;
                            phi_1146_ = ((_e446 + _e447) <= 1f);
                        }
                        let _e451 = phi_1146_;
                        let _e452 = distance_;
                        let _e455 = distance_;
                        let _e456 = closest;
                        if ((_e451 && (_e452 > 0f)) && (_e455 < _e456)) {
                            let _e459 = distance_;
                            closest = _e459;
                            let _e460 = distance_;
                            (*dist_2) = _e460;
                            let _e461 = u;
                            let _e463 = v_2;
                            let _e465 = u;
                            let _e466 = v_2;
                            (*barycoord_1) = vec3<f32>(((1f - _e461) - _e463), _e465, _e466);
                            let _e468 = vertexIndices;
                            (*faceIndices_1) = vec4<u32>(_e468.x, _e468.y, _e468.z, 0u);
                            let _e473 = edge0_;
                            let _e474 = edge1_;
                            (*faceNormal) = normalize(cross(_e473, _e474));
                            let _e477 = determinant_;
                            (*side) = select(1f, -1f, (_e477 < 0f));
                            found = true;
                        }
                        continue;
                    } else {
                        break;
                    }
                    continuing {
                        let _e480 = triangle;
                        triangle = (_e480 + 1i);
                    }
                }
            } else {
                let _e483 = metadata[0u];
                left = i32((_e483 + 0.5f));
                let _e487 = metadata[1u];
                right = i32((_e487 + 0.5f));
                let _e490 = pointer;
                if ((_e490 + 2i) >= 64i) {
                    continue;
                }
                let _e493 = pointer;
                let _e494 = (_e493 + 1i);
                pointer = _e494;
                let _e495 = right;
                stack[_e494] = _e495;
                let _e497 = pointer;
                let _e498 = (_e497 + 1i);
                pointer = _e498;
                let _e499 = left;
                stack[_e498] = _e499;
            }
            continue;
        } else {
            break;
        }
    }
    let _e501 = found;
    return _e501;
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

    let _e305 = (*rayOrigin_1);
    param_785 = _e305;
    let _e306 = (*rayDirection_1);
    param_786 = _e306;
    let _e307 = (*maxDistance_1);
    param_787 = _e307;
    let _e308 = (*faceIndices_2);
    param_788 = _e308;
    let _e309 = (*faceNormal_1);
    param_789 = _e309;
    let _e310 = (*barycoord_2);
    param_790 = _e310;
    let _e311 = (*side_1);
    param_791 = _e311;
    let _e312 = (*dist_3);
    param_792 = _e312;
    let _e313 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_785), (&param_786), (&param_787), (&param_788), (&param_789), (&param_790), (&param_791), (&param_792));
    let _e314 = param_788;
    (*faceIndices_2) = _e314;
    let _e315 = param_789;
    (*faceNormal_1) = _e315;
    let _e316 = param_790;
    (*barycoord_2) = _e316;
    let _e317 = param_791;
    (*side_1) = _e317;
    let _e318 = param_792;
    (*dist_3) = _e318;
    return _e313;
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
    var phi_1397_: bool;
    var phi_1419_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e329 = (*rayOrigin_2);
    param_793 = _e329;
    let _e330 = (*rayDir);
    param_794 = _e330;
    let _e331 = (*maxDistance_2);
    param_795 = _e331;
    let _e332 = faceIndices_surface;
    param_796 = _e332;
    let _e333 = faceNormal_surface;
    param_797 = _e333;
    let _e334 = barycoord_surface;
    param_798 = _e334;
    let _e335 = side_surface;
    param_799 = _e335;
    let _e336 = dist_surface;
    param_800 = _e336;
    let _e337 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_793), (&param_794), (&param_795), (&param_796), (&param_797), (&param_798), (&param_799), (&param_800));
    let _e338 = param_796;
    faceIndices_surface = _e338;
    let _e339 = param_797;
    faceNormal_surface = _e339;
    let _e340 = param_798;
    barycoord_surface = _e340;
    let _e341 = param_799;
    side_surface = _e341;
    let _e342 = param_800;
    dist_surface = _e342;
    hit_surface = _e337;
    dist_closest = 100000000000000000000f;
    let _e343 = hit_surface;
    if _e343 {
        let _e344 = dist_closest;
        let _e345 = dist_surface;
        dist_closest = min(_e344, _e345);
    }
    dist_ground = 100000000000000000000f;
    hit_ground = false;
    let _e348 = (*rayDir)[1u];
    if (abs(_e348) > 0.0000000001f) {
        let _e352 = (*rayOrigin_2)[1u];
        let _e355 = (*rayDir)[1u];
        t = ((0.01f - _e352) / _e355);
        let _e357 = t;
        let _e358 = (_e357 > 0f);
        phi_1397_ = _e358;
        if _e358 {
            let _e359 = t;
            let _e360 = dist_closest;
            let _e361 = (*maxDistance_2);
            phi_1397_ = (_e359 < min(_e360, _e361));
        }
        let _e365 = phi_1397_;
        if _e365 {
            let _e366 = t;
            dist_ground = _e366;
            hit_ground = true;
        }
    }
    let _e367 = hit_surface;
    let _e368 = hit_ground;
    hit = (_e367 || _e368);
    let _e370 = hit;
    if !(_e370) {
        return false;
    }
    let _e372 = hit_surface;
    phi_1419_ = _e372;
    if _e372 {
        let _e373 = hit_ground;
        let _e375 = dist_surface;
        let _e376 = dist_ground;
        phi_1419_ = (!(_e373) || (_e375 <= _e376));
    }
    let _e380 = phi_1419_;
    if _e380 {
        let _e381 = (*rayOrigin_2);
        let _e382 = dist_surface;
        let _e383 = (*rayDir);
        (*P_4) = (_e381 + (_e383 * _e382));
        let _e386 = barycoord_surface;
        (*baryCoord_1) = _e386;
        let _e387 = faceNormal_surface;
        param_801 = _e387;
        let _e388 = safe_normalize_u0028_vf3_u003b((&param_801));
        (*Ng) = _e388;
        let _e389 = barycoord_surface;
        param_802 = _e389;
        let _e390 = faceIndices_surface;
        param_803 = _e390.xyz;
        let _e392 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_802), (&param_803));
        gN = _e392;
        let _e393 = barycoord_surface;
        param_804 = _e393;
        let _e394 = faceIndices_surface;
        param_805 = _e394.xyz;
        let _e396 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_804), (&param_805));
        gT = _e396;
        let _e397 = barycoord_surface;
        param_806 = _e397;
        let _e398 = faceIndices_surface;
        param_807 = _e398.xyz;
        let _e400 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_806), (&param_807));
        gS = _e400;
        let _e402 = unnamed.has_normals_surface;
        if (_e402 != 0u) {
            let _e404 = gN;
            local_12 = _e404.xyz;
        } else {
            let _e406 = (*Ng);
            local_12 = _e406;
        }
        let _e407 = local_12;
        (*Ns) = _e407;
        let _e409 = unnamed.has_uvs_surface;
        if (_e409 != 0u) {
            let _e412 = gN[3u];
            let _e414 = gT[3u];
            local_13 = vec2<f32>(_e412, _e414);
        } else {
            let _e416 = barycoord_surface;
            local_13 = _e416.xy;
        }
        let _e418 = local_13;
        (*texCoord_1) = _e418;
        let _e420 = unnamed.has_tangents_surface;
        if (_e420 != 0u) {
            let _e422 = gT;
            local_14 = _e422.xyz;
        } else {
            let _e424 = (*Ns);
            param_808 = _e424;
            let _e425 = normalToTangent_u0028_vf3_u003b((&param_808));
            local_14 = _e425;
        }
        let _e426 = local_14;
        (*Ts) = _e426;
        let _e427 = (*Ns);
        param_809 = _e427;
        let _e428 = safe_normalize_u0028_vf3_u003b((&param_809));
        let _e429 = (*Ts);
        param_810 = _e429;
        let _e430 = safe_normalize_u0028_vf3_u003b((&param_810));
        (*Bs) = cross(_e428, _e430);
        let _e433 = gS[0u];
        (*material) = select(1i, 0i, (_e433 > 0.5f));
    } else {
        let _e436 = hit_ground;
        if _e436 {
            let _e437 = (*rayOrigin_2);
            let _e438 = dist_ground;
            let _e439 = (*rayDir);
            (*P_4) = (_e437 + (_e439 * _e438));
            (*material) = 2i;
            (*baryCoord_1) = vec3<f32>(0f, 0f, 0f);
            (*Ng) = vec3<f32>(0f, 1f, 0f);
            let _e442 = (*Ng);
            (*Ns) = _e442;
            (*Ts) = vec3<f32>(1f, 0f, 0f);
            (*Bs) = vec3<f32>(0f, 0f, -1f);
            let _e444 = (*P_4)[0u];
            let _e446 = (*P_4)[2u];
            (*texCoord_1) = (((vec2<f32>(_e444, -(_e446)) / vec2(200f)) * 2f) + vec2(0.5f));
        }
    }
    return true;
}

fn makeBasis_u0028_vf3_u003b(nW_1: ptr<function, vec3<f32>>) -> Basis {
    var basis_4: Basis;
    var param_811: vec3<f32>;
    var param_812: vec3<f32>;

    let _e287 = (*nW_1);
    param_811 = _e287;
    let _e288 = safe_normalize_u0028_vf3_u003b((&param_811));
    basis_4.nW = _e288;
    let _e290 = (*nW_1);
    param_812 = _e290;
    let _e291 = normalToTangent_u0028_vf3_u003b((&param_812));
    basis_4.tW = _e291;
    let _e294 = basis_4.nW;
    let _e296 = basis_4.tW;
    basis_4.bW = cross(_e294, _e296);
    basis_4.baryCoord = vec3<f32>(0f, 0f, 0f);
    basis_4.texCoord = vec2<f32>(0f, 0f);
    let _e301 = basis_4;
    return _e301;
}

fn ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b(coordinate: ptr<function, vec2<f32>>, cameraWorld: ptr<function, mat4x4<f32>>, inverseProjection: ptr<function, mat4x4<f32>>, rayOrigin_3: ptr<function, vec3<f32>>, rayDirection_2: ptr<function, vec3<f32>>) {
    var lookDirection: vec4<f32>;
    var nearVector: vec4<f32>;
    var nearDistance_1: f32;
    var origin_1: vec4<f32>;
    var direction_1: vec4<f32>;

    let _e293 = (*cameraWorld);
    lookDirection = (_e293 * vec4<f32>(0f, 0f, -1f, 0f));
    let _e295 = (*inverseProjection);
    nearVector = (_e295 * vec4<f32>(0f, 0f, -1f, 1f));
    let _e298 = nearVector[2u];
    let _e300 = nearVector[3u];
    nearDistance_1 = abs((_e298 / _e300));
    let _e303 = (*cameraWorld);
    origin_1 = (_e303 * vec4<f32>(0f, 0f, 0f, 1f));
    let _e305 = (*inverseProjection);
    let _e306 = (*coordinate);
    direction_1 = (_e305 * vec4<f32>(_e306.x, _e306.y, 0.5f, 1f));
    let _e312 = direction_1[3u];
    let _e313 = direction_1;
    direction_1 = (_e313 / vec4(_e312));
    let _e316 = (*cameraWorld);
    let _e317 = direction_1;
    let _e319 = origin_1;
    direction_1 = ((_e316 * _e317) - _e319);
    let _e321 = direction_1;
    let _e323 = nearDistance_1;
    let _e325 = direction_1;
    let _e326 = lookDirection;
    let _e330 = origin_1;
    let _e332 = (_e330.xyz + ((_e321.xyz * _e323) / vec3(dot(_e325, _e326))));
    origin_1[0u] = _e332.x;
    origin_1[1u] = _e332.y;
    origin_1[2u] = _e332.z;
    let _e339 = origin_1;
    (*rayOrigin_3) = _e339.xyz;
    let _e341 = direction_1;
    (*rayDirection_2) = _e341.xyz;
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
    base_color_1 = vec3<f32>(0.5f, 0.5f, 0.5f);
    diffuse_roughness_1 = 0f;
    metalness_1 = 1f;
    specular_1 = 0f;
    specular_color_1 = vec3<f32>(0f, 0f, 0f);
    specular_roughness_1 = 0.25f;
    specular_IOR_1 = 1.52f;
    specular_anisotropy_1 = 0.65f;
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
    let _e346 = gl_FragCoord_1;
    pixel = (_e346.xy + vec2<f32>(0.5f, 0.5f));
    let _e349 = pixel;
    let _e351 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e349 / _e351) * 2f));
    let _e357 = unnamed.invModelMatrix;
    let _e359 = unnamed.cameraWorldMatrix;
    let _e361 = ndc;
    param_813 = _e361;
    param_814 = (_e357 * _e359);
    let _e363 = unnamed.invProjectionMatrix;
    param_815 = _e363;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
    let _e364 = param_816;
    pW_3 = _e364;
    let _e365 = param_817;
    dW = _e365;
    let _e366 = dW;
    dW = normalize(_e366);
    let _e369 = unnamed.sunDir;
    param_818 = _e369;
    let _e370 = makeBasis_u0028_vf3_u003b((&param_818));
    sunBasis = _e370;
    let _e371 = pW_3;
    param_819 = _e371;
    let _e372 = dW;
    param_820 = _e372;
    param_821 = 100000000000000000000f;
    let _e373 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825), (&param_826), (&param_827), (&param_828), (&param_829));
    let _e374 = param_822;
    pW_hit = _e374;
    let _e375 = param_823;
    NsW = _e375;
    let _e376 = param_824;
    NgW = _e376;
    let _e377 = param_825;
    TsW = _e377;
    let _e378 = param_826;
    BsW = _e378;
    let _e379 = param_827;
    baryCoord_2 = _e379;
    let _e380 = param_828;
    texCoord_2 = _e380;
    let _e381 = param_829;
    material_1 = _e381;
    surface_hit = _e373;
    let _e382 = surface_hit;
    if !(_e382) {
        let _e384 = dW;
        param_830 = _e384;
        let _e385 = sunRadiance_u0028_vf3_u003b((&param_830));
        let _e386 = dW;
        param_831 = _e386;
        let _e387 = skyRadiance_u0028_vf3_u003b((&param_831));
        let _e388 = (_e385 + _e387);
        mtlxFragmentColor[0u] = _e388.x;
        mtlxFragmentColor[1u] = _e388.y;
        mtlxFragmentColor[2u] = _e388.z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    let _e396 = NsW;
    let _e397 = dW;
    if (dot(_e396, _e397) > 0f) {
        let _e400 = NsW;
        NsW = (_e400 * -1f);
    }
    let _e402 = NgW;
    let _e403 = NsW;
    if (dot(_e402, _e403) < 0f) {
        let _e406 = NgW;
        NgW = (_e406 * -1f);
    }
    let _e409 = unnamed.smooth_normals;
    if (_e409 != 0u) {
        let _e411 = NsW;
        param_832 = _e411;
        let _e412 = TsW;
        param_833 = _e412;
        let _e413 = BsW;
        param_834 = _e413;
        let _e414 = baryCoord_2;
        param_835 = _e414;
        let _e415 = texCoord_2;
        param_836 = _e415;
        let _e416 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_832), (&param_833), (&param_834), (&param_835), (&param_836));
        basis_5 = _e416;
    } else {
        let _e417 = NgW;
        param_837 = _e417;
        let _e418 = TsW;
        param_838 = _e418;
        let _e419 = BsW;
        param_839 = _e419;
        let _e420 = baryCoord_2;
        param_840 = _e420;
        let _e421 = texCoord_2;
        param_841 = _e421;
        let _e422 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_837), (&param_838), (&param_839), (&param_840), (&param_841));
        basis_5 = _e422;
    }
    let _e423 = dW;
    winputW = -(_e423);
    let _e425 = winputW;
    param_842 = _e425;
    let _e426 = basis_5;
    param_843 = _e426;
    let _e427 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_842), (&param_843));
    winputL_2 = _e427;
    let _e429 = winputL_2[2u];
    if (abs(_e429) < 0.001f) {
        mtlxFragmentColor[0u] = vec3<f32>(0f, 0f, 0f).x;
        mtlxFragmentColor[1u] = vec3<f32>(0f, 0f, 0f).y;
        mtlxFragmentColor[2u] = vec3<f32>(0f, 0f, 0f).z;
        mtlxFragmentColor[3u] = 1f;
        return;
    }
    rndSeed_1 = 0u;
    let _e439 = material_1;
    if (_e439 == 1i) {
        let _e441 = pW_hit;
        param_844 = _e441;
        let _e442 = basis_5;
        param_845 = _e442;
        let _e443 = winputL_2;
        param_846 = _e443;
        let _e444 = rndSeed_1;
        param_847 = _e444;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_844), (&param_845), (&param_846), (&param_847));
        let _e445 = param_847;
        rndSeed_1 = _e445;
    }
    let _e446 = dW;
    let _e448 = basis_5.nW;
    viewReflectW = reflect(_e446, _e448);
    let _e450 = viewReflectW;
    param_848 = _e450;
    let _e451 = basis_5;
    param_849 = _e451;
    let _e452 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_848), (&param_849));
    viewReflectL = _e452;
    let _e454 = viewReflectL[2u];
    if (_e454 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e456 = material_1;
    if (_e456 == 1i) {
        let _e458 = pW_hit;
        param_850 = _e458;
        let _e459 = basis_5;
        param_851 = _e459;
        let _e460 = winputL_2;
        param_852 = _e460;
        let _e461 = viewReflectL;
        param_853 = _e461;
        let _e462 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_850), (&param_851), (&param_852), (&param_853));
        L_12 = _e462;
    } else {
        let _e463 = material_1;
        if (_e463 == 2i) {
            let _e465 = pW_hit;
            param_854 = _e465;
            let _e466 = ground_albedo_u0028_vf3_u003b((&param_854));
            L_12 = _e466;
        } else {
            let _e468 = unnamed.neutral_color;
            let _e470 = basis_5.nW;
            param_855 = _e470;
            let _e471 = skyRadiance_u0028_vf3_u003b((&param_855));
            L_12 = (_e468 * _e471);
        }
    }
    let _e473 = L_12;
    let _e475 = unnamed.firefly_clamp;
    let _e477 = clamp(_e473, vec3<f32>(0f, 0f, 0f), vec3(_e475));
    mtlxFragmentColor[0u] = _e477.x;
    mtlxFragmentColor[1u] = _e477.y;
    mtlxFragmentColor[2u] = _e477.z;
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
