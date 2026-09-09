// BVH compatibility layer for the Phase 1 refactor.
//
// This file centralizes the remaining `three-mesh-bvh` dependency behind a local
// API so the rest of the viewer can evolve toward a native BVH implementation
// without rewriting every callsite. The public API matches the current usage in
// the viewer: MeshBVH, MeshBVHUniformStruct, FloatVertexAttributeTexture,
// shaderStructs, shaderIntersectFunction, SAH and StaticGeometryGenerator.
//
// The actual implementation is still delegated to the upstream library for now,
// which keeps the app stable while we complete the migration out of the GLSL
// data path.

export {
    MeshBVH,
    MeshBVHUniformStruct,
    FloatVertexAttributeTexture,
    shaderStructs,
    shaderIntersectFunction,
    SAH,
    StaticGeometryGenerator,
} from 'three-mesh-bvh';
