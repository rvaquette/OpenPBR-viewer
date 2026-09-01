#!/usr/bin/env node
/**
 * render-showcase.mjs — Rendu par lot de tous les .mtlx d'un dossier, dans les
 * 4 modes du viewer, via launch_render.mjs.
 *
 * Pour chaque .mtlx trouvé (récursivement) sous --showcase, lance 4 rendus :
 *   Rasterizer legacy, Rasterizer MTLX, Pathtracer legacy, Pathtracer MTLX
 * et écrit le PNG sous  <out>/<mode>/<nom-du-mtlx>.png
 *
 * Usage :
 *   node render-showcase.mjs
 *   node render-showcase.mjs --showcase="D:\\...\\showcase" --spp=16 --size=256x256 --gpu=false
 *
 * Options :
 *   --showcase=DIR     Dossier racine des .mtlx (défaut: material-samples showcase)
 *   --filter=a,b,...   Ne rendre que les .mtlx dont le chemin relatif contient l'une
 *                      de ces sous-chaînes (insensible à la casse). Ex: --filter=chrome,gold
 *                      ou --filter=standard_surface/glass
 *   --out=DIR          Dossier de sortie (défaut: artifacts)
 *   --spp=N            Samples path-tracing (défaut: 16)
 *   --size=WxH         Résolution (défaut: 256x256)
 *   --gpu=true|false   GPU réel ou SwiftShader (défaut: false = logiciel)
 *   --firefly_clamp=N  Clamp anti-firefly (défaut viewer: 10). Augmenter pour des
 *                      émissions/lumières intenses non écrêtées (ex: --firefly_clamp=20000)
 *   --port=5173        Port Vite (défaut: 5173)
 *   --start-server=auto|true|false  Démarrage serveur (défaut: auto = démarre si absent)
 *   --modes=a,b,...    Sous-ensemble de modes (folders) à rendre (défaut: les 4)
 */

import { spawn, spawnSync, execSync } from 'child_process';
import { existsSync, mkdirSync, readdirSync, statSync } from 'fs';
import { basename, dirname, join, relative, resolve, sep } from 'path';
import { fileURLToPath } from 'url';
import http from 'http';
import { setTimeout as sleep } from 'timers/promises';

const __dirname = dirname(fileURLToPath(import.meta.url));

// --- CLI ---------------------------------------------------------------------
const opts = {};
for (const arg of process.argv.slice(2)) {
    const m = arg.match(/^--([^=:]+)(?:[=:](.*))?$/);
    if (m) opts[m[1]] = m[2] ?? 'true';
}

const showcaseDir = opts.showcase ?? 'D:\\WebGL2\\MaterialX\\material-samples\\materials\\showcase';
const filterPatterns = (opts.filter ?? '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean);
const outDir      = resolve(__dirname, opts.out ?? 'artifacts');
const spp         = opts.spp  ?? '16';
const size        = opts.size ?? '256x256';
const gpu         = (opts.gpu ?? 'false') !== 'false' ? 'true' : 'false';
const fireflyClamp = opts['firefly_clamp'] ?? null;
const port        = opts.port ?? '5173';
const startServer = (opts['start-server'] ?? 'auto').toLowerCase();
const BASE_URL    = `http://localhost:${port}/OpenPBR-viewer/`;

// mode -> dossier de sortie
const ALL_MODES = [
    { mode: 'Rasterizer legacy', folder: 'rasterizer-legacy' },
    { mode: 'Rasterizer MTLX',   folder: 'rasterizer-mtlx'   },
    { mode: 'Pathtracer legacy', folder: 'pathtracer-legacy' },
    { mode: 'Pathtracer MTLX',   folder: 'pathtracer-mtlx'   },
];
const modeFilter = opts.modes ? new Set(opts.modes.split(',').map(s => s.trim())) : null;
const MODES = modeFilter ? ALL_MODES.filter(m => modeFilter.has(m.folder)) : ALL_MODES;

// --- Collecte récursive des .mtlx --------------------------------------------
function collectMtlx(dir) {
    const out = [];
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const full = join(dir, entry.name);
        if (entry.isDirectory()) out.push(...collectMtlx(full));
        else if (entry.isFile() && /\.mtlx$/i.test(entry.name)) out.push(full);
    }
    return out;
}

// Nom unique dérivé du chemin relatif (évite les collisions carpaint/glass/...).
function uniqueNameFor(file, rootDir, used) {
    const relDir = relative(rootDir, dirname(file));
    const stem = basename(file).replace(/\.mtlx$/i, '');
    const segs = relDir ? relDir.split(sep) : [];
    // Le stem duplique souvent le dossier feuille — ne pas le répéter.
    if (segs.length && segs[segs.length - 1] === stem) segs.pop();
    let name = [...segs, stem].join('__') || stem;
    let unique = name, i = 1;
    while (used.has(unique)) unique = `${name}_${i++}`;
    used.add(unique);
    return unique;
}

