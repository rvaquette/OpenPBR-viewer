// Minimal native Radiance RGBE (.hdr) decoder, replacing three.js's RGBELoader
// addon. Supports the standard "-Y H +X W" orientation and both the flat and
// new-style (adaptive RLE per-channel) scanline encodings used by virtually all
// real-world .hdr files (Poly Haven, Radiance, Blender exports, etc).
//
// Output matches RGBELoader's default (HalfFloatType) so the rest of the
// pipeline (DataTexture, colorSpace, mapping) is unchanged.

function readHeader(bytes) {
    let pos = 0;
    const readLine = () => {
        let end = pos;
        while (end < bytes.length && bytes[end] !== 0x0a) end++;
        let line = String.fromCharCode(...bytes.subarray(pos, end));
        if (line.endsWith('\r')) line = line.slice(0, -1);
        pos = end + 1;
        return line;
    };

    const magic = readLine();
    if (magic.charAt(0) !== '#' || magic.charAt(1) !== '?') {
        throw new Error('HDR: bad initial token');
    }

    // The blank line ending the header variable section is NOT immediately
    // followed by the resolution string in a separate step -- it's just another
    // line in the same scan; keep reading (skipping blanks/comments) until both
    // FORMAT and the "-Y H +X W" resolution string have been seen.
    let width = 0, height = 0, sawFormat = false;
    for (;;) {
        const line = readLine();
        if (pos > bytes.length) throw new Error('HDR: unexpected end of header');
        if (line === '' || line.startsWith('#')) continue;
        if (/^FORMAT=/.test(line)) sawFormat = true;
        const dims = line.match(/^\s*-Y\s+(\d+)\s+\+X\s+(\d+)\s*$/);
        if (dims) { height = parseInt(dims[1], 10); width = parseInt(dims[2], 10); }
        if (sawFormat && width > 0 && height > 0) break;
    }
    if (!sawFormat) throw new Error('HDR: missing FORMAT specifier');
    if (width <= 0 || height <= 0) throw new Error('HDR: missing/invalid -Y H +X W dimensions');

    return { width, height, pos };
}

// Reads all scanlines into a flat Uint8Array of RGBE quadruplets (w*h*4 bytes).
function readScanlines(bytes, pos, width, height) {
    const rgbe = new Uint8Array(width * height * 4);

    const isRle = width >= 8 && width < 0x8000 &&
        bytes[pos] === 2 && bytes[pos + 1] === 2 && (bytes[pos + 2] & 0x80) === 0;

    if (!isRle) {
        // Flat (uncompressed) RGBE data, one quadruplet per pixel already.
        rgbe.set(bytes.subarray(pos, pos + rgbe.length));
        return rgbe;
    }

    const scanline = new Uint8Array(width * 4);
    let offset = 0;
    for (let y = 0; y < height; y++) {
        if (bytes[pos] !== 2 || bytes[pos + 1] !== 2 || (((bytes[pos + 2] << 8) | bytes[pos + 3]) !== width)) {
            throw new Error('HDR: bad scanline header');
        }
        pos += 4;

        // Each of the 4 channels (R,G,B,E) is stored independently, RLE-encoded.
        let ptr = 0;
        const end = width * 4;
        while (ptr < end) {
            let count = bytes[pos++];
            if (count > 128) {
                count -= 128;
                const value = bytes[pos++];
                for (let i = 0; i < count; i++) scanline[ptr++] = value;
            } else {
                scanline.set(bytes.subarray(pos, pos + count), ptr);
                ptr += count;
                pos += count;
            }
        }

        for (let x = 0; x < width; x++) {
            rgbe[offset]     = scanline[x];
            rgbe[offset + 1] = scanline[x + width];
            rgbe[offset + 2] = scanline[x + width * 2];
            rgbe[offset + 3] = scanline[x + width * 3];
            offset += 4;
        }
    }
    return rgbe;
}

// Converts RGBE bytes to half-float (Uint16) RGBA, matching THREE.DataUtils.toHalfFloat.
// Rec. 709 relative luminance, matching GLSL-PathTracer-JS's EnvironmentMap.luminance().
function luminance(r, g, b) {
    return 0.212671 * r + 0.715160 * g + 0.072169 * b;
}

// Converts RGBE bytes to half-float (Uint16) RGBA, matching THREE.DataUtils.toHalfFloat,
// and simultaneously builds the flat row-major luminance CDF used for importance
// sampling (cdf[i] = cdf[i-1] + luminance(pixel i), same convention as
// GLSL-PathTracer-JS's EnvironmentMap.buildCDF() -- a single monotonic array,
// reshaped into a (width x height) texture rather than a true 2D marginal/
// conditional decomposition).
function rgbeToHalfFloatRGBA(rgbe, toHalfFloat) {
    const n = rgbe.length / 4;
    const out = new Uint16Array(n * 4);
    const cdf = new Float32Array(n);
    let running = 0;
    for (let i = 0; i < n; i++) {
        const o = i * 4;
        const e = rgbe[o + 3];
        const scale = e === 0 ? 0 : Math.pow(2.0, e - 128.0) / 255.0;
        const r = rgbe[o] * scale, g = rgbe[o + 1] * scale, b = rgbe[o + 2] * scale;
        out[o]     = toHalfFloat(Math.min(r, 65504));
        out[o + 1] = toHalfFloat(Math.min(g, 65504));
        out[o + 2] = toHalfFloat(Math.min(b, 65504));
        out[o + 3] = toHalfFloat(1);
        running += luminance(r, g, b);
        cdf[i] = running;
    }
    return { data: out, cdf, totalSum: running };
}

// Fetches and decodes a Radiance .hdr file into { width, height, data (Uint16Array RGBA
// half-float), cdf (Float32Array, flat row-major cumulative luminance), totalSum }.
export async function loadRadianceHdr(url, toHalfFloat) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`HDR fetch failed: ${response.status} ${url}`);
    const bytes = new Uint8Array(await response.arrayBuffer());
    const { width, height, pos } = readHeader(bytes);
    const rgbe = readScanlines(bytes, pos, width, height);
    const { data, cdf, totalSum } = rgbeToHalfFloatRGBA(rgbe, toHalfFloat);
    return { width, height, data, cdf, totalSum };
}
