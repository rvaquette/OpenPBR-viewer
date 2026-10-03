import {
    CanvasTexture,
    ClampToEdgeWrapping,
    LinearFilter,
    LinearSRGBColorSpace,
} from 'three';

const MAX_IMAGE_WIDTH = 1024;
const GUTTER = 2;

async function loadBitmap(binding, maxTextureSize)
{
    const response = await fetch(binding.url);
    if (!response.ok) throw new Error(`Texture fetch failed: ${response.status} ${binding.url}`);
    const blob = await response.blob();
    let original;
    try {
        original = await createImageBitmap(blob);
    } catch (error) {
        throw new Error(`Texture decode failed: ${binding.url} (${blob.type || 'unknown content type'}, ${blob.size} bytes): ${error.message}`);
    }
    const scale = Math.min(
        1,
        MAX_IMAGE_WIDTH / original.width,
        (maxTextureSize - GUTTER * 2) / original.height
    );
    const width = Math.max(1, Math.floor(original.width * scale));
    const height = Math.max(1, Math.floor(original.height * scale));
    if (width === original.width && height === original.height)
        return { bitmap: original, width, height };

    try {
        const bitmap = await createImageBitmap(blob, {
            resizeWidth: width,
            resizeHeight: height,
            resizeQuality: 'high',
        });
        original.close?.();
        return { bitmap, width: bitmap.width, height: bitmap.height };
    } catch (error) {
        original.close?.();
        throw new Error(`Unable to resize texture ${binding.url}: ${error.message}`);
    }
}

function extrudeEdges(context, bitmap, x, y, width, height)
{
    context.drawImage(bitmap, x + GUTTER, y + GUTTER, width, height);
    context.drawImage(bitmap, 0, 0, 1, bitmap.height, x, y + GUTTER, GUTTER, height);
    context.drawImage(bitmap, bitmap.width - 1, 0, 1, bitmap.height,
        x + GUTTER + width, y + GUTTER, GUTTER, height);
    context.drawImage(bitmap, 0, 0, bitmap.width, 1, x + GUTTER, y, width, GUTTER);
    context.drawImage(bitmap, 0, bitmap.height - 1, bitmap.width, 1,
        x + GUTTER, y + GUTTER + height, width, GUTTER);
    context.drawImage(bitmap, 0, 0, 1, 1, x, y, GUTTER, GUTTER);
    context.drawImage(bitmap, bitmap.width - 1, 0, 1, 1,
        x + GUTTER + width, y, GUTTER, GUTTER);
    context.drawImage(bitmap, 0, bitmap.height - 1, 1, 1,
        x, y + GUTTER + height, GUTTER, GUTTER);
    context.drawImage(bitmap, bitmap.width - 1, bitmap.height - 1, 1, 1,
        x + GUTTER + width, y + GUTTER + height, GUTTER, GUTTER);
}

function createAtlasTexture(canvas)
{
    const texture = new CanvasTexture(canvas);
    texture.colorSpace = LinearSRGBColorSpace;
    texture.flipY = false;
    texture.wrapS = ClampToEdgeWrapping;
    texture.wrapT = ClampToEdgeWrapping;
    texture.magFilter = LinearFilter;
    texture.minFilter = LinearFilter;
    texture.generateMipmaps = false;
    texture.needsUpdate = true;
    return texture;
}

