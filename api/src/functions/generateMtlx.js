const { app } = require('@azure/functions');
const { generateMtlx } = require('../lib/copilotClient');
const { validateMtlxDocument } = require('../lib/mtlxValidation');

const MAX_BODY_BYTES = 16 * 1024;

function corsHeaders(origin) {
    const allowed = (process.env.ALLOWED_ORIGINS || '').split(',').map(value => value.trim()).filter(Boolean);
    const allowOrigin = allowed.includes(origin) ? origin : allowed.includes('*') ? '*' : allowed[0] || '';
    return {
        'Content-Type': 'application/json',
        ...(allowOrigin ? { 'Access-Control-Allow-Origin': allowOrigin } : {}),
        'Vary': 'Origin'
    };
}

app.http('generateMtlx', {
    methods: ['OPTIONS', 'POST'],
    authLevel: 'anonymous',
    route: 'copilot/mtlx',
    handler: async (request, context) => {
        const headers = corsHeaders(request.headers.get('origin') || '');
        if (request.method === 'OPTIONS') {
            return { status: 204, headers: { ...headers, 'Access-Control-Allow-Methods': 'POST,OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' } };
        }

        try {
            const bodyText = await request.text();
            if (Buffer.byteLength(bodyText, 'utf8') > MAX_BODY_BYTES) {
                return { status: 413, headers, jsonBody: { error: 'Request is too large.' } };
            }
            const body = JSON.parse(bodyText || '{}');
            const prompt = typeof body.prompt === 'string' ? body.prompt.trim() : '';
            if (prompt.length < 10 || prompt.length > 8000) {
                return { status: 400, headers, jsonBody: { error: 'prompt must contain between 10 and 8000 characters.' } };
            }

            const generated = await generateMtlx({ prompt, format: body.format });
            const mtlx = validateMtlxDocument(generated);
            return { status: 200, headers, jsonBody: { mtlx } };
        } catch (error) {
            context.error('[copilot/mtlx] request failed:', error.message);
            const status = error.name === 'SyntaxError' ? 400 : 502;
            return { status, headers, jsonBody: { error: status === 400 ? 'Invalid JSON request.' : 'MaterialX generation failed.' } };
        }
    }
});
