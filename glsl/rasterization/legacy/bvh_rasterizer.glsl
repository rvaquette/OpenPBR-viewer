
/////////////////////////////////////////////////////////////////////////
// Legacy OpenPBR BVH raster route
/////////////////////////////////////////////////////////////////////////

bool bvhIntersectFirstHitWithinDistance(
    sampler2D nodes, sampler2D indices, sampler2D positions, vec3 rayOrigin, vec3 rayDirection, in float maxDistance,
    inout uvec4 faceIndices, inout vec3 faceNormal, inout vec3 barycoord,
    inout float side, inout float dist)
{
    return nativeBvhIntersectFirstHitWithinDistance(nodes, indices, positions, rayOrigin, rayDirection, maxDistance,
                                                    faceIndices, faceNormal, barycoord, side, dist);
}

bool trace(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance,
           out vec3 P, out vec3 Ns, out vec3 Ng, out vec3 Ts, out vec3 baryCoord, out int material)
{
    uvec4 faceIndices_surface = uvec4(0u);
    vec3 faceNormal_surface = vec3(0.0, 0.0, 1.0);
    vec3 barycoord_surface = vec3(0.0);
    float side_surface = 1.0;
    float dist_surface = HUGE_DIST;
    bool hit_surface = bvhIntersectFirstHitWithinDistance(bvh_surface_nodes, bvh_surface_indices, bvh_surface_positions, rayOrigin, rayDir, maxDistance,
                                                          faceIndices_surface, faceNormal_surface, barycoord_surface, side_surface, dist_surface);

    uvec4 faceIndices_props = uvec4(0u);
    vec3 faceNormal_props = vec3(0.0, 0.0, 1.0);
    vec3 barycoord_props = vec3(0.0);
    float side_props = 1.0;
    float dist_props = HUGE_DIST;
    bool hit_props = bvhIntersectFirstHitWithinDistance(bvh_props_nodes, bvh_props_indices, bvh_props_positions, rayOrigin, rayDir, min(dist_surface, maxDistance),
                                                        faceIndices_props, faceNormal_props, barycoord_props, side_props, dist_props);

    float dist_closest = HUGE_DIST;
    if (hit_surface) dist_closest = min(dist_closest, dist_surface);
    if (hit_props) dist_closest = min(dist_closest, dist_props);

    const float GROUND_Y = 0.01;
    float dist_ground = HUGE_DIST;
    bool hit_ground = false;
    if (abs(rayDir.y) > DENOM_TOLERANCE)
    {
        float t = (GROUND_Y - rayOrigin.y) / rayDir.y;
        if (t > 0.0 && t < min(dist_closest, maxDistance))
        {
            dist_ground = t;
            hit_ground = true;
        }
    }

    bool hit = hit_surface || hit_props || hit_ground;
    if (!hit) return false;

    if (hit_surface && (!hit_props || (dist_surface <= dist_props)) && (!hit_ground || (dist_surface <= dist_ground)))
    {
        P = rayOrigin + dist_surface * rayDir;
        material = MATERIAL_OPENPBR;
        baryCoord = barycoord_surface;
        Ng = safe_normalize(faceNormal_surface);
        Ns = has_normals_surface ? textureSampleBarycoord(normalAttribute_surface, barycoord_surface, faceIndices_surface.xyz).xyz : Ng;
        Ts = has_tangents_surface ? textureSampleBarycoord(tangentAttribute_surface, barycoord_surface, faceIndices_surface.xyz).xyz : normalToTangent(Ns);
    }
    else if (hit_props && (!hit_ground || (dist_props <= dist_ground)))
    {
        P = rayOrigin + dist_props * rayDir;
        material = MATERIAL_PROPS;
        baryCoord = barycoord_props;
        Ng = safe_normalize(faceNormal_props);
        Ns = has_normals_props ? textureSampleBarycoord(normalAttribute_props, barycoord_props, faceIndices_props.xyz).xyz : Ng;
        Ts = has_tangents_props ? textureSampleBarycoord(tangentAttribute_props, barycoord_props, faceIndices_props.xyz).xyz : normalToTangent(Ns);
    }
    else
    {
        P = rayOrigin + dist_ground * rayDir;
        material = MATERIAL_GROUND;
        baryCoord = vec3(0.0);
        Ng = vec3(0.0, 1.0, 0.0);
        Ns = Ng;
        Ts = vec3(1.0, 0.0, 0.0);
    }

    return true;
}

