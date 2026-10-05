const BLOCKS = new Set(['material', 'light', 'camera', 'renderer', 'mesh', 'gltf']);

export const SCENE_DIRECTIVE_POLICY = Object.freeze({
    root: Object.freeze({
        supported: Object.freeze(['material', 'light', 'camera', 'renderer', 'mesh', 'gltf']),
        adapted: Object.freeze([]),
        rejected: Object.freeze(['materialx_pure_module_url', 'materialx_generator', 'materialx_essl_template']),
    }),
    material: Object.freeze({
        supported: Object.freeze(['materialx_document', 'materialx_inline_begin', 'materialx_inline_end', 'material_type']),
        adapted: Object.freeze(['color', 'opacity', 'alphamode', 'alphacutoff', 'emission', 'metallic', 'roughness',
            'subsurface', 'speculartint', 'anisotropic', 'sheen', 'sheentint', 'clearcoat', 'clearcoatgloss',
            'spectrans', 'ior', 'albedotexture', 'metallicroughnesstexture', 'normaltexture', 'emissiontexture',
            'mediumtype', 'mediumdensity', 'mediumcolor', 'mediumanisotropy']),
        rejected: Object.freeze(['specular']),
    }),
    light: Object.freeze({
        supported: Object.freeze(['position', 'emission', 'radius', 'v1', 'v2', 'type']),
        adapted: Object.freeze([]), rejected: Object.freeze([]),
    }),
    camera: Object.freeze({
        supported: Object.freeze(['position', 'lookat', 'aperture', 'focaldist', 'fov', 'matrix']),
        adapted: Object.freeze([]), rejected: Object.freeze([]),
    }),
    renderer: Object.freeze({
        supported: Object.freeze(['resolution', 'maxdepth', 'maxvolumesteps', 'fireflyclamp', 'maxspp',
            'enabletonemap', 'enableaces', 'hideemitters', 'enablebackground', 'transparentbackground', 'backgroundcolor']),
        adapted: Object.freeze(['envmapfile', 'envmapirradiancefile', 'envmapintensity', 'envmaprotation',
            'openglnormalmap', 'independentrendersize', 'tilewidth', 'tileheight']),
        rejected: Object.freeze(['texarraywidth', 'texarrayheight', 'enablerr', 'rrdepth',
            'enableroughnessmollification', 'roughnessmollificationamt', 'enablevolumemis', 'enableuniformlight',
            'uniformlightcolor', 'sssmode']),
    }),
    mesh: Object.freeze({
        supported: Object.freeze(['name', 'file', 'material', 'matrix', 'position', 'scale', 'rotation']),
        adapted: Object.freeze([]), rejected: Object.freeze([]),
    }),
    gltf: Object.freeze({
        supported: Object.freeze(['file', 'object', 'matrix', 'position', 'scale', 'rotation']),
        adapted: Object.freeze([]), rejected: Object.freeze([]),
    }),
});

const VECTOR_ARITY = Object.freeze({
    color:3, emission:3, mediumcolor:3, position:3, lookat:3, v1:3, v2:3,
    backgroundcolor:3, scale:3, rotation:4,
});
const FLOAT_DIRECTIVES = new Set(['opacity', 'alphacutoff', 'metallic', 'roughness', 'subsurface', 'speculartint',
    'anisotropic', 'sheen', 'sheentint', 'clearcoat', 'clearcoatgloss', 'spectrans', 'ior', 'mediumdensity',
    'mediumanisotropy', 'radius', 'aperture', 'focaldist', 'fov', 'maxdepth', 'fireflyclamp', 'maxspp',
    'envmapintensity', 'envmaprotation', 'tilewidth', 'tileheight']);
const INTEGER_DIRECTIVES = new Set(['resolution', 'maxvolumesteps']);
const BOOLEAN_DIRECTIVES = new Set(['enabletonemap', 'enableaces', 'hideemitters', 'enablebackground',
    'transparentbackground', 'openglnormalmap', 'independentrendersize']);
const STRING_DIRECTIVES = new Set(['materialx_document', 'material_type', 'alphamode', 'albedotexture',
    'metallicroughnesstexture', 'normaltexture', 'emissiontexture', 'mediumtype', 'type', 'name', 'file', 'material',
    'envmapfile', 'envmapirradiancefile']);

