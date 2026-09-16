export const SCENE_CONTRACT_VERSION = 1;

function finiteNumber(value, fallback = 0) {
    return Number.isFinite(value) ? value : fallback;
}

function vectorToArray(vector, length) {
    if (!vector) return Array(length).fill(0);
    if (Array.isArray(vector)) return vector.slice(0, length).map(value => finiteNumber(value));
    return [vector.x, vector.y, vector.z, vector.w]
        .slice(0, length)
        .map(value => finiteNumber(value));
}

function geometrySummary(mesh) {
    const geometry = mesh?.geometry;
    const position = geometry?.attributes?.position;
    return {
        vertexCount: position?.count || 0,
        indexed: Boolean(geometry?.index),
        hasNormals: Boolean(geometry?.attributes?.normal),
        hasTangents: Boolean(geometry?.attributes?.tangent),
        hasUvs: Boolean(geometry?.attributes?.uv),
        hasNeutralFlags: Boolean(geometry?.attributes?.neutralFlag)
    };
}

export function createRendererSceneContract({
    requestedBackend,
    activeBackend,
    params,
    camera,
    renderDimensions,
    surfaceMesh,
    propsMesh,
    materialTextureCount,
    lightCount,
    hasEnvironmentMap,
    hasGroundTexture,
    samples
}) {
    return Object.freeze({
        version: SCENE_CONTRACT_VERSION,
        requestedBackend,
        activeBackend,
        camera: {
            position: vectorToArray(camera?.position, 3),
            worldMatrix: camera?.matrixWorld?.elements?.slice(0, 16) || Array(16).fill(0),
            projectionMatrix: camera?.projectionMatrix?.elements?.slice(0, 16) || Array(16).fill(0)
        },
        render: {
            width: finiteNumber(renderDimensions?.w, 1),
            height: finiteNumber(renderDimensions?.h, 1),
            maxSamples: finiteNumber(params?.max_samples),
            bounces: finiteNumber(params?.bounces),
            maxVolumeSteps: finiteNumber(params?.max_volume_steps),
            fireflyClamp: finiteNumber(params?.firefly_clamp),
            paused: Boolean(params?.paused),
            samples: finiteNumber(samples)
        },
        lighting: {
            skyPower: finiteNumber(params?.skyPower),
            skyColor: vectorToArray(params?.skyColor, 3),
            sunPower: finiteNumber(params?.sunPower),
            sunColor: vectorToArray(params?.sunColor, 3),
            sunDirection: vectorToArray(params?.sunDir, 3),
            materialLightCount: finiteNumber(lightCount)
        },
        resources: {
            hasEnvironmentMap: Boolean(hasEnvironmentMap),
            hasGroundTexture: Boolean(hasGroundTexture),
            materialTextureCount: finiteNumber(materialTextureCount),
            surfaceGeometry: geometrySummary(surfaceMesh),
            propsGeometry: geometrySummary(propsMesh)
        }
    });
}