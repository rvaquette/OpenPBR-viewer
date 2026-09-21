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

struct VDF {
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
var<private> mtlxRasterOut_6: vec4<f32>;
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

fn mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_4: ptr<function, ClosureData>, top: ptr<function, BSDF>, base_1: ptr<function, BSDF>, result_4: ptr<function, BSDF>) {
    let _e287 = (*top).response;
    let _e289 = (*base_1).response;
    let _e291 = (*top).throughput;
    (*result_4).response = (_e287 + (_e289 * _e291));
    let _e296 = (*top).throughput;
    let _e298 = (*base_1).throughput;
    (*result_4).throughput = (_e296 * _e298);
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

fn mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b(N_3: ptr<function, vec3<f32>>, L: ptr<function, vec3<f32>>, radius: ptr<function, f32>, mfp: ptr<function, vec3<f32>>) -> vec3<f32> {
    var theta: f32;
    var shape_1: vec3<f32>;
    var sumD: vec3<f32>;
    var sumR: vec3<f32>;
    var i: i32;
    var x_1: f32;
    var dist_1: f32;
    var R: vec3<f32>;
    var param_12: f32;
    var param_13: vec3<f32>;

    let _e296 = (*N_3);
    let _e297 = (*L);
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
            x_1 = (-3.1415927f + ((f32(_e306) + 0.5f) * 0.19634955f));
            let _e311 = (*radius);
            let _e312 = x_1;
            dist_1 = (_e311 * abs((2f * sin((_e312 * 0.5f)))));
            let _e318 = dist_1;
            param_12 = _e318;
            let _e319 = shape_1;
            param_13 = _e319;
            let _e320 = mx_burley_diffusion_profile_u0028_f1_u003b_vf3_u003b((&param_12), (&param_13));
            R = _e320;
            let _e321 = R;
            let _e322 = theta;
            let _e323 = x_1;
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

fn mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(N_4: ptr<function, vec3<f32>>, L_1: ptr<function, vec3<f32>>, P: ptr<function, vec3<f32>>, albedo: ptr<function, vec3<f32>>, mfp_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var curvature: f32;
    var radius_1: f32;
    var param_14: vec3<f32>;
    var param_15: vec3<f32>;
    var param_16: f32;
    var param_17: vec3<f32>;

    let _e293 = (*N_4);
    let _e294 = fwidth(_e293);
    let _e296 = (*P);
    let _e297 = fwidth(_e296);
    curvature = (length(_e294) / length(_e297));
    let _e300 = curvature;
    radius_1 = (1f / max(_e300, 0.01f));
    let _e303 = (*albedo);
    let _e304 = (*N_4);
    param_14 = _e304;
    let _e305 = (*L_1);
    param_15 = _e305;
    let _e306 = radius_1;
    param_16 = _e306;
    let _e307 = (*mfp_1);
    param_17 = _e307;
    let _e308 = mx_integrate_burley_diffusion_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_14), (&param_15), (&param_16), (&param_17));
    return ((_e303 * _e308) / vec3<f32>(3.1415927f, 3.1415927f, 3.1415927f));
}

fn mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_5: ptr<function, ClosureData>, weight: ptr<function, f32>, color_1: ptr<function, vec3<f32>>, radius_2: ptr<function, vec3<f32>>, anisotropy: ptr<function, f32>, N_5: ptr<function, vec3<f32>>, bsdf: ptr<function, BSDF>) {
    var V_1: vec3<f32>;
    var L_2: vec3<f32>;
    var P_1: vec3<f32>;
    var occlusion: f32;
    var param_18: vec3<f32>;
    var param_19: vec3<f32>;
    var sss: vec3<f32>;
    var param_20: vec3<f32>;
    var param_21: vec3<f32>;
    var param_22: vec3<f32>;
    var param_23: vec3<f32>;
    var param_24: vec3<f32>;
    var NdotL: f32;
    var visibleOcclusion: f32;
    var Li_1: vec3<f32>;
    var param_25: vec3<f32>;

    (*bsdf).throughput = vec3<f32>(0f, 0f, 0f);
    let _e306 = (*weight);
    if (_e306 < 0.00000001f) {
        return;
    }
    let _e309 = (*closureData_5).V;
    V_1 = _e309;
    let _e311 = (*closureData_5).L;
    L_2 = _e311;
    let _e313 = (*closureData_5).P;
    P_1 = _e313;
    let _e315 = (*closureData_5).occlusion;
    occlusion = _e315;
    let _e316 = (*N_5);
    param_18 = _e316;
    let _e317 = V_1;
    param_19 = _e317;
    let _e318 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_18), (&param_19));
    (*N_5) = _e318;
    let _e320 = (*closureData_5).closureType;
    if (_e320 == 1i) {
        let _e322 = (*N_5);
        param_20 = _e322;
        let _e323 = L_2;
        param_21 = _e323;
        let _e324 = P_1;
        param_22 = _e324;
        let _e325 = (*color_1);
        param_23 = _e325;
        let _e326 = (*radius_2);
        param_24 = _e326;
        let _e327 = mx_subsurface_scattering_approx_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_20), (&param_21), (&param_22), (&param_23), (&param_24));
        sss = _e327;
        let _e328 = (*N_5);
        let _e329 = L_2;
        NdotL = clamp(dot(_e328, _e329), 0.00000001f, 1f);
        let _e332 = NdotL;
        let _e333 = occlusion;
        visibleOcclusion = (1f - (_e332 * (1f - _e333)));
        let _e337 = sss;
        let _e338 = visibleOcclusion;
        let _e340 = (*weight);
        (*bsdf).response = ((_e337 * _e338) * _e340);
    } else {
        let _e344 = (*closureData_5).closureType;
        if (_e344 == 3i) {
            let _e346 = (*N_5);
            param_25 = _e346;
            let _e347 = mx_environment_irradiance_u0028_vf3_u003b((&param_25));
            Li_1 = _e347;
            let _e348 = Li_1;
            let _e349 = (*color_1);
            let _e351 = (*weight);
            (*bsdf).response = ((_e348 * _e349) * _e351);
        }
    }
    return;
}

fn mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_6: ptr<function, ClosureData>, fg_1: ptr<function, BSDF>, bg_1: ptr<function, BSDF>, mixValue_1: ptr<function, f32>, result_5: ptr<function, BSDF>) {
    let _e288 = (*bg_1).response;
    let _e290 = (*fg_1).response;
    let _e291 = (*mixValue_1);
    (*result_5).response = mix(_e288, _e290, vec3(_e291));
    let _e296 = (*bg_1).throughput;
    let _e298 = (*fg_1).throughput;
    let _e299 = (*mixValue_1);
    (*result_5).throughput = mix(_e296, _e298, vec3(_e299));
    return;
}

fn mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_7: ptr<function, ClosureData>, weight_1: ptr<function, f32>, color_2: ptr<function, vec3<f32>>, N_6: ptr<function, vec3<f32>>, bsdf_1: ptr<function, BSDF>) {
    var V_2: vec3<f32>;
    var L_3: vec3<f32>;
    var NdotL_1: f32;
    var Li_2: vec3<f32>;
    var param_26: vec3<f32>;

    (*bsdf_1).throughput = vec3<f32>(0f, 0f, 0f);
    let _e293 = (*weight_1);
    if (_e293 < 0.00000001f) {
        return;
    }
    let _e296 = (*closureData_7).V;
    V_2 = _e296;
    let _e298 = (*closureData_7).L;
    L_3 = _e298;
    let _e299 = (*N_6);
    (*N_6) = -(_e299);
    let _e302 = (*closureData_7).closureType;
    if (_e302 == 1i) {
        let _e304 = (*N_6);
        let _e305 = L_3;
        NdotL_1 = clamp(dot(_e304, _e305), 0f, 1f);
        let _e308 = (*color_2);
        let _e309 = (*weight_1);
        let _e311 = NdotL_1;
        (*bsdf_1).response = (((_e308 * _e309) * _e311) * 0.31830987f);
    } else {
        let _e316 = (*closureData_7).closureType;
        if (_e316 == 3i) {
            let _e318 = (*N_6);
            param_26 = _e318;
            let _e319 = mx_environment_irradiance_u0028_vf3_u003b((&param_26));
            Li_2 = _e319;
            let _e320 = Li_2;
            let _e321 = (*color_2);
            let _e323 = (*weight_1);
            (*bsdf_1).response = ((_e320 * _e321) * _e323);
        }
    }
    return;
}

fn mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_8: ptr<function, ClosureData>, in1_1: ptr<function, BSDF>, in2_1: ptr<function, vec3<f32>>, result_6: ptr<function, BSDF>) {
    var tint: vec3<f32>;

    let _e287 = (*in2_1);
    tint = clamp(_e287, vec3(0f), vec3(1f));
    let _e292 = (*in1_1).response;
    let _e293 = tint;
    (*result_6).response = (_e292 * _e293);
    let _e297 = (*in1_1).throughput;
    (*result_6).throughput = _e297;
    return;
}

fn mx_square_u0028_f1_u003b(x_2: ptr<function, f32>) -> f32 {
    let _e283 = (*x_2);
    let _e284 = (*x_2);
    return (_e283 * _e284);
}

fn mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_1: ptr<function, f32>, roughness: ptr<function, f32>) -> f32 {
    var r: vec2<f32>;
    var param_27: f32;

    let _e286 = (*roughness);
    let _e289 = (*NdotV_1);
    let _e291 = (*roughness);
    let _e294 = (*roughness);
    param_27 = _e294;
    let _e295 = mx_square_u0028_f1_u003b((&param_27));
    r = (((vec2<f32>(1f, 1f) + (vec2<f32>(-0.4297f, -0.6076f) * _e286)) + ((vec2<f32>(-0.7632f, -0.4993f) * _e289) * _e291)) + (vec2<f32>(1.4385f, 2.0315f) * _e295));
    let _e299 = r[0u];
    let _e301 = r[1u];
    return (_e299 / _e301);
}

fn mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_2: ptr<function, f32>, roughness_1: ptr<function, f32>) -> f32 {
    var dirAlbedo: f32;
    var param_28: f32;
    var param_29: f32;

    let _e287 = (*NdotV_2);
    param_28 = _e287;
    let _e288 = (*roughness_1);
    param_29 = _e288;
    let _e289 = mx_oren_nayar_diffuse_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_28), (&param_29));
    dirAlbedo = _e289;
    let _e290 = dirAlbedo;
    return clamp(_e290, 0f, 1f);
}

fn mx_square_u0028_vf3_u003b(x_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e283 = (*x_3);
    let _e284 = (*x_3);
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
    var param_30: f32;
    var G: f32;

    let _e289 = (*roughness_3);
    A_1 = (1f / (1f + (0.2877934f * _e289)));
    let _e293 = (*roughness_3);
    let _e294 = A_1;
    B = (_e293 * _e294);
    let _e296 = (*cosTheta_1);
    param_30 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_30));
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

fn mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b(cosTheta_2: ptr<function, f32>, roughness_4: ptr<function, f32>, color_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var dirAlbedo_1: f32;
    var param_31: f32;
    var param_32: f32;
    var avgAlbedo: f32;
    var param_33: f32;
    var colorMultiScatter: vec3<f32>;
    var param_34: vec3<f32>;

    let _e292 = (*cosTheta_2);
    param_31 = _e292;
    let _e293 = (*roughness_4);
    param_32 = _e293;
    let _e294 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_31), (&param_32));
    dirAlbedo_1 = _e294;
    let _e295 = (*roughness_4);
    param_33 = _e295;
    let _e296 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_33));
    avgAlbedo = _e296;
    let _e297 = (*color_3);
    param_34 = _e297;
    let _e298 = mx_square_u0028_vf3_u003b((&param_34));
    let _e299 = avgAlbedo;
    let _e301 = (*color_3);
    let _e302 = avgAlbedo;
    colorMultiScatter = ((_e298 * _e299) / (vec3<f32>(1f, 1f, 1f) - (_e301 * max(0f, (1f - _e302)))));
    let _e308 = colorMultiScatter;
    let _e309 = (*color_3);
    let _e310 = dirAlbedo_1;
    return mix(_e308, _e309, vec3(_e310));
}

fn mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_3: ptr<function, f32>, NdotL_2: ptr<function, f32>, LdotV: ptr<function, f32>, roughness_5: ptr<function, f32>) -> f32 {
    var s_1: f32;
    var stinv: f32;
    var local_1: f32;
    var sigma2_: f32;
    var param_35: f32;
    var A_2: f32;
    var B_1: f32;

    let _e293 = (*LdotV);
    let _e294 = (*NdotL_2);
    let _e295 = (*NdotV_3);
    s_1 = (_e293 - (_e294 * _e295));
    let _e298 = s_1;
    if (_e298 > 0f) {
        let _e300 = s_1;
        let _e301 = (*NdotL_2);
        let _e302 = (*NdotV_3);
        local_1 = (_e300 / max(_e301, _e302));
    } else {
        local_1 = 0f;
    }
    let _e305 = local_1;
    stinv = _e305;
    let _e306 = (*roughness_5);
    param_35 = _e306;
    let _e307 = mx_square_u0028_f1_u003b((&param_35));
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

fn mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b(NdotV_4: ptr<function, f32>, NdotL_3: ptr<function, f32>, LdotV_1: ptr<function, f32>, roughness_6: ptr<function, f32>, color_4: ptr<function, vec3<f32>>) -> vec3<f32> {
    var s_2: f32;
    var stinv_1: f32;
    var local_2: f32;
    var A_3: f32;
    var lobeSingleScatter: vec3<f32>;
    var dirAlbedoV: f32;
    var param_36: f32;
    var param_37: f32;
    var dirAlbedoL: f32;
    var param_38: f32;
    var param_39: f32;
    var avgAlbedo_1: f32;
    var param_40: f32;
    var colorMultiScatter_1: vec3<f32>;
    var param_41: vec3<f32>;
    var lobeMultiScatter: vec3<f32>;

    let _e303 = (*LdotV_1);
    let _e304 = (*NdotL_3);
    let _e305 = (*NdotV_4);
    s_2 = (_e303 - (_e304 * _e305));
    let _e308 = s_2;
    if (_e308 > 0f) {
        let _e310 = s_2;
        let _e311 = (*NdotL_3);
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
    let _e321 = (*color_4);
    let _e322 = A_3;
    let _e324 = (*roughness_6);
    let _e325 = stinv_1;
    lobeSingleScatter = ((_e321 * _e322) * (1f + (_e324 * _e325)));
    let _e329 = (*NdotV_4);
    param_36 = _e329;
    let _e330 = (*roughness_6);
    param_37 = _e330;
    let _e331 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_36), (&param_37));
    dirAlbedoV = _e331;
    let _e332 = (*NdotL_3);
    param_38 = _e332;
    let _e333 = (*roughness_6);
    param_39 = _e333;
    let _e334 = mx_oren_nayar_fujii_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_38), (&param_39));
    dirAlbedoL = _e334;
    let _e335 = (*roughness_6);
    param_40 = _e335;
    let _e336 = mx_oren_nayar_fujii_diffuse_avg_albedo_u0028_f1_u003b((&param_40));
    avgAlbedo_1 = _e336;
    let _e337 = (*color_4);
    param_41 = _e337;
    let _e338 = mx_square_u0028_vf3_u003b((&param_41));
    let _e339 = avgAlbedo_1;
    let _e341 = (*color_4);
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

fn mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_9: ptr<function, ClosureData>, weight_2: ptr<function, f32>, color_5: ptr<function, vec3<f32>>, roughness_7: ptr<function, f32>, N_7: ptr<function, vec3<f32>>, energy_compensation: ptr<function, bool>, bsdf_2: ptr<function, BSDF>) {
    var V_3: vec3<f32>;
    var L_4: vec3<f32>;
    var param_42: vec3<f32>;
    var param_43: vec3<f32>;
    var NdotV_5: f32;
    var NdotL_4: f32;
    var LdotV_2: f32;
    var diffuse: vec3<f32>;
    var local_3: vec3<f32>;
    var param_44: f32;
    var param_45: f32;
    var param_46: f32;
    var param_47: f32;
    var param_48: vec3<f32>;
    var param_49: f32;
    var param_50: f32;
    var param_51: f32;
    var param_52: f32;
    var diffuse_1: vec3<f32>;
    var local_4: vec3<f32>;
    var param_53: f32;
    var param_54: f32;
    var param_55: vec3<f32>;
    var param_56: f32;
    var param_57: f32;
    var Li_3: vec3<f32>;
    var param_58: vec3<f32>;

    (*bsdf_2).throughput = vec3<f32>(0f, 0f, 0f);
    let _e317 = (*weight_2);
    if (_e317 < 0.00000001f) {
        return;
    }
    let _e320 = (*closureData_9).V;
    V_3 = _e320;
    let _e322 = (*closureData_9).L;
    L_4 = _e322;
    let _e323 = (*N_7);
    param_42 = _e323;
    let _e324 = V_3;
    param_43 = _e324;
    let _e325 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_42), (&param_43));
    (*N_7) = _e325;
    let _e326 = (*N_7);
    let _e327 = V_3;
    NdotV_5 = clamp(dot(_e326, _e327), 0.00000001f, 1f);
    let _e331 = (*closureData_9).closureType;
    if (_e331 == 1i) {
        let _e333 = (*N_7);
        let _e334 = L_4;
        NdotL_4 = clamp(dot(_e333, _e334), 0.00000001f, 1f);
        let _e337 = L_4;
        let _e338 = V_3;
        LdotV_2 = clamp(dot(_e337, _e338), 0.00000001f, 1f);
        let _e341 = (*energy_compensation);
        if _e341 {
            let _e342 = NdotV_5;
            param_44 = _e342;
            let _e343 = NdotL_4;
            param_45 = _e343;
            let _e344 = LdotV_2;
            param_46 = _e344;
            let _e345 = (*roughness_7);
            param_47 = _e345;
            let _e346 = (*color_5);
            param_48 = _e346;
            let _e347 = mx_oren_nayar_compensated_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b((&param_44), (&param_45), (&param_46), (&param_47), (&param_48));
            local_3 = _e347;
        } else {
            let _e348 = NdotV_5;
            param_49 = _e348;
            let _e349 = NdotL_4;
            param_50 = _e349;
            let _e350 = LdotV_2;
            param_51 = _e350;
            let _e351 = (*roughness_7);
            param_52 = _e351;
            let _e352 = mx_oren_nayar_diffuse_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_49), (&param_50), (&param_51), (&param_52));
            let _e353 = (*color_5);
            local_3 = (_e353 * _e352);
        }
        let _e355 = local_3;
        diffuse = _e355;
        let _e356 = diffuse;
        let _e358 = (*closureData_9).occlusion;
        let _e360 = (*weight_2);
        let _e362 = NdotL_4;
        (*bsdf_2).response = ((((_e356 * _e358) * _e360) * _e362) * 0.31830987f);
    } else {
        let _e367 = (*closureData_9).closureType;
        if (_e367 == 3i) {
            let _e369 = (*energy_compensation);
            if _e369 {
                let _e370 = NdotV_5;
                param_53 = _e370;
                let _e371 = (*roughness_7);
                param_54 = _e371;
                let _e372 = (*color_5);
                param_55 = _e372;
                let _e373 = mx_oren_nayar_compensated_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b((&param_53), (&param_54), (&param_55));
                local_4 = _e373;
            } else {
                let _e374 = NdotV_5;
                param_56 = _e374;
                let _e375 = (*roughness_7);
                param_57 = _e375;
                let _e376 = mx_oren_nayar_diffuse_dir_albedo_u0028_f1_u003b_f1_u003b((&param_56), (&param_57));
                let _e377 = (*color_5);
                local_4 = (_e377 * _e376);
            }
            let _e379 = local_4;
            diffuse_1 = _e379;
            let _e380 = (*N_7);
            param_58 = _e380;
            let _e381 = mx_environment_irradiance_u0028_vf3_u003b((&param_58));
            Li_3 = _e381;
            let _e382 = Li_3;
            let _e383 = diffuse_1;
            let _e385 = (*weight_2);
            (*bsdf_2).response = ((_e382 * _e383) * _e385);
        }
    }
    return;
}

fn mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_10: ptr<function, ClosureData>, top_1: ptr<function, BSDF>, base_2: ptr<function, VDF>, result_7: ptr<function, BSDF>) {
    let _e287 = (*top_1).response;
    let _e289 = (*base_2).throughput;
    (*result_7).response = (_e287 * _e289);
    let _e293 = (*top_1).throughput;
    let _e295 = (*base_2).throughput;
    (*result_7).throughput = (_e293 * _e295);
    return;
}

fn mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b(closureData_11: ptr<function, ClosureData>, absorption: ptr<function, vec3<f32>>, scattering: ptr<function, vec3<f32>>, anisotropy_1: ptr<function, f32>, vdf: ptr<function, VDF>) {
    let _e288 = (*closureData_11).closureType;
    if (_e288 == 2i) {
        (*vdf).response = vec3<f32>(0f, 0f, 0f);
        let _e291 = (*absorption);
        (*vdf).throughput = exp(-(_e291));
    }
    return;
}

fn mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_12: ptr<function, ClosureData>, in1_2: ptr<function, BSDF>, in2_2: ptr<function, f32>, result_8: ptr<function, BSDF>) {
    var weight_3: f32;

    let _e287 = (*in2_2);
    weight_3 = clamp(_e287, 0f, 1f);
    let _e290 = (*in1_2).response;
    let _e291 = weight_3;
    (*result_8).response = (_e290 * _e291);
    let _e295 = (*in1_2).throughput;
    (*result_8).throughput = _e295;
    return;
}

fn mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_13: ptr<function, ClosureData>, in1_3: ptr<function, BSDF>, in2_3: ptr<function, BSDF>, result_9: ptr<function, BSDF>) {
    let _e287 = (*in1_3).response;
    let _e289 = (*in2_3).response;
    (*result_9).response = (_e287 + _e289);
    let _e293 = (*in1_3).throughput;
    let _e295 = (*in2_3).throughput;
    (*result_9).throughput = max(((_e293 + _e295) - vec3(1f)), vec3(0f));
    return;
}

fn mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b(NdotL_5: ptr<function, f32>, NdotV_6: ptr<function, f32>, alpha: ptr<function, f32>) -> f32 {
    var alpha2_: f32;
    var param_59: f32;
    var lambdaL: f32;
    var param_60: f32;
    var lambdaV: f32;
    var param_61: f32;

    let _e291 = (*alpha);
    param_59 = _e291;
    let _e292 = mx_square_u0028_f1_u003b((&param_59));
    alpha2_ = _e292;
    let _e293 = alpha2_;
    let _e294 = alpha2_;
    let _e296 = (*NdotL_5);
    param_60 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_60));
    lambdaL = sqrt((_e293 + ((1f - _e294) * _e297)));
    let _e301 = alpha2_;
    let _e302 = alpha2_;
    let _e304 = (*NdotV_6);
    param_61 = _e304;
    let _e305 = mx_square_u0028_f1_u003b((&param_61));
    lambdaV = sqrt((_e301 + ((1f - _e302) * _e305)));
    let _e309 = (*NdotL_5);
    let _e311 = (*NdotV_6);
    let _e313 = lambdaL;
    let _e314 = (*NdotV_6);
    let _e316 = lambdaV;
    let _e317 = (*NdotL_5);
    return (((2f * _e309) * _e311) / ((_e313 * _e314) + (_e316 * _e317)));
}

fn mx_pow6_u0028_f1_u003b(x_4: ptr<function, f32>) -> f32 {
    var x2_: f32;
    var param_62: f32;
    var param_63: f32;

    let _e286 = (*x_4);
    param_62 = _e286;
    let _e287 = mx_square_u0028_f1_u003b((&param_62));
    x2_ = _e287;
    let _e288 = x2_;
    param_63 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_63));
    let _e290 = x2_;
    return (_e289 * _e290);
}

fn mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_3: ptr<function, f32>, fd: ptr<function, FresnelData>) -> vec3<f32> {
    var x_5: f32;
    var a_1: vec3<f32>;
    var param_64: f32;

    let _e287 = (*cosTheta_3);
    x_5 = clamp(_e287, 0f, 1f);
    let _e290 = (*fd).F0_;
    let _e292 = (*fd).F90_;
    let _e294 = (*fd).exponent;
    let _e299 = (*fd).F82_;
    a_1 = ((mix(_e290, _e292, vec3(pow(0.85714287f, _e294))) * (vec3<f32>(1f, 1f, 1f) - _e299)) * 17.651384f);
    let _e304 = (*fd).F0_;
    let _e306 = (*fd).F90_;
    let _e307 = x_5;
    let _e310 = (*fd).exponent;
    let _e314 = a_1;
    let _e315 = x_5;
    let _e317 = x_5;
    param_64 = (1f - _e317);
    let _e319 = mx_pow6_u0028_f1_u003b((&param_64));
    return (mix(_e304, _e306, vec3(pow((1f - _e307), _e310))) - ((_e314 * _e315) * _e319));
}

fn mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_4: ptr<function, f32>, n: ptr<function, vec3<f32>>, k: ptr<function, vec3<f32>>, Rp: ptr<function, vec3<f32>>, Rs: ptr<function, vec3<f32>>) {
    var cosTheta2_: f32;
    var param_65: f32;
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

    let _e299 = (*cosTheta_4);
    param_65 = clamp(_e299, 0f, 1f);
    let _e301 = mx_square_u0028_f1_u003b((&param_65));
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
    a_2 = sqrt(max(((_e329 + _e330) * 0.5f), vec3(0f)));
    let _e336 = a_2;
    let _e338 = (*cosTheta_4);
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

fn mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b(cosTheta_5: ptr<function, f32>, n_1: ptr<function, vec3<f32>>, k_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var Rp_1: vec3<f32>;
    var Rs_1: vec3<f32>;
    var param_66: f32;
    var param_67: vec3<f32>;
    var param_68: vec3<f32>;
    var param_69: vec3<f32>;
    var param_70: vec3<f32>;

    let _e292 = (*cosTheta_5);
    param_66 = _e292;
    let _e293 = (*n_1);
    param_67 = _e293;
    let _e294 = (*k_1);
    param_68 = _e294;
    mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_66), (&param_67), (&param_68), (&param_69), (&param_70));
    let _e295 = param_69;
    Rp_1 = _e295;
    let _e296 = param_70;
    Rs_1 = _e296;
    let _e297 = Rp_1;
    let _e298 = Rs_1;
    return ((_e297 + _e298) * 0.5f);
}

fn mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b(cosTheta_6: ptr<function, f32>, ior: ptr<function, f32>) -> f32 {
    var c_1: f32;
    var g2_: f32;
    var g: f32;
    var param_71: f32;
    var param_72: f32;

    let _e289 = (*cosTheta_6);
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
    param_71 = ((_e302 - _e303) / (_e305 + _e306));
    let _e309 = mx_square_u0028_f1_u003b((&param_71));
    let _e311 = g;
    let _e312 = c_1;
    let _e314 = c_1;
    let _e317 = g;
    let _e318 = c_1;
    let _e320 = c_1;
    param_72 = ((((_e311 + _e312) * _e314) - 1f) / (((_e317 - _e318) * _e320) + 1f));
    let _e324 = mx_square_u0028_f1_u003b((&param_72));
    return ((0.5f * _e309) * (1f + _e324));
}

