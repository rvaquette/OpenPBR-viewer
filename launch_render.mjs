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
 *   --legacy_comparison=true|false               Active le mode manuel Pathtracer legacy (defaut: false)
 *   --denoise=true|false    Débruitage OIDN après capture (défaut: false)
 *   --oidn=path             Chemin vers oidnDenoise.exe (défaut: oidnDenoise dans PATH)
 *
 * Options rendu :
 *   --mode=Rasterizer legacy|Rasterizer MTLX|Pathtracer MTLX|Pathtracer legacy
 *                                (alias: --mode=mtlx pour la route MTLX pathtracer,
 *                                        --mode=raster-mtlx pour la route MTLX rasterizer,
 *                                        --mode=legacy pour le pathtracer manuel)
 *   --gpu=true|false              false = rendu logiciel SwiftShader (défaut: true)
 *   --scene=standard-shader-ball|glavenus|terrain|bearded-man
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
 *   node launch_render.mjs --headless --mode=Pathtracer --base_color=0.8,0.1,0.1 --base_metalness=1 --screenshot=metal.png --spp=64
 *
 *   # Verre en rasterizer sans GPU, démarrage serveur automatique
 *   node launch_render.mjs --headless --start-server --mode=Rasterizer --transmission_weight=1 --gpu=false --output=glass.png
 *
 *   # Aperçu fenêtré (mode normal)
 *   node launch_render.mjs --mode=Pathtracer --base_metalness=1 --base_color=0.2,0.5,1
 */

import { chromium }    from 'playwright-core';
import { spawn, execSync } from 'child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, unlinkSync } from 'fs';
import { basename, dirname, isAbsolute, join, resolve } from 'path';
import { setTimeout as sleep } from 'timers/promises';
import sharp from 'sharp';

// ---------------------------------------------------------------------------
// Parseur MaterialX (open_pbr_surface, bloc unique)
// ---------------------------------------------------------------------------

// Noms MaterialX qui diffèrent des noms params du viewer
const MTLX_NAME_MAP = {
    specular_roughness_anisotropy : 'specular_anisotropy',
    coat_roughness_anisotropy     : 'coat_anisotropy',
};

function parseMtlx(filePath) {
    const xml = readFileSync(filePath, 'utf8');

    // Extraire le bloc <open_pbr_surface ...>...</open_pbr_surface>
    // ou <open_pbr_surface ... /> (auto-fermant)
    const blockRe = /<open_pbr_surface\b[^>]*>([\s\S]*?)<\/open_pbr_surface>|<open_pbr_surface\b([^>]*\/\s*)>/;
    const blockMatch = xml.match(blockRe);
    if (!blockMatch) throw new Error(`Aucun nœud <open_pbr_surface> trouvé dans ${filePath}`);

    const innerXml = blockMatch[1] ?? blockMatch[0]; // contenu ou tag entier

    // Extraire chaque <input name="..." type="..." value="..." />
    const inputRe = /<input\b([^>]*)\/>/g;
    const result = {};
    let m;
    while ((m = inputRe.exec(innerXml)) !== null) {
        const attrs = m[1];
        const name  = (attrs.match(/\bname="([^"]+)"/)  ?? [])[1];
        const type  = (attrs.match(/\btype="([^"]+)"/)  ?? [])[1];
        const value = (attrs.match(/\bvalue="([^"]+)"/) ?? [])[1];
        if (!name || !type || value === undefined) continue;

        const paramName = MTLX_NAME_MAP[name] ?? name;

        if (type === 'color3' || type === 'vector3') {
            // "0.912, 0.914, 0.920" → "0.912,0.914,0.920"
            result[paramName] = value.replace(/\s*,\s*/g, ',').trim();
        } else {
            result[paramName] = value.trim();
        }
    }
    // emission_weight defaults to 0 in OpenPBR, but a material that explicitly sets
    // emission_luminance/color clearly intends to emit — default to 1 when absent.
    if (result.emission_luminance !== undefined && result.emission_weight === undefined)
        result.emission_weight = '1';
    return result;
}

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

