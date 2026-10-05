import { Matrix4 } from 'three';
import { BBox } from './reference/bvh/bbox.js';
import { Vec3 } from './reference/math/vec3.js';
import { BvhTranslator } from './reference/bvh/bvhTranslator.js';
import { createReferenceBvh, inspectReferenceBvh } from './referenceBlas.js';

function requireScene(condition, code, detail) {
    if (!condition) throw new Error(`${code}: ${detail}`);
}

export function normalizeReferenceTransform(input) {
    if (input?.data) requireScene(Array.isArray(input.data) && input.data.length === 4 &&
        input.data.every((column) => Array.isArray(column) && column.length === 4),
        'REFERENCE_TRANSFORM_INVALID', 'reference Mat4.data must contain four columns');
    const values = input?.isMatrix4 ? input.elements : input?.data ? input.data.flat() : input ?? new Matrix4().elements;
    requireScene(values?.length === 16 && Array.from(values).every((value) => Number.isFinite(value) && Number.isFinite(Math.fround(value))),
        'REFERENCE_TRANSFORM_INVALID', '16 finite float32-compatible column-major values required');
    requireScene(values[3] === 0 && values[7] === 0 && values[11] === 0 && values[15] === 1,
        'REFERENCE_TRANSFORM_NON_AFFINE', 'affine matrix required');
    const elements = Float32Array.from(values);
    const matrix = new Matrix4().fromArray(elements);
    const determinant = matrix.determinant();
    requireScene(Number.isFinite(determinant) && Number.isFinite(Math.fround(determinant)) && Math.fround(determinant) !== 0,
        'REFERENCE_TRANSFORM_SINGULAR', 'invertible float32 transform required');
    requireScene(matrix.clone().invert().elements.every((value) => Number.isFinite(Math.fround(value))),
        'REFERENCE_TRANSFORM_INVERSE_INVALID', 'inverse exceeds float32 range');
    return elements;
}

export function referenceInstanceBounds(bounds, elements) {
    const right = new Vec3(elements[0], elements[1], elements[2]);
    const up = new Vec3(elements[4], elements[5], elements[6]);
    const forward = new Vec3(elements[8], elements[9], elements[10]);
    const translation = new Vec3(elements[12], elements[13], elements[14]);
    const xa = right.scale(bounds.pmin.x), xb = right.scale(bounds.pmax.x);
    const ya = up.scale(bounds.pmin.y), yb = up.scale(bounds.pmax.y);
    const za = forward.scale(bounds.pmin.z), zb = forward.scale(bounds.pmax.z);
    const minimum = Vec3.min(xa, xb).add(Vec3.min(ya, yb)).add(Vec3.min(za, zb)).add(translation);
    const maximum = Vec3.max(xa, xb).add(Vec3.max(ya, yb)).add(Vec3.max(za, zb)).add(translation);
    requireScene([...minimum.toArray(), ...maximum.toArray()].every((value) => Number.isFinite(Math.fround(value))),
        'REFERENCE_INSTANCE_BOUNDS_INVALID', 'world bounds exceed float32 range');
    return new BBox(minimum, maximum);
}

function packMeshTable(meshes) {
    const verticesUVX = [];
    const normalsUVY = [];
    const vertexIndices = [];
    const meshRanges = [];
    let nodeOffset = 0;
    let triangleOffset = 0;
    for (const [meshID, mesh] of meshes.entries()) {
        requireScene(mesh?.bvh && mesh.blasStatus === 'built', 'REFERENCE_MESH_BLAS_REQUIRED', `mesh ${meshID}`);
        requireScene(mesh.normalsUVY?.length === mesh.verticesUVX.length, 'REFERENCE_MESH_ATTRIBUTES_INVALID', `mesh ${meshID}`);
        const vertexOffset = verticesUVX.length;
        meshRanges.push({ meshID, nodeOffset, triangleOffset, vertexOffset, vertexCount: mesh.verticesUVX.length,
            triangleCount: mesh.bvh.getNumIndices(), flags: mesh.flags, tangents: mesh.tangents, extraAttributes: mesh.extraAttributes });
        for (const triangle of mesh.bvh.getIndices()) {
            vertexIndices.push(vertexOffset + triangle * 3, vertexOffset + triangle * 3 + 1, vertexOffset + triangle * 3 + 2);
        }
        for (const vertex of mesh.verticesUVX) verticesUVX.push(vertex);
        for (const normal of mesh.normalsUVY) normalsUVY.push(normal);
        nodeOffset += mesh.bvh.m_nodecnt;
        triangleOffset += mesh.bvh.getNumIndices();
    }
    requireScene(nodeOffset <= 0xffffff && triangleOffset <= 0xffffff && verticesUVX.length <= 0x7fffffff,
        'REFERENCE_SCENE_CAPACITY', 'node/triangle/vertex addressing limits');
    return { verticesUVX, normalsUVY, vertexIndices: Int32Array.from(vertexIndices), meshRanges, blasNodeCount: nodeOffset };
}

