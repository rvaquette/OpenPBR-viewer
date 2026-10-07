#!/usr/bin/env node
/**
 * launch_render.mjs  —  Lance l'OpenPBR-viewer en mode headless ou fenêtré.
 *
 * Prérequis :
 *   npm install          (installe playwright-core)
 *   npx vite             (serveur Vite démarré sur le port configuré)
 *                         — ou utiliser --start-server pour le démarrer automatiquement
 *
 * Usage :
 *   node launch_render.mjs [options]
 *
 * Options serveur :
 *   --headless              Navigateur invisible (défaut: true)
 *   --browser=auto|chrome|edge Navigateur a utiliser (defaut: auto)
 *   --launch-timeout-ms=N   Timeout de lancement navigateur (defaut: 180000)
 *   --start-server          Démarre npx vite avant le lancement (défaut: true)
 *   --port=5173             Port Vite (défaut: 5173)
 *   --output=out.png        Fichier image de sortie (défaut: render_YYYYMMDD_HHMMSS.png)
 *   --screenshot=out.png    Alias de --output
 *   --spp=N                 Samples path-tracing à attendre avant la capture (défaut: 10)
 *   --size=WxH             Résolution du rendu (défaut: 256x256)  ex: --size=1280x720
 *   --mtlx=file.mtlx       Charge les paramètres matériau depuis un fichier MaterialX OpenPBR
 *   --contract_url=/mtlx/material-contract.json  Contrat de fonctions générées par matériau
 *   --strict_generated_contract=true|false       Active l'echec strict sans fallback legacy (defaut: true)
 *   --denoise=true|false    Débruitage HDR local dans le navigateur (défaut: true pour Pathtracer MTLX)
 *   --dump-glsl=dir         Exporte les sources GLSL envoyées à WebGL et le dispatch MTLX généré
 *   --report=file.json     Exporte l'etat observe du viewer et les erreurs navigateur
 *
 * Options rendu :
 *   --mode=Rasterizer MTLX|Pathtracer MTLX
 *                                (alias: --mode=mtlx pour le pathtracer MTLX,
 *                                        --mode=raster-mtlx pour le rasterizer MTLX)
 *   --gpu=true|false              false = rendu logiciel SwiftShader (défaut: true)
 *   --scene=shader-ball|standard-shader-ball|glavenus|terrain|bearded-man
 *   --scene_url=/scenes/example.scene   Charge une scene .scene locale
 *   --linear_radiance_capture=true     Ajoute les stats RGBA32F avant présentation
 *   --smooth_normals=true|false   Lissage des normales (défaut: true)
 *   --bounces=N                   Nombre de rebonds (défaut: 6)
 *   --max_samples=N               Samples max avant arrêt (défaut: 512)
 *   --max_volume_steps=N          Pas volume max (défaut: 8)
 *   --firefly_clamp=N             Clamp anti-firefly (défaut: 10)
 *   --wireframe=true|false        Fil de fer (défaut: false)
 *   --neutral_color=R,G,B         Couleur neutre (défaut: 0.99,0.99,0.99)
 *
 * Paramètres matériau OpenPBR :
 *   --base_color=R,G,B      ex: --base_color=0.8,0.1,0.1
 *   --base_metalness=1.0
 *   --specular_roughness=0.05
 *   --coat_weight=0.5
 *   --thin_film_weight=1.0
 *   --thin_film_thickness=500
 *   --transmission_weight=1.0
 *   ... (toutes les propriétés de l'objet params dans main.js)
 *
 * Exemples :
 *   # Screenshot métal rouge en path-tracing (headless, GPU)
 *   node launch_render.mjs --headless --mode=mtlx --base_color=0.8,0.1,0.1 --base_metalness=1 --screenshot=metal.png --spp=64
 *
 *   # Verre en rasterizer sans GPU, démarrage serveur automatique
 *   node launch_render.mjs --headless --start-server --mode=raster-mtlx --transmission_weight=1 --gpu=false --output=glass.png
 *
 *   # Aperçu fenêtré (mode normal)
 *   node launch_render.mjs --mode=mtlx --base_metalness=1 --base_color=0.2,0.5,1
 */