function normalizeSceneMaterial(raw, index, sceneDir) {
    const mtlx = raw.mtlx ?? raw.file ?? raw.path;
    if (!mtlx) throw new Error(`[mtlx-scene] materials[${index}] missing mtlx/file/path`);
    const id = raw.id ?? raw.materialId ?? basename(mtlx).replace(/\.mtlx$/i, '') ?? `material_${index}`;
    const objects = Array.isArray(raw.objects) ? raw.objects : Array.isArray(raw.meshes) ? raw.meshes : [];
    const source = isAbsolute(mtlx) ? mtlx : resolve(sceneDir, mtlx);
    return { id, source, objects };
}

function copyMtlxSceneManifest(scenePath) {
    const fullScenePath = resolve(process.cwd(), scenePath);
    if (!existsSync(fullScenePath)) throw new Error(`[mtlx-scene] manifest not found: ${fullScenePath}`);
    const sceneDir = dirname(fullScenePath);
    const scene = JSON.parse(readFileSync(fullScenePath, 'utf8'));
    const rawMaterials = Array.isArray(scene.materials) ? scene.materials : [];
    if (rawMaterials.length === 0) throw new Error('[mtlx-scene] manifest requires a non-empty materials array');

    const sceneId = basename(fullScenePath).replace(/\.json$/i, '') || 'scene';
    const normalizedMaterials = rawMaterials.map((raw, index) => {
        const material = normalizeSceneMaterial(raw, index, sceneDir);
        const materialId = `${sceneId}_${index}_${material.id}`.replace(/[^A-Za-z0-9_-]/g, '_');
        const mtlxUrl = copyMtlxWithRelativeFiles(material.source, materialId);
        console.log(`MTLX scene material[${index}] ${material.id}: ${material.source} → ${mtlxUrl}`);
        return {
            slot: index,
            id: material.id,
            materialId,
            mtlx_url: mtlxUrl,
            objects: material.objects
        };
    });

    const publicRoot = resolve(process.cwd(), 'public');
    const targetDir = join(publicRoot, 'mtlx-input', '_scenes');
    mkdirSync(targetDir, { recursive: true });
    const targetFile = join(targetDir, `${sceneId}.json`);
    writeFileSync(targetFile, JSON.stringify({
        version: 1,
        scene_name: scene.scene_name ?? scene.sceneName ?? null,
        materials: normalizedMaterials
    }, null, 2), 'utf8');
    return `/mtlx-input/_scenes/${sceneId}.json`;
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
const waitSamples   = parseInt(options['spp'] ?? options['wait-samples'] ?? '16', 10);
// Normalize friendly mode aliases to canonical renderer_mode strings.
const MODE_ALIASES = {
    'pathtracer-mtlx':   'Pathtracer MTLX',
    'raster-mtlx':       'Rasterizer MTLX',
    'rasterizer-legacy': 'Rasterizer legacy',
    'pathtracer-legacy': 'Pathtracer legacy',
};
const rawMode       = options.mode ?? 'Rasterizer legacy';
const mode          = MODE_ALIASES[rawMode.toLowerCase()] ?? rawMode;
const [renderW, renderH] = (options.size ?? '256x256').toLowerCase().split('x').map(Number);

const mtlxPath      = options.mtlx    ?? null;
const mtlxScenePath = options.mtlx_scene ?? null;
const denoiseEnabled = (options.denoise ?? 'true') !== 'false';
const oidnPath       = options.oidn    ?? 'D:\\oidn-2.5.0\\bin\\oidnDenoise.exe';
const DEFAULT_ENV_MAP = 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\san_giuseppe_bridge.hdr';
const DEFAULT_ENV_IRRADIANCE = 'D:\\WebGL2\\MaterialX\\MaterialX-rva\\resources\\Lights\\irradiance\\san_giuseppe_bridge.hdr';
const envMapInput = options.envmap ?? options.env_map_path ?? DEFAULT_ENV_MAP;
const envIrradianceInput = options.env_irradiance_path ?? DEFAULT_ENV_IRRADIANCE;
delete options.port; delete options.gpu; delete options.headless;
delete options.browser; delete options['launch-timeout-ms'];
delete options['start-server']; delete options.screenshot; delete options.output;
delete options['wait-samples']; delete options['spp']; delete options.mode; delete options.size;
delete options.mtlx; delete options.mtlx_scene; delete options.denoise; delete options.oidn;
delete options.envmap; delete options.env_map_path; delete options.env_irradiance_path;

if (!options.renderer_mode) options.renderer_mode = mode;
if (options.strict_generated_contract === undefined) options.strict_generated_contract = 'true';
if (options.legacy_comparison === undefined) options.legacy_comparison = 'false';
options.env_map_path = prepareEnvAsset(envMapInput, '_env');
options.env_irradiance_path = prepareEnvAsset(envIrradianceInput, '_env/irradiance');
options.env_map_provided = 'true';
// --scene is a shorthand alias for the scene_name param
if (options.scene) { options.scene_name ??= options.scene; delete options.scene; }

// Injection des paramètres MaterialX via WASM (génération GLSL côté Node.js)
// Le .mtlx est copié dans public/ pour que Vite le serve ; le browser le fetchera via ?mtlx_url=.
// En mode legacy, les params sont en plus extraits via parseMtlx() et injectés dans l'URL.
let mtlxPublicUrl = null;
let mtlxScenePublicUrl = null;
if (mtlxScenePath) {
    mtlxScenePublicUrl = copyMtlxSceneManifest(mtlxScenePath);
    console.log(`MTLX scene: ${mtlxScenePath} → servi via ${mtlxScenePublicUrl}`);
}
else if (mtlxPath) {
    if (!existsSync(mtlxPath)) throw new Error(`Fichier .mtlx introuvable : ${mtlxPath}`);
    // Preserve the source material-id (filename stem) so the MTLX route/contract
    // resolves the matching generated dispatch artifact, even though the file is
    // served as tmp_material.mtlx.
    if (!options.material_id) {
        options.material_id = basename(mtlxPath).replace(/\.mtlx$/i, '');
    }
    mtlxPublicUrl = copyMtlxWithRelativeFiles(mtlxPath, options.material_id);
    console.log(`MTLX      : ${mtlxPath} → servi via ${mtlxPublicUrl}`);

    // En mode legacy, injecter aussi les params comme query string pour alimenter les uniforms.
    if (options.renderer_mode === 'Pathtracer legacy') {
        options.legacy_comparison = 'true';
        try {
            const mtlxParams = parseMtlx(mtlxPath);
            // CLI args take priority over mtlx values
            for (const [k, v] of Object.entries(mtlxParams)) {
                if (!(k in options)) options[k] = v;
            }
            console.log(`MTLX legacy params : ${Object.keys(mtlxParams).length} paramètres`);
        } catch (e) {
            console.warn('[mtlx] parseMtlx failed:', e.message);
        }
    }
}

// ---------------------------------------------------------------------------
// Démarrage optionnel du serveur Vite
// ---------------------------------------------------------------------------
let viteProcess = null;
if (startServer) {
    console.log('Démarrage du serveur Vite...');
    viteProcess = spawn(`npx vite --port ${port}`, [], {
        shell: true,
        stdio: ['ignore', 'pipe', 'pipe'],
    });
    // Attendre que Vite soit prêt
    await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Vite timeout')), 300000);
        viteProcess.stdout.on('data', data => {
            if (data.toString().includes('localhost:')) {
                clearTimeout(timeout);
                resolve();
            }
        });
        viteProcess.on('error', reject);
    });
    console.log('Serveur Vite prêt.');
    await sleep(500); // Délai supplémentaire pour initialisation complète
}

