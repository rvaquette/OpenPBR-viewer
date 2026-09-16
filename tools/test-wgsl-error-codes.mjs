#!/usr/bin/env node
import assert from 'node:assert/strict';
import { classifyMtlxWgslError, formatMtlxWgslError, MTLX_WGSL_ERROR_CODES } from '../src/webgpu/errorCodes.js';

const cases = [
  ['generated dispatch missing', MTLX_WGSL_ERROR_CODES.dispatch],
  ['unsupported closure model', MTLX_WGSL_ERROR_CODES.closure],
  ['texture fetch failed: 404', MTLX_WGSL_ERROR_CODES.texture],
  ['signature entry point mismatch', MTLX_WGSL_ERROR_CODES.signature],
  ['adapter limit exceeded maxBindingsPerBindGroup', MTLX_WGSL_ERROR_CODES.limits],
  ['WGSL shader compilation failed', MTLX_WGSL_ERROR_CODES.compile],
  ['Naga SPIR-V transpile failed', MTLX_WGSL_ERROR_CODES.transpile],
];
for (const [message, expected] of cases) assert.equal(classifyMtlxWgslError(new Error(message)), expected);
assert.match(formatMtlxWgslError(new Error('texture fetch failed')), /^\[MTLX_WGSL_TEXTURE_INVALID\]/);
console.log(JSON.stringify({ pass: true, cases: cases.length }, null, 2));
