const EPSILON = 1.0e-12;
const WORLD_UP = [0,1,0];

function fail(code, detail) {
    const error = new Error(`${code}: ${detail}`);
    error.code = code;
    throw error;
}

function finiteVector(value, name) {
    if (!Array.isArray(value) || value.length !== 3 || value.some((component) => !Number.isFinite(component)))
        fail('SCENE_CAMERA_VECTOR_INVALID', `${name} must contain three finite components`);
    return [...value];
}

function add(a,b) { return a.map((value,index) => value + b[index]); }
function subtract(a,b) { return a.map((value,index) => value - b[index]); }
function scale(vector,factor) { return vector.map((value) => value * factor); }
function dot(a,b) { return a.reduce((sum,value,index) => sum + value * b[index],0); }
function cross(a,b) { return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]; }
function normalize(vector,name) {
    const length = Math.hypot(...vector);
    if (!Number.isFinite(length) || length <= EPSILON) fail('SCENE_CAMERA_DIRECTION_INVALID', `${name} must be nonzero`);
    return scale(vector,1/length);
}

export function verticalFovFromHorizontal(fovHorizontal,aspect) {
    if (!Number.isFinite(fovHorizontal) || fovHorizontal <= 0 || fovHorizontal >= 180)
        fail('SCENE_CAMERA_FOV_INVALID','horizontal FOV must be in (0,180) degrees');
    if (!Number.isFinite(aspect) || aspect <= 0) fail('SCENE_CAMERA_ASPECT_INVALID','aspect must be positive');
    return 2 * Math.atan(Math.tan(fovHorizontal * Math.PI / 360) / aspect) * 180 / Math.PI;
}

function resolveInitialPose(cameraBlock,bounds) {
    const values = cameraBlock?.values || {};
    if (values.matrix) {
        const matrix = values.matrix;
        if (matrix.length !== 16 || matrix.some((value) => !Number.isFinite(value)))
            fail('SCENE_CAMERA_MATRIX_INVALID','camera matrix must have 16 finite row-major values');
        if (Math.abs(matrix[12]) > 1.0e-8 || Math.abs(matrix[13]) > 1.0e-8 ||
            Math.abs(matrix[14]) > 1.0e-8 || Math.abs(matrix[15] - 1) > 1.0e-8)
            fail('SCENE_CAMERA_MATRIX_NOT_AFFINE','camera matrix must be affine row-major');
        const position = [matrix[3],matrix[7],matrix[11]];
        const forward = normalize([matrix[2],matrix[6],matrix[10]],'camera matrix forward');
        return { position,target:add(position,forward),warnings:['CAMERA_ROLL_DROPPED'] };
    }
    if (values.position || values.lookat) {
        if (!values.position || !values.lookat)
            fail('SCENE_CAMERA_POSE_INCOMPLETE','position and lookat are both required without matrix');
        return { position:finiteVector(values.position,'position'),target:finiteVector(values.lookat,'lookat'),warnings:[] };
    }

    const min = bounds?.min ? finiteVector(bounds.min,'bounds.min') : [-1,-1,-1];
    const max = bounds?.max ? finiteVector(bounds.max,'bounds.max') : [1,1,1];
    const target = scale(add(min,max),0.5);
    const radius = Math.max(Math.hypot(...subtract(max,target)),EPSILON);
    const direction = normalize([1,0.65,1],'fallback direction');
    return { position:add(target,scale(direction,radius*4)),target,warnings:['SCENE_CAMERA_FRAMED_TO_BOUNDS'] };
}