fn mx_matrix_mul_u0028_mf33_u003b_vf3_u003b(m_1: ptr<function, mat3x3<f32>>, v_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    let _e284 = (*m_1);
    let _e285 = (*v_1);
    return (_e284 * _e285);
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

fn mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b(cosTheta_7: ptr<function, f32>, eta1_: ptr<function, f32>, eta2_: ptr<function, vec3<f32>>, kappa2_: ptr<function, vec3<f32>>, phiP: ptr<function, vec3<f32>>, phiS: ptr<function, vec3<f32>>) {
    var k2_1: vec3<f32>;
    var sinThetaSqr: vec3<f32>;
    var A_4: vec3<f32>;
    var B_2: vec3<f32>;
    var param_73: vec3<f32>;
    var U: vec3<f32>;
    var V_4: vec3<f32>;
    var param_74: f32;
    var param_75: vec3<f32>;

    let _e297 = (*kappa2_);
    let _e298 = (*eta2_);
    k2_1 = (_e297 / _e298);
    let _e300 = (*cosTheta_7);
    let _e301 = (*cosTheta_7);
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
    param_73 = (((_e322 * 2f) * _e324) * _e326);
    let _e328 = mx_square_u0028_vf3_u003b((&param_73));
    B_2 = sqrt(((_e319 * _e320) + _e328));
    let _e331 = A_4;
    let _e332 = B_2;
    U = sqrt(((_e331 + _e332) / vec3(2f)));
    let _e337 = B_2;
    let _e338 = A_4;
    V_4 = max(vec3<f32>(0f, 0f, 0f), sqrt(((_e337 - _e338) / vec3(2f))));
    let _e344 = (*eta1_);
    let _e346 = V_4;
    let _e348 = (*cosTheta_7);
    let _e350 = U;
    let _e351 = U;
    let _e353 = V_4;
    let _e354 = V_4;
    let _e357 = (*eta1_);
    let _e358 = (*cosTheta_7);
    param_74 = (_e357 * _e358);
    let _e360 = mx_square_u0028_f1_u003b((&param_74));
    (*phiS) = atan2(((_e346 * (2f * _e344)) * _e348), (((_e350 * _e351) + (_e353 * _e354)) - vec3(_e360)));
    let _e364 = (*eta1_);
    let _e366 = (*eta2_);
    let _e368 = (*eta2_);
    let _e370 = (*cosTheta_7);
    let _e372 = k2_1;
    let _e374 = U;
    let _e376 = k2_1;
    let _e377 = k2_1;
    let _e380 = V_4;
    let _e384 = (*eta2_);
    let _e385 = (*eta2_);
    let _e387 = k2_1;
    let _e388 = k2_1;
    let _e392 = (*cosTheta_7);
    param_75 = (((_e384 * _e385) * (vec3<f32>(1f, 1f, 1f) + (_e387 * _e388))) * _e392);
    let _e394 = mx_square_u0028_vf3_u003b((&param_75));
    let _e395 = (*eta1_);
    let _e396 = (*eta1_);
    let _e398 = U;
    let _e399 = U;
    let _e401 = V_4;
    let _e402 = V_4;
    (*phiP) = atan2(((((_e366 * (2f * _e364)) * _e368) * _e370) * (((_e372 * 2f) * _e374) - ((vec3<f32>(1f, 1f, 1f) - (_e376 * _e377)) * _e380))), (_e394 - (((_e398 * _e399) + (_e401 * _e402)) * (_e395 * _e396))));
    return;
}

fn mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b(cosTheta_8: ptr<function, f32>, ior_1: ptr<function, f32>) -> vec2<f32> {
    var cosTheta2_1: f32;
    var param_76: f32;
    var sinTheta2_1: f32;
    var t0_1: f32;
    var t1_1: f32;
    var t2_1: f32;
    var Rs_2: f32;
    var t3_1: f32;
    var t4_1: f32;
    var Rp_2: f32;

    let _e294 = (*cosTheta_8);
    param_76 = clamp(_e294, 0f, 1f);
    let _e296 = mx_square_u0028_f1_u003b((&param_76));
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
    let _e311 = (*cosTheta_8);
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

fn mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_9: ptr<function, f32>, fd_1: ptr<function, FresnelData>) -> vec3<f32> {
    var eta1_1: f32;
    var eta2_1: f32;
    var eta3_: vec3<f32>;
    var local_5: vec3<f32>;
    var param_77: vec3<f32>;
    var kappa3_: vec3<f32>;
    var local_6: vec3<f32>;
    var cosThetaT: f32;
    var param_78: f32;
    var param_79: f32;
    var R12_: vec2<f32>;
    var param_80: f32;
    var param_81: f32;
    var T121_: vec2<f32>;
    var f_1: vec3<f32>;
    var param_82: f32;
    var param_83: FresnelData;
    var R23p: vec3<f32>;
    var R23s: vec3<f32>;
    var param_84: f32;
    var param_85: vec3<f32>;
    var param_86: vec3<f32>;
    var param_87: vec3<f32>;
    var param_88: vec3<f32>;
    var cosB: f32;
    var phi21_: vec2<f32>;
    var phi23p: vec3<f32>;
    var phi23s: vec3<f32>;
    var param_89: f32;
    var param_90: f32;
    var param_91: vec3<f32>;
    var param_92: vec3<f32>;
    var param_93: vec3<f32>;
    var param_94: vec3<f32>;
    var r123p: vec3<f32>;
    var r123s: vec3<f32>;
    var I: vec3<f32>;
    var distMeters: f32;
    var opd_1: f32;
    var Rs_3: vec3<f32>;
    var param_95: f32;
    var Cm: vec3<f32>;
    var m_2: i32;
    var Sm: vec3<f32>;
    var param_96: f32;
    var param_97: vec3<f32>;
    var Rp_3: vec3<f32>;
    var param_98: f32;
    var m_3: i32;
    var param_99: f32;
    var param_100: vec3<f32>;
    var param_101: mat3x3<f32>;
    var param_102: vec3<f32>;

    eta1_1 = 1f;
    let _e338 = (*fd_1).tf_ior;
    let _e339 = eta1_1;
    eta2_1 = max(_e338, _e339);
    let _e342 = (*fd_1).model;
    if (_e342 == 2i) {
        let _e345 = (*fd_1).F0_;
        param_77 = _e345;
        let _e346 = mx_f0_to_ior_u0028_vf3_u003b((&param_77));
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
    let _e356 = (*cosTheta_9);
    param_78 = _e356;
    let _e357 = mx_square_u0028_f1_u003b((&param_78));
    let _e359 = eta1_1;
    let _e360 = eta2_1;
    param_79 = (_e359 / _e360);
    let _e362 = mx_square_u0028_f1_u003b((&param_79));
    cosThetaT = sqrt((1f - ((1f - _e357) * _e362)));
    let _e366 = eta2_1;
    let _e367 = eta1_1;
    let _e369 = (*cosTheta_9);
    param_80 = _e369;
    param_81 = (_e366 / _e367);
    let _e370 = mx_fresnel_dielectric_polarized_u0028_f1_u003b_f1_u003b((&param_80), (&param_81));
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
        param_82 = _e378;
        let _e379 = (*fd_1);
        param_83 = _e379;
        let _e380 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_82), (&param_83));
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
        param_84 = _e393;
        param_85 = (_e385 / vec3(_e386));
        param_86 = (_e389 / vec3(_e390));
        mx_fresnel_conductor_polarized_u0028_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_84), (&param_85), (&param_86), (&param_87), (&param_88));
        let _e394 = param_87;
        R23p = _e394;
        let _e395 = param_88;
        R23s = _e395;
    }
    let _e396 = eta2_1;
    let _e397 = eta1_1;
    cosB = cos(atan((_e396 / _e397)));
    let _e401 = (*cosTheta_9);
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
        param_89 = _e426;
        let _e427 = eta2_1;
        param_90 = _e427;
        let _e428 = eta3_;
        param_91 = _e428;
        let _e429 = kappa3_;
        param_92 = _e429;
        mx_fresnel_conductor_phase_polarized_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_89), (&param_90), (&param_91), (&param_92), (&param_93), (&param_94));
        let _e430 = param_93;
        phi23p = _e430;
        let _e431 = param_94;
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
    param_95 = _e456;
    let _e457 = mx_square_u0028_f1_u003b((&param_95));
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
    m_2 = 1i;
    loop {
        let _e478 = m_2;
        if (_e478 <= 2i) {
            let _e480 = r123p;
            let _e481 = Cm;
            Cm = (_e481 * _e480);
            let _e483 = m_2;
            let _e485 = opd_1;
            let _e487 = m_2;
            let _e489 = phi23p;
            let _e491 = phi21_[0u];
            param_96 = (f32(_e483) * _e485);
            param_97 = ((_e489 + vec3(_e491)) * f32(_e487));
            let _e495 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_96), (&param_97));
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
            let _e502 = m_2;
            m_2 = (_e502 + 1i);
        }
    }
    let _e505 = T121_[1u];
    param_98 = _e505;
    let _e506 = mx_square_u0028_f1_u003b((&param_98));
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
    m_3 = 1i;
    loop {
        let _e527 = m_3;
        if (_e527 <= 2i) {
            let _e529 = r123s;
            let _e530 = Cm;
            Cm = (_e530 * _e529);
            let _e532 = m_3;
            let _e534 = opd_1;
            let _e536 = m_3;
            let _e538 = phi23s;
            let _e540 = phi21_[1u];
            param_99 = (f32(_e532) * _e534);
            param_100 = ((_e538 + vec3(_e540)) * f32(_e536));
            let _e544 = mx_eval_sensitivity_u0028_f1_u003b_vf3_u003b((&param_99), (&param_100));
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
            let _e551 = m_3;
            m_3 = (_e551 + 1i);
        }
    }
    let _e553 = I;
    I = (_e553 * 0.5f);
    param_101 = mat3x3<f32>(vec3<f32>(2.3706744f, -0.513885f, 0.0052982f), vec3<f32>(-0.9000405f, 1.4253036f, -0.0146949f), vec3<f32>(-0.4706338f, 0.0885814f, 1.0093968f));
    let _e555 = I;
    param_102 = _e555;
    let _e556 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_101), (&param_102));
    I = clamp(_e556, vec3(0f), vec3(1f));
    let _e560 = I;
    return _e560;
}

fn mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(cosTheta_10: ptr<function, f32>, fd_2: ptr<function, FresnelData>) -> vec3<f32> {
    var param_103: f32;
    var param_104: FresnelData;
    var param_105: f32;
    var param_106: f32;
    var param_107: f32;
    var param_108: vec3<f32>;
    var param_109: vec3<f32>;
    var param_110: f32;
    var param_111: FresnelData;

    let _e294 = (*fd_2).airy;
    if _e294 {
        let _e295 = (*cosTheta_10);
        param_103 = _e295;
        let _e296 = (*fd_2);
        param_104 = _e296;
        let _e297 = mx_fresnel_airy_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_103), (&param_104));
        return _e297;
    } else {
        let _e299 = (*fd_2).model;
        if (_e299 == 0i) {
            let _e301 = (*cosTheta_10);
            param_105 = _e301;
            let _e304 = (*fd_2).ior[0u];
            param_106 = _e304;
            let _e305 = mx_fresnel_dielectric_u0028_f1_u003b_f1_u003b((&param_105), (&param_106));
            return vec3(_e305);
        } else {
            let _e308 = (*fd_2).model;
            if (_e308 == 1i) {
                let _e310 = (*cosTheta_10);
                param_107 = _e310;
                let _e312 = (*fd_2).ior;
                param_108 = _e312;
                let _e314 = (*fd_2).extinction;
                param_109 = _e314;
                let _e315 = mx_fresnel_conductor_u0028_f1_u003b_vf3_u003b_vf3_u003b((&param_107), (&param_108), (&param_109));
                return _e315;
            } else {
                let _e316 = (*cosTheta_10);
                param_110 = _e316;
                let _e317 = (*fd_2);
                param_111 = _e317;
                let _e318 = mx_fresnel_hoffman_schlick_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_110), (&param_111));
                return _e318;
            }
        }
    }
}

fn mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b(dir_2: ptr<function, vec3<f32>>, transform_1: ptr<function, mat4x4<f32>>, lod_1: ptr<function, f32>) -> vec3<f32> {
    var envDir_1: vec3<f32>;
    var param_112: mat4x4<f32>;
    var param_113: vec4<f32>;
    var uv_2: vec2<f32>;
    var param_114: vec3<f32>;

    let _e290 = (*dir_2);
    let _e295 = (*transform_1);
    param_112 = _e295;
    param_113 = vec4<f32>(_e290.x, _e290.y, _e290.z, 0f);
    let _e296 = mx_matrix_mul_u0028_mf44_u003b_vf4_u003b((&param_112), (&param_113));
    envDir_1 = normalize(_e296.xyz);
    let _e299 = envDir_1;
    param_114 = _e299;
    let _e300 = mx_latlong_projection_u0028_vf3_u003b((&param_114));
    uv_2 = _e300;
    let _e301 = uv_2;
    let _e302 = textureSampleLevel(envMapLatLong_texture, envMapLatLong_sampler, _e301, 0.0);
    return _e302.xyz;
}

fn mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b(dir_3: ptr<function, vec3<f32>>, pdf: ptr<function, f32>, maxMipLevel: ptr<function, f32>, envSamples: ptr<function, i32>) -> f32 {
    var effectiveMaxMipLevel: f32;
    var distortion: f32;
    var param_115: f32;

    let _e289 = (*maxMipLevel);
    effectiveMaxMipLevel = (_e289 - 1.5f);
    let _e292 = (*dir_3)[1u];
    param_115 = _e292;
    let _e293 = mx_square_u0028_f1_u003b((&param_115));
    distortion = sqrt((1f - _e293));
    let _e296 = effectiveMaxMipLevel;
    let _e297 = (*envSamples);
    let _e299 = (*pdf);
    let _e301 = distortion;
    return max((_e296 - (0.5f * log2(((f32(_e297) * _e299) * _e301)))), 0f);
}

fn mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b(H: ptr<function, vec3<f32>>, alpha_1: ptr<function, vec2<f32>>) -> f32 {
    var He: vec2<f32>;
    var denom_1: f32;
    var param_116: f32;
    var param_117: f32;

    let _e288 = (*H);
    let _e290 = (*alpha_1);
    He = (_e288.xy / _e290);
    let _e292 = He;
    let _e293 = He;
    let _e296 = (*H)[2u];
    param_116 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_116));
    denom_1 = (dot(_e292, _e293) + _e297);
    let _e300 = (*alpha_1)[0u];
    let _e303 = (*alpha_1)[1u];
    let _e305 = denom_1;
    param_117 = _e305;
    let _e306 = mx_square_u0028_f1_u003b((&param_117));
    return (1f / (((3.1415927f * _e300) * _e303) * _e306));
}

fn mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b(H_1: ptr<function, vec3<f32>>, alpha_2: ptr<function, vec2<f32>>, G1V: ptr<function, f32>, NdotV_7: ptr<function, f32>) -> f32 {
    var param_118: vec3<f32>;
    var param_119: vec2<f32>;

    let _e288 = (*H_1);
    param_118 = _e288;
    let _e289 = (*alpha_2);
    param_119 = _e289;
    let _e290 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_118), (&param_119));
    let _e291 = (*G1V);
    let _e293 = (*NdotV_7);
    return ((_e290 * _e291) / (4f * _e293));
}

fn mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b(R_1: ptr<function, vec3<f32>>, N_8: ptr<function, vec3<f32>>, ior_2: ptr<function, f32>) -> vec3<f32> {
    var N1_: vec3<f32>;

    let _e286 = (*R_1);
    let _e287 = (*N_8);
    let _e288 = (*ior_2);
    (*R_1) = refract(_e286, _e287, (1f / _e288));
    let _e291 = (*R_1);
    let _e292 = (*R_1);
    let _e293 = (*N_8);
    let _e296 = (*N_8);
    N1_ = normalize(((_e291 * dot(_e292, _e293)) - (_e296 * 0.5f)));
    let _e300 = (*R_1);
    let _e301 = N1_;
    let _e302 = (*ior_2);
    return refract(_e300, _e301, _e302);
}

fn mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b(Xi: ptr<function, vec2<f32>>, V_5: ptr<function, vec3<f32>>, alpha_3: ptr<function, vec2<f32>>) -> vec3<f32> {
    var phi: f32;
    var z: f32;
    var sinTheta: f32;
    var x_6: f32;
    var y: f32;
    var c_2: vec3<f32>;
    var H_2: vec3<f32>;

    let _e292 = (*V_5);
    let _e294 = (*alpha_3);
    let _e295 = (_e292.xy * _e294);
    let _e297 = (*V_5)[2u];
    (*V_5) = normalize(vec3<f32>(_e295.x, _e295.y, _e297));
    let _e303 = (*Xi)[0u];
    phi = (6.2831855f * _e303);
    let _e306 = (*Xi)[1u];
    let _e309 = (*V_5)[2u];
    let _e313 = (*V_5)[2u];
    z = (((1f - _e306) * (1f + _e309)) - _e313);
    let _e315 = z;
    let _e316 = z;
    sinTheta = sqrt(clamp((1f - (_e315 * _e316)), 0f, 1f));
    let _e321 = sinTheta;
    let _e322 = phi;
    x_6 = (_e321 * cos(_e322));
    let _e325 = sinTheta;
    let _e326 = phi;
    y = (_e325 * sin(_e326));
    let _e329 = x_6;
    let _e330 = y;
    let _e331 = z;
    c_2 = vec3<f32>(_e329, _e330, _e331);
    let _e333 = c_2;
    let _e334 = (*V_5);
    H_2 = (_e333 + _e334);
    let _e336 = H_2;
    let _e338 = (*alpha_3);
    let _e339 = (_e336.xy * _e338);
    let _e341 = H_2[2u];
    H_2 = normalize(vec3<f32>(_e339.x, _e339.y, max(_e341, 0f)));
    let _e347 = H_2;
    return _e347;
}

fn mx_golden_ratio_sequence_u0028_i1_u003b(i_1: ptr<function, i32>) -> f32 {
    let _e283 = (*i_1);
    return fract(((f32(_e283) + 1f) * 1.618034f));
}

fn mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b(i_2: ptr<function, i32>, numSamples: ptr<function, i32>) -> vec2<f32> {
    var param_120: i32;

    let _e285 = (*i_2);
    let _e288 = (*numSamples);
    let _e291 = (*i_2);
    param_120 = _e291;
    let _e292 = mx_golden_ratio_sequence_u0028_i1_u003b((&param_120));
    return vec2<f32>(((f32(_e285) + 0.5f) / f32(_e288)), _e292);
}

fn mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b(cosTheta_11: ptr<function, f32>, alpha_4: ptr<function, f32>) -> f32 {
    var cosTheta2_2: f32;
    var param_121: f32;
    var tanTheta2_: f32;
    var param_122: f32;

    let _e288 = (*cosTheta_11);
    param_121 = _e288;
    let _e289 = mx_square_u0028_f1_u003b((&param_121));
    cosTheta2_2 = _e289;
    let _e290 = cosTheta2_2;
    let _e292 = cosTheta2_2;
    tanTheta2_ = ((1f - _e290) / _e292);
    let _e294 = (*alpha_4);
    param_122 = _e294;
    let _e295 = mx_square_u0028_f1_u003b((&param_122));
    let _e296 = tanTheta2_;
    return (2f / (1f + sqrt((1f + (_e295 * _e296)))));
}

fn mx_average_alpha_u0028_vf2_u003b(alpha_5: ptr<function, vec2<f32>>) -> f32 {
    let _e284 = (*alpha_5)[0u];
    let _e286 = (*alpha_5)[1u];
    return sqrt((_e284 * _e286));
}

fn mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(N_9: ptr<function, vec3<f32>>, V_6: ptr<function, vec3<f32>>, X: ptr<function, vec3<f32>>, alpha_6: ptr<function, vec2<f32>>, distribution: ptr<function, i32>, fd_3: ptr<function, FresnelData>) -> vec3<f32> {
    var Y: vec3<f32>;
    var tangentToWorld: mat3x3<f32>;
    var NdotV_8: f32;
    var avgAlpha: f32;
    var param_123: vec2<f32>;
    var G1V_1: f32;
    var param_124: f32;
    var param_125: f32;
    var radiance: vec3<f32>;
    var envRadianceSamples: i32;
    var i_3: i32;
    var Xi_1: vec2<f32>;
    var param_126: i32;
    var param_127: i32;
    var H_3: vec3<f32>;
    var param_128: vec2<f32>;
    var param_129: vec3<f32>;
    var param_130: vec2<f32>;
    var L_5: vec3<f32>;
    var local_7: vec3<f32>;
    var param_131: vec3<f32>;
    var param_132: vec3<f32>;
    var param_133: f32;
    var NdotL_6: f32;
    var VdotH: f32;
    var Lw: vec3<f32>;
    var param_134: mat3x3<f32>;
    var param_135: vec3<f32>;
    var pdf_1: f32;
    var param_136: vec3<f32>;
    var param_137: vec2<f32>;
    var param_138: f32;
    var param_139: f32;
    var lod_2: f32;
    var param_140: vec3<f32>;
    var param_141: f32;
    var param_142: f32;
    var param_143: i32;
    var sampleColor: vec3<f32>;
    var param_144: vec3<f32>;
    var param_145: mat4x4<f32>;
    var param_146: f32;
    var F: vec3<f32>;
    var param_147: f32;
    var param_148: FresnelData;
    var G_1: f32;
    var param_149: f32;
    var param_150: f32;
    var param_151: f32;
    var FG: vec3<f32>;
    var local_8: vec3<f32>;

    let _e339 = (*X);
    let _e340 = (*X);
    let _e341 = (*N_9);
    let _e343 = (*N_9);
    (*X) = normalize((_e339 - (_e343 * dot(_e340, _e341))));
    let _e347 = (*N_9);
    let _e348 = (*X);
    Y = cross(_e347, _e348);
    let _e350 = (*X);
    let _e351 = Y;
    let _e352 = (*N_9);
    tangentToWorld = mat3x3<f32>(vec3<f32>(_e350.x, _e350.y, _e350.z), vec3<f32>(_e351.x, _e351.y, _e351.z), vec3<f32>(_e352.x, _e352.y, _e352.z));
    let _e366 = (*V_6);
    let _e367 = (*X);
    let _e369 = (*V_6);
    let _e370 = Y;
    let _e372 = (*V_6);
    let _e373 = (*N_9);
    (*V_6) = vec3<f32>(dot(_e366, _e367), dot(_e369, _e370), dot(_e372, _e373));
    let _e377 = (*V_6)[2u];
    NdotV_8 = clamp(_e377, 0.00000001f, 1f);
    let _e379 = (*alpha_6);
    param_123 = _e379;
    let _e380 = mx_average_alpha_u0028_vf2_u003b((&param_123));
    avgAlpha = _e380;
    let _e381 = NdotV_8;
    param_124 = _e381;
    let _e382 = avgAlpha;
    param_125 = _e382;
    let _e383 = mx_ggx_smith_G1_u0028_f1_u003b_f1_u003b((&param_124), (&param_125));
    G1V_1 = _e383;
    radiance = vec3<f32>(0f, 0f, 0f);
    envRadianceSamples = 1i;
    i_3 = 0i;
    loop {
        let _e384 = i_3;
        let _e385 = envRadianceSamples;
        if (_e384 < _e385) {
            let _e387 = i_3;
            param_126 = _e387;
            let _e388 = envRadianceSamples;
            param_127 = _e388;
            let _e389 = mx_spherical_fibonacci_u0028_i1_u003b_i1_u003b((&param_126), (&param_127));
            Xi_1 = _e389;
            let _e390 = Xi_1;
            param_128 = _e390;
            let _e391 = (*V_6);
            param_129 = _e391;
            let _e392 = (*alpha_6);
            param_130 = _e392;
            let _e393 = mx_ggx_importance_sample_VNDF_u0028_vf2_u003b_vf3_u003b_vf2_u003b((&param_128), (&param_129), (&param_130));
            H_3 = _e393;
            let _e395 = (*fd_3).refraction;
            if _e395 {
                let _e396 = (*V_6);
                param_131 = -(_e396);
                let _e398 = H_3;
                param_132 = _e398;
                let _e401 = (*fd_3).ior[0u];
                param_133 = _e401;
                let _e402 = mx_refraction_solid_sphere_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_131), (&param_132), (&param_133));
                local_7 = _e402;
            } else {
                let _e403 = (*V_6);
                let _e404 = H_3;
                local_7 = -(reflect(_e403, _e404));
            }
            let _e407 = local_7;
            L_5 = _e407;
            let _e409 = L_5[2u];
            NdotL_6 = clamp(_e409, 0.00000001f, 1f);
            let _e411 = (*V_6);
            let _e412 = H_3;
            VdotH = clamp(dot(_e411, _e412), 0.00000001f, 1f);
            let _e415 = tangentToWorld;
            param_134 = _e415;
            let _e416 = L_5;
            param_135 = _e416;
            let _e417 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_134), (&param_135));
            Lw = _e417;
            let _e418 = H_3;
            param_136 = _e418;
            let _e419 = (*alpha_6);
            param_137 = _e419;
            let _e420 = G1V_1;
            param_138 = _e420;
            let _e421 = NdotV_8;
            param_139 = _e421;
            let _e422 = mx_ggx_VNDF_reflection_PDF_u0028_vf3_u003b_vf2_u003b_f1_u003b_f1_u003b((&param_136), (&param_137), (&param_138), (&param_139));
            pdf_1 = _e422;
            let _e423 = Lw;
            param_140 = _e423;
            let _e424 = pdf_1;
            param_141 = _e424;
            param_142 = 0f;
            let _e425 = envRadianceSamples;
            param_143 = _e425;
            let _e426 = mx_latlong_compute_lod_u0028_vf3_u003b_f1_u003b_f1_u003b_i1_u003b((&param_140), (&param_141), (&param_142), (&param_143));
            lod_2 = _e426;
            let _e427 = mtlxEnvMatrix_u0028_();
            let _e428 = Lw;
            param_144 = _e428;
            param_145 = _e427;
            let _e429 = lod_2;
            param_146 = _e429;
            let _e430 = mx_latlong_map_lookup_radiance_u0028_vf3_u003b_mf44_u003b_f1_u003b((&param_144), (&param_145), (&param_146));
            sampleColor = _e430;
            let _e431 = VdotH;
            param_147 = _e431;
            let _e432 = (*fd_3);
            param_148 = _e432;
            let _e433 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_147), (&param_148));
            F = _e433;
            let _e434 = NdotL_6;
            param_149 = _e434;
            let _e435 = NdotV_8;
            param_150 = _e435;
            let _e436 = avgAlpha;
            param_151 = _e436;
            let _e437 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_149), (&param_150), (&param_151));
            G_1 = _e437;
            let _e439 = (*fd_3).refraction;
            if _e439 {
                let _e440 = F;
                local_8 = (vec3<f32>(1f, 1f, 1f) - _e440);
            } else {
                let _e442 = F;
                let _e443 = G_1;
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

fn mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b(N_10: ptr<function, vec3<f32>>, V_7: ptr<function, vec3<f32>>, X_1: ptr<function, vec3<f32>>, alpha_7: ptr<function, vec2<f32>>, distribution_1: ptr<function, i32>, fd_4: ptr<function, FresnelData>, tint_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_152: vec3<f32>;
    var param_153: vec3<f32>;
    var param_154: vec3<f32>;
    var param_155: vec3<f32>;
    var param_156: vec2<f32>;
    var param_157: i32;
    var param_158: FresnelData;

    (*fd_4).refraction = true;
    if false {
        let _e297 = (*tint_1);
        param_152 = _e297;
        let _e298 = mx_square_u0028_vf3_u003b((&param_152));
        (*tint_1) = _e298;
    }
    let _e299 = (*N_10);
    param_153 = _e299;
    let _e300 = (*V_7);
    param_154 = _e300;
    let _e301 = (*X_1);
    param_155 = _e301;
    let _e302 = (*alpha_7);
    param_156 = _e302;
    let _e303 = (*distribution_1);
    param_157 = _e303;
    let _e304 = (*fd_4);
    param_158 = _e304;
    let _e305 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_153), (&param_154), (&param_155), (&param_156), (&param_157), (&param_158));
    let _e306 = (*tint_1);
    return (_e305 * _e306);
}

fn mx_f0_to_ior_u0028_f1_u003b(F0_2: ptr<function, f32>) -> f32 {
    var sqrtF0_1: f32;

    let _e284 = (*F0_2);
    sqrtF0_1 = sqrt(clamp(_e284, 0.01f, 0.99f));
    let _e287 = sqrtF0_1;
    let _e289 = sqrtF0_1;
    return ((1f + _e287) / (1f - _e289));
}

fn mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_9: ptr<function, f32>, alpha_8: ptr<function, f32>, F0_3: ptr<function, vec3<f32>>, F90_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var x_7: f32;
    var y_1: f32;
    var x2_1: f32;
    var param_159: f32;
    var y2_: f32;
    var param_160: f32;
    var r_1: vec4<f32>;
    var AB: vec2<f32>;

    let _e294 = (*NdotV_9);
    x_7 = _e294;
    let _e295 = (*alpha_8);
    y_1 = _e295;
    let _e296 = x_7;
    param_159 = _e296;
    let _e297 = mx_square_u0028_f1_u003b((&param_159));
    x2_1 = _e297;
    let _e298 = y_1;
    param_160 = _e298;
    let _e299 = mx_square_u0028_f1_u003b((&param_160));
    y2_ = _e299;
    let _e300 = x_7;
    let _e303 = y_1;
    let _e306 = x_7;
    let _e308 = y_1;
    let _e311 = x2_1;
    let _e314 = y2_;
    let _e317 = x2_1;
    let _e319 = y_1;
    let _e322 = x_7;
    let _e324 = y2_;
    let _e327 = x2_1;
    let _e329 = y2_;
    r_1 = ((((((((vec4<f32>(0.1003f, 0.9345f, 1f, 1f) + (vec4<f32>(-0.6303f, -2.323f, -1.765f, 0.2281f) * _e300)) + (vec4<f32>(9.748f, 2.229f, 8.263f, 15.94f) * _e303)) + ((vec4<f32>(-2.038f, -3.748f, 11.53f, -55.83f) * _e306) * _e308)) + (vec4<f32>(29.34f, 1.424f, 28.96f, 13.08f) * _e311)) + (vec4<f32>(-8.245f, -0.7684f, -7.507f, 41.26f) * _e314)) + ((vec4<f32>(-26.44f, 1.436f, -36.11f, 54.9f) * _e317) * _e319)) + ((vec4<f32>(19.99f, 0.2913f, 15.86f, 300.2f) * _e322) * _e324)) + ((vec4<f32>(-5.448f, 0.6286f, 33.37f, -285.1f) * _e327) * _e329));
    let _e332 = r_1;
    let _e334 = r_1;
    AB = clamp((_e332.xy / _e334.zw), vec2(0f), vec2(1f));
    let _e340 = (*F0_3);
    let _e342 = AB[0u];
    let _e344 = (*F90_1);
    let _e346 = AB[1u];
    return ((_e340 * _e342) + (_e344 * _e346));
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b(NdotV_10: ptr<function, f32>, alpha_9: ptr<function, f32>, F0_4: ptr<function, vec3<f32>>, F90_2: ptr<function, vec3<f32>>) -> vec3<f32> {
    var param_161: f32;
    var param_162: f32;
    var param_163: vec3<f32>;
    var param_164: vec3<f32>;

    let _e290 = (*NdotV_10);
    param_161 = _e290;
    let _e291 = (*alpha_9);
    param_162 = _e291;
    let _e292 = (*F0_4);
    param_163 = _e292;
    let _e293 = (*F90_2);
    param_164 = _e293;
    let _e294 = mx_ggx_dir_albedo_analytic_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_161), (&param_162), (&param_163), (&param_164));
    return _e294;
}

fn mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotV_11: ptr<function, f32>, alpha_10: ptr<function, f32>, F0_5: ptr<function, f32>, F90_3: ptr<function, f32>) -> f32 {
    var param_165: f32;
    var param_166: f32;
    var param_167: vec3<f32>;
    var param_168: vec3<f32>;

    let _e290 = (*F0_5);
    let _e292 = (*F90_3);
    let _e294 = (*NdotV_11);
    param_165 = _e294;
    let _e295 = (*alpha_10);
    param_166 = _e295;
    param_167 = vec3(_e290);
    param_168 = vec3(_e292);
    let _e296 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_165), (&param_166), (&param_167), (&param_168));
    return _e296.x;
}

fn mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(fd_5: ptr<function, FresnelData>) -> vec3<f32> {
    var F0_6: vec3<f32>;
    var param_169: f32;
    var param_170: FresnelData;
    var F90_4: vec3<f32>;
    var local_9: vec3<f32>;
    var phi_3020_: bool;

    param_169 = 1f;
    let _e288 = (*fd_5);
    param_170 = _e288;
    let _e289 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_169), (&param_170));
    F0_6 = _e289;
    let _e291 = (*fd_5).model;
    let _e292 = (_e291 == 2i);
    phi_3020_ = _e292;
    if _e292 {
        let _e294 = (*fd_5).airy;
        phi_3020_ = !(_e294);
    }
    let _e297 = phi_3020_;
    if _e297 {
        let _e299 = (*fd_5).F90_;
        local_9 = _e299;
    } else {
        local_9 = vec3<f32>(1f, 1f, 1f);
    }
    let _e300 = local_9;
    F90_4 = _e300;
    let _e301 = F0_6;
    let _e302 = F90_4;
    let _e303 = F0_6;
    return (_e301 + ((_e302 - _e303) * 0.04761905f));
}

fn mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b(NdotV_12: ptr<function, f32>, alpha_11: ptr<function, f32>, fd_6: ptr<function, FresnelData>) -> vec3<f32> {
    var Fss: vec3<f32>;
    var param_171: FresnelData;
    var Ess: f32;
    var param_172: f32;
    var param_173: f32;
    var param_174: f32;
    var param_175: f32;

    let _e292 = (*fd_6);
    param_171 = _e292;
    let _e293 = mx_fresnel_average_u0028_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_171));
    Fss = _e293;
    let _e294 = (*NdotV_12);
    param_172 = _e294;
    let _e295 = (*alpha_11);
    param_173 = _e295;
    param_174 = 1f;
    param_175 = 1f;
    let _e296 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_172), (&param_173), (&param_174), (&param_175));
    Ess = _e296;
    let _e297 = Fss;
    let _e298 = Ess;
    let _e301 = Ess;
    return (vec3(1f) + ((_e297 * (1f - _e298)) / vec3(_e301)));
}