import { chromium }    from 'playwright-core';
import { spawn, execSync } from 'child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { basename, dirname, isAbsolute, join, resolve } from 'path';
import { setTimeout as sleep } from 'timers/promises';

function killProcessTree(proc) {
    if (!proc) return;
    try {
        // Sur Windows, kill() ne tue que le shell (cmd.exe) — taskkill tue l'arbre complet
        execSync(`taskkill /F /T /PID ${proc.pid}`, { stdio: 'ignore' });
    } catch (_) {
        proc.kill();
    }
}

function extractMtlxFilenameRefs(xml) {
    const refs = new Set();
    const inputRe = /<input\b([^>]*)\/>/g;
    let match;
    while ((match = inputRe.exec(xml)) !== null) {
        const attrs = match[1];
        const type = (attrs.match(/\btype="([^"]+)"/) ?? [])[1];
        const value = (attrs.match(/\bvalue="([^"]+)"/) ?? [])[1];
        if (type === 'filename' && value && !/^(?:[a-z]+:)?\/\//i.test(value) && !isAbsolute(value)) {
            refs.add(value.replace(/\\/g, '/'));
        }
    }
    return [...refs];
}

function copyMtlxWithRelativeFiles(mtlxPath, materialId) {
    const sourceText = readFileSync(mtlxPath, 'utf8');
    const sourceDir = dirname(mtlxPath);
    const publicRoot = resolve(process.cwd(), 'public');
    const targetDir = join(publicRoot, 'mtlx-input', materialId);
    rmSync(targetDir, { recursive: true, force: true });
    mkdirSync(targetDir, { recursive: true });

    const targetMtlx = join(targetDir, basename(mtlxPath));
    writeFileSync(targetMtlx, sourceText, 'utf8');

    for (const ref of extractMtlxFilenameRefs(sourceText)) {
        const sourceFile = resolve(sourceDir, ref);
        if (!existsSync(sourceFile)) {
            console.warn(`[mtlx] texture introuvable ignoree: ${sourceFile}`);
            continue;
        }
        const targetFile = join(targetDir, ...ref.split('/'));
        mkdirSync(dirname(targetFile), { recursive: true });
        copyFileSync(sourceFile, targetFile);
    }

    return `/mtlx-input/${materialId}/${basename(mtlxPath)}`;
}

