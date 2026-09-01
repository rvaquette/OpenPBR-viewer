

// MaterialX pathtracer host route (feature 003).
// This file hosts the pathtracing control flow. The OpenPBR-material BSDF
// dispatch (evaluateBsdf/sampleBsdf for MATERIAL_OPENPBR) is provided by a
// per-material generated artifact injected at the marker below by the viewer
// assembler (main.js). This route MUST NOT depend on legacy _brdf/_btdf files.
//
// __MTLX_GENERATED_DISPATCH__
// The generated artifact must define:
//   vec3 mtlx_openpbr_bsdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL, inout float pdf_woutputL);
//   vec3 mtlx_openpbr_bsdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed, out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium);
//   void mtlx_openpbr_prepare(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed);
//   bool mtlx_openpbr_is_opaque();
//   bool mtlx_openpbr_is_thinwalled();


/////////////////////////////////////////////////////////////////////////
// Raytracing routines
/////////////////////////////////////////////////////////////////////////

bool bvhIntersectFirstHitWithinDistance(
	BVH bvh, vec3 rayOrigin, vec3 rayDirection, in float maxDistance,
	// output variables
	inout uvec4 faceIndices, inout vec3 faceNormal, inout vec3 barycoord,
	inout float side, inout float dist)
{
	// stack needs to be twice as long as the deepest tree we expect because
	// we push both the left and right child onto the stack every traversal
	int ptr = 0;
	uint stack[ 32 ];
	stack[ 0 ] = 0u;
	float triangleDistance = 1e20;
	bool found = false;
	while (ptr > - 1 && ptr < 32)
    {
		uint currNodeIndex = stack[ ptr ];
		ptr --;
		// check if we intersect the current bounds
		float boundsHitDistance = intersectsBVHNodeBounds( rayOrigin, rayDirection, bvh, currNodeIndex );
		if (boundsHitDistance == INFINITY ||
            boundsHitDistance > triangleDistance ||
            boundsHitDistance > maxDistance)
		        continue;
		uvec2 boundsInfo = uTexelFetch1D( bvh.bvhContents, currNodeIndex ).xy;
		bool isLeaf = bool( boundsInfo.x & 0xffff0000u );
		if (isLeaf)
        {
			uint count = boundsInfo.x & 0x0000ffffu;
			uint offset = boundsInfo.y;
            float minDistance = min(maxDistance, triangleDistance);
            bool found_intersection = intersectTriangles(bvh, rayOrigin, rayDirection, offset, count, minDistance,
				                                         faceIndices, faceNormal, barycoord, side, dist);
            if (found_intersection)
            {
                triangleDistance = minDistance;
                found = true;
            }
		}
        else
        {
			uint leftIndex = currNodeIndex + 1u;
			uint splitAxis = boundsInfo.x & 0x0000ffffu;
			uint rightIndex = boundsInfo.y;
			bool leftToRight = rayDirection[ splitAxis ] >= 0.0;
			uint c1 = leftToRight ? leftIndex : rightIndex;
			uint c2 = leftToRight ? rightIndex : leftIndex;
			// set c2 in the stack so we traverse it later. We need to keep track of a pointer in
			// the stack while we traverse. The second pointer added is the one that will be
			// traversed first
			ptr ++;
			stack[ ptr ] = c2;
			ptr ++;
			stack[ ptr ] = c1;
		}
	}
	return found;
}

