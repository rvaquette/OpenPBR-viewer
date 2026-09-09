// `?raw` imports are inlined by Vite at build time, so this works identically
// in dev, build and preview (a runtime fetch() would 404 in preview/build and
// fall back to the SPA's index.html, injecting HTML into the GLSL source).
import glsl_mtlx_route_common from './glsl/pathtracing/mtlx/common.glsl?raw';
import glsl_mtlx_route_pathtracer from './glsl/pathtracing/mtlx/pathtracer.glsl?raw';
import glsl_rasterization_mtlx_common from './glsl/rasterization/mtlx/common.glsl?raw';
import glsl_rasterization_mtlx_rasterizer from './glsl/rasterization/mtlx/rasterizer.glsl?raw';

import glsl_legacy_main from './glsl/pathtracing/legacy/main.glsl?raw';
import glsl_legacy_fuzz_brdf from './glsl/pathtracing/legacy/fuzz_brdf.glsl?raw';
import glsl_legacy_coat_brdf from './glsl/pathtracing/legacy/coat_brdf.glsl?raw';
import glsl_legacy_thin_film from './glsl/pathtracing/legacy/thin-film.glsl?raw';
import glsl_legacy_metal_brdf from './glsl/pathtracing/legacy/metal_brdf.glsl?raw';
import glsl_legacy_specular_brdf from './glsl/pathtracing/legacy/specular_brdf.glsl?raw';
import glsl_legacy_specular_btdf from './glsl/pathtracing/legacy/specular_btdf.glsl?raw';
import glsl_legacy_diffuse_brdf from './glsl/pathtracing/legacy/diffuse_brdf.glsl?raw';
import glsl_legacy_diffuse_btdf from './glsl/pathtracing/legacy/diffuse_btdf.glsl?raw';
import glsl_legacy_openpbr_surface from './glsl/pathtracing/legacy/openpbr_surface.glsl?raw';
import glsl_legacy_pathtracer from './glsl/pathtracing/legacy/pathtracer.glsl?raw';

import glsl_rasterization_openpbr_frag from './glsl/rasterization/legacy/openpbr.frag.glsl?raw';
import glsl_rasterization_openpbr_vert from './glsl/rasterization/legacy/openpbr.vert.glsl?raw';
import glsl_rasterization_neutral_frag from './glsl/rasterization/legacy/neutral.frag.glsl?raw';
import glsl_rasterization_neutral_vert from './glsl/rasterization/legacy/neutral.vert.glsl?raw';
import glsl_rasterization_legacy_bvh_rasterizer from './glsl/rasterization/legacy/bvh_rasterizer.glsl?raw';

export {
    glsl_mtlx_route_common,
    glsl_mtlx_route_pathtracer,
    glsl_rasterization_mtlx_common,
    glsl_rasterization_mtlx_rasterizer,
    glsl_legacy_main,
    glsl_legacy_fuzz_brdf,
    glsl_legacy_coat_brdf,
    glsl_legacy_thin_film,
    glsl_legacy_metal_brdf,
    glsl_legacy_specular_brdf,
    glsl_legacy_specular_btdf,
    glsl_legacy_diffuse_brdf,
    glsl_legacy_diffuse_btdf,
    glsl_legacy_openpbr_surface,
    glsl_legacy_pathtracer,
    glsl_rasterization_openpbr_frag,
    glsl_rasterization_openpbr_vert,
    glsl_rasterization_neutral_frag,
    glsl_rasterization_neutral_vert,
    glsl_rasterization_legacy_bvh_rasterizer,
};
