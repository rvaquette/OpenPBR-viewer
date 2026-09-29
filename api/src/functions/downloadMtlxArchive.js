const { app } = require('@azure/functions');

const MAX_ARCHIVE_BYTES = 200 * 1024 * 1024;
const AMBIENTCG_HOSTS = new Set(['ambientcg.com', 'www.ambientcg.com']);
const DOWNLOAD_HOST = 'acg-download.struffelproductions.com';

function corsHeaders(origin, contentType = 'application/json') {
    const allowed = (process.env.ALLOWED_ORIGINS || 'http://localhost:5173,http://127.0.0.1:5173')
        .split(',').map(value => value.trim()).filter(Boolean);
    const allowOrigin = allowed.includes(origin) ? origin : allowed.includes('*') ? '*' : allowed[0] || '';
    return {
        'Content-Type': contentType,
        ...(allowOrigin ? { 'Access-Control-Allow-Origin': allowOrigin } : {}),
        'Vary': 'Origin'
    };
}

function isAllowedArchiveUrl(url) {
    if (url.protocol !== 'https:' || url.username || url.password) return false;
    if (AMBIENTCG_HOSTS.has(url.hostname)) {
        return url.pathname === '/get' && /^[\w-]+\.zip$/i.test(url.searchParams.get('file') || '');
    }
    return url.hostname === DOWNLOAD_HOST &&
        /^\/file\/ambientCG-Web\/download\/[\w-]+\/[\w-]+\.zip$/i.test(url.pathname);
}

function errorResponse(status, error, headers) {
    return { status, headers, jsonBody: { error } };
}

app.http('downloadMtlxArchive', {
    methods: ['GET', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'mtlx/archive',
    handler: async request => {
        const headers = corsHeaders(request.headers.get('origin') || '');
        if (request.method === 'OPTIONS') {
            return {
                status: 204,
                headers: {
                    ...headers,
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                }
            };
        }

        let downloadUrl;
        try {
            downloadUrl = new URL(request.query.get('url') || '');
        } catch {
            return errorResponse(400, 'A valid AmbientCG ZIP URL is required.', headers);
        }
        if (!isAllowedArchiveUrl(downloadUrl)) {
            return errorResponse(400, 'Only AmbientCG ZIP download URLs are allowed.', headers);
        }

        try {
            let upstream;
            for (let redirectCount = 0; redirectCount <= 3; redirectCount++) {
                upstream = await fetch(downloadUrl, {
                    redirect: 'manual',
                    signal: AbortSignal.timeout(180_000)
                });
                if (![301, 302, 303, 307, 308].includes(upstream.status)) break;

                const location = upstream.headers.get('location');
                if (!location || redirectCount === 3) {
                    return errorResponse(502, 'AmbientCG returned an invalid download redirect.', headers);
                }
                const nextUrl = new URL(location, downloadUrl);
                if (!isAllowedArchiveUrl(nextUrl)) {
                    return errorResponse(502, 'AmbientCG redirected to an unsupported download host.', headers);
                }
                downloadUrl = nextUrl;
            }

            if (!upstream?.ok || !upstream.body) {
                return errorResponse(502, `AmbientCG download failed (${upstream?.status || 'no response'}).`, headers);
            }
            const contentLength = Number(upstream.headers.get('content-length'));
            if (Number.isFinite(contentLength) && contentLength > MAX_ARCHIVE_BYTES) {
                return errorResponse(413, 'The ZIP archive exceeds the 200 MiB download limit.', headers);
            }

            const chunks = [];
            let totalBytes = 0;
            for await (const chunk of upstream.body) {
                totalBytes += chunk.byteLength;
                if (totalBytes > MAX_ARCHIVE_BYTES) {
                    await upstream.body.cancel();
                    return errorResponse(413, 'The ZIP archive exceeds the 200 MiB download limit.', headers);
                }
                chunks.push(Buffer.from(chunk));
            }
            const archive = Buffer.concat(chunks, totalBytes);
            if (archive.length < 4 || archive[0] !== 0x50 || archive[1] !== 0x4b) {
                return errorResponse(502, 'AmbientCG did not return a ZIP archive.', headers);
            }

            return {
                status: 200,
                headers: {
                    ...corsHeaders(request.headers.get('origin') || '', 'application/zip'),
                    'Content-Length': String(archive.length),
                    'Cache-Control': 'no-store'
                },
                body: archive
            };
        } catch (error) {
            return errorResponse(502, `AmbientCG ZIP proxy failed: ${error.message}`, headers);
        }
    }
});