bool trace(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance,
            out vec3 P, out vec3 Ns, out vec3 Ng, out vec3 Ts, out vec3 baryCoord, out vec2 texCoord, out int materialSlot, out int material)
{
    // hit results
    uvec4 faceIndices_surface = uvec4(0u);
    vec3   faceNormal_surface = vec3(0.0, 0.0, 1.0);
    vec3    barycoord_surface = vec3(0.0);
    float        side_surface = 1.0;
    float        dist_surface = HUGE_DIST;
    bool hit_surface = bvhIntersectFirstHitWithinDistance( bvh_surface, rayOrigin, rayDir, maxDistance,
                                                           faceIndices_surface, faceNormal_surface, barycoord_surface, side_surface, dist_surface );
    // Find closest BVH hit distance
    float dist_closest = HUGE_DIST;
    if (hit_surface) dist_closest = min(dist_closest, dist_surface);

    // Analytical ground plane intersection at y = 0.01 (matching rasterizer)
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

    bool hit = hit_surface || hit_ground;
    if (!hit)
        return false;

    if (hit_surface && (!hit_ground || (dist_surface <= dist_ground)))
    {
        P = rayOrigin + dist_surface*rayDir;
        baryCoord = barycoord_surface;
        Ng = safe_normalize(faceNormal_surface);
        vec4 gN = textureSampleBarycoord(geomN_surface, barycoord_surface, faceIndices_surface.xyz);
        vec4 gT = textureSampleBarycoord(geomT_surface, barycoord_surface, faceIndices_surface.xyz);
        vec4 gS = textureSampleBarycoord(geomS_surface, barycoord_surface, faceIndices_surface.xyz);
        Ns = has_normals_surface ? gN.xyz : Ng;
        texCoord = has_uvs_surface ? vec2(gN.w, gT.w) : barycoord_surface.xy;
        Ts = has_tangents_surface ? gT.xyz : normalToTangent(Ns);
        materialSlot = int(floor(gS.x + 0.5));
        material = (gS.y > 0.5) ? MATERIAL_PROPS : MATERIAL_OPENPBR;   // neutral objects merged into surface BVH
    }

    else if (hit_ground)
    {
        P = rayOrigin + dist_ground*rayDir;
        material = MATERIAL_GROUND;
        baryCoord = vec3(0.0);
        Ng = vec3(0.0, 1.0, 0.0);
        Ns = Ng;
        Ts = vec3(1.0, 0.0, 0.0);
        texCoord = vec2(P.x, -P.z) / 200.0 * 2.0 + 0.5;
        materialSlot = 0;
    }
    return true;
}


float TraceShadow(in vec3 rayOrigin, in vec3 rayDir, in float maxDistance)
{
    int material;
    int materialSlot;
    vec3 pW, nsW, ngW, TsW, baryCoord;
    vec2 texCoord;
    bool hit = trace(rayOrigin, rayDir, maxDistance,
                     pW, nsW, ngW, TsW, baryCoord, texCoord, materialSlot, material);
    if (hit && material == MATERIAL_OPENPBR && !mtlx_openpbr_is_opaque(materialSlot) && mtlx_openpbr_is_thinwalled(materialSlot))
        return 1.0;
    return hit ? 0.0 : 1.0;
}


////////////////////////////////////////////////
// "Neutral" color Lambertian BRDF for props
////////////////////////////////////////////////

vec3 neutral_brdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL,
                        inout float pdf_woutputL)
{
    if (winputL.z < DENOM_TOLERANCE || woutputL.z < DENOM_TOLERANCE) return vec3(0.0);
    pdf_woutputL = pdfHemisphereCosineWeighted(woutputL);
    if (wireframe && minComponent(basis.baryCoord) < 0.003) return vec3(0.0);
    return neutral_color / PI;
}

vec3 neutral_brdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed,
                         out vec3 woutputL, out float pdf_woutputL)
{
    if (winputL.z < DENOM_TOLERANCE) return vec3(0.0);
    woutputL = sampleHemisphereCosineWeighted(rndSeed, pdf_woutputL);
    if (wireframe && minComponent(basis.baryCoord) < 0.003) return vec3(0.0);
    return neutral_color / PI;
}

////////////////////////////////////////////////
// Ground plane textured Lambertian BRDF
////////////////////////////////////////////////

vec3 ground_albedo(in vec3 pW)
{
    // UV mapping: match rasterizer's repeat=2, offset=0.5 on 200x200 plane
    vec2 uv = vec2(pW.x, -pW.z) / 200.0 * 2.0 + 0.5;
    return texture(ground_texture, uv).rgb;
}

vec3 ground_brdf_evaluate(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL,
                           inout float pdf_woutputL)
{
    if (winputL.z < DENOM_TOLERANCE || woutputL.z < DENOM_TOLERANCE) return vec3(0.0);
    pdf_woutputL = pdfHemisphereCosineWeighted(woutputL);
    return ground_albedo(pW) / PI;
}

vec3 ground_brdf_sample(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed,
                         out vec3 woutputL, out float pdf_woutputL)
{
    if (winputL.z < DENOM_TOLERANCE) return vec3(0.0);
    woutputL = sampleHemisphereCosineWeighted(rndSeed, pdf_woutputL);
    return ground_albedo(pW) / PI;
}

//////////////////////////////////////
// BSDF dispatch
//////////////////////////////////////

vec3 evaluateBsdf(in vec3 pW, in Basis basis, in vec3 winputL, in vec3 woutputL, in int material,
                  inout float pdf_woutputL)
{
    if      (material == MATERIAL_OPENPBR) return mtlx_openpbr_bsdf_evaluate(pW, basis, winputL, woutputL, pdf_woutputL);
    else if (material == MATERIAL_GROUND)  return ground_brdf_evaluate(pW, basis, winputL, woutputL, pdf_woutputL);
    else                                   return neutral_brdf_evaluate(pW, basis, winputL, woutputL, pdf_woutputL);
}


