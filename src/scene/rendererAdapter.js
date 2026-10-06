function fail(code,detail) {
    const error = new Error(`${code}: ${detail}`);
    error.code = code;
    throw error;
}

export function mapSceneRendererOptions(values = {},explicitOverrides = new Set()) {
    const settings = {};
    const mappings = [
        ['maxdepth','bounces'],['maxvolumesteps','max_volume_steps'],['fireflyclamp','firefly_clamp'],
        ['maxspp','max_samples'],['envmapintensity','skyPower'],
    ];
    for (const [source,target] of mappings) {
        if (Object.hasOwn(values,source) && !explicitOverrides.has(target)) settings[target] = values[source];
    }
    if (Array.isArray(values.resolution) && !explicitOverrides.has('render_size'))
        settings.resolution = Object.freeze([...values.resolution]);

    for (const key of ['hideemitters','enablebackground','transparentbackground','enabletonemap','enableaces'])
        if (Object.hasOwn(values,key)) settings[key] = values[key];
    if (values.backgroundcolor) settings.backgroundColor = Object.freeze([...values.backgroundcolor]);

    if (values.transparentbackground === true)
        fail('SCENE_RENDERER_TRANSPARENT_BACKGROUND_UNSUPPORTED','accumulation alpha currently stores sample weight');
    if (values.enableaces === true && values.enabletonemap === false)
        fail('SCENE_RENDERER_OPTION_CONFLICT','enableaces requires enabletonemap');
    if (values.envmaprotation !== undefined && values.envmaprotation !== 0)
        fail('SCENE_RENDERER_ENV_ROTATION_UNSUPPORTED','local environment rotation is not implemented yet');
    if (values.openglnormalmap === true)
        fail('SCENE_RENDERER_NORMALMAP_CONVENTION_UNSUPPORTED','scene OpenGL normal-map override is not implemented');
    return Object.freeze(settings);
}