import { BufferGeometry, Float32BufferAttribute } from 'three';
import { mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';

const MAX_DISPLACEMENT_TRIANGLES = 350000;
const MAX_DISPLACEMENT_SUBDIVISIONS = 3;

function addressIndex(index, size, mode)
{
    if (mode === 'clamp') return Math.max(0, Math.min(size - 1, index));
    if (mode === 'mirror') {
        const period = size * 2;
        const wrapped = ((index % period) + period) % period;
        return wrapped < size ? wrapped : period - wrapped - 1;
    }
    if (mode === 'constant') return index < 0 || index >= size ? -1 : index;
    return ((index % size) + size) % size;
}

function readHeight(displacement, x, y)
{
    const width = displacement.width;
    const height = displacement.height;
    const ix = addressIndex(x, width, displacement.uaddressmode);
    const iy = addressIndex(y, height, displacement.vaddressmode);
    if (ix < 0 || iy < 0) return 0;
    return displacement.pixels[(iy * width + ix) * 4] / 255;
}

function sampleHeight(displacement, u, v)
{
    u = u * displacement.uvtiling[0] + displacement.uvoffset[0];
    v = v * displacement.uvtiling[1] + displacement.uvoffset[1];
    const x = u * displacement.width - 0.5;
    const y = v * displacement.height - 0.5;
    if (displacement.filtertype === 'closest')
        return readHeight(displacement, Math.floor(x + 0.5), Math.floor(y + 0.5));

    const x0 = Math.floor(x);
    const y0 = Math.floor(y);
    const tx = x - x0;
    const ty = y - y0;
    const a = readHeight(displacement, x0, y0);
    const b = readHeight(displacement, x0 + 1, y0);
    const c = readHeight(displacement, x0, y0 + 1);
    const d = readHeight(displacement, x0 + 1, y0 + 1);
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty;
}

function subdivideOnce(geometry)
{
    const oldIndex = geometry.index.array;
    const attributes = Object.fromEntries(
        ['position', 'normal', 'uv', 'tangent']
            .filter(name => geometry.attributes[name])
            .map(name => [name, geometry.attributes[name]])
    );
    const vertexCount = attributes.position.count;
    const nextArrays = {};
    for (const [name, attribute] of Object.entries(attributes)) {
        const itemSize = attribute.itemSize;
        const values = new Float32Array((vertexCount + oldIndex.length) * itemSize);
        for (let vertex = 0; vertex < vertexCount; vertex++) {
            for (let component = 0; component < itemSize; component++)
                values[vertex * itemSize + component] = attribute.array[vertex * itemSize + component];
        }
        nextArrays[name] = { values, itemSize, normalized: attribute.normalized };
    }

    let nextVertex = vertexCount;
    const edgeVertices = new Map();
    const midpoint = (first, second) => {
        const low = Math.min(first, second);
        const high = Math.max(first, second);
        const key = `${low}:${high}`;
        if (edgeVertices.has(key)) return edgeVertices.get(key);

        const index = nextVertex++;
        for (const { values, itemSize } of Object.values(nextArrays)) {
            for (let component = 0; component < itemSize; component++) {
                const a = values[first * itemSize + component];
                const b = values[second * itemSize + component];
                values[index * itemSize + component] = (a + b) * 0.5;
            }
        }
        edgeVertices.set(key, index);
        return index;
    };

    const indices = [];
    for (let i = 0; i < oldIndex.length; i += 3) {
        const a = oldIndex[i];
        const b = oldIndex[i + 1];
        const c = oldIndex[i + 2];
        const ab = midpoint(a, b);
        const bc = midpoint(b, c);
        const ca = midpoint(c, a);
        indices.push(a, ab, ca, ab, b, bc, ca, bc, c, ab, bc, ca);
    }

    const result = new BufferGeometry();
    for (const [name, { values, itemSize, normalized }] of Object.entries(nextArrays)) {
        result.setAttribute(name, new Float32BufferAttribute(values.slice(0, nextVertex * itemSize), itemSize, normalized));
    }
    result.setIndex(indices);
    return result;
}

function subdivideForDisplacement(geometry)
{
    let result = mergeVertices(geometry.clone(), 1.0e-6);
    result.clearGroups();
    if (!result.index) result = mergeVertices(result, 1.0e-6);
    if (!result.attributes.normal) result.computeVertexNormals();

    let triangles = result.index.count / 3;
    for (let level = 0; level < MAX_DISPLACEMENT_SUBDIVISIONS && triangles * 4 <= MAX_DISPLACEMENT_TRIANGLES; level++) {
        result = subdivideOnce(result);
        triangles *= 4;
    }
    return result;
}

export function applyMtlxDisplacement(sourceGeometry, displacement)
{
    if (!displacement) return sourceGeometry;

    let geometry = displacement.pixels ? subdivideForDisplacement(sourceGeometry) : mergeVertices(sourceGeometry.clone(), 1.0e-6);
    const positions = geometry.attributes.position;
    const normals = geometry.attributes.normal;
    const uvs = geometry.attributes.uv;
    if (!normals) geometry.computeVertexNormals();
    if (displacement.pixels && !uvs)
        throw new Error('[mtlx-displacement] the displaced mesh has no UV attribute');

    const position = geometry.attributes.position;
    const normal = geometry.attributes.normal;
    const uv = geometry.attributes.uv;
    for (let i = 0; i < position.count; i++) {
        const height = displacement.pixels ? sampleHeight(displacement, uv.getX(i), uv.getY(i)) : displacement.value;
        const distance = height * displacement.scale;
        position.setXYZ(
            i,
            position.getX(i) + normal.getX(i) * distance,
            position.getY(i) + normal.getY(i) * distance,
            position.getZ(i) + normal.getZ(i) * distance
        );
    }

    position.needsUpdate = true;
    geometry.computeVertexNormals();
    if (geometry.attributes.tangent && geometry.attributes.uv)
        geometry.computeTangents();
    geometry.computeBoundingBox();
    geometry.computeBoundingSphere();
    return geometry;
}