export function validateLinearRgba(data,width,height) {
    if (!(data instanceof Float32Array)) throw new TypeError('DENOISER_INPUT_TYPE_INVALID: expected Float32Array');
    if (!Number.isInteger(width) || width <= 0 || !Number.isInteger(height) || height <= 0 || data.length !== width*height*4)
        throw new Error('DENOISER_INPUT_SHAPE_INVALID: expected width*height*4 float values');
    let nonFinite = 0;
    let aboveOne = 0;
    for (const value of data) {
        if (!Number.isFinite(value)) nonFinite++;
        if (value > 1) aboveOne++;
    }
    if (nonFinite) throw new Error(`DENOISER_INPUT_NONFINITE: ${nonFinite} nonfinite component(s)`);
    return Object.freeze({ width,height,components:data.length,aboveOne });
}

export class ReferenceDenoiserAdapter {
    constructor({ weightsBaseUrl,origin = globalThis.location?.origin,backend = 'webgl',quality = 'fast',createDenoiser = null } = {}) {
        if (typeof weightsBaseUrl !== 'string' || !/^https?:\/\//i.test(weightsBaseUrl))
            throw new Error('DENOISER_WEIGHTS_URL_INVALID: explicit same-origin HTTP(S) base required');
        if (origin && new URL(weightsBaseUrl).origin !== origin)
            throw new Error('DENOISER_WEIGHTS_ORIGIN_INVALID: weights must use the viewer origin');
        this.weightsBaseUrl = weightsBaseUrl.replace(/\/$/,'');
        this.backendName = backend;
        this.qualityValue = quality;
        this.createDenoiser = createDenoiser;
        this.denoiser = null;
        this.width = 0;
        this.height = 0;
        this.revision = 0;
        this.runToken = 0;
        this.busy = false;
    }

    async initialize(width,height,fromExecution = false) {
        if (!Number.isInteger(width) || width <= 0 || !Number.isInteger(height) || height <= 0)
            throw new Error('DENOISER_DIMENSIONS_INVALID: positive integer dimensions required');
        if (this.denoiser && this.width === width && this.height === height) return this.denoiser;
        if (this.busy && !fromExecution) throw new Error('DENOISER_BUSY: cannot rebuild while execution is active');
        if (this.denoiser) await this.dispose(false);
        const denoiser = this.createDenoiser
            ? await this.createDenoiser(this.backendName)
            : new (await import('./reference/denoiser.mjs')).Denoiser(this.backendName,
                this.backendName === 'webgl' ? document.createElement('canvas') : undefined);
        denoiser.weightsUrl = this.weightsBaseUrl;
        denoiser.filterType = 'rt';
        denoiser.quality = this.qualityValue;
        denoiser.hdr = true;
        denoiser.srgb = false;
        denoiser.width = width;
        denoiser.height = height;
        denoiser.flipOutputY = true;
        denoiser.outputMode = 'float32';
        if (denoiser.backendInitialization) {
            try { await denoiser.backendInitialization; }
            catch (error) {
                throw new Error(`DENOISER_BACKEND_UNAVAILABLE: ${error?.message || String(error)}`,{cause:error});
            }
        }
        this.denoiser = denoiser;
        this.width = width;
        this.height = height;
        if (!denoiser.backendReady) {
            await new Promise((resolve,reject) => {
                let unsubscribe = () => {};
                const timeout = setTimeout(() => {
                    unsubscribe();
                    reject(new Error('DENOISER_BACKEND_TIMEOUT'));
                },120000);
                unsubscribe = denoiser.onBackendReady(() => {
                    clearTimeout(timeout);
                    unsubscribe();
                    resolve();
                });
            });
        }
        return denoiser;
    }

    async execute(rgba,width,height,{ revision = this.revision,isCurrent = () => true,signal } = {}) {
        const input = validateLinearRgba(rgba,width,height);
        if (this.busy) throw new Error('DENOISER_BUSY: concurrent executions are not allowed');
        if (signal?.aborted) throw new Error('DENOISER_ABORTED: request was already aborted');
        this.busy = true;
        const runToken = ++this.runToken;
        const snapshot = rgba.slice();
        let abortListener;
        try {
            const denoiser = await this.initialize(width,height,true);
            if (signal) {
                abortListener = () => denoiser.abort();
                signal.addEventListener('abort',abortListener,{ once:true });
            }
            denoiser.flipOutputY = true;
            denoiser.hdr = true;
            denoiser.srgb = false;
            await denoiser.setInputData('color',snapshot,{ flipY:true });
            const output = await denoiser.execute();
            if (signal?.aborted || runToken !== this.runToken || !isCurrent(revision))
                throw new Error('DENOISER_RESULT_STALE: scene or request revision changed');
            if (!(output instanceof Float32Array) || output.length !== input.components)
                throw new Error('DENOISER_OUTPUT_SHAPE_INVALID: expected RGBA Float32Array matching input');
            let nonFinite = 0;
            for (const value of output) if (!Number.isFinite(value)) nonFinite++;
            if (nonFinite) throw new Error(`DENOISER_OUTPUT_NONFINITE: ${nonFinite} nonfinite component(s)`);
            return Object.freeze({ data:output,width,height,channels:4,revision,aboveOneInput:input.aboveOne });
        } finally {
            if (signal && abortListener) signal.removeEventListener('abort',abortListener);
            this.busy = false;
        }
    }

    abort() {
        this.runToken++;
        this.denoiser?.abort();
    }

    async dispose(invalidate = true) {
        if (invalidate) this.abort();
        else this.denoiser?.abort();
        if (this.denoiser) {
            if (this.denoiser.timesGenerated > 0) this.denoiser.dispose();
            else this.denoiser.resetInputs();
        }
        this.denoiser = null;
        this.width = 0;
        this.height = 0;
    }
}