function prepareInstances(meshes, inputs) {
    requireScene(Array.isArray(inputs) && inputs.length <= 0xffffff, 'REFERENCE_INSTANCES_INVALID', 'instance array required');
    return inputs.map((input, instanceID) => {
        requireScene(input && typeof input === 'object', 'REFERENCE_INSTANCE_INVALID', `instance ${instanceID}`);
        requireScene(Number.isSafeInteger(input.meshID) && input.meshID >= 0 && input.meshID < meshes.length,
            'REFERENCE_INSTANCE_MESH_INVALID', `instance ${instanceID}`);
        requireScene(Number.isSafeInteger(input.materialID) && input.materialID >= 0 && input.materialID <= 0xffffff,
            'REFERENCE_INSTANCE_MATERIAL_INVALID', `instance ${instanceID}`);
        return { name: input.name ?? `instance-${instanceID}`, instanceID, meshID: input.meshID,
            materialID: input.materialID, worldTransform: normalizeReferenceTransform(input.worldTransform ?? input.transform) };
    });
}

function assembleInstances(scene, inputs) {
    const instances = prepareInstances(scene.meshes, inputs);
    requireScene(scene.geometry.blasNodeCount + instances.length * 2 <= 0xffffff,
        'REFERENCE_SCENE_CAPACITY', 'combined BLAS/TLAS node addressing');
    const bounds = instances.map((instance) => referenceInstanceBounds(scene.meshes[instance.meshID].bvh.bounds(), instance.worldTransform));
    if (!instances.length) {
        Object.assign(scene, { instances, transforms: [], instanceBounds: [], tlas: null, translator: null,
            nodes: [], topLevelIndex: 0, activeNodeCount: 0, sceneBounds: null, tlasStats: null });
        return scene;
    }
    const tlas = createReferenceBvh('tlas');
    tlas.build(bounds);
    const stats = inspectReferenceBvh(tlas, bounds);
    requireScene(stats.maxLeafPrimitives === 1, 'REFERENCE_TLAS_LEAF_INVALID', 'exactly one instance per leaf required');
    const reuse = scene.translator && scene.instances.length === instances.length;
    const translator = reuse ? scene.translator : new BvhTranslator();
    if (reuse) translator.updateTLAS(tlas, instances);
    else translator.process(tlas, scene.meshes, instances);
    Object.assign(scene, { instances, transforms: instances.map((instance) => instance.worldTransform),
        instanceBounds: bounds, tlas, translator, nodes: translator.nodes, topLevelIndex: translator.topLevelIndex,
        activeNodeCount: scene.geometry.blasNodeCount + tlas.m_nodecnt, sceneBounds: tlas.bounds(), tlasStats: stats });
    return scene;
}

export function buildReferenceScene(meshes, instances = []) {
    requireScene(Array.isArray(meshes), 'REFERENCE_MESH_TABLE_INVALID', 'unique built mesh table required');
    requireScene(new Set(meshes).size === meshes.length, 'REFERENCE_MESH_TABLE_DUPLICATE', 'reuse a meshID instead of repeating a mesh record');
    const table = Object.freeze([...meshes]);
    const scene = { version: 1, meshes: table, geometry: packMeshTable(table), instances: [], translator: null,
        meshSignature: table.map((mesh) => ({ bvh: mesh.bvh, nodes: mesh.bvh.m_nodecnt, vertices: mesh.verticesUVX.length,
            nodeArray: mesh.bvh.m_nodes, vertexArray: mesh.verticesUVX, normalArray: mesh.normalsUVY, indices: mesh.bvh.getNumIndices() })) };
    return assembleInstances(scene, instances);
}

export function updateReferenceSceneInstances(scene, instances) {
    requireScene(scene.meshes.every((mesh, index) => mesh.bvh === scene.meshSignature[index].bvh &&
        mesh.bvh.m_nodecnt === scene.meshSignature[index].nodes && mesh.verticesUVX.length === scene.meshSignature[index].vertices &&
        mesh.bvh.m_nodes === scene.meshSignature[index].nodeArray && mesh.verticesUVX === scene.meshSignature[index].vertexArray &&
        mesh.normalsUVY === scene.meshSignature[index].normalArray && mesh.bvh.getNumIndices() === scene.meshSignature[index].indices),
        'REFERENCE_SCENE_TOPOLOGY_CHANGED', 'rebuild the complete scene after changing meshes');
    return assembleInstances(scene, instances);
}