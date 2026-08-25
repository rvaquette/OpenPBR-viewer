// Deterministic paths and shared checks for the MTLX pathtracer host generator workflow.

import { basename } from "node:path";

const REQUIRED_MODELS = [
  "open_pbr_surface",
  "standard_surface",
  "disney_principled",
  "gltf_pbr",
  "usd_preview_surface"
];

// Forbidden implementation dependencies for the MTLX route and generated artifacts.
const FORBIDDEN_PATTERNS = [
  /(^|[^\w])legacy\//,
  /_brdf\b/,
  /_btdf\b/,
  /openpbr_bsdf_evaluate/,
  /openpbr_bsdf_sample/,
  /PathTracerGlslShaderGenerator/
];

// material-id is the .mtlx filename without extension (deterministic, filesystem-safe).
function materialIdFromMtlxPath(mtlxPath) {
  return basename(String(mtlxPath)).replace(/\.mtlx$/i, "");
}

function generatedDispatchPath(materialId) {
  return `glsl/pathtracing/mtlx/generated/${materialId}/generated_bsdf_dispatch.glsl`;
}

// Strip line/block comments so documented forbidden references don't trip the check.
function stripGlslComments(source) {
  return String(source)
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/[^\n]*/g, "");
}

function findForbiddenReferences(source) {
  const code = stripGlslComments(source);
  const hits = [];
  for (const pattern of FORBIDDEN_PATTERNS) {
    const m = code.match(pattern);
    if (m) hits.push(m[0].trim());
  }
  return hits;
}

function hasDispatchFunctions(source) {
  const code = stripGlslComments(source);
  return /\bvec3\s+evaluateBsdf\s*\(/.test(code) && /\bvec3\s+sampleBsdf\s*\(/.test(code);
}

export {
  REQUIRED_MODELS,
  FORBIDDEN_PATTERNS,
  materialIdFromMtlxPath,
  generatedDispatchPath,
  stripGlslComments,
  findForbiddenReferences,
  hasDispatchFunctions
};
