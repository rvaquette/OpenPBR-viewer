import { parseSceneText, resolveSceneReferences } from './sceneLoader.js';
import { Float32BufferAttribute, Group, Matrix4, Quaternion, Vector3 } from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
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

function requireMeshUrl(url, block) {
    const path = new URL(url).pathname.toLowerCase();
    if (!/\.(gltf|glb|obj)$/.test(path))
        sceneError('SCENE_MESH_FORMAT_UNSUPPORTED', `${block.type} '${block.values.name || block.name || ''}' requires .gltf, .glb or .obj, got '${url}'`);
}

function sceneMaterials(scene) {
    const materials = scene.blocks.filter((block) => block.type === 'material');
    if (!materials.length) sceneError('SCENE_MATERIAL_SOURCE_REQUIRED', 'scene has no MaterialX material block');
    resolveSceneReferences(scene);
    return materials;
}

async function readResponse(fetchImpl, url, kind, signal) {
    const response = await fetchImpl(url, { signal });
    if (!response?.ok) sceneError(`SCENE_${kind}_FETCH_FAILED`, `${response?.status ?? 'no response'} ${url}`);
    return response;
}

export async function prepareReferenceScene(sceneUrl, { fetchImpl = globalThis.fetch, signal,
    createMaterialDocument = null, environmentPath, irradiancePath, environmentBaseUrl } = {}) {
    if (typeof fetchImpl !== 'function') sceneError('SCENE_FETCH_UNAVAILABLE', 'fetch implementation is required');
    const resolvedSceneUrl = resolveSceneResourceUrl(sceneUrl, globalThis.location?.href || 'http://localhost/');
    const sceneResponse = await readResponse(fetchImpl, resolvedSceneUrl, 'DOCUMENT', signal);
    const scene = parseSceneText(await sceneResponse.text(), { url:resolvedSceneUrl });
    const materials = [];
    for (const material of sceneMaterials(scene)) {
        let materialText;
        let materialUrl = resolvedSceneUrl;
        if (material.effectiveMaterialType === 'materialx') {
            const unsupported = Object.keys(material.values).find((key) => !['materialx_document','materialx_inline','material_type'].includes(key));
            if (unsupported) sceneError('SCENE_MATERIAL_BINDING_UNSUPPORTED', `${material.name}.${unsupported}`);
            if (material.values.materialx_document) {
                materialUrl = resolveSceneResourceUrl(material.values.materialx_document,resolvedSceneUrl);
                materialText = await (await readResponse(fetchImpl,materialUrl,'MATERIALX',signal)).text();
            } else materialText = material.values.materialx_inline;
        } else {
            if (!createMaterialDocument) sceneError('SCENE_MATERIAL_BINDING_UNSUPPORTED', `${material.name} requires a Disney MaterialX adapter`);
            materialText = await createMaterialDocument(material);
        }
        if (!materialText?.trim()) sceneError('SCENE_MATERIALX_EMPTY', `empty MaterialX document ${materialUrl}`);
        materials.push({ name:material.name, materialText, materialUrl,
            materialBaseUrl:new URL('.',materialUrl).href, variant:materials.length + 2 });
    }
    const { name:materialName, materialText, materialUrl, materialBaseUrl } = materials[0];
    const geometry = [];
    for (let blockIndex = 0; blockIndex < scene.blocks.length; blockIndex++) {
        const block = scene.blocks[blockIndex];
        if (!['mesh','gltf'].includes(block.type)) continue;
        const fileUrl = resolveSceneResourceUrl(block.values.file, resolvedSceneUrl);
        requireMeshUrl(fileUrl, block);
        geometry.push({ blockIndex, type:block.type, name:block.values.name || block.name || `${block.type}-${geometry.length}`,
            url:fileUrl, materialName:block.values.material || materialName, matrix:block.values.matrix || null, position:block.values.position || [0,0,0],
            rotation:block.values.rotation || [0,0,0,1], scale:block.values.scale || [1,1,1],
            overrides:block.repeated.map((override) => ({ ...override })) });
    }
    if (!geometry.length) sceneError('SCENE_GEOMETRY_REQUIRED', 'scene must contain at least one mesh or gltf block');

    const renderer = scene.blocks.find((block) => block.type === 'renderer')?.values || Object.create(null);
    const hasSceneLights = scene.blocks.some((block) => block.type === 'light');
    const envmapfile = environmentPath ?? renderer.envmapfile;
    const envmapirradiancefile = irradiancePath ?? renderer.envmapirradiancefile;
    const environmentOwner = environmentBaseUrl || resolvedSceneUrl;
    const environmentUrl = hasSceneLights ? null : envmapfile && envmapfile.toLowerCase() !== 'none'
        ? resolveSceneResourceUrl(envmapfile, environmentOwner) : (envmapfile ? null : undefined);
    const irradianceUrl = hasSceneLights ? null : envmapirradiancefile && envmapirradiancefile.toLowerCase() !== 'none'
        ? resolveSceneResourceUrl(envmapirradiancefile, environmentOwner) : (envmapirradiancefile ? null : undefined);
    resolveSceneReferences(scene);
    return Object.freeze({ scene, sceneUrl:resolvedSceneUrl, materialName, materialText, materials:Object.freeze(materials),
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

function disposeObjectTree(root, additionalMaterials = []) {
    const geometries = new Set();
    const materials = new Set();
    const textures = new Set();
    const addMaterial = (material) => {
        if (!material) return;
        materials.add(material);
        for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    };
    root?.traverse?.((object) => {
        if (object.geometry) geometries.add(object.geometry);
        for (const material of Array.isArray(object.material) ? object.material : [object.material]) addMaterial(material);
    });
    for (const material of additionalMaterials) addMaterial(material);
    for (const geometry of geometries) geometry.dispose();
    for (const material of materials) material.dispose();
    for (const texture of textures) texture.dispose();
}

export function disposeReferenceSceneResources(resources) {
    if (!resources) return;
    disposeObjectTree(resources.objectScene,resources.sourceMaterials);
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
    loadObj = (url) => new OBJLoader().loadAsync(url), loadEnvironment = null, signal, isCurrent = () => true } = {}) {
    if (!prepared?.scene || !Array.isArray(prepared.geometry))
        sceneError('SCENE_PREPARED_INVALID', 'prepared scene and geometry descriptors are required');
    const loadedScenes = [];
    const environmentResults = [];
    let mergedGeometry = null;
    try {
        const settled = await Promise.allSettled(prepared.geometry.map(async (descriptor) => {
            if (signal?.aborted) sceneError('SCENE_LOAD_ABORTED', prepared.sceneUrl);
            const isObj = new URL(descriptor.url).pathname.toLowerCase().endsWith('.obj');
            const asset = await (isObj ? loadObj : loadGltf)(descriptor.url,{ signal, blockIndex:descriptor.blockIndex });
            const root = isObj ? asset : asset?.scene;
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
        const objects = [];
        let vertexOffset = 0;
        for (const { group, descriptor } of loaded) {
            group.traverse((object) => {
                if (!object.isMesh) return;
                let materialName = descriptor.materialName;
                for (const override of descriptor.overrides) {
                    const pattern = override.pattern.replace(/[.+^${}()|[\]\\]/g,'\\$&').replace(/\*/g,'.*').replace(/\?/g,'.');
                    if (new RegExp(`^${pattern}$`,'i').test(object.name)) materialName = override.materialName;
                }
                const material = prepared.materials.find((candidate) => candidate.name === materialName);
                if (!material) sceneError('SCENE_REFERENCE_UNKNOWN',materialName);
                let geometry = object.geometry.clone();
                if (geometry.index) {
                    const expanded = geometry.toNonIndexed();
                    geometry.dispose();
                    geometry = expanded;
                }
                for (const name of Object.keys(geometry.attributes))
                    if (!['position','normal','uv'].includes(name)) geometry.deleteAttribute(name);
                if (!geometry.attributes.normal) geometry.computeVertexNormals();
                const vertexCount = geometry.attributes.position.count;
                if (!geometry.attributes.uv)
                    geometry.setAttribute('uv',new Float32BufferAttribute(new Float32Array(vertexCount * 2),2));
                geometry.setAttribute('materialVariant',new Float32BufferAttribute(new Float32Array(vertexCount).fill(material.variant),1));
                geometry.applyMatrix4(object.matrixWorld);
                objects.push({ id:`${descriptor.blockIndex}:${objects.length}`, name:`${descriptor.name}/${object.name || 'mesh'}`,
                    materialName, vertexOffset, vertexCount });
                vertexOffset += vertexCount;
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
        const sourceMaterials = new Set();
        for (const { group } of loaded) {
            group.traverse((object) => {
                for (const material of Array.isArray(object.material) ? object.material : [object.material])
                    if (material) sourceMaterials.add(material);
            });
        }
        for (const { group } of loaded) objectScene.add(group);
        return { objectScene, geometry:mergedGeometry, environment:environmentResults[0],
            irradiance:environmentResults[1], sourceMaterials, objects, warnings:prepared.warnings };
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