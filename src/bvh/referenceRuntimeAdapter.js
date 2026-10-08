import { adaptReferenceGeometry } from './referenceSceneAdapter.js';
import { buildReferenceBlas } from './referenceBlas.js';
import { buildReferenceScene } from './referenceScene.js';

export function buildReferenceSurfaceScene(geometry, { materialKey, variants = [] } = {}) {
    const expanded = geometry.index ? geometry.toNonIndexed() : geometry.clone();
    try {
        expanded.clearGroups();
        const count = expanded.attributes.position.count;
        const neutral = expanded.attributes.neutralFlag;
        const variant = expanded.attributes.materialVariant;
        const records = [];
        const ids = new Map();
        let groupStart = 0;
        let previousId = -1;
        for (let offset = 0; offset < count; offset += 3) {
            const kind = neutral?.getX(offset) > 0.5 ? 'props' : 'openpbr';
            const parameterVariant = kind === 'props' ? 0 : variant?.getX(offset) || 0;
            const key = `${kind}:${parameterVariant}`;
            if (!ids.has(key)) {
                const values = variants.find((entry) => entry.variant === parameterVariant)?.values || [];
                ids.set(key,records.length);
                records.push({ sceneMaterialID:records.length, kind, localMaterialID:kind === 'props' ? 0 : 1,
                    materialKey, parameterVariant, parameterValues:values });
            }
            const id = ids.get(key);
            for (let corner = 1; corner < 3; corner++) {
                if ((neutral?.getX(offset + corner) > 0.5) !== (kind === 'props') ||
                    (kind !== 'props' && (variant?.getX(offset + corner) || 0) !== parameterVariant))
                    throw new Error('REFERENCE_TRIANGLE_MATERIAL_INVALID: a triangle must have one material variant');
            }
            if (id !== previousId) {
                if (previousId >= 0) expanded.addGroup(groupStart,offset - groupStart,previousId);
                groupStart = offset;
                previousId = id;
            }
        }
        if (previousId >= 0) expanded.addGroup(groupStart,count - groupStart,previousId);
        const primitives = adaptReferenceGeometry(expanded,{materialIDs:records.map((entry) => entry.sceneMaterialID)}).primitives;
        const meshes = primitives.map(buildReferenceBlas).filter((mesh) => mesh.blasStatus === 'built');
        const scene = buildReferenceScene(meshes,meshes.map((mesh,meshID) => ({meshID,materialID:mesh.materialID})));
        return { scene,records };
    } finally { expanded.dispose(); }
}