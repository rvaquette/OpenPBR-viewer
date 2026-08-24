#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const DEFAULT_EXPECTATIONS = {
  requiredSymbols: ["pt_InitMaterialSummary", "EvalMtlxClosure", "SampleMtlxClosure"],
  requiredSignatures: {}
};

function normalizeSignature(signature) {
  return String(signature || "")
    .replace(/\s+/g, " ")
    .replace(/\s*([(),])\s*/g, "$1")
    .trim();
}

function parseSignatures(glsl) {
  const signatures = {};
  const regex = /^\s*(?:highp|mediump|lowp)?\s*([a-zA-Z_]\w*)\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*\{/gm;
  let match;
  while ((match = regex.exec(glsl)) !== null) {
    signatures[match[2]] = normalizeSignature(`${match[1]} ${match[2]}(${match[3]})`);
  }
  return signatures;
}

function checkGeneratorAbi({ glslSource, expectations = DEFAULT_EXPECTATIONS, generatorVersion = "unknown" }) {
  const signatures = parseSignatures(glslSource);
  const missingSymbols = [];
  const signatureMismatches = [];

  for (const symbol of expectations.requiredSymbols || []) {
    if (!(symbol in signatures)) {
      missingSymbols.push(symbol);
      continue;
    }
    const expectedSig = expectations.requiredSignatures?.[symbol];
    if (expectedSig && normalizeSignature(expectedSig) !== signatures[symbol]) {
      signatureMismatches.push({ symbol, expected: normalizeSignature(expectedSig), actual: signatures[symbol] });
    }
  }

  return {
    generatorVersion,
    conformsToLegacyExpectations: missingSymbols.length === 0 && signatureMismatches.length === 0,
    exportedEntryPoints: Object.keys(signatures),
    signatureMap: signatures,
    missingSymbols,
    signatureMismatches
  };
}

export { checkGeneratorAbi };

if (process.argv[1] && process.argv[1].toLowerCase().endsWith("check-generator-abi.mjs")) {
  const glslArg = process.argv.find(a => a.startsWith("--glsl="));
  const outArg = process.argv.find(a => a.startsWith("--out="));
  const expectationsArg = process.argv.find(a => a.startsWith("--expectations="));
  const versionArg = process.argv.find(a => a.startsWith("--version="));

  if (!glslArg) {
    console.error("Missing required argument: --glsl=<path>");
    process.exit(2);
  }

  const glslPath = resolve(process.cwd(), glslArg.slice("--glsl=".length));
  const glslSource = readFileSync(glslPath, "utf8");

  let expectations = DEFAULT_EXPECTATIONS;
  if (expectationsArg) {
    const path = resolve(process.cwd(), expectationsArg.slice("--expectations=".length));
    expectations = JSON.parse(readFileSync(path, "utf8"));
  }

  const result = checkGeneratorAbi({
    glslSource,
    expectations,
    generatorVersion: versionArg ? versionArg.slice("--version=".length) : "unknown"
  });

  if (outArg) {
    const outPath = resolve(process.cwd(), outArg.slice("--out=".length));
    writeFileSync(outPath, JSON.stringify(result, null, 2), "utf8");
  }

  console.log(JSON.stringify(result, null, 2));
  process.exit(result.conformsToLegacyExpectations ? 0 : 1);
}