fn mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(F0_7: ptr<function, vec3<f32>>, F82_: ptr<function, vec3<f32>>, F90_5: ptr<function, vec3<f32>>, exponent_2: ptr<function, f32>, tf_thickness: ptr<function, f32>, tf_ior: ptr<function, f32>) -> FresnelData {
    var fd_7: FresnelData;

    fd_7.model = 2i;
    let _e290 = (*tf_thickness);
    fd_7.airy = (_e290 > 0f);
    fd_7.ior = vec3<f32>(0f, 0f, 0f);
    fd_7.extinction = vec3<f32>(0f, 0f, 0f);
    let _e295 = (*F0_7);
    fd_7.F0_ = _e295;
    let _e297 = (*F82_);
    fd_7.F82_ = _e297;
    let _e299 = (*F90_5);
    fd_7.F90_ = _e299;
    let _e301 = (*exponent_2);
    fd_7.exponent = _e301;
    let _e303 = (*tf_thickness);
    fd_7.tf_thickness = _e303;
    let _e305 = (*tf_ior);
    fd_7.tf_ior = _e305;
    fd_7.refraction = false;
    let _e308 = fd_7;
    return _e308;
}

fn mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_14: ptr<function, ClosureData>, weight_4: ptr<function, f32>, color0_1: ptr<function, vec3<f32>>, color82_: ptr<function, vec3<f32>>, color90_1: ptr<function, vec3<f32>>, exponent_3: ptr<function, f32>, roughness_8: ptr<function, vec2<f32>>, retroreflective: ptr<function, bool>, thinfilm_thickness: ptr<function, f32>, thinfilm_ior: ptr<function, f32>, N_11: ptr<function, vec3<f32>>, X_2: ptr<function, vec3<f32>>, distribution_2: ptr<function, i32>, scatter_mode: ptr<function, i32>, bsdf_3: ptr<function, BSDF>) {
    var V_8: vec3<f32>;
    var L_6: vec3<f32>;
    var param_176: vec3<f32>;
    var param_177: vec3<f32>;
    var NdotV_13: f32;
    var safeColor0_: vec3<f32>;
    var safeColor82_: vec3<f32>;
    var safeColor90_: vec3<f32>;
    var fd_8: FresnelData;
    var param_178: vec3<f32>;
    var param_179: vec3<f32>;
    var param_180: vec3<f32>;
    var param_181: f32;
    var param_182: f32;
    var param_183: f32;
    var safeAlpha: vec2<f32>;
    var avgAlpha_1: f32;
    var param_184: vec2<f32>;
    var Y_1: vec3<f32>;
    var H_4: vec3<f32>;
    var NdotL_7: f32;
    var VdotH_1: f32;
    var Ht: vec3<f32>;
    var F_1: vec3<f32>;
    var param_185: f32;
    var param_186: FresnelData;
    var D: f32;
    var param_187: vec3<f32>;
    var param_188: vec2<f32>;
    var G_2: f32;
    var param_189: f32;
    var param_190: f32;
    var param_191: f32;
    var comp: vec3<f32>;
    var param_192: f32;
    var param_193: f32;
    var param_194: FresnelData;
    var dirAlbedo_2: vec3<f32>;
    var param_195: f32;
    var param_196: f32;
    var param_197: vec3<f32>;
    var param_198: vec3<f32>;
    var avgDirAlbedo: f32;
    var comp_1: vec3<f32>;
    var param_199: f32;
    var param_200: f32;
    var param_201: FresnelData;
    var dirAlbedo_3: vec3<f32>;
    var param_202: f32;
    var param_203: f32;
    var param_204: vec3<f32>;
    var param_205: vec3<f32>;
    var avgDirAlbedo_1: f32;
    var avgF0_: f32;
    var param_206: f32;
    var param_207: vec3<f32>;
    var param_208: vec3<f32>;
    var param_209: vec3<f32>;
    var param_210: vec2<f32>;
    var param_211: i32;
    var param_212: FresnelData;
    var param_213: vec3<f32>;
    var comp_2: vec3<f32>;
    var param_214: f32;
    var param_215: f32;
    var param_216: FresnelData;
    var dirAlbedo_4: vec3<f32>;
    var param_217: f32;
    var param_218: f32;
    var param_219: vec3<f32>;
    var param_220: vec3<f32>;
    var avgDirAlbedo_2: f32;
    var Li_4: vec3<f32>;
    var param_221: vec3<f32>;
    var param_222: vec3<f32>;
    var param_223: vec3<f32>;
    var param_224: vec2<f32>;
    var param_225: i32;
    var param_226: FresnelData;
    var phi_5035_: bool;

    let _e376 = (*weight_4);
    if (_e376 < 0.00000001f) {
        return;
    }
    let _e379 = (*closureData_14).closureType;
    let _e381 = (*scatter_mode);
    if ((_e379 != 2i) && (_e381 == 1i)) {
        return;
    }
    let _e385 = (*closureData_14).V;
    V_8 = _e385;
    let _e387 = (*closureData_14).L;
    L_6 = _e387;
    let _e388 = (*retroreflective);
    phi_5035_ = _e388;
    if _e388 {
        let _e390 = (*closureData_14).closureType;
        phi_5035_ = (_e390 != 2i);
    }
    let _e393 = phi_5035_;
    if _e393 {
        let _e394 = V_8;
        let _e396 = (*N_11);
        V_8 = reflect(-(_e394), _e396);
    }
    let _e398 = (*N_11);
    param_176 = _e398;
    let _e399 = V_8;
    param_177 = _e399;
    let _e400 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_176), (&param_177));
    (*N_11) = _e400;
    let _e401 = (*N_11);
    let _e402 = V_8;
    NdotV_13 = clamp(dot(_e401, _e402), 0.00000001f, 1f);
    let _e405 = (*color0_1);
    safeColor0_ = max(_e405, vec3(0f));
    let _e408 = (*color82_);
    safeColor82_ = max(_e408, vec3(0f));
    let _e411 = (*color90_1);
    safeColor90_ = max(_e411, vec3(0f));
    let _e414 = safeColor0_;
    param_178 = _e414;
    let _e415 = safeColor82_;
    param_179 = _e415;
    let _e416 = safeColor90_;
    param_180 = _e416;
    let _e417 = (*exponent_3);
    param_181 = _e417;
    let _e418 = (*thinfilm_thickness);
    param_182 = _e418;
    let _e419 = (*thinfilm_ior);
    param_183 = _e419;
    let _e420 = mx_init_fresnel_schlick_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_178), (&param_179), (&param_180), (&param_181), (&param_182), (&param_183));
    fd_8 = _e420;
    let _e421 = (*roughness_8);
    safeAlpha = clamp(_e421, vec2(0.00000001f), vec2(1f));
    let _e425 = safeAlpha;
    param_184 = _e425;
    let _e426 = mx_average_alpha_u0028_vf2_u003b((&param_184));
    avgAlpha_1 = _e426;
    let _e428 = (*closureData_14).closureType;
    if (_e428 == 1i) {
        let _e430 = (*X_2);
        let _e431 = (*X_2);
        let _e432 = (*N_11);
        let _e434 = (*N_11);
        (*X_2) = normalize((_e430 - (_e434 * dot(_e431, _e432))));
        let _e438 = (*N_11);
        let _e439 = (*X_2);
        Y_1 = cross(_e438, _e439);
        let _e441 = L_6;
        let _e442 = V_8;
        H_4 = normalize((_e441 + _e442));
        let _e445 = (*N_11);
        let _e446 = L_6;
        NdotL_7 = clamp(dot(_e445, _e446), 0.00000001f, 1f);
        let _e449 = V_8;
        let _e450 = H_4;
        VdotH_1 = clamp(dot(_e449, _e450), 0.00000001f, 1f);
        let _e453 = H_4;
        let _e454 = (*X_2);
        let _e456 = H_4;
        let _e457 = Y_1;
        let _e459 = H_4;
        let _e460 = (*N_11);
        Ht = vec3<f32>(dot(_e453, _e454), dot(_e456, _e457), dot(_e459, _e460));
        let _e463 = VdotH_1;
        param_185 = _e463;
        let _e464 = fd_8;
        param_186 = _e464;
        let _e465 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_185), (&param_186));
        F_1 = _e465;
        let _e466 = Ht;
        param_187 = _e466;
        let _e467 = safeAlpha;
        param_188 = _e467;
        let _e468 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_187), (&param_188));
        D = _e468;
        let _e469 = NdotL_7;
        param_189 = _e469;
        let _e470 = NdotV_13;
        param_190 = _e470;
        let _e471 = avgAlpha_1;
        param_191 = _e471;
        let _e472 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_189), (&param_190), (&param_191));
        G_2 = _e472;
        let _e473 = NdotV_13;
        param_192 = _e473;
        let _e474 = avgAlpha_1;
        param_193 = _e474;
        let _e475 = fd_8;
        param_194 = _e475;
        let _e476 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_192), (&param_193), (&param_194));
        comp = _e476;
        let _e477 = NdotV_13;
        param_195 = _e477;
        let _e478 = avgAlpha_1;
        param_196 = _e478;
        let _e479 = safeColor0_;
        param_197 = _e479;
        let _e480 = safeColor90_;
        param_198 = _e480;
        let _e481 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_195), (&param_196), (&param_197), (&param_198));
        let _e482 = comp;
        dirAlbedo_2 = (_e481 * _e482);
        let _e484 = dirAlbedo_2;
        avgDirAlbedo = dot(_e484, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
        let _e486 = avgDirAlbedo;
        let _e487 = (*weight_4);
        (*bsdf_3).throughput = vec3((1f - (_e486 * _e487)));
        let _e492 = D;
        let _e493 = F_1;
        let _e495 = G_2;
        let _e497 = comp;
        let _e500 = (*closureData_14).occlusion;
        let _e502 = (*weight_4);
        let _e504 = NdotV_13;
        (*bsdf_3).response = ((((((_e493 * _e492) * _e495) * _e497) * _e500) * _e502) / vec3((4f * _e504)));
    } else {
        let _e510 = (*closureData_14).closureType;
        if (_e510 == 2i) {
            let _e512 = NdotV_13;
            param_199 = _e512;
            let _e513 = avgAlpha_1;
            param_200 = _e513;
            let _e514 = fd_8;
            param_201 = _e514;
            let _e515 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_199), (&param_200), (&param_201));
            comp_1 = _e515;
            let _e516 = NdotV_13;
            param_202 = _e516;
            let _e517 = avgAlpha_1;
            param_203 = _e517;
            let _e518 = safeColor0_;
            param_204 = _e518;
            let _e519 = safeColor90_;
            param_205 = _e519;
            let _e520 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_202), (&param_203), (&param_204), (&param_205));
            let _e521 = comp_1;
            dirAlbedo_3 = (_e520 * _e521);
            let _e523 = dirAlbedo_3;
            avgDirAlbedo_1 = dot(_e523, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
            let _e525 = avgDirAlbedo_1;
            let _e526 = (*weight_4);
            (*bsdf_3).throughput = vec3((1f - (_e525 * _e526)));
            let _e531 = (*scatter_mode);
            if (_e531 != 0i) {
                let _e533 = safeColor0_;
                avgF0_ = dot(_e533, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e535 = avgF0_;
                param_206 = _e535;
                let _e536 = mx_f0_to_ior_u0028_f1_u003b((&param_206));
                fd_8.ior = vec3(_e536);
                let _e539 = (*N_11);
                param_207 = _e539;
                let _e540 = V_8;
                param_208 = _e540;
                let _e541 = (*X_2);
                param_209 = _e541;
                let _e542 = safeAlpha;
                param_210 = _e542;
                let _e543 = (*distribution_2);
                param_211 = _e543;
                let _e544 = fd_8;
                param_212 = _e544;
                param_213 = vec3<f32>(1f, 1f, 1f);
                let _e545 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_207), (&param_208), (&param_209), (&param_210), (&param_211), (&param_212), (&param_213));
                let _e546 = (*weight_4);
                (*bsdf_3).response = (_e545 * _e546);
            }
        } else {
            let _e550 = (*closureData_14).closureType;
            if (_e550 == 3i) {
                let _e552 = NdotV_13;
                param_214 = _e552;
                let _e553 = avgAlpha_1;
                param_215 = _e553;
                let _e554 = fd_8;
                param_216 = _e554;
                let _e555 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_214), (&param_215), (&param_216));
                comp_2 = _e555;
                let _e556 = NdotV_13;
                param_217 = _e556;
                let _e557 = avgAlpha_1;
                param_218 = _e557;
                let _e558 = safeColor0_;
                param_219 = _e558;
                let _e559 = safeColor90_;
                param_220 = _e559;
                let _e560 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_217), (&param_218), (&param_219), (&param_220));
                let _e561 = comp_2;
                dirAlbedo_4 = (_e560 * _e561);
                let _e563 = dirAlbedo_4;
                avgDirAlbedo_2 = dot(_e563, vec3<f32>(0.33333334f, 0.33333334f, 0.33333334f));
                let _e565 = avgDirAlbedo_2;
                let _e566 = (*weight_4);
                (*bsdf_3).throughput = vec3((1f - (_e565 * _e566)));
                let _e571 = (*N_11);
                param_221 = _e571;
                let _e572 = V_8;
                param_222 = _e572;
                let _e573 = (*X_2);
                param_223 = _e573;
                let _e574 = safeAlpha;
                param_224 = _e574;
                let _e575 = (*distribution_2);
                param_225 = _e575;
                let _e576 = fd_8;
                param_226 = _e576;
                let _e577 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_221), (&param_222), (&param_223), (&param_224), (&param_225), (&param_226));
                Li_4 = _e577;
                let _e578 = Li_4;
                let _e579 = comp_2;
                let _e581 = (*weight_4);
                (*bsdf_3).response = ((_e578 * _e579) * _e581);
            }
        }
    }
    return;
}

fn mx_ior_to_f0_u0028_f1_u003b(ior_3: ptr<function, f32>) -> f32 {
    var param_227: f32;

    let _e284 = (*ior_3);
    let _e286 = (*ior_3);
    param_227 = ((_e284 - 1f) / (_e286 + 1f));
    let _e289 = mx_square_u0028_f1_u003b((&param_227));
    return _e289;
}

fn mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b(ior_4: ptr<function, f32>, tf_thickness_1: ptr<function, f32>, tf_ior_1: ptr<function, f32>) -> FresnelData {
    var fd_9: FresnelData;

    fd_9.model = 0i;
    let _e287 = (*tf_thickness_1);
    fd_9.airy = (_e287 > 0f);
    let _e290 = (*ior_4);
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

fn mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_15: ptr<function, ClosureData>, weight_5: ptr<function, f32>, tint_2: ptr<function, vec3<f32>>, ior_5: ptr<function, f32>, roughness_9: ptr<function, vec2<f32>>, retroreflective_1: ptr<function, bool>, thinfilm_thickness_1: ptr<function, f32>, thinfilm_ior_1: ptr<function, f32>, N_12: ptr<function, vec3<f32>>, X_3: ptr<function, vec3<f32>>, distribution_3: ptr<function, i32>, scatter_mode_1: ptr<function, i32>, bsdf_4: ptr<function, BSDF>) {
    var V_9: vec3<f32>;
    var L_7: vec3<f32>;
    var param_228: vec3<f32>;
    var param_229: vec3<f32>;
    var NdotV_14: f32;
    var fd_10: FresnelData;
    var param_230: f32;
    var param_231: f32;
    var param_232: f32;
    var F0_8: f32;
    var param_233: f32;
    var safeAlpha_1: vec2<f32>;
    var avgAlpha_2: f32;
    var param_234: vec2<f32>;
    var safeTint: vec3<f32>;
    var Y_2: vec3<f32>;
    var H_5: vec3<f32>;
    var NdotL_8: f32;
    var VdotH_2: f32;
    var Ht_1: vec3<f32>;
    var F_2: vec3<f32>;
    var param_235: f32;
    var param_236: FresnelData;
    var D_1: f32;
    var param_237: vec3<f32>;
    var param_238: vec2<f32>;
    var G_3: f32;
    var param_239: f32;
    var param_240: f32;
    var param_241: f32;
    var comp_3: vec3<f32>;
    var param_242: f32;
    var param_243: f32;
    var param_244: FresnelData;
    var dirAlbedo_5: vec3<f32>;
    var param_245: f32;
    var param_246: f32;
    var param_247: f32;
    var param_248: f32;
    var comp_4: vec3<f32>;
    var param_249: f32;
    var param_250: f32;
    var param_251: FresnelData;
    var dirAlbedo_6: vec3<f32>;
    var param_252: f32;
    var param_253: f32;
    var param_254: f32;
    var param_255: f32;
    var param_256: vec3<f32>;
    var param_257: vec3<f32>;
    var param_258: vec3<f32>;
    var param_259: vec2<f32>;
    var param_260: i32;
    var param_261: FresnelData;
    var param_262: vec3<f32>;
    var comp_5: vec3<f32>;
    var param_263: f32;
    var param_264: f32;
    var param_265: FresnelData;
    var dirAlbedo_7: vec3<f32>;
    var param_266: f32;
    var param_267: f32;
    var param_268: f32;
    var param_269: f32;
    var Li_5: vec3<f32>;
    var param_270: vec3<f32>;
    var param_271: vec3<f32>;
    var param_272: vec3<f32>;
    var param_273: vec2<f32>;
    var param_274: i32;
    var param_275: FresnelData;
    var phi_4004_: bool;

    let _e366 = (*weight_5);
    if (_e366 < 0.00000001f) {
        return;
    }
    let _e369 = (*closureData_15).closureType;
    let _e371 = (*scatter_mode_1);
    if ((_e369 != 2i) && (_e371 == 1i)) {
        return;
    }
    let _e375 = (*closureData_15).V;
    V_9 = _e375;
    let _e377 = (*closureData_15).L;
    L_7 = _e377;
    let _e378 = (*retroreflective_1);
    phi_4004_ = _e378;
    if _e378 {
        let _e380 = (*closureData_15).closureType;
        phi_4004_ = (_e380 != 2i);
    }
    let _e383 = phi_4004_;
    if _e383 {
        let _e384 = V_9;
        let _e386 = (*N_12);
        V_9 = reflect(-(_e384), _e386);
    }
    let _e388 = (*N_12);
    param_228 = _e388;
    let _e389 = V_9;
    param_229 = _e389;
    let _e390 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_228), (&param_229));
    (*N_12) = _e390;
    let _e391 = (*N_12);
    let _e392 = V_9;
    NdotV_14 = clamp(dot(_e391, _e392), 0.00000001f, 1f);
    let _e395 = (*ior_5);
    param_230 = _e395;
    let _e396 = (*thinfilm_thickness_1);
    param_231 = _e396;
    let _e397 = (*thinfilm_ior_1);
    param_232 = _e397;
    let _e398 = mx_init_fresnel_dielectric_u0028_f1_u003b_f1_u003b_f1_u003b((&param_230), (&param_231), (&param_232));
    fd_10 = _e398;
    let _e399 = (*ior_5);
    param_233 = _e399;
    let _e400 = mx_ior_to_f0_u0028_f1_u003b((&param_233));
    F0_8 = _e400;
    let _e401 = (*roughness_9);
    safeAlpha_1 = clamp(_e401, vec2(0.00000001f), vec2(1f));
    let _e405 = safeAlpha_1;
    param_234 = _e405;
    let _e406 = mx_average_alpha_u0028_vf2_u003b((&param_234));
    avgAlpha_2 = _e406;
    let _e407 = (*tint_2);
    safeTint = max(_e407, vec3(0f));
    let _e411 = (*closureData_15).closureType;
    if (_e411 == 1i) {
        let _e413 = (*X_3);
        let _e414 = (*X_3);
        let _e415 = (*N_12);
        let _e417 = (*N_12);
        (*X_3) = normalize((_e413 - (_e417 * dot(_e414, _e415))));
        let _e421 = (*N_12);
        let _e422 = (*X_3);
        Y_2 = cross(_e421, _e422);
        let _e424 = L_7;
        let _e425 = V_9;
        H_5 = normalize((_e424 + _e425));
        let _e428 = (*N_12);
        let _e429 = L_7;
        NdotL_8 = clamp(dot(_e428, _e429), 0.00000001f, 1f);
        let _e432 = V_9;
        let _e433 = H_5;
        VdotH_2 = clamp(dot(_e432, _e433), 0.00000001f, 1f);
        let _e436 = H_5;
        let _e437 = (*X_3);
        let _e439 = H_5;
        let _e440 = Y_2;
        let _e442 = H_5;
        let _e443 = (*N_12);
        Ht_1 = vec3<f32>(dot(_e436, _e437), dot(_e439, _e440), dot(_e442, _e443));
        let _e446 = VdotH_2;
        param_235 = _e446;
        let _e447 = fd_10;
        param_236 = _e447;
        let _e448 = mx_compute_fresnel_u0028_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_235), (&param_236));
        F_2 = _e448;
        let _e449 = Ht_1;
        param_237 = _e449;
        let _e450 = safeAlpha_1;
        param_238 = _e450;
        let _e451 = mx_ggx_NDF_u0028_vf3_u003b_vf2_u003b((&param_237), (&param_238));
        D_1 = _e451;
        let _e452 = NdotL_8;
        param_239 = _e452;
        let _e453 = NdotV_14;
        param_240 = _e453;
        let _e454 = avgAlpha_2;
        param_241 = _e454;
        let _e455 = mx_ggx_smith_G2_u0028_f1_u003b_f1_u003b_f1_u003b((&param_239), (&param_240), (&param_241));
        G_3 = _e455;
        let _e456 = NdotV_14;
        param_242 = _e456;
        let _e457 = avgAlpha_2;
        param_243 = _e457;
        let _e458 = fd_10;
        param_244 = _e458;
        let _e459 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_242), (&param_243), (&param_244));
        comp_3 = _e459;
        let _e460 = NdotV_14;
        param_245 = _e460;
        let _e461 = avgAlpha_2;
        param_246 = _e461;
        let _e462 = F0_8;
        param_247 = _e462;
        param_248 = 1f;
        let _e463 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_245), (&param_246), (&param_247), (&param_248));
        let _e464 = comp_3;
        dirAlbedo_5 = (_e464 * _e463);
        let _e466 = dirAlbedo_5;
        let _e467 = (*weight_5);
        (*bsdf_4).throughput = (vec3(1f) - (_e466 * _e467));
        let _e472 = D_1;
        let _e473 = F_2;
        let _e475 = G_3;
        let _e477 = comp_3;
        let _e479 = safeTint;
        let _e482 = (*closureData_15).occlusion;
        let _e484 = (*weight_5);
        let _e486 = NdotV_14;
        (*bsdf_4).response = (((((((_e473 * _e472) * _e475) * _e477) * _e479) * _e482) * _e484) / vec3((4f * _e486)));
    } else {
        let _e492 = (*closureData_15).closureType;
        if (_e492 == 2i) {
            let _e494 = NdotV_14;
            param_249 = _e494;
            let _e495 = avgAlpha_2;
            param_250 = _e495;
            let _e496 = fd_10;
            param_251 = _e496;
            let _e497 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_249), (&param_250), (&param_251));
            comp_4 = _e497;
            let _e498 = NdotV_14;
            param_252 = _e498;
            let _e499 = avgAlpha_2;
            param_253 = _e499;
            let _e500 = F0_8;
            param_254 = _e500;
            param_255 = 1f;
            let _e501 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_252), (&param_253), (&param_254), (&param_255));
            let _e502 = comp_4;
            dirAlbedo_6 = (_e502 * _e501);
            let _e504 = dirAlbedo_6;
            let _e505 = (*weight_5);
            (*bsdf_4).throughput = (vec3(1f) - (_e504 * _e505));
            let _e510 = (*scatter_mode_1);
            if (_e510 != 0i) {
                let _e512 = (*N_12);
                param_256 = _e512;
                let _e513 = V_9;
                param_257 = _e513;
                let _e514 = (*X_3);
                param_258 = _e514;
                let _e515 = safeAlpha_1;
                param_259 = _e515;
                let _e516 = (*distribution_3);
                param_260 = _e516;
                let _e517 = fd_10;
                param_261 = _e517;
                let _e518 = safeTint;
                param_262 = _e518;
                let _e519 = mx_surface_transmission_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b_vf3_u003b((&param_256), (&param_257), (&param_258), (&param_259), (&param_260), (&param_261), (&param_262));
                let _e520 = (*weight_5);
                (*bsdf_4).response = (_e519 * _e520);
            }
        } else {
            let _e524 = (*closureData_15).closureType;
            if (_e524 == 3i) {
                let _e526 = NdotV_14;
                param_263 = _e526;
                let _e527 = avgAlpha_2;
                param_264 = _e527;
                let _e528 = fd_10;
                param_265 = _e528;
                let _e529 = mx_ggx_energy_compensation_u0028_f1_u003b_f1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_263), (&param_264), (&param_265));
                comp_5 = _e529;
                let _e530 = NdotV_14;
                param_266 = _e530;
                let _e531 = avgAlpha_2;
                param_267 = _e531;
                let _e532 = F0_8;
                param_268 = _e532;
                param_269 = 1f;
                let _e533 = mx_ggx_dir_albedo_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_266), (&param_267), (&param_268), (&param_269));
                let _e534 = comp_5;
                dirAlbedo_7 = (_e534 * _e533);
                let _e536 = dirAlbedo_7;
                let _e537 = (*weight_5);
                (*bsdf_4).throughput = (vec3(1f) - (_e536 * _e537));
                let _e542 = (*N_12);
                param_270 = _e542;
                let _e543 = V_9;
                param_271 = _e543;
                let _e544 = (*X_3);
                param_272 = _e544;
                let _e545 = safeAlpha_1;
                param_273 = _e545;
                let _e546 = (*distribution_3);
                param_274 = _e546;
                let _e547 = fd_10;
                param_275 = _e547;
                let _e548 = mx_environment_radiance_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b_struct_u002d_FresnelData_u002d_i1_u002d_b1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f1_u002d_f1_u002d_f1_u002d_b11_u003b((&param_270), (&param_271), (&param_272), (&param_273), (&param_274), (&param_275));
                Li_5 = _e548;
                let _e549 = Li_5;
                let _e550 = safeTint;
                let _e552 = comp_5;
                let _e554 = (*weight_5);
                (*bsdf_4).response = (((_e549 * _e550) * _e552) * _e554);
            }
        }
    }
    return;
}

fn mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(x_8: ptr<function, f32>, y_2: ptr<function, f32>) -> f32 {
    var s_3: f32;
    var m_4: f32;
    var o: f32;
    var param_276: f32;

    let _e288 = (*y_2);
    let _e289 = (*y_2);
    let _e293 = (*y_2);
    let _e294 = (*y_2);
    s_3 = ((_e288 * (0.0206607f + (1.58491f * _e289))) / (0.0379424f + (_e293 * (1.32227f + _e294))));
    let _e299 = (*y_2);
    let _e300 = (*y_2);
    let _e301 = (*y_2);
    let _e302 = (*y_2);
    let _e304 = (*y_2);
    let _e312 = (*y_2);
    m_4 = ((_e299 * (-0.193854f + (_e300 * (-1.14885f + (_e301 * (1.7932f - ((0.95943f * _e302) * _e304))))))) / (0.046391f + _e312));
    let _e315 = (*y_2);
    let _e316 = (*y_2);
    let _e319 = (*y_2);
    let _e323 = (*y_2);
    let _e324 = (*y_2);
    o = ((_e315 * (0.000654023f + ((-0.0207818f + (0.119681f * _e316)) * _e319))) / (1.26264f + (_e323 * (-1.92021f + _e324))));
    let _e329 = (*x_8);
    let _e330 = m_4;
    let _e332 = s_3;
    param_276 = ((_e329 - _e330) / _e332);
    let _e334 = mx_square_u0028_f1_u003b((&param_276));
    let _e337 = s_3;
    let _e340 = o;
    return ((exp((-0.5f * _e334)) / (_e337 * 2.5066283f)) + _e340);
}

fn mx_cosine_hemisphere_PDF_u0028_f1_u003b(cosTheta_12: ptr<function, f32>) -> f32 {
    let _e283 = (*cosTheta_12);
    return (max(_e283, 0f) * 0.31830987f);
}

fn mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b(x_9: ptr<function, f32>, y_3: ptr<function, f32>) -> f32 {
    let _e284 = (*x_9);
    let _e287 = (*y_3);
    let _e290 = (*y_3);
    let _e292 = (*y_3);
    let _e294 = (*y_3);
    let _e296 = (*x_9);
    let _e299 = (*x_9);
    let _e301 = (*y_3);
    let _e304 = (*y_3);
    let _e306 = (*y_3);
    return (((((sqrt((1f - _e284)) * (_e287 - 1f)) * _e290) * _e292) * _e294) / (((0.0000254053f + (1.71228f * _e296)) - ((1.71506f * _e299) * _e301)) + ((1.34174f * _e304) * _e306)));
}

fn mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b(x_10: ptr<function, f32>, y_4: ptr<function, f32>) -> f32 {
    let _e284 = (*x_10);
    let _e286 = (*y_4);
    let _e289 = (*y_4);
    let _e291 = (*x_10);
    let _e293 = (*x_10);
    let _e296 = (*x_10);
    let _e298 = (*y_4);
    return ((((2.58126f * _e284) + (0.813703f * _e286)) * _e289) / ((1f + ((0.310327f * _e291) * _e293)) + ((2.60994f * _e296) * _e298)));
}

fn mx_orthonormal_basis_u0028_vf3_u003b(N_13: ptr<function, vec3<f32>>) -> mat3x3<f32> {
    var sign_: f32;
    var a_3: f32;
    var b: f32;
    var X_4: vec3<f32>;
    var Y_3: vec3<f32>;

    let _e289 = (*N_13)[2u];
    sign_ = select(1f, -1f, (_e289 < 0f));
    let _e292 = sign_;
    let _e294 = (*N_13)[2u];
    a_3 = (-1f / (_e292 + _e294));
    let _e298 = (*N_13)[0u];
    let _e300 = (*N_13)[1u];
    let _e302 = a_3;
    b = ((_e298 * _e300) * _e302);
    let _e304 = sign_;
    let _e306 = (*N_13)[0u];
    let _e309 = (*N_13)[0u];
    let _e311 = a_3;
    let _e314 = sign_;
    let _e315 = b;
    let _e317 = sign_;
    let _e320 = (*N_13)[0u];
    X_4 = vec3<f32>((1f + (((_e304 * _e306) * _e309) * _e311)), (_e314 * _e315), (-(_e317) * _e320));
    let _e323 = b;
    let _e324 = sign_;
    let _e326 = (*N_13)[1u];
    let _e328 = (*N_13)[1u];
    let _e330 = a_3;
    let _e334 = (*N_13)[1u];
    Y_3 = vec3<f32>(_e323, (_e324 + ((_e326 * _e328) * _e330)), -(_e334));
    let _e337 = X_4;
    let _e338 = Y_3;
    let _e339 = (*N_13);
    return mat3x3<f32>(vec3<f32>(_e337.x, _e337.y, _e337.z), vec3<f32>(_e338.x, _e338.y, _e338.z), vec3<f32>(_e339.x, _e339.y, _e339.z));
}

