// Native replacement for THREE.TextureLoader (feature 004, Phase 3): returns a
// THREE.Texture synchronously (matching TextureLoader's contract, so existing
// call sites that set .wrapS/.flipY/.colorSpace right after `load()` keep
// working), and fills in the image asynchronously via fetch+createImageBitmap
// instead of an <img> element.
import { Texture } from 'three';

export function loadNativeTexture(url, onError) {
    const texture = new Texture();
    fetch(url)
        .then(response => {
            if (!response.ok) throw new Error(`Texture fetch failed: ${response.status} ${url}`);
            return response.blob();
        })
        // three.js still applies UNPACK_FLIP_Y_WEBGL per texture.flipY at upload time
        // for ImageBitmap sources (WebGLTextures.js), same as it did for the <img>-based
        // TextureLoader -- so no extra flip is needed here.
        .then(blob => createImageBitmap(blob))
        .then(bitmap => {
            texture.image = bitmap;
            texture.needsUpdate = true;
        })
        .catch(err => {
            if (onError) onError(err);
            else console.error(`[texture] failed to load ${url}:`, err);
        });
    return texture;
}