export async function buildMtlxTextureAtlases(bindings, maxTextureSize)
{
    if (!Number.isFinite(maxTextureSize) || maxTextureSize < 8)
        throw new Error('[mtlx-textures] invalid MAX_TEXTURE_SIZE');

    const images = [];
    const imagesByUrl = new Map();
    for (const binding of bindings) {
        let image = imagesByUrl.get(binding.url);
        if (!image) {
            image = { id: images.length, url: binding.url, bindings: [] };
            imagesByUrl.set(binding.url, image);
            images.push(image);
        }
        image.bindings.push(binding);
    }
    if (images.length === 0) {
        return { textures: [], uniforms: {}, bindings: [], rects: [], width: 0, height: 0 };
    }

    const loaded = [];
    const pages = [{ items: [], x: 0, y: 0, rowHeight: 0, usedWidth: 0, usedHeight: 0 }];
    const textures = [];
    try {
        for (const image of images) {
            Object.assign(image, await loadBitmap(image.bindings[0], maxTextureSize));
            loaded.push(image);
        }

        const sortedImages = [...images].sort((a, b) =>
            (b.height + GUTTER * 2) - (a.height + GUTTER * 2) || b.width - a.width
        );
        let page = pages[0];
        for (const image of sortedImages) {
            const paddedWidth = image.width + GUTTER * 2;
            const paddedHeight = image.height + GUTTER * 2;
            if (paddedWidth > maxTextureSize || paddedHeight > maxTextureSize)
                throw new Error(`[mtlx-textures] image exceeds MAX_TEXTURE_SIZE after resizing: ${image.url}`);

            if (page.x + paddedWidth > maxTextureSize) {
                page.x = 0;
                page.y += page.rowHeight;
                page.rowHeight = 0;
            }
            if (page.y + paddedHeight > maxTextureSize) {
                page = { items: [], x: 0, y: 0, rowHeight: 0, usedWidth: 0, usedHeight: 0 };
                pages.push(page);
            }

            image.page = pages.length - 1;
            image.x = page.x;
            image.y = page.y;
            page.items.push(image);
            page.x += paddedWidth;
            page.rowHeight = Math.max(page.rowHeight, paddedHeight);
            page.usedWidth = Math.max(page.usedWidth, page.x);
            page.usedHeight = Math.max(page.usedHeight, page.y + paddedHeight);
        }

        const width = Math.max(1, ...pages.map(page => page.usedWidth));
        const height = Math.max(1, ...pages.map(page => page.usedHeight));
        if (width > maxTextureSize || height > maxTextureSize)
            throw new Error('[mtlx-textures] atlas packing exceeded MAX_TEXTURE_SIZE');

        const uniforms = {};
        for (let pageIndex = 0; pageIndex < pages.length; pageIndex++) {
            const canvas = document.createElement('canvas');
            canvas.width = width;
            canvas.height = height;
            const context = canvas.getContext('2d', { alpha: true });
            if (!context) throw new Error('[mtlx-textures] unable to create atlas canvas');
            for (const image of pages[pageIndex].items)
                extrudeEdges(context, image.bitmap, image.x, image.y, image.width, image.height);

            const texture = createAtlasTexture(canvas);
            textures.push(texture);
            uniforms[`mtlxTextureAtlas${pageIndex}`] = { value: texture };
        }

        const rects = new Array(images.length);
        for (const image of images) {
            rects[image.id] = {
                x: (image.x + GUTTER) / width,
                y: (image.y + GUTTER) / height,
                width: image.width / width,
                height: image.height / height,
            };
            for (const binding of image.bindings) {
                binding.atlasUniform = `mtlxTextureAtlas${image.page}`;
                binding.atlasIndex = image.id;
            }
        }

        return { textures, uniforms, bindings, rects, width, height };
    } catch (error) {
        textures.forEach(texture => texture.dispose());
        throw error;
    } finally {
        loaded.forEach(image => image.bitmap.close?.());
    }
}

function findClosingParen(source, openIndex)
{
    let depth = 0;
    for (let index = openIndex; index < source.length; index++) {
        if (source[index] === '(') depth++;
        else if (source[index] === ')' && --depth === 0) return index;
    }
    return -1;
}

function findClosingBrace(source, openIndex)
{
    let depth = 0;
    for (let index = openIndex; index < source.length; index++) {
        if (source[index] === '{') depth++;
        else if (source[index] === '}' && --depth === 0) return index;
    }
    return -1;
}