fn mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b(V_10: ptr<function, vec3<f32>>, N_14: ptr<function, vec3<f32>>, NdotV_15: ptr<function, f32>) -> mat3x3<f32> {
    var X_5: vec3<f32>;
    var lenSqr: f32;
    var Y_4: vec3<f32>;
    var param_277: vec3<f32>;

    let _e289 = (*V_10);
    let _e290 = (*N_14);
    let _e291 = (*NdotV_15);
    X_5 = (_e289 - (_e290 * _e291));
    let _e294 = X_5;
    let _e295 = X_5;
    lenSqr = dot(_e294, _e295);
    let _e297 = lenSqr;
    if (_e297 > 0f) {
        let _e299 = lenSqr;
        let _e301 = X_5;
        X_5 = (_e301 * inverseSqrt(_e299));
        let _e303 = (*N_14);
        let _e304 = X_5;
        Y_4 = cross(_e303, _e304);
        let _e306 = X_5;
        let _e307 = Y_4;
        let _e308 = (*N_14);
        return mat3x3<f32>(vec3<f32>(_e306.x, _e306.y, _e306.z), vec3<f32>(_e307.x, _e307.y, _e307.z), vec3<f32>(_e308.x, _e308.y, _e308.z));
    }
    let _e322 = (*N_14);
    param_277 = _e322;
    let _e323 = mx_orthonormal_basis_u0028_vf3_u003b((&param_277));
    return _e323;
}

fn mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(L_8: ptr<function, vec3<f32>>, V_11: ptr<function, vec3<f32>>, N_15: ptr<function, vec3<f32>>, NdotV_16: ptr<function, f32>, roughness_10: ptr<function, f32>) -> f32 {
    var toLTC: mat3x3<f32>;
    var param_278: vec3<f32>;
    var param_279: vec3<f32>;
    var param_280: f32;
    var w: vec3<f32>;
    var param_281: mat3x3<f32>;
    var param_282: vec3<f32>;
    var aInv: f32;
    var param_283: f32;
    var param_284: f32;
    var bInv: f32;
    var param_285: f32;
    var param_286: f32;
    var wo: vec3<f32>;
    var lenSqr_1: f32;
    var param_287: f32;
    var param_288: f32;

    let _e304 = (*V_11);
    param_278 = _e304;
    let _e305 = (*N_15);
    param_279 = _e305;
    let _e306 = (*NdotV_16);
    param_280 = _e306;
    let _e307 = mx_orthonormal_basis_ltc_u0028_vf3_u003b_vf3_u003b_f1_u003b((&param_278), (&param_279), (&param_280));
    toLTC = transpose(_e307);
    let _e309 = toLTC;
    param_281 = _e309;
    let _e310 = (*L_8);
    param_282 = _e310;
    let _e311 = mx_matrix_mul_u0028_mf33_u003b_vf3_u003b((&param_281), (&param_282));
    w = _e311;
    let _e312 = (*NdotV_16);
    param_283 = _e312;
    let _e313 = (*roughness_10);
    param_284 = _e313;
    let _e314 = mx_zeltner_sheen_ltc_aInv_u0028_f1_u003b_f1_u003b((&param_283), (&param_284));
    aInv = _e314;
    let _e315 = (*NdotV_16);
    param_285 = _e315;
    let _e316 = (*roughness_10);
    param_286 = _e316;
    let _e317 = mx_zeltner_sheen_ltc_bInv_u0028_f1_u003b_f1_u003b((&param_285), (&param_286));
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
    param_287 = _e338;
    let _e339 = mx_cosine_hemisphere_PDF_u0028_f1_u003b((&param_287));
    let _e340 = aInv;
    let _e341 = lenSqr_1;
    param_288 = (_e340 / _e341);
    let _e343 = mx_square_u0028_f1_u003b((&param_288));
    return (_e339 * _e343);
}

fn mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b(NdotV_17: ptr<function, f32>, roughness_11: ptr<function, f32>) -> f32 {
    var r_2: vec2<f32>;
    var param_289: f32;
    var param_290: f32;

    let _e287 = (*NdotV_17);
    let _e290 = (*roughness_11);
    let _e293 = (*NdotV_17);
    let _e295 = (*roughness_11);
    let _e298 = (*NdotV_17);
    param_289 = _e298;
    let _e299 = mx_square_u0028_f1_u003b((&param_289));
    let _e302 = (*roughness_11);
    param_290 = _e302;
    let _e303 = mx_square_u0028_f1_u003b((&param_290));
    r_2 = (((((vec2<f32>(13.673f, 1f) + (vec2<f32>(-68.78018f, 61.57746f) * _e287)) + (vec2<f32>(799.08826f, 442.7821f) * _e290)) + ((vec2<f32>(-905.0006f, 2597.4932f) * _e293) * _e295)) + (vec2<f32>(60.28956f, 121.81241f) * _e299)) + (vec2<f32>(1086.9647f, 3045.5508f) * _e303));
    let _e307 = r_2[0u];
    let _e309 = r_2[1u];
    return (_e307 / _e309);
}

fn mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b(NdotV_18: ptr<function, f32>, roughness_12: ptr<function, f32>) -> f32 {
    var dirAlbedo_8: f32;
    var param_291: f32;
    var param_292: f32;

    let _e287 = (*NdotV_18);
    param_291 = _e287;
    let _e288 = (*roughness_12);
    param_292 = _e288;
    let _e289 = mx_imageworks_sheen_dir_albedo_analytic_u0028_f1_u003b_f1_u003b((&param_291), (&param_292));
    dirAlbedo_8 = _e289;
    let _e290 = dirAlbedo_8;
    return clamp(_e290, 0f, 1f);
}

fn mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b(NdotH: ptr<function, f32>, roughness_13: ptr<function, f32>) -> f32 {
    var invRoughness: f32;
    var cos2_: f32;
    var sin2_: f32;

    let _e287 = (*roughness_13);
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

fn mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b(NdotL_9: ptr<function, f32>, NdotV_19: ptr<function, f32>, NdotH_1: ptr<function, f32>, roughness_14: ptr<function, f32>) -> f32 {
    var D_2: f32;
    var param_293: f32;
    var param_294: f32;
    var F_3: f32;
    var G_4: f32;

    let _e291 = (*NdotH_1);
    param_293 = _e291;
    let _e292 = (*roughness_14);
    param_294 = _e292;
    let _e293 = mx_imageworks_sheen_NDF_u0028_f1_u003b_f1_u003b((&param_293), (&param_294));
    D_2 = _e293;
    F_3 = 1f;
    G_4 = 1f;
    let _e294 = D_2;
    let _e295 = F_3;
    let _e297 = G_4;
    let _e299 = (*NdotL_9);
    let _e300 = (*NdotV_19);
    let _e302 = (*NdotL_9);
    let _e303 = (*NdotV_19);
    return (((_e294 * _e295) * _e297) / (4f * ((_e299 + _e300) - (_e302 * _e303))));
}

fn mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b(closureData_16: ptr<function, ClosureData>, weight_6: ptr<function, f32>, color_6: ptr<function, vec3<f32>>, roughness_15: ptr<function, f32>, N_16: ptr<function, vec3<f32>>, mode: ptr<function, i32>, bsdf_5: ptr<function, BSDF>) {
    var V_12: vec3<f32>;
    var L_9: vec3<f32>;
    var param_295: vec3<f32>;
    var param_296: vec3<f32>;
    var NdotV_20: f32;
    var H_6: vec3<f32>;
    var NdotL_10: f32;
    var NdotH_2: f32;
    var fr: vec3<f32>;
    var param_297: f32;
    var param_298: f32;
    var param_299: f32;
    var param_300: f32;
    var dirAlbedo_9: f32;
    var param_301: f32;
    var param_302: f32;
    var fr_1: vec3<f32>;
    var param_303: vec3<f32>;
    var param_304: vec3<f32>;
    var param_305: vec3<f32>;
    var param_306: f32;
    var param_307: f32;
    var param_308: f32;
    var param_309: f32;
    var dirAlbedo_10: f32;
    var param_310: f32;
    var param_311: f32;
    var param_312: f32;
    var param_313: f32;
    var Li_6: vec3<f32>;
    var param_314: vec3<f32>;

    let _e320 = (*weight_6);
    if (_e320 < 0.00000001f) {
        return;
    }
    let _e323 = (*closureData_16).V;
    V_12 = _e323;
    let _e325 = (*closureData_16).L;
    L_9 = _e325;
    let _e326 = (*N_16);
    param_295 = _e326;
    let _e327 = V_12;
    param_296 = _e327;
    let _e328 = mx_forward_facing_normal_u0028_vf3_u003b_vf3_u003b((&param_295), (&param_296));
    (*N_16) = _e328;
    let _e329 = (*N_16);
    let _e330 = V_12;
    NdotV_20 = clamp(dot(_e329, _e330), 0.00000001f, 1f);
    let _e334 = (*closureData_16).closureType;
    if (_e334 == 1i) {
        let _e336 = (*mode);
        if (_e336 == 0i) {
            let _e338 = L_9;
            let _e339 = V_12;
            H_6 = normalize((_e338 + _e339));
            let _e342 = (*N_16);
            let _e343 = L_9;
            NdotL_10 = clamp(dot(_e342, _e343), 0.00000001f, 1f);
            let _e346 = (*N_16);
            let _e347 = H_6;
            NdotH_2 = clamp(dot(_e346, _e347), 0.00000001f, 1f);
            let _e350 = (*color_6);
            let _e351 = NdotL_10;
            param_297 = _e351;
            let _e352 = NdotV_20;
            param_298 = _e352;
            let _e353 = NdotH_2;
            param_299 = _e353;
            let _e354 = (*roughness_15);
            param_300 = _e354;
            let _e355 = mx_imageworks_sheen_brdf_u0028_f1_u003b_f1_u003b_f1_u003b_f1_u003b((&param_297), (&param_298), (&param_299), (&param_300));
            fr = (_e350 * _e355);
            let _e357 = NdotV_20;
            param_301 = _e357;
            let _e358 = (*roughness_15);
            param_302 = _e358;
            let _e359 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_301), (&param_302));
            dirAlbedo_9 = _e359;
            let _e360 = fr;
            let _e361 = NdotL_10;
            let _e364 = (*closureData_16).occlusion;
            let _e366 = (*weight_6);
            (*bsdf_5).response = (((_e360 * _e361) * _e364) * _e366);
        } else {
            let _e369 = (*roughness_15);
            (*roughness_15) = clamp(_e369, 0.01f, 1f);
            let _e371 = (*color_6);
            let _e372 = L_9;
            param_303 = _e372;
            let _e373 = V_12;
            param_304 = _e373;
            let _e374 = (*N_16);
            param_305 = _e374;
            let _e375 = NdotV_20;
            param_306 = _e375;
            let _e376 = (*roughness_15);
            param_307 = _e376;
            let _e377 = mx_zeltner_sheen_brdf_u0028_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b((&param_303), (&param_304), (&param_305), (&param_306), (&param_307));
            fr_1 = (_e371 * _e377);
            let _e379 = NdotV_20;
            param_308 = _e379;
            let _e380 = (*roughness_15);
            param_309 = _e380;
            let _e381 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_308), (&param_309));
            dirAlbedo_9 = _e381;
            let _e382 = dirAlbedo_9;
            let _e383 = fr_1;
            let _e386 = (*closureData_16).occlusion;
            let _e388 = (*weight_6);
            (*bsdf_5).response = (((_e383 * _e382) * _e386) * _e388);
        }
        let _e391 = dirAlbedo_9;
        let _e392 = (*weight_6);
        (*bsdf_5).throughput = vec3((1f - (_e391 * _e392)));
    } else {
        let _e398 = (*closureData_16).closureType;
        if (_e398 == 3i) {
            let _e400 = (*mode);
            if (_e400 == 0i) {
                let _e402 = NdotV_20;
                param_310 = _e402;
                let _e403 = (*roughness_15);
                param_311 = _e403;
                let _e404 = mx_imageworks_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_310), (&param_311));
                dirAlbedo_10 = _e404;
            } else {
                let _e405 = (*roughness_15);
                (*roughness_15) = clamp(_e405, 0.01f, 1f);
                let _e407 = NdotV_20;
                param_312 = _e407;
                let _e408 = (*roughness_15);
                param_313 = _e408;
                let _e409 = mx_zeltner_sheen_dir_albedo_u0028_f1_u003b_f1_u003b((&param_312), (&param_313));
                dirAlbedo_10 = _e409;
            }
            let _e410 = (*N_16);
            param_314 = _e410;
            let _e411 = mx_environment_irradiance_u0028_vf3_u003b((&param_314));
            Li_6 = _e411;
            let _e412 = Li_6;
            let _e413 = (*color_6);
            let _e415 = dirAlbedo_10;
            let _e417 = (*weight_6);
            (*bsdf_5).response = (((_e412 * _e413) * _e415) * _e417);
            let _e420 = dirAlbedo_10;
            let _e421 = (*weight_6);
            (*bsdf_5).throughput = vec3((1f - (_e420 * _e421)));
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

fn sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b(light: ptr<function, i32>, position: ptr<function, vec3<f32>>, result_10: ptr<function, lightshader>) {
    (*result_10).intensity = vec3<f32>(0f, 0f, 0f);
    (*result_10).direction = vec3<f32>(0f, 0f, 0f);
    return;
}

fn numActiveLightSources_u0028_() -> i32 {
    let _e283 = unnamed.mtlxLightCount;
    return min(_e283, 1i);
}

fn NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_4: ptr<function, vec3<f32>>, outx: ptr<function, f32>, outy: ptr<function, f32>, outz: ptr<function, f32>) {
    var N_extract_0_out: f32;
    var N_extract_1_out: f32;
    var N_extract_2_out: f32;

    let _e290 = (*in1_4)[0u];
    N_extract_0_out = _e290;
    let _e292 = (*in1_4)[1u];
    N_extract_1_out = _e292;
    let _e294 = (*in1_4)[2u];
    N_extract_2_out = _e294;
    let _e295 = N_extract_0_out;
    (*outx) = _e295;
    let _e296 = N_extract_1_out;
    (*outy) = _e296;
    let _e297 = N_extract_2_out;
    (*outz) = _e297;
    return;
}

fn NG_mincomponent_vector3_u0028_vf3_u003b_f1_u003b(in1_5: ptr<function, vec3<f32>>, mtlxRasterOut: ptr<function, f32>) {
    var N_separate_outx: f32;
    var N_separate_outy: f32;
    var N_separate_outz: f32;
    var param_315: vec3<f32>;
    var param_316: f32;
    var param_317: f32;
    var param_318: f32;
    var N_min_01_out: f32;
    var N_min_out: f32;

    N_separate_outx = 0f;
    N_separate_outy = 0f;
    N_separate_outz = 0f;
    let _e293 = (*in1_5);
    param_315 = _e293;
    NG_separate3_vector3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_315), (&param_316), (&param_317), (&param_318));
    let _e294 = param_316;
    N_separate_outx = _e294;
    let _e295 = param_317;
    N_separate_outy = _e295;
    let _e296 = param_318;
    N_separate_outz = _e296;
    let _e297 = N_separate_outx;
    let _e298 = N_separate_outy;
    N_min_01_out = min(_e297, _e298);
    let _e300 = N_min_01_out;
    let _e301 = N_separate_outz;
    N_min_out = min(_e300, _e301);
    let _e303 = N_min_out;
    (*mtlxRasterOut) = _e303;
    return;
}

fn NG_convert_float_color3_u0028_f1_u003b_vf3_u003b(in1_6: ptr<function, f32>, mtlxRasterOut_1: ptr<function, vec3<f32>>) {
    var combine_out: vec3<f32>;

    let _e285 = (*in1_6);
    combine_out = vec3(_e285);
    let _e287 = combine_out;
    (*mtlxRasterOut_1) = _e287;
    return;
}

fn NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b(in1_7: ptr<function, f32>, mtlxRasterOut_2: ptr<function, vec3<f32>>) {
    var combine_out_1: vec3<f32>;

    let _e285 = (*in1_7);
    combine_out_1 = vec3(_e285);
    let _e287 = combine_out_1;
    (*mtlxRasterOut_2) = _e287;
    return;
}

fn NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b(in1_8: ptr<function, vec3<f32>>, outr: ptr<function, f32>, outg: ptr<function, f32>, outb: ptr<function, f32>) {
    var N_extract_0_out_1: f32;
    var N_extract_1_out_1: f32;
    var N_extract_2_out_1: f32;

    let _e290 = (*in1_8)[0u];
    N_extract_0_out_1 = _e290;
    let _e292 = (*in1_8)[1u];
    N_extract_1_out_1 = _e292;
    let _e294 = (*in1_8)[2u];
    N_extract_2_out_1 = _e294;
    let _e295 = N_extract_0_out_1;
    (*outr) = _e295;
    let _e296 = N_extract_1_out_1;
    (*outg) = _e296;
    let _e297 = N_extract_2_out_1;
    (*outb) = _e297;
    return;
}

fn NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b(in1_9: ptr<function, vec3<f32>>, mtlxRasterOut_3: ptr<function, vec3<f32>>) {
    var separate_outr: f32;
    var separate_outg: f32;
    var separate_outb: f32;
    var param_319: vec3<f32>;
    var param_320: f32;
    var param_321: f32;
    var param_322: f32;
    var combine_out_2: vec3<f32>;

    separate_outr = 0f;
    separate_outg = 0f;
    separate_outb = 0f;
    let _e292 = (*in1_9);
    param_319 = _e292;
    NG_separate3_color3_u0028_vf3_u003b_f1_u003b_f1_u003b_f1_u003b((&param_319), (&param_320), (&param_321), (&param_322));
    let _e293 = param_320;
    separate_outr = _e293;
    let _e294 = param_321;
    separate_outg = _e294;
    let _e295 = param_322;
    separate_outb = _e295;
    let _e296 = separate_outr;
    let _e297 = separate_outg;
    let _e298 = separate_outb;
    combine_out_2 = vec3<f32>(_e296, _e297, _e298);
    let _e300 = combine_out_2;
    (*mtlxRasterOut_3) = _e300;
    return;
}

fn NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b(roughness_16: ptr<function, f32>, anisotropy_2: ptr<function, f32>, mtlxRasterOut_4: ptr<function, vec2<f32>>) {
    var rough_sq_out: f32;
    var aniso_invert_out: f32;
    var aniso_invert_sq_out: f32;
    var denom_out: f32;
    var fraction_out: f32;
    var sqrt_out: f32;
    var alpha_x_out: f32;
    var alpha_y_out: f32;
    var result_out: vec2<f32>;

    let _e294 = (*roughness_16);
    let _e295 = (*roughness_16);
    rough_sq_out = (_e294 * _e295);
    let _e297 = (*anisotropy_2);
    aniso_invert_out = (1f - _e297);
    let _e299 = aniso_invert_out;
    let _e300 = aniso_invert_out;
    aniso_invert_sq_out = (_e299 * _e300);
    let _e302 = aniso_invert_sq_out;
    denom_out = (_e302 + 1f);
    let _e304 = denom_out;
    fraction_out = (2f / _e304);
    let _e306 = fraction_out;
    sqrt_out = sqrt(_e306);
    let _e308 = rough_sq_out;
    let _e309 = sqrt_out;
    alpha_x_out = (_e308 * _e309);
    let _e311 = aniso_invert_out;
    let _e312 = alpha_x_out;
    alpha_y_out = (_e311 * _e312);
    let _e314 = alpha_x_out;
    let _e315 = alpha_y_out;
    result_out = vec2<f32>(_e314, _e315);
    let _e317 = result_out;
    (*mtlxRasterOut_4) = _e317;
    return;
}

