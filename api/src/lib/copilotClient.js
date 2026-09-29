const DEFAULT_SYSTEM_PROMPT = [
    'You generate complete MaterialX 1.39 XML documents.',
    'Return only XML, without Markdown fences or explanatory text.',
    'The document must contain a renderable surfacematerial and its connected shader.',
    'Use inline values unless the user explicitly requests textures.',
    'Keep the document self-contained and compatible with a WebGL MaterialX shader generator.'
].join(' ');

function stripMarkdownFences(value) {
    return value
        .replace(/^```(?:xml|materialx)?\\s*/i, '')
        .replace(/\\s*```$/i, '')
        .trim();
}

async function generateMtlx({ prompt, format }) {
    const apiUrl = process.env.COPILOT_API_URL;
    const apiKey = process.env.COPILOT_API_KEY;
    const model = process.env.COPILOT_MODEL;
    if (!apiUrl || !apiKey || !model) {
        throw new Error('Copilot endpoint configuration is incomplete.');
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 45000);
    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`
            },
            body: JSON.stringify({
                model,
                temperature: 0.2,
                max_tokens: 5000,
                messages: [
                    { role: 'system', content: DEFAULT_SYSTEM_PROMPT },
                    { role: 'user', content: `Format: ${format || 'materialx-1.39'}\\nMaterial request: ${prompt}` }
                ]
            }),
            signal: controller.signal
        });
        if (!response.ok) {
            throw new Error(`Copilot upstream returned ${response.status}.`);
        }
        const payload = await response.json();
        const content = payload?.choices?.[0]?.message?.content;
        if (typeof content !== 'string') throw new Error('Copilot upstream returned no text.');
        return stripMarkdownFences(content);
    } finally {
        clearTimeout(timeout);
    }
}

module.exports = { generateMtlx };
