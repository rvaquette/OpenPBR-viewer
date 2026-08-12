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
 *   --start-server          Démarre npx vite avant le lancement (défaut: true)
 *   --port=5173             Port Vite (défaut: 5173)
 *   --output=out.png        Fichier image de sortie (défaut: render_YYYYMMDD_HHMMSS.png)
 *   --screenshot=out.png    Alias de --output
 *   --spp=N                 Samples path-tracing à attendre avant la capture (défaut: 10)
 *   --size=WxH             Résolution du rendu (défaut: 256x256)  ex: --size=1280x720
 *
 * Options rendu :
 *   --mode=Rasterizer|Pathtracer
 *   --gpu=true|false        false = rendu logiciel SwiftShader (défaut: true)
 *   --scene=standard-shader-ball|glavenus|terrain|bearded-man
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
import { existsSync }  from 'fs';
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

// ---------------------------------------------------------------------------
// Parse des arguments CLI
// ---------------------------------------------------------------------------
const cliArgs = process.argv.slice(2);
const options = {};

for (const arg of cliArgs) {
    const m = arg.match(/^--([^=]+)(?:=(.*))?$/);
    if (!m) { console.warn('Argument ignoré :', arg); continue; }
    options[m[1]] = m[2] ?? 'true';
}

const port          = options.port           ?? '5173';
const useGpu        = (options.gpu           ?? 'true') !== 'false';
const headless      = (options.headless      ?? 'true') !== 'false';
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
const waitSamples   = parseInt(options['spp'] ?? options['wait-samples'] ?? '10', 10);
const mode          = options.mode           ?? 'Rasterizer';
const [renderW, renderH] = (options.size ?? '256x256').toLowerCase().split('x').map(Number);

delete options.port; delete options.gpu; delete options.headless;
delete options['start-server']; delete options.screenshot; delete options.output;
delete options['wait-samples']; delete options['spp']; delete options.mode; delete options.size;

if (!options.renderer_mode) options.renderer_mode = mode;

// ---------------------------------------------------------------------------
// Démarrage optionnel du serveur Vite
// ---------------------------------------------------------------------------
let viteProcess = null;
if (startServer) {
    console.log('Démarrage du serveur Vite...');
    viteProcess = spawn('npx', ['vite', '--port', port], {
        shell: true,
        stdio: ['ignore', 'pipe', 'pipe'],
    });
    // Attendre que Vite soit prêt
    await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Vite timeout')), 30000);
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
const query = Object.entries(options)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
const url = query ? `${BASE_URL}?${query}` : BASE_URL;

// ---------------------------------------------------------------------------
// Chemin du navigateur (playwright-core ne l'inclut pas)
// ---------------------------------------------------------------------------
const BROWSER_CANDIDATES = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
];
const executablePath = BROWSER_CANDIDATES.find(p => existsSync(p));
if (!executablePath) {
    console.error('Chrome ou Edge introuvable.\nAjoutez le chemin dans BROWSER_CANDIDATES dans launch_render.mjs.');
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
console.log(`Output    : ${screenshotPath}${options.renderer_mode === 'Pathtracer' ? ` (${waitSamples} spp)` : ''}`);
console.log('');

const browser = await chromium.launch({ executablePath, headless, args });
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
page.on('console', msg => console.log(`[browser] ${msg.type().toUpperCase()}: ${msg.text()}`));
page.on('pageerror', err => console.error('[browser] PAGE ERROR:', err.stack ?? err.message));
page.on('response',      resp => { if (resp.status() >= 400) console.error(`[browser] HTTP ${resp.status()}: ${resp.url()}`); });
page.on('requestfailed', req  => console.error(`[browser] REQUEST FAILED: ${req.url()} — ${req.failure()?.errorText ?? ''}`));

await page.goto(url, { waitUntil: 'domcontentloaded' });

// Attendre la fin de la compilation des shaders
console.log('Attente de la fin de compilation des shaders...');
await page.waitForFunction(() => window.__openpbrReady === true, null, { timeout: 120_000 });
console.log('Shaders compilés.');

if (options.renderer_mode === 'Pathtracing' && waitSamples > 0) {
    console.log(`Attente de ${waitSamples} spp...`);
    await page.waitForFunction(
        n => (window.__openpbrSamples ?? 0) >= n,
        waitSamples,
        { timeout: 300_000 }
    );
    console.log(`${waitSamples} spp atteints.`);
}
try {
    await page.screenshot({ path: screenshotPath, fullPage: false });
    console.log(`Image enregistrée : ${screenshotPath}`);

    if (!headless) {
        console.log('Navigateur ouvert. Fermez la fenêtre pour terminer.');
        await page.waitForEvent('close').catch(() => {});
    }
} finally {
    await browser.close().catch(() => {});
    if (viteProcess) {
        killProcessTree(viteProcess);
        console.log('Serveur Vite arrêté.');
    }
    console.log('Terminé.');
}
