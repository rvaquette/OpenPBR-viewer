import { assertGpuLayouts, GPU_LAYOUTS } from '../src/webgpu/gpuLayouts.js';

assertGpuLayouts();
console.log(JSON.stringify(GPU_LAYOUTS, null, 2));