vec3 sampleBsdf(in vec3 pW, in Basis basis, in vec3 winputL, inout uint rndSeed, in int material,
                out vec3 woutputL, out float pdf_woutputL, out Volume internal_medium)
{
    if      (material == MATERIAL_OPENPBR) return mtlx_openpbr_bsdf_sample(pW, basis, winputL, rndSeed, woutputL, pdf_woutputL, internal_medium);
    else if (material == MATERIAL_GROUND)  return ground_brdf_sample(pW, basis, winputL, rndSeed, woutputL, pdf_woutputL);
    else                                   return neutral_brdf_sample(pW, basis, winputL, rndSeed, woutputL, pdf_woutputL);
}


/////////////////////////////////////////////////////////////////////////
// lighting
/////////////////////////////////////////////////////////////////////////

Basis sunBasis;

vec3 sunRadiance(in vec3 woutputW)
{
    float theta_max = sunAngularSize * PI/180.0;
    if (dot(woutputW, sunDir) < cos(theta_max)) return vec3(0.0);
    return sunPower * sunColor;
}

float sunTotalPower()
{
    return length(sunPower * sunColor);
}

vec3 sunSample(Basis basis,
               inout vec3 woutputL, inout vec3 woutputW, inout float pdfDir,
               inout uint rndSeed)
{
    float theta_max = sunAngularSize * PI/180.0;
    float theta = theta_max * sqrt(rand(rndSeed));
    float costheta = cos(theta);
    float sintheta = sqrt(max(0.0, 1.0-costheta*costheta));
    float phi = 2.0 * PI * rand(rndSeed);
    float cosphi = cos(phi);
    float sinphi = sin(phi);
    float x = sintheta * cosphi;
    float y = sintheta * sinphi;
    float z = costheta;
    float solid_angle = PI2 *(1.0 - cos(theta_max));
    pdfDir = 1.0/solid_angle;
    woutputW = localToWorld(vec3(x, y, z), sunBasis);
    woutputL = worldToLocal(woutputW, basis);
    // (Normalize by solid angle to make total power independent of angular size)
    return sunPower * sunColor / solid_angle;
}

float sunPdf(in vec3 woutputL, in vec3 woutputW)
{
    float theta_max = sunAngularSize * PI/180.0;
    if (dot(woutputW, sunDir) < cos(theta_max)) return 0.0;
    float solid_angle = 2.0*PI*(1.0 - cos(theta_max));
    return 1.0/solid_angle;
}

float mtlxLightTotalPower(int index)
{
    return length(mtlxLightColor[index] * mtlxLightIntensity[index]);
}

float mtlxLightsTotalPower()
{
    float power = 0.0;
    for (int i = 0; i < MAX_MTLX_LIGHTS; ++i)
    {
        if (i >= mtlxLightCount) break;
        power += mtlxLightTotalPower(i);
    }
    return power;
}

vec3 mtlxLightSample(int index, in vec3 pW, in Basis basis,
                     out vec3 woutputL, out vec3 woutputW, out float maxDistance)
{
    int lightType = mtlxLightType[index];
    vec3 intensity = mtlxLightColor[index] * mtlxLightIntensity[index];
    maxDistance = HUGE_DIST;

    if (lightType == 1)
    {
        woutputW = safe_normalize(-mtlxLightDirection[index]);
    }
    else
    {
        vec3 toLight = mtlxLightPosition[index] - pW;
        float distanceToLight = max(length(toLight), DENOM_TOLERANCE);
        woutputW = toLight / distanceToLight;
        maxDistance = max(0.0, distanceToLight - 2.0 * RAY_OFFSET);
        float attenuation = pow(distanceToLight + 1.0, mtlxLightDecayRate[index] + DENOM_TOLERANCE);
        intensity /= max(attenuation, DENOM_TOLERANCE);

        if (lightType == 2)
        {
            float cosDir = dot(woutputW, -safe_normalize(mtlxLightDirection[index]));
            float low = min(mtlxLightInnerCone[index], mtlxLightOuterCone[index]);
            float high = mtlxLightInnerCone[index];
            intensity *= smoothstep(low, high, cosDir);
        }
    }

    woutputL = worldToLocal(woutputW, basis);
    return intensity;
}

vec3 skyRadiance(in vec3 woutputW)
{
    vec4 env = textureLod(envMap, vec3(woutputW.x, woutputW.yz), 0.0);
    return env.rgb * skyPower * skyColor;
}

