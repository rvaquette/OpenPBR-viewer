import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const VALID_STATUSES = new Set(["success", "failure"]);
const VALID_DIFF_TYPES = new Set(["none", "energy", "hue", "detail", "mixed"]);

function normalizeFailureCause(rawCause, details = "") {
  const value = String(rawCause || "").trim().toLowerCase();
  if (!value) return "unknown_failure";
  if (value.includes("missing") || value.includes("symbol")) return "missing_required_function";
  if (value.includes("signature")) return "signature_mismatch";
  if (value.includes("abi")) return "abi_non_conformant";
  if (value.includes("schema")) return "schema_validation_failed";
  if (value.includes("render") || value.includes("compile")) return "render_pipeline_failure";
  if (value.includes("critical")) return "critical_visual_difference";
  if (details) return value;
  return "unknown_failure";
}

function isCriticalVisualDifference(visualDifferenceType) {
  return ["energy", "hue", "detail", "mixed"].includes(String(visualDifferenceType || ""));
}

function createReportEntry(input) {
  const entry = {
    materialId: String(input.materialId || "unknown-material"),
    substitutionStatus: VALID_STATUSES.has(input.substitutionStatus) ? input.substitutionStatus : "failure",
    renderStatus: VALID_STATUSES.has(input.renderStatus) ? input.renderStatus : "failure",
    generatedFunctionsUsed: Array.isArray(input.generatedFunctionsUsed) ? input.generatedFunctionsUsed : [],
    visualDifferenceType: VALID_DIFF_TYPES.has(input.visualDifferenceType) ? input.visualDifferenceType : "none",
    renderTimeMs: Number.isFinite(input.renderTimeMs) ? input.renderTimeMs : 0,
    wasmGenerationVersion: String(input.wasmGenerationVersion || "unknown"),
    criticalDifference: typeof input.criticalDifference === "boolean"
      ? input.criticalDifference
      : isCriticalVisualDifference(input.visualDifferenceType)
  };

  const failed = entry.substitutionStatus === "failure" || entry.renderStatus === "failure";
  if (failed) {
    entry.failureCause = normalizeFailureCause(input.failureCause, input.failureDetails);
  } else if (input.failureCause) {
    entry.failureCause = normalizeFailureCause(input.failureCause, input.failureDetails);
  }

  return entry;
}

function createRunSummary(entries, runMeta = {}) {
  const safeEntries = Array.isArray(entries) ? entries : [];
  const total = safeEntries.length;
  const successful = safeEntries.filter(e => e.substitutionStatus === "success" && e.renderStatus === "success").length;
  const failures = total - successful;
  const critical = safeEntries.filter(e => e.criticalDifference).length;
  const avgRenderTimeMs = total ? safeEntries.reduce((sum, e) => sum + Number(e.renderTimeMs || 0), 0) / total : 0;
  return {
    runId: runMeta.runId || `run-${Date.now()}`,
    wasmGenerationVersion: runMeta.wasmGenerationVersion || "unknown",
    startedAt: runMeta.startedAt || new Date().toISOString(),
    completedAt: runMeta.completedAt || new Date().toISOString(),
    totalMaterials: total,
    successCount: successful,
    failureCount: failures,
    criticalCount: critical,
    passRate: total ? successful / total : 0,
    avgRenderTimeMs
  };
}

function writeRunArtifact(outputPath, payload) {
  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, JSON.stringify(payload, null, 2), "utf8");
}

export {
  normalizeFailureCause,
  isCriticalVisualDifference,
  createReportEntry,
  createRunSummary,
  writeRunArtifact
};
