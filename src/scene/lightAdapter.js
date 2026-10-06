export const SCENE_LIGHT_TYPE = Object.freeze({ quad:0, sphere:1, distant:2 });
export const LOCAL_MTLX_LIGHT_TYPE = Object.freeze({ point:0, directional:1, spot:2, quad:3, sphere:4 });
export const LIGHT_SAMPLING_MODE = Object.freeze({ mis:0, nee:1, bsdf:2 });
export const LIGHT_TEXELS_PER_LIGHT = 6;
const EPSILON = 1.0e-12;

function fail(code,detail) {
    const error = new Error(`${code}: ${detail}`);
    error.code = code;
    throw error;
}

function vec3(value,name) {
    if (!Array.isArray(value) || value.length !== 3 || value.some((component) => !Number.isFinite(component)))
        fail('SCENE_LIGHT_VECTOR_INVALID',`${name} must contain three finite components`);
    return [...value];
}

function add(a,b) { return a.map((value,index) => value+b[index]); }
function subtract(a,b) { return a.map((value,index) => value-b[index]); }
function cross(a,b) { return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]; }
function dot(a,b) { return a.reduce((sum,value,index) => sum+value*b[index],0); }
function normalize(value,name) {
    const length = Math.hypot(...value);
    if (!Number.isFinite(length) || length <= EPSILON) fail('SCENE_LIGHT_DIRECTION_INVALID',`${name} must be nonzero`);
    return value.map((component) => component === 0 ? 0 : component/length);
}

function requireEmission(value,name) {
    const emission = vec3(value,name);
    if (emission.some((component) => component < 0)) fail('SCENE_LIGHT_EMISSION_INVALID',`${name} must be nonnegative linear RGB`);
    return emission;
}

export function adaptSceneLights(scene) {
    if (!Array.isArray(scene?.blocks)) fail('SCENE_LIGHT_SCENE_INVALID','parsed scene blocks are required');
    const blocks = scene.blocks.filter((block) => block.type === 'light');
    return blocks.map((block,index) => {
        const values = block.values || {};
        const sceneType = String(values.type || '').toLowerCase();
        if (!Object.hasOwn(SCENE_LIGHT_TYPE,sceneType))
            fail('SCENE_LIGHT_TYPE_INVALID',`unsupported .scene light type '${sceneType}'`);
        const position = vec3(values.position,`${block.name || index}.position`);
        const emission = requireEmission(values.emission,`${block.name || index}.emission`);
        const light = { name:block.name || `scene-light-${index}`,sceneType,
            sceneTypeId:SCENE_LIGHT_TYPE[sceneType],color:emission,emission:[...emission],intensity:1,
            decayRate:0,innerCone:1,outerCone:1,position,direction:[0,0,0],u:[0,0,0],v:[0,0,0],radius:0 };

        if (sceneType === 'quad') {
            const point1 = vec3(values.v1,`${light.name}.v1`);
            const point2 = vec3(values.v2,`${light.name}.v2`);
            light.u = subtract(point1,position);
            light.v = subtract(point2,position);
            const area = Math.hypot(...cross(light.u,light.v));
            const edgeProduct = Math.hypot(...light.u)*Math.hypot(...light.v);
            if (!(area > EPSILON)) fail('SCENE_LIGHT_AREA_INVALID',`${light.name} quad edges must be nonzero`);
            if (Math.abs(dot(light.u,light.v)) > 1.0e-6*edgeProduct)
                fail('SCENE_LIGHT_QUAD_NON_ORTHOGONAL',`${light.name} quad edges must be orthogonal`);
            light.area = area;
            light.type = LOCAL_MTLX_LIGHT_TYPE.quad;
        } else if (sceneType === 'sphere') {
            if (!Number.isFinite(values.radius) || values.radius <= 0)
                fail('SCENE_LIGHT_RADIUS_INVALID',`${light.name} sphere radius must be positive`);
            light.radius = values.radius;
            light.area = 4*Math.PI*values.radius*values.radius;
            light.type = LOCAL_MTLX_LIGHT_TYPE.sphere;
        } else {
            light.sourceDirection = normalize(position,`${light.name}.position`);
            // GetMtlxLight's directional sampler negates its stored direction.
            light.direction = light.sourceDirection.map((component) => component === 0 ? 0 : -component);
            light.type = LOCAL_MTLX_LIGHT_TYPE.directional;
        }
        return Object.freeze({ ...light,position:Object.freeze(light.position),direction:Object.freeze(light.direction),
            sourceDirection:light.sourceDirection ? Object.freeze(light.sourceDirection) : null,
            color:Object.freeze(light.color),emission:Object.freeze(light.emission),u:Object.freeze(light.u),v:Object.freeze(light.v) });
    });
}

