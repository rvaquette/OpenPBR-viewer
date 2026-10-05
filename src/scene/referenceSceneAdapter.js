import { parseSceneText, resolveSceneReferences } from './sceneLoader.js';
import { Group, Matrix4, Mesh, Quaternion, Vector3 } from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

function sceneError(code, detail) {
    const error = new Error(`${code}: ${detail}`);
    error.code = code;
    throw error;
}

export function resolveSceneResourceUrl(resource, ownerUrl) {
    if (typeof resource !== 'string' || !resource.trim()) sceneError('SCENE_RESOURCE_URL_INVALID', 'nonempty URL required');
    let url;
    try { url = new URL(resource, ownerUrl); }
    catch { sceneError('SCENE_RESOURCE_URL_INVALID', `cannot resolve '${resource}' from '${ownerUrl}'`); }
    if (!['http:','https:'].includes(url.protocol) || url.username || url.password)
        sceneError('SCENE_RESOURCE_URL_UNSAFE', `only credential-free HTTP(S) URLs are allowed: ${url.href}`);
    return url.href;
}

function requireGltfUrl(url, block) {
    const path = new URL(url).pathname.toLowerCase();
    if (!path.endsWith('.gltf') && !path.endsWith('.glb'))
        sceneError('SCENE_MESH_FORMAT_UNSUPPORTED', `${block.type} '${block.values.name || block.name || ''}' requires .gltf or .glb, got '${url}'`);
}

function selectedMaterial(scene) {
    const materials = scene.blocks.filter((block) => block.type === 'material');
    if (!materials.length) sceneError('SCENE_MATERIAL_SOURCE_REQUIRED', 'scene has no MaterialX material block');
    const referenced = new Set();
    for (const block of scene.blocks) {
        if (block.type === 'mesh') referenced.add(block.values.material);
        if (block.type === 'gltf') for (const override of block.repeated) referenced.add(override.materialName);
    }
    if (referenced.size !== 1 || !referenced.values().next().value)
        sceneError('SCENE_MATERIAL_DISPATCH_UNSUPPORTED', 'the active viewer supports one explicitly bound scene material per .scene load');
    const name = referenced.values().next().value;
    const material = materials.find((block) => block.name === name);
    if (!material) sceneError('SCENE_REFERENCE_UNKNOWN', `unknown material '${name}'`);
    const allowed = new Set(['materialx_document','materialx_inline','material_type']);
    const unsupported = Object.keys(material.values).find((key) => !allowed.has(key));
    if (unsupported) sceneError('SCENE_MATERIAL_BINDING_UNSUPPORTED', `${material.name}.${unsupported} has no active local scene binding`);
    if (material.effectiveMaterialType !== 'materialx')
        sceneError('SCENE_MATERIAL_BINDING_UNSUPPORTED', `${material.name} has no local MaterialX source`);
    return material;
}

async function readResponse(fetchImpl, url, kind, signal) {
    const response = await fetchImpl(url, { signal });
    if (!response?.ok) sceneError(`SCENE_${kind}_FETCH_FAILED`, `${response?.status ?? 'no response'} ${url}`);
    return response;
}