fn NG_open_pbr_surface_surfaceshader_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_b1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b(base_weight: ptr<function, f32>, base_color: ptr<function, vec3<f32>>, base_diffuse_roughness: ptr<function, f32>, base_metalness: ptr<function, f32>, specular_weight: ptr<function, f32>, specular_color: ptr<function, vec3<f32>>, specular_roughness: ptr<function, f32>, specular_ior: ptr<function, f32>, specular_roughness_anisotropy: ptr<function, f32>, transmission_weight: ptr<function, f32>, transmission_color: ptr<function, vec3<f32>>, transmission_depth: ptr<function, f32>, transmission_scatter: ptr<function, vec3<f32>>, transmission_scatter_anisotropy: ptr<function, f32>, transmission_dispersion_scale: ptr<function, f32>, transmission_dispersion_abbe_number: ptr<function, f32>, subsurface_weight: ptr<function, f32>, subsurface_color: ptr<function, vec3<f32>>, subsurface_radius: ptr<function, f32>, subsurface_radius_scale: ptr<function, vec3<f32>>, subsurface_scatter_anisotropy: ptr<function, f32>, fuzz_weight: ptr<function, f32>, fuzz_color: ptr<function, vec3<f32>>, fuzz_roughness: ptr<function, f32>, coat_weight: ptr<function, f32>, coat_color: ptr<function, vec3<f32>>, coat_roughness: ptr<function, f32>, coat_roughness_anisotropy: ptr<function, f32>, coat_ior: ptr<function, f32>, coat_darkening: ptr<function, f32>, thin_film_weight: ptr<function, f32>, thin_film_thickness: ptr<function, f32>, thin_film_ior: ptr<function, f32>, emission_luminance: ptr<function, f32>, emission_color: ptr<function, vec3<f32>>, geometry_opacity: ptr<function, f32>, geometry_thin_walled: ptr<function, bool>, geometry_normal: ptr<function, vec3<f32>>, geometry_coat_normal: ptr<function, vec3<f32>>, geometry_tangent: ptr<function, vec3<f32>>, geometry_coat_tangent: ptr<function, vec3<f32>>, mtlxRasterOut_5: ptr<function, surfaceshader>) {
    var coat_roughness_vector_out: vec2<f32>;
    var param_323: f32;
    var param_324: f32;
    var param_325: vec2<f32>;
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
    var param_326: vec3<f32>;
    var param_327: vec3<f32>;
    var transmission_depth_vector_out: vec3<f32>;
    var param_328: f32;
    var param_329: vec3<f32>;
    var transmission_scatter_vector_out: vec3<f32>;
    var param_330: vec3<f32>;
    var param_331: vec3<f32>;
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
    var param_332: f32;
    var param_333: vec3<f32>;
    var effective_specular_roughness_out: f32;
    var specular_F0_out: f32;
    var absorption_coeff_min_out: f32;
    var param_334: vec3<f32>;
    var param_335: f32;
    var Kcoat_out: f32;
    var main_roughness_out: vec2<f32>;
    var param_336: f32;
    var param_337: f32;
    var param_338: vec2<f32>;
    var scaled_specular_F0_out: f32;
    var absorption_coeff_min_vector_out: vec3<f32>;
    var param_339: f32;
    var param_340: vec3<f32>;
    var one_minus_Kcoat_out: f32;
    var Ebase_Kcoat_out: vec3<f32>;
    var scaled_specular_F0_clamped_out: f32;
    var absorption_coeff_shifted_out: vec3<f32>;
    var one_minus_Kcoat_color_out: vec3<f32>;
    var param_341: f32;
    var param_342: vec3<f32>;
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
    var P_3: vec3<f32>;
    var L_11: vec3<f32>;
    var occlusion_2: f32;
    var surfaceOpacity: f32;
    var numLights: i32;
    var activeLightIndex: i32;
    var lightShader: lightshader;
    var param_343: i32;
    var param_344: vec3<f32>;
    var param_345: lightshader;
    var closureData_17: ClosureData;
    var param_346: i32;
    var param_347: vec3<f32>;
    var param_348: vec3<f32>;
    var param_349: vec3<f32>;
    var param_350: vec3<f32>;
    var param_351: f32;
    var fuzz_bsdf_out: BSDF;
    var param_352: ClosureData;
    var param_353: f32;
    var param_354: vec3<f32>;
    var param_355: f32;
    var param_356: vec3<f32>;
    var param_357: i32;
    var param_358: BSDF;
    var coat_bsdf_out: BSDF;
    var param_359: ClosureData;
    var param_360: f32;
    var param_361: vec3<f32>;
    var param_362: f32;
    var param_363: vec2<f32>;
    var param_364: bool;
    var param_365: f32;
    var param_366: f32;
    var param_367: vec3<f32>;
    var param_368: vec3<f32>;
    var param_369: i32;
    var param_370: i32;
    var param_371: BSDF;
    var metal_bsdf_tf_out: BSDF;
    var param_372: ClosureData;
    var param_373: f32;
    var param_374: vec3<f32>;
    var param_375: vec3<f32>;
    var param_376: vec3<f32>;
    var param_377: f32;
    var param_378: vec2<f32>;
    var param_379: bool;
    var param_380: f32;
    var param_381: f32;
    var param_382: vec3<f32>;
    var param_383: vec3<f32>;
    var param_384: i32;
    var param_385: i32;
    var param_386: BSDF;
    var metal_bsdf_out: BSDF;
    var param_387: ClosureData;
    var param_388: f32;
    var param_389: vec3<f32>;
    var param_390: vec3<f32>;
    var param_391: vec3<f32>;
    var param_392: f32;
    var param_393: vec2<f32>;
    var param_394: bool;
    var param_395: f32;
    var param_396: f32;
    var param_397: vec3<f32>;
    var param_398: vec3<f32>;
    var param_399: i32;
    var param_400: i32;
    var param_401: BSDF;
    var metal_bsdf_tf_mix_add_out: BSDF;
    var param_402: ClosureData;
    var param_403: BSDF;
    var param_404: BSDF;
    var param_405: BSDF;
    var base_substrate_fg_mul_out: BSDF;
    var param_406: ClosureData;
    var param_407: BSDF;
    var param_408: f32;
    var param_409: BSDF;
    var dielectric_reflection_tf_out: BSDF;
    var param_410: ClosureData;
    var param_411: f32;
    var param_412: vec3<f32>;
    var param_413: f32;
    var param_414: vec2<f32>;
    var param_415: bool;
    var param_416: f32;
    var param_417: f32;
    var param_418: vec3<f32>;
    var param_419: vec3<f32>;
    var param_420: i32;
    var param_421: i32;
    var param_422: BSDF;
    var dielectric_reflection_out: BSDF;
    var param_423: ClosureData;
    var param_424: f32;
    var param_425: vec3<f32>;
    var param_426: f32;
    var param_427: vec2<f32>;
    var param_428: bool;
    var param_429: f32;
    var param_430: f32;
    var param_431: vec3<f32>;
    var param_432: vec3<f32>;
    var param_433: i32;
    var param_434: i32;
    var param_435: BSDF;
    var dielectric_reflection_tf_mix_add_out: BSDF;
    var param_436: ClosureData;
    var param_437: BSDF;
    var param_438: BSDF;
    var param_439: BSDF;
    var dielectric_transmission_out: BSDF;
    var param_440: ClosureData;
    var param_441: f32;
    var param_442: vec3<f32>;
    var param_443: f32;
    var param_444: vec2<f32>;
    var param_445: bool;
    var param_446: f32;
    var param_447: f32;
    var param_448: vec3<f32>;
    var param_449: vec3<f32>;
    var param_450: i32;
    var param_451: i32;
    var param_452: BSDF;
    var dielectric_volume_out: VDF;
    var param_453: ClosureData;
    var param_454: vec3<f32>;
    var param_455: vec3<f32>;
    var param_456: f32;
    var param_457: VDF;
    var dielectric_volume_transmission_out: BSDF;
    var param_458: ClosureData;
    var param_459: BSDF;
    var param_460: VDF;
    var param_461: BSDF;
    var dielectric_substrate_fg_mul_out: BSDF;
    var param_462: ClosureData;
    var param_463: BSDF;
    var param_464: f32;
    var param_465: BSDF;
    var subsurface_thin_walled_reflection_bsdf_out: BSDF;
    var param_466: ClosureData;
    var param_467: f32;
    var param_468: vec3<f32>;
    var param_469: f32;
    var param_470: vec3<f32>;
    var param_471: bool;
    var param_472: BSDF;
    var subsurface_thin_walled_reflection_out: BSDF;
    var param_473: ClosureData;
    var param_474: BSDF;
    var param_475: vec3<f32>;
    var param_476: BSDF;
    var subsurface_thin_walled_transmission_bsdf_out: BSDF;
    var param_477: ClosureData;
    var param_478: f32;
    var param_479: vec3<f32>;
    var param_480: vec3<f32>;
    var param_481: BSDF;
    var subsurface_thin_walled_transmission_out: BSDF;
    var param_482: ClosureData;
    var param_483: BSDF;
    var param_484: vec3<f32>;
    var param_485: BSDF;
    var subsurface_thin_walled_out: BSDF;
    var param_486: ClosureData;
    var param_487: BSDF;
    var param_488: BSDF;
    var param_489: f32;
    var param_490: BSDF;
    var selected_subsurface_fg_mul_out: BSDF;
    var param_491: ClosureData;
    var param_492: BSDF;
    var param_493: f32;
    var param_494: BSDF;
    var subsurface_bsdf_out: BSDF;
    var param_495: ClosureData;
    var param_496: f32;
    var param_497: vec3<f32>;
    var param_498: vec3<f32>;
    var param_499: f32;
    var param_500: vec3<f32>;
    var param_501: BSDF;
    var selected_subsurface_add_out: BSDF;
    var param_502: ClosureData;
    var param_503: BSDF;
    var param_504: BSDF;
    var param_505: BSDF;
    var opaque_base_fg_mul_out: BSDF;
    var param_506: ClosureData;
    var param_507: BSDF;
    var param_508: f32;
    var param_509: BSDF;
    var diffuse_bsdf_out: BSDF;
    var param_510: ClosureData;
    var param_511: f32;
    var param_512: vec3<f32>;
    var param_513: f32;
    var param_514: vec3<f32>;
    var param_515: bool;
    var param_516: BSDF;
    var opaque_base_add_out: BSDF;
    var param_517: ClosureData;
    var param_518: BSDF;
    var param_519: BSDF;
    var param_520: BSDF;
    var dielectric_substrate_bg_mul_out: BSDF;
    var param_521: ClosureData;
    var param_522: BSDF;
    var param_523: f32;
    var param_524: BSDF;
    var dielectric_substrate_add_out: BSDF;
    var param_525: ClosureData;
    var param_526: BSDF;
    var param_527: BSDF;
    var param_528: BSDF;
    var dielectric_base_out: BSDF;
    var param_529: ClosureData;
    var param_530: BSDF;
    var param_531: BSDF;
    var param_532: BSDF;
    var base_substrate_bg_mul_out: BSDF;
    var param_533: ClosureData;
    var param_534: BSDF;
    var param_535: f32;
    var param_536: BSDF;
    var base_substrate_add_out: BSDF;
    var param_537: ClosureData;
    var param_538: BSDF;
    var param_539: BSDF;
    var param_540: BSDF;
    var darkened_base_substrate_out: BSDF;
    var param_541: ClosureData;
    var param_542: BSDF;
    var param_543: vec3<f32>;
    var param_544: BSDF;
    var coat_substrate_attenuated_out: BSDF;
    var param_545: ClosureData;
    var param_546: BSDF;
    var param_547: vec3<f32>;
    var param_548: BSDF;
    var coat_layer_out: BSDF;
    var param_549: ClosureData;
    var param_550: BSDF;
    var param_551: BSDF;
    var param_552: BSDF;
    var fuzz_layer_out: BSDF;
    var param_553: ClosureData;
    var param_554: BSDF;
    var param_555: BSDF;
    var param_556: BSDF;
    var closureData_18: ClosureData;
    var param_557: i32;
    var param_558: vec3<f32>;
    var param_559: vec3<f32>;
    var param_560: vec3<f32>;
    var param_561: vec3<f32>;
    var param_562: f32;
    var fuzz_bsdf_out_1: BSDF;
    var param_563: ClosureData;
    var param_564: f32;
    var param_565: vec3<f32>;
    var param_566: f32;
    var param_567: vec3<f32>;
    var param_568: i32;
    var param_569: BSDF;
    var coat_bsdf_out_1: BSDF;
    var param_570: ClosureData;
    var param_571: f32;
    var param_572: vec3<f32>;
    var param_573: f32;
    var param_574: vec2<f32>;
    var param_575: bool;
    var param_576: f32;
    var param_577: f32;
    var param_578: vec3<f32>;
    var param_579: vec3<f32>;
    var param_580: i32;
    var param_581: i32;
    var param_582: BSDF;
    var metal_bsdf_tf_out_1: BSDF;
    var param_583: ClosureData;
    var param_584: f32;
    var param_585: vec3<f32>;
    var param_586: vec3<f32>;
    var param_587: vec3<f32>;
    var param_588: f32;
    var param_589: vec2<f32>;
    var param_590: bool;
    var param_591: f32;
    var param_592: f32;
    var param_593: vec3<f32>;
    var param_594: vec3<f32>;
    var param_595: i32;
    var param_596: i32;
    var param_597: BSDF;
    var metal_bsdf_out_1: BSDF;
    var param_598: ClosureData;
    var param_599: f32;
    var param_600: vec3<f32>;
    var param_601: vec3<f32>;
    var param_602: vec3<f32>;
    var param_603: f32;
    var param_604: vec2<f32>;
    var param_605: bool;
    var param_606: f32;
    var param_607: f32;
    var param_608: vec3<f32>;
    var param_609: vec3<f32>;
    var param_610: i32;
    var param_611: i32;
    var param_612: BSDF;
    var metal_bsdf_tf_mix_add_out_1: BSDF;
    var param_613: ClosureData;
    var param_614: BSDF;
    var param_615: BSDF;
    var param_616: BSDF;
    var base_substrate_fg_mul_out_1: BSDF;
    var param_617: ClosureData;
    var param_618: BSDF;
    var param_619: f32;
    var param_620: BSDF;
    var dielectric_reflection_tf_out_1: BSDF;
    var param_621: ClosureData;
    var param_622: f32;
    var param_623: vec3<f32>;
    var param_624: f32;
    var param_625: vec2<f32>;
    var param_626: bool;
    var param_627: f32;
    var param_628: f32;
    var param_629: vec3<f32>;
    var param_630: vec3<f32>;
    var param_631: i32;
    var param_632: i32;
    var param_633: BSDF;
    var dielectric_reflection_out_1: BSDF;
    var param_634: ClosureData;
    var param_635: f32;
    var param_636: vec3<f32>;
    var param_637: f32;
    var param_638: vec2<f32>;
    var param_639: bool;
    var param_640: f32;
    var param_641: f32;
    var param_642: vec3<f32>;
    var param_643: vec3<f32>;
    var param_644: i32;
    var param_645: i32;
    var param_646: BSDF;
    var dielectric_reflection_tf_mix_add_out_1: BSDF;
    var param_647: ClosureData;
    var param_648: BSDF;
    var param_649: BSDF;
    var param_650: BSDF;
    var dielectric_transmission_out_1: BSDF;
    var param_651: ClosureData;
    var param_652: f32;
    var param_653: vec3<f32>;
    var param_654: f32;
    var param_655: vec2<f32>;
    var param_656: bool;
    var param_657: f32;
    var param_658: f32;
    var param_659: vec3<f32>;
    var param_660: vec3<f32>;
    var param_661: i32;
    var param_662: i32;
    var param_663: BSDF;
    var dielectric_volume_out_1: VDF;
    var param_664: ClosureData;
    var param_665: vec3<f32>;
    var param_666: vec3<f32>;
    var param_667: f32;
    var param_668: VDF;
    var dielectric_volume_transmission_out_1: BSDF;
    var param_669: ClosureData;
    var param_670: BSDF;
    var param_671: VDF;
    var param_672: BSDF;
    var dielectric_substrate_fg_mul_out_1: BSDF;
    var param_673: ClosureData;
    var param_674: BSDF;
    var param_675: f32;
    var param_676: BSDF;
    var subsurface_thin_walled_reflection_bsdf_out_1: BSDF;
    var param_677: ClosureData;
    var param_678: f32;
    var param_679: vec3<f32>;
    var param_680: f32;
    var param_681: vec3<f32>;
    var param_682: bool;
    var param_683: BSDF;
    var subsurface_thin_walled_reflection_out_1: BSDF;
    var param_684: ClosureData;
    var param_685: BSDF;
    var param_686: vec3<f32>;
    var param_687: BSDF;
    var subsurface_thin_walled_transmission_bsdf_out_1: BSDF;
    var param_688: ClosureData;
    var param_689: f32;
    var param_690: vec3<f32>;
    var param_691: vec3<f32>;
    var param_692: BSDF;
    var subsurface_thin_walled_transmission_out_1: BSDF;
    var param_693: ClosureData;
    var param_694: BSDF;
    var param_695: vec3<f32>;
    var param_696: BSDF;
    var subsurface_thin_walled_out_1: BSDF;
    var param_697: ClosureData;
    var param_698: BSDF;
    var param_699: BSDF;
    var param_700: f32;
    var param_701: BSDF;
    var selected_subsurface_fg_mul_out_1: BSDF;
    var param_702: ClosureData;
    var param_703: BSDF;
    var param_704: f32;
    var param_705: BSDF;
    var subsurface_bsdf_out_1: BSDF;
    var param_706: ClosureData;
    var param_707: f32;
    var param_708: vec3<f32>;
    var param_709: vec3<f32>;
    var param_710: f32;
    var param_711: vec3<f32>;
    var param_712: BSDF;
    var selected_subsurface_add_out_1: BSDF;
    var param_713: ClosureData;
    var param_714: BSDF;
    var param_715: BSDF;
    var param_716: BSDF;
    var opaque_base_fg_mul_out_1: BSDF;
    var param_717: ClosureData;
    var param_718: BSDF;
    var param_719: f32;
    var param_720: BSDF;
    var diffuse_bsdf_out_1: BSDF;
    var param_721: ClosureData;
    var param_722: f32;
    var param_723: vec3<f32>;
    var param_724: f32;
    var param_725: vec3<f32>;
    var param_726: bool;
    var param_727: BSDF;
    var opaque_base_add_out_1: BSDF;
    var param_728: ClosureData;
    var param_729: BSDF;
    var param_730: BSDF;
    var param_731: BSDF;
    var dielectric_substrate_bg_mul_out_1: BSDF;
    var param_732: ClosureData;
    var param_733: BSDF;
    var param_734: f32;
    var param_735: BSDF;
    var dielectric_substrate_add_out_1: BSDF;
    var param_736: ClosureData;
    var param_737: BSDF;
    var param_738: BSDF;
    var param_739: BSDF;
    var dielectric_base_out_1: BSDF;
    var param_740: ClosureData;
    var param_741: BSDF;
    var param_742: BSDF;
    var param_743: BSDF;
    var base_substrate_bg_mul_out_1: BSDF;
    var param_744: ClosureData;
    var param_745: BSDF;
    var param_746: f32;
    var param_747: BSDF;
    var base_substrate_add_out_1: BSDF;
    var param_748: ClosureData;
    var param_749: BSDF;
    var param_750: BSDF;
    var param_751: BSDF;
    var darkened_base_substrate_out_1: BSDF;
    var param_752: ClosureData;
    var param_753: BSDF;
    var param_754: vec3<f32>;
    var param_755: BSDF;
    var coat_substrate_attenuated_out_1: BSDF;
    var param_756: ClosureData;
    var param_757: BSDF;
    var param_758: vec3<f32>;
    var param_759: BSDF;
    var coat_layer_out_1: BSDF;
    var param_760: ClosureData;
    var param_761: BSDF;
    var param_762: BSDF;
    var param_763: BSDF;
    var fuzz_layer_out_1: BSDF;
    var param_764: ClosureData;
    var param_765: BSDF;
    var param_766: BSDF;
    var param_767: BSDF;
    var closureData_19: ClosureData;
    var param_768: i32;
    var param_769: vec3<f32>;
    var param_770: vec3<f32>;
    var param_771: vec3<f32>;
    var param_772: vec3<f32>;
    var param_773: f32;
    var uncoated_emission_edf_out: vec3<f32>;
    var param_774: ClosureData;
    var param_775: vec3<f32>;
    var param_776: vec3<f32>;
    var coat_tinted_emission_edf_out: vec3<f32>;
    var param_777: ClosureData;
    var param_778: vec3<f32>;
    var param_779: vec3<f32>;
    var param_780: vec3<f32>;
    var coated_emission_edf_out: vec3<f32>;
    var param_781: ClosureData;
    var param_782: vec3<f32>;
    var param_783: vec3<f32>;
    var param_784: f32;
    var param_785: vec3<f32>;
    var param_786: vec3<f32>;
    var emission_edf_out: vec3<f32>;
    var param_787: ClosureData;
    var param_788: vec3<f32>;
    var param_789: vec3<f32>;
    var param_790: f32;
    var param_791: vec3<f32>;
    var closureData_20: ClosureData;
    var param_792: i32;
    var param_793: vec3<f32>;
    var param_794: vec3<f32>;
    var param_795: vec3<f32>;
    var param_796: vec3<f32>;
    var param_797: f32;
    var fuzz_bsdf_out_2: BSDF;
    var param_798: ClosureData;
    var param_799: f32;
    var param_800: vec3<f32>;
    var param_801: f32;
    var param_802: vec3<f32>;
    var param_803: i32;
    var param_804: BSDF;
    var coat_bsdf_out_2: BSDF;
    var param_805: ClosureData;
    var param_806: f32;
    var param_807: vec3<f32>;
    var param_808: f32;
    var param_809: vec2<f32>;
    var param_810: bool;
    var param_811: f32;
    var param_812: f32;
    var param_813: vec3<f32>;
    var param_814: vec3<f32>;
    var param_815: i32;
    var param_816: i32;
    var param_817: BSDF;
    var metal_bsdf_tf_out_2: BSDF;
    var param_818: ClosureData;
    var param_819: f32;
    var param_820: vec3<f32>;
    var param_821: vec3<f32>;
    var param_822: vec3<f32>;
    var param_823: f32;
    var param_824: vec2<f32>;
    var param_825: bool;
    var param_826: f32;
    var param_827: f32;
    var param_828: vec3<f32>;
    var param_829: vec3<f32>;
    var param_830: i32;
    var param_831: i32;
    var param_832: BSDF;
    var metal_bsdf_out_2: BSDF;
    var param_833: ClosureData;
    var param_834: f32;
    var param_835: vec3<f32>;
    var param_836: vec3<f32>;
    var param_837: vec3<f32>;
    var param_838: f32;
    var param_839: vec2<f32>;
    var param_840: bool;
    var param_841: f32;
    var param_842: f32;
    var param_843: vec3<f32>;
    var param_844: vec3<f32>;
    var param_845: i32;
    var param_846: i32;
    var param_847: BSDF;
    var metal_bsdf_tf_mix_add_out_2: BSDF;
    var param_848: ClosureData;
    var param_849: BSDF;
    var param_850: BSDF;
    var param_851: BSDF;
    var base_substrate_fg_mul_out_2: BSDF;
    var param_852: ClosureData;
    var param_853: BSDF;
    var param_854: f32;
    var param_855: BSDF;
    var dielectric_reflection_tf_out_2: BSDF;
    var param_856: ClosureData;
    var param_857: f32;
    var param_858: vec3<f32>;
    var param_859: f32;
    var param_860: vec2<f32>;
    var param_861: bool;
    var param_862: f32;
    var param_863: f32;
    var param_864: vec3<f32>;
    var param_865: vec3<f32>;
    var param_866: i32;
    var param_867: i32;
    var param_868: BSDF;
    var dielectric_reflection_out_2: BSDF;
    var param_869: ClosureData;
    var param_870: f32;
    var param_871: vec3<f32>;
    var param_872: f32;
    var param_873: vec2<f32>;
    var param_874: bool;
    var param_875: f32;
    var param_876: f32;
    var param_877: vec3<f32>;
    var param_878: vec3<f32>;
    var param_879: i32;
    var param_880: i32;
    var param_881: BSDF;
    var dielectric_reflection_tf_mix_add_out_2: BSDF;
    var param_882: ClosureData;
    var param_883: BSDF;
    var param_884: BSDF;
    var param_885: BSDF;
    var dielectric_transmission_out_2: BSDF;
    var param_886: ClosureData;
    var param_887: f32;
    var param_888: vec3<f32>;
    var param_889: f32;
    var param_890: vec2<f32>;
    var param_891: bool;
    var param_892: f32;
    var param_893: f32;
    var param_894: vec3<f32>;
    var param_895: vec3<f32>;
    var param_896: i32;
    var param_897: i32;
    var param_898: BSDF;
    var dielectric_volume_out_2: VDF;
    var param_899: ClosureData;
    var param_900: vec3<f32>;
    var param_901: vec3<f32>;
    var param_902: f32;
    var param_903: VDF;
    var dielectric_volume_transmission_out_2: BSDF;
    var param_904: ClosureData;
    var param_905: BSDF;
    var param_906: VDF;
    var param_907: BSDF;
    var dielectric_substrate_fg_mul_out_2: BSDF;
    var param_908: ClosureData;
    var param_909: BSDF;
    var param_910: f32;
    var param_911: BSDF;
    var subsurface_thin_walled_reflection_bsdf_out_2: BSDF;
    var param_912: ClosureData;
    var param_913: f32;
    var param_914: vec3<f32>;
    var param_915: f32;
    var param_916: vec3<f32>;
    var param_917: bool;
    var param_918: BSDF;
    var subsurface_thin_walled_reflection_out_2: BSDF;
    var param_919: ClosureData;
    var param_920: BSDF;
    var param_921: vec3<f32>;
    var param_922: BSDF;
    var subsurface_thin_walled_transmission_bsdf_out_2: BSDF;
    var param_923: ClosureData;
    var param_924: f32;
    var param_925: vec3<f32>;
    var param_926: vec3<f32>;
    var param_927: BSDF;
    var subsurface_thin_walled_transmission_out_2: BSDF;
    var param_928: ClosureData;
    var param_929: BSDF;
    var param_930: vec3<f32>;
    var param_931: BSDF;
    var subsurface_thin_walled_out_2: BSDF;
    var param_932: ClosureData;
    var param_933: BSDF;
    var param_934: BSDF;
    var param_935: f32;
    var param_936: BSDF;
    var selected_subsurface_fg_mul_out_2: BSDF;
    var param_937: ClosureData;
    var param_938: BSDF;
    var param_939: f32;
    var param_940: BSDF;
    var subsurface_bsdf_out_2: BSDF;
    var param_941: ClosureData;
    var param_942: f32;
    var param_943: vec3<f32>;
    var param_944: vec3<f32>;
    var param_945: f32;
    var param_946: vec3<f32>;
    var param_947: BSDF;
    var selected_subsurface_add_out_2: BSDF;
    var param_948: ClosureData;
    var param_949: BSDF;
    var param_950: BSDF;
    var param_951: BSDF;
    var opaque_base_fg_mul_out_2: BSDF;
    var param_952: ClosureData;
    var param_953: BSDF;
    var param_954: f32;
    var param_955: BSDF;
    var diffuse_bsdf_out_2: BSDF;
    var param_956: ClosureData;
    var param_957: f32;
    var param_958: vec3<f32>;
    var param_959: f32;
    var param_960: vec3<f32>;
    var param_961: bool;
    var param_962: BSDF;
    var opaque_base_add_out_2: BSDF;
    var param_963: ClosureData;
    var param_964: BSDF;
    var param_965: BSDF;
    var param_966: BSDF;
    var dielectric_substrate_bg_mul_out_2: BSDF;
    var param_967: ClosureData;
    var param_968: BSDF;
    var param_969: f32;
    var param_970: BSDF;
    var dielectric_substrate_add_out_2: BSDF;
    var param_971: ClosureData;
    var param_972: BSDF;
    var param_973: BSDF;
    var param_974: BSDF;
    var dielectric_base_out_2: BSDF;
    var param_975: ClosureData;
    var param_976: BSDF;
    var param_977: BSDF;
    var param_978: BSDF;
    var base_substrate_bg_mul_out_2: BSDF;
    var param_979: ClosureData;
    var param_980: BSDF;
    var param_981: f32;
    var param_982: BSDF;
    var base_substrate_add_out_2: BSDF;
    var param_983: ClosureData;
    var param_984: BSDF;
    var param_985: BSDF;
    var param_986: BSDF;
    var darkened_base_substrate_out_2: BSDF;
    var param_987: ClosureData;
    var param_988: BSDF;
    var param_989: vec3<f32>;
    var param_990: BSDF;
    var coat_substrate_attenuated_out_2: BSDF;
    var param_991: ClosureData;
    var param_992: BSDF;
    var param_993: vec3<f32>;
    var param_994: BSDF;
    var coat_layer_out_2: BSDF;
    var param_995: ClosureData;
    var param_996: BSDF;
    var param_997: BSDF;
    var param_998: BSDF;
    var fuzz_layer_out_2: BSDF;
    var param_999: ClosureData;
    var param_1000: BSDF;
    var param_1001: BSDF;
    var param_1002: BSDF;

    coat_roughness_vector_out = vec2<f32>(0f, 0f);
    let _e1204 = (*coat_roughness);
    param_323 = _e1204;
    let _e1205 = (*coat_roughness_anisotropy);
    param_324 = _e1205;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_323), (&param_324), (&param_325));
    let _e1206 = param_325;
    coat_roughness_vector_out = _e1206;
    let _e1207 = (*specular_weight);
    let _e1208 = (*thin_film_weight);
    metal_bsdf_tf_mix_fg_weight_out = (_e1207 * _e1208);
    let _e1210 = (*base_color);
    let _e1211 = (*base_weight);
    metal_reflectivity_out = (_e1210 * _e1211);
    let _e1213 = (*coat_roughness);
    coat_roughness_to_power_4_out = pow(_e1213, 4f);
    let _e1215 = (*specular_roughness);
    specular_roughness_to_power_4_out = pow(_e1215, 4f);
    let _e1217 = (*thin_film_thickness);
    thin_film_thickness_nm_out = (_e1217 * 1000f);
    let _e1219 = (*thin_film_weight);
    metal_bsdf_tf_mix_mix_inv_out = (1f - _e1219);
    let _e1221 = (*thin_film_weight);
    dielectric_reflection_tf_mix_fg_weight_out = (1f * _e1221);
    let _e1223 = (*specular_ior);
    let _e1224 = (*coat_ior);
    specular_to_coat_ior_ratio_out = (_e1223 / _e1224);
    let _e1226 = (*coat_ior);
    let _e1227 = (*specular_ior);
    coat_to_specular_ior_ratio_out = (_e1226 / _e1227);
    let _e1229 = (*thin_film_weight);
    dielectric_reflection_tf_mix_mix_inv_out = (1f - _e1229);
    let _e1231 = (*transmission_depth);
    let _e1233 = (*transmission_color);
    if_transmission_tint_out = select(_e1233, vec3<f32>(1f, 1f, 1f), (_e1231 > 0f));
    transmission_color_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e1235 = (*transmission_color);
    param_326 = _e1235;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_326), (&param_327));
    let _e1236 = param_327;
    transmission_color_vector_out = _e1236;
    transmission_depth_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e1237 = (*transmission_depth);
    param_328 = _e1237;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_328), (&param_329));
    let _e1238 = param_329;
    transmission_depth_vector_out = _e1238;
    transmission_scatter_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e1239 = (*transmission_scatter);
    param_330 = _e1239;
    NG_convert_color3_vector3_u0028_vf3_u003b_vf3_u003b((&param_330), (&param_331));
    let _e1240 = param_331;
    transmission_scatter_vector_out = _e1240;
    let _e1241 = (*subsurface_color);
    subsurface_color_nonnegative_out = max(_e1241, vec3(0f));
    let _e1244 = (*subsurface_scatter_anisotropy);
    one_minus_subsurface_scatter_anisotropy_out = (1f - _e1244);
    let _e1246 = (*subsurface_scatter_anisotropy);
    one_plus_subsurface_scatter_anisotropy_out = (1f + _e1246);
    let _e1248 = (*geometry_thin_walled);
    subsurface_selector_out = select(0f, 1f, _e1248);
    let _e1250 = (*subsurface_radius_scale);
    let _e1251 = (*subsurface_radius);
    subsurface_radius_scaled_out = (_e1250 * _e1251);
    let _e1253 = (*subsurface_weight);
    opaque_base_mix_inv_out = (1f - _e1253);
    let _e1255 = (*base_color);
    base_color_nonnegative_out = max(_e1255, vec3(0f));
    let _e1258 = (*transmission_weight);
    dielectric_substrate_mix_inv_out = (1f - _e1258);
    let _e1260 = (*base_metalness);
    base_substrate_mix_inv_out = (1f - _e1260);
    let _e1262 = (*coat_ior);
    coat_ior_minus_one_out = (_e1262 - 1f);
    let _e1264 = (*coat_ior);
    coat_ior_plus_one_out = (1f + _e1264);
    let _e1266 = (*coat_ior);
    let _e1267 = (*coat_ior);
    coat_ior_sqr_out = (_e1266 * _e1267);
    let _e1269 = (*base_color);
    let _e1270 = (*specular_weight);
    Emetal_out = (_e1269 * _e1270);
    let _e1272 = (*base_color);
    let _e1273 = (*subsurface_color);
    let _e1274 = (*subsurface_weight);
    Edielectric_out = mix(_e1272, _e1273, vec3(_e1274));
    let _e1277 = (*coat_weight);
    let _e1278 = (*coat_darkening);
    coat_weight_times_coat_darkening_out = (_e1277 * _e1278);
    let _e1280 = (*coat_color);
    let _e1281 = (*coat_weight);
    coat_attenuation_out = mix(vec3<f32>(1f, 1f, 1f), _e1280, vec3(_e1281));
    let _e1284 = (*emission_color);
    let _e1285 = (*emission_luminance);
    emission_weight_out = (_e1284 * _e1285);
    let _e1287 = coat_roughness_to_power_4_out;
    two_times_coat_roughness_to_power_4_out = (_e1287 * 2f);
    let _e1289 = (*specular_weight);
    let _e1290 = metal_bsdf_tf_mix_mix_inv_out;
    metal_bsdf_tf_mix_bg_weight_out = (_e1289 * _e1290);
    let _e1292 = specular_to_coat_ior_ratio_out;
    let _e1294 = specular_to_coat_ior_ratio_out;
    let _e1295 = coat_to_specular_ior_ratio_out;
    specular_to_coat_ior_ratio_tir_fix_out = select(_e1295, _e1294, (_e1292 > 1f));
    let _e1297 = dielectric_reflection_tf_mix_mix_inv_out;
    dielectric_reflection_tf_mix_bg_weight_out = (1f * _e1297);
    let _e1299 = transmission_color_vector_out;
    transmission_color_ln_out = log(_e1299);
    let _e1301 = transmission_scatter_vector_out;
    let _e1302 = transmission_depth_vector_out;
    scattering_coeff_out = (_e1301 / _e1302);
    let _e1304 = (*subsurface_color);
    let _e1305 = one_minus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_brdf_factor_out = (_e1304 * _e1305);
    let _e1307 = (*subsurface_color);
    let _e1308 = one_plus_subsurface_scatter_anisotropy_out;
    subsurface_thin_walled_btdf_factor_out = (_e1307 * _e1308);
    let _e1310 = subsurface_selector_out;
    selected_subsurface_mix_inv_out = (1f - _e1310);
    let _e1312 = (*base_weight);
    let _e1313 = opaque_base_mix_inv_out;
    opaque_base_bg_weight_out = (_e1312 * _e1313);
    let _e1315 = coat_ior_minus_one_out;
    let _e1316 = coat_ior_plus_one_out;
    coat_ior_to_F0_sqrt_out = (_e1315 / _e1316);
    let _e1318 = Edielectric_out;
    let _e1319 = Emetal_out;
    let _e1320 = (*base_metalness);
    Ebase_out = mix(_e1318, _e1319, vec3(_e1320));
    let _e1323 = two_times_coat_roughness_to_power_4_out;
    let _e1324 = specular_roughness_to_power_4_out;
    add_coat_and_spec_roughnesses_to_power_4_out = (_e1323 + _e1324);
    let _e1326 = (*specular_ior);
    let _e1327 = specular_to_coat_ior_ratio_tir_fix_out;
    let _e1328 = (*coat_weight);
    eta_s_out = mix(_e1326, _e1327, _e1328);
    let _e1330 = transmission_color_ln_out;
    extinction_coeff_denom_out = (_e1330 * -1f);
    let _e1332 = (*transmission_depth);
    let _e1334 = scattering_coeff_out;
    if_volume_scattering_out = select(vec3<f32>(0f, 0f, 0f), _e1334, (_e1332 > 0f));
    let _e1336 = selected_subsurface_mix_inv_out;
    selected_subsurface_bg_weight_out = (1f * _e1336);
    let _e1338 = coat_ior_to_F0_sqrt_out;
    let _e1339 = coat_ior_to_F0_sqrt_out;
    coat_ior_to_F0_out = (_e1338 * _e1339);
    let _e1341 = add_coat_and_spec_roughnesses_to_power_4_out;
    min_1_add_coat_and_spec_roughnesses_to_power_4_out = min(1f, _e1341);
    let _e1343 = eta_s_out;
    eta_s_minus_one_out = (_e1343 - 1f);
    let _e1345 = eta_s_out;
    eta_s_plus_one_out = (_e1345 + 1f);
    let _e1347 = extinction_coeff_denom_out;
    let _e1348 = transmission_depth_vector_out;
    extinction_coeff_out = (_e1347 / _e1348);
    let _e1350 = coat_ior_to_F0_out;
    one_minus_coat_F0_out = (1f - _e1350);
    let _e1352 = min_1_add_coat_and_spec_roughnesses_to_power_4_out;
    coat_affected_specular_roughness_out = pow(_e1352, 0.25f);
    let _e1354 = eta_s_minus_one_out;
    sign_eta_s_minus_one_out = sign(_e1354);
    let _e1356 = eta_s_minus_one_out;
    let _e1357 = eta_s_plus_one_out;
    specular_F0_sqrt_out = (_e1356 / _e1357);
    let _e1359 = extinction_coeff_out;
    let _e1360 = scattering_coeff_out;
    absorption_coeff_out = (_e1359 - _e1360);
    let _e1362 = one_minus_coat_F0_out;
    let _e1363 = coat_ior_sqr_out;
    one_minus_coat_F0_over_eta2_out = (_e1362 / _e1363);
    one_minus_coat_F0_color_out = vec3<f32>(0f, 0f, 0f);
    let _e1365 = one_minus_coat_F0_out;
    param_332 = _e1365;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_332), (&param_333));
    let _e1366 = param_333;
    one_minus_coat_F0_color_out = _e1366;
    let _e1367 = (*specular_roughness);
    let _e1368 = coat_affected_specular_roughness_out;
    let _e1369 = (*coat_weight);
    effective_specular_roughness_out = mix(_e1367, _e1368, _e1369);
    let _e1371 = specular_F0_sqrt_out;
    let _e1372 = specular_F0_sqrt_out;
    specular_F0_out = (_e1371 * _e1372);
    absorption_coeff_min_out = 0f;
    let _e1374 = absorption_coeff_out;
    param_334 = _e1374;
    NG_mincomponent_vector3_u0028_vf3_u003b_f1_u003b((&param_334), (&param_335));
    let _e1375 = param_335;
    absorption_coeff_min_out = _e1375;
    let _e1376 = one_minus_coat_F0_over_eta2_out;
    Kcoat_out = (1f - _e1376);
    main_roughness_out = vec2<f32>(0f, 0f);
    let _e1378 = effective_specular_roughness_out;
    param_336 = _e1378;
    let _e1379 = (*specular_roughness_anisotropy);
    param_337 = _e1379;
    NG_open_pbr_anisotropy_u0028_f1_u003b_f1_u003b_vf2_u003b((&param_336), (&param_337), (&param_338));
    let _e1380 = param_338;
    main_roughness_out = _e1380;
    let _e1381 = (*specular_weight);
    let _e1382 = specular_F0_out;
    scaled_specular_F0_out = (_e1381 * _e1382);
    absorption_coeff_min_vector_out = vec3<f32>(0f, 0f, 0f);
    let _e1384 = absorption_coeff_min_out;
    param_339 = _e1384;
    NG_convert_float_vector3_u0028_f1_u003b_vf3_u003b((&param_339), (&param_340));
    let _e1385 = param_340;
    absorption_coeff_min_vector_out = _e1385;
    let _e1386 = Kcoat_out;
    one_minus_Kcoat_out = (1f - _e1386);
    let _e1388 = Ebase_out;
    let _e1389 = Kcoat_out;
    Ebase_Kcoat_out = (_e1388 * _e1389);
    let _e1391 = scaled_specular_F0_out;
    scaled_specular_F0_clamped_out = clamp(_e1391, 0f, 0.99999f);
    let _e1393 = absorption_coeff_out;
    let _e1394 = absorption_coeff_min_vector_out;
    absorption_coeff_shifted_out = (_e1393 - _e1394);
    one_minus_Kcoat_color_out = vec3<f32>(0f, 0f, 0f);
    let _e1396 = one_minus_Kcoat_out;
    param_341 = _e1396;
    NG_convert_float_color3_u0028_f1_u003b_vf3_u003b((&param_341), (&param_342));
    let _e1397 = param_342;
    one_minus_Kcoat_color_out = _e1397;
    let _e1398 = Ebase_Kcoat_out;
    one_minus_Ebase_Kcoat_out = (vec3<f32>(1f, 1f, 1f) - _e1398);
    let _e1400 = scaled_specular_F0_clamped_out;
    sqrt_scaled_specular_F0_out = sqrt(_e1400);
    let _e1402 = absorption_coeff_min_out;
    let _e1404 = absorption_coeff_shifted_out;
    let _e1405 = absorption_coeff_out;
    if_absorption_coeff_shifted_out = select(_e1405, _e1404, (0f > _e1402));
    let _e1407 = one_minus_Kcoat_color_out;
    let _e1408 = one_minus_Ebase_Kcoat_out;
    base_darkening_out = (_e1407 / _e1408);
    let _e1410 = sign_eta_s_minus_one_out;
    let _e1411 = sqrt_scaled_specular_F0_out;
    modulated_eta_s_epsilon_out = (_e1410 * _e1411);
    let _e1413 = (*transmission_depth);
    let _e1415 = if_absorption_coeff_shifted_out;
    if_volume_absorption_out = select(vec3<f32>(0f, 0f, 0f), _e1415, (_e1413 > 0f));
    let _e1417 = base_darkening_out;
    let _e1418 = coat_weight_times_coat_darkening_out;
    modulated_base_darkening_out = mix(vec3<f32>(1f, 1f, 1f), _e1417, vec3(_e1418));
    let _e1421 = modulated_eta_s_epsilon_out;
    one_plus_modulated_eta_s_epsilon_out = (1f + _e1421);
    let _e1423 = modulated_eta_s_epsilon_out;
    one_minus_modulated_eta_s_epsilon_out = (1f - _e1423);
    let _e1425 = one_plus_modulated_eta_s_epsilon_out;
    let _e1426 = one_minus_modulated_eta_s_epsilon_out;
    modulated_eta_s_out = (_e1425 / _e1426);
    shader_constructor_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e1428 = normalWorld;
    N_18 = normalize(_e1428);
    let _e1432 = unnamed.cameraWorldMatrix[3];
    let _e1434 = positionWorld;
    V_14 = normalize((_e1432.xyz - _e1434));
    let _e1437 = positionWorld;
    P_3 = _e1437;
    L_11 = vec3<f32>(0f, 0f, 0f);
    occlusion_2 = 1f;
    let _e1438 = (*geometry_opacity);
    surfaceOpacity = _e1438;
    let _e1439 = numActiveLightSources_u0028_();
    numLights = _e1439;
    activeLightIndex = 0i;
    loop {
        let _e1440 = activeLightIndex;
        let _e1441 = numLights;
        if (_e1440 < _e1441) {
            let _e1443 = activeLightIndex;
            let _e1446 = unnamed.u_lightData[_e1443];
            param_343 = _e1446;
            let _e1447 = positionWorld;
            param_344 = _e1447;
            sampleLightSource_u0028_i1_u003b_vf3_u003b_struct_u002d_lightshader_u002d_vf3_u002d_vf31_u003b((&param_343), (&param_344), (&param_345));
            let _e1448 = param_345;
            lightShader = _e1448;
            let _e1450 = lightShader.direction;
            L_11 = _e1450;
            param_346 = 1i;
            let _e1451 = L_11;
            param_347 = _e1451;
            let _e1452 = V_14;
            param_348 = _e1452;
            let _e1453 = N_18;
            param_349 = _e1453;
            let _e1454 = P_3;
            param_350 = _e1454;
            let _e1455 = occlusion_2;
            param_351 = _e1455;
            let _e1456 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_346), (&param_347), (&param_348), (&param_349), (&param_350), (&param_351));
            closureData_17 = _e1456;
            fuzz_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1457 = closureData_17;
            param_352 = _e1457;
            let _e1458 = (*fuzz_weight);
            param_353 = _e1458;
            let _e1459 = (*fuzz_color);
            param_354 = _e1459;
            let _e1460 = (*fuzz_roughness);
            param_355 = _e1460;
            let _e1461 = (*geometry_normal);
            param_356 = _e1461;
            param_357 = 1i;
            let _e1462 = fuzz_bsdf_out;
            param_358 = _e1462;
            mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_352), (&param_353), (&param_354), (&param_355), (&param_356), (&param_357), (&param_358));
            let _e1463 = param_358;
            fuzz_bsdf_out = _e1463;
            coat_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1464 = closureData_17;
            param_359 = _e1464;
            let _e1465 = (*coat_weight);
            param_360 = _e1465;
            param_361 = vec3<f32>(1f, 1f, 1f);
            let _e1466 = (*coat_ior);
            param_362 = _e1466;
            let _e1467 = coat_roughness_vector_out;
            param_363 = _e1467;
            param_364 = false;
            param_365 = 0f;
            param_366 = 1.5f;
            let _e1468 = (*geometry_coat_normal);
            param_367 = _e1468;
            let _e1469 = (*geometry_coat_tangent);
            param_368 = _e1469;
            param_369 = 0i;
            param_370 = 0i;
            let _e1470 = coat_bsdf_out;
            param_371 = _e1470;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_359), (&param_360), (&param_361), (&param_362), (&param_363), (&param_364), (&param_365), (&param_366), (&param_367), (&param_368), (&param_369), (&param_370), (&param_371));
            let _e1471 = param_371;
            coat_bsdf_out = _e1471;
            metal_bsdf_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1472 = closureData_17;
            param_372 = _e1472;
            let _e1473 = metal_bsdf_tf_mix_fg_weight_out;
            param_373 = _e1473;
            let _e1474 = metal_reflectivity_out;
            param_374 = _e1474;
            let _e1475 = (*specular_color);
            param_375 = _e1475;
            param_376 = vec3<f32>(1f, 1f, 1f);
            param_377 = 5f;
            let _e1476 = main_roughness_out;
            param_378 = _e1476;
            param_379 = false;
            let _e1477 = thin_film_thickness_nm_out;
            param_380 = _e1477;
            let _e1478 = (*thin_film_ior);
            param_381 = _e1478;
            let _e1479 = (*geometry_normal);
            param_382 = _e1479;
            let _e1480 = (*geometry_tangent);
            param_383 = _e1480;
            param_384 = 0i;
            param_385 = 0i;
            let _e1481 = metal_bsdf_tf_out;
            param_386 = _e1481;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_372), (&param_373), (&param_374), (&param_375), (&param_376), (&param_377), (&param_378), (&param_379), (&param_380), (&param_381), (&param_382), (&param_383), (&param_384), (&param_385), (&param_386));
            let _e1482 = param_386;
            metal_bsdf_tf_out = _e1482;
            metal_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1483 = closureData_17;
            param_387 = _e1483;
            let _e1484 = metal_bsdf_tf_mix_bg_weight_out;
            param_388 = _e1484;
            let _e1485 = metal_reflectivity_out;
            param_389 = _e1485;
            let _e1486 = (*specular_color);
            param_390 = _e1486;
            param_391 = vec3<f32>(1f, 1f, 1f);
            param_392 = 5f;
            let _e1487 = main_roughness_out;
            param_393 = _e1487;
            param_394 = false;
            param_395 = 0f;
            param_396 = 1.5f;
            let _e1488 = (*geometry_normal);
            param_397 = _e1488;
            let _e1489 = (*geometry_tangent);
            param_398 = _e1489;
            param_399 = 0i;
            param_400 = 0i;
            let _e1490 = metal_bsdf_out;
            param_401 = _e1490;
            mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_387), (&param_388), (&param_389), (&param_390), (&param_391), (&param_392), (&param_393), (&param_394), (&param_395), (&param_396), (&param_397), (&param_398), (&param_399), (&param_400), (&param_401));
            let _e1491 = param_401;
            metal_bsdf_out = _e1491;
            metal_bsdf_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1492 = closureData_17;
            param_402 = _e1492;
            let _e1493 = metal_bsdf_tf_out;
            param_403 = _e1493;
            let _e1494 = metal_bsdf_out;
            param_404 = _e1494;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_402), (&param_403), (&param_404), (&param_405));
            let _e1495 = param_405;
            metal_bsdf_tf_mix_add_out = _e1495;
            base_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1496 = closureData_17;
            param_406 = _e1496;
            let _e1497 = metal_bsdf_tf_mix_add_out;
            param_407 = _e1497;
            let _e1498 = (*base_metalness);
            param_408 = _e1498;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_406), (&param_407), (&param_408), (&param_409));
            let _e1499 = param_409;
            base_substrate_fg_mul_out = _e1499;
            dielectric_reflection_tf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1500 = closureData_17;
            param_410 = _e1500;
            let _e1501 = dielectric_reflection_tf_mix_fg_weight_out;
            param_411 = _e1501;
            let _e1502 = (*specular_color);
            param_412 = _e1502;
            let _e1503 = modulated_eta_s_out;
            param_413 = _e1503;
            let _e1504 = main_roughness_out;
            param_414 = _e1504;
            param_415 = false;
            let _e1505 = thin_film_thickness_nm_out;
            param_416 = _e1505;
            let _e1506 = (*thin_film_ior);
            param_417 = _e1506;
            let _e1507 = (*geometry_normal);
            param_418 = _e1507;
            let _e1508 = (*geometry_tangent);
            param_419 = _e1508;
            param_420 = 0i;
            param_421 = 0i;
            let _e1509 = dielectric_reflection_tf_out;
            param_422 = _e1509;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_410), (&param_411), (&param_412), (&param_413), (&param_414), (&param_415), (&param_416), (&param_417), (&param_418), (&param_419), (&param_420), (&param_421), (&param_422));
            let _e1510 = param_422;
            dielectric_reflection_tf_out = _e1510;
            dielectric_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1511 = closureData_17;
            param_423 = _e1511;
            let _e1512 = dielectric_reflection_tf_mix_bg_weight_out;
            param_424 = _e1512;
            let _e1513 = (*specular_color);
            param_425 = _e1513;
            let _e1514 = modulated_eta_s_out;
            param_426 = _e1514;
            let _e1515 = main_roughness_out;
            param_427 = _e1515;
            param_428 = false;
            param_429 = 0f;
            param_430 = 1.5f;
            let _e1516 = (*geometry_normal);
            param_431 = _e1516;
            let _e1517 = (*geometry_tangent);
            param_432 = _e1517;
            param_433 = 0i;
            param_434 = 0i;
            let _e1518 = dielectric_reflection_out;
            param_435 = _e1518;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_423), (&param_424), (&param_425), (&param_426), (&param_427), (&param_428), (&param_429), (&param_430), (&param_431), (&param_432), (&param_433), (&param_434), (&param_435));
            let _e1519 = param_435;
            dielectric_reflection_out = _e1519;
            dielectric_reflection_tf_mix_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1520 = closureData_17;
            param_436 = _e1520;
            let _e1521 = dielectric_reflection_tf_out;
            param_437 = _e1521;
            let _e1522 = dielectric_reflection_out;
            param_438 = _e1522;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_436), (&param_437), (&param_438), (&param_439));
            let _e1523 = param_439;
            dielectric_reflection_tf_mix_add_out = _e1523;
            dielectric_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1524 = closureData_17;
            param_440 = _e1524;
            param_441 = 1f;
            let _e1525 = if_transmission_tint_out;
            param_442 = _e1525;
            let _e1526 = modulated_eta_s_out;
            param_443 = _e1526;
            let _e1527 = main_roughness_out;
            param_444 = _e1527;
            param_445 = false;
            param_446 = 0f;
            param_447 = 1.5f;
            let _e1528 = (*geometry_normal);
            param_448 = _e1528;
            let _e1529 = (*geometry_tangent);
            param_449 = _e1529;
            param_450 = 0i;
            param_451 = 1i;
            let _e1530 = dielectric_transmission_out;
            param_452 = _e1530;
            mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_440), (&param_441), (&param_442), (&param_443), (&param_444), (&param_445), (&param_446), (&param_447), (&param_448), (&param_449), (&param_450), (&param_451), (&param_452));
            let _e1531 = param_452;
            dielectric_transmission_out = _e1531;
            dielectric_volume_out = VDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1532 = closureData_17;
            param_453 = _e1532;
            let _e1533 = if_volume_absorption_out;
            param_454 = _e1533;
            let _e1534 = if_volume_scattering_out;
            param_455 = _e1534;
            let _e1535 = (*transmission_scatter_anisotropy);
            param_456 = _e1535;
            let _e1536 = dielectric_volume_out;
            param_457 = _e1536;
            mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b((&param_453), (&param_454), (&param_455), (&param_456), (&param_457));
            let _e1537 = param_457;
            dielectric_volume_out = _e1537;
            dielectric_volume_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1538 = closureData_17;
            param_458 = _e1538;
            let _e1539 = dielectric_transmission_out;
            param_459 = _e1539;
            let _e1540 = dielectric_volume_out;
            param_460 = _e1540;
            mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_458), (&param_459), (&param_460), (&param_461));
            let _e1541 = param_461;
            dielectric_volume_transmission_out = _e1541;
            dielectric_substrate_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1542 = closureData_17;
            param_462 = _e1542;
            let _e1543 = dielectric_volume_transmission_out;
            param_463 = _e1543;
            let _e1544 = (*transmission_weight);
            param_464 = _e1544;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_462), (&param_463), (&param_464), (&param_465));
            let _e1545 = param_465;
            dielectric_substrate_fg_mul_out = _e1545;
            subsurface_thin_walled_reflection_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1546 = closureData_17;
            param_466 = _e1546;
            param_467 = 1f;
            let _e1547 = subsurface_color_nonnegative_out;
            param_468 = _e1547;
            let _e1548 = (*base_diffuse_roughness);
            param_469 = _e1548;
            let _e1549 = (*geometry_normal);
            param_470 = _e1549;
            param_471 = false;
            let _e1550 = subsurface_thin_walled_reflection_bsdf_out;
            param_472 = _e1550;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_466), (&param_467), (&param_468), (&param_469), (&param_470), (&param_471), (&param_472));
            let _e1551 = param_472;
            subsurface_thin_walled_reflection_bsdf_out = _e1551;
            subsurface_thin_walled_reflection_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1552 = closureData_17;
            param_473 = _e1552;
            let _e1553 = subsurface_thin_walled_reflection_bsdf_out;
            param_474 = _e1553;
            let _e1554 = subsurface_thin_walled_brdf_factor_out;
            param_475 = _e1554;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_473), (&param_474), (&param_475), (&param_476));
            let _e1555 = param_476;
            subsurface_thin_walled_reflection_out = _e1555;
            subsurface_thin_walled_transmission_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1556 = closureData_17;
            param_477 = _e1556;
            param_478 = 1f;
            let _e1557 = subsurface_color_nonnegative_out;
            param_479 = _e1557;
            let _e1558 = (*geometry_normal);
            param_480 = _e1558;
            let _e1559 = subsurface_thin_walled_transmission_bsdf_out;
            param_481 = _e1559;
            mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_477), (&param_478), (&param_479), (&param_480), (&param_481));
            let _e1560 = param_481;
            subsurface_thin_walled_transmission_bsdf_out = _e1560;
            subsurface_thin_walled_transmission_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1561 = closureData_17;
            param_482 = _e1561;
            let _e1562 = subsurface_thin_walled_transmission_bsdf_out;
            param_483 = _e1562;
            let _e1563 = subsurface_thin_walled_btdf_factor_out;
            param_484 = _e1563;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_482), (&param_483), (&param_484), (&param_485));
            let _e1564 = param_485;
            subsurface_thin_walled_transmission_out = _e1564;
            subsurface_thin_walled_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1565 = closureData_17;
            param_486 = _e1565;
            let _e1566 = subsurface_thin_walled_reflection_out;
            param_487 = _e1566;
            let _e1567 = subsurface_thin_walled_transmission_out;
            param_488 = _e1567;
            param_489 = 0.5f;
            mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_486), (&param_487), (&param_488), (&param_489), (&param_490));
            let _e1568 = param_490;
            subsurface_thin_walled_out = _e1568;
            selected_subsurface_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1569 = closureData_17;
            param_491 = _e1569;
            let _e1570 = subsurface_thin_walled_out;
            param_492 = _e1570;
            let _e1571 = subsurface_selector_out;
            param_493 = _e1571;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_491), (&param_492), (&param_493), (&param_494));
            let _e1572 = param_494;
            selected_subsurface_fg_mul_out = _e1572;
            subsurface_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1573 = closureData_17;
            param_495 = _e1573;
            let _e1574 = selected_subsurface_bg_weight_out;
            param_496 = _e1574;
            let _e1575 = subsurface_color_nonnegative_out;
            param_497 = _e1575;
            let _e1576 = subsurface_radius_scaled_out;
            param_498 = _e1576;
            let _e1577 = (*subsurface_scatter_anisotropy);
            param_499 = _e1577;
            let _e1578 = (*geometry_normal);
            param_500 = _e1578;
            let _e1579 = subsurface_bsdf_out;
            param_501 = _e1579;
            mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_495), (&param_496), (&param_497), (&param_498), (&param_499), (&param_500), (&param_501));
            let _e1580 = param_501;
            subsurface_bsdf_out = _e1580;
            selected_subsurface_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1581 = closureData_17;
            param_502 = _e1581;
            let _e1582 = selected_subsurface_fg_mul_out;
            param_503 = _e1582;
            let _e1583 = subsurface_bsdf_out;
            param_504 = _e1583;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_502), (&param_503), (&param_504), (&param_505));
            let _e1584 = param_505;
            selected_subsurface_add_out = _e1584;
            opaque_base_fg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1585 = closureData_17;
            param_506 = _e1585;
            let _e1586 = selected_subsurface_add_out;
            param_507 = _e1586;
            let _e1587 = (*subsurface_weight);
            param_508 = _e1587;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_506), (&param_507), (&param_508), (&param_509));
            let _e1588 = param_509;
            opaque_base_fg_mul_out = _e1588;
            diffuse_bsdf_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1589 = closureData_17;
            param_510 = _e1589;
            let _e1590 = opaque_base_bg_weight_out;
            param_511 = _e1590;
            let _e1591 = base_color_nonnegative_out;
            param_512 = _e1591;
            let _e1592 = (*base_diffuse_roughness);
            param_513 = _e1592;
            let _e1593 = (*geometry_normal);
            param_514 = _e1593;
            param_515 = true;
            let _e1594 = diffuse_bsdf_out;
            param_516 = _e1594;
            mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_510), (&param_511), (&param_512), (&param_513), (&param_514), (&param_515), (&param_516));
            let _e1595 = param_516;
            diffuse_bsdf_out = _e1595;
            opaque_base_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1596 = closureData_17;
            param_517 = _e1596;
            let _e1597 = opaque_base_fg_mul_out;
            param_518 = _e1597;
            let _e1598 = diffuse_bsdf_out;
            param_519 = _e1598;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_517), (&param_518), (&param_519), (&param_520));
            let _e1599 = param_520;
            opaque_base_add_out = _e1599;
            dielectric_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1600 = closureData_17;
            param_521 = _e1600;
            let _e1601 = opaque_base_add_out;
            param_522 = _e1601;
            let _e1602 = dielectric_substrate_mix_inv_out;
            param_523 = _e1602;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_521), (&param_522), (&param_523), (&param_524));
            let _e1603 = param_524;
            dielectric_substrate_bg_mul_out = _e1603;
            dielectric_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1604 = closureData_17;
            param_525 = _e1604;
            let _e1605 = dielectric_substrate_fg_mul_out;
            param_526 = _e1605;
            let _e1606 = dielectric_substrate_bg_mul_out;
            param_527 = _e1606;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_525), (&param_526), (&param_527), (&param_528));
            let _e1607 = param_528;
            dielectric_substrate_add_out = _e1607;
            dielectric_base_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1608 = closureData_17;
            param_529 = _e1608;
            let _e1609 = dielectric_reflection_tf_mix_add_out;
            param_530 = _e1609;
            let _e1610 = dielectric_substrate_add_out;
            param_531 = _e1610;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_529), (&param_530), (&param_531), (&param_532));
            let _e1611 = param_532;
            dielectric_base_out = _e1611;
            base_substrate_bg_mul_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1612 = closureData_17;
            param_533 = _e1612;
            let _e1613 = dielectric_base_out;
            param_534 = _e1613;
            let _e1614 = base_substrate_mix_inv_out;
            param_535 = _e1614;
            mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_533), (&param_534), (&param_535), (&param_536));
            let _e1615 = param_536;
            base_substrate_bg_mul_out = _e1615;
            base_substrate_add_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1616 = closureData_17;
            param_537 = _e1616;
            let _e1617 = base_substrate_fg_mul_out;
            param_538 = _e1617;
            let _e1618 = base_substrate_bg_mul_out;
            param_539 = _e1618;
            mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_537), (&param_538), (&param_539), (&param_540));
            let _e1619 = param_540;
            base_substrate_add_out = _e1619;
            darkened_base_substrate_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1620 = closureData_17;
            param_541 = _e1620;
            let _e1621 = base_substrate_add_out;
            param_542 = _e1621;
            let _e1622 = modulated_base_darkening_out;
            param_543 = _e1622;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_541), (&param_542), (&param_543), (&param_544));
            let _e1623 = param_544;
            darkened_base_substrate_out = _e1623;
            coat_substrate_attenuated_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1624 = closureData_17;
            param_545 = _e1624;
            let _e1625 = darkened_base_substrate_out;
            param_546 = _e1625;
            let _e1626 = coat_attenuation_out;
            param_547 = _e1626;
            mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_545), (&param_546), (&param_547), (&param_548));
            let _e1627 = param_548;
            coat_substrate_attenuated_out = _e1627;
            coat_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1628 = closureData_17;
            param_549 = _e1628;
            let _e1629 = coat_bsdf_out;
            param_550 = _e1629;
            let _e1630 = coat_substrate_attenuated_out;
            param_551 = _e1630;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_549), (&param_550), (&param_551), (&param_552));
            let _e1631 = param_552;
            coat_layer_out = _e1631;
            fuzz_layer_out = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
            let _e1632 = closureData_17;
            param_553 = _e1632;
            let _e1633 = fuzz_bsdf_out;
            param_554 = _e1633;
            let _e1634 = coat_layer_out;
            param_555 = _e1634;
            mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_553), (&param_554), (&param_555), (&param_556));
            let _e1635 = param_556;
            fuzz_layer_out = _e1635;
            let _e1637 = lightShader.intensity;
            let _e1639 = fuzz_layer_out.response;
            let _e1642 = shader_constructor_out.color;
            shader_constructor_out.color = (_e1642 + (_e1637 * _e1639));
            occlusion_2 = 1f;
            continue;
        } else {
            break;
        }
        continuing {
            let _e1645 = activeLightIndex;
            activeLightIndex = (_e1645 + 1i);
        }
    }
    occlusion_2 = 1f;
    param_557 = 3i;
    let _e1647 = L_11;
    param_558 = _e1647;
    let _e1648 = V_14;
    param_559 = _e1648;
    let _e1649 = N_18;
    param_560 = _e1649;
    let _e1650 = P_3;
    param_561 = _e1650;
    let _e1651 = occlusion_2;
    param_562 = _e1651;
    let _e1652 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_557), (&param_558), (&param_559), (&param_560), (&param_561), (&param_562));
    closureData_18 = _e1652;
    fuzz_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1653 = closureData_18;
    param_563 = _e1653;
    let _e1654 = (*fuzz_weight);
    param_564 = _e1654;
    let _e1655 = (*fuzz_color);
    param_565 = _e1655;
    let _e1656 = (*fuzz_roughness);
    param_566 = _e1656;
    let _e1657 = (*geometry_normal);
    param_567 = _e1657;
    param_568 = 1i;
    let _e1658 = fuzz_bsdf_out_1;
    param_569 = _e1658;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_563), (&param_564), (&param_565), (&param_566), (&param_567), (&param_568), (&param_569));
    let _e1659 = param_569;
    fuzz_bsdf_out_1 = _e1659;
    coat_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1660 = closureData_18;
    param_570 = _e1660;
    let _e1661 = (*coat_weight);
    param_571 = _e1661;
    param_572 = vec3<f32>(1f, 1f, 1f);
    let _e1662 = (*coat_ior);
    param_573 = _e1662;
    let _e1663 = coat_roughness_vector_out;
    param_574 = _e1663;
    param_575 = false;
    param_576 = 0f;
    param_577 = 1.5f;
    let _e1664 = (*geometry_coat_normal);
    param_578 = _e1664;
    let _e1665 = (*geometry_coat_tangent);
    param_579 = _e1665;
    param_580 = 0i;
    param_581 = 0i;
    let _e1666 = coat_bsdf_out_1;
    param_582 = _e1666;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_570), (&param_571), (&param_572), (&param_573), (&param_574), (&param_575), (&param_576), (&param_577), (&param_578), (&param_579), (&param_580), (&param_581), (&param_582));
    let _e1667 = param_582;
    coat_bsdf_out_1 = _e1667;
    metal_bsdf_tf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1668 = closureData_18;
    param_583 = _e1668;
    let _e1669 = metal_bsdf_tf_mix_fg_weight_out;
    param_584 = _e1669;
    let _e1670 = metal_reflectivity_out;
    param_585 = _e1670;
    let _e1671 = (*specular_color);
    param_586 = _e1671;
    param_587 = vec3<f32>(1f, 1f, 1f);
    param_588 = 5f;
    let _e1672 = main_roughness_out;
    param_589 = _e1672;
    param_590 = false;
    let _e1673 = thin_film_thickness_nm_out;
    param_591 = _e1673;
    let _e1674 = (*thin_film_ior);
    param_592 = _e1674;
    let _e1675 = (*geometry_normal);
    param_593 = _e1675;
    let _e1676 = (*geometry_tangent);
    param_594 = _e1676;
    param_595 = 0i;
    param_596 = 0i;
    let _e1677 = metal_bsdf_tf_out_1;
    param_597 = _e1677;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_583), (&param_584), (&param_585), (&param_586), (&param_587), (&param_588), (&param_589), (&param_590), (&param_591), (&param_592), (&param_593), (&param_594), (&param_595), (&param_596), (&param_597));
    let _e1678 = param_597;
    metal_bsdf_tf_out_1 = _e1678;
    metal_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1679 = closureData_18;
    param_598 = _e1679;
    let _e1680 = metal_bsdf_tf_mix_bg_weight_out;
    param_599 = _e1680;
    let _e1681 = metal_reflectivity_out;
    param_600 = _e1681;
    let _e1682 = (*specular_color);
    param_601 = _e1682;
    param_602 = vec3<f32>(1f, 1f, 1f);
    param_603 = 5f;
    let _e1683 = main_roughness_out;
    param_604 = _e1683;
    param_605 = false;
    param_606 = 0f;
    param_607 = 1.5f;
    let _e1684 = (*geometry_normal);
    param_608 = _e1684;
    let _e1685 = (*geometry_tangent);
    param_609 = _e1685;
    param_610 = 0i;
    param_611 = 0i;
    let _e1686 = metal_bsdf_out_1;
    param_612 = _e1686;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_598), (&param_599), (&param_600), (&param_601), (&param_602), (&param_603), (&param_604), (&param_605), (&param_606), (&param_607), (&param_608), (&param_609), (&param_610), (&param_611), (&param_612));
    let _e1687 = param_612;
    metal_bsdf_out_1 = _e1687;
    metal_bsdf_tf_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1688 = closureData_18;
    param_613 = _e1688;
    let _e1689 = metal_bsdf_tf_out_1;
    param_614 = _e1689;
    let _e1690 = metal_bsdf_out_1;
    param_615 = _e1690;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_613), (&param_614), (&param_615), (&param_616));
    let _e1691 = param_616;
    metal_bsdf_tf_mix_add_out_1 = _e1691;
    base_substrate_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1692 = closureData_18;
    param_617 = _e1692;
    let _e1693 = metal_bsdf_tf_mix_add_out_1;
    param_618 = _e1693;
    let _e1694 = (*base_metalness);
    param_619 = _e1694;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_617), (&param_618), (&param_619), (&param_620));
    let _e1695 = param_620;
    base_substrate_fg_mul_out_1 = _e1695;
    dielectric_reflection_tf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1696 = closureData_18;
    param_621 = _e1696;
    let _e1697 = dielectric_reflection_tf_mix_fg_weight_out;
    param_622 = _e1697;
    let _e1698 = (*specular_color);
    param_623 = _e1698;
    let _e1699 = modulated_eta_s_out;
    param_624 = _e1699;
    let _e1700 = main_roughness_out;
    param_625 = _e1700;
    param_626 = false;
    let _e1701 = thin_film_thickness_nm_out;
    param_627 = _e1701;
    let _e1702 = (*thin_film_ior);
    param_628 = _e1702;
    let _e1703 = (*geometry_normal);
    param_629 = _e1703;
    let _e1704 = (*geometry_tangent);
    param_630 = _e1704;
    param_631 = 0i;
    param_632 = 0i;
    let _e1705 = dielectric_reflection_tf_out_1;
    param_633 = _e1705;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_621), (&param_622), (&param_623), (&param_624), (&param_625), (&param_626), (&param_627), (&param_628), (&param_629), (&param_630), (&param_631), (&param_632), (&param_633));
    let _e1706 = param_633;
    dielectric_reflection_tf_out_1 = _e1706;
    dielectric_reflection_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1707 = closureData_18;
    param_634 = _e1707;
    let _e1708 = dielectric_reflection_tf_mix_bg_weight_out;
    param_635 = _e1708;
    let _e1709 = (*specular_color);
    param_636 = _e1709;
    let _e1710 = modulated_eta_s_out;
    param_637 = _e1710;
    let _e1711 = main_roughness_out;
    param_638 = _e1711;
    param_639 = false;
    param_640 = 0f;
    param_641 = 1.5f;
    let _e1712 = (*geometry_normal);
    param_642 = _e1712;
    let _e1713 = (*geometry_tangent);
    param_643 = _e1713;
    param_644 = 0i;
    param_645 = 0i;
    let _e1714 = dielectric_reflection_out_1;
    param_646 = _e1714;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_634), (&param_635), (&param_636), (&param_637), (&param_638), (&param_639), (&param_640), (&param_641), (&param_642), (&param_643), (&param_644), (&param_645), (&param_646));
    let _e1715 = param_646;
    dielectric_reflection_out_1 = _e1715;
    dielectric_reflection_tf_mix_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1716 = closureData_18;
    param_647 = _e1716;
    let _e1717 = dielectric_reflection_tf_out_1;
    param_648 = _e1717;
    let _e1718 = dielectric_reflection_out_1;
    param_649 = _e1718;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_647), (&param_648), (&param_649), (&param_650));
    let _e1719 = param_650;
    dielectric_reflection_tf_mix_add_out_1 = _e1719;
    dielectric_transmission_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1720 = closureData_18;
    param_651 = _e1720;
    param_652 = 1f;
    let _e1721 = if_transmission_tint_out;
    param_653 = _e1721;
    let _e1722 = modulated_eta_s_out;
    param_654 = _e1722;
    let _e1723 = main_roughness_out;
    param_655 = _e1723;
    param_656 = false;
    param_657 = 0f;
    param_658 = 1.5f;
    let _e1724 = (*geometry_normal);
    param_659 = _e1724;
    let _e1725 = (*geometry_tangent);
    param_660 = _e1725;
    param_661 = 0i;
    param_662 = 1i;
    let _e1726 = dielectric_transmission_out_1;
    param_663 = _e1726;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_651), (&param_652), (&param_653), (&param_654), (&param_655), (&param_656), (&param_657), (&param_658), (&param_659), (&param_660), (&param_661), (&param_662), (&param_663));
    let _e1727 = param_663;
    dielectric_transmission_out_1 = _e1727;
    dielectric_volume_out_1 = VDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1728 = closureData_18;
    param_664 = _e1728;
    let _e1729 = if_volume_absorption_out;
    param_665 = _e1729;
    let _e1730 = if_volume_scattering_out;
    param_666 = _e1730;
    let _e1731 = (*transmission_scatter_anisotropy);
    param_667 = _e1731;
    let _e1732 = dielectric_volume_out_1;
    param_668 = _e1732;
    mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b((&param_664), (&param_665), (&param_666), (&param_667), (&param_668));
    let _e1733 = param_668;
    dielectric_volume_out_1 = _e1733;
    dielectric_volume_transmission_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1734 = closureData_18;
    param_669 = _e1734;
    let _e1735 = dielectric_transmission_out_1;
    param_670 = _e1735;
    let _e1736 = dielectric_volume_out_1;
    param_671 = _e1736;
    mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_669), (&param_670), (&param_671), (&param_672));
    let _e1737 = param_672;
    dielectric_volume_transmission_out_1 = _e1737;
    dielectric_substrate_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1738 = closureData_18;
    param_673 = _e1738;
    let _e1739 = dielectric_volume_transmission_out_1;
    param_674 = _e1739;
    let _e1740 = (*transmission_weight);
    param_675 = _e1740;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_673), (&param_674), (&param_675), (&param_676));
    let _e1741 = param_676;
    dielectric_substrate_fg_mul_out_1 = _e1741;
    subsurface_thin_walled_reflection_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1742 = closureData_18;
    param_677 = _e1742;
    param_678 = 1f;
    let _e1743 = subsurface_color_nonnegative_out;
    param_679 = _e1743;
    let _e1744 = (*base_diffuse_roughness);
    param_680 = _e1744;
    let _e1745 = (*geometry_normal);
    param_681 = _e1745;
    param_682 = false;
    let _e1746 = subsurface_thin_walled_reflection_bsdf_out_1;
    param_683 = _e1746;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_677), (&param_678), (&param_679), (&param_680), (&param_681), (&param_682), (&param_683));
    let _e1747 = param_683;
    subsurface_thin_walled_reflection_bsdf_out_1 = _e1747;
    subsurface_thin_walled_reflection_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1748 = closureData_18;
    param_684 = _e1748;
    let _e1749 = subsurface_thin_walled_reflection_bsdf_out_1;
    param_685 = _e1749;
    let _e1750 = subsurface_thin_walled_brdf_factor_out;
    param_686 = _e1750;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_684), (&param_685), (&param_686), (&param_687));
    let _e1751 = param_687;
    subsurface_thin_walled_reflection_out_1 = _e1751;
    subsurface_thin_walled_transmission_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1752 = closureData_18;
    param_688 = _e1752;
    param_689 = 1f;
    let _e1753 = subsurface_color_nonnegative_out;
    param_690 = _e1753;
    let _e1754 = (*geometry_normal);
    param_691 = _e1754;
    let _e1755 = subsurface_thin_walled_transmission_bsdf_out_1;
    param_692 = _e1755;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_688), (&param_689), (&param_690), (&param_691), (&param_692));
    let _e1756 = param_692;
    subsurface_thin_walled_transmission_bsdf_out_1 = _e1756;
    subsurface_thin_walled_transmission_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1757 = closureData_18;
    param_693 = _e1757;
    let _e1758 = subsurface_thin_walled_transmission_bsdf_out_1;
    param_694 = _e1758;
    let _e1759 = subsurface_thin_walled_btdf_factor_out;
    param_695 = _e1759;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_693), (&param_694), (&param_695), (&param_696));
    let _e1760 = param_696;
    subsurface_thin_walled_transmission_out_1 = _e1760;
    subsurface_thin_walled_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1761 = closureData_18;
    param_697 = _e1761;
    let _e1762 = subsurface_thin_walled_reflection_out_1;
    param_698 = _e1762;
    let _e1763 = subsurface_thin_walled_transmission_out_1;
    param_699 = _e1763;
    param_700 = 0.5f;
    mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_697), (&param_698), (&param_699), (&param_700), (&param_701));
    let _e1764 = param_701;
    subsurface_thin_walled_out_1 = _e1764;
    selected_subsurface_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1765 = closureData_18;
    param_702 = _e1765;
    let _e1766 = subsurface_thin_walled_out_1;
    param_703 = _e1766;
    let _e1767 = subsurface_selector_out;
    param_704 = _e1767;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_702), (&param_703), (&param_704), (&param_705));
    let _e1768 = param_705;
    selected_subsurface_fg_mul_out_1 = _e1768;
    subsurface_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1769 = closureData_18;
    param_706 = _e1769;
    let _e1770 = selected_subsurface_bg_weight_out;
    param_707 = _e1770;
    let _e1771 = subsurface_color_nonnegative_out;
    param_708 = _e1771;
    let _e1772 = subsurface_radius_scaled_out;
    param_709 = _e1772;
    let _e1773 = (*subsurface_scatter_anisotropy);
    param_710 = _e1773;
    let _e1774 = (*geometry_normal);
    param_711 = _e1774;
    let _e1775 = subsurface_bsdf_out_1;
    param_712 = _e1775;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_706), (&param_707), (&param_708), (&param_709), (&param_710), (&param_711), (&param_712));
    let _e1776 = param_712;
    subsurface_bsdf_out_1 = _e1776;
    selected_subsurface_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1777 = closureData_18;
    param_713 = _e1777;
    let _e1778 = selected_subsurface_fg_mul_out_1;
    param_714 = _e1778;
    let _e1779 = subsurface_bsdf_out_1;
    param_715 = _e1779;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_713), (&param_714), (&param_715), (&param_716));
    let _e1780 = param_716;
    selected_subsurface_add_out_1 = _e1780;
    opaque_base_fg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1781 = closureData_18;
    param_717 = _e1781;
    let _e1782 = selected_subsurface_add_out_1;
    param_718 = _e1782;
    let _e1783 = (*subsurface_weight);
    param_719 = _e1783;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_717), (&param_718), (&param_719), (&param_720));
    let _e1784 = param_720;
    opaque_base_fg_mul_out_1 = _e1784;
    diffuse_bsdf_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1785 = closureData_18;
    param_721 = _e1785;
    let _e1786 = opaque_base_bg_weight_out;
    param_722 = _e1786;
    let _e1787 = base_color_nonnegative_out;
    param_723 = _e1787;
    let _e1788 = (*base_diffuse_roughness);
    param_724 = _e1788;
    let _e1789 = (*geometry_normal);
    param_725 = _e1789;
    param_726 = true;
    let _e1790 = diffuse_bsdf_out_1;
    param_727 = _e1790;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_721), (&param_722), (&param_723), (&param_724), (&param_725), (&param_726), (&param_727));
    let _e1791 = param_727;
    diffuse_bsdf_out_1 = _e1791;
    opaque_base_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1792 = closureData_18;
    param_728 = _e1792;
    let _e1793 = opaque_base_fg_mul_out_1;
    param_729 = _e1793;
    let _e1794 = diffuse_bsdf_out_1;
    param_730 = _e1794;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_728), (&param_729), (&param_730), (&param_731));
    let _e1795 = param_731;
    opaque_base_add_out_1 = _e1795;
    dielectric_substrate_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1796 = closureData_18;
    param_732 = _e1796;
    let _e1797 = opaque_base_add_out_1;
    param_733 = _e1797;
    let _e1798 = dielectric_substrate_mix_inv_out;
    param_734 = _e1798;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_732), (&param_733), (&param_734), (&param_735));
    let _e1799 = param_735;
    dielectric_substrate_bg_mul_out_1 = _e1799;
    dielectric_substrate_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1800 = closureData_18;
    param_736 = _e1800;
    let _e1801 = dielectric_substrate_fg_mul_out_1;
    param_737 = _e1801;
    let _e1802 = dielectric_substrate_bg_mul_out_1;
    param_738 = _e1802;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_736), (&param_737), (&param_738), (&param_739));
    let _e1803 = param_739;
    dielectric_substrate_add_out_1 = _e1803;
    dielectric_base_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1804 = closureData_18;
    param_740 = _e1804;
    let _e1805 = dielectric_reflection_tf_mix_add_out_1;
    param_741 = _e1805;
    let _e1806 = dielectric_substrate_add_out_1;
    param_742 = _e1806;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_740), (&param_741), (&param_742), (&param_743));
    let _e1807 = param_743;
    dielectric_base_out_1 = _e1807;
    base_substrate_bg_mul_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1808 = closureData_18;
    param_744 = _e1808;
    let _e1809 = dielectric_base_out_1;
    param_745 = _e1809;
    let _e1810 = base_substrate_mix_inv_out;
    param_746 = _e1810;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_744), (&param_745), (&param_746), (&param_747));
    let _e1811 = param_747;
    base_substrate_bg_mul_out_1 = _e1811;
    base_substrate_add_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1812 = closureData_18;
    param_748 = _e1812;
    let _e1813 = base_substrate_fg_mul_out_1;
    param_749 = _e1813;
    let _e1814 = base_substrate_bg_mul_out_1;
    param_750 = _e1814;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_748), (&param_749), (&param_750), (&param_751));
    let _e1815 = param_751;
    base_substrate_add_out_1 = _e1815;
    darkened_base_substrate_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1816 = closureData_18;
    param_752 = _e1816;
    let _e1817 = base_substrate_add_out_1;
    param_753 = _e1817;
    let _e1818 = modulated_base_darkening_out;
    param_754 = _e1818;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_752), (&param_753), (&param_754), (&param_755));
    let _e1819 = param_755;
    darkened_base_substrate_out_1 = _e1819;
    coat_substrate_attenuated_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1820 = closureData_18;
    param_756 = _e1820;
    let _e1821 = darkened_base_substrate_out_1;
    param_757 = _e1821;
    let _e1822 = coat_attenuation_out;
    param_758 = _e1822;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_756), (&param_757), (&param_758), (&param_759));
    let _e1823 = param_759;
    coat_substrate_attenuated_out_1 = _e1823;
    coat_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1824 = closureData_18;
    param_760 = _e1824;
    let _e1825 = coat_bsdf_out_1;
    param_761 = _e1825;
    let _e1826 = coat_substrate_attenuated_out_1;
    param_762 = _e1826;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_760), (&param_761), (&param_762), (&param_763));
    let _e1827 = param_763;
    coat_layer_out_1 = _e1827;
    fuzz_layer_out_1 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1828 = closureData_18;
    param_764 = _e1828;
    let _e1829 = fuzz_bsdf_out_1;
    param_765 = _e1829;
    let _e1830 = coat_layer_out_1;
    param_766 = _e1830;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_764), (&param_765), (&param_766), (&param_767));
    let _e1831 = param_767;
    fuzz_layer_out_1 = _e1831;
    let _e1832 = occlusion_2;
    let _e1834 = fuzz_layer_out_1.response;
    let _e1837 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1837 + (_e1834 * _e1832));
    param_768 = 4i;
    let _e1840 = L_11;
    param_769 = _e1840;
    let _e1841 = V_14;
    param_770 = _e1841;
    let _e1842 = N_18;
    param_771 = _e1842;
    let _e1843 = P_3;
    param_772 = _e1843;
    let _e1844 = occlusion_2;
    param_773 = _e1844;
    let _e1845 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_768), (&param_769), (&param_770), (&param_771), (&param_772), (&param_773));
    closureData_19 = _e1845;
    uncoated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1846 = closureData_19;
    param_774 = _e1846;
    let _e1847 = emission_weight_out;
    param_775 = _e1847;
    mx_uniform_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b((&param_774), (&param_775), (&param_776));
    let _e1848 = param_776;
    uncoated_emission_edf_out = _e1848;
    coat_tinted_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1849 = closureData_19;
    param_777 = _e1849;
    let _e1850 = uncoated_emission_edf_out;
    param_778 = _e1850;
    let _e1851 = (*coat_color);
    param_779 = _e1851;
    mx_multiply_edf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_777), (&param_778), (&param_779), (&param_780));
    let _e1852 = param_780;
    coat_tinted_emission_edf_out = _e1852;
    coated_emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1853 = closureData_19;
    param_781 = _e1853;
    let _e1854 = one_minus_coat_F0_color_out;
    param_782 = _e1854;
    param_783 = vec3<f32>(0f, 0f, 0f);
    param_784 = 5f;
    let _e1855 = coat_tinted_emission_edf_out;
    param_785 = _e1855;
    mx_generalized_schlick_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b((&param_781), (&param_782), (&param_783), (&param_784), (&param_785), (&param_786));
    let _e1856 = param_786;
    coated_emission_edf_out = _e1856;
    emission_edf_out = vec3<f32>(0f, 0f, 0f);
    let _e1857 = closureData_19;
    param_787 = _e1857;
    let _e1858 = coated_emission_edf_out;
    param_788 = _e1858;
    let _e1859 = uncoated_emission_edf_out;
    param_789 = _e1859;
    let _e1860 = (*coat_weight);
    param_790 = _e1860;
    mx_mix_edf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b((&param_787), (&param_788), (&param_789), (&param_790), (&param_791));
    let _e1861 = param_791;
    emission_edf_out = _e1861;
    let _e1862 = emission_edf_out;
    let _e1864 = shader_constructor_out.color;
    shader_constructor_out.color = (_e1864 + _e1862);
    param_792 = 2i;
    let _e1867 = L_11;
    param_793 = _e1867;
    let _e1868 = V_14;
    param_794 = _e1868;
    let _e1869 = N_18;
    param_795 = _e1869;
    let _e1870 = P_3;
    param_796 = _e1870;
    let _e1871 = occlusion_2;
    param_797 = _e1871;
    let _e1872 = makeClosureData_u0028_i1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b((&param_792), (&param_793), (&param_794), (&param_795), (&param_796), (&param_797));
    closureData_20 = _e1872;
    fuzz_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1873 = closureData_20;
    param_798 = _e1873;
    let _e1874 = (*fuzz_weight);
    param_799 = _e1874;
    let _e1875 = (*fuzz_color);
    param_800 = _e1875;
    let _e1876 = (*fuzz_roughness);
    param_801 = _e1876;
    let _e1877 = (*geometry_normal);
    param_802 = _e1877;
    param_803 = 1i;
    let _e1878 = fuzz_bsdf_out_2;
    param_804 = _e1878;
    mx_sheen_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_798), (&param_799), (&param_800), (&param_801), (&param_802), (&param_803), (&param_804));
    let _e1879 = param_804;
    fuzz_bsdf_out_2 = _e1879;
    coat_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1880 = closureData_20;
    param_805 = _e1880;
    let _e1881 = (*coat_weight);
    param_806 = _e1881;
    param_807 = vec3<f32>(1f, 1f, 1f);
    let _e1882 = (*coat_ior);
    param_808 = _e1882;
    let _e1883 = coat_roughness_vector_out;
    param_809 = _e1883;
    param_810 = false;
    param_811 = 0f;
    param_812 = 1.5f;
    let _e1884 = (*geometry_coat_normal);
    param_813 = _e1884;
    let _e1885 = (*geometry_coat_tangent);
    param_814 = _e1885;
    param_815 = 0i;
    param_816 = 0i;
    let _e1886 = coat_bsdf_out_2;
    param_817 = _e1886;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_805), (&param_806), (&param_807), (&param_808), (&param_809), (&param_810), (&param_811), (&param_812), (&param_813), (&param_814), (&param_815), (&param_816), (&param_817));
    let _e1887 = param_817;
    coat_bsdf_out_2 = _e1887;
    metal_bsdf_tf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1888 = closureData_20;
    param_818 = _e1888;
    let _e1889 = metal_bsdf_tf_mix_fg_weight_out;
    param_819 = _e1889;
    let _e1890 = metal_reflectivity_out;
    param_820 = _e1890;
    let _e1891 = (*specular_color);
    param_821 = _e1891;
    param_822 = vec3<f32>(1f, 1f, 1f);
    param_823 = 5f;
    let _e1892 = main_roughness_out;
    param_824 = _e1892;
    param_825 = false;
    let _e1893 = thin_film_thickness_nm_out;
    param_826 = _e1893;
    let _e1894 = (*thin_film_ior);
    param_827 = _e1894;
    let _e1895 = (*geometry_normal);
    param_828 = _e1895;
    let _e1896 = (*geometry_tangent);
    param_829 = _e1896;
    param_830 = 0i;
    param_831 = 0i;
    let _e1897 = metal_bsdf_tf_out_2;
    param_832 = _e1897;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_818), (&param_819), (&param_820), (&param_821), (&param_822), (&param_823), (&param_824), (&param_825), (&param_826), (&param_827), (&param_828), (&param_829), (&param_830), (&param_831), (&param_832));
    let _e1898 = param_832;
    metal_bsdf_tf_out_2 = _e1898;
    metal_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1899 = closureData_20;
    param_833 = _e1899;
    let _e1900 = metal_bsdf_tf_mix_bg_weight_out;
    param_834 = _e1900;
    let _e1901 = metal_reflectivity_out;
    param_835 = _e1901;
    let _e1902 = (*specular_color);
    param_836 = _e1902;
    param_837 = vec3<f32>(1f, 1f, 1f);
    param_838 = 5f;
    let _e1903 = main_roughness_out;
    param_839 = _e1903;
    param_840 = false;
    param_841 = 0f;
    param_842 = 1.5f;
    let _e1904 = (*geometry_normal);
    param_843 = _e1904;
    let _e1905 = (*geometry_tangent);
    param_844 = _e1905;
    param_845 = 0i;
    param_846 = 0i;
    let _e1906 = metal_bsdf_out_2;
    param_847 = _e1906;
    mx_generalized_schlick_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_833), (&param_834), (&param_835), (&param_836), (&param_837), (&param_838), (&param_839), (&param_840), (&param_841), (&param_842), (&param_843), (&param_844), (&param_845), (&param_846), (&param_847));
    let _e1907 = param_847;
    metal_bsdf_out_2 = _e1907;
    metal_bsdf_tf_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1908 = closureData_20;
    param_848 = _e1908;
    let _e1909 = metal_bsdf_tf_out_2;
    param_849 = _e1909;
    let _e1910 = metal_bsdf_out_2;
    param_850 = _e1910;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_848), (&param_849), (&param_850), (&param_851));
    let _e1911 = param_851;
    metal_bsdf_tf_mix_add_out_2 = _e1911;
    base_substrate_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1912 = closureData_20;
    param_852 = _e1912;
    let _e1913 = metal_bsdf_tf_mix_add_out_2;
    param_853 = _e1913;
    let _e1914 = (*base_metalness);
    param_854 = _e1914;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_852), (&param_853), (&param_854), (&param_855));
    let _e1915 = param_855;
    base_substrate_fg_mul_out_2 = _e1915;
    dielectric_reflection_tf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1916 = closureData_20;
    param_856 = _e1916;
    let _e1917 = dielectric_reflection_tf_mix_fg_weight_out;
    param_857 = _e1917;
    let _e1918 = (*specular_color);
    param_858 = _e1918;
    let _e1919 = modulated_eta_s_out;
    param_859 = _e1919;
    let _e1920 = main_roughness_out;
    param_860 = _e1920;
    param_861 = false;
    let _e1921 = thin_film_thickness_nm_out;
    param_862 = _e1921;
    let _e1922 = (*thin_film_ior);
    param_863 = _e1922;
    let _e1923 = (*geometry_normal);
    param_864 = _e1923;
    let _e1924 = (*geometry_tangent);
    param_865 = _e1924;
    param_866 = 0i;
    param_867 = 0i;
    let _e1925 = dielectric_reflection_tf_out_2;
    param_868 = _e1925;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_856), (&param_857), (&param_858), (&param_859), (&param_860), (&param_861), (&param_862), (&param_863), (&param_864), (&param_865), (&param_866), (&param_867), (&param_868));
    let _e1926 = param_868;
    dielectric_reflection_tf_out_2 = _e1926;
    dielectric_reflection_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1927 = closureData_20;
    param_869 = _e1927;
    let _e1928 = dielectric_reflection_tf_mix_bg_weight_out;
    param_870 = _e1928;
    let _e1929 = (*specular_color);
    param_871 = _e1929;
    let _e1930 = modulated_eta_s_out;
    param_872 = _e1930;
    let _e1931 = main_roughness_out;
    param_873 = _e1931;
    param_874 = false;
    param_875 = 0f;
    param_876 = 1.5f;
    let _e1932 = (*geometry_normal);
    param_877 = _e1932;
    let _e1933 = (*geometry_tangent);
    param_878 = _e1933;
    param_879 = 0i;
    param_880 = 0i;
    let _e1934 = dielectric_reflection_out_2;
    param_881 = _e1934;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_869), (&param_870), (&param_871), (&param_872), (&param_873), (&param_874), (&param_875), (&param_876), (&param_877), (&param_878), (&param_879), (&param_880), (&param_881));
    let _e1935 = param_881;
    dielectric_reflection_out_2 = _e1935;
    dielectric_reflection_tf_mix_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1936 = closureData_20;
    param_882 = _e1936;
    let _e1937 = dielectric_reflection_tf_out_2;
    param_883 = _e1937;
    let _e1938 = dielectric_reflection_out_2;
    param_884 = _e1938;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_882), (&param_883), (&param_884), (&param_885));
    let _e1939 = param_885;
    dielectric_reflection_tf_mix_add_out_2 = _e1939;
    dielectric_transmission_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1940 = closureData_20;
    param_886 = _e1940;
    param_887 = 1f;
    let _e1941 = if_transmission_tint_out;
    param_888 = _e1941;
    let _e1942 = modulated_eta_s_out;
    param_889 = _e1942;
    let _e1943 = main_roughness_out;
    param_890 = _e1943;
    param_891 = false;
    param_892 = 0f;
    param_893 = 1.5f;
    let _e1944 = (*geometry_normal);
    param_894 = _e1944;
    let _e1945 = (*geometry_tangent);
    param_895 = _e1945;
    param_896 = 0i;
    param_897 = 1i;
    let _e1946 = dielectric_transmission_out_2;
    param_898 = _e1946;
    mx_dielectric_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf2_u003b_b1_u003b_f1_u003b_f1_u003b_vf3_u003b_vf3_u003b_i1_u003b_i1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_886), (&param_887), (&param_888), (&param_889), (&param_890), (&param_891), (&param_892), (&param_893), (&param_894), (&param_895), (&param_896), (&param_897), (&param_898));
    let _e1947 = param_898;
    dielectric_transmission_out_2 = _e1947;
    dielectric_volume_out_2 = VDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1948 = closureData_20;
    param_899 = _e1948;
    let _e1949 = if_volume_absorption_out;
    param_900 = _e1949;
    let _e1950 = if_volume_scattering_out;
    param_901 = _e1950;
    let _e1951 = (*transmission_scatter_anisotropy);
    param_902 = _e1951;
    let _e1952 = dielectric_volume_out_2;
    param_903 = _e1952;
    mx_anisotropic_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_vf3_u003b_vf3_u003b_f1_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b((&param_899), (&param_900), (&param_901), (&param_902), (&param_903));
    let _e1953 = param_903;
    dielectric_volume_out_2 = _e1953;
    dielectric_volume_transmission_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1954 = closureData_20;
    param_904 = _e1954;
    let _e1955 = dielectric_transmission_out_2;
    param_905 = _e1955;
    let _e1956 = dielectric_volume_out_2;
    param_906 = _e1956;
    mx_layer_vdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_VDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_904), (&param_905), (&param_906), (&param_907));
    let _e1957 = param_907;
    dielectric_volume_transmission_out_2 = _e1957;
    dielectric_substrate_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1958 = closureData_20;
    param_908 = _e1958;
    let _e1959 = dielectric_volume_transmission_out_2;
    param_909 = _e1959;
    let _e1960 = (*transmission_weight);
    param_910 = _e1960;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_908), (&param_909), (&param_910), (&param_911));
    let _e1961 = param_911;
    dielectric_substrate_fg_mul_out_2 = _e1961;
    subsurface_thin_walled_reflection_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1962 = closureData_20;
    param_912 = _e1962;
    param_913 = 1f;
    let _e1963 = subsurface_color_nonnegative_out;
    param_914 = _e1963;
    let _e1964 = (*base_diffuse_roughness);
    param_915 = _e1964;
    let _e1965 = (*geometry_normal);
    param_916 = _e1965;
    param_917 = false;
    let _e1966 = subsurface_thin_walled_reflection_bsdf_out_2;
    param_918 = _e1966;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_912), (&param_913), (&param_914), (&param_915), (&param_916), (&param_917), (&param_918));
    let _e1967 = param_918;
    subsurface_thin_walled_reflection_bsdf_out_2 = _e1967;
    subsurface_thin_walled_reflection_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1968 = closureData_20;
    param_919 = _e1968;
    let _e1969 = subsurface_thin_walled_reflection_bsdf_out_2;
    param_920 = _e1969;
    let _e1970 = subsurface_thin_walled_brdf_factor_out;
    param_921 = _e1970;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_919), (&param_920), (&param_921), (&param_922));
    let _e1971 = param_922;
    subsurface_thin_walled_reflection_out_2 = _e1971;
    subsurface_thin_walled_transmission_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1972 = closureData_20;
    param_923 = _e1972;
    param_924 = 1f;
    let _e1973 = subsurface_color_nonnegative_out;
    param_925 = _e1973;
    let _e1974 = (*geometry_normal);
    param_926 = _e1974;
    let _e1975 = subsurface_thin_walled_transmission_bsdf_out_2;
    param_927 = _e1975;
    mx_translucent_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_923), (&param_924), (&param_925), (&param_926), (&param_927));
    let _e1976 = param_927;
    subsurface_thin_walled_transmission_bsdf_out_2 = _e1976;
    subsurface_thin_walled_transmission_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1977 = closureData_20;
    param_928 = _e1977;
    let _e1978 = subsurface_thin_walled_transmission_bsdf_out_2;
    param_929 = _e1978;
    let _e1979 = subsurface_thin_walled_btdf_factor_out;
    param_930 = _e1979;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_928), (&param_929), (&param_930), (&param_931));
    let _e1980 = param_931;
    subsurface_thin_walled_transmission_out_2 = _e1980;
    subsurface_thin_walled_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1981 = closureData_20;
    param_932 = _e1981;
    let _e1982 = subsurface_thin_walled_reflection_out_2;
    param_933 = _e1982;
    let _e1983 = subsurface_thin_walled_transmission_out_2;
    param_934 = _e1983;
    param_935 = 0.5f;
    mx_mix_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_932), (&param_933), (&param_934), (&param_935), (&param_936));
    let _e1984 = param_936;
    subsurface_thin_walled_out_2 = _e1984;
    selected_subsurface_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1985 = closureData_20;
    param_937 = _e1985;
    let _e1986 = subsurface_thin_walled_out_2;
    param_938 = _e1986;
    let _e1987 = subsurface_selector_out;
    param_939 = _e1987;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_937), (&param_938), (&param_939), (&param_940));
    let _e1988 = param_940;
    selected_subsurface_fg_mul_out_2 = _e1988;
    subsurface_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1989 = closureData_20;
    param_941 = _e1989;
    let _e1990 = selected_subsurface_bg_weight_out;
    param_942 = _e1990;
    let _e1991 = subsurface_color_nonnegative_out;
    param_943 = _e1991;
    let _e1992 = subsurface_radius_scaled_out;
    param_944 = _e1992;
    let _e1993 = (*subsurface_scatter_anisotropy);
    param_945 = _e1993;
    let _e1994 = (*geometry_normal);
    param_946 = _e1994;
    let _e1995 = subsurface_bsdf_out_2;
    param_947 = _e1995;
    mx_subsurface_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_941), (&param_942), (&param_943), (&param_944), (&param_945), (&param_946), (&param_947));
    let _e1996 = param_947;
    subsurface_bsdf_out_2 = _e1996;
    selected_subsurface_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e1997 = closureData_20;
    param_948 = _e1997;
    let _e1998 = selected_subsurface_fg_mul_out_2;
    param_949 = _e1998;
    let _e1999 = subsurface_bsdf_out_2;
    param_950 = _e1999;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_948), (&param_949), (&param_950), (&param_951));
    let _e2000 = param_951;
    selected_subsurface_add_out_2 = _e2000;
    opaque_base_fg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2001 = closureData_20;
    param_952 = _e2001;
    let _e2002 = selected_subsurface_add_out_2;
    param_953 = _e2002;
    let _e2003 = (*subsurface_weight);
    param_954 = _e2003;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_952), (&param_953), (&param_954), (&param_955));
    let _e2004 = param_955;
    opaque_base_fg_mul_out_2 = _e2004;
    diffuse_bsdf_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2005 = closureData_20;
    param_956 = _e2005;
    let _e2006 = opaque_base_bg_weight_out;
    param_957 = _e2006;
    let _e2007 = base_color_nonnegative_out;
    param_958 = _e2007;
    let _e2008 = (*base_diffuse_roughness);
    param_959 = _e2008;
    let _e2009 = (*geometry_normal);
    param_960 = _e2009;
    param_961 = true;
    let _e2010 = diffuse_bsdf_out_2;
    param_962 = _e2010;
    mx_oren_nayar_diffuse_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_b1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_956), (&param_957), (&param_958), (&param_959), (&param_960), (&param_961), (&param_962));
    let _e2011 = param_962;
    diffuse_bsdf_out_2 = _e2011;
    opaque_base_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2012 = closureData_20;
    param_963 = _e2012;
    let _e2013 = opaque_base_fg_mul_out_2;
    param_964 = _e2013;
    let _e2014 = diffuse_bsdf_out_2;
    param_965 = _e2014;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_963), (&param_964), (&param_965), (&param_966));
    let _e2015 = param_966;
    opaque_base_add_out_2 = _e2015;
    dielectric_substrate_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2016 = closureData_20;
    param_967 = _e2016;
    let _e2017 = opaque_base_add_out_2;
    param_968 = _e2017;
    let _e2018 = dielectric_substrate_mix_inv_out;
    param_969 = _e2018;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_967), (&param_968), (&param_969), (&param_970));
    let _e2019 = param_970;
    dielectric_substrate_bg_mul_out_2 = _e2019;
    dielectric_substrate_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2020 = closureData_20;
    param_971 = _e2020;
    let _e2021 = dielectric_substrate_fg_mul_out_2;
    param_972 = _e2021;
    let _e2022 = dielectric_substrate_bg_mul_out_2;
    param_973 = _e2022;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_971), (&param_972), (&param_973), (&param_974));
    let _e2023 = param_974;
    dielectric_substrate_add_out_2 = _e2023;
    dielectric_base_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2024 = closureData_20;
    param_975 = _e2024;
    let _e2025 = dielectric_reflection_tf_mix_add_out_2;
    param_976 = _e2025;
    let _e2026 = dielectric_substrate_add_out_2;
    param_977 = _e2026;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_975), (&param_976), (&param_977), (&param_978));
    let _e2027 = param_978;
    dielectric_base_out_2 = _e2027;
    base_substrate_bg_mul_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2028 = closureData_20;
    param_979 = _e2028;
    let _e2029 = dielectric_base_out_2;
    param_980 = _e2029;
    let _e2030 = base_substrate_mix_inv_out;
    param_981 = _e2030;
    mx_multiply_bsdf_float_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_f1_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_979), (&param_980), (&param_981), (&param_982));
    let _e2031 = param_982;
    base_substrate_bg_mul_out_2 = _e2031;
    base_substrate_add_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2032 = closureData_20;
    param_983 = _e2032;
    let _e2033 = base_substrate_fg_mul_out_2;
    param_984 = _e2033;
    let _e2034 = base_substrate_bg_mul_out_2;
    param_985 = _e2034;
    mx_add_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_983), (&param_984), (&param_985), (&param_986));
    let _e2035 = param_986;
    base_substrate_add_out_2 = _e2035;
    darkened_base_substrate_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2036 = closureData_20;
    param_987 = _e2036;
    let _e2037 = base_substrate_add_out_2;
    param_988 = _e2037;
    let _e2038 = modulated_base_darkening_out;
    param_989 = _e2038;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_987), (&param_988), (&param_989), (&param_990));
    let _e2039 = param_990;
    darkened_base_substrate_out_2 = _e2039;
    coat_substrate_attenuated_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2040 = closureData_20;
    param_991 = _e2040;
    let _e2041 = darkened_base_substrate_out_2;
    param_992 = _e2041;
    let _e2042 = coat_attenuation_out;
    param_993 = _e2042;
    mx_multiply_bsdf_color3_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_vf3_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_991), (&param_992), (&param_993), (&param_994));
    let _e2043 = param_994;
    coat_substrate_attenuated_out_2 = _e2043;
    coat_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2044 = closureData_20;
    param_995 = _e2044;
    let _e2045 = coat_bsdf_out_2;
    param_996 = _e2045;
    let _e2046 = coat_substrate_attenuated_out_2;
    param_997 = _e2046;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_995), (&param_996), (&param_997), (&param_998));
    let _e2047 = param_998;
    coat_layer_out_2 = _e2047;
    fuzz_layer_out_2 = BSDF(vec3<f32>(0f, 0f, 0f), vec3<f32>(1f, 1f, 1f));
    let _e2048 = closureData_20;
    param_999 = _e2048;
    let _e2049 = fuzz_bsdf_out_2;
    param_1000 = _e2049;
    let _e2050 = coat_layer_out_2;
    param_1001 = _e2050;
    mx_layer_bsdf_u0028_struct_u002d_ClosureData_u002d_i1_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_f11_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b_struct_u002d_BSDF_u002d_vf3_u002d_vf31_u003b((&param_999), (&param_1000), (&param_1001), (&param_1002));
    let _e2051 = param_1002;
    fuzz_layer_out_2 = _e2051;
    let _e2053 = fuzz_layer_out_2.response;
    let _e2055 = shader_constructor_out.color;
    shader_constructor_out.color = (_e2055 + _e2053);
    let _e2058 = surfaceOpacity;
    let _e2060 = shader_constructor_out.color;
    shader_constructor_out.color = (_e2060 * _e2058);
    let _e2064 = shader_constructor_out.transparency;
    let _e2065 = surfaceOpacity;
    shader_constructor_out.transparency = mix(vec3<f32>(1f, 1f, 1f), _e2064, vec3(_e2065));
    let _e2069 = shader_constructor_out;
    (*mtlxRasterOut_5) = _e2069;
    return;
}

