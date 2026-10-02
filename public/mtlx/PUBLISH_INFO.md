# Published MaterialX runtime artifacts

This directory contains published runtime artifacts consumed by the OpenPBR viewer.

## Current files
- JsMaterialXGenShader.js
- JsMaterialXGenShader.wasm
- JsMaterialXGenShader.data
- material-contract.json
- generator-abi-expectations.json
- generated-function-registry.mjs

## Publication notes
- Source generator repository: ../MaterialX-rva
- Host generators: source/MaterialXGenGlsl/EsslHostShaderGenerator.cpp and source/MaterialXGenGlsl/MtlxPathTracerHostShaderGenerator.cpp
- Publication date: 2026-10-02
- Publication mode: synchronized JS/WASM/data bundle with typed nodegraph interface uniforms