float skyTotalPower()
{
    return length(skyPower * skyColor) * PI2;
}

vec3 skySample(in Basis basis,
                out vec3 woutputL, out vec3 woutputW, out float pdfDir,
                inout uint rndSeed)
{
    woutputL = sampleHemisphereCosineWeighted(rndSeed, pdfDir);
    woutputW = localToWorld(woutputL, basis);
    return skyRadiance(woutputW);
}

float skyPdf(in vec3 woutputL, in vec3 woutputWs)
{
    return pdfHemisphereCosineWeighted(woutputL);
}

// Sample direct radiance at the given surface vertex
vec3 LiDirect(in vec3 pW, in Basis basis,
              out vec3 shadowL, out vec3 shadowW,
              out float lightPdf,
              inout uint rndSeed)
{
    // Do 1-sample MIS between sky, sun, and MaterialX document lights.
    vec3 Li;
    {
        float w_mtlx = mtlxLightsTotalPower();
        float w_sun = (mtlxDisableSun || mtlxLightCount > 0) ? 0.0 : sunTotalPower();
        float w_sky = skyTotalPower();
        float w_total = max(DENOM_TOLERANCE, w_sun + w_sky + w_mtlx);
        float P_sun = w_sun / w_total;
        float P_sky = w_sky / w_total;
        float P_mtlx = w_mtlx / w_total;
        float pdf_sun, pdf_sky;
        float r = rand(rndSeed);
        float maxDistance = HUGE_DIST;
        if (r < P_sun)
        {
            Li = sunSample(basis, shadowL, shadowW, pdf_sun, rndSeed);
            Li += skyRadiance(shadowW);
            pdf_sky = skyPdf(shadowL, shadowW);
        }
        else if (r < P_sun + P_sky)
        {
            Li = skySample(basis, shadowL, shadowW, pdf_sky, rndSeed);
            if (w_sun > 0.0) Li += sunRadiance(shadowW);
            pdf_sun = sunPdf(shadowL, shadowW);
        }
        else
        {
            float target = rand(rndSeed) * max(w_mtlx, DENOM_TOLERANCE);
            float accum = 0.0;
            int selected = 0;
            for (int i = 0; i < MAX_MTLX_LIGHTS; ++i)
            {
                if (i >= mtlxLightCount) break;
                accum += mtlxLightTotalPower(i);
                if (target <= accum)
                {
                    selected = i;
                    break;
                }
            }
            float selectedPower = max(mtlxLightTotalPower(selected), DENOM_TOLERANCE);
            Li = mtlxLightSample(selected, pW, basis, shadowL, shadowW, maxDistance);
            pdf_sun = sunPdf(shadowL, shadowW);
            pdf_sky = skyPdf(shadowL, shadowW);
            lightPdf = P_mtlx * selectedPower / max(w_mtlx, DENOM_TOLERANCE);
            if (shadowL.z < 0.0) return vec3(0.0);
            if (maxComponent(Li) < RADIANCE_EPSILON) return vec3(0.0);
            vec3 shadowOrigin = pW + basis.nW * sign(dot(shadowW, basis.nW)) * RAY_OFFSET;
            float visibility = TraceShadow(shadowOrigin, shadowW, maxDistance);
            return visibility * Li;
        }
        lightPdf = P_sun*pdf_sun + P_sky*pdf_sky; // Light PDF according to 1-sample MIS
    }
    if (shadowL.z < 0.0) return vec3(0.0);
    if (maxComponent(Li) < RADIANCE_EPSILON) return vec3(0.0);
    vec3 shadowOrigin = pW + basis.nW * sign(dot(shadowW, basis.nW)) * RAY_OFFSET;
    float visibility = TraceShadow(shadowOrigin, shadowW, HUGE_DIST);
    return visibility * Li;
}

// Corresponding PDF of direct radiance in the given shadow ray direction (for MIS)
float LiPDF(in vec3 shadowW, in Basis basis)
{
    vec3 shadowL = worldToLocal(shadowW, basis);
    float pdf_sky = skyPdf(shadowL, shadowW);
    float pdf_sun = sunPdf(shadowL, shadowW);
    float w_sun = (mtlxDisableSun || mtlxLightCount > 0) ? 0.0 : sunTotalPower();
    float w_sky = skyTotalPower();
    float w_total = max(DENOM_TOLERANCE, w_sun + w_sky);
    float P_sun = w_sun / w_total;
    float P_sky = w_sky / w_total;
    float lightPdf = P_sun*pdf_sun + P_sky*pdf_sky; // Light PDF according to 1-sample MIS
    return lightPdf;
}