function splitArguments(source)
{
    const args = [];
    let depth = 0;
    let start = 0;
    for (let index = 0; index < source.length; index++) {
        const character = source[index];
        if ('([{'.includes(character)) depth++;
        else if (')]}'.includes(character)) depth--;
        else if (character === ',' && depth === 0) {
            args.push(source.slice(start, index).trim());
            start = index + 1;
        }
    }
    if (source.slice(start).trim()) args.push(source.slice(start).trim());
    return args;
}

function findFunctionDefinitions(source)
{
    const functions = [];
    const regex = /\b([A-Za-z_]\w*)\s*\(/g;
    let match;
    while ((match = regex.exec(source)) !== null) {
        const openParen = source.indexOf('(', match.index);
        const closeParen = findClosingParen(source, openParen);
        if (closeParen < 0) continue;
        let openBrace = closeParen + 1;
        while (/\s/.test(source[openBrace] || '')) openBrace++;
        if (source[openBrace] !== '{') continue;
        const lineStart = source.lastIndexOf('\n', match.index) + 1;
        const prefix = source.slice(lineStart, match.index).trim();
        if (!/^(?:[A-Za-z_]\w*\s*)+$/.test(prefix)) continue;
        const closeBrace = findClosingBrace(source, openBrace);
        if (closeBrace < 0) continue;
        const args = splitArguments(source.slice(openParen + 1, closeParen));
        const sampler = args[0]?.match(/^sampler2D\s+([A-Za-z_]\w*)$/);
        functions.push({
            name: match[1],
            args,
            samplerName: sampler?.[1] || '',
            layerName: args[1]?.match(/^int\s+([A-Za-z_]\w*)$/)?.[1] || '',
            openParen,
            closeParen,
            openBrace,
            closeBrace,
            start: lineStart,
        });
        regex.lastIndex = closeBrace + 1;
    }
    return functions;
}

function findCalls(source, names)
{
    if (!names.length) return [];
    const regex = new RegExp(`\\b(${names.map(name => name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})\\s*\\(`, 'g');
    const calls = [];
    let match;
    while ((match = regex.exec(source)) !== null) {
        const openParen = source.indexOf('(', match.index);
        const closeParen = findClosingParen(source, openParen);
        if (closeParen < 0) continue;
        calls.push({ name: match[1], openParen, closeParen, args: splitArguments(source.slice(openParen + 1, closeParen)) });
        regex.lastIndex = closeParen + 1;
    }
    return calls;
}

function rewriteSamplerCalls(body, parent, functionByName, bindingBySampler)
{
    const patches = [];
    for (const call of findCalls(body, [...functionByName.keys()])) {
        const target = functionByName.get(call.name);
        const binding = bindingBySampler.get(call.args[0]);
        const forwardsParentSampler = parent?.samplerName && call.args[0] === parent.samplerName;
        if (!binding && !forwardsParentSampler) continue;

        const args = call.args;
        args[0] = binding ? binding.atlasUniform : args[0];
        const layerIndex = binding ? String(binding.atlasIndex) : 'mtlxTextureIndex';
        if (target.layerName) args[1] = layerIndex;
        else args.splice(1, 0, layerIndex);
        patches.push({ start: call.openParen + 1, end: call.closeParen, value: args.join(', ') });
    }
    for (const patch of patches.sort((a, b) => b.start - a.start))
        body = body.slice(0, patch.start) + patch.value + body.slice(patch.end);
    return body;
}

function rewriteTextureSampling(body, samplerName)
{
    const patches = [];
    for (const call of findCalls(body, ['texture', 'textureGrad', 'textureLod'])) {
        const args = call.args;
        if (args[0] !== samplerName || args.length < 2) continue;
        args[1] = `mtlxAtlasUv(${args[1]}, mtlxTextureIndex)`;
        if (call.name === 'textureGrad') {
            args[2] = `(${args[2]}) * mtlxAtlasRect(mtlxTextureIndex).zw`;
            args[3] = `(${args[3]}) * mtlxAtlasRect(mtlxTextureIndex).zw`;
        }
        patches.push({ start: call.openParen + 1, end: call.closeParen, value: args.join(', ') });
    }
    for (const patch of patches.sort((a, b) => b.start - a.start))
        body = body.slice(0, patch.start) + patch.value + body.slice(patch.end);
    return body;
}

export function adaptMtlxTextureShader(source, atlas)
{
    if (atlas.bindings.length === 0) return source;
    let shader = source;
    const bindingBySampler = new Map(atlas.bindings.map(binding => [binding.sampler, binding]));
    const functions = findFunctionDefinitions(shader);
    const functionByName = new Map(functions
        .filter(fn => fn.samplerName)
        .map(fn => [fn.name, fn]));
    const needed = new Set();
    for (const fn of functions) {
        const body = shader.slice(fn.openBrace + 1, fn.closeBrace);
        if (rewriteSamplerCalls(body, fn, functionByName, bindingBySampler) !== body)
            for (const call of findCalls(body, [...functionByName.keys()])) {
                if (bindingBySampler.has(call.args[0])) needed.add(call.name);
            }
    }

    const queue = [...needed];
    while (queue.length) {
        const fn = functionByName.get(queue.pop());
        if (!fn) continue;
        const body = shader.slice(fn.openBrace + 1, fn.closeBrace);
        for (const call of findCalls(body, [...functionByName.keys()])) {
            if (call.args[0] === fn.samplerName && !needed.has(call.name)) {
                needed.add(call.name);
                queue.push(call.name);
            }
        }
    }
    if (needed.size === 0)
        throw new Error('[mtlx-textures] no generated image sampler calls were found');

    const activeFunctions = functions.filter(fn => fn.samplerName && needed.has(fn.name));
    const activeFunctionByName = new Map(activeFunctions.map(fn => [fn.name, fn]));
    const patches = [];
    for (const fn of functions) {
        let body = shader.slice(fn.openBrace + 1, fn.closeBrace);
        body = rewriteSamplerCalls(body, fn, activeFunctionByName, bindingBySampler);
        if (fn.samplerName && needed.has(fn.name)) {
            body = rewriteTextureSampling(body, fn.samplerName);
            const args = [...fn.args];
            if (fn.layerName) args[1] = 'int mtlxTextureIndex';
            else args.splice(1, 0, 'int mtlxTextureIndex');
            patches.push({ start: fn.openParen + 1, end: fn.closeParen, value: args.join(', ') });
        }
        if (body !== shader.slice(fn.openBrace + 1, fn.closeBrace))
            patches.push({ start: fn.openBrace + 1, end: fn.closeBrace, value: body });
    }

    for (const patch of patches.sort((a, b) => b.start - a.start))
        shader = shader.slice(0, patch.start) + patch.value + shader.slice(patch.end);
    for (const binding of atlas.bindings) {
        const escaped = binding.sampler.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        shader = shader.replace(new RegExp(`^[ \\t]*uniform[ \\t]+sampler2D[ \\t]+${escaped}[ \\t]*;[ \\t]*\\r?\\n`, 'gm'), '');
    }

    const samplerUniforms = [...new Set(atlas.bindings.map(binding => binding.atlasUniform))]
        .map(name => `uniform sampler2D ${name};`).join('\n');
    const cases = atlas.rects.map((rect, index) =>
        `        case ${index}: return vec4(${rect.x.toFixed(9)}, ${rect.y.toFixed(9)}, ${rect.width.toFixed(9)}, ${rect.height.toFixed(9)});`
    ).join('\n');
    const preamble = `${samplerUniforms}\nvec4 mtlxAtlasRect(int imageIndex) {\n    switch (imageIndex) {\n${cases}\n    }\n    return vec4(0.0, 0.0, 1.0, 1.0);\n}\nvec2 mtlxAtlasUv(vec2 uv, int imageIndex) {\n    vec4 rect = mtlxAtlasRect(imageIndex);\n    return rect.xy + fract(uv) * rect.zw;\n}\n`;
    return preamble + shader;
}