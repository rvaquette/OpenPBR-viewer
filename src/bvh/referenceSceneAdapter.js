import { BBox } from './reference/bvh/bbox.ts';
import { Vec3 } from './reference/math/vec3.ts';
import { Vec4 } from './reference/math/vec4.ts';

function requireGeometry(condition, code, detail) {
    if (!condition) throw new Error(`${code}: ${detail}`);
}

function readAttribute(attribute, vertexIndex, name) {
    const getters = ['getX', 'getY', 'getZ', 'getW'];
    const values = getters.slice(0, attribute.itemSize).map((getter) => attribute[getter](vertexIndex));
    requireGeometry(values.every((value) => Number.isFinite(value) && Number.isFinite(Math.fround(value))),
        'GEOMETRY_ATTRIBUTE_VALUE_INVALID', name);
    return values;
}

export function adaptReferenceGeometry(geometry, options = {}) {
    requireGeometry(geometry?.isBufferGeometry, 'GEOMETRY_TYPE_UNSUPPORTED', 'BufferGeometry required');
    const position = geometry.getAttribute('position');
    requireGeometry(position?.itemSize === 3, 'GEOMETRY_POSITION_INVALID', 'position must contain vec3 values');
    requireGeometry(Number.isSafeInteger(position.count) && position.count >= 0, 'GEOMETRY_VERTEX_COUNT_INVALID', 'position count');
    const index = geometry.getIndex();
    requireGeometry(!index || index.itemSize === 1, 'GEOMETRY_INDEX_INVALID', 'scalar indices required');
    const elementCount = index ? index.count : position.count;
    requireGeometry(Number.isSafeInteger(elementCount) && elementCount % 3 === 0, 'GEOMETRY_TRIANGLE_COUNT_INVALID', 'triangle-list elements');
    for (const [name, attribute] of Object.entries(geometry.attributes)) {
        requireGeometry(Number.isInteger(attribute.itemSize) && attribute.itemSize >= 1 && attribute.itemSize <= 4,
            'GEOMETRY_ATTRIBUTE_SIZE_UNSUPPORTED', name);
        requireGeometry(attribute.count === position.count, 'GEOMETRY_ATTRIBUTE_COUNT_INVALID', name);
    }
    const normal = geometry.getAttribute('normal');
    const uv = geometry.getAttribute('uv');
    const tangent = geometry.getAttribute('tangent');
    requireGeometry(!normal || normal.itemSize === 3, 'GEOMETRY_NORMAL_INVALID', 'normal must be vec3');
    requireGeometry(!uv || uv.itemSize === 2, 'GEOMETRY_UV_INVALID', 'uv must be vec2');
    requireGeometry(!tangent || [3, 4].includes(tangent.itemSize), 'GEOMETRY_TANGENT_INVALID', 'tangent must be vec3 or vec4');
    const flags = { hasNormals: Boolean(normal), hasUvs: Boolean(uv), hasTangents: Boolean(tangent) };
    const draw = geometry.drawRange;
    requireGeometry(Number.isSafeInteger(draw.start) && draw.start >= 0 && draw.start % 3 === 0,
        'GEOMETRY_DRAW_RANGE_INVALID', 'start must align to a triangle');
    requireGeometry(draw.count === Infinity || Number.isSafeInteger(draw.count) && draw.count >= 0 && draw.count % 3 === 0,
        'GEOMETRY_DRAW_RANGE_INVALID', 'count must align to a triangle');
    const start = Math.min(draw.start, elementCount);
    const end = Math.min(elementCount, start + draw.count);
    const groups = geometry.groups.length ? geometry.groups.map((group) => ({ ...group }))
        : [{ start: 0, count: elementCount, materialIndex: 0 }];
    let cursor = 0;
    for (const group of [...groups].sort((first, second) => first.start - second.start)) {
        requireGeometry(Number.isSafeInteger(group.start) && group.start >= 0 && group.start % 3 === 0 &&
            Number.isSafeInteger(group.count) && group.count >= 0 && group.count % 3 === 0 && group.start + group.count <= elementCount,
            'GEOMETRY_GROUP_RANGE_INVALID', 'group must cover complete triangles');
        requireGeometry(group.start === cursor, 'GEOMETRY_GROUP_PARTITION_INVALID', 'groups must not overlap or leave gaps');
        requireGeometry(Number.isSafeInteger(group.materialIndex) && group.materialIndex >= 0,
            'GEOMETRY_MATERIAL_INDEX_INVALID', 'group material index');
        cursor = group.start + group.count;
    }
    requireGeometry(cursor === elementCount, 'GEOMETRY_GROUP_PARTITION_INVALID', 'groups must cover all elements');
    const extras = Object.entries(geometry.attributes).filter(([name]) => !['position', 'normal', 'uv', 'tangent'].includes(name));
    const primitives = [];
    for (const [groupIndex, group] of groups.entries()) {
        const first = Math.max(start, group.start);
        const last = Math.min(end, group.start + group.count);
        if (last <= first) continue;
        const materialID = options.materialIDs ? options.materialIDs[group.materialIndex] : options.materialID ?? null;
        requireGeometry(materialID === null || Number.isSafeInteger(materialID) && materialID >= 0 && materialID <= 0xffffff,
            'GEOMETRY_MATERIAL_ID_INVALID', `material index ${group.materialIndex}`);
        const extraAttributes = Object.fromEntries(extras.map(([name, attribute]) => [name, { itemSize: attribute.itemSize,
            normalizedSource: attribute.normalized, values: [] }]));
        const primitive = { name: `${options.name || geometry.name || 'geometry'}:group-${groupIndex}`,
            groupIndex, materialIndex: group.materialIndex, materialID, flags: { ...flags },
            verticesUVX: [], normalsUVY: [], tangents: tangent ? [] : null,
            triangleBounds: [], sourceTriangleIDs: [], sourceVertexIndices: [], degenerateTriangleIDs: [], extraAttributes };
        for (let element = first; element < last; element += 3) {
            const vertexIndices = [0, 1, 2].map((corner) => index ? index.getX(element + corner) : element + corner);
            requireGeometry(vertexIndices.every((value) => Number.isSafeInteger(value) && value >= 0 && value < position.count),
                'GEOMETRY_INDEX_OUT_OF_BOUNDS', `triangle ${element / 3}`);
            const positions = vertexIndices.map((vertexIndex) => new Vec3(...readAttribute(position, vertexIndex, 'position')));
            const faceNormal = Vec3.cross(positions[1].subtract(positions[0]), positions[2].subtract(positions[0]));
            const length = Vec3.Length(faceNormal);
            const fallbackNormal = length > 0 ? faceNormal.scale(1 / length) : new Vec3(0, 0, 1);
            if (length === 0) primitive.degenerateTriangleIDs.push(element / 3);
            const bounds = new BBox();
            for (const [corner, vertexIndex] of vertexIndices.entries()) {
                const point = positions[corner];
                const texCoord = uv ? readAttribute(uv, vertexIndex, 'uv') : [[0, 0], [0, 1], [1, 1]][corner];
                const shadingNormal = normal ? readAttribute(normal, vertexIndex, 'normal') : fallbackNormal.toArray();
                primitive.verticesUVX.push(new Vec4(point.x, point.y, point.z, texCoord[0]));
                primitive.normalsUVY.push(new Vec4(...shadingNormal, texCoord[1]));
                if (tangent) {
                    const components = readAttribute(tangent, vertexIndex, 'tangent');
                    primitive.tangents.push(new Vec4(components[0], components[1], components[2], components[3] ?? 1));
                }
                for (const [name, attribute] of extras) extraAttributes[name].values.push(...readAttribute(attribute, vertexIndex, name));
                primitive.sourceVertexIndices.push(vertexIndex);
                bounds.grow(point);
            }
            primitive.triangleBounds.push(bounds);
            primitive.sourceTriangleIDs.push(element / 3);
        }
        primitive.triangleCount = primitive.triangleBounds.length;
        primitives.push(primitive);
    }
    return { version: 1, space: 'object', transformsApplied: false, primitives,
        sourceTriangleCount: elementCount / 3, triangleCount: primitives.reduce((count, primitive) => count + primitive.triangleCount, 0),
        empty: primitives.length === 0 };
}