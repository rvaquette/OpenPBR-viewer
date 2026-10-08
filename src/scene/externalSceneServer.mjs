import { createReadStream } from 'node:fs';
import { realpath, stat } from 'node:fs/promises';
import { isAbsolute, relative, resolve, extname } from 'node:path';

export const DEFAULT_SCENE_ROOT = 'D:\\WebGL2\\GLSL-PathTracer-JS\\scenes\\pathtracer';
export const EXTERNAL_SCENE_PREFIX = '/external-scenes/';

export function isWithinSceneRoot(root, target) {
    const path = relative(root, target);
    return path !== '..' && !path.startsWith(`..${process.platform === 'win32' ? '\\' : '/'}`) && !isAbsolute(path);
}

export function externalSceneAssetUrl(sourcePath, root = DEFAULT_SCENE_ROOT) {
    if (!sourcePath || sourcePath.toLowerCase() === 'none') return null;
    if (/^https?:\/\//i.test(sourcePath) || sourcePath.startsWith('/')) return sourcePath;
    const resolvedRoot = resolve(root);
    const target = resolve(resolvedRoot,sourcePath);
    if (!isWithinSceneRoot(resolvedRoot,target)) throw new Error('External asset must be within --scene-root');
    return EXTERNAL_SCENE_PREFIX + relative(resolvedRoot,target).replace(/\\/g,'/').split('/').map(encodeURIComponent).join('/');
}

export function externalSceneServer(root = process.env.SCENE_ROOT || DEFAULT_SCENE_ROOT) {
    let base = '/';
    const types = { '.scene':'text/plain', '.obj':'text/plain', '.mtlx':'application/xml',
        '.gltf':'model/gltf+json', '.glb':'model/gltf-binary', '.bin':'application/octet-stream',
        '.hdr':'application/octet-stream', '.png':'image/png', '.jpg':'image/jpeg',
        '.jpeg':'image/jpeg', '.webp':'image/webp', '.exr':'application/octet-stream' };
    const middleware = async (request, response, next) => {
        let pathname = request.url?.split('?')[0] || '';
        if (base !== '/' && pathname.startsWith(base)) pathname = pathname.slice(base.length - 1);
        if (!pathname.startsWith(EXTERNAL_SCENE_PREFIX)) return next();
        if (!['GET','HEAD'].includes(request.method)) {
            response.writeHead(405, { Allow:'GET, HEAD' });
            response.end();
            return;
        }
        try {
            const path = decodeURIComponent(pathname.slice(EXTERNAL_SCENE_PREFIX.length));
            const resolvedRoot = await realpath(root);
            const target = resolve(resolvedRoot, path);
            if (!isWithinSceneRoot(resolvedRoot,target)) throw Object.assign(new Error('Forbidden'),{status:403});
            const resolvedTarget = await realpath(target);
            if (!isWithinSceneRoot(resolvedRoot,resolvedTarget)) throw Object.assign(new Error('Forbidden'),{status:403});
            const type = types[extname(resolvedTarget).toLowerCase()];
            if (!type) throw Object.assign(new Error('Unsupported asset'),{status:403});
            const info = await stat(resolvedTarget);
            if (!info.isFile()) throw Object.assign(new Error('Not a file'),{status:404});
            response.writeHead(200, { 'Content-Type':type, 'Content-Length':info.size, 'Cache-Control':'no-store' });
            if (request.method === 'HEAD') response.end();
            else createReadStream(resolvedTarget).on('error',() => response.destroy()).pipe(response);
        } catch (error) {
            response.writeHead(error.status || (error instanceof URIError ? 400 : 404),{'Content-Type':'text/plain'});
            response.end('External scene asset unavailable');
        }
    };
    return { name:'external-scene-assets',
        configureServer(server) { base = server.config?.base || '/'; server.middlewares.use(middleware); },
        configurePreviewServer(server) { base = server.config?.base || '/'; server.middlewares.use(middleware); } };
}