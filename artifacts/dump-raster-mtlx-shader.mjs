import { chromium } from 'playwright-core';
import { spawn, execSync } from 'child_process';
import { existsSync, writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';

const port = '5174';
const out = 'artifacts/mtlx-pathtracer/generated/brick_raster_mtlx_final_assembled.glsl';
const url = `http://localhost:${port}/OpenPBR-viewer/?skyPower=2.0&renderer_mode=Rasterizer%20MTLX&strict_generated_contract=true&legacy_comparison=false&env_map_path=textures%2Fenvmaps%2Fetzwihl_16k.jpg&env_irradiance_path=&env_map_provided=true&scene_name=standard-shader-ball&material_id=brick_procedural&mtlx_url=%2Fmtlx-input%2Fbrick_procedural%2Fbrick_procedural.mtlx`;
function killProcessTree(proc) { try { execSync(`taskkill /F /T /PID ${proc.pid}`, { stdio: 'ignore' }); } catch { proc.kill(); } }
const vite = spawn(`npx vite --port ${port}`, [], { shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
await new Promise((resolve, reject) => { const t = setTimeout(() => reject(new Error('Vite timeout')), 300000); vite.stdout.on('data', d => { if (d.toString().includes('localhost:')) { clearTimeout(t); resolve(); } }); vite.on('error', reject); });
const executablePath = ['C:/Program Files/Google/Chrome/Application/chrome.exe','C:/Program Files (x86)/Google/Chrome/Application/chrome.exe','C:/Program Files/Microsoft/Edge/Application/msedge.exe','C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].find(existsSync);
if (!executablePath) throw new Error('Chrome/Edge not found');
const browser = await chromium.launch({ executablePath, headless: true, args: ['--disable-gpu', '--use-gl=swiftshader', '--no-sandbox'] });
try {
  const page = await browser.newPage({ viewport: { width: 256, height: 256 } });
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => typeof window.__openpbrMtlxRasterFragmentShader === 'string' && window.__openpbrMtlxRasterFragmentShader.length > 0, null, { timeout: 1200000 });
  const shader = await page.evaluate(() => window.__openpbrMtlxRasterFragmentShader);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, shader, 'utf8');
  console.log(JSON.stringify({ out, lines: shader.split('\n').length, bytes: shader.length, hasEvaluate: /mtlxGenEvaluateBsdf/.test(shader), hasSample: /mtlxGenSampleBsdf/.test(shader) }, null, 2));
} finally { await browser.close().catch(() => {}); killProcessTree(vite); }
