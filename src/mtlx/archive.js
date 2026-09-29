import JSZip from 'jszip';

const MAX_UNCOMPRESSED_BYTES = 512 * 1024 * 1024;
const MAX_ARCHIVE_FILES = 5000;

function normalizeArchivePath(value)
{
    const parts = [];
    for (const part of String(value || '').replace(/\\/g, '/').split('/')) {
        if (!part || part === '.') continue;
        if (part === '..') parts.pop();
        else parts.push(part);
    }
    return parts.join('/');
}

function joinArchivePath(...parts)
{
    return normalizeArchivePath(parts.filter(Boolean).join('/'));
}

function getMaterialXFiles(xmlText)
{
    const document = new DOMParser().parseFromString(xmlText, 'application/xml');
    if (document.querySelector('parsererror') || document.documentElement?.nodeName !== 'materialx')
        throw new Error('The ZIP contains an invalid MaterialX document.');

    const fileInputs = Array.from(document.getElementsByTagName('input'))
        .filter(input => input.getAttribute('type') === 'filename')
        .map(input => input.getAttribute('value'))
        .filter(Boolean);
    return { document, fileInputs };
}

function findArchiveEntry(fileValue, materialPath, filePrefix, entriesByName)
{
    const materialDirectory = materialPath.includes('/') ? materialPath.slice(0, materialPath.lastIndexOf('/')) : '';
    const candidates = [
        joinArchivePath(materialDirectory, filePrefix, fileValue),
        joinArchivePath(materialDirectory, fileValue),
        joinArchivePath(filePrefix, fileValue),
        normalizeArchivePath(fileValue)
    ];
    for (const candidate of candidates) {
        const entry = entriesByName.get(candidate.toLowerCase());
        if (entry) return { entry, candidates };
    }

    const basename = normalizeArchivePath(fileValue).split('/').pop()?.toLowerCase();
    const matches = Array.from(entriesByName.values()).filter(entry =>
        normalizeArchivePath(entry.name).split('/').pop()?.toLowerCase() === basename
    );
    if (matches.length === 1) return { entry: matches[0], candidates };
    throw new Error(`Texture referenced by MaterialX was not found in ZIP: ${fileValue}`);
}

function validateAmbientCgZipUrl(value)
{
    let url;
    try {
        url = new URL(value);
    } catch {
        throw new Error('Enter a valid AmbientCG ZIP URL.');
    }
    if (url.protocol !== 'https:' || url.username || url.password)
        throw new Error('AmbientCG archive URLs must use HTTPS.');

    const isAmbientCg = ['ambientcg.com', 'www.ambientcg.com'].includes(url.hostname) &&
        url.pathname === '/get' && /^[\w-]+\.zip$/i.test(url.searchParams.get('file') || '');
    const isDownloadHost = url.hostname === 'acg-download.struffelproductions.com' &&
        /^\/file\/ambientCG-Web\/download\/[\w-]+\/[\w-]+\.zip$/i.test(url.pathname);
    if (!isAmbientCg && !isDownloadHost)
        throw new Error('Use an AmbientCG ZIP URL such as https://ambientcg.com/get?file=Ground112_1K-JPG.zip.');
    return url.toString();
}

export async function loadMtlxArchive(zipUrl, proxyEndpoint)
{
    const validatedUrl = validateAmbientCgZipUrl(zipUrl);
    const separator = proxyEndpoint.includes('?') ? '&' : '?';
    const response = await fetch(`${proxyEndpoint}${separator}url=${encodeURIComponent(validatedUrl)}`);
    if (!response.ok) {
        let message = `ZIP download failed (${response.status}).`;
        try {
            const payload = await response.json();
            if (payload?.error) message = payload.error;
        } catch {}
        throw new Error(message);
    }

    const zip = await JSZip.loadAsync(await response.arrayBuffer());
    const files = Object.values(zip.files).filter(entry => !entry.dir);
    if (files.length > MAX_ARCHIVE_FILES)
        throw new Error(`The ZIP contains too many files (limit: ${MAX_ARCHIVE_FILES}).`);
    const uncompressedBytes = files.reduce((total, entry) => total + (entry._data?.uncompressedSize || 0), 0);
    if (uncompressedBytes > MAX_UNCOMPRESSED_BYTES)
        throw new Error('The uncompressed ZIP exceeds the 512 MiB limit.');

    const materials = files
        .filter(entry => entry.name.toLowerCase().endsWith('.mtlx'))
        .map(entry => ({
            path: entry.name,
            name: entry.name.split('/').pop().replace(/\.mtlx$/i, '')
        }));
    if (materials.length === 0)
        throw new Error('No .mtlx file was found in this ZIP.');

    const entriesByName = new Map(files.map(entry => [normalizeArchivePath(entry.name).toLowerCase(), entry]));
    return {
        materials,
        async selectMaterial(materialPath) {
            const material = materials.find(item => item.path === materialPath);
            if (!material) throw new Error('The selected MaterialX file is not in this ZIP.');
            const xmlText = await entriesByName.get(material.path.toLowerCase()).async('string');
            const { document, fileInputs } = getMaterialXFiles(xmlText);
            const filePrefix = document.documentElement.getAttribute('fileprefix') || '';
            const urlsByInput = new Map();
            const urlsByCandidate = new Map();
            const objectUrls = new Set();

            try {
                for (const fileValue of new Set(fileInputs)) {
                    const { entry, candidates } = findArchiveEntry(fileValue, material.path, filePrefix, entriesByName);
                    const blob = await entry.async('blob');
                    const objectUrl = URL.createObjectURL(blob);
                    objectUrls.add(objectUrl);
                    urlsByInput.set(fileValue.replace(/\\/g, '/').toLowerCase(), objectUrl);
                    for (const candidate of candidates) urlsByCandidate.set(candidate.toLowerCase(), objectUrl);
                    urlsByCandidate.set(normalizeArchivePath(fileValue).toLowerCase(), objectUrl);
                }
            } catch (error) {
                for (const objectUrl of objectUrls) URL.revokeObjectURL(objectUrl);
                throw error;
            }

            let released = false;
            return {
                materialId: material.name,
                mtlxText: xmlText,
                textureLoadsPending: 0,
                retired: false,
                resolveTexture(fileValue) {
                    const normalized = String(fileValue || '').replace(/\\/g, '/').toLowerCase();
                    const direct = urlsByInput.get(normalized) || urlsByCandidate.get(normalizeArchivePath(fileValue).toLowerCase());
                    if (direct) return direct;
                    const basename = normalizeArchivePath(fileValue).split('/').pop()?.toLowerCase();
                    const match = Array.from(urlsByInput.entries()).find(([key]) => key.split('/').pop() === basename);
                    return match?.[1] || null;
                },
                release() {
                    if (released) return;
                    released = true;
                    for (const objectUrl of objectUrls) URL.revokeObjectURL(objectUrl);
                    objectUrls.clear();
                }
            };
        }
    };
}