import type { Bvh } from '../bvh/bvh.js';

export interface Mesh {
    bvh: Bvh;
}

export interface MeshInstance {
    meshID: number;
    materialID: number;
}