export class SceneParseError extends Error {
    constructor(code, context, detail) {
        const location = `${context.url || '<scene>'}:${context.line}`;
        const block = context.block || 'root';
        const name = context.name ? ` '${context.name}'` : '';
        const token = context.token ? ` token '${context.token}'` : '';
        super(`${code}: ${location} block '${block}'${name}${token}: ${detail}`);
        this.name = 'SceneParseError';
        this.code = code;
        this.url = context.url || '<scene>';
        this.line = context.line;
        this.block = block;
        this.blockName = context.name || null;
        this.token = context.token || null;
    }
}

function fail(code, context, detail) {
    throw new SceneParseError(code, context, detail);
}

function stripComment(line, context) {
    let quote = '';
    let escaped = false;
    for (let index = 0; index < line.length; index++) {
        const character = line[index];
        if (escaped) { escaped = false; continue; }
        if (character === '\\' && quote) { escaped = true; continue; }
        if (quote) {
            if (character === quote) quote = '';
            continue;
        }
        if (character === '"' || character === "'") { quote = character; continue; }
        if (character === '#') return line.slice(0, index);
    }
    if (quote) fail('SCENE_QUOTE_UNTERMINATED', context, 'quoted token is missing its closing quote');
    return line;
}

function tokenize(line, context) {
    const tokens = [];
    let token = '';
    let quote = '';
    let escaped = false;
    const push = () => { if (token.length) { tokens.push(token); token = ''; } };
    for (const character of line) {
        if (escaped) { token += character; escaped = false; continue; }
        if (quote) {
            if (character === '\\') { escaped = true; continue; }
            if (character === quote) { quote = ''; continue; }
            token += character;
            continue;
        }
        if (character === '"' || character === "'") { quote = character; continue; }
        if (/	| /.test(character)) { push(); continue; }
        token += character;
    }
    if (quote) fail('SCENE_QUOTE_UNTERMINATED', context, 'quoted token is missing its closing quote');
    push();
    return tokens;
}

function directiveTokens(tokens) {
    return tokens[1] === '=' ? [tokens[0], ...tokens.slice(2)] : tokens;
}

function numbers(tokens, context, directive, arity) {
    const values = tokens.slice(1).flatMap((token) => token.split(',').filter(Boolean)).map(Number);
    if (values.length !== arity || values.some((value) => !Number.isFinite(value)))
        fail('SCENE_VALUE_ARITY_INVALID', { ...context, token:directive }, `expected ${arity} finite number(s), got ${tokens.length - 1}`);
    return values;
}

function scalarNumber(tokens, context, directive, integer = false) {
    const value = tokens.length === 2 ? Number(tokens[1]) : NaN;
    if (!Number.isFinite(value) || integer && !Number.isInteger(value))
        fail('SCENE_VALUE_INVALID', { ...context, token:directive }, `expected one finite ${integer ? 'integer' : 'number'}`);
    return value;
}

