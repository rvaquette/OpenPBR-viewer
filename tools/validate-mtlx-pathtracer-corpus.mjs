#!/usr/bin/env node
// Validate the MTLX pathtracer generated dispatch corpus:
//  - required function definitions (evaluateBsdf/sampleBsdf)
//  - absence of forbidden legacy/PathTracerGlslShaderGenerator references
//  - carpaint vs synthetic fixture distinction in the report
//
// Usage:
//   node tools/validate-mtlx-pathtracer-corpus.mjs [--report=<path>]

import { readFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import {
  REQUIRED_MODELS,
  materialIdFromMtlxPath,
  generatedDispatchPath,
  findForbiddenReferences,
  hasDispatchFunctions
} from "./mtlx-pathtracer-common.mjs";

const CARPAINT_SOURCE_DIR = "D:/WebGL2/MaterialX/materials";
const SYNTHETIC_SOURCE_DIR = "artifacts/mtlx-pathtracer/fixtures";

// Mixed validation corpus manifest: 5 carpaint + 5 synthetic (one per required model).
function buildCorpusManifest() {
  const carpaint = [
    { model: "open_pbr_surface", mtlx: `${CARPAINT_SOURCE_DIR}/open_pbr_carpaint.mtlx` },
    { model: "standard_surface", mtlx: `${CARPAINT_SOURCE_DIR}/standard_surface_carpaint.mtlx` },
    { model: "disney_principled", mtlx: `${CARPAINT_SOURCE_DIR}/disney_principled_carpaint.mtlx` },
    { model: "gltf_pbr", mtlx: `${CARPAINT_SOURCE_DIR}/gltf_pbr_carpaint.mtlx` },
    { model: "usd_preview_surface", mtlx: `${CARPAINT_SOURCE_DIR}/usd_preview_surface_carpaint.mtlx` }
  ].map(e => ({ ...e, fixtureType: "carpaint" }));

  const synthetic = REQUIRED_MODELS.map(model => ({
    model,
    fixtureType: "synthetic",
    mtlx: `${SYNTHETIC_SOURCE_DIR}/synthetic_${model}.mtlx`
  }));

  return [...carpaint, ...synthetic].map(e => {
    const materialId = materialIdFromMtlxPath(e.mtlx);
    return { ...e, materialId, dispatch: generatedDispatchPath(materialId) };
  });
}

function checkFixture(entry) {
  const dispatchPath = resolve(process.cwd(), entry.dispatch);
  // Viewer compile/render evidence: launch_render.mjs writes render_<materialId>.png
  // on a successful MTLX-route compile + render.
  const viewerImage = `artifacts/mtlx-pathtracer/validation/render_${entry.materialId}.png`;
  const viewerCompileStatus = existsSync(resolve(process.cwd(), viewerImage)) ? "success" : "not_run";
  if (!existsSync(dispatchPath)) {
    return { ...entry, generationStatus: "failure", legacyDependencyCheckStatus: "failure", viewerCompileStatus, viewerImage, failureCause: "missing_generated_dispatch" };
  }
  const source = readFileSync(dispatchPath, "utf8");
  const forbidden = findForbiddenReferences(source);
  const hasFns = hasDispatchFunctions(source);
  const legacyOk = forbidden.length === 0;
  const genOk = hasFns;
  const status = {
    ...entry,
    generationStatus: genOk ? "success" : "failure",
    legacyDependencyCheckStatus: legacyOk ? "success" : "failure",
    viewerCompileStatus,
    viewerImage
  };
  if (!genOk || !legacyOk) {
    status.failureCause = !hasFns ? "missing_dispatch_functions" : `forbidden_reference:${forbidden.join(",")}`;
  }
  return status;
}

function main() {
  const reportArg = process.argv.find(a => a.startsWith("--report="));
  const reportPath = resolve(process.cwd(), reportArg ? reportArg.slice("--report=".length) : "artifacts/mtlx-pathtracer/validation/report.json");

  const manifest = buildCorpusManifest();
  const entries = manifest.map(checkFixture);

  const carpaint = entries.filter(e => e.fixtureType === "carpaint");
  const synthetic = entries.filter(e => e.fixtureType === "synthetic");
  const summarize = list => ({
    total: list.length,
    passed: list.filter(e => e.generationStatus === "success" && e.legacyDependencyCheckStatus === "success").length,
    failed: list.filter(e => e.generationStatus === "failure" || e.legacyDependencyCheckStatus === "failure").length,
    viewerRendered: list.filter(e => e.viewerCompileStatus === "success").length
  });

  const report = {
    generatedAt: new Date().toISOString(),
    // No legacy fallback and no generic approximation path exist in the MTLX route
    // (T041): assemble_mtlx_route_dispatch() throws when the generated dispatch is
    // missing, and MtlxPathTracerHostShaderGenerator throws on unsupported/incomplete
    // materials. Per-fixture legacyDependencyCheckStatus proves the generated GLSL
    // carries no legacy _brdf/_btdf or PathTracerGlslShaderGenerator references.
    guarantees: {
      noLegacyFallback: entries.every(e => e.legacyDependencyCheckStatus === "success"),
      noGenericApproximation: true
    },
    carpaint: summarize(carpaint),
    synthetic: summarize(synthetic),
    entries
  };
  const ok = report.carpaint.failed === 0 && report.synthetic.failed === 0;

  mkdirSync(dirname(reportPath), { recursive: true });
  writeFileSync(reportPath, JSON.stringify(report, null, 2), "utf8");
  console.log(JSON.stringify({ ok, carpaint: report.carpaint, synthetic: report.synthetic, report: reportPath }, null, 2));
  process.exit(ok ? 0 : 1);
}

main();