// ---------------------------------------------------------------------------
// Construction de l'URL
// ---------------------------------------------------------------------------
const BASE_URL = `http://localhost:${port}/OpenPBR-viewer/`;
if (mtlxPublicUrl) options.mtlx_url = mtlxPublicUrl;
if (mtlxScenePublicUrl) options.mtlx_scene_url = mtlxScenePublicUrl;
// Le viewer désactive le path tracer GPU par défaut ; un rendu non-Rasterizer
// (pathtracer) doit l'activer explicitement via le paramètre d'URL ?gpu=true.
if (options.renderer_mode && options.renderer_mode !== 'Rasterizer legacy' && !('gpu' in options)) {
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
const isPathtracing = options.renderer_mode === 'Pathtracer' || options.renderer_mode === 'Pathtracer MTLX' || options.renderer_mode === 'Rasterizer MTLX' || options.renderer_mode === 'Pathtracer legacy';
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

// Relayer les logs console du navigateur vers le terminal
page.on('console', msg => {
    if (msg.type() === 'warning') return;
    console.log(`[browser] ${msg.type().toUpperCase()}: ${msg.text()}`);
});
page.on('pageerror', err => console.error('[browser] PAGE ERROR:', err.stack ?? err.message));
page.on('response',      resp => { if (resp.status() >= 400) console.error(`[browser] HTTP ${resp.status()}: ${resp.url()}`); });
page.on('requestfailed', req  => console.error(`[browser] REQUEST FAILED: ${req.url()} — ${req.failure()?.errorText ?? ''}`));

await page.goto(url, { waitUntil: 'domcontentloaded' });

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
await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 1200_000 });