function validateResourceUrl(value, context, directive) {
    if (typeof value !== 'string' || !value) return;
    if (/^(?:file|javascript|data):/i.test(value) || /^[A-Za-z]:[\\/]/.test(value) || value.startsWith('\\\\') || value.includes('\\'))
        fail('SCENE_URL_UNSAFE', { ...context, token:directive }, 'filesystem, script, data and backslash paths are not allowed');
    if (/^[A-Za-z][A-Za-z0-9+.-]*:/.test(value) && !/^https?:\/\//i.test(value))
        fail('SCENE_URL_UNSAFE', { ...context, token:directive }, 'only HTTP(S) URLs or relative public paths are allowed');
    if (/^https?:\/\//i.test(value)) {
        try { new URL(value); } catch { fail('SCENE_URL_INVALID', { ...context, token:directive }, 'malformed HTTP(S) URL'); }
    }
}

function parseValue(blockType, directive, tokens, context) {
    if (Object.hasOwn(VECTOR_ARITY, directive)) {
        const value = numbers(tokens, context, directive, VECTOR_ARITY[directive]);
        if (directive === 'rotation' && Math.hypot(...value) <= 1.0e-12)
            fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'quaternion must be nonzero');
        if (directive === 'emission' && value.some((component) => component < 0))
            fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'emission must be nonnegative');
        return value;
    }
    if (directive === 'matrix') return numbers(tokens, context, directive, 16);
    if (directive === 'resolution') {
        const value = numbers(tokens, context, directive, 2);
        if (value.some((component) => !Number.isInteger(component) || component <= 0))
            fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'resolution values must be positive integers');
        return value;
    }
    if (FLOAT_DIRECTIVES.has(directive)) {
        const value = scalarNumber(tokens, context, directive);
        if (['aperture','maxdepth','fireflyclamp','maxspp','maxvolumesteps','tilewidth','tileheight','radius','envmapintensity'].includes(directive) && value < 0)
            fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'value must be nonnegative');
        if (directive === 'focaldist' && value <= 0) fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'focaldist must be positive');
        if (directive === 'fov' && !(value > 0 && value < 180)) fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'fov must be in (0,180) degrees');
        if (directive === 'opacity' && (value < 0 || value > 1)) fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'opacity must be in [0,1]');
        return value;
    }
    if (INTEGER_DIRECTIVES.has(directive)) {
        const value = scalarNumber(tokens, context, directive, true);
        if (value < 0) fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'integer must be nonnegative');
        return value;
    }
    if (BOOLEAN_DIRECTIVES.has(directive)) {
        if (tokens.length !== 2 || !['true','false'].includes(tokens[1]))
            fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'expected true or false');
        return tokens[1] === 'true';
    }
    if (STRING_DIRECTIVES.has(directive)) {
        if (tokens.length !== 2 || !tokens[1]) fail('SCENE_VALUE_ARITY_INVALID', { ...context, token:directive }, 'expected one nonempty value');
        return tokens[1];
    }
    if (directive === 'object') {
        if (tokens.length < 3) fail('SCENE_VALUE_ARITY_INVALID', { ...context, token:directive }, 'expected an object pattern and material name');
        const pattern = tokens.slice(1, -1).join(' ');
        const materialName = tokens[tokens.length - 1];
        if (!pattern || !materialName) fail('SCENE_VALUE_INVALID', { ...context, token:directive }, 'pattern/material cannot be empty');
        return { pattern, materialName };
    }
    fail('SCENE_DIRECTIVE_VALUE_UNSUPPORTED', { ...context, token:directive }, `no value parser for ${blockType}.${directive}`);
}

function policyFor(blockType, directive, context) {
    const policy = SCENE_DIRECTIVE_POLICY[blockType];
    if (!policy) fail('SCENE_BLOCK_UNKNOWN', context, `unknown block '${blockType}'`);
    if (policy.rejected.includes(directive))
        fail('SCENE_DIRECTIVE_REJECTED', { ...context, token:directive }, 'directive is explicitly rejected by the local contract');
    if (policy.supported.includes(directive)) return 'supported';
    if (policy.adapted.includes(directive)) return 'adapted';
    fail('SCENE_DIRECTIVE_UNKNOWN', { ...context, token:directive }, `unknown ${blockType} directive`);
}

function readLogicalLine(lines, index, url, block, name) {
    const original = lines[index] ?? '';
    const line = index === 0 ? original.replace(/^\uFEFF/, '') : original;
    const context = { url, line:index + 1, block, name };
    return { text:stripComment(line, context).trim(), context, raw:line };
}

function createBlock(type, name, line) {
    return { type, name, line, values:Object.create(null), repeated:[], directives:[] };
}

