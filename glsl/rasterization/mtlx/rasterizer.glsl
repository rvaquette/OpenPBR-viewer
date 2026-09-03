
/////////////////////////////////////////////////////////////////////////
// MaterialX BVH raster route
/////////////////////////////////////////////////////////////////////////

void main()
{
    vec2 pixel = gl_FragCoord.xy + vec2(0.5);
    vec2 ndc = -1.0 + 2.0 * (pixel / resolution.xy);

    vec3 pW;
    vec3 dW;
    ndcToCameraRay(ndc, invModelMatrix * cameraWorldMatrix, invProjectionMatrix, pW, dW);
    dW = normalize(dW);

    sunBasis = makeBasis(sunDir);

    vec3 pW_hit;
    vec3 NsW;
    vec3 NgW;
    vec3 TsW;
    vec3 BsW;
    vec3 baryCoord;
    vec2 texCoord;
    int material;
    bool surface_hit = trace(pW, dW, HUGE_DIST, pW_hit, NsW, NgW, TsW, BsW, baryCoord, texCoord, material);

    if (!surface_hit)
    {
        gl_FragColor.rgb = sunRadiance(dW) + skyRadiance(dW);
        gl_FragColor.a = 1.0;
        return;
    }

    if (dot(NsW, dW) > 0.0) NsW *= -1.0;
    if (dot(NgW, NsW) < 0.0) NgW *= -1.0;

    Basis basis;
    if (smooth_normals)
        basis = makeBasis(NsW, TsW, BsW, baryCoord, texCoord);
    else
        basis = makeBasis(NgW, TsW, BsW, baryCoord, texCoord);

    vec3 winputW = -dW;
    vec3 winputL = worldToLocal(winputW, basis);

    if (abs(winputL.z) < 1.0e-3)
    {
        gl_FragColor.rgb = vec3(0.0);
        gl_FragColor.a = 1.0;
        return;
    }

    uint rndSeed = 0u;
    if (material == MATERIAL_OPENPBR)
        mtlx_openpbr_prepare(pW_hit, basis, winputL, rndSeed);

    vec3 viewReflectW = reflect(dW, basis.nW);
    vec3 viewReflectL = worldToLocal(viewReflectW, basis);
    if (viewReflectL.z <= 0.0) viewReflectL = vec3(0.0, 0.0, 1.0);

    vec3 L;
    if (material == MATERIAL_OPENPBR)
        L = mtlx_openpbr_raster_color(pW_hit, basis, winputL, viewReflectL);
    else if (material == MATERIAL_GROUND)
        L = ground_albedo(pW_hit);
    else
        L = neutral_color * skyRadiance(basis.nW);   // neutral props: environment-lit lambert

    gl_FragColor.rgb = clamp(L, vec3(0.0), vec3(firefly_clamp));
    gl_FragColor.a = 1.0;
}