vec3 evaluateEdf(in vec3 pW, in Basis basis, in vec3 winputL)
{
    // Spatial emission: evaluate the generated surface's emission at this hit point so
    // graph-driven (masked) emission renders correctly, not just a per-material constant.
    return mtlx_openpbr_emission_at(pW, basis);
}

vec3 evaluateThinFilmEnvironmentReflection(in Basis basis, in vec3 winputL)
{
    int materialSlot = basis.materialSlot;
    if (!mtlx_openpbr_is_thinwalled(materialSlot)) return vec3(0.0);
    if (mtlx_openpbr_transmission_weight(materialSlot) <= 0.0) return vec3(0.0);
    if (mtlx_openpbr_thin_film_weight(materialSlot) <= 0.0) return vec3(0.0);
    if (mtlx_openpbr_specular_roughness(materialSlot) > 0.02) return vec3(0.0);

    float cosI = clamp(abs(winputL.z), 1.0e-4, 1.0);
    FresnelData fd = mx_init_fresnel_dielectric(
        max(mtlx_openpbr_specular_ior(materialSlot), 1.0 + 1.0e-3),
        mtlx_openpbr_thin_film_thickness_nm(materialSlot),
        mtlx_openpbr_thin_film_ior(materialSlot));
    vec3 F = mtlx_openpbr_thin_film_weight(materialSlot) * mx_compute_fresnel(cosI, fd);

    vec3 reflectedL = reflect(-winputL, vec3(0.0, 0.0, 1.0));
    if (reflectedL.z <= 0.0) return vec3(0.0);
    vec3 reflectedW = localToWorld(reflectedL, basis);
    vec3 envRadiance = sunRadiance(reflectedW) + skyRadiance(reflectedW);
    envRadiance = max(envRadiance, 0.25 * skyPower * skyColor);
    return F * envRadiance;
}


/////////////////////////////////////////////////////////////////////////
// pathtracer
/////////////////////////////////////////////////////////////////////////

#define MIN_VOLUME_STEPS_BEFORE_RR 3

int sample_channel(in vec3 albedo, in vec3 throughput, inout uint rndSeed, inout vec3 channel_probs)
{
    // Sample color channel in proportion to throughput
    vec3 w = abs(throughput);
    float sum = w.r + w.g + w.b;
    channel_probs = w / max(DENOM_TOLERANCE, sum);
    float cdf = 0.0;
    float r = rand(rndSeed);
    for (int channel=0; channel<3; ++channel)
    {
        cdf += channel_probs[channel];
        if (r < cdf)
            return channel;
    }
    return 0;
}

#ifdef VOLUME_ENABLED
bool trace_volumetric(in vec3 pW, in vec3 dW, inout uint rndSeed,
                      in Volume volume,
                      out vec3 volume_throughput,
                      out vec3 pW_hit,
                      out vec3 dW_hit,
                      out vec3 NsW_hit,
                      out vec3 NgW_hit,
                      out vec3 TsW_hit,
                      out vec3 baryCoord_hit,
                      out vec2 texCoord_hit,
                      out int materialSlot_hit,
                      out int material_hit)
{
    // Do an "analogue random-walk" in the scattering medium, i.e. following the physical path of a photon.
    // Returns whether a surface hit occurred (and the hit data), and the volumetric path throughput.
    vec3 pWalk = pW;
    vec3 dWalk = dW;
    vec3 mfp = 1.0 / max(vec3(DENOM_TOLERANCE), volume.extinction);
    volume_throughput = vec3(1.0);
    for (int n=0; n < max_volume_steps; ++n)
    {
        vec3 channel_probs;
        int channel = sample_channel(volume.albedo, volume_throughput, rndSeed, channel_probs);
        float walk_step = -log(rand(rndSeed)) * mfp[channel];
        bool surface_hit = trace(pWalk, dWalk, walk_step,
                                 pW_hit, NsW_hit, NgW_hit, TsW_hit, baryCoord_hit, texCoord_hit, materialSlot_hit, material_hit);
        if (surface_hit)
        {
            // ray hits surface within walk_step, walk terminates.
            // update walk throughput on exit (via MIS)
            float dist_to_surface = length(pW_hit - pWalk);
            vec3 transmittance = exp(-dist_to_surface * volume.extinction);
            volume_throughput *= transmittance / max(DENOM_TOLERANCE, dot(channel_probs, transmittance));
            dW_hit = dWalk;
            return true;
        }
        // Scatter within the medium, and continue walking.
        // First, make a Russian-roulette termination decision (after a minimum number of steps has been taken)
        float termination_prob = 0.0;
        if (n > MIN_VOLUME_STEPS_BEFORE_RR)
        {
            float continuation_prob = clamp(maxComponent(volume_throughput), 0.0, 1.0);
            float termination_prob = 1.0 - continuation_prob;
            if (rand(rndSeed) < termination_prob)
                break;
            volume_throughput /= continuation_prob; // update walk throughput due to RR continuation
        }

        // update walk throughput on scattering in medium (via MIS)
        vec3 transmittance = exp(-walk_step * volume.extinction);
        volume_throughput *= volume.albedo * volume.extinction * transmittance;
        volume_throughput /= max(DENOM_TOLERANCE, dot(channel_probs, volume.extinction * transmittance));

        // walk in the sampled direction, staying inside the medium
        pWalk += walk_step * dWalk;

        // scatter into a new direction sampled from Henyey-Greenstein phase function
        dWalk = samplePhaseFunction(dWalk, volume.anisotropy, rndSeed);
        dWalk = normalize(dWalk);
    }
    // max_volume_steps exhausted without surface exit: keep current throughput so high-albedo
    // SSS materials (pearl, ketchup) contribute sky radiance in last scatter direction.
    dW_hit = dWalk;
    return false;
}
#endif // VOLUME_ENABLED


