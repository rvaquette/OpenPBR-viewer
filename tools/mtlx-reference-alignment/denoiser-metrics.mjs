export function compareLinearRadianceRgb(candidate,reference) {
    if (!candidate || !reference || candidate.width !== reference.width || candidate.height !== reference.height ||
        !Array.isArray(candidate.rgba) || !Array.isArray(reference.rgba))
        throw new Error('DENOISER_METRIC_SHAPE_INVALID: matching width/height and RGBA arrays required');
    const components = candidate.width*candidate.height*4;
    if (candidate.rgba.length !== components || reference.rgba.length !== components)
        throw new Error('DENOISER_METRIC_SHAPE_INVALID: RGBA array length mismatch');
    let squaredError = 0;
    let absoluteError = 0;
    let referenceSquared = 0;
    let peak = 0;
    let aboveOne = 0;
    const channelSquared = [0,0,0];
    const pixels = candidate.width*candidate.height;
    for (let pixel=0; pixel<pixels; pixel++) {
        for (let channel=0; channel<3; channel++) {
            const index=pixel*4+channel;
            const actual=candidate.rgba[index];
            const expected=reference.rgba[index];
            if (!Number.isFinite(actual) || !Number.isFinite(expected))
                throw new Error('DENOISER_METRIC_NONFINITE: radiance inputs must be finite');
            if (actual > 1) aboveOne++;
            if (expected > 1) aboveOne++;
            const difference=actual-expected;
            squaredError+=difference*difference;
            absoluteError+=Math.abs(difference);
            referenceSquared+=expected*expected;
            channelSquared[channel]+=difference*difference;
            peak=Math.max(peak,Math.abs(expected));
        }
    }
    const count=pixels*3;
    const rmse=Math.sqrt(squaredError/count);
    return Object.freeze({ width:candidate.width,height:candidate.height,colorSpace:'linear-radiance',channels:3,
        rmse,mae:absoluteError/count,relativeRmse:Math.sqrt(squaredError/Math.max(referenceSquared,1.0e-30)),
        psnr:rmse===0?Infinity:20*Math.log10(Math.max(peak,1.0e-30)/rmse),
        perChannelRmse:channelSquared.map((sum)=>Math.sqrt(sum/pixels)),aboveOneComponents:aboveOne });
}