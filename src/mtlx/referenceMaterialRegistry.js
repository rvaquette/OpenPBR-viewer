export const MAX_REFERENCE_MATERIALS = 64;
export const REFERENCE_MATERIAL_KIND = Object.freeze({ props:0, openpbr:1 });

function requireRegistry(condition, code, detail) {
    if (!condition) throw new Error(`${code}: ${detail}`);
}

export function createReferenceMaterialRegistry(records, { activeMaterialKey = null, maxEntries = MAX_REFERENCE_MATERIALS,
    parameterSchema = null } = {}) {
    requireRegistry(Array.isArray(records), 'REFERENCE_MATERIAL_REGISTRY_INVALID', 'array required');
    requireRegistry(Number.isSafeInteger(maxEntries) && maxEntries > 0 && maxEntries <= MAX_REFERENCE_MATERIALS,
        'REFERENCE_MATERIAL_REGISTRY_CAPACITY', 'registry limit must be 1..64');
    requireRegistry(records.length <= maxEntries, 'REFERENCE_MATERIAL_REGISTRY_CAPACITY', `${records.length} exceeds ${maxEntries}`);
    if (parameterSchema !== null) {
        requireRegistry(Array.isArray(parameterSchema) && parameterSchema.every((parameter) =>
            typeof parameter?.name === 'string' && typeof parameter?.type === 'string'),
        'REFERENCE_MATERIAL_SCHEMA_INVALID', 'ordered name/type pairs required');
    }
    const ids = new Set();
    const entries = records.map((record, index) => {
        requireRegistry(record && typeof record === 'object', 'REFERENCE_MATERIAL_REGISTRY_ENTRY_INVALID', `entry ${index}`);
        const { sceneMaterialID, localMaterialID, materialKey, kind, parameterVariant = 0, parameterValues = [] } = record;
        requireRegistry(Number.isSafeInteger(sceneMaterialID) && sceneMaterialID >= 0 && sceneMaterialID <= 0xffffff,
            'REFERENCE_MATERIAL_REGISTRY_ID_INVALID', `scene material ID at entry ${index}`);
        requireRegistry(!ids.has(sceneMaterialID), 'REFERENCE_MATERIAL_REGISTRY_ID_DUPLICATE', `${sceneMaterialID}`);
        ids.add(sceneMaterialID);
        requireRegistry(Number.isSafeInteger(localMaterialID) && localMaterialID >= 0 && localMaterialID <= 0xffffff,
            'REFERENCE_MATERIAL_REGISTRY_LOCAL_ID_INVALID', `local material ID at entry ${index}`);
        requireRegistry(typeof materialKey === 'string' && materialKey.trim().length > 0,
            'REFERENCE_MATERIAL_REGISTRY_KEY_INVALID', `material key at entry ${index}`);
        requireRegistry(Object.hasOwn(REFERENCE_MATERIAL_KIND, kind), 'REFERENCE_MATERIAL_REGISTRY_KIND_INVALID', `${kind}`);
        requireRegistry(localMaterialID === REFERENCE_MATERIAL_KIND[kind], 'REFERENCE_MATERIAL_REGISTRY_KIND_MISMATCH',
            `${kind} must map to local pathtracer material ID ${REFERENCE_MATERIAL_KIND[kind]}`);
        requireRegistry(Number.isSafeInteger(parameterVariant) && parameterVariant >= 0 && parameterVariant < maxEntries,
            'REFERENCE_MATERIAL_REGISTRY_VARIANT_INVALID', `parameter variant at entry ${index}`);
        requireRegistry(parameterVariant !== 1 || kind === 'props', 'REFERENCE_MATERIAL_REGISTRY_VARIANT_RESERVED',
            'parameter variant 1 is reserved for generated defaults');
        requireRegistry(Array.isArray(parameterValues) && parameterValues.every((value) => {
            const components = Array.isArray(value) ? value : [value];
            return components.every((component) => typeof component === 'boolean' ||
                typeof component === 'number' && Number.isFinite(component) && Number.isFinite(Math.fround(component)));
        }), 'REFERENCE_MATERIAL_REGISTRY_PARAMETERS_INVALID', `parameter values at entry ${index}`);
        if (kind === 'props')
            requireRegistry(parameterVariant === 0 && parameterValues.length === 0,
                'REFERENCE_MATERIAL_REGISTRY_PROPS_VARIANT_INVALID', `props entry ${index} cannot use MTLX parameter variants`);
        else if (parameterVariant >= 2)
            requireRegistry(parameterValues.length > 0, 'REFERENCE_MATERIAL_REGISTRY_PARAMETERS_REQUIRED', `variant ${parameterVariant} entry ${index}`);
        if (kind === 'openpbr' && activeMaterialKey !== null) {
            requireRegistry(materialKey === activeMaterialKey, 'REFERENCE_MATERIAL_DISPATCH_MISMATCH',
                `${materialKey} does not match the active local dispatch ${activeMaterialKey}`);
        }
        return Object.freeze({ sceneMaterialID, localMaterialID, materialKey, kind,
            kindID:REFERENCE_MATERIAL_KIND[kind], parameterVariant,
            parameterValues:Object.freeze(parameterValues.map((value) => Array.isArray(value) ? Object.freeze([...value]) : value)) });
    });
    const packedData = new Float32Array(entries.length * 4);
    entries.forEach((entry, index) => {
        const offset = index * 4;
        packedData[offset] = entry.sceneMaterialID;
        packedData[offset + 1] = entry.kindID;
        packedData[offset + 2] = entry.localMaterialID;
        packedData[offset + 3] = entry.parameterVariant;
    });
    const bySceneMaterialID = new Map(entries.map((entry) => [entry.sceneMaterialID, entry]));
    const schema = parameterSchema === null ? null : Object.freeze(parameterSchema.map(({ name, type }) => Object.freeze({ name, type })));
    return Object.freeze({ entries:Object.freeze(entries), packedData, bySceneMaterialID, activeMaterialKey, maxEntries,
        parameterSchema:schema });
}

export function assertReferenceMaterialParameterSchema(registry, parameters) {
    requireRegistry(registry?.parameterSchema === null || Array.isArray(registry?.parameterSchema),
        'REFERENCE_MATERIAL_REGISTRY_INVALID', 'validated registry required');
    if (registry.parameterSchema === null) return true;
    requireRegistry(Array.isArray(parameters) && parameters.length === registry.parameterSchema.length,
        'REFERENCE_MATERIAL_PARAMETER_SCHEMA_MISMATCH', 'parameter count changed');
    for (let index = 0; index < parameters.length; index++) {
        requireRegistry(parameters[index].name === registry.parameterSchema[index].name &&
            parameters[index].type === registry.parameterSchema[index].type,
        'REFERENCE_MATERIAL_PARAMETER_SCHEMA_MISMATCH', `parameter #${index} changed`);
    }
    return true;
}

export function assertReferenceMaterialCoverage(scene, registry) {
    requireRegistry(Array.isArray(scene?.instances), 'REFERENCE_MATERIAL_SCENE_INVALID', 'scene instances required');
    requireRegistry(registry?.bySceneMaterialID instanceof Map, 'REFERENCE_MATERIAL_REGISTRY_INVALID', 'validated registry required');
    for (const instance of scene.instances) {
        requireRegistry(registry.bySceneMaterialID.has(instance.materialID), 'REFERENCE_MATERIAL_ID_UNREGISTERED',
            `scene material ID ${instance.materialID} on instance ${instance.instanceID}`);
    }
    return true;
}