function validateBlock(block, url) {
    const context = { url, line:block.line, block:block.type, name:block.name };
    if (block.type === 'material') {
        const hasDocument = typeof block.values.materialx_document === 'string';
        const hasInline = typeof block.values.materialx_inline === 'string';
        if (hasDocument && hasInline) fail('SCENE_MATERIALX_SOURCE_AMBIGUOUS', context, 'provide exactly one document or inline source');
        if ((hasDocument && !block.values.materialx_document.trim()) || (hasInline && !block.values.materialx_inline.trim()))
            fail('SCENE_MATERIALX_SOURCE_EMPTY', context, 'MaterialX source cannot be empty');
        const declared = block.values.material_type;
        if (declared && !['materialx','disney'].includes(declared.toLowerCase()))
            fail('SCENE_MATERIAL_TYPE_INVALID', { ...context, token:'material_type' }, `unsupported material type '${declared}'`);
        if (declared?.toLowerCase() === 'materialx' && !hasDocument && !hasInline)
            fail('SCENE_MATERIALX_SOURCE_REQUIRED', context, 'material_type materialx requires one source');
        if (hasDocument || hasInline) block.effectiveMaterialType = 'materialx';
        else block.effectiveMaterialType = declared?.toLowerCase() || 'disney';
        if (block.values.alphamode && !['opaque','blend','mask'].includes(block.values.alphamode.toLowerCase()))
            fail('SCENE_VALUE_INVALID', { ...context, token:'alphamode' }, 'expected opaque, blend or mask');
        if (block.values.alphacutoff !== undefined && (block.values.alphacutoff < 0 || block.values.alphacutoff > 1))
            fail('SCENE_VALUE_INVALID', { ...context, token:'alphacutoff' }, 'alphacutoff must be in [0,1]');
        if (block.values.mediumtype && !['none','absorb','scatter','emissive'].includes(block.values.mediumtype.toLowerCase()))
            fail('SCENE_VALUE_INVALID', { ...context, token:'mediumtype' }, 'unknown medium type');
        validateResourceUrl(block.values.materialx_document, context, 'materialx_document');
        for (const directive of ['albedotexture','metallicroughnesstexture','normaltexture','emissiontexture'])
            validateResourceUrl(block.values[directive], context, directive);
    }
    if (block.type === 'light') {
        const type = block.values.type?.toLowerCase();
        if (!type) fail('SCENE_REQUIRED_DIRECTIVE', context, 'light type is required');
        if (!['quad','sphere','distant'].includes(type)) fail('SCENE_VALUE_INVALID', { ...context, token:'type' }, `unsupported light type '${type}'`);
        if (type === 'sphere' && !(block.values.radius > 0)) fail('SCENE_VALUE_INVALID', { ...context, token:'radius' }, 'sphere radius must be positive');
        if (type === 'distant' && (!block.values.position || Math.hypot(...block.values.position) <= 1.0e-12))
            fail('SCENE_VALUE_INVALID', { ...context, token:'position' }, 'distant light position must encode a nonzero direction');
        if (block.values.emission?.some((component) => component < 0))
            fail('SCENE_VALUE_INVALID', { ...context, token:'emission' }, 'emission must be nonnegative');
        if (type === 'quad') {
            const position = block.values.position;
            const v1 = block.values.v1;
            const v2 = block.values.v2;
            if (!position || !v1 || !v2) fail('SCENE_REQUIRED_DIRECTIVE', context, 'quad requires position, v1 and v2');
            const u = v1.map((value,index) => value - position[index]);
            const v = v2.map((value,index) => value - position[index]);
            const dot = u.reduce((sum,value,index) => sum + value * v[index],0);
            const lengths = Math.hypot(...u) * Math.hypot(...v);
            if (!(lengths > 0)) fail('SCENE_VALUE_INVALID', { ...context, token:'v1/v2' }, 'quad edges must be nonzero');
            if (Math.abs(dot) > 1.0e-6 * lengths) fail('LIGHT_QUAD_NON_ORTHOGONAL', context, 'quad edges must be orthogonal');
        }
    }
    if (block.type === 'camera') {
        if (block.values.matrix && (block.values.position || block.values.lookat || block.values.rotation))
            block.warnings.push('CAMERA_MATRIX_OVERRIDES_TRS');
        if (!block.values.matrix && (!block.values.position || !block.values.lookat))
            fail('SCENE_REQUIRED_DIRECTIVE', context, 'camera requires matrix or position and lookat');
        const aperture = block.values.aperture ?? 0;
        const focaldist = block.values.focaldist ?? 1;
        const fov = block.values.fov ?? 45;
        if (aperture < 0) fail('SCENE_VALUE_INVALID', { ...context, token:'aperture' }, 'aperture must be nonnegative');
        if (!(focaldist > 0)) fail('SCENE_VALUE_INVALID', { ...context, token:'focaldist' }, 'focaldist must be positive');
        if (!(fov > 0 && fov < 180)) fail('SCENE_VALUE_INVALID', { ...context, token:'fov' }, 'fov must be in (0,180) degrees');
        if (block.values.position && block.values.lookat && block.values.position.every((value,index) => value === block.values.lookat[index]))
            fail('SCENE_VALUE_INVALID', context, 'camera position and lookat must differ');
        block.values.aperture = aperture; block.values.focaldist = focaldist; block.values.fov = fov;
    }
    if (block.type === 'renderer') {
        if (block.values.tilewidth !== undefined || block.values.tileheight !== undefined)
            block.warnings.push('SCENE_OPTION_NO_RUNTIME_EFFECT');
        for (const directive of ['envmapfile','envmapirradiancefile']) {
            if (block.values[directive] && block.values[directive].toLowerCase() !== 'none')
                validateResourceUrl(block.values[directive],context,directive);
        }
    }
    if (['mesh','gltf'].includes(block.type)) {
        if (!block.values.file) fail('SCENE_REQUIRED_DIRECTIVE', context, `${block.type} requires file`);
        validateResourceUrl(block.values.file, context, 'file');
        if (block.values.matrix && (block.values.position || block.values.scale || block.values.rotation))
            block.warnings.push(`${block.type.toUpperCase()}_MATRIX_OVERRIDES_TRS`);
        if (block.type === 'mesh' && !block.values.material)
            fail('SCENE_REQUIRED_DIRECTIVE', context, 'mesh requires an explicit material binding');
    }
}

