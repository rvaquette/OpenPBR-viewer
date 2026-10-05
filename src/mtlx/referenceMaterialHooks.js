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