import type { Mesh, MeshInstance } from "../core/mesh.js";
import { Vec3 } from "../math/vec3.js";
import { BBox } from "./bbox.js";
import { Bvh, Node, NodeType } from "./bvh.js";

export interface NodeBvh
{
    bboxmin: Vec3;
    bboxmax: Vec3;
    LRLeaf: Vec3;
};

export class BvhTranslator {
    private meshes: Mesh[] = [];
    private meshInstances: MeshInstance[] = [];
    private bvhRootStartIndices: number[] = [];
    private topLevelBvh: Bvh | null = null;
    private curNode: number = 0;
    private curTriIndex: number = 0;
    private nodeTexWidth: number;
    public nodes: NodeBvh[] = [];
    public topLevelIndex: number = 0;

    private processBLASNodes(node: Node): number {
        const bbox = node.bounds;

        this.nodes[this.curNode] = {
            bboxmin: bbox.pmin,
            bboxmax: bbox.pmax,
            LRLeaf: new Vec3(0, 0, 0)
        };

        const index = this.curNode;

        if (node.type === NodeType.kLeaf) {
            this.nodes[this.curNode].LRLeaf.x = this.curTriIndex + node.startidx;
            this.nodes[this.curNode].LRLeaf.y = node.numprims;
            this.nodes[this.curNode].LRLeaf.z = 1;
        } else {
            this.curNode++;
            this.nodes[index].LRLeaf.x = this.processBLASNodes(node.lc!);
            this.curNode++;
            this.nodes[index].LRLeaf.y = this.processBLASNodes(node.rc!);
        }
        return index;
    }

    private processTLASNodes(node: Node): number {
        const bbox = node.bounds;

        this.nodes[this.curNode] = {
            bboxmin: bbox.pmin,
            bboxmax: bbox.pmax,
            LRLeaf: new Vec3(0, 0, 0)
        };

        const index = this.curNode;

        if (node.type === NodeType.kLeaf) {
            if (!this.topLevelBvh) throw new Error("topLevelBvh is null");
            const instanceIndex = this.topLevelBvh.m_packed_indices[node.startidx];
            const meshIndex = this.meshInstances[instanceIndex].meshID;
            const materialID = this.meshInstances[instanceIndex].materialID;

            this.nodes[this.curNode].LRLeaf.x = this.bvhRootStartIndices[meshIndex];
            this.nodes[this.curNode].LRLeaf.y = materialID;
            this.nodes[this.curNode].LRLeaf.z = -instanceIndex - 1;
        } else {
            this.curNode++;
            this.nodes[index].LRLeaf.x = this.processTLASNodes(node.lc!);
            this.curNode++;
            this.nodes[index].LRLeaf.y = this.processTLASNodes(node.rc!);
        }
        return index;
    }

    private processBLAS() {
        let nodeCnt = 0;

        for (let i = 0; i < this.meshes.length; i++)
            nodeCnt += this.meshes[i].bvh.m_nodecnt;
        this.topLevelIndex = nodeCnt;

        // reserve space for top level nodes
        nodeCnt += 2 * this.meshInstances.length;
        this.nodes = new Array(nodeCnt);
        for (let i = 0; i < nodeCnt; ++i) {
            this.nodes[i] = {
                bboxmin: new Vec3(0, 0, 0),
                bboxmax: new Vec3(0, 0, 0),
                LRLeaf: new Vec3(0, 0, 0)
            };
        }

        let bvhRootIndex = 0;
        this.curTriIndex = 0;

        for (let i = 0; i < this.meshes.length; i++) {
            const mesh = this.meshes[i];
            this.curNode = bvhRootIndex;

            this.bvhRootStartIndices.push(bvhRootIndex);
            bvhRootIndex += mesh.bvh.m_nodecnt;

            this.processBLASNodes(mesh.bvh.m_nodes[0]);
            this.curTriIndex += mesh.bvh.getNumIndices();
        }
    }

    private processTLAS() {
        this.curNode = this.topLevelIndex;
        if (!this.topLevelBvh) throw new Error("topLevelBvh is null");
        this.processTLASNodes(this.topLevelBvh.m_nodes[0]);
    }

    public updateTLAS(topLevelBvh: Bvh, sceneInstances: MeshInstance[]) {
        this.topLevelBvh = topLevelBvh;
        this.meshInstances = sceneInstances;
        this.curNode = this.topLevelIndex;
        this.processTLASNodes(topLevelBvh.m_nodes[0]);
    }

    public process(topLevelBvh: Bvh, sceneMeshes: Mesh[], sceneInstances: MeshInstance[]) {
        this.topLevelBvh = topLevelBvh;
        this.meshes = sceneMeshes;
        this.meshInstances = sceneInstances;
        this.processBLAS();
        this.processTLAS();
    }
}