export function packLocalLightTexels(lights) {
    if (!Array.isArray(lights)) fail('SCENE_LIGHT_LIST_INVALID','light array required');
    const height = Math.max(1,lights.length);
    const data = new Float32Array(LIGHT_TEXELS_PER_LIGHT*height*4);
    lights.forEach((light,index) => {
        const position = vec3(light.position,`light ${index}.position`);
        const direction = vec3(light.direction ?? [0,-1,0],`light ${index}.direction`);
        const color = vec3(light.color,`light ${index}.color`);
        const u = vec3(light.u ?? [0,0,0],`light ${index}.u`);
        const v = vec3(light.v ?? [0,0,0],`light ${index}.v`);
        const decayRate = light.decayRate ?? 0;
        const intensity = light.intensity ?? 1;
        const innerCone = light.innerCone ?? 1;
        const outerCone = light.outerCone ?? 1;
        const radius = light.radius ?? 0;
        if (!Number.isInteger(light.type) || light.type < 0 || light.type > LOCAL_MTLX_LIGHT_TYPE.sphere ||
            ![decayRate,intensity,innerCone,outerCone,radius].every(Number.isFinite) || radius < 0)
            fail('SCENE_LIGHT_RECORD_INVALID',`light record ${index} contains missing or nonfinite values`);
        const base = LIGHT_TEXELS_PER_LIGHT*4*index;
        data.set([...position,decayRate],base);
        data.set([...direction,light.type],base+4);
        data.set([...color,intensity],base+8);
        data.set([innerCone,outerCone,0,0],base+12);
        data.set([...u,0],base+16);
        data.set([...v,radius],base+20);
    });
    return Object.freeze({ data,width:LIGHT_TEXELS_PER_LIGHT,height,count:lights.length });
}

export function quadSolidAnglePdf(area,distanceSquared,cosLight) {
    if (![area,distanceSquared,cosLight].every(Number.isFinite) || area <= 0 || distanceSquared <= 0 || cosLight <= 0)
        return 0;
    return distanceSquared/(area*cosLight);
}

export function sphereSolidAnglePdf(radius,centerDistance) {
    if (![radius,centerDistance].every(Number.isFinite) || radius <= 0) return 0;
    if (centerDistance <= radius) return 1/(4*Math.PI);
    const cosThetaMax = Math.sqrt(Math.max(0,1-radius*radius/(centerDistance*centerDistance)));
    const solidAngle = 2*Math.PI*(1-cosThetaMax);
    return solidAngle > EPSILON ? 1/solidAngle : 0;
}

export function intersectSceneLight(lights,rayOrigin,rayDirection,maxDistance = Infinity) {
    if (!Array.isArray(lights) || !Number.isFinite(maxDistance) && maxDistance !== Infinity || maxDistance <= 0)
        fail('SCENE_LIGHT_RAY_INVALID','lights and a positive max distance are required');
    const origin = vec3(rayOrigin,'ray origin');
    const direction = normalize(vec3(rayDirection,'ray direction'),'ray direction');
    let closest = maxDistance;
    let hit = null;
    lights.forEach((light,index) => {
        let distance = Infinity;
        let normal = null;
        if (light.type === LOCAL_MTLX_LIGHT_TYPE.quad) {
            const edgeNormal = cross(light.u,light.v);
            const area = Math.hypot(...edgeNormal);
            if (area <= EPSILON) return;
            normal = edgeNormal.map((value) => value/area);
            if (dot(normal,direction.map((value) => -value)) <= EPSILON) return;
            const denominator = dot(normal,direction);
            distance = dot(normal,subtract(light.position,origin))/denominator;
            if (!(distance > 0 && distance < closest)) return;
            const relative = subtract(add(origin,direction.map((value) => value*distance)),light.position);
            const u = dot(relative,light.u)/dot(light.u,light.u);
            const v = dot(relative,light.v)/dot(light.v,light.v);
            if (u < 0 || u > 1 || v < 0 || v > 1) return;
        } else if (light.type === LOCAL_MTLX_LIGHT_TYPE.sphere) {
            const offset = subtract(origin,light.position);
            const halfB = dot(offset,direction);
            const discriminant = halfB*halfB-dot(offset,offset)+light.radius*light.radius;
            if (light.radius <= 0 || discriminant < 0) return;
            const root = Math.sqrt(discriminant);
            distance = -halfB-root;
            if (distance <= 0) distance = -halfB+root;
            if (!(distance > 0 && distance < closest)) return;
            normal = normalize(subtract(add(origin,direction.map((value) => value*distance)),light.position),'sphere hit normal');
        } else return;
        closest = distance;
        hit = Object.freeze({ lightIndex:index,distance,normal:Object.freeze(normal),emission:light.color });
    });
    return hit;
}