export function parseSceneText(text, { url = '<scene>' } = {}) {
    if (typeof text !== 'string') throw new TypeError('SCENE_TEXT_INVALID: scene text must be a string');
    const lines = text.replace(/\r\n?/g,'\n').split('\n');
    const blocks = [];
    const rootOptions = Object.create(null);
    const warnings = [];
    const singleton = new Set();
    const materialNames = new Set();
    let index = 0;
    while (index < lines.length) {
        const logical = readLogicalLine(lines,index,url,'root',null);
        if (!logical.text) { index++; continue; }
        const tokens = directiveTokens(tokenize(logical.text,logical.context));
        const directive = tokens[0];
        const policy = SCENE_DIRECTIVE_POLICY.root;
        if (policy.rejected.includes(directive))
            fail('SCENE_DIRECTIVE_REJECTED',{...logical.context,token:directive},'root directive is explicitly rejected');
        if (!BLOCKS.has(directive))
            fail('SCENE_BLOCK_UNKNOWN',{...logical.context,token:directive},'expected a supported root block');
        const name = directive === 'material' ? tokens[1] : null;
        if (directive === 'material' && (tokens.length !== 2 || !name))
            fail('SCENE_BLOCK_HEADER_INVALID',logical.context,'material block requires exactly one name');
        if (directive !== 'material' && tokens.length !== 1)
            fail('SCENE_BLOCK_HEADER_INVALID',logical.context,`${directive} block has no name`);
        if (directive === 'material') {
            if (materialNames.has(name)) fail('SCENE_DUPLICATE_MATERIAL', {...logical.context,name},'material names must be unique');
            materialNames.add(name);
        }
        if (['camera','renderer'].includes(directive)) {
            if (singleton.has(directive)) fail('SCENE_DUPLICATE_BLOCK',{...logical.context,block:directive},'block may appear only once');
            singleton.add(directive);
        }
        const block = createBlock(directive,name,index+1);
        block.warnings = [];
        index++;
        let open = false;
        while (index < lines.length) {
            const braceLine = readLogicalLine(lines,index,url,directive,name);
            if (!braceLine.text) { index++; continue; }
            if (braceLine.text === '{') { open = true; index++; break; }
            fail('SCENE_BLOCK_BRACE_INVALID',braceLine.context,'opening brace must be on its own line after the block header');
        }
        if (!open) fail('SCENE_BLOCK_UNCLOSED',{url,line:block.line,block:directive,name},'missing opening brace');
        let closed = false;
        while (index < lines.length) {
            const logicalLine = readLogicalLine(lines,index,url,directive,name);
            if (!logicalLine.text) { index++; continue; }
            if (logicalLine.text === '}') { closed = true; index++; break; }
            if (/[{}]/.test(logicalLine.text)) fail('SCENE_BLOCK_BRACE_INVALID',logicalLine.context,'braces must be on their own lines');
            const values = directiveTokens(tokenize(logicalLine.text,logicalLine.context));
            const key = values[0];
            const fieldPolicy = policyFor(directive,key,logicalLine.context);
            if (fieldPolicy === 'adapted' && (key === 'tilewidth' || key === 'tileheight'))
                warnings.push({ code:'SCENE_OPTION_NO_RUNTIME_EFFECT',url,line:index+1,block:directive,name,token:key });
            if (key === 'materialx_inline_begin') {
                const beginLine = index + 1;
                if (directive !== 'material' || values.length !== 1) fail('SCENE_INLINE_CONTEXT_INVALID',logicalLine.context,'inline source is only valid as a material marker');
                if (Object.hasOwn(block.values,'materialx_inline')) fail('SCENE_DUPLICATE_DIRECTIVE',logicalLine.context,'inline source already declared');
                const inlineLines = [];
                index++;
                let terminated = false;
                while (index < lines.length) {
                    const raw = lines[index].replace(/\r$/,'');
                    if (raw.trim() === 'materialx_inline_end') { terminated = true; index++; break; }
                    if (raw.length > 2048) fail('SCENE_INLINE_LINE_TOO_LONG',{url,line:index+1,block:directive,name,token:key},'inline XML line exceeds 2048 characters');
                    inlineLines.push(raw); index++;
                }
                if (!terminated) fail('SCENE_INLINE_TERMINATOR_MISSING',logicalLine.context,'missing materialx_inline_end');
                block.values.materialx_inline = inlineLines.join('\n').trim();
                block.directives.push({name:key,line:beginLine,policy:'supported',raw:inlineLines.join('\n')});
                continue;
            }
            if (key === 'materialx_inline_end') fail('SCENE_INLINE_TERMINATOR_UNEXPECTED',logicalLine.context,'terminator without begin');
            if (key !== 'object' && Object.hasOwn(block.values,key))
                fail('SCENE_DUPLICATE_DIRECTIVE',logicalLine.context,'scalar directive may appear only once per block');
            if (!['object'].includes(key) && values.length < 2)
                fail('SCENE_VALUE_ARITY_INVALID',{...logicalLine.context,token:key},'directive is missing its value');
            const parsedValue = parseValue(directive,key,values,logicalLine.context);
            if (key === 'object') block.repeated.push({ ...parsedValue,line:index+1 });
            else block.values[key] = parsedValue;
            block.directives.push({ name:key,line:index+1,policy });
            index++;
        }
        if (!closed) fail('SCENE_BLOCK_UNCLOSED',{url,line:block.line,block:directive,name},'missing closing brace');
        validateBlock(block,url);
        blocks.push(block);
    }
    if (!singleton.has('camera')) warnings.push({ code:'SCENE_CAMERA_MISSING',url,line:1,block:'root',token:'camera' });
    const scene = { version:1,url,blocks,rootOptions,warnings };
    resolveSceneReferences(scene);
    return scene;
}