export function createSceneCamera(cameraBlock,{ aspect = 1, overrides = {}, bounds = null } = {}) {
    const pose = resolveInitialPose(cameraBlock,bounds);
    const position = overrides.position === undefined ? pose.position : finiteVector(overrides.position,'override position');
    let target = overrides.lookat === undefined ? pose.target : finiteVector(overrides.lookat,'override lookat');
    const matrixForward = cameraBlock?.values?.matrix
        ? normalize([cameraBlock.values.matrix[2],cameraBlock.values.matrix[6],cameraBlock.values.matrix[10]],'camera matrix forward')
        : null;
    if (overrides.position !== undefined && overrides.lookat === undefined && matrixForward)
        target = add(position,matrixForward);
    if (Math.hypot(...subtract(target,position)) <= EPSILON)
        fail('SCENE_CAMERA_POSE_INVALID','position and lookat must differ');
    const forward = normalize(subtract(target,position),'camera position/lookat');

    let worldUp = WORLD_UP;
    if (Math.abs(dot(forward,worldUp)) > 1-1.0e-8) worldUp = [0,0,1];
    const right = normalize(cross(forward,worldUp),'camera right');
    const up = normalize(cross(right,forward),'camera up');
    const values = cameraBlock?.values || {};
    const fovHorizontal = overrides.fov ?? values.fov ?? 45;
    const aperture = overrides.aperture ?? values.aperture ?? 0;
    const focaldist = overrides.focaldist ?? values.focaldist ?? 1;
    if (!Number.isFinite(aperture) || aperture < 0) fail('SCENE_CAMERA_APERTURE_INVALID','aperture must be nonnegative');
    if (!Number.isFinite(focaldist) || focaldist <= 0) fail('SCENE_CAMERA_FOCALDIST_INVALID','focaldist must be positive');

    return Object.freeze({ position:Object.freeze(position),target:Object.freeze(target),forward:Object.freeze(forward),
        right:Object.freeze(right),up:Object.freeze(up),fovHorizontal,
        fovVertical:verticalFovFromHorizontal(fovHorizontal,aspect),aspect,aperture,focaldist,
        warnings:Object.freeze([...pose.warnings]),source:cameraBlock ? 'scene' : 'bounds' });
}

export function generatePrimaryRay(camera,pixelNdc,lensSample = [0.5,0.5]) {
    const screen = finiteVector([pixelNdc[0],pixelNdc[1],0],'pixel NDC').slice(0,2);
    if (!Array.isArray(lensSample) || lensSample.length !== 2 || lensSample.some((value) => !Number.isFinite(value) || value < 0 || value > 1))
        fail('SCENE_CAMERA_LENS_SAMPLE_INVALID','lens sample must be in [0,1]^2');
    const tanHorizontal = Math.tan(camera.fovHorizontal * Math.PI / 360);
    const tanVertical = Math.tan(camera.fovVertical * Math.PI / 360);
    const direction = normalize(add(camera.forward,add(scale(camera.right,screen[0]*tanHorizontal),
        scale(camera.up,screen[1]*tanVertical))),'primary ray direction');
    if (camera.aperture === 0) return { origin:[...camera.position],direction };
    const radius = Math.sqrt(lensSample[0] * camera.aperture);
    const angle = 2 * Math.PI * lensSample[1];
    const lensOffset = add(scale(camera.right,radius*Math.cos(angle)),scale(camera.up,radius*Math.sin(angle)));
    const origin = add(camera.position,lensOffset);
    const focalPoint = add(camera.position,scale(direction,camera.focaldist));
    return { origin,direction:normalize(subtract(focalPoint,origin),'depth-of-field ray direction'),focalPoint };
}

export function parseSceneCameraOverrides(searchParams) {
    const overrides = {};
    const parseVector = (key) => {
        const raw = searchParams.get(key);
        const values = raw?.split(',').map(Number);
        if (!values || values.length !== 3 || values.some((value) => !Number.isFinite(value)))
            fail('SCENE_CAMERA_OVERRIDE_INVALID',`${key} must be three comma-separated finite numbers`);
        return values;
    };
    for (const key of ['camera_position','camera_lookat'])
        if (searchParams.has(key)) overrides[key === 'camera_position' ? 'position' : 'lookat'] = parseVector(key);
    for (const [key,field] of [['camera_fov','fov'],['camera_aperture','aperture'],['camera_focaldist','focaldist']]) {
        if (!searchParams.has(key)) continue;
        const value = Number(searchParams.get(key));
        if (!Number.isFinite(value)) fail('SCENE_CAMERA_OVERRIDE_INVALID',`${key} must be finite`);
        if (field === 'fov' && !(value > 0 && value < 180)) fail('SCENE_CAMERA_OVERRIDE_INVALID','camera_fov must be in (0,180) degrees');
        if (field === 'aperture' && value < 0) fail('SCENE_CAMERA_OVERRIDE_INVALID','camera_aperture must be nonnegative');
        if (field === 'focaldist' && value <= 0) fail('SCENE_CAMERA_OVERRIDE_INVALID','camera_focaldist must be positive');
        overrides[field] = value;
    }
    return Object.freeze(overrides);
}