void main()
{
    vec2 frag = gl_FragCoord.xy;

    // Initialize RNG
    uint rndSeed = uint(frag.x + frag.y*resolution.x);
    xorshift(rndSeed);
    rndSeed ^= uint(samples);

    // Apply FIS to obtain pixel jitter about center in pixel units
    const float filterRadius = 1.0;
    float jx = 0.5 * filterRadius * sample_triangle_filter(rand(rndSeed));
    float jy = 0.5 * filterRadius * sample_triangle_filter(rand(rndSeed));
    vec2 pixel = frag + vec2(jx, jy);

    // Get [-1, 1] normalized device coordinates,
    vec2 ndc = -1.0 + 2.0*(pixel/resolution.xy);

    // Compute primary camera ray in world-space
    vec3 pW, dW;
    ndcToCameraRay(ndc, invModelMatrix * cameraWorldMatrix, invProjectionMatrix,
                    pW, dW);
    dW = normalize(dW);

    // Setup sun basis
    sunBasis = makeBasis(sunDir);

    // Perform uni-directional pathtrace starting from the (pinhole) camera lens to estimate the primary ray radiance, L
    vec3 L = vec3(0.0);
    vec3 throughput = vec3(1.0);
    Basis basis;                      // kept for MIS book-keeping
    float bsdfPdf_continuation = 1.0; // ditto

#ifdef VOLUME_ENABLED
    // Initialize volumetric medium of camera ray
    // (NB, camera inside the volume is not handled properly in this implementation, for simplicity)
    Volume exterior_medium;
    exterior_medium.extinction = vec3(0.0);
    exterior_medium.albedo     = vec3(0.0);
    Volume current_medium = exterior_medium;
#endif
    bool in_dielectric = false;

    for (int vertex=0; vertex <= bounces; vertex++)
    {
        // Generate next surface hit, given current vertex pW and current propagation direction dW
        // (where vertex 0 corresponds to the camera position)
        bool surface_hit;
        vec3 pW_next;
        vec3 NsW_next;
        vec3 NgW_next;
        vec3 TsW_next;
        vec3 baryCoord_next;
        vec2 texCoord_next;
        int materialSlot_next;
        int material_next;

        // Check for presence of volume
#ifdef VOLUME_ENABLED
        bool inside_volume            = in_dielectric && maxComponent(current_medium.extinction) > FLT_EPSILON;
        bool inside_scattering_volume = inside_volume && maxComponent(current_medium.albedo) > FLT_EPSILON;
#else
        bool inside_volume = false;
        bool inside_scattering_volume = false;
#endif

        // If not inside a scattering volume, ray proceeds in a straight line to the next surface hit
        if (!inside_scattering_volume)
        {
            // Raycast along current propagation direction dW, from current vertex pW
            surface_hit = trace(pW, dW, HUGE_DIST,
                                pW_next, NsW_next, NgW_next, TsW_next, baryCoord_next, texCoord_next, materialSlot_next, material_next);

#ifdef VOLUME_ENABLED
            // Apply Beer-Lambert law for absorption
            if (surface_hit && inside_volume)
            {
                float ray_length = length(pW_next - pW);
                throughput *= exp(-ray_length * current_medium.extinction);
            }
#endif // VOLUME_ENABLED
        }

#ifdef VOLUME_ENABLED
        // Otherwise volumetric scattering may occur before the next surface hit
        else
        {
            vec3 volume_throughput;
            vec3 dW_next;
            surface_hit = trace_volumetric(pW, dW, rndSeed, current_medium, volume_throughput,
                                           pW_next, dW_next, NsW_next, NgW_next, TsW_next, baryCoord_next, texCoord_next, materialSlot_next, material_next);
            dW = dW_next;
            throughput *= volume_throughput;
            // Clamp throughput after volume RR amplification to prevent fireflies
            float maxVT = maxComponent(throughput);
            if (maxVT > firefly_clamp) throughput *= firefly_clamp / maxVT;
        }
#endif // VOLUME_ENABLED

        if (!surface_hit)
        {
            // Ray missed all geometry; add contribution from distant lights
            float misWeightLight = 1.0;
            // Skip MIS for volumetric paths: dW is a random scatter direction decoupled from the entry BSDF
            if (vertex > 0 && !inside_scattering_volume)
            {
                float lightPdf = LiPDF(dW, basis); // surface basis of previous hit
                misWeightLight = powerHeuristic(bsdfPdf_continuation, lightPdf);
            }
            vec3 Lenv = throughput * misWeightLight * (sunRadiance(dW) + skyRadiance(dW));
            float maxLenv = maxComponent(Lenv);
            if (maxLenv > firefly_clamp) Lenv *= firefly_clamp / maxLenv;
            L += Lenv;
            break; // Ray escapes to infinity, terminate path
        }

        // Terminate at max bounce count (biased)
        if (vertex == bounces)
            break;

        // Update to the next surface vertex.
        // First, compute the normal and thus the local vertex basis:
        pW             = pW_next;
        vec3 NsW       = NsW_next;
        vec3 NgW       = NgW_next;
        vec3 TsW       = TsW_next;
        vec3 baryCoord = baryCoord_next;
        vec2 texCoord  = texCoord_next;
        int materialSlot = materialSlot_next;
        int material   = material_next;

        if (material == MATERIAL_OPENPBR)
        {
            // Orient local shading normal so that it points from the surface interior to the exterior
            if ( (in_dielectric && dot(NsW, dW) < 0.0) ||
                (!in_dielectric && dot(NsW, dW) > 0.0))
                NsW *= -1.0;
        }
        else
        {
            // Otherwise surface is opaque, must be approaching from the exterior
            if (dot(NsW, dW) > 0.0)
                NsW *= -1.0;
        }

        // Align geometric normal into same hemisphere as shading normal
        if (dot(NgW, NsW) < 0.0) NgW *= -1.0;

        // Construct local shading frame
        if (smooth_normals)
        {
            // If the surface is opaque, but the incident ray lies below the hemisphere of the normal,
            // which can occur due to shading normals, apply the "Flipping hack" to prevent artifacts
            // (see Schüßler, "Microfacet-based Normal Mapping for Robust Monte Carlo Path Tracing")
            if (material == MATERIAL_OPENPBR && mtlx_openpbr_is_opaque(materialSlot) && dot(NsW, dW) > 0.0)
                NsW = 2.0*NgW*dot(NgW, NsW) - NsW;
            basis = makeBasis(NsW, TsW_next, baryCoord, texCoord, materialSlot);
        }
        else
            basis = makeBasis(NgW, TsW_next, baryCoord, texCoord, materialSlot);

        vec3 winputW = -dW; // winputW, points *towards* the incident direction (parallel to photon)
        vec3 winputL = worldToLocal(winputW, basis);

        // Skip shading if view direction is nearly tangent to the surface (avoids fireflies with flat normals).
        // Use abs() because inside a dielectric winputL.z is negative (z points interior→exterior by convention).
        if (abs(winputL.z) < 1.0e-3) break;

        if (debug_material_slots && material == MATERIAL_OPENPBR)
        {
            vec3 slotColor = vec3(0.9, 0.1, 0.1);
            if (basis.materialSlot == 1) slotColor = vec3(0.1, 0.8, 0.2);
            else if (basis.materialSlot == 2) slotColor = vec3(0.1, 0.35, 1.0);
            else if (basis.materialSlot == 3) slotColor = vec3(1.0, 0.75, 0.1);
            L += throughput * slotColor;
            break;
        }

        // Prepare OpenPBR if that material is used at the current vertex
        bool thin_walled = false;
        if (material == MATERIAL_OPENPBR)
        {
            mtlx_openpbr_prepare(pW, basis, winputL, rndSeed);
            thin_walled = mtlx_openpbr_is_thinwalled(materialSlot);
        }

        if (material == MATERIAL_OPENPBR)
        {
            vec3 Ltf = throughput * evaluateThinFilmEnvironmentReflection(basis, winputL);
            float maxLtf = maxComponent(Ltf);
            if (maxLtf > firefly_clamp) Ltf *= firefly_clamp / maxLtf;
            L += Ltf;
        }

        // Sample BSDF for the continuation ray direction
        Volume internal_medium;
        vec3 surface_throughput;
        {
            vec3 woutputL; // points *towards* the outgoing ray direction (opposite to photon)
            vec3 f = sampleBsdf(pW, basis, winputL, rndSeed, material, woutputL, bsdfPdf_continuation, internal_medium);
            vec3 woutputW = localToWorld(woutputL, basis);
            bool transmitted_sample = (material == MATERIAL_OPENPBR) && (winputL.z * woutputL.z < 0.0);
            float cos_out = (material == MATERIAL_OPENPBR && !transmitted_sample) ? 1.0 : abs(dot(woutputW, basis.nW));
            surface_throughput = f / max(PDF_EPSILON, bsdfPdf_continuation) * cos_out;
            // Clamp to prevent fireflies from extreme BSDF values (e.g. grazing microfacets on flat normals)
            float maxComp = maxComponent(surface_throughput);
            if (maxComp > firefly_clamp) surface_throughput *= firefly_clamp / maxComp;
            dW = woutputW; // Update continuation ray direction to the BSDF-sampled direction
        }

        // Add emission from the surface point, if present
        if (material == MATERIAL_OPENPBR)
        {
            vec3 Le = throughput * evaluateEdf(pW, basis, winputL);
            float maxLe = maxComponent(Le);
            if (maxLe > firefly_clamp) Le *= firefly_clamp / maxLe;
            L += Le;
        }

        // Check if a transmission between dielectric media has occurred,
        // and update the current_medium and dispersion state accordingly.
        bool transmitted = !thin_walled && (material == MATERIAL_OPENPBR) && (dot(winputW, NgW) * dot(dW, NgW) < 0.0);
        if (transmitted)
        {
            // Update in_dielectric state
            in_dielectric = !in_dielectric;

#ifdef VOLUME_ENABLED
            // Thus update current medium
            if (in_dielectric)
                current_medium = internal_medium;
            else
                current_medium = exterior_medium;
#endif // VOLUME_ENABLED
        } // transmitted

        // Add direct lighting term at the current surface vertex
        if (!in_dielectric && !transmitted)
        {
            vec3 shadowL, shadowW; // sampled shadow ray direction
            float lightPdf;
            vec3 Li = LiDirect(pW, basis, shadowL, shadowW, lightPdf, rndSeed);
            if (maxComponent(Li) > RADIANCE_EPSILON)
            {
                float bsdfPdf_shadow = PDF_EPSILON;
                vec3 fshadow = evaluateBsdf(pW, basis, winputL, shadowL, material, bsdfPdf_shadow);
                float misWeightLight = powerHeuristic(lightPdf, bsdfPdf_shadow);
                float cos_shadow = (material == MATERIAL_OPENPBR) ? 1.0 : abs(dot(shadowW, basis.nW));
                vec3 Ld = misWeightLight * fshadow * cos_shadow * Li / max(PDF_EPSILON, lightPdf);
                vec3 Lcontrib = throughput * Ld;
                float maxLcontrib = maxComponent(Lcontrib);
                if (maxLcontrib > firefly_clamp) Lcontrib *= firefly_clamp / maxLcontrib;
                L += Lcontrib;
            }
        } // direct lighting

        // Prepare for tracing the continuation ray.
        pW += NgW * sign(dot(dW, NgW)) * RAY_OFFSET; // perturb vertex into geometric half-space of scattered ray

        // Update path continuation throughput
        throughput *= surface_throughput;
        float maxTP = maxComponent(throughput);
        if (maxTP > firefly_clamp) throughput *= firefly_clamp / maxTP;

        // Russian roulette termination (unbiased)
        if (maxComponent(throughput) < 1.0 && vertex > 1)
        {
            float q = max(0.0, 1.0 - maxComponent(throughput));
            if (rand(rndSeed) < q)
                break;
            throughput /= 1.0 - q;
        }

    } // bounce loop

    gl_FragColor.rgb = L;
    gl_FragColor.a = accumulation_weight; // Implements Monte-Carlo accumulation via alpha blending
}
