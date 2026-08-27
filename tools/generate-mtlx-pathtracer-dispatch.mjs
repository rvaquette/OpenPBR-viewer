#!/usr/bin/env node
// Generate per-material `generated_bsdf_dispatch.glsl` from a .mtlx material using
// the MaterialX host generator (MtlxPathTracerHostShaderGenerator). This wrapper
// resolves deterministic paths and enforces the forbidden-dependency contract.
//
// Usage:
//   node tools/generate-mtlx-pathtracer-dispatch.mjs --mtlx=<path> [--out=<path>]
//
// If --out is omitted, the deterministic path is used:
//   glsl/pathtracing/mtlx/generated/<material-id>/generated_bsdf_dispatch.glsl

import { mkdirSync, writeFileSync, existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import {
  materialIdFromMtlxPath,
  generatedDispatchPath,
  findForbiddenReferences,
  hasDispatchFunctions
} from "./mtlx-pathtracer-common.mjs";

function argValue(name) {
  const arg = process.argv.find(a => a.startsWith(`--${name}=`));
  return arg ? arg.slice(name.length + 3) : "";
}

// Host-generator invocation. The dispatch body is emitted by the C++
// MtlxPathTracerHostShaderGenerator (compiled to WASM). The generator fails
// explicitly for unsupported/incomplete materials, so no legacy/approximation
// fallback is ever produced here.
async function generateDispatchGlsl(mtlxPath) {
  const wasmJs = resolve(process.cwd(), "public/mtlx/JsMaterialXGenShader.js");
  if (!existsSync(wasmJs)) {
    throw new Error(`[mtlx-dispatch] MaterialX WASM module not found at ${wasmJs}`);
  }
  const mod = await import(pathToFileURL(wasmJs).href);
  const mx = await mod.default({ locateFile: p => resolve(process.cwd(), "public/mtlx", p) });
  if (typeof mx.MtlxPathTracerHostShaderGenerator === "undefined") {
    throw new Error(
      "[mtlx-dispatch] MtlxPathTracerHostShaderGenerator is not exposed by the current WASM build. " +
      "Build and expose the new C++ generator (US2) before generating dispatch."
    );
  }
  const gen = mx.MtlxPathTracerHostShaderGenerator.create();
  const ctx = new mx.GenContext(gen);
  const stdlib = mx.loadStandardLibraries(ctx);
  const doc = mx.createDocument();
  doc.importLibrary(stdlib);
  const mtlxText = readFileSync(mtlxPath, "utf8");
  await mx.readFromXmlString(doc, mtlxText, "");
  const elem = mx.findRenderableElement(doc);
  if (!elem) {
    throw new Error(`[mtlx-dispatch] no renderable element in ${mtlxPath}`);
  }
  const glsl = gen.generate(elem.getNamePath(), elem, ctx).getSourceCode("pixel");
  if (!glsl || !glsl.trim()) {
    throw new Error(`[mtlx-dispatch] empty pixel source generated for ${mtlxPath}`);
  }
  return glsl;
}

async function main() {
  const mtlxArg = argValue("mtlx");
  if (!mtlxArg) {
    console.error("Missing required argument: --mtlx=<path-to-.mtlx>");
    process.exit(2);
  }
  const mtlxPath = resolve(process.cwd(), mtlxArg);
  if (!existsSync(mtlxPath)) {
    console.error(`[mtlx-dispatch] .mtlx not found: ${mtlxPath}`);
    process.exit(2);
  }

  const materialId = materialIdFromMtlxPath(mtlxPath);
  const outArg = argValue("out");
  const outPath = resolve(process.cwd(), outArg || generatedDispatchPath(materialId));

  const glsl = await generateDispatchGlsl(mtlxPath);

  const forbidden = findForbiddenReferences(glsl);
  if (forbidden.length > 0) {
    console.error(`[mtlx-dispatch] forbidden references in generated output: ${forbidden.join(", ")}`);
    process.exit(1);
  }
  if (!hasDispatchFunctions(glsl)) {
    console.error("[mtlx-dispatch] generated output is missing evaluateBsdf/sampleBsdf definitions");
    process.exit(1);
  }

  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, glsl, "utf8");
  console.log(JSON.stringify({ materialId, out: outPath, ok: true }, null, 2));
}

main().catch(err => {
  console.error(err.message || String(err));
  process.exit(1);
});