export async function prepareReferenceScene(sceneUrl, { fetchImpl = globalThis.fetch, signal } = {}) {
    if (typeof fetchImpl !== 'function') sceneError('SCENE_FETCH_UNAVAILABLE', 'fetch implementation is required');
    const resolvedSceneUrl = resolveSceneResourceUrl(sceneUrl, globalThis.location?.href || 'http://localhost/');
    const sceneResponse = await readResponse(fetchImpl, resolvedSceneUrl, 'DOCUMENT', signal);
    const scene = parseSceneText(await sceneResponse.text(), { url:resolvedSceneUrl });
    const material = selectedMaterial(scene);
    let materialText;
    let materialUrl = resolvedSceneUrl;
    if (material.values.materialx_document) {
        materialUrl = resolveSceneResourceUrl(material.values.materialx_document, resolvedSceneUrl);
        const materialResponse = await readResponse(fetchImpl, materialUrl, 'MATERIALX', signal);
        materialText = await materialResponse.text();
        if (!materialText.trim()) sceneError('SCENE_MATERIALX_EMPTY', `empty MaterialX document ${materialUrl}`);
    } else {
        materialText = material.values.materialx_inline;
    }

    const materialBaseUrl = new URL('.', materialUrl).href;
    const geometry = [];
    for (let blockIndex = 0; blockIndex < scene.blocks.length; blockIndex++) {
        const block = scene.blocks[blockIndex];
        if (!['mesh','gltf'].includes(block.type)) continue;
        const fileUrl = resolveSceneResourceUrl(block.values.file, resolvedSceneUrl);
        requireGltfUrl(fileUrl, block);
        geometry.push({ blockIndex, type:block.type, name:block.values.name || block.name || `${block.type}-${geometry.length}`,
            url:fileUrl, matrix:block.values.matrix || null, position:block.values.position || [0,0,0],
            rotation:block.values.rotation || [0,0,0,1], scale:block.values.scale || [1,1,1],
            overrides:block.repeated.map((override) => ({ ...override })) });
    }
    if (!geometry.length) sceneError('SCENE_GEOMETRY_REQUIRED', 'scene must contain at least one mesh or gltf block');

    const renderer = scene.blocks.find((block) => block.type === 'renderer')?.values || Object.create(null);
    const environmentUrl = renderer.envmapfile && renderer.envmapfile.toLowerCase() !== 'none'
        ? resolveSceneResourceUrl(renderer.envmapfile, resolvedSceneUrl) : (renderer.envmapfile ? null : undefined);
    const irradianceUrl = renderer.envmapirradiancefile && renderer.envmapirradiancefile.toLowerCase() !== 'none'
        ? resolveSceneResourceUrl(renderer.envmapirradiancefile, resolvedSceneUrl) : (renderer.envmapirradiancefile ? null : undefined);
    resolveSceneReferences(scene);
    return Object.freeze({ scene, sceneUrl:resolvedSceneUrl, materialName:material.name, materialText,
        materialUrl, materialBaseUrl, geometry:Object.freeze(geometry), environmentUrl, irradianceUrl,
        warnings:Object.freeze([...scene.warnings]) });
}

function sceneBlockMatrix(descriptor) {
    const matrix = new Matrix4();
    if (descriptor.matrix) {
        const values = descriptor.matrix;
        if (Math.abs(values[12]) > 1.0e-8 || Math.abs(values[13]) > 1.0e-8 ||
            Math.abs(values[14]) > 1.0e-8 || Math.abs(values[15] - 1) > 1.0e-8)
            sceneError('SCENE_MATRIX_NOT_AFFINE', `${descriptor.name} matrix must be affine row-major`);
        matrix.fromArray(values).transpose();
        if (Math.abs(matrix.determinant()) <= 1.0e-12)
            sceneError('SCENE_MATRIX_SINGULAR', `${descriptor.name} matrix is singular`);
        return matrix;
    }
    const rotation = new Quaternion(...descriptor.rotation).normalize();
    matrix.compose(new Vector3(...descriptor.position),rotation,new Vector3(...descriptor.scale));
    if (Math.abs(matrix.determinant()) <= 1.0e-12)
        sceneError('SCENE_MATRIX_SINGULAR', `${descriptor.name} transform has zero scale`);
    return matrix;
}

function disposeObjectTree(root) {
    const geometries = new Set();
    const materials = new Set();
    const textures = new Set();
    root?.traverse?.((object) => {
        if (object.geometry) geometries.add(object.geometry);
        for (const material of Array.isArray(object.material) ? object.material : [object.material]) {
            if (!material) continue;
            materials.add(material);
            for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
        }
    });
    for (const geometry of geometries) geometry.dispose();
    for (const material of materials) material.dispose();
    for (const texture of textures) texture.dispose();
}

