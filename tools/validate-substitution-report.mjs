#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function validateEntry(entry) {
  const errors = [];
  const required = [
    "materialId",
    "substitutionStatus",
    "renderStatus",
    "generatedFunctionsUsed",
    "visualDifferenceType",
    "renderTimeMs",
    "wasmGenerationVersion",
    "criticalDifference"
  ];

  for (const field of required) {
    if (!(field in entry)) errors.push(`missing required field: ${field}`);
  }

  if (!["success", "failure"].includes(entry.substitutionStatus)) {
    errors.push("substitutionStatus must be success|failure");
  }
  if (!["success", "failure"].includes(entry.renderStatus)) {
    errors.push("renderStatus must be success|failure");
  }
  if (!Array.isArray(entry.generatedFunctionsUsed)) {
    errors.push("generatedFunctionsUsed must be an array");
  }
  if (!["none", "energy", "hue", "detail", "mixed"].includes(entry.visualDifferenceType)) {
    errors.push("visualDifferenceType must be one of none|energy|hue|detail|mixed");
  }
  if (typeof entry.renderTimeMs !== "number" || Number.isNaN(entry.renderTimeMs) || entry.renderTimeMs < 0) {
    errors.push("renderTimeMs must be a non-negative number");
  }
  if (typeof entry.wasmGenerationVersion !== "string" || !entry.wasmGenerationVersion.length) {
    errors.push("wasmGenerationVersion must be a non-empty string");
  }
  if (typeof entry.criticalDifference !== "boolean") {
    errors.push("criticalDifference must be a boolean");
  }

  const failed = entry.substitutionStatus === "failure" || entry.renderStatus === "failure";
  if (failed && (typeof entry.failureCause !== "string" || !entry.failureCause.length)) {
    errors.push("failureCause is required when substitutionStatus or renderStatus is failure");
  }

  return errors;
}

function validatePayload(payload) {
  const entries = Array.isArray(payload) ? payload : payload?.entries;
  if (!Array.isArray(entries)) {
    return { ok: false, errors: ["payload must be an array or an object with entries[]"] };
  }

  const errors = [];
  entries.forEach((entry, i) => {
    const entryErrors = validateEntry(entry);
    for (const err of entryErrors) errors.push(`entries[${i}]: ${err}`);
  });

  return { ok: errors.length === 0, errors, count: entries.length };
}

export function validateReportFile(reportPath) {
  const payload = readJson(reportPath);
  return validatePayload(payload);
}

if (process.argv[1] && process.argv[1].toLowerCase().endsWith("validate-substitution-report.mjs")) {
  const reportArg = process.argv.find(a => a.startsWith("--report="));
  const reportPath = resolve(process.cwd(), reportArg ? reportArg.slice("--report=".length) : "substitution-report.json");

  let schemaId = "";
  const schemaArg = process.argv.find(a => a.startsWith("--schema="));
  if (schemaArg) {
    const schemaPath = resolve(process.cwd(), schemaArg.slice("--schema=".length));
    try {
      const schema = readJson(schemaPath);
      schemaId = schema?.$id || "";
    } catch {
      // schema is optional for this lightweight validator
    }
  }

  const result = validateReportFile(reportPath);
  const summary = {
    ok: result.ok,
    count: result.count || 0,
    schemaId,
    errors: result.errors
  };
  console.log(JSON.stringify(summary, null, 2));
  process.exit(result.ok ? 0 : 1);
}