float TraceShadow(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance)
{
    int material;
    vec3 pW, nsW, ngW, TsW, baryCoord;
    bool hit = trace(rayOrigin, rayDir, maxDistance, pW, nsW, ngW, TsW, baryCoord, material);
    return hit ? 0.0 : 1.0;
}

vec3 ground_albedo(in vec3 pW)
{
    vec2 uv = vec2(pW.x, -pW.z) / 200.0 * 2.0 + 0.5;
    return texture(ground_texture, uv).rgb;
}

    vec2 uv = vec2(pW.x, pW.z) / 200.0 * 2.0 + 0.5;
{
    vec4 env = textureLod(envMap, vec3(woutputW.x, woutputW.yz), 0.0);
    return env.rgb * skyPower * skyColor;
}

vec3 shadeLegacyOpenPbr(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 winputW)
{
    uint rndSeed = uint(gl_FragCoord.x) * 1973u + uint(gl_FragCoord.y) * 9277u + 89173u;
    openpbr_prepare(pW, basis, winputL, rndSeed);

    vec3 radiance = vec3(0.0);

    vec3 Lworld = normalize(sunDir);
    vec3 Llocal = worldToLocal(Lworld, basis);
    float NdotL = max(0.0, Llocal.z);
    if (NdotL > 0.0)
    {
        float pdf = 0.0;
        vec3 f = openpbr_bsdf_evaluate(pW, basis, winputL, Llocal, pdf);
        float visibility = TraceShadow(pW + basis.nW * RAY_OFFSET, Lworld, HUGE_DIST);
        radiance += visibility * f * NdotL * sunColor * sunPower;
    }

    vec3 reflectedW = reflect(-winputW, basis.nW);
    vec3 reflectedL = worldToLocal(reflectedW, basis);
    if (reflectedL.z > 0.0)
    {
        float pdf = 0.0;
        vec3 f = openpbr_bsdf_evaluate(pW, basis, winputL, reflectedL, pdf);
        radiance += f * max(0.0, reflectedL.z) * skyRadiance(reflectedW) * PI;
    }

    return radiance;
}

void main()
{
    vec2 pixel = gl_FragCoord.xy + vec2(0.5);
    vec2 ndc = -1.0 + 2.0 * (pixel / resolution.xy);

    vec3 rayOrigin;
    vec3 rayDir;
    ndcToCameraRay(ndc, invModelMatrix * cameraWorldMatrix, invProjectionMatrix, rayOrigin, rayDir);
    rayDir = normalize(rayDir);

    vec3 pW;
    vec3 NsW;
    vec3 NgW;
    vec3 TsW;
    vec3 baryCoord;
    int material;
    bool surfaceHit = trace(rayOrigin, rayDir, HUGE_DIST, pW, NsW, NgW, TsW, baryCoord, material);

    if (!surfaceHit)
    {
        gl_FragColor.rgb = skyRadiance(rayDir);
        gl_FragColor.a = 1.0;
        return;
    }

    if (dot(NsW, rayDir) > 0.0) NsW *= -1.0;
    if (dot(NgW, NsW) < 0.0) NgW *= -1.0;

    Basis basis;
    if (smooth_normals)
        basis = makeBasis(NsW, TsW, baryCoord);
    else
        basis = makeBasis(NgW, TsW, baryCoord);
    vec3 winputW = -rayDir;
    vec3 winputL = worldToLocal(winputW, basis);

    vec3 radiance;
    if (material == MATERIAL_OPENPBR)
        radiance = shadeLegacyOpenPbr(pW, basis, winputL, winputW);
    else if (material == MATERIAL_GROUND)
        radiance = ground_albedo(pW) * (0.25 * skyPower + max(0.0, dot(basis.nW, normalize(sunDir))) * sunPower * sunColor);
    else
        radiance = neutral_color * (0.25 * skyPower + max(0.0, dot(basis.nW, normalize(sunDir))) * sunPower * sunColor);

    gl_FragColor.rgb = clamp(radiance, vec3(0.0), vec3(firefly_clamp));
    gl_FragColor.a = 1.0;
}
