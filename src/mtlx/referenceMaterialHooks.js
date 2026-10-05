const HOOK_PARAMETER_NAME = Object.freeze({
    thinWalled:'geometry_thin_walled',
    thinFilmWeight:'thin_film_weight',
    thinFilmThicknessNm:'thin_film_thickness',
    thinFilmIor:'thin_film_ior',
    specularIor:'specular_ior',
    specularRoughness:'specular_roughness',
    transmissionWeight:'transmission_weight',
});

function literal(type, value) {
    if (type === 'bool') return value ? 'true' : 'false';
    if (type === 'vec3') {
        const components = Array.isArray(value) ? value : [0,0,0];
        return `vec3(${components.slice(0,3).map((component) => Number(component).toFixed(8)).join(',')})`;
    }
    return Number(value).toFixed(8);
}

export function mtlxParameterExpression(type, parameterName, defaultValue, descriptors, scale = 1) {
    const parameter = descriptors.find((candidate) => candidate.name === parameterName && candidate.tableBacked !== false);
    if (!parameter) return literal(type, defaultValue);
    const texel = `mtlxGetMaterialParam(${parameter.index})`;
    const expression = type === 'bool' ? `(${texel}.x > 0.5)`
        : type === 'int' ? `int(${texel}.x)`
            : type === 'vec2' ? `${texel}.xy`
                : type === 'vec3' ? `${texel}.xyz`
                    : type === 'vec4' ? texel
                        : `${texel}.x`;
    return scale === 1 ? expression : `(${expression} * ${Number(scale).toFixed(8)})`;
}

export function emitMtlxMaterialValueFunction(type, name, key, defaultValue, descriptors) {
    if (key === 'emission') {
        const color = mtlxParameterExpression('vec3', 'emission_color', [1,1,1], descriptors);
        const luminance = mtlxParameterExpression('float', 'emission_luminance', 0, descriptors);
        if (descriptors.some((parameter) => parameter.name === 'emission_color') &&
            descriptors.some((parameter) => parameter.name === 'emission_luminance'))
            return `vec3 ${name}() { return (${color}) * (${luminance}); }`;
    }
    const parameterName = HOOK_PARAMETER_NAME[key];
    const scale = key === 'thinFilmThicknessNm' ? 1000 : 1;
    const expression = parameterName
        ? mtlxParameterExpression(type, parameterName, defaultValue, descriptors, scale)
        : literal(type, defaultValue);
    return `${type} ${name}() { return ${expression}; }`;
}

export function emitMtlxOpenPbrOpaqueFunction(summary, descriptors) {
    const thinWalled = mtlxParameterExpression('bool', 'geometry_thin_walled', summary.thinWalled, descriptors);
    const transmissionWeight = mtlxParameterExpression('float', 'transmission_weight', summary.transmissionWeight, descriptors);
    return `bool mtlx_openpbr_is_opaque() { return !(${thinWalled}) && (${transmissionWeight} <= 0.0); }`;
}

export function bindMtlxVariantHookFunctions(glsl, descriptors) {
    const opacity = descriptors.find((parameter) => parameter.name === 'geometry_opacity');
    const thinWalled = descriptors.find((parameter) => parameter.name === 'geometry_thin_walled');
    let source = String(glsl);
    if (opacity) {
        source = source.replace(/bool\s+mtlx_openpbr_is_opaque\s*\(\)\s*\{[^{}]*\}/,
            `bool mtlx_openpbr_is_opaque() { return mtlxGetMaterialParam(${opacity.index}).x >= 1.0 - 1.0e-6; }`);
    }
    if (thinWalled) {
        source = source.replace(/bool\s+mtlx_openpbr_is_thinwalled\s*\(\)\s*\{[^{}]*\}/,
            `bool mtlx_openpbr_is_thinwalled() { return mtlxGetMaterialParam(${thinWalled.index}).x > 0.5; }`);
    }
    return source;
}

export function validateMtlxVariantFeatures(registry, descriptors, enabledFeatures) {
    const descriptorIndex = new Map(descriptors.map((parameter, index) => [parameter.name, index]));
    const valueFor = (entry, name) => {
        const index = descriptorIndex.get(name);
        if (index === undefined) return 0;
        if (entry.parameterVariant === 0) return descriptors[index].value;
        if (entry.parameterVariant === 1) return descriptors[index].defaultValue;
        return entry.parameterValues[index];
    };
    for (const entry of registry.entries) {
        if (entry.kind !== 'openpbr') continue;
        const transmission = Number(valueFor(entry, 'transmission_weight')) > 0;
        const depth = Number(valueFor(entry, 'transmission_depth')) > 0;
        const thinWalled = Boolean(valueFor(entry, 'geometry_thin_walled'));
        const dispersion = Number(valueFor(entry, 'transmission_dispersion_scale')) > 0;
        const thinFilm = Number(valueFor(entry, 'thin_film_weight')) > 0;
        const requirements = [
            ['VOLUME_ENABLED', transmission && depth && !thinWalled],
            ['TRANSMISSION_ENABLED', transmission && dispersion],
            ['THIN_FILM_ENABLED', thinFilm],
        ];
        for (const [feature, required] of requirements) {
            if (required && enabledFeatures[feature] !== true)
                throw new Error(`REFERENCE_MATERIAL_FEATURE_UNAVAILABLE: scene material ${entry.sceneMaterialID} requires ${feature}`);
        }
    }
    return true;
}