// --- Serveur Vite ------------------------------------------------------------
function ping(url) {
    return new Promise(res => {
        const req = http.get(url, r => { r.resume(); res(true); });
        req.on('error', () => res(false));
        req.setTimeout(1500, () => { req.destroy(); res(false); });
    });
}

function killTree(proc) {
    if (!proc) return;
    try { execSync(`taskkill /F /T /PID ${proc.pid}`, { stdio: 'ignore' }); }
    catch { proc.kill(); }
}

async function ensureServer() {
    const up = await ping(BASE_URL);
    if (up) { console.log(`Serveur déjà actif sur ${BASE_URL}`); return null; }
    if (startServer === 'false') {
        console.error(`Aucun serveur sur ${BASE_URL} et --start-server=false. Abandon.`);
        process.exit(1);
    }
    console.log('Démarrage du serveur Vite...');
    const proc = spawn(`npx vite --port ${port}`, [], { shell: true, cwd: __dirname, stdio: ['ignore', 'pipe', 'pipe'] });
    await new Promise((res, rej) => {
        const t = setTimeout(() => rej(new Error('Vite timeout')), 300000);
        proc.stdout.on('data', d => { if (d.toString().includes('localhost:')) { clearTimeout(t); res(); } });
        proc.on('error', rej);
    });
    await sleep(800);
    console.log('Serveur Vite prêt.');
    return proc;
}

// --- Rendu unitaire ----------------------------------------------------------
function renderOne(mtlxFile, modeSpec, name) {
    const destDir = join(outDir, modeSpec.folder);
    mkdirSync(destDir, { recursive: true });
    const screenshot = join(destDir, `${name}.png`);
    const args = [
        'launch_render.mjs',
        '--headless=true',
        '--start-server=false',
        `--gpu=${gpu}`,
        `--mode=${modeSpec.mode}`,
        `--mtlx=${mtlxFile}`,
        `--spp=${spp}`,
        `--size=${size}`,
        '--denoise=false',
        `--port=${port}`,
        `--screenshot=${screenshot}`,
    ];
    if (fireflyClamp !== null) args.push(`--firefly_clamp=${fireflyClamp}`);
    const r = spawnSync(process.execPath, args, { cwd: __dirname, encoding: 'utf8' });
    const ok = r.status === 0 && existsSync(screenshot);
    if (!ok) {
        const tail = ((r.stderr || '') + (r.stdout || '')).split('\n').filter(Boolean).slice(-6).join('\n   ');
        console.error(`   ✗ ${modeSpec.folder} — échec (code ${r.status})\n   ${tail}`);
    }
    return ok ? screenshot : null;
}

// --- Main --------------------------------------------------------------------
(async () => {
    if (!existsSync(showcaseDir)) {
        console.error(`Dossier introuvable : ${showcaseDir}`);
        process.exit(1);
    }
    const files = collectMtlx(showcaseDir).sort();
    if (files.length === 0) {
        console.error(`Aucun .mtlx sous ${showcaseDir}`);
        process.exit(1);
    }
    const selected = filterPatterns.length
        ? files.filter(f => {
            const rel = relative(showcaseDir, f).replace(/\\/g, '/').toLowerCase();
            return filterPatterns.some(p => rel.includes(p));
          })
        : files;
    if (selected.length === 0) {
        console.error(`Aucun .mtlx ne correspond au filtre: ${filterPatterns.join(', ')}`);
        process.exit(1);
    }

    const used = new Set();
    const jobs = selected.map(f => ({ file: f, name: uniqueNameFor(f, showcaseDir, used) }));

    console.log(`${jobs.length} matériaux${filterPatterns.length ? ` (filtre: ${filterPatterns.join(', ')})` : ''} × ${MODES.length} modes = ${jobs.length * MODES.length} rendus`);
    console.log(`Sortie : ${outDir}`);
    console.log(`spp=${spp} size=${size} gpu=${gpu}\n`);

    const server = await ensureServer();
    let done = 0, failed = 0;
    const total = jobs.length * MODES.length;
    try {
        for (const job of jobs) {
            console.log(`● ${job.name}`);
            for (const modeSpec of MODES) {
                const out = renderOne(job.file, modeSpec, job.name);
                if (out) { done++; console.log(`   ✓ ${modeSpec.folder}`); }
                else failed++;
                console.log(`     [${done + failed}/${total}]`);
            }
        }
    } finally {
        killTree(server);
    }

    console.log(`\nTerminé : ${done} réussis, ${failed} échoués sur ${total}.`);
    process.exit(failed > 0 ? 1 : 0);
})();
