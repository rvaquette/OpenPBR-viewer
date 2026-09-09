// Standalone (no browser) repro for the "Rasterizer legacy" freeze reported after
// wiring the local BVH (src/bvh/*) into the legacy raster route. Loads the same
// GLB assets as main.js's MeshLoader + buildCombinedSurfaceGeometry(), then builds
// the local Bvh with progress instrumentation to find where it stalls.
//
// Usage:
//   node tools/repro-bvh-hang.mjs [scene_name]
//   node tools/repro-bvh-hang.mjs standard-shader-ball

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

// GLTFLoader's TextureLoader fallback path (no createImageBitmap in Node) uses
// `new Image()` and waits for `onload`. Stub it so texture decoding can't hang
// parse() forever -- we only care about geometry here.
class FakeImage {
    set src(_value) { queueMicrotask(() => this.onload && this.onload()); }
}
globalThis.Image = FakeImage;

const { GLTFLoader } = await import('three/examples/jsm/loaders/GLTFLoader.js');
const { mergeGeometries } = await import('three/examples/jsm/utils/BufferGeometryUtils.js');
const { Mesh, MeshStandardMaterial, BufferGeometry, Float32BufferAttribute } = await import('three');
const { Bvh } = await import('../src/bvh/bvh.js');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.join(__dirname, '..');

function loadGlb(relativePath) {
    const bytes = readFileSync(path.join(repoRoot, 'public', relativePath));
    const arrayBuffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
    const loader = new GLTFLoader();
    return new Promise((resolve, reject) => loader.parse(arrayBuffer, '', resolve, reject));
}

function meshesOf(gltf) {
    const meshes = [];
    const roots = Array.isArray(gltf.scene) ? gltf.scene : [gltf.scene];
    for (const root of roots) root.traverseVisible(o => { if (o.isMesh) meshes.push(o); });
    return meshes;
}

async function loadMergedMesh(scenePath) {
    const gltf = await loadGlb(scenePath);
    const meshes = meshesOf(gltf);
    if (meshes.length === 0) return null;
    const merged = mergeGeometries(meshes.map(m => m.geometry.clone()), false);
    if (!merged) throw new Error(`Unable to merge geometries for ${scenePath}`);
    merged.clearGroups();
    return new Mesh(merged, new MeshStandardMaterial());
}

// Mirrors main.js's buildCombinedSurfaceGeometry(): merges neutral (props) +
// openpbr (surface) geometry into one non-indexed geometry tagged with neutralFlag.
function buildCombinedSurfaceGeometry(neutralGeom, surfaceGeom) {
    const toNI = g => (g && g.index) ? g.toNonIndexed() : g;
    const A = neutralGeom ? toNI(neutralGeom) : null;
    const B = toNI(surfaceGeom);
    const countA = A ? A.attributes.position.count : 0;
    const countB = B.attributes.position.count;
    const N = countA + countB;
    const pos = new Float32Array(N * 3);
    const copy = (G, base) => {
        if (!G) return;
        const p = G.attributes.position;
        for (let i = 0; i < p.count; i++) {
            const j = base + i;
            pos[j * 3 + 0] = p.getX(i); pos[j * 3 + 1] = p.getY(i); pos[j * 3 + 2] = p.getZ(i);
        }
    };
    copy(A, 0);
    copy(B, countA);
    const g = new BufferGeometry();
    g.setAttribute('position', new Float32BufferAttribute(pos, 3));
    return g;
}

// Instrument Bvh.build to detect true infinite recursion (depth blow-up) vs. slow
// convergence, without touching src/bvh/bvh.js.
function instrumentBvh() {
    const originalBuild = Bvh.prototype.build;
    let calls = 0;
    let maxDepth = 0;
    Bvh.prototype.build = function (indices, start, end) {
        // Depth is tracked on the instance (not via a parameter) because
        // build()'s own recursive `this.build(...)` calls don't pass a depth arg.
        this.__reproDepth = (this.__reproDepth || 0) + 1;
        calls++;
        if (this.__reproDepth > maxDepth) maxDepth = this.__reproDepth;
        if (this.__reproDepth > 200) {
            throw new Error(`Bvh.build recursion depth exceeded 200 (count=${end - start}) -- likely infinite recursion (no shrinking split).`);
        }
        if (calls % 100000 === 0) {
            console.log(`  ...build() call #${calls}, depth=${this.__reproDepth}, count=${end - start}`);
        }
        try {
            return originalBuild.call(this, indices, start, end);
        } finally {
            this.__reproDepth--;
        }
    };
    return () => ({ calls, maxDepth });
}

async function main() {
    const sceneName = process.argv[2] || 'standard-shader-ball';
    console.log(`Scene: ${sceneName}`);

    console.log('Loading neutral_objects.glb ...');
    const neutralMesh = await loadMergedMesh(`${sceneName}/neutral_objects.glb`);
    console.log(`  neutral vertices: ${neutralMesh ? neutralMesh.geometry.attributes.position.count : 0}`);

    console.log('Loading openpbr_objects.glb ...');
    const surfaceMesh = await loadMergedMesh(`${sceneName}/openpbr_objects.glb`);
    console.log(`  openpbr vertices: ${surfaceMesh.geometry.attributes.position.count}`);

    const stats = instrumentBvh();

    console.log('Building props BVH (neutral only, as MeshLoader.load() does per object)...');
    let t0 = Date.now();
    if (neutralMesh) new Bvh(neutralMesh.geometry);
    console.log(`  props BVH OK in ${Date.now() - t0} ms`, stats());

    console.log('Building surface BVH (openpbr only, as MeshLoader.load() does per object)...');
    t0 = Date.now();
    new Bvh(surfaceMesh.geometry);
    console.log(`  surface BVH OK in ${Date.now() - t0} ms`, stats());

    console.log('Building combined BVH (neutral+openpbr merged, as the fullscreen BVH route does)...');
    const combinedGeom = buildCombinedSurfaceGeometry(neutralMesh ? neutralMesh.geometry : null, surfaceMesh.geometry);
    console.log(`  combined vertices: ${combinedGeom.attributes.position.count}`);
    t0 = Date.now();
    const watchdog = setInterval(() => console.log(`  ...still building, elapsed ${Date.now() - t0} ms`), 2000);
    const combinedBvh = new Bvh(combinedGeom);
    clearInterval(watchdog);
    console.log(`  combined BVH OK in ${Date.now() - t0} ms, nodes=${combinedBvh.nodes.length}`, stats());
}

main().catch(err => { console.error('FAILED:', err); process.exit(1); });
