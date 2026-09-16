#!/usr/bin/env node
import { chromium } from 'playwright-core';
import { existsSync } from 'node:fs';
import { spawn } from 'node:child_process';

const port = process.env.SMOKE_PORT || '5192';
const BASE_URL = `http://localhost:${port}`;
const candidates = [
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
];
const browserPath = candidates.find(existsSync);
if (!browserPath) {
  console.error('Chrome or Edge not found for the minimal lights[] test.');
  process.exit(1);
}

console.log('Starting Vite server...');
const vite = spawn('npx', ['vite', '--port', port], { shell: true, stdio: ['ignore', 'pipe', 'pipe'] });
await new Promise((resolve, reject) => {
  const timeout = setTimeout(() => reject(new Error('Vite timeout')), 60000);
  const onOutput = data => {
    if (/Local:|localhost:/i.test(data.toString())) {
      clearTimeout(timeout);
      resolve();
    }
  };
  vite.stdout.on('data', onOutput);
  vite.stderr.on('data', onOutput);
  vite.on('error', reject);
});
console.log('Vite ready.');

let browser = null;
let exitCode = 0;
try {
  browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--use-gl=angle', '--enable-gpu', '--enable-unsafe-webgpu'],
  });
  const page = await browser.newPage({ viewport: { width: 128, height: 128 } });
  await page.goto(`${BASE_URL}/OpenPBR-viewer/minimal-lights-test.html`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => typeof window.runMinimalLightTest === 'function', null, { timeout: 30000 });
  const result = await page.evaluate(async () => window.runMinimalLightTest());
  console.log(JSON.stringify(result, null, 2));

  if (!result.ok) {
    console.error('Minimal lights[] case failed: buffer packing or WGSL array interpretation is wrong.');
    exitCode = 1;
  }
} catch (error) {
  console.error('Minimal lights[] test crashed:', error?.message || error);
  exitCode = 1;
} finally {
  await browser?.close();
  vite.kill();
}

process.exit(exitCode);
