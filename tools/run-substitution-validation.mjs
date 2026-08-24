#!/usr/bin/env node
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { performance } from "node:perf_hooks";
import { checkGeneratorAbi } from "./check-generator-abi.mjs";
import { validateReportFile } from "./validate-substitution-report.mjs";
import { createReportEntry, createRunSummary, writeRunArtifact } from "./substitution-report.mjs";

function argValue(name, fallback = "") {
  const arg = process.argv.find(a => a.startsWith(`--${name}=`));
  return arg ? arg.slice(name.length + 3) : fallback;
}

function readJsonIfExists(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

const nowIso = () => new Date().toISOString();

async function main() {
  const reportPath = resolve(process.cwd(), argValue("report", "artifacts/substitution-report.json"));
  const schemaPath = resolve(process.cwd(), argValue("schema", "specs/002-wasm-bxdf-replacement/contracts/substitution-report.schema.json"));
  const glslPath = argValue("glsl") ? resolve(process.cwd(), argValue("glsl")) : "";
  const materialsPath = argValue("materials") ? resolve(process.cwd(), argValue("materials")) : "";
  const manualPath = argValue("manual") ? resolve(process.cwd(), argValue("manual")) : "";
  const version = argValue("version", "unknown");
  const maxMsPerMaterial = Number(argValue("max-ms-per-material", "30000"));
  const integrationTargetMinutes = Number(argValue("integration-target-minutes", "15"));

  const runId = `substitution-${Date.now()}`;
  const startedAt = nowIso();
  const startedPerf = performance.now();

  const materialListRaw = readJsonIfExists(materialsPath) || ["default-material"];
  const materials = Array.isArray(materialListRaw)
    ? materialListRaw
    : Array.isArray(materialListRaw?.materials)
      ? materialListRaw.materials
      : ["default-material"];

  const manualInput = readJsonIfExists(manualPath) || {};

  let abi = null;
  if (glslPath) {
    const glslSource = readFileSync(glslPath, "utf8");
    abi = checkGeneratorAbi({ glslSource, generatorVersion: version });
  }

  const entries = [];
  for (const material of materials) {
    const mat = typeof material === "string" ? { materialId: material } : material;
    const t0 = performance.now();

    const manualCategory = manualInput?.[mat.materialId]?.visualDifferenceType || mat.visualDifferenceType || "none";
    const criticalDifference = ["energy", "hue", "detail", "mixed"].includes(manualCategory);

    const abiFailure = abi && !abi.conformsToLegacyExpectations;
    const substitutionStatus = abiFailure ? "failure" : (mat.substitutionStatus || "success");
    const renderStatus = abiFailure ? "failure" : (mat.renderStatus || "success");

    const entry = createReportEntry({
      materialId: mat.materialId || "unknown-material",
      substitutionStatus,
      renderStatus,
      generatedFunctionsUsed: mat.generatedFunctionsUsed || ["EvalMtlxClosure", "SampleMtlxClosure"],
      visualDifferenceType: manualCategory,
      renderTimeMs: Number(mat.renderTimeMs || (performance.now() - t0)),
      wasmGenerationVersion: mat.wasmGenerationVersion || version,
      failureCause: abiFailure ? "abi_non_conformant" : mat.failureCause,
      criticalDifference
    });

    if (entry.renderTimeMs > maxMsPerMaterial && entry.substitutionStatus === "success") {
      entry.substitutionStatus = "failure";
      entry.renderStatus = "failure";
      entry.failureCause = "runtime_stability_watchdog_timeout";
      entry.criticalDifference = true;
    }

    entries.push(entry);
  }

  const completedAt = nowIso();
  const durationMs = performance.now() - startedPerf;
  const summary = createRunSummary(entries, {
    runId,
    wasmGenerationVersion: version,
    startedAt,
    completedAt
  });
  summary.durationMs = durationMs;
  summary.durationMinutes = durationMs / 60000;
  summary.integrationTargetMinutes = integrationTargetMinutes;
  summary.integrationTargetMet = summary.durationMinutes <= integrationTargetMinutes;

  const payload = { runId, startedAt, completedAt, summary, entries, abi };
  writeRunArtifact(reportPath, payload);

  const validation = validateReportFile(reportPath);
  const passRateOk = summary.passRate >= 0.95;
  const noCritical = entries.every(e => !e.criticalDifference);
  const abiOk = !abi || abi.conformsToLegacyExpectations;
  const overallOk = validation.ok && passRateOk && noCritical && abiOk && summary.integrationTargetMet;

  const verdict = {
    ok: overallOk,
    checks: {
      schemaValidation: validation.ok,
      passRateGte95Percent: passRateOk,
      noCriticalDifferences: noCritical,
      abiConformance: abiOk,
      integrationTimeWithinTarget: summary.integrationTargetMet
    },
    summary
  };

  const verdictPath = resolve(dirname(reportPath), "substitution-verdict.json");
  mkdirSync(dirname(verdictPath), { recursive: true });
  writeFileSync(verdictPath, JSON.stringify(verdict, null, 2), "utf8");

  console.log(JSON.stringify(verdict, null, 2));
  process.exit(overallOk ? 0 : 1);
}

main().catch(err => {
  console.error("Substitution validation failed:", err);
  process.exit(1);
});