export function resolveSceneReferences(scene, gltfObjectNames = null) {
    if (!scene || !Array.isArray(scene.blocks)) throw new TypeError('SCENE_AST_INVALID: parsed scene required');
    const materialByName = new Map(scene.blocks.filter((block) => block.type === 'material').map((block,index) => [block.name,index]));
    for (const block of scene.blocks) {
        if (block.type === 'mesh' && block.values.material) {
            if (!materialByName.has(block.values.material))
                fail('SCENE_REFERENCE_UNKNOWN',{url:scene.url,line:block.line,block:block.type,name:block.name,token:'material'},`unknown material '${block.values.material}'`);
            block.materialIndex = materialByName.get(block.values.material);
        }
        if (block.type === 'gltf') {
            for (const override of block.repeated) {
                if (!materialByName.has(override.materialName))
                    fail('SCENE_REFERENCE_UNKNOWN',{url:scene.url,line:override.line,block:'gltf',name:block.name,token:'object'},`unknown material '${override.materialName}'`);
                override.materialIndex = materialByName.get(override.materialName);
            }
        }
    }
    if (gltfObjectNames) {
        for (const [blockIndex,names] of gltfObjectNames) {
            const block = scene.blocks[blockIndex];
            if (!block || block.type !== 'gltf') continue;
            for (const override of block.repeated) {
                const pattern = override.pattern.replace(/[.+^${}()|[\]\\]/g,'\\$&').replace(/\*/g,'.*').replace(/\?/g,'.');
                const matcher = new RegExp(`^${pattern}$`,'i');
                if (!names.some((objectName) => matcher.test(objectName)))
                    fail('SCENE_OVERRIDE_NO_MATCH',{url:scene.url,line:override.line,block:'gltf',name:block.name,token:'object'},`pattern '${override.pattern}' matched no object`);
            }
        }
    }
    return scene;
}