#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import sharp from 'sharp';

function option(name) {
    const arg = process.argv.find(value => value.startsWith(`--${name}=`));
    return arg ? arg.slice(name.length + 3) : null;
}

const referencePath = resolve(process.cwd(), option('reference') || '');
const candidatePath = resolve(process.cwd(), option('candidate') || '');
const outputPath = option('output') ? resolve(process.cwd(), option('output')) : null;
const meanThreshold = Number(option('mean-threshold') ?? '0.08');
const outlierThreshold = Number(option('outlier-threshold') ?? '0.02');
const pixelThreshold = Number(option('pixel-threshold') ?? '0.25');

if (!existsSync(referencePath) || !existsSync(candidatePath)) {
    throw new Error('Both --reference and --candidate image paths must exist.');
}

const [reference, candidate] = await Promise.all([
    sharp(referencePath).removeAlpha().raw().toBuffer({ resolveWithObject: true }),
    sharp(candidatePath).removeAlpha().raw().toBuffer({ resolveWithObject: true })
]);
if (reference.info.width !== candidate.info.width || reference.info.height !== candidate.info.height) {
    throw new Error(`Image dimensions differ: ${reference.info.width}x${reference.info.height} vs ${candidate.info.width}x${candidate.info.height}`);
}

let errorSum = 0;
let outliers = 0;
const pixelCount = reference.info.width * reference.info.height;
for (let offset = 0; offset < reference.data.length; offset += 3) {
    const error = (Math.abs(reference.data[offset] - candidate.data[offset])
        + Math.abs(reference.data[offset + 1] - candidate.data[offset + 1])
        + Math.abs(reference.data[offset + 2] - candidate.data[offset + 2])) / (3 * 255);
    errorSum += error;
    if (error > pixelThreshold) outliers++;
}

const result = {
    reference: referencePath,
    candidate: candidatePath,
    width: reference.info.width,
    height: reference.info.height,
    meanAbsoluteRgbError: errorSum / pixelCount,
    outlierPixelRatio: outliers / pixelCount,
    thresholds: { meanAbsoluteRgbError: meanThreshold, outlierPixelRatio: outlierThreshold, pixelAbsoluteRgbError: pixelThreshold },
    pass: errorSum / pixelCount <= meanThreshold && outliers / pixelCount <= outlierThreshold
};
if (outputPath) writeFileSync(outputPath, `${JSON.stringify(result, null, 2)}\n`, 'utf8');
console.log(JSON.stringify(result, null, 2));
process.exit(result.pass ? 0 : 1);