// Vérifier qu'il n'y a pas eu d'erreur de compilation GLSL
const shaderError = await page.evaluate(() => window.__openpbrShaderError ?? null);
if (shaderError) {
    console.error('\n[ERREUR] Compilation GLSL échouée — arrêt du rendu.');
    process.exitCode = 1;
    await browser.close();
    if (viteProcess) viteProcess.kill();
    process.exit(1);
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
    await hideUiForScreenshot();
    await page.screenshot({ path: screenshotPath, fullPage: false, timeout: 60_000 });
    console.log(`Image enregistrée : ${screenshotPath}`);

    if (denoiseEnabled) {
        const pfmIn  = screenshotPath.replace(/\.png$/i, '_oidn_in.pfm');
        const pfmOut = screenshotPath.replace(/\.png$/i, '_oidn_out.pfm');
        console.log('Débruitage OIDN...');
        try {
            // OIDN 2.x accepte PFM (float32, rows bottom-to-top, little-endian avec scale -1.0)
            const { data, info } = await sharp(screenshotPath).removeAlpha().raw().toBuffer({ resolveWithObject: true });
            const { width, height } = info;
            const floatBuf = Buffer.allocUnsafe(width * height * 3 * 4);
            for (let row = 0; row < height; row++) {
                const dstRow = height - 1 - row; // PFM: bottom-to-top
                for (let col = 0; col < width; col++) {
                    const s = (row * width + col) * 3;
                    const d = (dstRow * width + col) * 3 * 4;
                    floatBuf.writeFloatLE(data[s]   / 255, d);
                    floatBuf.writeFloatLE(data[s+1] / 255, d + 4);
                    floatBuf.writeFloatLE(data[s+2] / 255, d + 8);
                }
            }
            writeFileSync(pfmIn, Buffer.concat([
                Buffer.from(`PF\n${width} ${height}\n-1.0\n`, 'ascii'), floatBuf
            ]));
            execSync(`"${oidnPath}" --ldr "${pfmIn}" -o "${pfmOut}"`, { stdio: 'pipe' });
            // PFM → PNG (rows bottom-to-top → flip back, float32 → uint8)
            const pfmBuf = readFileSync(pfmOut);
            let pos = 0, nl = 0;
            while (nl < 3) if (pfmBuf[pos++] === 0x0A) nl++;
            const [outW, outH] = pfmBuf.slice(pfmBuf.indexOf(0x0A) + 1).toString('ascii', 0, 30).trim().split(/\s+/).map(Number);
            const rgbOut = Buffer.allocUnsafe(outW * outH * 3);
            for (let row = 0; row < outH; row++) {
                const srcRow = outH - 1 - row;
                for (let col = 0; col < outW; col++) {
                    const s = pos + (srcRow * outW + col) * 3 * 4;
                    const d = (row * outW + col) * 3;
                    rgbOut[d]   = Math.min(255, Math.max(0, Math.round(pfmBuf.readFloatLE(s)     * 255)));
                    rgbOut[d+1] = Math.min(255, Math.max(0, Math.round(pfmBuf.readFloatLE(s + 4) * 255)));
                    rgbOut[d+2] = Math.min(255, Math.max(0, Math.round(pfmBuf.readFloatLE(s + 8) * 255)));
                }
            }
            await sharp(rgbOut, { raw: { width: outW, height: outH, channels: 3 } }).png().toFile(screenshotPath);
            unlinkSync(pfmIn); unlinkSync(pfmOut);
            console.log('Débruitage terminé.');
        } catch (e) {
            console.warn('OIDN échoué :', e.message.trim());
            try { unlinkSync(pfmIn); } catch {}
            try { unlinkSync(pfmOut); } catch {}
        }
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