fn mtlxRasterMain_u0028_() -> vec4<f32> {
    var geomprop_Nworld_out: vec3<f32>;
    var geomprop_Tworld_out: vec3<f32>;
    var open_pbr_surface_surfaceshader_out: surfaceshader;
    var param_1003: f32;
    var param_1004: vec3<f32>;
    var param_1005: f32;
    var param_1006: f32;
    var param_1007: f32;
    var param_1008: vec3<f32>;
    var param_1009: f32;
    var param_1010: f32;
    var param_1011: f32;
    var param_1012: f32;
    var param_1013: vec3<f32>;
    var param_1014: f32;
    var param_1015: vec3<f32>;
    var param_1016: f32;
    var param_1017: f32;
    var param_1018: f32;
    var param_1019: f32;
    var param_1020: vec3<f32>;
    var param_1021: f32;
    var param_1022: vec3<f32>;
    var param_1023: f32;
    var param_1024: f32;
    var param_1025: vec3<f32>;
    var param_1026: f32;
    var param_1027: f32;
    var param_1028: vec3<f32>;
    var param_1029: f32;
    var param_1030: f32;
    var param_1031: f32;
    var param_1032: f32;
    var param_1033: f32;
    var param_1034: f32;
    var param_1035: f32;
    var param_1036: f32;
    var param_1037: vec3<f32>;
    var param_1038: f32;
    var param_1039: bool;
    var param_1040: vec3<f32>;
    var param_1041: vec3<f32>;
    var param_1042: vec3<f32>;
    var param_1043: vec3<f32>;
    var param_1044: surfaceshader;

    let _e327 = normalWorld;
    geomprop_Nworld_out = normalize(_e327);
    let _e329 = tangentWorld;
    geomprop_Tworld_out = normalize(_e329);
    open_pbr_surface_surfaceshader_out = surfaceshader(vec3<f32>(0f, 0f, 0f), vec3<f32>(0f, 0f, 0f));
    let _e331 = base_weight_1;
    param_1003 = _e331;
    let _e332 = base_color_1;
    param_1004 = _e332;
    let _e333 = base_diffuse_roughness_1;
    param_1005 = _e333;
    let _e334 = base_metalness_1;
    param_1006 = _e334;
    let _e335 = specular_weight_1;
    param_1007 = _e335;
    let _e336 = specular_color_1;
    param_1008 = _e336;
    let _e337 = specular_roughness_1;
    param_1009 = _e337;
    let _e338 = specular_ior_1;
    param_1010 = _e338;
    let _e339 = specular_roughness_anisotropy_1;
    param_1011 = _e339;
    let _e340 = transmission_weight_1;
    param_1012 = _e340;
    let _e341 = transmission_color_1;
    param_1013 = _e341;
    let _e342 = transmission_depth_1;
    param_1014 = _e342;
    let _e343 = transmission_scatter_1;
    param_1015 = _e343;
    let _e344 = transmission_scatter_anisotropy_1;
    param_1016 = _e344;
    let _e345 = transmission_dispersion_scale_1;
    param_1017 = _e345;
    let _e346 = transmission_dispersion_abbe_number_1;
    param_1018 = _e346;
    let _e347 = subsurface_weight_1;
    param_1019 = _e347;
    let _e348 = subsurface_color_1;
    param_1020 = _e348;
    let _e349 = subsurface_radius_1;
    param_1021 = _e349;
    let _e350 = subsurface_radius_scale_1;
    param_1022 = _e350;
    let _e351 = subsurface_scatter_anisotropy_1;
    param_1023 = _e351;
    let _e352 = fuzz_weight_1;
    param_1024 = _e352;
    let _e353 = fuzz_color_1;
    param_1025 = _e353;
    let _e354 = fuzz_roughness_1;
    param_1026 = _e354;
    let _e355 = coat_weight_1;
    param_1027 = _e355;
    let _e356 = coat_color_1;
    param_1028 = _e356;
    let _e357 = coat_roughness_1;
    param_1029 = _e357;
    let _e358 = coat_roughness_anisotropy_1;
    param_1030 = _e358;
    let _e359 = coat_ior_1;
    param_1031 = _e359;
    let _e360 = coat_darkening_1;
    param_1032 = _e360;
    let _e361 = thin_film_weight_1;
    param_1033 = _e361;
    let _e362 = thin_film_thickness_1;
    param_1034 = _e362;
    let _e363 = thin_film_ior_1;
    param_1035 = _e363;
    let _e364 = emission_luminance_1;
    param_1036 = _e364;
    let _e365 = emission_color_1;
    param_1037 = _e365;
    let _e366 = geometry_opacity_1;
    param_1038 = _e366;
    let _e367 = geometry_thin_walled_1;
    param_1039 = _e367;
    let _e368 = geomprop_Nworld_out;
    param_1040 = _e368;
    let _e369 = geomprop_Nworld_out;
    param_1041 = _e369;
    let _e370 = geomprop_Tworld_out;
    param_1042 = _e370;
    let _e371 = geomprop_Tworld_out;
    param_1043 = _e371;
    NG_open_pbr_surface_surfaceshader_u0028_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_f1_u003b_vf3_u003b_f1_u003b_b1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_struct_u002d_surfaceshader_u002d_vf3_u002d_vf31_u003b((&param_1003), (&param_1004), (&param_1005), (&param_1006), (&param_1007), (&param_1008), (&param_1009), (&param_1010), (&param_1011), (&param_1012), (&param_1013), (&param_1014), (&param_1015), (&param_1016), (&param_1017), (&param_1018), (&param_1019), (&param_1020), (&param_1021), (&param_1022), (&param_1023), (&param_1024), (&param_1025), (&param_1026), (&param_1027), (&param_1028), (&param_1029), (&param_1030), (&param_1031), (&param_1032), (&param_1033), (&param_1034), (&param_1035), (&param_1036), (&param_1037), (&param_1038), (&param_1039), (&param_1040), (&param_1041), (&param_1042), (&param_1043), (&param_1044));
    let _e372 = param_1044;
    open_pbr_surface_surfaceshader_out = _e372;
    let _e374 = open_pbr_surface_surfaceshader_out.color;
    mtlxRasterOut_6 = vec4<f32>(_e374.x, _e374.y, _e374.z, 1f);
    let _e379 = mtlxRasterOut_6;
    return _e379;
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
    var param_1045: vec3<f32>;
    var param_1046: vec3<f32>;
    var param_1047: vec3<f32>;

    let _e291 = (*nW);
    param_1045 = _e291;
    let _e292 = safe_normalize_u0028_vf3_u003b((&param_1045));
    basis_3.nW = _e292;
    let _e294 = (*tW);
    param_1046 = _e294;
    let _e295 = safe_normalize_u0028_vf3_u003b((&param_1046));
    basis_3.tW = _e295;
    let _e297 = (*bW);
    param_1047 = _e297;
    let _e298 = safe_normalize_u0028_vf3_u003b((&param_1047));
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
    var param_1048: vec3<f32>;

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
    param_1048 = _e304;
    let _e305 = safe_normalize_u0028_vf3_u003b((&param_1048));
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
    var param_1049: i32;
    var param_1050: i32;
    var param_1051: i32;

    let _e290 = (*barycoord)[0u];
    let _e292 = (*faceIndices)[0u];
    param_1049 = bitcast<i32>(_e292);
    let _e294 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_1049));
    let _e297 = (*barycoord)[1u];
    let _e299 = (*faceIndices)[1u];
    param_1050 = bitcast<i32>(_e299);
    let _e301 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_1050));
    let _e305 = (*barycoord)[2u];
    let _e307 = (*faceIndices)[2u];
    param_1051 = bitcast<i32>(_e307);
    let _e309 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(texture_1, sampler_1, (&param_1051));
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
    var local_10: f32;

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
        local_10 = max(_e333, 0f);
    } else {
        local_10 = 100000000000000000000f;
    }
    let _e335 = local_10;
    return _e335;
}