function copyPublicInputFile(sourcePath, publicSubdir) {
    if (!sourcePath || /^(?:[a-z]+:)?\/\//i.test(sourcePath) || sourcePath.startsWith('/')) return sourcePath;
    const fullSource = resolve(process.cwd(), sourcePath);
    if (!existsSync(fullSource)) return sourcePath;
    const publicRoot = resolve(process.cwd(), 'public');
    const targetDir = join(publicRoot, 'mtlx-input', publicSubdir);
    mkdirSync(targetDir, { recursive: true });
    const targetFile = join(targetDir, basename(fullSource));
    copyFileSync(fullSource, targetFile);
    return `/mtlx-input/${publicSubdir}/${basename(fullSource)}`;
}

function prepareEnvAsset(sourcePath, publicSubdir) {
    if (!sourcePath) return '';
    if (/^(?:[a-z]+:)?\/\//i.test(sourcePath) || sourcePath.startsWith('/')) return sourcePath;
    if (!existsSync(sourcePath)) return sourcePath;
    const publicRoot = resolve(process.cwd(), 'public');
    const targetDir = join(publicRoot, 'mtlx-input', publicSubdir);
    rmSync(targetDir, { recursive: true, force: true });
    mkdirSync(targetDir, { recursive: true });
    const targetFile = join(targetDir, basename(sourcePath));
    copyFileSync(sourcePath, targetFile);
    return `mtlx-input/${publicSubdir}/${basename(sourcePath)}`;
}

// ---------------------------------------------------------------------------
// Parse des arguments CLI
// ---------------------------------------------------------------------------
const cliArgs = process.argv.slice(2);
const options = {};

for (const arg of cliArgs) {
    const m = arg.match(/^--([^=:]+)(?:[=:](.*))?$/);
    if (!m) { console.warn('Argument ignoré :', arg); continue; }
    options[m[1]] = m[2] ?? 'true';
}

const port          = options.port           ?? '5173';
const useGpu        = (options.gpu           ?? 'false') !== 'false';
const headless      = (options.headless      ?? 'true') !== 'false';
const browserChoice = (options.browser       ?? 'auto').toLowerCase();
const launchTimeoutMs = parseInt(options['launch-timeout-ms'] ?? '180000', 10);
const startServer   = (options['start-server'] ?? 'true') !== 'false';
function defaultOutputPath() {
    const d = new Date();
    const ts = d.getFullYear().toString()
        + String(d.getMonth()+1).padStart(2,'0')
        + String(d.getDate()).padStart(2,'0') + '_'
        + String(d.getHours()).padStart(2,'0')
        + String(d.getMinutes()).padStart(2,'0')
        + String(d.getSeconds()).padStart(2,'0');
    return `render_${ts}.png`;
}
const screenshotPath = options.output ?? options.screenshot ?? defaultOutputPath();
const reportPath = options.report ? resolve(options.report) : null;
const browserErrors = [];
let rejectBrowserFailure;
const browserFailure = new Promise((_resolve, reject) => { rejectBrowserFailure = reject; });
browserFailure.catch(() => {});
const waitSamples   = parseInt(options['spp'] ?? options['wait-samples'] ?? '16', 10);
const dumpGlslDir   = options['dump-glsl']
    ? resolve(options['dump-glsl'] === 'true' ? 'artifacts/glsl-dump' : options['dump-glsl'])
    : null;
// Normalize friendly mode aliases to canonical renderer_mode strings.
const MODE_ALIASES = {
    'pathtracer-mtlx':   'Pathtracer MTLX',
    'raster-mtlx':       'Rasterizer MTLX',
};
const rawMode       = options.mode ?? 'Rasterizer MTLX';
const mode          = MODE_ALIASES[rawMode.toLowerCase()] ?? rawMode;
if (options.oidn !== undefined) throw new Error('--oidn was removed; denoising runs locally in the browser');
const denoiseEnabled = options.denoise === undefined ? mode === 'Pathtracer MTLX' : options.denoise !== 'false';
const linearRadianceOutput = options['linear-radiance-output'] ? resolve(options['linear-radiance-output']) : null;
if (linearRadianceOutput) options.linear_radiance_capture = 'true';
const [renderW, renderH] = (options.size ?? '256x256').toLowerCase().split('x').map(Number);

const mtlxPath      = options.mtlx    ?? null;
const DEFAULT_ENV_MAP = 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\san_giuseppe_bridge.hdr';
const DEFAULT_ENV_IRRADIANCE = 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\irradiance\\san_giuseppe_bridge.hdr';
const envMapInput = options.envmap ?? options.env_map_path ?? DEFAULT_ENV_MAP;
const envIrradianceInput = options.env_irradiance_path ?? DEFAULT_ENV_IRRADIANCE;
delete options.port; delete options.gpu; delete options.headless;
delete options.browser; delete options['launch-timeout-ms'];
delete options['start-server']; delete options.screenshot; delete options.output;
delete options['wait-samples']; delete options['spp']; delete options.mode; delete options.size;
delete options['dump-glsl'];
delete options.report; delete options['linear-radiance-output'];
delete options.mtlx; delete options.denoise; delete options.oidn;
delete options.envmap; delete options.env_map_path; delete options.env_irradiance_path;

if (!options.renderer_mode) options.renderer_mode = mode;
if (options.strict_generated_contract === undefined) options.strict_generated_contract = 'true';
options.env_map_path = prepareEnvAsset(envMapInput, '_env');
options.env_irradiance_path = prepareEnvAsset(envIrradianceInput, '_env/irradiance');
options.env_map_provided = 'true';
// --scene is a shorthand alias for the scene_name param
if (options.scene) { options.scene_name ??= options.scene; delete options.scene; }

// Injection des paramètres MaterialX via WASM (génération GLSL côté Node.js)
// Le .mtlx est copié dans public/ pour que Vite le serve ; le browser le fetchera via ?mtlx_url=.
let mtlxPublicUrl = null;
if (mtlxPath) {
    if (!existsSync(mtlxPath)) throw new Error(`Fichier .mtlx introuvable : ${mtlxPath}`);
    // Preserve the source material-id (filename stem) so the MTLX route/contract
    // resolves the matching generated dispatch artifact, even though the file is
    // served as tmp_material.mtlx.
    if (!options.material_id) {
        options.material_id = basename(mtlxPath).replace(/\.mtlx$/i, '');
    }
    mtlxPublicUrl = copyMtlxWithRelativeFiles(mtlxPath, options.material_id);
    console.log(`MTLX      : ${mtlxPath} → servi via ${mtlxPublicUrl}`);

}

// ---------------------------------------------------------------------------
// Démarrage optionnel du serveur Vite
// ---------------------------------------------------------------------------
let viteProcess = null;
if (startServer) {
    console.log('Démarrage du serveur Vite...');
    viteProcess = spawn(`npx vite --port ${port} --strictPort`, [], {
        shell: true,
        stdio: ['ignore', 'pipe', 'pipe'],
    });
    await new Promise((resolve, reject) => {
        let settled = false;
        let pollTimer;
        const timeout = setTimeout(() => finish(new Error('Vite timeout')), 300000);
        const finish = error => {
            if (settled) return;
            settled = true;
            clearTimeout(timeout);
            clearTimeout(pollTimer);
            error ? reject(error) : resolve();
        };
        const poll = async () => {
            if (settled) return;
            if (viteProcess.exitCode !== null) {
                finish(new Error(`Vite exited before ready (code ${viteProcess.exitCode})`));
                return;
            }
            try {
                const response = await fetch(`http://localhost:${port}/OpenPBR-viewer/`);
                if (response.ok) {
                    finish();
                    return;
                }
            } catch {}
            if (!settled) pollTimer = setTimeout(poll, 250);
        };
        viteProcess.once('error', finish);
        viteProcess.once('exit', code => finish(new Error(`Vite exited before ready (code ${code})`)));
        poll();
    });
    console.log('Serveur Vite prêt.');
    await sleep(500); // Délai supplémentaire pour initialisation complète
}

// ---------------------------------------------------------------------------
// Construction de l'URL
// ---------------------------------------------------------------------------
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;
if (mtlxPublicUrl) options.mtlx_url = mtlxPublicUrl;
// Le viewer désactive le path tracer GPU par défaut ; un rendu non-Rasterizer
// (pathtracer) doit l'activer explicitement via le paramètre d'URL ?gpu=true.
if (options.renderer_mode && options.renderer_mode !== 'Rasterizer MTLX' && !('gpu' in options)) {
    options.gpu = 'true';
}
// Le viewer démarre en pause par défaut ; un rendu automatisé doit accumuler,
// donc on force paused=false sauf si l'appelant l'a explicitement fixé.
if (!('paused' in options)) {
    options.paused = 'false';
}
const query = Object.entries(options)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
const url = query ? `${BASE_URL}?${query}` : BASE_URL;

// ---------------------------------------------------------------------------
// Chemin du navigateur (playwright-core ne l'inclut pas)
// ---------------------------------------------------------------------------
const BROWSER_CANDIDATES = [
    { kind: 'chrome', path: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'chrome', path: 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe' },
    { kind: 'edge', path: 'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe' },
    { kind: 'edge', path: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' },
];
const availableCandidates = BROWSER_CANDIDATES.filter(c => existsSync(c.path));
if (availableCandidates.length === 0) {
    console.error('Chrome ou Edge introuvable.\nAjoutez le chemin dans BROWSER_CANDIDATES dans launch_render.mjs.');
    viteProcess?.kill();
    process.exit(1);
}

let launchCandidates = availableCandidates;
if (browserChoice === 'chrome' || browserChoice === 'edge') {
    launchCandidates = availableCandidates.filter(c => c.kind === browserChoice);
}
if (launchCandidates.length === 0) {
    console.error(`Aucun navigateur disponible pour --browser=${browserChoice}`);
    viteProcess?.kill();
    process.exit(1);
}

// ---------------------------------------------------------------------------
// Flags Chromium
// ---------------------------------------------------------------------------
const args = ['--no-sandbox', '--disable-setuid-sandbox'];
if (!useGpu) {
    args.push('--disable-gpu', '--use-gl=swiftshader');
    console.log('GPU : rendu logiciel (SwiftShader)');
} else {
    args.push('--use-gl=angle', '--enable-gpu');
    console.log('GPU : matériel (ANGLE)');
}

// ---------------------------------------------------------------------------
// Lancement Playwright
// ---------------------------------------------------------------------------
console.log(`Mode      : ${headless ? 'headless' : 'fenêtré'}`);
console.log(`Renderer  : ${options.renderer_mode}`);
console.log(`URL       : ${url}`);
console.log(`Size      : ${renderW}x${renderH}`);
const isPathtracing = options.renderer_mode === 'Pathtracer MTLX' || options.renderer_mode === 'Rasterizer MTLX';
console.log(`Output    : ${screenshotPath}${isPathtracing ? ` (${waitSamples} spp)` : ''}`);
console.log('');

let browser = null;
let launchError = null;
for (const candidate of launchCandidates) {
    try {
        console.log(`Lancement navigateur: ${candidate.kind} (${candidate.path})`);
        browser = await chromium.launch({
            executablePath: candidate.path,
            headless,
            args,
            timeout: launchTimeoutMs
        });
        launchError = null;
        break;
    } catch (err) {
        launchError = err;
        console.warn(`[launch] Echec ${candidate.kind}: ${err?.message ?? err}`);
    }
}

if (!browser) {
    throw launchError ?? new Error('Echec de lancement navigateur');
}
const context = await browser.newContext({ viewport: { width: renderW, height: renderH } });
const page    = await context.newPage();

// Capture les erreurs JS avec stack trace AVANT le chargement des scripts
await page.addInitScript(() => {
    window.addEventListener('error', e => {
        console.error('[JS ERROR]', e.message, '\nat', e.filename + ':' + e.lineno + ':' + e.colno, '\n' + (e.error?.stack ?? ''));
    });
    window.addEventListener('unhandledrejection', e => {
        console.error('[UNHANDLED REJECTION]', e.reason?.message ?? String(e.reason), '\n' + (e.reason?.stack ?? ''));
    });
});

if (dumpGlslDir) {
    await page.addInitScript(() => {
        window.__openpbrShaderSources = [];
        for (const contextType of [window.WebGL2RenderingContext, window.WebGLRenderingContext]) {
            const prototype = contextType?.prototype;
            if (!prototype || prototype.__openpbrShaderSourceHook) continue;
            prototype.__openpbrShaderSourceHook = true;
            const originalShaderSource = prototype.shaderSource;
            prototype.shaderSource = function(shader, source) {
                try {
                    const shaderType = this.getShaderParameter(shader, this.SHADER_TYPE);
                    const type = shaderType === this.FRAGMENT_SHADER ? 'fragment'
                        : shaderType === this.VERTEX_SHADER ? 'vertex' : 'unknown';
                    window.__openpbrShaderSources.push({ type, source: String(source) });
                } catch (_) {}
                return originalShaderSource.call(this, shader, source);
            };
        }
    });
}

if (reportPath) {
    await page.addInitScript(() => {
        window.__openpbrUniformSnapshots = {};
        const programs = new WeakMap();
        const locations = new WeakMap();
        let programIndex = 0;
        for (const contextType of [window.WebGL2RenderingContext, window.WebGLRenderingContext]) {
            const prototype = contextType?.prototype;
            if (!prototype || prototype.__openpbrUniformCaptureHook) continue;
            prototype.__openpbrUniformCaptureHook = true;
            const originalGetUniformLocation = prototype.getUniformLocation;
            prototype.getUniformLocation = function(program, name) {
                const location = originalGetUniformLocation.call(this, program, name);
                if (location) {
                    if (!programs.has(program)) programs.set(program, ++programIndex);
                    locations.set(location, { program: programs.get(program), name });
                }
                return location;
            };
            for (const method of ['uniform1f', 'uniform2f', 'uniform3f', 'uniform4f',
                'uniform1i', 'uniform2i', 'uniform3i', 'uniform4i',
                'uniform1fv', 'uniform2fv', 'uniform3fv', 'uniform4fv',
                'uniform1iv', 'uniform2iv', 'uniform3iv', 'uniform4iv',
                'uniform1ui', 'uniform1uiv', 'uniformMatrix2fv', 'uniformMatrix3fv', 'uniformMatrix4fv']) {
                const original = prototype[method];
                if (!original) continue;
                prototype[method] = function(location, ...values) {
                    const identity = location && locations.get(location);
                    if (identity) {
                        window.__openpbrUniformSnapshots[`${identity.program}:${identity.name}`] = {
                            ...identity, method,
                            values: values.map((value) => ArrayBuffer.isView(value) ? Array.from(value) : value),
                        };
                    }
                    return original.call(this, location, ...values);
                };
            }
        }
    });
}

// Relayer les logs console du navigateur vers le terminal
page.on('console', msg => {
    if (msg.type() === 'warning') return;
    if (msg.type() === 'error') browserErrors.push({ type: 'console', message: msg.text() });
    console.log(`[browser] ${msg.type().toUpperCase()}: ${msg.text()}`);
});
page.on('pageerror', err => {
    browserErrors.push({ type: 'pageerror', message: err.stack ?? err.message });
    rejectBrowserFailure(new Error(`Browser page error: ${err.message}`));
    console.error('[browser] PAGE ERROR:', err.stack ?? err.message);
});
page.on('response',      resp => { if (resp.status() >= 400) console.error(`[browser] HTTP ${resp.status()}: ${resp.url()}`); });
page.on('requestfailed', req  => console.error(`[browser] REQUEST FAILED: ${req.url()} — ${req.failure()?.errorText ?? ''}`));

await page.goto(url, { waitUntil: 'domcontentloaded' });

if (options.scene_url) {
    await page.waitForFunction(() => window.__openpbrScene?.status === 'loaded' || window.__openpbrSceneLoadError,
        null,{ timeout:1200_000 });
    const sceneLoad = await page.evaluate(() => window.__openpbrScene ?? null);
    if (sceneLoad?.status !== 'loaded') {
        const message = await page.evaluate(() => window.__openpbrSceneLoadError || 'scene_url did not load');
        throw new Error(`[scene_url] ${message}`);
    }
}

// Masquer l'UI (GUI, stats, overlays) pour un screenshot propre
if (headless) {
    await page.addStyleTag({ content: `
        #info, #samples, #output, #progress_overlay, #shader-error, #stats-panel, .lil-gui { display: none !important; }
        body > div:not(:has(canvas)), body > div[style*="position"] { display: none !important; }
    `});
}

async function hideUiForScreenshot() {
    if (!headless) return;
    await page.evaluate(() => {
        for (const element of document.body.children) {
            if (element.tagName.toLowerCase() === 'canvas') continue;
            element.setAttribute('data-openpbr-headless-hidden', 'true');
            element.style.setProperty('display', 'none', 'important');
            element.style.setProperty('visibility', 'hidden', 'important');
            element.style.setProperty('pointer-events', 'none', 'important');
        }
    });
}

// Attendre la fin de la compilation des shaders
console.log('Attente de la fin de compilation des shaders...');
try {
    await Promise.race([
        page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 1200_000 }),
        browserFailure,
    ]);
} catch (error) {
    if (reportPath) {
        mkdirSync(dirname(reportPath), { recursive: true });
        writeFileSync(reportPath, `${JSON.stringify({ version: 1, url, requestedMode: mode,
            useGpu, denoiseEnabled, browserErrors, failure: error.message }, null, 2)}\n`, 'utf8');
    }
    await browser.close();
    if (viteProcess) killProcessTree(viteProcess);
    throw error;
}

// Vérifier qu'il n'y a pas eu d'erreur de compilation GLSL
const shaderError = await page.evaluate(() => window.__openpbrShaderError ?? null);
if (shaderError) {
    console.error('\n[ERREUR] Compilation GLSL échouée — arrêt du rendu.');
    if (reportPath) {
        const observed = await page.evaluate(() => ({
            ready: window.__openpbrReady === true,
            shaderError: window.__openpbrShaderError ?? null,
            bvhBackend: window.__openpbrBvhBackend ?? null,
            dispatchBytes: (window.__openpbrMtlxDispatch ?? '').length,
        }));
        mkdirSync(dirname(reportPath), { recursive: true });
        writeFileSync(reportPath, `${JSON.stringify({ version: 1, url, requestedMode: mode,
            useGpu, denoiseEnabled, failure: shaderError, observed, browserErrors }, null, 2)}\n`, 'utf8');
    }
    process.exitCode = 1;
    await browser.close();
    if (viteProcess) killProcessTree(viteProcess);
    process.exit(1);
}

if (dumpGlslDir) {
    const dump = await page.evaluate(() => ({
        shaders: window.__openpbrShaderSources ?? [],
        dispatch: window.__openpbrMtlxDispatch ?? ''
    }));
    if (dump.shaders.length === 0) {
        throw new Error('Aucune source GLSL interceptée; export annulé.');
    }
    mkdirSync(dumpGlslDir, { recursive: true });
    const files = [];
    dump.shaders.forEach(({ type, source }, index) => {
        const name = `webgl-${String(index + 1).padStart(3, '0')}-${type}.glsl`;
        writeFileSync(join(dumpGlslDir, name), source, 'utf8');
        files.push({ name, type, bytes: Buffer.byteLength(source), lines: source.split(/\r?\n/).length });
    });
    if (dump.dispatch) {
        writeFileSync(join(dumpGlslDir, 'wasm-generated-dispatch.glsl'), dump.dispatch, 'utf8');
        files.push({
            name: 'wasm-generated-dispatch.glsl',
            type: 'mtlx-dispatch',
            bytes: Buffer.byteLength(dump.dispatch),
            lines: dump.dispatch.split(/\r?\n/).length
        });
    }
    writeFileSync(join(dumpGlslDir, 'manifest.json'), `${JSON.stringify({ renderer: mode, files }, null, 2)}\n`, 'utf8');
    console.log(`GLSL exporté : ${files.length} fichier(s) dans ${dumpGlslDir}`);
}
console.log('Shaders compilés.');

if (isPathtracing && waitSamples > 0) {
    console.log(`Attente de ${waitSamples} spp...`);
    const deadline = Date.now() + 3000_000;
    let lastSpp = -1;
    while (true) {
        let spp = 0;
        try {
            spp = await page.evaluate(() => window.__openpbrSamples ?? 0);
        } catch (err) {
            const message = err?.message ?? String(err);
            if (/Execution context was destroyed|Cannot find context|navigation/i.test(message)) {
                process.stdout.write('\n  page reload detected; waiting for shaders again...\n');
                await page.waitForLoadState('domcontentloaded', { timeout: 120_000 }).catch(() => {});
                await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 1200_000 });
                lastSpp = -1;
                continue;
            }
            throw err;
        }
        if (spp !== lastSpp) {
            process.stdout.write(`\r  spp: ${spp} / ${waitSamples}`);
            lastSpp = spp;
        }
        if (spp >= waitSamples) break;
        if (Date.now() > deadline) throw new Error(`Timeout: ${waitSamples} spp non atteints en 5 min`);
        await sleep(250);
    }
    process.stdout.write('\n');
    console.log(`${waitSamples} spp atteints.`);
}
try {
  if (waitSamples > 0) {
    await sleep(500); // let GPU compositor finish before screenshot
    let linearRadiance = null;
    if (options.linear_radiance_capture === 'true' || options.linear_radiance_capture === '1') {
        linearRadiance = await page.evaluate(() => window.__openpbrReadLinearRadiance?.() ?? null);
        if (!linearRadiance) throw new Error('LINEAR_RADIANCE_CAPTURE_UNAVAILABLE: hook did not return target data');
        if (linearRadiance.nonFiniteComponents !== 0 || linearRadiance.finitePixels !== linearRadiance.width * linearRadiance.height)
            throw new Error(`LINEAR_RADIANCE_NONFINITE: ${linearRadiance.nonFiniteComponents} nonfinite component(s)`);
        console.log(`Linear radiance ${linearRadiance.width}x${linearRadiance.height} @ ${linearRadiance.samples} spp: mean=${linearRadiance.meanRGB.join(',')}, >1=${linearRadiance.aboveOneComponents}`);
    }
    await hideUiForScreenshot();
    let rawScreenshotPath = null;
    if (denoiseEnabled) {
        if (mode !== 'Pathtracer MTLX') throw new Error('--denoise=true requires Pathtracer MTLX');
        rawScreenshotPath = screenshotPath.replace(/\.png$/i,'_raw.png');
        await page.screenshot({ path:rawScreenshotPath,fullPage:false,timeout:60_000 });
        console.log(`Image brute enregistrée : ${rawScreenshotPath}`);
        const denoiseResult = await page.evaluate(async () => {
            if (typeof window.__openpbrDenoiseCurrent !== 'function')
                throw new Error('DENOISER_API_UNAVAILABLE');
            const result = await window.__openpbrDenoiseCurrent();
            if (result?.status !== 'ready') throw new Error(window.__openpbrDenoiserState?.error || 'DENOISER_NOT_READY');
            window.__openpbrSetDenoisedVisible(true);
            return result;
        });
        console.log(`Denoiser local prêt: ${denoiseResult.width}x${denoiseResult.height} @ ${denoiseResult.samples} spp`);
    }
    if (linearRadianceOutput) {
        const linearCapture = await page.evaluate(() => {
            if (typeof window.__openpbrReadLinearRadiance !== 'function') throw new Error('LINEAR_RADIANCE_CAPTURE_UNAVAILABLE');
            const raw = window.__openpbrReadLinearRadiance({ includePixels:true });
            const denoised = window.__openpbrReadDenoisedRadiance?.() ?? null;
            return { ...raw,rgba:Array.from(raw.rgba),denoised:denoised ? Array.from(denoised) : null };
        });
        mkdirSync(dirname(linearRadianceOutput),{recursive:true});
        writeFileSync(linearRadianceOutput,`${JSON.stringify(linearCapture)}\n`,'utf8');
        console.log(`Radiance linéaire exportée : ${linearRadianceOutput}`);
    }
    await page.screenshot({ path: screenshotPath, fullPage: false, timeout: 60_000 });
    console.log(`Image enregistrée : ${screenshotPath}`);
    if (reportPath) {
        const observed = await page.evaluate((linearRadiance) => ({
            ready: window.__openpbrReady === true,
            samples: window.__openpbrSamples ?? 0,
            shaderError: window.__openpbrShaderError ?? null,
            contextLoss: window.__openpbrContextLossReport ?? null,
            gpu: window.__openpbrGpuInfo ?? null,
            rendererState: window.__openpbrGetRendererState?.() ?? null,
            dispatchBytes: (window.__openpbrMtlxDispatch ?? '').length,
            bvhBackend: window.__openpbrBvhBackend ?? null,
            scene: window.__openpbrScene ?? null,
            linearRadiance,
            denoiser: window.__openpbrDenoiserState ?? null,
            uniforms: window.__openpbrUniformSnapshots ?? {},
        }),linearRadiance);
        mkdirSync(dirname(reportPath), { recursive: true });
        writeFileSync(reportPath, `${JSON.stringify({
            version: 1, url, requestedMode: mode, requestedSamples: waitSamples,
            requestedSize: [renderW, renderH], useGpu, denoiseEnabled,
            screenshotPath,rawScreenshotPath,observed,browserErrors,
        }, null, 2)}\n`, 'utf8');
    }

  } else {
    console.log('spp=0 : aucune capture générée (mode aperçu).');
  }

    if (!headless) {
        console.log('Navigateur ouvert. Fermez la fenêtre pour terminer.');
        // timeout: 0 -> pas de limite (le défaut Playwright de 30 s fermait Vite tout seul).
        await page.waitForEvent('close', { timeout: 0 }).catch(() => {});
    }
} finally {
    await browser.close().catch(() => {});
    if (viteProcess) {
        killProcessTree(viteProcess);
        console.log('Serveur Vite arrêté.');
    }
    console.log('Terminé.');
}
