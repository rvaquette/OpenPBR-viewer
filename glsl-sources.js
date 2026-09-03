async function loadShader(path)
{
    const response = await fetch(new URL(path, import.meta.url));
    if (!response.ok) throw new Error(`Shader fetch failed: ${response.status} ${path}`);
    return response.text();
}

export const glsl_mtlx_route_common = await loadShader('./glsl/pathtracing/mtlx/common.glsl');
export const glsl_mtlx_route_pathtracer = await loadShader('./glsl/pathtracing/mtlx/pathtracer.glsl');
export const glsl_rasterization_mtlx_common = await loadShader('./glsl/rasterization/mtlx/common.glsl');
export const glsl_rasterization_mtlx_rasterizer = await loadShader('./glsl/rasterization/mtlx/rasterizer.glsl');

export const glsl_legacy_main = await loadShader('./glsl/pathtracing/legacy/main.glsl');
export const glsl_legacy_fuzz_brdf = await loadShader('./glsl/pathtracing/legacy/fuzz_brdf.glsl');
export const glsl_legacy_coat_brdf = await loadShader('./glsl/pathtracing/legacy/coat_brdf.glsl');
export const glsl_legacy_thin_film = await loadShader('./glsl/pathtracing/legacy/thin-film.glsl');
export const glsl_legacy_metal_brdf = await loadShader('./glsl/pathtracing/legacy/metal_brdf.glsl');
export const glsl_legacy_specular_brdf = await loadShader('./glsl/pathtracing/legacy/specular_brdf.glsl');
export const glsl_legacy_specular_btdf = await loadShader('./glsl/pathtracing/legacy/specular_btdf.glsl');
export const glsl_legacy_diffuse_brdf = await loadShader('./glsl/pathtracing/legacy/diffuse_brdf.glsl');
export const glsl_legacy_diffuse_btdf = await loadShader('./glsl/pathtracing/legacy/diffuse_btdf.glsl');
export const glsl_legacy_openpbr_surface = await loadShader('./glsl/pathtracing/legacy/openpbr_surface.glsl');
export const glsl_legacy_pathtracer = await loadShader('./glsl/pathtracing/legacy/pathtracer.glsl');

export const glsl_rasterization_openpbr_frag = await loadShader('./glsl/rasterization/legacy/openpbr.frag.glsl');
export const glsl_rasterization_openpbr_vert = await loadShader('./glsl/rasterization/legacy/openpbr.vert.glsl');
export const glsl_rasterization_neutral_frag = await loadShader('./glsl/rasterization/legacy/neutral.frag.glsl');
export const glsl_rasterization_neutral_vert = await loadShader('./glsl/rasterization/legacy/neutral.vert.glsl');
