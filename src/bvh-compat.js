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

import {
    MeshBVH,
    MeshBVHUniformStruct,
    FloatVertexAttributeTexture,
    shaderStructs,
    shaderIntersectFunction as upstreamShaderIntersectFunction,
    SAH,
    StaticGeometryGenerator,
} from 'three-mesh-bvh';

const shaderIntersectFunction = upstreamShaderIntersectFunction
    .replace(
        'BVH bvh, vec3 rayOrigin, vec3 rayDirection, uint offset, uint count,',
        'usampler2D bvhIndex, sampler2D bvhPosition, vec3 rayOrigin, vec3 rayDirection, uint offset, uint count,'
    )
    .replace(/bvh\.index/g, 'bvhIndex')
    .replace(/bvh\.position/g, 'bvhPosition')
    .replace(
        'float intersectsBVHNodeBounds( vec3 rayOrigin, vec3 rayDirection, BVH bvh, uint currNodeIndex )',
        'float intersectsBVHNodeBounds( vec3 rayOrigin, vec3 rayDirection, sampler2D bvhBounds, uint currNodeIndex )',
    )
    .replace(/bvh\.bvhBounds/g, 'bvhBounds')
    .replace(
        'BVH bvh, vec3 rayOrigin, vec3 rayDirection,',
        'usampler2D bvhIndex, sampler2D bvhPosition, sampler2D bvhBounds, usampler2D bvhContents, vec3 rayOrigin, vec3 rayDirection,',
    )
    .replace(
        'intersectsBVHNodeBounds( rayOrigin, rayDirection, bvh, currNodeIndex )',
        'intersectsBVHNodeBounds( rayOrigin, rayDirection, bvhBounds, currNodeIndex )',
    )
    .replace(/bvh\.bvhContents/g, 'bvhContents')
    .replace(
        'bvh, rayOrigin, rayDirection, offset, count, triangleDistance,',
        'bvhIndex, bvhPosition, rayOrigin, rayDirection, offset, count, triangleDistance,',
        )
        .replace(
        /inout uvec4 faceIndices, inout vec3 faceNormal, inout vec3 barycoord,\s*inout float side, inout float dist/g,
        'out uvec4 faceIndices, out vec3 faceNormal, out vec3 barycoord,\n out float side, out float dist',
        )
        .replace(
            /found\s*=\s*intersectTriangles\(\s*bvhIndex,\s*bvhPosition,\s*rayOrigin,\s*rayDirection,\s*offset,\s*count,\s*triangleDistance,\s*faceIndices,\s*faceNormal,\s*barycoord,\s*side,\s*dist\s*\)\s*\|\|\s*found;/,
        `uvec4 leafFaceIndices;
            vec3 leafFaceNormal;
            vec3 leafBarycoord;
            float leafSide;
            float leafDist;
            bool leafFound = intersectTriangles(
                bvhIndex, bvhPosition, rayOrigin, rayDirection, offset, count, triangleDistance,
                leafFaceIndices, leafFaceNormal, leafBarycoord, leafSide, leafDist
            );
            if (leafFound) {
                faceIndices = leafFaceIndices;
                faceNormal = leafFaceNormal;
                barycoord = leafBarycoord;
                side = leafSide;
                dist = leafDist;
            }
            found = leafFound || found;`,
    );

export {
    MeshBVH,
    MeshBVHUniformStruct,
    FloatVertexAttributeTexture,
    shaderStructs,
    shaderIntersectFunction,
    SAH,
    StaticGeometryGenerator,
};
