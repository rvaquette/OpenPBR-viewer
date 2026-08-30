const DEFAULT_REQUIRED_SYMBOLS = [
  "pt_InitMaterialSummary",
  "EvalMtlxClosure",
  "SampleMtlxClosure"
];

function normalizeSignature(signature) {
  return String(signature || "")
    .replace(/\s+/g, " ")
    .replace(/\s*([(),])\s*/g, "$1")
    .trim();
}

function parseFunctionSignatures(glsl) {
  const text = String(glsl || "");
  const regex = /^\s*(?:highp|mediump|lowp)?\s*([a-zA-Z_]\w*)\s+([a-zA-Z_]\w*)\s*\(([^)]*)\)\s*\{/gm;
  const signatures = new Map();
  let match;
  while ((match = regex.exec(text)) !== null) {
    const returnType = match[1];
    const name = match[2];
    const args = match[3].trim();
    const signature = normalizeSignature(`${returnType} ${name}(${args})`);
    signatures.set(name, signature);
  }
  return signatures;
}

function deriveDefaultMaterialContract(materialId = "default") {
  return {
    materialId,
    wasmGenerationVersion: "unknown",
    requiredFunctions: [...DEFAULT_REQUIRED_SYMBOLS],
    optionalFunctions: []
  };
}

function checkRequiredFunctions(registry, materialContract) {
  const required = materialContract?.requiredFunctions || [];
  const expectedSignatures = materialContract?.requiredSignatures || {};
  const missingFunctions = [];
  const signatureMismatches = [];

  for (const fnName of required) {
    if (!registry.signatures.has(fnName)) {
      missingFunctions.push(fnName);
      continue;
    }
    const expected = expectedSignatures[fnName];
    if (!expected) continue;
    const actual = registry.signatures.get(fnName);
    if (normalizeSignature(expected) !== normalizeSignature(actual)) {
      signatureMismatches.push({ fnName, expected, actual });
    }
  }

  return {
    ok: missingFunctions.length === 0 && signatureMismatches.length === 0,
    missingFunctions,
    signatureMismatches
  };
}

function buildGeneratedFunctionRegistry(glsl, options = {}) {
  const signatures = parseFunctionSignatures(glsl);
  return {
    generatorVersion: options.generatorVersion || "unknown",
    sourceHash: options.sourceHash || "unknown",
    signatures,
    hasSymbol(name) {
      return signatures.has(name);
    },
    getSignature(name) {
      return signatures.get(name) || null;
    },
    toJSON() {
      return {
        generatorVersion: this.generatorVersion,
        sourceHash: this.sourceHash,
        signatures: Object.fromEntries(this.signatures)
      };
    }
  };
}

export {
  DEFAULT_REQUIRED_SYMBOLS,
  normalizeSignature,
  parseFunctionSignatures,
  deriveDefaultMaterialContract,
  checkRequiredFunctions,
  buildGeneratedFunctionRegistry
};