fn nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes: texture_2d<f32>, nodesSampler: sampler, indices: texture_2d<f32>, indicesSampler: sampler, positions: texture_2d<f32>, positionsSampler: sampler, rayOrigin: ptr<function, vec3<f32>>, rayDirection: ptr<function, vec3<f32>>, maxDistance: ptr<function, f32>, faceIndices_1: ptr<function, vec4<u32>>, faceNormal: ptr<function, vec3<f32>>, barycoord_1: ptr<function, vec3<f32>>, side: ptr<function, f32>, dist_2: ptr<function, f32>) -> bool {
    var pointer: i32;
    var stack: array<i32, 64>;
    var closest: f32;
    var found: bool;
    var nodeIndex: i32;
    var minimum_1: vec4<f32>;
    var param_1052: i32;
    var maximum_1: vec4<f32>;
    var param_1053: i32;
    var metadata: vec4<f32>;
    var param_1054: i32;
    var param_1055: vec3<f32>;
    var param_1056: vec3<f32>;
    var param_1057: vec3<f32>;
    var param_1058: vec3<f32>;
    var offset: i32;
    var count: i32;
    var triangle: i32;
    var vertexIndices: vec3<u32>;
    var param_1059: i32;
    var p0_: vec3<f32>;
    var param_1060: i32;
    var p1_: vec3<f32>;
    var param_1061: i32;
    var p2_: vec3<f32>;
    var param_1062: i32;
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
    var phi_1184_: bool;

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
            param_1052 = (_e345 * 3i);
            let _e347 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_1052));
            minimum_1 = _e347;
            let _e348 = nodeIndex;
            param_1053 = ((_e348 * 3i) + 1i);
            let _e351 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_1053));
            maximum_1 = _e351;
            let _e352 = nodeIndex;
            param_1054 = ((_e352 * 3i) + 2i);
            let _e355 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(nodes, nodesSampler, (&param_1054));
            metadata = _e355;
            let _e356 = minimum_1;
            param_1055 = _e356.xyz;
            let _e358 = maximum_1;
            param_1056 = _e358.xyz;
            let _e360 = (*rayOrigin);
            param_1057 = _e360;
            let _e361 = (*rayDirection);
            param_1058 = _e361;
            let _e362 = nativeBvhAabbIntersect_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b((&param_1055), (&param_1056), (&param_1057), (&param_1058));
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
                        param_1059 = (_e379 + _e380);
                        let _e382 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(indices, indicesSampler, (&param_1059));
                        vertexIndices = vec3<u32>((_e382.xyz + vec3(0.5f)));
                        let _e388 = vertexIndices[0u];
                        param_1060 = bitcast<i32>(_e388);
                        let _e390 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_1060));
                        p0_ = _e390.xyz;
                        let _e393 = vertexIndices[1u];
                        param_1061 = bitcast<i32>(_e393);
                        let _e395 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_1061));
                        p1_ = _e395.xyz;
                        let _e398 = vertexIndices[2u];
                        param_1062 = bitcast<i32>(_e398);
                        let _e400 = nativeBvhTexelFetch1D_u0028_t21_u003b_p1_u003b_i1_u003b(positions, positionsSampler, (&param_1062));
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
                        phi_1184_ = _e444;
                        if _e444 {
                            let _e445 = u;
                            let _e446 = v_2;
                            phi_1184_ = ((_e445 + _e446) <= 1f);
                        }
                        let _e450 = phi_1184_;
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
    var param_1063: vec3<f32>;
    var param_1064: vec3<f32>;
    var param_1065: f32;
    var param_1066: vec4<u32>;
    var param_1067: vec3<f32>;
    var param_1068: vec3<f32>;
    var param_1069: f32;
    var param_1070: f32;

    let _e304 = (*rayOrigin_1);
    param_1063 = _e304;
    let _e305 = (*rayDirection_1);
    param_1064 = _e305;
    let _e306 = (*maxDistance_1);
    param_1065 = _e306;
    let _e307 = (*faceIndices_2);
    param_1066 = _e307;
    let _e308 = (*faceNormal_1);
    param_1067 = _e308;
    let _e309 = (*barycoord_2);
    param_1068 = _e309;
    let _e310 = (*side_1);
    param_1069 = _e310;
    let _e311 = (*dist_3);
    param_1070 = _e311;
    let _e312 = nativeBvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(nodes_1, nodesSampler_1, indices_1, indicesSampler_1, positions_1, positionsSampler_1, (&param_1063), (&param_1064), (&param_1065), (&param_1066), (&param_1067), (&param_1068), (&param_1069), (&param_1070));
    let _e313 = param_1066;
    (*faceIndices_2) = _e313;
    let _e314 = param_1067;
    (*faceNormal_1) = _e314;
    let _e315 = param_1068;
    (*barycoord_2) = _e315;
    let _e316 = param_1069;
    (*side_1) = _e316;
    let _e317 = param_1070;
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
    var param_1071: vec3<f32>;
    var param_1072: vec3<f32>;
    var param_1073: f32;
    var param_1074: vec4<u32>;
    var param_1075: vec3<f32>;
    var param_1076: vec3<f32>;
    var param_1077: f32;
    var param_1078: f32;
    var dist_closest: f32;
    var dist_ground: f32;
    var hit_ground: bool;
    var t: f32;
    var hit: bool;
    var param_1079: vec3<f32>;
    var gN: vec4<f32>;
    var param_1080: vec3<f32>;
    var param_1081: vec3<u32>;
    var gT: vec4<f32>;
    var param_1082: vec3<f32>;
    var param_1083: vec3<u32>;
    var gS: vec4<f32>;
    var param_1084: vec3<f32>;
    var param_1085: vec3<u32>;
    var local_11: vec3<f32>;
    var local_12: vec2<f32>;
    var local_13: vec3<f32>;
    var param_1086: vec3<f32>;
    var param_1087: vec3<f32>;
    var param_1088: vec3<f32>;
    var phi_1434_: bool;
    var phi_1456_: bool;

    faceIndices_surface = vec4<u32>(0u, 0u, 0u, 0u);
    faceNormal_surface = vec3<f32>(0f, 0f, 1f);
    barycoord_surface = vec3<f32>(0f, 0f, 0f);
    side_surface = 1f;
    dist_surface = 100000000000000000000f;
    let _e328 = (*rayOrigin_2);
    param_1071 = _e328;
    let _e329 = (*rayDir);
    param_1072 = _e329;
    let _e330 = (*maxDistance_2);
    param_1073 = _e330;
    let _e331 = faceIndices_surface;
    param_1074 = _e331;
    let _e332 = faceNormal_surface;
    param_1075 = _e332;
    let _e333 = barycoord_surface;
    param_1076 = _e333;
    let _e334 = side_surface;
    param_1077 = _e334;
    let _e335 = dist_surface;
    param_1078 = _e335;
    let _e336 = bvhIntersectFirstHitWithinDistance_u0028_t21_u003b_p1_u003b_t21_u003b_p1_u003b_t21_u003b_p1_u003b_vf3_u003b_vf3_u003b_f1_u003b_vu4_u003b_vf3_u003b_vf3_u003b_f1_u003b_f1_u003b(bvh_surface_nodes_texture, bvh_surface_nodes_sampler, bvh_surface_indices_texture, bvh_surface_indices_sampler, bvh_surface_positions_texture, bvh_surface_positions_sampler, (&param_1071), (&param_1072), (&param_1073), (&param_1074), (&param_1075), (&param_1076), (&param_1077), (&param_1078));
    let _e337 = param_1074;
    faceIndices_surface = _e337;
    let _e338 = param_1075;
    faceNormal_surface = _e338;
    let _e339 = param_1076;
    barycoord_surface = _e339;
    let _e340 = param_1077;
    side_surface = _e340;
    let _e341 = param_1078;
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
        phi_1434_ = _e357;
        if _e357 {
            let _e358 = t;
            let _e359 = dist_closest;
            let _e360 = (*maxDistance_2);
            phi_1434_ = (_e358 < min(_e359, _e360));
        }
        let _e364 = phi_1434_;
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
    phi_1456_ = _e371;
    if _e371 {
        let _e372 = hit_ground;
        let _e374 = dist_surface;
        let _e375 = dist_ground;
        phi_1456_ = (!(_e372) || (_e374 <= _e375));
    }
    let _e379 = phi_1456_;
    if _e379 {
        let _e380 = (*rayOrigin_2);
        let _e381 = dist_surface;
        let _e382 = (*rayDir);
        (*P_4) = (_e380 + (_e382 * _e381));
        let _e385 = barycoord_surface;
        (*baryCoord_1) = _e385;
        let _e386 = faceNormal_surface;
        param_1079 = _e386;
        let _e387 = safe_normalize_u0028_vf3_u003b((&param_1079));
        (*Ng) = _e387;
        let _e388 = barycoord_surface;
        param_1080 = _e388;
        let _e389 = faceIndices_surface;
        param_1081 = _e389.xyz;
        let _e391 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomN_surface_texture, geomN_surface_sampler, (&param_1080), (&param_1081));
        gN = _e391;
        let _e392 = barycoord_surface;
        param_1082 = _e392;
        let _e393 = faceIndices_surface;
        param_1083 = _e393.xyz;
        let _e395 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomT_surface_texture, geomT_surface_sampler, (&param_1082), (&param_1083));
        gT = _e395;
        let _e396 = barycoord_surface;
        param_1084 = _e396;
        let _e397 = faceIndices_surface;
        param_1085 = _e397.xyz;
        let _e399 = textureSampleBarycoord_u0028_t21_u003b_p1_u003b_vf3_u003b_vu3_u003b(geomS_surface_texture, geomS_surface_sampler, (&param_1084), (&param_1085));
        gS = _e399;
        let _e401 = unnamed.has_normals_surface;
        if (_e401 != 0u) {
            let _e403 = gN;
            local_11 = _e403.xyz;
        } else {
            let _e405 = (*Ng);
            local_11 = _e405;
        }
        let _e406 = local_11;
        (*Ns) = _e406;
        let _e408 = unnamed.has_uvs_surface;
        if (_e408 != 0u) {
            let _e411 = gN[3u];
            let _e413 = gT[3u];
            local_12 = vec2<f32>(_e411, _e413);
        } else {
            let _e415 = barycoord_surface;
            local_12 = _e415.xy;
        }
        let _e417 = local_12;
        (*texCoord_1) = _e417;
        let _e419 = unnamed.has_tangents_surface;
        if (_e419 != 0u) {
            let _e421 = gT;
            local_13 = _e421.xyz;
        } else {
            let _e423 = (*Ns);
            param_1086 = _e423;
            let _e424 = normalToTangent_u0028_vf3_u003b((&param_1086));
            local_13 = _e424;
        }
        let _e425 = local_13;
        (*Ts) = _e425;
        let _e426 = (*Ns);
        param_1087 = _e426;
        let _e427 = safe_normalize_u0028_vf3_u003b((&param_1087));
        let _e428 = (*Ts);
        param_1088 = _e428;
        let _e429 = safe_normalize_u0028_vf3_u003b((&param_1088));
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
    var param_1089: vec3<f32>;
    var param_1090: vec3<f32>;

    let _e286 = (*nW_1);
    param_1089 = _e286;
    let _e287 = safe_normalize_u0028_vf3_u003b((&param_1089));
    basis_4.nW = _e287;
    let _e289 = (*nW_1);
    param_1090 = _e289;
    let _e290 = normalToTangent_u0028_vf3_u003b((&param_1090));
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
    var param_1091: vec2<f32>;
    var param_1092: mat4x4<f32>;
    var param_1093: mat4x4<f32>;
    var param_1094: vec3<f32>;
    var param_1095: vec3<f32>;
    var param_1096: vec3<f32>;
    var surface_hit: bool;
    var pW_hit: vec3<f32>;
    var NsW: vec3<f32>;
    var NgW: vec3<f32>;
    var TsW: vec3<f32>;
    var BsW: vec3<f32>;
    var baryCoord_2: vec3<f32>;
    var texCoord_2: vec2<f32>;
    var material_1: i32;
    var param_1097: vec3<f32>;
    var param_1098: vec3<f32>;
    var param_1099: f32;
    var param_1100: vec3<f32>;
    var param_1101: vec3<f32>;
    var param_1102: vec3<f32>;
    var param_1103: vec3<f32>;
    var param_1104: vec3<f32>;
    var param_1105: vec3<f32>;
    var param_1106: vec2<f32>;
    var param_1107: i32;
    var param_1108: vec3<f32>;
    var param_1109: vec3<f32>;
    var basis_5: Basis;
    var param_1110: vec3<f32>;
    var param_1111: vec3<f32>;
    var param_1112: vec3<f32>;
    var param_1113: vec3<f32>;
    var param_1114: vec2<f32>;
    var param_1115: vec3<f32>;
    var param_1116: vec3<f32>;
    var param_1117: vec3<f32>;
    var param_1118: vec3<f32>;
    var param_1119: vec2<f32>;
    var winputW: vec3<f32>;
    var winputL_2: vec3<f32>;
    var param_1120: vec3<f32>;
    var param_1121: Basis;
    var rndSeed_1: u32;
    var param_1122: vec3<f32>;
    var param_1123: Basis;
    var param_1124: vec3<f32>;
    var param_1125: u32;
    var viewReflectW: vec3<f32>;
    var viewReflectL: vec3<f32>;
    var param_1126: vec3<f32>;
    var param_1127: Basis;
    var L_12: vec3<f32>;
    var param_1128: vec3<f32>;
    var param_1129: Basis;
    var param_1130: vec3<f32>;
    var param_1131: vec3<f32>;
    var param_1132: vec3<f32>;
    var param_1133: vec3<f32>;

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
    let _e345 = gl_FragCoord_1;
    pixel = (_e345.xy + vec2<f32>(0.5f, 0.5f));
    let _e348 = pixel;
    let _e350 = unnamed.resolution;
    ndc = (vec2(-1f) + ((_e348 / _e350) * 2f));
    let _e356 = unnamed.invModelMatrix;
    let _e358 = unnamed.cameraWorldMatrix;
    let _e360 = ndc;
    param_1091 = _e360;
    param_1092 = (_e356 * _e358);
    let _e362 = unnamed.invProjectionMatrix;
    param_1093 = _e362;
    ndcToCameraRay_u0028_vf2_u003b_mf44_u003b_mf44_u003b_vf3_u003b_vf3_u003b((&param_1091), (&param_1092), (&param_1093), (&param_1094), (&param_1095));
    let _e363 = param_1094;
    pW_3 = _e363;
    let _e364 = param_1095;
    dW = _e364;
    let _e365 = dW;
    dW = normalize(_e365);
    let _e368 = unnamed.sunDir;
    param_1096 = _e368;
    let _e369 = makeBasis_u0028_vf3_u003b((&param_1096));
    sunBasis = _e369;
    let _e370 = pW_3;
    param_1097 = _e370;
    let _e371 = dW;
    param_1098 = _e371;
    param_1099 = 100000000000000000000f;
    let _e372 = trace_u0028_vf3_u003b_vf3_u003b_f1_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b_i1_u003b((&param_1097), (&param_1098), (&param_1099), (&param_1100), (&param_1101), (&param_1102), (&param_1103), (&param_1104), (&param_1105), (&param_1106), (&param_1107));
    let _e373 = param_1100;
    pW_hit = _e373;
    let _e374 = param_1101;
    NsW = _e374;
    let _e375 = param_1102;
    NgW = _e375;
    let _e376 = param_1103;
    TsW = _e376;
    let _e377 = param_1104;
    BsW = _e377;
    let _e378 = param_1105;
    baryCoord_2 = _e378;
    let _e379 = param_1106;
    texCoord_2 = _e379;
    let _e380 = param_1107;
    material_1 = _e380;
    surface_hit = _e372;
    let _e381 = surface_hit;
    if !(_e381) {
        let _e383 = dW;
        param_1108 = _e383;
        let _e384 = sunRadiance_u0028_vf3_u003b((&param_1108));
        let _e385 = dW;
        param_1109 = _e385;
        let _e386 = skyRadiance_u0028_vf3_u003b((&param_1109));
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
        param_1110 = _e410;
        let _e411 = TsW;
        param_1111 = _e411;
        let _e412 = BsW;
        param_1112 = _e412;
        let _e413 = baryCoord_2;
        param_1113 = _e413;
        let _e414 = texCoord_2;
        param_1114 = _e414;
        let _e415 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_1110), (&param_1111), (&param_1112), (&param_1113), (&param_1114));
        basis_5 = _e415;
    } else {
        let _e416 = NgW;
        param_1115 = _e416;
        let _e417 = TsW;
        param_1116 = _e417;
        let _e418 = BsW;
        param_1117 = _e418;
        let _e419 = baryCoord_2;
        param_1118 = _e419;
        let _e420 = texCoord_2;
        param_1119 = _e420;
        let _e421 = makeBasis_u0028_vf3_u003b_vf3_u003b_vf3_u003b_vf3_u003b_vf2_u003b((&param_1115), (&param_1116), (&param_1117), (&param_1118), (&param_1119));
        basis_5 = _e421;
    }
    let _e422 = dW;
    winputW = -(_e422);
    let _e424 = winputW;
    param_1120 = _e424;
    let _e425 = basis_5;
    param_1121 = _e425;
    let _e426 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_1120), (&param_1121));
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
        param_1122 = _e440;
        let _e441 = basis_5;
        param_1123 = _e441;
        let _e442 = winputL_2;
        param_1124 = _e442;
        let _e443 = rndSeed_1;
        param_1125 = _e443;
        mtlx_openpbr_prepare_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_u1_u003b((&param_1122), (&param_1123), (&param_1124), (&param_1125));
        let _e444 = param_1125;
        rndSeed_1 = _e444;
    }
    let _e445 = dW;
    let _e447 = basis_5.nW;
    viewReflectW = reflect(_e445, _e447);
    let _e449 = viewReflectW;
    param_1126 = _e449;
    let _e450 = basis_5;
    param_1127 = _e450;
    let _e451 = worldToLocal_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b((&param_1126), (&param_1127));
    viewReflectL = _e451;
    let _e453 = viewReflectL[2u];
    if (_e453 <= 0f) {
        viewReflectL = vec3<f32>(0f, 0f, 1f);
    }
    let _e455 = material_1;
    if (_e455 == 1i) {
        let _e457 = pW_hit;
        param_1128 = _e457;
        let _e458 = basis_5;
        param_1129 = _e458;
        let _e459 = winputL_2;
        param_1130 = _e459;
        let _e460 = viewReflectL;
        param_1131 = _e460;
        let _e461 = mtlx_openpbr_raster_color_u0028_vf3_u003b_struct_u002d_Basis_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf3_u002d_vf21_u003b_vf3_u003b_vf3_u003b((&param_1128), (&param_1129), (&param_1130), (&param_1131));
        L_12 = _e461;
    } else {
        let _e462 = material_1;
        if (_e462 == 2i) {
            let _e464 = pW_hit;
            param_1132 = _e464;
            let _e465 = ground_albedo_u0028_vf3_u003b((&param_1132));
            L_12 = _e465;
        } else {
            let _e467 = unnamed.neutral_color;
            let _e469 = basis_5.nW;
            param_1133 = _e469;
            let _e470 = skyRadiance_u0028_vf3_u003b((&param_1133));
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