export function disposeReferenceSceneResources(resources) {
    if (!resources) return;
    disposeObjectTree(resources.objectScene);
    resources.geometry?.dispose?.();
    resources.groundTexture?.dispose?.();
    const textures = new Set();
    for (const environment of [resources.environment,resources.irradiance]) {
        if (environment?.texture) textures.add(environment.texture);
        if (environment?.latLongTexture) textures.add(environment.latLongTexture);
        for (const texture of [environment?.importance?.equirectTexture,environment?.importance?.cdfTexture])
            if (texture) textures.add(texture);
    }
    for (const texture of textures) texture.dispose();
}

function objectNames(root) {
    const names = [];
    root?.traverse?.((object) => { if (object.isMesh) names.push(object.name); });
    return names;
}

export async function loadReferenceSceneResources(prepared, { loadGltf = (url) => new GLTFLoader().loadAsync(url),
    loadEnvironment = null, signal, isCurrent = () => true } = {}) {
    if (!prepared?.scene || !Array.isArray(prepared.geometry))
        sceneError('SCENE_PREPARED_INVALID', 'prepared scene and geometry descriptors are required');
    const loadedScenes = [];
    const environmentResults = [];
    let mergedGeometry = null;
    try {
        const settled = await Promise.allSettled(prepared.geometry.map(async (descriptor) => {
            if (signal?.aborted) sceneError('SCENE_LOAD_ABORTED', prepared.sceneUrl);
            const gltf = await loadGltf(descriptor.url,{ signal, blockIndex:descriptor.blockIndex });
            const root = gltf?.scene;
            if (!root?.traverse) sceneError('SCENE_GLTF_INVALID', `no scene root in ${descriptor.url}`);
            const names = objectNames(root);
            const group = new Group();
            group.name = descriptor.name;
            group.matrixAutoUpdate = false;
            group.matrix.copy(sceneBlockMatrix(descriptor));
            group.add(root);
            group.updateMatrixWorld(true);
            loadedScenes.push(group);
            return { descriptor, group, names };
        }));
        const failed = settled.find((result) => result.status === 'rejected');
        if (failed) throw failed.reason;
        const loaded = settled.map((result) => result.value);
        const objectNamesByBlock = new Map(loaded.filter(({ descriptor }) => descriptor.type === 'gltf')
            .map(({ descriptor,names }) => [descriptor.blockIndex,names]));
        resolveSceneReferences(prepared.scene,objectNamesByBlock);

        const geometries = [];
        for (const { group } of loaded) {
            group.traverse((object) => {
                if (!object.isMesh) return;
                const geometry = object.geometry.clone();
                geometry.applyMatrix4(object.matrixWorld);
                geometries.push(geometry);
            });
        }
        if (!geometries.length) sceneError('SCENE_GEOMETRY_EMPTY', 'loaded glTF resources contain no meshes');
        mergedGeometry = mergeGeometries(geometries,false);
        if (!mergedGeometry) sceneError('SCENE_GEOMETRY_MERGE_FAILED', 'glTF mesh attributes are incompatible');
        for (const geometry of geometries) if (geometry !== mergedGeometry) geometry.dispose();

        for (const url of [prepared.environmentUrl,prepared.irradianceUrl]) {
            if (url === undefined || url === null) { environmentResults.push(url); continue; }
            if (typeof loadEnvironment !== 'function')
                sceneError('SCENE_ENVIRONMENT_LOADER_REQUIRED', 'inject the local environment texture loader');
            const loadedEnvironment = await loadEnvironment(url,{ signal });
            environmentResults.push({ ...loadedEnvironment,url });
        }
        if (signal?.aborted || !isCurrent()) sceneError('SCENE_LOAD_SUPERSEDED', prepared.sceneUrl);

        const objectScene = new Group();
        for (const { group } of loaded) objectScene.add(group);
        return { objectScene, geometry:mergedGeometry, environment:environmentResults[0],
            irradiance:environmentResults[1], warnings:prepared.warnings };
    } catch (error) {
        for (const root of loadedScenes) disposeObjectTree(root);
        for (const environment of environmentResults) {
            if (environment?.texture) environment.texture.dispose();
            environment?.importance?.equirectTexture?.dispose();
            environment?.importance?.cdfTexture?.dispose();
        }
        mergedGeometry?.dispose();
        throw error;
    }
}