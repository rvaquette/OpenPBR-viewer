// `?raw` imports are inlined by Vite at build time, so this works identically
// in dev, build and preview (a runtime fetch() would 404 in preview/build and
// fall back to the SPA's index.html, injecting HTML into the GLSL source).
import glsl_mtlx_route_common from './glsl/pathtracing/mtlx/common.glsl?raw';
import glsl_mtlx_route_pathtracer from './glsl/pathtracing/mtlx/pathtracer.glsl?raw';
import glsl_rasterization_mtlx_common from './glsl/rasterization/mtlx/common.glsl?raw';
import glsl_rasterization_mtlx_rasterizer from './glsl/rasterization/mtlx/rasterizer.glsl?raw';

import glsl_rasterization_openpbr_frag from './glsl/rasterization/legacy/openpbr.frag.glsl?raw';
import glsl_rasterization_openpbr_vert from './glsl/rasterization/legacy/openpbr.vert.glsl?raw';
import glsl_rasterization_neutral_frag from './glsl/rasterization/legacy/neutral.frag.glsl?raw';
import glsl_rasterization_neutral_vert from './glsl/rasterization/legacy/neutral.vert.glsl?raw';

export {
    glsl_mtlx_route_common,
    glsl_mtlx_route_pathtracer,
    glsl_rasterization_mtlx_common,
    glsl_rasterization_mtlx_rasterizer,
    glsl_rasterization_openpbr_frag,
    glsl_rasterization_openpbr_vert,
    glsl_rasterization_neutral_frag,
    glsl_rasterization_neutral_vert,
};
