const { XMLParser } = require('fast-xml-parser');

const MAX_MTLX_BYTES = 256 * 1024;

function validateMtlxDocument(mtlxText) {
    if (typeof mtlxText !== 'string' || !mtlxText.trim()) {
        throw new Error('The model returned an empty MaterialX document.');
    }
    if (Buffer.byteLength(mtlxText, 'utf8') > MAX_MTLX_BYTES) {
        throw new Error('The generated MaterialX document is too large.');
    }

    let document;
    try {
        document = new XMLParser({
            ignoreAttributes: false,
            removeNSPrefix: true,
            processEntities: false,
            allowBooleanAttributes: false
        }).parse(mtlxText);
    } catch {
        throw new Error('The model returned invalid XML.');
    }

    const materialx = document?.materialx;
    if (!materialx || typeof materialx !== 'object') {
        throw new Error('The XML root must be a MaterialX document.');
    }
    if (!materialx.surfacematerial && !materialx.material) {
        throw new Error('The MaterialX document must contain a material element.');
    }
    return mtlxText.trim();
}

module.exports = { validateMtlxDocument };
