export const DEFAULT_BVH_BACKEND = 'threejs';
export const AVAILABLE_BVH_BACKENDS = Object.freeze(['threejs','reference']);

export function resolveBvhBackend(requested = DEFAULT_BVH_BACKEND, rendererMode = 'Pathtracer MTLX') {
    if (!['threejs', 'reference'].includes(requested)) {
        throw new Error(`BVH_BACKEND_UNKNOWN: ${requested}`);
    }
    if (requested === 'reference') {
        if (rendererMode !== 'Pathtracer MTLX') {
            throw new Error(`BVH_BACKEND_ROUTE_UNSUPPORTED: reference is restricted to Pathtracer MTLX, not ${rendererMode}`);
        }
        return 'reference';
    }
    return DEFAULT_BVH_BACKEND;
}